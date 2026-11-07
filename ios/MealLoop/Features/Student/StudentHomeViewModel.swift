import Foundation
import Observation

/// Student Home, the answer page and Entry QR share this model, so an answer shows everywhere at once.
/// It holds screen state only: the cutoff and every stored value belong to the repositories.
@MainActor
@Observable
final class StudentHomeViewModel {
    private(set) var state: LoadState<StudentHomeContent> = .idle
    private(set) var menu: LoadState<[Dish]> = .idle
    private(set) var entryCode: LoadState<EntryCode> = .idle
    private(set) var savingAnswer: MealIntention?
    private(set) var answerError: String?
    /// An answer that failed and can be tried again (Answer · Lunch · Failed). It belongs to `failedMeal` only.
    private(set) var failedAnswer: MealIntention?
    private(set) var failedMeal: MealID?
    private var failedReason: MealSkipReason?
    /// An answer tapped while offline. Nothing is stored until the connection is back and the backend accepts it.
    private(set) var pendingAnswer: (intention: MealIntention, meal: MealID, reason: MealSkipReason?)?
    private(set) var skipReasons: [MealID: MealSkipReason] = [:]

    private(set) var rotatingCode: RotatingEntryCode?
    private(set) var entrySecondsLeft = StudentHomeViewModel.entryQRWindow
    private(set) var isRefreshingQR = false
    private(set) var standing: StudentEntryStanding = .notScanned
    /// When Home last loaded, so a saved QR can say how old it is.
    private(set) var lastLoadedAt: Date?

    /// The Entry QR refresh window: 12 seconds (Entry QR, 221:62986).
    static let entryQRWindow = 12

    let context: StudentContext
    let name: String

    private let mealState: any MealStateRepository
    private let intentions: any IntentionRepository
    private let entries: any EntryRepository
    private let meals: any MealRepository
    private let extras: any StudentExtrasRepository
    private let clock: any AppClock
    private var menus: [MealID: [Dish]] = [:]
    private var rotationStep = 0

