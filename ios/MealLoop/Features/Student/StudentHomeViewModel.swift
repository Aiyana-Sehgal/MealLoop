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

    let context: StudentContext
    let name: String

    private let mealState: any MealStateRepository
    private let intentions: any IntentionRepository
    private let entries: any EntryRepository
    private let meals: any MealRepository
    private let clock: any AppClock

    /// Nil for any session that is not a Student's, so no other role can open these screens.
    init?(session: Session, repositories: Repositories, clock: any AppClock) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.name = session.account.displayName
        self.mealState = repositories.mealState
        self.intentions = repositories.intentions
        self.entries = repositories.entries
        self.meals = repositories.meals
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
            var next: StudentMealCard?
            if let later {
                let card = try await card(for: later.meal)
                next = card.isAnswerOpen ? card : nil
            }
            state = .loaded(StudentHomeContent(today: clock.now(), hero: try await card(for: hero.meal), nextMeal: next))
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
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
        guard let content = state.value else { return nil }
        return [content.hero, content.nextMeal].compactMap { $0 }.first { $0.id == id }
    }

    /// The buttons' state: saving while a write runs, otherwise what the backend last said.
    func answerState(for card: StudentMealCard) -> MealAnswerState {
        savingAnswer.map(MealAnswerState.saving) ?? card.answerState
    }

    /// Sends the answer and shows what the backend stored. A second tap during a write does nothing.
    func answer(_ intention: MealIntention, for meal: MealID) async {
        guard savingAnswer == nil else { return }
        savingAnswer = intention
        answerError = nil
        defer { savingAnswer = nil }
        do {
            _ = try await intentions.setIntention(intention, of: context.student.id, for: meal)
        } catch RepositoryError.notAllowed {
            // The cutoff passed: the reload below shows the locked state and its note.
        } catch {
            answerError = LoadFailure(error).message
        }
        await load()
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

    func loadEntryCode() async {
        do {
            entryCode = .loaded(try await entries.entryCode(for: context.student.id))
        } catch {
            entryCode = .failed(LoadFailure(error))
        }
    }
}
