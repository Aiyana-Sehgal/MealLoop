import Foundation

/// Only a Pass Desk session may open this role.
enum PassDeskAccess {
    static func canOpen(_ session: Session) -> Bool {
        session.account.role == .passDesk && session.staff?.role == .passDesk
    }
}

/// What Home shows, by meal state (FR-PASS-008). The Supervisor controls the state; this only follows it.
enum PassDeskHomePhase: Equatable {
    /// No keypad and no count.
    case beforeMeal(opensAt: Date)
    case duringMeal
    case afterMeal(closedAt: Date?)
}

struct PassDeskHomeContent: Equatable {
    let status: MealStatus
    let phase: PassDeskHomePhase
    let count: SpecialMealCount
    let requests: [PassReissueRequest]
    /// Shortages this desk reported. The alert is about the ones the kitchen has seen.
    let reportedShortages: [Shortage]

    var meal: Meal { status.meal }
    var waitingRequests: Int { requests.filter { $0.status == .waiting }.count }
}

/// One Alerts row, worked out from what the repositories hold. Nothing is made up.
struct PassDeskAlert: Equatable, Identifiable {
    enum Kind: Equatable {
        case mealStarted
        case newPassApproved(String)
        case shortageSeen
    }

    let kind: Kind
    let at: Date

    var id: String { "\(kind)" }

    /// Newest first, at most three (pass_desk_spec.md). A request only counts here once the admin said yes.
    static func alerts(for content: PassDeskHomeContent?) -> [PassDeskAlert] {
        guard let content else { return [] }
        var alerts: [PassDeskAlert] = []
        if let startedAt = content.status.startedAt {
            alerts.append(PassDeskAlert(kind: .mealStarted, at: startedAt))
        }
        for request in content.requests where request.status == .approved {
            if let at = request.updatedAt {
                alerts.append(PassDeskAlert(kind: .newPassApproved(request.holder.student.maskedID), at: at))
            }
        }
        for shortage in content.reportedShortages {
            if case .seen(let at, _) = shortage.delivery {
                alerts.append(PassDeskAlert(kind: .shortageSeen, at: at))
            }
        }
        return Array(alerts.sorted { $0.at > $1.at }.prefix(3))
    }
}

/// Check this pass: what the student's phone should show right now.
struct PassDeskCompare: Equatable {
    let holder: SpecialPassHolder
    var live: LivePassCode
    var secondsLeft: Int
    /// True for a moment after the code changed under the sheet.
    var justChanged = false
    /// The window ran out and no new code came: staff must check again.
    var isExpired = false
}

/// Every end of a check. Only `.verified` can show the lime screen, and only a saved entry makes one.
enum PassDeskOutcome: Equatable {
    case verified(SpecialPassHolder, count: Int?, passes: Int?)
    case noPass(SpecialPassHolder)
    case wrongMeal(SpecialPassHolder, passFor: MealSlot)
    case alreadyRecorded(SpecialPassHolder, firstRecordedAt: Date, count: Int?)
    case mismatch(LivePassCode)
    case cantCheck(lastUpdate: Date?)
    case mealEnded(closedAt: Date?, count: Int?, passes: Int?)
}
