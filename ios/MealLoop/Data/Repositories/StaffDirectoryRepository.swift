import Foundation

/// Facts staff screens show about people, apart from what an entry records.
/// A nil answer means the source does not know, and the screen shows less rather than a made-up value.
protocol StaffDirectoryRepository: Sendable {
    /// The first name drawn with the masked ID ("Aarav ••0238").
    func studentName(_ student: StudentID) async throws -> String?
    /// When this role's shift began, for "On shift · since 11:40 AM".
    func shiftStartedAt(for role: Role, mess: MessID) async throws -> Date?
}

/// The default for a source with no directory: every answer is "not known", never an error on a staff screen.
struct UnavailableStaffDirectory: StaffDirectoryRepository {
    func studentName(_ student: StudentID) async throws -> String? { nil }
    func shiftStartedAt(for role: Role, mess: MessID) async throws -> Date? { nil }
}
