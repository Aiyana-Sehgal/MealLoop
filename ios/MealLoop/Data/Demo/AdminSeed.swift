#if DEMO_DATA || REVIEW_DATA
import Foundation

/// DEMO DATA for the Food Head's Students, Results and More tabs. Sample values only, never measured results.
/// Unless a line says otherwise, the source is design/reference/admin_redesign_2026-10/data/admin_sample_data.md.
/// Reference names (A09, F01...) point at design/audit/export_admin_redesign and design/audit/export_fix2.
enum AdminSeed {
    private static let d = DemoSeed.date

    // MARK: Results

    static let periodTitle = "Last 4 weeks · all messes"
    static let totalMeals = 56
    static let messNames = ["Main", "North", "South", "Annexe"]

    private static func mealID(_ text: String) -> MealID { MealID("admin-sample-\(text)") }
    static let tueDinnerNorth = mealID("2024-08-13-dinner-north")
    static let monLunchMain = mealID("2024-08-12-lunch-main")
    static let tueDinnerMain = mealID("2024-08-13-dinner-main")
    static let monDinnerSouth = mealID("2024-08-12-dinner-south")
    static let tueLunchNorth = mealID("2024-08-13-lunch-north")

    static let wednesdayPlan = CheckID("wednesday-lunch")
    static let northScanner = CheckID("north-scanner")

    private static func meal(_ id: MealID, mess: String, slot: MealSlot, day: Int, sent: Int?, sentAt: Date? = nil, came: Int?,
                             closedAt: Date? = nil, leftovers: [FoodAmount] = [], plate: Double? = nil, ranOut: [FoodRanOut] = [],
                             late: Bool = false, data: Int? = nil, missing: [MissingEvidence] = [],
                             questions: [String] = [], review: Bool = false) -> AdminMealFacts {
        AdminMealFacts(id: id, mess: mess, slot: slot, day: d(day, 0, 0), headcountSent: sent, sentAt: sentAt, finalEntries: came,
                       closedAt: closedAt, isClosed: true, leftovers: leftovers, plateWasteKg: plate, ranOut: ranOut,
                       wasReportedLate: late, dataCompletePercent: data, missing: missing, headcountChange: nil,
                       openQuestions: questions, needsReview: review, linkedCheck: nil, suggestedChange: nil)
    }

    /// The story meal as the pack draws it. `DemoAdminRepositories` replaces its counts and waste with the live
    /// repositories, so Admin never disagrees with the Supervisor or the Kitchen about the same meal.
    static let storyLunch = AdminMealFacts(
        id: DemoSeed.lunch.id, mess: "Main", slot: .lunch, day: d(14, 0, 0), headcountSent: nil, sentAt: nil, finalEntries: nil,
        closedAt: nil, isClosed: false, leftovers: [], plateWasteKg: nil,
        // A09_reason_cant_tell_ran_out: "Rice ran out 1:34 PM".
        ranOut: [FoodRanOut(dish: "Rice", at: DemoSeed.time(13, 34))], wasReportedLate: false,
        dataCompletePercent: 80, missing: [.amountCooked],
        headcountChange: HeadcountChange(from: 800, to: 860, at: DemoSeed.time(9, 0), reason: "staff event"),
        openQuestions: ["Did the event add diners?"], needsReview: true, linkedCheck: wednesdayPlan,
        suggestedChange: "Use the 4-week average (612) unless an event is confirmed")

    static let pastMeals: [AdminMealFacts] = [
        meal(tueDinnerNorth, mess: "North", slot: .dinner, day: 13, sent: 640, came: 602,
             leftovers: [FoodAmount(dish: "Rice", amount: 6, unit: .kilograms)]),
        meal(monLunchMain, mess: "Main", slot: .lunch, day: 12, sent: 820, came: 730,
             leftovers: [FoodAmount(dish: "Dal", amount: 3, unit: .litres), FoodAmount(dish: "Sambar", amount: 2, unit: .litres)]),
        // F01_results_to_check_meal_report_tue_dinner. Differs from the Supervisor seed for the same meal (REPORT.md).
        meal(tueDinnerMain, mess: "Main", slot: .dinner, day: 13, sent: 640, sentAt: d(13, 16, 30), came: 691, closedAt: d(13, 21, 30),
             plate: 11, ranOut: [FoodRanOut(dish: "Rice", at: d(13, 20, 34))], late: true, data: 90, missing: [.amountCooked],
             questions: ["Was there an event?"], review: true),
        // A09_reason_more_came.
        meal(monDinnerSouth, mess: "South", slot: .dinner, day: 12, sent: 580, came: 627,
             ranOut: [FoodRanOut(dish: "Rice", at: d(12, 20, 40))]),
        // A09_reason_reported_late and A09_reason_last_30_minutes. No counts are drawn for this meal.
        meal(tueLunchNorth, mess: "North", slot: .lunch, day: 13, sent: nil, came: nil,
             ranOut: [FoodRanOut(dish: "Rice", at: d(13, 13, 50))], late: true, missing: [.scannerRecords]),
    ]

    static let leftOver = ResultGroup(meals: 9, totalMeals: totalMeals, reasons: [
        ResultReason(kind: .fewerCame, title: "Fewer students came than we planned for", detail: nil, meals: 5, tag: .sure),
        ResultReason(kind: .didntLikeDish, title: "Students didn't like a dish", detail: nil, meals: 3, tag: .probably),
        ResultReason(kind: .raisedLate, title: "We raised the headcount late", detail: nil, meals: 2, tag: .sure),
        ResultReason(kind: .cantTellLeftOver, title: "Can't tell why", detail: "Amount not shared", meals: 4, tag: .cantTell),
    ])

