import Foundation

// Repository protocols. Views and view models depend only on these; they never touch data directly.
// Keep each protocol small and async. Implementations live in Data/Demo (seeded, Debug and Review only) and Data/Remote (HTTP, not implemented yet).

/// Menus and meals. Used by Kitchen (Menu for Lunch), Student (Meals) and Admin (Weekly menu).
protocol MealRepository: Sendable {
    func menu(for meal: MealID) async throws -> [Dish]
}

/// The meal lifecycle for one mess. Started and closed by the Supervisor; read by every staff role.
protocol MealStateRepository: Sendable {
    /// The meal the mess is in or about to start, or nil when there is none today.
    func currentMeal(for mess: MessID) async throws -> MealStatus?
    /// Every meal of the day for one mess, earliest first.
    func meals(for mess: MessID) async throws -> [MealStatus]
    func startMeal(_ meal: MealID, by role: Role) async throws -> MealStatus
    func closeMeal(_ meal: MealID, by role: Role) async throws -> MealStatus
    /// Closed meals of one mess, newest first, with their final entries, shortages and waste status. Read only.
    func mealHistory(for mess: MessID) async throws -> [MealRecord]
}

/// The six headcount quantities of a meal and the vendor's acknowledgment.
protocol HeadcountRepository: Sendable {
    func headcount(for meal: MealID) async throws -> Headcount
    /// Food Head / Admin only. A count that differs from the forecast or an earlier approval needs a reason.
    /// A repeat of the same count changes nothing. Refused once the headcount has been sent.
    func approveHeadcount(_ count: Int, reason: String?, for meal: MealID, by role: Role) async throws -> Headcount
    /// Sends the approved headcount to the vendor account. Food Head / Admin only. A repeat changes nothing.
    func publishHeadcount(for meal: MealID, by role: Role) async throws -> Headcount
    /// Records receipt by the vendor account. Throws `notAllowed` for any other account or before publication.
    /// A repeat returns the first acknowledgment unchanged.
    func acknowledgeHeadcount(for meal: MealID, by account: AccountID) async throws -> Headcount
}

/// Verified entry at the door. Scans are idempotent and a student is never counted twice for one meal.
protocol EntryRepository: Sendable {
    func recordEntry(_ request: EntryRequest) async throws -> EntryResult
    /// Students who have entered so far (live, never final).
    func liveCount(for meal: MealID) async throws -> CountReading
    /// Final entries after the meal closed, or `.unavailable` (never zero).
    func finalCount(for meal: MealID) async throws -> CountReading
    func enteredWithoutVoting(for meal: MealID) async throws -> [EnteredWithoutVoting]
    /// Always available: never gated by the answer, the cutoff or a lost connection.
    func entryCode(for student: StudentID) async throws -> EntryCode
    /// Checks a scanned or typed credential. It records nothing; `recordEntry` does that.
    func resolveEntry(_ credential: EntryCredential, for meal: MealID) async throws -> EntryCredentialResult
}

/// Student answers (I'm in / Skip / Not sure) before the cutoff.
protocol IntentionRepository: Sendable {
    func response(of student: StudentID, for meal: MealID) async throws -> IntentionResponse
    /// The same answer again changes nothing. Throws `notAllowed` after the meal's cutoff.
    func setIntention(_ intention: MealIntention, of student: StudentID, for meal: MealID) async throws -> IntentionResponse
    func answerCounts(for meal: MealID) async throws -> MealAnswerCounts
}

/// Shortages reported by the kitchen or the pass desk, followed up by the Supervisor.
protocol ShortageRepository: Sendable {
    func reportShortage(_ report: ShortageReport) async throws -> Shortage
    func shortages(for meal: MealID) async throws -> [Shortage]
    func markResolved(_ shortage: ShortageID, by role: Role) async throws -> Shortage
    /// The Supervisor has read the report, so the kitchen may show "Ravi saw it". Supervisor only.
    /// A repeat keeps the first sighting.
    func markSeen(_ shortage: ShortageID, by role: Role) async throws -> Shortage
}

/// Leftovers per dish and one plate-waste total, recorded after the meal only.
protocol WasteReportRepository: Sendable {
    func summary(for meal: MealID) async throws -> WasteReportSummary
    func report(for meal: MealID) async throws -> WasteReport
    /// Kitchen Staff only; every other role reads the report. Throws `notAllowed` for any other role.
    func saveDraft(_ report: WasteReport, by role: Role) async throws -> WasteReport
    /// Throws `validationFailed` while any field is missing or invalid.
    func save(_ report: WasteReport, by role: Role) async throws -> WasteReport
}

