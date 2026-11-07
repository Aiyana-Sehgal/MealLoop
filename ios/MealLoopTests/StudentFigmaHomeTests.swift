#if DEMO_DATA || REVIEW_DATA
import CoreImage
import XCTest
@testable import MealLoop

private final class FigmaClock: StoryClock, @unchecked Sendable {
    private var current = Date(timeIntervalSince1970: 0)
    func now() -> Date { current }
    func set(_ date: Date) { current = date }
}

/// Fails every write, as a server error would. Reads go to the prototype backend.
private struct RefusingIntentions: IntentionRepository {
    let source: DemoDataProvider

    func response(of student: StudentID, for meal: MealID) async throws -> IntentionResponse {
        try await source.response(of: student, for: meal)
    }
    func setIntention(_ intention: MealIntention, of student: StudentID, for meal: MealID) async throws -> IntentionResponse {
        throw RepositoryError.notFound
    }
    func answerCounts(for meal: MealID) async throws -> MealAnswerCounts { try await source.answerCounts(for: meal) }
}

/// Student Home, the answer page and Entry QR as rebuilt from the Figma frames.
@MainActor
final class StudentFigmaHomeTests: XCTestCase {
    private let lunch = DemoSeed.lunch
    private let aarav = DemoSeed.sampleStudent.id

