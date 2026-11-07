#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The additive Student records operations on the prototype backend.
final class StudentRecordsRepositoryTests: XCTestCase {
    private let aarav = DemoSeed.sampleStudent.id
    private let stranger = StudentID("demo-student-unknown")
    private let needInfo = StudentFiledReportID("demo-report-1031")
    private let fixed = StudentFiledReportID("demo-report-0998")

    private func make(_ scenario: DemoScenario = .storyStart) -> any StudentRecordsRepository {
        DemoDataProvider(scenario: scenario).makeRepositories().studentRecords
    }

    func testReportsListActiveFirstThenClosed() async throws {
        let reports = try await make().reports(for: aarav)
        XCTAssertEqual(reports.map(\.reference), ["ML-1031", "ML-1017", "ML-0998"])
        XCTAssertEqual(reports.map(\.stage), [.needMoreInfo, .workingOnIt, .fixed])
        XCTAssertEqual(reports.map(\.stage.step), [2, 3, 4])
    }

    func testAReplyIsRecordedOnTheTimelineAndTheStageStays() async throws {
        let records = make()
        let replied = try await records.reply(to: needInfo, text: "  Counter 3 ", by: aarav)
        XCTAssertEqual(replied.reply, "Counter 3")
        XCTAssertEqual(replied.stage, .needMoreInfo, "Only the mess moves the report on.")
        XCTAssertEqual(replied.events.last?.kind, .replied("Counter 3"))
        let again = try await records.reply(to: needInfo, text: "Counter 4", by: aarav)
        XCTAssertEqual(again.reply, "Counter 3", "The first reply stays.")
        let reread = try await records.report(needInfo, for: aarav)
        XCTAssertEqual(reread.reply, "Counter 3")
    }

    func testAFixedReportTakesNoReplyAndAnEmptyReplyIsRefused() async {
        let records = make()
        do {
            _ = try await records.reply(to: fixed, text: "Hello", by: aarav)
            XCTFail("A fixed report is read only.")
        } catch {}
        do {
            _ = try await records.reply(to: needInfo, text: "   ", by: aarav)
            XCTFail("An empty reply is refused.")
        } catch {}
    }

    func testOfflineNeverRecordsAReply() async throws {
        let records = make(.offline)
        do {
            _ = try await records.reply(to: needInfo, text: "Counter 3", by: aarav)
            XCTFail("Offline must throw.")
        } catch RepositoryError.offline {}
    }

    func testFeedbackCountsAreComputedFromTheItems() async throws {
        let summary = try await make().feedback(for: aarav)
        XCTAssertEqual(summary.total, 3)
        XCTAssertEqual(summary.fixed, 1)
        XCTAssertEqual(summary.withTheKitchen, 1)
    }

    func testARecheckAnswerIsKeptOnceAndOnlyForAFixedDish() async throws {
        let records = make()
        let sambar = StudentFeedbackID("demo-feedback-sambar")
        let first = try await records.answerRecheck(sambar, .better, by: aarav)
        XCTAssertEqual(first.items.first { $0.id == sambar }?.recheck, .better)
        let second = try await records.answerRecheck(sambar, .same, by: aarav)
        XCTAssertEqual(second.items.first { $0.id == sambar }?.recheck, .better)
        do {
            _ = try await records.answerRecheck(StudentFeedbackID("demo-feedback-pulao"), .better, by: aarav)
            XCTFail("Not fixed yet.")
        } catch {}
    }

    func testSpendingTotalsTheWeeksAndAMissingWeekIsNeverZero() async throws {
        let spending = try await make().spending(for: aarav)
        XCTAssertEqual(spending.monthTotal, 3000)
        XCTAssertEqual(spending.thisWeek, 500)
        let partial = StudentSpending(weeks: [StudentSpendingWeek(start: .distantPast, end: .distantPast, amount: 100, isCurrent: false),
                                              StudentSpendingWeek(start: .now, end: .now, amount: nil, isCurrent: true)],
                                      recent: [])
        XCTAssertNil(partial.monthTotal, "A missing week makes the total unknown, not smaller.")
        XCTAssertNil(partial.thisWeek)
        let none = try await make().spending(for: stranger)
        XCTAssertNil(none.monthTotal)
    }

    func testHelpHasOnlyTheDrawnAnswer() async throws {
        let help = try await make().help(at: DemoSeed.mess.id)
        XCTAssertEqual(help.topics.count, 5)
        XCTAssertEqual(help.topics.compactMap(\.answer).count, 1)
        XCTAssertNotNil(help.contact)
    }

    func testIssueUpdatesComeFromTheSeedAndOthersHaveNone() async throws {
        let records = make()
        let wait = try await records.updates(for: CommunityIssueID("demo-issue-long-wait"))
        XCTAssertEqual(wait.map(\.isNext), [false, true])
        XCTAssertEqual(wait.first?.title, "Seen by the team")
        let sambar = try await records.updates(for: CommunityIssueID("demo-issue-watery-sambar"))
        XCTAssertTrue(sambar.isEmpty)
    }

    func testTheUnavailableSourceNeverFakesAResult() async {
        do {
            _ = try await UnavailableStudentRecords().reports(for: aarav)
            XCTFail("Must throw.")
        } catch RepositoryError.notImplemented {} catch { XCTFail("\(error)") }
    }
}
#endif
