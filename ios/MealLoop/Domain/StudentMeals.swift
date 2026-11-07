import Foundation

/// The week the Meals tab shows: seven days and which one is today in the mess.
struct StudentWeek: Sendable, Hashable {
    let days: [Date]
    let today: Date
}

/// Whether the mess has posted a menu for one meal of one day.
enum StudentMenuStatus: Sendable, Hashable {
    case published
    /// The mess has not posted this menu yet.
    case notPublished
    /// The mess does not serve this meal on this day.
    case noMeal
}

/// The alternate-Wednesday ticket on the Meals page. "Special items are limited" is a tag, never a count.
struct StudentSpecialMeal: Sendable, Hashable {
    let dishes: [String]
    let note: String
    let isLimited: Bool
}

/// One meal of one day, laid out the way the Meals frames draw it. Which dish sits in which part is menu data from
/// the mess, not a rule of the screen.
struct StudentMealMenu: Sendable, Hashable {
    let day: Date
    let slot: MealSlot
    let status: StudentMenuStatus
    /// When the meal is served. Nil when no time is known for that day.
    let servedFrom: Date?
    let servedUntil: Date?
    /// The black tile.
    let highlight: Dish?
    /// The tiles under it, with no heading.
    let mains: [Dish]
    /// The tiles under "Curries".
    let curries: [Dish]
    /// The slim rows: the board's non-veg lines and the `**` gravies (P9 default: drawn as a slim non-veg row).
    let slimRows: [Dish]
    /// "Comes with it", as one line.
    let sides: [Dish]
    let special: StudentSpecialMeal?
    /// When the mess last changed this menu. Nil when it has not changed since it was posted.
    let changedAt: Date?
    /// False for Snacks: the menu only, no answer and no entry QR (P7 default).
    let isAnswerable: Bool

    var allDishes: [Dish] {
        [highlight].compactMap { $0 } + mains + curries + slimRows + sides
    }
}

/// What the Dish page knows about one dish. Missing details stay missing: nothing is filled in.
struct StudentDishDetail: Sendable, Hashable {
    let dish: Dish
    let slot: MealSlot
    let day: Date
    let servedFrom: Date?
    let servedUntil: Date?
    /// "1 bowl". Nil when the mess has not said.
    let portion: String?
    /// Empty when the mess has not listed any.
    let allergens: [String]
    /// When the mess checked these details. Nil when it never has.
    let verifiedOn: Date?
}

/// One dish found by name in the week's menu.
struct StudentDishMatch: Sendable, Hashable, Identifiable {
    let dish: Dish
    let day: Date
    let slot: MealSlot

    var id: String { "\(dish.id.rawValue)-\(day.timeIntervalSince1970)-\(slot.rawValue)" }
}

/// The special-meal pass as its holder sees it.
struct StudentPassTicket: Sendable, Hashable {
    let meal: Meal
    let dishes: [String]
    let holderName: String
    let maskedID: String
    let messName: String
}

/// Where the student's special-meal pass stands. The live code itself comes from `SpecialPassRepository.refreshPassCode`.
enum StudentPassStanding: Sendable, Hashable {
    /// No pass this week.
    case notEligible
    /// The student is at another mess. `passMess` is where the pass works.
    case wrongMess(passMess: String)
    case available(StudentPassTicket)
    /// The student chose to use it: the phone shows the live code until the door records the entry.
    case live(StudentPassTicket, startedAt: Date)
    /// The entry was recorded. `wasShowingCode` is true when the student had the live code open in the app.
    case used(StudentPassTicket, at: Date, wasShowingCode: Bool)
    /// The meal ended before the pass was used.
    case expired(StudentPassTicket, endedAt: Date)
}

/// One 15-minute slot of the Crowd chart.
struct StudentCrowdSlot: Sendable, Hashable {
    let startsAt: Date
    /// Arrivals at the door in this slot, relative to the busiest slot of the day (0 to 1). An estimate of the pattern,
    /// never a head count.
    let activity: Double
}

/// The Crowd page. The level is an estimate; nothing here claims how many people are inside.
struct StudentCrowd: Sendable, Hashable {
    let meal: Meal
    let observedAt: Date
    /// The same estimate as the Home row, so the two never disagree.
    let level: CrowdLevel
    /// Quiet: the best time. Busy: when it gets quieter. Closed: when it opens.
    let detailTime: Date?
    /// Empty when there are not enough entries to draw the day.
    let slots: [StudentCrowdSlot]
    /// The slot the clock is in. Nil outside the meal.
    let currentSlot: Int?
    /// The slot with the best time, for the dot.
    let bestSlot: Int?
    /// About how long the wait is now, in minutes. Nil when the mess is not serving.
    let waitNowMinutes: Int?
    let busiestWaitMinutes: Int?
    let busiestAt: Date?
}
