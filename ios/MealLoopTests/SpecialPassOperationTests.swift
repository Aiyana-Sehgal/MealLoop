#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The pass operations added for the Pass Desk (FR-PASS-002 to 007), against the prototype backend.
final class SpecialPassOperationTests: XCTestCase {
    private let lunch = DemoSeed.lunch.id
    private let aarav = DemoSeed.sampleStudent

    private func serving() -> DemoDataProvider { DemoDataProvider(scenario: .duringMeal) }

    private func live(_ demo: DemoDataProvider) async throws -> LivePassCode {
        guard case .valid(_, let live) = try await demo.lookUpPass(lastFour: "0238", for: lunch) else {
            throw RepositoryError.notFound
        }
        return live
    }

    private func request(_ code: String, by role: Role = .passDesk, key: String = "k") -> SpecialPassEntryRequest {
        SpecialPassEntryRequest(mealID: lunch, student: aarav, comparedCode: code, recordedBy: role,
                                idempotencyKey: IdempotencyKey(key))
    }

    func testALookupNeverRecordsOrMovesTheCount() async throws {
        let demo = serving()
        let before = try await demo.specialMealCount(for: lunch)
        for lastFour in ["0238", "0412", "0377", "9999"] {
            _ = try await demo.lookUpPass(lastFour: lastFour, for: lunch)
        }
        let after = try await demo.specialMealCount(for: lunch)
        XCTAssertEqual(before.recorded.value, after.recorded.value)
        let entries = try await demo.specialMealEntries(for: lunch)
        XCTAssertTrue(entries.isEmpty)
    }

    func testTheSeededOutcomes() async throws {
        let demo = serving()
        if case .notFound = try await demo.lookUpPass(lastFour: "0999", for: lunch) {} else { XCTFail("0999") }
        if case .noPass = try await demo.lookUpPass(lastFour: "0412", for: lunch) {} else { XCTFail("0412") }
        guard case .wrongMeal(_, let slot) = try await demo.lookUpPass(lastFour: "0377", for: lunch) else {
            return XCTFail("0377")
        }
        XCTAssertEqual(slot, .dinner)
    }

    func testRecordingAddsOneAndARepeatAddsNothing() async throws {
        let demo = serving()
        let code = try await live(demo).code
        guard case .recorded(_, let count) = try await demo.recordPassEntry(request(code)) else { return XCTFail("recorded") }
        XCTAssertEqual(count, DemoSeed.specialMealsSoFar + 1)
        guard case .alreadyRecorded(_, let again) = try await demo.recordPassEntry(request(code, key: "other")) else {
            return XCTFail("already recorded")
        }
        XCTAssertEqual(again, count)
        let entries = try await demo.specialMealEntries(for: lunch)
        XCTAssertEqual(entries.map(\.student), [aarav])
    }

    func testTheSameKeyReturnsTheFirstResult() async throws {
        let demo = serving()
        let code = try await live(demo).code
        let first = try await demo.recordPassEntry(request(code))
        let second = try await demo.recordPassEntry(request(code))
        XCTAssertEqual(first, second)
    }

    func testAnOldCodeCannotRecord() async throws {
        let demo = serving()
        let old = try await live(demo).code
        let fresh = try await demo.refreshPassCode(for: aarav.id, meal: lunch)
        XCTAssertNotEqual(old, fresh.code)
        let result = try await demo.recordPassEntry(request(old))
        XCTAssertEqual(result, .codeChanged)
        let entries = try await demo.specialMealEntries(for: lunch)
        XCTAssertTrue(entries.isEmpty)
    }

    func testAnExpiredWindowCannotRecord() async throws {
        let clock = DemoClock(DemoSeed.duringMealNow)
        let demo = DemoDataProvider(scenario: .duringMeal, clock: clock)
        let live = try await live(demo)
        clock.set(live.changesAt)
        let result = try await demo.recordPassEntry(request(live.code))
        XCTAssertEqual(result, .codeChanged)
    }

