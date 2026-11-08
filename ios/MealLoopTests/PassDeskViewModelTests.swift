#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The Pass Desk through its view models, on the prototype backend with a clock the test owns.
@MainActor
final class PassDeskViewModelTests: XCTestCase {
    private let lunch = DemoSeed.lunch.id

    private struct World {
        let demo: DemoDataProvider
        let clock: DemoClock
        var repositories: Repositories { demo.makeRepositories() }
    }

    private func world(_ scenario: DemoScenario = .duringMeal) -> World {
        let clock = DemoClock(DemoSeed.duringMealNow)
        return World(demo: DemoDataProvider(scenario: scenario, clock: clock), clock: clock)
    }

    private func staff(_ role: Role = .passDesk) -> StaffSession {
        StaffSession(role: role, mess: DemoSeed.mess, staffInitials: DemoSeed.staffInitials(for: role),
                     supervisorName: DemoSeed.supervisorName)
    }

    private func home(_ world: World) async -> PassDeskHomeViewModel {
        let model = PassDeskHomeViewModel(session: staff(), repositories: world.repositories, clock: world.clock)
        await model.load()
        return model
    }

    private func checkDigits(_ world: World) -> PassDeskCheckDigitsModel {
        PassDeskCheckDigitsModel(use: world.repositories.passUse, live: world.repositories.livePassCodes, meal: lunch)
    }

    private func typed(_ digits: String, _ model: PassDeskCheckDigitsModel) async {
        for character in digits {
            await model.type(character.wholeNumberValue ?? 0)
        }
    }

    /// The student's hold of "Use pass" on their own phone: the only way an entry is recorded (owner ruling, Prompt 2B).
    private func studentHolds(_ world: World) async throws -> PassUseState {
        try await world.repositories.passUse.usePass(of: DemoSeed.sampleStudent.id, meal: lunch, key: .make())
    }

    private func recorded(_ world: World) async throws -> Int {
        try await world.demo.specialMealEntries(for: lunch).count
    }

    // MARK: Home follows the meal

    func testBeforeTheMealThereIsNoKeypadOrCount() async {
        let model = await home(world(.storyStart))
        XCTAssertEqual(model.state.value?.phase, .beforeMeal(opensAt: DemoSeed.lunch.startsAt))
        XCTAssertEqual(model.state.value?.count.recorded, .unavailable, "Missing, never zero")
    }

    func testDuringTheMealTheCountIsTheSpecialCount() async {
        let model = await home(world())
        XCTAssertEqual(model.state.value?.phase, .duringMeal)
        XCTAssertEqual(model.state.value?.count.recorded.value, DemoSeed.specialMealsSoFar)
        XCTAssertEqual(model.state.value?.count.passes, DemoSeed.specialPassesTotal)
    }

    func testAfterTheMealShowsTheFinalCountAndWaitingRequests() async {
        let model = await home(world(.afterMeal))
        XCTAssertEqual(model.state.value?.phase, .afterMeal(closedAt: DemoSeed.closedAt))
        XCTAssertEqual(model.state.value?.count.recorded.value, DemoSeed.specialMealsFinal)
        XCTAssertEqual(model.state.value?.waitingRequests, 1)
    }

    func testOfflineKeepsNothingItNeverHad() async {
        let model = await home(world(.offline))
        guard case .offline(let value, let savedAt) = model.state else { return XCTFail("\(model.state)") }
        XCTAssertNil(value)
        XCTAssertEqual(savedAt, DemoSeed.offlineSavedAt)
    }

    // MARK: Home shows the live code; the desk records nothing (owner ruling, Prompt 2B)
    // These replace the earlier keypad, check sheet and "Matches · record entry" tests, whose behaviour the ruling removed.

    func testHomeShowsTheLiveCodeDuringTheMealAndNoneOutsideIt() async {
        let during = await home(world())
        XCTAssertNotNil(during.code.current, "The code and colour show during the meal")
        XCTAssertFalse(during.code.isUnavailable)
        let before = await home(world(.storyStart))
        XCTAssertNil(before.code.current, "No code before the meal")
        let after = await home(world(.afterMeal))
        XCTAssertNil(after.code.current, "No code after the meal")
    }

