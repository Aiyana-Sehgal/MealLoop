import Foundation

/// Session-bound prototype access. The requested mess is checked before any underlying read or write.
struct AdminDataScope: Sendable {
    let session: Session
    let mess: Mess
    var allMesses: Bool { session.account.role == .superAdmin }
    var name: String { mess.name.replacingOccurrences(of: " Mess", with: "") }
    func require() throws {
        guard allMesses || (session.account.role == .admin && session.account.scope == .mess(mess.id)) else {
            throw RepositoryError.notAllowed(reason: "This mess is outside your account's scope.")
        }
    }
    func requireName(_ name: String) throws {
        try require()
        guard allMesses || name.replacingOccurrences(of: " Mess", with: "") == self.name else {
            throw RepositoryError.notAllowed(reason: "This mess is outside your account's scope.")
        }
    }
    func accountPowers() throws {
        try require()
        guard allMesses else { throw RepositoryError.notAllowed(reason: "Only the Super Admin manages people and access.") }
    }
    func legacyRole(_ role: Role) throws -> Role {
        try require()
        guard role == session.account.role else { throw RepositoryError.notAllowed(reason: "The acting role doesn't match this session.") }
        return .admin
    }
}

struct ScopedAdminResultsRepository: AdminResultsRepository {
    let base: any AdminResultsRepository
    let scope: AdminDataScope
    func overview() async throws -> AdminResultsOverview {
        try scope.require()
        guard scope.allMesses else { throw RepositoryError.notImplemented(feature: "Single-mess summary; use the scoped meal records") }
        return try await base.overview()
    }
    func reason(_ kind: ReasonKind) async throws -> AdminReasonDetail {
        try scope.require()
        guard scope.allMesses else { throw RepositoryError.notImplemented(feature: "Single-mess summary; use the scoped meal records") }
        return try await base.reason(kind)
    }
    func meal(_ id: MealID) async throws -> AdminMealFacts {
        try scope.require()
        let value = try await base.meal(id)
        try scope.requireName(value.mess)
        return value
    }
    func findMeals(mess: String?, slot: MealSlot) async throws -> [AdminMealFacts] {
        try scope.require()
        if let mess { try scope.requireName(mess) }
        return try await base.findMeals(mess: scope.allMesses ? mess : scope.name, slot: slot)
    }
    func messNames() async throws -> [String] {
        try scope.require()
        return scope.allMesses ? try await base.messNames() : [scope.name]
    }
    func safetyCases() async throws -> [AdminSafetyCase] {
        try scope.require()
        return try await base.safetyCases().filter { scope.allMesses || $0.mess == scope.name }
    }
    func check(_ id: CheckID) async throws -> CheckNextTime {
        try scope.require()
        let value = try await base.check(id)
        try scope.requireName(value.mess)
        return value
    }
    func saveChange(_ draft: ChangeDraft, by role: Role) async throws -> CheckNextTime {
        try scope.require()
        if let meal = draft.meal { try scope.requireName(try await base.meal(meal).mess) }
        else if !scope.allMesses { throw RepositoryError.notAllowed(reason: "Choose a meal from your mess.") }
        return try await base.saveChange(draft, by: try scope.legacyRole(role))
    }
    func addNote(_ note: String, to check: CheckID, by role: Role) async throws -> CheckNextTime {
        try scope.require()
        try scope.requireName(try await base.check(check).mess)
        return try await base.addNote(note, to: check, by: try scope.legacyRole(role))
    }
    func closeAsWorked(_ check: CheckID, by role: Role) async throws -> CheckNextTime {
        try scope.require()
        try scope.requireName(try await base.check(check).mess)
        return try await base.closeAsWorked(check, by: try scope.legacyRole(role))
    }
    func weeklyReport(_ period: ReportPeriod) async throws -> AdminWeeklyReport {
        try scope.require()
        guard scope.allMesses else { throw RepositoryError.notImplemented(feature: "Single-mess summary; use the scoped meal records") }
        return try await base.weeklyReport(period)
    }
}

