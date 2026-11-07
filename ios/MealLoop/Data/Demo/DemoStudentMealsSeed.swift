#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SAMPLE, NOT MEASURED. What the Student Meals tab, the Special pass and Crowd draw beyond the board itself. Each value
/// is cited to its Figma frame (file nzzTAm9YnJRSdKEeYUWUEb) or to data/mess_menu_2024-08-12.md. The dishes come from
/// `AdminMenuSeed`, the board as the Food Head keeps it.
extension DemoSeed {
    // MARK: Meals

    /// When each meal is served. Breakfast and lunch are the story day's; dinner is Answer · Dinner (2154:144248).
    /// No document gives a time for Snacks, so it has none.
    static func servingTimes(_ slot: MealSlot) -> (from: Date, until: Date)? {
        switch slot {
        case .breakfast: return (breakfast.startsAt, breakfast.endsAt)
        case .lunch: return (lunch.startsAt, lunch.endsAt)
        case .snacks: return nil
        case .dinner: return (dinner.startsAt, dinner.endsAt)
        }
    }

    /// Which dishes the Wednesday frames draw as tiles, by meal. The rest of a meal's veg dishes are "Comes with it".
    /// Meals · Wed 14 · Breakfast (1339:105019): Pongal. Meals · Wed 14 · Lunch (221:62892): Chappati, Veg Pulao,
    /// Muttar Masala. Meals · Wed 14 · Snacks (2150:136464): Sweet Puff. Meals · Wed 14 · Dinner (1339:104742):
    /// Chappathi, Steamed Rice, Dal Tadka.
    static let wednesdayMains: [MealSlot: [String]] = [
        .breakfast: ["Pongal"],
        .lunch: ["Chappati", "Veg Pulao", "Muttar Masala"],
        .snacks: ["Sweet Puff"],
        .dinner: ["Chappathi", "Steamed Rice", "Dal Tadka"],
    ]

    /// Meals · Wed 14 · Dinner (1339:104742): the "Curries" tiles.
    static let wednesdayCurries: [MealSlot: [String]] = [
        .dinner: ["Butter Chicken Masala", "Panneer Butter Masala"],
    ]

    /// The Wednesday frames draw these non-veg dishes as tiles; every other non-veg dish is a slim row.
    static let nonVegTiles: Set<String> = ["Butter Chicken Masala"]

    /// Board footer: "Monthly twice (alternative Wednesday) we provided Chicken Briyani & Panneer Briyani",
    /// "Note: Special Items are Limited". Meals · Wed 14 · Lunch draws it as "Alternate Wednesday special", "Limited".
    static let specialMeal = StudentSpecialMeal(dishes: ["Chicken Briyani", "Panneer Briyani"],
                                                note: "Alternate Wednesday special", isLimited: true)
    static let specialMealDay = date(14, 0, 0)
    static let specialMealSlot: MealSlot = .lunch

    /// Meals · Dish detail (221:62916): "PORTION AND ALLERGENS 1 bowl · Mustard seeds · Curry leaves",
    /// "Verified by mess · Mon 12 Aug". No other dish has details anywhere in the design.
    static let dishFacts: [String: (portion: String, allergens: [String], verifiedOn: Date)] = [
        "Sambar": ("1 bowl", ["Mustard seeds", "Curry leaves"], date(12, 0, 0)),
    ]

    // MARK: Special pass

    /// Pass · Wrong mess (221:65326): "This pass is for Main Mess, Block A".
    static let passMessName = "Main Mess, Block A"

    // MARK: Crowd

    /// Crowd · Main Mess (221:63246), "Today, every 15 minutes": the eight bar heights as drawn (35 to 118 pt), from
    /// 12:00 to 1:45 PM. An estimate of the usual pattern, not arrivals counted today.
    static let lunchCrowdHeights: [Double] = [35, 57, 86, 118, 112, 80, 48, 32]
    static let crowdSlotLength: TimeInterval = 15 * 60
    /// Crowd · Main Mess: the best-time dot sits on the seventh bar, 1:30 PM.
    static let crowdBestSlot = 6
    /// Crowd · Main Mess: "Wait now 2 min about", "At the busiest 18 min 12:45 PM".
    static let crowdWaitNowMinutes = 2
    static let crowdBusiestWaitMinutes = 18
    static let crowdBusiestAt = time(12, 45)
}
#endif
