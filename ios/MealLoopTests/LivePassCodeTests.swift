#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The clock-derived live pass code (P-PASS-9 a): one code per window, the same for the phone and the desk.
final class LivePassCodeTests: XCTestCase {
    private let aarav = DemoSeed.sampleStudent.id
    private let lunch = DemoSeed.lunch.id

    private func duringLunch() async throws -> DemoDataProvider {
        let demo = DemoDataProvider(scenario: .duringMeal)
        return demo
    }

    func testTheCodeHoldsWithinAWindowAndChangesAtTheBoundary() async throws {
        let demo = try await duringLunch()
        let start = Date(timeIntervalSince1970: 1_723_617_000) // a multiple of 10 s
        let first = try await demo.currentPassCode(for: aarav, meal: lunch, at: start)
        let late = try await demo.currentPassCode(for: aarav, meal: lunch, at: start.addingTimeInterval(9.9))
        XCTAssertEqual(first.live, late.live, "Same code, colour and end inside one window")
        XCTAssertEqual(first.secondsLeft, Int(DemoSeed.passCodeWindow))
        XCTAssertEqual(late.secondsLeft, 1)
        let next = try await demo.currentPassCode(for: aarav, meal: lunch, at: start.addingTimeInterval(10))
        XCTAssertEqual(next.windowIndex, first.windowIndex + 1)
        XCTAssertNotEqual(next.live.code, first.live.code)
        XCTAssertNotEqual(next.live.colourName, first.live.colourName)
    }

    func testAnExpiredWindowIsNeverCurrent() async throws {
        let demo = try await duringLunch()
        let start = Date(timeIntervalSince1970: 1_723_617_000)
        let first = try await demo.currentPassCode(for: aarav, meal: lunch, at: start)
        let atEnd = try await demo.currentPassCode(for: aarav, meal: lunch, at: first.live.changesAt)
        XCTAssertNotEqual(atEnd.windowIndex, first.windowIndex)
        XCTAssertGreaterThan(atEnd.live.changesAt, first.live.changesAt)
    }

    func testThePhoneAndTheDeskReadTheSameInstantAndCode() async throws {
        let demo = try await duringLunch()
        let phoneInstant = await demo.passCodeInstant()
        let deskInstant = await demo.passCodeInstant()
        let phone = try await demo.currentPassCode(for: aarav, meal: lunch, at: phoneInstant)
        let desk = try await demo.currentPassCode(for: aarav, meal: lunch, at: deskInstant)
        XCTAssertEqual(phone.live.code, desk.live.code)
        XCTAssertEqual(phone.live.colourName, desk.live.colourName)
    }

    func testReadingTheCodeNeverRecords() async throws {
        let demo = try await duringLunch()
        let before = try await demo.specialMealEntries(for: lunch).count
        for step in 0..<5 {
            _ = try await demo.currentPassCode(for: aarav, meal: lunch, at: Date(timeIntervalSince1970: TimeInterval(step * 10)))
        }
        let after = try await demo.specialMealEntries(for: lunch).count
        XCTAssertEqual(before, after)
    }

    func testAStudentWithoutAPassForThisMealGetsNoCode() async throws {
        let demo = try await duringLunch()
        do {
            _ = try await demo.currentPassCode(for: StudentID("demo-student-0377"), meal: lunch, at: Date())
            XCTFail("Kiran's pass is for dinner")
        } catch RepositoryError.notFound {}
    }

    func testTheCurrentCodeRecordsOnceAndAStaleCodeNever() async throws {
        let demo = try await duringLunch()
        let current = try await demo.currentPassCode(for: aarav, meal: lunch, at: await demo.passCodeInstant())
        let stale = try await demo.currentPassCode(for: aarav, meal: lunch, at: current.live.changesAt)
        func request(_ code: String, _ key: String) -> SpecialPassEntryRequest {
            SpecialPassEntryRequest(mealID: lunch, student: DemoSeed.sampleStudent, comparedCode: code, recordedBy: .passDesk,
                                    idempotencyKey: IdempotencyKey(key))
        }
        let refused = try await demo.recordPassEntryForCurrentCode(request(stale.live.code, "a"))
        XCTAssertEqual(refused, .codeChanged)
        let none = try await demo.specialMealEntries(for: lunch).count
        XCTAssertEqual(none, 0)
        guard case .recorded = try await demo.recordPassEntryForCurrentCode(request(current.live.code, "b")) else {
            return XCTFail("The current code records")
        }
        guard case .alreadyRecorded = try await demo.recordPassEntryForCurrentCode(request(current.live.code, "c")) else {
            return XCTFail("A repeat is refused")
        }
        let one = try await demo.specialMealEntries(for: lunch).count
        XCTAssertEqual(one, 1)
    }

    func testOfflineReadsAndRecordsNothing() async throws {
        let demo = DemoDataProvider(scenario: .offline)
        do {
            _ = try await demo.currentPassCode(for: aarav, meal: lunch, at: Date())
            XCTFail("Offline")
        } catch RepositoryError.offline {}
        do {
            _ = try await demo.recordPassEntryForCurrentCode(SpecialPassEntryRequest(
                mealID: lunch, student: DemoSeed.sampleStudent, comparedCode: "218", recordedBy: .passDesk,
                idempotencyKey: IdempotencyKey("k")))
            XCTFail("Offline")
        } catch RepositoryError.offline {}
    }

    func testTheTickerAddsElapsedTimeAndRestartsWhenTheStoryMoves() {
        final class Uptime: @unchecked Sendable { var value: TimeInterval = 100 }
        let uptime = Uptime()
        let ticker = PassCodeTicker(uptime: { uptime.value })
        let story = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(ticker.instant(story: story), story)
        uptime.value = 107
        XCTAssertEqual(ticker.instant(story: story), story.addingTimeInterval(7))
        let moved = story.addingTimeInterval(3_600)
        XCTAssertEqual(ticker.instant(story: moved), moved, "A story jump starts counting again")
    }
}
#endif
