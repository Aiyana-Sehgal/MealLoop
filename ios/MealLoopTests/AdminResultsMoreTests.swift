#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// Students, Results and More, through their view models against the prototype backend.
@MainActor
final class AdminResultsMoreTests: XCTestCase {
    private let timeZone = DemoSeed.mess.timeZone

    private func repositories(_ scenario: DemoScenario = .afterMeal) -> Repositories {
        DemoDataProvider(scenario: scenario).makeRepositories()
    }

    private func json<Value: Encodable>(_ value: Value) throws -> String {
        String(decoding: try JSONEncoder().encode(value), as: UTF8.self)
    }

    private func session(_ role: Role) throws -> Session {
        let account = try XCTUnwrap(DemoSeed.accounts.first { $0.role == role })
        return Session(account: account, staff: nil, student: nil)
    }

    private func comparable(day: Int, ranOut: Bool = false, isComparable: Bool = true) -> ComparableMeal {
        ComparableMeal(day: DemoSeed.date(day, 0, 0), headcountSent: 800, finalEntries: 780, note: nil, isRecorded: true,
                       isComparable: isComparable, ranOut: ranOut)
    }

    private func check(_ meals: [ComparableMeal], actionDone: Bool = true) throws -> CheckNextTime {
        var check = try XCTUnwrap(AdminSeed.checks.first)
        check = CheckNextTime(id: check.id, title: check.title, listTitle: check.listTitle, mess: check.mess, startedOn: check.startedOn,
                              startedBy: check.startedBy, change: check.change, owner: check.owner, plan: check.plan,
                              comparableTitle: check.comparableTitle, comparable: meals, footnote: check.footnote,
                              isActionCompleted: actionDone, stage: .testing, notes: [], closedAsWorked: false)
        return check
    }

    // MARK: Reasons

    func testNoReasonCarriesAPercentage() async throws {
        let repositories = repositories()
        let overview = try await repositories.adminResults.overview()
        XCTAssertFalse(try json(overview.leftOver).contains("%"))
        XCTAssertFalse(try json(overview.ranOut).contains("%"))
        for kind in ReasonKind.allCases {
            let detail = try await repositories.adminResults.reason(kind)
            let reasonText = [detail.reason.title, detail.reason.detail ?? "", detail.explanation, detail.timelineNote ?? "",
                              detail.arrivals?.markerText ?? ""] + detail.timeline.map(\.text) + detail.feedback.map(\.problem)
            XCTAssertFalse(reasonText.joined().contains("%"), "\(kind)")
        }
        let report = try await repositories.adminResults.weeklyReport(.thisWeek)
        XCTAssertFalse(try json(report.pages?.reasons).contains("%"))
        XCTAssertFalse(AdminScreenCopy.moreThanSent(came: 627, more: 47).contains("%"))
    }

    func testEveryReasonUsesOnlyTheThreeTags() {
        XCTAssertEqual(Set(ReasonTag.allCases.map(AdminScreenCopy.tag)), ["Sure", "Probably", "Can't tell"])
    }

    func testAReasonIsTaggedAndCountedInMealsWithNoShareField() {
        let reason = AdminSeed.leftOver.reasons[0]
        let labels = Mirror(reflecting: reason).children.compactMap(\.label)
        XCTAssertEqual(labels.sorted(), ["detail", "kind", "meals", "tag", "title"])
        XCTAssertEqual(AdminScreenCopy.countMeals(1), "1 meal")
        XCTAssertEqual(AdminScreenCopy.countMeals(5), "5 meals")
    }

    func testReasonCountsMatchThePack() async throws {
        let overview = try await repositories().adminResults.overview()
        XCTAssertEqual(overview.leftOver.reasons.map(\.meals), [5, 3, 2, 4])
        XCTAssertEqual(overview.leftOver.meals, 9)
        XCTAssertEqual(overview.ranOut.reasons.map(\.meals), [1, 1, 1, 1])
        XCTAssertEqual(overview.ranOut.meals, 2)
    }

    func testAMealWithNoFinalCountIsNotListedAsFewerCame() async throws {
        let detail = try await repositories(.duringMeal).adminResults.reason(.fewerCame)
        XCTAssertFalse(detail.meals.contains { $0.id == DemoSeed.lunch.id })
        XCTAssertEqual(detail.meals.count + detail.moreMeals, detail.reason.meals)
    }

    // MARK: Check next time

