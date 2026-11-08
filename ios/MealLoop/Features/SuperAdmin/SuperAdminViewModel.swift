import Foundation
import Observation

/// Accounts and one account's page. Screen state only: who may act and what is recorded belong to
/// `SuperAdminRepository`. Nothing here holds or shows a password.
@MainActor
@Observable
final class SuperAdminViewModel {
    enum Send: Equatable { case idle, sending, failed(String) }

    private(set) var accounts: LoadState<[ManagedAccount]> = .idle
    private(set) var send: Send = .idle
    let role: Role
    private let repository: any SuperAdminRepository

    init(role: Role, repository: any SuperAdminRepository) {
        self.role = role
        self.repository = repository
    }

    func account(_ id: AccountID) -> ManagedAccount? { accounts.value?.first { $0.id == id } }

    func load() async {
        do {
            accounts = .loaded(try await repository.accounts(by: role))
        } catch RepositoryError.offline(let savedAt) {
            accounts = .offline(accounts.value, savedAt: savedAt)
        } catch {
            accounts = .failed(LoadFailure(error))
        }
    }

    func deactivate(_ id: AccountID) async {
        await act { try await self.repository.deactivate(id, by: self.role) }
    }

    func startPasswordReset(_ id: AccountID) async {
        await act { try await self.repository.startPasswordReset(id, by: self.role) }
    }

    /// Shown as recorded only after the repository recorded it.
    private func act(_ operation: () async throws -> ManagedAccount) async {
        guard send != .sending else { return }
        send = .sending
        do {
            let updated = try await operation()
            if var list = accounts.value, let index = list.firstIndex(where: { $0.id == updated.id }) {
                list[index] = updated
                accounts = .loaded(list)
            }
            send = .idle
        } catch {
            send = .failed(LoadFailure(error).message)
        }
    }
}
