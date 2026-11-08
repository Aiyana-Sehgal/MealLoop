import Foundation

// Owner ruling (Prompt 2B): the student's hold of "Use pass" is the entry. The pass is then In use for a short, fixed
// time, showing the same live code and colour as the Pass Desk, and then Used for good. The desk records nothing.

/// The backend's rule for how long a used pass may still be shown. Views read it; they never type the number.
enum PassUsePolicy {
    /// Owner ruling: 30 seconds of validity after the hold.
    static let validity: TimeInterval = 30
}

/// Where the student's pass stands for this meal, at an instant.
enum PassUseState: Sendable, Hashable {
    case notUsed
    /// Held "Use pass": still valid to show until `validUntil`.
    case inUse(usedAt: Date, validUntil: Date, secondsLeft: Int)
    /// Past the validity, or recorded as used. It can't be shown or used again.
    case used(usedAt: Date)
}

/// What the desk's "Check last 4 digits" says. A lookup only: it never records.
enum PassDigitCheck: Sendable, Hashable {
    case validNotUsed(SpecialPassHolder, meal: MealSlot)
    case inUse(SpecialPassHolder, secondsLeft: Int)
    case used(SpecialPassHolder, usedAt: Date)
    case notFound
    case noPass(SpecialPassHolder)
    case wrongMeal(SpecialPassHolder, passFor: MealSlot)
}