    func testWorkedNeedsTwoComparableMeals() throws {
        XCTAssertEqual(CheckNextTimePolicy.requiredMeals, 2)
        XCTAssertFalse(CheckNextTimePolicy.canCloseAsWorked(try check([])))
        XCTAssertFalse(CheckNextTimePolicy.canCloseAsWorked(try check([comparable(day: 14)])))
        XCTAssertTrue(CheckNextTimePolicy.canCloseAsWorked(try check([comparable(day: 14), comparable(day: 21)])))
    }

    func testAMealThatIsNotComparableDoesNotCount() throws {
        let meals = [comparable(day: 14), comparable(day: 21, isComparable: false)]
        XCTAssertEqual(CheckNextTimePolicy.countedMeals(try check(meals)), 1)
        XCTAssertFalse(CheckNextTimePolicy.canCloseAsWorked(try check(meals)))
    }

    func testAMealThatRanOutStopsWorked() throws {
        XCTAssertFalse(CheckNextTimePolicy.canCloseAsWorked(try check([comparable(day: 14), comparable(day: 21, ranOut: true)])))
    }

    func testACompletedActionIsNotAVerifiedImprovement() throws {
        let done = try check([comparable(day: 14)], actionDone: true)
        XCTAssertTrue(done.isActionCompleted)
        XCTAssertFalse(CheckNextTimePolicy.canCloseAsWorked(done))
        XCTAssertFalse(done.closedAsWorked)
    }

    func testTheBackendAndTheScreenBothRefuseWorkedWithOneMeal() async throws {
        let repositories = repositories()
        let model = AdminCheckViewModel(id: AdminSeed.wednesdayPlan, role: .admin, results: repositories.adminResults)
        await model.load()
        XCTAssertEqual(model.counted, 1)
        XCTAssertFalse(model.canCloseAsWorked)

        await model.closeAsWorked()

        XCTAssertNotNil(model.errorText)
        XCTAssertEqual(model.state.value?.closedAsWorked, false)
        XCTAssertEqual(model.state.value?.stage, .testing)
        let saved = try await repositories.adminResults.check(AdminSeed.wednesdayPlan)
        XCTAssertFalse(saved.closedAsWorked)
    }

    func testAStoryMealStillOpenCountsForNothing() async {
        let model = AdminCheckViewModel(id: AdminSeed.wednesdayPlan, role: .admin, results: repositories(.duringMeal).adminResults)
        await model.load()
        XCTAssertEqual(model.counted, 0)
    }

    func testIDsTypedByHandDoNotCount() async {
        let model = AdminCheckViewModel(id: AdminSeed.northScanner, role: .admin, results: repositories().adminResults)
        await model.load()
        XCTAssertEqual(model.state.value?.stage, .open)
        XCTAssertEqual(model.counted, 0)
    }

    func testMakingAChangeForTheStoryMealOpensTheExistingOneAndReviewsTheMeal() async throws {
        let context = try XCTUnwrap(AdminContext(session: try session(.admin)))
        let repositories = repositories()
        let model = AdminChangeViewModel(meal: DemoSeed.lunch.id, suggested: "Use the average", context: context, results: repositories.adminResults)

        let saved = await model.save()

        XCTAssertEqual(saved?.id, AdminSeed.wednesdayPlan)
        let meal = try await repositories.adminResults.meal(DemoSeed.lunch.id)
        XCTAssertFalse(meal.needsReview)
    }

    func testAnEmptyChangeCannotBeSaved() async throws {
        let context = try XCTUnwrap(AdminContext(session: try session(.admin)))
        let model = AdminChangeViewModel(meal: nil, suggested: "  ", context: context, results: repositories().adminResults)
        XCTAssertFalse(model.canSave)
        let saved = await model.save()
        XCTAssertNil(saved)
    }

    // MARK: Missing is never zero

    func testMissingCountsAreDashesNotZero() {
        XCTAssertEqual(AdminFormat.count(nil), "—")
        XCTAssertEqual(AdminFormat.count(0), "0", "A real zero still reads as zero")
        XCTAssertEqual(AdminFormat.amount(FoodAmount(dish: "Rice", amount: nil, unit: .kilograms)), "—")
    }

    func testAMealBeforeItClosesShowsDashesAndSaysWhy() async throws {
        let meal = try await repositories(.storyStart).adminResults.meal(DemoSeed.lunch.id)
        XCTAssertEqual(AdminFormat.sentToCame(meal), "— → —")
        XCTAssertNil(AdminMealReportContent.difference(meal))
        let lines = AdminMealReportContent.lines(meal, timeZone: timeZone)
        XCTAssertTrue(lines.contains { $0.text == AdminScreenCopy.notClosedYet && !$0.isKnown })
    }

