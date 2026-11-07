import Foundation
import Observation

/// The result card after a decision (WV-1 Approved, Change asked, Rejected).
struct WardenResult: Equatable {
    let kind: WardenDecisionKind
    let outing: OutingCase
    let next: OutingCase?
}

/// Everything the Warden tabs read, from the outing repository only. Decisions go through the repository, which
/// refuses any decision before the guardian's answer and any request outside this warden's block.
@MainActor
@Observable
final class WardenModel {
    enum Phase: Equatable {
        case loading
        case ready
        case offline
        case failed(LoadFailure)
    }

    private(set) var phase: Phase = .loading
    private(set) var now: Date?
    private(set) var profile: WardenProfile?
    private(set) var queue: [OutingCase] = []
    private(set) var outNow: [OutingCase] = []
    private(set) var escalated: [OutingCase] = []
    private(set) var history: [WardenHistoryItem] = []
    /// A request opened from Escalated (Watch, Record the answer). Shown on the Queue tab until decided.
    private(set) var focused: OutingCase?
    private(set) var result: WardenResult?
    private(set) var isWorking = false
    private(set) var actionError: String?
    /// True while a reload runs over data already shown (the video tile shows its loading state).
    var isRefreshing = false

    let account: AccountID
    private let repository: any OutingCaseRepository
    private var hasBegun = false

    init(account: AccountID, repository: any OutingCaseRepository) {
        self.account = account
        self.repository = repository
    }

    /// The request on the queue card: the one opened from Escalated, else the closest deadline.
    var current: OutingCase? { focused ?? queue.first }

    /// 1-based place of the current request in the queue, or nil when it came from Escalated.
    var position: Int? {
        guard let current, focused == nil || queue.contains(where: { $0.id == current.id }) else { return nil }
        return queue.firstIndex { $0.id == current.id }.map { $0 + 1 }
    }

    func load() async {
        if profile != nil { isRefreshing = true }
        defer { isRefreshing = false }
        do {
            if !hasBegun {
                try await repository.begin(as: .warden)
                hasBegun = true
            }
            now = await repository.now()
            profile = try await repository.wardenProfile(for: account)
            queue = try await repository.wardenQueue(for: account)
            outNow = try await repository.wardenOutNow(for: account)
            escalated = try await repository.wardenEscalated(for: account)
            history = try await repository.wardenHistory(for: account)
            if let focusedID = focused?.id {
                focused = try await repository.outing(focusedID, for: account)
            }
            phase = .ready
        } catch RepositoryError.offline {
            phase = .offline
        } catch {
            phase = .failed(LoadFailure(error))
        }
    }

    func focus(on outing: OutingRequestID) async {
        result = nil
        do {
            focused = try await repository.outing(outing, for: account)
        } catch {
            actionError = LoadFailure(error).message
        }
    }

    func clearFocus() { focused = nil }

    /// What the current card needs before a decision: a note when the guardian is answered by call.
    var needsCallNote: Bool { current?.stage == .guardianCallRequested }

    func approve(note: String? = nil) async {
        await decide(note: note) { [repository, account] id in
            try await repository.approve(id, warden: account, by: .warden)
        }
    }

    func askForChange(fields: [String], note: String?, callNote: String? = nil) async {
        await decide(note: callNote) { [repository, account] id in
            try await repository.askForChange(id, fields: fields, note: note, warden: account, by: .warden)
        }
    }

    func reject(reason: String, callNote: String? = nil) async {
        await decide(note: callNote) { [repository, account] id in
            try await repository.reject(id, reason: reason, warden: account, by: .warden)
        }
    }

    /// Records the call first when the card is on the call path, then makes the decision. Both go through the
    /// repository, so the guardian's answer is always on record before the warden's.
    private func decide(note: String?, _ work: @escaping (OutingRequestID) async throws -> OutingCase) async {
        guard let current, !isWorking else { return }
        isWorking = true
        actionError = nil
        defer { isWorking = false }
        do {
            if current.stage == .guardianCallRequested {
                _ = try await repository.recordGuardianCall(current.id, note: note ?? "", warden: account, by: .warden)
            }
            let decided = try await work(current.id)
            focused = nil
            await load()
            result = WardenResult(kind: decided.wardenDecision?.kind ?? .approved, outing: decided, next: queue.first)
        } catch {
            actionError = LoadFailure(error).message
        }
    }

    func undo() async {
        guard let result, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let restored = try await repository.undoDecision(result.outing.id, warden: account, by: .warden)
            self.result = nil
            await load()
            if queue.first?.id != restored.id { focused = restored }
        } catch {
            actionError = LoadFailure(error).message
            self.result = nil
        }
    }

    func dismissResult() { result = nil }

    @discardableResult
    func closeRequest(_ outing: OutingRequestID) async -> Bool {
        do {
            _ = try await repository.closeRequest(outing, warden: account, by: .warden)
            await load()
            return true
        } catch {
            actionError = LoadFailure(error).message
            return false
        }
    }

    // MARK: Derived

    func remainingFraction(of outing: OutingCase) -> Double? {
        guard let now, let deadline = outing.wardenDecideBy, let start = outing.guardianAnswer?.at, deadline > start else {
            return nil
        }
        return deadline.timeIntervalSince(now) / deadline.timeIntervalSince(start)
    }

    var lateCount: Int {
        guard let now else { return 0 }
        return outNow.filter { $0.isLate(at: now) }.count
    }

    /// The latest back-by among students not late, for "Due back by 8 PM".
    var latestDue: Date? {
        guard let now else { return nil }
        return outNow.filter { !$0.isLate(at: now) }.compactMap(\.returnBy).max()
    }
}
