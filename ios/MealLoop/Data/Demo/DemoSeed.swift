#if DEMO_DATA || REVIEW_DATA
import Foundation

/// DEMO DATA. Seeded sample values for the Debug and Review builds only. Never pilot data and never measured results.
/// Every value below is copied from the design documentation; the source is named next to it.
/// Sample names such as "Main Mess" are placeholders (the pilot is planned at Meenakshi Girls' Mess).
enum DemoSeed {
    // design/reference/kitchen_2026-10/data/kitchen_spec.md: "Main Mess, Lunch, Wed 14 Aug 2024, 12 to 2 PM".
    // The mess time zone is India's; the time zone is not a sample value.
    static let mess = Mess(id: MessID("demo-main-mess"), name: "Main Mess", timeZoneIdentifier: "Asia/Kolkata")

    static let lunch = Meal(
        id: MealID("demo-2024-08-14-lunch"),
        messID: mess.id,
        slot: .lunch,
        startsAt: time(12, 0),
        endsAt: time(14, 0)
    )

    // kitchen_spec.md: Wed lunch dishes and their units ("Chappathi = pieces; Sambar, Dal and Rasam = L; the rest kg").
    static let lunchMenu: [Dish] = [
        Dish(id: DishID("bhindi-aloo-bujjiya"), name: "Bhindi Aloo Bujjiya", isHighlight: true, diet: .veg, wasteUnit: .kilograms),
        Dish(id: DishID("steamed-rice"), name: "Steamed Rice", isHighlight: false, diet: .veg, wasteUnit: .kilograms),
        Dish(id: DishID("chappathi"), name: "Chappathi", isHighlight: false, diet: .veg, wasteUnit: .pieces),
        Dish(id: DishID("muttar-masala"), name: "Muttar Masala", isHighlight: false, diet: .veg, wasteUnit: .kilograms),
        Dish(id: DishID("veg-pulao"), name: "Veg Pulao", isHighlight: false, diet: .veg, wasteUnit: .kilograms),
        Dish(id: DishID("masala-sambar"), name: "Masala Sambar", isHighlight: false, diet: .veg, wasteUnit: .litres),
        Dish(id: DishID("tomato-dal"), name: "Tomato Dal", isHighlight: false, diet: .veg, wasteUnit: .litres),
        Dish(id: DishID("garlic-rasam"), name: "Garlic Rasam", isHighlight: false, diet: .veg, wasteUnit: .litres),
    ]

    // 03_home: "Serving 7:30–9:30 AM".
    static let breakfast = Meal(
        id: MealID("demo-2024-08-14-breakfast"),
        messID: mess.id,
        slot: .breakfast,
        startsAt: time(7, 30),
        endsAt: time(9, 30)
    )

    // 03_home is drawn at 7:00 AM. The Review build starts here, with the lunch answer window open.
    static let storyStartNow = time(7, 0)
    // Owner decision: approving the headcount moves the story to just after the lunch cutoff.
    static let approvalAfterCutoff: TimeInterval = 5 * 60

    // kitchen_spec.md: "Forecasted attendance 860. Entries 714 at 1:40 PM; final 774."
    static let forecastDiners = 860
    // kitchen_spec.md stale state: "Updated 8:50 AM, may be out of date".
    static let forecastSetAt = time(8, 50)
    static let liveEntries = 714
    static let liveEntriesAt = time(13, 40)
    // kitchen_spec.md stale state: "Updated 1:12 PM · reconnecting".
    static let staleEntriesAt = time(13, 12)
    static let finalEntries = 774
    // supervisor_spec.md: closed "2:00 PM".
    static let closedAt = time(14, 0)

    // Clock moments of the exported frames: K01 11:30 AM, K02 / K03 1:40 PM, K05 2:05 PM.
    static let beforeMealNow = time(11, 30)
    static let duringMealNow = time(13, 40)
    static let afterMealNow = time(14, 5)

    // supervisor_spec.md: "Shortage: Steamed Rice, almost out, posted 1:30 PM by the kitchen."
    static let shortageDish = "Steamed Rice"
    static let shortageLevel: ShortageLevel = .almostOut
    static let shortageReportedAt = time(13, 30)

