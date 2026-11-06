import Foundation
import Observation

/// The SOS cases of the mess for the Supervisor (S03, S04, S05). The tab exists only while a case is active.
/// Claim, Mark as checked and Close case go to the SOS repository, which is the one that decides who may close.
@MainActor
@Observable
final class SupervisorSOSModel {
    private(set) var cases: [SOSCase] = []
    /// A claim, check or close is being written.
    private(set) var isWorking = false
    /// Why the last action did not happen. Shown in the panel; nothing changed.
    private(set) var actionError: String?

    let session: StaffSession
    private let repository: any SOSRepository
    private let clock: any AppClock

    init(session: StaffSession, repositories: Repositories, clock: any AppClock) {
        self.session = session
        self.repository = repositories.sos
        self.clock = clock
    }

    /// The case the panel shows: the oldest one still open.
    var current: SOSCase? { cases.first }

    var stage: SupervisorSOSStage? { current.map { SupervisorSOSStage($0, viewer: session.role) } }

    var isClaimedByYou: Bool { current?.claim?.role == session.role }

    var now: Date { clock.now() }

    func load() async {
        do {
            cases = try await repository.activeCases(for: session.mess.id).sorted { $0.raisedAt < $1.raisedAt }
        } catch RepositoryError.offline {
            // Keep what was shown; an offline phone cannot say a case has closed.
        } catch {
            cases = []
        }
    }

    @discardableResult
    func claim() async -> Bool {
        await act { try await self.repository.claim($0, by: self.session.role) }
    }

    @discardableResult
    func markChecked() async -> Bool {
        await act { try await self.repository.markChecked($0, by: self.session.role) }
    }

    /// Closes the case. The repository refuses it for any role but the Supervisor.
    @discardableResult
    func close() async -> Bool {
        await act { try await self.repository.close($0, by: self.session.role) }
    }

    private func act(_ change: @escaping (SOSCaseID) async throws -> SOSCase) async -> Bool {
        guard let id = current?.id, !isWorking else { return false }
        isWorking = true
        actionError = nil
        defer { isWorking = false }
        do {
            _ = try await change(id)
            await load()
            return true
        } catch {
            actionError = LoadFailure(error).message
            return false
        }
    }
}
