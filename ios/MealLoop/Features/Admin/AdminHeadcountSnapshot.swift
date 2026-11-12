import Foundation

/// What the headcount page draws for one mess and meal, from either source: the signed-in mess's full record
/// (`AdminMealContent`) or another mess's summary (`AdminMessHeadcount`, Super Admin only). Every value keeps its own
/// name and stays nil when the source does not hold it, so a missing value is a dash, never a zero or another value.
struct AdminHeadcountSnapshot: Equatable {
    enum Next: Equatable {
        case approve(Int)
        case send(Int)
        case none
    }

    /// "Main"
    let mess: String
    let mealName: String
    let day: String
    /// Under the title: answers closing, who approved, or when it was sent.
    let subtitle: String
    /// Forecast, Approve, Send, Vendor: the step waiting (4 when all are done).
    let stepIndex: Int
    let next: Next
    /// What the hero shows once nothing is next, under its own name.
    let leadName: String
    let leadCount: Int?
    let statusLine: String

    let liveForecast: Int?
    let answered: Int?
    let notYet: Int?
    let answersOpen: Bool
    let cutoffTime: String
    let cutoffForecast: Int?
    let approvedCount: Int?
    /// "By Devi · 10:12 AM"
    let approvedLine: String?
    let sentCount: Int?
    let sentLine: String
    let actualEntries: Int?
    let actualLine: String
    let finalEntries: Int?
    let canChangeNumber: Bool
    let canContactVendor: Bool
    /// The meal report behind Final entries. Only the signed-in mess's meal has one.
    let mealID: MealID?
    let track: [AdminVendorTrack.Step]
    /// "approved by Devi · 10:12 AM", for the Approved sheet.
    let approvedCaption: String?
    /// Forecast locked, each change with its reason, Approved: oldest first, only what the record holds.
    let approvalHistory: [AdminVendorTrack.Step]
    let hasChanges: Bool
    /// "Live · updated 12:42 PM" while serving; nil when no entries are held.
    let actualAsOf: String?
    /// "meal closed 2:15 PM"; nil until the meal closes.
    let closedCaption: String?

    /// Once a number is approved the Approved and Sent tiles lead; before, the forecasts do.
    var isApproved: Bool { approvedCount != nil }
}

