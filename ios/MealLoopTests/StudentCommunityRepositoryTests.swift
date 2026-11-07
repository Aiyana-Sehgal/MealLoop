#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

private final class CommunityClock: StoryClock, @unchecked Sendable {
    private var current = Date(timeIntervalSince1970: 0)
    func now() -> Date { current }
    func set(_ date: Date) { current = date }
}

/// The additive Student Community and report operations on the prototype backend.
final class StudentCommunityRepositoryTests: XCTestCase {
    private let aarav = DemoSeed.sampleStudent.id
    private let meera = StudentID("demo-student-0412")
    private let mess = DemoSeed.mess.id
    private let longWait = CommunityIssueID("demo-issue-long-wait")

    private func make(_ scenario: DemoScenario = .storyStart) -> (DemoDataProvider, CommunityClock) {
        let clock = CommunityClock()
        return (DemoDataProvider(scenario: scenario, clock: clock), clock)
    }

    private func report(_ category: StudentReportCategory, note: String? = nil, key: String = "r1") -> StudentReportRequest {
        StudentReportRequest(student: aarav, messID: mess, category: category, note: note, place: "Main Mess · Block A",
                             meal: .lunch, idempotencyKey: IdempotencyKey(key))
    }

    func testTheDrawnProblemsNewestFirstWithTheirCounts() async throws {
        let (demo, _) = make()
        let issues = try await demo.issues(at: mess, for: aarav)
        XCTAssertEqual(issues.map(\.title), ["Long wait at counter 3 after 1 PM", "Sambar too watery at dinner"])
        XCTAssertEqual(issues.map(\.backers), [64, 38])
        XCTAssertEqual(issues.map(\.stage), [.seen, .fixing])
        XCTAssertFalse(issues.contains { $0.isBackedByMe })
        XCTAssertFalse(issues.contains { $0.stage == .fixed }, "Nothing is fixed yet, as Community · Fixed · Empty draws.")
    }

    func testMeTooCountsOncePerStudentPerProblem() async throws {
        let (demo, _) = make()
        let once = try await demo.back(longWait, by: aarav)
        XCTAssertEqual(once.backers, 65)
        XCTAssertTrue(once.isBackedByMe)
        let twice = try await demo.back(longWait, by: aarav)
        XCTAssertEqual(twice.backers, 65, "Backing again changes nothing.")
        let other = try await demo.back(longWait, by: meera)
        XCTAssertEqual(other.backers, 66)
        let undone = try await demo.unback(longWait, by: aarav)
        XCTAssertEqual(undone.backers, 65)
        XCTAssertFalse(undone.isBackedByMe)
    }

    func testAReportThatPassesTheChecksIsPublishedWithoutTheStudentsName() async throws {
        let (demo, _) = make()
        let receipt = try await demo.submitReport(report(.notClean, note: "Plates at counter 2 were wet and smelled."))
        XCTAssertEqual(receipt.reference, "ML-1042")
        guard case .published(let id) = receipt.outcome else { return XCTFail("Published") }
        let issue = try await demo.issue(id, for: meera)
        XCTAssertEqual(issue.title, "Plates at counter 2 were wet and smelled.")
        XCTAssertEqual(issue.backers, 1, "The reporter counts once.")
        XCTAssertEqual(issue.stage, .reported)
        XCTAssertFalse(issue.title.contains("Aarav"))
        let mine = try await demo.back(id, by: aarav)
        XCTAssertEqual(mine.backers, 1, "The reporter backing their own report does not count twice.")
    }

    func testAReportNamingAPersonOrANumberIsHeldNotPublished() async throws {
        let (demo, _) = make()
        let named = try await demo.submitReport(report(.staffOrService, note: "Ravi shouted at us", key: "n"))
        XCTAssertEqual(named.outcome, .heldForReview(reason: DemoSeed.heldForNamingReason))
        let phone = try await demo.submitReport(report(.somethingElse, note: "Call me on 9876543210", key: "p"))
        XCTAssertEqual(phone.outcome, .heldForReview(reason: DemoSeed.heldForPhoneReason))
        let issues = try await demo.issues(at: mess, for: aarav)
        XCTAssertEqual(issues.count, 2, "Held reports are not public.")
    }

    func testTheSameKeyReturnsTheFirstReceipt() async throws {
        let (demo, _) = make()
        let first = try await demo.submitReport(report(.ranOut))
        let again = try await demo.submitReport(report(.ranOut))
        XCTAssertEqual(first, again)
        let count = try await demo.issues(at: mess, for: aarav).count
        XCTAssertEqual(count, 3)
    }

    func testAnUrgentReportNeverEntersCommunityAndRaisesAnSOSTheStaffSee() async throws {
        let (demo, _) = make()
        do {
            _ = try await demo.submitReport(report(.foundInFood))
            XCTFail("Urgent reports go to SOS")
        } catch RepositoryError.notAllowed {}
        _ = try await demo.raise(SOSReport(messID: mess, title: StudentReportCategoryTitle.title(.foundInFood),
                                           place: "Main Mess · Block A", idempotencyKey: IdempotencyKey("sos")))
        let cases = try await demo.activeCases(for: mess)
        XCTAssertEqual(cases.map(\.title), ["Found something in my food"], "The Door Scanner and Supervisor read these cases.")
        let issues = try await demo.issues(at: mess, for: aarav)
        XCTAssertEqual(issues.count, 2)
    }

    func testOfflineNothingIsSentOrBacked() async throws {
        let (demo, _) = make(.offline)
        do {
            _ = try await demo.submitReport(report(.notClean))
            XCTFail("Offline must throw")
        } catch RepositoryError.offline {}
        do {
            _ = try await demo.back(longWait, by: aarav)
            XCTFail("Offline must throw")
        } catch RepositoryError.offline {}
    }

    func testNoOneReadsReportsBeforeTheMessOpens() async throws {
        let (demo, clock) = make()
        let open = try await demo.isReportDeskStaffed(at: mess)
        XCTAssertTrue(open)
        clock.set(DemoSeed.time(6, 30))
        let early = try await demo.isReportDeskStaffed(at: mess)
        XCTAssertFalse(early)
    }
}
#endif
