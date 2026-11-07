import Foundation
import Observation

/// Alerts (S07, S08, S09): the SOS card on top while a case is active, then Shortages, then Waste not recorded.
@MainActor
@Observable
final class SupervisorAlertsViewModel {
    struct Content: Equatable {
        let mess: Mess
        let followUps: SupervisorFollowUps
    }

    private(set) var state: LoadState<Content> = .idle
    let session: StaffSession
    let sosModel: SupervisorSOSModel
    private let repositories: Repositories

    init(session: StaffSession, repositories: Repositories, clock: any AppClock) {
        self.session = session
        self.repositories = repositories
        self.sosModel = SupervisorSOSModel(session: session, repositories: repositories, clock: clock)
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        await sosModel.load()
        do {
            let current = try await repositories.mealState.currentMeal(for: session.mess.id)
            let followUps = try await SupervisorFollowUps.load(mess: session.mess.id, current: current,
                                                               repositories: repositories)
            state = .loaded(Content(mess: session.mess, followUps: followUps))
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }
}

/// Shortage details (S12) and "Mark shortage as resolved?" (S13).
@MainActor
@Observable
final class SupervisorShortageViewModel {
    private(set) var state: LoadState<Shortage> = .idle
    private(set) var isResolving = false
    private(set) var actionError: String?

    let session: StaffSession
    let shortageID: ShortageID
    private let repositories: Repositories

    init(shortageID: ShortageID, session: StaffSession, repositories: Repositories) {
        self.shortageID = shortageID
        self.session = session
        self.repositories = repositories
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            guard let current = try await repositories.mealState.currentMeal(for: session.mess.id),
                  let shortage = try await repositories.shortages.shortages(for: current.meal.id)
                    .first(where: { $0.id == shortageID }) else {
                state = .failed(LoadFailure(RepositoryError.notFound))
                return
            }
            state = .loaded(try await seen(shortage))
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    /// Opening a report is the Supervisor seeing it: the repository records the sighting once, by the seeded
    /// Supervisor's name, so the Kitchen status row can say "Ravi saw it". Any other role only reads.
    private func seen(_ shortage: Shortage) async throws -> Shortage {
        guard session.role == .supervisor, case .sent = shortage.delivery else { return shortage }
        return try await repositories.shortages.markSeen(shortage.id, by: session.role)
    }

    /// Marks the shortage resolved. Returns true when the data source accepted it.
    @discardableResult
    func markResolved() async -> Bool {
        guard !isResolving else { return false }
        isResolving = true
        actionError = nil
        defer { isResolving = false }
        do {
            state = .loaded(try await repositories.shortages.markResolved(shortageID, by: session.role))
            return true
        } catch {
            actionError = LoadFailure(error).message
            return false
        }
    }
}

/// Waste report (S10, S11), read only. The Supervisor has no save, edit, approve or forward action: the
/// repository refuses a save from any role but Kitchen Staff, and this screen offers none.
@MainActor
@Observable
final class SupervisorWasteReportViewModel {
    private(set) var state: LoadState<SupervisorWasteContent> = .idle
    let session: StaffSession
    let mealID: MealID
    private let repositories: Repositories

    init(mealID: MealID, session: StaffSession, repositories: Repositories) {
        self.mealID = mealID
        self.session = session
        self.repositories = repositories
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            let history = try await repositories.mealState.mealHistory(for: session.mess.id)
            guard let record = history.first(where: { $0.mealID == mealID }) else {
                state = .failed(LoadFailure(RepositoryError.notFound))
                return
            }
            state = .loaded(SupervisorWasteContent(record: record, mess: session.mess, report: try await rows(for: record)))
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    /// The kitchen's rows. Today's meal is read from the waste report repository, the same report the kitchen saves;
    /// an earlier meal's rows come with its history record. Missing quantities stay nil.
    private func rows(for record: MealRecord) async throws -> WasteReport? {
        guard case .recorded = record.waste else { return nil }
        let current = try await repositories.mealState.currentMeal(for: session.mess.id)
        guard current?.meal.id == record.mealID else { return record.wasteReport }
        do {
            let report = try await repositories.wasteReports.report(for: record.mealID)
            if case .recorded = report.status { return report }
            return nil
        } catch RepositoryError.notImplemented {
            return nil
        }
    }
}

/// Me (S16): the person, the follow-up counts, Meal history and Sign out.
@MainActor
@Observable
final class SupervisorMeViewModel {
    private(set) var state: LoadState<SupervisorFollowUps> = .idle
    let session: StaffSession
    private let repositories: Repositories

    init(session: StaffSession, repositories: Repositories) {
        self.session = session
        self.repositories = repositories
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            let current = try await repositories.mealState.currentMeal(for: session.mess.id)
            state = .loaded(try await SupervisorFollowUps.load(mess: session.mess.id, current: current,
                                                               repositories: repositories))
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }
}

/// Meal history (S18) and Past meal (S19). Read only; an empty list is its own state ("No meals yet").
@MainActor
@Observable
final class SupervisorHistoryViewModel {
    private(set) var state: LoadState<SupervisorHistoryContent> = .idle
    let session: StaffSession
    private let repositories: Repositories

    init(session: StaffSession, repositories: Repositories) {
        self.session = session
        self.repositories = repositories
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            let records = try await repositories.mealState.mealHistory(for: session.mess.id)
            state = records.isEmpty ? .empty : .loaded(SupervisorHistoryContent(mess: session.mess, records: records))
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    func record(_ id: MealID) -> MealRecord? {
        state.value?.records.first { $0.mealID == id }
    }
}

/// Past meal (S19): one closed meal, read only.
@MainActor
@Observable
final class SupervisorPastMealViewModel {
    private(set) var state: LoadState<MealRecord> = .idle
    let session: StaffSession
    let mealID: MealID
    private let repositories: Repositories

    init(mealID: MealID, session: StaffSession, repositories: Repositories) {
        self.mealID = mealID
        self.session = session
        self.repositories = repositories
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            let history = try await repositories.mealState.mealHistory(for: session.mess.id)
            guard let record = history.first(where: { $0.mealID == mealID }) else {
                state = .failed(LoadFailure(RepositoryError.notFound))
                return
            }
            state = .loaded(record)
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }
}
