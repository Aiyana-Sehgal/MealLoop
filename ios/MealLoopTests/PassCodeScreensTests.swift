#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The student's Special pass and the Pass Desk sheet, side by side on one prototype backend with a test clock:
/// at the same instant they show the same code, colour and countdown (P-PASS-9 a).
@MainActor
final class PassCodeScreensTests: XCTestCase {
    private func world() -> (DemoDataProvider, DemoClock) {
        let clock = DemoClock(DemoSeed.duringMealNow)
        return (DemoDataProvider(scenario: .duringMeal, clock: clock), clock)
    }

    private func student(_ demo: DemoDataProvider, _ clock: DemoClock) async throws -> StudentPassViewModel {
        let account = try XCTUnwrap(DemoSeed.accounts.first { $0.role == .student })
        let session = Session(account: account, staff: nil,
                              student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
        let model = try XCTUnwrap(StudentPassViewModel(session: session, repositories: demo.makeRepositories(), clock: clock))
        await model.load()
        if !model.isLive {
            model.beginConfirm()
            _ = await model.confirmHold()
        }
        return model
    }

    private func desk(_ demo: DemoDataProvider, _ clock: DemoClock) async -> PassDeskHomeViewModel {
        let staff = StaffSession(role: .passDesk, mess: DemoSeed.mess, staffInitials: DemoSeed.staffInitials(for: .passDesk),
                                 supervisorName: DemoSeed.supervisorName)
        let home = PassDeskHomeViewModel(session: staff, repositories: demo.makeRepositories(), clock: clock)
        await home.load()
        return home
    }

    func testThePhoneAndTheDeskShowTheSameCodeColourAndCountdown() async throws {
        let (demo, clock) = world()
        let phone = try await student(demo, clock)
        let desk = await desk(demo, clock)
        let phoneCode = try XCTUnwrap(phone.liveCode)
        let deskCode = try XCTUnwrap(desk.code.current)
        XCTAssertEqual(phoneCode.code, deskCode.live.code)
        XCTAssertEqual(phoneCode.colourName, deskCode.live.colourName)
        XCTAssertEqual(phoneCode.changesAt, deskCode.live.changesAt)
        XCTAssertEqual(phone.secondsLeft, desk.code.secondsLeft)
    }

    func testAfterTheBoundaryBothMoveToTheSameNextCode() async throws {
        let (demo, clock) = world()
        let phone = try await student(demo, clock)
        let desk = await desk(demo, clock)
        let first = try XCTUnwrap(phone.liveCode)
        clock.set(first.changesAt)
        await phone.refreshCode()
        while (desk.code.secondsLeft ?? 0) > 1 { await desk.code.tick() }
        await desk.code.tick()
        let phoneNext = try XCTUnwrap(phone.liveCode)
        XCTAssertNotEqual(phoneNext.code, first.code)
        XCTAssertEqual(desk.code.current?.live.code, phoneNext.code)
        XCTAssertEqual(desk.code.current?.live.colourName, phoneNext.colourName)
    }

    func testTheHoldRecordsOnceAndTheDeskRecordsNothing() async throws {
        let (demo, clock) = world()
        let desk = await desk(demo, clock)
        for _ in 0..<5 { await desk.code.tick() }
        let before = try await demo.specialMealEntries(for: DemoSeed.lunch.id).count
        XCTAssertEqual(before, 0, "Showing the code records nothing")
        _ = try await student(demo, clock)
        let after = try await demo.specialMealEntries(for: DemoSeed.lunch.id).count
        XCTAssertEqual(after, 1, "The student's hold is the entry")
    }
}
#endif
