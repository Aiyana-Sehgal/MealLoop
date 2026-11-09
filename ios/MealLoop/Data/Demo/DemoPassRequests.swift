#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SIMULATED. Pass requests of one run, seeded with the labelled rows of admin_passes_01_requests.
actor DemoPassRequestStore {
    private(set) var requests: [PassRequest] = []
    private var seeded = false
    private var nextNumber = 1

    func seedIfNeeded(_ rows: [PassRequest]) {
        guard !seeded else { return }
        seeded = true
        requests = rows
    }

    func add(_ request: PassRequest) { requests.append(request) }

    func update(_ id: PassRequestID, _ change: (inout PassRequest) -> Void) -> PassRequest? {
        guard let index = requests.firstIndex(where: { $0.id == id }) else { return nil }
        change(&requests[index])
        return requests[index]
    }

    func newID() -> PassRequestID {
        defer { nextNumber += 1 }
        return PassRequestID("demo-pass-request-\(nextNumber)")
    }
}

/// SIMULATED. Pass requests on the prototype data source. The current week's pass is the story's seeded one; next
/// week's is usable only once accepted. Nothing is sent to anyone.
struct DemoPassRequests: PassRequestRepository {
    let core: DemoDataProvider
    let store: DemoPassRequestStore

    private var timeZone: TimeZone { DemoSeed.mess.timeZone }
    private var nextWeek: PassWeek { PassWeekMath.nextWeek(after: core.clock.now(), timeZone: timeZone) }

    private func requests() async -> [PassRequest] {
        await store.seedIfNeeded(DemoSeed.samplePassRequests(week: nextWeek))
        return await store.requests
    }

    private func requireAdmin(_ role: Role) throws {
        guard role == .admin || role == .superAdmin else {
            throw RepositoryError.notAllowed(reason: "Only the admin decides pass requests.")
        }
    }

    func status(for student: StudentID) async throws -> PassRequest? {
        try await core.requireConnection()
        let week = nextWeek
        return await requests().last { $0.student == student && $0.week == week && $0.state != .cancelled }
    }

    func request(for student: StudentRef, at mess: Mess) async throws -> PassRequest {
        try await core.requireConnection()
        if let current = try await status(for: student.id), current.state == .pending || current.state == .accepted {
            throw RepositoryError.notAllowed(reason: "You already asked for next week's pass.")
        }
        let request = PassRequest(id: await store.newID(), student: student.id, maskedID: student.maskedID,
                                  messName: mess.name, week: nextWeek, requestedAt: core.clock.now(), state: .pending)
        await store.add(request)
        return request
    }

    func cancel(for student: StudentID) async throws {
        try await core.requireConnection()
        guard let current = try await status(for: student), current.state == .pending else {
            throw RepositoryError.notAllowed(reason: "Only a waiting request can be cancelled.")
        }
        _ = await store.update(current.id) { $0.state = .cancelled }
    }

    func queue(by role: Role) async throws -> PassRequestQueue {
        try await core.requireConnection()
        try requireAdmin(role)
        let week = nextWeek
        let forWeek = await requests().filter { $0.week == week }
        return PassRequestQueue(week: week, pending: forWeek.filter { $0.state == .pending }.sorted { $0.requestedAt < $1.requestedAt },
                                approvedCount: forWeek.filter { $0.state == .accepted }.count)
    }

    func accept(_ id: PassRequestID, by role: Role) async throws -> PassRequest {
        try await decide(id, .accepted, by: role)
    }

    func decline(_ id: PassRequestID, by role: Role) async throws -> PassRequest {
        try await decide(id, .declined, by: role)
    }

    private func decide(_ id: PassRequestID, _ state: PassRequestState, by role: Role) async throws -> PassRequest {
        try await core.requireConnection()
        try requireAdmin(role)
        guard let current = await requests().first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        guard current.state == .pending else { throw RepositoryError.notAllowed(reason: "This request is already decided.") }
        let now = core.clock.now()
        guard let updated = await store.update(id, { $0.state = state; $0.decidedAt = now }) else {
            throw RepositoryError.notFound
        }
        return updated
    }

    func isPassUsable(for student: StudentID, on date: Date) async throws -> Bool {
        try await core.requireConnection()
        let calendar = PassWeekMath.calendar(timeZone)
        // This week: the pass the story already issued to the sample student.
        if PassWeekMath.week(containing: core.clock.now(), timeZone: timeZone).contains(date, calendar: calendar) {
            return student == DemoSeed.sampleStudent.id
        }
        return await requests().contains {
            $0.student == student && $0.state == .accepted && $0.week.contains(date, calendar: calendar)
        }
    }
}

extension DemoSeed {
    /// SAMPLE, from admin_passes_01_requests: ••0412 (Tue 13 Aug, Main), ••0377 (Wed 14 Aug, North), ••0190 (Wed 14 Aug,
    /// South). The image's ••0238 is the sample student, who starts with no request so the Student flow can be shown.
    static func samplePassRequests(week: PassWeek) -> [PassRequest] {
        [("0412", 13, "Main Mess"), ("0377", 14, "North Mess"), ("0190", 14, "South Mess")].map { id, day, mess in
            PassRequest(id: PassRequestID("demo-pass-request-sample-\(id)"), student: StudentID("demo-student-\(id)"),
                        maskedID: "••\(id)", messName: mess, week: week, requestedAt: date(day, 9, 0), state: .pending)
        }
    }
}
#endif
