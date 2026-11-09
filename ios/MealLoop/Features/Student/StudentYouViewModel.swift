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
    /// The one entry record the student may ask to correct (Entry · Discrepancy, 221:63082). Nil when there is none or
    /// it could not be read (offline): then no day opens the sheet.
    private(set) var correctable: AttendanceRecord?
    /// A correction request for `correctable` was recorded in this run. The prototype sends it nowhere.
    private(set) var correctionRecorded = false

    let context: StudentContext
    let displayName: String
    private let you: any StudentYouRepository
    private let extras: any StudentExtrasRepository
    private let clock: any AppClock

    init?(session: Session, repositories: Repositories, clock: any AppClock) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.displayName = session.account.displayName
        self.you = repositories.studentYou
        self.extras = repositories.studentExtras
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
        correctable = try? await extras.correctableRecord(for: context.student.id)
    }

    /// The day of `month` whose missed entry can be corrected: the correctable record's day, when the calendar marks it
    /// "No entry for a meal". Nil otherwise, so only that day opens "Something's wrong?".
    func correctableDay(in month: StudentAttendanceMonth) -> Int? {
        guard let record = correctable else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard calendar.isDate(record.day, equalTo: month.month, toGranularity: .month) else { return nil }
        let day = calendar.component(.day, from: record.day)
        return month.marks[day] == .noEntryForAMeal ? day : nil
    }

    /// Asks for the entry to be corrected. A request only: it changes no entry and no count. Offline it throws and
    /// nothing is recorded; a retry with the same key never makes a second request.
    func sendCorrection(for record: AttendanceRecord, reason: EntryCorrectionReason, note: String?, key: IdempotencyKey) async throws {
        _ = try await extras.requestEntryCorrection(EntryCorrectionRequest(student: context.student.id, mealID: record.mealID,
                                                                           reason: reason, note: note, idempotencyKey: key))
        correctionRecorded = true
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
