#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SIMULATED. Ratings given in one run of the app. Nothing is seeded: there is no sample to cite.
actor DemoFeedbackRatingStore {
    private var ratings: [StudentID: [StudentRatingTarget: StudentRating]] = [:]

    func rating(_ target: StudentRatingTarget, for student: StudentID) -> StudentRating? { ratings[student]?[target] }
    func set(_ rating: StudentRating?, for target: StudentRatingTarget, student: StudentID) {
        ratings[student, default: [:]][target] = rating
    }
    func count(_ target: StudentRatingTarget) -> Int { ratings.values.filter { $0[target] != nil }.count }
}

/// SIMULATED. Ratings on top of the prototype data source. In the review build a meal or dish can be rated and
/// re-rated at any time: no time, attendance or meal-state gate (owner, 11 November). Credits are not touched.
struct DemoFeedbackRatings: FeedbackRatingRepository {
    let core: DemoDataProvider
    let store: DemoFeedbackRatingStore

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: DemoSeed.mess.timeZoneIdentifier) ?? .current
        return calendar
    }

    /// Always open; the date only says the window has no end in the demo.
    func ratingWindow(day: Date, slot: MealSlot, at mess: MessID) async throws -> StudentRatingWindow {
        try await core.requireConnection()
        return .open(closesAt: .distantFuture)
    }

    func rateMeal(day: Date, slot: MealSlot, _ answer: StudentRatingAnswer, at mess: MessID, for student: StudentID)
        async throws -> StudentRating? {
        try await rate(StudentRatingTarget(day: calendar.startOfDay(for: day), slot: slot, dish: nil), answer, mess, student)
    }

    func rateDish(_ dish: DishID, day: Date, slot: MealSlot, _ answer: StudentRatingAnswer, at mess: MessID,
                  for student: StudentID) async throws -> StudentRating? {
        try await rate(StudentRatingTarget(day: calendar.startOfDay(for: day), slot: slot, dish: dish), answer, mess, student)
    }

    func myRating(_ target: StudentRatingTarget, for student: StudentID) async throws -> StudentRating? {
        try await core.requireConnection()
        return await store.rating(normalised(target), for: student)
    }

    func goodCount(_ target: StudentRatingTarget, at mess: MessID) async throws -> Int {
        try await core.requireConnection()
        return await store.count(normalised(target))
    }

    private func normalised(_ target: StudentRatingTarget) -> StudentRatingTarget {
        StudentRatingTarget(day: calendar.startOfDay(for: target.day), slot: target.slot, dish: target.dish)
    }

    private func rate(_ target: StudentRatingTarget, _ answer: StudentRatingAnswer, _ mess: MessID, _ student: StudentID)
        async throws -> StudentRating? {
        try await core.requireConnection()
        switch answer {
        case .good:
            let rating = StudentRating(target: target, at: core.clock.now())
            await store.set(rating, for: target, student: student)
            return rating
        case .notGood:
            await store.set(nil, for: target, student: student)
            return nil
        }
    }
}
#endif
