#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SIMULATED. The ledger of one run of the app, per student. The sample student starts with the seed's labelled
/// entries; everyone else starts empty. Nothing is sent anywhere.
actor DemoStudentSpendingStore {
    private var ledgers: [StudentID: [StudentExpense]] = [:]
    private var seeded: Set<StudentID> = []
    private var nextNumber = 1

    func ledger(for student: StudentID, seed: () -> [StudentExpense]) -> [StudentExpense] {
        if !seeded.contains(student) {
            seeded.insert(student)
            ledgers[student] = seed()
        }
        return ledgers[student] ?? []
    }

    func replace(_ ledger: [StudentExpense], for student: StudentID) {
        ledgers[student] = ledger
    }

    func newID() -> StudentExpenseID {
        defer { nextNumber += 1 }
        return StudentExpenseID("demo-expense-new-\(nextNumber)")
    }
}

/// SIMULATED. Spending on top of the prototype data source: offline throws like every other operation, and a refused
/// draft records nothing.
struct DemoStudentSpending: StudentSpendingRepository {
    let core: DemoDataProvider
    let store: DemoStudentSpendingStore

    private var timeZone: TimeZone { TimeZone(identifier: DemoSeed.mess.timeZoneIdentifier) ?? .current }

    private func ledger(for student: StudentID) async -> [StudentExpense] {
        await store.ledger(for: student) {
            student == DemoSeed.sampleStudent.id ? DemoSeed.sampleExpenses : []
        }
    }

    func expenses(for student: StudentID) async throws -> [StudentExpense] {
        try await core.requireConnection()
        return StudentSpendingMath.summary(of: await ledger(for: student), today: core.clock.now(), timeZone: timeZone).recent
    }

    func addExpense(_ draft: StudentExpenseDraft, for student: StudentID) async throws -> StudentExpense {
        try await core.requireConnection()
        let draft = draft.normalised
        let problems = StudentSpendingMath.problems(in: draft, today: core.clock.now(), timeZone: timeZone)
        guard problems.isEmpty else { throw RepositoryError.validationFailed(problems) }
        let expense = StudentExpense(id: await store.newID(), amount: draft.amount, day: draft.day, category: draft.category,
                                     place: draft.place, note: draft.note, recordedAt: core.clock.now())
        await store.replace(await ledger(for: student) + [expense], for: student)
        return expense
    }

    func updateExpense(_ id: StudentExpenseID, with draft: StudentExpenseDraft, for student: StudentID) async throws
        -> StudentExpense {
        try await core.requireConnection()
        var entries = await ledger(for: student)
        guard let index = entries.firstIndex(where: { $0.id == id }) else { throw RepositoryError.notFound }
        let draft = draft.normalised
        let problems = StudentSpendingMath.problems(in: draft, today: core.clock.now(), timeZone: timeZone)
        guard problems.isEmpty else { throw RepositoryError.validationFailed(problems) }
        let updated = StudentExpense(id: id, amount: draft.amount, day: draft.day, category: draft.category,
                                     place: draft.place, note: draft.note, recordedAt: entries[index].recordedAt)
        entries[index] = updated
        await store.replace(entries, for: student)
        return updated
    }

    func deleteExpense(_ id: StudentExpenseID, for student: StudentID) async throws {
        try await core.requireConnection()
        var entries = await ledger(for: student)
        guard let index = entries.firstIndex(where: { $0.id == id }) else { throw RepositoryError.notFound }
        entries.remove(at: index)
        await store.replace(entries, for: student)
    }
}

extension DemoSeed {
    /// SAMPLE, not measured. Spending (221:63988) draws "Food delivery · Wed 14 Aug · dinner order · ₹320", "Canteen ·
    /// Mon 12 Aug · snacks · ₹180" and "Snacks · Sat 10 Aug · ₹90", a month of ₹3,000 and ₹500 this week. The frame does
    /// not draw the rest of the month's entries, so two "Other" entries carry the remainder: ₹1,125 in 1–4 Aug and
    /// ₹1,285 in 5–11 Aug, which keeps the frame's bar order (the middle week tallest). Spending · Saved (221:64164) then
    /// reads ₹3,060 and ₹560 after "Canteen ₹60", as drawn.
    static let sampleExpenses: [StudentExpense] = [
        sampleExpense("demo-expense-1", 1125, day: 2, .other, note: nil),
        sampleExpense("demo-expense-2", 1285, day: 8, .other, note: nil),
        sampleExpense("demo-expense-snacks", 90, day: 10, .snacks, note: nil),
        sampleExpense("demo-expense-canteen", 180, day: 12, .canteen, note: "snacks"),
        sampleExpense("demo-expense-delivery", 320, day: 14, .foodDelivery, note: "dinner order"),
    ]

    private static func sampleExpense(_ id: String, _ amount: Int, day: Int, _ category: StudentExpenseCategory,
                                      note: String?) -> StudentExpense {
        StudentExpense(id: StudentExpenseID(id), amount: amount, day: date(day, 0, 0), category: category, place: nil,
                       note: note, recordedAt: date(day, 0, 0))
    }
}
#endif