    static let ranOut = ResultGroup(meals: 2, totalMeals: totalMeals, reasons: [
        ResultReason(kind: .moreCame, title: "More students came than we planned for", detail: nil, meals: 1, tag: .sure),
        ResultReason(kind: .lastThirtyMinutes, title: "Most came in the last 30 minutes", detail: nil, meals: 1, tag: .probably),
        ResultReason(kind: .reportedLate, title: "It was reported late", detail: nil, meals: 1, tag: .sure),
        ResultReason(kind: .cantTellRanOut, title: "Can't tell why", detail: "Amount not shared", meals: 1, tag: .cantTell),
    ])

    /// Wording of each reason page, without its meals. A09 draws "8%" and "41%" on two pages: the rule is no
    /// percentages in reasons, so `moreCame` states the count (the screen works it out) and `lastThirtyMinutes` says it in words.
    static func detail(_ kind: ReasonKind) -> (explanation: String, foodsTitle: String?, foods: [ReasonFood], feedback: [DishFeedbackLine],
                                               missing: [MissingEvidence], meals: [MealID], more: Int, arrivals: ArrivalShape?,
                                               timeline: [ReasonTimelineLine], timelineNote: String?) {
        switch kind {
        case .fewerCame:
            return ("Final entries were well below the headcount sent.", "Foods left over",
                    [ReasonFood(dish: "Sambar", meals: 3, at: nil, mess: nil), ReasonFood(dish: "Rice", meals: 2, at: nil, mess: nil),
                     ReasonFood(dish: "Dal", meals: 2, at: nil, mess: nil)],
                    [], [], [DemoSeed.lunch.id, tueDinnerNorth, monLunchMain], 2, nil, [], nil)
        case .didntLikeDish:
            return ("The dish left over also had at least 3 \"not good\" answers for that meal.", nil, [],
                    [DishFeedbackLine(dish: "Sambar", problem: "Too salty", students: 6)], [], [DemoSeed.lunch.id], 2, nil, [], nil)
        case .raisedLate:
            return ("Raised after the forecast froze, and fewer came than the raised number.", nil, [], [], [],
                    [DemoSeed.lunch.id], 1, nil, [], nil)
        case .cantTellLeftOver:
            return ("Key data is missing for these meals, so MealLoop does not guess.", nil, [], [], [.amountCooked, .wasteRecord],
                    [DemoSeed.lunch.id], 3, nil, [], nil)
        case .moreCame:
            return ("Final entries were well above the headcount sent.", "Foods that ran out",
                    [ReasonFood(dish: "Rice", meals: nil, at: d(12, 20, 40), mess: "South")], [], [], [monDinnerSouth], 0, nil, [], nil)
        case .lastThirtyMinutes:
            // Bar heights measured from A09_reason_last_30_minutes; the pack gives no counts for them.
            return ("Tue 13 · lunch · North. Most entries came in the last 30 minutes.", nil, [], [], [], [], 0,
                    ArrivalShape(barHeights: [45, 54, 64, 72, 80, 100, 145, 150], markerAfterBar: 7,
                                 markerText: "Dashed line: Rice ran out at 1:50 PM.", axisLabels: ["12:00", "1:00", "2:00"]),
                    [], nil)
        case .reportedLate:
            return ("Low stock was reported more than 15 minutes after the first sign.", nil, [], [], [], [tueLunchNorth], 0, nil,
                    [ReasonTimelineLine(at: d(13, 13, 20), text: "Entries above the usual pace (first sign)"),
                     ReasonTimelineLine(at: d(13, 13, 41), text: "Staff reported Rice running low"),
                     ReasonTimelineLine(at: d(13, 13, 50), text: "Rice ran out")],
                    "21 minutes between the first sign and the report.")
        case .cantTellRanOut:
            return ("Key data is missing for this meal, so MealLoop does not guess.", nil, [], [], [.amountCooked, .scannerRecords],
                    [DemoSeed.lunch.id], 0, nil, [], nil)
        }
    }

    static let checks: [CheckNextTime] = [
        CheckNextTime(id: wednesdayPlan, title: "Wednesday lunch", listTitle: "Wednesday lunch plan", mess: "Main", startedOn: d(14, 0, 0),
                      startedBy: "Devi", change: "Use the 4-week average unless an event is confirmed", owner: "Devi",
                      plan: "check 2 Wednesday lunches", comparableTitle: "Comparable meals · Wednesday lunch",
                      comparable: [
                          ComparableMeal(day: d(14, 0, 0), headcountSent: nil, finalEntries: nil, note: nil, isRecorded: false, isComparable: true, ranOut: false),
                          ComparableMeal(day: d(21, 0, 0), headcountSent: nil, finalEntries: nil, note: nil, isRecorded: false, isComparable: true, ranOut: false),
                          ComparableMeal(day: d(28, 0, 0), headcountSent: nil, finalEntries: nil, note: nil, isRecorded: false, isComparable: true, ranOut: false),
                      ],
                      footnote: "Also checks that nothing ran out.", isActionCompleted: true, stage: .testing, notes: [], closedAsWorked: false),
        // F01_results_to_check_north_scanner.
        CheckNextTime(id: northScanner, title: "North scanner", listTitle: "North scanner", mess: "North", startedOn: d(13, 0, 0),
                      startedBy: "Devi", change: "Check the door scanner before every meal", owner: "Ravi",
                      plan: "check 2 North lunches", comparableTitle: "Comparable meals · North lunch",
                      comparable: [
                          ComparableMeal(day: d(13, 0, 0), headcountSent: nil, finalEntries: nil, note: "41 IDs typed by hand", isRecorded: true, isComparable: false, ranOut: false),
                          ComparableMeal(day: d(15, 0, 0), headcountSent: nil, finalEntries: nil, note: nil, isRecorded: false, isComparable: true, ranOut: false),
                          ComparableMeal(day: d(16, 0, 0), headcountSent: nil, finalEntries: nil, note: nil, isRecorded: false, isComparable: true, ranOut: false),
                      ],
                      footnote: "A meal counts only when no IDs were typed by hand.", isActionCompleted: false, stage: .open, notes: [], closedAsWorked: false),
    ]

