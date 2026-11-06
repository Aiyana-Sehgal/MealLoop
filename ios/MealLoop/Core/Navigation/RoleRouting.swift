import Foundation

/// The root area an account lands in. Exactly one per role, so no role shares another role's screens.
enum RoleRoot: String, CaseIterable, Hashable, Sendable {
    case student
    case superAdmin
    case admin
    case supervisor
    case kitchen
    case doorScanner
    case passDesk
    case vendor
    case guardian
    case warden
    case gate

    /// The single place that maps a role to its root.
    static func destination(for role: Role) -> RoleRoot {
        switch role {
        case .student: return .student
        case .superAdmin: return .superAdmin
        case .admin: return .admin
        case .supervisor: return .supervisor
        case .kitchenStaff: return .kitchen
        case .doorScanner: return .doorScanner
        case .passDesk: return .passDesk
        case .vendor: return .vendor
        case .guardian: return .guardian
        case .warden: return .warden
        case .gate: return .gate
        }
    }

    /// True for the roots that use the shared staff tabs (Home, Alerts, Me).
    var usesStaffTabs: Bool {
        switch self {
        case .supervisor, .kitchen, .doorScanner, .passDesk: return true
        default: return false
        }
    }

    /// Tab titles of the roots that are not built yet. Empty means the root has no tab bar.
    /// Student, Admin and Warden come from their packs. Gate, Vendor and Super Admin have no documented tabs,
    /// so they get the smallest chrome that can hold a Home and Sign out. Guardian is a single-page web flow.
    var placeholderTabs: [String] {
        switch self {
        case .student: return ["Home", "Meals", "Community", "You"]
        case .admin: return ["Today", "Students", "Results", "More"]
        case .warden: return ["Queue", "Out now", "Escalated", "History"]
        case .gate, .vendor, .superAdmin: return ["Home", "Me"]
        case .guardian, .supervisor, .kitchen, .doorScanner, .passDesk: return []
        }
    }
}
