#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The Supervisor role through its view models, on the prototype backend with a clock the test owns
/// (supervisor_spec.md; core story: start, door entries, kitchen live count, close, kitchen waste, read-only waste).
@MainActor
final class SupervisorViewModelTests: XCTestCase {
    private let lunch = DemoSeed.lunch.id

    private struct World {
        let demo: DemoDataProvider
        let clock: DemoClock
        var repositories: Repositories { demo.makeRepositories() }
    }

    private func world(_ scenario: DemoScenario = .storyStart) -> World {
        let clock = DemoClock(DemoSeed.storyStartNow)
        return World(demo: DemoDataProvider(scenario: scenario, clock: clock), clock: clock)
    }

    private func staff(_ role: Role = .supervisor) -> StaffSession {
        StaffSession(role: role, mess: DemoSeed.mess, staffInitials: DemoSeed.staffInitials(for: role),
                     supervisorName: DemoSeed.supervisorName)
    }

    private func home(_ world: World, role: Role = .supervisor) -> SupervisorHomeViewModel {
        SupervisorHomeViewModel(session: staff(role), repositories: world.repositories, clock: world.clock)
    }

    private func loadedHome(_ model: SupervisorHomeViewModel, line: UInt = #line) async throws -> SupervisorHomeContent {
        await model.load()
        guard case .loaded(let content) = model.state else {
            XCTFail("Expected loaded, got \(model.state)", line: line)
            throw CancellationError()
        }
        return content
    }

    private func reportRice(_ world: World) async throws -> Shortage {
        try await world.demo.reportShortage(ShortageReport(mealID: lunch, dishName: DemoSeed.shortageDish,
                                                           level: DemoSeed.shortageLevel, note: nil,
                                                           reportedBy: .kitchenStaff, idempotencyKey: IdempotencyKey("rice")))
    }

    private func raiseSOS(_ world: World) async throws -> SOSCase {
        try await world.demo.raise(SOSReport(messID: DemoSeed.mess.id, title: DemoSeed.sosTitle, place: DemoSeed.sosPlace,
                                             idempotencyKey: IdempotencyKey("sos")))
    }

    // MARK: Home by meal state

    func testBeforeTheMealHomeShowsTheForecastAndTheSeededFollowUps() async throws {
        let content = try await loadedHome(home(world()))
        XCTAssertEqual(content.phase, .notStarted(forecast: .ready(diners: DemoSeed.forecastDiners, setAt: DemoSeed.forecastSetAt)))
        // S01: Waste not recorded 1 (Dinner Tue 13), Active shortages 0.
        XCTAssertEqual(content.followUps.wasteNotRecorded.map(\.mealID), [MealID("demo-2024-08-13-dinner")])
        XCTAssertTrue(content.followUps.activeShortages.isEmpty)
    }

    func testStartMovesTheClockToTheSeedStartAndOpensScanningForOtherRoles() async throws {
        let world = world()
        let model = home(world)
        _ = try await loadedHome(model)
        XCTAssertEqual(world.clock.now(), DemoSeed.storyStartNow)

        let started = await model.startMeal()
        XCTAssertTrue(started)
        XCTAssertEqual(world.clock.now(), DemoSeed.lunch.startsAt, "The backend moves the story clock to 12:00 PM")
        guard case .loaded(let content) = model.state,
              case .inService(let entered, let minutes) = content.phase else { return XCTFail("\(model.state)") }
        XCTAssertEqual(minutes, 0)
        XCTAssertEqual(entered.value, 0, "Recorded entries only; nobody has entered yet")

        // The Door Scanner side: scanning is open and an entry records.
        let door = world.repositories
        let status = try await door.mealState.currentMeal(for: DemoSeed.mess.id)
        XCTAssertEqual(status?.state, .inService)
        let meera = DemoSeed.sampleStudents[1]
        let resolved = try await door.entries.resolveEntry(.lastFour(meera.entryCode.lastFour), for: lunch)
        XCTAssertEqual(resolved, .student(meera.ref))
        let result = try await door.entries.recordEntry(EntryRequest(mealID: lunch, student: meera.ref, method: .typedLastFour,
                                                                    idempotencyKey: IdempotencyKey("door-1")))
        guard case .recorded(_, let count) = result else { return XCTFail("\(result)") }
        XCTAssertEqual(count, 1)

        // The Supervisor's live count follows the door.
        let after = try await loadedHome(model)
        guard case .inService(let live, _) = after.phase else { return XCTFail("\(after.phase)") }
        XCTAssertEqual(live.value, 1)
    }

