#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

private final class TestClock: StoryClock, @unchecked Sendable {
    private var current = Date(timeIntervalSince1970: 0)
    func now() -> Date { current }
    func set(_ date: Date) { current = date }
}

/// The Kitchen role against the prototype backend, with a clock the tests control.
@MainActor
final class KitchenRoleTests: XCTestCase {
    private let lunch = DemoSeed.lunch
    private let session = StaffSession(role: .kitchenStaff, mess: DemoSeed.mess, staffInitials: DemoSeed.staffInitials(for: .kitchenStaff),
                                       supervisorName: DemoSeed.supervisorName)

    private func story(clock: TestClock = TestClock()) -> DemoDataProvider {
        DemoDataProvider(scenario: .storyStart, clock: clock)
    }

    private func home(_ demo: DemoDataProvider) async -> KitchenHomeViewModel {
        let model = KitchenHomeViewModel(session: session, repositories: demo.makeRepositories(), clock: demo.clock)
        await model.load()
        return model
    }

    private func scan(_ student: StudentRef, _ demo: DemoDataProvider) async throws {
        let repositories = demo.makeRepositories()
        guard case .student(let ref) = try await repositories.entries.resolveEntry(.lastFour(String(student.maskedID.suffix(4))), for: lunch.id) else {
            return XCTFail("Expected the student")
        }
        _ = try await repositories.entries.recordEntry(EntryRequest(mealID: lunch.id, student: ref, method: .typedLastFour, idempotencyKey: .make()))
    }

    private func closed(clock: TestClock = TestClock()) async throws -> (DemoDataProvider, KitchenWasteViewModel) {
        let demo = story(clock: clock)
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        _ = try await demo.closeMeal(lunch.id, by: .supervisor)
        let model = KitchenWasteViewModel(meal: lunch, session: session, repositories: demo.makeRepositories())
        await model.load()
        return (demo, model)
    }

    private func fill(_ model: KitchenWasteViewModel) {
        for row in model.report?.leftovers ?? [] { model.set(.noneLeft, for: row.dishID) }
        model.setPlate(1)
    }

    // MARK: Before and during the meal

    func testBeforeTheMealShowsTheForecastWording() async {
        let content = await home(story()).state.value
        XCTAssertEqual(content?.visibleForecast?.diners, DemoSeed.forecastDiners)
        XCTAssertEqual(KitchenCopy.forecastEyebrow, "Forecasted attendance")
        XCTAssertEqual(KitchenCopy.forecastCaption, "expected diners")
    }

    func testTheLiveCountRisesWithEachEntryFromTheDoor() async throws {
        let demo = story()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        let model = await home(demo)
        func live() -> Int? {
            if case .duringMeal(let entered, _, _)? = model.state.value?.phase { return entered.value }
            return nil
        }
        XCTAssertEqual(live(), 0)
        for (index, sample) in DemoSeed.sampleStudents.prefix(3).enumerated() {
            try await scan(sample.ref, demo)
            await model.load()
            XCTAssertEqual(live(), index + 1)
        }
    }

    func testDuringTheMealTheForecastIsNotShown() async throws {
        let demo = story()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        let content = await home(demo).state.value
        XCTAssertNil(content?.visibleForecast)
        XCTAssertEqual(KitchenCopy.liveCaption, "students entered")
    }

    // MARK: Shortage

    private func during() async throws -> (DemoDataProvider, KitchenHomeViewModel) {
        let demo = story()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        return (demo, await home(demo))
    }

    func testAShortageNeedsADish() async throws {
        let (demo, model) = try await during()
        let outcome = await model.reportShortage(dish: nil, level: .out, note: nil)
        XCTAssertEqual(outcome, .needsDish)
        let stored = try await demo.shortages(for: lunch.id)
        XCTAssertTrue(stored.isEmpty)
    }

    func testAReportReachesTheSupervisorSideAndShowsSent() async throws {
        let (demo, model) = try await during()
        let outcome = await model.reportShortage(dish: "Steamed Rice", level: .almostOut, note: "  ")
        XCTAssertEqual(outcome, .sent)
        let stored = try await demo.makeRepositories().shortages.shortages(for: lunch.id)
        XCTAssertEqual(stored.map(\.dishName), ["Steamed Rice"])
        XCTAssertNil(stored.first?.note)
        XCTAssertEqual(model.state.value?.visibleShortages.count, 1)
    }

    func testHowBadAndANoteAreOptional() async throws {
        let (demo, model) = try await during()
        _ = await model.reportShortage(dish: "Chappathi", level: .gettingLow, note: "Second batch late")
        let stored = try await demo.shortages(for: lunch.id)
        XCTAssertEqual(stored.first?.level, .gettingLow)
        XCTAssertEqual(stored.first?.note, "Second batch late")
    }

