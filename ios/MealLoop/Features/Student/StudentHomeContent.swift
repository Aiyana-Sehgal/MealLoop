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

    var answeredAt: Date? {
        if case .answered(_, let date) = response { return date }
        return nil
    }

    var answerState: MealAnswerState {
        guard isAnswerOpen else { return .locked(answer) }
        return answer.map(MealAnswerState.answered) ?? .unanswered
    }
}

/// Which top card Home shows. HeroCard (2135:2336) and the Home frames of page 07.
enum StudentHeroCase: Equatable {
    /// Home · Mess closed: "Mess opens at 7:30".
    case messClosed
    /// Home · Not answered: "Breakfast today?" with the answer buttons.
    case question
    /// Home · You're in and Home · Skipped.
    case answered
    /// Home · Breakfast open: "Breakfast is open".
    case nowServing
    /// Home · After a meal: "Lunch at 12 PM".
    case nextMeal
}

/// What Student Home shows: the meal at hand, and the one after it while its answer window is open.
struct StudentHomeContent: Equatable {
    let today: Date
    let hero: StudentMealCard
    let nextMeal: StudentMealCard?
    var heroState: MealState = .notStarted
    /// The latest meal of the day that has closed. Home asks how it was.
    var lastClosedMeal: Meal?
    /// A meal after the staff-run ones. It takes over the top card once those are over.
    var laterMeal: StudentMealCard?
    /// Nil when the extras could not be read. Their rows then show as missing, never as zero.
    var extras: StudentHomeExtras?

    /// The card on top: the last staff-run meal stays `hero`, and a later meal replaces it on screen once it closes.
    var shownHero: StudentMealCard {
        heroState == .closed ? (laterMeal ?? hero) : hero
    }

    var heroCase: StudentHeroCase {
        // Before the doors open an open question still comes first: the answer is what the kitchen needs.
        if extras?.isMessClosed == true && !(hero.answer == nil && hero.isAnswerOpen) { return .messClosed }
        if heroState == .inService { return .nowServing }
        if heroState == .closed && laterMeal != nil { return .nextMeal }
        if heroState == .notStarted && lastClosedMeal != nil { return .nextMeal }
        return hero.answer == nil ? .question : .answered
    }

    /// The answer row under the top card (AnswerRow 2135:2382).
    var answerRow: StudentMealCard? {
        if let nextMeal { return nextMeal }
        if heroState == .notStarted && lastClosedMeal != nil { return hero }
        return laterMeal
    }

    /// Every meal this screen can open the answer page for.
    var cards: [StudentMealCard] { [hero, nextMeal, laterMeal].compactMap { $0 } }
}