    // A05_safety_case. "Aarav ••2231" is the masked form the pack gives the reporter.
    static let safetyCases: [AdminSafetyCase] = [
        AdminSafetyCase(id: "safety-wed-lunch", title: "Found something in food", dish: "Sambar", mess: "Main", place: "Main Mess · Block A",
                        slot: .lunch, day: d(14, 0, 0), reportedAt: DemoSeed.sosRaisedAt, accuracyMetres: 8, closedAt: nil,
                        steps: [
                            SafetyStep(title: "Reported", detail: "Aarav ••2231 · 12:45", who: "Student", isDone: true, isCurrent: false),
                            SafetyStep(title: "Hold asked", detail: "Ravi told · 12:50", who: "Staff", isDone: true, isCurrent: true),
                            SafetyStep(title: "Hold confirmed", detail: "Waiting for Ravi", who: "Staff", isDone: false, isCurrent: false),
                            SafetyStep(title: "Vendor told", detail: "Not yet", who: "Vendor", isDone: false, isCurrent: false),
                            SafetyStep(title: "Checked and closed", detail: "Needs a different person", who: "You", isDone: false, isCurrent: false),
                        ], contactName: "Ravi"),
    ]

    private static let sections = [
        ReportSection(title: "Summary and reasons", page: 1), ReportSection(title: "Foods left over", page: 1),
        ReportSection(title: "Changes, safety, data gaps", page: 2),
    ]

    // F02, F03 and COWORK_PROMPT_FIX2.md stage R3.
    static let weeklyReports: [ReportPeriod: AdminWeeklyReport] = [
        .thisWeek: AdminWeeklyReport(
            period: .thisWeek, range: "12 – 18 Aug · all messes", fullRange: "12 – 18 Aug 2024 · All messes", eyebrow: "Last 7 days",
            mealsLeftOver: 4, mealsRanOut: 1, dataCompletePercent: 92, sections: sections,
            pages: ReportPages(
                reasons: [ReportReasonLine(title: "Fewer students came than we planned for", meals: 2, tag: .sure),
                          ReportReasonLine(title: "Students didn't like a dish", meals: 1, tag: .probably),
                          ReportReasonLine(title: "We raised the headcount late", meals: 1, tag: .sure),
                          ReportReasonLine(title: "Can't tell why (amount cooked not shared)", meals: 1, tag: .cantTell)],
                foods: [ReportFoodLine(dish: "Sambar", meals: 2, amount: "7 L"), ReportFoodLine(dish: "Rice", meals: 1, amount: "6 kg"),
                        ReportFoodLine(dish: "Dal", meals: 1, amount: "3 L")],
                ranOutLines: ["Rice ran out at Main, Tue dinner, about 8:34 PM.", "More students came than we planned for (Sure)."],
                byMess: [ReportMessLine(mess: "Main", plateWasteKg: 31, ranOutMeals: 1, dataCompletePercent: 80),
                         ReportMessLine(mess: "North", plateWasteKg: 24, ranOutMeals: 0, dataCompletePercent: 92),
                         ReportMessLine(mess: "Annexe", plateWasteKg: 12, ranOutMeals: 0, dataCompletePercent: 70),
                         ReportMessLine(mess: "South", plateWasteKg: nil, ranOutMeals: nil, dataCompletePercent: nil)],
                changes: [ReportChangeLine(title: "Wednesday lunch: use the 4-week average", detail: "Main · checked after 2 comparable meals", status: "Testing · 1 of 2")],
                safetyLines: ["1 open: Found something in food", "Main · Wed 14 Aug, 12:45 PM · Sambar"],
                dataGaps: ["South sent no data this week.", "Amount cooked was not shared for 9 meals.",
                           "North scanner was offline at Tue lunch; 41 IDs were typed by hand."]),
            vendorSummary: "Hi, this is Devi from MealLoop. Weekly summary, 12 – 18 Aug, all messes: food was left over at 4 meals and ran out at 1 meal. Main reasons: fewer students came than planned for (2 meals) and students didn't like a dish (1 meal). Could you share how much was cooked for each meal?"),
        .lastWeek: AdminWeeklyReport(
            period: .lastWeek, range: "5 – 11 Aug · all messes", fullRange: "5 – 11 Aug 2024 · All messes", eyebrow: "The 7 days before",
            mealsLeftOver: 3, mealsRanOut: 1, dataCompletePercent: 88, sections: sections, pages: nil,
            vendorSummary: "Hi, this is Devi from MealLoop. Weekly summary, 5 – 11 Aug, all messes: food was left over at 3 meals and ran out at 1 meal. Could you share how much was cooked for each meal?"),
        .month: AdminWeeklyReport(
            period: .month, range: "1 – 18 Aug · all messes", fullRange: "1 – 18 Aug 2024 · All messes", eyebrow: "August so far",
            mealsLeftOver: 7, mealsRanOut: 2, dataCompletePercent: 90, sections: sections, pages: nil,
            vendorSummary: "Hi, this is Devi from MealLoop. Summary, 1 – 18 Aug, all messes: food was left over at 7 meals and ran out at 2 meals. Could you share how much was cooked for each meal?"),
    ]

