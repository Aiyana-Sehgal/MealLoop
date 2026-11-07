import Foundation

/// One meal as the vendor account sees it: the headcount sent and the reply, nothing else.
/// No dish quantities and no cooking or buying advice reach the vendor.
struct VendorHeadcountEntry: Sendable, Hashable, Identifiable {
    let meal: Meal
    /// Nil when the headcount has not been sent. Never zero for "unknown".
    let sentCount: Int?
    /// Nil when the send time is not known, even if it was sent.
    let sentAt: Date?
    /// Nil means Pending: a reply is never filled in.
    let acknowledgedAt: Date?
    /// True for a value the pack supplies as a sample, not one recorded in this session.
    let isSample: Bool

    var id: MealID { meal.id }
    var isSent: Bool { sentCount != nil }
}
