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

/// SIMULATED. Ratings on top of the prototype data source. The window comes from the day's meals in
/// `DemoDataProvider`: open once the meal is closed or past its end, and for 2 days after it ends (owner decision,
/// 9 November). Credits are not touched.
struct DemoFeedbackRatings: FeedbackRatingRepository {
    let core: DemoDataProvider
    let store: DemoFeedbackRatingStore

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: DemoSeed.mess.timeZoneIdentifier) ?? .current
        return calendar
    }

    /// How long a meal stays open for ratings after its service ends (owner decision, 9 November).
    static let ratingDays = 2

    func ratingWindow(day: Date, slot: MealSlot, at mess: MessID) async throws -> StudentRatingWindow {
        let now = core.clock.now()
        let statuses = try await core.meals(for: mess)
        let day = calendar.startOfDay(for: day)
        let today = calendar.startOfDay(for: now)
        let endsAt: Date
        if let status = statuses.first(where: { $0.meal.slot == slot && calendar.startOfDay(for: $0.meal.startsAt) == day }) {
            guard status.state == .closed || now >= status.meal.endsAt else { return .notYet }
            endsAt = status.closedAt ?? status.meal.endsAt
        } else {
            // A meal of another day ends at the same time of day as today's meal of that slot; a slot today does not
            // serve ends with its day. Later days are not rated yet.
            guard day < today else { return .notYet }
            let offset = statuses.first(where: { $0.meal.slot == slot }).map { $0.meal.endsAt.timeIntervalSince(today) }
            endsAt = offset.map { day.addingTimeInterval($0) } ?? (calendar.date(byAdding: .day, value: 1, to: day) ?? day)
        }
        guard let closesAt = calendar.date(byAdding: .day, value: Self.ratingDays, to: endsAt) else { return .closed }
        return now < closesAt ? .open(closesAt: closesAt) : .closed
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
        switch try await ratingWindow(day: target.day, slot: target.slot, at: mess) {
        case .notYet: throw RepositoryError.notAllowed(reason: "You can rate this after the meal.")
        case .closed: throw RepositoryError.notAllowed(reason: "Ratings close when the next meal starts.")
        case .open: break
        }
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
