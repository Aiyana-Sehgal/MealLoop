import Foundation
import Observation

/// Today and the headcount pages (A01, A02). Reads through repositories, and every write goes through one:
/// the backend decides what is allowed and moves the clock. This model never does either.
@MainActor
@Observable
final class AdminTodayViewModel {
    private enum Write {
        case approve
        case send
    }

    private(set) var state: LoadState<AdminTodayContent> = .idle
    /// Why the last approve, adjust or send did not happen. It stays on screen until the next try.
    private(set) var actionError: String?
    private var activeWrite: Write?
    private var chosenSlot: MealSlot?
    /// Only the newest load may publish, so a slow refresh can't put back the meal the Food Head just left.
    private var latestLoad = 0

    let context: AdminContext

    private let mealState: any MealStateRepository
    private let headcount: any HeadcountRepository
    private let intentions: any IntentionRepository
    private let shortages: any ShortageRepository
    private let sos: any SOSRepository
    private let clock: any AppClock

    var isApproving: Bool { activeWrite == .approve }
    var isSending: Bool { activeWrite == .send }

    init(context: AdminContext, repositories: Repositories, clock: any AppClock) {
        self.context = context
        self.mealState = repositories.mealState
        self.headcount = repositories.headcount
        self.intentions = repositories.intentions
        self.shortages = repositories.shortages
        self.sos = repositories.sos
        self.clock = clock
    }

    func load() async {
        latestLoad += 1
        let thisLoad = latestLoad
        if state.value == nil {
            state = .loading
        }
        do {
            let messID = context.mess.id
            let day = try await mealState.meals(for: messID)
            guard !day.isEmpty else {
                if thisLoad == latestLoad { state = .empty }
                return
            }
            let current = try await mealState.currentMeal(for: messID)
            let safetyCases = try await sos.activeCases(for: messID)
            let selected = chosenSlot ?? current?.meal.slot ?? day[0].meal.slot
            let meal = try await loadMeal(day.first { $0.meal.slot == selected })
            guard thisLoad == latestLoad else { return }
            let now = clock.now()
            let content = AdminTodayContent(mess: context.mess, now: now,
                                            nodes: Self.nodes(day: day, current: current),
                                            selectedSlot: selected, meal: meal, safetyCases: safetyCases)
            if let asOf = meal?.headcount.actualEntries.asOf,
               now.timeIntervalSince(asOf) > KitchenHomeViewModel.staleAfter {
                state = .stale(content, asOf: asOf)
            } else {
                state = .loaded(content)
            }
        } catch RepositoryError.offline(let savedAt) {
            // Keep what was on screen; never claim anything new was saved.
            if thisLoad == latestLoad { state = .offline(state.value, savedAt: savedAt) }
        } catch {
            if thisLoad == latestLoad { state = .failed(LoadFailure(error)) }
        }
    }

    func select(_ slot: MealSlot) async {
        chosenSlot = slot
        actionError = nil
        await load()
    }

    /// Clears an old failure when the Food Head starts again, for example by opening the adjust sheet.
    func clearActionError() {
        actionError = nil
    }

    /// Approves the forecast as it stands. Only ever called from the Food Head's own tap.
    @discardableResult
    func approve() async -> Bool {
        guard let meal = state.value?.meal, case .approve(let count)? = meal.nextAction else { return false }
        return await write(.approve) { [headcount, context] in
            try await headcount.approveHeadcount(count, reason: nil, for: meal.meal.id, by: context.account.role)
        }
    }

    /// Approves a different count. The backend refuses it without a reason, so that rule lives in one place.
    @discardableResult
    func adjust(to count: Int, reason: String?) async -> Bool {
        guard let meal = state.value?.meal, !meal.isClosed else { return false }
        return await write(.approve) { [headcount, context] in
            try await headcount.approveHeadcount(count, reason: reason, for: meal.meal.id, by: context.account.role)
        }
    }

    /// Publishes the approved headcount. The vendor's acknowledgment stays Pending until the vendor acts.
    @discardableResult
    func send() async -> Bool {
        guard let meal = state.value?.meal, !meal.isClosed else { return false }
        return await write(.send) { [headcount, context] in
            try await headcount.publishHeadcount(for: meal.meal.id, by: context.account.role)
        }
    }

    private func write(_ kind: Write, _ operation: @escaping () async throws -> Headcount) async -> Bool {
        guard activeWrite == nil else { return false }
        activeWrite = kind
        actionError = nil
        defer { activeWrite = nil }
        do {
            _ = try await operation()
            await load()
            return true
        } catch RepositoryError.offline {
            actionError = AdminCopy.offlineNothingSaved
        } catch {
            actionError = LoadFailure(error).message
        }
        return false
    }

    private func loadMeal(_ status: MealStatus?) async throws -> AdminMealContent? {
        guard let status else { return nil }
        let mealID = status.meal.id
        let record = try await headcount.headcount(for: mealID)
        let answers = try await intentions.answerCounts(for: mealID)
        return AdminMealContent(status: status, headcount: record, answers: answers,
                                shortages: try await activeShortages(for: mealID))
    }

    /// A meal the backend keeps no shortages for has none to show; that must not fail the whole page.
    private func activeShortages(for meal: MealID) async throws -> [Shortage] {
        do {
            return try await shortages.shortages(for: meal).filter { $0.status == .active }
        } catch RepositoryError.notFound {
            return []
        }
    }

    private static func nodes(day: [MealStatus], current: MealStatus?) -> [AdminDayNode] {
        MealSlot.allCases.map { slot in
            guard let status = day.first(where: { $0.meal.slot == slot }) else {
                return AdminDayNode(slot: slot, progress: .upcoming)
            }
            if status.state == .closed { return AdminDayNode(slot: slot, progress: .done) }
            let isCurrent = status.meal.id == current?.meal.id
            return AdminDayNode(slot: slot, progress: isCurrent ? .current : .upcoming)
        }
    }
}