struct ScopedAdminStudentsRepository: AdminStudentsRepository {
    let base: any AdminStudentsRepository
    let scope: AdminDataScope
    func studentsOverview() async throws -> AdminStudentsOverview {
        try scope.require()
        let value = try await base.studentsOverview()
        return AdminStudentsOverview(mealTitle: value.mealTitle, mealLongTitle: value.mealLongTitle, totalStudents: value.totalStudents, yes: value.yes, no: value.no, notSure: value.notSure, reminderMessage: value.reminderMessage, reminderSentAt: value.reminderSentAt, feedback: value.feedback.filter { scope.allMesses || $0.mess == scope.name }, community: value.community.filter { scope.allMesses || $0.context.hasPrefix(scope.mess.name + " · ") })
    }
    func feedback(_ id: FeedbackItemID) async throws -> FeedbackItem {
        try scope.require()
        let value = try await base.feedback(id)
        try scope.requireName(value.mess)
        return value
    }
    func community(_ id: CommunityIssueID) async throws -> AdminCommunityIssue {
        try scope.require()
        let value = try await base.community(id)
        try scope.requireName(value.context.components(separatedBy: " · ").first ?? value.context)
        return value
    }
    func skipReasons() async throws -> StudentSkipReasons {
        try scope.require()
        return try await base.skipReasons()
    }
    func ownerChoices() async throws -> [String] {
        try scope.require()
        return try await base.ownerChoices()
    }
    func remind(key: IdempotencyKey, by role: Role) async throws -> AdminStudentsOverview {
        try scope.require()
        let value = try await base.remind(key: key, by: try scope.legacyRole(role))
        return AdminStudentsOverview(mealTitle: value.mealTitle, mealLongTitle: value.mealLongTitle, totalStudents: value.totalStudents, yes: value.yes, no: value.no, notSure: value.notSure, reminderMessage: value.reminderMessage, reminderSentAt: value.reminderSentAt, feedback: value.feedback.filter { scope.allMesses || $0.mess == scope.name }, community: value.community.filter { scope.allMesses || $0.context.hasPrefix(scope.mess.name + " · ") })
    }
    func assignOwner(_ owner: String, to issue: CommunityIssueID, by role: Role) async throws -> AdminCommunityIssue {
        try scope.require()
        let value = try await base.community(issue)
        try scope.requireName(value.context.components(separatedBy: " · ").first ?? value.context)
        return try await base.assignOwner(owner, to: issue, by: try scope.legacyRole(role))
    }
    func postNote(_ note: String, on issue: CommunityIssueID, by role: Role) async throws -> AdminCommunityIssue {
        try scope.require()
        let value = try await base.community(issue)
        try scope.requireName(value.context.components(separatedBy: " · ").first ?? value.context)
        return try await base.postNote(note, on: issue, by: try scope.legacyRole(role))
    }
}

struct ScopedAdminMoreRepository: AdminMoreRepository {
    let base: any AdminMoreRepository
    let scope: AdminDataScope
    func hub() async throws -> AdminMoreHub {
        try scope.require()
        return try await base.hub()
    }
    func weekMenu() async throws -> WeekMenu {
        try scope.require()
        return try await base.weekMenu()
    }
    func copySource(for day: Date, slot: MealSlot) async throws -> [MenuDish] {
        try scope.require()
        return try await base.copySource(for: day, slot: slot)
    }
    func earlierDishes() async throws -> [String] {
        try scope.require()
        return try await base.earlierDishes()
    }
    func saveDay(_ day: MenuDay, by role: Role) async throws -> WeekMenu {
        try scope.require()
        return try await base.saveDay(day, by: try scope.legacyRole(role))
    }
    func applyToTodaysDinner(_ change: QuickChange, by role: Role) async throws -> WeekMenu {
        try scope.require()
        return try await base.applyToTodaysDinner(change, by: try scope.legacyRole(role))
    }
    func people() async throws -> AdminPeople {
        try scope.require()
        try scope.accountPowers()
        return try await base.people()
    }
    func invite(phone: String, role: String, by actor: Role) async throws -> AdminPeople {
        try scope.require()
        try scope.accountPowers()
        return try await base.invite(phone: phone, role: role, by: try scope.legacyRole(actor))
    }
    func saveVendorContact(_ contact: VendorContact, by role: Role) async throws -> AdminPeople {
        try scope.require()
        try scope.accountPowers()
        return try await base.saveVendorContact(contact, by: try scope.legacyRole(role))
    }
    func announcementDraft() async throws -> AnnouncementDraft {
        try scope.require()
        return try await base.announcementDraft()
    }
    func announce(_ message: String, to audience: String, by role: Role) async throws {
        try scope.require()
        try await base.announce(message, to: audience, by: try scope.legacyRole(role))
    }
    func passes() async throws -> PassesPage {
        try scope.require()
        return try await base.passes()
    }
    func votes() async throws -> VotesPage {
        try scope.require()
        return try await base.votes()
    }
    func rewards() async throws -> RewardsPage {
        try scope.require()
        return try await base.rewards()
    }
    func spareFood() async throws -> SpareFoodPage {
        try scope.require()
        return try await base.spareFood()
    }
    func history() async throws -> HistoryPage {
        try scope.require()
        return try await base.history()
    }
    func outings() async throws -> OutingsPage {
        try scope.require()
        return try await base.outings()
    }
}