    private var session: Session {
        get throws {
            Session(account: try XCTUnwrap(DemoSeed.accounts.first { $0.role == .student }), staff: nil,
                    student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
        }
    }

    private func make(at time: Date? = nil, clock: FigmaClock = FigmaClock()) async throws -> (StudentHomeViewModel, DemoDataProvider) {
        let demo = DemoDataProvider(scenario: .storyStart, clock: clock)
        if let time { clock.set(time) }
        let model = try XCTUnwrap(StudentHomeViewModel(session: try session, repositories: demo.makeRepositories(), clock: demo.clock))
        await model.load()
        return (model, demo)
    }

    /// The story meal's state moves with the Supervisor, so these use the backend's own operations.
    private func content(_ model: StudentHomeViewModel) throws -> StudentHomeContent { try XCTUnwrap(model.state.value) }

    // MARK: The top card

    func testAtSevenTheCardSaysYoureIn() async throws {
        let (model, _) = try await make()
        XCTAssertEqual(try content(model).heroCase, .answered)
    }

    func testAnOpenBreakfastQuestionComesBeforeTheClosedMess() async throws {
        let clock = FigmaClock()
        let demo = DemoDataProvider(scenario: .storyStart, clock: clock)
        clock.set(DemoSeed.time(5, 0))
        var repositories = demo.makeRepositories()
        repositories = Repositories(meals: demo, mealState: demo, headcount: demo, entries: demo,
                                    intentions: EmptyBreakfast(source: demo), shortages: demo, wasteReports: demo, sos: demo,
                                    auth: demo, specialPasses: demo, studentExtras: demo)
        let model = try XCTUnwrap(StudentHomeViewModel(session: try session, repositories: repositories, clock: demo.clock))
        await model.load()
        XCTAssertEqual(try content(model).heroCase, .question)
    }

    func testBeforeTheDoorsOpenTheCardSaysTheMessIsClosed() async throws {
        let (model, _) = try await make(at: DemoSeed.time(6, 30))
        XCTAssertEqual(try content(model).heroCase, .messClosed)
    }

    func testDuringBreakfastTheCardSaysItIsOpen() async throws {
        let (model, _) = try await make(at: DemoSeed.time(8, 10))
        XCTAssertEqual(try content(model).heroCase, .nowServing)
    }

    func testAfterBreakfastTheCardIsTheNextMealAndAsksHowItWas() async throws {
        let (model, _) = try await make(at: DemoSeed.time(9, 40))
        let home = try content(model)
        XCTAssertEqual(home.heroCase, .nextMeal)
        XCTAssertEqual(home.shownHero.meal.slot, .lunch)
        XCTAssertEqual(home.lastClosedMeal?.slot, .breakfast)
    }

    func testAfterTheCutoffTheRowSaysLunchAnswersAreClosed() async throws {
        let (model, _) = try await make(at: IntentionPolicy.cutoff(for: lunch).addingTimeInterval(60))
        let row = try XCTUnwrap(try content(model).answerRow)
        XCTAssertEqual(row.meal.slot, .lunch)
        XCTAssertFalse(row.isAnswerOpen)
    }

    func testDuringLunchTheCardIsOpenAndTheRowAsksAboutDinner() async throws {
        let (model, demo) = try await make()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        await model.load()
        let home = try content(model)
        XCTAssertEqual(home.heroCase, .nowServing)
        XCTAssertEqual(home.shownHero.meal.slot, .lunch)
        XCTAssertEqual(home.answerRow?.meal.slot, .dinner)
    }

    func testOnceLunchClosesTheCardMovesToDinnerAndHeroStaysLunch() async throws {
        let (model, demo) = try await make()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        _ = try await demo.closeMeal(lunch.id, by: .supervisor)
        await model.load()
        let home = try content(model)
        XCTAssertEqual(home.hero.meal.slot, .lunch)
        XCTAssertEqual(home.shownHero.meal.slot, .dinner)
        XCTAssertEqual(home.heroCase, .nextMeal)
        XCTAssertEqual(home.lastClosedMeal?.slot, .lunch)
    }

    // MARK: Answers

    func testAnswerChangeThenLockAfterTheCutoff() async throws {
        let clock = FigmaClock()
        let (model, demo) = try await make(clock: clock)
        await model.answer(.attending, for: lunch.id)
        XCTAssertEqual(model.card(id: lunch.id)?.answer, .attending)
        await model.answer(.notSure, for: lunch.id)
        XCTAssertEqual(model.card(id: lunch.id)?.answer, .notSure)

        clock.set(IntentionPolicy.cutoff(for: lunch))
        await model.answer(.skipping, for: lunch.id)
        let stored = try await demo.response(of: aarav, for: lunch.id)
        guard case .answered(.notSure, _) = stored else { return XCTFail("The backend must refuse it, got \(stored)") }
        XCTAssertEqual(model.card(id: lunch.id)?.answerState, .locked(.notSure))
    }

    func testASkipKeepsItsReason() async throws {
        let (model, _) = try await make()
        await model.answer(.skipping, for: lunch.id, reason: .eatingElsewhere)
        XCTAssertEqual(model.skipReasons[lunch.id], .eatingElsewhere)
    }

    func testASkipWithoutAReasonHasNone() async throws {
        let (model, _) = try await make()
        await model.answer(.skipping, for: lunch.id)
        XCTAssertEqual(model.card(id: lunch.id)?.answer, .skipping)
        XCTAssertNil(model.skipReasons[lunch.id])
    }

    func testDinnerCanBeAnsweredFromHome() async throws {
        let (model, _) = try await make()
        await model.answer(.attending, for: DemoSeed.dinner.id)
        XCTAssertEqual(model.card(id: DemoSeed.dinner.id)?.answer, .attending)
    }

    func testAnOfflineAnswerWaitsAndIsNotShownAsSaved() async throws {
        let (model, demo) = try await make()
        await demo.setScenario(.offline)
        await model.answer(.attending, for: lunch.id)
        XCTAssertEqual(model.pendingAnswer?.intention, .attending)
        XCTAssertNil(model.failedAnswer)
        XCTAssertNil(model.card(id: lunch.id)?.answer)
        XCTAssertEqual(model.answerState(for: try XCTUnwrap(model.card(id: lunch.id))), .saving(.attending))
    }

    func testAWaitingAnswerGoesWhenTheConnectionIsBack() async throws {
        let clock = FigmaClock()
        let (model, demo) = try await make(clock: clock)
        await demo.setScenario(.offline)
        await model.answer(.attending, for: lunch.id)
        await demo.setScenario(.storyStart)
        clock.set(DemoSeed.storyStartNow)
        await model.load()
        XCTAssertNil(model.pendingAnswer)
        XCTAssertEqual(model.card(id: lunch.id)?.answer, .attending)
    }

    func testAWaitingAnswerIsRefusedAfterTheCutoff() async throws {
        let clock = FigmaClock()
        let (model, demo) = try await make(clock: clock)
        await demo.setScenario(.offline)
        await model.answer(.attending, for: lunch.id)
        await demo.setScenario(.storyStart)
        clock.set(IntentionPolicy.cutoff(for: lunch).addingTimeInterval(60))
        await model.load()
        XCTAssertNil(model.pendingAnswer)
        let stored = try await demo.response(of: aarav, for: lunch.id)
        XCTAssertEqual(stored, .noResponse)
    }

    func testAFailedAnswerOffersTryAgainAndStoresNothing() async throws {
        let demo = DemoDataProvider(scenario: .storyStart, clock: FigmaClock())
        let repositories = Repositories(meals: demo, mealState: demo, headcount: demo, entries: demo,
                                        intentions: RefusingIntentions(source: demo), shortages: demo, wasteReports: demo, sos: demo,
                                        auth: demo, specialPasses: demo, studentExtras: demo)
        let model = try XCTUnwrap(StudentHomeViewModel(session: try session, repositories: repositories, clock: demo.clock))
        await model.load()
        await model.answer(.attending, for: lunch.id)
        XCTAssertEqual(model.failedAnswer, .attending)
        XCTAssertNotNil(model.answerError)
        let stored = try await demo.response(of: aarav, for: lunch.id)
        XCTAssertEqual(stored, .noResponse)
    }

    func testAFailureAndAWaitingAnswerBelongToTheirOwnMeal() async throws {
        let demo = DemoDataProvider(scenario: .storyStart, clock: FigmaClock())
        let repositories = Repositories(meals: demo, mealState: demo, headcount: demo, entries: demo,
                                        intentions: RefusingIntentions(source: demo), shortages: demo, wasteReports: demo, sos: demo,
                                        auth: demo, specialPasses: demo, studentExtras: demo)
        let model = try XCTUnwrap(StudentHomeViewModel(session: try session, repositories: repositories, clock: demo.clock))
        await model.load()
        await model.answer(.attending, for: lunch.id)
        XCTAssertEqual(model.failedMeal, lunch.id)

        let (offline, source) = try await make()
        await source.setScenario(.offline)
        await offline.answer(.attending, for: lunch.id)
        let dinner = try XCTUnwrap(offline.card(id: DemoSeed.dinner.id))
        XCTAssertEqual(offline.answerState(for: dinner), dinner.answerState)
    }

    func testTryAgainKeepsTheReason() async throws {
        let (model, demo) = try await make()
        await demo.setScenario(.offline)
        await model.answer(.skipping, for: lunch.id, reason: .notHungry)
        await demo.setScenario(.storyStart)
        await model.load()
        XCTAssertEqual(model.card(id: lunch.id)?.answer, .skipping)
        XCTAssertEqual(model.skipReasons[lunch.id], .notHungry)
    }

    // MARK: The answer page menu

    func testTheAnswerMenuComesFromTheStudentMenu() async throws {
        let (model, _) = try await make()
        await model.loadAnswerMenu(for: DemoSeed.breakfast.id)
        XCTAssertEqual(model.menu.value?.first?.name, "Millet Idli")
    }

    func testAShownMenuStaysOffline() async throws {
        let (model, demo) = try await make()
        await model.loadAnswerMenu(for: lunch.id)
        await demo.setScenario(.offline)
        await model.loadAnswerMenu(for: lunch.id)
        XCTAssertEqual(model.menu.value?.count, 4)
    }

    func testDishesFollowTheKeywordRule() {
        XCTAssertEqual(StudentPictogram.asset(for: "Chappathi"), "student-dish-bread")
        XCTAssertEqual(StudentPictogram.asset(for: "Millet Idli"), "student-dish-bread")
        XCTAssertEqual(StudentPictogram.asset(for: "Veg Pulao"), "student-dish-rice")
        XCTAssertEqual(StudentPictogram.asset(for: "Steamed Rice"), "student-dish-rice")
        XCTAssertEqual(StudentPictogram.asset(for: "Panneer Butter Masala"), "student-dish-paneer")
        XCTAssertEqual(StudentPictogram.asset(for: "Muttar Masala"), "student-dish-curry")
    }

    // MARK: Entry QR

    func testTheQRChangesEveryTwelveSeconds() async throws {
        let (model, _) = try await make()
        await model.loadEntryCode()
        let first = try XCTUnwrap(model.rotatingCode?.payload)
        XCTAssertEqual(model.entrySecondsLeft, 12)
        for _ in 0..<11 { await model.tickEntryQR() }
        XCTAssertEqual(model.entrySecondsLeft, 1)
        XCTAssertEqual(model.rotatingCode?.payload, first)
        await model.tickEntryQR()
        XCTAssertNotEqual(model.rotatingCode?.payload, first)
        XCTAssertEqual(model.entrySecondsLeft, 12)
        XCTAssertTrue(model.isRefreshingQR)
        model.finishQRRefresh()
        XCTAssertFalse(model.isRefreshingQR)
    }

    func testTheRotatingCodeDrawsAReadableQR() async throws {
        let (model, _) = try await make()
        await model.loadEntryCode()
        let payload = try XCTUnwrap(model.rotatingCode?.payload)
        let image = try XCTUnwrap(EntryQRImage.make(payload)?.cgImage)
        let detector = try XCTUnwrap(CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: nil))
        let scaled = CIImage(cgImage: image).transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        let read = detector.features(in: scaled).compactMap { ($0 as? CIQRCodeFeature)?.messageString }
        XCTAssertEqual(read, [payload])
    }

