#if DEMO_DATA || REVIEW_DATA
import Foundation

/// The moments the demo can show. Changing the scenario replaces all demo state (SIMULATED time skip,
/// like the hidden time-skip hotspots in the Figma prototype).
enum DemoScenario: String, CaseIterable, Identifiable, Sendable {
    case beforeMeal
    case duringMeal
    case duringMealShortageReported
    case duringMealEntriesStale
    case afterMeal
    case afterMealWasteRecorded
    case offline

    var id: String { rawValue }

    #if DEMO_DATA
    var title: String {
        switch self {
        case .beforeMeal: return "Before the meal (K01)"
        case .duringMeal: return "During the meal (K02)"
        case .duringMealShortageReported: return "Shortage reported (K03)"
        case .duringMealEntriesStale: return "Entries stale (K02b)"
        case .afterMeal: return "After the meal (K05)"
        case .afterMealWasteRecorded: return "Waste recorded (K15)"
        case .offline: return "Offline (K02c)"
        }
    }
    #endif
}

/// A clock the demo can move. Thread-safe so it can be read synchronously from any context.
final class DemoClock: AppClock, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    init(_ date: Date) {
        current = date
    }

    func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    func set(_ date: Date) {
        lock.lock()
        current = date
        lock.unlock()
    }
}

/// All mutable demo state, rebuilt from DemoSeed for each scenario.
struct DemoState: Sendable {
    struct EntryKey: Hashable, Sendable {
        let student: StudentID
        let meal: MealID
    }

    struct IntentionKey: Hashable, Sendable {
        let student: StudentID
        let meal: MealID
    }

    var now: Date
    var mealStatus: MealStatus
    var liveBaseCount: Int
    var liveAsOf: Date
    var isOffline: Bool
    var shortages: [Shortage] = []
    var entries: [EntryKey: EntryRecord] = [:]
    var entryResults: [IdempotencyKey: EntryResult] = [:]
    var withoutVoting: [EnteredWithoutVoting] = []
    var intentions: [IntentionKey: IntentionResponse] = [:]
    var wasteReports: [MealID: WasteReport] = [:]
    var sosCases: [SOSCase] = []
    var wrongPasswordCount: [Role: Int] = [:]
    var recordedSummaryOnly = false

    init(scenario: DemoScenario) {
        let meal = DemoSeed.lunch
        switch scenario {
        case .beforeMeal:
            now = DemoSeed.beforeMealNow
            mealStatus = MealStatus(meal: meal, state: .notStarted, startedAt: nil, closedAt: nil)
        case .duringMeal, .duringMealShortageReported, .duringMealEntriesStale, .offline:
            now = DemoSeed.duringMealNow
            mealStatus = MealStatus(meal: meal, state: .inService, startedAt: meal.startsAt, closedAt: nil)
        case .afterMeal, .afterMealWasteRecorded:
            now = DemoSeed.afterMealNow
            mealStatus = MealStatus(meal: meal, state: .closed, startedAt: meal.startsAt, closedAt: DemoSeed.closedAt)
        }
        liveBaseCount = DemoSeed.liveEntries
        liveAsOf = scenario == .duringMealEntriesStale ? DemoSeed.staleEntriesAt : DemoSeed.liveEntriesAt
        isOffline = scenario == .offline

        if scenario == .duringMealShortageReported {
            shortages = [Shortage(
                id: ShortageID("demo-shortage-steamed-rice"),
                mealID: meal.id,
                dishName: DemoSeed.shortageDish,
                level: DemoSeed.shortageLevel,
                note: nil,
                reportedAt: DemoSeed.shortageReportedAt,
                reportedBy: .kitchenStaff,
                delivery: .sent(at: DemoSeed.shortageReportedAt),
                status: .active
            )]
        }

        let emptyRows = DemoSeed.lunchMenu.map {
            DishLeftover(dishID: $0.id, dishName: $0.name, unit: $0.wasteUnit, measurement: .notEntered)
        }
        wasteReports[meal.id] = WasteReport(mealID: meal.id, leftovers: emptyRows, plateWaste: .notEntered, status: .notStarted)
        // The design documents when this report was recorded (2:40 PM) but not its quantities, so the demo
        // exposes only the summary and never invents the rows.
        recordedSummaryOnly = scenario == .afterMealWasteRecorded
    }
}