    // supervisor_spec.md: "SOS: Found something in food, Main Mess Block A, 12:45 PM."
    static let sosTitle = "Found something in food"
    // S04 and S08 draw the place as "Main Mess · Block A".
    static let sosPlace = "Main Mess · Block A"
    static let sosRaisedAt = time(12, 45)

    // kitchen_spec.md: "Recorded -> 'Recorded · 2:40 PM', 'You can edit until 8:40 PM.'"
    static let wasteRecordedAt = time(14, 40)

    // MARK: Meal history (supervisor S18, S19b to S19f, S10, S11)

    // S19d: Wed 14 · Breakfast, final entries 402, "1 shortage · Resolved" (no item or time drawn),
    // waste "Recorded · 10:05 AM".
    static let breakfastFinalEntries = 402
    static let breakfastWasteRecordedAt = time(10, 5)

    /// A closed meal before the story day. Only what the pack draws is filled in.
    struct PastMeal: Sendable {
        let id: MealID
        let slot: MealSlot
        let day: Date
        let finalEntries: Int?
        let shortages: [MealRecord.ShortageLine]
        let waste: MealRecord.WasteStatus
        let wasteReport: WasteReport?
    }

    private static let tuesdayLunchID = MealID("demo-2024-08-13-lunch")

    /// Newest first. S18 draws Tue 13 · Dinner, Tue 13 · Lunch and Mon 12 · Dinner under the story day.
    static let pastMeals: [PastMeal] = [
        // S11, S19e: 598 entered, no shortage, waste not recorded.
        PastMeal(id: MealID("demo-2024-08-13-dinner"), slot: .dinner, day: date(13, 0, 0), finalEntries: 598,
                 shortages: [], waste: .notRecorded, wasteReport: nil),
        // S19: 806 entered; Steamed Rice resolved 1:52 PM; recorded by the kitchen 2:40 PM.
        PastMeal(id: tuesdayLunchID, slot: .lunch, day: date(13, 0, 0), finalEntries: 806,
                 shortages: [MealRecord.ShortageLine(dishName: "Steamed Rice", outcome: .resolved(at: date(13, 13, 52)))],
                 waste: .recorded(at: date(13, 14, 40)), wasteReport: tuesdayLunchWaste),
        // S19f: final entries Unavailable, no shortage, waste recorded (no time drawn).
        PastMeal(id: MealID("demo-2024-08-12-dinner"), slot: .dinner, day: date(12, 0, 0), finalEntries: nil,
                 shortages: [], waste: .recorded(at: nil), wasteReport: nil),
    ]

    // S10: "Steamed Rice 4 kg, Masala Sambar 3 L, Muttar Masala 0 kg · none left, Chappathi 12 pieces",
    // "Plate waste, whole meal 21 kg", recorded 2:40 PM.
    private static var tuesdayLunchWaste: WasteReport {
        func row(_ id: String, _ name: String, _ unit: WasteUnit, _ measurement: LeftoverMeasurement) -> DishLeftover {
            DishLeftover(dishID: DishID(id), dishName: name, unit: unit, measurement: measurement)
        }
        return WasteReport(
            mealID: tuesdayLunchID,
            leftovers: [
                row("steamed-rice", "Steamed Rice", .kilograms, .entered(4)),
                row("masala-sambar", "Masala Sambar", .litres, .entered(3)),
                row("muttar-masala", "Muttar Masala", .kilograms, .noneLeft),
                row("chappathi", "Chappathi", .pieces, .entered(12)),
            ],
            plateWaste: .entered(kilograms: 21),
            status: .recorded(savedAt: date(13, 14, 40))
        )
    }

    // PROJECT_CONTEXT.md sample rules: offline banner "Offline · saved 1:38 PM".
    static let offlineSavedAt = time(13, 38)

    // Staff initials and the supervisor from the role specs (door SK, pass desk SK, kitchen AK, supervisor RV, Ravi).
    static let supervisorName = "Ravi"
    static func staffInitials(for role: Role) -> String {
        switch role {
        case .doorScanner, .passDesk: return "SK"
        case .kitchenStaff: return "AK"
        case .supervisor: return "RV"
        default: return "—"
        }
    }

    // STATE.md: "Aarav ••0238".
    static let sampleStudent = StudentRef(id: StudentID("demo-student-0238"), maskedID: "••0238")

