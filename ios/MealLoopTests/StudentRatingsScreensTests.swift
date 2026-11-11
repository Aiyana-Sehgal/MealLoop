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

    private func make(_ scenario: DemoScenario = .afterMeal, dish: DishID? = nil,
                      repositories: Repositories? = nil) throws -> StudentRatingViewModel {
        let repositories = repositories ?? DemoDataProvider(scenario: scenario).makeRepositories()
        return try XCTUnwrap(StudentRatingViewModel(session: try session, repositories: repositories,
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

    /// Owner, 9 November: Not good on a dish opens that dish's What's wrong (2159:149347), never the Report form.
    func testNotGoodRecordsNothingAndOpensThatDishsWhatsWrong() async throws {
        let model = try make(dish: rice)
        model.dishName = "Steamed Rice"
        await model.load()
        _ = await model.rate(.notGood)
        XCTAssertFalse(model.isGood)
        XCTAssertEqual(model.feedbackRequest(after: .notGood).kind, .dish("Steamed Rice"))
        XCTAssertEqual(model.feedbackRequest(after: .good).kind, .thanks)
    }

    /// No gate on screen: at 7:00 AM, before lunch, Good saves and shows again when the page is reopened.
    func testARatingBeforeTheMealSavesAndShowsOnReopen() async throws {
        let repositories = DemoDataProvider(scenario: .storyStart).makeRepositories()
        let model = try make(repositories: repositories)
        await model.load()
        XCTAssertTrue(model.canRate)
        let saved = await model.rate(.good)
        XCTAssertTrue(saved)
        XCTAssertTrue(model.isGood)
        let reopened = try make(repositories: repositories)
        await reopened.load()
        XCTAssertTrue(reopened.isGood)
    }
}
#endif
