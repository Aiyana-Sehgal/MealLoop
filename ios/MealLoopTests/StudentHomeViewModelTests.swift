#if DEMO_DATA || REVIEW_DATA
import CoreImage
import XCTest
@testable import MealLoop

private final class TestClock: StoryClock, @unchecked Sendable {
    private var current = Date(timeIntervalSince1970: 0)
    func now() -> Date { current }
    func set(_ date: Date) { current = date }
}

/// Student Home against the prototype backend, with a clock the tests control.
@MainActor
final class StudentHomeViewModelTests: XCTestCase {
    private let lunch = DemoSeed.lunch
    private let breakfast = DemoSeed.breakfast
    private let aarav = DemoSeed.sampleStudent.id

    private func make(_ scenario: DemoScenario = .storyStart, clock: TestClock = TestClock()) async throws -> (StudentHomeViewModel, DemoDataProvider) {
        let demo = DemoDataProvider(scenario: scenario, clock: clock)
        let session = Session(account: try XCTUnwrap(DemoSeed.accounts.first { $0.role == .student }), staff: nil,
                              student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
        let model = try XCTUnwrap(StudentHomeViewModel(session: session, repositories: demo.makeRepositories(), clock: demo.clock))
        await model.load()
        return (model, demo)
    }

    private func lunchAnswer(_ model: StudentHomeViewModel) -> MealIntention? { model.card(id: lunch.id)?.answer }

    // MARK: What Home shows

    func testAtSevenTheHeroIsBreakfastWithTheSeededAnswer() async throws {
        let (model, _) = try await make()
        let content = try XCTUnwrap(model.state.value)
        XCTAssertEqual(content.hero.meal.slot, .breakfast)
        XCTAssertEqual(content.hero.answer, .attending)
    }

    func testTheNextMealRowIsLunchWithNoResponse() async throws {
        let (model, _) = try await make()
        let next = try XCTUnwrap(model.state.value?.nextMeal)
        XCTAssertEqual(next.meal.slot, .lunch)
        XCTAssertEqual(next.response, .noResponse)
        XCTAssertEqual(next.answerState, .unanswered)
        XCTAssertEqual(next.cutoff, IntentionPolicy.cutoff(for: lunch))
    }

    func testAfterBreakfastTheHeroIsLunchAndThereIsNoNextRow() async throws {
        let clock = TestClock()
        let (model, _) = try await make(clock: clock)
        clock.set(IntentionPolicy.cutoff(for: lunch).addingTimeInterval(60))
        await model.load()
        XCTAssertEqual(model.state.value?.hero.meal.slot, .lunch)
        XCTAssertNil(model.state.value?.nextMeal)
    }

    func testOnceEveryMealIsOverTheLastOneStays() async throws {
        let (model, demo) = try await make()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        _ = try await demo.closeMeal(lunch.id, by: .supervisor)
        await model.load()
        XCTAssertEqual(model.state.value?.hero.meal.slot, .lunch)
    }

    // MARK: Answers

    func testAnswerThenChangeBeforeTheCutoff() async throws {
        let (model, demo) = try await make()
        await model.answer(.attending, for: lunch.id)
        XCTAssertEqual(lunchAnswer(model), .attending)
        await model.answer(.notSure, for: lunch.id)
        XCTAssertEqual(lunchAnswer(model), .notSure)
        let stored = try await demo.response(of: aarav, for: lunch.id)
        guard case .answered(.notSure, _) = stored else { return XCTFail("\(stored)") }
    }

    func testAnAnswerAfterTheCutoffIsRefusedAndShownLocked() async throws {
        let clock = TestClock()
        let (model, demo) = try await make(clock: clock)
        clock.set(IntentionPolicy.cutoff(for: lunch))
        await model.answer(.attending, for: lunch.id)
        let stored = try await demo.response(of: aarav, for: lunch.id)
        XCTAssertEqual(stored, .noResponse)
        XCTAssertEqual(model.state.value?.hero.answerState, .locked(nil))
        XCTAssertNil(model.answerError)
    }

    func testAStoredAnswerShowsAsLockedAfterTheCutoff() async throws {
        let clock = TestClock()
        let (model, _) = try await make(clock: clock)
        await model.answer(.skipping, for: lunch.id)
        clock.set(IntentionPolicy.cutoff(for: lunch))
        await model.load()
        XCTAssertEqual(model.state.value?.hero.answerState, .locked(.skipping))
    }

    func testARepeatTapKeepsTheFirstAnswerTime() async throws {
        let clock = TestClock()
        let (model, demo) = try await make(clock: clock)
        await model.answer(.attending, for: lunch.id)
        let first = try await demo.response(of: aarav, for: lunch.id)
        clock.set(clock.now().addingTimeInterval(60))
        await model.answer(.attending, for: lunch.id)
        let second = try await demo.response(of: aarav, for: lunch.id)
        XCTAssertEqual(first, second)
    }

    func testAnOfflineAnswerRecordsNothingAndSaysSo() async throws {
        let (model, demo) = try await make()
        await demo.setScenario(.offline)
        await model.answer(.attending, for: lunch.id)
        XCTAssertNotNil(model.answerError)
        XCTAssertNil(model.savingAnswer)
        await demo.setScenario(.storyStart)
        let stored = try await demo.response(of: aarav, for: lunch.id)
        XCTAssertEqual(stored, .noResponse)
    }

    // MARK: Entry QR

    func testTheQRIsAvailableForEveryAnswerAndAfterTheCutoff() async throws {
        for intention in [MealIntention.attending, .skipping, .notSure] as [MealIntention?] + [nil] {
            let clock = TestClock()
            let (model, _) = try await make(clock: clock)
            if let intention { await model.answer(intention, for: lunch.id) }
            clock.set(IntentionPolicy.cutoff(for: lunch).addingTimeInterval(60))
            await model.load()
            await model.loadEntryCode()
            XCTAssertNotNil(model.entryCode.value, "\(String(describing: intention))")
        }
    }

    func testTheQRStaysReachableOffline() async throws {
        let (model, _) = try await make(.offline)
        XCTAssertNil(model.state.value)
        XCTAssertTrue(model.showsEntryFallback)
        await model.loadEntryCode()
        XCTAssertNotNil(model.entryCode.value)
    }

    func testTheSeededCodeDrawsAQR() async throws {
        let (model, _) = try await make()
        await model.loadEntryCode()
        let code = try XCTUnwrap(model.entryCode.value)
        XCTAssertNotNil(EntryQRImage.make(code.payload))
        XCTAssertTrue(model.context.student.maskedID.hasSuffix(code.lastFour))
    }

    func testTheDrawnQRReadsBackAsTheSeededPayload() async throws {
        let (model, demo) = try await make()
        await model.loadEntryCode()
        let code = try XCTUnwrap(model.entryCode.value)
        let cgImage = try XCTUnwrap(EntryQRImage.make(code.payload)?.cgImage)
        let scaled = CIImage(cgImage: cgImage).transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let detector = try XCTUnwrap(CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: nil))
        let read = try XCTUnwrap((detector.features(in: scaled).first as? CIQRCodeFeature)?.messageString)
        XCTAssertEqual(read, code.payload)
        // What the door reads resolves to this student once lunch is being served.
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        let resolved = try await demo.resolveEntry(.qrPayload(read), for: lunch.id)
        XCTAssertEqual(resolved, .student(DemoSeed.sampleStudent))
    }