/// DEMO DATA provider. Implements every repository with seeded, clearly simulated data.
/// Compiled only with DEMO_DATA (Debug) or REVIEW_DATA (Review); a Release build cannot contain it.
actor DemoDataProvider: MealRepository, MealStateRepository, HeadcountRepository, EntryRepository, IntentionRepository,
    ShortageRepository, WasteReportRepository, SOSRepository, AuthRepository {

    nonisolated let clock: DemoClock
    private(set) var scenario: DemoScenario
    private var state: DemoState

    init(scenario: DemoScenario = .duringMeal) {
        let initial = DemoState(scenario: scenario)
        self.scenario = scenario
        self.state = initial
        self.clock = DemoClock(initial.now)
    }

    func setScenario(_ scenario: DemoScenario) {
        self.scenario = scenario
        state = DemoState(scenario: scenario)
        clock.set(state.now)
    }

    nonisolated func makeRepositories() -> Repositories {
        Repositories(meals: self, mealState: self, headcount: self, entries: self, intentions: self,
                     shortages: self, wasteReports: self, sos: self, auth: self)
    }

    private func failIfOffline() throws {
        if state.isOffline { throw RepositoryError.offline(lastSavedAt: DemoSeed.offlineSavedAt) }
    }

    private func requireKnownMeal(_ meal: MealID) throws {
        guard meal == state.mealStatus.meal.id else { throw RepositoryError.notFound }
    }

    // MARK: MealRepository

    func menu(for meal: MealID) async throws -> [Dish] {
        try failIfOffline()
        try requireKnownMeal(meal)
        return DemoSeed.lunchMenu
    }

    // MARK: MealStateRepository

    func currentMeal(for mess: MessID) async throws -> MealStatus? {
        try failIfOffline()
        guard mess == DemoSeed.mess.id else { return nil }
        return state.mealStatus
    }

    func startMeal(_ meal: MealID, by role: Role) async throws -> MealStatus {
        try failIfOffline()
        try requireKnownMeal(meal)
        guard role == .supervisor else { throw RepositoryError.notAllowed(reason: "Only the Supervisor starts a meal.") }
        guard state.mealStatus.state == .notStarted else { throw RepositoryError.notAllowed(reason: "The meal has already started.") }
        state.mealStatus.state = .inService
        state.mealStatus.startedAt = clock.now()
        return state.mealStatus
    }

    func closeMeal(_ meal: MealID, by role: Role) async throws -> MealStatus {
        try failIfOffline()
        try requireKnownMeal(meal)
        guard role == .supervisor else { throw RepositoryError.notAllowed(reason: "Only the Supervisor closes a meal.") }
        guard state.mealStatus.state == .inService else { throw RepositoryError.notAllowed(reason: "The meal is not in service.") }
        state.mealStatus.state = .closed
        state.mealStatus.closedAt = clock.now()
        return state.mealStatus
    }

    // MARK: HeadcountRepository

    func headcount(for meal: MealID) async throws -> Headcount {
        try failIfOffline()
        try requireKnownMeal(meal)
        return Headcount(
            mealID: meal,
            forecast: .ready(diners: DemoSeed.forecastDiners, setAt: DemoSeed.forecastSetAt),
            sent: nil,
            vendorReply: .notSent
        )
    }

    // MARK: EntryRepository

    func recordEntry(_ request: EntryRequest) async throws -> EntryResult {
        // Offline: nothing is recorded and nothing is returned as success.
        try failIfOffline()
        try requireKnownMeal(request.mealID)
        if let previous = state.entryResults[request.idempotencyKey] {
            return previous
        }
        guard state.mealStatus.state == .inService else {
            throw RepositoryError.notAllowed(reason: "Scanning is closed for this meal.")
        }
        let key = DemoState.EntryKey(student: request.student.id, meal: request.mealID)
        let result: EntryResult
        if let existing = state.entries[key] {
            result = .alreadyRecorded(firstRecordedAt: existing.recordedAt, count: currentLiveCount)
        } else {
            let intentionKey = DemoState.IntentionKey(student: request.student.id, meal: request.mealID)
            let hadResponse: Bool
            if case .answered = state.intentions[intentionKey] ?? .noResponse { hadResponse = true } else { hadResponse = false }
            let record = EntryRecord(
                id: EntryID(request.idempotencyKey.rawValue),
                mealID: request.mealID,
                student: request.student,
                recordedAt: clock.now(),
                method: request.method,
                hadMealResponse: hadResponse
            )
            state.entries[key] = record
            if !hadResponse {
                state.withoutVoting.append(EnteredWithoutVoting(mealID: request.mealID, student: request.student, enteredAt: record.recordedAt))
            }
            result = .recorded(record, count: currentLiveCount)
        }
        state.entryResults[request.idempotencyKey] = result
        return result
    }

    private var currentLiveCount: Int { state.liveBaseCount + state.entries.count }

    func liveCount(for meal: MealID) async throws -> CountReading {
        try failIfOffline()
        try requireKnownMeal(meal)
        guard state.mealStatus.state == .inService else { return .unavailable }
        return .available(currentLiveCount, asOf: state.entries.isEmpty ? state.liveAsOf : clock.now())
    }

    func finalCount(for meal: MealID) async throws -> CountReading {
        try failIfOffline()
        try requireKnownMeal(meal)
        guard state.mealStatus.state == .closed, let closedAt = state.mealStatus.closedAt else { return .unavailable }
        return .available(DemoSeed.finalEntries, asOf: closedAt)
    }

    func enteredWithoutVoting(for meal: MealID) async throws -> [EnteredWithoutVoting] {
        try failIfOffline()
        try requireKnownMeal(meal)
        return state.withoutVoting.filter { $0.mealID == meal }
    }

    // MARK: IntentionRepository

    func response(of student: StudentID, for meal: MealID) async throws -> IntentionResponse {
        try failIfOffline()
        try requireKnownMeal(meal)
        return state.intentions[DemoState.IntentionKey(student: student, meal: meal)] ?? .noResponse
    }

    func setIntention(_ intention: MealIntention, of student: StudentID, for meal: MealID) async throws -> IntentionResponse {
        try failIfOffline()
        try requireKnownMeal(meal)
        guard IntentionPolicy.canAnswer(state.mealStatus.meal, at: clock.now()) else {
            throw RepositoryError.notAllowed(reason: "The cutoff has passed.")
        }
        let response = IntentionResponse.answered(intention, at: clock.now())
        state.intentions[DemoState.IntentionKey(student: student, meal: meal)] = response
        return response
    }

    // MARK: ShortageRepository

    func reportShortage(_ report: ShortageReport) async throws -> Shortage {
        try failIfOffline()
        try requireKnownMeal(report.mealID)
        let id = ShortageID(report.idempotencyKey.rawValue)
        if let existing = state.shortages.first(where: { $0.id == id }) { return existing }
        let shortage = Shortage(id: id, mealID: report.mealID, dishName: report.dishName, level: report.level,
                                note: report.note, reportedAt: clock.now(), reportedBy: report.reportedBy,
                                delivery: .sent(at: clock.now()), status: .active)
        state.shortages.append(shortage)
        return shortage
    }

    func shortages(for meal: MealID) async throws -> [Shortage] {
        try failIfOffline()
        try requireKnownMeal(meal)
        return state.shortages.filter { $0.mealID == meal }
    }

    func markResolved(_ shortage: ShortageID, by role: Role) async throws -> Shortage {
        try failIfOffline()
        guard role == .supervisor else { throw RepositoryError.notAllowed(reason: "Only the Supervisor resolves a shortage.") }
        guard let index = state.shortages.firstIndex(where: { $0.id == shortage }) else { throw RepositoryError.notFound }
        state.shortages[index].status = .resolved(at: clock.now())
        return state.shortages[index]
    }

    // MARK: WasteReportRepository

    func summary(for meal: MealID) async throws -> WasteReportSummary {
        if state.recordedSummaryOnly {
            try failIfOffline()
            try requireKnownMeal(meal)
            let fields = DemoSeed.lunchMenu.count + 1
            return WasteReportSummary(mealID: meal, status: .recorded(savedAt: DemoSeed.wasteRecordedAt),
                                      completedFieldCount: fields, totalFieldCount: fields)
        }
        let report = try await self.report(for: meal)
        return WasteReportSummary(mealID: meal, status: report.status,
                                  completedFieldCount: report.completedFieldCount, totalFieldCount: report.totalFieldCount)
    }

    func report(for meal: MealID) async throws -> WasteReport {
        try failIfOffline()
        try requireKnownMeal(meal)
        if state.recordedSummaryOnly {
            throw RepositoryError.notImplemented(feature: "Demo · quantities for this recorded report are not in the design documents")
        }
        guard let report = state.wasteReports[meal] else { throw RepositoryError.notFound }
        return report
    }

    func saveDraft(_ report: WasteReport) async throws -> WasteReport {
        try failIfOffline()
        try requireKnownMeal(report.mealID)
        guard state.mealStatus.state == .closed else {
            throw RepositoryError.notAllowed(reason: "Waste is recorded only after the meal has ended.")
        }
        var draft = report
        draft.status = .draft(savedAt: clock.now())
        state.wasteReports[report.mealID] = draft
        return draft
    }

    func save(_ report: WasteReport) async throws -> WasteReport {
        try failIfOffline()
        try requireKnownMeal(report.mealID)
        guard state.mealStatus.state == .closed else {
            throw RepositoryError.notAllowed(reason: "Waste is recorded only after the meal has ended.")
        }
        if let current = state.wasteReports[report.mealID], !WasteReportPolicy.canEdit(current.status, at: clock.now()) {
            throw RepositoryError.notAllowed(reason: "Editing closed after 6 hours.")
        }
        guard report.canSave else {
            throw RepositoryError.validationFailed(["\(report.missingCount) field(s) still empty or invalid."])
        }
        var recorded = report
        recorded.status = .recorded(savedAt: clock.now())
        state.wasteReports[report.mealID] = recorded
        return recorded
    }

    // MARK: SOSRepository

    func activeCases(for mess: MessID) async throws -> [SOSCase] {
        try failIfOffline()
        return state.sosCases.filter { $0.messID == mess && $0.status == .open }
    }

    func claim(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase {
        try updateSOS(sos) { $0.claim = SOSClaim(role: role, at: self.clock.now()) }
    }

    func markChecked(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase {
        try updateSOS(sos) { $0.checks.append(SOSCheck(role: role, at: self.clock.now())) }
    }

    func close(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase {
        guard role == SOSCase.closingRole else { throw RepositoryError.notAllowed(reason: "Only the Supervisor closes a case.") }
        return try updateSOS(sos) { $0.status = .closed(at: self.clock.now(), by: role) }
    }

    private func updateSOS(_ id: SOSCaseID, _ change: (inout SOSCase) -> Void) throws -> SOSCase {
        try failIfOffline()
        guard let index = state.sosCases.firstIndex(where: { $0.id == id }) else { throw RepositoryError.notFound }
        change(&state.sosCases[index])
        return state.sosCases[index]
    }

    // MARK: AuthRepository (SIMULATED)

    func signInStaff(email: String, password: String) async throws -> Session {
        try failIfOffline()
        let wanted = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let account = DemoSeed.accounts.first(where: { $0.email.lowercased() == wanted }),
              account.role != .student,
              password == DemoSeed.prototypePassword else {
            throw RepositoryError.invalidCredentials
        }
        return session(for: account)
    }

    /// UNVERIFIED AND SIMULATED: no SRM SSO exists and its feasibility is unconfirmed.
    /// With no real identity to read, this always returns the seeded student. Super Admin is also meant to use
    /// SRM, so until a real identity exists the prototype lets that account in through `signInStaff`.
    func signInWithSRM() async throws -> Session {
        try failIfOffline()
        guard let account = DemoSeed.accounts.first(where: { $0.role == .student }) else {
            throw RepositoryError.notFound
        }
        return session(for: account)
    }

    func resume(_ account: AccountID) async throws -> Session {
        try failIfOffline()
        guard let known = DemoSeed.accounts.first(where: { $0.id == account }) else {
            throw RepositoryError.notFound
        }
        return session(for: known)
    }

    private func session(for account: Account) -> Session {
        let staff = account.role.isMessStaff
            ? StaffSession(role: account.role, mess: DemoSeed.mess, staffInitials: DemoSeed.staffInitials(for: account.role),
                           supervisorName: DemoSeed.supervisorName)
            : nil
        return Session(account: account, staff: staff)
    }

    #if DEMO_DATA
    func verifyRolePassword(_ password: String, for role: Role) async throws -> RolePasswordResult {
        guard role.isMessStaff else { throw RepositoryError.notAllowed(reason: "Not a mess staff role.") }
        let wrongSoFar = state.wrongPasswordCount[role] ?? 0
        if wrongSoFar >= RolePasswordPolicy.maximumTries {
            return .locked(resetBy: DemoSeed.supervisorName)
        }
        if password == DemoSeed.simulatedRolePassword {
            state.wrongPasswordCount[role] = 0
            return .granted(StaffSession(role: role, mess: DemoSeed.mess,
                                         staffInitials: DemoSeed.staffInitials(for: role),
                                         supervisorName: DemoSeed.supervisorName))
        }
        let wrong = wrongSoFar + 1
        state.wrongPasswordCount[role] = wrong
        if wrong >= RolePasswordPolicy.maximumTries {
            return .locked(resetBy: DemoSeed.supervisorName)
        }
        return .wrong(triesLeft: RolePasswordPolicy.maximumTries - wrong)
    }
    #endif
}

#if DEMO_DATA
// Debug-only controls (SIMULATED time skip). Not compiled into the Review build.
extension DemoDataProvider: DemoControlling {
    nonisolated var scenarioOptions: [DemoScenarioOption] {
        DemoScenario.allCases.map { DemoScenarioOption(id: $0.rawValue, title: $0.title) }
    }

    func selectScenario(id: String) async {
        guard let scenario = DemoScenario(rawValue: id) else { return }
        setScenario(scenario)
    }
}
#endif
#endif
