import Foundation

/// A student's answer for one meal. Shown as "I'm in", "Skip" and "Not sure".
/// (`in` is a Swift keyword, so the case is `attending`; the wire value stays "in".)
enum MealIntention: String, Codable, Sendable, CaseIterable, Hashable {
    case attending = "in"
    case skipping = "skip"
    case notSure
}

/// "No response" is its own group. It is never counted as a skip, and nobody is denied food for it.
enum IntentionResponse: Codable, Sendable, Hashable {
    case answered(MealIntention, at: Date)
    case noResponse
}

/// How many students gave each answer. These are counts only; a forecast is never derived from them here.
struct MealAnswerCounts: Codable, Sendable, Hashable {
    let attending: Int
    let skipping: Int
    let notSure: Int
    let noResponse: Int
}

enum IntentionPolicy {
    /// Planning cutoff: two hours before the meal starts (owner decision).
    static let cutoffBeforeMeal: TimeInterval = 2 * 60 * 60

    /// Breakfast stays open to answers until its service ends. PENDING the owner's per-meal cutoff decision (Figma
    /// "Open decision / Cutoff time for each meal"): Home · Not answered (221:62529) asks "Breakfast today?" with I'm in,
    /// Skip and the swipe-to-remind at 7:00 AM, which no cutoff before the meal allows.
    static func cutoff(for meal: Meal) -> Date {
        switch meal.slot {
        case .breakfast: meal.endsAt
        case .lunch, .snacks, .dinner: meal.startsAt.addingTimeInterval(-cutoffBeforeMeal)
        }
    }

    /// After the cutoff the answer buttons are disabled. The entry QR is never locked.
    static func canAnswer(_ meal: Meal, at now: Date) -> Bool {
        now < cutoff(for: meal)
    }
}
