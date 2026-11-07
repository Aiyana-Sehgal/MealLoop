#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The additive Admin operations on the prototype backend. Existing operations are not touched.
final class AdminBackendTests: XCTestCase {
    private func admin(_ scenario: DemoScenario = .duringMeal) -> (DemoDataProvider, Repositories) {
        let demo = DemoDataProvider(scenario: scenario)
        return (demo, demo.makeRepositories())
    }

    private func refused(_ work: () async throws -> Void) async {
        do {
            try await work()
            XCTFail("Expected notAllowed")
        } catch {
            guard case RepositoryError.notAllowed = error else { return XCTFail("\(error)") }
        }
    }

    func testAnotherSourceSaysItHasNoAdminData() async {
        let repositories = RemoteAPI(baseURL: nil).makeRepositories()
        do {
            _ = try await repositories.adminResults.overview()
            XCTFail("Expected notImplemented")
        } catch {
            XCTAssertEqual(error as? RepositoryError, .notImplemented(feature: "Admin data"))
        }
    }

    func testEveryReadFollowsTheConnection() async {
        let (_, repositories) = admin(.offline)
        do {
            _ = try await repositories.adminStudents.studentsOverview()
            XCTFail("Expected offline")
        } catch {
            XCTAssertEqual(error as? RepositoryError, .offline(lastSavedAt: DemoSeed.offlineSavedAt))
        }
    }

    func testOnlyTheFoodHeadCanWrite() async {
        let (_, repositories) = admin()
        for role in Role.allCases where role != .admin {
            await refused { _ = try await repositories.adminResults.addNote("x", to: AdminSeed.northScanner, by: role) }
            await refused { _ = try await repositories.adminStudents.remind(key: .make(), by: role) }
            await refused { try await repositories.adminMore.announce("x", to: "main", by: role) }
        }
    }

    func testTheStoryMealIsReadFromTheLiveRepositories() async throws {
        let (_, during) = admin(.duringMeal)
        let open = try await during.adminResults.meal(DemoSeed.lunch.id)
        XCTAssertFalse(open.isClosed)
        XCTAssertNil(open.finalEntries, "Live entries are never final")

        let (_, after) = admin(.afterMeal)
        let closed = try await after.adminResults.meal(DemoSeed.lunch.id)
        XCTAssertEqual(closed.finalEntries, DemoSeed.finalEntries)
        XCTAssertTrue(closed.missing.contains(.wasteRecord))
        XCTAssertNil(closed.plateWasteKg, "No waste record is not zero")
        XCTAssertNil(closed.dataCompletePercent)
    }

    func testAKitchenReportReachesTheMealReport() async throws {
        let (demo, repositories) = admin(.afterMeal)
        var report = try await demo.report(for: DemoSeed.lunch.id)
        for index in report.leftovers.indices { report.leftovers[index].measurement = .noneLeft }
        report.leftovers[0].measurement = .entered(4)
        report.plateWaste = .entered(kilograms: 18)
        _ = try await demo.save(report, by: .kitchenStaff)

        let meal = try await repositories.adminResults.meal(DemoSeed.lunch.id)
        XCTAssertEqual(meal.plateWasteKg, 18)
        XCTAssertEqual(meal.leftovers.map(\.amount), [4])
        XCTAssertFalse(meal.missing.contains(.wasteRecord))
    }

    /// Integration item 4: one record per meal, read by both roles. 598 is the Supervisor's figure (supervisor_spec.md:19).
    func testAdminAndSupervisorAgreeOnTuesdayDinner() async throws {
        let (demo, repositories) = admin()
        let history = try await demo.mealHistory(for: DemoSeed.mess.id)
        let record = try XCTUnwrap(history.first { $0.mealID == AdminSeed.tueDinnerMain })
        let meal = try await repositories.adminResults.meal(AdminSeed.tueDinnerMain)
        XCTAssertEqual(record.finalEntries.value, 598)
        XCTAssertEqual(meal.finalEntries, record.finalEntries.value)
        XCTAssertEqual(record.waste, .notRecorded)
        XCTAssertNil(meal.plateWasteKg, "Waste is not recorded, so Admin shows no plate waste")
        XCTAssertNil(meal.headcountSent, "No spec document gives this meal's headcount")
        XCTAssertNil(meal.dataCompletePercent)
        XCTAssertTrue(meal.missing.contains(.wasteRecord))
        let found = try await repositories.adminResults.findMeals(mess: "Main", slot: .dinner)
        XCTAssertEqual(found.first { $0.id == AdminSeed.tueDinnerMain }?.finalEntries, 598)
    }

