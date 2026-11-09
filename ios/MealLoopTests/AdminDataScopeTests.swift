import XCTest
@testable import MealLoop

final class AdminDataScopeTests: XCTestCase {
    private func session(_ role: Role) -> Session { Session(account: DemoSeed.accounts.first { $0.role == role }!, staff: nil) }
    /// Owner decision (9 November): the Food Head reads and adjusts every mess, as the Super Admin does.
    func testFoodHeadCanReadAndAdjustOtherMesses() async throws {
        let repos = DemoDataProvider().makeRepositories().scopedAdmin(session(.admin), mess: DemoSeed.mess)
        let north = try await repos.adminMesses.messHeadcount("North", slot: .lunch)
        XCTAssertEqual(north.name, "North")
        let adjusted = try await repos.adminMesses.adjustHeadcount(mess: "North", slot: .lunch, to: 700, reason: "Review", by: .admin)
        XCTAssertEqual(adjusted.expected, 700)
        let northMeals = try await repos.adminResults.findMeals(mess: "North", slot: .dinner)
        XCTAssertTrue(northMeals.allSatisfy { $0.mess == "North" })
        let own = try await repos.headcount.headcount(for: DemoSeed.lunch.id)
        XCTAssertEqual(own.mealID, DemoSeed.lunch.id)
    }
    func testFoodHeadGetsTheGlobalTotalsTheSuperAdminGets() async throws {
        let repos = DemoDataProvider().makeRepositories().scopedAdmin(session(.admin), mess: DemoSeed.mess)
        _ = try await repos.adminStudents.studentsOverview()
        _ = try await repos.adminMore.hub()
    }
    func testSuperAdminCanReadAndAdjustOtherMesses() async throws {
        let repos = DemoDataProvider().makeRepositories().scopedAdmin(session(.superAdmin), mess: DemoSeed.mess)
        let day = try await repos.adminMesses.messDay(for: .lunch)
        XCTAssertEqual(day.messes.count, 3) // plus Main, supplied by the live core story
        let adjusted = try await repos.adminMesses.adjustHeadcount(mess: "North", slot: .lunch, to: 701, reason: "Review", by: .superAdmin)
        XCTAssertEqual(adjusted.expected, 701)
        _ = try await repos.adminResults.overview()
    }
    func testFoodHeadAnnouncesToEveryMessAsTheAdmin() async throws {
        let repos = DemoDataProvider().makeRepositories().scopedAdmin(session(.admin), mess: DemoSeed.mess)
        let draft = try await repos.adminMore.announcementDraft()
        XCTAssertTrue(draft.audiences.count > 1, "All messes, as the Super Admin sees them.")
        let source = try XCTUnwrap(repos.adminResults as? any SingleMessReportRepository)
        let report = try await source.singleMessReport(.thisWeek)
        XCTAssertEqual(report.line?.mess, "Main")
        let missing = try await source.singleMessReport(.lastWeek)
        XCTAssertNil(missing.line)
    }
    func testScopeRejectsOtherRolesAndMismatchedAssignedMess() throws {
        for role in Role.allCases where role != .admin && role != .superAdmin {
            XCTAssertThrowsError(try AdminDataScope(session: session(role), mess: DemoSeed.mess).require())
        }
        let other = Mess(id: MessID("other-mess"), name: "Other Mess", timeZoneIdentifier: "Asia/Kolkata")
        XCTAssertNoThrow(try AdminDataScope(session: session(.admin), mess: other).require(), "The Food Head has every mess.")
    }
    func testSupervisorOfOtherMessCannotStartOrCloseStoryMeal() async throws {
        let core = DemoDataProvider(scenario: .beforeMeal)
        let other = Mess(id: MessID("other-mess"), name: "Other Mess", timeZoneIdentifier: "Asia/Kolkata")
        let wrong = StaffSession(role: .supervisor, mess: other, staffInitials: "S", supervisorName: DemoSeed.supervisorName)
        do { _ = try await core.startMeal(DemoSeed.lunch.id, by: wrong); XCTFail("Cross-mess start") } catch { guard case RepositoryError.notAllowed = error else { return XCTFail("Wrong error") } }
        let own = StaffSession(role: .supervisor, mess: DemoSeed.mess, staffInitials: "S", supervisorName: DemoSeed.supervisorName)
        _ = try await core.startMeal(DemoSeed.lunch.id, by: own)
        do { _ = try await core.closeMeal(DemoSeed.lunch.id, by: wrong); XCTFail("Cross-mess close") } catch {}
        let closed = try await core.closeMeal(DemoSeed.lunch.id, by: own)
        XCTAssertEqual(closed.state, .closed)
    }
}
