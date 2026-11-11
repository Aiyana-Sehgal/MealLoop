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

    func testStudentAndAdminTabsMatchTheirDesigns() {
        XCTAssertEqual(RoleRoot.student.placeholderTabs, ["Home", "Meals", "Community", "You"])
        XCTAssertEqual(RoleRoot.admin.placeholderTabs, ["Today", "Students", "Results", "More"])
    }

    func testOnlyStudentAndAdminHaveSearch() {
        XCTAssertEqual(RoleRoot.allCases.filter(\.hasSearch), [.student, .admin])
    }

    func testTheWardenTabsAreWordsOnly() {
        XCTAssertEqual(RoleRoot.warden.placeholderTabs, ["Queue", "Out now", "Escalated", "History"])
        XCTAssertEqual(RoleRoot.allCases.filter { !$0.showsTabIcons }, [.warden])
    }

    func testGuardianHasNoTabs() {
        XCTAssertTrue(RoleRoot.guardian.placeholderTabs.isEmpty)
    }

    func testTheSearchValueIsNeverATabTitle() {
        for root in RoleRoot.allCases {
            XCTAssertFalse(root.placeholderTabs.contains(RoleRoot.searchTab), "\(root)")
        }
    }

    func testRouterResetClearsPositionForTheNextAccount() {
        let router = AppRouter()
        router.entryPath = [.chooseRole, .rolePassword(.kitchenStaff)]
        router.selectedStaffTab = .me
        router.staffHomePath = [.notImplemented(title: "Past meals")]
        router.reset()
        XCTAssertTrue(router.entryPath.isEmpty)
        XCTAssertEqual(router.selectedStaffTab, .home)
        XCTAssertTrue(router.staffHomePath.isEmpty)
    }
}
