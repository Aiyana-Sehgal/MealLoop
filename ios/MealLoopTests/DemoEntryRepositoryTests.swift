#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// Door entry rules, checked against the demo provider.
final class DemoEntryRepositoryTests: XCTestCase {
    private func request(_ student: StudentRef = DemoSeed.sampleStudent, key: String = UUID().uuidString) -> EntryRequest {
        EntryRequest(mealID: DemoSeed.lunch.id, student: student, method: .qrScan, idempotencyKey: IdempotencyKey(key))
    }

    func testDuplicateEntryForSameStudentAndMealIsRejected() async throws {
        let demo = DemoDataProvider(scenario: .duringMeal)

        let first = try await demo.recordEntry(request())
        guard case .recorded(_, let countAfterFirst) = first else {
            return XCTFail("First scan should be recorded, got \(first)")
        }
        XCTAssertEqual(countAfterFirst, DemoSeed.liveEntries + 1)

        let second = try await demo.recordEntry(request())
        guard case .alreadyRecorded(_, let countAfterSecond) = second else {
            return XCTFail("Second scan of the same student should be rejected, got \(second)")
        }
        XCTAssertEqual(countAfterSecond, countAfterFirst, "Nothing is added to the count for a duplicate")
        let live = try await demo.liveCount(for: DemoSeed.lunch.id)
        XCTAssertEqual(live.value, countAfterFirst)
    }

    func testSameIdempotencyKeyReturnsTheOriginalResult() async throws {
        let demo = DemoDataProvider(scenario: .duringMeal)
        let first = try await demo.recordEntry(request(key: "scan-1"))
        let replay = try await demo.recordEntry(request(key: "scan-1"))
        XCTAssertEqual(first, replay)
    }

    func testOfflineScanThrowsAndRecordsNothing() async throws {
        let demo = DemoDataProvider(scenario: .offline)
        do {
            _ = try await demo.recordEntry(request())
            XCTFail("An offline scan must never succeed")
        } catch RepositoryError.offline {
            // Expected.
        }
        await demo.setScenario(.duringMeal)
        let live = try await demo.liveCount(for: DemoSeed.lunch.id)
        XCTAssertEqual(live.value, DemoSeed.liveEntries)
    }

    func testStudentWithoutAnswerIsRecordedAndListedSeparately() async throws {
        let demo = DemoDataProvider(scenario: .duringMeal)
        let result = try await demo.recordEntry(request())
        guard case .recorded(let record, _) = result else { return XCTFail("Expected recorded") }
        XCTAssertFalse(record.hadMealResponse)
        let list = try await demo.enteredWithoutVoting(for: DemoSeed.lunch.id)
        XCTAssertEqual(list.map(\.student), [DemoSeed.sampleStudent])
    }

    func testScanningIsClosedBeforeTheMeal() async throws {
        let demo = DemoDataProvider(scenario: .beforeMeal)
        do {
            _ = try await demo.recordEntry(request())
            XCTFail("Scanning must be closed before the meal starts")
        } catch RepositoryError.notAllowed {
            // Expected.
        }
    }

    func testFinalEntriesAreUnavailableUntilTheMealCloses() async throws {
        let during = DemoDataProvider(scenario: .duringMeal)
        let duringFinal = try await during.finalCount(for: DemoSeed.lunch.id)
        XCTAssertEqual(duringFinal, .unavailable)
        let after = DemoDataProvider(scenario: .afterMeal)
        let afterFinal = try await after.finalCount(for: DemoSeed.lunch.id)
        XCTAssertEqual(afterFinal.value, DemoSeed.finalEntries)
    }

    func testOnlyTheSupervisorClosesAMeal() async throws {
        let demo = DemoDataProvider(scenario: .duringMeal)
        do {
            _ = try await demo.closeMeal(DemoSeed.lunch.id, by: .kitchenStaff)
            XCTFail("Kitchen Staff must not close the meal")
        } catch RepositoryError.notAllowed {
            // Expected.
        }
        let closed = try await demo.closeMeal(DemoSeed.lunch.id, by: .supervisor)
        XCTAssertEqual(closed.state, .closed)
    }

    func testIncompleteWasteReportIsNotSaved() async throws {
        let demo = DemoDataProvider(scenario: .afterMeal)
        let report = try await demo.report(for: DemoSeed.lunch.id)
        XCTAssertGreaterThan(report.missingCount, 0)
        do {
            _ = try await demo.save(report, by: .kitchenStaff)
            XCTFail("A report with empty fields must not be recorded")
        } catch RepositoryError.validationFailed {
            // Expected.
        }
    }

    func testRolePasswordLocksAfterThreeWrongTries() async throws {
        let demo = DemoDataProvider(scenario: .duringMeal)
        let first = try await demo.verifyRolePassword("0000", for: .kitchenStaff)
        XCTAssertEqual(first, .wrong(triesLeft: 2))
        _ = try await demo.verifyRolePassword("0000", for: .kitchenStaff)
        let third = try await demo.verifyRolePassword("0000", for: .kitchenStaff)
        XCTAssertEqual(third, .locked(resetBy: DemoSeed.supervisorName))
        let afterLock = try await demo.verifyRolePassword(DemoSeed.simulatedRolePassword, for: .kitchenStaff)
        XCTAssertEqual(afterLock, .locked(resetBy: DemoSeed.supervisorName))
    }
}
#endif
