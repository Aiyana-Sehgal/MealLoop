#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The additive Student You operations on the prototype backend: notifications, credits and attendance.
final class StudentYouRepositoryTests: XCTestCase {
    private let aarav = DemoSeed.sampleStudent.id
    private let stranger = StudentID("demo-student-unknown")
    private let mess = DemoSeed.mess.id

    private func make() -> (DemoDataProvider, any StudentYouRepository) {
        let demo = DemoDataProvider(scenario: .storyStart)
        return (demo, demo.makeRepositories().studentYou)
    }

    func testNotificationsNewestFirstWithTheirReadState() async throws {
        let (_, you) = make()
        let notes = try await you.notifications(for: aarav)
        XCTAssertEqual(notes.map(\.title), ["Guardian approved", "Breakfast today?", "Feedback seen", "Special pass"])
        XCTAssertEqual(notes.map(\.isRead), [false, false, true, true])
    }

    func testMarkingReadIsKeptAndRepeatsChangeNothing() async throws {
        let (_, you) = make()
        let id = StudentNotificationID("demo-note-guardian-approved")
        let first = try await you.markRead(id, for: aarav)
        XCTAssertTrue(first.isRead)
        _ = try await you.markRead(id, for: aarav)
        let notes = try await you.notifications(for: aarav)
        XCTAssertEqual(notes.filter { !$0.isRead }.map(\.title), ["Breakfast today?"])
    }

    func testAStudentWithNoNotificationsGetsAnEmptyList() async throws {
        let (_, you) = make()
        let notes = try await you.notifications(for: stranger)
        XCTAssertTrue(notes.isEmpty)
    }

    func testTheRuleEarnsForDefiniteAnswersOnly() {
        let at = DemoSeed.storyStartNow
        XCTAssertEqual(StudentCreditRule.points(for: .answered(.attending, at: at), perDefiniteAnswer: 5), 5)
        XCTAssertEqual(StudentCreditRule.points(for: .answered(.skipping, at: at), perDefiniteAnswer: 5), 5)
        XCTAssertEqual(StudentCreditRule.points(for: .answered(.notSure, at: at), perDefiniteAnswer: 5), 0)
        XCTAssertEqual(StudentCreditRule.points(for: .noResponse, perDefiniteAnswer: 5), 0)
    }

    func testTheSampleBalanceBeforeAnyAnswerInThisRun() async throws {
        let (_, you) = make()
        let credits = try await you.credits(for: aarav)
        XCTAssertEqual(credits.balance, 120)
        XCTAssertEqual(credits.nextGoal?.ticket.name, "Biryani coupon")
        XCTAssertEqual(credits.nextGoal?.missing, 80)
    }

    func testADefiniteAnswerEarnsAndNotSureEarnsNothing() async throws {
        let (demo, you) = make()
        _ = try await demo.setIntention(.notSure, of: aarav, for: DemoSeed.lunch.id)
        let notSure = try await you.credits(for: aarav)
        XCTAssertEqual(notSure.balance, 120, "Not sure earns nothing.")
        _ = try await demo.setIntention(.attending, of: aarav, for: DemoSeed.lunch.id)
        let attending = try await you.credits(for: aarav)
        XCTAssertEqual(attending.balance, 125)
        XCTAssertEqual(attending.history.first?.title, "Answered lunch")
        XCTAssertEqual(attending.history.first?.points, 5)
        _ = try await demo.setIntention(.skipping, of: aarav, for: DemoSeed.dinner.id)
        let skipping = try await you.credits(for: aarav)
        XCTAssertEqual(skipping.balance, 130, "Skip is a definite answer too.")
    }

    func testAnUnknownStudentHasNoBalanceRatherThanZero() async throws {
        let (_, you) = make()
        let credits = try await you.credits(for: stranger)
        XCTAssertNil(credits.balance)
        XCTAssertNil(credits.nextGoal)
        let profile = try await you.profile(for: stranger, at: mess)
        XCTAssertNil(profile.credits)
    }

    func testAttendanceComputesTheShareAndStreakFromTheMarks() async throws {
        let (_, you) = make()
        let month = try await you.attendance(for: aarav, at: mess)
        XCTAssertEqual(month.mealsEntered, 36)
        XCTAssertEqual(month.mealsServed, 41)
        XCTAssertEqual(month.percentEntered, 88)
        XCTAssertEqual(month.bestStreak, 4)
        XCTAssertEqual(month.marks[3], .noEntryForAMeal, "A missing entry is recorded as no entry, never as absent.")
        XCTAssertNil(month.marks[20])
    }

    func testMissingAttendanceCountsAreMissingNotZero() async throws {
        let (_, you) = make()
        let month = try await you.attendance(for: stranger, at: mess)
        XCTAssertNil(month.mealsEntered)
        XCTAssertNil(month.percentEntered)
        XCTAssertTrue(month.marks.isEmpty)
    }

    func testOfflineIsAnErrorNotAnEmptyInbox() async throws {
        let demo = DemoDataProvider(scenario: .offline)
        let you = demo.makeRepositories().studentYou
        do {
            _ = try await you.notifications(for: aarav)
            XCTFail("Offline must throw.")
        } catch RepositoryError.offline {
        }
    }

    func testASourceWithoutTheServiceSaysSo() async {
        do {
            _ = try await UnavailableStudentYou().credits(for: aarav)
            XCTFail("Must throw.")
        } catch RepositoryError.notImplemented {
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }
}
#endif
