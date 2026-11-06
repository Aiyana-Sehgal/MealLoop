import Foundation

/// Formatting only the Supervisor screens need. Shared formats stay in `MLFormat`.
enum SupervisorFormat {
    /// "Wed 14"
    static func shortDay(_ date: Date, in timeZone: TimeZone) -> String {
        format(date, "EEE d", timeZone)
    }

    /// "Tue 13 Aug"
    static func dayAndMonth(_ date: Date, in timeZone: TimeZone) -> String {
        format(date, "EEE d MMM", timeZone)
    }

    /// "Almost out" from "almost out".
    static func sentenceCase(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }

    /// Who did something, as a short phrase: "the door", "the desk", "the kitchen", "the supervisor".
    static func who(_ role: Role) -> String {
        switch role {
        case .doorScanner: return "the door"
        case .passDesk: return "the desk"
        case .kitchenStaff: return "the kitchen"
        case .supervisor: return "the supervisor"
        case .admin: return "the food head"
        default: return MLFormat.roleName(role).lowercased()
        }
    }

    /// "4", "2.5": a quantity without trailing zeros. Never used for a missing value.
    static func quantity(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// "kg", "L", "pieces"
    static func unit(_ unit: WasteUnit) -> String { unit.symbol }

    private static func format(_ date: Date, _ pattern: String, _ timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}
