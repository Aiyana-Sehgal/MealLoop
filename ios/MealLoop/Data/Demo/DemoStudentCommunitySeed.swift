#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SAMPLE, NOT MEASURED. Student Community and reports, each value cited to its Figma frame (file
/// nzzTAm9YnJRSdKEeYUWUEb, page 07). The counts are drawn numbers, not real students.
extension DemoSeed {
    /// A Community problem as stored. `baseBackers` is the drawn count; students who back it in this run add to it.
    struct SampleIssue: Sendable, Hashable {
        let id: CommunityIssueID
        let title: String
        let reportedOn: Date
        var updatedAt: Date
        var stage: StudentIssueStage
        var stageNote: String?
        let baseBackers: Int
        var hiddenReason: String?
        let isAboutWaiting: Bool
        /// Set for problems a student reported in this run, so the reporter counts as a backer.
        var reporter: StudentID?
    }

    /// Community (221:63630): "Long wait at counter 3 after 1 PM · updated 5 h ago · Seen by the team · 64 students" and
    /// "Sambar too watery at dinner · updated 2 d ago · Fixing · the second batch now uses the same recipe · 38 students".
    /// Community · Issue (221:63643): "reported Mon 12 Aug". The third card ("Curd runs out by 8:45 PM") is cut off in
    /// the frame with no stage or count, so it is not seeded.
    static let sampleIssues: [SampleIssue] = [
        SampleIssue(id: CommunityIssueID("demo-issue-long-wait"), title: "Long wait at counter 3 after 1 PM",
                    reportedOn: date(12, 0, 0), updatedAt: storyStartNow.addingTimeInterval(-5 * 3600), stage: .seen,
                    stageNote: nil, baseBackers: 64, hiddenReason: nil, isAboutWaiting: true, reporter: nil),
        SampleIssue(id: CommunityIssueID("demo-issue-watery-sambar"), title: "Sambar too watery at dinner",
                    reportedOn: date(11, 19, 0), updatedAt: storyStartNow.addingTimeInterval(-2 * 86_400), stage: .fixing,
                    stageNote: "the second batch now uses the same recipe", baseBackers: 38, hiddenReason: nil,
                    isAboutWaiting: false, reporter: nil),
    ]

    /// Community · Issue · Hidden (221:65484).
    static let hiddenForNamingReason = "The mess team hid this report because it named a person. The count is kept."

    /// The deterministic check that holds a report for the mess team: it names a person from the mess staff list
    /// (supervisor_spec.md "Ravi"; A06 owners "Devi", "Ravi") or carries a phone number. No AI decides publication.
    static let namesHeldForReview = ["Ravi", "Devi"]
    static let heldForNamingReason = "It names a person, so the mess team checks it first."
    static let heldForPhoneReason = "It has a phone number, so the mess team checks it first."

    /// Report · Receipt (221:63557): "ML-1042". Later reports in a run count up from it.
    static let firstReportNumber = 1042
}
#endif