    /// SAMPLE, NOT MEASURED. A small labelled roster so the answer counts and the door have someone to work with.
    /// Names and IDs come from the design documents; the answers are made up (docs/OPEN_DECISIONS.md, P-STORY-2).
    /// The student account starts with no lunch answer.
    struct SampleStudent: Sendable {
        let name: String
        let ref: StudentRef
        let lunchAnswer: MealIntention?
        /// A placeholder code: opaque, static and valid only in this prototype.
        var entryCode: EntryCode {
            let lastFour = String(ref.maskedID.suffix(4))
            return EntryCode(payload: "demo-entry-\(lastFour)", lastFour: lastFour)
        }
    }

    static let sampleStudents: [SampleStudent] = [
        SampleStudent(name: "Aarav", ref: sampleStudent, lunchAnswer: nil),
        SampleStudent(name: "Meera", ref: StudentRef(id: StudentID("demo-student-0412"), maskedID: "••0412"), lunchAnswer: .attending),
        SampleStudent(name: "Kiran", ref: StudentRef(id: StudentID("demo-student-0377"), maskedID: "••0377"), lunchAnswer: .skipping),
        SampleStudent(name: "Dev", ref: StudentRef(id: StudentID("demo-student-0190"), maskedID: "••0190"), lunchAnswer: .notSure),
    ]

    // Before the breakfast cutoff (5:30 AM), so 03_home's "You're in for breakfast" is true. Owner decision.
    static let sampleBreakfastAnswer = IntentionResponse.answered(.attending, at: time(5, 0))
    // Before the story starts, so the sample answers already exist at 7:00 AM.
    static let sampleLunchAnswersAt = time(6, 30)

    #if DEMO_DATA
    /// NOT FROM THE DESIGN. The design documents no password value; this placeholder exists only so the
    /// simulated password page can be tried. Recorded in docs/OPEN_DECISIONS.md.
    static let simulatedRolePassword = "1234"
    #endif

    // MARK: - Accounts

    /// The one prototype credential for every seeded account. Never shown in a View and never logged.
    static let prototypePassword = "MealLoop-2026"

    static let hostelID = HostelID("demo-main-hostel")

    /// One account per role, listed for the presenter in docs/PRESENTER_ACCOUNTS.md.
    /// Staff use the initials from the role specs, and the food head is the design's sample person
    /// (design_intent.md, "Devi Raman, Food head", initials DR). The design names no one else here, so the
    /// other names describe the post rather than invent a person. `.example` addresses are never real.
    static let accounts: [Account] = [
        account("student", "Aarav", .student, .hostel(hostelID)),
        account("superadmin", "SRM admin", .superAdmin, .mess(mess.id)),
        account("foodhead", "Devi Raman", .admin, .mess(mess.id)),
        account("supervisor", supervisorName, .supervisor, .mess(mess.id)),
        account("kitchen", staffInitials(for: .kitchenStaff), .kitchenStaff, .mess(mess.id)),
        account("door", staffInitials(for: .doorScanner), .doorScanner, .mess(mess.id)),
        account("passdesk", staffInitials(for: .passDesk), .passDesk, .mess(mess.id)),
        account("vendor", "Mess vendor", .vendor, .mess(mess.id)),
        account("guardian", "Aarav's guardian", .guardian, .hostel(hostelID)),
        account("warden", "Hostel warden", .warden, .hostel(hostelID)),
        account("gate", "Main gate", .gate, .hostel(hostelID)),
    ]

    private static func account(_ handle: String, _ name: String, _ role: Role, _ scope: AccountScope) -> Account {
        Account(id: AccountID("demo-account-\(handle)"), displayName: name, email: "\(handle)@mealloop.example",
                role: role, scope: scope)
    }

    // MARK: - Helpers

    /// A time on another day of the sample week (August 2024), in the mess time zone.
    static func date(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        let components = DateComponents(year: 2024, month: 8, day: day, hour: hour, minute: minute)
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    /// A time on the sample day, Wed 14 Aug 2024, in the mess time zone.
    static func time(_ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        let components = DateComponents(year: 2024, month: 8, day: 14, hour: hour, minute: minute)
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }
}
#endif