    // MARK: Students

    static let sambarFeedback = FeedbackItemID("sambar-too-salty")
    static let longWait = CommunityIssueID("long-wait-north")

    static let feedback = [
        FeedbackItem(id: sambarFeedback, dish: "Sambar", problem: "too salty", mess: "Main", slot: .lunch, day: d(14, 0, 0), students: 6, isNew: true,
                     problems: [FeedbackProblem(title: "Too salty", severity: "How bad: quite (5), very (1)", students: 6)], meal: DemoSeed.lunch.id),
    ]

    static let community = [
        AdminCommunityIssue(id: longWait, title: "Long wait at North", students: 48, raisedOn: d(12, 0, 0), context: "North Mess · lunch queue",
                       owner: nil, stage: .owner, postedNote: nil),
    ]

    // "Tomorrow lunch" is the day after the story day; A06_students_remind_sheet writes it out.
    static let students = AdminStudentsOverview(
        mealTitle: "Tomorrow lunch", mealLongTitle: "tomorrow lunch (Thu 15 Aug)", totalStudents: 3_500, yes: 2_310, no: 420, notSure: 140,
        reminderMessage: "Lunch tomorrow: are you in? Answer by 9 AM so the kitchen can plan.", reminderSentAt: nil,
        feedback: feedback, community: community)

    // A06_students_why_students_skip. 385 given, 35 with no reason: 420 said no.
    static let skipReasons = StudentSkipReasons(
        mealTitle: "Tomorrow lunch", saidNo: 420,
        reasons: [SkipReason(title: "Class or exam", students: 118), SkipReason(title: "Home or leave", students: 96),
                  SkipReason(title: "Eating elsewhere", students: 74), SkipReason(title: "Don't like the dish", students: 52),
                  SkipReason(title: "Not hungry", students: 31), SkipReason(title: "Other", students: 14)],
        hiddenGroups: ["Dietary reason", "Prefer not to say"], gaveNoReason: 35)

    static let ownerChoices = ["Devi", "Ravi"]

    // MARK: More

    // A12: "Published · Mon 8:10 AM"; A12_weekly_menu_uploading: "Photo of the printed board · 2.1 MB".
    static let weekMenu = WeekMenu(range: "12 – 18 Aug", publishedAt: d(12, 8, 10), today: d(14, 0, 0), copySourceDay: d(8, 0, 0),
                                   photoSize: "2.1 MB", days: AdminMenuSeed.days)

    private static func role(_ id: String, _ title: String, _ singular: String, _ count: Int) -> PeopleRole {
        PeopleRole(id: id, title: title, singular: singular, count: count, messes: nil, permissions: nil, named: [])
    }

    static let people = AdminPeople(
        roles: [role("food-heads", "Food heads", "food head", 2), role("supervisors", "Mess supervisors", "mess supervisor", 4),
                role("door", "Door staff", "door staff", 12),
                // A13_people_kitchen_staff.
                PeopleRole(id: "kitchen", title: "Kitchen staff", singular: "kitchen staff", count: 20, messes: "Main, North, South, Annexe",
                           permissions: "Can: record food left, report low stock, confirm a hold. Cannot: send headcounts or close safety cases.",
                           named: [PersonLine(name: "Ravi", detail: "Kitchen · Main Mess")]),
                role("wardens", "Wardens", "warden", 6), role("gate", "Gate security", "gate security", 4)],
        invited: 2, vendor: VendorContact(phone: "+91 98••• ••214", channel: .message))


    // A11_more_announce_write and _confirm_sheet: "About 860 students at Main Mess"; F05: "All 3,500 students".
    static let announcement = AnnouncementDraft(
        audiences: [AnnouncementAudience(id: "all", title: "All messes", confirmName: "all messes", students: 3_500),
                    AnnouncementAudience(id: "main", title: "Main", confirmName: "Main Mess", students: 860),
                    AnnouncementAudience(id: "north", title: "North", confirmName: "North Mess", students: nil),
                    AnnouncementAudience(id: "south", title: "South", confirmName: "South Mess", students: nil),
                    AnnouncementAudience(id: "annexe", title: "Annexe", confirmName: "Annexe Mess", students: nil)],
        defaultAudience: "main", sampleMessage: "Lunch today starts at 12:15 PM at Main Mess. Sorry for the wait.", maxCharacters: 140)

