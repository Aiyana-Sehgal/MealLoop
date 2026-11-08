import Foundation
import Observation

/// Supervisor Home (S01, S02, S06): the meal state, Start meal and Close meal, the follow-up counts and the SOS tab.
/// Starting and closing go through the meal-state repository, which drives every role of the mess and moves the
/// story clock. This model never decides a rule and never moves the clock.
@MainActor
@Observable
final class SupervisorHomeViewModel {
    private(set) var state: LoadState<SupervisorHomeContent> = .idle
    /// A start or close is being written. The dialog shows a spinner and ignores taps.
    private(set) var isWriting = false
    /// Why the last start or close did not happen. Shown under the card; nothing changed.
    private(set) var actionError: String?

    let session: StaffSession
    let sosModel: SupervisorSOSModel
    private let repositories: Repositories
    private let clock: any AppClock

    init(session: StaffSession, repositories: Repositories, clock: any AppClock) {
        self.session = session
        self.repositories = repositories
        self.clock = clock
        self.sosModel = SupervisorSOSModel(session: session, repositories: repositories, clock: clock)
    }

    var now: Date { clock.now() }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        await sosModel.load()
        do {
            guard let status = try await repositories.mealState.currentMeal(for: session.mess.id) else {
                state = .empty
                return
            }
            async let phase = loadPhase(for: status)
            async let followUps = SupervisorFollowUps.load(mess: session.mess.id, current: status, repositories: repositories)
            let content = SupervisorHomeContent(meal: status.meal, mess: session.mess, phase: try await phase,
                                                followUps: try await followUps)
            state = .loaded(content)
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    /// Starts the meal for every role of the mess. Returns true when the data source accepted it.
    @discardableResult
    func startMeal() async -> Bool {
        await write { meal in try await self.repositories.mealState.startMeal(meal, by: self.session) }
    }

    /// Closes the meal for every role of the mess. It resolves no shortage and completes no waste report.
    @discardableResult
    func closeMeal() async -> Bool {
        await write { meal in try await self.repositories.mealState.closeMeal(meal, by: self.session) }
    }

    private func write(_ change: @escaping (MealID) async throws -> MealStatus) async -> Bool {
        guard let meal = state.value?.meal.id, !isWriting else { return false }
        isWriting = true
        actionError = nil
        defer { isWriting = false }
        do {
            _ = try await change(meal)
            await load()
            return true
        } catch {
            actionError = LoadFailure(error).message
            return false
        }
    }

    private func loadPhase(for status: MealStatus) async throws -> SupervisorHomePhase {
        let mealID = status.meal.id
        switch status.state {
        case .notStarted:
            return .notStarted(forecast: try await repositories.headcount.headcount(for: mealID).liveForecast)
        case .inService:
            let entered = try await repositories.entries.liveCount(for: mealID)
            let minutes = MLFormat.minutes(from: status.startedAt ?? status.meal.startsAt, to: clock.now())
            return .inService(entered: entered, minutesInService: minutes)
        case .closed:
            return .closed(finalEntries: try await repositories.entries.finalCount(for: mealID), closedAt: status.closedAt)
        }
    }
}
