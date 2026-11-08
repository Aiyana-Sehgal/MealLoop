#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SIMULATED. Deactivations and reset requests recorded for one run of the app. Nothing is sent and sign-in is unchanged.
actor DemoSuperAdminStore {
    private var deactivated: [AccountID: Date] = [:]
    private var resets: [AccountID: Date] = [:]

    func deactivatedAt(_ id: AccountID) -> Date? { deactivated[id] }
    func resetAt(_ id: AccountID) -> Date? { resets[id] }
    /// The first record stays.
    func deactivate(_ id: AccountID, at date: Date) { if deactivated[id] == nil { deactivated[id] = date } }
    func reset(_ id: AccountID, at date: Date) { if resets[id] == nil { resets[id] = date } }
}

/// SIMULATED. The seeded accounts (`DemoSeed.accounts`, which hold no password) as the Super Admin sees them. Every
/// seeded account can sign in, so each starts active.
struct DemoSuperAdmin: SuperAdminRepository {
    let core: DemoDataProvider
    let store: DemoSuperAdminStore

    private func require(_ role: Role) throws {
        guard role == .superAdmin else {
            throw RepositoryError.notAllowed(reason: "Only the Super Admin manages accounts.")
        }
    }

    private func managed(_ account: Account) async -> ManagedAccount {
        let deactivatedAt = await store.deactivatedAt(account.id)
        return ManagedAccount(account: account, isActive: deactivatedAt == nil, deactivatedAt: deactivatedAt,
                              resetStartedAt: await store.resetAt(account.id))
    }

    private func seeded(_ id: AccountID) throws -> Account {
        guard let account = DemoSeed.accounts.first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        return account
    }

    func accounts(by role: Role) async throws -> [ManagedAccount] {
        try await core.requireConnection()
        try require(role)
        var list: [ManagedAccount] = []
        for account in DemoSeed.accounts { list.append(await managed(account)) }
        return list
    }

    func account(_ id: AccountID, by role: Role) async throws -> ManagedAccount {
        try await core.requireConnection()
        try require(role)
        return await managed(try seeded(id))
    }

    func deactivate(_ id: AccountID, by role: Role) async throws -> ManagedAccount {
        try await core.requireConnection()
        try require(role)
        let account = try seeded(id)
        guard account.role != .superAdmin else {
            throw RepositoryError.notAllowed(reason: "A Super Admin account can't be deactivated here.")
        }
        await store.deactivate(id, at: core.clock.now())
        return await managed(account)
    }

    func startPasswordReset(_ id: AccountID, by role: Role) async throws -> ManagedAccount {
        try await core.requireConnection()
        try require(role)
        let account = try seeded(id)
        await store.reset(id, at: core.clock.now())
        return await managed(account)
    }
}
#endif
