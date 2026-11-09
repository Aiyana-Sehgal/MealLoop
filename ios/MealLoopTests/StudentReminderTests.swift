#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// G2 swipe-to-remind (2222:158038 to 2222:158543): local, simulated, read from the story clock, never past the cutoff.
@MainActor
final class StudentReminderTests: XCTestCase {
    private let seven = DemoSeed.time(7, 0)

    private func lunch(_ response: IntentionResponse = .noResponse, open: Bool = true) -> StudentMealCard {
        StudentMealCard(meal: DemoSeed.lunch, response: response, isAnswerOpen: open,
                        cutoff: IntentionPolicy.cutoff(for: DemoSeed.lunch))
    }

    func testSetIsNowPlusOneHourAndShowsTheExactTime() {
        let reminders = StudentMealReminders()
        let at = reminders.set(lunch(), now: seven)
        XCTAssertEqual(at, DemoSeed.time(8, 0))
        XCTAssertEqual(reminders.state(for: lunch(), now: seven), .set(at: DemoSeed.time(8, 0)))
        XCTAssertEqual(MLFormat.time(DemoSeed.time(8, 0), in: DemoSeed.mess.timeZone), "8:00 AM")
        XCTAssertEqual(ReminderCopy.setLabel("8:00 AM"), "Reminder set, we'll ask again at 8:00 AM")
    }

    func testUndoRestoresTheCard() {
        let reminders = StudentMealReminders()
        reminders.set(lunch(), now: seven)
        reminders.undo(DemoSeed.lunch.id)
        XCTAssertEqual(reminders.state(for: lunch(), now: seven), .none)
    }

    func testItFiresWhenTheAppClockReachesTheTimeAndNotBefore() {
        let reminders = StudentMealReminders()
        reminders.set(lunch(), now: seven)
        XCTAssertEqual(reminders.state(for: lunch(), now: DemoSeed.time(7, 59)), .set(at: DemoSeed.time(8, 0)))
        XCTAssertEqual(reminders.state(for: lunch(), now: DemoSeed.time(8, 0)), .fired)
        XCTAssertEqual(reminders.state(for: lunch(), now: DemoSeed.time(8, 30)), .fired)
    }

    /// The cutoff is 10:00 AM for lunch at 12. A reminder never extends it.
    func testTheCutoffGuard() {
        let reminders = StudentMealReminders()
        XCTAssertTrue(reminders.canOffer(lunch(), now: DemoSeed.time(8, 59)))
        XCTAssertFalse(reminders.canOffer(lunch(), now: DemoSeed.time(9, 0)), "Now + 1 hour at the cutoff: not offered.")
        XCTAssertNil(reminders.set(lunch(), now: DemoSeed.time(9, 30)))
        XCTAssertFalse(reminders.canOffer(lunch(open: false), now: seven), "Closed answers: not offered.")
        let breakfast = StudentMealCard(meal: DemoSeed.breakfast, response: .noResponse, isAnswerOpen: false,
                                        cutoff: IntentionPolicy.cutoff(for: DemoSeed.breakfast))
        XCTAssertFalse(reminders.canOffer(breakfast, now: seven), "Breakfast's cutoff (5:30 AM) has passed at 7:00.")
    }

    func testAnsweringCancelsIt() {
        let reminders = StudentMealReminders()
        reminders.set(lunch(), now: seven)
        let answered = lunch(.answered(.attending, at: seven))
        XCTAssertEqual(reminders.state(for: answered, now: DemoSeed.time(8, 0)), .none)
        reminders.cancelAnswered([answered])
        XCTAssertNil(reminders.times[DemoSeed.lunch.id])
        XCTAssertFalse(reminders.canOffer(lunch(.answered(.notSure, at: seven)), now: seven), "Not sure is an answer.")
    }

    func testASecondReminderReplacesTheFirst() {
        let reminders = StudentMealReminders()
        reminders.set(lunch(), now: seven)
        reminders.set(lunch(), now: DemoSeed.time(7, 30))
        XCTAssertEqual(reminders.times.count, 1)
        XCTAssertEqual(reminders.times[DemoSeed.lunch.id], DemoSeed.time(8, 30))
    }

    /// The accessibility action and the context-menu item call the same `onRemind` as the swipe, which sets this.
    func testTheAccessibilityActionEqualsTheSwipe() {
        let swiped = StudentMealReminders()
        let viaAction = StudentMealReminders()
        var called: [StudentMealCard] = []
        let body = StudentHomeBody(content: StudentHomeContent(today: seven, hero: lunch(), nextMeal: nil),
                                   mess: DemoSeed.mess.name, timeZone: DemoSeed.mess.timeZone, isOffline: false, savedAt: nil,
                                   heroAnswerState: .unanswered, onAnswer: { _ in }, onShowEntry: {}, onOpenAnswer: { _ in },
                                   onRemind: { called.append($0); viaAction.set($0, now: self.seven) })
        swiped.set(lunch(), now: seven)
        body.onRemind(lunch())
        XCTAssertEqual(called.count, 1)
        XCTAssertEqual(swiped.times, viaAction.times)
        XCTAssertEqual(ReminderCopy.remindAction, "Remind me in 1 hour")
    }

    func testARemindersEarnsNoCreditsAndSendsNothing() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        let repositories = demo.makeRepositories()
        let before = try await repositories.studentYou.credits(for: DemoSeed.sampleStudent.id).balance
        let reminders = StudentMealReminders()
        reminders.set(lunch(), now: seven)
        let after = try await repositories.studentYou.credits(for: DemoSeed.sampleStudent.id).balance
        XCTAssertEqual(before, after)
    }
}
#endif
