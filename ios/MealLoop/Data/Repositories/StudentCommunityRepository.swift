import Foundation

/// Community and non-urgent reports for students. Separate from the core repositories, so nothing existing changes.
/// Urgent reports do not come here: they are raised with `SOSRepository.raise`.
protocol StudentCommunityRepository: Sendable {
    /// Open problems, most recently updated first, then Fixed ones.
    func issues(at mess: MessID, for student: StudentID) async throws -> [StudentIssue]
    func issue(_ id: CommunityIssueID, for student: StudentID) async throws -> StudentIssue
    /// "Me too". Once per student per problem: backing again changes nothing.
    func back(_ id: CommunityIssueID, by student: StudentID) async throws -> StudentIssue
    /// "Undo" on a problem the student backed.
    func unback(_ id: CommunityIssueID, by student: StudentID) async throws -> StudentIssue
    /// Runs the deterministic checks, then publishes or holds the report. The same key returns the first receipt.
    func submitReport(_ report: StudentReportRequest) async throws -> StudentReportReceipt
    /// False when no one at the mess reads reports right now.
    func isReportDeskStaffed(at mess: MessID) async throws -> Bool
}

/// The answer of any data source with no such service yet. It never fakes a result.
struct UnavailableStudentCommunity: StudentCommunityRepository {
    private var unavailable: RepositoryError { .notImplemented(feature: "Student Community") }

    func issues(at mess: MessID, for student: StudentID) async throws -> [StudentIssue] { throw unavailable }
    func issue(_ id: CommunityIssueID, for student: StudentID) async throws -> StudentIssue { throw unavailable }
    func back(_ id: CommunityIssueID, by student: StudentID) async throws -> StudentIssue { throw unavailable }
    func unback(_ id: CommunityIssueID, by student: StudentID) async throws -> StudentIssue { throw unavailable }
    func submitReport(_ report: StudentReportRequest) async throws -> StudentReportReceipt { throw unavailable }
    func isReportDeskStaffed(at mess: MessID) async throws -> Bool { throw unavailable }
}