extension AdminHeadcountSnapshot {
    /// The signed-in mess, from its full record.
    static func own(_ content: AdminTodayContent, _ meal: AdminMealContent, context: AdminContext) -> AdminHeadcountSnapshot {
        let timeZone = content.mess.timeZone
        let headcount = meal.headcount
        let cutoff = MLFormat.time(IntentionPolicy.cutoff(for: meal.meal), in: timeZone)
        let answers = meal.answers
        let answered = answers.attending + answers.skipping + answers.notSure

        var approvedLine: String?
        var approvedBy: String?
        var approvedTime: String?
        if case .approved(let approved) = headcount.approved {
            approvedBy = approved.approvedBy == context.account.role ? context.account.firstName : StaffEntryCopy.roleTitle(approved.approvedBy)
            approvedTime = MLFormat.time(approved.approvedAt, in: timeZone)
            approvedLine = AdminCopy.byWhom(approvedBy ?? "", time: approvedTime ?? "")
        }

        let next: Next = switch meal.nextAction {
        case .approve(let count)?: .approve(count)
        case .send(let count)?: .send(count)
        case nil: .none
        }

        let stepIndex: Int = {
            if headcount.liveForecast.diners == nil && headcount.cutoffForecast.diners == nil { return 0 }
            if headcount.approved.count == nil { return 1 }
            switch headcount.vendorAcknowledgmentStatus {
            case .notPublished: return 2
            case .pending: return 3
            case .acknowledged: return 4
            }
        }()

        let subtitle: String
        if case .sent(let sent) = headcount.sentToVendor {
            subtitle = AdminCopy.sentToVendorAt(MLFormat.time(sent.sentAt, in: timeZone))
        } else if let approvedBy, let approvedTime {
            subtitle = AdminCopy.approvedByLine(approvedBy, time: approvedTime)
        } else {
            subtitle = content.answersAreOpen ? AdminCopy.answersCloseShort(cutoff) : AdminCopy.answersClosedShort(cutoff)
        }

        let actualLine: String = switch meal.status.state {
        case .notStarted: AdminCopy.startsAt(MLFormat.time(meal.meal.startsAt, in: timeZone))
        case .inService: AdminCopy.servingNow
        case .closed: AdminCopy.afterTheMeal
        }

        var track: [AdminVendorTrack.Step] = [
            .init(title: AdminCopy.trackApproved, detail: approvedLine.map { _ in "\(approvedBy ?? "") · \(AdminCopy.clock(approvedTime ?? ""))" }
                  ?? AdminCopy.notYetCapital, isDone: approvedLine != nil),
        ]
        if case .sent(let sent) = headcount.sentToVendor {
            track.append(.init(title: AdminCopy.trackSent, detail: MLFormat.time(sent.sentAt, in: timeZone), isDone: true))
        } else {
            track.append(.init(title: AdminCopy.trackSent, detail: AdminCopy.notYetCapital, isDone: false))
        }
        switch headcount.vendorAcknowledgmentStatus {
        case .acknowledged(let record):
            track.append(.init(title: AdminCopy.trackAcknowledged, detail: MLFormat.time(record.acknowledgedAt, in: timeZone), isDone: true))
        case .pending:
            track.append(.init(title: AdminCopy.trackAcknowledged, detail: AdminCopy.waitingWord, isDone: false))
        case .notPublished:
            track.append(.init(title: AdminCopy.trackAcknowledged, detail: AdminCopy.notYetCapital, isDone: false))
        }

        var history: [AdminVendorTrack.Step] = []
        var hasChanges = false
        if let locked = headcount.cutoffForecast.diners {
            history.append(.init(title: AdminCopy.forecastLocked(locked), detail: cutoff, isDone: true))
        }
        if case .approved(let approved) = headcount.approved {
            for change in approved.adjustments {
                hasChanges = true
                history.append(.init(title: AdminCopy.historyAdjusted(from: change.from, to: change.to),
                                     detail: "\(change.reason) · \(StaffEntryCopy.roleTitle(change.adjustedBy)) · \(MLFormat.time(change.adjustedAt, in: timeZone))",
                                     isDone: true))
            }
            history.append(.init(title: AdminCopy.approvedCount(approved.count), detail: "\(approvedBy ?? "") · \(approvedTime ?? "")", isDone: true))
        }
        let actualAsOf: String? = switch meal.status.state {
        case .inService: headcount.actualEntries.asOf.map { AdminCopy.liveUpdated(MLFormat.time($0, in: timeZone)) }
        case .closed, .notStarted: nil
        }
        let closedCaption = meal.status.closedAt.map { AdminCopy.mealClosedAt(MLFormat.time($0, in: timeZone)) }

        return AdminHeadcountSnapshot(
            mess: AdminCopy.tileName(content.mess.name), mealName: MLFormat.mealSlot(meal.meal.slot),
            day: AdminCopy.dayLine(content.now, in: timeZone), subtitle: subtitle, stepIndex: stepIndex, next: next,
            leadName: meal.leadValue.name, leadCount: meal.leadValue.count, statusLine: AdminMealStatusText.vendorLine(meal, in: timeZone),
            liveForecast: headcount.liveForecast.diners, answered: answered, notYet: answers.noResponse,
            answersOpen: content.answersAreOpen, cutoffTime: cutoff, cutoffForecast: headcount.cutoffForecast.diners,
            approvedCount: headcount.approved.count, approvedLine: approvedLine,
            sentCount: headcount.sentToVendor.count, sentLine: sentLine(headcount.vendorAcknowledgmentStatus, timeZone: timeZone),
            actualEntries: headcount.actualEntries.value, actualLine: actualLine, finalEntries: headcount.finalEntries.value,
            canChangeNumber: meal.adjustableCount != nil, canContactVendor: headcount.approved.count != nil,
            mealID: meal.meal.id, track: track,
            approvedCaption: approvedBy.flatMap { who in approvedTime.map { AdminCopy.approvedByCaption(who, time: $0) } },
            approvalHistory: history, hasChanges: hasChanges, actualAsOf: actualAsOf, closedCaption: closedCaption)
    }