    func testHomeHasNoKeypadDigitBoxesOrRecordButton() throws {
        let source = try String(contentsOf: URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("../MealLoop/Features/PassDesk/PassDeskHomeView.swift").standardizedFileURL, encoding: .utf8)
        for banned in ["KeyPad(", "DigitBoxes", "Matches", "Doesn't match", "Record entry", "recordPassEntry", "Camera"] {
            XCTAssertFalse(source.contains(banned), "Home contains \(banned)")
        }
        let labels = Mirror(reflecting: PassDeskHomeViewModel(session: staff(), repositories: world().repositories,
                                                              clock: world().clock)).children.compactMap(\.label)
        XCTAssertFalse(labels.contains { $0.contains("flow") }, "No check-and-record flow on Home")
    }

    func testTheDeskCodeIsThePhonesCodeAndChangesAtTheBoundary() async throws {
        let world = world()
        let model = await home(world)
        let first = try XCTUnwrap(model.code.current)
        let phone = try await world.repositories.livePassCodes.currentPassCode(
            for: DemoSeed.sampleStudent.id, meal: lunch, at: await world.repositories.livePassCodes.passCodeInstant())
        XCTAssertEqual(first.live.code, phone.live.code)
        XCTAssertEqual(first.live.colourName, phone.live.colourName)
        world.clock.set(first.live.changesAt)
        while (model.code.secondsLeft ?? 0) > 1 { await model.code.tick() }
        await model.code.tick()
        XCTAssertNotEqual(model.code.current?.live.code, first.live.code, "An expired window is never shown as current")
    }

    func testLosingTheConnectionHidesTheCode() async throws {
        let world = world()
        let model = await home(world)
        XCTAssertNotNil(model.code.current)
        await world.demo.setScenario(.offline)
        await model.load()
        XCTAssertNil(model.code.current, "Offline: the code is never shown as valid")
    }

    func testTheDeskRecordsNothingAndTheStudentsHoldRecordsOne() async throws {
        let world = world()
        let model = await home(world)
        for _ in 0..<12 { await model.code.tick() }
        let none = try await recorded(world)
        XCTAssertEqual(none, 0, "Showing the code records nothing")
        _ = try await studentHolds(world)
        let one = try await recorded(world)
        XCTAssertEqual(one, 1)
        await model.load()
        XCTAssertEqual(model.state.value?.count.recorded.value, DemoSeed.specialMealsSoFar + 1)
    }

    // MARK: Check last 4 digits: a lookup that never records

    func testCheckingDigitsSaysValidAndRecordsNothing() async throws {
        let world = world()
        let model = checkDigits(world)
        await typed("0238", model)
        XCTAssertEqual(model.statusLine, "Valid for lunch · not used yet")
        let count = try await recorded(world)
        XCTAssertEqual(count, 0)
    }

    func testCheckingDigitsAfterTheHoldSaysInUseThenUsed() async throws {
        let world = world()
        guard case .inUse(let usedAt, _, _) = try await studentHolds(world) else { return XCTFail("In use") }
        let model = checkDigits(world)
        await typed("0238", model)
        XCTAssertEqual(model.statusLine, "In use · valid for \(Int(PassUsePolicy.validity)) s")
        world.clock.set(usedAt.addingTimeInterval(PassUsePolicy.validity))
        model.deleteLast()
        await model.type(8)
        XCTAssertEqual(model.statusLine, "Used")
        let count = try await recorded(world)
        XCTAssertEqual(count, 1, "The check added nothing")
    }

    func testCheckingDigitsNotFoundNoPassAndWrongMeal() async {
        let world = world()
        let nobody = checkDigits(world)
        await typed("9999", nobody)
        XCTAssertEqual(nobody.statusLine, "Not found")
        let meera = checkDigits(world)
        await typed("0412", meera)
        XCTAssertEqual(meera.statusLine, "No special pass")
        let kiran = checkDigits(world)
        await typed("0377", kiran)
        XCTAssertEqual(kiran.statusLine, "Wrong meal")
    }

    func testCheckingDigitsOfflineNeverShowsSuccess() async {
        let world = world()
        await world.demo.setScenario(.offline)
        let model = checkDigits(world)
        await typed("0238", model)
        XCTAssertEqual(model.statusLine, "Can't check right now")
    }

