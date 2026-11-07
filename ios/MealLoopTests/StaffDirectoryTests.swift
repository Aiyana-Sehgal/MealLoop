#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

final class StaffDirectoryTests: XCTestCase {
    private func repositories() -> Repositories {
        DemoDataProvider(scenario: .duringMeal, clock: DemoClock(DemoSeed.storyStartNow)).makeRepositories()
    }

    func testASeededStudentHasTheirName() async throws {
        let name = try await repositories().staffDirectory.studentName(DemoSeed.sampleStudent.id)
        XCTAssertEqual(name, "Aarav")
    }

    func testAnUnknownStudentHasNoNameRatherThanAMadeUpOne() async throws {
        let name = try await repositories().staffDirectory.studentName(StudentID("nobody"))
        XCTAssertNil(name)
    }

    func testTheShiftTimeIsTheLabelledSampleForTheDoorAndDesk() async throws {
        let directory = repositories().staffDirectory
        let door = try await directory.shiftStartedAt(for: .doorScanner, mess: DemoSeed.mess.id)
        let desk = try await directory.shiftStartedAt(for: .passDesk, mess: DemoSeed.mess.id)
        XCTAssertEqual(door, DemoSeed.deskShiftStartedAt)
        XCTAssertEqual(desk, DemoSeed.deskShiftStartedAt)
    }

    func testOtherRolesHaveNoShiftTime() async throws {
        let time = try await repositories().staffDirectory.shiftStartedAt(for: .supervisor, mess: DemoSeed.mess.id)
        XCTAssertNil(time)
    }

    func testOnlyTheWaitingRequestNamesAReason() {
        let reasons = DemoSeed.sampleReissues.map { $0.status == .waiting ? $0.reason : nil }
        XCTAssertEqual(DemoSeed.sampleReissues.first { $0.status == .waiting }?.reason, .phoneLost)
        XCTAssertEqual(DemoSeed.sampleReissues.compactMap(\.reason).count, reasons.compactMap { $0 }.count)
    }

    func testTheDefaultSourceAnswersNothing() async throws {
        let directory = UnavailableStaffDirectory()
        let name = try await directory.studentName(DemoSeed.sampleStudent.id)
        let time = try await directory.shiftStartedAt(for: .doorScanner, mess: DemoSeed.mess.id)
        XCTAssertNil(name)
        XCTAssertNil(time)
    }
}
#endif