    /// The story lunch's final entries come from `finalCount(for:)` for Admin, Supervisor and Kitchen alike (774,
    /// kitchen_spec.md:3 and supervisor_spec.md:3).
    func testAdminAndSupervisorAgreeOnTheClosedStoryLunch() async throws {
        let (demo, repositories) = admin(.afterMeal)
        let history = try await demo.mealHistory(for: DemoSeed.mess.id)
        let record = try XCTUnwrap(history.first { $0.mealID == DemoSeed.lunch.id })
        let meal = try await repositories.adminResults.meal(DemoSeed.lunch.id)
        XCTAssertEqual(meal.finalEntries, record.finalEntries.value)
        let final = try await demo.finalCount(for: DemoSeed.lunch.id)
        XCTAssertNotNil(final.value)
        XCTAssertEqual(meal.finalEntries, final.value)
    }

    func testAChangeForAMealIsNotOpenedTwice() async throws {
        let (_, repositories) = admin()
        let draft = ChangeDraft(meal: AdminSeed.tueDinnerMain, change: "Keep more rice ready", owner: "Devi")
        let first = try await repositories.adminResults.saveChange(draft, by: .admin)
        let again = try await repositories.adminResults.saveChange(draft, by: .admin)
        XCTAssertEqual(first.id, again.id)
        let meal = try await repositories.adminResults.meal(AdminSeed.tueDinnerMain)
        XCTAssertFalse(meal.needsReview)
        XCTAssertEqual(meal.linkedCheck, first.id)
    }

    func testTheSameReminderKeyChangesNothing() async throws {
        let (demo, repositories) = admin()
        let key = IdempotencyKey.make()
        let first = try await repositories.adminStudents.remind(key: key, by: .admin)
        demo.clock.set(DemoSeed.afterMealNow)
        let again = try await repositories.adminStudents.remind(key: key, by: .admin)
        XCTAssertEqual(first.reminderSentAt, again.reminderSentAt)
    }

    func testTheBoardHasFourMealsEveryDayAndNoOrBetweenDishes() async throws {
        let (_, repositories) = admin()
        let menu = try await repositories.adminMore.weekMenu()
        XCTAssertEqual(menu.days.count, 7)
        for day in menu.days {
            XCTAssertEqual(Set(day.meals.keys), Set(MealSlot.allCases))
            for dish in day.meals.values.flatMap({ $0 }) {
                XCTAssertFalse(dish.name.contains(" or "), dish.name)
                XCTAssertFalse(dish.name.contains("/"), dish.name)
            }
        }
        let thursday = try XCTUnwrap(menu.days.first { $0.day == DemoSeed.date(15, 0, 0) })
        XCTAssertEqual(thursday.wordsToCheck, 2)
    }

    func testTodaysDinnerChangesOnlyTodaysDinner() async throws {
        let (_, repositories) = admin()
        let before = try await repositories.adminMore.weekMenu()
        let after = try await repositories.adminMore.applyToTodaysDinner(.addSpecial(name: "Chicken Biryani", isLimited: true, isNonVeg: true), by: .admin)
        let today = try XCTUnwrap(after.days.first { $0.day == after.today })
        XCTAssertEqual(today.meals[.dinner]?.last?.name, "Chicken Biryani")
        XCTAssertEqual(today.meals[.dinner]?.last?.isLimited, true)
        XCTAssertEqual(before.days.filter { $0.day != before.today }, after.days.filter { $0.day != after.today })
    }
}
#endif
