#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The rules the Figma pass must not bend. Chips change how a status looks, never what it says.
@MainActor
final class AdminFigmaFixTests: XCTestCase {
    private func foodHead(_ demo: DemoDataProvider) async throws -> AdminContext {
        let session = try await demo.signInStaff(email: "foodhead@mealloop.example", password: "MealLoop-2026")
        return try XCTUnwrap(AdminContext(session: session))
    }

    private func today(_ scenario: DemoScenario = .storyStart) async throws -> (DemoDataProvider, AdminTodayViewModel) {
        let demo = DemoDataProvider(scenario: scenario)
        let model = AdminTodayViewModel(context: try await foodHead(demo), repositories: demo.makeRepositories(), clock: demo.clock)
        await model.load()
        return (demo, model)
    }

    // Chips

    func testEachReasonTagKeepsItsOwnChipAndWord() {
        XCTAssertEqual(AdminChipRules.reason(.sure), .lime)
        XCTAssertEqual(AdminChipRules.reason(.probably), .outline)
        XCTAssertEqual(AdminChipRules.reason(.cantTell), .dashed)
        XCTAssertEqual(ReasonTag.allCases.map(AdminScreenCopy.tag), ["Sure", "Probably", "Can't tell"])
    }

    func testAChipFollowsTheStatusAndNeverDecidesIt() {
        XCTAssertEqual(AdminChipRules.review(needsReview: true), .black)
        XCTAssertEqual(AdminChipRules.review(needsReview: false), .outline)
        XCTAssertEqual(AdminChipRules.stage(.testing), .lime)
        XCTAssertEqual(AdminChipRules.stage(.open), .outline)
        XCTAssertEqual(AdminChipRules.safety(isOpen: true), .lime)
        XCTAssertEqual(AdminChipRules.safety(isOpen: false), .outline)
    }

    func testWaitingAndNoReplyNeverLookOrReadLikeAReply() {
        let zone = TimeZone(identifier: "Asia/Kolkata")!
        XCTAssertEqual(AdminCopy.replyWord(.waiting, in: zone), "Waiting")
        XCTAssertEqual(AdminCopy.replyWord(.noReply, in: zone), "No reply")
        XCTAssertEqual(AdminChipRules.vendor(.waiting), .quiet)
        XCTAssertEqual(AdminChipRules.vendor(.notSent), .dashed)
    }

    func testEveryReasonStaysFreeOfPercentages() async throws {
        let repositories = DemoDataProvider(scenario: .afterMealWasteRecorded).makeRepositories()
        let overview = try await repositories.adminResults.overview()
        for reason in overview.leftOver.reasons + overview.ranOut.reasons {
            XCTAssertFalse(reason.title.contains("%"), reason.title)
            XCTAssertFalse((reason.detail ?? "").contains("%"), reason.title)
            let detail = try await repositories.adminResults.reason(reason.kind)
            XCTAssertFalse(detail.explanation.contains("%"), detail.explanation)
        }
    }

    // Wording

    func testNothingClaimsAMessageReachedAnyone() {
        let audience = AnnouncementAudience(id: "main", title: "Main", confirmName: "Main Mess", students: 860)
        let lines = [AdminScreenCopy.savedTold, AdminScreenCopy.sentDinner, AdminScreenCopy.everyoneGets("3,500"), AdminScreenCopy.remindNote,
                     AdminScreenCopy.reminderToast, AdminScreenCopy.reminderSent("9:00 AM"), AdminScreenCopy.announcementSent,
                     AdminScreenCopy.inviteSent, AdminScreenCopy.audienceReach(audience)]
        for line in lines {
            for claim in ["see it", "see the new", "get this", "get a notification", "delivered", "received"] {
                XCTAssertFalse(line.localizedCaseInsensitiveContains(claim), line)
            }
        }
    }

    // Pictograms

    func testDishesTakeThePictogramOfTheirKeyword() {
        XCTAssertEqual(AdminDishKind.kind(for: "Masala Dosa"), .bread)
        XCTAssertEqual(AdminDishKind.kind(for: "Chappathi"), .bread)
        XCTAssertEqual(AdminDishKind.kind(for: "Steamed Rice"), .rice)
        XCTAssertEqual(AdminDishKind.kind(for: "Veg Pulao"), .rice)
        XCTAssertEqual(AdminDishKind.kind(for: "Panneer Butter Masala"), .paneer)
        XCTAssertEqual(AdminDishKind.kind(for: "Curd Rice"), .curd)
        XCTAssertEqual(AdminDishKind.kind(for: "Sambar"), .curry)
    }

    // Today

    func testTheGridHoldsTheOtherMessesWithoutTouchingTheSixValues() async throws {
        let (_, model) = try await today()
        let content = try XCTUnwrap(model.state.value)
        XCTAssertEqual(content.otherMesses?.messes.map(\.name), ["North", "South", "Annexe"])
        XCTAssertEqual(content.values.count, 6)
        XCTAssertEqual(Set(content.values.map(\.name)).count, 6, "The six values stay separate")
        XCTAssertTrue(content.values.contains { $0.count == nil }, "A missing value stays nil")
    }

