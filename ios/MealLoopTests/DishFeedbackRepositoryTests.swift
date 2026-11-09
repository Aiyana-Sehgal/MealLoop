#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// Dish feedback after Not good (2159:149347 and the other Feedback sheets): additive operations only.
final class DishFeedbackRepositoryTests: XCTestCase {
    private let aarav = DemoSeed.sampleStudent.id
    private let other = StudentID("demo-student-other")
    private let mess = DemoSeed.mess.id
    private let day = DemoSeed.time(0, 0)

    private func make(_ scenario: DemoScenario = .afterMeal) -> (DemoDataProvider, Repositories) {
        let provider = DemoDataProvider(scenario: scenario)
        return (provider, provider.makeRepositories())
    }

    private func sambar(_ problem: String = "Too salty", key: String = "k1", severity: DishFeedbackSeverity = .quite)
        -> DishFeedbackSubmission {
        DishFeedbackSubmission(dishName: "Masala Sambar", day: day, slot: .lunch, problem: problem, severity: severity,
                               note: nil, key: IdempotencyKey(key))
    }

    func testEachDishHasItsFramesChoices() async throws {
        let (_, repositories) = make()
        let sambar = try await repositories.dishFeedback.problems(forDish: "Masala Sambar").map(\.title)
        XCTAssertEqual(sambar, ["Too salty", "Too spicy", "Too watery", "Too sour", "Cold", "Too little"])
        let milk = try await repositories.dishFeedback.problems(forDish: "Milk").map(\.title)
        XCTAssertEqual(milk, ["Too sour", "Watery", "Not fresh", "Warm", "Too little"])
        let pongal = try await repositories.dishFeedback.problems(forDish: "Pongal").map(\.title)
        XCTAssertEqual(pongal.first, "Undercooked")
    }

    func testOthersCountsComeFromTheFeedbackDataAndAreNeverZero() async throws {
        let (_, repositories) = make()
        let counts = try await repositories.dishFeedback.otherCounts(dish: "Masala Sambar", day: day, slot: .lunch, at: mess,
                                                                      excluding: aarav)
        XCTAssertEqual(counts, ["Too salty": 6], "The Admin seed's six; a problem nobody reported is absent.")
        let none = try await repositories.dishFeedback.otherCounts(dish: "Pongal", day: day, slot: .breakfast, at: mess,
                                                                    excluding: aarav)
        XCTAssertTrue(none.isEmpty)
    }

    func testASendAddsToTheAdminCountAndMyFeedbackWithoutAName() async throws {
        let (_, repositories) = make()
        let receipt = try await repositories.dishFeedback.send(sambar(severity: .very), at: mess, by: aarav)
        _ = try await repositories.dishFeedback.send(sambar(severity: .very), at: mess, by: aarav)
        XCTAssertEqual(receipt.submission.problem, "Too salty")
        let overview = try await repositories.adminStudents.studentsOverview()
        let item = try XCTUnwrap(overview.feedback.first { $0.id == AdminSeed.sambarFeedback })
        XCTAssertEqual(item.students, 7, "The same key counts once.")
        XCTAssertEqual(item.problems.first?.severity, "How bad: quite (5), very (2)")
        let mine = try await repositories.studentRecords.feedback(for: aarav)
        XCTAssertEqual(mine.items.first?.dish, "Masala Sambar")
        XCTAssertEqual(mine.items.first?.stage, .reported)
        let mirror = Mirror(reflecting: item)
        XCTAssertFalse(mirror.children.contains { $0.label?.lowercased().contains("student") == true && $0.label != "students" },
                       "An item never carries who sent it.")
        let mostReported = try await repositories.dishFeedback.mostReported(day: day, slot: .lunch, at: mess)
        XCTAssertEqual(mostReported?.students, 7)
        let othersForAarav = try await repositories.dishFeedback.otherCounts(dish: "Masala Sambar", day: day, slot: .lunch,
                                                                              at: mess, excluding: aarav)
        XCTAssertEqual(othersForAarav["Too salty"], 6, "The student's own send is not one of the others.")
    }

    func testANewProblemStartsItsOwnAdminItem() async throws {
        let (_, repositories) = make()
        _ = try await repositories.dishFeedback.send(sambar("Cold", key: "k2", severity: .aBit), at: mess, by: other)
        let overview = try await repositories.adminStudents.studentsOverview()
        let cold = try XCTUnwrap(overview.feedback.first { $0.problem == "cold" })
        XCTAssertEqual(cold.students, 1)
        XCTAssertEqual(cold.problems.first?.severity, "How bad: a bit (1)")
        XCTAssertEqual(cold.meal, DemoSeed.lunch.id)
        let detail = try await repositories.adminStudents.feedback(cold.id)
        XCTAssertEqual(detail.students, 1)
    }

    func testOfflineNothingIsSentAndKeptFeedbackSendsLater() async throws {
        let (provider, repositories) = make(.offline)
        do {
            _ = try await repositories.dishFeedback.send(sambar(), at: mess, by: aarav)
            XCTFail("Offline never sends.")
        } catch RepositoryError.offline {}
        await repositories.dishFeedback.keepForLater(sambar(), at: mess, by: aarav)
        let kept = await repositories.dishFeedback.kept(by: aarav)
        XCTAssertEqual(kept.count, 1)
        do {
            _ = try await repositories.dishFeedback.sendKept(by: aarav)
            XCTFail("Still offline.")
        } catch RepositoryError.offline {}
        await provider.setScenario(.afterMeal)
        let overviewBefore = try await repositories.adminStudents.studentsOverview()
        XCTAssertEqual(overviewBefore.feedback.first?.students, 6, "Kept is not counted.")
        let receipts = try await repositories.dishFeedback.sendKept(by: aarav)
        XCTAssertEqual(receipts.count, 1)
        let keptAfter = await repositories.dishFeedback.kept(by: aarav)
        XCTAssertTrue(keptAfter.isEmpty)
        let overview = try await repositories.adminStudents.studentsOverview()
        XCTAssertEqual(overview.feedback.first?.students, 7)
    }

    func testSeverityLineRoundTrips() {
        let counts = DemoDishFeedbackTally.parse("How bad: quite (5), very (1)")
        XCTAssertEqual(counts, [.quite: 5, .very: 1])
        XCTAssertEqual(DemoDishFeedbackTally.severityLine(counts), "How bad: quite (5), very (1)")
    }
}
#endif
