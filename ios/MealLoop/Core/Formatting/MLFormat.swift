import Foundation

/// Formatting shared by every screen. Times are shown in the mess's time zone.
enum MLFormat {
    /// "1:40 PM"
    static func time(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    /// "12–2 PM", "7:30–9:30 AM", "11:30 AM–1 PM". Whole hours drop ":00".
    static func timeRange(_ start: Date, _ end: Date, in timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        func clock(_ date: Date) -> (text: String, period: String) {
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            let hour12 = hour % 12 == 0 ? 12 : hour % 12
            let text = minute == 0 ? "\(hour12)" : String(format: "%d:%02d", hour12, minute)
            return (text, hour < 12 ? "AM" : "PM")
        }
        let a = clock(start)
        let b = clock(end)
        if a.period == b.period {
            return "\(a.text)–\(b.text) \(b.period)"
        }
        return "\(a.text) \(a.period)–\(b.text) \(b.period)"
    }

    /// "1 h 40 min", "55 min", "2 h"
    static func elapsed(minutes: Int) -> String {
        let safe = max(0, minutes)
        let hours = safe / 60
        let rest = safe % 60
        switch (hours, rest) {
        case (0, _): return "\(rest) min"
        case (_, 0): return "\(hours) h"
        default: return "\(hours) h \(rest) min"
        }
    }

    static func minutes(from start: Date, to end: Date) -> Int {
        Int(end.timeIntervalSince(start) / 60)
    }

    /// Plain words for a shortage level, as used in "Steamed Rice, almost out".
    static func shortageLevel(_ level: ShortageLevel) -> String {
        switch level {
        case .gettingLow: return "getting low"
        case .almostOut: return "almost out"
        case .out: return "out"
        }
    }

    static func mealSlot(_ slot: MealSlot) -> String {
        switch slot {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .snacks: return "Snacks"
        case .dinner: return "Dinner"
        }
    }

    static func roleName(_ role: Role) -> String {
        switch role {
        case .student: return "Student"
        case .superAdmin: return "Super Admin"
        case .admin: return "Food Head / Admin"
        case .doorScanner: return "Door Scanner"
        case .passDesk: return "Pass Desk"
        case .kitchenStaff: return "Kitchen Staff"
        case .supervisor: return "Supervisor"
        case .guardian: return "Guardian"
        case .vendor: return "Vendor"
        case .warden: return "Warden"
        case .gate: return "Gate Security"
        }
    }
}
