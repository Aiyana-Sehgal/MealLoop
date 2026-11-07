import Foundation

// The Student "You" area: Notifications, the profile, Credits and Attendance. Additive models; nothing existing uses them.

enum StudentNotificationTag {}
typealias StudentNotificationID = Identifier<StudentNotificationTag>

/// What a notification is about. It picks the icon only; the words come with the notification.
enum StudentNotificationKind: String, Codable, Sendable, Hashable, CaseIterable {
    case outingGuardianApproved
    case outingUpdate
    case mealQuestion
    case menuChanged
    case feedbackSeen
    case specialPass
}

/// One notification as the student's inbox stores it. It never says a message reached a person; it says what the
/// mess or the outing record shows.
struct StudentNotification: Codable, Sendable, Hashable, Identifiable {
    let id: StudentNotificationID
    let kind: StudentNotificationKind
    let title: String
    let detail: String
    let at: Date
    var isRead: Bool
}

/// A ticket the student can get with credits (Credits 221:64313).
struct StudentCreditTicket: Codable, Sendable, Hashable, Identifiable {
    enum Availability: Codable, Sendable, Hashable {
        case available
        /// Not yet offered. The note is the mess's own words ("Launches Friday").
        case notYet(note: String)
    }

    let id: String
    let name: String
    let place: String
    let cost: Int
    let availability: Availability
}

/// One line of Credits history (221:64443). `points` is negative for a redeemed ticket.
struct StudentCreditEntry: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let title: String
    let day: Date
    let points: Int
}

/// The student's credits. `balance` is nil when the source has none; it is never shown as zero.
struct StudentCredits: Codable, Sendable, Hashable {
    let balance: Int?
    let tickets: [StudentCreditTicket]
    let history: [StudentCreditEntry]

    /// The cheapest ticket the balance does not reach yet, and how many points are missing.
    var nextGoal: (ticket: StudentCreditTicket, missing: Int)? {
        guard let balance else { return nil }
        return tickets.filter { $0.cost > balance }.min { $0.cost < $1.cost }.map { ($0, $0.cost - balance) }
    }
}

/// Participation credits. A definite answer (I'm in or Skip) earns; Not sure and No response earn nothing.
/// How many points a definite answer earns is not decided (open decision P1); the source passes its own number.
enum StudentCreditRule {
    static func points(for response: IntentionResponse, perDefiniteAnswer: Int) -> Int {
        switch response {
        case .answered(.attending, _), .answered(.skipping, _): return perDefiniteAnswer
        case .answered(.notSure, _), .noResponse: return 0
        }
    }
}

/// One day on the attendance calendar. A day with no entry recorded is never called absent: a missing scan is not
/// proof that the student was away.
enum StudentAttendanceMark: String, Codable, Sendable, Hashable {
    /// An entry was recorded for every meal the mess served.
    case everyMeal
    /// At least one meal has no entry recorded.
    case noEntryForAMeal
    case today
    /// Nothing is recorded for this day (a future day, or no record).
    case noRecord
}

struct StudentAttendanceMonth: Codable, Sendable, Hashable {
    /// The first day of the month, in the mess's time zone.
    let month: Date
    /// Day of the month (1...31) to its mark. Days missing here have no record.
    let marks: [Int: StudentAttendanceMark]
    let daysInMonth: Int
    /// Weekday of the 1st, Monday = 0.
    let firstWeekdayOffset: Int
    /// Meals with an entry recorded and meals served this month so far. Nil when unknown, never zero.
    let mealsEntered: Int?
    let mealsServed: Int?

    /// Rounded share of served meals with an entry, or nil when either count is missing.
    var percentEntered: Int? {
        guard let mealsEntered, let mealsServed, mealsServed > 0 else { return nil }
        return Int((Double(mealsEntered) / Double(mealsServed) * 100).rounded())
    }

    /// The longest run of consecutive days with an entry for every meal.
    var bestStreak: Int {
        var best = 0
        var run = 0
        for day in 1...max(1, daysInMonth) {
            if marks[day] == .everyMeal { run += 1; best = max(best, run) } else { run = 0 }
        }
        return best
    }
}

/// The You page's header and its rows' small values.
struct StudentProfileSummary: Codable, Sendable, Hashable {
    let firstName: String?
    let maskedID: String
    let messName: String
    let credits: Int?
}
