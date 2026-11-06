import Foundation

/// Interface copy for the Student root, Home, the answer page and Entry QR. This is wording, not data.
/// Sources: design/audit/export_redesign 03, 04, 07 and 08, and the redesign prompt's stage P5 for the locked state.
enum StudentCopy {
    static let brand = "MealLoop"

    static func greeting(_ name: String) -> String { "Hey \(name)" }

    static let imIn = "I'm in"
    static let skipped = "Skipped"
    static let notSure = "Not sure"
    static let notAnswered = "Not answered"
    static let showEntryQR = "Show entry QR"
    static let answer = "Answer"
    static let change = "Change"

    static func eyebrow(_ slot: MealSlot) -> String {
        switch slot {
        case .breakfast: return "This morning"
        case .lunch: return "This afternoon"
        case .snacks, .dinner: return "This evening"
        }
    }

    private static func mealWord(_ slot: MealSlot) -> String { MLFormat.mealSlot(slot).lowercased() }

    static func youreIn(_ slot: MealSlot) -> String { "You're in for \(mealWord(slot))" }
    static func youSkipped(_ slot: MealSlot) -> String { "You skipped \(mealWord(slot))" }
    /// Not drawn: the owner asked for the Skip layout with its own wording.
    static func youreNotSure(_ slot: MealSlot) -> String { "Not sure about \(mealWord(slot))" }
    static func mealToday(_ slot: MealSlot) -> String { "\(MLFormat.mealSlot(slot)) today?" }
    static func youInFor(_ slot: MealSlot) -> String { "You in for \(mealWord(slot))?" }

    static func serving(_ range: String) -> String { "Serving \(range)" }
    static let canStillEat = "Changed your mind? You can still eat."
    static let notSureCanEat = "You can still eat."
    static func decideBy(_ time: String, left: String) -> String { "Decide by \(time) · \(unbroken("\(left) left"))" }
    static func changeBy(_ time: String, left: String) -> String { "Change by \(time) · \(unbroken("\(left) left"))" }
    static func answerBy(_ range: String, time: String, left: String) -> String { "\(range) · answer by \(time), \(left) left" }
    static func answersClosed(_ time: String) -> String { "Answers closed at \(time). Your QR still works." }

    /// Keeps a duration on one line, so "3 h left" never splits between the number and its unit.
    private static func unbroken(_ text: String) -> String { text.replacingOccurrences(of: " ", with: "\u{00A0}") }

    static let footerLocked = "The entry QR is never locked."
    static let footerPlan = "Your answer only helps the kitchen plan."
    static let answerFooter = "You can still eat if you skip. Your QR always works."
    static let highlight = "Highlight"
    static let vegetarian = "Vegetarian"
    static let nonVegetarian = "Non-vegetarian"
    static let menuUnavailable = "The menu isn't available yet."

    static let entryQR = "Entry QR"
    static let youreInChip = "You're in"
    static let live = "Live"
    static let holdUp = "Hold this up to the scanner."
    static let cantScan = "Can't scan? Give the door staff your SRM ID."
    static let qrUnavailable = "The QR can't be shown right now."
    static func qrLabel(_ name: String, maskedID: String) -> String { "Entry QR code for \(name), \(maskedID)" }
    static func entrySubtitle(_ slot: MealSlot?, mess: String) -> String {
        slot.map { "\(MLFormat.mealSlot($0)) · \(mess)" } ?? mess
    }
}

/// Short times for the student screens, in the mess's time zone. "10 AM", "5:30 AM".
enum StudentFormat {
    static func shortTime(_ date: Date, in timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = calendar.component(.minute, from: date) == 0 ? "h a" : "h:mm a"
        return formatter.string(from: date)
    }

    /// "Wednesday 14 Aug"
    static func day(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEEE d MMM"
        return formatter.string(from: date)
    }
}
