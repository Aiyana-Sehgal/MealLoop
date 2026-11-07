import Foundation
import Observation

/// The confirm sheet of the Special pass: hold, then send.
enum PassConfirmPhase: Equatable {
    case holding
    case sending
    case failed
}

/// The Special pass and its live code. Where the pass stands comes from `StudentMealsRepository`; the live code and
/// colour from `SpecialPassRepository.refreshPassCode`, the same service the Pass Desk compares against.
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

    let context: StudentContext
    let name: String
    private let meals: any StudentMealsRepository
    private let passes: any SpecialPassRepository
    private let extras: any StudentExtrasRepository
    private let clock: any AppClock
    private var startKey = IdempotencyKey(UUID().uuidString)

    init?(session: Session, repositories: Repositories, clock: any AppClock) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.name = session.account.displayName
        self.meals = repositories.studentMeals
        self.passes = repositories.specialPasses
        self.extras = repositories.studentExtras
        self.clock = clock
    }

    var timeZone: TimeZone { context.mess.timeZone }

    var isLive: Bool {
        if case .live? = state.value { return true }
        return false
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let standing = try await meals.passStanding(of: context.student.id, at: context.mess.id)
            state = .loaded(standing)
            if case .live = standing, liveCode == nil {
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

    /// The hold finished: ask the backend to start the pass. True when the live code can show.
    func confirmHold() async -> Bool {
        guard phase != .sending else { return false }
        phase = .sending
        do {
            let standing = try await meals.startPass(of: context.student.id, key: startKey)
            state = .loaded(standing)
            phase = .holding
            await refreshCode()
            return true
        } catch {
            phase = .failed
            return false
        }
    }

    func refreshCode() async {
        guard let meal = state.value?.ticket?.meal else { return }
        do {
            let code = try await passes.refreshPassCode(for: context.student.id, meal: meal.id)
            liveCode = code
            let window = max(1, Int(code.changesAt.timeIntervalSince(clock.now()).rounded()))
            codeWindow = window
            secondsLeft = window
        } catch {
            // The code stays as it was; the standing check below says whether the pass is still live.
            secondsLeft = codeWindow
        }
    }

    /// One second of the live code. When the window ends the code changes, and the standing is checked, so a pass the
    /// door has just recorded turns to Used.
    func tick() async {
        guard isLive, let left = secondsLeft else { return }
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