    func testOnlyThePassDeskRecords() async throws {
        for role in Role.allCases where role != .passDesk {
            let demo = serving()
            let code = try await live(demo).code
            do {
                _ = try await demo.recordPassEntry(request(code, by: role))
                XCTFail("\(role) must not record")
            } catch {
                guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
            }
        }
    }

    func testOfflineRecordsNothing() async throws {
        let demo = serving()
        let code = try await live(demo).code
        await demo.setScenario(.offline)
        do {
            _ = try await demo.recordPassEntry(request(code))
            XCTFail("Offline must not record")
        } catch {
            guard case .offline? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
        await demo.setScenario(.duringMeal)
        let entries = try await demo.specialMealEntries(for: lunch)
        XCTAssertTrue(entries.isEmpty, "Nothing was queued")
    }

    func testCheckingFollowsTheMealState() async throws {
        let before = DemoDataProvider(scenario: .storyStart)
        let closed = DemoDataProvider(scenario: .afterMeal)
        let count = try await before.specialMealCount(for: lunch)
        XCTAssertEqual(count.recorded, .unavailable, "No count before the meal, and never zero")
        do {
            _ = try await before.recordPassEntry(request("218"))
            XCTFail("Checking has not opened")
        } catch {
            guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
        let result = try await closed.recordPassEntry(request("218"))
        XCTAssertEqual(result, .mealEnded(closedAt: DemoSeed.closedAt, count: DemoSeed.specialMealsFinal))
    }

    func testTheStoryCountsRecordedEntriesOnly() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        _ = try await demo.startMeal(lunch, by: .supervisor)
        let opening = try await demo.specialMealCount(for: lunch)
        XCTAssertEqual(opening.recorded.value, 0, "A real zero once the meal is open")
        XCTAssertEqual(opening.passes, DemoSeed.specialPassesTotal)
        let code = try await live(demo).code
        _ = try await demo.recordPassEntry(request(code))
        _ = try await demo.closeMeal(lunch, by: .supervisor)
        let final = try await demo.specialMealCount(for: lunch)
        XCTAssertEqual(final.recorded.value, 1)
    }

    func testPassEntriesStayOutOfTheDoorCount() async throws {
        let demo = serving()
        let before = try await demo.liveCount(for: lunch)
        let code = try await live(demo).code
        _ = try await demo.recordPassEntry(request(code))
        let after = try await demo.liveCount(for: lunch)
        XCTAssertEqual(before.value, after.value)
    }

    func testAnotherMealHasNoSpecialCount() async throws {
        let count = try await serving().specialMealCount(for: DemoSeed.breakfast.id)
        XCTAssertEqual(count, SpecialMealCount(recorded: .unavailable, passes: nil))
    }

    func testReissueStartsWaitingAndKeepsTheSeededStatuses() async throws {
        let demo = serving()
        let seeded = try await demo.reissueRequests(for: DemoSeed.mess.id)
        XCTAssertEqual(seeded.map(\.status), [.waiting, .approved, .done, .rejected])
        let submission = PassReissueSubmission(student: aarav, reason: .phoneLost, requestedBy: .passDesk,
                                               idempotencyKey: IdempotencyKey("r"))
        let request = try await demo.requestReissue(submission)
        XCTAssertEqual(request.status, .waiting)
        _ = try await demo.requestReissue(submission)
        let all = try await demo.reissueRequests(for: DemoSeed.mess.id)
        XCTAssertEqual(all.count, seeded.count + 1, "The same key adds one request")
    }

    func testOnlyThePassDeskRequestsANewPass() async throws {
        let submission = PassReissueSubmission(student: aarav, reason: .other, requestedBy: .student,
                                               idempotencyKey: IdempotencyKey("r"))
        do {
            _ = try await serving().requestReissue(submission)
            XCTFail("Only the desk")
        } catch {
            guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testRemoteHasNoPassServiceAndSaysSo() async {
        do {
            _ = try await RemoteAPI(baseURL: nil).makeRepositories().specialPasses.lookUpPass(lastFour: "0238", for: lunch)
            XCTFail("Must not fake a result")
        } catch {
            guard case .notImplemented? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }
}
#endif
