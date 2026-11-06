import XCTest
@testable import MealLoop

/// Each role lands in its own area and no other.
final class RoleRoutingTests: XCTestCase {
    func testThereAreElevenRoles() {
        XCTAssertEqual(Role.allCases.count, 11)
    }

    func testEveryRoleRoutesToItsOwnRoot() {
        let expected: [Role: RoleRoot] = [
            .student: .student, .superAdmin: .superAdmin, .admin: .admin, .supervisor: .supervisor,
            .kitchenStaff: .kitchen, .doorScanner: .doorScanner, .passDesk: .passDesk, .vendor: .vendor,
            .guardian: .guardian, .warden: .warden, .gate: .gate,
        ]
        XCTAssertEqual(expected.count, Role.allCases.count)
        for role in Role.allCases {
            XCTAssertEqual(RoleRoot.destination(for: role), expected[role], "\(role)")
        }
    }

    func testNoTwoRolesShareARoot() {
        let roots = Set(Role.allCases.map(RoleRoot.destination(for:)))
        XCTAssertEqual(roots.count, Role.allCases.count)
        XCTAssertEqual(roots, Set(RoleRoot.allCases))
    }

    func testOnlyMessStaffGetTheStaffTabs() {
        for role in Role.allCases {
            XCTAssertEqual(RoleRoot.destination(for: role).usesStaffTabs, role.isMessStaff, "\(role)")
        }
    }

    func testStaffRootsNeverHavePlaceholderTabs() {
        for root in RoleRoot.allCases where root.usesStaffTabs {
            XCTAssertTrue(root.placeholderTabs.isEmpty, "\(root)")
        }
    }

    func testPlaceholderTabsRespectTheFourTabLimit() {
        for root in RoleRoot.allCases {
            XCTAssertLessThanOrEqual(root.placeholderTabs.count, 4, "\(root)")
        }
    }

    func testRouterResetClearsPositionForTheNextAccount() {
        let router = AppRouter()
        router.entryPath = [.staffSignIn]
        router.selectedStaffTab = .me
        router.staffHomePath = [.notImplemented(title: "Past meals")]
        router.reset()
        XCTAssertTrue(router.entryPath.isEmpty)
        XCTAssertEqual(router.selectedStaffTab, .home)
        XCTAssertTrue(router.staffHomePath.isEmpty)
    }
}
