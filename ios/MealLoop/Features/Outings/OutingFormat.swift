import Foundation

/// Formatting for the outing screens (Guardian, Warden, Gate). Times are shown in the hostel's time zone (India),
/// in the forms the guardian pack draws: "Sat", "Sat 17", "Sat 17 Aug", "12 PM", "10:05 AM", "Sat 2–8 PM".
enum OutingFormat {
    static let timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private static func format(_ date: Date, _ pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }

    /// "Sat"
    static func weekday(_ date: Date) -> String { format(date, "EEE") }
    /// "Sat 17"
    static func dayShort(_ date: Date) -> String { format(date, "EEE d") }
    /// "Sat 17 Aug"
    static func dayLong(_ date: Date) -> String { format(date, "EEE d MMM") }
    /// "Mon 16 Sep"
    static func dayMonth(_ date: Date) -> String { format(date, "EEE d MMM") }

    /// "12 PM", "10:05 AM": whole hours drop ":00".
    static func hour(_ date: Date) -> String {
        let minute = calendar.component(.minute, from: date)
        return minute == 0 ? format(date, "h a") : format(date, "h:mm a")
    }

    /// "1:04 PM", always with minutes (gate times).
    static func clock(_ date: Date) -> String { format(date, "h:mm a") }

    /// "Sat 12 PM", "Fri 11 PM"
    static func dayHour(_ date: Date) -> String { "\(weekday(date)) \(hour(date))" }

    /// "Sat 2–8 PM"
    static func window(_ start: Date, _ end: Date) -> String {
        "\(weekday(start)) \(MLFormat.timeRange(start, end, in: timeZone))"
    }

    /// "2–8 PM"
    static func hours(_ start: Date, _ end: Date) -> String { MLFormat.timeRange(start, end, in: timeZone) }

    /// "2 → 8 PM", the guardian's form.
    static func arrowHours(_ start: Date, _ end: Date) -> String {
        hours(start, end).replacingOccurrences(of: "–", with: " → ")
    }

    /// "2 h", "48 min", "2 h 48 min"
    static func span(from start: Date, to end: Date) -> String {
        MLFormat.elapsed(minutes: max(0, MLFormat.minutes(from: start, to: end)))
    }

    /// Whole hours left, rounded down, for the deadline ring ("2 h"). Under an hour shows minutes.
    static func shortLeft(from now: Date, to deadline: Date) -> String {
        let minutes = MLFormat.minutes(from: now, to: deadline)
        if minutes <= 0 { return "0" }
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60) h"
    }

    static func isSameDay(_ a: Date, _ b: Date) -> Bool { calendar.isDate(a, inSameDayAs: b) }

    /// True when both dates fall in the same calendar week (Sunday to Saturday).
    static func isSameWeek(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, equalTo: b, toGranularity: .weekOfYear)
    }

    /// Hour of the day as a fraction of a 12-hour dial, 0 at 12 o'clock.
    static func dialFraction(_ date: Date) -> Double {
        let hour = calendar.component(.hour, from: date) % 12
        let minute = calendar.component(.minute, from: date)
        return (Double(hour) + Double(minute) / 60) / 12
    }

    /// "+91 98••• ••557" stays as stored; nil shows the missing mark.
    static func orMissing(_ text: String?) -> String { text ?? "—" }
}