    func testAnOfflineHoldIsNeverRecorded() async throws {
        let world = world()
        await world.demo.setScenario(.offline)
        do {
            _ = try await studentHolds(world)
            XCTFail("Offline")
        } catch RepositoryError.offline {}
    }

    // MARK: Reissue

    func testApprovedIsNeverDone() async {
        let world = world()
        let model = PassDeskRequestsModel(passes: world.repositories.specialPasses, mess: DemoSeed.mess.id)
        await model.load()
        let requests = model.state.value ?? []
        XCTAssertEqual(requests.map(\.status), [.waiting, .approved, .done, .rejected])
        XCTAssertNotEqual(PassDeskCopy.status(.approved), PassDeskCopy.status(.done))
        let meera = requests.first { $0.holder.name == "Meera" }
        XCTAssertEqual(meera?.status, .approved, "The desk shows the status as it is and moves nothing on")
    }

    func testANewRequestStartsWaitingAndNothingApprovesIt() async throws {
        let world = world()
        let form = PassDeskRequestForm(session: staff(), passes: world.repositories.specialPasses, meal: lunch)
        await form.prefill("0412")
        XCTAssertEqual(form.holder?.name, "Meera")
        XCTAssertFalse(form.canSend, "A reason is needed")
        form.reason = .phoneLost
        let didSend = await form.send()
        XCTAssertTrue(didSend)
        let requests = try await world.demo.reissueRequests(for: DemoSeed.mess.id)
        XCTAssertEqual(requests.first?.status, .waiting)
        XCTAssertEqual(requests.first?.holder.name, "Meera")
        let model = await home(world)
        XCTAssertEqual(model.state.value?.waitingRequests, 2)
    }

    func testARequestForAStudentNobodyHoldsIsRefused() async {
        let world = world()
        let form = PassDeskRequestForm(session: staff(), passes: world.repositories.specialPasses, meal: lunch)
        await form.prefill("0999")
        XCTAssertNil(form.holder)
        XCTAssertNotNil(form.problem)
    }

    func testAnOfflineRequestIsNotSent() async throws {
        let world = world()
        let form = PassDeskRequestForm(session: staff(), passes: world.repositories.specialPasses, meal: lunch)
        await form.prefill("0412")
        form.reason = .other
        await world.demo.setScenario(.offline)
        let didSend = await form.send()
        XCTAssertFalse(didSend)
        XCTAssertNotNil(form.problem)
        await world.demo.setScenario(.duringMeal)
        let requests = try await world.demo.reissueRequests(for: DemoSeed.mess.id)
        XCTAssertEqual(requests.count, DemoSeed.sampleReissues.count)
    }

    // MARK: Problems and food short

    func testFoodShortReachesTheKitchenThroughTheRepository() async throws {
        let world = world()
        let log = PassDeskProblemLog(session: staff(), repositories: world.repositories, clock: world.clock)
        let dishes = await log.dishes(for: lunch)
        XCTAssertEqual(dishes, DemoSeed.lunchMenu.map(\.name), "The chips come from the day's menu")
        let didSend = await log.reportFoodShort(DemoSeed.shortageDish, meal: lunch)
        XCTAssertTrue(didSend)
        let shortages = try await world.demo.shortages(for: lunch)
        XCTAssertEqual(shortages.map(\.dishName), [DemoSeed.shortageDish])
        XCTAssertEqual(shortages.first?.reportedBy, .passDesk)
        XCTAssertEqual(log.problems.count, 1)
    }

    func testAnOfflineProblemIsNotClaimedAsSent() async {
        let world = world(.offline)
        let log = PassDeskProblemLog(session: staff(), repositories: world.repositories, clock: world.clock)
        let didSend = await log.report(.crowd)
        XCTAssertFalse(didSend)
        XCTAssertTrue(log.problems.isEmpty)
    }

    // MARK: Alerts

