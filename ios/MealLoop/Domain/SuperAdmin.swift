import Foundation

// Super Admin: accounts only. There is no approved design for this role; these are the minimal records the screens
// need. A Super Admin never sees a password and has no Food Head powers.

/// An account as the Super Admin manages it. It has no password, hash or token field, so none can be shown.
struct ManagedAccount: Codable, Sendable, Hashable, Identifiable {
    let account: Account
    /// False once a deactivation is recorded in this run.
    let isActive: Bool
    /// When the deactivation was recorded, if it was.
    let deactivatedAt: Date?
    /// When a password reset was started, if it was.
    let resetStartedAt: Date?

    var id: AccountID { account.id }
}
