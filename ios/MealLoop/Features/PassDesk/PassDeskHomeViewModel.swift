import Foundation
import Observation

/// Pass Desk Home, and the meal facts Alerts and Me read from it.
@MainActor
@Observable
final class PassDeskHomeViewModel {
    private(set) var state: LoadState<PassDeskHomeContent> = .idle
    /// When this shift began, once it has. Nil means the chip says only "On shift".
    private(set) var shiftStartedAt: Date?
    let session: StaffSession
    let flow: PassDeskCheckFlow

    private let repositories: Repositories
    private let clock: any AppClock

    init(session: StaffSession, repositories: Repositories, clock: any AppClock) {
        self.session = session
        self.repositories = repositories
        self.clock = clock
        self.flow = PassDeskCheckFlow(session: session, passes: repositories.specialPasses, live: repositories.livePassCodes,
                                      clock: clock)
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            guard let status = try await repositories.mealState.currentMeal(for: session.mess.id) else {
                state = .empty
                return
            }
            let mealID = status.meal.id
            let count = try await repositories.specialPasses.specialMealCount(for: mealID)
            let requests = try await repositories.specialPasses.reissueRequests(for: session.mess.id)
            let shortages = try await repositories.shortages.shortages(for: mealID)
            let content = PassDeskHomeContent(status: status, phase: Self.phase(for: status), count: count, requests: requests,
                                              reportedShortages: shortages.filter { $0.reportedBy == session.role })
            flow.meal = status.meal
            flow.passTotal = count.passes
            state = .loaded(content)
            let started = try? await repositories.staffDirectory.shiftStartedAt(for: session.role, mess: session.mess.id)
            shiftStartedAt = started.flatMap { $0 <= clock.now() ? $0 : nil }
        } catch RepositoryError.offline(let savedAt) {
            // Keep what was on screen; nothing new is claimed.
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    private static func phase(for status: MealStatus) -> PassDeskHomePhase {
        switch status.state {
        case .notStarted: return .beforeMeal(opensAt: status.meal.startsAt)
        case .inService: return .duringMeal
        case .closed: return .afterMeal(closedAt: status.closedAt)
        }
    }
}

/// Type the last four, compare, record. The pass service decides; this only follows its answers.
/// Nothing is recorded anywhere but `matches()`.
@MainActor
@Observable
final class PassDeskCheckFlow {
    /// How many ticks "Just changed" stays up.
    private static let highlightTicks = 2

    private(set) var entry = DigitEntry()
    private(set) var isChecking = false
    private(set) var isRecording = false
    /// The digits nobody matched, shown on the black card.
    private(set) var notFoundDigits: String?
    private(set) var compare: PassDeskCompare?
    private(set) var outcome: PassDeskOutcome?
    /// Why a record was refused for a reason with no outcome screen.
    private(set) var actionError: String?

    var meal: Meal?
    var passTotal: Int?

    private var recordKey = IdempotencyKey.make()
    private var ticksSinceChange = 0
    private let session: StaffSession
    private let passes: any SpecialPassRepository
    /// The code and colour on the sheet, and the record, follow the clock-derived window (P-PASS-9 a): the same
    /// operation and instant as the student's phone. The desk never calls `refreshPassCode`.
    private let live: any LivePassCodeRepository
    private let clock: any AppClock

    init(session: StaffSession, passes: any SpecialPassRepository,
         live: any LivePassCodeRepository = UnavailableLivePassCodes(), clock: any AppClock) {
        self.session = session
        self.passes = passes
        self.live = live
        self.clock = clock
    }

    /// One key press. The fourth digit asks the pass service, which records nothing.
    func type(_ digit: Int) async {
        guard !isChecking else { return }
        if notFoundDigits != nil { reset() }
        entry.append(digit)
        if entry.isComplete { await lookUp() }
    }

    func deleteLast() {
        guard !isChecking else { return }
        notFoundDigits = nil
        entry.deleteLast()
    }