    func testAlertsAreAtMostThreeNewestFirstAndOnlyFromRealFacts() async {
        let model = await home(world())
        let alerts = PassDeskAlert.alerts(for: model.state.value)
        XCTAssertLessThanOrEqual(alerts.count, 3)
        XCTAssertEqual(alerts.map(\.at), alerts.map(\.at).sorted(by: >))
        XCTAssertTrue(alerts.contains { $0.kind == .mealStarted })
        XCTAssertTrue(alerts.contains { $0.kind == .newPassApproved("••0412") }, "Only the approved request")
        XCTAssertFalse(alerts.contains { $0.kind == .shortageSeen }, "Nothing was seen, so nothing says so")
    }

    func testBeforeTheMealThereIsNoMealStartedAlert() async {
        let model = await home(world(.storyStart))
        XCTAssertFalse(PassDeskAlert.alerts(for: model.state.value).contains { $0.kind == .mealStarted })
    }

    // MARK: SOS

    func testTheDeskCanCheckButNotCloseACase() async throws {
        let world = world()
        _ = try await world.demo.raise(SOSReport(messID: DemoSeed.mess.id, title: DemoSeed.sosTitle, place: DemoSeed.sosPlace,
                                                 idempotencyKey: IdempotencyKey("sos")))
        let sos = DoorSOSViewModel(sos: world.repositories.sos, mess: DemoSeed.mess.id, role: .passDesk)
        await sos.load()
        XCTAssertEqual(sos.stage, .notTaken)
        await sos.claim()
        XCTAssertEqual(sos.stage, .claimedByYou)
        let didCheck = await sos.markChecked()
        XCTAssertTrue(didCheck)
        let open = try await world.demo.activeCases(for: DemoSeed.mess.id)
        XCTAssertEqual(open.count, 1, "Marking checked does not close the case")
        guard case .checked(let text, _) = PassDeskSOSText.status(try XCTUnwrap(sos.stage), timeZone: DemoSeed.mess.timeZone) else {
            return XCTFail("Expected checked")
        }
        XCTAssertEqual(text, "Checked by the desk")
        do {
            _ = try await world.demo.close(try XCTUnwrap(sos.current?.id), by: .passDesk)
            XCTFail("Only the Supervisor closes")
        } catch {
            guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    // MARK: Access and visibility

    func testNoOtherSessionCanReachTheRole() {
        for account in DemoSeed.accounts {
            let staffSession = account.role.isMessStaff ? staff(account.role) : nil
            let session = Session(account: account, staff: staffSession)
            XCTAssertEqual(PassDeskAccess.canOpen(session), account.role == .passDesk, "\(account.role)")
            XCTAssertEqual(RoleRoot.destination(for: account.role) == .passDesk, account.role == .passDesk, "\(account.role)")
        }
        let account = DemoSeed.accounts.first { $0.role == .supervisor }
        if let account {
            XCTAssertFalse(PassDeskAccess.canOpen(Session(account: account, staff: staff(.passDesk))), "The account decides")
        }
    }

    func testTheDeskHasNoRecordOperationOnItsScreens() throws {
        let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("../MealLoop/Features/PassDesk").standardizedFileURL
        let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        for file in files where file.pathExtension == "swift" {
            let source = try String(contentsOf: file, encoding: .utf8)
            XCTAssertFalse(source.contains("recordPassEntry"), "\(file.lastPathComponent) records")
        }
    }

    func testAStudentsHoldIsVisibleToOtherRolesThroughTheRepository() async throws {
        let world = world()
        _ = try await studentHolds(world)
        // The read takes no role: what the Supervisor's or Admin's screens would read.
        let entries = try await world.repositories.specialPasses.specialMealEntries(for: lunch)
        XCTAssertEqual(entries.map(\.student), [DemoSeed.sampleStudent])
        XCTAssertEqual(entries.first?.recordedBy, .student)
        let count = try await world.repositories.specialPasses.specialMealCount(for: lunch)
        XCTAssertEqual(count.recorded.value, DemoSeed.specialMealsSoFar + 1)
    }

    func testRemoteDataSaysItIsNotAvailable() async {
        let api = AppEnvironment.makeAPI()
        let model = PassDeskHomeViewModel(session: staff(), repositories: api.repositories, clock: api.clock)
        await model.load()
        guard case .failed(let failure) = model.state else { return XCTFail("\(model.state)") }
        XCTAssertTrue(failure.isNotImplemented)
    }
}
#endif