/// SOS cases. Staff claim and check; only the Supervisor closes.
protocol SOSRepository: Sendable {
    /// Opens a case for the mess. A repeat with the same idempotency key returns the case already opened.
    func raise(_ report: SOSReport) async throws -> SOSCase
    func activeCases(for mess: MessID) async throws -> [SOSCase]
    func claim(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase
    func markChecked(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase
    func close(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase
}

/// Sign-in. Every method returns the session the data source vouches for; the client never picks a role itself.
protocol AuthRepository: Sendable {
    /// Throws `invalidCredentials` for a wrong password or an unknown email, without saying which.
    func signInStaff(email: String, password: String) async throws -> Session
    /// SRM SSO feasibility is unverified. No real SRM integration exists anywhere in this app.
    func signInWithSRM() async throws -> Session
    #if DEMO_DATA
    /// The shared role password (4 digits, 3 tries). A Debug-only prototype interaction, never production authentication.
    func verifyRolePassword(_ password: String, for role: Role) async throws -> RolePasswordResult
    #endif
}

// MARK: - Documented stubs (no implementation and no caller yet)
// Add methods when the first screen that needs them is built, following the contracts in docs/backend/openapi.yaml.

/// Not implemented: Student feedback and My feedback.
protocol FeedbackRepository: Sendable {}
/// Not implemented: Community issues and "Me too" support.
protocol CommunityRepository: Sendable {}
/// The special-meal pass: lookup, recording and reissue requests (Pass Desk). There is no camera and no scan.
protocol SpecialPassRepository: Sendable {
    /// Status only: it never records and never changes a count.
    func lookUpPass(lastFour: String, for meal: MealID) async throws -> SpecialPassLookup
    /// The next code and colour, once the current window has run out.
    func refreshPassCode(for student: StudentID, meal: MealID) async throws -> LivePassCode
    /// Pass Desk only. A student is recorded at most once per meal; the same idempotency key returns the first result.
    func recordPassEntry(_ request: SpecialPassEntryRequest) async throws -> SpecialPassEntryResult
    func specialMealCount(for meal: MealID) async throws -> SpecialMealCount
    /// Readable by any role: the entries recorded for this meal, oldest first.
    func specialMealEntries(for meal: MealID) async throws -> [SpecialPassEntry]
    func reissueRequests(for mess: MessID) async throws -> [PassReissueRequest]
    /// Pass Desk only. A new request is always Waiting; only the admin pass-exception flow moves it on.
    func requestReissue(_ submission: PassReissueSubmission) async throws -> PassReissueRequest
}

/// The answer of any data source with no pass service yet. It never fakes a result.
struct UnavailableSpecialPasses: SpecialPassRepository {
    private var unavailable: RepositoryError { .notImplemented(feature: "Special-meal passes") }

    func lookUpPass(lastFour: String, for meal: MealID) async throws -> SpecialPassLookup { throw unavailable }
    func refreshPassCode(for student: StudentID, meal: MealID) async throws -> LivePassCode { throw unavailable }
    func recordPassEntry(_ request: SpecialPassEntryRequest) async throws -> SpecialPassEntryResult { throw unavailable }
    func specialMealCount(for meal: MealID) async throws -> SpecialMealCount { throw unavailable }
    func specialMealEntries(for meal: MealID) async throws -> [SpecialPassEntry] { throw unavailable }
    func reissueRequests(for mess: MessID) async throws -> [PassReissueRequest] { throw unavailable }
    func requestReissue(_ submission: PassReissueSubmission) async throws -> PassReissueRequest { throw unavailable }
}
/// Not implemented: digital outings (student, guardian, warden, gate).
protocol OutingRepository: Sendable {}

/// Optional and separate. Core dining actions must never depend on it. Nothing implements it yet.
protocol IntelligenceService: Sendable {}

/// The set of repositories the app runs with. Exactly one source (demo or api) per running app; never mixed.
struct Repositories: Sendable {
    let meals: any MealRepository
    let mealState: any MealStateRepository
    let headcount: any HeadcountRepository
    let entries: any EntryRepository
    let intentions: any IntentionRepository
    let shortages: any ShortageRepository
    let wasteReports: any WasteReportRepository
    let sos: any SOSRepository
    let auth: any AuthRepository
    /// Defaulted, so every existing caller stays as it was and a source without a pass service says so.
    var specialPasses: any SpecialPassRepository = UnavailableSpecialPasses()
    /// Defaulted for the same reason.
    var studentExtras: any StudentExtrasRepository = UnavailableStudentExtras()
    var studentMeals: any StudentMealsRepository = UnavailableStudentMeals()
    var studentCommunity: any StudentCommunityRepository = UnavailableStudentCommunity()
    var adminResults: any AdminResultsRepository = AdminDataNotBuilt()
    var adminStudents: any AdminStudentsRepository = AdminDataNotBuilt()
    var adminMore: any AdminMoreRepository = AdminDataNotBuilt()
    var adminMesses: any AdminMessRepository = AdminMessesNotBuilt()
    /// Defaulted, so every existing caller stays as it was and a source without a directory says nothing.
    var staffDirectory: any StaffDirectoryRepository = UnavailableStaffDirectory()
}
