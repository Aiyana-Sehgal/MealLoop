#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

private final class ScreensClock: StoryClock, @unchecked Sendable {
    private var current = Date(timeIntervalSince1970: 0)
    func now() -> Date { current }
    func set(_ date: Date) { current = date }
}

/// Forwards to the prototype backend, and can lose the connection or the crowd data on demand.
private final class SwitchableMeals: StudentMealsRepository, @unchecked Sendable {
    let source: DemoDataProvider
    var isOffline = false
    var crowdHasNoSlots = false
    var startFails = false

    init(_ source: DemoDataProvider) { self.source = source }

    private func check() throws {
        if isOffline { throw RepositoryError.offline(lastSavedAt: nil) }
    }

    func week(for mess: MessID) async throws -> StudentWeek { try check(); return try await source.week(for: mess) }
    func mealMenu(on day: Date, slot: MealSlot, mess: MessID) async throws -> StudentMealMenu {
        try check(); return try await source.mealMenu(on: day, slot: slot, mess: mess)
    }
    func dishDetail(_ dish: DishID, on day: Date, slot: MealSlot, mess: MessID) async throws -> StudentDishDetail {
        try check(); return try await source.dishDetail(dish, on: day, slot: slot, mess: mess)
    }
    func findDishes(_ text: String, mess: MessID) async throws -> [StudentDishMatch] {
        try check(); return try await source.findDishes(text, mess: mess)
    }
    func passStanding(of student: StudentID, at mess: MessID) async throws -> StudentPassStanding {
        try check(); return try await source.passStanding(of: student, at: mess)
    }
    func startPass(of student: StudentID, key: IdempotencyKey) async throws -> StudentPassStanding {
        try check()
        if startFails { throw RepositoryError.notFound }
        return try await source.startPass(of: student, key: key)
    }
    func crowd(at mess: MessID) async throws -> StudentCrowd {
        try check()
        let crowd = try await source.crowd(at: mess)
        guard crowdHasNoSlots else { return crowd }
        return StudentCrowd(meal: crowd.meal, observedAt: crowd.observedAt, level: crowd.level, detailTime: crowd.detailTime, slots: [],
                            currentSlot: nil, bestSlot: nil, waitNowMinutes: nil, busiestWaitMinutes: nil, busiestAt: nil)
    }
}

/// The Meals tab, Search, the Special pass and Crowd as rebuilt from the Figma frames.
@MainActor
final class StudentMealsScreensTests: XCTestCase {
    private let wednesday = DemoSeed.date(14, 0, 0)

