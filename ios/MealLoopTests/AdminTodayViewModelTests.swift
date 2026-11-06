#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// Today and the headcount flow, checked through the view model against the prototype backend.
@MainActor
final class AdminTodayViewModelTests: XCTestCase {
    private let lunch = DemoSeed.lunch
    private let student = DemoSeed.sampleStudent.id

    /// A separate provider signs in, because the one under test may be offline.
    private func foodHead() async throws -> AdminContext {
        let email = try XCTUnwrap(DemoSeed.accounts.first { $0.role == .admin }).email
        let session = try await DemoDataProvider().signInStaff(email: email, password: DemoSeed.prototypePassword)
        return try XCTUnwrap(AdminContext(session: session))
    }

    private func loaded(_ scenario: DemoScenario = .storyStart) async throws -> (DemoDataProvider, AdminTodayViewModel) {
        let demo = DemoDataProvider(scenario: scenario)
        let model = AdminTodayViewModel(context: try await foodHead(), repositories: demo.makeRepositories(), clock: demo.clock)
        await model.load()
        return (demo, model)
    }

    private func meal(_ model: AdminTodayViewModel) throws -> AdminMealContent {
        try XCTUnwrap(model.state.value?.meal)
    }

    private func value(_ name: String, in model: AdminTodayViewModel) throws -> Int? {
        try XCTUnwrap(model.state.value?.values.first { $0.name == name }).count
    }

    private func vendorAccount() throws -> AccountID {
        try XCTUnwrap(DemoSeed.accounts.first { $0.role == .vendor }).id
    }

    // MARK: Approve

