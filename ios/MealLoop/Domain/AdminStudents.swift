import Foundation

// Read models for the Food Head's Students tab. Counts only: a student is never named here.

struct FeedbackItemID: Hashable, Codable, Sendable {
    let rawValue: String

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

struct FeedbackProblem: Codable, Sendable, Hashable, Identifiable {
    let title: String
    let severity: String
    let students: Int

    var id: String { title }
}

struct FeedbackItem: Codable, Sendable, Hashable, Identifiable {
    let id: FeedbackItemID
    let dish: String
    let problem: String
    let mess: String
    let slot: MealSlot
    let day: Date
    let students: Int
    let isNew: Bool
    let problems: [FeedbackProblem]
    let meal: MealID
}

enum CommunityStage: String, Codable, Sendable, CaseIterable, Hashable {
    case raised
    case owner
    case fixed
}

struct AdminCommunityIssue: Codable, Sendable, Hashable, Identifiable {
    let id: CommunityIssueID
    let title: String
    let students: Int
    let raisedOn: Date
    let context: String
    var owner: String?
    var stage: CommunityStage
    var postedNote: String?
}

struct SkipReason: Codable, Sendable, Hashable, Identifiable {
    let title: String
    let students: Int

    var id: String { title }
}

struct StudentSkipReasons: Codable, Sendable, Hashable {
    let mealTitle: String
    let saidNo: Int
    let reasons: [SkipReason]
    /// Groups under 10 are hidden, so nobody can be picked out.
    let hiddenGroups: [String]
    let gaveNoReason: Int
}

struct AdminStudentsOverview: Codable, Sendable, Hashable {
    let mealTitle: String
    /// "tomorrow lunch (Thu 15 Aug)"
    let mealLongTitle: String
    let totalStudents: Int
    let yes: Int
    let no: Int
    let notSure: Int
    let reminderMessage: String
    var reminderSentAt: Date?
    let feedback: [FeedbackItem]
    let community: [AdminCommunityIssue]

    var answered: Int { yes + no + notSure }
    var notAnswered: Int { totalStudents - answered }
}
