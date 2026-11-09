import XCTest
@testable import MealLoop

final class PeopleAccessTests: XCTestCase {
    private func account(_ role: Role) -> Account { DemoSeed.accounts.first { $0.role == role }! }
    private func session(_ role: Role) -> Session { Session(account: account(role), staff: nil) }
    func testRevokeBlocksNewSignInAndGiveReplacesSharedPassword() async throws {
        let core = DemoDataProvider()
        let people = core.makeRepositories().people
        let target = account(.doorScanner)
        _ = try await core.signInStaff(email: target.email, password: DemoSeed.prototypePassword)
        try await people.revokePassword(of: target.id, by: session(.superAdmin))
        do { _ = try await core.signInStaff(email: target.email, password: DemoSeed.prototypePassword); XCTFail("Revoked sign-in") } catch { XCTAssertEqual(error as? RepositoryError, .invalidCredentials) }
        let given = try await people.givePassword(to: target.id, by: session(.superAdmin))
        let signedIn = try await core.signInStaff(email: target.email, password: given.value)
        XCTAssertEqual(signedIn.account.id, target.id)
        do { _ = try await core.signInStaff(email: target.email, password: DemoSeed.prototypePassword); XCTFail("Old password") } catch { XCTAssertEqual(error as? RepositoryError, .invalidCredentials) }
        let next = try await people.givePassword(to: target.id, by: session(.superAdmin))
        XCTAssertNotEqual(next.value, given.value)
        do { _ = try await core.signInStaff(email: target.email, password: given.value); XCTFail("Replaced password") } catch { XCTAssertEqual(error as? RepositoryError, .invalidCredentials) }
        // There is no password readback method on the directory; public entries contain only account and status.
        let directory = try await people.directory(by: session(.superAdmin))
        XCTAssertFalse(String(reflecting: directory).contains(given.value))
    }
    func testEveryRoleButTheAdminCannotManagePeople() async throws {
        let core = DemoDataProvider()
        let people = core.makeRepositories().people
        _ = try await people.directory(by: session(.admin))
        for role in Role.allCases where role != .superAdmin && role != .admin {
            do { _ = try await people.directory(by: session(role)); XCTFail("Allowed \(role)") } catch { guard case RepositoryError.notAllowed = error else { return XCTFail("Wrong error") } }
            do { _ = try await people.givePassword(to: account(.doorScanner).id, by: session(role)); XCTFail("Allowed give") } catch {}
            do { try await people.revokePassword(of: account(.doorScanner).id, by: session(role)); XCTFail("Allowed revoke") } catch {}
        }
    }
    func testAdminPasswordsCannotBeRevoked() async throws {
        let people = DemoDataProvider().makeRepositories().people
        for role in [Role.admin, .superAdmin] {
            do { try await people.revokePassword(of: account(role).id, by: session(.superAdmin)); XCTFail("Protected role") } catch { guard case RepositoryError.notAllowed = error else { return XCTFail("Wrong error") } }
        }
    }
    func testInviteAndAllotKeepHistoryAndUseChosenMessAtSignIn() async throws {
        let core = DemoDataProvider()
        let people = core.makeRepositories().people
        let directory = try await people.directory(by: session(.superAdmin))
        let north = directory.messes[1], south = directory.messes[2]
        let given = try await people.invite(name: "Sample name", contact: "sample@mealloop.example", role: .supervisor, mess: north.id, by: session(.superAdmin))
        let signedIn = try await core.signInStaff(email: given.person.account.email, password: given.value)
        XCTAssertEqual(signedIn.staff?.mess.id, north.id)
        try await people.allot(given.person.id, to: south.id, by: session(.superAdmin))
        let moved = try await core.signInStaff(email: given.person.account.email, password: given.value)
        XCTAssertEqual(moved.staff?.mess.id, south.id)
        let audit = try await people.audit(by: session(.superAdmin))
        XCTAssertEqual(audit.count, 2)
        XCTAssertEqual(audit.map(\.at), [core.clock.now(), core.clock.now()])
        XCTAssertEqual(audit.map(\.actor), [account(.superAdmin).id, account(.superAdmin).id])
    }
    func testOfflineActionsDoNotMutateAndRelaunchResetsRevocation() async throws {
        let core = DemoDataProvider()
        let people = core.makeRepositories().people
        try await people.revokePassword(of: account(.doorScanner).id, by: session(.superAdmin))
        await core.setScenario(.offline)
        do { _ = try await people.givePassword(to: account(.doorScanner).id, by: session(.superAdmin)); XCTFail("Offline") } catch {}
        await core.setScenario(.duringMeal)
        let directory = try await people.directory(by: session(.superAdmin))
        XCTAssertTrue(directory.people.first { $0.id == account(.doorScanner).id }!.passwordRevoked)
        _ = try await DemoDataProvider().signInStaff(email: account(.doorScanner).email, password: DemoSeed.prototypePassword)
    }
}
