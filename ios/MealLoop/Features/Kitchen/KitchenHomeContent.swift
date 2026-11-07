import Foundation

/// What Kitchen Home shows, by meal state (design/reference/kitchen_2026-10/data/kitchen_spec.md).
/// The type makes the counting rules hard to break:
/// - before the meal: the forecast only;
/// - during the meal: students entered only (never meals served, never the forecast beside it);
/// - after the meal: final entries and the waste report status.
enum KitchenHomePhase: Equatable {
    case beforeMeal(forecast: Forecast)
    case duringMeal(entered: CountReading, minutesInService: Int, shortages: [Shortage])
    case afterMeal(finalEntries: CountReading, closedAt: Date?, waste: WasteReportSummary)
}

/// A report that did not get through. It keeps its key, so a retry can never count twice.
struct KitchenFailedReport: Equatable, Identifiable {
    let report: ShortageReport

    var id: String { report.idempotencyKey.rawValue }
}

/// What came of a tap on "Send to Ravi".
enum KitchenReportOutcome: Equatable {
    case needsDish
    case sent
    case alreadyReported(Shortage)
    case mealEnded(at: Date?)
    case couldNotSend
}

struct KitchenHomeContent: Equatable {
    /// A second report for the same dish within this time asks first (kitchen_spec.md: 10 minutes).
    static let repeatWindow: TimeInterval = 10 * 60

    let meal: Meal
    let mess: Mess
    let staffInitials: String
    let supervisorName: String
    let phase: KitchenHomePhase

    /// The forecast is shown only before the meal.
    var visibleForecast: Forecast? {
        if case .beforeMeal(let forecast) = phase { return forecast }
        return nil
    }

    /// Up to two shortage rows are shown on Home; the rest are behind "See all".
    var visibleShortages: [Shortage] {
        if case .duringMeal(_, _, let shortages) = phase { return Array(shortages.prefix(2)) }
        return []
    }

    var allShortages: [Shortage] {
        if case .duringMeal(_, _, let shortages) = phase { return shortages }
        return []
    }

    var hiddenShortageCount: Int {
        if case .duringMeal(_, _, let shortages) = phase { return max(0, shortages.count - 2) }
        return 0
    }
}
