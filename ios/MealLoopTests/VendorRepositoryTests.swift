#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The vendor read against the prototype backend and the story clock.
final class VendorRepositoryTests: XCTestCase {
    private func vendorID() throws -> AccountID { try XCTUnwrap(DemoSeed.accounts.first { $0.role == .vendor }).id }
    private func foodHeadID() throws -> AccountID { try XCTUnwrap(DemoSeed.accounts.first { $0.role == .admin }).id }

    func testTheVendorReadsItsOwnMess() async throws {
        let mess = try await DemoDataProvider().vendorMess(for: try vendorID())
        XCTAssertEqual(mess, DemoSeed.mess)
    }

    func testAnotherAccountCannotReadTheVendorView() async throws {
        do {
            _ = try await DemoDataProvider().vendorHistory(for: try foodHeadID())
            XCTFail("Only the vendor account reads it")
        } catch {
            guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testBeforeApprovalOnlyTheSampleBreakfastIsThereAndItsReplyWaitsForTheClock() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        let early = try await demo.vendorHistory(for: try vendorID())
        XCTAssertEqual(early.map(\.meal.id), [DemoSeed.breakfast.id], "Lunch is not sent, so it is not listed")
        XCTAssertEqual(early.first?.sentCount, DemoSeed.vendorBreakfastSentCount)
        XCTAssertNil(early.first?.acknowledgedAt, "At 7:00 AM the 7:05 reply has not happened: Pending, not filled in")
        XCTAssertNil(early.first?.sentAt, "The pack gives no send time")
        XCTAssertEqual(early.first?.isSample, true)
        demo.clock.set(DemoSeed.vendorBreakfastRepliedAt)
        let later = try await demo.vendorHistory(for: try vendorID())
        XCTAssertEqual(later.first?.acknowledgedAt, DemoSeed.vendorBreakfastRepliedAt)
    }

    func testLunchAppearsOnceSentAndCarriesTheSameReplyTheFoodHeadReads() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        _ = try await demo.approveHeadcount(DemoSeed.forecastDiners, reason: nil, for: DemoSeed.lunch.id, by: .admin)
        let approvedOnly = try await demo.vendorHistory(for: try vendorID())
        XCTAssertFalse(approvedOnly.contains { $0.meal.id == DemoSeed.lunch.id }, "Approved but not sent stays hidden")
        _ = try await demo.publishHeadcount(for: DemoSeed.lunch.id, by: .admin)
        let sentHistory = try await demo.vendorHistory(for: try vendorID())
        let sent = try XCTUnwrap(sentHistory.last)
        XCTAssertEqual(sent.meal.id, DemoSeed.lunch.id)
        XCTAssertEqual(sent.sentCount, DemoSeed.forecastDiners)
        XCTAssertNil(sent.acknowledgedAt)
        XCTAssertEqual(sent.isSample, false)
        let acknowledged = try await demo.acknowledgeHeadcount(for: DemoSeed.lunch.id, by: try vendorID())
        let afterHistory = try await demo.vendorHistory(for: try vendorID())
        let entry = try XCTUnwrap(afterHistory.last)
        XCTAssertEqual(entry.acknowledgedAt, acknowledged.acknowledgment?.acknowledgedAt)
    }

    func testOfflineIsAnErrorNeverAnEmptyHistory() async throws {
        let demo = DemoDataProvider(scenario: .offline)
        do {
            _ = try await demo.vendorHistory(for: try vendorID())
            XCTFail("Offline must not look like no meals")
        } catch {
            guard case .offline? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testTheDefaultSourceSaysItHasNoVendorView() async throws {
        do {
            _ = try await UnavailableVendor().vendorHistory(for: try vendorID())
            XCTFail("expected notImplemented")
        } catch {
            guard case .notImplemented? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }
}
#endif
