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

    private func typed(_ digits: String, _ flow: PassDeskCheckFlow) async {
        for character in digits {
            await flow.type(character.wholeNumberValue ?? 0)
        }
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

    // MARK: Check and record

    func testTheFourthDigitOpensTheCheckAndRecordsNothing() async throws {
        let world = world()
        let flow = await home(world).flow
        await typed("023", flow)
        XCTAssertNil(flow.compare, "Nothing is asked before the fourth digit")
        await typed("8", flow)
        XCTAssertEqual(flow.compare?.holder.student, DemoSeed.sampleStudent)
        XCTAssertEqual(flow.compare?.live.code, DemoSeed.samplePassCodes[0].code)
        XCTAssertEqual(flow.compare?.secondsLeft, Int(DemoSeed.passCodeWindow))
        let count = try await recorded(world)
        XCTAssertEqual(count, 0)
    }

    func testRecordingHappensOnlyOnMatches() async throws {
        let world = world()
        let flow = await home(world).flow
        await typed("0238", flow)
        await flow.matches()
        XCTAssertEqual(flow.outcome, .verified(SpecialPassHolder(student: DemoSeed.sampleStudent, name: "Aarav"),
                                               count: DemoSeed.specialMealsSoFar + 1, passes: DemoSeed.specialPassesTotal))
        XCTAssertNil(flow.compare)
        let count = try await recorded(world)
        XCTAssertEqual(count, 1)
    }

    func testDoesntMatchShowsWhatItShouldAndRecordsNothing() async throws {
        let world = world()
        let flow = await home(world).flow
        await typed("0238", flow)
        let live = try XCTUnwrap(flow.compare?.live)
        flow.doesNotMatch()
        XCTAssertEqual(flow.outcome, .mismatch(live))
        let count = try await recorded(world)
        XCTAssertEqual(count, 0)
        await flow.checkAgain()
        XCTAssertNil(flow.outcome)
        XCTAssertNotNil(flow.compare, "Check again opens the sheet afresh")
    }

    func testClosingTheSheetRecordsNothing() async throws {
        let world = world()
        let flow = await home(world).flow
        await typed("0238", flow)
        flow.reset()
        XCTAssertNil(flow.compare)
        XCTAssertTrue(flow.entry.digits.isEmpty)
        let count = try await recorded(world)
        XCTAssertEqual(count, 0)
    }

    func testAStudentNobodyHoldsIsSaidOnHome() async {
        let flow = await home(world()).flow
        await typed("0999", flow)
        XCTAssertEqual(flow.notFoundDigits, "0999")
        XCTAssertNil(flow.outcome)
        await flow.type(1)
        XCTAssertNil(flow.notFoundDigits, "The next key starts again")
        XCTAssertEqual(flow.entry.text, "1")
    }

    func testNoPassAndWrongMealRecordNothing() async throws {
        let world = world()
        let flow = await home(world).flow
        await typed("0412", flow)
        guard case .noPass? = flow.outcome else { return XCTFail("\(String(describing: flow.outcome))") }
        flow.reset()
        await typed("0377", flow)
        guard case .wrongMeal(_, let slot)? = flow.outcome else { return XCTFail("\(String(describing: flow.outcome))") }
        XCTAssertEqual(slot, .dinner)
        let count = try await recorded(world)
        XCTAssertEqual(count, 0)
    }

    func testASecondCheckIsAlreadyRecordedAndTheCountStays() async throws {
        let world = world()
        let flow = await home(world).flow
        await typed("0238", flow)
        await flow.matches()
        flow.reset()
        await typed("0238", flow)
        guard case .alreadyRecorded(_, _, let count)? = flow.outcome else {
            return XCTFail("\(String(describing: flow.outcome))")
        }
        XCTAssertEqual(count, DemoSeed.specialMealsSoFar + 1)
        let entries = try await recorded(world)
        XCTAssertEqual(entries, 1)
    }

    // MARK: The live code

    func testTheCodeChangesWhenTheWindowRunsOut() async throws {
        let world = world()
        let flow = await home(world).flow
        await typed("0238", flow)
        let first = try XCTUnwrap(flow.compare?.live.code)
        let changesAt = try XCTUnwrap(flow.compare?.live.changesAt)
        for _ in 0..<Int(DemoSeed.passCodeWindow) - 1 {
            await flow.tick()
        }
        XCTAssertEqual(flow.compare?.live.code, first, "The code holds for its whole window")
        // The code follows the clock (P-PASS-9 a): it changes when time crosses the window, not because of a tick.
        world.clock.set(changesAt)
        await flow.tick()
        XCTAssertNotEqual(flow.compare?.live.code, first)
        XCTAssertEqual(flow.compare?.justChanged, true)
        XCTAssertEqual(flow.compare?.secondsLeft, Int(DemoSeed.passCodeWindow))
        await flow.tick()
        await flow.tick()
        XCTAssertEqual(flow.compare?.justChanged, false, "The highlight is brief")
    }

    func testAnExpiredWindowCannotBeRecorded() async throws {
        let world = world()
        let flow = await home(world).flow
        await typed("0238", flow)
        let changesAt = try XCTUnwrap(flow.compare?.live.changesAt)
        world.clock.set(changesAt)
        await flow.matches()
        XCTAssertEqual(flow.compare?.isExpired, true)
        XCTAssertNil(flow.outcome)
        let count = try await recorded(world)
        XCTAssertEqual(count, 0)
        await flow.matches()
        let again = try await recorded(world)
        XCTAssertEqual(again, 0, "Expired stays expired until Check again")
    }

    func testLosingTheConnectionMidWindowExpiresTheCode() async throws {
        let world = world()
        let flow = await home(world).flow
        await typed("0238", flow)
        await world.demo.setScenario(.offline)
        for _ in 0..<Int(DemoSeed.passCodeWindow) {
            await flow.tick()
        }
        XCTAssertEqual(flow.compare?.isExpired, true)
    }

    // MARK: Offline and the meal ending

    func testAnOfflineLookupIsNeverSuccess() async throws {
        let world = world()
        let flow = await home(world).flow
        await world.demo.setScenario(.offline)
        await typed("0238", flow)
        XCTAssertEqual(flow.outcome, .cantCheck(lastUpdate: DemoSeed.offlineSavedAt))
    }

    func testAnOfflineRecordIsNeverSuccessAndNeverQueued() async throws {
        let world = world()
        let flow = await home(world).flow
        await typed("0238", flow)
        await world.demo.setScenario(.offline)
        await flow.matches()
        XCTAssertEqual(flow.outcome, .cantCheck(lastUpdate: DemoSeed.offlineSavedAt))
        await world.demo.setScenario(.duringMeal)
        let count = try await recorded(world)
        XCTAssertEqual(count, 0)
    }

    func testTheMealEndingWhileCheckingRecordsNothing() async throws {
        let world = world()
        let flow = await home(world).flow
        await typed("0238", flow)
        _ = try await world.demo.closeMeal(lunch, by: .supervisor)
        await flow.matches()
        guard case .mealEnded(let closedAt, _, _)? = flow.outcome else {
            return XCTFail("\(String(describing: flow.outcome))")
        }
        XCTAssertNotNil(closedAt)
        let count = try await recorded(world)
        XCTAssertEqual(count, 0)
    }

    // MARK: Look up

    func testALookupNeverRecordsAndSaysSo() async throws {
        let world = world()
        let model = PassDeskLookUpModel(passes: world.repositories.specialPasses, meal: lunch)
        for digit in [0, 2, 3, 8] {
            await model.type(digit)
        }
        guard case .loaded(.valid) = model.state else { return XCTFail("\(model.state)") }
        let count = try await recorded(world)
        XCTAssertEqual(count, 0)
        let reading = try await world.demo.specialMealCount(for: lunch)
        XCTAssertEqual(reading.recorded.value, DemoSeed.specialMealsSoFar)
    }

    func testALookupShowsUsedOnceRecorded() async throws {
        let world = world()
        let flow = await home(world).flow
        await typed("0238", flow)
        await flow.matches()
        let model = PassDeskLookUpModel(passes: world.repositories.specialPasses, meal: lunch)
        for digit in [0, 2, 3, 8] {
            await model.type(digit)
        }
        guard case .loaded(.used) = model.state else { return XCTFail("\(model.state)") }
    }

    func testALookupOfflineClaimsNothing() async {
        let world = world(.offline)
        let model = PassDeskLookUpModel(passes: world.repositories.specialPasses, meal: lunch)
        for digit in [0, 2, 3, 8] {
            await model.type(digit)
        }
        guard case .offline(nil, _) = model.state else { return XCTFail("\(model.state)") }
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

    func testAnotherRoleCannotRecordThroughTheFlow() async throws {
        let world = world()
        let flow = PassDeskCheckFlow(session: staff(.supervisor), passes: world.repositories.specialPasses,
                                     live: world.repositories.livePassCodes, clock: world.clock)
        flow.meal = DemoSeed.lunch
        await typed("0238", flow)
        await flow.matches()
        XCTAssertNotNil(flow.actionError)
        let count = try await recorded(world)
        XCTAssertEqual(count, 0)
    }

    func testARecordedEntryIsVisibleToOtherRolesThroughTheRepository() async throws {
        let world = world()
        let flow = await home(world).flow
        await typed("0238", flow)
        await flow.matches()
        // The read takes no role: what the Supervisor's or Admin's screens would read.
        let entries = try await world.repositories.specialPasses.specialMealEntries(for: lunch)
        XCTAssertEqual(entries.map(\.student), [DemoSeed.sampleStudent])
        XCTAssertEqual(entries.first?.recordedBy, .passDesk)
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
