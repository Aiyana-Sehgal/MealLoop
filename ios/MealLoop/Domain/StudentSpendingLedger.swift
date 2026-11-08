import Foundation

// The student's private spending ledger (Spending 221:63988, Add expense 221:64118, Edit expense 221:64238). Only the
// student who wrote an entry can read it; no staff or Admin operation exists. Additive: nothing existing uses it.

enum StudentExpenseTag {}
typealias StudentExpenseID = Identifier<StudentExpenseTag>

/// The category chips of Add expense (221:64118), in the frame's order.
enum StudentExpenseCategory: String, Codable, Sendable, Hashable, CaseIterable {
    case foodDelivery
    case canteen
    case snacks
    case groceries
    case other
}

/// What the student typed in Add expense or Edit expense. Whole rupees.
struct StudentExpenseDraft: Codable, Sendable, Hashable {
    var amount: Int
    var day: Date
    var category: StudentExpenseCategory
    /// "Place (optional)". Nil when empty.
    var place: String?
    /// "Note (optional)". Nil when empty.
    var note: String?

    /// Blank optional text becomes nil; text is trimmed.
    var normalised: StudentExpenseDraft {
        func clean(_ text: String?) -> String? {
            let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }
        return StudentExpenseDraft(amount: amount, day: day, category: category, place: clean(place), note: clean(note))
    }
}

/// One recorded expense.
struct StudentExpense: Codable, Sendable, Hashable, Identifiable {
    let id: StudentExpenseID
    let amount: Int
    let day: Date
    let category: StudentExpenseCategory
    let place: String?
    let note: String?
    /// When it was written, so two entries on one day keep the order they were added in.
    let recordedAt: Date

    var draft: StudentExpenseDraft {
        StudentExpenseDraft(amount: amount, day: day, category: category, place: place, note: note)
    }
}

/// What Spending shows, computed from the entries alone. Nothing here is stored or typed in.
struct StudentSpendingSummary: Sendable, Hashable {
    /// The weeks of the current month up to today, Monday to Sunday, cut at the 1st and at today. A week with no
    /// entry has a nil amount: nothing was written, which is not shown as ₹0.
    let weeks: [StudentSpendingWeek]
    /// Newest first.
    let recent: [StudentExpense]
    /// Nil when nothing was written this month.
    let monthTotal: Int?
    /// Nil when nothing was written this week.
    let thisWeek: Int?

    var isEmpty: Bool { recent.isEmpty }
}

enum StudentSpendingMath {
    /// The summary for `today` in `timeZone`. Entries in other months count in no week and in no total, but stay in
    /// Recent so an edit to another month never hides an entry.
    static func summary(of entries: [StudentExpense], today: Date, timeZone: TimeZone) -> StudentSpendingSummary {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2 // Monday
        let todayStart = calendar.startOfDay(for: today)
        guard let month = calendar.dateInterval(of: .month, for: todayStart) else {
            return StudentSpendingSummary(weeks: [], recent: sorted(entries, calendar), monthTotal: nil, thisWeek: nil)
        }
        var weeks: [StudentSpendingWeek] = []
        var start = month.start
        while start <= todayStart {
            let weekEnd = calendar.dateInterval(of: .weekOfYear, for: start).map {
                calendar.date(byAdding: .day, value: -1, to: $0.end) ?? start
            } ?? start
            let end = min(weekEnd, todayStart)
            let amounts = entries.filter {
                let day = calendar.startOfDay(for: $0.day)
                return day >= start && day <= end
            }.map(\.amount)
            weeks.append(StudentSpendingWeek(start: start, end: end, amount: amounts.isEmpty ? nil : amounts.reduce(0, +),
                                             isCurrent: end == todayStart))
            guard let next = calendar.date(byAdding: .day, value: 1, to: end) else { break }
            start = next
        }
        let inMonth = weeks.compactMap(\.amount)
        return StudentSpendingSummary(weeks: weeks, recent: sorted(entries, calendar),
                                      monthTotal: inMonth.isEmpty ? nil : inMonth.reduce(0, +),
                                      thisWeek: weeks.last?.amount)
    }

    /// Newest day first; on one day, the one written last first.
    private static func sorted(_ entries: [StudentExpense], _ calendar: Calendar) -> [StudentExpense] {
        entries.sorted {
            (calendar.startOfDay(for: $0.day), $0.recordedAt) > (calendar.startOfDay(for: $1.day), $1.recordedAt)
        }
    }

    /// The reasons a draft is refused, in the order the form shows them. Empty when it can be saved.
    static func problems(in draft: StudentExpenseDraft, today: Date, timeZone: TimeZone) -> [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var problems: [String] = []
        if draft.amount <= 0 { problems.append("amount") }
        if calendar.startOfDay(for: draft.day) > calendar.startOfDay(for: today) { problems.append("day") }
        return problems
    }
}