    func testCloseMovesTheClockToTheSeedEndAndShowsTheFinalEntries() async throws {
        let world = world()
        let model = home(world)
        _ = try await loadedHome(model)
        await model.startMeal()
        let closed = await model.closeMeal()
        XCTAssertTrue(closed)
        XCTAssertEqual(world.clock.now(), DemoSeed.lunch.endsAt, "The backend moves the story clock to 2:00 PM")
        guard case .loaded(let content) = model.state else { return XCTFail("\(model.state)") }
        XCTAssertEqual(content.phase, .closed(finalEntries: .available(0, asOf: DemoSeed.closedAt), closedAt: DemoSeed.closedAt))

        // Scanning is closed for the door.
        do {
            _ = try await world.repositories.entries.recordEntry(EntryRequest(mealID: lunch, student: DemoSeed.sampleStudent,
                                                                              method: .qrScan, idempotencyKey: IdempotencyKey("late")))
            XCTFail("Expected scanning to be closed")
        } catch {
            guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testAMissingFinalCountIsUnavailableNeverZero() async throws {
        let world = world(.duringMeal)
        let model = home(world)
        _ = try await loadedHome(model)
        await model.closeMeal()
        let content = try await loadedHome(model)
        guard case .closed(let finalEntries, _) = content.phase else { return XCTFail("\(content.phase)") }
        XCTAssertEqual(finalEntries.value, DemoSeed.finalEntries)
        // Mon 12 · Dinner has no final count in the record: it stays unavailable instead of 0 (S19f).
        let monday = try await world.repositories.mealState.mealHistory(for: DemoSeed.mess.id).last
        XCTAssertEqual(monday?.finalEntries, .unavailable)
    }

    func testBreakfastPastMealShowsUnavailableLikeFinalCountNeverZero() async throws {
        let world = world(.duringMeal)
        let breakfast = DemoSeed.breakfast.id
        let model = SupervisorPastMealViewModel(mealID: breakfast, session: staff(), repositories: world.repositories)
        await model.load()
        let record = try XCTUnwrap(model.state.value)
        let finalCount = try await world.repositories.entries.finalCount(for: breakfast)
        XCTAssertEqual(record.finalEntries, finalCount)
        XCTAssertEqual(record.finalEntries, .unavailable)
        XCTAssertNil(record.finalEntries.value, "Shown as \"Unavailable\", never 0")

        let history = SupervisorHistoryViewModel(session: staff(), repositories: world.repositories)
        await history.load()
        XCTAssertEqual(history.record(breakfast)?.finalEntries, .unavailable)
    }

    func testClosingLeavesShortagesUnresolvedAndWasteIncomplete() async throws {
        let world = world()
        let model = home(world)
        _ = try await loadedHome(model)
        await model.startMeal()
        let rice = try await reportRice(world)
        await model.closeMeal()

        let shortages = try await world.repositories.shortages.shortages(for: lunch)
        XCTAssertEqual(shortages.first { $0.id == rice.id }?.status, .active)
        let waste = try await world.repositories.wasteReports.summary(for: lunch)
        XCTAssertEqual(waste.status, .notStarted)
        XCTAssertLessThan(waste.completedFieldCount, waste.totalFieldCount)

        // S06: Waste not recorded 2 (Lunch Wed 14, Dinner Tue 13), Active shortages 1.
        let content = try await loadedHome(model)
        XCTAssertEqual(content.followUps.activeShortages.map(\.id), [rice.id])
        XCTAssertEqual(content.followUps.wasteNotRecorded.map(\.mealID), [lunch, MealID("demo-2024-08-13-dinner")])
    }

    func testOneTaskHasOneCountOnHomeAlertsAndMe() async throws {
        let world = world()
        let homeModel = home(world)
        _ = try await loadedHome(homeModel)
        await homeModel.startMeal()
        _ = try await reportRice(world)
        await homeModel.closeMeal()

        let homeCounts = try await loadedHome(homeModel).followUps
        let alerts = SupervisorAlertsViewModel(session: staff(), repositories: world.repositories, clock: world.clock)
        await alerts.load()
        let me = SupervisorMeViewModel(session: staff(), repositories: world.repositories)
        await me.load()
        XCTAssertEqual(alerts.state.value?.followUps, homeCounts)
        XCTAssertEqual(me.state.value, homeCounts)
    }

    func testANonSupervisorCannotStartOrCloseTheMeal() async throws {
        let world = world()
        let model = home(world, role: .doorScanner)
        _ = try await loadedHome(model)
        let started = await model.startMeal()
        XCTAssertFalse(started)
        XCTAssertNotNil(model.actionError)
        XCTAssertEqual(world.clock.now(), DemoSeed.storyStartNow, "Nothing moved")
        let status = try await world.repositories.mealState.currentMeal(for: DemoSeed.mess.id)
        XCTAssertEqual(status?.state, .notStarted)
    }

    func testClosingTwiceIsRefusedAndSaysWhy() async throws {
        let model = home(world())
        _ = try await loadedHome(model)
        await model.startMeal()
        let closed = await model.closeMeal()
        XCTAssertTrue(closed)
        let again = await model.closeMeal()
        XCTAssertFalse(again)
        XCTAssertEqual(model.actionError, "The meal is not in service.")
    }

    func testOfflineHomeClaimsNothing() async {
        let model = home(world(.offline))
        await model.load()
        guard case .offline(nil, let savedAt) = model.state else { return XCTFail("\(model.state)") }
        XCTAssertEqual(savedAt, DemoSeed.offlineSavedAt)
        let started = await model.startMeal()
        XCTAssertFalse(started)
    }

    // MARK: Other roles see the meal state through their own repositories

    func testKitchenSeesTheMealStateTheSupervisorSets() async throws {
        let world = world()
        let kitchen = KitchenHomeViewModel(session: staff(.kitchenStaff), repositories: world.repositories, clock: world.clock)
        await kitchen.load()
        guard case .loaded(let before) = kitchen.state, case .beforeMeal = before.phase else { return XCTFail("\(kitchen.state)") }

        let supervisor = home(world)
        _ = try await loadedHome(supervisor)
        await supervisor.startMeal()
        await kitchen.load()
        guard case .loaded(let during) = kitchen.state,
              case .duringMeal(let entered, _, _) = during.phase else { return XCTFail("\(kitchen.state)") }
        XCTAssertEqual(entered.value, 0)

        await supervisor.closeMeal()
        await kitchen.load()
        guard case .loaded(let after) = kitchen.state,
              case .afterMeal(_, let closedAt, let waste) = after.phase else { return XCTFail("\(kitchen.state)") }
        XCTAssertEqual(closedAt, DemoSeed.closedAt)
        XCTAssertEqual(waste.status, .notStarted, "Closing completes no waste report")
    }

    // MARK: Shortages

    func testMarkResolvedLeavesTheActiveListAndShowsInHistory() async throws {
        let world = world()
        let homeModel = home(world)
        _ = try await loadedHome(homeModel)
        await homeModel.startMeal()
        let rice = try await reportRice(world)

        let model = SupervisorShortageViewModel(shortageID: rice.id, session: staff(), repositories: world.repositories)
        await model.load()
        XCTAssertEqual(model.state.value?.status, .active)
        let resolved = await model.markResolved()
        XCTAssertTrue(resolved)
        guard case .resolved(let at)? = model.state.value?.status else { return XCTFail("\(model.state)") }
        XCTAssertEqual(at, world.clock.now())

        let followUps = try await loadedHome(homeModel).followUps
        XCTAssertTrue(followUps.activeShortages.isEmpty)

        await homeModel.closeMeal()
        let history = SupervisorHistoryViewModel(session: staff(), repositories: world.repositories)
        await history.load()
        let record = history.record(lunch)
        XCTAssertEqual(record?.shortages.first?.outcome, .resolved(at: at))
        XCTAssertEqual(record.map { SupervisorHistoryText.shortageSummary($0.shortages) }, SupervisorCopy.shortageResolved)
    }

    func testOnlyTheSupervisorResolvesAShortage() async throws {
        let world = world(.duringMealShortageReported)
        let shortage = try await world.repositories.shortages.shortages(for: lunch)[0]
        let kitchen = SupervisorShortageViewModel(shortageID: shortage.id, session: staff(.kitchenStaff),
                                                  repositories: world.repositories)
        await kitchen.load()
        let resolved = await kitchen.markResolved()
        XCTAssertFalse(resolved)
        XCTAssertEqual(kitchen.actionError, "Only the Supervisor resolves a shortage.")
    }

    func testOpeningAReportMarksItSeenSoTheKitchenSaysRaviSawIt() async throws {
        let world = world()
        let homeModel = home(world)
        _ = try await loadedHome(homeModel)
        await homeModel.startMeal()
        let rice = try await reportRice(world)
        guard case .sent = rice.delivery else { return XCTFail("A new report is only sent: \(rice.delivery)") }

        world.clock.set(world.clock.now().addingTimeInterval(120))
        let model = SupervisorShortageViewModel(shortageID: rice.id, session: staff(), repositories: world.repositories)
        await model.load()
        let seenAt = world.clock.now()
        XCTAssertEqual(model.state.value?.delivery, .seen(at: seenAt, by: DemoSeed.supervisorName))

        // The Kitchen reads the same repository the Supervisor wrote to.
        let kitchenView = try await world.repositories.shortages.shortages(for: lunch).first { $0.id == rice.id }
        guard case .seen(_, let by)? = kitchenView?.delivery else { return XCTFail("\(String(describing: kitchenView))") }
        XCTAssertEqual(KitchenCopy.seenBy(by), "Ravi saw it")

        // Opening it again keeps the first sighting.
        world.clock.set(world.clock.now().addingTimeInterval(60))
        await model.load()
        XCTAssertEqual(model.state.value?.delivery, .seen(at: seenAt, by: DemoSeed.supervisorName))
    }

    func testAnotherRoleOpeningAReportDoesNotMarkItSeen() async throws {
        let world = world(.duringMealShortageReported)
        let shortage = try await world.repositories.shortages.shortages(for: lunch)[0]
        guard case .sent = shortage.delivery else { return XCTFail("Seeded report should be only sent: \(shortage.delivery)") }
        let kitchen = SupervisorShortageViewModel(shortageID: shortage.id, session: staff(.kitchenStaff),
                                                  repositories: world.repositories)
        await kitchen.load()
        let stored = try await world.repositories.shortages.shortages(for: lunch)[0]
        guard case .sent = stored.delivery else { return XCTFail("Only the Supervisor marks a report seen: \(stored.delivery)") }
    }

    // MARK: Waste, read only

    func testWasteSaveIsRefusedForTheSupervisor() async throws {
        let world = world(.afterMeal)
        var report = try await world.repositories.wasteReports.report(for: lunch)
        report.leftovers = report.leftovers.map { var row = $0; row.measurement = .noneLeft; return row }
        report.plateWaste = .entered(kilograms: 18)
        for write in [{ try await world.repositories.wasteReports.save(report, by: .supervisor) },
                      { try await world.repositories.wasteReports.saveDraft(report, by: .supervisor) }] {
            do {
                _ = try await write()
                XCTFail("Expected the Supervisor's save to be refused")
            } catch {
                XCTAssertEqual(error as? RepositoryError, .notAllowed(reason: "Only Kitchen Staff record waste."))
            }
        }
        let summary = try await world.repositories.wasteReports.summary(for: lunch)
        XCTAssertEqual(summary.status, .notStarted)
    }

    func testTheSupervisorSeesTheKitchensSavedReportReadOnly() async throws {
        let world = world(.afterMeal)
        var report = try await world.repositories.wasteReports.report(for: lunch)
        report.leftovers = report.leftovers.map { var row = $0; row.measurement = .entered(2); return row }
        report.leftovers[0].measurement = .notMade
        report.plateWaste = .entered(kilograms: 18)

        let model = SupervisorWasteReportViewModel(mealID: lunch, session: staff(), repositories: world.repositories)
        await model.load()
        XCTAssertEqual(model.state.value?.record.waste, .notRecorded)
        XCTAssertNil(model.state.value?.report, "Nothing saved yet: no rows and no zeros")

        let saved = try await world.repositories.wasteReports.save(report, by: .kitchenStaff)
        await model.load()
        guard case .recorded(let at) = saved.status else { return XCTFail("\(saved.status)") }
        XCTAssertEqual(model.state.value?.record.waste, .recorded(at: at))
        XCTAssertEqual(model.state.value?.report, saved)
    }

    func testAMissingWasteReportIsNotRecordedNeverZero() async throws {
        let world = world()
        let model = SupervisorWasteReportViewModel(mealID: MealID("demo-2024-08-13-dinner"), session: staff(),
                                                   repositories: world.repositories)
        await model.load()
        let content = try XCTUnwrap(model.state.value)
        XCTAssertEqual(content.record.waste, .notRecorded)
        XCTAssertNil(content.report)
        XCTAssertEqual(content.record.finalEntries.value, 598)
    }

    func testAnEarlierRecordedReportCarriesItsOwnUnits() async throws {
        let model = SupervisorWasteReportViewModel(mealID: MealID("demo-2024-08-13-lunch"), session: staff(),
                                                   repositories: world().repositories)
        await model.load()
        let report = try XCTUnwrap(model.state.value?.report)
        XCTAssertEqual(report.leftovers.map { SupervisorFormat.unit($0.unit) }, ["kg", "L", "kg", "pieces"])
        XCTAssertEqual(SupervisorFormat.quantity(2.5), "2.5")
        XCTAssertEqual(SupervisorFormat.quantity(4), "4")
    }

    // MARK: SOS

    func testTheSOSTabExistsOnlyWhileACaseIsActive() async throws {
        let world = world(.duringMeal)
        let model = home(world)
        await model.load()
        XCTAssertTrue(model.sosModel.cases.isEmpty)
        _ = try await raiseSOS(world)
        await model.load()
        XCTAssertEqual(model.sosModel.cases.count, 1)
        XCTAssertEqual(model.sosModel.stage, .notTaken)
    }

    func testTheSupervisorClaimsChecksAndClosesACase() async throws {
        let world = world(.duringMeal)
        let sos = SupervisorSOSModel(session: staff(), repositories: world.repositories, clock: world.clock)
        _ = try await raiseSOS(world)
        await sos.load()
        XCTAssertEqual(sos.stage, .notTaken)

        let claimed = await sos.claim()
        XCTAssertTrue(claimed)
        XCTAssertEqual(sos.stage, .claimedByYou)
        XCTAssertTrue(sos.isClaimedByYou)

        let checked = await sos.markChecked()
        XCTAssertTrue(checked)
        XCTAssertEqual(sos.stage, .checked(by: .supervisor, at: world.clock.now()))
        XCTAssertEqual(sos.cases.count, 1, "A check does not close the case")

        let closed = await sos.close()
        XCTAssertTrue(closed)
        XCTAssertTrue(sos.cases.isEmpty, "The tab disappears once the case is closed")
    }

    func testOnlyTheSupervisorClosesACaseOtherStaffOnlyCheck() async throws {
        let world = world(.duringMeal)
        _ = try await raiseSOS(world)
        let door = SupervisorSOSModel(session: staff(.doorScanner), repositories: world.repositories, clock: world.clock)
        await door.load()
        let doorClaimed = await door.claim()
        XCTAssertTrue(doorClaimed)
        let doorChecked = await door.markChecked()
        XCTAssertTrue(doorChecked)
        let doorClosed = await door.close()
        XCTAssertFalse(doorClosed)
        XCTAssertEqual(door.actionError, "Only the Supervisor closes a case.")
        XCTAssertEqual(door.cases.count, 1)

        let supervisor = SupervisorSOSModel(session: staff(), repositories: world.repositories, clock: world.clock)
        await supervisor.load()
        XCTAssertEqual(supervisor.stage, .checked(by: .doorScanner, at: world.clock.now()))
        XCTAssertEqual(SupervisorSOSText.status(supervisor.stage!, timeZone: DemoSeed.mess.timeZone),
                       .checked("Checked by the door", time: MLFormat.time(world.clock.now(), in: DemoSeed.mess.timeZone)))
        let supervisorClosed = await supervisor.close()
        XCTAssertTrue(supervisorClosed)
        XCTAssertTrue(supervisor.cases.isEmpty)
    }

    func testAClaimBySomeoneElseIsNotShownAsYours() async throws {
        let world = world(.duringMeal)
        let raised = try await raiseSOS(world)
        _ = try await world.repositories.sos.claim(raised.id, by: .kitchenStaff)
        let sos = SupervisorSOSModel(session: staff(), repositories: world.repositories, clock: world.clock)
        await sos.load()
        XCTAssertEqual(sos.stage, .claimedBy(.kitchenStaff))
        XCTAssertFalse(sos.isClaimedByYou)
    }

    func testTheIncidentShowsItsTimeAndAge() async throws {
        let world = world(.duringMeal)
        world.clock.set(DemoSeed.sosRaisedAt)
        let raised = try await raiseSOS(world)
        world.clock.set(DemoSeed.time(12, 50))
        let incident = SupervisorSOSText.incident(raised, now: world.clock.now(), timeZone: DemoSeed.mess.timeZone)
        XCTAssertEqual(incident.time, "12:45 PM")
        XCTAssertEqual(incident.age, "5 min ago")
    }

    // MARK: History

    func testHistoryListsClosedMealsAndHandlesEmptyAndOffline() async throws {
        let model = SupervisorHistoryViewModel(session: staff(), repositories: world().repositories)
        await model.load()
        XCTAssertEqual(model.state.value?.records.count, DemoSeed.pastMeals.count)

        let elsewhere = StaffSession(role: .supervisor, mess: Mess(id: MessID("elsewhere"), name: "Other", timeZoneIdentifier: "Asia/Kolkata"),
                                     staffInitials: "RV", supervisorName: "Ravi")
        let empty = SupervisorHistoryViewModel(session: elsewhere, repositories: world().repositories)
        await empty.load()
        XCTAssertEqual(empty.state, .empty)

        let offline = SupervisorHistoryViewModel(session: staff(), repositories: world(.offline).repositories)
        await offline.load()
        guard case .offline(nil, _) = offline.state else { return XCTFail("\(offline.state)") }
    }

    func testHistoryLinesReadAsThePackDrawsThem() {
        let none: [MealRecord.ShortageLine] = []
        XCTAssertEqual(SupervisorHistoryText.shortageSummary(none), "No shortage")
        XCTAssertEqual(SupervisorHistoryText.shortageSummary([.init(dishName: "Steamed Rice", outcome: .active)]), "Shortage active")
        XCTAssertEqual(SupervisorHistoryText.shortageSummary([.init(dishName: nil, outcome: .resolved(at: nil))]), "Shortage resolved")
        XCTAssertEqual(SupervisorHistoryText.wasteSummary(.notRecorded), "Waste not recorded")
        XCTAssertEqual(SupervisorHistoryText.wasteSummary(.recorded(at: nil)), "Waste recorded")
    }

    // MARK: Reaching the role

    func testNonSupervisorSessionsCannotReachTheRole() {
        for account in DemoSeed.accounts where account.role != .supervisor {
            XCTAssertNotEqual(RoleRoot.destination(for: account.role), .supervisor, "\(account.role)")
            let staffSession = account.role.isMessStaff ? staff(account.role) : nil
            XCTAssertFalse(SupervisorRootView.allows(Session(account: account, staff: staffSession)), "\(account.role)")
        }
        let supervisor = DemoSeed.accounts.first { $0.role == .supervisor }!
        XCTAssertTrue(SupervisorRootView.allows(Session(account: supervisor, staff: staff())))
        XCTAssertFalse(SupervisorRootView.allows(Session(account: supervisor, staff: staff(.kitchenStaff))),
                       "A mismatched staff session never opens the Supervisor screens")
        XCTAssertFalse(SupervisorRootView.allows(Session(account: supervisor, staff: nil)))
    }

    func testTheDialogsSayWhatHappensToEveryRole() {
        let start = SupervisorCopy.startDialog(meal: "Lunch", mess: "Main Mess")
        XCTAssertEqual(start.title, "Start this meal?")
        XCTAssertEqual(start.subject, "Lunch · Main Mess")
        XCTAssertEqual(start.detail, "Door scanner and pass desk will open.")
        XCTAssertEqual([start.cancelTitle, start.actionTitle], ["Cancel", "Start meal"])
        let close = SupervisorCopy.closeDialog(meal: "Lunch", mess: "Main Mess")
        XCTAssertEqual(close.detail, "Door scanner and pass desk will stop.")
        XCTAssertEqual([close.cancelTitle, close.actionTitle], ["Cancel", "Close meal"])
    }
}
#endif
