import XCTest
@testable import MealLoop

private final class MemoryRecentStore: RecentAccountsStoring {
    var saved: [RecentAccount] = []
    func load() -> [RecentAccount] { saved }
    func save(_ accounts: [RecentAccount]) { saved = accounts }
}

/// Sign-out and what the device remembers.
final class SessionStoreTests: XCTestCase {
    private func session(_ handle: String, _ role: Role = .warden) -> Session {
        Session(account: Account(id: AccountID(handle), displayName: handle, email: "\(handle)@mealloop.example",
                                 role: role, scope: .hostel(HostelID("h"))), staff: nil)
    }

    func testSignOutClearsTheSessionAndKeepsRecentAccounts() {
        let store = SessionStore(recentStore: MemoryRecentStore())
        store.signIn(session("a"))
        XCTAssertNotNil(store.current)
        store.signOut()
        XCTAssertNil(store.current)
        XCTAssertEqual(store.recentAccounts.map(\.id), [AccountID("a")])
    }

    func testLatestAccountComesFirstWithoutDuplicates() {
        let store = SessionStore(recentStore: MemoryRecentStore())
        store.signIn(session("a"))
        store.signIn(session("b"))
        store.signIn(session("a"))
        XCTAssertEqual(store.recentAccounts.map(\.id), [AccountID("a"), AccountID("b")])
    }

    func testRecentAccountsSurviveARelaunch() {
        let memory = MemoryRecentStore()
        SessionStore(recentStore: memory).signIn(session("a"))
        let relaunched = SessionStore(recentStore: memory)
        XCTAssertEqual(relaunched.recentAccounts.map(\.id), [AccountID("a")])
        XCTAssertNil(relaunched.current, "A relaunch never signs anyone in by itself")
    }

    func testRecentListIsCapped() {
        let store = SessionStore(recentStore: MemoryRecentStore())
        for index in 0..<(Role.allCases.count + 3) { store.signIn(session("a\(index)")) }
        XCTAssertEqual(store.recentAccounts.count, Role.allCases.count)
    }

    func testRecentAccountStoresOnlyIdentityFields() throws {
        let data = try JSONEncoder().encode(RecentAccount(session("a").account))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["id", "displayName", "role", "email"])
    }

    func testCorruptStoredDataReadsAsNoAccounts() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "SessionStoreTests"))
        defer { defaults.removePersistentDomain(forName: "SessionStoreTests") }
        defaults.set(Data("not json".utf8), forKey: "recentAccounts.v1")
        XCTAssertTrue(UserDefaultsRecentAccountsStore(defaults: defaults).load().isEmpty)
    }
}
