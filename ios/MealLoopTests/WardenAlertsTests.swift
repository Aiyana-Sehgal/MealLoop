#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// W-6 Alerts are built only from the warden's own records.
@MainActor
final class WardenAlertsTests: XCTestCase {
    func testNoRecordsMeansNoAlerts() {
        XCTAssertTrue(WardenAlerts.alerts(queue: [], escalated: [], outNow: [], now: OutingSeed.wardenMoment).isEmpty)
    }

    func testEveryAlertComesFromTheListsItWasGiven() {
        let cases = OutingSeed.cases
        let alerts = WardenAlerts.alerts(queue: cases, escalated: [], outNow: [], now: OutingSeed.wardenMoment)
        // Only requests waiting for the warden, with a decide-by time still ahead, become deadlines.
        let expected = cases.filter { item in
            guard let by = item.wardenDecideBy else { return false }
            return item.stage == .awaitingWarden && OutingSeed.wardenMoment <= by
        }
        XCTAssertEqual(alerts.count, expected.count)
        XCTAssertTrue(alerts.allSatisfy { $0.kind == .deadline })
        XCTAssertEqual(alerts.map(\.time), alerts.map(\.time).sorted { ($0 ?? .distantPast) < ($1 ?? .distantPast) })
    }

    func testAnEscalationSaysWhenTheReplyWasMissed() {
        XCTAssertEqual(WardenAlertsCopy.missed("Dev ••0190", "Fri 4 PM"), "Dev ••0190 · missed Fri 4 PM")
        XCTAssertEqual(WardenAlertsCopy.missed("Dev ••0190", nil), "Dev ••0190 · past the reply time")
    }
}
#endif
