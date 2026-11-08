#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// Owner ruling (Prompt 2B): the student's hold is the entry; 30 s In use, then Used for good; the desk only reads.
final class PassUseTests: XCTestCase {
    private let aarav = DemoSeed.sampleStudent.id
    private let lunch = DemoSeed.lunch.id

    private func world() -> (DemoDataProvider, DemoClock) {
        let clock = DemoClock(DemoSeed.duringMealNow)
        return (DemoDataProvider(scenario: .duringMeal, clock: clock), clock)
    }

    func testAHoldIsInUseForThirtySecondsThenUsed() async throws {
        let (demo, _) = world()
        guard case .inUse(let usedAt, let until, let left) = try await demo.usePass(of: aarav, meal: lunch, key: IdempotencyKey("a")) else {
            return XCTFail("In use")
        }
        XCTAssertEqual(left, Int(PassUsePolicy.validity))
        XCTAssertEqual(until, usedAt.addingTimeInterval(PassUsePolicy.validity))
        let at29 = try await demo.passUseState(of: aarav, meal: lunch, at: usedAt.addingTimeInterval(29))
        guard case .inUse(_, _, 1) = at29 else { return XCTFail("Still in use at 29 s: \(at29)") }
        let at30 = try await demo.passUseState(of: aarav, meal: lunch, at: usedAt.addingTimeInterval(30))
        XCTAssertEqual(at30, .used(usedAt: usedAt))
    }

    func testASecondHoldIsRefusedAndTheSameKeyReturnsTheFirst() async throws {
        let (demo, _) = world()
        let first = try await demo.usePass(of: aarav, meal: lunch, key: IdempotencyKey("a"))
        let again = try await demo.usePass(of: aarav, meal: lunch, key: IdempotencyKey("a"))
        XCTAssertEqual(first, again)
        do {
            _ = try await demo.usePass(of: aarav, meal: lunch, key: IdempotencyKey("b"))
            XCTFail("Already used")
        } catch RepositoryError.notAllowed(let reason) { XCTAssertEqual(reason, "Already used") }
    }

    func testTheHoldRecordsOneEntryAndTheDeskCountsIt() async throws {
        let (demo, _) = world()
        _ = try await demo.usePass(of: aarav, meal: lunch, key: IdempotencyKey("a"))
        let entries = try await demo.specialMealEntries(for: lunch)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.recordedBy, .student)
    }

    func testCheckingTheLastFourNeverRecordsAndFollowsTheState() async throws {
        let (demo, _) = world()
        let start = await demo.passCodeInstant()
        let before = try await demo.checkLastFour("0238", meal: lunch, at: start)
        guard case .validNotUsed(_, .lunch) = before else { return XCTFail("\(before)") }
        let none = try await demo.specialMealEntries(for: lunch).count
        XCTAssertEqual(none, 0, "A lookup records nothing")
        guard case .inUse(let usedAt, _, _) = try await demo.usePass(of: aarav, meal: lunch, key: IdempotencyKey("a")) else {
            return XCTFail("In use")
        }
        let during = try await demo.checkLastFour("0238", meal: lunch, at: usedAt.addingTimeInterval(10))
        guard case .inUse(_, 20) = during else { return XCTFail("\(during)") }
        let after = try await demo.checkLastFour("0238", meal: lunch, at: usedAt.addingTimeInterval(30))
        guard case .used = after else { return XCTFail("\(after)") }
        let nobody = try await demo.checkLastFour("9999", meal: lunch, at: start)
        XCTAssertEqual(nobody, .notFound)
        let kiran = try await demo.checkLastFour("0377", meal: lunch, at: start)
        guard case .wrongMeal(_, .dinner) = kiran else { return XCTFail("\(kiran)") }
    }

    func testThePhoneAndTheDeskAgreeOnTheCode() async throws {
        let (demo, _) = world()
        let instant = await demo.passCodeInstant()
        let desk = try await demo.deskCode(for: lunch, at: instant)
        let phone = try await demo.currentPassCode(for: aarav, meal: lunch, at: instant)
        XCTAssertEqual(desk, phone)
        let next = try await demo.deskCode(for: lunch, at: desk.live.changesAt)
        XCTAssertNotEqual(next.live.code, desk.live.code)
    }

    func testOfflineNeitherUsesNorChecks() async {
        let demo = DemoDataProvider(scenario: .offline)
        do {
            _ = try await demo.usePass(of: aarav, meal: lunch, key: IdempotencyKey("a"))
            XCTFail("Offline")
        } catch RepositoryError.offline {} catch { XCTFail("\(error)") }
        do {
            _ = try await demo.checkLastFour("0238", meal: lunch, at: Date())
            XCTFail("Offline")
        } catch RepositoryError.offline {} catch { XCTFail("\(error)") }
    }
}
#endif
