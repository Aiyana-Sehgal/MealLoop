#if DEMO_DATA || REVIEW_DATA
import Foundation

/// The moments the demo can show. Changing the scenario replaces all demo state (SIMULATED time skip,
/// like the hidden time-skip hotspots in the Figma prototype).
enum DemoScenario: String, CaseIterable, Identifiable, Sendable {
    /// The start of the core story: 7:00 AM, nothing approved, lunch not started. Time then follows the story.
    case storyStart
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
        case .storyStart: return "Story start"
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
final class DemoClock: StoryClock, @unchecked Sendable {
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
    var headcountApproval: HeadcountApproval = .notApproved
    var headcountPublication: VendorPublication = .notSent
    /// Stays nil until the vendor account acts. The sample state is "Not acknowledged".
    var headcountAcknowledgment: VendorAcknowledgment?
    /// True in the story: counts come only from entries really recorded, never from the sample numbers.
    var countsRecordedEntriesOnly = false
    var specialEntries: [StudentID: SpecialPassEntry] = [:]
    var specialEntryResults: [IdempotencyKey: SpecialPassEntryResult] = [:]
    /// Which sample code is live, and when its window opened. Nil until a lookup asks for one.
    var passCodeIndex = 0
    var passCodeIssuedAt: Date?
    var reissueRequests = DemoSeed.sampleReissues

