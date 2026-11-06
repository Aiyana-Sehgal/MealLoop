import XCTest
@testable import MealLoop

/// The six headcount quantities stay separate, and an acknowledgment is never fabricated.
final class HeadcountContractTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000)
    private let sent = SentHeadcount(count: 800, sentBy: .admin, sentAt: Date(timeIntervalSince1970: 500))

    private func headcount(sentToVendor: VendorPublication, acknowledgment: VendorAcknowledgment? = nil) -> Headcount {
        Headcount(mealID: MealID("m"), liveForecast: .notReady, cutoffForecast: .notReady, approved: .notApproved,
                  sentToVendor: sentToVendor, actualEntries: .unavailable, finalEntries: .unavailable,
                  acknowledgment: acknowledgment)
    }

    func testAPublishedHeadcountWithoutAcknowledgmentIsPending() {
        XCTAssertEqual(headcount(sentToVendor: .sent(sent)).vendorAcknowledgmentStatus, .pending(publishedAt: sent.sentAt))
    }

    func testAnUnpublishedHeadcountCannotShowAsAcknowledged() {
        let record = VendorAcknowledgment(acknowledgedBy: AccountID("v"), acknowledgedAt: now)
        XCTAssertEqual(headcount(sentToVendor: .notSent, acknowledgment: record).vendorAcknowledgmentStatus, .notPublished)
    }

    func testAnAcknowledgedHeadcountKeepsTheActorAndTime() {
        let record = VendorAcknowledgment(acknowledgedBy: AccountID("v"), acknowledgedAt: now)
        XCTAssertEqual(headcount(sentToVendor: .sent(sent), acknowledgment: record).vendorAcknowledgmentStatus,
                       .acknowledged(record))
    }

    func testMissingValuesHaveNoCount() {
        let empty = headcount(sentToVendor: .notSent)
        XCTAssertNil(empty.approved.count)
        XCTAssertNil(empty.sentToVendor.count)
        XCTAssertNil(empty.liveForecast.diners)
        XCTAssertNil(empty.cutoffForecast.diners)
        XCTAssertNil(empty.actualEntries.value)
        XCTAssertNil(empty.finalEntries.value)
    }

    func testRemoteAcknowledgmentNeverFakesSuccess() async {
        do {
            _ = try await RemoteAPI(baseURL: nil).acknowledgeHeadcount(for: MealID("m"), by: AccountID("v"))
            XCTFail("RemoteAPI must not acknowledge anything yet")
        } catch {
            guard case .notImplemented? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }
}

#if DEMO_DATA || REVIEW_DATA
final class SeededHeadcountTests: XCTestCase {
    private let meal = DemoSeed.lunch.id

    private func account(_ role: Role) throws -> AccountID {
        try XCTUnwrap(DemoSeed.accounts.first { $0.role == role }).id
    }

    func testBeforeTheMealActualAndFinalAreUnavailable() async throws {
        let headcount = try await DemoDataProvider(scenario: .beforeMeal).headcount(for: meal)
        XCTAssertEqual(headcount.actualEntries, .unavailable)
        XCTAssertEqual(headcount.finalEntries, .unavailable)
    }

    func testDuringTheMealActualIsLiveAndFinalIsUnavailable() async throws {
        let headcount = try await DemoDataProvider(scenario: .duringMeal).headcount(for: meal)
        XCTAssertEqual(headcount.actualEntries.value, DemoSeed.liveEntries)
        XCTAssertEqual(headcount.finalEntries, .unavailable)
    }

    func testAfterTheMealFinalIsAvailableAndActualIsNotReusedForIt() async throws {
        let headcount = try await DemoDataProvider(scenario: .afterMeal).headcount(for: meal)
        XCTAssertEqual(headcount.finalEntries.value, DemoSeed.finalEntries)
        XCTAssertEqual(headcount.actualEntries, .unavailable)
    }

    func testCutoffForecastIsNotFilledFromTheLiveForecast() async throws {
        let headcount = try await DemoDataProvider().headcount(for: meal)
        XCTAssertEqual(headcount.liveForecast.diners, DemoSeed.forecastDiners)
        XCTAssertEqual(headcount.cutoffForecast, .notReady)
    }

    private func publishedProvider() async throws -> DemoDataProvider {
        let demo = DemoDataProvider()
        _ = try await demo.approveHeadcount(DemoSeed.forecastDiners, reason: nil, for: meal, by: .admin)
        _ = try await demo.publishHeadcount(for: meal, by: .admin)
        return demo
    }

    func testSeededHeadcountStartsNotApproved() async throws {
        let headcount = try await DemoDataProvider().headcount(for: meal)
        XCTAssertEqual(headcount.approved, .notApproved)
        XCTAssertEqual(headcount.sentToVendor, .notSent)
        XCTAssertEqual(headcount.vendorAcknowledgmentStatus, .notPublished)
    }

