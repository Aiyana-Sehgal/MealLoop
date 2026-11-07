import Foundation
import Observation

/// The Student outing pages. Screen state only: stages, deadlines, who may ask and what is refused belong to
/// `StudentOutingRepository`. Nothing here moves a request forward.
@MainActor
@Observable
final class StudentOutingsViewModel {
    enum Send: Equatable { case idle, sending, failed(String) }

    private(set) var outings: LoadState<StudentOutings> = .idle
    private(set) var detail: LoadState<OutingCase> = .idle
    private(set) var send: Send = .idle
    private(set) var cancelling = false
    private(set) var cancelError: String?
    /// The outing story's time, read from the repository on load. Deadlines and "in 5 h" are measured from it.
    private(set) var now: Date

    // The New outing form. Defaults are the frame's (New outing · Wed: 6 PM – 9 PM).
    var selectedDay: Date?
    var leaveHour = 18
    var backHour = 21
    var place = ""
    var reason: String?
    /// One key per form, so a repeated tap returns the first request.
    private var key = IdempotencyKey.make()

    let context: StudentContext
    private let repository: any StudentOutingRepository

    init?(session: Session, repository: any StudentOutingRepository) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.repository = repository
        self.now = .distantPast
    }

    private var student: StudentID { context.student.id }
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = OutingFormat.timeZone
        return calendar
    }

    /// Monday to Sunday of the outing story's week.
    var weekDays: [Date] {
        let start = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: start) // Sunday = 1
        let monday = calendar.date(byAdding: .day, value: -((weekday + 5) % 7), to: start) ?? start
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    func isPast(_ day: Date) -> Bool { calendar.startOfDay(for: day) < calendar.startOfDay(for: now) }

    private func at(_ hour: Int, on day: Date) -> Date? {
        calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)
    }

    /// The open request already on the picked day, which the repository would refuse a second one for.
    var duplicate: OutingCase? {
        guard let day = selectedDay else { return nil }
        return outings.value?.current.first { $0.leaveAt.map { calendar.isDate($0, inSameDayAs: day) } == true }
    }

    var canSend: Bool {
        selectedDay != nil && duplicate == nil && !place.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && backHour > leaveHour && send != .sending && outings.value?.eligibility == .enabled
    }

    var isOffline: Bool { if case .offline = outings { return true } else { return false } }

    func load() async {
        now = await repository.now()
        outings = await Self.load(outings) { [repository, student] in try await repository.outings(for: student) }
        if selectedDay == nil { selectedDay = weekDays.first { !isPast($0) } }
    }

    func loadDetail(_ id: OutingRequestID) async {
        now = await repository.now()
        detail = await Self.load(detail) { [repository, student] in try await repository.outing(id, for: student) }
    }

    /// Sends the request. A failure or offline keeps the form and never shows the request as sent.
    func sendRequest() async -> OutingCase? {
        guard canSend, let day = selectedDay, let leave = at(leaveHour, on: day), let back = at(backHour, on: day) else {
            return nil
        }
        send = .sending
        let draft = StudentOutingDraft(leaveAt: leave, returnBy: back, place: place, reason: reason, idempotencyKey: key)
        do {
            let made = try await repository.requestOuting(draft, by: student)
            send = .idle
            key = IdempotencyKey.make()
            place = ""
            reason = nil
            await load()
            return made
        } catch RepositoryError.validationFailed(let problems) {
            send = .failed(problems.joined(separator: " "))
        } catch {
            send = .failed(LoadFailure(error).message)
        }
        return nil
    }

    func cancel(_ id: OutingRequestID) async -> Bool {
        guard !cancelling else { return false }
        cancelling = true
        defer { cancelling = false }
        do {
            detail = .loaded(try await repository.cancelOuting(id, by: student))
            cancelError = nil
            await load()
            return true
        } catch {
            cancelError = LoadFailure(error).message
            return false
        }
    }

    private static func load<Value>(_ current: LoadState<Value>, _ fetch: () async throws -> Value) async -> LoadState<Value> {
        do {
            return .loaded(try await fetch())
        } catch RepositoryError.offline(let savedAt) {
            return .offline(current.value, savedAt: savedAt)
        } catch {
            return .failed(LoadFailure(error))
        }
    }
}
