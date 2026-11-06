import XCTest
@testable import MealLoop

/// Sign-in and sign-out, and that nothing about an account stays on the device.
final class SessionStoreTests: XCTestCase {
    private let session = Session(account: Account(id: AccountID("a"), displayName: "a", email: "a@mealloop.example",
                                                   role: .warden, scope: .hostel(HostelID("h"))), staff: nil)

    func testANewStoreStartsSignedOut() {
        XCTAssertNil(SessionStore().current)
    }

    func testSignInSetsTheSessionAndSignOutClearsIt() {
        let store = SessionStore()
        store.signIn(session)
        XCTAssertEqual(store.current, session)
        store.signOut()
        XCTAssertNil(store.current)
    }

    func testARelaunchRemembersNobody() {
        SessionStore().signIn(session)
        XCTAssertNil(SessionStore().current)
    }

    func testSigningInWritesNothingToTheDevice() {
        let before = Set(UserDefaults.standard.dictionaryRepresentation().keys)
        SessionStore().signIn(session)
        XCTAssertEqual(Set(UserDefaults.standard.dictionaryRepresentation().keys), before)
    }
}
