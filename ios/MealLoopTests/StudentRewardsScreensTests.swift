#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// Credits Get to the reward ticket, read from the prototype backend.
@MainActor
final class StudentRewardsScreensTests: XCTestCase {
    private var session: Session {
        get throws {
            Session(account: try XCTUnwrap(DemoSeed.accounts.first { $0.role == .student }), staff: nil,
                    student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
        }
    }

    private func make(_ scenario: DemoScenario = .storyStart) throws -> (Repositories, StudentRewardsViewModel) {
        let demo = DemoDataProvider(scenario: scenario)
        let repositories = demo.makeRepositories()
        let model = try XCTUnwrap(StudentRewardsViewModel(session: try session, repositories: repositories, clock: demo.clock))
        return (repositories, model)
    }

    func testGetOpensTheTicketAndNoLongerSaysComingSoon() async throws {
        let (_, model) = try make()
        let id = try await XCTUnwrapAsync(await model.get("juice"))
        XCTAssertNil(model.getting)
        XCTAssertNil(model.failedReward)
        XCTAssertEqual(model.ticket.value?.id, id)
        XCTAssertEqual(model.ticket.value?.balanceAfter, 70)
        XCTAssertTrue(StudentHomeRoute.rewardTicket(id).usesSystemBar)
        XCTAssertTrue(StudentYouRoute.credits.usesSystemBar)
    }

    func testARefusedTicketShowsTheFailedStateAndTakesNothing() async throws {
        let (repositories, model) = try make()
        let none = await model.get("biryani-coupon")
        XCTAssertNil(none)
        XCTAssertEqual(model.failedReward, "biryani-coupon", "Credits · Failed 221:65873")
        let credits = try await repositories.studentYou.credits(for: DemoSeed.sampleStudent.id)
        XCTAssertEqual(credits.balance, 120, "Your points are safe.")
    }

    func testTheTicketShowsUsedAfterTheCounterRecordsIt() async throws {
        let (repositories, model) = try make()
        let id = try await XCTUnwrapAsync(await model.get("juice"))
        _ = try await repositories.studentRewards.recordCounterUse(of: id, for: DemoSeed.sampleStudent.id)
        await model.loadTicket(id)
        XCTAssertEqual(model.ticket.value?.isUsed, true, "Ticket · Juice · Used 1529:2180")
    }

    func testABalanceQuestionIsRecorded() async throws {
        let (_, model) = try make()
        await model.reportBalanceIssue("Missing pts from Fri 9 Aug")
        XCTAssertEqual(model.balanceSend, .sent)
    }

    private func XCTUnwrapAsync<T>(_ value: T?) async throws -> T { try XCTUnwrap(value) }
}
#endif
