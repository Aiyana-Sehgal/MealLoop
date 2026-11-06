#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

private final class TestClock: StoryClock, @unchecked Sendable {
    private let lock = NSLock()
    private var current = Date(timeIntervalSince1970: 0)
    func now() -> Date { lock.lock(); defer { lock.unlock() }; return current }
    func set(_ date: Date) { lock.lock(); current = date; lock.unlock() }
}

/// An entry repository that fails on `recordEntry` until told otherwise, to prove nothing is recorded offline.
private final class FlakyEntries: EntryRepository, @unchecked Sendable {
    let base: any EntryRepository
    var isOffline = true
    var attempts: [IdempotencyKey] = []

    init(_ base: any EntryRepository) { self.base = base }

    func recordEntry(_ request: EntryRequest) async throws -> EntryResult {
        attempts.append(request.idempotencyKey)
        if isOffline { throw RepositoryError.offline(lastSavedAt: nil) }
        return try await base.recordEntry(request)
    }
    func liveCount(for meal: MealID) async throws -> CountReading { try await base.liveCount(for: meal) }
    func finalCount(for meal: MealID) async throws -> CountReading { try await base.finalCount(for: meal) }
    func enteredWithoutVoting(for meal: MealID) async throws -> [EnteredWithoutVoting] { try await base.enteredWithoutVoting(for: meal) }
    func entryCode(for student: StudentID) async throws -> EntryCode { try await base.entryCode(for: student) }
    func resolveEntry(_ credential: EntryCredential, for meal: MealID) async throws -> EntryCredentialResult {
        try await base.resolveEntry(credential, for: meal)
    }
}

