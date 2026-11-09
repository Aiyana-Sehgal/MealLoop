#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The Admin polish rules: role-scoped Invite, Search groups that never list students, the Remind wording.
@MainActor
final class AdminPolishTests: XCTestCase {
    func testGlobalInviteOffersEveryRoleAndARolePageOnlyItsOwn() {
        XCTAssertEqual(AdminAccessCopy.inviteRoles(fixedRole: nil), AdminAccessCopy.roles)
        XCTAssertEqual(AdminAccessCopy.inviteRoles(fixedRole: nil).count, 8)
        XCTAssertEqual(AdminAccessCopy.inviteRoles(fixedRole: .doorScanner), [.doorScanner])
        XCTAssertEqual(AdminAccessCopy.inviteTitle(fixedRole: .doorScanner), "Add door staff")
        XCTAssertEqual(AdminAccessCopy.inviteTitle(fixedRole: nil), "Invite someone")
        XCTAssertEqual(AdminAccessCopy.fixedRoleLine(.doorScanner), "Role · Door staff")
    }

    private func index() async throws -> AdminSearchIndex {
        let core = DemoDataProvider(scenario: .duringMeal)
        let session = try await core.signInStaff(email: "superadmin@mealloop.example", password: DemoSeed.prototypePassword)
        let repos = core.makeRepositories()
        let directory = try await repos.people.directory(by: session)
        let menu = try await repos.adminMore.weekMenu()
        let students = try await repos.adminStudents.studentsOverview()
        return AdminSearchEngine.index(directory: directory, menu: menu, students: students, timeZone: DemoSeed.mess.timeZone)
    }

    func testSearchGroupsMealsReportsPeopleAndMesses() async throws {
        let index = try await index()
        XCTAssertFalse(index.messes.isEmpty)
        XCTAssertFalse(index.people.isEmpty)
        XCTAssertFalse(index.meals.isEmpty)
        let all = AdminSearchEngine.results(for: "sambar", scope: .all, in: index)
        XCTAssertEqual(all.map(\.group), [.meals, .reports, .people, .messes])
        XCTAssertFalse(all.first { $0.group == .meals }?.results.isEmpty ?? true)
        let onlyMeals = AdminSearchEngine.results(for: "sambar", scope: .meals, in: index)
        XCTAssertEqual(onlyMeals.map(\.group), [.meals])
        XCTAssertTrue(AdminSearchEngine.results(for: "  ", scope: .all, in: index).isEmpty, "Empty shows Recent and Jump to.")
    }

    func testSearchNeverListsAStudentByName() async throws {
        let index = try await index()
        let studentNames = DemoSeed.accounts.filter { $0.role == .student }.map(\.displayName)
        XCTAssertFalse(studentNames.isEmpty)
        for name in studentNames {
            let people = AdminSearchEngine.results(for: name, scope: .people, in: index)
            XCTAssertEqual(people.first?.results.count, 0, "\(name) is a student and is never listed.")
        }
        XCTAssertTrue(index.people.allSatisfy { !$0.id.isEmpty })
    }

    func testAGroupWithNoMatchStaysToSaySo() async throws {
        let index = try await index()
        let people = AdminSearchEngine.results(for: "zzzz", scope: .all, in: index).first { $0.group == .people }
        XCTAssertEqual(people?.results.count, 0)
        XCTAssertEqual(AdminSearchCopy.noMatch(.people, "sam"), "No one matches “sam”")
    }

    func testRemindWordingClaimsNothingDelivered() {
        XCTAssertEqual(AdminScreenCopy.remindNote, "Sends one notification. Students who already answered get nothing.")
        XCTAssertEqual(AdminScreenCopy.reminderToast, "Reminder recorded. This prototype sends nothing.")
    }

    func testNoMorePagesSayNotPartOfThisPrototype() throws {
        let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("MealLoop/Features/Admin/AdminMoreView.swift")
        let source = try String(contentsOf: file, encoding: .utf8)
        XCTAssertFalse(source.contains("notInPrototype"))
    }
}
#endif
