#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

private final class ScreensClock: StoryClock, @unchecked Sendable {
    private var current = Date(timeIntervalSince1970: 0)
    func now() -> Date { current }
    func set(_ date: Date) { current = date }
}

/// Forwards to the prototype backend, and can lose the connection on demand.
private final class SwitchableCommunity: StudentCommunityRepository, @unchecked Sendable {
    let source: DemoDataProvider
    var isOffline = false
    var failsSend = false

    init(_ source: DemoDataProvider) { self.source = source }
    private func check() throws { if isOffline { throw RepositoryError.offline(lastSavedAt: nil) } }

    func issues(at mess: MessID, for student: StudentID) async throws -> [StudentIssue] {
        try check(); return try await source.issues(at: mess, for: student)
    }
    func issue(_ id: CommunityIssueID, for student: StudentID) async throws -> StudentIssue {
        try check(); return try await source.issue(id, for: student)
    }
    func back(_ id: CommunityIssueID, by student: StudentID) async throws -> StudentIssue {
        try check(); return try await source.back(id, by: student)
    }
    func unback(_ id: CommunityIssueID, by student: StudentID) async throws -> StudentIssue {
        try check(); return try await source.unback(id, by: student)
    }
    func submitReport(_ report: StudentReportRequest) async throws -> StudentReportReceipt {
        try check()
        if failsSend { throw RepositoryError.notFound }
        return try await source.submitReport(report)
    }
    func isReportDeskStaffed(at mess: MessID) async throws -> Bool { try check(); return try await source.isReportDeskStaffed(at: mess) }
}

/// Community and Report as rebuilt from the Figma frames.
@MainActor
final class StudentCommunityScreensTests: XCTestCase {
    private let longWait = CommunityIssueID("demo-issue-long-wait")

    private var session: Session {
        get throws {
            Session(account: try XCTUnwrap(DemoSeed.accounts.first { $0.role == .student }), staff: nil,
                    student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
        }
    }

    private func make() throws -> (DemoDataProvider, SwitchableCommunity, Repositories, ScreensClock) {
        let clock = ScreensClock()
        let demo = DemoDataProvider(scenario: .storyStart, clock: clock)
        let community = SwitchableCommunity(demo)
        var repositories = demo.makeRepositories()
        repositories.studentCommunity = community
        return (demo, community, repositories, clock)
    }

    func testMeTooOnceThenUndo() async throws {
        let (_, _, repositories, clock) = try make()
        let model = try XCTUnwrap(StudentCommunityViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        XCTAssertEqual(model.issues(fixed: false).count, 2)
        XCTAssertTrue(model.issues(fixed: true).isEmpty)
        await model.meToo(longWait)
        await model.meToo(longWait)
        XCTAssertEqual(model.issue(longWait)?.backers, 65)
        XCTAssertEqual(model.issue(longWait)?.isBackedByMe, true)
        await model.undo(longWait)
        XCTAssertEqual(model.issue(longWait)?.backers, 64)
    }

    func testOfflineMeTooWaitsAndIsNeverShownAsBacked() async throws {
        let (_, community, repositories, clock) = try make()
        let model = try XCTUnwrap(StudentCommunityViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        community.isOffline = true
        await model.meToo(longWait)
        XCTAssertTrue(model.waiting.contains(longWait))
        XCTAssertEqual(model.issue(longWait)?.isBackedByMe, false)
        XCTAssertEqual(model.issue(longWait)?.backers, 64)
        community.isOffline = false
        await model.load()
        XCTAssertTrue(model.waiting.isEmpty)
        XCTAssertEqual(model.issue(longWait)?.backers, 65, "It is counted once the connection is back.")
    }

    func testAnUrgentReportRaisesAnSOSTheDoorScannerSees() async throws {
        let (demo, _, repositories, clock) = try make()
        let model = try XCTUnwrap(StudentReportViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        model.begin()
        let raised = await model.raiseSOS(.foundInFood)
        XCTAssertTrue(raised)
        let again = await model.raiseSOS(.foundInFood)
        XCTAssertTrue(again)
        let cases = try await demo.activeCases(for: DemoSeed.mess.id)
        XCTAssertEqual(cases.count, 1, "A retry never opens a second case.")
        XCTAssertEqual(cases.first?.title, "Found something in my food")
        let issues = try await demo.issues(at: DemoSeed.mess.id, for: DemoSeed.sampleStudent.id)
        XCTAssertEqual(issues.count, 2, "Urgent reports never reach Community.")
    }

    func testAFailedReportKeepsItsTextAndSendsOnceOnRetry() async throws {
        let (demo, community, repositories, clock) = try make()
        let model = try XCTUnwrap(StudentReportViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        model.begin()
        model.note = "Plates at counter 2 were wet and smelled."
        community.failsSend = true
        await model.sendReport(.notClean)
        XCTAssertEqual(model.send, .failed)
        XCTAssertNil(model.receipt)
        XCTAssertEqual(model.note, "Plates at counter 2 were wet and smelled.")
        community.failsSend = false
        await model.sendReport(.notClean)
        await model.sendReport(.notClean)
        XCTAssertEqual(model.receipt?.reference, "ML-1042")
        let count = try await demo.issues(at: DemoSeed.mess.id, for: DemoSeed.sampleStudent.id).count
        XCTAssertEqual(count, 3)
    }

    func testTheMealOnTheReportIsTheOneAtHand() async throws {
        let (_, _, repositories, clock) = try make()
        let model = try XCTUnwrap(StudentReportViewModel(session: try session, repositories: repositories, clock: clock))
        await model.load()
        XCTAssertEqual(model.meal?.slot, .breakfast, "At 7:00 AM breakfast is the next meal to start.")
        XCTAssertTrue(model.isDeskStaffed)
    }
}
#endif
