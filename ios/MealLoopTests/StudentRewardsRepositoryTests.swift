#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The additive reward tickets: the cost comes off the Credits balance, which never goes below zero.
final class StudentRewardsRepositoryTests: XCTestCase {
    private let aarav = DemoSeed.sampleStudent.id
    private let stranger = StudentID("demo-student-unknown")

    private func make(_ scenario: DemoScenario = .storyStart) -> Repositories {
        DemoDataProvider(scenario: scenario).makeRepositories()
    }

    func testGettingAJuiceTakesItsCostAndAddsAHistoryLine() async throws {
        let repositories = make()
        let before = try await repositories.studentYou.credits(for: aarav)
        XCTAssertEqual(before.balance, 120, "Credits 221:64313")
        let ticket = try await repositories.studentRewards.getTicket("juice", for: aarav)
        XCTAssertEqual(ticket.cost, 50)
        XCTAssertEqual(ticket.balanceAfter, 70, "Ticket · Juice 1529:1901: 50 pts used · 70 left")
        XCTAssertEqual(ticket.code, "7A3F")
        XCTAssertFalse(ticket.isUsed)
        let after = try await repositories.studentYou.credits(for: aarav)
        XCTAssertEqual(after.balance, 70)
        XCTAssertEqual(after.history.first?.title, "Juice redeemed")
        XCTAssertEqual(after.history.first?.points, -50)
    }

    func testTheBalanceNeverGoesBelowZero() async throws {
        let repositories = make()
        _ = try await repositories.studentRewards.getTicket("ice-cream", for: aarav) // 120 → 40
        do {
            _ = try await repositories.studentRewards.getTicket("juice", for: aarav)
            XCTFail("40 does not cover 50.")
        } catch RepositoryError.notAllowed {}
        let credits = try await repositories.studentYou.credits(for: aarav)
        XCTAssertEqual(credits.balance, 40, "Nothing was taken by the refused ticket.")
    }

    func testATicketNotOfferedYetAndAnUnknownBalanceAreRefused() async throws {
        let repositories = make()
        do {
            _ = try await repositories.studentRewards.getTicket("biryani-coupon", for: aarav)
            XCTFail("Launches Friday.")
        } catch RepositoryError.notAllowed {}
        do {
            _ = try await repositories.studentRewards.getTicket("juice", for: stranger)
            XCTFail("No balance is known for this student.")
        } catch RepositoryError.notAllowed {}
    }

    func testTheCounterUsesATicketOnce() async throws {
        let repositories = make()
        let ticket = try await repositories.studentRewards.getTicket("juice", for: aarav)
        let used = try await repositories.studentRewards.recordCounterUse(of: ticket.id, for: aarav)
        XCTAssertNotNil(used.usedAt)
        let reread = try await repositories.studentRewards.ticket(ticket.id, for: aarav)
        XCTAssertTrue(reread.isUsed)
        do {
            _ = try await repositories.studentRewards.recordCounterUse(of: ticket.id, for: aarav)
            XCTFail("A used ticket is not used again.")
        } catch RepositoryError.notAllowed {}
    }

    func testABalanceIssueIsRecordedAndAnEmptyOneRefused() async throws {
        let repositories = make()
        let receipt = try await repositories.studentRewards.reportBalanceIssue("  Missing pts from Fri 9 Aug ", for: aarav)
        XCTAssertEqual(receipt.text, "Missing pts from Fri 9 Aug")
        do {
            _ = try await repositories.studentRewards.reportBalanceIssue("   ", for: aarav)
            XCTFail("Empty.")
        } catch RepositoryError.validationFailed {}
    }

    func testOfflineTakesNothing() async throws {
        let repositories = make(.offline)
        do {
            _ = try await repositories.studentRewards.getTicket("juice", for: aarav)
            XCTFail("Offline never gets a ticket.")
        } catch RepositoryError.offline {}
    }
}
#endif