    func testAPublishedHeadcountIsPendingUntilTheVendorActs() async throws {
        let demo = try await publishedProvider()
        let headcount = try await demo.headcount(for: meal)
        XCTAssertEqual(headcount.approved.count, DemoSeed.forecastDiners)
        XCTAssertEqual(headcount.sentToVendor.count, DemoSeed.forecastDiners)
        guard case .pending = headcount.vendorAcknowledgmentStatus else {
            return XCTFail("Expected pending, got \(headcount.vendorAcknowledgmentStatus)")
        }
    }

    func testOnlyTheFoodHeadApprovesAndPublishes() async throws {
        for role in Role.allCases where role != .admin {
            let demo = DemoDataProvider()
            do {
                _ = try await demo.approveHeadcount(DemoSeed.forecastDiners, reason: nil, for: meal, by: role)
                XCTFail("\(role) must not approve")
            } catch {
                guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
            }
        }
        let demo = DemoDataProvider()
        _ = try await demo.approveHeadcount(DemoSeed.forecastDiners, reason: nil, for: meal, by: .admin)
        do {
            _ = try await demo.publishHeadcount(for: meal, by: .supervisor)
            XCTFail("The Supervisor must not publish")
        } catch {
            guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testPublishingNeedsAnApproval() async {
        do {
            _ = try await DemoDataProvider().publishHeadcount(for: meal, by: .admin)
            XCTFail("Nothing is approved yet")
        } catch {
            guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testChangingTheCountNeedsAReasonAndIsRecorded() async throws {
        let demo = DemoDataProvider()
        let changed = DemoSeed.forecastDiners + 10
        do {
            _ = try await demo.approveHeadcount(changed, reason: "  ", for: meal, by: .admin)
            XCTFail("A change needs a reason")
        } catch {
            guard case .validationFailed? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
        let headcount = try await demo.approveHeadcount(changed, reason: "Staff event", for: meal, by: .admin)
        guard case .approved(let approved) = headcount.approved else { return XCTFail("Expected approved") }
        XCTAssertEqual(approved.adjustments.map(\.from), [DemoSeed.forecastDiners])
        XCTAssertEqual(approved.adjustments.map(\.to), [changed])
    }

    func testAHeadcountCannotChangeOnceSent() async throws {
        let demo = try await publishedProvider()
        do {
            _ = try await demo.approveHeadcount(DemoSeed.forecastDiners + 1, reason: "Late", for: meal, by: .admin)
            XCTFail("The sent headcount must not change here")
        } catch {
            guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testAnUnpublishedHeadcountCannotBeAcknowledged() async throws {
        do {
            _ = try await DemoDataProvider().acknowledgeHeadcount(for: meal, by: try account(.vendor))
            XCTFail("Nothing has been sent")
        } catch {
            guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }

    func testTheVendorAcknowledgmentRecordsActorAndTime() async throws {
        let demo = try await publishedProvider()
        let vendor = try account(.vendor)
        let headcount = try await demo.acknowledgeHeadcount(for: meal, by: vendor)
        XCTAssertEqual(headcount.vendorAcknowledgmentStatus,
                       .acknowledged(VendorAcknowledgment(acknowledgedBy: vendor, acknowledgedAt: demo.clock.now())))
    }

    func testARepeatKeepsTheFirstAcknowledgment() async throws {
        let demo = try await publishedProvider()
        let vendor = try account(.vendor)
        let first = try await demo.acknowledgeHeadcount(for: meal, by: vendor).acknowledgment
        demo.clock.set(demo.clock.now().addingTimeInterval(60))
        let second = try await demo.acknowledgeHeadcount(for: meal, by: vendor).acknowledgment
        XCTAssertEqual(first, second)
    }

    func testNoOtherRoleCanAcknowledge() async throws {
        for role in Role.allCases where role != .vendor {
            let demo = try await publishedProvider()
            do {
                _ = try await demo.acknowledgeHeadcount(for: meal, by: try account(role))
                XCTFail("\(role) must not acknowledge")
            } catch {
                guard case .notAllowed? = error as? RepositoryError else { return XCTFail("\(error)") }
            }
            let headcount = try await demo.headcount(for: meal)
            XCTAssertNil(headcount.acknowledgment, "\(role)")
        }
    }

    func testOfflineAcknowledgmentRecordsNothing() async throws {
        let demo = DemoDataProvider(scenario: .offline)
        do {
            _ = try await demo.acknowledgeHeadcount(for: meal, by: try account(.vendor))
            XCTFail("Offline must not record an acknowledgment")
        } catch {
            guard case .offline? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
        await demo.setScenario(.duringMeal)
        let headcount = try await demo.headcount(for: meal)
        XCTAssertNil(headcount.acknowledgment)
    }
}
#endif