struct ScopedAdminMessRepository: AdminMessRepository {
    let base: any AdminMessRepository
    let scope: AdminDataScope
    func messDay(for slot: MealSlot) async throws -> AdminMessDay {
        try scope.require()
        try scope.accountPowers()
        return try await base.messDay(for: slot)
    }
    func messHeadcount(_ id: String, slot: MealSlot) async throws -> AdminMessHeadcount {
        try scope.require()
        try scope.requireName(id)
        return try await base.messHeadcount(id, slot: slot)
    }
    func sendHeadcount(mess id: String, slot: MealSlot, key: IdempotencyKey, by role: Role) async throws -> AdminMessHeadcount {
        try scope.require()
        try scope.requireName(id)
        return try await base.sendHeadcount(mess: id, slot: slot, key: key, by: try scope.legacyRole(role))
    }
    func adjustHeadcount(mess id: String, slot: MealSlot, to count: Int, reason: String?, by role: Role) async throws -> AdminMessHeadcount {
        try scope.require()
        try scope.requireName(id)
        return try await base.adjustHeadcount(mess: id, slot: slot, to: count, reason: reason, by: try scope.legacyRole(role))
    }
    func liveReference(for meal: MealID) async throws -> AdminLiveReference {
        try scope.require()
        return try await base.liveReference(for: meal)
    }
    func notAnsweredByMess() async throws -> [AdminMessCount] {
        try scope.require()
        return try await base.notAnsweredByMess().filter { scope.allMesses || $0.name.replacingOccurrences(of: " Mess", with: "") == scope.name }
    }
}

extension Repositories {
    /// The Admin subtree gets session-bound adapters; other roles keep their own repositories.
    func scopedAdmin(_ session: Session, mess: Mess) -> Repositories {
        var value = self
        let scope = AdminDataScope(session: session, mess: mess)
        value.headcount = ScopedAdminHeadcount(base: headcount, meals: mealState, scope: scope)
        value.adminResults = ScopedAdminResultsRepository(base: adminResults, scope: scope)
        value.adminStudents = ScopedAdminStudentsRepository(base: adminStudents, scope: scope)
        value.adminMore = ScopedAdminMoreRepository(base: adminMore, scope: scope)
        value.adminMesses = ScopedAdminMessRepository(base: adminMesses, scope: scope)
        return value
    }
}

struct ScopedAdminHeadcount: HeadcountRepository {
    let base: any HeadcountRepository
    let meals: any MealStateRepository
    let scope: AdminDataScope
    private func require(_ meal: MealID) async throws {
        try scope.require()
        if !scope.allMesses {
            guard try await meals.meals(for: scope.mess.id).contains(where: { $0.meal.id == meal && $0.meal.messID == scope.mess.id }) else {
                throw RepositoryError.notAllowed(reason: "This meal is outside your mess.")
            }
        }
    }
    func headcount(for meal: MealID) async throws -> Headcount { try await require(meal); return try await base.headcount(for: meal) }
    func approveHeadcount(_ count: Int, reason: String?, for meal: MealID, by role: Role) async throws -> Headcount {
        try await require(meal); return try await base.approveHeadcount(count, reason: reason, for: meal, by: scope.legacyRole(role))
    }
    func publishHeadcount(for meal: MealID, by role: Role) async throws -> Headcount {
        try await require(meal); return try await base.publishHeadcount(for: meal, by: scope.legacyRole(role))
    }
    func acknowledgeHeadcount(for meal: MealID, by account: AccountID) async throws -> Headcount {
        throw RepositoryError.notAllowed(reason: "Only the vendor account acknowledges receipt.")
    }
}

extension MealStateRepository {
    /// Legacy role-only methods remain for existing prototype callers. Supervisor writes use this scoped overload.
    func startMeal(_ meal: MealID, by session: StaffSession) async throws -> MealStatus {
        guard session.role == .supervisor,
              let target = try await currentMeal(for: session.mess.id), target.meal.id == meal,
              target.meal.messID == session.mess.id else {
            throw RepositoryError.notAllowed(reason: "Only the Supervisor of this mess can start its meal.")
        }
        return try await startMeal(meal, by: session.role)
    }
    func closeMeal(_ meal: MealID, by session: StaffSession) async throws -> MealStatus {
        guard session.role == .supervisor,
              let target = try await currentMeal(for: session.mess.id), target.meal.id == meal,
              target.meal.messID == session.mess.id else {
            throw RepositoryError.notAllowed(reason: "Only the Supervisor of this mess can close its meal.")
        }
        return try await closeMeal(meal, by: session.role)
    }
}
