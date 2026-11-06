#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// Kitchen Home counting rules (kitchen_spec.md), checked through the view model and the demo provider.
@MainActor
final class KitchenHomeViewModelTests: XCTestCase {
    private func makeModel(_ scenario: DemoScenario) -> KitchenHomeViewModel {
        let demo = DemoDataProvider(scenario: scenario)
        let session = StaffSession(role: .kitchenStaff, mess: DemoSeed.mess,
                                   staffInitials: DemoSeed.staffInitials(for: .kitchenStaff),
                                   supervisorName: DemoSeed.supervisorName)
        return KitchenHomeViewModel(session: session, repositories: demo.makeRepositories(), clock: demo.clock)
    }

    func testBeforeTheMealShowsTheForecastOnly() async {
        let model = makeModel(.beforeMeal)
        await model.load()
        guard case .loaded(let content) = model.state else { return XCTFail("Expected loaded, got \(model.state)") }
        XCTAssertEqual(content.visibleForecast?.diners, DemoSeed.forecastDiners)
        XCTAssertTrue(content.visibleShortages.isEmpty)
    }

    func testDuringTheMealShowsEntriesAndNeverTheForecast() async {
        let model = makeModel(.duringMeal)
        await model.load()
        guard case .loaded(let content) = model.state else { return XCTFail("Expected loaded, got \(model.state)") }
        guard case .duringMeal(let entered, let minutes, let shortages) = content.phase else {
            return XCTFail("Expected the during-meal phase")
        }
        XCTAssertEqual(entered.value, DemoSeed.liveEntries)
        XCTAssertEqual(minutes, 100, "12:00 PM to 1:40 PM")
        XCTAssertNil(content.visibleForecast, "The forecast is never shown beside the live count")
        XCTAssertTrue(shortages.isEmpty, "No shortage row when nothing was reported")
    }

    func testReportedShortageShowsOneRow() async {
        let model = makeModel(.duringMealShortageReported)
        await model.load()
        guard case .loaded(let content) = model.state else { return XCTFail("Expected loaded, got \(model.state)") }
        XCTAssertEqual(content.visibleShortages.map(\.dishName), [DemoSeed.shortageDish])
        XCTAssertEqual(content.hiddenShortageCount, 0)
    }

    func testOldLiveCountIsShownAsStale() async {
        let model = makeModel(.duringMealEntriesStale)
        await model.load()
        guard case .stale(_, let asOf) = model.state else { return XCTFail("Expected stale, got \(model.state)") }
        XCTAssertEqual(asOf, DemoSeed.staleEntriesAt)
    }

    func testAfterTheMealShowsFinalEntriesAndWasteStatus() async {
        let model = makeModel(.afterMeal)
        await model.load()
        guard case .loaded(let content) = model.state,
              case .afterMeal(let finalEntries, let closedAt, let waste) = content.phase else {
            return XCTFail("Expected the after-meal phase, got \(model.state)")
        }
        XCTAssertEqual(finalEntries.value, DemoSeed.finalEntries)
        XCTAssertEqual(closedAt, DemoSeed.closedAt)
        XCTAssertEqual(waste.status, .notStarted)
    }

    func testRecordedWasteReportIsEditableUntilSixHoursLater() async {
        let model = makeModel(.afterMealWasteRecorded)
        await model.load()
        guard case .loaded(let content) = model.state,
              case .afterMeal(_, _, let waste) = content.phase else {
            return XCTFail("Expected the after-meal phase, got \(model.state)")
        }
        XCTAssertEqual(model.editableUntil(waste), DemoSeed.wasteRecordedAt.addingTimeInterval(6 * 60 * 60))
    }

    func testOfflineNeverPretendsToHaveData() async {
        let model = makeModel(.offline)
        await model.load()
        guard case .offline(let value, let savedAt) = model.state else { return XCTFail("Expected offline, got \(model.state)") }
        XCTAssertNil(value, "Nothing was loaded before going offline")
        XCTAssertEqual(savedAt, DemoSeed.offlineSavedAt)
    }
}
#endif
