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

/// The headcount the Food Head / Admin approved. It always comes from a person, never from the forecast.
struct ApprovedHeadcount: Codable, Sendable, Hashable {
    let count: Int
    let approvedBy: Role
    let approvedAt: Date
    let adjustments: [HeadcountAdjustment]
}

/// Approval is explicit. There is no automatic approval (FR-HC-005).
enum HeadcountApproval: Codable, Sendable, Hashable {
    case notApproved
    case approved(ApprovedHeadcount)

    var count: Int? {
        if case .approved(let headcount) = self { return headcount.count }
        return nil
    }
}

/// The approved headcount as published to the vendor account.
struct SentHeadcount: Codable, Sendable, Hashable {
    let count: Int
    let sentBy: Role
    let sentAt: Date
}

enum VendorPublication: Codable, Sendable, Hashable {
    case notSent
    case sent(SentHeadcount)

    var count: Int? {
        if case .sent(let headcount) = self { return headcount.count }
        return nil
    }
}

/// The vendor's acknowledgment of receipt, made through its restricted MealLoop account.
struct VendorAcknowledgment: Codable, Sendable, Hashable {
    let acknowledgedBy: AccountID
    let acknowledgedAt: Date
}

/// What the Food Head sees. Publishing is never an acknowledgment and pending never reads as replied or agreed.
enum VendorAcknowledgmentStatus: Sendable, Hashable {
    case notPublished
    case pending(publishedAt: Date)
    case acknowledged(VendorAcknowledgment)
}

/// The six headcount quantities of one meal (FR-HC-002). They stay separate: no field is filled from another.
/// Management sends the vendor a headcount only: no dish quantities, no ingredient data.
struct Headcount: Codable, Sendable, Hashable {
    let mealID: MealID
    /// Moves as students answer.
    var liveForecast: Forecast
    /// The forecast frozen at the cutoff. `.notReady` until one has been frozen.
    var cutoffForecast: Forecast
    var approved: HeadcountApproval
    var sentToVendor: VendorPublication
    /// Entries so far, during service only. Never final.
    var actualEntries: CountReading
    /// `.unavailable` until the meal closes, never zero.
    var finalEntries: CountReading
    /// Set only by the vendor acting. Read `vendorAcknowledgmentStatus` instead.
    var acknowledgment: VendorAcknowledgment?

    /// Derived, so a record without a publication can never show as acknowledged.
    var vendorAcknowledgmentStatus: VendorAcknowledgmentStatus {
        guard case .sent(let sent) = sentToVendor else { return .notPublished }
        if let acknowledgment { return .acknowledged(acknowledgment) }
        return .pending(publishedAt: sent.sentAt)
    }
}