/// A stand-in that can be told to fail a write. The real prototype path is covered by `testARaisedCaseRunsThroughTheDoorOnTheRealBackend`.
private actor FakeSOS: SOSRepository {
    private var cases: [SOSCase]
    private(set) var closeCalls = 0
    var failNext = false

    init(_ cases: [SOSCase]) { self.cases = cases }

    func setFailNext() { failNext = true }
    func raise(_ report: SOSReport) async throws -> SOSCase { cases[0] }
    func activeCases(for mess: MessID) async throws -> [SOSCase] { cases }
    func claim(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase {
        try update { $0.claim = SOSClaim(role: role, at: DemoSeed.duringMealNow) }
    }
    func markChecked(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase {
        try update { $0.checks.append(SOSCheck(role: role, at: DemoSeed.duringMealNow)) }
    }
    func close(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase {
        closeCalls += 1
        return cases[0]
    }
    private func update(_ change: (inout SOSCase) -> Void) throws -> SOSCase {
        if failNext { failNext = false; throw RepositoryError.offline(lastSavedAt: nil) }
        change(&cases[0])
        return cases[0]
    }
}

@MainActor
final class DoorScannerTests: XCTestCase {
    private let lunch = DemoSeed.lunch
    private let meera = "0412"
    private let aarav = "0238"

    private var session: StaffSession {
        StaffSession(role: .doorScanner, mess: DemoSeed.mess, staffInitials: DemoSeed.staffInitials(for: .doorScanner),
                     supervisorName: DemoSeed.supervisorName)
    }

    /// The core story with the Supervisor having started lunch.
    private func storyInService(clock: TestClock = TestClock()) async throws -> DemoDataProvider {
        let demo = DemoDataProvider(scenario: .storyStart, clock: clock)
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        return demo
    }

    private func flow(_ repositories: Repositories) -> DoorEntryFlow {
        DoorEntryFlow(meal: lunch.id, mess: DemoSeed.mess.id, repositories: repositories)
    }

    private func type(_ digits: String, into flow: DoorEntryFlow) async {
        for character in digits {
            await flow.append(Int(String(character)) ?? 0)
        }
    }

    private func replacing(entries: any EntryRepository, in base: Repositories) -> Repositories {
        Repositories(meals: base.meals, mealState: base.mealState, headcount: base.headcount, entries: entries,
                     intentions: base.intentions, shortages: base.shortages, wasteReports: base.wasteReports,
                     sos: base.sos, auth: base.auth)
    }

    private func count(_ demo: DemoDataProvider) async throws -> Int? {
        try await demo.liveCount(for: lunch.id).value
    }

    // MARK: Home follows the meal state

    func testHomeBeforeTheMealShowsTheOpeningTimeFromDataAndOffersNoEntry() async {
        let demo = DemoDataProvider(scenario: .storyStart, clock: TestClock())
        let model = DoorHomeViewModel(session: session, repositories: demo.makeRepositories(), clock: demo.clock)
        await model.load()
        guard case .loaded(let content) = model.state else { return XCTFail("\(model.state)") }
        XCTAssertEqual(content.phase, .beforeMeal(opensAt: lunch.startsAt))
        XCTAssertFalse(content.canEnterStudents)
        XCTAssertNil(content.recordedCount, "No count before the meal")
    }

    func testHomeFollowsTheSupervisorThroughTheMeal() async throws {
        let demo = DemoDataProvider(scenario: .storyStart, clock: TestClock())
        let model = DoorHomeViewModel(session: session, repositories: demo.makeRepositories(), clock: demo.clock)
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        await model.load()
        guard case .duringMeal(let recorded, let minutes)? = model.state.value?.phase else { return XCTFail("\(model.state)") }
        XCTAssertEqual(recorded.value, 0, "The story's count starts at zero and counts real entries only")
        XCTAssertEqual(minutes, 0)
        XCTAssertEqual(model.state.value?.canEnterStudents, true)

        _ = try await demo.closeMeal(lunch.id, by: .supervisor)
        await model.load()
        guard case .afterMeal(let finalEntries, let closedAt, _)? = model.state.value?.phase else { return XCTFail("\(model.state)") }
        XCTAssertEqual(finalEntries.value, 0)
        XCTAssertEqual(closedAt, lunch.endsAt)
        XCTAssertEqual(model.state.value?.canEnterStudents, false)
    }

    func testHomeOfflineKeepsTheLastContentAndSaysSo() async {
        let demo = DemoDataProvider(scenario: .duringMeal)
        let model = DoorHomeViewModel(session: session, repositories: demo.makeRepositories(), clock: demo.clock)
        await model.load()
        await demo.setScenario(.offline)
        await model.load()
        XCTAssertTrue(model.isOffline)
        XCTAssertNotNil(model.state.value)
    }

    // MARK: Outcomes

    func testTypedEntryWithAnAnswerIsRecorded() async throws {
        let demo = try await storyInService()
        let flow = flow(demo.makeRepositories())
        await type(meera, into: flow)
        await flow.recordMatch()
        guard case .recorded(let student, let total, let withoutVoting)? = flow.outcome else { return XCTFail("\(String(describing: flow.outcome))") }
        XCTAssertEqual(student.maskedID, "••0412")
        XCTAssertEqual(total, 1)
        XCTAssertFalse(withoutVoting)
        let list = try await demo.enteredWithoutVoting(for: lunch.id)
        XCTAssertTrue(list.isEmpty, "A student who answered is not on the list")
    }

    func testNoResponseStudentIsRecordedAndListedWithNoDeclineStep() async throws {
        let demo = try await storyInService()
        let flow = flow(demo.makeRepositories())
        await type(aarav, into: flow)
        await flow.recordMatch()
        guard case .recorded(_, let total, let withoutVoting)? = flow.outcome else { return XCTFail("\(String(describing: flow.outcome))") }
        XCTAssertTrue(withoutVoting)
        XCTAssertEqual(total, 1, "Counted like anyone else")
        let list = try await demo.enteredWithoutVoting(for: lunch.id)
        XCTAssertEqual(list.map(\.student.maskedID), ["••0238"])
        let answer = try await demo.response(of: DemoSeed.sampleStudent.id, for: lunch.id)
        XCTAssertEqual(answer, .noResponse, "Entering is not a vote")
    }

    func testRepeatIsNotCountedTwice() async throws {
        let demo = try await storyInService()
        let repositories = demo.makeRepositories()
        let first = flow(repositories)
        await type(meera, into: first)
        await first.recordMatch()
        let second = flow(repositories)
        await type(meera, into: second)
        await second.recordMatch()
        guard case .alreadyScanned(_, _, let total)? = second.outcome else { return XCTFail("\(String(describing: second.outcome))") }
        XCTAssertEqual(total, 1)
        let live = try await count(demo)
        XCTAssertEqual(live, 1)
    }

    func testUnknownDigitsAreNoMatchAndRecordNothing() async throws {
        let demo = try await storyInService()
        let flow = flow(demo.makeRepositories())
        await type("9999", into: flow)
        XCTAssertEqual(flow.lookup, .noMatch)
        await flow.recordMatch()
        XCTAssertNil(flow.outcome)
        let live = try await count(demo)
        XCTAssertEqual(live, 0)
    }

    func testALookupNeverRecords() async throws {
        let demo = try await storyInService()
        let flow = flow(demo.makeRepositories())
        await type(meera, into: flow)
        guard case .match = flow.lookup else { return XCTFail("\(flow.lookup)") }
        let live = try await count(demo)
        XCTAssertEqual(live, 0)
        XCTAssertNil(flow.outcome)
    }

    func testDeleteAfterAMatchLetsTheStaffCorrectTheDigits() async throws {
        let demo = try await storyInService()
        let flow = flow(demo.makeRepositories())
        await type(meera, into: flow)
        flow.deleteLast()
        XCTAssertEqual(flow.lookup, .typing)
        XCTAssertEqual(flow.entry.text, "041")
        await flow.append(2)
        guard case .match = flow.lookup else { return XCTFail("\(flow.lookup)") }
    }

    func testAnUnknownQRIsNotRecognised() async throws {
        let demo = try await storyInService()
        let flow = flow(demo.makeRepositories())
        await flow.scan(payload: "not-an-entry-code")
        XCTAssertEqual(flow.outcome, .notRecognised)
        let live = try await count(demo)
        XCTAssertEqual(live, 0)
    }

    func testAKnownQRUsesTheEntryCodeTheModelDefinesAndRecords() async throws {
        let demo = try await storyInService()
        let code = try await demo.entryCode(for: DemoSeed.sampleStudent.id)
        let flow = flow(demo.makeRepositories())
        await flow.scan(payload: code.payload)
        XCTAssertEqual(flow.outcome?.isRecorded, true)
    }

    func testWrongMealComesFromTheBackendWithTheMealBeingServed() async throws {
        let clock = TestClock()
        let demo = DemoDataProvider(scenario: .storyStart, clock: clock)
        clock.set(DemoSeed.breakfast.startsAt)
        let flow = flow(demo.makeRepositories())
        await type(meera, into: flow)
        XCTAssertEqual(flow.outcome, .wrongMeal(servingNow: .breakfast))
        XCTAssertEqual(flow.lookup, .typing)
    }

    func testMealEndedDuringAScanIsNotRecorded() async throws {
        let demo = try await storyInService()
        let flow = flow(demo.makeRepositories())
        await type(meera, into: flow)
        _ = try await demo.closeMeal(lunch.id, by: .supervisor)
        await flow.recordMatch()
        guard case .mealEnded(let closedAt, let finalEntries)? = flow.outcome else { return XCTFail("\(String(describing: flow.outcome))") }
        XCTAssertEqual(closedAt, lunch.endsAt)
        XCTAssertEqual(finalEntries.value, 0)
    }

    // MARK: Offline is never a success

    func testOfflineLookupIsNeverAMatch() async throws {
        let demo = DemoDataProvider(scenario: .offline)
        let flow = flow(demo.makeRepositories())
        await type(meera, into: flow)
        XCTAssertEqual(flow.lookup, .offline)
        await flow.recordMatch()
        XCTAssertNil(flow.outcome, "Nothing to record from an unverified lookup")
    }

    func testOfflineScanIsNeverASuccess() async {
        let demo = DemoDataProvider(scenario: .offline)
        let flow = flow(demo.makeRepositories())
        await flow.scan(payload: "demo-entry-0412")
        XCTAssertEqual(flow.outcome, .offline(lastUpdate: DemoSeed.offlineSavedAt))
        XCTAssertEqual(flow.outcome?.isRecorded, false)
    }

    func testConnectionLostWhileRecordingRecordsNothingAndRetryCountsOnce() async throws {
        let demo = try await storyInService()
        let base = demo.makeRepositories()
        let flaky = FlakyEntries(base.entries)
        let flow = flow(replacing(entries: flaky, in: base))
        await type(meera, into: flow)
        await flow.recordMatch()
        XCTAssertEqual(flow.outcome, .offline(lastUpdate: nil))
        let afterFailure = try await count(demo)
        XCTAssertEqual(afterFailure, 0)

        flaky.isOffline = false
        await flow.retry()
        XCTAssertEqual(flow.outcome?.isRecorded, true)
        let afterRetry = try await count(demo)
        XCTAssertEqual(afterRetry, 1)
        XCTAssertEqual(Set(flaky.attempts).count, 1, "A retry reuses the same key")
    }

    func testAnUnknownFailureIsNotShownAsAnAnswer() async throws {
        let demo = try await storyInService()
        let flow = DoorEntryFlow(meal: MealID("not-a-meal"), mess: DemoSeed.mess.id, repositories: demo.makeRepositories())
        await type(meera, into: flow)
        XCTAssertEqual(flow.lookup, .offline, "An unverified failure never reads as no such student")
    }

    func testDoubleTapRecordsOnce() async throws {
        let demo = try await storyInService()
        let flow = flow(demo.makeRepositories())
        await type(meera, into: flow)
        async let first: Void = flow.recordMatch()
        async let second: Void = flow.recordMatch()
        _ = await (first, second)
        let live = try await count(demo)
        XCTAssertEqual(live, 1)
    }

    // MARK: Across roles

    func testKitchenSeesEachRecordedEntry() async throws {
        let demo = try await storyInService()
        let repositories = demo.makeRepositories()
        let kitchenSession = StaffSession(role: .kitchenStaff, mess: DemoSeed.mess, staffInitials: DemoSeed.staffInitials(for: .kitchenStaff),
                                          supervisorName: DemoSeed.supervisorName)
        let kitchen = KitchenHomeViewModel(session: kitchenSession, repositories: repositories, clock: demo.clock)

        func kitchenCount() async -> Int? {
            await kitchen.load()
            if case .duringMeal(let entered, _, _)? = kitchen.state.value?.phase { return entered.value }
            return nil
        }

        let before = await kitchenCount()
        XCTAssertEqual(before, 0)
        for (index, digits) in [meera, aarav].enumerated() {
            let door = flow(repositories)
            await type(digits, into: door)
            await door.recordMatch()
            let seen = await kitchenCount()
            XCTAssertEqual(seen, index + 1)
        }
    }

    func testOnlyADoorScannerSessionOpensTheRole() {
        for account in DemoSeed.accounts {
            let staff = account.role.isMessStaff
                ? StaffSession(role: account.role, mess: DemoSeed.mess, staffInitials: "SK", supervisorName: DemoSeed.supervisorName) : nil
            let session = Session(account: account, staff: staff, student: nil)
            XCTAssertEqual(DoorScannerAccess.canOpen(session), account.role == .doorScanner, "\(account.role)")
            XCTAssertEqual(RoleRoot.destination(for: account.role) == .doorScanner, account.role == .doorScanner)
        }
    }

    func testASessionWhoseStaffRoleDiffersCannotOpenTheRole() throws {
        let door = try XCTUnwrap(DemoSeed.accounts.first { $0.role == .doorScanner })
        let kitchen = StaffSession(role: .kitchenStaff, mess: DemoSeed.mess, staffInitials: "AK", supervisorName: DemoSeed.supervisorName)
        XCTAssertFalse(DoorScannerAccess.canOpen(Session(account: door, staff: kitchen, student: nil)))
        XCTAssertFalse(DoorScannerAccess.canOpen(Session(account: door, staff: nil, student: nil)))
    }

    // MARK: SOS

    private func sampleCase() -> SOSCase {
        SOSCase(id: SOSCaseID("test-sos"), messID: DemoSeed.mess.id, title: "Test case", place: "Test place",
                raisedAt: DemoSeed.duringMealNow, claim: nil, checks: [], status: .open)
    }

    func testARaisedCaseRunsThroughTheDoorOnTheRealBackend() async throws {
        let demo = DemoDataProvider(scenario: .duringMeal)
        let sos = demo.makeRepositories().sos
        let model = DoorSOSViewModel(sos: sos, mess: session.mess.id, role: .doorScanner)
        await model.load()
        XCTAssertNil(model.current, "No tab before anything is raised")

        let raised = try await sos.raise(SOSReport(messID: session.mess.id, title: DemoSeed.sosTitle, place: DemoSeed.sosPlace,
                                                   idempotencyKey: .make()))
        await model.load()
        XCTAssertEqual(model.current?.id, raised.id)
        XCTAssertEqual(model.stage, .notTaken)

        await model.claim()
        XCTAssertEqual(model.stage, .claimedByYou)
        let checked = await model.markChecked()
        XCTAssertTrue(checked)
        XCTAssertEqual(model.stage, .checkedByYou(at: demo.clock.now()))

        let stillActive = try await sos.activeCases(for: session.mess.id)
        XCTAssertEqual(stillActive.map(\.id), [raised.id], "A check leaves the case open for the Supervisor")
        XCTAssertEqual(stillActive.first?.status, .open)

        _ = try await sos.close(raised.id, by: .supervisor)
        await model.load()
        XCTAssertNil(model.current, "The tab goes once the Supervisor closes the case")
    }

    func testNoTabWhileNoSOSIsActive() async {
        let demo = DemoDataProvider(scenario: .duringMeal)
        let model = DoorSOSViewModel(sos: demo.makeRepositories().sos, mess: DemoSeed.mess.id, role: .doorScanner)
        await model.load()
        XCTAssertNil(model.current)
        XCTAssertNil(model.stage)
    }

    func testTheDoorClaimsAndChecksButNeverCloses() async {
        let sos = FakeSOS([sampleCase()])
        let model = DoorSOSViewModel(sos: sos, mess: DemoSeed.mess.id, role: .doorScanner)
        await model.load()
        XCTAssertEqual(model.stage, .notTaken)
        await model.claim()
        XCTAssertEqual(model.stage, .claimedByYou)
        XCTAssertTrue(model.isClaimedByYou)
        let saved = await model.markChecked()
        XCTAssertTrue(saved)
        XCTAssertEqual(model.stage, .checkedByYou(at: DemoSeed.duringMealNow))
        XCTAssertNotNil(model.current, "A check does not close the case")
        let closes = await sos.closeCalls
        XCTAssertEqual(closes, 0)
    }

    func testAFailedClaimSaysSoAndChangesNothing() async {
        let sos = FakeSOS([sampleCase()])
        await sos.setFailNext()
        let model = DoorSOSViewModel(sos: sos, mess: DemoSeed.mess.id, role: .doorScanner)
        await model.load()
        await model.claim()
        XCTAssertTrue(model.didFail)
        XCTAssertEqual(model.stage, .notTaken)
    }

    func testTheBackendRefusesADoorClose() async {
        let demo = DemoDataProvider(scenario: .duringMeal)
        do {
            _ = try await demo.close(SOSCaseID("any"), by: .doorScanner)
            XCTFail("The door must not close a case")
        } catch {
            guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    // MARK: Problems and Alerts

    func testAReportIsKeptAsWaiting() async {
        let demo = DemoDataProvider(scenario: .duringMeal)
        let log = DoorProblemLog(mealState: demo.makeRepositories().mealState, mess: DemoSeed.mess.id, clock: demo.clock)
        let sent = await log.report(.crowd)
        XCTAssertTrue(sent)
        XCTAssertEqual(log.problems.map(\.kind), [.crowd])
        XCTAssertEqual(log.problems.first?.sentAt, DemoSeed.duringMealNow)
    }

    func testAnOfflineReportIsRefusedNotSent() async {
        let demo = DemoDataProvider(scenario: .offline)
        let log = DoorProblemLog(mealState: demo.makeRepositories().mealState, mess: DemoSeed.mess.id, clock: demo.clock)
        let sent = await log.report(.scanner)
        XCTAssertFalse(sent)
        XCTAssertTrue(log.problems.isEmpty)
    }

    func testAlertsComeOnlyFromTheMealState() async throws {
        let demo = DemoDataProvider(scenario: .storyStart, clock: TestClock())
        let model = DoorHomeViewModel(session: session, repositories: demo.makeRepositories(), clock: demo.clock)
        await model.load()
        XCTAssertTrue(DoorAlert.alerts(for: model.state.value, supervisorName: "Ravi").isEmpty, "Nothing to say before the meal")

        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        await model.load()
        XCTAssertEqual(DoorAlert.alerts(for: model.state.value, supervisorName: "Ravi").map(\.kind), [.mealStarted])

        _ = try await demo.closeMeal(lunch.id, by: .supervisor)
        await model.load()
        XCTAssertEqual(DoorAlert.alerts(for: model.state.value, supervisorName: "Ravi").map(\.kind), [.mealClosed, .mealStarted])
    }

    func testOnlyTheRecordedOutcomeCountsAsSuccess() {
        let student = DemoSeed.sampleStudent
        let others: [DoorScanOutcome] = [
            .alreadyScanned(student: student, firstAt: DemoSeed.duringMealNow, count: 1), .notRecognised,
            .wrongMeal(servingNow: .lunch), .offline(lastUpdate: nil), .mealEnded(closedAt: nil, finalEntries: .unavailable),
        ]
        XCTAssertTrue(others.allSatisfy { !$0.isRecorded })
        XCTAssertTrue(DoorScanOutcome.recorded(student: student, count: 1, withoutVoting: false).isRecorded)
    }
}
#endif
