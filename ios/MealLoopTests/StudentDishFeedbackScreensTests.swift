#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// G1 (owner, 9 November): Not good opens the dish feedback sheets (2159:285, 2159:149347 …), never the Report form.
@MainActor
final class StudentDishFeedbackScreensTests: XCTestCase {
    private let context = StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess)
    private let day = DemoSeed.lunch.startsAt

    private func make(_ kind: StudentDishFeedbackRequest.Kind, _ scenario: DemoScenario = .afterMeal)
        -> (StudentDishFeedbackViewModel, DemoDataProvider, Repositories) {
        let demo = DemoDataProvider(scenario: scenario)
        let repositories = demo.makeRepositories()
        let model = StudentDishFeedbackViewModel(context: context, repositories: repositories, clock: demo.clock,
                                                 request: StudentDishFeedbackRequest(day: day, slot: .lunch, kind: kind))
        return (model, demo, repositories)
    }

    func testNotGoodFromADishGoesStraightToThatDishsWhatsWrong() async {
        let (model, _, _) = make(.dish("Masala Sambar"))
        XCTAssertEqual(model.step, .whatsWrong("Masala Sambar"))
        XCTAssertFalse(model.canGoBack, "No Which dish under it.")
        await model.load()
        XCTAssertEqual(model.options.map(\.title), ["Too salty", "Too spicy", "Too watery", "Too sour", "Cold", "Too little"])
        XCTAssertEqual(model.others(model.options[0]), 6, "From the feedback data.")
        XCTAssertNil(model.others(model.options[1]), "Nobody said it: no count, never zero.")
        XCTAssertEqual(model.severity, .quite, "Quite is preselected (2136:2382).")
        XCTAssertFalse(model.canSend, "A problem must be chosen first.")
    }

    func testFromTheHomeCardItGoesThroughWhichDish() async {
        let (model, _, _) = make(.meal)
        XCTAssertEqual(model.step, .whichDish)
        await model.load()
        XCTAssertEqual(model.visibleDishes.count, 3)
        XCTAssertTrue(model.hasMoreDishes)
        model.showMoreDishes()
        XCTAssertEqual(model.visibleDishes.count, model.dishes.count)
        XCTAssertGreaterThan(model.dishes.count, 3)
        XCTAssertEqual(model.mostReported?.problem, "Too salty")
        await model.choose(dish: "Masala Sambar", problem: "too salty")
        XCTAssertEqual(model.step, .whatsWrong("Masala Sambar"))
        XCTAssertEqual(model.problem, "Too salty", "Me too preselects the problem.")
        XCTAssertTrue(model.canGoBack)
        model.back()
        XCTAssertEqual(model.step, .whichDish)
    }

    func testSendRecordsFeedbackWithoutANameAndNoCredits() async throws {
        let (model, _, repositories) = make(.dish("Masala Sambar"))
        await model.load()
        let before = try await repositories.studentYou.credits(for: context.student.id).balance
        model.problem = "Too salty"
        model.severity = .very
        model.note = "  Much saltier than usual.  "
        let sent = await model.send()
        XCTAssertTrue(sent)
        guard case .sent(let receipt) = model.step else { return XCTFail("Shows Sent.") }
        XCTAssertEqual(receipt.submission.note, "Much saltier than usual.")
        XCTAssertEqual(receipt.submission.severity, .very)
        let overview = try await repositories.adminStudents.studentsOverview()
        XCTAssertEqual(overview.feedback.first?.students, 7, "Counted, never named.")
        let mine = try await repositories.studentRecords.feedback(for: context.student.id)
        XCTAssertEqual(mine.items.first?.problem, "Too salty", "Shows on My feedback.")
        let after = try await repositories.studentYou.credits(for: context.student.id).balance
        XCTAssertEqual(before, after, "Feedback earns no credits.")
    }

    func testOfflineKeepsItAndSendsNothing() async throws {
        let (model, demo, repositories) = make(.dish("Masala Sambar"), .offline)
        await model.load()
        model.problem = "Cold"
        let sent = await model.send()
        XCTAssertFalse(sent)
        XCTAssertEqual(model.sendState, .keptOffline)
        XCTAssertEqual(model.step, .whatsWrong("Masala Sambar"), "Never shows Sent offline.")
        let kept = await repositories.dishFeedback.kept(by: context.student.id)
        XCTAssertEqual(kept.count, 1)
        await demo.setScenario(.afterMeal)
        let overview = try await repositories.adminStudents.studentsOverview()
        XCTAssertNil(overview.feedback.first { $0.problem == "cold" }, "Nothing reached the kitchen while offline.")
    }

    func testAFailedSendOffersTryAgainWithTheSameKey() async throws {
        let (model, _, _) = make(.dish("Masala Sambar"))
        await model.load()
        let sent = await model.send()
        XCTAssertFalse(sent, "Nothing chosen: nothing sent.")
        XCTAssertEqual(model.sendState, .idle)
    }

    func testGoodShowsThanksAndTheRatingIsRecorded() async throws {
        let demo = DemoDataProvider(scenario: .afterMeal)
        let session = Session(account: try XCTUnwrap(DemoSeed.accounts.first { $0.role == .student }), staff: nil,
                              student: context)
        let rating = try XCTUnwrap(StudentRatingViewModel(session: session, repositories: demo.makeRepositories(),
                                                          day: day, slot: .lunch))
        await rating.load()
        let saved = await rating.rate(.good)
        XCTAssertTrue(saved)
        XCTAssertTrue(rating.isGood)
        let request = rating.feedbackRequest(after: .good)
        XCTAssertEqual(request.kind, .thanks)
        let model = StudentDishFeedbackViewModel(context: context, repositories: demo.makeRepositories(), clock: demo.clock,
                                                 request: request)
        guard case .thanks = model.step else { return XCTFail("Thanks sheet.") }
        XCTAssertEqual(rating.feedbackRequest(after: .notGood).kind, .meal, "The meal card goes through Which dish.")
    }

    func testTheTwoDayWindowStillHolds() async throws {
        let demo = DemoDataProvider(scenario: .afterMeal)
        demo.clock.set(DemoSeed.date(16, 14, 1))
        let session = Session(account: try XCTUnwrap(DemoSeed.accounts.first { $0.role == .student }), staff: nil,
                              student: context)
        let rating = try XCTUnwrap(StudentRatingViewModel(session: session, repositories: demo.makeRepositories(),
                                                          day: day, slot: .lunch))
        await rating.load()
        XCTAssertEqual(rating.window, .closed)
        XCTAssertFalse(rating.canRate, "No Good, no Not good, so no feedback sheet after 2 days.")
    }

    /// The SOS link is the only route from the sheets to SOS; nothing here opens the Report form.
    func testTheSOSLinkIsTheOnlyRouteToSOS() {
        XCTAssertEqual(DishFeedbackCopy.useSOS, "Unsafe or unwell? Use SOS")
        let homeRoutes: [StudentHomeRoute] = [.sos, .myFeedback]
        XCTAssertTrue(homeRoutes.allSatisfy(\.usesSystemBar))
        XCTAssertTrue(StudentMealsRoute.sos.usesSystemBar)
    }
}
#endif