    // The restyled pages, from their reference images.
    static let passes = PassesPage(mess: "Main Mess", title: "Biryani · closed 2 PM", used: 196, total: 214, expiredUnused: 18,
                                   requestName: "Karan · •••0733", requestStatus: "Reissue asked", requestDetail: "Desk offline · 12:41 PM")
    static let votes = VotesPage(closedTitle: "Idli sambar on Sundays", forPercent: 76, forCount: 1_204, againstCount: 388, advice: "Advice only · you decide",
                                 inProgressTitle: "Masala dosa at breakfast", inProgressDetail: "Vote in progress", timeLeft: "2 d 6 h", newProposals: 3)
    static let rewards = RewardsPage(
        budgetTitle: "Pilot budget · August", spent: "₹2,370", budget: "₹5,000", spentShare: 2_370.0 / 5_000.0, detail: "63 juices · 12 ice creams",
        rewards: [RewardLine(title: "Juice", status: "Live", isLive: true, detail: "₹30 each · 57 left", points: 50),
                  RewardLine(title: "Ice cream", status: "Live", isLive: true, detail: "₹40 each", points: 80),
                  RewardLine(title: "Biryani coupon", status: "Launches Fri", isLive: true, detail: "₹120 each · 0 claimed", points: 200),
                  RewardLine(title: "Fruit bowl", status: "Awaiting SRM", isLive: false, detail: "Not shown to students yet", points: 60)])
    static let spareFood = SpareFoodPage(
        mess: "Main Mess", status: "Awaiting pickup", title: "Lunch spare food", partner: "Partner NGO", collectBy: "3:00 PM", dishes: 4,
        steps: [SpareStep(title: "Offered", time: "2:10 PM", isDone: true), SpareStep(title: "Accepted", time: "2:14 PM", isDone: true),
                SpareStep(title: "Collected", time: "by 3:00 PM", isDone: false)],
        note: "Pickups are logged by the supervisor.")
    static let history = HistoryPage(entriesToday: 6, lines: [HistoryLine(time: "2:20 PM", title: "Lunch waste logged", tag: nil),
                                                              HistoryLine(time: "1:32 PM", title: "Biryani report assigned", tag: "Safety"),
                                                              HistoryLine(time: "12:52 PM", title: "Sambar salt cut", tag: nil)])
    static let outings = OutingsPage(subtitle: "Today · all hostels", outNow: 41, dueBackTitle: "Due back by 8 PM", dueBack: 36, late: 0, lines: [
        OutingLine(title: "Waiting for a warden", detail: "Oldest 2 h", count: 14, status: nil),
        OutingLine(title: "Escalated", detail: "1 pass · Block B", count: 1, status: nil),
        OutingLine(title: "Late returns", detail: "None today", count: 0, status: nil),
        OutingLine(title: "Rules", detail: "Weekday and weekend", count: nil, status: "Draft"),
        OutingLine(title: "Gate log", detail: "Exits and returns", count: nil, status: nil),
    ])
    // A11_more: "Published", "196/214", "41 out", "1 open", "3 live", "2 pickups".
    static let openVotes = 1
    static let liveRewards = 3
    static let pickups = 2
}

/// What the Food Head has changed in this run. A relaunch starts again, like the rest of the demo.
actor DemoAdminStore {
    private var checks = AdminSeed.checks
    private var reviewed: Set<MealID> = []
    private var linkedChecks: [MealID: CheckID] = [:]
    private var reminderKey: IdempotencyKey?
    private var reminderSentAt: Date?
    private var community = AdminSeed.community
    private var menu = AdminSeed.weekMenu
    private var people = AdminSeed.people

    var allChecks: [CheckNextTime] { checks }
    func isReviewed(_ meal: MealID) -> Bool { reviewed.contains(meal) }
    func linkedCheck(_ meal: MealID) -> CheckID? { linkedChecks[meal] }

    func check(_ id: CheckID) throws -> CheckNextTime {
        guard let check = checks.first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        return check
    }

    func addCheck(_ check: CheckNextTime, for meal: MealID?) {
        checks.append(check)
        if let meal { linkedChecks[meal] = check.id }
    }

    func markReviewed(_ meal: MealID) { reviewed.insert(meal) }

    func update(_ id: CheckID, _ change: (inout CheckNextTime) -> Void) throws -> CheckNextTime {
        guard let index = checks.firstIndex(where: { $0.id == id }) else { throw RepositoryError.notFound }
        change(&checks[index])
        return checks[index]
    }

    func remind(key: IdempotencyKey, at now: Date) {
        guard reminderKey != key else { return }
        reminderKey = key
        reminderSentAt = now
    }

    func studentsOverview() -> AdminStudentsOverview {
        let overview = AdminSeed.students
        return AdminStudentsOverview(mealTitle: overview.mealTitle, mealLongTitle: overview.mealLongTitle, totalStudents: overview.totalStudents,
                                     yes: overview.yes, no: overview.no, notSure: overview.notSure, reminderMessage: overview.reminderMessage,
                                     reminderSentAt: reminderSentAt, feedback: overview.feedback, community: community)
    }

    func issue(_ id: CommunityIssueID) throws -> AdminCommunityIssue {
        guard let issue = community.first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        return issue
    }

    func updateIssue(_ id: CommunityIssueID, _ change: (inout AdminCommunityIssue) -> Void) throws -> AdminCommunityIssue {
        guard let index = community.firstIndex(where: { $0.id == id }) else { throw RepositoryError.notFound }
        change(&community[index])
        return community[index]
    }

    var weekMenu: WeekMenu { menu }

    /// When the Food Head last changed each day's menu in this run. Read by the Student Meals tab.
    private(set) var menuChangedAt: [Date: Date] = [:]

    func noteMenuChange(on day: Date, at time: Date) {
        menuChangedAt[day] = time
    }

    func saveDay(_ day: MenuDay) throws -> WeekMenu {
        guard let index = menu.days.firstIndex(where: { $0.day == day.day }) else { throw RepositoryError.notFound }
        menu.days[index] = day
        return menu
    }

    func apply(_ change: QuickChange) throws -> WeekMenu {
        guard let index = menu.days.firstIndex(where: { $0.day == menu.today }) else { throw RepositoryError.notFound }
        var dishes = menu.days[index].meals[.dinner] ?? []
        switch change {
        case .swap(let dish, let replacement):
            guard let row = dishes.firstIndex(where: { $0.name == dish }) else { throw RepositoryError.notFound }
            dishes[row].name = replacement
        case .addSpecial(let name, let isLimited, let isNonVeg):
            dishes.append(MenuDish(id: name, name: name, isHighlight: true, isNonVeg: isNonVeg, needsCheck: false, suggestions: [], isLimited: isLimited))
        case .remove(let dish):
            dishes.removeAll { $0.name == dish }
        }
        menu.days[index].meals[.dinner] = dishes
        return menu
    }

    var currentPeople: AdminPeople { people }

    func addInvite() -> AdminPeople {
        people.invited += 1
        return people
    }

    func setVendor(_ contact: VendorContact) -> AdminPeople {
        people.vendor = contact
        return people
    }
}

