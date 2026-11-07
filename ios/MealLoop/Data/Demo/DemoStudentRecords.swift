#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SIMULATED. Replies and recheck answers recorded in one run of the app. Nothing is sent to anyone.
actor DemoStudentRecordsStore {
    private var replies: [StudentFiledReportID: (text: String, at: Date)] = [:]
    private var rechecks: [StudentFeedbackID: StudentRecheckAnswer] = [:]

    func reply(_ id: StudentFiledReportID) -> (text: String, at: Date)? { replies[id] }
    func recordReply(_ id: StudentFiledReportID, text: String, at: Date) { replies[id] = (text, at) }
    func recheck(_ id: StudentFeedbackID) -> StudentRecheckAnswer? { rechecks[id] }
    /// The first answer stays.
    func recordRecheck(_ id: StudentFeedbackID, _ answer: StudentRecheckAnswer) {
        if rechecks[id] == nil { rechecks[id] = answer }
    }
}

/// SIMULATED. Student records on top of the prototype data source. Every answer is the seed's labelled sample plus what
/// the student recorded in this run; nothing is confirmed by a server.
struct DemoStudentRecords: StudentRecordsRepository {
    let core: DemoDataProvider
    let store: DemoStudentRecordsStore

    private func isSample(_ student: StudentID) -> Bool { student == DemoSeed.sampleStudent.id }

    func reports(for student: StudentID) async throws -> [StudentFiledReport] {
        try await core.requireConnection()
        guard isSample(student) else { return [] }
        var all: [StudentFiledReport] = []
        for report in DemoSeed.sampleFiledReports { all.append(await withReply(report)) }
        let active = all.filter { !$0.stage.isClosed }.sorted { $0.sentAt > $1.sentAt }
        let closed = all.filter { $0.stage.isClosed }.sorted { $0.sentAt > $1.sentAt }
        return active + closed
    }

    func report(_ id: StudentFiledReportID, for student: StudentID) async throws -> StudentFiledReport {
        try await core.requireConnection()
        guard isSample(student), let report = DemoSeed.sampleFiledReports.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return await withReply(report)
    }

    func reply(to id: StudentFiledReportID, text: String, by student: StudentID) async throws -> StudentFiledReport {
        try await core.requireConnection()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isSample(student), let report = DemoSeed.sampleFiledReports.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        guard report.stage == .needMoreInfo, !trimmed.isEmpty else {
            throw RepositoryError.notAllowed(reason: "Only a question from the mess can be answered, and the answer needs words.")
        }
        if await store.reply(id) == nil {
            await store.recordReply(id, text: trimmed, at: core.clock.now())
        }
        return await withReply(report)
    }

    func feedback(for student: StudentID) async throws -> StudentFeedbackSummary {
        try await core.requireConnection()
        guard isSample(student) else { return StudentFeedbackSummary(items: []) }
        var items: [StudentFeedbackItem] = []
        for item in DemoSeed.sampleFeedback {
            let answer = await store.recheck(item.id)
            items.append(StudentFeedbackItem(id: item.id, dish: item.dish, problem: item.problem, stage: item.stage,
                                             at: item.at, fixNote: item.fixNote, recheck: answer ?? item.recheck))
        }
        return StudentFeedbackSummary(items: items)
    }

    func answerRecheck(_ id: StudentFeedbackID, _ answer: StudentRecheckAnswer, by student: StudentID) async throws
        -> StudentFeedbackSummary {
        try await core.requireConnection()
        guard isSample(student), let item = DemoSeed.sampleFeedback.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        guard item.stage == .fixed else {
            throw RepositoryError.notAllowed(reason: "Only a fixed dish asks if it is better.")
        }
        await store.recordRecheck(id, answer)
        return try await feedback(for: student)
    }

    func spending(for student: StudentID) async throws -> StudentSpending {
        try await core.requireConnection()
        guard isSample(student) else { return StudentSpending(weeks: [], recent: []) }
        return StudentSpending(weeks: DemoSeed.sampleSpendingWeeks, recent: DemoSeed.sampleSpendingRecent)
    }

    func help(at mess: MessID) async throws -> StudentHelp {
        try await core.requireConnection()
        guard mess == DemoSeed.mess.id else { return StudentHelp(topics: [], contact: nil) }
        return StudentHelp(topics: DemoSeed.sampleHelpTopics, contact: DemoSeed.sampleHelpContact)
    }

    func updates(for issue: CommunityIssueID) async throws -> [StudentIssueUpdate] {
        try await core.requireConnection()
        return DemoSeed.sampleIssueUpdates[issue] ?? []
    }

    /// Adds the recorded reply to the timeline. The stage stays Need more info: only the mess moves it on.
    private func withReply(_ report: StudentFiledReport) async -> StudentFiledReport {
        guard let reply = await store.reply(report.id) else { return report }
        let events = report.events + [StudentReportEvent(kind: .replied(reply.text), at: reply.at, isCurrent: false)]
        return StudentFiledReport(id: report.id, reference: report.reference, category: report.category, place: report.place,
                                  meal: report.meal, sentAt: report.sentAt, stage: report.stage, question: report.question,
                                  reply: reply.text, events: events)
    }
}
#endif
