import Foundation

/// The mess context of a signed-in mess staff account.
/// Staff are shown by initials only; the design never invents a staff name.
struct StaffSession: Codable, Sendable, Hashable {
    let role: Role
    let mess: Mess
    let staffInitials: String
    /// The Supervisor of this mess, named on "Send to …" and "… saw it" lines.
    let supervisorName: String
}

enum RolePasswordPolicy {
    static let digits = 4
    static let maximumTries = 3
}

enum RolePasswordResult: Sendable, Hashable {
    case granted(StaffSession)
    case wrong(triesLeft: Int)
    /// "Ask your supervisor to reset it." Who resets it is named when known.
    case locked(resetBy: String?)
}
