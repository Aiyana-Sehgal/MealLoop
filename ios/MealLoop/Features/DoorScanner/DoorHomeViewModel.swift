import Foundation
import Observation

/// What Door Home shows, by meal state. The Supervisor controls the state; this only follows it.
/// - before the meal: the opening time only, no count and no way to enter anyone;
/// - during the meal: recorded entries only;
/// - after the meal: final entries and the two lists.
enum DoorHomePhase: Equatable {
    case beforeMeal(opensAt: Date)
    case duringMeal(recorded: CountReading, minutesInService: Int)
    case afterMeal(finalEntries: CountReading, closedAt: Date?, withoutVoting: Int)
}

struct DoorHomeContent: Equatable {
    let status: MealStatus
    let phase: DoorHomePhase

    var meal: Meal { status.meal }

    /// Entry is offered only while the meal is in service.
    var canEnterStudents: Bool {
        if case .duringMeal = phase { return true }
        return false
    }

    /// The count for Me. Nil before the meal, because there is nothing to show yet.
    var recordedCount: CountReading? {
        switch phase {
        case .beforeMeal: return nil
        case .duringMeal(let recorded, _): return recorded
        case .afterMeal(let finalEntries, _, _): return finalEntries
        }
    }
}

/// Only a Door Scanner session may open this role.
enum DoorScannerAccess {
    static func canOpen(_ session: Session) -> Bool {
        session.account.role == .doorScanner && session.staff?.role == .doorScanner
    }
}

/// Door Home, and the meal facts Alerts and Me read from it.
@MainActor
@Observable
final class DoorHomeViewModel {
    private(set) var state: LoadState<DoorHomeContent> = .idle
    let session: StaffSession

    private let mealState: any MealStateRepository
    private let entries: any EntryRepository
    private let clock: any AppClock

    init(session: StaffSession, repositories: Repositories, clock: any AppClock) {
        self.session = session
        self.mealState = repositories.mealState
        self.entries = repositories.entries
        self.clock = clock
    }

    var isOffline: Bool {
        if case .offline = state { return true }
        return false
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
            state = .loaded(DoorHomeContent(status: status, phase: try await phase(for: status)))
        } catch RepositoryError.offline(let savedAt) {
            // Keep what was on screen; nothing new is claimed.
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    private func phase(for status: MealStatus) async throws -> DoorHomePhase {
        let mealID = status.meal.id
        switch status.state {
        case .notStarted:
            return .beforeMeal(opensAt: status.meal.startsAt)
        case .inService:
            let recorded = try await entries.liveCount(for: mealID)
            let started = status.startedAt ?? status.meal.startsAt
            return .duringMeal(recorded: recorded, minutesInService: MLFormat.minutes(from: started, to: clock.now()))
        case .closed:
            let finalEntries = try await entries.finalCount(for: mealID)
            let withoutVoting = try await entries.enteredWithoutVoting(for: mealID)
            return .afterMeal(finalEntries: finalEntries, closedAt: status.closedAt, withoutVoting: withoutVoting.count)
        }
    }
}

/// The Entered without voting list (D15).
@MainActor
@Observable
final class DoorWithoutVotingViewModel {
    private(set) var state: LoadState<[EnteredWithoutVoting]> = .idle
    private let entries: any EntryRepository
    private let meal: MealID

    init(entries: any EntryRepository, meal: MealID) {
        self.entries = entries
        self.meal = meal
    }

    func load() async {
        state = .loading
        do {
            let list = try await entries.enteredWithoutVoting(for: meal)
            state = list.isEmpty ? .empty : .loaded(list)
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(nil, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }
}
