import Foundation

/// The diners the kitchen plans for. It is a forecast, never confirmed attendance.
enum Forecast: Codable, Sendable, Hashable {
    case ready(diners: Int, setAt: Date)
    /// Shown as "—" with "Forecast not ready yet".
    case notReady

    var diners: Int? {
        if case .ready(let diners, _) = self { return diners }
        return nil
    }
}

/// A change to the headcount before it is sent. It always carries a reason and stays in the audit history.
struct HeadcountAdjustment: Codable, Sendable, Hashable {
    let from: Int
    let to: Int
    let reason: String
    let adjustedBy: Role
    let adjustedAt: Date
}

struct SentHeadcount: Codable, Sendable, Hashable {
    let count: Int
    let sentAt: Date
    let adjustments: [HeadcountAdjustment]
}

/// The vendor's answer, given through a restricted MealLoop vendor account.
enum VendorReply: Codable, Sendable, Hashable {
    case notSent
    case waiting
    case replied(at: Date, note: String?)
    /// Nothing was recorded. Never treated as an agreement.
    case missing
}

/// Management sends the vendor a headcount only: no dish quantities, no ingredient data.
struct Headcount: Codable, Sendable, Hashable {
    let mealID: MealID
    var forecast: Forecast
    /// Not yet sent when nil.
    var sent: SentHeadcount?
    var vendorReply: VendorReply
}
