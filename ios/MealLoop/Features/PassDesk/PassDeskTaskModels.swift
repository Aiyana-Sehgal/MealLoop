import Foundation
import Observation

/// Look up a student (P17). Status only: this model has no way to record.
@MainActor
@Observable
final class PassDeskLookUpModel {
    private(set) var entry = DigitEntry()
    private(set) var state: LoadState<SpecialPassLookup> = .idle

    private let passes: any SpecialPassRepository
    private let meal: MealID

    init(passes: any SpecialPassRepository, meal: MealID) {
        self.passes = passes
        self.meal = meal
    }

    func type(_ digit: Int) async {
        guard !entry.isComplete else { return }
        entry.append(digit)
        guard entry.isComplete else { return }
        state = .loading
        do {
            state = .loaded(try await passes.lookUpPass(lastFour: entry.text, for: meal))
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(nil, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    func deleteLast() {
        entry.deleteLast()
        state = .idle
    }

    func reset() {
        entry.clear()
        state = .idle
    }
}

/// Request a new pass (P09). It goes to the admin pass-exception flow and starts Waiting; nothing here approves.
@MainActor
@Observable
final class PassDeskRequestForm {
    private(set) var entry = DigitEntry()
    private(set) var holder: SpecialPassHolder?
    private(set) var isSending = false
    /// Why the digits or the request did not go through. It stays on screen.
    private(set) var problem: String?
    var reason: PassReissueReason?

    var canSend: Bool { holder != nil && reason != nil && !isSending }
    var messName: String { session.mess.name }

    private var requestKey = IdempotencyKey.make()
    private let session: StaffSession
    private let passes: any SpecialPassRepository
    private let meal: MealID

    init(session: StaffSession, passes: any SpecialPassRepository, meal: MealID) {
        self.session = session
        self.passes = passes
        self.meal = meal
    }

    func prefill(_ digits: String) async {
        for character in digits {
            if let digit = character.wholeNumberValue { await type(digit) }
        }
    }

    func type(_ digit: Int) async {
        guard !entry.isComplete else { return }
        entry.append(digit)
        guard entry.isComplete else { return }
        do {
            switch try await passes.lookUpPass(lastFour: entry.text, for: meal) {
            case .notFound:
                problem = PassDeskCopy.noStudent(entry.text, mess: session.mess.name)
            case .noPass(let found), .wrongMeal(let found, _), .valid(let found, _), .used(let found, _, _):
                holder = found
            }
        } catch RepositoryError.offline {
            problem = PassDeskCopy.couldNotSend
        } catch {
            problem = LoadFailure(error).message
        }
    }

    func deleteLast() {
        entry.deleteLast()
        holder = nil
        problem = nil
    }

    func clear() {
        entry.clear()
        holder = nil
        problem = nil
    }

    /// True once the request is saved.
    func send() async -> Bool {
        guard let holder, let reason, !isSending else { return false }
        isSending = true
        problem = nil
        defer { isSending = false }
        let submission = PassReissueSubmission(student: holder.student, reason: reason, requestedBy: session.role,
                                               idempotencyKey: requestKey)
        do {
            _ = try await passes.requestReissue(submission)
            return true
        } catch RepositoryError.offline {
            problem = PassDeskCopy.couldNotSend
        } catch {
            problem = LoadFailure(error).message
        }
        return false
    }
}

/// The four things the desk can report (pass_desk_spec.md, "Report a problem").
enum PassDeskProblemKind: String, CaseIterable, Identifiable, Sendable {
    case cantCheck
    case crowd
    case foodShort
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cantCheck: return "Can't check passes"
        case .crowd: return "Crowd at the desk"
        case .foodShort: return "Food running short"
        case .other: return "Something else"
        }
    }

    var detail: String {
        switch self {
        case .cantCheck: return "The phone or app is not working"
        case .crowd: return "The line is not moving"
        case .foodShort: return "Tell the kitchen now"
        case .other: return "Anything else at the desk"
        }
    }

    var symbol: String {
        switch self {
        case .cantCheck: return "iphone"
        case .crowd: return "person.2"
        case .foodShort: return "frying.pan"
        case .other: return "text.bubble"
        }
    }
}

struct PassDeskProblem: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let sentAt: Date
    /// True only for a report that really left this phone (Food running short).
    var isDelivered = false
    /// The dish, in place of the "Saved" line.
    var dish: String?
}

/// Problems reported in this sign-in. Three kinds are STATIC AND LOCAL as drawn: no repository takes a problem report,
/// so the Supervisor sees nothing and a problem stays Waiting (REPORT.md). Food running short is real: it goes through
/// `reportShortage`, so the kitchen and the Supervisor read it.
@MainActor
@Observable
final class PassDeskProblemLog {
    private(set) var problems: [PassDeskProblem] = []
    private(set) var isSending = false

    private let repositories: Repositories
    private let session: StaffSession
    private let clock: any AppClock

    init(session: StaffSession, repositories: Repositories, clock: any AppClock) {
        self.session = session
        self.repositories = repositories
        self.clock = clock
    }

    /// True when the report was kept. A read of the shared data stands in for delivery, so offline is refused, not "sent".
    func report(_ kind: PassDeskProblemKind) async -> Bool {
        await send(title: kind.title) { [repositories, session] in
            _ = try await repositories.mealState.currentMeal(for: session.mess.id)
        }
    }

    /// The day's dishes for the food-short sheet. An offline read gives none, and the sheet still offers Something else.
    func dishes(for meal: MealID) async -> [String] {
        ((try? await repositories.meals.menu(for: meal)) ?? []).map(\.name)
    }

    /// The sheet asks which food only. `gettingLow` is the mildest level and an open question (REPORT.md).
    func reportFoodShort(_ dish: String, meal: MealID) async -> Bool {
        let report = ShortageReport(mealID: meal, dishName: dish, level: .gettingLow, note: nil, reportedBy: session.role,
                                    idempotencyKey: .make())
        return await send(title: PassDeskCopy.foodRunningShort, isDelivered: true, dish: dish) { [repositories] in
            _ = try await repositories.shortages.reportShortage(report)
        }
    }

    private func send(title: String, isDelivered: Bool = false, dish: String? = nil, _ work: @escaping () async throws -> Void) async -> Bool {
        guard !isSending else { return false }
        isSending = true
        defer { isSending = false }
        do {
            try await work()
        } catch {
            return false
        }
        problems.insert(PassDeskProblem(id: UUID(), title: title, sentAt: clock.now(), isDelivered: isDelivered, dish: dish), at: 0)
        return true
    }
}

/// New pass requests (P10): the statuses as the repository holds them.
@MainActor
@Observable
final class PassDeskRequestsModel {
    private(set) var state: LoadState<[PassReissueRequest]> = .idle

    private let passes: any SpecialPassRepository
    private let mess: MessID

    init(passes: any SpecialPassRepository, mess: MessID) {
        self.passes = passes
        self.mess = mess
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            let requests = try await passes.reissueRequests(for: mess)
            state = requests.isEmpty ? .empty : .loaded(requests)
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }
}
