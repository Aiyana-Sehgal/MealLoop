import XCTest
@testable import MealLoop

final class AdminDataScopeTests: XCTestCase {
    private func session(_ role: Role) -> Session { Session(account: DemoSeed.accounts.first { $0.role == role }!, staff: nil) }
    func testFoodHeadBackendRefusesOtherMessAndOtherMessMeal() async throws {
        let repos = DemoDataProvider().makeRepositories().scopedAdmin(session(.admin), mess: DemoSeed.mess)
        do { _ = try await repos.adminMesses.messHeadcount("North", slot: .lunch); XCTFail("Read North") } catch { guard case RepositoryError.notAllowed = error else { return XCTFail("Wrong error") } }
        do { _ = try await repos.adminMesses.adjustHeadcount(mess: "North", slot: .lunch, to: 700, reason: "Review", by: .admin); XCTFail("Write North") } catch {}
        let all = try await repos.adminResults.findMeals(mess: nil, slot: .dinner)
        XCTAssertTrue(all.allSatisfy { $0.mess == "Main" })
        do { _ = try await repos.adminResults.findMeals(mess: "North", slot: .dinner); XCTFail("North filter") } catch {}
        do { _ = try await repos.headcount.headcount(for: MealID("other-mess-meal")); XCTFail("Other meal") } catch { guard case RepositoryError.notAllowed = error else { return XCTFail("Wrong error") } }
        let own = try await repos.headcount.headcount(for: DemoSeed.lunch.id)
        XCTAssertEqual(own.mealID, DemoSeed.lunch.id)
    }
    func testFoodHeadHasNoAccountPowersAndNoNorthCommunity() async throws {
        let repos = DemoDataProvider().makeRepositories().scopedAdmin(session(.admin), mess: DemoSeed.mess)
        do { _ = try await repos.adminMore.people(); XCTFail("People") } catch {}
        let overview = try await repos.adminStudents.studentsOverview()
        XCTAssertTrue(overview.feedback.allSatisfy { $0.mess == "Main" })
        XCTAssertTrue(overview.community.allSatisfy { $0.context.hasPrefix("Main Mess · ") })
    }
    func testSuperAdminCanReadAndAdjustOtherMesses() async throws {
        let repos = DemoDataProvider().makeRepositories().scopedAdmin(session(.superAdmin), mess: DemoSeed.mess)
        let day = try await repos.adminMesses.messDay(for: .lunch)
        XCTAssertEqual(day.messes.count, 3) // plus Main, supplied by the live core story
        let adjusted = try await repos.adminMesses.adjustHeadcount(mess: "North", slot: .lunch, to: 701, reason: "Review", by: .superAdmin)
        XCTAssertEqual(adjusted.expected, 701)
        _ = try await repos.adminResults.overview()
    }
    func testScopeRejectsOtherRolesAndMismatchedAssignedMess() throws {
        for role in Role.allCases where role != .admin && role != .superAdmin {
            XCTAssertThrowsError(try AdminDataScope(session: session(role), mess: DemoSeed.mess).require())
        }
        let other = Mess(id: MessID("other-mess"), name: "Other Mess", timeZoneIdentifier: "Asia/Kolkata")
        XCTAssertThrowsError(try AdminDataScope(session: session(.admin), mess: other).require())
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
