import Foundation
import Observation

/// Where recent accounts are kept. Injected so tests never touch the device's defaults.
protocol RecentAccountsStoring {
    func load() -> [RecentAccount]
    func save(_ accounts: [RecentAccount])
}

/// Keeps recent accounts in UserDefaults. `RecentAccount` has no secret fields, so none can be written here.
struct UserDefaultsRecentAccountsStore: RecentAccountsStoring {
    private let key = "recentAccounts.v1"
    var defaults: UserDefaults = .standard

    func load() -> [RecentAccount] {
        guard let data = defaults.data(forKey: key),
              let accounts = try? JSONDecoder().decode([RecentAccount].self, from: data) else { return [] }
        return accounts
    }

    func save(_ accounts: [RecentAccount]) {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        defaults.set(data, forKey: key)
    }
}

/// The signed-in session and the accounts offered on Welcome. One instance, made at the composition root.
@Observable
final class SessionStore {
    private(set) var current: Session?
    private(set) var recentAccounts: [RecentAccount]
    @ObservationIgnored private let recentStore: any RecentAccountsStoring

    init(recentStore: any RecentAccountsStoring) {
        self.recentStore = recentStore
        recentAccounts = recentStore.load()
    }

    /// Starts the session and moves the account to the top of the recent list.
    func signIn(_ session: Session) {
        current = session
        let recent = RecentAccount(session.account)
        recentAccounts = [recent] + recentAccounts.filter { $0.id != recent.id }
        recentAccounts = Array(recentAccounts.prefix(Role.allCases.count))
        recentStore.save(recentAccounts)
    }

    /// Ends the session. Recent accounts stay so the next sign-in is one tap.
    func signOut() {
        current = nil
    }
}
