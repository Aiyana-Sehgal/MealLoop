import Foundation
import Observation

/// Kitchen Home (K01, K02, K03, K05). Reads the shared meal state and the feeds behind it through repositories.
@MainActor
@Observable
final class KitchenHomeViewModel {
    /// Live entries older than this are shown as stale ("Updated 1:12 PM · reconnecting").
    static let staleAfter: TimeInterval = 2 * 60

    private(set) var state: LoadState<KitchenHomeContent> = .idle
    /// Reports that did not reach the Supervisor. They stay on Home with Retry and are never shown as sent.
    private(set) var failedReports: [KitchenFailedReport] = []
    private(set) var dishes: [Dish] = []
    private(set) var isSending = false
    let session: StaffSession

    private let mealState: any MealStateRepository
    private let headcount: any HeadcountRepository
    private let entries: any EntryRepository
    private let shortages: any ShortageRepository
    private let wasteReports: any WasteReportRepository
    private let meals: any MealRepository
    private let clock: any AppClock

    init(session: StaffSession, repositories: Repositories, clock: any AppClock) {
        self.session = session
        self.mealState = repositories.mealState
        self.headcount = repositories.headcount
        self.entries = repositories.entries
        self.shortages = repositories.shortages
        self.wasteReports = repositories.wasteReports
        self.meals = repositories.meals
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

    /// The day's dishes for the report sheet. A failed read leaves the list empty, and the sheet cannot send.
    func loadDishes() async {
        guard let meal = state.value?.meal else { return }
        dishes = (try? await meals.menu(for: meal.id)) ?? []
    }

    /// Sends a report. A dish is required. A repeat for the same dish within ten minutes asks first (kitchen_spec.md).
    /// If the meal has ended, or the send fails, nothing is claimed as delivered.
    func reportShortage(dish: String?, level: ShortageLevel, note: String?, confirmed: Bool = false) async -> KitchenReportOutcome {
        guard let dish, !isSending, let meal = state.value?.meal else { return .needsDish }
        isSending = true
        defer { isSending = false }
        let text = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let report = ShortageReport(mealID: meal.id, dishName: dish, level: level, note: text.isEmpty ? nil : text,
                                    reportedBy: session.role, idempotencyKey: .make())
        do {
            if let status = try await mealState.currentMeal(for: session.mess.id), status.state == .closed {
                await load()
                return .mealEnded(at: status.closedAt)
            }
            if !confirmed, let earlier = try await recentReport(of: dish, for: meal.id) {
                return .alreadyReported(earlier)
            }
            _ = try await shortages.reportShortage(report)
            await load()
            return .sent
        } catch {
            failedReports.append(KitchenFailedReport(report: report))
            return .couldNotSend
        }
    }

    private func recentReport(of dish: String, for meal: MealID) async throws -> Shortage? {
        let now = clock.now()
        return try await shortages.shortages(for: meal).last { shortage in
            shortage.dishName == dish && now.timeIntervalSince(shortage.reportedAt) < KitchenHomeContent.repeatWindow
        }
    }

    /// Sends the same report again. Its key is unchanged, so it can never be recorded twice.
    func retry(_ failed: KitchenFailedReport) async {
        guard !isSending else { return }
        isSending = true
        defer { isSending = false }
        guard (try? await shortages.reportShortage(failed.report)) != nil else { return }
        failedReports.removeAll { $0.id == failed.id }
        await load()
    }

    /// "You can edit until 8:40 PM." for a recorded report.
    func editableUntil(_ summary: WasteReportSummary) -> Date? {
        WasteReportPolicy.editableUntil(summary.status)
    }
}
