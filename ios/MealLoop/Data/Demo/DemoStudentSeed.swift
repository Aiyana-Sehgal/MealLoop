#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SAMPLE, NOT MEASURED. What Student Home draws beyond the core story, each value cited to its Figma frame
/// (file nzzTAm9YnJRSdKEeYUWUEb). Nothing here is a real balance, a real crowd reading or a real attendance record.
extension DemoSeed {
    // Home · Not answered (221:62529), CreditsChip: "120 pts". No formula exists (open decision P1).
    static let sampleCredits = 120

    // CrowdRow in Home · Not answered (2133:2380): seven hourly bars. The same heights on every Home frame.
    static let crowdBars = [22, 38, 46, 46, 34, 17, 17]
    // Home · Not answered: the first bar is lime. Home · Breakfast open (221:62565): the third.
    static let crowdQuietBar = 0
    static let crowdBusyBar = 2
    // Home · Not answered: "Best time 1:30 PM".
    static let crowdBestTime = time(13, 30)
    // Home · Breakfast open: "Quieter after 8:45 AM".
    static let crowdQuieterAfterBreakfast = time(8, 45)

    // Home · Mess closed (221:64833) is drawn at 6:30 AM and every open frame from 7:00 AM.
    static let messOpensForTheDay = time(7, 0)

    // Home · No Special pass (221:64860): the feedback row under the Crowd card.
    static let sampleRecheck = StudentRecheck(title: "You said the sambar was too salty.",
                                              detail: "Better today? Tell us in 5 seconds")

    // Answer · Dinner (2154:144248): "7:30–9:30 PM". The cutoff still comes from `IntentionPolicy`.
    static let dinner = Meal(id: MealID("demo-2024-08-14-dinner"), messID: mess.id, slot: .dinner,
                             startsAt: time(19, 30), endsAt: time(21, 30))

    private static func dish(_ id: String, _ name: String, highlight: Bool = false, diet: Diet = .veg) -> Dish {
        Dish(id: DishID(id), name: name, isHighlight: highlight, diet: diet, wasteUnit: .kilograms)
    }

    // Answer · Breakfast (2154:143268), and data/mess_menu_2024-08-12.md for Wednesday.
    static let breakfastAnswerMenu = [dish("millet-idli", "Millet Idli", highlight: true), dish("pongal", "Pongal")]

    // Answer · Lunch (221:62596) draws the highlight and three tiles out of the full menu.
    static let lunchAnswerDishes = ["bhindi-aloo-bujjiya", "chappathi", "veg-pulao", "muttar-masala"]

    // Answer · Dinner (2154:144248), and data/mess_menu_2024-08-12.md for Wednesday.
    static let dinnerAnswerMenu = [
        dish("chappathi", "Chappathi"), dish("steamed-rice", "Steamed Rice"), dish("dal-tadka", "Dal Tadka"),
        dish("butter-chicken-masala", "Butter Chicken Masala", diet: .nonVeg),
        dish("panneer-butter-masala", "Panneer Butter Masala"),
    ]

    // Entry · Discrepancy (221:63082): "Dinner · Tue 13 Aug", "Not scanned".
    static let sampleCorrectableRecord = AttendanceRecord(mealID: MealID("demo-2024-08-13-dinner"), slot: .dinner,
                                                          day: date(13, 0, 0), wasScanned: false)
}
#endif
