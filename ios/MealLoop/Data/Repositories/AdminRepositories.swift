import Foundation

// Repositories for the Food Head's Students, Results and More tabs. Every write takes the role and is refused
// for anyone but the Food Head / Admin.

protocol AdminResultsRepository: Sendable {
    func overview() async throws -> AdminResultsOverview
    func reason(_ kind: ReasonKind) async throws -> AdminReasonDetail
    func meal(_ id: MealID) async throws -> AdminMealFacts
    /// Meals of the period. A nil mess means every mess.
    func findMeals(mess: String?, slot: MealSlot) async throws -> [AdminMealFacts]
    func messNames() async throws -> [String]
    func safetyCases() async throws -> [AdminSafetyCase]
    func check(_ id: CheckID) async throws -> CheckNextTime
    /// Marks the meal reviewed. A meal that already feeds a change returns that change.
    func saveChange(_ draft: ChangeDraft, by role: Role) async throws -> CheckNextTime
    func addNote(_ note: String, to check: CheckID, by role: Role) async throws -> CheckNextTime
    /// Throws `notAllowed` until `CheckNextTimePolicy.canCloseAsWorked` says yes.
    func closeAsWorked(_ check: CheckID, by role: Role) async throws -> CheckNextTime
    func weeklyReport(_ period: ReportPeriod) async throws -> AdminWeeklyReport
}

protocol AdminStudentsRepository: Sendable {
    func studentsOverview() async throws -> AdminStudentsOverview
    func feedback(_ id: FeedbackItemID) async throws -> FeedbackItem
    func community(_ id: CommunityIssueID) async throws -> AdminCommunityIssue
    func skipReasons() async throws -> StudentSkipReasons
    func ownerChoices() async throws -> [String]
    /// SIMULATED: records that the reminder went. A repeat with the same key changes nothing.
    func remind(key: IdempotencyKey, by role: Role) async throws -> AdminStudentsOverview
    func assignOwner(_ owner: String, to issue: CommunityIssueID, by role: Role) async throws -> AdminCommunityIssue
    func postNote(_ note: String, on issue: CommunityIssueID, by role: Role) async throws -> AdminCommunityIssue
}

protocol AdminMoreRepository: Sendable {
    func hub() async throws -> AdminMoreHub
    func weekMenu() async throws -> WeekMenu
    /// The week as saved before any edit, for "Copy last Thursday".
    func copySource(for day: Date, slot: MealSlot) async throws -> [MenuDish]
    func earlierDishes() async throws -> [String]
    func saveDay(_ day: MenuDay, by role: Role) async throws -> WeekMenu
    func applyToTodaysDinner(_ change: QuickChange, by role: Role) async throws -> WeekMenu
    func people() async throws -> AdminPeople
    /// SIMULATED: nothing is delivered.
    func invite(phone: String, role: String, by actor: Role) async throws -> AdminPeople
    func saveVendorContact(_ contact: VendorContact, by role: Role) async throws -> AdminPeople
    func announcementDraft() async throws -> AnnouncementDraft
    /// SIMULATED: nothing is delivered.
    func announce(_ message: String, to audience: String, by role: Role) async throws
    func passes() async throws -> PassesPage
    func votes() async throws -> VotesPage
    func rewards() async throws -> RewardsPage
    func spareFood() async throws -> SpareFoodPage
    func history() async throws -> HistoryPage
    func outings() async throws -> OutingsPage
}

/// Used by any source with no Admin data. Every call says so; nothing is faked as success.
struct AdminDataNotBuilt: AdminResultsRepository, AdminStudentsRepository, AdminMoreRepository {
    private var missing: RepositoryError { .notImplemented(feature: "Admin data") }

    func overview() async throws -> AdminResultsOverview { throw missing }
    func reason(_ kind: ReasonKind) async throws -> AdminReasonDetail { throw missing }
    func meal(_ id: MealID) async throws -> AdminMealFacts { throw missing }
    func findMeals(mess: String?, slot: MealSlot) async throws -> [AdminMealFacts] { throw missing }
    func messNames() async throws -> [String] { throw missing }
    func safetyCases() async throws -> [AdminSafetyCase] { throw missing }
    func check(_ id: CheckID) async throws -> CheckNextTime { throw missing }
    func saveChange(_ draft: ChangeDraft, by role: Role) async throws -> CheckNextTime { throw missing }
    func addNote(_ note: String, to check: CheckID, by role: Role) async throws -> CheckNextTime { throw missing }
    func closeAsWorked(_ check: CheckID, by role: Role) async throws -> CheckNextTime { throw missing }
    func weeklyReport(_ period: ReportPeriod) async throws -> AdminWeeklyReport { throw missing }

    func studentsOverview() async throws -> AdminStudentsOverview { throw missing }
    func feedback(_ id: FeedbackItemID) async throws -> FeedbackItem { throw missing }
    func community(_ id: CommunityIssueID) async throws -> AdminCommunityIssue { throw missing }
    func skipReasons() async throws -> StudentSkipReasons { throw missing }
    func ownerChoices() async throws -> [String] { throw missing }
    func remind(key: IdempotencyKey, by role: Role) async throws -> AdminStudentsOverview { throw missing }
    func assignOwner(_ owner: String, to issue: CommunityIssueID, by role: Role) async throws -> AdminCommunityIssue { throw missing }
    func postNote(_ note: String, on issue: CommunityIssueID, by role: Role) async throws -> AdminCommunityIssue { throw missing }

    func hub() async throws -> AdminMoreHub { throw missing }
    func weekMenu() async throws -> WeekMenu { throw missing }
    func copySource(for day: Date, slot: MealSlot) async throws -> [MenuDish] { throw missing }
    func earlierDishes() async throws -> [String] { throw missing }
    func saveDay(_ day: MenuDay, by role: Role) async throws -> WeekMenu { throw missing }
    func applyToTodaysDinner(_ change: QuickChange, by role: Role) async throws -> WeekMenu { throw missing }
    func people() async throws -> AdminPeople { throw missing }
    func invite(phone: String, role: String, by actor: Role) async throws -> AdminPeople { throw missing }
    func saveVendorContact(_ contact: VendorContact, by role: Role) async throws -> AdminPeople { throw missing }
    func announcementDraft() async throws -> AnnouncementDraft { throw missing }
    func announce(_ message: String, to audience: String, by role: Role) async throws { throw missing }
    func passes() async throws -> PassesPage { throw missing }
    func votes() async throws -> VotesPage { throw missing }
    func rewards() async throws -> RewardsPage { throw missing }
    func spareFood() async throws -> SpareFoodPage { throw missing }
    func history() async throws -> HistoryPage { throw missing }
    func outings() async throws -> OutingsPage { throw missing }
}
