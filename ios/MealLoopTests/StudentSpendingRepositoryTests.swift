#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The additive private spending ledger: totals come from the entries, and only the student can read them.
final class StudentSpendingRepositoryTests: XCTestCase {
    private let aarav = DemoSeed.sampleStudent.id
    private let stranger = StudentID("demo-student-unknown")
    private let timeZone = TimeZone(identifier: "Asia/Kolkata")!

    private func make(_ scenario: DemoScenario = .storyStart) -> (DemoDataProvider, any StudentSpendingRepository) {
        let provider = DemoDataProvider(scenario: scenario)
        return (provider, provider.makeRepositories().studentSpending)
    }

    private func summary(_ repo: any StudentSpendingRepository, _ provider: DemoDataProvider) async throws
        -> StudentSpendingSummary {
        StudentSpendingMath.summary(of: try await repo.expenses(for: aarav), today: provider.clock.now(), timeZone: timeZone)
    }

    func testTheSeedGivesTheFramesTotalsComputedFromEntries() async throws {
        let (provider, repo) = make()
        let summary = try await summary(repo, provider)
        XCTAssertEqual(summary.monthTotal, 3000, "Spending 221:63988")
        XCTAssertEqual(summary.thisWeek, 500)
        XCTAssertEqual(summary.weeks.map(\.amount), [1125, 1285 + 90, 500])
        XCTAssertEqual(summary.weeks.map(\.isCurrent), [false, false, true])
        XCTAssertEqual(summary.recent.first?.category, .foodDelivery, "Newest first.")
    }

    func testWeeksRunMondayToSundayCutAtTheFirstAndToday() {
        let today = DemoSeed.time(9, 0)
        let weeks = StudentSpendingMath.summary(of: [], today: today, timeZone: timeZone).weeks
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        XCTAssertEqual(weeks.map { calendar.component(.day, from: $0.start) }, [1, 5, 12])
        XCTAssertEqual(weeks.map { calendar.component(.day, from: $0.end) }, [4, 11, 14])
        XCTAssertEqual(weeks.map(\.amount), [nil, nil, nil], "A week with nothing written is never ₹0.")
    }

    func testAddingAnExpenseMovesTheTotalAndTheWeek() async throws {
        let (provider, repo) = make()
        let added = try await repo.addExpense(StudentExpenseDraft(amount: 60, day: provider.clock.now(), category: .canteen,
                                                                  place: "  ", note: nil), for: aarav)
        XCTAssertNil(added.place, "Blank optional text is not stored.")
        let summary = try await summary(repo, provider)
        XCTAssertEqual(summary.monthTotal, 3060, "Spending · Saved 221:64164")
        XCTAssertEqual(summary.thisWeek, 560)
        XCTAssertEqual(summary.recent.first?.id, added.id)
    }

    func testEditingReplacesTheFieldsAndKeepsTheID() async throws {
        let (provider, repo) = make()
        let id = StudentExpenseID("demo-expense-canteen")
        let edited = try await repo.updateExpense(id, with: StudentExpenseDraft(amount: 200, day: DemoSeed.date(12, 12, 0),
                                                                                 category: .snacks, place: "Night order",
                                                                                 note: nil), for: aarav)
        XCTAssertEqual(edited.id, id)
        XCTAssertEqual(edited.place, "Night order")
        let summary = try await summary(repo, provider)
        XCTAssertEqual(summary.thisWeek, 520)
        XCTAssertEqual(summary.monthTotal, 3020)
    }

    func testDeletingRemovesTheEntryFromEveryFigure() async throws {
        let (provider, repo) = make()
        try await repo.deleteExpense(StudentExpenseID("demo-expense-delivery"), for: aarav)
        let summary = try await summary(repo, provider)
        XCTAssertEqual(summary.thisWeek, 180)
        XCTAssertEqual(summary.monthTotal, 2680)
        XCTAssertFalse(summary.recent.contains { $0.id == StudentExpenseID("demo-expense-delivery") })
    }

    func testAZeroAmountAndAFutureDayAreRefusedAndNothingIsRecorded() async throws {
        let (provider, repo) = make()
        let before = try await repo.expenses(for: aarav)
        for draft in [StudentExpenseDraft(amount: 0, day: provider.clock.now(), category: .snacks),
                      StudentExpenseDraft(amount: 50, day: DemoSeed.date(15, 12, 0), category: .snacks)] {
            do {
                _ = try await repo.addExpense(draft, for: aarav)
                XCTFail("Refused: \(draft)")
            } catch RepositoryError.validationFailed {}
        }
        let after = try await repo.expenses(for: aarav)
        XCTAssertEqual(after, before)
    }

    func testAnotherStudentNeitherSeesNorChangesTheEntries() async throws {
        let (_, repo) = make()
        let theirs = try await repo.expenses(for: stranger)
        XCTAssertEqual(theirs, [], "Private: only the student who wrote them.")
        do {
            try await repo.deleteExpense(StudentExpenseID("demo-expense-delivery"), for: stranger)
            XCTFail("Not their entry.")
        } catch RepositoryError.notFound {}
        let mine = try await repo.expenses(for: aarav)
        XCTAssertEqual(mine.count, DemoSeed.sampleExpenses.count)
    }

    func testOfflineRecordsNothing() async throws {
        let (provider, repo) = make(.offline)
        do {
            _ = try await repo.addExpense(StudentExpenseDraft(amount: 60, day: provider.clock.now(), category: .canteen),
                                          for: aarav)
            XCTFail("Offline never records.")
        } catch RepositoryError.offline {}
    }
}

private extension StudentExpenseDraft {
    init(amount: Int, day: Date, category: StudentExpenseCategory) {
        self.init(amount: amount, day: day, category: category, place: nil, note: nil)
    }
}
#endif
