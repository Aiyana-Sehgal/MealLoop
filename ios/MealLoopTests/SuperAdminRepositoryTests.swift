#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The Super Admin accounts list: simulated actions, no password anywhere, no other role's powers.
final class SuperAdminRepositoryTests: XCTestCase {
    private func make(_ scenario: DemoScenario = .storyStart) -> any SuperAdminRepository {
        DemoDataProvider(scenario: scenario).makeRepositories().superAdmin
    }

    private var foodHead: AccountID { DemoSeed.accounts.first { $0.role == .admin }!.id }

    func testEverySeededAccountIsListedAndActive() async throws {
        let accounts = try await make().accounts(by: .superAdmin)
        XCTAssertEqual(accounts.count, DemoSeed.accounts.count)
        XCTAssertTrue(accounts.allSatisfy(\.isActive))
    }

    func testNoOtherRoleCanReadOrChangeAccounts() async {
        for role in Role.allCases where role != .superAdmin {
            do {
                _ = try await make().accounts(by: role)
                XCTFail("\(role) must be refused")
            } catch RepositoryError.notAllowed {} catch { XCTFail("\(error)") }
        }
        do {
            _ = try await make().deactivate(foodHead, by: .admin)
            XCTFail("The Food Head has no Super Admin powers")
        } catch RepositoryError.notAllowed {} catch { XCTFail("\(error)") }
    }

    func testAManagedAccountCarriesNoPassword() throws {
        let account = try XCTUnwrap(DemoSeed.accounts.first)
        let managed = ManagedAccount(account: account, isActive: true, deactivatedAt: nil, resetStartedAt: nil)
        let json = String(decoding: try JSONEncoder().encode(managed), as: UTF8.self).lowercased()
        XCTAssertFalse(json.contains("password"))
        XCTAssertFalse(json.contains(DemoSeed.prototypePassword.lowercased()))
        let labels = Mirror(reflecting: managed).children.compactMap(\.label) + Mirror(reflecting: account).children.compactMap(\.label)
        XCTAssertFalse(labels.contains { $0.lowercased().contains("password") || $0.lowercased().contains("token") })
    }

    func testDeactivatingIsRecordedOnceAndNeverForASuperAdmin() async throws {
        let repo = make()
        let first = try await repo.deactivate(foodHead, by: .superAdmin)
        XCTAssertFalse(first.isActive)
        let again = try await repo.deactivate(foodHead, by: .superAdmin)
        XCTAssertEqual(first.deactivatedAt, again.deactivatedAt)
        let superAdmin = DemoSeed.accounts.first { $0.role == .superAdmin }!.id
        do {
            _ = try await repo.deactivate(superAdmin, by: .superAdmin)
            XCTFail("Refused")
        } catch RepositoryError.notAllowed {}
    }

    func testAResetIsRecordedAndReturnsNoPassword() async throws {
        let repo = make()
        let reset = try await repo.startPasswordReset(foodHead, by: .superAdmin)
        XCTAssertNotNil(reset.resetStartedAt)
        XCTAssertTrue(reset.isActive, "A reset never deactivates the account")
    }

    func testOfflineRecordsNothing() async {
        do {
            _ = try await make(.offline).deactivate(foodHead, by: .superAdmin)
            XCTFail("Offline")
        } catch RepositoryError.offline {} catch { XCTFail("\(error)") }
    }
}
#endif