    func testNothingAboutAnOpenMealIsStatedBeforeItCloses() async throws {
        let meal = try await repositories(.duringMeal).adminResults.meal(DemoSeed.lunch.id)
        XCTAssertNil(meal.headcountChange)
        XCTAssertTrue(meal.missing.isEmpty)
        XCTAssertTrue(meal.openQuestions.isEmpty)
        XCTAssertTrue(meal.ranOut.isEmpty)
        XCTAssertEqual(AdminMealReportContent.lines(meal, timeZone: timeZone).map(\.text), [AdminScreenCopy.notClosedYet])
    }

    func testMissingEvidenceIsListedAsMissing() async throws {
        let meal = try await repositories(.afterMeal).adminResults.meal(DemoSeed.lunch.id)
        XCTAssertEqual(meal.finalEntries, DemoSeed.finalEntries)
        XCTAssertEqual(Set(meal.missing), [.amountCooked, .wasteRecord])
        let unknown = AdminMealReportContent.lines(meal, timeZone: timeZone).filter { !$0.isKnown }.map(\.text)
        XCTAssertTrue(unknown.contains(AdminScreenCopy.evidenceLine(.amountCooked)))
        XCTAssertTrue(unknown.contains(AdminScreenCopy.evidenceLine(.wasteRecord)))
    }

    func testAMessThatSentNoDataStaysEmptyInTheReport() async throws {
        let report = try await repositories().adminResults.weeklyReport(.thisWeek)
        let south = try XCTUnwrap(report.pages?.byMess.first { $0.mess == "South" })
        XCTAssertNil(south.plateWasteKg)
        XCTAssertNil(south.ranOutMeals)
        XCTAssertNil(south.dataCompletePercent)
    }

    func testAnAudienceWithNoNumberDoesNotSayZero() async throws {
        let draft = try await repositories().adminMore.announcementDraft()
        let north = try XCTUnwrap(draft.audiences.first { $0.id == "north" })
        XCTAssertNil(north.students)
        XCTAssertFalse(AdminScreenCopy.audienceReach(north).contains("0"))
    }

    // MARK: Who can reach it

    func testOnlyAFoodHeadSessionMakesAnAdminContext() throws {
        for role in Role.allCases where role != .admin {
            guard let account = DemoSeed.accounts.first(where: { $0.role == role }) else { continue }
            XCTAssertNil(AdminContext(session: Session(account: account, staff: nil, student: nil)), "\(role)")
        }
        XCTAssertNotNil(AdminContext(session: try session(.admin)))
    }

    // MARK: Each tab loads its states

    func testStudentsLoadsAndGoesOffline() async {
        let model = AdminStudentsViewModel(students: repositories(.duringMeal).adminStudents, role: .admin)
        XCTAssertEqual(model.state, .idle)
        await model.load()
        XCTAssertEqual(model.state.value?.answered, 2_870)
        XCTAssertEqual(model.state.value?.notAnswered, 630)

        let offline = AdminStudentsViewModel(students: repositories(.offline).adminStudents, role: .admin)
        await offline.load()
        XCTAssertEqual(offline.state, .offline(nil, savedAt: DemoSeed.offlineSavedAt))
    }

    func testResultsAndMoreLoadAndGoOffline() async {
        let online = repositories(.duringMeal)
        let results = AdminPageModel { try await online.adminResults.overview() }
        await results.load()
        XCTAssertEqual(results.state.value?.toReview.count, 2)
        XCTAssertEqual(results.state.value?.changes.count, 2)
        let more = AdminPageModel { try await online.adminMore.hub() }
        await more.load()
        XCTAssertEqual(more.state.value?.passUsed, 196)

        let down = repositories(.offline)
        let offline = AdminPageModel { try await down.adminResults.overview() }
        await offline.load()
        if case .offline = offline.state {} else { XCTFail("\(offline.state)") }
    }

    func testAnotherSourceShowsNotBuiltNotAnEmptyScreen() async {
        let remote = RemoteAPI(baseURL: nil).makeRepositories()
        let model = AdminStudentsViewModel(students: remote.adminStudents, role: .admin)
        await model.load()
        guard case .failed(let failure) = model.state else { return XCTFail("\(model.state)") }
        XCTAssertTrue(failure.isNotImplemented)
    }

