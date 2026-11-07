import Foundation

/// Words of the My reports, report page, My feedback, Spending, Help and Privacy frames (page 07). This is wording,
/// not data: every name, date and amount comes from `StudentRecordsRepository`.
enum RecordsCopy {
    // My reports (221:63573), Need more info (221:63587), Fixed (221:63606).
    static let myReports = "My reports"
    static let active = "ACTIVE"
    static let closed = "CLOSED"
    static let timeline = "TIMELINE"
    static let noReportsTitle = "No reports yet"
    static let noReportsDetail = "Reports you send show here with where they stand."
    static let reportsOffline = "You're offline. These are the reports you last saw."
    static func stageLabel(_ stage: StudentFiledReportStage) -> String {
        switch stage {
        case .sent: return "Sent"
        case .seen: return "Seen"
        case .needMoreInfo: return "Need more info"
        case .workingOnIt: return "Working on it"
        case .fixed: return "Fixed"
        }
    }
    static func stepCount(_ step: Int) -> String { "\(step)/4" }
    static func referenceLine(_ reference: String, _ day: String) -> String { "\(reference) · \(day.uppercased())" }
    static func mealDay(_ meal: String, _ day: String) -> String { "\(meal) · \(day)" }
    static func messAsked(_ question: String) -> String { "The mess asked: \(question)" }
    static let reply = "Reply"
    static let yourReply = "Your reply"
    static let replyPlaceholder = "Write your answer"
    static let sendReply = "Send reply"
    static let sending = "Sending…"
    static let cancel = "Cancel"
    /// A reply is recorded in the prototype; it never says a person read it.
    static let replyRecorded = "Your reply is recorded."
    static let isItBetter = "Is it better now?"
    static let yesBetter = "Yes, better"
    static let stillBad = "Still bad"
    static let didntTry = "Didn't try it"
    /// Fixed is read only in the prototype: no operation records this answer.
    static let checkNotRecorded = "Answers here aren't recorded in this prototype."
    static func eventTitle(_ kind: StudentReportEvent.Kind) -> String {
        switch kind {
        case .sent: return "Sent"
        case .seen: return "Seen"
        case .askedQuestion: return "Need more info"
        case .replied: return "You replied"
        case .workingOnIt: return "Working on it"
        case .fixed: return "Fixed"
        }
    }
    static func eventDetail(_ kind: StudentReportEvent.Kind) -> String {
        switch kind {
        case .sent: return "You told us"
        case .seen: return "The mess read it"
        case .askedQuestion: return "The mess asked a question"
        case .replied(let text): return text
        case .workingOnIt: return "They're fixing it"
        case .fixed: return "You check if it's better"
        }
    }
    static func withWhen(_ detail: String, _ when: String?) -> String { when.map { "\(detail) · \($0)" } ?? detail }

    // My feedback (2159:151331), Better saved (2159:151464), Empty (2159:151588), Offline (2159:151689).
    static let feedbackSubtitle = "What you reported and what happened"
    static let yourReports = "YOUR REPORTS"
    static let thisMonth = "this month"
    static func fixedCount(_ count: Int) -> String { "\(count) fixed" }
    static func withKitchen(_ count: Int) -> String { "\(count) with the kitchen" }
    static func dishProblem(_ dish: String, _ problem: String) -> String { "\(dish) · \(problem)" }
    static func fixedOn(_ weekday: String) -> String { "Fixed \(weekday)" }
    static let betterToday = "Better today?"
    static let better = "Better"
    static let same = "Same"
    /// Better saved (2159:151464) adds "Thanks, the kitchen sees it."; the prototype sends nothing, so it says only
    /// what was recorded.
    static func youSaid(_ answer: StudentRecheckAnswer) -> String { "You said: \(answer == .better ? "better" : "same")." }
    static func feedbackStage(_ stage: StudentFeedbackStage, _ day: String) -> String {
        switch stage {
        case .reported: return "Reported · \(day)"
        case .seenByKitchen: return "Seen by the kitchen · \(day)"
        case .fixed: return "Fixed · \(day)"
        }
    }
    static let noFeedbackTitle = "No feedback yet"
    static let noFeedbackDetail = "Dish feedback you give shows here with what the kitchen did."
    static let feedbackOffline = "You're offline. This is the feedback you last saw."

    // Spending (221:63988), Empty (221:65727), Offline (221:65753).
    static let privateChip = "Private · only you see this"
    static let monthSoFar = "This month so far"
    static func rupees(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_IN")
        return "₹" + (formatter.string(from: NSNumber(value: amount)) ?? "\(amount)")
    }
    static func thisWeek(_ amount: Int) -> String { "\(rupees(amount)) this week" }
    static let recent = "Recent"
    static let totalMissing = "This month's total isn't available"
    static let noSpendingTitle = "Nothing added yet"
    static let noSpendingDetail = "Spending you add stays on this phone's account and only you see it."
    static let spendingOffline = "You're offline. This is the spending you last saw."
    static func weekRange(_ start: String, _ end: String) -> String { "\(start)–\(end)" }

    // Help (221:64742).
    static let helpSubtitle = "Answers in plain words"
    static let notPublishedYet = "Not published yet"
    static let contactOffice = "Contact the mess office"

    // Terms and privacy (221:64669).
    static let privacyTitle = "Privacy & data"
    static let sharedWithMess = "Shared with the mess"
    static let shared = ["Your meal answers, so they cook the right amount", "Your entry scans at the door",
                         "Your Special pass use", "Reports and feedback you send"]
    static let onlyYou = "Only you"
    static let onlyYouItems = ["Your spending", "Your notification settings"]
    static let noNames = "Community issues never show your name."
    static let yourData = "YOUR DATA"
    static let requestCopy = "Request a copy of your data"
    static let requestDeletion = "Request data deletion"

    // Community · Issue (221:63643).
    static func next(_ step: String) -> String { "Next: \(step)" }
    static let meTooFootnote = "Me too counts you. You can undo it."
}