    /// Nil for any session that is not a Student's, so no other role can open these screens.
    init?(session: Session, repositories: Repositories, clock: any AppClock) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.name = session.account.displayName
        self.mealState = repositories.mealState
        self.intentions = repositories.intentions
        self.entries = repositories.entries
        self.meals = repositories.meals
        self.extras = repositories.studentExtras
        self.clock = clock
    }

    /// True when loading ended with no top card, so Home offers the QR on its own.
    var showsEntryFallback: Bool {
        switch state {
        case .idle, .loading, .loaded, .stale: return false
        case .empty, .failed: return true
        case .offline(let value, _): return value == nil
        }
    }

    var timeZone: TimeZone { context.mess.timeZone }
    var now: Date { clock.now() }

    var isOffline: Bool {
        if case .offline = state { return true }
        return false
    }

    var isLoadingHome: Bool {
        switch state {
        case .idle, .loading: return true
        default: return false
        }
    }

    /// The meal the entry code is shown for.
    var entryMeal: StudentMealCard? { state.value?.shownHero }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            let statuses = try await mealState.meals(for: context.mess.id)
            // The meal at hand is the first still to finish; once all are over, the last one stays.
            guard let hero = statuses.first(where: { $0.state != .closed }) ?? statuses.last else {
                state = .empty
                return
            }
            let later = statuses.first { $0.meal.startsAt > hero.meal.startsAt && $0.state == .notStarted }
            // Extras are never allowed to take Home down, so a failure here only hides their rows.
            let homeExtras = try? await extras.homeExtras(for: context.student.id, mess: context.mess.id)
            var next: StudentMealCard?
            if let later {
                let card = try await card(for: later.meal)
                next = card.isAnswerOpen ? card : nil
            }
            var laterCard: StudentMealCard?
            if let meal = homeExtras?.laterMeal {
                laterCard = try await card(for: meal)
            }
            state = .loaded(StudentHomeContent(today: clock.now(), hero: try await card(for: hero.meal), nextMeal: next,
                                               heroState: hero.state,
                                               lastClosedMeal: statuses.last { $0.state == .closed }?.meal,
                                               laterMeal: laterCard, extras: homeExtras))
            lastLoadedAt = clock.now()
            await loadSkipReasons()
            await sendPendingAnswer()
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: lastLoadedAt ?? savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    private func card(for meal: Meal) async throws -> StudentMealCard {
        StudentMealCard(meal: meal,
                        response: try await intentions.response(of: context.student.id, for: meal.id),
                        isAnswerOpen: IntentionPolicy.canAnswer(meal, at: clock.now()),
                        cutoff: IntentionPolicy.cutoff(for: meal))
    }

    func card(id: MealID) -> StudentMealCard? {
        state.value?.cards.first { $0.id == id }
    }

    /// The buttons' state: saving while a write runs, otherwise what the backend last said.
    func answerState(for card: StudentMealCard) -> MealAnswerState {
        let waiting = pendingAnswer?.meal == card.id ? pendingAnswer?.intention : nil
        return (savingAnswer ?? waiting).map(MealAnswerState.saving) ?? card.answerState
    }

    /// Sends the answer and shows what the backend stored. A second tap during a write does nothing.
    func answer(_ intention: MealIntention, for meal: MealID, reason: MealSkipReason? = nil) async {
        guard savingAnswer == nil else { return }
        savingAnswer = intention
        answerError = nil
        failedAnswer = nil
        failedMeal = nil
        failedReason = nil
        defer { savingAnswer = nil }
        do {
            _ = try await intentions.setIntention(intention, of: context.student.id, for: meal)
            if let reason {
                try await extras.setSkipReason(reason, of: context.student.id, for: meal)
            }
        } catch RepositoryError.notAllowed {
            // The cutoff passed: the reload below shows the locked state and its note.
        } catch RepositoryError.offline {
            // Nothing was stored. The answer goes when the connection is back, and only then shows as saved.
            pendingAnswer = (intention, meal, reason)
            answerError = StudentCopy.answerWaiting
        } catch {
            failedAnswer = intention
            failedMeal = meal
            failedReason = reason
            answerError = LoadFailure(error).message
        }
        await load()
    }

    /// Sends the answer waiting from an offline tap. The backend still decides: after the cutoff it is refused.
    private func sendPendingAnswer() async {
        guard let pending = pendingAnswer, savingAnswer == nil else { return }
        pendingAnswer = nil
        await answer(pending.intention, for: pending.meal, reason: pending.reason)
    }

    /// Try again: the same answer for the same meal, with the reason it had.
    func retryFailedAnswer() async {
        guard let intention = failedAnswer, let meal = failedMeal else { return }
        await answer(intention, for: meal, reason: failedReason)
    }

    private func loadSkipReasons() async {
        for card in state.value?.cards ?? [] where card.answer == .skipping {
            skipReasons[card.id] = try? await extras.skipReason(of: context.student.id, for: card.id)
        }
    }

    func loadMenu(for meal: MealID) async {
        menu = .loading
        do {
            let dishes = try await meals.menu(for: meal)
            menu = dishes.isEmpty ? .empty : .loaded(dishes)
        } catch RepositoryError.offline(let savedAt) {
            menu = .offline(nil, savedAt: savedAt)
        } catch {
            menu = .failed(LoadFailure(error))
        }
    }

    /// The menu for the answer page. A meal already shown stays on screen when the connection drops.
    func loadAnswerMenu(for meal: MealID) async {
        do {
            let dishes = try await extras.studentMenu(for: meal)
            menus[meal] = dishes
            menu = dishes.isEmpty ? .empty : .loaded(dishes)
        } catch RepositoryError.notImplemented {
            await loadMenu(for: meal)
        } catch RepositoryError.offline(let savedAt) {
            menu = .offline(menus[meal], savedAt: savedAt)
        } catch {
            menu = .failed(LoadFailure(error))
        }
    }

    func loadEntryCode() async {
        do {
            entryCode = .loaded(try await entries.entryCode(for: context.student.id))
        } catch {
            entryCode = .failed(LoadFailure(error))
        }
        entrySecondsLeft = Self.entryQRWindow
        rotatingCode = try? await extras.rotatingEntryCode(for: context.student.id, step: rotationStep)
        await loadStanding()
    }

    private func loadStanding() async {
        guard let meal = entryMeal?.id else { return }
        standing = (try? await extras.entryStanding(of: context.student.id, for: meal, at: context.mess.id)) ?? .notScanned
    }

    /// One second of the Entry QR. Every 12 seconds the code moves to its next token.
    func tickEntryQR() async {
        entrySecondsLeft -= 1
        guard entrySecondsLeft <= 0 else { return }
        rotationStep += 1
        isRefreshingQR = true
        rotatingCode = try? await extras.rotatingEntryCode(for: context.student.id, step: rotationStep)
        entrySecondsLeft = Self.entryQRWindow
        await loadStanding()
    }

    func finishQRRefresh() {
        isRefreshingQR = false
    }

    // MARK: Attendance correction

    func correctableRecord() async -> AttendanceRecord? {
        try? await extras.correctableRecord(for: context.student.id)
    }

    /// Throws on failure so the sheet can keep what was typed and say it did not send.
    func sendCorrection(for record: AttendanceRecord, reason: EntryCorrectionReason, note: String?, key: IdempotencyKey) async throws {
        _ = try await extras.requestEntryCorrection(EntryCorrectionRequest(student: context.student.id, mealID: record.mealID,
                                                                           reason: reason, note: note, idempotencyKey: key))
    }
}
