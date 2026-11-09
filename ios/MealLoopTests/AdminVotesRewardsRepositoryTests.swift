#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The additive menu-vote decisions, proposals and redemptions.
final class AdminVotesRewardsRepositoryTests: XCTestCase {
    private func make(_ scenario: DemoScenario = .storyStart) -> any AdminVotesRewardsRepository {
        DemoDataProvider(scenario: scenario).makeRepositories().adminVotesRewards
    }

    func testADecisionIsRecordedAndReplacedOnlyByTheAdmin() async throws {
        let repo = make()
        let none = try await repo.decision()
        XCTAssertNil(none, "Advice only: nothing is decided until the admin decides.")
        _ = try await repo.decide(.addToMenu, by: .superAdmin)
        let changed = try await repo.decide(.notNow, by: .admin)
        let stored = try await repo.decision()
        XCTAssertEqual(stored, changed)
        do {
            _ = try await repo.decide(.addToMenu, by: .supervisor)
            XCTFail("Only the admin decides.")
        } catch RepositoryError.notAllowed {}
    }

    func testAProposalIsAnsweredOnceAndNamesNoStudent() async throws {
        let repo = make()
        let list = try await repo.proposals()
        XCTAssertEqual(list.counted, 3)
        let dosa = try XCTUnwrap(list.proposals.first)
        XCTAssertEqual(dosa.askedCount, 212)
        let opened = try await repo.respond(to: dosa.id, .voteOpened, by: .superAdmin)
        XCTAssertEqual(opened.response, .voteOpened)
        do {
            _ = try await repo.respond(to: dosa.id, .declined, by: .superAdmin)
            XCTFail("Answered once.")
        } catch RepositoryError.notAllowed {}
        let reread = try await repo.proposals()
        XCTAssertEqual(reread.proposals.first?.response, .voteOpened)
    }

    func testRedemptionsAreCountsFromTheRewardsFrame() async throws {
        let summary = try await make().redemptions()
        XCTAssertEqual(summary.lines.map(\.count), [63, 12, 0])
        XCTAssertEqual(summary.total, 75)
    }

    func testOfflineRecordsNothing() async throws {
        do {
            _ = try await make(.offline).decide(.addToMenu, by: .superAdmin)
            XCTFail("Offline.")
        } catch RepositoryError.offline {}
    }
}
#endif
