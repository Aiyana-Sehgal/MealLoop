#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// "Ravi saw it" appears only when the Supervisor has really seen the report.
final class ShortageSeenTests: XCTestCase {
    private let meal = DemoSeed.lunch.id

    private func reported() async throws -> (DemoDataProvider, Shortage) {
        let demo = DemoDataProvider(scenario: .duringMeal)
        let report = ShortageReport(mealID: meal, dishName: DemoSeed.shortageDish, level: .almostOut, note: nil,
                                    reportedBy: .kitchenStaff, idempotencyKey: .make())
        return (demo, try await demo.reportShortage(report))
    }

    func testANewReportIsOnlySent() async throws {
        let (_, shortage) = try await reported()
        guard case .sent = shortage.delivery else { return XCTFail("\(shortage.delivery)") }
    }

    func testTheSupervisorMarksItSeenByName() async throws {
        let (demo, shortage) = try await reported()
        let seen = try await demo.markSeen(shortage.id, by: .supervisor)
        XCTAssertEqual(seen.delivery, .seen(at: demo.clock.now(), by: DemoSeed.supervisorName))
        let stored = try await demo.shortages(for: meal)
        XCTAssertEqual(stored.first?.delivery, seen.delivery)
    }

    func testARepeatKeepsTheFirstSighting() async throws {
        let (demo, shortage) = try await reported()
        let first = try await demo.markSeen(shortage.id, by: .supervisor)
        demo.clock.set(demo.clock.now().addingTimeInterval(60))
        let second = try await demo.markSeen(shortage.id, by: .supervisor)
        XCTAssertEqual(first.delivery, second.delivery)
    }

    func testNoOtherRoleCanMarkItSeen() async throws {
        for role in Role.allCases where role != .supervisor {
            let (demo, shortage) = try await reported()
            do {
                _ = try await demo.markSeen(shortage.id, by: role)
                XCTFail("\(role) must not mark a report seen")
            } catch {
                guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
            }
        }
    }

    func testAnUnknownReportIsNotFound() async {
        do {
            _ = try await DemoDataProvider(scenario: .duringMeal).markSeen(ShortageID("gone"), by: .supervisor)
            XCTFail("Expected notFound")
        } catch {
            XCTAssertEqual(error as? RepositoryError, .notFound)
        }
    }

    func testOfflineRecordsNothing() async throws {
        let (demo, shortage) = try await reported()
        await demo.setScenario(.offline)
        do {
            _ = try await demo.markSeen(shortage.id, by: .supervisor)
            XCTFail("Expected offline")
        } catch {
            guard case .offline? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testRemoteNeverFakesIt() async {
        do {
            _ = try await RemoteAPI(baseURL: nil).markSeen(ShortageID("s"), by: .supervisor)
            XCTFail("RemoteAPI must not mark anything yet")
        } catch {
            guard case .notImplemented? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }
}
#endif
