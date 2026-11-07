import Foundation

/// What Student Home, the answer page and Entry QR need beyond the core story operations.
/// Separate from the core repositories, so no existing operation changes.
protocol StudentExtrasRepository: Sendable {
    func homeExtras(for student: StudentID, mess: MessID) async throws -> StudentHomeExtras
    /// The dishes a student sees for a meal, for any meal of the day.
    func studentMenu(for meal: MealID) async throws -> [Dish]
    /// The reason given for a skip, if any. Never shown with the student's name to anyone else.
    func skipReason(of student: StudentID, for meal: MealID) async throws -> MealSkipReason?
    /// Refused unless the stored answer for this meal is Skip.
    func setSkipReason(_ reason: MealSkipReason, of student: StudentID, for meal: MealID) async throws
    func entryStanding(of student: StudentID, for meal: MealID, at mess: MessID) async throws -> StudentEntryStanding
    /// Never gated by the answer, the cutoff or a lost connection, like `entryCode`.
    func rotatingEntryCode(for student: StudentID, step: Int) async throws -> RotatingEntryCode
    func correctableRecord(for student: StudentID) async throws -> AttendanceRecord?
    /// The same idempotency key returns the first request.
    func requestEntryCorrection(_ request: EntryCorrectionRequest) async throws -> EntryCorrection
}

/// The answer of any data source with no such service yet. It never fakes a result.
struct UnavailableStudentExtras: StudentExtrasRepository {
    private var unavailable: RepositoryError { .notImplemented(feature: "Student Home extras") }

    func homeExtras(for student: StudentID, mess: MessID) async throws -> StudentHomeExtras { throw unavailable }
    func studentMenu(for meal: MealID) async throws -> [Dish] { throw unavailable }
    func skipReason(of student: StudentID, for meal: MealID) async throws -> MealSkipReason? { throw unavailable }
    func setSkipReason(_ reason: MealSkipReason, of student: StudentID, for meal: MealID) async throws { throw unavailable }
    func entryStanding(of student: StudentID, for meal: MealID, at mess: MessID) async throws -> StudentEntryStanding { throw unavailable }
    func rotatingEntryCode(for student: StudentID, step: Int) async throws -> RotatingEntryCode { throw unavailable }
    func correctableRecord(for student: StudentID) async throws -> AttendanceRecord? { throw unavailable }
    func requestEntryCorrection(_ request: EntryCorrectionRequest) async throws -> EntryCorrection { throw unavailable }
}
