import Foundation

// Student feedback ratings (owner design 7 November 2026: images student_feedback_01_how_was_lunch and
// student_feedback_02_rate_a_dish; spec data/review_additions_spec.md "Student feedback ratings"). No Figma frame.
// Every rule here is the owner's proposal and is listed "owner to confirm" in the Student final report:
// - Good records a positive rating and nothing else.
// - Not good records nothing by itself; it hands off to the report form. It does take back an earlier Good.
// - Skip for now records nothing (no operation exists for it).
// - At most one rating per meal and one per dish per meal, replaceable while the window is open.
// - Allowed from when that meal's service ends until 2 days later (owner decision, 9 November).
// - Private to the student; staff see a count only. No credits for ratings. No AI decides anything.

/// What is rated: a meal of a day, or one dish of it.
struct StudentRatingTarget: Codable, Sendable, Hashable {
    /// The start of the day, in the mess's time zone.
    let day: Date
    let slot: MealSlot
    /// Nil for the whole meal ("How was lunch?").
    let dish: DishID?
}

enum StudentRatingAnswer: String, Codable, Sendable, Hashable {
    case good
    case notGood
}

/// A recorded rating. Only Good is ever recorded.
struct StudentRating: Codable, Sendable, Hashable {
    let target: StudentRatingTarget
    let at: Date
}

/// Whether a meal can be rated now.
enum StudentRatingWindow: Codable, Sendable, Hashable {
    /// The meal has not ended yet (or has not started).
    case notYet
    /// Open; `closesAt` is 2 days after the meal ended.
    case open(closesAt: Date?)
    /// More than 2 days have passed since the meal ended.
    case closed

    var isOpen: Bool { if case .open = self { return true } else { return false } }
}
