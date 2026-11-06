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
    func startMeal(_ meal: MealID, by role: Role) async throws -> MealStatus
    func closeMeal(_ meal: MealID, by role: Role) async throws -> MealStatus
}

/// The six headcount quantities of a meal and the vendor's acknowledgment.
protocol HeadcountRepository: Sendable {
    func headcount(for meal: MealID) async throws -> Headcount
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
}

/// Student answers (I'm in / Skip / Not sure) before the cutoff.
protocol IntentionRepository: Sendable {
    func response(of student: StudentID, for meal: MealID) async throws -> IntentionResponse
    func setIntention(_ intention: MealIntention, of student: StudentID, for meal: MealID) async throws -> IntentionResponse
}

/// Shortages reported by the kitchen or the pass desk, followed up by the Supervisor.
protocol ShortageRepository: Sendable {
    func reportShortage(_ report: ShortageReport) async throws -> Shortage
    func shortages(for meal: MealID) async throws -> [Shortage]
    func markResolved(_ shortage: ShortageID, by role: Role) async throws -> Shortage
}

/// Leftovers per dish and one plate-waste total, recorded after the meal only.
protocol WasteReportRepository: Sendable {
    func summary(for meal: MealID) async throws -> WasteReportSummary
    func report(for meal: MealID) async throws -> WasteReport
    func saveDraft(_ report: WasteReport) async throws -> WasteReport
    /// Throws `validationFailed` while any field is missing or invalid.
    func save(_ report: WasteReport) async throws -> WasteReport
}

/// SOS cases. Staff claim and check; only the Supervisor closes.
protocol SOSRepository: Sendable {
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
/// Not implemented: special-meal pass check, lookup and reissue requests (Pass Desk).
protocol SpecialPassRepository: Sendable {}
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
}
