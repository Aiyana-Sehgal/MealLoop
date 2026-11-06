import Foundation

/// Every person who uses MealLoop: the 11 approved roles. One account has exactly one role.
enum Role: String, Codable, Sendable, CaseIterable, Hashable, Identifiable {
    case student
    /// Account provisioning and role assignment. A separate role from Food Head / Admin.
    case superAdmin
    /// Food Head and administrators (the admin app: Today, Students, Results, More).
    case admin
    case supervisor
    case kitchenStaff
    case doorScanner
    case passDesk
    /// A MealLoop-managed account with a restricted scope, not an external API client.
    case vendor
    case guardian
    case warden
    case gate

    /// The four mess staff roles, which share the Home, Alerts and Me tabs.
    static let staffRoles: [Role] = [.doorScanner, .passDesk, .kitchenStaff, .supervisor]

    var isMessStaff: Bool { Role.staffRoles.contains(self) }

    var id: String { rawValue }
}
