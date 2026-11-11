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
        // Breakfast stays open until its service ends at 9:30 AM; after that it refuses.
        let clock = TestClock()
        let demo = story(clock: clock)
        _ = try await demo.setIntention(.skipping, of: aarav, for: DemoSeed.breakfast.id)
        clock.set(DemoSeed.breakfast.endsAt)
        await assertRefused { _ = try await demo.setIntention(.attending, of: self.aarav, for: DemoSeed.breakfast.id) }
    }

    func testTheStudentStartsWithNoLunchResponse() async throws {
        let stored = try await story().response(of: aarav, for: lunch.id)
        XCTAssertEqual(stored, .noResponse)
    }

    /// Home · Not answered (221:62529): at 7:00 AM breakfast is unanswered and still open to answers.
    func testTheStudentStartsWithBreakfastUnansweredAndOpen() async throws {
        let stored = try await story().response(of: aarav, for: DemoSeed.breakfast.id)
        XCTAssertEqual(stored, .noResponse)
        XCTAssertTrue(IntentionPolicy.canAnswer(DemoSeed.breakfast, at: DemoSeed.storyStartNow))
        // The swipe-to-remind needs the cutoff more than an hour away.
        XCTAssertGreaterThan(IntentionPolicy.cutoff(for: DemoSeed.breakfast), DemoSeed.storyStartNow.addingTimeInterval(60 * 60))
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

    // Nothing in the backend moves the clock: time runs on its own (the running demo clock), and the gates follow it.

    func testApprovingKeepsTheTimeAndTheCutoffStillLocksAnswers() async throws {
        let clock = TestClock()
        let demo = story(clock: clock)
        _ = try await demo.approveHeadcount(DemoSeed.forecastDiners, reason: nil, for: lunch.id, by: .admin)
        XCTAssertEqual(clock.now(), DemoSeed.storyStartNow)
        clock.set(cutoff)
        await assertRefused { _ = try await demo.setIntention(.attending, of: self.aarav, for: self.lunch.id) }
    }

    func testStartingRecordsTheTimeItHappened() async throws {
        let demo = story()
        let status = try await demo.startMeal(lunch.id, by: .supervisor)
        XCTAssertEqual(demo.clock.now(), DemoSeed.storyStartNow)
        XCTAssertEqual(status.startedAt, DemoSeed.storyStartNow)
    }

    func testClosingRecordsTheTimeItHappened() async throws {
        let clock = TestClock()
        let demo = story(clock: clock)
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        clock.set(DemoSeed.storyStartNow.addingTimeInterval(90 * 60))
        let status = try await demo.closeMeal(lunch.id, by: .supervisor)
        XCTAssertEqual(status.closedAt, DemoSeed.storyStartNow.addingTimeInterval(90 * 60))
        XCTAssertEqual(clock.now(), DemoSeed.storyStartNow.addingTimeInterval(90 * 60))
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

    /// Debug and Review both launch clean at Wed 14 Aug, 7:00 AM, with the Demo sheet's controls.
    func testTheSeededBuildsBootAtSevenWithTheDemoControls() {
        let environment = AppEnvironment.make()
        let now = environment.clock.now()
        XCTAssertGreaterThanOrEqual(now, DemoSeed.storyStartNow)
        XCTAssertLessThan(now, DemoSeed.storyStartNow.addingTimeInterval(60))
        XCTAssertNotNil(environment.demoControls)
    }

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

    // MARK: The whole story

    /// Every step of the core story, in order, on one provider: what one student does reaches every other role.
    func testTheWholeStoryRunsInOrderOnOneDataSource() async throws {
        let demo = story()
        let data = demo.makeRepositories()
        let vendor = try XCTUnwrap(DemoSeed.accounts.first { $0.role == .vendor }).email

        // Sign-in, and the student answers and has the entry QR.
        let student = try await data.auth.srmStudentSession()
        let aaravRef = try XCTUnwrap(student.student?.student)
        _ = try await data.intentions.setIntention(.attending, of: aaravRef.id, for: lunch.id)
        let code = try await data.entries.entryCode(for: aaravRef.id)

        // The Food Head approves and publishes; the vendor acknowledges.
        _ = try await data.headcount.approveHeadcount(DemoSeed.forecastDiners, reason: nil, for: lunch.id, by: .admin)
        _ = try await data.headcount.publishHeadcount(for: lunch.id, by: .admin)
        let vendorSession = try await data.auth.signInStaff(email: vendor, password: DemoSeed.prototypePassword)
        let acknowledged = try await data.headcount.acknowledgeHeadcount(for: lunch.id, by: vendorSession.account.id)
        guard case .acknowledged = acknowledged.vendorAcknowledgmentStatus else { return XCTFail("Expected acknowledged") }

        // The Supervisor starts the meal; the Door Scanner verifies and records the entry.
        demo.clock.set(DemoSeed.lunch.startsAt)  // The clock no longer jumps; move it as the story does.

        _ = try await data.mealState.startMeal(lunch.id, by: .supervisor)
        guard case .student(let scanned) = try await data.entries.resolveEntry(.qrPayload(code.payload), for: lunch.id) else {
            return XCTFail("Expected the student")
        }
        _ = try await data.entries.recordEntry(EntryRequest(mealID: lunch.id, student: scanned, method: .qrScan, idempotencyKey: .make()))

        // The Kitchen sees the live count and reports a shortage.
        let live = try await data.entries.liveCount(for: lunch.id)
        XCTAssertEqual(live.value, 1)
        _ = try await data.shortages.reportShortage(ShortageReport(mealID: lunch.id, dishName: DemoSeed.shortageDish, level: .almostOut,
                                                                   note: nil, reportedBy: .kitchenStaff, idempotencyKey: .make()))
        let shortages = try await data.shortages.shortages(for: lunch.id)
        XCTAssertEqual(shortages.map(\.dishName), [DemoSeed.shortageDish])

        // The Supervisor closes the meal; the Kitchen records waste.
        demo.clock.set(DemoSeed.lunch.endsAt)  // The clock no longer jumps; move it as the story does.

        _ = try await data.mealState.closeMeal(lunch.id, by: .supervisor)
        var report = try await data.wasteReports.report(for: lunch.id)
        report.leftovers = report.leftovers.map { var row = $0; row.measurement = .noneLeft; return row }
        report.plateWaste = .entered(kilograms: 1)
        let saved = try await data.wasteReports.save(report, by: .kitchenStaff)
        guard case .recorded = saved.status else { return XCTFail("Expected recorded") }

        // The Supervisor and Admin read the same values.
        let summary = try await data.wasteReports.summary(for: lunch.id)
        XCTAssertEqual(summary.status, saved.status)
        let headcount = try await data.headcount.headcount(for: lunch.id)
        XCTAssertEqual(headcount.finalEntries.value, 1)
        XCTAssertEqual(headcount.approved.count, DemoSeed.forecastDiners)
        XCTAssertEqual(headcount.sentToVendor.count, DemoSeed.forecastDiners)
        XCTAssertEqual(headcount.actualEntries, .unavailable)
        XCTAssertEqual(demo.clock.now(), lunch.endsAt)
    }

    // MARK: Waste

    private func closedStory() async throws -> (DemoDataProvider, WasteReport) {
        let demo = story()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        _ = try await demo.closeMeal(lunch.id, by: .supervisor)
        var report = try await demo.report(for: lunch.id)
        report.leftovers = report.leftovers.map { var row = $0; row.measurement = .noneLeft; return row }
        report.plateWaste = .entered(kilograms: 1)
        return (demo, report)
    }

    func testOnlyKitchenStaffCanSaveWaste() async throws {
        for role in Role.allCases where role != .kitchenStaff {
            let (demo, report) = try await closedStory()
            await assertRefused { _ = try await demo.save(report, by: role) }
            await assertRefused { _ = try await demo.saveDraft(report, by: role) }
            let stored = try await demo.report(for: lunch.id)
            XCTAssertEqual(stored.status, .notStarted, "\(role)")
            XCTAssertEqual(stored.plateWaste, .notEntered, "\(role)")
        }
    }

    func testKitchenStaffCanSaveADraftAndTheReport() async throws {
        let (demo, report) = try await closedStory()
        let draft = try await demo.saveDraft(report, by: .kitchenStaff)
        guard case .draft = draft.status else { return XCTFail("\(draft.status)") }
        let saved = try await demo.save(report, by: .kitchenStaff)
        guard case .recorded = saved.status else { return XCTFail("\(saved.status)") }
    }

    func testSupervisorAndAdminCanStillReadTheReport() async throws {
        let (demo, report) = try await closedStory()
        let saved = try await demo.save(report, by: .kitchenStaff)
        let repositories = demo.makeRepositories()
        let read = try await repositories.wasteReports.report(for: lunch.id)
        let summary = try await repositories.wasteReports.summary(for: lunch.id)
        XCTAssertEqual(read, saved)
        XCTAssertEqual(summary.status, saved.status)
    }

    // MARK: Session

    func testAStudentSessionHasIdentityAndAMess() async throws {
        let session = try await story().srmStudentSession()
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
