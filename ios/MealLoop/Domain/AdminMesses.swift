import Foundation

// Read models for the mess tiles on Today, and the headcount of a mess other than the signed-in one.
// A value the source does not have stays nil: it is never zero.

/// What the vendor has done with a headcount. "Waiting" and "No reply" never read as agreed.
enum AdminVendorReply: Codable, Sendable, Hashable {
    case notSent
    case waiting
    case replied(at: Date)
    case noReply
}

/// A headcount already sent today, as listed under "Sent before".
struct AdminSentBefore: Codable, Sendable, Hashable, Identifiable {
    let title: String
    /// Nil means the record holds no reply.
    let repliedAt: Date?

    var id: String { title }
}

/// One mess for one meal.
struct AdminMessHeadcount: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let name: String
    let slot: MealSlot
    /// Nil means there is no data, which is not the same as nobody coming.
    var expected: Int?
    let rangeLow: Int?
    let rangeHigh: Int?
    let saidYes: Int?
    let usual: Int?
    /// "usual Wed"
    let usualLabel: String?
    /// "None", or what the record says. Nil means it was not recorded.
    let events: String?
    let sendBy: Date?
    /// When a forecast will be ready, for a meal that has none yet.
    let forecastAt: Date?
    var sentAt: Date?
    var reply: AdminVendorReply
    /// How long the vendor has not replied. Held as a sample, so it can't go negative on the story clock.
    let noReplyMinutes: Int?
    let sentBefore: [AdminSentBefore]
    /// The reason the Food Head gave, once the number was changed.
    var adjustmentReason: String?
    /// Who approved the number and when. Nil when the record holds no approval, never assumed.
    var approvedBy: Role? = nil
    var approvedAt: Date? = nil
    /// The forecast frozen at the cutoff, and how many students had answered. Nil when not held, never zero.
    var cutoffForecast: Int? = nil
    var answered: Int? = nil

    var canSend: Bool { expected != nil && sentAt == nil }
}

/// The other messes for one meal slot, and when that meal's headcount is due.
struct AdminMessDay: Codable, Sendable, Hashable {
    let slot: MealSlot
    let headcountDue: Date?
    let messes: [AdminMessHeadcount]
    /// When the signed-in mess's forecast is ready, for a meal the story does not hold.
    var ownForecastAt: Date?
}

/// What a live meal is compared against.
struct AdminLiveReference: Codable, Sendable, Hashable {
    /// Nil means there is no history to compare with.
    let usualByNow: Int?
}

/// How many students of one mess have not answered yet. Counts only, never a name.
struct AdminMessCount: Codable, Sendable, Hashable, Identifiable {
    let name: String
    let students: Int

    var id: String { name }
}