    func testASecondReportWithinTenMinutesAsksFirst() async throws {
        let (demo, model) = try await during()
        _ = await model.reportShortage(dish: "Steamed Rice", level: .almostOut, note: nil)
        let second = await model.reportShortage(dish: "Steamed Rice", level: .out, note: nil)
        guard case .alreadyReported = second else { return XCTFail("\(second)") }
        let stored = try await demo.shortages(for: lunch.id)
        XCTAssertEqual(stored.count, 1)
        let confirmed = await model.reportShortage(dish: "Steamed Rice", level: .out, note: nil, confirmed: true)
        XCTAssertEqual(confirmed, .sent)
        let after = try await demo.shortages(for: lunch.id)
        XCTAssertEqual(after.count, 2)
    }

    func testAfterTenMinutesItDoesNotAsk() async throws {
        let clock = TestClock()
        let demo = story(clock: clock)
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        let model = await home(demo)
        _ = await model.reportShortage(dish: "Steamed Rice", level: .almostOut, note: nil)
        clock.set(clock.now().addingTimeInterval(KitchenHomeContent.repeatWindow))
        let again = await model.reportShortage(dish: "Steamed Rice", level: .out, note: nil)
        XCTAssertEqual(again, .sent)
    }

    func testAFailedSendIsNeverShownAsSentAndRetryWorks() async throws {
        let (demo, model) = try await during()
        await demo.setScenario(.offline)
        let outcome = await model.reportShortage(dish: "Steamed Rice", level: .out, note: nil)
        XCTAssertEqual(outcome, .couldNotSend)
        XCTAssertEqual(model.failedReports.count, 1)
        // Still offline: Retry keeps the row.
        await model.retry(model.failedReports[0])
        XCTAssertEqual(model.failedReports.count, 1)
        await demo.setScenario(.duringMeal)
        let failed = model.failedReports[0]
        await model.retry(failed)
        await model.retry(failed)
        XCTAssertTrue(model.failedReports.isEmpty)
        let stored = try await demo.shortages(for: lunch.id)
        XCTAssertEqual(stored.count, 1, "The same key is recorded once")
    }

    func testAReportAfterTheMealEndedIsNotSent() async throws {
        let (demo, model) = try await during()
        demo.clock.set(DemoSeed.lunch.endsAt)  // The clock no longer jumps; move it as the story does.

        _ = try await demo.closeMeal(lunch.id, by: .supervisor)
        let outcome = await model.reportShortage(dish: "Steamed Rice", level: .out, note: nil)
        XCTAssertEqual(outcome, .mealEnded(at: lunch.endsAt))
        let stored = try await demo.shortages(for: lunch.id)
        XCTAssertTrue(stored.isEmpty)
    }

    func testRaviSawItOnlyAfterTheSupervisorSawIt() async throws {
        let (demo, model) = try await during()
        _ = await model.reportShortage(dish: "Steamed Rice", level: .out, note: nil)
        let row = try XCTUnwrap(model.state.value?.visibleShortages.first)
        guard case .sent = row.delivery else { return XCTFail("\(row.delivery)") }
        _ = try await demo.markSeen(row.id, by: .supervisor)
        await model.load()
        guard case .seen(_, let by)? = model.state.value?.visibleShortages.first?.delivery else { return XCTFail("Expected seen") }
        XCTAssertEqual(by, DemoSeed.supervisorName)
    }

    // MARK: Record waste

    func testWasteCannotBeRecordedBeforeTheMealEnds() async throws {
        let demo = story()
        let model = KitchenWasteViewModel(meal: lunch, session: session, repositories: demo.makeRepositories())
        await model.load()
        fill(model)
        let saved = await model.save()
        XCTAssertNil(saved)
        XCTAssertEqual(model.saveError, "Waste is recorded only after the meal has ended.")
    }

    func testEveryDishKeepsItsOwnUnit() async throws {
        let (_, model) = try await closed()
        let units = Dictionary(uniqueKeysWithValues: (model.report?.leftovers ?? []).map { ($0.dishName, $0.unit) })
        XCTAssertEqual(units["Chappathi"], .pieces)
        XCTAssertEqual(units["Masala Sambar"], .litres)
        XCTAssertEqual(units["Steamed Rice"], .kilograms)
    }

