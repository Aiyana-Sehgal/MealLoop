import XCTest
@testable import MealLoop

/// The hold behind Use pass: complete, release early, cancel.
@MainActor
final class PassHoldTrackerTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_000)

    func testAFullHoldCompletes() {
        let hold = PassHoldTracker()
        hold.press(at: start)
        XCTAssertEqual(hold.outcome, .holding)
        hold.complete()
        XCTAssertEqual(hold.outcome, .completed)
        let late = PassHoldTracker()
        late.press(at: start)
        XCTAssertEqual(late.release(at: start.addingTimeInterval(PassHoldTracker.holdSeconds)), .completed)
    }

    func testReleasingEarlyUsesNothing() {
        let hold = PassHoldTracker()
        hold.press(at: start)
        XCTAssertEqual(hold.release(at: start.addingTimeInterval(0.4)), .released)
        hold.complete()
        XCTAssertEqual(hold.outcome, .released, "A released hold cannot complete afterwards.")
    }

    func testCancelUsesNothing() {
        let hold = PassHoldTracker()
        hold.press(at: start)
        hold.cancel()
        XCTAssertEqual(hold.outcome, .cancelled)
        hold.complete()
        XCTAssertEqual(hold.outcome, .cancelled)
        hold.reset()
        XCTAssertEqual(hold.outcome, .idle)
    }
}
