import Foundation
import Observation

/// The confirm sheet of the Special pass: hold, then send.
enum PassConfirmPhase: Equatable {
    case holding
    case sending
    case failed
}

/// The Special pass and its live code. Where the pass stands comes from `StudentMealsRepository`; the live code and
/// colour from `LivePassCodeRepository.currentPassCode` at the backend's pass-code instant, the same operation and
/// instant the Pass Desk reads (P-PASS-9 a), so both show the same code, colour and countdown.
@MainActor
@Observable
final class StudentPassViewModel {
    private(set) var state: LoadState<StudentPassStanding> = .idle
    private(set) var liveCode: LivePassCode?
    /// Seconds until the code changes, counted on the phone. Nil until a code is shown.
    private(set) var secondsLeft: Int?
    private(set) var codeWindow: Int?
    private(set) var phase: PassConfirmPhase = .holding
    private(set) var nextMeal: (meal: Meal, dishes: [Dish])?
    private(set) var crowd: StudentCrowd?
    /// Owner ruling (Prompt 2B): seconds left of the 30 s validity after the hold, from the repository. Nil when the pass
    /// is not in use.
    private(set) var inUseSecondsLeft: Int?
    /// Why the hold was refused, in the backend's words ("Already used").
    private(set) var holdError: String?

    let context: StudentContext
    let name: String
    private let meals: any StudentMealsRepository
    private let passes: any SpecialPassRepository
    private let live: any LivePassCodeRepository
    private let use: any PassUseRepository
    private let extras: any StudentExtrasRepository
    private let clock: any AppClock
    private var startKey = IdempotencyKey(UUID().uuidString)

    init?(session: Session, repositories: Repositories, clock: any AppClock) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.name = session.account.displayName
        self.meals = repositories.studentMeals
        self.passes = repositories.specialPasses
        self.live = repositories.livePassCodes
        self.use = repositories.passUse
        self.extras = repositories.studentExtras
        self.clock = clock
    }

    var timeZone: TimeZone { context.mess.timeZone }

    var isLive: Bool {
        if inUseSecondsLeft != nil { return true }
        if case .live? = state.value { return true }
        return false
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let standing = try await meals.passStanding(of: context.student.id, at: context.mess.id)
            state = .loaded(standing)
            await refreshUse()
            if isLive, liveCode == nil {
                await refreshCode()
            }
            if !standing.showsTicket {
                await loadNext()
            }
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    /// The rows under a pass that cannot be used: the next meal here and the crowd. A failure only hides them.
    private func loadNext() async {
        if let meal = (try? await extras.homeExtras(for: context.student.id, mess: context.mess.id))?.laterMeal {
            let dishes = (try? await extras.studentMenu(for: meal.id)) ?? []
            nextMeal = (meal, dishes)
        }
        crowd = try? await meals.crowd(at: context.mess.id)
    }

    /// A new sheet is a new request. Trying again after a failure keeps the same key, so nothing is started twice.
    func beginConfirm() {
        phase = .holding
        startKey = IdempotencyKey(UUID().uuidString)
    }

    /// The hold finished: the hold is the entry (owner ruling, Prompt 2B). The pass is In use for the backend's validity,
    /// then Used. A refusal ("Already used") or offline keeps the pass as it was. True when the live code can show.
    func confirmHold() async -> Bool {
        guard phase != .sending, let meal = state.value?.ticket?.meal else { return false }
        phase = .sending
        holdError = nil
        do {
            _ = try await use.usePass(of: context.student.id, meal: meal.id, key: startKey)
            state = .loaded(try await meals.passStanding(of: context.student.id, at: context.mess.id))
            phase = .holding
            await refreshUse()
            await refreshCode()
            return true
        } catch RepositoryError.notAllowed(let reason) {
            holdError = reason
            phase = .failed
            return false
        } catch {
            phase = .failed
            return false
        }
    }

    /// In use or not, from the repository at the pass-code instant. Used drops the code: it can't be shown again.
    func refreshUse() async {
        guard let meal = state.value?.ticket?.meal,
              let current = try? await use.passUseState(of: context.student.id, meal: meal.id, at: await live.passCodeInstant())
        else { return }
        if case .inUse(_, _, let left) = current {
            inUseSecondsLeft = left
        } else {
            if inUseSecondsLeft != nil { liveCode = nil }
            inUseSecondsLeft = nil
        }
    }

    func refreshCode() async {
        guard let meal = state.value?.ticket?.meal else { return }
        do {
            let current = try await live.currentPassCode(for: context.student.id, meal: meal.id, at: await live.passCodeInstant())
            liveCode = current.live
            codeWindow = current.windowSeconds
            secondsLeft = current.secondsLeft
        } catch {
            // The code stays as it was; the standing check below says whether the pass is still live.
            secondsLeft = codeWindow
        }
    }

    /// One second of the live code. When the window ends the code changes, and the standing is checked, so a pass the
    /// door has just recorded turns to Used.
    func tick() async {
        guard isLive, let left = secondsLeft else { return }
        if inUseSecondsLeft != nil {
            await refreshUse()
            if inUseSecondsLeft == nil { return }
        }
        if left > 1 {
            secondsLeft = left - 1
            return
        }
        await refreshCode()
        if let standing = try? await meals.passStanding(of: context.student.id, at: context.mess.id) {
            state = .loaded(standing)
        }
    }
}

extension StudentPassStanding {
    var ticket: StudentPassTicket? {
        switch self {
        case .available(let ticket), .live(let ticket, _), .used(let ticket, _, _), .expired(let ticket, _): return ticket
        case .notEligible, .wrongMess: return nil
        }
    }

    /// Available, Live and Used show the pass itself. The rest show a status card.
    var showsTicket: Bool {
        switch self {
        case .available, .live: return true
        case .used(_, _, let wasShowing): return wasShowing
        case .expired, .notEligible, .wrongMess: return false
        }
    }
}

/// Crowd: the estimate for the mess, kept so a lost connection still shows the last reading with its time.
@MainActor
@Observable
final class StudentCrowdViewModel {
    private(set) var state: LoadState<StudentCrowd> = .idle

    let context: StudentContext
    private let repository: any StudentMealsRepository

    init?(session: Session, repositories: Repositories) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.repository = repositories.studentMeals
    }

    var timeZone: TimeZone { context.mess.timeZone }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let crowd = try await repository.crowd(at: context.mess.id)
            state = crowd.slots.isEmpty ? .empty : .loaded(crowd)
        } catch RepositoryError.offline {
            let kept = state.value
            state = .offline(kept, savedAt: kept?.observedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }
}