    func testFindAMealFiltersAndSaysWhenThereIsNothing() async {
        let model = AdminFindMealViewModel(defaultMess: "Main", results: repositories().adminResults)
        await model.load()
        XCTAssertEqual(model.messes, ["Main", "North", "South", "Annexe"])
        XCTAssertEqual(model.state.value?.map(\.mess), ["Main", "Main"])
        await model.select(slot: .snacks)
        XCTAssertEqual(model.state, .empty)
    }

    // MARK: Students

    func testARemindIsRecordedOnce() async {
        let model = AdminStudentsViewModel(students: repositories().adminStudents, role: .admin)
        await model.load()
        let first = await model.remind()
        XCTAssertTrue(first)
        let sentAt = model.state.value?.reminderSentAt
        XCTAssertNotNil(sentAt)
        _ = await model.remind()
        XCTAssertEqual(model.state.value?.reminderSentAt, sentAt)
    }

    func testAnOfflineRemindIsNotShownAsSent() async {
        let model = AdminStudentsViewModel(students: repositories(.offline).adminStudents, role: .admin)
        let sent = await model.remind()
        XCTAssertFalse(sent)
        XCTAssertEqual(model.errorText, AdminScreenCopy.offlineNothingSaved)
    }

    func testAnOwnerDoesNotFixTheIssue() async {
        let model = AdminCommunityViewModel(id: AdminSeed.longWait, role: .admin, students: repositories().adminStudents)
        await model.load()
        let assigned = await model.assign("Ravi")
        XCTAssertTrue(assigned)
        XCTAssertEqual(model.state.value?.owner, "Ravi")
        XCTAssertNotEqual(model.state.value?.stage, .fixed)
    }

    func testStudentDataHasNoNames() throws {
        let text = try json(AdminSeed.students) + json(AdminSeed.skipReasons)
        for name in ["Aarav", "Meera", "Karan", "••"] {
            XCTAssertFalse(text.contains(name), name)
        }
    }

    func testSkipCountsAddUpToThoseWhoSaidNo() {
        let skips = AdminSeed.skipReasons
        XCTAssertEqual(skips.reasons.map(\.students).reduce(0, +) + skips.gaveNoReason, skips.saidNo)
        XCTAssertTrue(skips.reasons.allSatisfy { $0.students >= 10 })
    }

    // MARK: Weekly report

    func testExportNeverClaimsAFile() async {
        let model = AdminWeeklyReportViewModel(results: repositories().adminResults, preparingTime: .zero)
        await model.load()
        await model.exportPDF()
        XCTAssertEqual(model.exportState, .preview)
        model.exportCSV()
        XCTAssertEqual(model.csvNote, AdminScreenCopy.csvNotBuilt)
        for text in [AdminScreenCopy.noFileMade, AdminScreenCopy.csvNotBuilt, AdminScreenCopy.reportPreview] {
            XCTAssertFalse(text.lowercased().contains("saved"), text)
            XCTAssertFalse(text.lowercased().contains("ready"), text)
        }
    }

    func testPeriodsFollowThePack() async {
        let model = AdminWeeklyReportViewModel(results: repositories().adminResults, preparingTime: .zero)
        await model.load()
        XCTAssertEqual(model.state.value?.mealsLeftOver, 4)
        await model.select(.lastWeek)
        XCTAssertEqual(model.state.value?.mealsLeftOver, 3)
        XCTAssertNil(model.state.value?.pages, "No breakdown is drawn for this period, so none is made up")
        await model.select(.month)
        XCTAssertEqual(model.state.value?.mealsRanOut, 2)
    }

    func testTheVendorSummaryHasNoStudentIdentity() {
        for report in AdminSeed.weeklyReports.values {
            XCTAssertFalse(report.vendorSummary.contains("Aarav"))
            XCTAssertFalse(report.vendorSummary.contains("••"))
        }
    }

    // MARK: More

    func testTheUploadIsSimulatedAndChangesNoData() async {
        let repositories = repositories()
        let model = AdminMenuViewModel(more: repositories.adminMore, role: .admin, stepTime: .zero)
        await model.load()
        let before = model.state.value
        await model.simulateUpload()
        XCTAssertEqual(model.phase, .idle)
        await model.load()
        XCTAssertEqual(model.state.value, before)
        XCTAssertTrue(AdminScreenCopy.simulatedUpload.contains("no photo is uploaded or read"))
    }

