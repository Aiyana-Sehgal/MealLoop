#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The added prototype-backend operation `SOSRepository.raise`. Nothing else about SOS changes.
final class SOSRaiseOperationTests: XCTestCase {
    private let mess = DemoSeed.mess.id

    private func report(key: String = "sos-1", mess: MessID = DemoSeed.mess.id) -> SOSReport {
        SOSReport(messID: mess, title: DemoSeed.sosTitle, place: DemoSeed.sosPlace, idempotencyKey: IdempotencyKey(key))
    }

    func testARaisedCaseIsActiveForTheMessAndOpen() async throws {
        let demo = DemoDataProvider(scenario: .duringMeal)
        let sos = try await demo.raise(report())
        XCTAssertEqual(sos.status, .open)
        XCTAssertNil(sos.claim)
        XCTAssertTrue(sos.checks.isEmpty)
        XCTAssertEqual(sos.raisedAt, demo.clock.now())
        let active = try await demo.activeCases(for: mess)
        XCTAssertEqual(active.map(\.id), [sos.id])
    }

    func testTheSameKeyNeverOpensASecondCase() async throws {
        let demo = DemoDataProvider(scenario: .duringMeal)
        let first = try await demo.raise(report())
        let again = try await demo.raise(report())
        XCTAssertEqual(first, again)
        let active = try await demo.activeCases(for: mess)
        XCTAssertEqual(active.count, 1)
    }

    func testAnUnknownMessIsRefused() async {
        let demo = DemoDataProvider(scenario: .duringMeal)
        do {
            _ = try await demo.raise(report(mess: MessID("elsewhere")))
            XCTFail("Expected notFound")
        } catch {
            XCTAssertEqual(error as? RepositoryError, .notFound)
        }
    }

    func testOfflineRaisesNothing() async throws {
        let demo = DemoDataProvider(scenario: .offline)
        do {
            _ = try await demo.raise(report())
            XCTFail("Expected offline")
        } catch {
            guard case .offline? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testTheRemoteSourceIsNotImplemented() async {
        do {
            _ = try await RemoteAPI(baseURL: nil).raise(report())
            XCTFail("Expected notImplemented")
        } catch {
            guard case .notImplemented? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testAClosedCaseLeavesTheActiveList() async throws {
        let demo = DemoDataProvider(scenario: .duringMeal)
        let sos = try await demo.raise(report())
        _ = try await demo.close(sos.id, by: .supervisor)
        let active = try await demo.activeCases(for: mess)
        XCTAssertTrue(active.isEmpty)
    }
}
#endif
