import Foundation

/// One closed meal as Meal history and Past meal show it (supervisor S18, S19). Read only.
/// A value the record does not have stays nil or `.unavailable`; it is never filled with zero.
struct MealRecord: Codable, Sendable, Hashable, Identifiable {
    enum ShortageOutcome: Codable, Sendable, Hashable {
        case active
        /// The time is nil when the record does not give it.
        case resolved(at: Date?)
    }

    /// A shortage reported during the meal. The item is nil when the record does not name it.
    struct ShortageLine: Codable, Sendable, Hashable {
        let dishName: String?
        let outcome: ShortageOutcome
    }

    enum WasteStatus: Codable, Sendable, Hashable {
        case notRecorded
        /// Saved by the kitchen. The time is nil when the record does not give it.
        case recorded(at: Date?)
    }

    let mealID: MealID
    let messID: MessID
    let slot: MealSlot
    /// Midnight of the day the meal was served, in the mess time zone.
    let day: Date
    let closedAt: Date?
    let finalEntries: CountReading
    let shortages: [ShortageLine]
    let waste: WasteStatus
    /// The kitchen's rows when the quantities are known. Nil otherwise.
    let wasteReport: WasteReport?

    var id: MealID { mealID }
}
