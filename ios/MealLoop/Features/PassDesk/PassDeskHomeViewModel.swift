import Foundation
import Observation

/// Pass Desk Home, and the meal facts Alerts and Me read from it.
@MainActor
@Observable
final class PassDeskHomeViewModel {
    private(set) var state: LoadState<PassDeskHomeContent> = .idle
    /// When this shift began, once it has. Nil means the chip says only "On shift".
    private(set) var shiftStartedAt: Date?
    let session: StaffSession
    /// The live code and colour on Home (owner ruling, Prompt 2B). The desk records nothing.
    let code: PassDeskLiveCodeModel

    private let repositories: Repositories
    private let clock: any AppClock

    init(session: StaffSession, repositories: Repositories, clock: any AppClock) {
        self.session = session
        self.repositories = repositories
        self.clock = clock
        self.code = PassDeskLiveCodeModel(use: repositories.passUse, live: repositories.livePassCodes)
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            guard let status = try await repositories.mealState.currentMeal(for: session.mess.id) else {
                state = .empty
                return
            }
            let mealID = status.meal.id
            let count = try await repositories.specialPasses.specialMealCount(for: mealID)
            let requests = try await repositories.specialPasses.reissueRequests(for: session.mess.id)
            let shortages = try await repositories.shortages.shortages(for: mealID)
            let content = PassDeskHomeContent(status: status, phase: Self.phase(for: status), count: count, requests: requests,
                                              reportedShortages: shortages.filter { $0.reportedBy == session.role })
            state = .loaded(content)
            if case .duringMeal = content.phase {
                await code.load(meal: mealID)
            } else {
                code.clear()
            }
            let started = try? await repositories.staffDirectory.shiftStartedAt(for: session.role, mess: session.mess.id)
            shiftStartedAt = started.flatMap { $0 <= clock.now() ? $0 : nil }
        } catch RepositoryError.offline(let savedAt) {
            // Keep what was on screen; nothing new is claimed, and no code is shown as valid.
            state = .offline(state.value, savedAt: savedAt)
            code.clear()
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    private static func phase(for status: MealStatus) -> PassDeskHomePhase {
        switch status.state {
        case .notStarted: return .beforeMeal(opensAt: status.meal.startsAt)
        case .inService: return .duringMeal
        case .closed: return .afterMeal(closedAt: status.closedAt)
        }
    }
}