    func testApprovingMovesTheClockPastTheCutoffAndLocksAnswers() async throws {
        let (demo, model) = try await loaded()
        XCTAssertEqual(demo.clock.now(), DemoSeed.storyStartNow)
        XCTAssertEqual(model.state.value?.answersAreOpen, true)

        let didApprove = await model.approve()

        XCTAssertTrue(didApprove)
        let expected = IntentionPolicy.cutoff(for: lunch).addingTimeInterval(DemoSeed.approvalAfterCutoff)
        XCTAssertEqual(demo.clock.now(), expected)
        XCTAssertEqual(model.state.value?.now, expected, "The screen shows the moved clock")
        XCTAssertEqual(model.state.value?.answersAreOpen, false)
        XCTAssertEqual(try meal(model).headcount.approved.count, DemoSeed.forecastDiners)
        do {
            _ = try await demo.setIntention(.attending, of: student, for: lunch.id)
            XCTFail("Answers must be locked after the cutoff")
        } catch {
            guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testTheViewModelNeverMovesTheClockByItself() async throws {
        let (demo, model) = try await loaded()
        await model.load()
        await model.select(.breakfast)
        await model.select(.lunch)
        XCTAssertEqual(demo.clock.now(), DemoSeed.storyStartNow)
    }

    func testApproveIsNotOfferedTwice() async throws {
        let (demo, model) = try await loaded()
        await model.approve()
        let approvedAt = demo.clock.now()
        let second = await model.approve()
        XCTAssertFalse(second, "Once approved, the next action is to send")
        XCTAssertEqual(try meal(model).nextAction, .send(count: DemoSeed.forecastDiners))
        XCTAssertEqual(demo.clock.now(), approvedAt)
    }

    // MARK: Adjust

    func testAdjustWithoutAReasonIsRejectedAndChangesNothing() async throws {
        for reason in [nil, "", "   "] as [String?] {
            let (demo, model) = try await loaded()
            let didAdjust = await model.adjust(to: DemoSeed.forecastDiners + 10, reason: reason)
            XCTAssertFalse(didAdjust)
            XCTAssertNotNil(model.actionError, "The refusal stays on screen")
            XCTAssertEqual(try meal(model).headcount.approved, .notApproved)
            XCTAssertEqual(demo.clock.now(), DemoSeed.storyStartNow, "A refused change does not move the story")
        }
    }

    func testAdjustWithAReasonIsApprovedAndKeptInTheHistory() async throws {
        let (demo, model) = try await loaded()
        let changed = DemoSeed.forecastDiners + 10

        let didAdjust = await model.adjust(to: changed, reason: "Event")

        XCTAssertTrue(didAdjust)
        XCTAssertNil(model.actionError)
        XCTAssertEqual(try value(AdminCopy.approvedHeadcount, in: model), changed)
        XCTAssertEqual(try value(AdminCopy.liveForecast, in: model), DemoSeed.forecastDiners, "The forecast is not overwritten")
        let change = HeadcountAdjustment(from: DemoSeed.forecastDiners, to: changed, reason: "Event", adjustedBy: .admin,
                                         adjustedAt: demo.clock.now())
        XCTAssertEqual(try meal(model).history.first, .adjusted(change))
    }

    func testAHeadcountCanStillChangeUntilItIsSentButNotAfter() async throws {
        let (_, model) = try await loaded()
        await model.approve()
        XCTAssertEqual(try meal(model).adjustableCount, DemoSeed.forecastDiners)
        await model.send()
        XCTAssertNil(try meal(model).adjustableCount)
        XCTAssertNil(try meal(model).nextAction)
        let didAdjust = await model.adjust(to: DemoSeed.forecastDiners + 1, reason: "Late")
        XCTAssertFalse(didAdjust)
        XCTAssertEqual(try value(AdminCopy.sentToVendor, in: model), DemoSeed.forecastDiners)
    }

    // MARK: Never automatic

    func testAHeadcountIsNeverApprovedOrSentAutomatically() async throws {
        let (demo, model) = try await loaded()
        // Time passing and reloading are all that happens here: nobody responds.
        for moment in [DemoSeed.time(10, 1), DemoSeed.time(11, 30), DemoSeed.time(23, 59)] {
            demo.clock.set(moment)
            await model.load()
            let headcount = try meal(model).headcount
            XCTAssertEqual(headcount.approved, .notApproved)
            XCTAssertEqual(headcount.sentToVendor, .notSent)
            XCTAssertEqual(try meal(model).nextAction, .approve(count: DemoSeed.forecastDiners))
        }
    }

    func testNothingReachesTheVendorBeforeTheFoodHeadSends() async throws {
        let (_, model) = try await loaded()
        let refused = await model.send()
        XCTAssertFalse(refused, "Sending needs an approval")
        XCTAssertNotNil(model.actionError)
        await model.approve()
        XCTAssertEqual(try meal(model).headcount.sentToVendor, .notSent, "Approving is not sending")
        XCTAssertNil(try value(AdminCopy.sentToVendor, in: model))
    }

    // MARK: The six values

    func testTheSixValuesKeepTheirOwnNamesInOrder() async throws {
        let (_, model) = try await loaded()
        XCTAssertEqual(model.state.value?.values.map(\.name),
                       ["Live forecast", "Cutoff forecast", "Approved headcount", "Sent to vendor", "Actual entries", "Final entries"])
    }

    func testTheSixValuesStaySeparateThroughTheWholeStory() async throws {
        let (demo, model) = try await loaded()
        let approved = DemoSeed.forecastDiners + 10
        await model.adjust(to: approved, reason: "Event")
        await model.send()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        let request = EntryRequest(mealID: lunch.id, student: DemoSeed.sampleStudent, method: .qrScan,
                                   idempotencyKey: .make())
        _ = try await demo.recordEntry(request)
        await model.load()

        XCTAssertEqual(try value(AdminCopy.liveForecast, in: model), DemoSeed.forecastDiners)
        XCTAssertNil(try value(AdminCopy.cutoffForecast, in: model), "Never filled from the live forecast")
        XCTAssertEqual(try value(AdminCopy.approvedHeadcount, in: model), approved)
        XCTAssertEqual(try value(AdminCopy.sentToVendor, in: model), approved)
        XCTAssertEqual(try value(AdminCopy.actualEntries, in: model), 1)
        XCTAssertNil(try value(AdminCopy.finalEntries, in: model), "Live entries are never final")

        _ = try await demo.closeMeal(lunch.id, by: .supervisor)
        await model.load()
        XCTAssertNil(try value(AdminCopy.actualEntries, in: model))
        XCTAssertEqual(try value(AdminCopy.finalEntries, in: model), 1)
        XCTAssertEqual(try meal(model).leadValue.name, AdminCopy.finalEntries)
    }

    func testTheTileAlwaysNamesTheValueItLeadsWith() async throws {
        let (demo, model) = try await loaded()
        XCTAssertEqual(try meal(model).leadValue.name, AdminCopy.liveForecast)
        await model.approve()
        XCTAssertEqual(try meal(model).leadValue.name, AdminCopy.approvedHeadcount)
        await model.send()
        XCTAssertEqual(try meal(model).leadValue.name, AdminCopy.sentToVendor)
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        await model.load()
        XCTAssertEqual(try meal(model).leadValue, AdminHeadcountValue(name: AdminCopy.actualEntries, count: 0),
                       "A real zero in service is a recorded count, not a missing one")
    }

    // MARK: Missing is not zero

    func testMissingValuesAreNilAndNeverZeroAtTheStart() async throws {
        let (_, model) = try await loaded()
        for name in [AdminCopy.cutoffForecast, AdminCopy.approvedHeadcount, AdminCopy.sentToVendor,
                     AdminCopy.actualEntries, AdminCopy.finalEntries] {
            XCTAssertNil(try value(name, in: model), name)
        }
    }

    func testBreakfastShowsMissingValuesWithoutFailing() async throws {
        let (_, model) = try await loaded()
        await model.select(.breakfast)
        guard case .loaded(let content) = model.state else { return XCTFail("Expected loaded, got \(model.state)") }
        XCTAssertEqual(content.selectedSlot, .breakfast)
        XCTAssertTrue(content.values.allSatisfy { $0.count == nil })
        XCTAssertNil(content.meal?.filledSteps, "No data is dashed, not step 0")
        XCTAssertNil(content.meal?.nextAction, "Nothing to approve without a forecast")
    }

    func testASlotWithNoMealIsMissingAndNotZero() async throws {
        let (_, model) = try await loaded()
        for slot in [MealSlot.snacks, .dinner] {
            await model.select(slot)
            guard case .loaded(let content) = model.state else { return XCTFail("Expected loaded, got \(model.state)") }
            XCTAssertNil(content.meal)
            XCTAssertEqual(content.values.count, 6)
            XCTAssertTrue(content.values.allSatisfy { $0.count == nil })
            XCTAssertFalse(content.tileIsUrgent)
        }
    }

    // MARK: Vendor

    func testSendingShowsPendingUntilTheVendorAcknowledges() async throws {
        let (demo, model) = try await loaded()
        await model.approve()
        let didSend = await model.send()
        XCTAssertTrue(didSend)

        let sentAt = demo.clock.now()
        XCTAssertEqual(try meal(model).headcount.vendorAcknowledgmentStatus, .pending(publishedAt: sentAt))
        XCTAssertEqual(try meal(model).filledSteps, 2, "Forecast and sent, but not replied")

        // Nothing the Food Head does here can stand in for the vendor.
        await model.load()
        XCTAssertEqual(try meal(model).headcount.vendorAcknowledgmentStatus, .pending(publishedAt: sentAt))

        let vendor = try vendorAccount()
        _ = try await demo.acknowledgeHeadcount(for: lunch.id, by: vendor)
        await model.load()
        XCTAssertEqual(try meal(model).headcount.vendorAcknowledgmentStatus,
                       .acknowledged(VendorAcknowledgment(acknowledgedBy: vendor, acknowledgedAt: demo.clock.now())))
        XCTAssertEqual(try meal(model).filledSteps, 3)
    }

    func testTheHistoryRecordsEachStepInOrder() async throws {
        let (demo, model) = try await loaded()
        await model.adjust(to: DemoSeed.forecastDiners + 10, reason: "Exam")
        await model.send()
        _ = try await demo.acknowledgeHeadcount(for: lunch.id, by: try vendorAccount())
        await model.load()
        let kinds = try meal(model).history.map { event -> String in
            switch event {
            case .adjusted: return "adjusted"
            case .approved: return "approved"
            case .sent: return "sent"
            case .acknowledged: return "acknowledged"
            }
        }
        XCTAssertEqual(kinds, ["adjusted", "approved", "sent", "acknowledged"])
    }

    // MARK: Student answers

    func testAStudentsAnswerAppearsThroughTheRepository() async throws {
        let (demo, model) = try await loaded()
        let before = try meal(model).answers
        let fromRepository = try await demo.answerCounts(for: lunch.id)
        XCTAssertEqual(before, fromRepository)

        _ = try await demo.setIntention(.attending, of: student, for: lunch.id)
        await model.load()

        let after = try meal(model).answers
        XCTAssertEqual(after.attending, before.attending + 1)
        XCTAssertEqual(after.noResponse, before.noResponse - 1)
        XCTAssertEqual(try value(AdminCopy.liveForecast, in: model), DemoSeed.forecastDiners,
                       "An answer does not move the forecast (P-STORY-1)")
    }

    // MARK: Access

    func testNoOtherRoleCanReachTheAdminRole() async throws {
        for account in DemoSeed.accounts where account.role != .admin {
            XCTAssertNotEqual(RoleRoot.destination(for: account.role), .admin, "\(account.role)")
            XCTAssertNil(AdminContext(session: Session(account: account, staff: nil)), "\(account.role)")
        }
        let wrongScope = Account(id: AccountID("hostel-admin"), displayName: "Admin", email: "a@mealloop.example",
                                 role: .admin, scope: .hostel(DemoSeed.hostelID))
        XCTAssertNil(AdminContext(session: Session(account: wrongScope, staff: nil)), "No mess, no Today")
        let context = try await foodHead()
        XCTAssertEqual(context.account.role, .admin)
        XCTAssertEqual(context.mess, DemoSeed.mess)
    }

    // MARK: Today states

    func testOnlyTheTileThatNeedsActionIsUrgent() async throws {
        let (_, model) = try await loaded()
        XCTAssertEqual(model.state.value?.tileIsUrgent, true)
        await model.approve()
        XCTAssertEqual(model.state.value?.tileIsUrgent, true, "It still needs sending")
        await model.send()
        XCTAssertEqual(model.state.value?.tileIsUrgent, false)
    }

    func testAnOpenSafetyCaseTakesTheBlackPlaceFromTheTile() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        let safetyCase = SOSCase(id: SOSCaseID("case"), messID: DemoSeed.mess.id, title: "Found something in food",
                                 place: "Block A", raisedAt: DemoSeed.time(6, 45), claim: nil, checks: [], status: .open)
        let live = demo.makeRepositories()
        let repositories = Repositories(meals: live.meals, mealState: live.mealState, headcount: live.headcount,
                                        entries: live.entries, intentions: live.intentions, shortages: live.shortages,
                                        wasteReports: live.wasteReports, sos: OpenCaseRepository(safetyCase: safetyCase),
                                        auth: live.auth)
        let model = AdminTodayViewModel(context: try await foodHead(), repositories: repositories, clock: demo.clock)
        await model.load()
        XCTAssertEqual(model.state.value?.safetyCases, [safetyCase])
        XCTAssertEqual(model.state.value?.tileIsUrgent, false)
        XCTAssertNotNil(try meal(model).nextAction, "The approval still waits; it just isn't the black tile")
    }

    func testAReportedShortageNeedsTheFoodHead() async throws {
        let (_, model) = try await loaded(.duringMealShortageReported)
        XCTAssertEqual(model.state.value?.visibleShortages.map(\.dishName), [DemoSeed.shortageDish])
        XCTAssertEqual(model.state.value?.hasMoreShortages, false)
    }

    func testAtMostTwoShortagesShowOnToday() async throws {
        let (demo, model) = try await loaded(.duringMeal)
        for dish in ["Rice", "Sambar", "Dal"] {
            _ = try await demo.reportShortage(ShortageReport(mealID: lunch.id, dishName: dish, level: .gettingLow, note: nil,
                                                             reportedBy: .kitchenStaff, idempotencyKey: .make()))
        }
        await model.load()
        XCTAssertEqual(model.state.value?.visibleShortages.count, AdminTodayContent.needsYouLimit)
        XCTAssertEqual(model.state.value?.hasMoreShortages, true)
    }

    func testOldLiveEntriesShowAsStale() async throws {
        let (_, model) = try await loaded(.duringMealEntriesStale)
        guard case .stale(_, let asOf) = model.state else { return XCTFail("Expected stale, got \(model.state)") }
        XCTAssertEqual(asOf, DemoSeed.staleEntriesAt)
    }

    func testAClosedMealLeadsWithFinalEntries() async throws {
        let (_, model) = try await loaded(.afterMeal)
        XCTAssertEqual(try meal(model).leadValue, AdminHeadcountValue(name: AdminCopy.finalEntries, count: DemoSeed.finalEntries))
        XCTAssertEqual(model.state.value?.nodes.first { $0.slot == .lunch }?.progress, .done)
    }

    func testAClosedMealOffersNothingEvenIfItWasNeverApproved() async throws {
        let (demo, model) = try await loaded(.afterMeal)
        XCTAssertEqual(try meal(model).headcount.approved, .notApproved)
        XCTAssertNil(try meal(model).nextAction)
        XCTAssertNil(try meal(model).adjustableCount)
        XCTAssertEqual(model.state.value?.tileIsUrgent, false)

        let approved = await model.approve()
        let adjusted = await model.adjust(to: DemoSeed.forecastDiners + 1, reason: "Late")
        let sent = await model.send()

        XCTAssertFalse(approved || adjusted || sent)
        let record = try await demo.headcount(for: lunch.id)
        XCTAssertEqual(record.approved, .notApproved, "Nothing reached the backend")
        XCTAssertEqual(record.sentToVendor, .notSent)
    }

    func testAnApprovedHeadcountIsNotOfferedForSendingOnceTheMealCloses() async throws {
        let (demo, model) = try await loaded()
        await model.approve()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        _ = try await demo.closeMeal(lunch.id, by: .supervisor)
        await model.load()
        XCTAssertNil(try meal(model).nextAction)
        let sent = await model.send()
        XCTAssertFalse(sent)
        let record = try await demo.headcount(for: lunch.id)
        XCTAssertEqual(record.sentToVendor, .notSent)
    }

    func testAClosedMealKeepsPendingOrAcknowledgedFromTheRepository() async throws {
        let (demo, model) = try await loaded()
        await model.approve()
        await model.send()
        let sentAt = demo.clock.now()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        _ = try await demo.closeMeal(lunch.id, by: .supervisor)
        await model.load()
        XCTAssertEqual(try meal(model).headcount.vendorAcknowledgmentStatus, .pending(publishedAt: sentAt),
                       "Closing a meal is never an acknowledgment")
        XCTAssertNil(try meal(model).nextAction)

        let vendor = try vendorAccount()
        _ = try await demo.acknowledgeHeadcount(for: lunch.id, by: vendor)
        await model.load()
        guard case .acknowledged(let record) = try meal(model).headcount.vendorAcknowledgmentStatus else {
            return XCTFail("Expected acknowledged")
        }
        XCTAssertEqual(record.acknowledgedBy, vendor)
    }

    func testTheDayLineFollowsTheMovedClock() async throws {
        let (_, model) = try await loaded()
        XCTAssertEqual(model.state.value?.nodes.map(\.slot), MealSlot.allCases)
        XCTAssertEqual(model.state.value?.nodes.first?.progress, .upcoming, "Breakfast starts at 7:30 AM")
        await model.approve()
        XCTAssertEqual(model.state.value?.nodes.first?.progress, .done, "10:05 AM is after breakfast")
        XCTAssertEqual(model.state.value?.nodes[1].progress, .current)
    }

    func testOfflineNeverPretendsToHaveData() async throws {
        let (_, model) = try await loaded(.offline)
        guard case .offline(let value, let savedAt) = model.state else { return XCTFail("Expected offline, got \(model.state)") }
        XCTAssertNil(value)
        XCTAssertEqual(savedAt, DemoSeed.offlineSavedAt)
    }

    func testGoingOfflineKeepsTheLastContentAndSavesNothing() async throws {
        let (demo, model) = try await loaded()
        await demo.setScenario(.offline)
        let didApprove = await model.approve()
        XCTAssertFalse(didApprove)
        XCTAssertEqual(model.actionError, AdminCopy.offlineNothingSaved)
        XCTAssertEqual(try meal(model).headcount.approved, .notApproved)
        await model.load()
        guard case .offline(let value, _) = model.state else { return XCTFail("Expected offline, got \(model.state)") }
        XCTAssertNotNil(value, "The last content stays on screen")
    }

    func testRemoteDataFailsHonestly() async throws {
        let model = AdminTodayViewModel(context: try await foodHead(), repositories: RemoteAPI(baseURL: nil).makeRepositories(),
                                        clock: SystemClock())
        await model.load()
        guard case .failed(let failure) = model.state else { return XCTFail("Expected failed, got \(model.state)") }
        XCTAssertTrue(failure.isNotImplemented)
    }

    func testASlowRefreshCannotPutBackTheMealTheFoodHeadLeft() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        let live = demo.makeRepositories()
        let gate = HoldNextCall()
        let repositories = Repositories(meals: live.meals, mealState: live.mealState,
                                        headcount: GatedHeadcount(base: live.headcount, gate: gate),
                                        entries: live.entries, intentions: live.intentions,
                                        shortages: live.shortages, wasteReports: live.wasteReports, sos: live.sos,
                                        auth: live.auth)
        let model = AdminTodayViewModel(context: try await foodHead(), repositories: repositories, clock: demo.clock)
        await model.load()
        XCTAssertEqual(model.state.value?.selectedSlot, .lunch)

        await gate.arm()
        let refresh = Task { await model.load() }
        await gate.waitUntilHolding()
        await model.select(.breakfast)
        await gate.release()
        await refresh.value

        XCTAssertEqual(model.state.value?.selectedSlot, .breakfast)
    }

