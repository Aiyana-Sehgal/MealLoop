#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SIMULATED. The read state of the sample notifications, kept for one run of the app.
actor DemoStudentYouStore {
    private var read: Set<StudentNotificationID> = []

    func markRead(_ id: StudentNotificationID) { read.insert(id) }
    func isRead(_ id: StudentNotificationID) -> Bool { read.contains(id) }
}

/// SIMULATED. Student You on top of the prototype data source. Credits count the student's own answers recorded in
/// `DemoDataProvider`, so an answer on Home shows here; nothing is confirmed by a server.
struct DemoStudentYou: StudentYouRepository {
    let core: DemoDataProvider
    let store: DemoStudentYouStore
    /// Reward tickets got in this run. Their cost comes off the balance and each one is a history line. Nil keeps the
    /// balance as it was before reward tickets existed.
    var rewards: DemoStudentRewardsStore?
    /// The Admin's reward catalogue. Nil keeps the seeded tickets.
    var catalogue: DemoRewardCatalogueStore?

    /// Today's meals a student can answer, in the order the day serves them.
    private static let todaysMeals = [DemoSeed.breakfast.id, DemoSeed.lunch.id, DemoSeed.dinner.id]

    func notifications(for student: StudentID) async throws -> [StudentNotification] {
        try await core.requireConnection()
        guard student == DemoSeed.sampleStudent.id else { return [] }
        var notes: [StudentNotification] = []
        for var note in DemoSeed.sampleNotifications {
            if await store.isRead(note.id) { note.isRead = true }
            notes.append(note)
        }
        return notes.sorted { $0.at > $1.at }
    }

    func markRead(_ id: StudentNotificationID, for student: StudentID) async throws -> StudentNotification {
        try await core.requireConnection()
        guard student == DemoSeed.sampleStudent.id,
              var note = DemoSeed.sampleNotifications.first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        await store.markRead(id)
        note.isRead = true
        return note
    }

    func profile(for student: StudentID, at mess: MessID) async throws -> StudentProfileSummary {
        try await core.requireConnection()
        let isSample = student == DemoSeed.sampleStudent.id
        let credits = isSample ? try await self.credits(for: student).balance : nil
        // STATE.md: "Aarav ••0238".
        return StudentProfileSummary(firstName: isSample ? "Aarav" : nil,
                                     maskedID: isSample ? DemoSeed.sampleStudent.maskedID : "",
                                     messName: DemoSeed.mess.name, credits: credits)
    }

    func credits(for student: StudentID) async throws -> StudentCredits {
        try await core.requireConnection()
        let tickets = await catalogue?.items ?? DemoSeed.sampleCreditTickets
        guard student == DemoSeed.sampleStudent.id else {
            return StudentCredits(balance: nil, tickets: tickets, history: [])
        }
        // Answers given in this run (after the story starts) earn; the sample balance already holds earlier ones.
        var earned: [StudentCreditEntry] = []
        for meal in Self.todaysMeals {
            let response = try await core.response(of: student, for: meal)
            guard case .answered(_, let at) = response, at >= DemoSeed.storyStartNow else { continue }
            let points = StudentCreditRule.points(for: response, perDefiniteAnswer: DemoSeed.samplePointsPerDefiniteAnswer)
            guard points > 0 else { continue }
            earned.append(StudentCreditEntry(id: "run-\(meal.rawValue)", title: Self.answeredTitle(meal), day: at, points: points))
        }
        // Credits history (221:64443): "Juice redeemed · Mon 12 Aug · -50 pts".
        let redeemed = (await rewards?.list(for: student) ?? []).map {
            StudentCreditEntry(id: "reward-\($0.id.rawValue)", title: "\($0.name) redeemed", day: $0.gotAt, points: -$0.cost)
        }
        let lines = earned + redeemed
        let balance = DemoSeed.sampleCredits + lines.reduce(0) { $0 + $1.points }
        return StudentCredits(balance: balance, tickets: tickets,
                              history: lines.sorted { $0.day > $1.day } + DemoSeed.sampleCreditHistory)
    }

    func attendance(for student: StudentID, at mess: MessID) async throws -> StudentAttendanceMonth {
        try await core.requireConnection()
        guard student == DemoSeed.sampleStudent.id, mess == DemoSeed.mess.id else {
            return StudentAttendanceMonth(month: DemoSeed.sampleMonthStart, marks: [:], daysInMonth: DemoSeed.sampleMonthDays,
                                          firstWeekdayOffset: DemoSeed.sampleMonthFirstWeekday, mealsEntered: nil, mealsServed: nil)
        }
        return StudentAttendanceMonth(month: DemoSeed.sampleMonthStart, marks: DemoSeed.sampleAttendanceMarks,
                                      daysInMonth: DemoSeed.sampleMonthDays, firstWeekdayOffset: DemoSeed.sampleMonthFirstWeekday,
                                      mealsEntered: DemoSeed.sampleMealsEntered, mealsServed: DemoSeed.sampleMealsServed)
    }

    private static func answeredTitle(_ meal: MealID) -> String {
        switch meal {
        case DemoSeed.breakfast.id: return "Answered breakfast"
        case DemoSeed.lunch.id: return "Answered lunch"
        default: return "Answered dinner"
        }
    }
}
#endif