    func testTheFourStatesStayDistinct() async throws {
        let (_, model) = try await closed()
        let rows = try XCTUnwrap(model.report?.leftovers)
        model.saveQuantity(2.5, for: .dish(rows[0].dishID))
        model.set(.noneLeft, for: rows[1].dishID)
        model.set(.notMade, for: rows[2].dishID)
        let stored = try XCTUnwrap(model.report?.leftovers)
        XCTAssertEqual(stored[0].measurement, .entered(2.5))
        XCTAssertEqual(stored[1].measurement, .noneLeft)
        XCTAssertEqual(stored[2].measurement, .notMade)
        XCTAssertEqual(stored[3].measurement, .notEntered)
        XCTAssertEqual(KitchenWasteText.value(stored[1]), "0 kg")
        XCTAssertNil(KitchenWasteText.value(stored[2]))
        XCTAssertNil(KitchenWasteText.value(stored[3]))
    }

    func testMissingNeverBecomesZero() async throws {
        let (_, model) = try await closed()
        XCTAssertEqual(model.report?.plateWaste, .notEntered)
        XCTAssertNil(model.report.flatMap { KitchenWasteText.plate($0.plateWaste) })
        XCTAssertEqual(model.doneDishes, 0)
        XCTAssertFalse(model.canSave)
    }

    func testATypedZeroOnADishIsNoneLeftNotAMeasurement() async throws {
        let (_, model) = try await closed()
        let row = try XCTUnwrap(model.report?.leftovers.first)
        model.saveQuantity(0, for: .dish(row.dishID))
        XCTAssertEqual(model.leftover(row.dishID)?.measurement, .noneLeft)
    }

    func testAnIncompleteReportIsNotSavedButADraftIs() async throws {
        let (demo, model) = try await closed()
        let row = try XCTUnwrap(model.report?.leftovers.first)
        model.saveQuantity(2, for: .dish(row.dishID))
        let saved = await model.save()
        XCTAssertNil(saved)
        let draft = await model.saveDraft()
        XCTAssertTrue(draft)
        let stored = try await demo.report(for: lunch.id)
        guard case .draft = stored.status else { return XCTFail("\(stored.status)") }
        XCTAssertFalse(model.isDirty)
    }

    func testASavedReportIsRecordedAndReachesTheHistory() async throws {
        let (demo, model) = try await closed()
        fill(model)
        let saved = try await XCTUnwrapAsync(await model.save())
        XCTAssertEqual(saved.status, .recorded(savedAt: demo.clock.now()))
        let history = try await demo.mealHistory(for: DemoSeed.mess.id)
        let record = try XCTUnwrap(history.first { $0.mealID == lunch.id })
        XCTAssertEqual(record.waste, .recorded(at: demo.clock.now()))
        XCTAssertEqual(record.wasteReport, saved)
    }

    func testAnEditIsAllowedInsideSixHoursAndRefusedAfter() async throws {
        let clock = TestClock()
        let (_, model) = try await closed(clock: clock)
        fill(model)
        let saved = try await XCTUnwrapAsync(await model.save())
        guard case .recorded(let at) = saved.status else { return XCTFail("Expected recorded") }
        clock.set(at.addingTimeInterval(WasteReportPolicy.editWindow - 60))
        model.setPlate(2)
        let edited = await model.save()
        XCTAssertNotNil(edited)
        guard case .recorded(let second)? = edited?.status else { return XCTFail("Expected recorded") }
        clock.set(second.addingTimeInterval(WasteReportPolicy.editWindow))
        model.setPlate(3)
        let late = await model.save()
        XCTAssertNil(late)
        XCTAssertEqual(model.saveError, "Editing closed after 6 hours.")
    }

    func testTheSupervisorAndAdminAreRefused() async throws {
        for role in [Role.supervisor, .admin] {
            let (demo, model) = try await closed()
            fill(model)
            let report = try XCTUnwrap(model.report)
            do {
                _ = try await demo.save(report, by: role)
                XCTFail("\(role) must not save waste")
            } catch {
                guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
            }
        }
    }

    func testAnAddedDishStartsNotEntered() async throws {
        let (_, model) = try await closed()
        let before = model.totalDishes
        model.addDish(name: " Poriyal ", unit: .kilograms)
        model.addDish(name: "   ", unit: .kilograms)
        XCTAssertEqual(model.totalDishes, before + 1)
        XCTAssertEqual(model.report?.leftovers.last?.dishName, "Poriyal")
        XCTAssertEqual(model.report?.leftovers.last?.measurement, .notEntered)
    }

    // MARK: Quantity entry

    func testQuantityLimitsFollowTheSpec() {
        var kilograms = KitchenQuantityInput(unit: .kilograms)
        for digit in [9, 9] { kilograms.append(digit) }
        kilograms.appendDecimal()
        kilograms.append(9)
        XCTAssertEqual(kilograms.value, 99.9)
        kilograms.append(9)
        XCTAssertEqual(kilograms.text, "99.9", "One decimal only")
        var over = KitchenQuantityInput(unit: .litres)
        for digit in [1, 0, 0] { over.append(digit) }
        XCTAssertNil(over.value)
        var pieces = KitchenQuantityInput(unit: .pieces)
        pieces.appendDecimal()
        XCTAssertEqual(pieces.text, "", "Pieces take no decimal")
        for digit in [9, 9, 9] { pieces.append(digit) }
        XCTAssertEqual(pieces.value, 999)
        pieces.append(9)
        XCTAssertNil(pieces.value)
    }