    func testOnlyOneTileIsBlack() async throws {
        let (_, model) = try await today()
        let content = try XCTUnwrap(model.state.value)
        XCTAssertTrue(content.tileIsUrgent)
        XCTAssertNil(content.urgentOtherMess)
    }

    func testAMissingMessSourceStillShowsTheFoodHeadsOwnMess() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        var repositories = demo.makeRepositories()
        repositories.adminMesses = AdminMessesNotBuilt()
        let model = AdminTodayViewModel(context: try await foodHead(demo), repositories: repositories, clock: demo.clock)
        await model.load()
        XCTAssertNil(model.state.value?.otherMesses)
        XCTAssertNotNil(model.state.value?.meal)
    }

    func testNeedsYouNeverHoldsMoreThanTheLimit() async throws {
        let (_, model) = try await today(.duringMealShortageReported)
        let content = try XCTUnwrap(model.state.value)
        XCTAssertLessThanOrEqual(content.visibleShortages.count + content.visibleReviews.count, AdminTodayContent.needsYouLimit)
    }

    func testAMealStillToComeIsNeverOfferedForReview() async throws {
        let (_, model) = try await today()
        let reviews = try XCTUnwrap(model.state.value).reviewMeals
        XCTAssertFalse(reviews.isEmpty)
        XCTAssertTrue(reviews.allSatisfy(\.meal.isClosed))
        XCTAssertFalse(reviews.contains { $0.id == DemoSeed.lunch.id })
    }

    func testMealHoursDropWhatTheyRepeat() {
        XCTAssertEqual(AdminCopy.mealHours("12:00 PM", "2:00 PM"), "12–2 PM")
        XCTAssertEqual(AdminCopy.mealHours("7:30 AM", "9:00 AM"), "7:30–9 AM")
        XCTAssertEqual(AdminCopy.mealHours("11:00 AM", "1:00 PM"), "11 AM–1 PM")
    }

    func testOpenCaseGoesToTheCasePageWhenResultsHoldsIt() async throws {
        let (_, model) = try await today()
        let known = SOSCase(id: SOSCaseID("a"), messID: DemoSeed.mess.id, title: "Found something in food", place: "", raisedAt: DemoSeed.sosRaisedAt,
                            claim: nil, checks: [], status: .open)
        let unknown = SOSCase(id: SOSCaseID("b"), messID: DemoSeed.mess.id, title: "Something else", place: "", raisedAt: DemoSeed.sosRaisedAt,
                              claim: nil, checks: [], status: .open)
        let first = await model.safetyPage(for: known)
        let second = await model.safetyPage(for: unknown)
        XCTAssertEqual(first, .safetyCase("safety-wed-lunch"))
        XCTAssertEqual(second, .safetyCases)
    }

    // Another mess

    func testSendingForAnotherMessWaitsAndADoubleTapSendsOnce() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        let messes = demo.makeRepositories().adminMesses
        let model = AdminMessHeadcountViewModel(id: "North", slot: .lunch, role: .admin, messes: messes)
        await model.load()
        let first = await model.send()
        let second = await model.send()
        XCTAssertTrue(first)
        XCTAssertTrue(second, "The same key returns the same record")
        XCTAssertEqual(model.state.value?.reply, .waiting)
    }

    func testTheForecastLineSaysOnlyWhatTheRecordHolds() async throws {
        let messes = DemoDataProvider(scenario: .storyStart).makeRepositories().adminMesses
        let north = try await messes.messHeadcount("North", slot: .lunch)
        let south = try await messes.messHeadcount("South", slot: .lunch)
        let annexe = try await messes.messHeadcount("Annexe", slot: .lunch)
        XCTAssertEqual(AdminCopy.forecastRangeLine(north), "Forecast 700 · range 660–740 · usual Wed 692")
        XCTAssertEqual(AdminCopy.forecastRangeLine(south), "Forecast 612")
        XCTAssertNil(AdminCopy.forecastRangeLine(annexe))
    }

    // Live meal

    func testAShortageChipUsesTheLevelTheStaffReported() {
        XCTAssertEqual(AdminCopy.levelChip(.gettingLow), "Running low")
        XCTAssertEqual(AdminCopy.levelChip(.almostOut), "Almost out")
        XCTAssertEqual(AdminCopy.levelChip(.out), "Out")
    }

    func testADishNobodyReportedOnIsNotCalledOK() {
        XCTAssertNotEqual(AdminCopy.noReport, "OK")
    }

    // Check a day

    func testAToggleOnCheckADayChangesThatWordAndKeepsTheSlot() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        let more = demo.makeRepositories().adminMore
        let menu = try await more.weekMenu()
        let day = try XCTUnwrap(menu.days.first { $0.wordsToCheck > 0 })
        let model = AdminDayEditViewModel(date: day.day, more: more, role: .admin)
        await model.load()
        let word = try XCTUnwrap(model.wordsToCheck.first)
        let otherSlot = MealSlot.allCases.first { $0 != word.slot } ?? .lunch
        model.slot = otherSlot
        model.toggle(model.toggleHighlight, id: word.dish.id, in: word.slot)
        XCTAssertEqual(model.dish(word.dish.id, in: word.slot)?.isHighlight, !word.dish.isHighlight)
        XCTAssertEqual(model.slot, otherSlot)
    }
}
#endif
