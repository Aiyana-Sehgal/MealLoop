#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// Sign-in against the seeded accounts (SIMULATED) and the form states.
@MainActor
final class AccountSignInTests: XCTestCase {
    private let password = DemoSeed.prototypePassword

    private func email(_ role: Role) throws -> String {
        try XCTUnwrap(DemoSeed.accounts.first { $0.role == role }).email
    }

    private func assertInvalid(email: String, password: String, line: UInt = #line) async {
        do {
            _ = try await DemoDataProvider().signInStaff(email: email, password: password)
            XCTFail("Expected invalid credentials", line: line)
        } catch {
            XCTAssertEqual(error as? RepositoryError, .invalidCredentials, line: line)
        }
    }

    func testOneSeededAccountPerRole() {
        XCTAssertEqual(DemoSeed.accounts.map(\.role).sorted { $0.rawValue < $1.rawValue },
                       Role.allCases.sorted { $0.rawValue < $1.rawValue })
        XCTAssertEqual(Set(DemoSeed.accounts.map(\.email)).count, DemoSeed.accounts.count)
    }

    func testEveryAccountExceptTheStudentSignsInByEmail() async throws {
        for account in DemoSeed.accounts where account.role != .student {
            let session = try await DemoDataProvider().signInStaff(email: account.email, password: password)
            XCTAssertEqual(session.account, account)
            XCTAssertEqual(session.staff != nil, account.role.isMessStaff, "\(account.role)")
            XCTAssertEqual(session.staff?.role, account.role.isMessStaff ? account.role : nil)
        }
    }

    func testEmailIgnoresCaseAndSurroundingSpace() async throws {
        let email = try email(.warden)
        let session = try await DemoDataProvider().signInStaff(email: "  \(email.uppercased()) ", password: password)
        XCTAssertEqual(session.account.role, .warden)
    }

    func testWrongPasswordIsRejected() async throws {
        await assertInvalid(email: try email(.supervisor), password: password + "x")
    }

    func testUnknownEmailIsRejectedWithTheSameError() async {
        await assertInvalid(email: "nobody@mealloop.example", password: password)
    }

    func testAStudentCannotUseStaffSignIn() async throws {
        await assertInvalid(email: try email(.student), password: password)
    }

    func testSRMReturnsTheStudent() async throws {
        let session = try await DemoDataProvider().signInWithSRM()
        XCTAssertEqual(session.account.role, .student)
        XCTAssertNil(session.staff)
    }

    func testOfflineSignInFailsAndSignsNobodyIn() async throws {
        let demo = DemoDataProvider(scenario: .offline)
        let model = StaffSignInViewModel(auth: demo)
        model.email = try email(.supervisor)
        model.password = password
        let session = await model.submit()
        XCTAssertNil(session)
        XCTAssertNotNil(model.errorMessage)
    }

    func testFormIsDisabledUntilBothFieldsAreFilled() {
        let model = StaffSignInViewModel(auth: DemoDataProvider())
        XCTAssertFalse(model.canSubmit)
        model.email = "a@mealloop.example"
        XCTAssertFalse(model.canSubmit)
        model.email = "   "
        model.password = "x"
        XCTAssertFalse(model.canSubmit)
        model.email = "a@mealloop.example"
        XCTAssertTrue(model.canSubmit)
    }

    func testWrongCredentialsShowTheInlineMessage() async {
        let model = StaffSignInViewModel(auth: DemoDataProvider())
        model.email = "nobody@mealloop.example"
        model.password = "wrong"
        let session = await model.submit()
        XCTAssertNil(session)
        XCTAssertEqual(model.errorMessage, "The email or password is incorrect.")
        XCTAssertFalse(model.isSubmitting)
    }

    func testSRMStepsEndInASession() async {
        let model = SRMSignInViewModel(auth: DemoDataProvider(), pause: {})
        let session = await model.start()
        XCTAssertEqual(session?.account.role, .student)
    }

    func testSRMFailureIsShownAndNeverSignsIn() async {
        let model = SRMSignInViewModel(auth: RemoteAPI(baseURL: nil), pause: {})
        let session = await model.start()
        XCTAssertNil(session)
        guard case .failed = model.phase else { return XCTFail("Expected failed, got \(model.phase)") }
    }

    func testRemoteSignInNeverFakesSuccess() async {
        do {
            _ = try await RemoteAPI(baseURL: nil).signInStaff(email: "a", password: "b")
            XCTFail("RemoteAPI must not sign anyone in yet")
        } catch {
            guard case .notImplemented? = error as? RepositoryError else { return XCTFail("\(error)") }
        }
    }
}
#endif
