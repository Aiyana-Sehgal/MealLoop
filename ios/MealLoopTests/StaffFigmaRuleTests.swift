#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The product rules the Figma pass touched. The frame wins on looks, never on these.
@MainActor
final class StaffFigmaRuleTests: XCTestCase {
    private func world(_ scenario: DemoScenario = .duringMeal) -> (demo: DemoDataProvider, clock: DemoClock, repositories: Repositories) {
        let clock = DemoClock(DemoSeed.storyStartNow)
        let demo = DemoDataProvider(scenario: scenario, clock: clock)
        return (demo, clock, demo.makeRepositories())
    }

    private func session(_ role: Role) -> StaffSession {
        StaffSession(role: role, mess: DemoSeed.mess, staffInitials: DemoSeed.staffInitials(for: role),
                     supervisorName: DemoSeed.supervisorName)
    }

    private func type(_ digits: [Int], into flow: DoorEntryFlow) async {
        for digit in digits { await flow.append(digit) }
    }

    func testAMatchShowsTheNameAndStillRecordsNothing() async throws {
        let world = world()
        let before = try await world.repositories.entries.liveCount(for: DemoSeed.lunch.id).value
        let flow = DoorEntryFlow(meal: DemoSeed.lunch.id, mess: DemoSeed.mess.id, repositories: world.repositories)
        await type([0, 2, 3, 8], into: flow)
        XCTAssertEqual(flow.lookup, .match(DemoSeed.sampleStudent))
        XCTAssertEqual(flow.names[DemoSeed.sampleStudent.id], "Aarav")
        XCTAssertNil(flow.outcome)
        let after = try await world.repositories.entries.liveCount(for: DemoSeed.lunch.id).value
        XCTAssertEqual(after, before, "A lookup never records")
    }

    func testAStudentLineWithNoNameShowsTheMaskedIDAlone() {
        XCTAssertEqual(DoorScannerCopy.studentLine(DemoSeed.sampleStudent, name: nil), DemoSeed.sampleStudent.maskedID)
        XCTAssertEqual(DoorScannerCopy.studentLine(DemoSeed.sampleStudent, name: "Aarav"), "Aarav \(DemoSeed.sampleStudent.maskedID)")
    }

    func testAnOfflineLookupIsNeverAMatchAndNeverRecorded() async {
        let world = world()
        let flow = DoorEntryFlow(meal: DemoSeed.lunch.id, mess: DemoSeed.mess.id, repositories: world.repositories)
        await type([0, 2, 3], into: flow)
        await world.demo.setScenario(.offline)
        await flow.append(8)
        XCTAssertEqual(flow.lookup, .offline)
        XCTAssertNil(flow.outcome)
        XCTAssertTrue(flow.names.isEmpty)
    }

    func testWithoutVotingListsTheNameFromTheDirectory() async throws {
        let world = world()
        let flow = DoorEntryFlow(meal: DemoSeed.lunch.id, mess: DemoSeed.mess.id, repositories: world.repositories)
        await type([0, 2, 3, 8], into: flow)
        await flow.recordMatch()
        let model = DoorWithoutVotingViewModel(entries: world.repositories.entries, meal: DemoSeed.lunch.id,
                                               directory: world.repositories.staffDirectory)
        await model.load()
        XCTAssertEqual(model.names[DemoSeed.sampleStudent.id], "Aarav")
    }

    func testReportsThatStayOnThePhoneNeverClaimDelivery() {
        let lines = [DoorScannerCopy.pickOne, DoorScannerCopy.sentOnTap, DoorScannerCopy.savedToast, DoorScannerCopy.savedLine,
                     DoorScannerCopy.savedOnPhone, PassDeskCopy.pickOne, PassDeskCopy.sentOnTap, PassDeskCopy.savedToast,
                     PassDeskCopy.savedLine]
        for line in lines {
            XCTAssertFalse(line.lowercased().contains("sent"), line)
            XCTAssertFalse(line.contains(DemoSeed.supervisorName), line)
        }
    }

    func testOnlyFoodShortIsMarkedDelivered() async {
        let world = world()
        let log = PassDeskProblemLog(session: session(.passDesk), repositories: world.repositories, clock: world.clock)
        _ = await log.report(.crowd)
        XCTAssertEqual(log.problems.first?.isDelivered, false)
        _ = await log.reportFoodShort(DemoSeed.shortageDish, meal: DemoSeed.lunch.id)
        XCTAssertEqual(log.problems.first?.isDelivered, true)
    }

    func testTheShiftTimeShowsOnlyOnceItHasBegun() async {
        let world = world()
        let model = DoorHomeViewModel(session: session(.doorScanner), repositories: world.repositories, clock: world.clock)
        world.clock.set(DemoSeed.time(11, 0))
        await model.load()
        XCTAssertNil(model.shiftStartedAt, "At 11:00 AM the 11:40 AM shift has not begun")
        world.clock.set(DemoSeed.time(12, 55))
        await model.load()
        XCTAssertEqual(model.shiftStartedAt, DemoSeed.deskShiftStartedAt)
    }

    func testTheDeskShiftTimeFollowsTheSameRule() async {
        let world = world()
        let model = PassDeskHomeViewModel(session: session(.passDesk), repositories: world.repositories, clock: world.clock)
        world.clock.set(DemoSeed.time(11, 0))
        await model.load()
        XCTAssertNil(model.shiftStartedAt)
        world.clock.set(DemoSeed.time(12, 55))
        await model.load()
        XCTAssertEqual(model.shiftStartedAt, DemoSeed.deskShiftStartedAt)
    }
}
#endif
