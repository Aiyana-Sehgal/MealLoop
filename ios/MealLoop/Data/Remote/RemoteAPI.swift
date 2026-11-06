import Foundation

/// Placeholder for the future HTTP implementation (see docs/backend/openapi.yaml).
/// Not implemented: every method throws `RepositoryError.notImplemented` and never fakes success.
struct RemoteAPI: MealRepository, MealStateRepository, HeadcountRepository, EntryRepository, IntentionRepository,
    ShortageRepository, WasteReportRepository, SOSRepository, AuthRepository {
    /// Set by the build configuration when the backend exists. Unused until then.
    let baseURL: URL?

    private func notImplemented(_ feature: String) -> RepositoryError {
        .notImplemented(feature: "Remote · \(feature)")
    }

    func menu(for meal: MealID) async throws -> [Dish] { throw notImplemented("menu") }

    func currentMeal(for mess: MessID) async throws -> MealStatus? { throw notImplemented("current meal") }
    func startMeal(_ meal: MealID, by role: Role) async throws -> MealStatus { throw notImplemented("start meal") }
    func closeMeal(_ meal: MealID, by role: Role) async throws -> MealStatus { throw notImplemented("close meal") }
    func meals(for mess: MessID) async throws -> [MealStatus] { throw notImplemented("meals") }
    func mealHistory(for mess: MessID) async throws -> [MealRecord] { throw notImplemented("meal history") }

    func headcount(for meal: MealID) async throws -> Headcount { throw notImplemented("headcount") }
    func approveHeadcount(_ count: Int, reason: String?, for meal: MealID, by role: Role) async throws -> Headcount {
        throw notImplemented("approve headcount")
    }
    func publishHeadcount(for meal: MealID, by role: Role) async throws -> Headcount { throw notImplemented("publish headcount") }
    func acknowledgeHeadcount(for meal: MealID, by account: AccountID) async throws -> Headcount {
        throw notImplemented("acknowledge headcount")
    }

    func recordEntry(_ request: EntryRequest) async throws -> EntryResult { throw notImplemented("record entry") }
    func liveCount(for meal: MealID) async throws -> CountReading { throw notImplemented("live entries") }
    func finalCount(for meal: MealID) async throws -> CountReading { throw notImplemented("final entries") }
    func enteredWithoutVoting(for meal: MealID) async throws -> [EnteredWithoutVoting] { throw notImplemented("entered without voting") }
    func entryCode(for student: StudentID) async throws -> EntryCode { throw notImplemented("entry code") }
    func resolveEntry(_ credential: EntryCredential, for meal: MealID) async throws -> EntryCredentialResult {
        throw notImplemented("resolve entry")
    }

    func response(of student: StudentID, for meal: MealID) async throws -> IntentionResponse { throw notImplemented("intention") }
    func setIntention(_ intention: MealIntention, of student: StudentID, for meal: MealID) async throws -> IntentionResponse {
        throw notImplemented("set intention")
    }
    func answerCounts(for meal: MealID) async throws -> MealAnswerCounts { throw notImplemented("answer counts") }

    func reportShortage(_ report: ShortageReport) async throws -> Shortage { throw notImplemented("report shortage") }
    func shortages(for meal: MealID) async throws -> [Shortage] { throw notImplemented("shortages") }
    func markResolved(_ shortage: ShortageID, by role: Role) async throws -> Shortage { throw notImplemented("resolve shortage") }

    func summary(for meal: MealID) async throws -> WasteReportSummary { throw notImplemented("waste report summary") }
    func report(for meal: MealID) async throws -> WasteReport { throw notImplemented("waste report") }
    func saveDraft(_ report: WasteReport, by role: Role) async throws -> WasteReport { throw notImplemented("save waste draft") }
    func save(_ report: WasteReport, by role: Role) async throws -> WasteReport { throw notImplemented("save waste report") }

    func raise(_ report: SOSReport) async throws -> SOSCase { throw notImplemented("raise SOS") }
    func activeCases(for mess: MessID) async throws -> [SOSCase] { throw notImplemented("SOS cases") }
    func claim(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase { throw notImplemented("claim SOS") }
    func markChecked(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase { throw notImplemented("check SOS") }
    func close(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase { throw notImplemented("close SOS") }

    func signInStaff(email: String, password: String) async throws -> Session { throw RepositoryError.notImplemented(feature: "Remote sign in") }
    func signInWithSRM() async throws -> Session { throw RepositoryError.notImplemented(feature: "Remote sign in") }

    #if DEMO_DATA
    func verifyRolePassword(_ password: String, for role: Role) async throws -> RolePasswordResult {
        throw notImplemented("role password")
    }
    #endif

    func makeRepositories() -> Repositories {
        Repositories(meals: self, mealState: self, headcount: self, entries: self, intentions: self,
                     shortages: self, wasteReports: self, sos: self, auth: self)
    }
}
