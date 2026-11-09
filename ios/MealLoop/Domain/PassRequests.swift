import Foundation

// Special pass approval for the upcoming week (owner decision, 9 November; approved images student_pass_04_request,
// student_pass_05_requested, admin_passes_01_requests). A student asks for next week's pass; only the Admin accepts it;
// the pass is usable only once accepted and only in that week. Staff see a masked ID, never a name.

enum PassRequestTag {}
typealias PassRequestID = Identifier<PassRequestTag>

/// Monday to Sunday, in the mess's time zone.
struct PassWeek: Codable, Sendable, Hashable {
    let start: Date
    /// The start of the Sunday.
    let end: Date

    func contains(_ date: Date, calendar: Calendar) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day >= start && day <= end
    }
}

enum PassRequestState: String, Codable, Sendable, Hashable {
    case pending
    case accepted
    case declined
    case cancelled
}

struct PassRequest: Codable, Sendable, Hashable, Identifiable {
    let id: PassRequestID
    let student: StudentID
    /// "••0238". Never a name.
    let maskedID: String
    let messName: String
    let week: PassWeek
    let requestedAt: Date
    var state: PassRequestState
    var decidedAt: Date?
}

/// The Admin's queue for next week: what waits, and how many were accepted.
struct PassRequestQueue: Codable, Sendable, Hashable {
    let week: PassWeek
    let pending: [PassRequest]
    let approvedCount: Int
}

enum PassWeekMath {
    static func calendar(_ timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        return calendar
    }

    static func week(containing date: Date, timeZone: TimeZone) -> PassWeek {
        let calendar = calendar(timeZone)
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        return PassWeek(start: start, end: end)
    }

    static func nextWeek(after date: Date, timeZone: TimeZone) -> PassWeek {
        let current = week(containing: date, timeZone: timeZone)
        let calendar = calendar(timeZone)
        let start = calendar.date(byAdding: .day, value: 7, to: current.start) ?? current.start
        return PassWeek(start: start, end: calendar.date(byAdding: .day, value: 6, to: start) ?? start)
    }
}
