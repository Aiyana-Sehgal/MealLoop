import Foundation

/// One meal as the student sees it. Every value comes from the repositories.
struct StudentMealCard: Equatable, Identifiable {
    let meal: Meal
    let response: IntentionResponse
    /// From the domain policy, for display only. The backend enforces the cutoff on every write.
    let isAnswerOpen: Bool
    let cutoff: Date

    var id: MealID { meal.id }

    var answer: MealIntention? {
        if case .answered(let intention, _) = response { return intention }
        return nil
    }

    var answerState: MealAnswerState {
        guard isAnswerOpen else { return .locked(answer) }
        return answer.map(MealAnswerState.answered) ?? .unanswered
    }
}

/// What Student Home shows: the meal at hand, and the one after it while its answer window is open.
struct StudentHomeContent: Equatable {
    let today: Date
    let hero: StudentMealCard
    let nextMeal: StudentMealCard?
}
