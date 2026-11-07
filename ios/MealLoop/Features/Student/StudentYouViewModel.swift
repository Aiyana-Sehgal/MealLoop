import Foundation
import Observation

/// Notifications, the You page, Credits and Attendance. Screen state only: read state, the balance, the earning rule
/// and the attendance marks belong to `StudentYouRepository`.
@MainActor
@Observable
final class StudentYouViewModel {
    private(set) var notifications: LoadState<[StudentNotification]> = .idle
    private(set) var profile: LoadState<StudentProfileSummary> = .idle
    private(set) var credits: LoadState<StudentCredits> = .idle
    private(set) var attendance: LoadState<StudentAttendanceMonth> = .idle

    let context: StudentContext
    let displayName: String
    private let you: any StudentYouRepository
    private let clock: any AppClock

    init?(session: Session, repositories: Repositories, clock: any AppClock) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.displayName = session.account.displayName
        self.you = repositories.studentYou
        self.clock = clock
    }

    var timeZone: TimeZone { context.mess.timeZone }
    var now: Date { clock.now() }

    /// Today's notifications, then earlier ones, each newest first.
    var notificationGroups: (today: [StudentNotification], earlier: [StudentNotification]) {
        let all = notifications.value ?? []
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = all.filter { calendar.isDate($0.at, inSameDayAs: now) }
        return (today, all.filter { !calendar.isDate($0.at, inSameDayAs: now) })
    }

    func loadNotifications() async {
        notifications = await Self.load(notifications) { [you, context] in try await you.notifications(for: context.student.id) }
    }

    func open(_ note: StudentNotification) async {
        guard !note.isRead, let updated = try? await you.markRead(note.id, for: context.student.id),
              var list = notifications.value, let index = list.firstIndex(where: { $0.id == updated.id }) else { return }
        list[index] = updated
        notifications = .loaded(list)
    }

    func loadProfile() async {
        profile = await Self.load(profile) { [you, context] in try await you.profile(for: context.student.id, at: context.mess.id) }
    }

    func loadCredits() async {
        credits = await Self.load(credits) { [you, context] in try await you.credits(for: context.student.id) }
    }

    func loadAttendance() async {
        attendance = await Self.load(attendance) { [you, context] in try await you.attendance(for: context.student.id, at: context.mess.id) }
    }

    /// Keeps the last value under the offline banner; a failure is never shown as an empty result.
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