    // MARK: Missing data and access

    func testAMealWithNoMenuIsEmptyNotZero() async throws {
        let (model, _) = try await make()
        await model.loadMenu(for: breakfast.id)
        XCTAssertEqual(model.menu, .empty)
        await model.loadMenu(for: lunch.id)
        XCTAssertEqual(model.menu.value, DemoSeed.lunchMenu)
    }

    func testNoResponseIsNotAnAnswer() async throws {
        let (model, _) = try await make()
        XCTAssertNil(lunchAnswer(model))
    }

    func testANonStudentSessionCannotOpenStudentHome() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        for account in DemoSeed.accounts where account.role != .student {
            let session = try await demo.signInStaff(email: account.email, password: DemoSeed.prototypePassword)
            XCTAssertNil(StudentHomeViewModel(session: session, repositories: demo.makeRepositories(), clock: demo.clock), "\(account.role)")
        }
        // A session claiming a student's context still needs the Student role.
        let warden = try XCTUnwrap(DemoSeed.accounts.first { $0.role == .warden })
        let forged = Session(account: warden, staff: nil, student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
        XCTAssertNil(StudentHomeViewModel(session: forged, repositories: demo.makeRepositories(), clock: demo.clock))
    }

    func testTheTabsMatchTheRoleRoot() {
        XCTAssertEqual(StudentTab.pillTabs.map(\.rawValue), RoleRoot.student.placeholderTabs)
    }

    // MARK: Cross-role

    func testTheAnswerIsVisibleToTheAdminAndDoorSides() async throws {
        let (model, demo) = try await make()
        await model.answer(.attending, for: lunch.id)
        let repositories = demo.makeRepositories()
        let counts = try await repositories.intentions.answerCounts(for: lunch.id)
        XCTAssertEqual(counts.attending, 2)
        _ = try await repositories.mealState.startMeal(lunch.id, by: .supervisor)
        let request = EntryRequest(mealID: lunch.id, student: DemoSeed.sampleStudent, method: .qrScan, idempotencyKey: .make())
        guard case .recorded(let record, _) = try await repositories.entries.recordEntry(request) else {
            return XCTFail("Expected a new entry")
        }
        XCTAssertTrue(record.hadMealResponse)
    }

    // MARK: Formatting

    func testCutoffsShowFromTheBackendNotTheSampleText() {
        let timeZone = DemoSeed.mess.timeZone
        XCTAssertEqual(StudentFormat.shortTime(IntentionPolicy.cutoff(for: lunch), in: timeZone), "10 AM")
        XCTAssertEqual(StudentFormat.shortTime(IntentionPolicy.cutoff(for: breakfast), in: timeZone), "5:30 AM")
        XCTAssertEqual(StudentFormat.day(DemoSeed.storyStartNow, in: timeZone), "Wednesday 14 Aug")
    }
}
#endif
