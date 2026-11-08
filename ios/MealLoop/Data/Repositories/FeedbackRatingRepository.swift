import Foundation

/// Good / Not good on a meal or a dish (see `StudentRatings.swift` for the proposed rules). Ratings earn no credits.
protocol FeedbackRatingRepository: Sendable {
    func ratingWindow(day: Date, slot: MealSlot, at mess: MessID) async throws -> StudentRatingWindow
    /// Good records (or keeps) the rating; Not good records nothing and takes back an earlier Good. Refused
    /// (`notAllowed`) outside the window. Returns the rating now held, nil after Not good.
    func rateMeal(day: Date, slot: MealSlot, _ answer: StudentRatingAnswer, at mess: MessID, for student: StudentID)
        async throws -> StudentRating?
    func rateDish(_ dish: DishID, day: Date, slot: MealSlot, _ answer: StudentRatingAnswer, at mess: MessID,
                  for student: StudentID) async throws -> StudentRating?
    /// The student's own rating. Nobody else's is ever returned.
    func myRating(_ target: StudentRatingTarget, for student: StudentID) async throws -> StudentRating?
    /// For staff: how many students said Good. A count only, never who.
    func goodCount(_ target: StudentRatingTarget, at mess: MessID) async throws -> Int
}

/// The answer of any data source with no such service yet. It never fakes a result.
struct UnavailableFeedbackRatings: FeedbackRatingRepository {
    private var unavailable: RepositoryError { .notImplemented(feature: "Ratings") }

    func ratingWindow(day: Date, slot: MealSlot, at mess: MessID) async throws -> StudentRatingWindow { throw unavailable }
    func rateMeal(day: Date, slot: MealSlot, _ answer: StudentRatingAnswer, at mess: MessID, for student: StudentID)
        async throws -> StudentRating? { throw unavailable }
    func rateDish(_ dish: DishID, day: Date, slot: MealSlot, _ answer: StudentRatingAnswer, at mess: MessID,
                  for student: StudentID) async throws -> StudentRating? { throw unavailable }
    func myRating(_ target: StudentRatingTarget, for student: StudentID) async throws -> StudentRating? { throw unavailable }
    func goodCount(_ target: StudentRatingTarget, at mess: MessID) async throws -> Int { throw unavailable }
}