    private func thursday(_ repositories: Repositories) async -> AdminDayEditViewModel {
        let model = AdminDayEditViewModel(date: DemoSeed.date(15, 0, 0), more: repositories.adminMore, role: .admin)
        await model.load()
        return model
    }

    func testEditingADayAndUndoing() async throws {
        let model = await thursday(repositories())
        let original = model.dishes
        XCTAssertEqual(original.count, 11)

        model.toggleHighlight("Steamed Rice")
        XCTAssertEqual(model.dishes.first { $0.id == "Steamed Rice" }?.isHighlight, true)
        model.toggleVeg("Rasam")
        XCTAssertEqual(model.dishes.first { $0.id == "Rasam" }?.isNonVeg, true)
        model.move(from: IndexSet(integer: 0), to: 2)
        XCTAssertEqual(model.dishes[1].id, "Chappathi")
        model.delete("Pickle")
        XCTAssertFalse(model.dishes.contains { $0.id == "Pickle" })
        model.add("Curd Rice")
        XCTAssertEqual(model.dishes.last?.name, "Curd Rice")

        for _ in 0..<5 { model.undo() }
        XCTAssertEqual(model.dishes, original)
        XCTAssertFalse(model.canUndo)
    }

    func testCheckingAWordClearsTheMarkAndSaves() async throws {
        let repositories = repositories()
        let model = await thursday(repositories)
        XCTAssertEqual(model.wordsToCheck.count, 2)
        model.useWord("Aloo Gobi Adraki", for: "Aloo Gobi Athiraki", in: .lunch)
        XCTAssertEqual(model.wordsToCheck.count, 1)
        let saved = await model.save()
        XCTAssertTrue(saved)
        let menu = try await repositories.adminMore.weekMenu()
        let day = try XCTUnwrap(menu.days.first { $0.day == DemoSeed.date(15, 0, 0) })
        XCTAssertEqual(day.wordsToCheck, 1)
    }

    func testCopyLastWeekFillsTheMealAndKeepsTheWordToCheck() async {
        let model = await thursday(repositories())
        model.delete("Pickle")
        await model.copyLastWeek(sourceDay: "Thu 8 Aug")
        XCTAssertEqual(model.dishes.count, 11)
        XCTAssertEqual(model.copiedNote, "Copied from Thu 8 Aug lunch: 11 dishes. The word to check is kept.")
    }

    func testDishSuggestionsComeFromTheBoard() async {
        let model = await thursday(repositories())
        XCTAssertEqual(Set(model.suggestions(for: "Cur")).isSuperset(of: ["Curd Rice"]), true)
        XCTAssertTrue(model.suggestions(for: "").isEmpty)
    }

    func testSwapSuggestionsAreSimilarDishesFromTheBoard() {
        XCTAssertEqual(AdminDishSuggestions.similar(to: "Dal Tadka", in: ["Tomato Dal", "Dal Fry", "Rasam", "Dal Tadka"]), ["Tomato Dal", "Dal Fry"])
    }

    func testTheDinnerChangeReachesTheMenu() async throws {
        let model = AdminMenuViewModel(more: repositories().adminMore, role: .admin, stepTime: .zero)
        await model.load()
        let didApply = await model.apply(.swap(dish: "Dal Tadka", with: "Tomato Dal"))
        XCTAssertTrue(didApply)
        XCTAssertEqual(model.today?.meals[.dinner]?.contains { $0.name == "Tomato Dal" }, true)
        XCTAssertEqual(model.today?.meals[.dinner]?.contains { $0.name == "Dal Tadka" }, false)
    }

    func testAnAnnouncementHasALimit() async {
        let model = AdminAnnounceViewModel(more: repositories().adminMore, role: .admin)
        await model.load()
        XCTAssertEqual(model.audience?.confirmName, "Main Mess")
        XCTAssertTrue(model.canSend)
        model.message = String(repeating: "x", count: 141)
        XCTAssertFalse(model.canSend)
        let sent = await model.send()
        XCTAssertFalse(sent)
    }

    func testAnInviteNeedsANumberAndCountsOnce() async {
        let model = AdminPeopleViewModel(more: repositories().adminMore, role: .admin)
        await model.load()
        let empty = await model.invite(phone: "", role: "Door staff")
        XCTAssertFalse(empty)
        XCTAssertEqual(model.errorText, "Enter a phone number.")
        let sent = await model.invite(phone: "+91 90000 00000", role: "Door staff")
        XCTAssertTrue(sent)
        XCTAssertEqual(model.state.value?.invited, 3)
    }
}
#endif