    func testAnEmptyQuantityIsNotZero() {
        XCTAssertNil(KitchenQuantityInput(unit: .kilograms).value)
    }

    // MARK: Menu, history, alerts

    func testTheMenuIsDishNamesFromTheRepository() async {
        let model = KitchenMenuViewModel(meal: lunch, meals: story())
        await model.load()
        XCTAssertEqual(model.state.value?.map(\.name), DemoSeed.lunchMenu.map(\.name))
    }

    func testHistoryListsEndedMealsOnly() async throws {
        let demo = story()
        let model = KitchenHistoryViewModel(session: session, repositories: demo.makeRepositories())
        await model.load()
        XCTAssertFalse(model.state.value?.contains { $0.mealID == lunch.id } ?? true, "Lunch has not ended")
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        _ = try await demo.closeMeal(lunch.id, by: .supervisor)
        await model.load()
        XCTAssertTrue(model.state.value?.contains { $0.mealID == lunch.id } ?? false)
    }

    func testAPastMealOffersEditOnlyInsideTheWindow() async throws {
        let clock = TestClock()
        let (demo, waste) = try await closed(clock: clock)
        fill(waste)
        _ = await waste.save()
        let model = KitchenPastMealViewModel(mealID: lunch.id, session: session, repositories: demo.makeRepositories(), clock: clock)
        await model.load()
        XCTAssertEqual(model.editableMeal?.id, lunch.id)
        XCTAssertTrue(model.canEdit(savedAt: clock.now()))
        let savedAt = clock.now()
        clock.set(savedAt.addingTimeInterval(WasteReportPolicy.editWindow))
        XCTAssertFalse(model.canEdit(savedAt: savedAt))
    }

    func testAnOlderMealCannotBeEditedHere() async throws {
        let demo = story()
        let older = try XCTUnwrap(DemoSeed.pastMeals.first)
        let model = KitchenPastMealViewModel(mealID: older.id, session: session, repositories: demo.makeRepositories(), clock: demo.clock)
        await model.load()
        XCTAssertNil(model.editableMeal)
    }

    func testMealEndedAlertAppearsAndGoesOnceRecorded() async throws {
        let (demo, waste) = try await closed()
        let model = KitchenAlertsViewModel(session: session, repositories: demo.makeRepositories())
        await model.load()
        XCTAssertEqual(model.state.value?.first?.title, KitchenCopy.mealEnded)
        fill(waste)
        _ = await waste.save()
        await model.load()
        XCTAssertFalse(model.state.value?.contains { $0.title == KitchenCopy.mealEnded } ?? false)
    }

    func testAlertsNeverShowAMealStillInProgressAsMissingWaste() async throws {
        let demo = story()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        let model = KitchenAlertsViewModel(session: session, repositories: demo.makeRepositories())
        await model.load()
        XCTAssertFalse(model.state.value?.contains { $0.detail.contains("Lunch") && $0.title == KitchenCopy.mealEnded } ?? false)
    }

    // MARK: Access

    func testOnlyKitchenStaffReachTheRole() async throws {
        let demo = story()
        for account in DemoSeed.accounts where account.role != .student {
            let signedIn = try await demo.signInStaff(email: account.email, password: DemoSeed.prototypePassword)
            XCTAssertEqual(KitchenRootView.allows(signedIn), account.role == .kitchenStaff, "\(account.role)")
        }
        let student = try await demo.srmStudentSession()
        XCTAssertFalse(KitchenRootView.allows(student))
    }

    func testTheAvatarLabelIsNotTheTabName() {
        XCTAssertNotEqual(KitchenCopy.avatarLabel, "Me")
    }

    func testNoBannedWordsInTheCopy() throws {
        let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("MealLoop/Features/Kitchen")
        let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        for file in files where file.pathExtension == "swift" {
            let code = try String(contentsOf: file, encoding: .utf8).components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }.joined().lowercased()
            for word in ["meals served", "recorded at the door", "needs attention", "\"remind", "forward to admin", "waiting for approval"] {
                XCTAssertFalse(code.contains(word), "\(word) in \(file.lastPathComponent)")
            }
        }
    }
}

private func XCTUnwrapAsync<T>(_ value: @autoclosure () async -> T?, file: StaticString = #filePath, line: UInt = #line) async throws -> T {
    let result = await value()
    return try XCTUnwrap(result, file: file, line: line)
}
#endif