/// The Admin repositories for the demo. Connection, clock and the story meal come from the core provider;
/// everything else from `AdminSeed` and `DemoAdminStore`. Only the Food Head / Admin may write.
struct DemoAdminRepositories: AdminResultsRepository, AdminStudentsRepository, AdminMoreRepository {
    let core: DemoDataProvider
    let store: DemoAdminStore

    private func requireFoodHead(_ role: Role) throws {
        guard role == .admin else { throw RepositoryError.notAllowed(reason: "Only the Food Head can do this.") }
    }

    private func allMeals() async throws -> [AdminMealFacts] {
        [try await storyLunch()] + AdminSeed.pastMeals
    }

    /// The story meal, read from the same repositories every other role uses. Until it closes there is no final count.
    private func storyLunch() async throws -> AdminMealFacts {
        let base = AdminSeed.storyLunch
        let headcount = try await core.headcount(for: base.id)
        let history = try await core.mealHistory(for: DemoSeed.mess.id)
        let record = history.first { $0.mealID == base.id }
        var sentAt: Date?
        if case .sent(let sent) = headcount.sentToVendor { sentAt = sent.sentAt }
        let isClosed = record != nil
        // The pack's facts about this meal describe it after service. Before the meal closes none of them has happened.
        var change = isClosed ? base.headcountChange : nil
        if case .approved(let approved) = headcount.approved, let last = approved.adjustments.last {
            change = HeadcountChange(from: last.from, to: last.to, at: last.adjustedAt, reason: last.reason)
        }
        let isWasteRecorded = { if case .recorded = record?.waste { return true } else { return false } }()
        let rows = record?.wasteReport
        let leftovers = (rows?.leftovers ?? []).compactMap { row -> FoodAmount? in
            guard case .entered(let amount) = row.measurement else { return nil }
            return FoodAmount(dish: row.dishName, amount: amount, unit: row.unit)
        }
        var missing = isClosed ? base.missing : []
        if isClosed, !isWasteRecorded { missing.append(.wasteRecord) }
        return AdminMealFacts(
            id: base.id, mess: base.mess, slot: base.slot, day: base.day, headcountSent: headcount.sentToVendor.count, sentAt: sentAt,
            finalEntries: record?.finalEntries.value, closedAt: record?.closedAt, isClosed: isClosed, leftovers: leftovers,
            plateWasteKg: rows?.plateWaste.measuredKilograms, ranOut: isClosed ? base.ranOut : [], wasReportedLate: base.wasReportedLate,
            dataCompletePercent: isClosed && isWasteRecorded ? base.dataCompletePercent : nil, missing: missing, headcountChange: change,
            openQuestions: isClosed ? base.openQuestions : [], needsReview: base.needsReview, linkedCheck: base.linkedCheck, suggestedChange: base.suggestedChange)
    }

    private func withReview(_ meal: AdminMealFacts) async -> AdminMealFacts {
        await reviewed(meal, linked: await store.linkedCheck(meal.id))
    }

    private func reviewed(_ meal: AdminMealFacts, linked: CheckID? = nil) async -> AdminMealFacts {
        let isReviewed = await store.isReviewed(meal.id)
        return AdminMealFacts(
            id: meal.id, mess: meal.mess, slot: meal.slot, day: meal.day, headcountSent: meal.headcountSent, sentAt: meal.sentAt,
            finalEntries: meal.finalEntries, closedAt: meal.closedAt, isClosed: meal.isClosed, leftovers: meal.leftovers,
            plateWasteKg: meal.plateWasteKg, ranOut: meal.ranOut, wasReportedLate: meal.wasReportedLate,
            dataCompletePercent: meal.dataCompletePercent, missing: meal.missing, headcountChange: meal.headcountChange,
            openQuestions: meal.openQuestions, needsReview: meal.needsReview && !isReviewed, linkedCheck: linked ?? meal.linkedCheck,
            suggestedChange: meal.suggestedChange)
    }

