import Foundation

/// The student's own use of a special-meal pass, and the desk's read-only checks (owner ruling, Prompt 2B). Separate from
/// `SpecialPassRepository` and `LivePassCodeRepository`, so no existing operation changes. Instants come from
/// `LivePassCodeRepository.passCodeInstant()`, the same clock as the live code.
protocol PassUseRepository: Sendable {
    /// The hold of "Use pass" on the student's phone: records the entry and starts the validity. The same key returns the
    /// first result; a second use is refused ("Already used"). Allowed any time before the meal ends (open decision).
    func usePass(of student: StudentID, meal: MealID, key: IdempotencyKey) async throws -> PassUseState
    func passUseState(of student: StudentID, meal: MealID, at instant: Date) async throws -> PassUseState
    /// "Check last 4 digits" on the desk. Read only.
    func checkLastFour(_ lastFour: String, meal: MealID, at instant: Date) async throws -> PassDigitCheck
    /// The meal's live code for the desk, the same one every pass shows in this window. Read only.
    func deskCode(for meal: MealID, at instant: Date) async throws -> CurrentPassCode
}

/// The answer of any data source with no pass-use service yet. It never fakes a result.
struct UnavailablePassUse: PassUseRepository {
    private var unavailable: RepositoryError { .notImplemented(feature: "Pass use") }

    func usePass(of student: StudentID, meal: MealID, key: IdempotencyKey) async throws -> PassUseState { throw unavailable }
    func passUseState(of student: StudentID, meal: MealID, at instant: Date) async throws -> PassUseState { throw unavailable }
    func checkLastFour(_ lastFour: String, meal: MealID, at instant: Date) async throws -> PassDigitCheck { throw unavailable }
    func deskCode(for meal: MealID, at instant: Date) async throws -> CurrentPassCode { throw unavailable }
}
