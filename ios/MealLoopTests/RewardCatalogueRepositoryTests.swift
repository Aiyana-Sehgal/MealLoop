#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The Admin's reward catalogue, which the Student Credits screen reads.
final class RewardCatalogueRepositoryTests: XCTestCase {
    private let aarav = DemoSeed.sampleStudent.id

    func testAnAddedRewardShowsInCreditsAtOnce() async throws {
        let repositories = DemoDataProvider().makeRepositories()
        let coffee = try await repositories.rewardCatalogue.add(name: "  Coffee ", cost: 30, by: .admin)
        XCTAssertEqual(coffee.name, "Coffee")
        let credits = try await repositories.studentYou.credits(for: aarav)
        XCTAssertTrue(credits.tickets.contains { $0.id == coffee.id && $0.cost == 30 })
        let ticket = try await repositories.studentRewards.getTicket(coffee.id, for: aarav)
        XCTAssertEqual(ticket.balanceAfter, 90)
    }

    func testADeletedRewardLeavesCreditsAndTicketsGotStayValid() async throws {
        let repositories = DemoDataProvider().makeRepositories()
        let got = try await repositories.studentRewards.getTicket("juice", for: aarav)
        try await repositories.rewardCatalogue.delete("juice", by: .superAdmin)
        let credits = try await repositories.studentYou.credits(for: aarav)
        XCTAssertFalse(credits.tickets.contains { $0.id == "juice" })
        let still = try await repositories.studentRewards.ticket(got.id, for: aarav)
        XCTAssertFalse(still.isUsed, "A ticket already got stays valid.")
        do {
            try await repositories.rewardCatalogue.delete("juice", by: .admin)
            XCTFail("Already deleted.")
        } catch RepositoryError.notFound {}
    }

    func testAnEmptyNameOrANonPositiveCostIsRefused() async throws {
        let catalogue = DemoDataProvider().makeRepositories().rewardCatalogue
        for (name, cost) in [("", 30), ("Tea", 0), ("Tea", -5)] {
            do {
                _ = try await catalogue.add(name: name, cost: cost, by: .admin)
                XCTFail("Refused: \(name) \(cost)")
            } catch RepositoryError.validationFailed {}
        }
        let items = try await catalogue.items()
        XCTAssertEqual(items.count, DemoSeed.sampleCreditTickets.count)
    }

    func testOnlyTheAdminManagesRewards() async throws {
        let catalogue = DemoDataProvider().makeRepositories().rewardCatalogue
        do {
            _ = try await catalogue.add(name: "Tea", cost: 20, by: .supervisor)
            XCTFail("Supervisor.")
        } catch RepositoryError.notAllowed {}
    }
}
#endif
