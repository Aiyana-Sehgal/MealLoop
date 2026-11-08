#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// How was lunch?, Rate a dish and the hand-off to the report form, read from the prototype backend.
@MainActor
final class StudentRatingsScreensTests: XCTestCase {
    private let rice = DishID("demo-dish-rice")

    private var session: Session {
        get throws {
            Session(account: try XCTUnwrap(DemoSeed.accounts.first { $0.role == .student }), staff: nil,
                    student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
        }
    }

    private func make(_ scenario: DemoScenario = .afterMeal, dish: DishID? = nil) throws -> StudentRatingViewModel {
        let demo = DemoDataProvider(scenario: scenario)
        return try XCTUnwrap(StudentRatingViewModel(session: try session, repositories: demo.makeRepositories(),
                                                    day: DemoSeed.lunch.startsAt, slot: .lunch, dish: dish))
    }

    func testRateADishNoLongerOpensComingSoon() {
        let route = StudentMealsRoute.rateDish(rice, day: DemoSeed.lunch.startsAt, slot: .lunch)
        XCTAssertNotEqual(route, .comingSoon(MealsCopy.rateDish))
        XCTAssertTrue(route.usesSystemBar)
        XCTAssertTrue(StudentHomeRoute.rateMeal(day: DemoSeed.lunch.startsAt, slot: .lunch).usesSystemBar)
    }

    func testGoodIsRecordedOnTheDishAfterTheMeal() async throws {
        let model = try make(dish: rice)
        await model.load()
        XCTAssertTrue(model.canRate)
        let saved = await model.rate(.good)
        XCTAssertTrue(saved)
        XCTAssertTrue(model.isGood)
    }

    func testNotGoodRecordsNothingAndHandsTheDishToTheReportForm() async throws {
        let model = try make(dish: rice)
        model.dishName = "Steamed Rice"
        await model.load()
        _ = await model.rate(.notGood)
        XCTAssertFalse(model.isGood)
        XCTAssertEqual(model.reportSubject, StudentReportSubject(slot: .lunch, day: model.target.day, dishName: "Steamed Rice"))
        let report = try XCTUnwrap(StudentReportViewModel(session: try session,
                                                          repositories: DemoDataProvider(scenario: .afterMeal).makeRepositories(),
                                                          clock: DemoDataProvider(scenario: .afterMeal).clock))
        _ = StudentReportView(model: report, subject: model.reportSubject, onShowIssue: nil) {}
        XCTAssertEqual(report.subject?.dishName, "Steamed Rice", "The report form opens with the dish selected.")
    }

    func testARatingBeforeTheMealEndsIsRefusedOnScreen() async throws {
        let model = try make(.storyStart)
        await model.load()
        XCTAssertEqual(model.window, .notYet)
        XCTAssertFalse(model.canRate)
        let saved = await model.rate(.good)
        XCTAssertFalse(saved)
        XCTAssertEqual(model.write, .failed)
    }
}
#endif