    /// The story meal is the first comparable meal of the Wednesday plan, so that row follows it too.
    private func resolved(_ check: CheckNextTime) async throws -> CheckNextTime {
        guard check.id == AdminSeed.wednesdayPlan else { return check }
        let lunch = try await storyLunch()
        let first = check.comparable[0]
        let row = ComparableMeal(day: first.day, headcountSent: lunch.headcountSent, finalEntries: lunch.finalEntries, note: nil,
                                 isRecorded: lunch.finalEntries != nil, isComparable: true, ranOut: !lunch.ranOut.isEmpty)
        return CheckNextTime(id: check.id, title: check.title, listTitle: check.listTitle, mess: check.mess, startedOn: check.startedOn,
                             startedBy: check.startedBy, change: check.change, owner: check.owner, plan: check.plan,
                             comparableTitle: check.comparableTitle, comparable: [row] + check.comparable.dropFirst(),
                             footnote: check.footnote, isActionCompleted: check.isActionCompleted, stage: check.stage, notes: check.notes,
                             closedAsWorked: check.closedAsWorked)
    }

    // MARK: AdminResultsRepository

    func overview() async throws -> AdminResultsOverview {
        try await core.requireConnection()
        var review: [ReviewMeal] = []
        for meal in try await allMeals() where meal.needsReview {
            let current = await withReview(meal)
            if current.needsReview { review.append(ReviewMeal(meal: current)) }
        }
        var changes: [CheckNextTime] = []
        for check in await store.allChecks { changes.append(try await resolved(check)) }
        return AdminResultsOverview(periodTitle: AdminSeed.periodTitle, leftOver: AdminSeed.leftOver, ranOut: AdminSeed.ranOut,
                                    toReview: review, changes: changes)
    }

    func reason(_ kind: ReasonKind) async throws -> AdminReasonDetail {
        try await core.requireConnection()
        guard let reason = (AdminSeed.leftOver.reasons + AdminSeed.ranOut.reasons).first(where: { $0.kind == kind }) else {
            throw RepositoryError.notFound
        }
        let text = AdminSeed.detail(kind)
        let all = try await allMeals()
        var meals = text.meals.compactMap { id in all.first { $0.id == id } }
        // A meal with no final count has no reason yet to be listed under, so it stays out of the cards.
        if kind == .moreCame || kind == .fewerCame { meals = meals.filter { $0.finalEntries != nil } }
        return AdminReasonDetail(reason: reason, explanation: text.explanation, foodsTitle: text.foodsTitle, foods: text.foods,
                                 feedback: text.feedback, missing: text.missing, meals: meals,
                                 moreMeals: text.more + text.meals.count - meals.count, arrivals: text.arrivals,
                                 timeline: text.timeline, timelineNote: text.timelineNote)
    }

    func meal(_ id: MealID) async throws -> AdminMealFacts {
        try await core.requireConnection()
        guard let meal = try await allMeals().first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        return await withReview(meal)
    }

    func findMeals(mess: String?, slot: MealSlot) async throws -> [AdminMealFacts] {
        try await core.requireConnection()
        return try await allMeals()
            .filter { (mess == nil || $0.mess == mess) && $0.slot == slot }
            .sorted { $0.day > $1.day }
    }

    func messNames() async throws -> [String] {
        try await core.requireConnection()
        return AdminSeed.messNames
    }

    func safetyCases() async throws -> [AdminSafetyCase] {
        try await core.requireConnection()
        return AdminSeed.safetyCases
    }

    func check(_ id: CheckID) async throws -> CheckNextTime {
        try await core.requireConnection()
        return try await resolved(try await store.check(id))
    }

