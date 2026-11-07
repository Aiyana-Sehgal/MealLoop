#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The Student outing pages' state, read from the in-memory outing story.
@MainActor
final class StudentOutingScreensTests: XCTestCase {
    private var session: Session {
        get throws {
            Session(account: try XCTUnwrap(DemoSeed.accounts.first { $0.role == .student }), staff: nil,
                    student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
        }
    }

    private func make(_ repo: InMemoryOutingCaseRepository = InMemoryOutingCaseRepository()) throws -> StudentOutingsViewModel {
        try XCTUnwrap(StudentOutingsViewModel(session: try session, repository: repo))
    }

    func testTheYouRowOpensOutingsNotComingSoon() {
        XCTAssertNotEqual(StudentYouRoute.outings, StudentYouRoute.comingSoon(YouCopy.outings))
    }

    func testTheStatusLineComesFromTheRepositoryStage() async throws {
        let model = try make()
        await model.load()
        let current = try XCTUnwrap(model.outings.value?.current.first)
        XCTAssertEqual(OutingStudentCopy.status(current), "Waiting for your guardian")
        XCTAssertEqual(OutingStudentCopy.chip(OutingSeed.meeraRequest.stage), "Waiting for the warden")
    }

    func testTheWeekStartsOnMondayAndPastDaysCannotBePicked() async throws {
        let model = try make()
        await model.load()
        XCTAssertEqual(model.weekDays.count, 7)
        XCTAssertEqual(OutingFormat.weekday(model.weekDays[0]), "Mon")
        XCTAssertTrue(model.isPast(model.weekDays[0]))
        XCTAssertEqual(model.selectedDay.map(OutingFormat.weekday), "Fri", "The first day not past is today.")
    }

    func testAnOpenRequestOnThePickedDayBlocksSending() async throws {
        let model = try make()
        await model.load()
        model.selectedDay = model.weekDays[5] // Saturday, which has the seeded request
        model.place = "Express Avenue Mall"
        XCTAssertNotNil(model.duplicate)
        XCTAssertFalse(model.canSend)
    }

    func testSendingAddsTheRequestAtWaitingForGuardian() async throws {
        let model = try make()
        await model.load()
        model.selectedDay = model.weekDays[6] // Sunday
        model.place = "Home, Tambaram"
        model.reason = "Family"
        XCTAssertTrue(model.canSend)
        let made = await model.sendRequest()
        XCTAssertEqual(made?.stage, .awaitingGuardian)
        XCTAssertEqual(model.outings.value?.current.count, 2)
        XCTAssertEqual(model.place, "", "The form clears only after the repository recorded the request.")
    }

    func testAnOfflineSendIsNeverShownAsSent() async throws {
        let repo = InMemoryOutingCaseRepository()
        let model = try make(repo)
        await model.load()
        model.selectedDay = model.weekDays[6]
        model.place = "Home, Tambaram"
        await repo.setOffline(true)
        let made = await model.sendRequest()
        XCTAssertNil(made)
        if case .failed = model.send {} else { XCTFail("Offline must show a failure.") }
        XCTAssertEqual(model.place, "Home, Tambaram", "The form is kept.")
    }

    func testCancellingMarksTheRequestCancelled() async throws {
        let model = try make()
        await model.load()
        let id = OutingSeed.aaravRequest.id
        await model.loadDetail(id)
        let cancelled = await model.cancel(id)
        XCTAssertTrue(cancelled)
        XCTAssertEqual(model.detail.value?.stage, .withdrawn)
        XCTAssertTrue(model.outings.value?.current.isEmpty == true)
    }

    func testAStudentWithoutOutingsSeesNotEnabled() async throws {
        let other = StudentRef(id: StudentID("demo-student-unknown"), maskedID: "••0000")
        let session = Session(account: try XCTUnwrap(DemoSeed.accounts.first { $0.role == .student }), staff: nil,
                              student: StudentContext(student: other, mess: DemoSeed.mess))
        let model = try XCTUnwrap(StudentOutingsViewModel(session: session, repository: InMemoryOutingCaseRepository()))
        await model.load()
        XCTAssertEqual(model.outings.value?.eligibility, .notEnabled)
        XCTAssertFalse(model.canSend)
    }
}
#endif
