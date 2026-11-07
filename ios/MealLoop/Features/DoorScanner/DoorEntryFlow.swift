import Foundation
import Observation

/// What a scan or a typed entry came to. Each case comes from the data source; this type decides nothing.
enum DoorScanOutcome: Equatable, Identifiable {
    case recorded(student: StudentRef, count: Int, withoutVoting: Bool)
    case alreadyScanned(student: StudentRef, firstAt: Date, count: Int)
    case notRecognised
    /// `servingNow` is the meal being served. The data source does not say which meal the code was for.
    case wrongMeal(servingNow: MealSlot)
    /// Nothing was recorded. An offline scan is never a success.
    case offline(lastUpdate: Date?)
    /// The Supervisor ended the meal during the scan. Nothing was recorded.
    case mealEnded(closedAt: Date?, finalEntries: CountReading)

    var id: String {
        switch self {
        case .recorded: return "recorded"
        case .alreadyScanned: return "alreadyScanned"
        case .notRecognised: return "notRecognised"
        case .wrongMeal: return "wrongMeal"
        case .offline: return "offline"
        case .mealEnded: return "mealEnded"
        }
    }

    /// True only for a verified and saved entry, the one case that may show the lime screen.
    var isRecorded: Bool {
        if case .recorded = self { return true }
        return false
    }
}

/// The state of the digits in the sheet (D06). A lookup never records anything.
enum DoorLookup: Equatable {
    case typing
    case checking
    case match(StudentRef)
    case noMatch
    case offline
}

/// Resolves a typed or scanned credential and records the entry through the repository.
/// The outcome always comes from `resolveEntry` and `recordEntry`; nothing here decides who may enter.
@MainActor
@Observable
final class DoorEntryFlow {
    /// There is no offline queue in this version (door_scanner_spec.md), so nothing is ever waiting.
    static let entriesWaiting = 0

    private(set) var entry = DigitEntry()
    private(set) var lookup: DoorLookup = .typing
    private(set) var isRecording = false
    /// First names found for the students on this attempt. A name is only shown, never used to decide anything.
    private(set) var names: [StudentID: String] = [:]
    var outcome: DoorScanOutcome?

    private let meal: MealID
    private let entries: any EntryRepository
    private let mealState: any MealStateRepository
    private let directory: any StaffDirectoryRepository
    private let mess: MessID
    /// Kept across a failed try, so a retry of the same scan can never count twice.
    private var pending: (student: StudentRef, method: EntryMethod, key: IdempotencyKey)?

    init(meal: MealID, mess: MessID, repositories: Repositories) {
        self.meal = meal
        self.mess = mess
        self.entries = repositories.entries
        self.mealState = repositories.mealState
        self.directory = repositories.staffDirectory
    }

    // MARK: Typing

    func append(_ digit: Int) async {
        guard lookup == .typing else { return }
        entry.append(digit)
        if entry.isComplete {
            await checkDigits()
        }
    }

    func deleteLast() {
        guard !isRecording else { return }
        entry.deleteLast()
        lookup = .typing
        pending = nil
    }

    func clear() {
        entry.clear()
        lookup = .typing
        pending = nil
    }

    private func checkDigits() async {
        lookup = .checking
        do {
            switch try await entries.resolveEntry(.lastFour(entry.text), for: meal) {
            case .student(let student):
                names[student.id] = try? await directory.studentName(student.id)
                lookup = .match(student)
            case .notRecognised:
                lookup = .noMatch
            case .wrongMeal(let servingNow):
                lookup = .typing
                await showWrongMeal(servingNow)
            }
        } catch {
            // Anything else is unverified too. It is never reported as "no such student".
            lookup = .offline
        }
    }

    /// The tap on Record entry. Only a match found by `resolveEntry` can get here.
    func recordMatch() async {
        guard case .match(let student) = lookup else { return }
        await record(student, method: .typedLastFour)
    }

    // MARK: Scanning

    /// Handles a QR payload exactly as the entry code carries it. A resolved student is recorded at once.
    /// The app has no camera yet, so only the tests reach this; the capture view will call it.
    func scan(payload: String) async {
        guard !isRecording else { return }
        do {
            switch try await entries.resolveEntry(.qrPayload(payload), for: meal) {
            case .student(let student):
                names[student.id] = try? await directory.studentName(student.id)
                await record(student, method: .qrScan)
            case .notRecognised:
                outcome = .notRecognised
            case .wrongMeal(let servingNow):
                await showWrongMeal(servingNow)
            }
        } catch RepositoryError.offline(let savedAt) {
            outcome = .offline(lastUpdate: savedAt)
        } catch {
            outcome = .offline(lastUpdate: nil)
        }
    }

    /// Tries the failed entry again with the same key.
    func retry() async {
        guard let pending else { return }
        await record(pending.student, method: pending.method)
    }

    // MARK: Recording

    private func record(_ student: StudentRef, method: EntryMethod) async {
        guard !isRecording else { return }
        isRecording = true
        defer { isRecording = false }
        let key = pending?.student == student ? pending?.key ?? .make() : .make()
        pending = (student, method, key)
        do {
            let result = try await entries.recordEntry(EntryRequest(mealID: meal, student: student, method: method, idempotencyKey: key))
            pending = nil
            switch result {
            case .recorded(let record, let count):
                outcome = .recorded(student: record.student, count: count, withoutVoting: !record.hadMealResponse)
            case .alreadyRecorded(let firstAt, let count):
                outcome = .alreadyScanned(student: student, firstAt: firstAt, count: count)
            }
        } catch RepositoryError.offline(let savedAt) {
            outcome = .offline(lastUpdate: savedAt)
        } catch RepositoryError.notAllowed {
            await showMealEnded()
        } catch {
            // Unverified, so it is shown as not recorded. The key is kept for a retry.
            outcome = .offline(lastUpdate: nil)
        }
    }

    private func showWrongMeal(_ servingNow: MealSlot?) async {
        if let servingNow {
            outcome = .wrongMeal(servingNow: servingNow)
        } else {
            await showMealEnded()
        }
    }

    /// Scanning closed under the scan. The final count is read, never assumed.
    private func showMealEnded() async {
        pending = nil
        let status = try? await mealState.currentMeal(for: mess)
        let finalEntries = (try? await entries.finalCount(for: meal)) ?? .unavailable
        outcome = .mealEnded(closedAt: status?.closedAt, finalEntries: finalEntries)
    }
}