    /// Another mess, from its summary. It holds no meal record, so entries are not held and Final has no report.
    static func other(_ mess: AdminMessHeadcount, content: AdminTodayContent, context: AdminContext) -> AdminHeadcountSnapshot {
        let timeZone = content.mess.timeZone
        // The same meal slot closes at the same time in every mess.
        let cutoff = content.meal.map { MLFormat.time(IntentionPolicy.cutoff(for: $0.meal), in: timeZone) } ?? AdminFormat.missing
        let approvedBy = mess.approvedBy.map { $0 == context.account.role ? context.account.firstName : StaffEntryCopy.roleTitle($0) }
        let approvedTime = mess.approvedAt.map { MLFormat.time($0, in: timeZone) }
        let approvedLine = approvedBy.flatMap { who in approvedTime.map { AdminCopy.byWhom(who, time: $0) } }

        let stepIndex: Int = {
            guard mess.expected != nil else { return 0 }
            guard mess.sentAt != nil else { return 2 }
            if case .replied = mess.reply { return 4 }
            return 3
        }()
        let next: Next = mess.canSend ? .send(mess.expected ?? 0) : .none

        let subtitle: String
        if let sentAt = mess.sentAt {
            subtitle = AdminCopy.sentToVendorAt(MLFormat.time(sentAt, in: timeZone))
        } else if let approvedBy, let approvedTime {
            subtitle = AdminCopy.approvedByLine(approvedBy, time: approvedTime)
        } else if mess.expected == nil {
            subtitle = mess.forecastAt.map { AdminCopy.forecastAt(MLFormat.time($0, in: timeZone)) } ?? AdminCopy.noData
        } else {
            subtitle = content.answersAreOpen ? AdminCopy.answersCloseShort(cutoff) : AdminCopy.answersClosedShort(cutoff)
        }

        let sentLine: String
        if let sentAt = mess.sentAt {
            let time = MLFormat.time(sentAt, in: timeZone)
            switch mess.reply {
            case .replied(let at): sentLine = AdminCopy.acknowledgedAt(MLFormat.time(at, in: timeZone))
            case .noReply: sentLine = AdminCopy.noReplySince(time)
            case .waiting, .notSent: sentLine = AdminCopy.sentWaiting(time)
            }
        } else {
            sentLine = approvedLine == nil && mess.expected == nil ? AdminCopy.unlocksAfterApprove : AdminCopy.notSentYet
        }

        var track: [AdminVendorTrack.Step] = [
            .init(title: AdminCopy.trackApproved,
                  detail: approvedBy.flatMap { who in approvedTime.map { "\(who) · \(AdminCopy.clock($0))" } } ?? AdminCopy.notRecorded,
                  isDone: approvedLine != nil),
        ]
        track.append(.init(title: AdminCopy.trackSent, detail: mess.sentAt.map { MLFormat.time($0, in: timeZone) } ?? AdminCopy.notYetCapital,
                           isDone: mess.sentAt != nil))
        switch mess.reply {
        case .replied(let at):
            track.append(.init(title: AdminCopy.trackAcknowledged, detail: MLFormat.time(at, in: timeZone), isDone: true))
        case .waiting, .noReply:
            track.append(.init(title: AdminCopy.trackAcknowledged, detail: AdminCopy.waitingWord, isDone: false))
        case .notSent:
            track.append(.init(title: AdminCopy.trackAcknowledged, detail: AdminCopy.notYetCapital, isDone: false))
        }

        // An approval the record holds is the number now expected; without one, nothing is called approved.
        let approvedCount = mess.approvedAt == nil ? nil : mess.expected
        return AdminHeadcountSnapshot(
            mess: mess.name, mealName: MLFormat.mealSlot(mess.slot), day: AdminCopy.dayLine(content.now, in: timeZone),
            subtitle: subtitle, stepIndex: stepIndex, next: next,
            leadName: mess.sentAt != nil ? AdminCopy.sentToVendor : AdminCopy.liveForecast, leadCount: mess.expected,
            statusLine: mess.sentAt == nil ? AdminCopy.notSentToVendorYet : sentLine,
            liveForecast: mess.expected, answered: mess.answered, notYet: nil, answersOpen: content.answersAreOpen,
            cutoffTime: cutoff, cutoffForecast: mess.cutoffForecast,
            approvedCount: approvedCount ?? (mess.sentAt != nil ? mess.expected : nil),
            approvedLine: approvedLine ?? (mess.sentAt != nil ? AdminCopy.notRecorded : nil),
            sentCount: mess.sentAt == nil ? nil : mess.expected, sentLine: sentLine,
            actualEntries: nil, actualLine: AdminCopy.notHeldFor(mess.name), finalEntries: nil,
            canChangeNumber: mess.canSend, canContactVendor: mess.expected != nil, mealID: nil, track: track,
            approvedCaption: approvedBy.flatMap { who in approvedTime.map { AdminCopy.approvedByCaption(who, time: $0) } },
            approvalHistory: otherHistory(mess, cutoff: cutoff, approvedBy: approvedBy, approvedTime: approvedTime),
            hasChanges: mess.adjustmentReason != nil, actualAsOf: nil, closedCaption: nil)
    }

    private static func otherHistory(_ mess: AdminMessHeadcount, cutoff: String, approvedBy: String?,
                                     approvedTime: String?) -> [AdminVendorTrack.Step] {
        var steps: [AdminVendorTrack.Step] = []
        if let locked = mess.cutoffForecast {
            steps.append(.init(title: AdminCopy.forecastLocked(locked), detail: cutoff, isDone: true))
        }
        if let reason = mess.adjustmentReason, let count = mess.expected {
            steps.append(.init(title: AdminCopy.changedTo(count), detail: reason, isDone: true))
        }
        if let approvedBy, let approvedTime, let count = mess.expected {
            steps.append(.init(title: AdminCopy.approvedCount(count), detail: "\(approvedBy) · \(approvedTime)", isDone: true))
        }
        return steps
    }

    private static func sentLine(_ status: VendorAcknowledgmentStatus, timeZone: TimeZone) -> String {
        switch status {
        case .acknowledged(let record): return AdminCopy.acknowledgedAt(MLFormat.time(record.acknowledgedAt, in: timeZone))
        case .pending(let publishedAt): return AdminCopy.sentWaiting(MLFormat.time(publishedAt, in: timeZone))
        case .notPublished: return AdminCopy.notSentYet
        }
    }
}
