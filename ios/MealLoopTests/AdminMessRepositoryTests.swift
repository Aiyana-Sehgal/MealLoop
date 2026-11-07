#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

final class AdminMessRepositoryTests: XCTestCase {
    private func repository() async -> (DemoDataProvider, any AdminMessRepository) {
        let demo = DemoDataProvider(scenario: .storyStart)
        return (demo, demo.makeRepositories().adminMesses)
    }

    func testLunchHoldsTheThreeOtherMessesAndAnnexeHasNoData() async throws {
        let (_, messes) = await repository()
        let day = try await messes.messDay(for: .lunch)
        XCTAssertEqual(day.messes.map(\.name), ["North", "South", "Annexe"])
        XCTAssertEqual(day.messes[0].expected, 700)
        XCTAssertEqual(day.messes[1].reply, .noReply)
        XCTAssertNil(day.messes[2].expected, "No data is nil, never zero")
    }

    func testAMealNoFrameDrawsIsMissingForEveryMess() async throws {
        let (_, messes) = await repository()
        let day = try await messes.messDay(for: .snacks)
        XCTAssertEqual(day.messes.count, 3)
        XCTAssertTrue(day.messes.allSatisfy { $0.expected == nil && $0.sentAt == nil })
    }

    func testSendingWaitsForTheVendorAndNeverReadsAsReplied() async throws {
        let (_, messes) = await repository()
        let sent = try await messes.sendHeadcount(mess: "North", slot: .lunch, key: IdempotencyKey("a"), by: .admin)
        XCTAssertEqual(sent.reply, .waiting)
        XCTAssertNotNil(sent.sentAt)
        XCTAssertFalse(sent.canSend)
    }

    func testARepeatedKeyChangesNothing() async throws {
        let (_, messes) = await repository()
        let key = IdempotencyKey("same")
        let first = try await messes.sendHeadcount(mess: "North", slot: .lunch, key: key, by: .admin)
        let second = try await messes.sendHeadcount(mess: "North", slot: .lunch, key: key, by: .admin)
        XCTAssertEqual(first, second)
    }

    func testOnlyTheFoodHeadCanSend() async throws {
        let (_, messes) = await repository()
        do {
            _ = try await messes.sendHeadcount(mess: "North", slot: .lunch, key: IdempotencyKey("b"), by: .supervisor)
            XCTFail("A supervisor must not send")
        } catch RepositoryError.notAllowed {}
    }

    func testNothingCanBeSentForAMessWithNoData() async throws {
        let (_, messes) = await repository()
        do {
            _ = try await messes.sendHeadcount(mess: "Annexe", slot: .lunch, key: IdempotencyKey("c"), by: .admin)
            XCTFail("No data, so nothing to send")
        } catch RepositoryError.notAllowed {}
    }

    func testAChangedNumberNeedsAReason() async throws {
        let (_, messes) = await repository()
        do {
            _ = try await messes.adjustHeadcount(mess: "North", slot: .lunch, to: 720, reason: " ", by: .admin)
            XCTFail("A reason is required")
        } catch RepositoryError.validationFailed {}
        let saved = try await messes.adjustHeadcount(mess: "North", slot: .lunch, to: 720, reason: "Event", by: .admin)
        XCTAssertEqual(saved.expected, 720)
        XCTAssertEqual(saved.adjustmentReason, "Event")
    }

    func testAMealWithNoHistoryHasNoUsualCount() async throws {
        let (_, messes) = await repository()
        let lunch = try await messes.liveReference(for: DemoSeed.lunch.id)
        let breakfast = try await messes.liveReference(for: DemoSeed.breakfast.id)
        XCTAssertEqual(lunch.usualByNow, 690)
        XCTAssertNil(breakfast.usualByNow)
    }

    func testNotAnsweredByMessAddsUpToTheStudentsOverview() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        let repositories = demo.makeRepositories()
        let byMess = try await repositories.adminMesses.notAnsweredByMess()
        let overview = try await repositories.adminStudents.studentsOverview()
        XCTAssertEqual(byMess.map(\.students).reduce(0, +), overview.notAnswered)
    }

    func testASourceWithNoMessDataSaysSo() async {
        do {
            _ = try await AdminMessesNotBuilt().messDay(for: .lunch)
            XCTFail("Must not pretend")
        } catch RepositoryError.notImplemented {
        } catch {
            XCTFail("Wrong error \(error)")
        }
    }
}
#endif
