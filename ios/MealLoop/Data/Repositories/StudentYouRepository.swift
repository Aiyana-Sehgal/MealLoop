import Foundation

/// Notifications, the profile, Credits and Attendance for one student. Separate from the core repositories, so no
/// existing operation changes.
protocol StudentYouRepository: Sendable {
    /// Newest first.
    func notifications(for student: StudentID) async throws -> [StudentNotification]
    /// Marks one notification read. Marking it again changes nothing.
    func markRead(_ id: StudentNotificationID, for student: StudentID) async throws -> StudentNotification
    func profile(for student: StudentID, at mess: MessID) async throws -> StudentProfileSummary
    /// The balance counts definite answers (I'm in, Skip) only; Not sure and No response earn nothing.
    func credits(for student: StudentID) async throws -> StudentCredits
    func attendance(for student: StudentID, at mess: MessID) async throws -> StudentAttendanceMonth
}

/// The answer of any data source with no such service yet. It never fakes a result.
struct UnavailableStudentYou: StudentYouRepository {
    private var unavailable: RepositoryError { .notImplemented(feature: "Student You") }

    func notifications(for student: StudentID) async throws -> [StudentNotification] { throw unavailable }
    func markRead(_ id: StudentNotificationID, for student: StudentID) async throws -> StudentNotification { throw unavailable }
    func profile(for student: StudentID, at mess: MessID) async throws -> StudentProfileSummary { throw unavailable }
    func credits(for student: StudentID) async throws -> StudentCredits { throw unavailable }
    func attendance(for student: StudentID, at mess: MessID) async throws -> StudentAttendanceMonth { throw unavailable }
}
