#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// Notifications, You, Credits and Attendance screen state, read from the prototype backend.
@MainActor
final class StudentYouScreensTests: XCTestCase {
    private var session: Session {
        get throws {
            Session(account: try XCTUnwrap(DemoSeed.accounts.first { $0.role == .student }), staff: nil,
                    student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
        }
    }

    private func make(_ scenario: DemoScenario = .storyStart) throws -> (DemoDataProvider, StudentYouViewModel) {
        let demo = DemoDataProvider(scenario: scenario)
        let model = try XCTUnwrap(StudentYouViewModel(session: try session, repositories: demo.makeRepositories(),
                                                      clock: demo.clock))
        return (demo, model)
    }

    func testTheHomeBellAndTheYouTabOpenTheirOwnScreens() throws {
        XCTAssertNotEqual(StudentHomeRoute.notifications, StudentHomeRoute.comingSoon(StudentCopy.notifications),
                          "The bell opens Notifications, not Coming soon.")
        XCTAssertTrue(StudentTab.pillTabs.contains(.you))
        XCTAssertNotNil(StudentYouViewModel(session: try session, repositories: DemoDataProvider().makeRepositories(),
                                            clock: SystemClock()), "The You tab builds its screen for a student.")
    }

    func testAStaffSessionGetsNoYouModel() throws {
        let staff = try XCTUnwrap(DemoSeed.accounts.first { $0.role == .supervisor })
        XCTAssertNil(StudentYouViewModel(session: Session(account: staff, staff: nil), repositories: DemoDataProvider().makeRepositories(),
                                         clock: SystemClock()))
    }

    func testNotificationsComeFromTheRepositoryGroupedByDay() async throws {
        let (_, model) = try make()
        await model.loadNotifications()
        XCTAssertEqual(model.notificationGroups.today.map(\.title), ["Guardian approved", "Breakfast today?"])
        XCTAssertEqual(model.notificationGroups.earlier.map(\.title), ["Feedback seen", "Special pass"])
    }

    func testOpeningANotificationMarksItReadInTheRepository() async throws {
        let (demo, model) = try make()
        await model.loadNotifications()
        let first = try XCTUnwrap(model.notifications.value?.first)
        await model.open(first)
        XCTAssertEqual(model.notifications.value?.first?.isRead, true)
        let stored = try await demo.makeRepositories().studentYou.notifications(for: DemoSeed.sampleStudent.id)
        XCTAssertEqual(stored.first?.isRead, true, "The read state is the repository's, not the screen's.")
    }

    func testOfflineNotificationsAreNeverShownAsAnEmptyInbox() async throws {
        let (_, model) = try make(.offline)
        await model.loadNotifications()
        guard case .offline(nil, _) = model.notifications else { return XCTFail("Expected offline, got \(model.notifications)") }
    }

    func testCreditsFollowTheAnswerOnHome() async throws {
        let (demo, model) = try make()
        _ = try await demo.setIntention(.attending, of: DemoSeed.sampleStudent.id, for: DemoSeed.lunch.id)
        await model.loadCredits()
        XCTAssertEqual(model.credits.value?.balance, 125)
        await model.loadProfile()
        XCTAssertEqual(model.profile.value?.credits, 125, "The You row shows the same balance.")
    }

    func testAttendanceStatesItsSampleCountsAndNoAbsence() async throws {
        let (_, model) = try make()
        await model.loadAttendance()
        let month = try XCTUnwrap(model.attendance.value)
        XCTAssertEqual(YouCopy.mealsOf(try XCTUnwrap(month.mealsEntered), try XCTUnwrap(month.mealsServed)), "36 of 41 meals")
        XCTAssertFalse(YouCopy.noEntry.localizedCaseInsensitiveContains("missed"))
        XCTAssertFalse(YouCopy.noEntry.localizedCaseInsensitiveContains("absent"))
    }
}
#endif