    /// Back to an empty Home. Closing the sheet comes here, so it records nothing.
    func reset() {
        entry.clear()
        notFoundDigits = nil
        compare = nil
        outcome = nil
        actionError = nil
    }

    /// Check again, Try again: ask for the same digits afresh.
    func checkAgain() async {
        outcome = nil
        compare = nil
        await lookUp()
    }

    private func lookUp() async {
        guard let meal else { return }
        isChecking = true
        defer { isChecking = false }
        do {
            switch try await passes.lookUpPass(lastFour: entry.text, for: meal.id) {
            case .notFound:
                notFoundDigits = entry.text
            case .noPass(let holder):
                outcome = .noPass(holder)
            case .wrongMeal(let holder, let slot):
                outcome = .wrongMeal(holder, passFor: slot)
            case .used(let holder, let at, let count):
                outcome = .alreadyRecorded(holder, firstRecordedAt: at, count: count)
            case .valid(let holder, _):
                let current = try await live.currentPassCode(for: holder.student.id, meal: meal.id,
                                                             at: await live.passCodeInstant())
                recordKey = .make()
                ticksSinceChange = 0
                compare = PassDeskCompare(holder: holder, live: current.live, secondsLeft: current.secondsLeft)
            }
        } catch RepositoryError.offline(let savedAt) {
            outcome = .cantCheck(lastUpdate: savedAt)
        } catch {
            outcome = .cantCheck(lastUpdate: nil)
        }
    }

    /// "Doesn't match": shows what it should show. Nothing is recorded.
    func doesNotMatch() {
        guard let compare else { return }
        self.compare = nil
        outcome = .mismatch(compare.live)
    }

    /// "Matches · record entry": the only way an entry is recorded.
    func matches() async {
        guard let compare, let meal, !compare.isExpired, !isRecording else { return }
        isRecording = true
        actionError = nil
        defer { isRecording = false }
        let request = SpecialPassEntryRequest(mealID: meal.id, student: compare.holder.student, comparedCode: compare.live.code,
                                              recordedBy: session.role, idempotencyKey: recordKey)
        do {
            switch try await live.recordPassEntryForCurrentCode(request) {
            case .recorded(_, let count):
                finish(.verified(compare.holder, count: count, passes: passTotal))
            case .alreadyRecorded(let at, let count):
                finish(.alreadyRecorded(compare.holder, firstRecordedAt: at, count: count))
            case .codeChanged:
                self.compare?.isExpired = true
            case .mealEnded(let closedAt, let count):
                finish(.mealEnded(closedAt: closedAt, count: count, passes: passTotal))
            }
        } catch RepositoryError.offline(let savedAt) {
            finish(.cantCheck(lastUpdate: savedAt))
        } catch {
            actionError = LoadFailure(error).message
        }
    }

    /// One second on the sheet. When the window runs out it fetches the next code; an old one can never be recorded.
    func tick() async {
        guard var current = compare, !current.isExpired, !isRecording else { return }
        current.secondsLeft -= 1
        ticksSinceChange += 1
        if ticksSinceChange >= Self.highlightTicks { current.justChanged = false }
        compare = current
        guard current.secondsLeft <= 0, let meal else { return }
        do {
            let next = try await live.currentPassCode(for: current.holder.student.id, meal: meal.id,
                                                      at: await live.passCodeInstant())
            guard compare != nil else { return }
            guard next.live != current.live else {
                // The same window is still current (the countdown ran ahead of the instant): keep it, never expire it early.
                compare?.secondsLeft = next.secondsLeft
                return
            }
            recordKey = .make()
            ticksSinceChange = 0
            compare = PassDeskCompare(holder: current.holder, live: next.live, secondsLeft: next.secondsLeft, justChanged: true)
        } catch {
            compare?.isExpired = true
        }
    }

    private func finish(_ result: PassDeskOutcome) {
        compare = nil
        outcome = result
    }

}
