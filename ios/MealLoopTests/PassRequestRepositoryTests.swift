#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// Special pass approval for next week: a request never unlocks the pass; only the Admin decides.
final class PassRequestRepositoryTests: XCTestCase {
    private let aarav = DemoSeed.sampleStudent
    private let nextMonday = DemoSeed.date(19, 12, 0)

    private func make() -> any PassRequestRepository { DemoDataProvider().makeRepositories().passRequests }

    func testARequestWaitsAndDoesNotUnlockThePass() async throws {
        let repo = make()
        let none = try await repo.status(for: aarav.id)
        XCTAssertNil(none)
        let request = try await repo.request(for: aarav, at: DemoSeed.mess)
        XCTAssertEqual(request.state, .pending)
        XCTAssertEqual(request.maskedID, aarav.maskedID)
        let usable = try await repo.isPassUsable(for: aarav.id, on: nextMonday)
        XCTAssertFalse(usable, "A request alone never unlocks the pass.")
        do {
            _ = try await repo.request(for: aarav, at: DemoSeed.mess)
            XCTFail("One request at a time.")
        } catch RepositoryError.notAllowed {}
    }

    func testCancelRemovesTheWaitingRequest() async throws {
        let repo = make()
        _ = try await repo.request(for: aarav, at: DemoSeed.mess)
        try await repo.cancel(for: aarav.id)
        let none = try await repo.status(for: aarav.id)
        XCTAssertNil(none)
        let queue = try await repo.queue(by: .admin)
        XCTAssertFalse(queue.pending.contains { $0.student == aarav.id })
    }

    func testTheAdminAcceptsAndThePassIsUsableOnlyInThatWeek() async throws {
        let repo = make()
        let request = try await repo.request(for: aarav, at: DemoSeed.mess)
        let accepted = try await repo.accept(request.id, by: .admin)
        XCTAssertEqual(accepted.state, .accepted)
        let monday = try await repo.isPassUsable(for: aarav.id, on: nextMonday)
        XCTAssertTrue(monday)
        let weekAfter = try await repo.isPassUsable(for: aarav.id, on: DemoSeed.date(26, 12, 0))
        XCTAssertFalse(weekAfter, "Only in that week.")
        let queue = try await repo.queue(by: .superAdmin)
        XCTAssertEqual(queue.approvedCount, 1)
    }

    func testADeclinedRequestCanBeAskedAgain() async throws {
        let repo = make()
        let request = try await repo.request(for: aarav, at: DemoSeed.mess)
        _ = try await repo.decline(request.id, by: .superAdmin)
        let status = try await repo.status(for: aarav.id)
        XCTAssertEqual(status?.state, .declined)
        let again = try await repo.request(for: aarav, at: DemoSeed.mess)
        XCTAssertEqual(again.state, .pending)
    }

    func testAStudentOrStaffRoleCannotDecide() async throws {
        let repo = make()
        let request = try await repo.request(for: aarav, at: DemoSeed.mess)
        for role in [Role.student, .supervisor, .passDesk] {
            do {
                _ = try await repo.accept(request.id, by: role)
                XCTFail("\(role) cannot decide.")
            } catch RepositoryError.notAllowed {}
        }
    }

    func testThisWeeksSeededPassStaysAvailableAndTheQueueShowsMaskedIDsOnly() async throws {
        let repo = make()
        let today = try await repo.isPassUsable(for: aarav.id, on: DemoSeed.time(12, 30))
        XCTAssertTrue(today)
        let queue = try await repo.queue(by: .admin)
        XCTAssertEqual(queue.pending.map(\.maskedID), ["••0412", "••0377", "••0190"])
        XCTAssertTrue(queue.pending.allSatisfy { $0.maskedID.hasPrefix("••") })
    }
}
#endif
