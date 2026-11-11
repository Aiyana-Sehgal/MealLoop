#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The additive ratings (owner design, rules proposed and listed "owner to confirm").
final class FeedbackRatingRepositoryTests: XCTestCase {
    private let aarav = DemoSeed.sampleStudent.id
    private let other = StudentID("demo-student-other")
    private let mess = DemoSeed.mess.id
    private let day = DemoSeed.time(0, 0)
    private let rice = DishID("demo-dish-rice")

    private func make(_ scenario: DemoScenario = .storyStart, at now: Date? = nil) -> (DemoDataProvider, Repositories) {
        let provider = DemoDataProvider(scenario: scenario)
        if let now { provider.clock.set(now) }
        return (provider, provider.makeRepositories())
    }

    /// Owner (11 November): in the demo a meal can be rated at any time, before it is served or days later.
    func testAMealCanBeRatedAtAnyTime() async throws {
        let (provider, repositories) = make() // 7:00 AM, lunch not started
        let ratings = repositories.feedbackRatings
        let window = try await ratings.ratingWindow(day: day, slot: .lunch, at: mess)
        XCTAssertTrue(window.isOpen)
        let early = try await ratings.rateMeal(day: day, slot: .lunch, .good, at: mess, for: aarav)
        XCTAssertNotNil(early, "Rated before the meal")
        provider.clock.set(DemoSeed.date(20, 12, 0))
        let late = try await ratings.rateDish(rice, day: DemoSeed.date(11, 0, 0), slot: .lunch, .good, at: mess, for: aarav)
        XCTAssertNotNil(late, "Rated days after the meal")
    }

    /// A saved rating is there when the page is opened again, and it can be changed.
    func testASavedRatingIsThereOnReopenAndCanBeChanged() async throws {
        let (_, repositories) = make()
        let ratings = repositories.feedbackRatings
        let target = StudentRatingTarget(day: day, slot: .breakfast, dish: nil)
        _ = try await ratings.rateMeal(day: day, slot: .breakfast, .good, at: mess, for: aarav)
        let first = try await ratings.myRating(target, for: aarav)
        XCTAssertNotNil(first)
        _ = try await ratings.rateMeal(day: day, slot: .breakfast, .notGood, at: mess, for: aarav)
        let changed = try await ratings.myRating(target, for: aarav)
        XCTAssertNil(changed, "Not good takes the Good back")
        _ = try await ratings.rateMeal(day: day, slot: .breakfast, .good, at: mess, for: aarav)
        let again = try await ratings.myRating(target, for: aarav)
        XCTAssertNotNil(again)
    }

    func testGoodIsRecordedOncePerMealAndAChangeReplacesIt() async throws {
        let (provider, repositories) = make(.afterMeal)
        let ratings = repositories.feedbackRatings
        _ = try await ratings.rateMeal(day: day, slot: .lunch, .good, at: mess, for: aarav)
        provider.clock.set(provider.clock.now().addingTimeInterval(60))
        let again = try await ratings.rateMeal(day: day, slot: .lunch, .good, at: mess, for: aarav)
        let target = StudentRatingTarget(day: day, slot: .lunch, dish: nil)
        let count = try await ratings.goodCount(target, at: mess)
        XCTAssertEqual(count, 1, "One rating per meal; the second replaces the first.")
        let mine = try await ratings.myRating(target, for: aarav)
        XCTAssertEqual(mine?.at, again?.at)
        let changed = try await ratings.rateMeal(day: day, slot: .lunch, .notGood, at: mess, for: aarav)
        XCTAssertNil(changed, "Not good records nothing and takes back the Good.")
        let none = try await ratings.myRating(target, for: aarav)
        XCTAssertNil(none)
    }

    func testADishIsRatedOnItsOwnBesideTheMeal() async throws {
        let (_, repositories) = make(.afterMeal)
        let ratings = repositories.feedbackRatings
        _ = try await ratings.rateDish(rice, day: day, slot: .lunch, .good, at: mess, for: aarav)
        let dish = try await ratings.myRating(StudentRatingTarget(day: day, slot: .lunch, dish: rice), for: aarav)
        XCTAssertNotNil(dish)
        let meal = try await ratings.myRating(StudentRatingTarget(day: day, slot: .lunch, dish: nil), for: aarav)
        XCTAssertNil(meal, "The dish rating is not a meal rating.")
    }

    func testNotGoodAloneRecordsNothing() async throws {
        let (_, repositories) = make(.afterMeal)
        let result = try await repositories.feedbackRatings.rateDish(rice, day: day, slot: .lunch, .notGood, at: mess,
                                                                    for: aarav)
        XCTAssertNil(result)
        let count = try await repositories.feedbackRatings.goodCount(StudentRatingTarget(day: day, slot: .lunch, dish: rice),
                                                                     at: mess)
        XCTAssertEqual(count, 0)
    }

    func testRatingsArePrivateAndEarnNoCredits() async throws {
        let (_, repositories) = make(.afterMeal)
        let before = try await repositories.studentYou.credits(for: aarav)
        _ = try await repositories.feedbackRatings.rateMeal(day: day, slot: .lunch, .good, at: mess, for: aarav)
        _ = try await repositories.feedbackRatings.rateDish(rice, day: day, slot: .lunch, .good, at: mess, for: aarav)
        let after = try await repositories.studentYou.credits(for: aarav)
        XCTAssertEqual(after.balance, before.balance, "Ratings earn no credits.")
        XCTAssertEqual(after.history, before.history)
        let theirs = try await repositories.feedbackRatings.myRating(StudentRatingTarget(day: day, slot: .lunch, dish: nil),
                                                                     for: other)
        XCTAssertNil(theirs, "Nobody reads another student's rating.")
    }
}
#endif
