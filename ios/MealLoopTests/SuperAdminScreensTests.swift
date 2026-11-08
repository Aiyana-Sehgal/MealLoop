#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The Super Admin pages' state: the list, a simulated reset and deactivation, and no powers for other roles.
@MainActor
final class SuperAdminScreensTests: XCTestCase {
    private func make(_ role: Role = .superAdmin) -> SuperAdminViewModel {
        SuperAdminViewModel(role: role, repository: DemoDataProvider(scenario: .storyStart).makeRepositories().superAdmin)
    }

    private var vendor: AccountID { DemoSeed.accounts.first { $0.role == .vendor }!.id }

    func testTheSuperAdminSignsInOnStaffSignIn() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        let session = try await demo.signInStaff(email: "superadmin@mealloop.example", password: DemoSeed.prototypePassword)
        XCTAssertEqual(session.account.role, .superAdmin)
        XCTAssertNil(session.staff, "No mess staff powers")
    }

    func testTheListShowsEverySeededAccount() async {
        let model = make()
        await model.load()
        XCTAssertEqual(model.accounts.value?.count, DemoSeed.accounts.count)
    }

    func testAFoodHeadGetsNoAccountsList() async {
        let model = make(.admin)
        await model.load()
        guard case .failed = model.accounts else { return XCTFail("Refused for the Food Head") }
    }

    func testResetAndDeactivateAreRecordedOnlyAfterTheRepositoryRecordsThem() async {
        let model = make()
        await model.load()
        await model.startPasswordReset(vendor)
        XCTAssertNotNil(model.account(vendor)?.resetStartedAt)
        XCTAssertEqual(model.account(vendor)?.isActive, true)
        await model.deactivate(vendor)
        XCTAssertEqual(model.account(vendor)?.isActive, false)
        XCTAssertEqual(model.send, .idle)
    }
}
#endif
