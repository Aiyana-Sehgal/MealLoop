#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// Spending with Add, Edit and Delete expense, read from the prototype backend.
@MainActor
final class StudentSpendingScreensTests: XCTestCase {
    private var session: Session {
        get throws {
            Session(account: try XCTUnwrap(DemoSeed.accounts.first { $0.role == .student }), staff: nil,
                    student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
        }
    }

    private func make(_ scenario: DemoScenario = .storyStart) throws -> (DemoDataProvider, StudentSpendingViewModel) {
        let demo = DemoDataProvider(scenario: scenario)
        let model = try XCTUnwrap(StudentSpendingViewModel(session: try session, repositories: demo.makeRepositories(),
                                                           clock: demo.clock))
        return (demo, model)
    }

    func testSpendingOpensItsOwnPageWithTheSystemBar() {
        XCTAssertTrue(StudentYouRoute.spending.usesSystemBar, "Built on MLScreen: native back and swipe-back.")
        XCTAssertNotEqual(StudentYouRoute.spending, .comingSoon(YouCopy.spending))
    }

    func testAddingAnExpenseShowsTheSavedLineAndTheNewTotal() async throws {
        let (demo, model) = try make()
        await model.load()
        XCTAssertEqual(model.state.value?.monthTotal, 3000)
        let saved = await model.save(StudentExpenseDraft(amount: 60, day: demo.clock.now(), category: .canteen, place: nil,
                                                         note: nil), replacing: nil)
        XCTAssertTrue(saved)
        XCTAssertEqual(model.savedLine, "Saved · Canteen ₹60", "Spending · Saved 221:64164")
        XCTAssertEqual(model.state.value?.monthTotal, 3060)
        XCTAssertEqual(model.state.value?.thisWeek, 560)
    }

    func testAnEditAndADeleteChangeTheTotals() async throws {
        let (_, model) = try make()
        await model.load()
        let canteen = try XCTUnwrap(model.state.value?.recent.first { $0.category == .canteen })
        var draft = canteen.draft
        draft.amount = 100
        let edited = await model.save(draft, replacing: canteen.id)
        XCTAssertTrue(edited)
        XCTAssertEqual(model.state.value?.thisWeek, 420)
        let deleted = await model.delete(canteen.id)
        XCTAssertTrue(deleted)
        XCTAssertEqual(model.state.value?.thisWeek, 320)
        XCTAssertNil(model.savedLine, "A delete is not called saved.")
    }

    func testAZeroAmountCannotBeSaved() async throws {
        let (demo, model) = try make()
        XCTAssertFalse(model.isSaveable(StudentExpenseDraft(amount: 0, day: demo.clock.now(), category: .snacks,
                                                            place: nil, note: nil)))
    }

    func testOfflineShowsTheFailedStateAndRecordsNothing() async throws {
        let (demo, model) = try make(.offline)
        await model.load()
        guard case .offline(let saved, _) = model.state else { return XCTFail("Expected the offline state.") }
        XCTAssertNil(saved, "Offline is never an empty ledger.")
        let result = await model.save(StudentExpenseDraft(amount: 60, day: demo.clock.now(), category: .canteen,
                                                          place: nil, note: nil), replacing: nil)
        XCTAssertFalse(result)
        XCTAssertEqual(model.write, .failed, "Add expense · Failed 221:65703")
        XCTAssertNil(model.savedLine)
    }
}
#endif