    func testInitialsComeFromTheName() {
        XCTAssertEqual(AdminCopy.initials("Devi Raman"), "DR")
        XCTAssertEqual(AdminCopy.initials("Mess food head"), "MF")
    }

    func testTheGreetingUsesTheFirstNameAsOnA01() {
        XCTAssertEqual(AdminCopy.greeting("Devi Raman"), "Hey Devi")
        XCTAssertEqual(AdminCopy.greeting("Devi"), "Hey Devi")
    }

    func testTheSeededFoodHeadMatchesTheDesign() throws {
        let account = try XCTUnwrap(DemoSeed.accounts.first { $0.role == .admin })
        XCTAssertEqual(AdminCopy.greeting(account.displayName), "Hey Devi")
        XCTAssertEqual(AdminCopy.initials(account.displayName), "DR")
    }
}

/// Holds the next call until the test lets it go, so a slow load can be finished last on purpose.
private actor HoldNextCall {
    private var isArmed = false
    private var held: CheckedContinuation<Void, Never>?

    func arm() { isArmed = true }

    func pass() async {
        guard isArmed else { return }
        isArmed = false
        await withCheckedContinuation { held = $0 }
    }

    func waitUntilHolding() async {
        while held == nil { await Task.yield() }
    }

    func release() {
        held?.resume()
        held = nil
    }
}

