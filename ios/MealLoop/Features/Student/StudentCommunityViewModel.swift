import Foundation
import Observation

/// Community: problems students want fixed. Screen state only; counts, stages and the once-per-student rule belong
/// to `StudentCommunityRepository`.
@MainActor
@Observable
final class StudentCommunityViewModel {
    private(set) var state: LoadState<[StudentIssue]> = .idle
    /// A "Me too" being sent.
    private(set) var sending: CommunityIssueID?
    /// A "Me too" tapped while offline. Nothing is counted until the connection is back and the backend accepts it.
    private(set) var waiting: Set<CommunityIssueID> = []
    private(set) var failed: CommunityIssueID?
    private(set) var crowd: StudentCrowd?

    let context: StudentContext
    private let community: any StudentCommunityRepository
    private let meals: any StudentMealsRepository
    private var lastLoadedAt: Date?
    private let clock: any AppClock

    init?(session: Session, repositories: Repositories, clock: any AppClock) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.community = repositories.studentCommunity
        self.meals = repositories.studentMeals
        self.clock = clock
    }

    var timeZone: TimeZone { context.mess.timeZone }
    var now: Date { clock.now() }

    var isOffline: Bool {
        if case .offline = state { return true }
        return false
    }

    func issues(fixed: Bool) -> [StudentIssue] {
        (state.value ?? []).filter { ($0.stage == .fixed) == fixed }
    }

    func issue(_ id: CommunityIssueID) -> StudentIssue? {
        state.value?.first { $0.id == id }
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let loaded = try await community.issues(at: context.mess.id, for: context.student.id)
            state = .loaded(loaded)
            lastLoadedAt = clock.now()
            await sendWaiting()
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: lastLoadedAt ?? savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    /// The wait pattern for a waiting-time problem. A failure only hides the card.
    func loadCrowd() async {
        crowd = try? await meals.crowd(at: context.mess.id)
    }

    func meToo(_ id: CommunityIssueID) async {
        guard sending == nil else { return }
        sending = id
        failed = nil
        defer { sending = nil }
        do {
            replace(try await community.back(id, by: context.student.id))
        } catch RepositoryError.offline {
            waiting.insert(id)
        } catch {
            failed = id
        }
    }

    func undo(_ id: CommunityIssueID) async {
        guard sending == nil else { return }
        sending = id
        defer { sending = nil }
        if let issue = try? await community.unback(id, by: context.student.id) { replace(issue) }
    }

    private func sendWaiting() async {
        for id in waiting {
            waiting.remove(id)
            await meToo(id)
        }
    }

    private func replace(_ issue: StudentIssue) {
        guard var issues = state.value, let index = issues.firstIndex(where: { $0.id == issue.id }) else { return }
        issues[index] = issue
        state = .loaded(issues)
    }
}

/// Report · What's wrong, Details, Sending, Failed, Receipt, and the SOS camera and Sent pages.
@MainActor
@Observable
final class StudentReportViewModel {
    /// What the report is about when it comes from a rating's Not good: the meal, and the dish when there is one.
    /// Nil for a report started from the feedback icon.
    var subject: StudentReportSubject?

    enum SendState: Equatable {
        case idle
        case sending
        case failed
    }

    private(set) var isDeskStaffed = true
    private(set) var send: SendState = .idle
    private(set) var receipt: StudentReportReceipt?
    private(set) var sos: SOSCase?
    private(set) var sosFailed = false
    private(set) var meal: Meal?
    var note = ""

    let context: StudentContext
    private let community: any StudentCommunityRepository
    private let sosRepository: any SOSRepository
    private let mealState: any MealStateRepository
    private let clock: any AppClock
    private var reportKey = IdempotencyKey(UUID().uuidString)
    private var sosKey = IdempotencyKey(UUID().uuidString)

    init?(session: Session, repositories: Repositories, clock: any AppClock) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.community = repositories.studentCommunity
        self.sosRepository = repositories.sos
        self.mealState = repositories.mealState
        self.clock = clock
    }

    var timeZone: TimeZone { context.mess.timeZone }
    var now: Date { clock.now() }

    func load() async {
        isDeskStaffed = (try? await community.isReportDeskStaffed(at: context.mess.id)) ?? true
        let meals = (try? await mealState.meals(for: context.mess.id)) ?? []
        if let subject, let rated = meals.first(where: { $0.meal.slot == subject.slot }) {
            meal = rated.meal
        } else {
            meal = (meals.first { $0.state == .inService } ?? meals.first { $0.state == .notStarted } ?? meals.last)?.meal
        }
    }

    /// The category of the report being written. Kept here, with the note, so the pushed pages share one draft.
    private(set) var category: StudentReportCategory?

    /// The page a category opens: urgent ones the SOS camera, the others the details form (Report · Details).
    enum NextPage: Equatable {
        case details(StudentReportCategory)
        case camera(StudentReportCategory)
    }

    /// Picking a category on What's wrong. Picking the same one again after Back keeps the draft (the typed note);
    /// a different category, or one after a report was sent, starts a new report.
    func choose(_ category: StudentReportCategory) -> NextPage {
        if category != self.category || receipt != nil || sos != nil {
            begin()
            self.category = category
        }
        return category.isUrgent ? .camera(category) : .details(category)
    }

    /// A new category is a new report.
    func begin() {
        reportKey = IdempotencyKey(UUID().uuidString)
        sosKey = IdempotencyKey(UUID().uuidString)
        send = .idle
        receipt = nil
        sos = nil
        sosFailed = false
        note = ""
    }

    /// Non-urgent: the deterministic checks run on the backend. A failure keeps what was typed; Try again sends the
    /// same request, so nothing is sent twice.
    func sendReport(_ category: StudentReportCategory) async {
        guard send != .sending else { return }
        send = .sending
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = StudentReportRequest(student: context.student.id, messID: context.mess.id, category: category,
                                           note: trimmed.isEmpty ? nil : trimmed, place: context.mess.name,
                                           meal: subject?.slot ?? meal?.slot, idempotencyKey: reportKey,
                                           dish: subject?.dishName)
        do {
            receipt = try await community.submitReport(request)
            send = .idle
        } catch {
            send = .failed
        }
    }

    /// Urgent: an SOS for every staff role of the mess. It never waits for Community. True when the case is open.
    func raiseSOS(_ category: StudentReportCategory) async -> Bool {
        sosFailed = false
        do {
            sos = try await sosRepository.raise(SOSReport(messID: context.mess.id, title: StudentReportCategoryTitle.title(category),
                                                          place: context.mess.name, idempotencyKey: sosKey))
            return true
        } catch {
            sosFailed = true
            return false
        }
    }
}

/// What a report from a rating is about (Not good on How was lunch? or Rate a dish).
struct StudentReportSubject: Hashable, Sendable {
    let slot: MealSlot
    let day: Date
    /// Nil for the whole meal.
    let dishName: String?
}