    private var session: Session {
        get throws {
            Session(account: try XCTUnwrap(DemoSeed.accounts.first { $0.role == .student }), staff: nil,
                    student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
        }
    }

    private func make(at time: Date? = nil) throws -> (DemoDataProvider, SwitchableMeals, Repositories, ScreensClock) {
        let clock = ScreensClock()
        let demo = DemoDataProvider(scenario: .storyStart, clock: clock)
        if let time { clock.set(time) }
        let meals = SwitchableMeals(demo)
        var repositories = demo.makeRepositories()
        repositories.studentMeals = meals
        return (demo, meals, repositories, clock)
    }

    // MARK: Meals

    func testMealsOpensOnTodaysLunchAtStoryStart() async throws {
        let (_, _, repositories, clock) = try make()
        let model = try XCTUnwrap(StudentMealsViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        XCTAssertEqual(model.selectedDay, wednesday)
        XCTAssertEqual(model.selectedSlot, .lunch, "Breakfast's cutoff has passed at 7:00 AM; lunch is still open.")
        XCTAssertEqual(model.state.value?.highlight?.name, "Bhindi Aloo Bujjiya")
        XCTAssertNil(model.serviceEnded)
    }

    /// S5: the dish page lists the rest of its meal from the menu already loaded, never a menu it did not load.
    func testTheDishPageListsTheRestOfItsMealFromTheLoadedMenu() async throws {
        let (_, _, repositories, clock) = try make()
        let model = try XCTUnwrap(StudentMealsViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        let menu = try XCTUnwrap(model.state.value)
        let all = [menu.highlight].compactMap { $0 } + menu.mains + menu.curries + menu.slimRows
        let first = try XCTUnwrap(all.first)
        let others = model.otherDishes(than: first.id, day: menu.day, slot: menu.slot)
        XCTAssertEqual(others.map(\.id), all.dropFirst().map(\.id), "Every other dish of the meal, in menu order.")
        XCTAssertFalse(others.contains { $0.id == first.id })
        let otherDay = menu.day.addingTimeInterval(86_400 * 3)
        XCTAssertTrue(model.otherDishes(than: first.id, day: otherDay, slot: menu.slot).isEmpty,
                      "A menu that was not loaded lists nothing.")
    }

    func testAfterLunchTheMealsTabSaysServiceEndedAndWhenDinnerOpens() async throws {
        let (_, _, repositories, clock) = try make(at: DemoSeed.time(14, 10))
        let model = try XCTUnwrap(StudentMealsViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        XCTAssertEqual(model.selectedSlot, .dinner, "At 2:10 PM the dinner answer is still open, so it leads.")
        await model.select(slot: .lunch)
        let ended = try XCTUnwrap(model.serviceEnded)
        XCTAssertEqual(ended.slot, .lunch)
        XCTAssertEqual(ended.next?.slot, .dinner, "Snacks have no time, so dinner is the next meal that opens.")
        XCTAssertEqual(ended.next?.from, DemoSeed.dinner.startsAt)
        await model.select(day: DemoSeed.date(15, 0, 0))
        XCTAssertNil(model.serviceEnded, "Only today's meals can have ended.")
    }

    func testAMenuAlreadyShownStaysWhenTheConnectionDrops() async throws {
        let (_, meals, repositories, clock) = try make()
        let model = try XCTUnwrap(StudentMealsViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        meals.isOffline = true
        await model.load()
        guard case .offline(let menu?, let savedAt) = model.state else { return XCTFail("Offline with the saved menu") }
        XCTAssertEqual(menu.slot, .lunch)
        XCTAssertEqual(savedAt, DemoSeed.storyStartNow)
        await model.select(slot: .dinner)
        guard case .offline(nil, _) = model.state else { return XCTFail("A meal never shown has nothing saved") }
    }

    // MARK: Search

    func testSearchNarrowsByNameAndShowsTheEmptyResult() async throws {
        let (_, _, repositories, _) = try make()
        let model = try XCTUnwrap(StudentSearchViewModel(session: try session, repositories: repositories))
        model.text = "sambar"
        await model.search()
        let wide = try XCTUnwrap(model.state.value)
        XCTAssertTrue(wide.allSatisfy { $0.dish.name.localizedCaseInsensitiveContains("sambar") })

        model.text = "masala sambar"
        await model.search()
        let narrow = try XCTUnwrap(model.state.value)
        XCTAssertLessThan(narrow.count, wide.count)

        model.text = "biryani"
        await model.search()
        guard case .empty = model.state else { return XCTFail("No dish is called biryani on the board") }
        XCTAssertEqual(model.searchedText, "biryani")
        XCTAssertEqual(MealsCopy.noResults(model.searchedText), "No results for \"biryani\"")

        model.clear()
        guard case .idle = model.state else { return XCTFail("Clearing goes back to the start") }
    }

    func testSearchOfflineIsNeverAnEmptyResult() async throws {
        let (_, meals, repositories, _) = try make()
        meals.isOffline = true
        let model = try XCTUnwrap(StudentSearchViewModel(session: try session, repositories: repositories))
        model.text = "sambar"
        await model.search()
        guard case .offline = model.state else { return XCTFail("Offline, not no results") }
    }

    // MARK: Special pass

    func testHoldingStartsTheLiveCodeWhichRotatesWithItsColour() async throws {
        let (_, _, repositories, clock) = try make(at: DemoSeed.time(12, 32))
        let model = try XCTUnwrap(StudentPassViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        guard case .available? = model.state.value else { return XCTFail("Available") }
        model.beginConfirm()
        let started = await model.confirmHold()
        XCTAssertTrue(started)
        XCTAssertTrue(model.isLive)
        let first = try XCTUnwrap(model.liveCode)
        XCTAssertEqual(model.secondsLeft, Int(DemoSeed.passCodeWindow))
        for _ in 0..<Int(DemoSeed.passCodeWindow) - 1 { await model.tick() }
        XCTAssertEqual(model.secondsLeft, 1)
        XCTAssertEqual(model.liveCode, first, "The code holds for its whole window.")
        // The code follows the clock (P-PASS-9 a): it changes when time crosses the window, not because of a tick.
        clock.set(first.changesAt)
        await model.tick()
        let second = try XCTUnwrap(model.liveCode)
        XCTAssertNotEqual(second.code, first.code)
        XCTAssertNotEqual(second.colourName, first.colourName)
        XCTAssertEqual(model.secondsLeft, Int(DemoSeed.passCodeWindow))
    }

    func testAFailedHoldSaysSoAndKeepsThePassAvailable() async throws {
        let (demo, _, repositories, clock) = try make()
        let model = try XCTUnwrap(StudentPassViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        // The hold is the use (owner ruling, Prompt 2B); losing the connection makes it fail, and nothing is used.
        await demo.setScenario(.offline)
        model.beginConfirm()
        let started = await model.confirmHold()
        XCTAssertFalse(started)
        XCTAssertEqual(model.phase, .failed)
        guard case .available? = model.state.value else { return XCTFail("Nothing was used") }
        XCTAssertNil(model.liveCode)
    }

    // Owner ruling (Prompt 2B): the hold is the entry; In use for the backend's validity, then Used for good. This
    // replaces the test where the desk recorded the entry, which the ruling removed.

    func testATapAloneDoesNothing() async throws {
        let (demo, _, repositories, clock) = try make(at: DemoSeed.time(12, 32))
        let model = try XCTUnwrap(StudentPassViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        model.beginConfirm()
        guard case .available? = model.state.value else { return XCTFail("Still available") }
        let entries = try await demo.specialMealEntries(for: DemoSeed.lunch.id).count
        XCTAssertEqual(entries, 0)
    }

    func testTheHoldIsInUseForThirtySecondsThenUsedAndASecondHoldIsRefused() async throws {
        let start = DemoSeed.time(12, 32)
        let (_, _, repositories, clock) = try make(at: start)
        let model = try XCTUnwrap(StudentPassViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        model.beginConfirm()
        let held = await model.confirmHold()
        XCTAssertTrue(held)
        XCTAssertEqual(model.inUseSecondsLeft, Int(PassUsePolicy.validity))
        XCTAssertTrue(model.isLive)
        XCTAssertNotNil(model.liveCode, "In use shows the live code and colour")
        clock.set(start.addingTimeInterval(PassUsePolicy.validity - 1))
        await model.tick()
        XCTAssertNotNil(model.inUseSecondsLeft, "Still in use at 29 s")
        clock.set(start.addingTimeInterval(PassUsePolicy.validity + 1))
        await model.tick()
        XCTAssertNil(model.inUseSecondsLeft)
        XCTAssertFalse(model.isLive)
        XCTAssertNil(model.liveCode, "Used shows no code")
        guard case .used(_, _, true)? = model.state.value else { return XCTFail("Used, shown as the greyed ticket") }
        model.beginConfirm()
        let again = await model.confirmHold()
        XCTAssertFalse(again)
        XCTAssertEqual(model.holdError, "Already used")
    }

    func testAnExpiredPassShowsTheNextMealAndTheCrowd() async throws {
        let (demo, _, repositories, clock) = try make()
        _ = try await demo.startMeal(DemoSeed.lunch.id, by: .supervisor)
        _ = try await demo.closeMeal(DemoSeed.lunch.id, by: .supervisor)
        let model = try XCTUnwrap(StudentPassViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        guard case .expired(_, let endedAt)? = model.state.value else { return XCTFail("Expired") }
        XCTAssertEqual(MealsCopy.expired(MLFormat.time(endedAt, in: model.timeZone)), "Pass expired · ended 2:00 PM")
        XCTAssertFalse(model.state.value?.showsTicket ?? true)
        XCTAssertEqual(model.nextMeal?.meal, DemoSeed.dinner)
        XCTAssertEqual(model.nextMeal?.dishes.count, 5)
        XCTAssertNotNil(model.crowd)
    }

    func testAnOfflinePassIsUnavailableNeverNotEligible() async throws {
        let (_, meals, repositories, clock) = try make()
        meals.isOffline = true
        let model = try XCTUnwrap(StudentPassViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        guard case .failed = model.state else { return XCTFail("Couldn't load your pass") }
    }

    // MARK: Crowd

    func testTheCrowdIsLabelledAnEstimateAndKeepsItsTimeOffline() async throws {
        let (_, meals, repositories, _) = try make()
        let model = try XCTUnwrap(StudentCrowdViewModel(session: try session, repositories: repositories))
        await model.load()
        let crowd = try XCTUnwrap(model.state.value)
        XCTAssertEqual(CrowdBody.eyebrow(crowd, isOffline: false, timeZone: model.timeZone), "Lunch · 7:00 AM · ESTIMATE")

        meals.isOffline = true
        await model.load()
        guard case .offline(let kept?, let savedAt) = model.state else { return XCTFail("Offline keeps the last reading") }
        XCTAssertEqual(savedAt, kept.observedAt)
        XCTAssertEqual(CrowdBody.eyebrow(kept, isOffline: true, timeZone: model.timeZone), "Lunch · Updated 7:00 AM")
        XCTAssertEqual(MealsCopy.levelAt(kept.level, time: "7:00"), "Quiet at 7:00")
    }

    func testTooFewEntriesIsAnHonestEmptyStateNotZero() async throws {
        let (_, meals, repositories, _) = try make()
        meals.crowdHasNoSlots = true
        let model = try XCTUnwrap(StudentCrowdViewModel(session: try session, repositories: repositories))
        await model.load()
        guard case .empty = model.state else { return XCTFail("Not enough entries yet") }
    }

    func testAnUnbuiltCrowdServiceSaysSoAndNeverShowsAReading() async throws {
        let (demo, _, _, _) = try make()
        var repositories = demo.makeRepositories()
        repositories.studentMeals = UnavailableStudentMeals()
        let model = try XCTUnwrap(StudentCrowdViewModel(session: try session, repositories: repositories))
        await model.load()
        guard case .failed(let failure) = model.state else { return XCTFail("Failed") }
        XCTAssertTrue(failure.isNotImplemented)
    }
}
#endif
