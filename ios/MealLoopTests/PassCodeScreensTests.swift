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

    private func desk(_ demo: DemoDataProvider, _ clock: DemoClock) async -> PassDeskCheckFlow {
        let staff = StaffSession(role: .passDesk, mess: DemoSeed.mess, staffInitials: DemoSeed.staffInitials(for: .passDesk),
                                 supervisorName: DemoSeed.supervisorName)
        let home = PassDeskHomeViewModel(session: staff, repositories: demo.makeRepositories(), clock: clock)
        await home.load()
        for digit in [0, 2, 3, 8] { await home.flow.type(digit) }
        return home.flow
    }

    func testThePhoneAndTheDeskShowTheSameCodeColourAndCountdown() async throws {
        let (demo, clock) = world()
        let phone = try await student(demo, clock)
        let sheet = await desk(demo, clock)
        let phoneCode = try XCTUnwrap(phone.liveCode)
        let deskCompare = try XCTUnwrap(sheet.compare)
        XCTAssertEqual(phoneCode.code, deskCompare.live.code)
        XCTAssertEqual(phoneCode.colourName, deskCompare.live.colourName)
        XCTAssertEqual(phoneCode.changesAt, deskCompare.live.changesAt)
        XCTAssertEqual(phone.secondsLeft, deskCompare.secondsLeft)
    }

    func testAfterTheBoundaryBothMoveToTheSameNextCode() async throws {
        let (demo, clock) = world()
        let phone = try await student(demo, clock)
        let sheet = await desk(demo, clock)
        let first = try XCTUnwrap(phone.liveCode)
        clock.set(first.changesAt)
        await phone.refreshCode()
        while sheet.compare?.secondsLeft ?? 0 > 1 { await sheet.tick() }
        await sheet.tick()
        let phoneNext = try XCTUnwrap(phone.liveCode)
        XCTAssertNotEqual(phoneNext.code, first.code)
        XCTAssertEqual(sheet.compare?.live.code, phoneNext.code)
        XCTAssertEqual(sheet.compare?.live.colourName, phoneNext.colourName)
    }

    func testTheCodeOnThePhoneRecordsAtTheDeskOnceAndLookingRecordsNothing() async throws {
        let (demo, clock) = world()
        _ = try await student(demo, clock)
        let sheet = await desk(demo, clock)
        let before = try await demo.specialMealEntries(for: DemoSeed.lunch.id).count
        XCTAssertEqual(before, 0, "Typing the digits and showing the sheet records nothing")
        await sheet.matches()
        guard case .verified? = sheet.outcome else { return XCTFail("\(String(describing: sheet.outcome))") }
        let after = try await demo.specialMealEntries(for: DemoSeed.lunch.id).count
        XCTAssertEqual(after, 1)
    }
}
#endif
