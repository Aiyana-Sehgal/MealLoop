#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// My reports, a report page, My feedback, Spending, Help, the Issue updates and the Home credits chip, read from the
/// prototype backend.
@MainActor
final class StudentRecordsScreensTests: XCTestCase {
    private var session: Session {
        get throws {
            Session(account: try XCTUnwrap(DemoSeed.accounts.first { $0.role == .student }), staff: nil,
                    student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
        }
    }

    private func make(_ scenario: DemoScenario = .storyStart) throws -> (DemoDataProvider, StudentRecordsViewModel) {
        let demo = DemoDataProvider(scenario: scenario)
        let model = try XCTUnwrap(StudentRecordsViewModel(session: try session, repositories: demo.makeRepositories(),
                                                          clock: demo.clock))
        return (demo, model)
    }

    func testEveryYouRowOpensItsOwnPage() {
        let routes: [StudentYouRoute] = [.outings, .credits, .attendance, .spending, .myFeedback, .help, .privacy]
        XCTAssertEqual(Set(routes).count, routes.count)
        for route in [StudentYouRoute.spending, .myFeedback, .help, .privacy] {
            XCTAssertNotEqual(route, .comingSoon(YouCopy.spending))
            XCTAssertNotEqual(route, .comingSoon(YouCopy.myFeedback))
            XCTAssertNotEqual(route, .comingSoon(YouCopy.help))
            XCTAssertNotEqual(route, .comingSoon(YouCopy.terms))
        }
    }

    func testMyReportsSplitsActiveAndClosed() async throws {
        let (_, model) = try make()
        await model.loadReports()
        XCTAssertEqual(model.activeReports.map(\.reference), ["ML-1031", "ML-1017"])
        XCTAssertEqual(model.closedReports.map(\.reference), ["ML-0998"])
    }

    func testAReplyIsShownAsRecordedOnlyAfterTheRepositoryRecordsIt() async throws {
        let (_, model) = try make()
        let id = StudentFiledReportID("demo-report-1031")
        await model.loadReport(id)
        XCTAssertNil(model.report.value?.reply)
        let recorded = await model.reply("Counter 3", to: id)
        XCTAssertTrue(recorded)
        XCTAssertEqual(model.report.value?.reply, "Counter 3")
        XCTAssertEqual(model.replySend, .idle)
    }

    func testAnOfflineReplyIsNeverShownAsRecorded() async throws {
        let (_, model) = try make(.offline)
        let id = StudentFiledReportID("demo-report-1031")
        let recorded = await model.reply("Counter 3", to: id)
        XCTAssertFalse(recorded)
        XCTAssertNil(model.report.value?.reply)
        if case .failed = model.replySend {} else { XCTFail("Offline must show a failure, not a recorded reply.") }
    }

    func testMyFeedbackCountsAndARecheckAnswer() async throws {
        let (_, model) = try make()
        await model.loadFeedback()
        XCTAssertEqual(model.feedback.value?.total, 3)
        let sambar = StudentFeedbackID("demo-feedback-sambar")
        await model.answerRecheck(sambar, .better)
        XCTAssertEqual(model.feedback.value?.items.first { $0.id == sambar }?.recheck, .better)
    }

    func testSpendingAndHelpLoadFromTheRepository() async throws {
        let (_, model) = try make()
        await model.loadSpending()
        XCTAssertEqual(model.spending.value?.monthTotal, 3000)
        await model.loadHelp()
        XCTAssertEqual(model.help.value?.topics.first?.answer?.isEmpty, false)
        XCTAssertNil(model.help.value?.topics.last?.answer, "An answer the frame does not draw is not written.")
    }

    func testOfflineSpendingIsNeverAnEmptyResult() async throws {
        let (_, model) = try make(.offline)
        await model.loadSpending()
        guard case .offline(let saved, _) = model.spending else { return XCTFail("Expected the offline state.") }
        XCTAssertNil(saved)
    }

    func testIssueUpdatesLoadForTheWaitingProblemOnly() async throws {
        let (_, model) = try make()
        await model.loadUpdates(for: CommunityIssueID("demo-issue-long-wait"))
        XCTAssertEqual(model.updates.count, 2)
        await model.loadUpdates(for: CommunityIssueID("demo-issue-watery-sambar"))
        XCTAssertTrue(model.updates.isEmpty)
    }

    /// Owner ruling (7 November): Home's chip, You and Credits show the same number.
    func testTheHomeChipBalanceIsTheStudentYouBalance() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        let you = try XCTUnwrap(StudentYouViewModel(session: try session, repositories: demo.makeRepositories(), clock: demo.clock))
        _ = try await demo.setIntention(.attending, of: DemoSeed.sampleStudent.id, for: DemoSeed.lunch.id)
        await you.loadCredits()
        await you.loadProfile()
        XCTAssertEqual(you.credits.value?.balance, 125)
        XCTAssertEqual(you.profile.value?.credits, you.credits.value?.balance)
    }
}
#endif