    func testTheStaticCodeIsUnchangedForTheDoor() async throws {
        let (model, _) = try await make()
        await model.loadEntryCode()
        XCTAssertEqual(model.entryCode.value?.payload, "demo-entry-0238")
        XCTAssertEqual(model.entryCode.value?.lastFour, "0238")
    }

    func testAScanShowsOnTheQRPage() async throws {
        let (model, demo) = try await make()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        await model.load()
        _ = try await demo.recordEntry(EntryRequest(mealID: lunch.id, student: DemoSeed.sampleStudent, method: .typedLastFour,
                                                    idempotencyKey: IdempotencyKey("door")))
        await model.loadEntryCode()
        guard case .scanned = model.standing else { return XCTFail("Got \(model.standing)") }
    }

    func testTheQRStaysAvailableOfflineWithSavedTime() async throws {
        let (model, demo) = try await make()
        await demo.setScenario(.offline)
        await model.load()
        XCTAssertTrue(model.isOffline)
        XCTAssertNotNil(model.state.value)
        XCTAssertNotNil(model.lastLoadedAt)
        await model.loadEntryCode()
        XCTAssertNotNil(model.entryCode.value)
    }

    // MARK: Missing data

    func testNoExtrasLeavesHomeWorkingAndShowsMissingNotZero() async throws {
        let demo = DemoDataProvider(scenario: .storyStart, clock: FigmaClock())
        let repositories = Repositories(meals: demo, mealState: demo, headcount: demo, entries: demo, intentions: demo,
                                        shortages: demo, wasteReports: demo, sos: demo, auth: demo, specialPasses: demo)
        let model = try XCTUnwrap(StudentHomeViewModel(session: try session, repositories: repositories, clock: demo.clock))
        await model.load()
        let home = try content(model)
        XCTAssertNil(home.extras)
        XCTAssertEqual(StudentCopy.points(home.extras?.credits), "— pts")
        XCTAssertEqual(home.answerRow?.meal.slot, .lunch)
    }

