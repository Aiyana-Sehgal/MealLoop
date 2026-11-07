import Foundation

// The Student records behind the You rows and the report pages: My reports (with Need more info and Fixed), My
// feedback, Spending, Help and the updates under a Community problem. Additive models; nothing existing uses them.

enum StudentFiledReportTag {}
typealias StudentFiledReportID = Identifier<StudentFiledReportTag>
enum StudentFeedbackTag {}
typealias StudentFeedbackID = Identifier<StudentFeedbackTag>

/// Where a report the student sent stands, as the StepBar draws it: Sent → Seen → Working on it → Fixed, plus Need
/// more info, which sits on the second step.
enum StudentFiledReportStage: String, Codable, Sendable, Hashable, CaseIterable {
    case sent
    case seen
    case needMoreInfo
    case workingOnIt
    case fixed

    /// The step the bar fills to, out of four.
    var step: Int {
        switch self {
        case .sent: return 1
        case .seen, .needMoreInfo: return 2
        case .workingOnIt: return 3
        case .fixed: return 4
        }
    }

    var isClosed: Bool { self == .fixed }
}

/// One dated line of a report's timeline. It names the role that acted, never a person.
struct StudentReportEvent: Codable, Sendable, Hashable {
    enum Kind: Codable, Sendable, Hashable {
        case sent
        case seen
        case askedQuestion
        /// The student's own reply. Recorded only; it never says a person read it.
        case replied(String)
        case workingOnIt
        case fixed
    }

    let kind: Kind
    /// Nil when the frame draws no time for the step.
    let at: Date?
    /// The step the report is on now (lime node).
    let isCurrent: Bool
}

/// A report the student sent, as My reports (221:63573) and the report page show it.
struct StudentFiledReport: Codable, Sendable, Hashable, Identifiable {
    let id: StudentFiledReportID
    /// "ML-1031".
    let reference: String
    let category: StudentReportCategory
    /// "Main Mess · Block A". Nil when nothing was recorded.
    let place: String?
    let meal: MealSlot?
    let sentAt: Date
    let stage: StudentFiledReportStage
    /// The mess's question on Need more info, in its own words.
    let question: String?
    /// The student's reply, once recorded.
    let reply: String?
    let events: [StudentReportEvent]
}

/// Where a dish feedback stands (My feedback 2159:151331).
enum StudentFeedbackStage: String, Codable, Sendable, Hashable {
    case reported
    case seenByKitchen
    case fixed

    /// Filled segments out of three.
    var step: Int {
        switch self {
        case .reported: return 1
        case .seenByKitchen: return 2
        case .fixed: return 3
        }
    }
}

/// "Better today?" after a fix. Recorded only.
enum StudentRecheckAnswer: String, Codable, Sendable, Hashable {
    case better
    case same
}

/// One dish feedback the student gave.
struct StudentFeedbackItem: Codable, Sendable, Hashable, Identifiable {
    let id: StudentFeedbackID
    let dish: String
    /// "Too salty".
    let problem: String
    let stage: StudentFeedbackStage
    /// When it last moved (reported, seen or fixed).
    let at: Date
    /// The kitchen's own words about the fix ("Less salt from Thursday 8 Aug."). Nil when it wrote nothing.
    let fixNote: String?
    let recheck: StudentRecheckAnswer?
}

/// My feedback. The counts are computed from the items, never typed in.
struct StudentFeedbackSummary: Codable, Sendable, Hashable {
    let items: [StudentFeedbackItem]

    var total: Int { items.count }
    var fixed: Int { items.filter { $0.stage == .fixed }.count }
    var withTheKitchen: Int { items.filter { $0.stage == .seenByKitchen }.count }
}

/// One week bar on Spending. The amount is nil when nothing was recorded; a missing week is never zero.
struct StudentSpendingWeek: Codable, Sendable, Hashable, Identifiable {
    var id: Date { start }
    let start: Date
    let end: Date
    let amount: Int?
    let isCurrent: Bool
}

/// One line of "Recent" on Spending.
struct StudentSpendingEntry: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let title: String
    let day: Date
    /// "dinner order". Nil when the student wrote nothing.
    let note: String?
    let amount: Int
}

/// Private spending, seen only by the student (Spending 221:63988). Amounts are whole rupees.
struct StudentSpending: Codable, Sendable, Hashable {
    let weeks: [StudentSpendingWeek]
    let recent: [StudentSpendingEntry]

    /// Nil when any week is missing, so a partial month is never shown as a total.
    var monthTotal: Int? {
        guard !weeks.isEmpty else { return nil }
        let amounts = weeks.compactMap(\.amount)
        return amounts.count == weeks.count ? amounts.reduce(0, +) : nil
    }

    var thisWeek: Int? { weeks.first(where: \.isCurrent)?.amount }
}

/// A Help question. The answer is nil when the mess has not published one.
struct StudentHelpTopic: Codable, Sendable, Hashable, Identifiable {
    var id: String { question }
    let question: String
    let answer: String?
}

/// Help (221:64742).
struct StudentHelp: Codable, Sendable, Hashable {
    let topics: [StudentHelpTopic]
    /// "Mess office, Block A · 9 AM–5 PM". Nil when the mess published no contact.
    let contact: String?
}

/// One update under a Community problem ("Seen by the team · Tue 13 Aug, 3:10 PM"). It names no person.
struct StudentIssueUpdate: Codable, Sendable, Hashable {
    let title: String
    /// Nil for the next step, which has not happened.
    let at: Date?
    /// "Next: the team picks an owner". Drawn hollow.
    let isNext: Bool
}
