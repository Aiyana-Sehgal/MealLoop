import SwiftUI

/// Where a meal's headcount stands, in words read from the record. Used by the headcount page's hero and snapshot.
enum AdminMealStatusText {
    /// What reached the vendor, read from the record (the hero once nothing is next).
    static func vendorLine(_ meal: AdminMealContent, in timeZone: TimeZone) -> String {
        guard meal.status.state == .notStarted else { return statusLine(meal, in: timeZone) }
        switch meal.headcount.vendorAcknowledgmentStatus {
        case .acknowledged(let record):
            return AdminCopy.acknowledgedAt(MLFormat.time(record.acknowledgedAt, in: timeZone))
        case .pending(let publishedAt):
            return AdminCopy.sentPending(MLFormat.time(publishedAt, in: timeZone))
        case .notPublished:
            return AdminCopy.notSentToVendorYet
        }
    }

    static func statusLine(_ meal: AdminMealContent, in timeZone: TimeZone) -> String {
        switch meal.status.state {
        case .closed:
            return closedLine(meal, in: timeZone)
        case .inService:
            return AdminCopy.servingNotFinal
        case .notStarted:
            break
        }
        switch meal.headcount.vendorAcknowledgmentStatus {
        case .acknowledged(let record):
            return AdminCopy.acknowledgedAt(MLFormat.time(record.acknowledgedAt, in: timeZone))
        case .pending(let publishedAt):
            return AdminCopy.sentPending(MLFormat.time(publishedAt, in: timeZone))
        case .notPublished:
            return meal.headcount.approved.count == nil ? AdminCopy.waitingForApproval : AdminCopy.approvedNotSent
        }
    }

    /// The final state of a closed meal: what reached the vendor, read from the record.
    private static func closedLine(_ meal: AdminMealContent, in timeZone: TimeZone) -> String {
        let vendor: String
        switch meal.headcount.vendorAcknowledgmentStatus {
        case .acknowledged(let record):
            vendor = AdminCopy.acknowledgedAt(MLFormat.time(record.acknowledgedAt, in: timeZone))
        case .pending:
            vendor = AdminCopy.pending
        case .notPublished:
            vendor = AdminCopy.notSent
        }
        guard let closedAt = meal.status.closedAt else { return vendor }
        return AdminCopy.closedWithStatus(MLFormat.time(closedAt, in: timeZone), status: vendor)
    }
}
