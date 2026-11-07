import Foundation

/// The live special-meal pass code as a function of time (owner ruling P-PASS-9, option a): the code and colour of an
/// instant come from `floor(instant / window)`, so the student's phone and the Pass Desk show the same code, colour and
/// countdown at the same moment. Separate from `SpecialPassRepository`; `refreshPassCode` and `recordPassEntry` are
/// unchanged.
protocol LivePassCodeRepository: Sendable {
    /// The instant both screens read the code at. In the prototype it is the story time plus the seconds since the
    /// story clock last moved, so the code keeps changing while the story waits.
    func passCodeInstant() async -> Date
    /// Read only: never records and never changes a count. Throws `notFound` when the student has no pass for this meal.
    func currentPassCode(for student: StudentID, meal: MealID, at instant: Date) async throws -> CurrentPassCode
    /// Pass Desk only. Records against the code of the backend's own current window: a code from an earlier window
    /// comes back as `.codeChanged` and is never recorded. Once per student per meal; the same key returns the first result.
    func recordPassEntryForCurrentCode(_ request: SpecialPassEntryRequest) async throws -> SpecialPassEntryResult
}

/// The code of one window.
struct CurrentPassCode: Codable, Sendable, Hashable {
    let live: LivePassCode
    let windowIndex: Int
    /// Whole seconds until the window ends, at least 1 while the window is current.
    let secondsLeft: Int
    /// The length of every window ("Changes every 10 s").
    let windowSeconds: Int
}

/// Window arithmetic, kept pure so both screens and the tests agree.
enum PassCodeWindow {
    static func index(at instant: Date, length: TimeInterval) -> Int {
        Int((instant.timeIntervalSince1970 / length).rounded(.down))
    }

    static func end(of index: Int, length: TimeInterval) -> Date {
        Date(timeIntervalSince1970: TimeInterval(index + 1) * length)
    }

    static func secondsLeft(at instant: Date, index: Int, length: TimeInterval) -> Int {
        max(1, Int(end(of: index, length: length).timeIntervalSince(instant).rounded(.up)))
    }
}

/// The answer of any data source with no live pass code yet. It never fakes a result.
struct UnavailableLivePassCodes: LivePassCodeRepository {
    private var unavailable: RepositoryError { .notImplemented(feature: "Live pass code") }

    func passCodeInstant() async -> Date { Date(timeIntervalSince1970: 0) }
    func currentPassCode(for student: StudentID, meal: MealID, at instant: Date) async throws -> CurrentPassCode {
        throw unavailable
    }
    func recordPassEntryForCurrentCode(_ request: SpecialPassEntryRequest) async throws -> SpecialPassEntryResult {
        throw unavailable
    }
}
