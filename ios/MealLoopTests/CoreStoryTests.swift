#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// A clock the tests own, to prove the backend moves it through the protocol.
private final class TestClock: StoryClock, @unchecked Sendable {
    private var current = Date(timeIntervalSince1970: 0)
    func now() -> Date { current }
    func set(_ date: Date) { current = date }
}

/// The core cross-role story on one prototype data source.
final class CoreStoryTests: XCTestCase {
    private let lunch = DemoSeed.lunch
    private let aarav = DemoSeed.sampleStudent.id
    private let cutoff = IntentionPolicy.cutoff(for: DemoSeed.lunch)

    private func story(clock: TestClock = TestClock()) -> DemoDataProvider {
        DemoDataProvider(scenario: .storyStart, clock: clock)
    }

    private func assertRefused(line: UInt = #line, _ work: () async throws -> Void) async {
        do {
            try await work()
            XCTFail("Expected a refusal", line: line)
        } catch {
            guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)", line: line) }
        }
    }

    // MARK: Answers

    func testTheStoryStartsAtSevenWithNothingStarted() async throws {
        let demo = story()
        XCTAssertEqual(demo.clock.now(), DemoSeed.storyStartNow)
        let status = try await demo.currentMeal(for: DemoSeed.mess.id)
        XCTAssertEqual(status?.state, .notStarted)
    }

    func testLunchAnswerIsAcceptedAtSeven() async throws {
        let answer = try await story().setIntention(.attending, of: aarav, for: lunch.id)
        guard case .answered(.attending, _) = answer else { return XCTFail("\(answer)") }
    }

    func testTheAnswerCanChangeBeforeTheCutoff() async throws {
        let demo = story()
        _ = try await demo.setIntention(.attending, of: aarav, for: lunch.id)
        _ = try await demo.setIntention(.skipping, of: aarav, for: lunch.id)
        let stored = try await demo.response(of: aarav, for: lunch.id)
        guard case .answered(.skipping, _) = stored else { return XCTFail("\(stored)") }
    }

    func testAnAnswerIsRefusedAfterTheCutoff() async throws {
        let clock = TestClock()
        let demo = story(clock: clock)
        clock.set(cutoff)
        await assertRefused { _ = try await demo.setIntention(.attending, of: self.aarav, for: self.lunch.id) }
        let stored = try await demo.response(of: aarav, for: lunch.id)
        XCTAssertEqual(stored, .noResponse)
    }

    func testTheCutoffIsThatOfTheMealAnswered() async throws {
        // At 7:00 AM the lunch window is open and the breakfast one has closed.
        await assertRefused { _ = try await self.story().setIntention(.skipping, of: self.aarav, for: DemoSeed.breakfast.id) }
    }

    func testTheStudentStartsWithNoLunchResponse() async throws {
        let stored = try await story().response(of: aarav, for: lunch.id)
        XCTAssertEqual(stored, .noResponse)
    }

    func testTheStudentHasTheSeededBreakfastAnswer() async throws {
        let stored = try await story().response(of: aarav, for: DemoSeed.breakfast.id)
        XCTAssertEqual(stored, DemoSeed.sampleBreakfastAnswer)
        guard case .answered(.attending, let at) = stored else { return XCTFail("\(stored)") }
        XCTAssertLessThan(at, IntentionPolicy.cutoff(for: DemoSeed.breakfast))
    }

    func testARepeatTapKeepsTheFirstAnswer() async throws {
        let clock = TestClock()
        let demo = story(clock: clock)
        let first = try await demo.setIntention(.attending, of: aarav, for: lunch.id)
        clock.set(clock.now().addingTimeInterval(60))
        let second = try await demo.setIntention(.attending, of: aarav, for: lunch.id)
        XCTAssertEqual(first, second)
    }

    func testAnswerCountsAreDerivedFromTheSampleRoster() async throws {
        let demo = story()
        let before = try await demo.answerCounts(for: lunch.id)
        XCTAssertEqual(before, MealAnswerCounts(attending: 1, skipping: 1, notSure: 1, noResponse: 1))
        _ = try await demo.setIntention(.attending, of: aarav, for: lunch.id)
        let after = try await demo.answerCounts(for: lunch.id)
        XCTAssertEqual(after, MealAnswerCounts(attending: 2, skipping: 1, notSure: 1, noResponse: 0))
    }

    // MARK: Meals

    func testTheDayHasBreakfastThenLunch() async throws {
        let meals = try await story().meals(for: DemoSeed.mess.id)
        XCTAssertEqual(meals.map(\.meal.slot), [.breakfast, .lunch])
    }

    func testAnotherMessHasNoMeals() async throws {
        let meals = try await story().meals(for: MessID("other"))
        XCTAssertTrue(meals.isEmpty)
    }

    func testBreakfastHasMissingNumbersNotZero() async throws {
        let headcount = try await story().headcount(for: DemoSeed.breakfast.id)
        XCTAssertEqual(headcount.liveForecast, .notReady)
        XCTAssertEqual(headcount.approved, .notApproved)
        XCTAssertEqual(headcount.actualEntries, .unavailable)
        XCTAssertEqual(headcount.finalEntries, .unavailable)
    }

    func testBreakfastCannotBeRunByTheSupervisor() async {
        do {
            _ = try await story().startMeal(DemoSeed.breakfast.id, by: .supervisor)
            XCTFail("Only the story meal is started")
        } catch {
            XCTAssertEqual(error as? RepositoryError, .notFound)
        }
    }

    // MARK: Clock

    func testApprovingMovesTimeJustPastTheCutoff() async throws {
        let demo = story()
        _ = try await demo.approveHeadcount(DemoSeed.forecastDiners, reason: nil, for: lunch.id, by: .admin)
        XCTAssertEqual(demo.clock.now(), cutoff.addingTimeInterval(DemoSeed.approvalAfterCutoff))
        await assertRefused { _ = try await demo.setIntention(.attending, of: self.aarav, for: self.lunch.id) }
    }

    func testStartingMovesTimeToTheSeedStart() async throws {
        let demo = story()
        let status = try await demo.startMeal(lunch.id, by: .supervisor)
        XCTAssertEqual(demo.clock.now(), lunch.startsAt)
        XCTAssertEqual(status.startedAt, lunch.startsAt)
    }

    func testClosingMovesTimeToTheSeedEnd() async throws {
        let demo = story()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        let status = try await demo.closeMeal(lunch.id, by: .supervisor)
        XCTAssertEqual(demo.clock.now(), lunch.endsAt)
        XCTAssertEqual(status.closedAt, lunch.endsAt)
    }

    func testTimeNeverRunsBackwards() async throws {
        let clock = TestClock()
        let demo = story(clock: clock)
        clock.set(lunch.endsAt)
        _ = try await demo.approveHeadcount(DemoSeed.forecastDiners, reason: nil, for: lunch.id, by: .admin)
        XCTAssertEqual(clock.now(), lunch.endsAt)
    }

    func testARepeatApprovalDoesNotMoveTime() async throws {
        let clock = TestClock()
        let demo = story(clock: clock)
        _ = try await demo.approveHeadcount(DemoSeed.forecastDiners, reason: nil, for: lunch.id, by: .admin)
        let moved = clock.now()
        clock.set(moved.addingTimeInterval(60))
        _ = try await demo.approveHeadcount(DemoSeed.forecastDiners, reason: nil, for: lunch.id, by: .admin)
        XCTAssertEqual(clock.now(), moved.addingTimeInterval(60))
    }

    func testARelaunchResetsToSeven() async throws {
        let clock = TestClock()
        let demo = story(clock: clock)
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        let relaunched = story(clock: clock)
        XCTAssertEqual(relaunched.clock.now(), DemoSeed.storyStartNow)
        let status = try await relaunched.currentMeal(for: DemoSeed.mess.id)
        XCTAssertEqual(status?.state, .notStarted)
    }

    #if REVIEW_DATA
    func testTheReviewBuildBootsIntoTheStory() {
        let environment = AppEnvironment.make()
        XCTAssertEqual(environment.clock.now(), DemoSeed.storyStartNow)
        XCTAssertNil(environment.demoControls)
    }
    #endif

    #if DEMO_DATA
    func testTheDebugMenuKeepsItsSevenMoments() {
        let options = DemoDataProvider().scenarioOptions
        XCTAssertEqual(options.count, 7)
        XCTAssertFalse(options.contains { $0.id == DemoScenario.storyStart.rawValue })
    }
    #endif

    // MARK: Cross-role read

    func testTheDoorSideSeesTheStudentsAnswer() async throws {
        let demo = story()
        let repositories = demo.makeRepositories()
        _ = try await repositories.intentions.setIntention(.attending, of: aarav, for: lunch.id)
        _ = try await repositories.mealState.startMeal(lunch.id, by: .supervisor)
        let request = EntryRequest(mealID: lunch.id, student: DemoSeed.sampleStudent, method: .qrScan, idempotencyKey: .make())
        guard case .recorded(let record, _) = try await repositories.entries.recordEntry(request) else {
            return XCTFail("Expected a new entry")
        }
        XCTAssertTrue(record.hadMealResponse)
        let withoutVoting = try await repositories.entries.enteredWithoutVoting(for: lunch.id)
        XCTAssertTrue(withoutVoting.isEmpty)
    }

    func testTheAdminSideSeesTheStudentsAnswer() async throws {
        let repositories = story().makeRepositories()
        _ = try await repositories.intentions.setIntention(.notSure, of: aarav, for: lunch.id)
        let counts = try await repositories.intentions.answerCounts(for: lunch.id)
        XCTAssertEqual(counts.notSure, 2)
        let stored = try await repositories.intentions.response(of: aarav, for: lunch.id)
        guard case .answered(.notSure, _) = stored else { return XCTFail("\(stored)") }
    }

    func testTheLiveAndFinalCountsAreRecordedEntriesOnly() async throws {
        let demo = story()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        let empty = try await demo.liveCount(for: lunch.id)
        XCTAssertEqual(empty.value, 0)
        _ = try await demo.recordEntry(EntryRequest(mealID: lunch.id, student: DemoSeed.sampleStudent, method: .typedLastFour, idempotencyKey: .make()))
        let one = try await demo.liveCount(for: lunch.id)
        XCTAssertEqual(one.value, 1)
        _ = try await demo.closeMeal(lunch.id, by: .supervisor)
        let final = try await demo.finalCount(for: lunch.id)
        XCTAssertEqual(final.value, 1)
    }

    // MARK: Entry code

    func testEverySampleStudentHasAUniqueCode() async throws {
        let demo = story()
        var payloads = Set<String>()
        var lastFours = Set<String>()
        for sample in DemoSeed.sampleStudents {
            let code = try await demo.entryCode(for: sample.ref.id)
            payloads.insert(code.payload)
            lastFours.insert(code.lastFour)
            XCTAssertTrue(sample.ref.maskedID.hasSuffix(code.lastFour))
        }
        XCTAssertEqual(payloads.count, DemoSeed.sampleStudents.count)
        XCTAssertEqual(lastFours.count, DemoSeed.sampleStudents.count)
    }

    func testPayloadAndLastFourResolveToTheStudent() async throws {
        let demo = story()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        let code = try await demo.entryCode(for: aarav)
        let byPayload = try await demo.resolveEntry(.qrPayload(code.payload), for: lunch.id)
        let byDigits = try await demo.resolveEntry(.lastFour(code.lastFour), for: lunch.id)
        XCTAssertEqual(byPayload, .student(DemoSeed.sampleStudent))
        XCTAssertEqual(byDigits, .student(DemoSeed.sampleStudent))
    }

    func testAnInvalidCodeIsNotRecognised() async throws {
        let demo = story()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        let payload = try await demo.resolveEntry(.qrPayload("not-a-code"), for: lunch.id)
        let digits = try await demo.resolveEntry(.lastFour("9999"), for: lunch.id)
        XCTAssertEqual(payload, .notRecognised)
        XCTAssertEqual(digits, .notRecognised)
    }

    func testARealCodeForAMealNotBeingServedIsAWrongMeal() async throws {
        let demo = story()
        let code = try await demo.entryCode(for: aarav)
        let beforeStart = try await demo.resolveEntry(.qrPayload(code.payload), for: lunch.id)
        XCTAssertEqual(beforeStart, .wrongMeal(servingNow: nil))
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        let duringLunch = try await demo.resolveEntry(.qrPayload(code.payload), for: DemoSeed.breakfast.id)
        XCTAssertEqual(duringLunch, .wrongMeal(servingNow: .lunch))
    }

    func testARepeatScanAddsNothing() async throws {
        let demo = story()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        let first = EntryRequest(mealID: lunch.id, student: DemoSeed.sampleStudent, method: .qrScan, idempotencyKey: .make())
        let second = EntryRequest(mealID: lunch.id, student: DemoSeed.sampleStudent, method: .qrScan, idempotencyKey: .make())
        _ = try await demo.recordEntry(first)
        guard case .alreadyRecorded(_, let count) = try await demo.recordEntry(second) else { return XCTFail("Expected a repeat") }
        XCTAssertEqual(count, 1)
    }

    func testAnOfflineScanIsNeverAResult() async {
        do {
            _ = try await DemoDataProvider(scenario: .offline).resolveEntry(.lastFour("0238"), for: lunch.id)
            XCTFail("An unverified scan must not produce a result")
        } catch {
            guard case .offline? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testTheCodeIsAvailableForEveryAnswerAndAfterTheCutoff() async throws {
        for intention in MealIntention.allCases {
            let clock = TestClock()
            let demo = story(clock: clock)
            _ = try await demo.setIntention(intention, of: aarav, for: lunch.id)
            clock.set(cutoff.addingTimeInterval(60))
            let code = try await demo.entryCode(for: aarav)
            XCTAssertFalse(code.payload.isEmpty)
        }
        let unanswered = try await story().entryCode(for: aarav)
        XCTAssertFalse(unanswered.payload.isEmpty)
        let offline = try await DemoDataProvider(scenario: .offline).entryCode(for: aarav)
        XCTAssertFalse(offline.payload.isEmpty)
    }

    // MARK: Session

    func testAStudentSessionHasIdentityAndAMess() async throws {
        let session = try await story().signInWithSRM()
        XCTAssertEqual(session.student?.student, DemoSeed.sampleStudent)
        XCTAssertEqual(session.student?.mess, DemoSeed.mess)
        XCTAssertNil(session.staff)
    }

    func testNoOtherSessionHasAStudent() async throws {
        for account in DemoSeed.accounts where account.role != .student {
            let session = try await story().signInStaff(email: account.email, password: DemoSeed.prototypePassword)
            XCTAssertNil(session.student, "\(account.role)")
        }
    }
}
#endif
