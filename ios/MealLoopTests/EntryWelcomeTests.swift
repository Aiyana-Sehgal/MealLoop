import XCTest
@testable import MealLoop

/// Welcome after the owner's 7 November review: no recent account is offered, and nothing about one is kept.
@MainActor
final class EntryWelcomeTests: XCTestCase {
    func testSigningOutKeepsNoAccountForWelcomeToOffer() {
        let store = SessionStore()
        XCTAssertNil(store.current)
        // The store holds the current session and nothing else, so Welcome has no "Continue as" account to show.
        let stored = Mirror(reflecting: store).children.compactMap(\.label).filter { !$0.contains("observationRegistrar") }
        XCTAssertEqual(stored, ["_current"])
    }

    func testWelcomeOffersOnlyTheTwoSignInActions() {
        XCTAssertEqual(EntryCopy.signInWithSRM, "Sign in with SRM")
        XCTAssertEqual(EntryCopy.staffSignIn, "Staff sign in")
    }

    func testTheTermsAreTheFramesTwoLines() {
        XCTAssertEqual(EntryCopy.termsLead, "By continuing, you agree to the")
        XCTAssertEqual(EntryCopy.termsLink, "Terms and Privacy Policy")
    }
}
