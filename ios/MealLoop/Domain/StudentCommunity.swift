import Foundation

/// Where a Community problem stands, as the four segments draw it: Reported, Seen, Fixing, Fixed.
enum StudentIssueStage: Int, Codable, Sendable, CaseIterable, Hashable, Comparable {
    case reported
    case seen
    case fixing
    case fixed

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A Community problem as students see it. It never names the students who reported or backed it.
struct StudentIssue: Codable, Sendable, Hashable, Identifiable {
    let id: CommunityIssueID
    let title: String
    let messName: String
    let reportedOn: Date
    let updatedAt: Date
    let stage: StudentIssueStage
    /// "the second batch now uses the same recipe". Nil when the mess wrote nothing.
    let stageNote: String?
    /// Students backing it, the reporter included. Each student counts once.
    let backers: Int
    let isBackedByMe: Bool
    /// Set when the mess team hid the text. The count is kept.
    let hiddenReason: String?
    /// True for a waiting-time problem, which shows when the wait is longest.
    let isAboutWaiting: Bool
}

/// The "What's wrong?" list. Urgent ones skip Community and go to the counter staff as an SOS.
enum StudentReportCategory: String, Codable, Sendable, CaseIterable, Hashable {
    case foundInFood
    case smellsOrTastesOff
    case notClean
    case ranOut
    case staffOrService
    case somethingElse

    /// Hygiene, contamination and illness. These never wait for Community.
    var isUrgent: Bool { self == .foundInFood || self == .smellsOrTastesOff }
}

/// A non-urgent report from a student.
struct StudentReportRequest: Codable, Sendable, Hashable {
    let student: StudentID
    let messID: MessID
    let category: StudentReportCategory
    let note: String?
    let place: String
    let meal: MealSlot?
    let idempotencyKey: IdempotencyKey
}

/// What happened to a non-urgent report after the deterministic checks. No AI decides this.
enum StudentReportOutcome: Codable, Sendable, Hashable {
    /// Passed the checks and is on Community.
    case published(CommunityIssueID)
    /// Flagged by a check (for example it names a person); the mess team looks at it first. Nothing is public.
    case heldForReview(reason: String)
}

/// The receipt after "Send report".
struct StudentReportReceipt: Codable, Sendable, Hashable {
    let reference: String
    let category: StudentReportCategory
    let place: String
    let meal: MealSlot?
    let sentAt: Date
    let outcome: StudentReportOutcome
}

/// The category names and hints of Report · What's wrong (221:63480). Shared by the screen and the backend, which uses
/// the name as a Community title when the student wrote nothing.
enum StudentReportCategoryTitle {
    static func title(_ category: StudentReportCategory) -> String {
        switch category {
        case .foundInFood: return "Found something in my food"
        case .smellsOrTastesOff: return "Food smells or tastes off"
        case .notClean: return "Plate, glass or spoon not clean"
        case .ranOut: return "Food ran out"
        case .staffOrService: return "Staff or service problem"
        case .somethingElse: return "Something else"
        }
    }

    static func hint(_ category: StudentReportCategory) -> String {
        switch category {
        case .foundInFood: return "Hair, insect, stone, plastic"
        case .smellsOrTastesOff: return "Spoiled, stale, made someone sick"
        case .notClean: return "Dirty, wet, stained"
        case .ranOut: return "Dish finished before my turn"
        case .staffOrService: return "Rude, very slow, long wait"
        case .somethingElse: return "Anything not listed here"
        }
    }
}
