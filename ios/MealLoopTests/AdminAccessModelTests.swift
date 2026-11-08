import XCTest
@testable import MealLoop

@MainActor final class AdminAccessModelTests: XCTestCase {
    private func session(_ role: Role) -> Session { Session(account: DemoSeed.accounts.first { $0.role == role }!, staff: nil) }
    func testFoodHeadOnlyOwnMessAndNoPeople() async throws {
        let core = DemoDataProvider()
        let context = try XCTUnwrap(AdminContext(session: session(.admin)))
        XCTAssertFalse(context.allMesses)
        XCTAssertFalse(context.canManagePeople)
        let model = AdminTodayViewModel(context: context, repositories: core.makeRepositories().scopedAdmin(session(.admin), mess: context.mess), clock: core.clock)
        await model.load()
        XCTAssertNil(model.state.value?.otherMesses)
        XCTAssertEqual(model.state.value?.mess.id, DemoSeed.mess.id)
        let access = AdminAccessModel(session: session(.admin), repository: core.makeRepositories().people)
        await access.load()
        XCTAssertNil(access.state.value)
    }
    func testInvitedFoodHeadGetsAssignedMessWithoutMainFallback() async throws {
        let core = DemoDataProvider()
        let people = core.makeRepositories().people
        let directory = try await people.directory(by: session(.superAdmin))
        let north = directory.messes[1]
        let given = try await people.invite(name: "Sample name", contact: "new-head@mealloop.example", role: .admin, mess: north.id, by: session(.superAdmin))
        let signedIn = try await core.signInStaff(email: given.person.account.email, password: given.value)
        let context = try XCTUnwrap(AdminContext(session: signedIn))
        XCTAssertEqual(context.mess.id, north.id)
        XCTAssertFalse(context.allMesses)
        let repos = core.makeRepositories().scopedAdmin(signedIn, mess: north)
        let today = AdminTodayViewModel(context: context, repositories: repos, clock: core.clock)
        await today.load()
        XCTAssertNil(today.state.value, "No North live data must not become Main data")
        guard case .failed = today.state else { return XCTFail("Missing live source must say unavailable, not that no meal exists") }
        do { _ = try await repos.mealState.currentMeal(for: DemoSeed.mess.id); XCTFail("Main live-read leak") } catch {}
        do { _ = try await repos.headcount.headcount(for: DemoSeed.lunch.id); XCTFail("Main leak") } catch {}
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
