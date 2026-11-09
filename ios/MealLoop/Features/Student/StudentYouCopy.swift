import Foundation

/// Words of the Notifications, You, Credits and Attendance frames (page 07). This is wording, not data.
enum YouCopy {
    static let notifications = "Notifications"
    static let today = "Today"
    static let earlier = "Earlier"
    static let yesterday = "Yesterday"
    static let unread = "Unread"
    static let noNotificationsTitle = "No notifications"
    static let noNotificationsDetail = "Meal reminders, outing updates and replies to your feedback show here."
    static let offline = "You're offline."
    static let notificationsOffline = "You're offline. These are the notifications you last saw."
    static let gettingNotifications = "Getting notifications"
    /// Offline with nothing saved: never shown as an empty inbox.
    static let nothingSaved = "Your notifications will show when you're back online."

    static let you = "You"
    static let outings = "Outings"
    static let credits = "Credits"
    static let attendance = "Attendance"
    static let spending = "Spending"
    static let myFeedback = "My feedback"
    static let help = "Help"
    static let terms = "Terms and privacy"
    static let signOut = "Sign out"
    static let youOffline = "You're offline. Some details may be out of date."
    static func idAndMess(_ maskedID: String, _ mess: String) -> String { maskedID.isEmpty ? mess : "\(maskedID) · \(mess)" }
    static func points(_ value: Int) -> String { "\(value) pts" }

    static let creditsSubtitle = "Earned by showing up. Never lost for a missed meal."
    static let pts = "pts"
    static let tickets = "Tickets"
    static let get = "Get"
    static let history = "History"
    static let creditsHistory = "Credits history"
    static let balance = "BALANCE"
    static let noBalance = "Your balance isn't available right now."
    static let creditsOffline = "You're offline. Tickets can't be got until you're back."
    static let noHistoryTitle = "No credits yet"
    static let noHistoryDetail = "Answer a meal question to earn your first credits."
    static func moreFor(_ missing: Int, _ ticket: String) -> String { "\(missing) more for the \(ticket)" }
    static func more(_ missing: Int) -> String { "\(missing) more" }
    static func signed(_ points: Int) -> String { points >= 0 ? "+\(points) pts" : "−\(-points) pts" }
    static func entryLine(_ title: String, _ day: String) -> String { "\(title) · \(day)" }

    static let attendanceSubtitle = "The days you came to the mess"
    static func mealsOf(_ entered: Int, _ served: Int) -> String { "\(entered) of \(served) meals" }
    static let cameThisMonth = "you came this month so far"
    static func bestStreak(_ days: Int) -> String { "Best streak: \(days) \(days == 1 ? "day" : "days")" }
    static let countsMissing = "Meal counts aren't available yet"
    static let everyMeal = "Came to every meal"
    /// Attendance (221:64717) says "Missed a meal". A missing scan is not proof the student was away, so the
    /// legend says only that no entry was recorded.
    static let noEntry = "No entry for a meal"
    static let missingScanNote = "No entry means no scan was recorded, not that you were away."
    /// Under the calendar while a missed day can be corrected (Entry · Discrepancy, 221:63082).
    static let tapMissedDay = "Ate but not scanned? Tap the circled day to ask for a correction."
    static let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
    static let attendanceOffline = "You're offline. This is the attendance you last saw."
}
