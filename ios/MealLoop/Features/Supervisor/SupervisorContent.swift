import Foundation

/// The Supervisor's open tasks: active shortages and closed meals whose waste report is not recorded.
/// Home, Alerts and Me load them the same way, so one task always has one count (spec: "the same task on Home,
/// Alerts and Me is the same underlying task").
struct SupervisorFollowUps: Equatable {
    let activeShortages: [Shortage]
    let wasteNotRecorded: [MealRecord]

    var isEmpty: Bool { activeShortages.isEmpty && wasteNotRecorded.isEmpty }

    /// Reads the current meal's shortages and the meal history. Nothing is decided here: an active shortage and a
    /// not-recorded report are what the data source says they are.
    static func load(mess: MessID, current: MealStatus?, repositories: Repositories) async throws -> SupervisorFollowUps {
        let shortageRepository = repositories.shortages
        let mealStateRepository = repositories.mealState
        async let history = mealStateRepository.mealHistory(for: mess)
        var shortages: [Shortage] = []
        if let current {
            shortages = try await shortageRepository.shortages(for: current.meal.id)
        }
        let records = try await history
        return SupervisorFollowUps(
            activeShortages: shortages.filter { $0.status == ShortageStatus.active },
            wasteNotRecorded: records.filter { $0.waste == .notRecorded }
        )
    }
}

/// What Supervisor Home shows by meal state (spec "Home by meal state"):
/// not started shows the forecast and Start meal; in service shows students entered (never the forecast beside it)
/// and Close meal; closed shows the final entries or "Unavailable", never zero.
enum SupervisorHomePhase: Equatable {
    case notStarted(forecast: Forecast)
    case inService(entered: CountReading, minutesInService: Int)
    case closed(finalEntries: CountReading, closedAt: Date?)
}

struct SupervisorHomeContent: Equatable {
    let meal: Meal
    let mess: Mess
    let phase: SupervisorHomePhase
    let followUps: SupervisorFollowUps
}

/// The SOS panel for the Supervisor: which state it is in, decided from the case the data source returned.
/// The Supervisor can claim, mark checked and close; the backend refuses a close from any other role.
enum SupervisorSOSStage: Equatable {
    /// Nobody has claimed or checked it (S04).
    case notTaken
    /// The Supervisor claimed it and has not checked it yet (S04b).
    case claimedByYou
    /// Someone else claimed it and nobody has checked it yet (not drawn).
    case claimedBy(Role)
    /// Someone checked it; only the Supervisor closes it (S05, S05b).
    case checked(by: Role, at: Date)

    init(_ sos: SOSCase, viewer: Role) {
        if let last = sos.checks.last {
            self = .checked(by: last.role, at: last.at)
        } else if let claim = sos.claim {
            self = claim.role == viewer ? .claimedByYou : .claimedBy(claim.role)
        } else {
            self = .notTaken
        }
    }
}

/// The waste report page (S10, S11): a closed meal and what the kitchen recorded for it. Read only.
struct SupervisorWasteContent: Equatable {
    let record: MealRecord
    let mess: Mess
    /// The kitchen's rows, when the data source has them. Nil means "not available", never an empty report.
    let report: WasteReport?
}

/// Meal history (S18) and a past meal (S19).
struct SupervisorHistoryContent: Equatable {
    let mess: Mess
    let records: [MealRecord]
}
