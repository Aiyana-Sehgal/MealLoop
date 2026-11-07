import Foundation

/// Vendor wording, from the Part 6 brief. Every number and time comes from data.
enum VendorCopy {
    static let notApprovedYet = "Not approved yet"
    static let notSentYet = "Not sent yet"
    static let waitingForApproval = "Waiting for the Food Head to approve."
    static let waitingForSend = "Waiting for the Food Head to send."
    static let approvedHeadcount = "Approved headcount"
    static let sentWaiting = "Sent · waiting for you"
    static func acknowledged(_ time: String) -> String { "Acknowledged \(time)" }
    static func sent(_ time: String) -> String { "Sent \(time)" }
    static let sentNoTime = "Sent"
    static func sentAndAcknowledged(_ sent: String, _ acknowledged: String) -> String { "\(sent) · Acknowledged \(acknowledged)" }
    static let acknowledgeReceipt = "Acknowledge receipt"
    static let approvedOnly = "You see the approved headcount only."
    static let noConnection = "No connection."
    static let yourReply = "Your reply"
    static let couldNotSend = "Couldn't send"
    static let retry = "Retry"
    static let notReached = "Your acknowledgment hasn't reached MealLoop yet."
    static let history = "History"
    static func historySubtitle(_ mess: String) -> String { mess }
    static let today = "Today"
    static let acknowledgedWord = "acknowledged"
    static let repliedWord = "replied"
    static let pending = "Pending"
    static let pendingNote = "A missing reply shows as Pending. It is never filled in."
    static let unavailable = "unavailable"
    static let noMealTitle = "No meal today"
    static let noMealDetail = "The next meal will show here."
    static let nothingSentYet = "Nothing sent yet"
    static let nothingSentYetDetail = "Headcounts the Food Head sends show here."
    static let me = "Me"
    static let signOut = "Sign out"
    static let home = "Home"
}
