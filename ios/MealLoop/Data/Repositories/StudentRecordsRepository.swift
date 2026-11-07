import Foundation

/// The student's own records behind the You rows and the report pages. Separate from the core repositories, so no
/// existing operation changes.
protocol StudentRecordsRepository: Sendable {
    /// Active reports first (newest first), then closed ones.
    func reports(for student: StudentID) async throws -> [StudentFiledReport]
    func report(_ id: StudentFiledReportID, for student: StudentID) async throws -> StudentFiledReport
    /// Records the student's answer to the mess's question. Only on Need more info; it never says a person read it.
    func reply(to id: StudentFiledReportID, text: String, by student: StudentID) async throws -> StudentFiledReport
    /// "Is it better now?" on a fixed report. Recorded once; it never changes the stage.
    func answerFixCheck(_ id: StudentFiledReportID, _ answer: StudentFixCheckAnswer, by student: StudentID) async throws
        -> StudentFiledReport
    /// Records a data request. Recording it once is enough; asking again changes nothing.
    func recordDataRequest(_ kind: StudentDataRequestKind, by student: StudentID) async throws -> StudentDataRequestReceipt
    func dataRequests(for student: StudentID) async throws -> [StudentDataRequestReceipt]
    func feedback(for student: StudentID) async throws -> StudentFeedbackSummary
    /// "Better today?" on a fixed item. Recorded once; answering again changes nothing.
    func answerRecheck(_ id: StudentFeedbackID, _ answer: StudentRecheckAnswer, by student: StudentID) async throws
        -> StudentFeedbackSummary
    /// Private: only the student sees it.
    func spending(for student: StudentID) async throws -> StudentSpending
    func help(at mess: MessID) async throws -> StudentHelp
    /// Oldest first, then the next step. Empty when the mess posted none.
    func updates(for issue: CommunityIssueID) async throws -> [StudentIssueUpdate]
}

/// The answer of any data source with no such service yet. It never fakes a result.
struct UnavailableStudentRecords: StudentRecordsRepository {
    private var unavailable: RepositoryError { .notImplemented(feature: "Student records") }

    func reports(for student: StudentID) async throws -> [StudentFiledReport] { throw unavailable }
    func report(_ id: StudentFiledReportID, for student: StudentID) async throws -> StudentFiledReport { throw unavailable }
    func reply(to id: StudentFiledReportID, text: String, by student: StudentID) async throws -> StudentFiledReport {
        throw unavailable
    }
    func answerFixCheck(_ id: StudentFiledReportID, _ answer: StudentFixCheckAnswer, by student: StudentID) async throws
        -> StudentFiledReport { throw unavailable }
    func recordDataRequest(_ kind: StudentDataRequestKind, by student: StudentID) async throws -> StudentDataRequestReceipt {
        throw unavailable
    }
    func dataRequests(for student: StudentID) async throws -> [StudentDataRequestReceipt] { throw unavailable }
    func feedback(for student: StudentID) async throws -> StudentFeedbackSummary { throw unavailable }
    func answerRecheck(_ id: StudentFeedbackID, _ answer: StudentRecheckAnswer, by student: StudentID) async throws
        -> StudentFeedbackSummary { throw unavailable }
    func spending(for student: StudentID) async throws -> StudentSpending { throw unavailable }
    func help(at mess: MessID) async throws -> StudentHelp { throw unavailable }
    func updates(for issue: CommunityIssueID) async throws -> [StudentIssueUpdate] { throw unavailable }
}
