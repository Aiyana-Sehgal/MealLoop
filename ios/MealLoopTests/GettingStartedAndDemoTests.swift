#if DEMO_DATA || REVIEW_DATA
import SwiftUI
import XCTest
@testable import MealLoop

/// A clock the tests own.
private final class FixedClock: StoryClock, @unchecked Sendable {
    private var current: Date
    init(_ date: Date) { current = date }
    func now() -> Date { current }
    func set(_ date: Date) { current = date }
}

/// Getting started (both sign-in paths), the Demo sheet's controls and the shared clock.
final class GettingStartedAndDemoTests: XCTestCase {
    private let lunch = DemoSeed.lunch
    private let aarav = DemoSeed.sampleStudent.id

    private func clean() -> (DemoDataProvider, FixedClock) {
        let clock = FixedClock(DemoSeed.storyStartNow)
        return (DemoDataProvider(scenario: .storyStart, clock: clock), clock)
    }

    // MARK: Sign in with SRM

    func testWelcomeSRMSignsInTheStudent() async throws {
        let (demo, _) = clean()
        let session = try await demo.signInWithSRM()
        XCTAssertEqual(session.account.role, .student)
        XCTAssertNil(session.staff)
    }

    /// Couldn't sign in (135:15825) is a retry branch: it fails once, signs nobody in, and Try again succeeds.
    @MainActor
    func testAFailedSRMSignInFailsOnceThenTryAgainSucceeds() async throws {
        let (demo, _) = clean()
        await demo.failNextSRMSignIn()
        let model = SRMSignInViewModel(auth: demo, pause: {})
        let first = await model.start()
        XCTAssertNil(first)
        XCTAssertEqual(model.phase, .failed(DemoSeed.srmNoAnswer))
        let retry = await model.start()
        XCTAssertEqual(retry?.account.role, .student)
        XCTAssertEqual(model.phase, .gettingDetails)
    }

    /// Choose your role → What you do → the role's shared password signs in that role's account at its mess.
    func testTheRightRolePasswordSignsInThatRolesAccount() async throws {
        let (demo, _) = clean()
        let result = try await demo.verifyRolePassword(DemoSeed.simulatedRolePassword, for: .kitchenStaff)
        guard case .granted(let session) = result else { return XCTFail("Expected granted, got \(result)") }
        XCTAssertEqual(session.account.role, .kitchenStaff)
        XCTAssertEqual(session.staff?.role, .kitchenStaff)
        XCTAssertEqual(session.staff?.mess, DemoSeed.mess)
    }

    func testOnlyMessStaffRolesHaveARolePassword() async {
        let (demo, _) = clean()
        do {
            _ = try await demo.verifyRolePassword(DemoSeed.simulatedRolePassword, for: .admin)
            XCTFail("Admin has no shared role password")
        } catch RepositoryError.notAllowed {
            // Expected.
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    // MARK: Shared clock

    func testStartingAndClosingTheMealDoesNotMoveTheClock() async throws {
        let (demo, clock) = clean()
        _ = try await demo.startMeal(lunch.id, by: .supervisor)
        XCTAssertEqual(clock.now(), DemoSeed.storyStartNow)
        _ = try await demo.closeMeal(lunch.id, by: .supervisor)
        XCTAssertEqual(clock.now(), DemoSeed.storyStartNow)
    }

    func testApprovingTheHeadcountDoesNotMoveTheClock() async throws {
        let (demo, clock) = clean()
        _ = try await demo.approveHeadcount(DemoSeed.forecastDiners, reason: nil, for: lunch.id, by: .admin)
        XCTAssertEqual(clock.now(), DemoSeed.storyStartNow)
    }

    func testTheRunningClockStartsAtTheSeedAndMovesOn() async throws {
        let clock = RunningDemoClock(startingAt: DemoSeed.storyStartNow)
        let first = clock.now()
        XCTAssertGreaterThanOrEqual(first, DemoSeed.storyStartNow)
        XCTAssertLessThan(first, DemoSeed.storyStartNow.addingTimeInterval(5))
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertGreaterThan(clock.now(), first)
    }

    // MARK: Switch role (keeps data)

    /// The Student answers, the Demo sheet switches to the Food Head: the answer and the time are both still there.
    func testSwitchingRoleKeepsTheDataAndTheTime() async throws {
        let (demo, clock) = clean()
        _ = try await demo.setIntention(.skipping, of: aarav, for: lunch.id)
        let before = clock.now()

        let foodHead = await demo.demoSession(for: .admin)
        XCTAssertEqual(foodHead?.account.role, .admin)
        let student = await demo.demoSession(for: .student)
        XCTAssertEqual(student?.student?.student.id, aarav)

        XCTAssertEqual(clock.now(), before)
        let answer = try await demo.response(of: aarav, for: lunch.id)
        guard case .answered(.skipping, _) = answer else { return XCTFail("The answer was lost: \(answer)") }
    }

    func testEveryRoleOnTheSheetHasASeededAccount() async {
        let (demo, _) = clean()
        for role in [Role.student, .admin, .superAdmin, .supervisor, .kitchenStaff, .doorScanner, .passDesk, .vendor,
                     .guardian, .warden, .gate] {
            let session = await demo.demoSession(for: role)
            XCTAssertEqual(session?.account.role, role)
        }
    }
}
#endif

#if DEMO_DATA || REVIEW_DATA
/// Choose your role lists Food Head and Admin after the four mess staff roles; they sign in with their own account.
final class ChooseRoleAccountsTests: XCTestCase {
    func testFoodHeadAndAdminAreOfferedWithTheirOwnSignIn() async throws {
        XCTAssertEqual(StaffEntryCopy.accountRoles, [.admin, .superAdmin])
        XCTAssertEqual(StaffEntryCopy.roleTitle(.admin), "Food Head")
        XCTAssertEqual(StaffEntryCopy.roleTitle(.superAdmin), "Admin")
        XCTAssertFalse(StaffEntryCopy.accountRoles.contains { $0.isMessStaff }, "No shared role password for them")
        let demo = DemoDataProvider(scenario: .storyStart)
        for role in StaffEntryCopy.accountRoles {
            let email = try XCTUnwrap(DemoSeed.accounts.first { $0.role == role }).email
            let session = try await demo.signInStaff(email: email, password: DemoSeed.prototypePassword)
            XCTAssertEqual(session.account.role, role)
        }
    }

    func testStudentTextScalesAndIsCappedForTheDesignedRows() {
        XCTAssertEqual(StudentType.largestSize, .accessibility1)
        XCTAssertEqual(StudentType.body, Font.custom("Inter-Regular", size: 17, relativeTo: .body))
    }
}
#endif
