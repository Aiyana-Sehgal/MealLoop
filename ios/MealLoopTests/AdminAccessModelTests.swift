import XCTest
@testable import MealLoop

@MainActor final class AdminAccessModelTests: XCTestCase {
    private func session(_ role: Role) -> Session { Session(account: DemoSeed.accounts.first { $0.role == role }!, staff: nil) }
    /// Owner decision (9 November): Admin and Super Admin are one role, so the Food Head sees every mess and manages people.
    func testFoodHeadSeesAllMessesAndPeopleLikeTheSuperAdmin() async throws {
        let core = DemoDataProvider()
        let context = try XCTUnwrap(AdminContext(session: session(.admin)))
        XCTAssertTrue(context.allMesses)
        XCTAssertTrue(context.canManagePeople)
        let model = AdminTodayViewModel(context: context, repositories: core.makeRepositories().scopedAdmin(session(.admin), mess: context.mess), clock: core.clock)
        await model.load()
        XCTAssertNotNil(model.state.value?.otherMesses, "The same four-mess Today as the Super Admin.")
        XCTAssertEqual(model.state.value?.mess.id, DemoSeed.mess.id)
        let access = AdminAccessModel(session: session(.admin), repository: core.makeRepositories().people)
        await access.load()
        XCTAssertNotNil(access.state.value)
    }
    func testInvitedFoodHeadGetsAssignedMessWithoutMainFallback() async throws {
        let core = DemoDataProvider()
        let people = core.makeRepositories().people
        let directory = try await people.directory(by: session(.superAdmin))
        let north = directory.messes[1]
        let given = try await people.invite(name: "Sample name", contact: "new-head@mealloop.example", role: .admin, mess: north.id, by: session(.superAdmin))
        let signedIn = try await core.signInStaff(email: given.person.account.email, password: given.value)
        let context = try XCTUnwrap(AdminContext(session: signedIn))
        XCTAssertEqual(context.mess.id, north.id, "The account keeps its assigned mess.")
        XCTAssertTrue(context.allMesses, "Owner decision (9 November): every Food Head has the all-mess scope.")
        let repos = core.makeRepositories().scopedAdmin(signedIn, mess: north)
        let main = try await repos.mealState.currentMeal(for: DemoSeed.mess.id)
        XCTAssertEqual(main?.meal.messID, DemoSeed.mess.id, "Main is read as Main, never passed off as North.")
    }
    func testSuperAdminAllMessContextAndPasswordDismissal() async throws {
        let core = DemoDataProvider()
        let context = try XCTUnwrap(AdminContext(session: session(.superAdmin)))
        XCTAssertTrue(context.allMesses)
        XCTAssertTrue(context.canManagePeople)
        let model = AdminAccessModel(session: session(.superAdmin), repository: core.makeRepositories().people)
        await model.load()
        let target = try XCTUnwrap(model.people(.doorScanner).first)
        XCTAssertTrue(target.canRevoke)
        _ = await model.give(target.id)
        XCTAssertNotNil(model.given)
        model.clearPassword()
        XCTAssertNil(model.given)
        await model.load()
        XCTAssertNil(model.given)
        _ = await model.revoke(target.id)
        XCTAssertTrue(try XCTUnwrap(model.person(target.id)).passwordRevoked)
        XCTAssertFalse(try XCTUnwrap(model.person(target.id)).canRevoke)
        XCTAssertTrue(model.people(.admin).allSatisfy { !$0.canRevoke })
    }
}
