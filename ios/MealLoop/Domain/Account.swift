import Foundation

/// Marker for `HostelID`. Hostels have no model of their own yet.
enum HostelTag {}

typealias AccountID = Identifier<Account>
typealias HostelID = Identifier<HostelTag>

/// What an account is limited to. The server enforces this; the client only shapes the interface.
enum AccountScope: Codable, Sendable, Hashable {
    case mess(MessID)
    case hostel(HostelID)
}

/// A person who can sign in. It holds no password or token.
struct Account: Codable, Sendable, Hashable, Identifiable {
    let id: AccountID
    let displayName: String
    let email: String
    let role: Role
    let scope: AccountScope
}

/// The signed-in account. `staff` is set only for the four mess staff roles.
struct Session: Sendable, Hashable {
    let account: Account
    let staff: StaffSession?
}
