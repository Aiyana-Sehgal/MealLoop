#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// Fails `acknowledgeHeadcount` until told otherwise, so a send that never reached MealLoop can be retried.
private final class FlakyHeadcount: HeadcountRepository, @unchecked Sendable {
    let base: any HeadcountRepository
    var isFailing = true
    private(set) var attempts = 0

    init(_ base: any HeadcountRepository) { self.base = base }

    func headcount(for meal: MealID) async throws -> Headcount { try await base.headcount(for: meal) }
    func approveHeadcount(_ count: Int, reason: String?, for meal: MealID, by role: Role) async throws -> Headcount {
        try await base.approveHeadcount(count, reason: reason, for: meal, by: role)
    }
    func publishHeadcount(for meal: MealID, by role: Role) async throws -> Headcount { try await base.publishHeadcount(for: meal, by: role) }
    func acknowledgeHeadcount(for meal: MealID, by account: AccountID) async throws -> Headcount {
        attempts += 1
        if isFailing { throw RepositoryError.offline(lastSavedAt: nil) }
        return try await base.acknowledgeHeadcount(for: meal, by: account)
    }
}

/// The Vendor role through its view models, against the prototype backend and the story clock.
@MainActor
final class VendorViewModelTests: XCTestCase {
    private let lunch = DemoSeed.lunch

    private func account(_ role: Role) throws -> Account { try XCTUnwrap(DemoSeed.accounts.first { $0.role == role }) }

    private func vendor(_ demo: DemoDataProvider, headcount: (any HeadcountRepository)? = nil) throws -> VendorHomeViewModel {
        var repositories = demo.makeRepositories()
        if let headcount {
            repositories = Repositories(meals: repositories.meals, mealState: repositories.mealState, headcount: headcount,
                                        entries: repositories.entries, intentions: repositories.intentions,
                                        shortages: repositories.shortages, wasteReports: repositories.wasteReports,
                                        sos: repositories.sos, auth: repositories.auth, vendor: repositories.vendor)
        }
        return VendorHomeViewModel(account: try account(.vendor), repositories: repositories)
    }

    private func approveAndSend(_ demo: DemoDataProvider) async throws {
        _ = try await demo.approveHeadcount(DemoSeed.forecastDiners, reason: nil, for: lunch.id, by: .admin)
        _ = try await demo.publishHeadcount(for: lunch.id, by: .admin)
    }

    func testBeforeApprovalTheVendorIsWaitingAndSeesNoNumber() async throws {
        let model = try vendor(DemoDataProvider(scenario: .storyStart))
        await model.load()
        let content = try XCTUnwrap(model.state.value)
        XCTAssertEqual(content.phase, .notApproved)
        XCTAssertEqual(content.meal, lunch)
        XCTAssertEqual(content.mess, DemoSeed.mess)
    }