    func saveChange(_ draft: ChangeDraft, by role: Role) async throws -> CheckNextTime {
        try await core.requireConnection()
        try requireFoodHead(role)
        let text = draft.change.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw RepositoryError.validationFailed(["Say what will change."]) }
        if let meal = draft.meal {
            await store.markReviewed(meal)
            if let known = try await allMeals().first(where: { $0.id == meal })?.linkedCheck {
                return try await check(known)
            }
            if let known = await store.linkedCheck(meal) { return try await check(known) }
        }
        let new = CheckNextTime(id: CheckID("change-\(UUID().uuidString)"), title: text, listTitle: text, mess: AdminSeed.messNames[0],
                                startedOn: Calendar.current.startOfDay(for: core.clock.now()), startedBy: draft.owner, change: text, owner: draft.owner,
                                plan: "check 2 comparable meals", comparableTitle: "Comparable meals", comparable: [],
                                footnote: "Also checks that nothing ran out.", isActionCompleted: false, stage: .open, notes: [], closedAsWorked: false)
        await store.addCheck(new, for: draft.meal)
        return new
    }

    func addNote(_ note: String, to check: CheckID, by role: Role) async throws -> CheckNextTime {
        try await core.requireConnection()
        try requireFoodHead(role)
        return try await resolved(try await store.update(check) { $0.notes.append(note) })
    }

    func closeAsWorked(_ check: CheckID, by role: Role) async throws -> CheckNextTime {
        try await core.requireConnection()
        try requireFoodHead(role)
        let current = try await resolved(try await store.check(check))
        guard CheckNextTimePolicy.canCloseAsWorked(current) else {
            throw RepositoryError.notAllowed(reason: "A change needs 2 comparable meals, and none that ran out, before it can be called worked.")
        }
        return try await resolved(try await store.update(check) { $0.stage = .result; $0.closedAsWorked = true })
    }

    func weeklyReport(_ period: ReportPeriod) async throws -> AdminWeeklyReport {
        try await core.requireConnection()
        guard let report = AdminSeed.weeklyReports[period] else { throw RepositoryError.notFound }
        return report
    }

    // MARK: AdminStudentsRepository

    func studentsOverview() async throws -> AdminStudentsOverview {
        try await core.requireConnection()
        return await store.studentsOverview()
    }

    func feedback(_ id: FeedbackItemID) async throws -> FeedbackItem {
        try await core.requireConnection()
        guard let item = AdminSeed.feedback.first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        return item
    }

    func community(_ id: CommunityIssueID) async throws -> AdminCommunityIssue {
        try await core.requireConnection()
        return try await store.issue(id)
    }

    func skipReasons() async throws -> StudentSkipReasons {
        try await core.requireConnection()
        return AdminSeed.skipReasons
    }

    func ownerChoices() async throws -> [String] {
        try await core.requireConnection()
        return AdminSeed.ownerChoices
    }

    func remind(key: IdempotencyKey, by role: Role) async throws -> AdminStudentsOverview {
        try await core.requireConnection()
        try requireFoodHead(role)
        await store.remind(key: key, at: core.clock.now())
        return await store.studentsOverview()
    }

    func assignOwner(_ owner: String, to issue: CommunityIssueID, by role: Role) async throws -> AdminCommunityIssue {
        try await core.requireConnection()
        try requireFoodHead(role)
        return try await store.updateIssue(issue) { $0.owner = owner }
    }

    func postNote(_ note: String, on issue: CommunityIssueID, by role: Role) async throws -> AdminCommunityIssue {
        try await core.requireConnection()
        try requireFoodHead(role)
        return try await store.updateIssue(issue) { $0.postedNote = note }
    }

    // MARK: AdminMoreRepository

    func hub() async throws -> AdminMoreHub {
        try await core.requireConnection()
        let invited = await store.currentPeople.invited
        return AdminMoreHub(menuStatus: "Published", passUsed: AdminSeed.passes.used, passTotal: AdminSeed.passes.total,
                            outNow: AdminSeed.outings.outNow, openVotes: AdminSeed.openVotes, liveRewards: AdminSeed.liveRewards,
                            pickups: AdminSeed.pickups, invited: invited)
    }

    func weekMenu() async throws -> WeekMenu {
        try await core.requireConnection()
        return await store.weekMenu
    }

    func copySource(for day: Date, slot: MealSlot) async throws -> [MenuDish] {
        try await core.requireConnection()
        guard let source = AdminSeed.weekMenu.days.first(where: { $0.day == day })?.meals[slot] else { throw RepositoryError.notFound }
        return source
    }

    func earlierDishes() async throws -> [String] {
        try await core.requireConnection()
        var seen = Set<String>()
        return AdminSeed.weekMenu.days.flatMap { day in MealSlot.allCases.flatMap { day.meals[$0] ?? [] } }
            .map(\.name).filter { seen.insert($0).inserted }
    }

    func saveDay(_ day: MenuDay, by role: Role) async throws -> WeekMenu {
        try await core.requireConnection()
        try requireFoodHead(role)
        let saved = try await store.saveDay(day)
        await store.noteMenuChange(on: day.day, at: core.clock.now())
        return saved
    }

    func applyToTodaysDinner(_ change: QuickChange, by role: Role) async throws -> WeekMenu {
        try await core.requireConnection()
        try requireFoodHead(role)
        let saved = try await store.apply(change)
        await store.noteMenuChange(on: saved.today, at: core.clock.now())
        return saved
    }

    func people() async throws -> AdminPeople {
        try await core.requireConnection()
        return await store.currentPeople
    }

    func invite(phone: String, role: String, by actor: Role) async throws -> AdminPeople {
        try await core.requireConnection()
        try requireFoodHead(actor)
        guard phone.contains(where: \.isNumber) else { throw RepositoryError.validationFailed(["Enter a phone number."]) }
        return await store.addInvite()
    }

    func saveVendorContact(_ contact: VendorContact, by role: Role) async throws -> AdminPeople {
        try await core.requireConnection()
        try requireFoodHead(role)
        return await store.setVendor(contact)
    }

    func announcementDraft() async throws -> AnnouncementDraft {
        try await core.requireConnection()
        return AdminSeed.announcement
    }

    func announce(_ message: String, to audience: String, by role: Role) async throws {
        try await core.requireConnection()
        try requireFoodHead(role)
        let limit = AdminSeed.announcement.maxCharacters
        guard !message.isEmpty, message.count <= limit else { throw RepositoryError.validationFailed(["Up to \(limit) characters."]) }
    }

    func passes() async throws -> PassesPage { try await core.requireConnection(); return AdminSeed.passes }
    func votes() async throws -> VotesPage { try await core.requireConnection(); return AdminSeed.votes }
    func rewards() async throws -> RewardsPage { try await core.requireConnection(); return AdminSeed.rewards }
    func spareFood() async throws -> SpareFoodPage { try await core.requireConnection(); return AdminSeed.spareFood }
    func history() async throws -> HistoryPage { try await core.requireConnection(); return AdminSeed.history }
    func outings() async throws -> OutingsPage { try await core.requireConnection(); return AdminSeed.outings }
}
#endif
