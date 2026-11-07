import Foundation

/// One of the six named headcount values (FR-HC-002). `count` is nil while it is missing, which is never zero.
struct AdminHeadcountValue: Equatable, Identifiable {
    let name: String
    let count: Int?

    var id: String { name }
}

/// The next thing the Food Head can do for this headcount. Nothing here happens by itself.
enum AdminHeadcountAction: Equatable {
    case approve(count: Int)
    case send(count: Int)

    var count: Int {
        switch self {
        case .approve(let count), .send(let count): return count
        }
    }
}

/// One line of the audit history, oldest first. Each case keeps what the record holds and nothing else.
enum AdminHistoryEvent: Equatable {
    case adjusted(HeadcountAdjustment)
    case approved(count: Int, by: Role, at: Date)
    case sent(SentHeadcount)
    case acknowledged(VendorAcknowledgment)

    var time: Date {
        switch self {
        case .adjusted(let adjustment): return adjustment.adjustedAt
        case .approved(_, _, let at): return at
        case .sent(let sent): return sent.sentAt
        case .acknowledged(let acknowledgment): return acknowledgment.acknowledgedAt
        }
    }
}

/// Everything loaded for one meal. Each value comes from a repository; none is filled in from another.
struct AdminMealContent: Equatable {
    let status: MealStatus
    let headcount: Headcount
    let answers: MealAnswerCounts
    /// Active shortages only.
    let shortages: [Shortage]

    var meal: Meal { status.meal }

    /// The six values, in the order of FR-HC-002. Each reads its own field.
    var values: [AdminHeadcountValue] {
        [
            AdminHeadcountValue(name: AdminCopy.liveForecast, count: headcount.liveForecast.diners),
            AdminHeadcountValue(name: AdminCopy.cutoffForecast, count: headcount.cutoffForecast.diners),
            AdminHeadcountValue(name: AdminCopy.approvedHeadcount, count: headcount.approved.count),
            AdminHeadcountValue(name: AdminCopy.sentToVendor, count: headcount.sentToVendor.count),
            AdminHeadcountValue(name: AdminCopy.actualEntries, count: headcount.actualEntries.value),
            AdminHeadcountValue(name: AdminCopy.finalEntries, count: headcount.finalEntries.value),
        ]
    }

    /// The number offered for approval: the frozen forecast once there is one, otherwise the live one.
    /// Nil means there is nothing to approve yet.
    var forecastToApprove: Int? {
        headcount.cutoffForecast.diners ?? headcount.liveForecast.diners
    }

    /// Owner ruling on P-ADMIN-1: once the meal has closed, nothing is offered and the final state is shown.
    var isClosed: Bool { status.state == .closed }

    /// Approve, then send. Once sent, or once the meal has closed, nothing is left to do here.
    var nextAction: AdminHeadcountAction? {
        guard !isClosed, case .notSent = headcount.sentToVendor else { return nil }
        if let approved = headcount.approved.count { return .send(count: approved) }
        return forecastToApprove.map { .approve(count: $0) }
    }

    /// The count the adjust sheet starts from, while the headcount can still change.
    var adjustableCount: Int? {
        guard !isClosed, case .notSent = headcount.sentToVendor else { return nil }
        return headcount.approved.count ?? forecastToApprove
    }

    /// The four-step bar on the tile (forecast ready, sent, replied, served and counted).
    /// Steps fill in order and stop at the first missing one. Nil means no data at all.
    var filledSteps: Int? {
        guard headcount.liveForecast.diners != nil || headcount.cutoffForecast.diners != nil else { return nil }
        guard case .sent = headcount.sentToVendor else { return 1 }
        guard case .acknowledged = headcount.vendorAcknowledgmentStatus else { return 2 }
        return headcount.finalEntries.value == nil ? 3 : 4
    }

    /// The one value the tile leads with, always shown under its own name.
    var leadValue: AdminHeadcountValue {
        switch status.state {
        case .closed:
            return AdminHeadcountValue(name: AdminCopy.finalEntries, count: headcount.finalEntries.value)
        case .inService:
            return AdminHeadcountValue(name: AdminCopy.actualEntries, count: headcount.actualEntries.value)
        case .notStarted:
            if let sent = headcount.sentToVendor.count {
                return AdminHeadcountValue(name: AdminCopy.sentToVendor, count: sent)
            }
            if let approved = headcount.approved.count {
                return AdminHeadcountValue(name: AdminCopy.approvedHeadcount, count: approved)
            }
            return AdminHeadcountValue(name: AdminCopy.liveForecast, count: headcount.liveForecast.diners)
        }
    }

    var history: [AdminHistoryEvent] {
        var events: [AdminHistoryEvent] = []
        if case .approved(let approved) = headcount.approved {
            events += approved.adjustments.map(AdminHistoryEvent.adjusted)
            events.append(.approved(count: approved.count, by: approved.approvedBy, at: approved.approvedAt))
        }
        if case .sent(let sent) = headcount.sentToVendor { events.append(.sent(sent)) }
        if case .acknowledged(let acknowledgment) = headcount.vendorAcknowledgmentStatus {
            events.append(.acknowledged(acknowledgment))
        }
        return events
    }
}

/// One stop on the day line. A slot with no meal behind it stays upcoming and shows no data.
struct AdminDayNode: Equatable, Identifiable {
    enum Progress: Equatable {
        case done
        case current
        case upcoming
    }

    let slot: MealSlot
    let progress: Progress

    var id: MealSlot { slot }
}

struct AdminTodayContent: Equatable {
    let mess: Mess
    let now: Date
    let nodes: [AdminDayNode]
    let selectedSlot: MealSlot
    /// Nil when the selected slot has no meal, which is not the same as a meal with zero students.
    let meal: AdminMealContent?
    let safetyCases: [SOSCase]
    /// The other messes for this meal. Nil when the source has none, which is not the same as no students.
    var otherMesses: AdminMessDay?
    /// Meals waiting for the Food Head's review, from Results.
    var reviewMeals: [ReviewMeal] = []

    /// Up to two rows show on Today; the rest are behind "See all".
    static let needsYouLimit = 2

    var values: [AdminHeadcountValue] {
        meal?.values ?? [AdminCopy.liveForecast, AdminCopy.cutoffForecast, AdminCopy.approvedHeadcount,
                         AdminCopy.sentToVendor, AdminCopy.actualEntries, AdminCopy.finalEntries]
            .map { AdminHeadcountValue(name: $0, count: nil) }
    }

    var visibleShortages: [Shortage] { Array((meal?.shortages ?? []).prefix(Self.needsYouLimit)) }
    var hasMoreShortages: Bool { (meal?.shortages.count ?? 0) > Self.needsYouLimit }
    /// Review rows fill what the shortages leave, so Today never holds more than the limit.
    var visibleReviews: [ReviewMeal] { Array(reviewMeals.prefix(max(Self.needsYouLimit - visibleShortages.count, 0))) }

    /// The tile that needs action is the black one, unless an open safety case takes that place.
    var tileIsUrgent: Bool { meal?.nextAction != nil && safetyCases.isEmpty }

    /// Only one tile is black. When the Food Head's own mess needs nothing, the first mess waiting to send takes it.
    var urgentOtherMess: String? {
        guard !tileIsUrgent, safetyCases.isEmpty else { return nil }
        return otherMesses?.messes.first(where: \.canSend)?.id
    }

    /// True until the cutoff of the selected meal has passed.
    var answersAreOpen: Bool {
        guard let meal else { return false }
        return IntentionPolicy.canAnswer(meal.meal, at: now)
    }
}
