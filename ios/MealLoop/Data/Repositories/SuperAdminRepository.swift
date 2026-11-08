import Foundation

/// The Super Admin's accounts list. Separate from the core repositories, so no existing operation changes. Every
/// operation is refused for any role but the Super Admin, and nothing here reads or returns a password.
protocol SuperAdminRepository: Sendable {
    /// Every account, grouped the way the seed lists them.
    func accounts(by role: Role) async throws -> [ManagedAccount]
    func account(_ id: AccountID, by role: Role) async throws -> ManagedAccount
    /// SIMULATED in the prototype: the deactivation is recorded, and sign-in is not changed. A Super Admin can't
    /// deactivate a Super Admin account. Recording it again changes nothing.
    func deactivate(_ id: AccountID, by role: Role) async throws -> ManagedAccount
    /// SIMULATED in the prototype: the request is recorded and nothing is sent. No password is set, shown or read.
    func startPasswordReset(_ id: AccountID, by role: Role) async throws -> ManagedAccount
}

/// The answer of any data source with no account service yet. It never fakes a result.
struct UnavailableSuperAdmin: SuperAdminRepository {
    private var unavailable: RepositoryError { .notImplemented(feature: "Super Admin accounts") }

    func accounts(by role: Role) async throws -> [ManagedAccount] { throw unavailable }
    func account(_ id: AccountID, by role: Role) async throws -> ManagedAccount { throw unavailable }
    func deactivate(_ id: AccountID, by role: Role) async throws -> ManagedAccount { throw unavailable }
    func startPasswordReset(_ id: AccountID, by role: Role) async throws -> ManagedAccount { throw unavailable }
}