    func testApprovedButNotSentStillShowsNoNumber() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        _ = try await demo.approveHeadcount(DemoSeed.forecastDiners, reason: nil, for: lunch.id, by: .admin)
        let model = try vendor(demo)
        await model.load()
        XCTAssertEqual(model.state.value?.phase, .approvedNotSent, "The vendor sees the headcount only once it is sent")
    }

    func testAfterTheFoodHeadApprovesAndSendsTheVendorSeesTheApprovedHeadcount() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        try await approveAndSend(demo)
        let model = try vendor(demo)
        await model.load()
        guard case .sent(let count, let sentAt) = try XCTUnwrap(model.state.value).phase else { return XCTFail("expected sent") }
        XCTAssertEqual(count, DemoSeed.forecastDiners)
        XCTAssertEqual(sentAt, demo.clock.now())
    }

    func testAcknowledgingRecordsTheTimeOnTheStoryClock() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        try await approveAndSend(demo)
        let model = try vendor(demo)
        await model.load()
        let at = demo.clock.now().addingTimeInterval(8 * 60)
        demo.clock.set(at)
        await model.acknowledge()
        guard case .acknowledged(_, _, let acknowledgedAt) = try XCTUnwrap(model.state.value).phase else {
            return XCTFail("expected acknowledged")
        }
        XCTAssertEqual(acknowledgedAt, at)
        XCTAssertEqual(model.send, .idle)
    }

    func testPendingIsNeverFilledIn() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        try await approveAndSend(demo)
        let model = try vendor(demo)
        await model.load()
        guard case .sent = try XCTUnwrap(model.state.value).phase else { return XCTFail("expected sent, not acknowledged") }
        let headcount = try await demo.headcount(for: lunch.id)
        guard case .pending = headcount.vendorAcknowledgmentStatus else { return XCTFail("The Food Head must see Pending") }
        let history = try await demo.vendorHistory(for: try account(.vendor).id)
        XCTAssertNil(history.last?.acknowledgedAt, "No reply until the vendor acts")
    }

    func testAFailedSendShowsCouldNotSendAndARetryCountsOnce() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        try await approveAndSend(demo)
        let flaky = FlakyHeadcount(demo)
        let model = try vendor(demo, headcount: flaky)
        await model.load()
        await model.acknowledge()
        XCTAssertEqual(model.send, .failed)
        guard case .sent = try XCTUnwrap(model.state.value).phase else { return XCTFail("A failed send is never acknowledged") }
        let notYet = try await demo.headcount(for: lunch.id)
        XCTAssertNil(notYet.acknowledgment)

        flaky.isFailing = false
        let firstAt = demo.clock.now()
        await model.acknowledge()
        demo.clock.set(firstAt.addingTimeInterval(60))
        await model.acknowledge()
        XCTAssertEqual(flaky.attempts, 3)
        let headcount = try await demo.headcount(for: lunch.id)
        XCTAssertEqual(headcount.acknowledgment?.acknowledgedAt, firstAt, "A repeat keeps the first acknowledgment")
        guard case .acknowledged(_, _, let at) = try XCTUnwrap(model.state.value).phase else { return XCTFail("expected acknowledged") }
        XCTAssertEqual(at, firstAt)
    }

    func testTheFoodHeadSeesTheReplyTheVendorWrote() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        try await approveAndSend(demo)
        let model = try vendor(demo)
        await model.load()
        await model.acknowledge()
        let foodHead = try await DemoDataProvider().signInStaff(email: try account(.admin).email, password: DemoSeed.prototypePassword)
        let admin = AdminTodayViewModel(context: try XCTUnwrap(AdminContext(session: foodHead)), repositories: demo.makeRepositories(),
                                        clock: demo.clock)
        await admin.load()
        let status = try XCTUnwrap(admin.state.value?.meal).headcount.vendorAcknowledgmentStatus
        guard case .acknowledged(let record) = status else { return XCTFail("Admin must show the vendor's reply") }
        XCTAssertEqual(record.acknowledgedBy, try account(.vendor).id)
        guard case .acknowledged(_, _, let vendorAt) = try XCTUnwrap(model.state.value).phase else { return XCTFail("expected acknowledged") }
        XCTAssertEqual(record.acknowledgedAt, vendorAt)
    }

    func testAcknowledgingBeforeTheSendIsRefusedByTheBackend() async throws {
        let model = try vendor(DemoDataProvider(scenario: .storyStart))
        await model.load()
        await model.acknowledge()
        XCTAssertEqual(model.send, .failed)
        XCTAssertEqual(model.state.value?.phase, .notApproved)
    }

    func testOnlyTheVendorAccountReachesTheRole() throws {
        for role in Role.allCases {
            let account = Account(id: AccountID("x-\(role.rawValue)"), displayName: "x", email: "x", role: role, scope: .mess(DemoSeed.mess.id))
            XCTAssertEqual(VendorAccess.canOpen(Session(account: account, staff: nil)), role == .vendor, role.rawValue)
        }
    }

    func testAnotherAccountCannotAcknowledge() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        try await approveAndSend(demo)
        do {
            _ = try await demo.acknowledgeHeadcount(for: lunch.id, by: try account(.admin).id)
            XCTFail("Only the vendor account acknowledges")
        } catch {
            guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testThePreviousMealRowIsTheSampleBreakfastWithItsReplyOnlyOnceItHappened() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        let model = try vendor(demo)
        await model.load()
        let early = try XCTUnwrap(model.state.value?.previous)
        XCTAssertEqual(early.meal.id, DemoSeed.breakfast.id)
        XCTAssertNil(early.acknowledgedAt)
        XCTAssertEqual(VendorFormat.previousTitle(early), "Breakfast · \(DemoSeed.vendorBreakfastSentCount)")
        demo.clock.set(DemoSeed.vendorBreakfastRepliedAt)
        await model.load()
        XCTAssertEqual(model.state.value?.previous?.acknowledgedAt, DemoSeed.vendorBreakfastRepliedAt)
    }

    func testOfflineKeepsWhatWasShownAndClaimsNothing() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        let model = try vendor(demo)
        await model.load()
        await demo.setScenario(.offline)
        await model.load()
        guard case .offline(let kept, _) = model.state else { return XCTFail("expected offline") }
        XCTAssertEqual(kept?.phase, .notApproved)
    }

    func testAMissingCountReadsUnavailableNeverZero() {
        let entry = VendorHeadcountEntry(meal: DemoSeed.breakfast, sentCount: nil, sentAt: nil, acknowledgedAt: nil, isSample: false)
        XCTAssertEqual(VendorFormat.previousTitle(entry), "Breakfast · unavailable")
        XCTAssertEqual(VendorFormat.initials("Mess vendor"), "MV")
    }
}
#endif