    func testAMenuFallsBackWithoutExtras() async throws {
        let demo = DemoDataProvider(scenario: .storyStart, clock: FigmaClock())
        let repositories = Repositories(meals: demo, mealState: demo, headcount: demo, entries: demo, intentions: demo,
                                        shortages: demo, wasteReports: demo, sos: demo, auth: demo, specialPasses: demo)
        let model = try XCTUnwrap(StudentHomeViewModel(session: try session, repositories: repositories, clock: demo.clock))
        await model.loadAnswerMenu(for: lunch.id)
        XCTAssertEqual(model.menu.value, DemoSeed.lunchMenu)
    }

    func testCutoffTextComesFromTheBackendNotTheFrame() {
        let row = StudentCopy.decideBy(StudentFormat.shortTime(IntentionPolicy.cutoff(for: lunch), in: DemoSeed.mess.timeZone), left: "3h")
        XCTAssertTrue(row.hasPrefix("Decide by 10 AM"))
        XCTAssertEqual(StudentFormat.compactLeft("1 h 50 min"), "1h 50m")
    }
}

/// Reads breakfast as unanswered, so the question case can be reached before its cutoff.
private struct EmptyBreakfast: IntentionRepository {
    let source: DemoDataProvider

    func response(of student: StudentID, for meal: MealID) async throws -> IntentionResponse {
        meal == DemoSeed.breakfast.id ? .noResponse : try await source.response(of: student, for: meal)
    }
    func setIntention(_ intention: MealIntention, of student: StudentID, for meal: MealID) async throws -> IntentionResponse {
        try await source.setIntention(intention, of: student, for: meal)
    }
    func answerCounts(for meal: MealID) async throws -> MealAnswerCounts { try await source.answerCounts(for: meal) }
}
#endif