/// The refresh has already chosen its meal by the time it reads the headcount, so this is where it can fall behind.
private struct GatedHeadcount: HeadcountRepository {
    let base: any HeadcountRepository
    let gate: HoldNextCall

    func headcount(for meal: MealID) async throws -> Headcount {
        await gate.pass()
        return try await base.headcount(for: meal)
    }
    func approveHeadcount(_ count: Int, reason: String?, for meal: MealID, by role: Role) async throws -> Headcount {
        try await base.approveHeadcount(count, reason: reason, for: meal, by: role)
    }
    func publishHeadcount(for meal: MealID, by role: Role) async throws -> Headcount {
        try await base.publishHeadcount(for: meal, by: role)
    }
    func acknowledgeHeadcount(for meal: MealID, by account: AccountID) async throws -> Headcount {
        try await base.acknowledgeHeadcount(for: meal, by: account)
    }
}

/// A safety case the seed does not have, so that Today state can be tested.
private struct OpenCaseRepository: SOSRepository {
    let safetyCase: SOSCase

    func activeCases(for mess: MessID) async throws -> [SOSCase] { [safetyCase] }
    func claim(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase { safetyCase }
    func markChecked(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase { safetyCase }
    func close(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase { safetyCase }
    func raise(_ report: SOSReport) async throws -> SOSCase { safetyCase }
}
#endif