    init(scenario: DemoScenario) {
        let meal = DemoSeed.lunch
        switch scenario {
        case .storyStart:
            now = DemoSeed.storyStartNow
            mealStatus = MealStatus(meal: meal, state: .notStarted, startedAt: nil, closedAt: nil)
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
        countsRecordedEntriesOnly = scenario == .storyStart
        liveBaseCount = countsRecordedEntriesOnly ? 0 : DemoSeed.liveEntries
        liveAsOf = scenario == .duringMealEntriesStale ? DemoSeed.staleEntriesAt : DemoSeed.liveEntriesAt
        isOffline = scenario == .offline

        intentions[IntentionKey(student: DemoSeed.sampleStudent.id, meal: DemoSeed.breakfast.id)] = DemoSeed.sampleBreakfastAnswer
        for sample in DemoSeed.sampleStudents {
            guard let answer = sample.lunchAnswer else { continue }
            intentions[IntentionKey(student: sample.ref.id, meal: meal.id)] = .answered(answer, at: DemoSeed.sampleLunchAnswersAt)
        }

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

    nonisolated let clock: any StoryClock
    private(set) var scenario: DemoScenario
    private var state: DemoState
    private nonisolated let adminStore = DemoAdminStore()
    private nonisolated let adminMessStore = DemoAdminMessStore()

    /// A new provider is a relaunch: in-memory state and the clock go back to the scenario's start.
    init(scenario: DemoScenario = .duringMeal, clock: (any StoryClock)? = nil) {
        let initial = DemoState(scenario: scenario)
        self.scenario = scenario
        self.state = initial
        self.clock = clock ?? DemoClock(initial.now)
        self.clock.set(initial.now)
    }

    func setScenario(_ scenario: DemoScenario) {
        self.scenario = scenario
        state = DemoState(scenario: scenario)
        clock.set(state.now)
    }

    nonisolated func makeRepositories() -> Repositories {
        let admin = DemoAdminRepositories(core: self, store: adminStore)
        return Repositories(meals: self, mealState: self, headcount: self, entries: self, intentions: self,
                            shortages: self, wasteReports: self, sos: self, auth: self, specialPasses: self,
                            adminResults: admin, adminStudents: admin, adminMore: admin,
                            adminMesses: DemoAdminMesses(core: self, store: adminMessStore))
    }

    /// For repositories that live outside this actor: throws exactly as the others do with no connection.
    func requireConnection() throws {
        try failIfOffline()
    }

    private func failIfOffline() throws {
        if state.isOffline { throw RepositoryError.offline(lastSavedAt: DemoSeed.offlineSavedAt) }
    }

    /// The story meal. Everything that changes a meal or records against it runs on this one.
    private func requireKnownMeal(_ meal: MealID) throws {
        guard meal == state.mealStatus.meal.id else { throw RepositoryError.notFound }
    }

    /// Any meal of the seeded day, for reads and answers.
    private func requireDayMeal(_ meal: MealID) throws {
        guard meal == state.mealStatus.meal.id || meal == DemoSeed.breakfast.id else { throw RepositoryError.notFound }
    }

    /// Breakfast is not run by the Supervisor in the story, so its state follows the clock and its own times.
    private var breakfastStatus: MealStatus {
        let meal = DemoSeed.breakfast
        let now = clock.now()
        if now < meal.startsAt { return MealStatus(meal: meal, state: .notStarted, startedAt: nil, closedAt: nil) }
        if now < meal.endsAt { return MealStatus(meal: meal, state: .inService, startedAt: meal.startsAt, closedAt: nil) }
        return MealStatus(meal: meal, state: .closed, startedAt: meal.startsAt, closedAt: meal.endsAt)
    }

    private var dayMeals: [MealStatus] { [breakfastStatus, state.mealStatus] }

    // MARK: MealRepository

    func menu(for meal: MealID) async throws -> [Dish] {
        try failIfOffline()
        try requireDayMeal(meal)
        // Only the lunch menu is seeded so far. An empty list is the honest answer for breakfast.
        return meal == state.mealStatus.meal.id ? DemoSeed.lunchMenu : []
    }

    // MARK: MealStateRepository

    func currentMeal(for mess: MessID) async throws -> MealStatus? {
        try failIfOffline()
        guard mess == DemoSeed.mess.id else { return nil }
        return state.mealStatus
    }

    func meals(for mess: MessID) async throws -> [MealStatus] {
        try failIfOffline()
        guard mess == DemoSeed.mess.id else { return [] }
        return dayMeals
    }

    func startMeal(_ meal: MealID, by role: Role) async throws -> MealStatus {
        try failIfOffline()
        try requireKnownMeal(meal)
        guard role == .supervisor else { throw RepositoryError.notAllowed(reason: "Only the Supervisor starts a meal.") }
        guard state.mealStatus.state == .notStarted else { throw RepositoryError.notAllowed(reason: "The meal has already started.") }
        clock.advance(to: state.mealStatus.meal.startsAt)
        state.mealStatus.state = .inService
        state.mealStatus.startedAt = clock.now()
        return state.mealStatus
    }

    func closeMeal(_ meal: MealID, by role: Role) async throws -> MealStatus {
        try failIfOffline()
        try requireKnownMeal(meal)
        guard role == .supervisor else { throw RepositoryError.notAllowed(reason: "Only the Supervisor closes a meal.") }
        guard state.mealStatus.state == .inService else { throw RepositoryError.notAllowed(reason: "The meal is not in service.") }
        clock.advance(to: state.mealStatus.meal.endsAt)
        state.mealStatus.state = .closed
        state.mealStatus.closedAt = clock.now()
        return state.mealStatus
    }

    func mealHistory(for mess: MessID) async throws -> [MealRecord] {
        try failIfOffline()
        guard mess == DemoSeed.mess.id else { return [] }
        var records: [MealRecord] = []
        if let lunch = try await storyMealRecord() { records.append(lunch) }
        if let breakfast = try await breakfastRecord() { records.append(breakfast) }
        records += DemoSeed.pastMeals.map { past in
            MealRecord(mealID: past.id, messID: mess, slot: past.slot, day: past.day, closedAt: nil,
                       finalEntries: past.finalEntries.map { .available($0, asOf: past.day) } ?? .unavailable,
                       shortages: past.shortages, waste: past.waste, wasteReport: past.wasteReport)
        }
        return records
    }

    /// The story meal once the Supervisor has closed it, read from the same state every role uses.
    private func storyMealRecord() async throws -> MealRecord? {
        let status = state.mealStatus
        guard status.state == .closed else { return nil }
        let lines = state.shortages.filter { $0.mealID == status.meal.id }.map { shortage in
            switch shortage.status {
            case .active: return MealRecord.ShortageLine(dishName: shortage.dishName, outcome: .active)
            case .resolved(let at): return MealRecord.ShortageLine(dishName: shortage.dishName, outcome: .resolved(at: at))
            }
        }
        let waste: MealRecord.WasteStatus
        var rows: WasteReport?
        if state.recordedSummaryOnly {
            waste = .recorded(at: DemoSeed.wasteRecordedAt)
        } else if let report = state.wasteReports[status.meal.id], case .recorded(let savedAt) = report.status {
            waste = .recorded(at: savedAt)
            rows = report
        } else {
            waste = .notRecorded
        }
        return MealRecord(mealID: status.meal.id, messID: status.meal.messID, slot: status.meal.slot,
                          day: startOfDay(status.meal.startsAt), closedAt: status.closedAt,
                          finalEntries: try await finalCount(for: status.meal.id), shortages: lines,
                          waste: waste, wasteReport: rows)
    }

    /// Breakfast joins the history once its own times have passed (it is not run by the Supervisor in the story).
    /// Its final entries come from `finalCount(for:)`, the same source every other screen reads, so the two always agree.
    /// No spec document gives a breakfast count (only frames S18, S19d, K10 and K11 draw one), so it stays
    /// unavailable, never zero (docs/OPEN_DECISIONS.md, P-STORY-8; supervisor_spec.md: "Unavailable" if missing).
    private func breakfastRecord() async throws -> MealRecord? {
        let status = breakfastStatus
        guard status.state == .closed else { return nil }
        let now = clock.now()
        return MealRecord(
            mealID: status.meal.id, messID: status.meal.messID, slot: status.meal.slot,
            day: startOfDay(status.meal.startsAt), closedAt: status.closedAt,
            finalEntries: try await finalCount(for: status.meal.id),
            shortages: [MealRecord.ShortageLine(dishName: nil, outcome: .resolved(at: nil))],
            waste: now >= DemoSeed.breakfastWasteRecordedAt ? .recorded(at: DemoSeed.breakfastWasteRecordedAt) : .notRecorded,
            wasteReport: nil
        )
    }

    private func startOfDay(_ date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DemoSeed.mess.timeZone
        return calendar.startOfDay(for: date)
    }

    // MARK: HeadcountRepository

    func headcount(for meal: MealID) async throws -> Headcount {
        try failIfOffline()
        try requireDayMeal(meal)
        // Nothing but the story meal has seeded numbers, so breakfast's values stay missing rather than zero.
        let isStoryMeal = meal == state.mealStatus.meal.id
        return Headcount(
            mealID: meal,
            liveForecast: isStoryMeal ? .ready(diners: DemoSeed.forecastDiners, setAt: DemoSeed.forecastSetAt) : .notReady,
            // No document gives a cutoff forecast, so it stays missing (docs/OPEN_DECISIONS.md, P-STORY-3).
            cutoffForecast: .notReady,
            approved: isStoryMeal ? state.headcountApproval : .notApproved,
            sentToVendor: isStoryMeal ? state.headcountPublication : .notSent,
            actualEntries: try await liveCount(for: meal),
            finalEntries: try await finalCount(for: meal),
            acknowledgment: isStoryMeal ? state.headcountAcknowledgment : nil
        )
    }

    func approveHeadcount(_ count: Int, reason: String?, for meal: MealID, by role: Role) async throws -> Headcount {
        try failIfOffline()
        try requireKnownMeal(meal)
        guard role == .admin else { throw RepositoryError.notAllowed(reason: "Only the Food Head approves the headcount.") }
        guard count > 0 else { throw RepositoryError.validationFailed(["Enter a headcount above zero."]) }
        guard case .notSent = state.headcountPublication else {
            throw RepositoryError.notAllowed(reason: "This headcount has already been sent to the vendor.")
        }
        if state.headcountApproval.count == count { return try await headcount(for: meal) }

        let from = state.headcountApproval.count ?? DemoSeed.forecastDiners
        let trimmedReason = reason?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if count != from && trimmedReason.isEmpty {
            throw RepositoryError.validationFailed(["Give a reason for changing the headcount."])
        }
        // The story moves on here: the Food Head works after the answers have closed.
        clock.advance(to: IntentionPolicy.cutoff(for: state.mealStatus.meal).addingTimeInterval(DemoSeed.approvalAfterCutoff))
        var adjustments: [HeadcountAdjustment] = []
        if case .approved(let earlier) = state.headcountApproval { adjustments = earlier.adjustments }
        if count != from {
            adjustments.append(HeadcountAdjustment(from: from, to: count, reason: trimmedReason, adjustedBy: role, adjustedAt: clock.now()))
        }
        state.headcountApproval = .approved(ApprovedHeadcount(count: count, approvedBy: role, approvedAt: clock.now(),
                                                              adjustments: adjustments))
        return try await headcount(for: meal)
    }

    func publishHeadcount(for meal: MealID, by role: Role) async throws -> Headcount {
        try failIfOffline()
        try requireKnownMeal(meal)
        guard role == .admin else { throw RepositoryError.notAllowed(reason: "Only the Food Head sends the headcount.") }
        guard let count = state.headcountApproval.count else {
            throw RepositoryError.notAllowed(reason: "Approve the headcount before sending it.")
        }
        if case .notSent = state.headcountPublication {
            state.headcountPublication = .sent(SentHeadcount(count: count, sentBy: role, sentAt: clock.now()))
        }
        return try await headcount(for: meal)
    }

    func acknowledgeHeadcount(for meal: MealID, by account: AccountID) async throws -> Headcount {
        try failIfOffline()
        guard DemoSeed.accounts.first(where: { $0.id == account })?.role == .vendor else {
            throw RepositoryError.notAllowed(reason: "Only the vendor account can acknowledge a headcount.")
        }
        let current = try await headcount(for: meal)
        guard case .sent = current.sentToVendor else {
            throw RepositoryError.notAllowed(reason: "This headcount has not been sent to the vendor.")
        }
        if state.headcountAcknowledgment == nil {
            state.headcountAcknowledgment = VendorAcknowledgment(acknowledgedBy: account, acknowledgedAt: clock.now())
        }
        return try await headcount(for: meal)
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
        try requireDayMeal(meal)
        guard meal == state.mealStatus.meal.id, state.mealStatus.state == .inService else { return .unavailable }
        let asOf = state.entries.isEmpty && !state.countsRecordedEntriesOnly ? state.liveAsOf : clock.now()
        return .available(currentLiveCount, asOf: asOf)
    }

    func finalCount(for meal: MealID) async throws -> CountReading {
        try failIfOffline()
        try requireDayMeal(meal)
        guard meal == state.mealStatus.meal.id, state.mealStatus.state == .closed,
              let closedAt = state.mealStatus.closedAt else { return .unavailable }
        return .available(state.countsRecordedEntriesOnly ? currentLiveCount : DemoSeed.finalEntries, asOf: closedAt)
    }

    func entryCode(for student: StudentID) async throws -> EntryCode {
        // Deliberately no offline or cutoff check: the entry QR is never locked.
        guard let sample = DemoSeed.sampleStudents.first(where: { $0.ref.id == student }) else {
            throw RepositoryError.notFound
        }
        return sample.entryCode
    }

    func resolveEntry(_ credential: EntryCredential, for meal: MealID) async throws -> EntryCredentialResult {
        // An offline scan cannot be verified, so it is an error and never a result.
        try failIfOffline()
        try requireDayMeal(meal)
        let match = DemoSeed.sampleStudents.first { sample in
            switch credential {
            case .qrPayload(let payload): return sample.entryCode.payload == payload
            case .lastFour(let digits): return sample.entryCode.lastFour == digits
            }
        }
        guard let match else { return .notRecognised }
        // One static code per student, so "wrong meal" here means this is not the meal being served.
        let serving = dayMeals.first { $0.state == .inService }?.meal
        guard serving?.id == meal else { return .wrongMeal(servingNow: serving?.slot) }
        return .student(match.ref)
    }

    func enteredWithoutVoting(for meal: MealID) async throws -> [EnteredWithoutVoting] {
        try failIfOffline()
        try requireKnownMeal(meal)
        return state.withoutVoting.filter { $0.mealID == meal }
    }

    // MARK: IntentionRepository

    func response(of student: StudentID, for meal: MealID) async throws -> IntentionResponse {
        try failIfOffline()
        try requireDayMeal(meal)
        return state.intentions[DemoState.IntentionKey(student: student, meal: meal)] ?? .noResponse
    }

    func setIntention(_ intention: MealIntention, of student: StudentID, for meal: MealID) async throws -> IntentionResponse {
        try failIfOffline()
        try requireDayMeal(meal)
        guard let status = dayMeals.first(where: { $0.meal.id == meal }),
              IntentionPolicy.canAnswer(status.meal, at: clock.now()) else {
            throw RepositoryError.notAllowed(reason: "The cutoff has passed.")
        }
        let key = DemoState.IntentionKey(student: student, meal: meal)
        if case .answered(intention, _)? = state.intentions[key], let existing = state.intentions[key] {
            return existing
        }
        let response = IntentionResponse.answered(intention, at: clock.now())
        state.intentions[key] = response
        return response
    }

    /// Counted over the sample roster only, so these are small labelled numbers and not the forecast.
    func answerCounts(for meal: MealID) async throws -> MealAnswerCounts {
        try failIfOffline()
        try requireDayMeal(meal)
        let answers = DemoSeed.sampleStudents.map { state.intentions[DemoState.IntentionKey(student: $0.ref.id, meal: meal)] ?? .noResponse }
        func count(_ intention: MealIntention) -> Int {
            answers.filter { if case .answered(intention, _) = $0 { return true } else { return false } }.count
        }
        return MealAnswerCounts(attending: count(.attending), skipping: count(.skipping), notSure: count(.notSure),
                                noResponse: answers.filter { $0 == .noResponse }.count)
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

    func markSeen(_ shortage: ShortageID, by role: Role) async throws -> Shortage {
        try failIfOffline()
        guard role == .supervisor else { throw RepositoryError.notAllowed(reason: "Only the Supervisor sees a shortage report.") }
        guard let index = state.shortages.firstIndex(where: { $0.id == shortage }) else { throw RepositoryError.notFound }
        if case .sent = state.shortages[index].delivery {
            state.shortages[index].delivery = .seen(at: clock.now(), by: DemoSeed.supervisorName)
        }
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

    func saveDraft(_ report: WasteReport, by role: Role) async throws -> WasteReport {
        try failIfOffline()
        try requireKnownMeal(report.mealID)
        guard role == .kitchenStaff else {
            throw RepositoryError.notAllowed(reason: "Only Kitchen Staff record waste.")
        }
        guard state.mealStatus.state == .closed else {
            throw RepositoryError.notAllowed(reason: "Waste is recorded only after the meal has ended.")
        }
        var draft = report
        draft.status = .draft(savedAt: clock.now())
        state.wasteReports[report.mealID] = draft
        return draft
    }

    func save(_ report: WasteReport, by role: Role) async throws -> WasteReport {
        try failIfOffline()
        try requireKnownMeal(report.mealID)
        guard role == .kitchenStaff else {
            throw RepositoryError.notAllowed(reason: "Only Kitchen Staff record waste.")
        }
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

    func raise(_ report: SOSReport) async throws -> SOSCase {
        try failIfOffline()
        guard report.messID == DemoSeed.mess.id else { throw RepositoryError.notFound }
        let id = SOSCaseID(report.idempotencyKey.rawValue)
        if let existing = state.sosCases.first(where: { $0.id == id }) { return existing }
        let sos = SOSCase(id: id, messID: report.messID, title: report.title, place: report.place,
                          raisedAt: clock.now(), claim: nil, checks: [], status: .open)
        state.sosCases.append(sos)
        return sos
    }

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

    private func session(for account: Account) -> Session {
        let staff = account.role.isMessStaff
            ? StaffSession(role: account.role, mess: DemoSeed.mess, staffInitials: DemoSeed.staffInitials(for: account.role),
                           supervisorName: DemoSeed.supervisorName)
            : nil
        let student = account.role == .student ? StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess) : nil
        return Session(account: account, staff: staff, student: student)
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

// SIMULATED pass service. The design has no verification algorithm, so the sample codes simply take turns.
extension DemoDataProvider: SpecialPassRepository {
    private func holder(_ sample: DemoSeed.SampleStudent) -> SpecialPassHolder {
        SpecialPassHolder(student: sample.ref, name: sample.name)
    }

    private func livePassCode() -> LivePassCode {
        let sample = DemoSeed.samplePassCodes[state.passCodeIndex % DemoSeed.samplePassCodes.count]
        let issuedAt = state.passCodeIssuedAt ?? clock.now()
        return LivePassCode(code: sample.code, colourName: sample.colourName,
                            changesAt: issuedAt.addingTimeInterval(DemoSeed.passCodeWindow))
    }

    private var specialRecordedCount: Int? {
        switch state.mealStatus.state {
        case .notStarted: return nil
        case .inService: return (state.countsRecordedEntriesOnly ? 0 : DemoSeed.specialMealsSoFar) + state.specialEntries.count
        case .closed: return state.countsRecordedEntriesOnly ? state.specialEntries.count : DemoSeed.specialMealsFinal
        }
    }

    func lookUpPass(lastFour: String, for meal: MealID) async throws -> SpecialPassLookup {
        try failIfOffline()
        try requireKnownMeal(meal)
        guard let sample = DemoSeed.sampleStudents.first(where: { $0.entryCode.lastFour == lastFour }) else { return .notFound }
        if let entry = state.specialEntries[sample.ref.id] {
            return .used(holder(sample), firstRecordedAt: entry.recordedAt, count: specialRecordedCount)
        }
        guard let slot = DemoSeed.samplePasses[sample.ref.id] else { return .noPass(holder(sample)) }
        guard slot == state.mealStatus.meal.slot else { return .wrongMeal(holder(sample), passFor: slot) }
        state.passCodeIssuedAt = clock.now()
        return .valid(holder(sample), live: livePassCode())
    }

    func refreshPassCode(for student: StudentID, meal: MealID) async throws -> LivePassCode {
        try failIfOffline()
        try requireKnownMeal(meal)
        guard DemoSeed.samplePasses[student] == state.mealStatus.meal.slot else { throw RepositoryError.notFound }
        state.passCodeIndex += 1
        state.passCodeIssuedAt = clock.now()
        return livePassCode()
    }

    func recordPassEntry(_ request: SpecialPassEntryRequest) async throws -> SpecialPassEntryResult {
        // Offline: nothing is recorded, nothing is queued and nothing comes back as a result.
        try failIfOffline()
        try requireKnownMeal(request.mealID)
        guard request.recordedBy == .passDesk else {
            throw RepositoryError.notAllowed(reason: "Only the Pass Desk records a special-meal entry.")
        }
        if let previous = state.specialEntryResults[request.idempotencyKey] { return previous }
        if state.mealStatus.state == .closed {
            return .mealEnded(closedAt: state.mealStatus.closedAt, count: specialRecordedCount)
        }
        guard state.mealStatus.state == .inService else {
            throw RepositoryError.notAllowed(reason: "Checking opens when the meal starts.")
        }
        if let entry = state.specialEntries[request.student.id] {
            return .alreadyRecorded(firstRecordedAt: entry.recordedAt, count: specialRecordedCount)
        }
        guard DemoSeed.samplePasses[request.student.id] == state.mealStatus.meal.slot else {
            throw RepositoryError.notAllowed(reason: "This student has no valid special-meal pass for this meal.")
        }
        let live = livePassCode()
        guard state.passCodeIssuedAt != nil, request.comparedCode == live.code, clock.now() < live.changesAt else {
            return .codeChanged
        }
        let entry = SpecialPassEntry(mealID: request.mealID, student: request.student, recordedAt: clock.now(),
                                     recordedBy: request.recordedBy)
        state.specialEntries[request.student.id] = entry
        let result = SpecialPassEntryResult.recorded(entry, count: specialRecordedCount)
        state.specialEntryResults[request.idempotencyKey] = result
        return result
    }

    func specialMealCount(for meal: MealID) async throws -> SpecialMealCount {
        try failIfOffline()
        try requireDayMeal(meal)
        // Only the story meal is a special meal in the seed, so any other has no count and no pass total.
        guard meal == state.mealStatus.meal.id else { return SpecialMealCount(recorded: .unavailable, passes: nil) }
        let recorded = specialRecordedCount.map { CountReading.available($0, asOf: clock.now()) } ?? .unavailable
        return SpecialMealCount(recorded: recorded, passes: DemoSeed.specialPassesTotal)
    }

    func specialMealEntries(for meal: MealID) async throws -> [SpecialPassEntry] {
        try failIfOffline()
        try requireDayMeal(meal)
        return state.specialEntries.values.filter { $0.mealID == meal }.sorted { $0.recordedAt < $1.recordedAt }
    }

    func reissueRequests(for mess: MessID) async throws -> [PassReissueRequest] {
        try failIfOffline()
        guard mess == DemoSeed.mess.id else { return [] }
        return state.reissueRequests
    }

    func requestReissue(_ submission: PassReissueSubmission) async throws -> PassReissueRequest {
        try failIfOffline()
        guard submission.requestedBy == .passDesk else {
            throw RepositoryError.notAllowed(reason: "Only the Pass Desk requests a new pass.")
        }
        guard let sample = DemoSeed.sampleStudents.first(where: { $0.ref.id == submission.student.id }) else {
            throw RepositoryError.notFound
        }
        let id = PassReissueID(submission.idempotencyKey.rawValue)
        if let existing = state.reissueRequests.first(where: { $0.id == id }) { return existing }
        let request = PassReissueRequest(id: id, holder: holder(sample), reason: submission.reason, status: .waiting,
                                         updatedAt: clock.now())
        state.reissueRequests.insert(request, at: 0)
        return request
    }
}

#if DEMO_DATA
// Debug-only controls (SIMULATED time skip). Not compiled into the Review build.
extension DemoDataProvider: DemoControlling {
    nonisolated var scenarioOptions: [DemoScenarioOption] {
        // The menu keeps its seven moments; the story start is the Review build's own.
        DemoScenario.allCases.filter { $0 != .storyStart }.map { DemoScenarioOption(id: $0.rawValue, title: $0.title) }
    }

    func selectScenario(id: String) async {
        guard let scenario = DemoScenario(rawValue: id) else { return }
        setScenario(scenario)
    }
}
#endif
#endif
