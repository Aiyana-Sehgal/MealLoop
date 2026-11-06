import Foundation
import Observation

/// Kitchen Home (K01, K02, K03, K05). Reads the shared meal state and the feeds behind it through repositories.
@MainActor
@Observable
final class KitchenHomeViewModel {
    /// Live entries older than this are shown as stale ("Updated 1:12 PM · reconnecting").
    static let staleAfter: TimeInterval = 2 * 60

    private(set) var state: LoadState<KitchenHomeContent> = .idle
    let session: StaffSession

    private let mealState: any MealStateRepository
    private let headcount: any HeadcountRepository
    private let entries: any EntryRepository
    private let shortages: any ShortageRepository
    private let wasteReports: any WasteReportRepository
    private let clock: any AppClock

    init(session: StaffSession, repositories: Repositories, clock: any AppClock) {
        self.session = session
        self.mealState = repositories.mealState
        self.headcount = repositories.headcount
        self.entries = repositories.entries
        self.shortages = repositories.shortages
        self.wasteReports = repositories.wasteReports
        self.clock = clock
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            guard let status = try await mealState.currentMeal(for: session.mess.id) else {
                state = .empty
                return
            }
            let phase = try await loadPhase(for: status)
            let content = KitchenHomeContent(meal: status.meal, mess: session.mess, staffInitials: session.staffInitials,
                                             supervisorName: session.supervisorName, phase: phase)
            if case .duringMeal(let entered, _, _) = phase, let asOf = entered.asOf,
               clock.now().timeIntervalSince(asOf) > Self.staleAfter {
                state = .stale(content, asOf: asOf)
            } else {
                state = .loaded(content)
            }
        } catch RepositoryError.offline(let savedAt) {
            // Keep what was on screen; never claim anything new was recorded.
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    private func loadPhase(for status: MealStatus) async throws -> KitchenHomePhase {
        let mealID = status.meal.id
        let entryRepository = entries
        let shortageRepository = shortages
        let wasteRepository = wasteReports
        switch status.state {
        case .notStarted:
            let forecast = try await headcount.headcount(for: mealID).liveForecast
            return .beforeMeal(forecast: forecast)
        case .inService:
            async let entered = entryRepository.liveCount(for: mealID)
            async let reported = shortageRepository.shortages(for: mealID)
            let started = status.startedAt ?? status.meal.startsAt
            let minutes = MLFormat.minutes(from: started, to: clock.now())
            let allShortages = try await reported
            let enteredCount = try await entered
            let active = allShortages.filter { $0.status == .active }
            return .duringMeal(entered: enteredCount, minutesInService: minutes, shortages: active)
        case .closed:
            async let finalReading = entryRepository.finalCount(for: mealID)
            async let wasteSummary = wasteRepository.summary(for: mealID)
            let finalEntries = try await finalReading
            let waste = try await wasteSummary
            return .afterMeal(finalEntries: finalEntries, closedAt: status.closedAt, waste: waste)
        }
    }

    /// "You can edit until 8:40 PM." for a recorded report.
    func editableUntil(_ summary: WasteReportSummary) -> Date? {
        WasteReportPolicy.editableUntil(summary.status)
    }
}
