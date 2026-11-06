#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The added prototype-backend operation `MealStateRepository.mealHistory`. Read only; no existing operation changes.
final class MealHistoryOperationTests: XCTestCase {
    private let mess = DemoSeed.mess.id

    func testAtTheStoryStartOnlyEarlierDaysAreListedNewestFirst() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        let history = try await demo.mealHistory(for: mess)
        XCTAssertEqual(history.map(\.mealID), DemoSeed.pastMeals.map(\.id))
        XCTAssertEqual(history.map(\.slot), [.dinner, .lunch, .dinner])
    }

    func testAMissingFinalCountStaysUnavailableNeverZero() async throws {
        let history = try await DemoDataProvider(scenario: .storyStart).mealHistory(for: mess)
        let monday = try XCTUnwrap(history.last)
        XCTAssertEqual(monday.finalEntries, .unavailable)
        XCTAssertEqual(monday.waste, .recorded(at: nil))
        XCTAssertNil(monday.wasteReport)
    }

    /// Owner's ruling on SV-Q2: the history and `finalCount(for:)` must agree for Wed 14 · Breakfast. No spec
    /// document gives that number, so both say unavailable, never zero or an invented number.
    func testBreakfastFinalEntriesAgreeWithFinalCountAndStayUnavailableNeverZero() async throws {
        let breakfast = DemoSeed.breakfast.id
        var checked: [DemoScenario] = []
        for scenario in DemoScenario.allCases where scenario != .offline {
            let demo = DemoDataProvider(scenario: scenario)
            let history = try await demo.mealHistory(for: mess)
            let finalCount = try await demo.finalCount(for: breakfast)
            let headcount = try await demo.headcount(for: breakfast)
            XCTAssertEqual(finalCount, .unavailable, "\(scenario)")
            XCTAssertEqual(headcount.finalEntries, finalCount, "\(scenario)")
            guard let record = history.first(where: { $0.mealID == breakfast }) else { continue }
            XCTAssertEqual(record.finalEntries, finalCount, "\(scenario)")
            XCTAssertNil(record.finalEntries.value, "Unavailable is never stored as a number (\(scenario))")
            XCTAssertNotEqual(record.finalEntries, .available(0, asOf: record.day), "\(scenario)")
            checked.append(scenario)
        }
        XCTAssertFalse(checked.isEmpty, "Breakfast must be in the history once its times have passed")
    }

    func testTuesdayLunchCarriesTheKitchenRowsInTheirOwnUnits() async throws {
        let history = try await DemoDataProvider(scenario: .storyStart).mealHistory(for: mess)
        let lunch = try XCTUnwrap(history.first { $0.slot == .lunch })
        XCTAssertEqual(lunch.finalEntries.value, 806)
        let report = try XCTUnwrap(lunch.wasteReport)
        XCTAssertEqual(report.leftovers.map(\.unit), [.kilograms, .litres, .kilograms, .pieces])
        XCTAssertEqual(report.leftovers[2].measurement, .noneLeft)
        XCTAssertEqual(report.plateWaste, .entered(kilograms: 21))
        XCTAssertEqual(lunch.shortages.count, 1)
    }

    func testTheStoryMealJoinsOnlyOnceClosedWithItsLiveShortagesAndWaste() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        let lunch = DemoSeed.lunch.id
        _ = try await demo.startMeal(lunch, by: .supervisor)
        _ = try await demo.reportShortage(ShortageReport(mealID: lunch, dishName: DemoSeed.shortageDish,
                                                         level: .almostOut, note: nil, reportedBy: .kitchenStaff,
                                                         idempotencyKey: IdempotencyKey("rice")))
        var history = try await demo.mealHistory(for: mess)
        XCTAssertFalse(history.contains { $0.mealID == lunch }, "An open meal is not history")

        _ = try await demo.closeMeal(lunch, by: .supervisor)
        history = try await demo.mealHistory(for: mess)
        let record = try XCTUnwrap(history.first)
        XCTAssertEqual(record.mealID, lunch)
        XCTAssertEqual(record.closedAt, DemoSeed.closedAt)
        XCTAssertEqual(record.shortages, [MealRecord.ShortageLine(dishName: DemoSeed.shortageDish, outcome: .active)])
        XCTAssertEqual(record.waste, .notRecorded)
        XCTAssertNil(record.wasteReport)
        // Breakfast's own times have passed by 2:00 PM, so it is listed after lunch with its record.
        // No spec document gives its final entries, so the record matches `finalCount(for:)`: unavailable.
        XCTAssertEqual(history[1].mealID, DemoSeed.breakfast.id)
        XCTAssertEqual(history[1].finalEntries, .unavailable)
        let breakfastFinal = try await demo.finalCount(for: DemoSeed.breakfast.id)
        XCTAssertEqual(history[1].finalEntries, breakfastFinal)
        XCTAssertEqual(history[1].waste, .recorded(at: DemoSeed.breakfastWasteRecordedAt))
    }

    func testAWasteReportTheKitchenSavesShowsAsRecordedWithItsRows() async throws {
        let demo = DemoDataProvider(scenario: .afterMeal)
        let lunch = DemoSeed.lunch.id
        var report = try await demo.report(for: lunch)
        report.leftovers = report.leftovers.map { var row = $0; row.measurement = .noneLeft; return row }
        report.plateWaste = .entered(kilograms: 18)
        let saved = try await demo.save(report, by: .kitchenStaff)
        let history = try await demo.mealHistory(for: mess)
        let record = try XCTUnwrap(history.first { $0.mealID == lunch })
        guard case .recorded(let at) = saved.status else { return XCTFail("\(saved.status)") }
        XCTAssertEqual(record.waste, .recorded(at: at))
        XCTAssertEqual(record.wasteReport, saved)
    }

    func testOfflineAndUnknownMess() async throws {
        let empty = try await DemoDataProvider(scenario: .duringMeal).mealHistory(for: MessID("elsewhere"))
        XCTAssertTrue(empty.isEmpty)
        do {
            _ = try await DemoDataProvider(scenario: .offline).mealHistory(for: mess)
            XCTFail("Expected offline")
        } catch {
            guard case .offline? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testTheRemoteSourceIsNotImplemented() async {
        do {
            _ = try await RemoteAPI(baseURL: nil).mealHistory(for: mess)
            XCTFail("Expected notImplemented")
        } catch {
            guard case .notImplemented? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }
}
#endif
