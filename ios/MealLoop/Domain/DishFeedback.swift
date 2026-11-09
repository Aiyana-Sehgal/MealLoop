import Foundation

// Dish feedback from Not good (Figma file nzzTAm9YnJRSdKEeYUWUEb, page 07: Feedback · What's wrong · Sambar 2159:149347
// and the other "Feedback · …" sheets 2159:6 to 2159:151121). The student picks one problem, how bad, and an optional
// note. The kitchen sees the dish, the problem and how bad, never the student's name. Feedback earns no credits.
// An urgent hygiene, contamination, illness or safety problem is not dish feedback: it goes through SOS.

/// How bad? (SeveritySegmented 2136:2382). "Quite" is preselected.
enum DishFeedbackSeverity: String, Codable, Sendable, Hashable, CaseIterable {
    case aBit
    case quite
    case very
}

/// The six problem glyphs of the pack (ProblemGlyph 2129:2324).
enum DishProblemGlyph: String, Codable, Sendable, Hashable {
    case salt
    case spicy
    case drop
    case sour
    case cold
    case little
}

/// One choice of "What's wrong?" (ProblemTile 2136:2360).
struct DishProblemOption: Codable, Sendable, Hashable, Identifiable {
    var id: String { title }
    let title: String
    let glyph: DishProblemGlyph
}

/// What the student sends. Never carries the student's name: the sender is passed apart and only counted.
struct DishFeedbackSubmission: Codable, Sendable, Hashable {
    let dishName: String
    /// The start of the meal's day, in the mess's time zone.
    let day: Date
    let slot: MealSlot
    let problem: String
    let severity: DishFeedbackSeverity
    /// Nil when the student wrote nothing.
    let note: String?
    /// The same key sends once, however many times it is retried.
    let key: IdempotencyKey
}

/// A recorded send, for the Sent sheet (2159:150785).
struct DishFeedbackReceipt: Codable, Sendable, Hashable {
    let submission: DishFeedbackSubmission
    let sentAt: Date
}

/// "Most reported today" on Which dish (2159:285): the dish and problem most students reported for this meal, and how
/// many. Nil when nobody reported anything.
struct DishMostReported: Codable, Sendable, Hashable {
    let dishName: String
    let problem: String
    let students: Int
}
