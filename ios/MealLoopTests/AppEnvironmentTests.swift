import XCTest
@testable import MealLoop

/// Demo data exists only in Debug, and the real API never fakes success.
final class AppEnvironmentTests: XCTestCase {
    func testDebugBuildUsesTheDemoProviderAndShowsIt() {
        #if DEMO_DATA
        let environment = AppEnvironment.make()
        XCTAssertEqual(environment.kind, .demo)
        XCTAssertNotNil(environment.demoControls)
        #elseif REVIEW_DATA
        let environment = AppEnvironment.make()
        XCTAssertEqual(environment.kind, .review)
        // The Review build carries the Demo sheet (Getting started, Switch role); it moves no time and replaces no data.
        XCTAssertNotNil(environment.demoControls)
        #else
        XCTFail("Unit tests are expected to run in Debug or Review, where seeded data is compiled in.")
        #endif
    }

    func testDemoFlagImpliesDebug() {
        // AppEnvironment.swift has a compile-time #error for DEMO_DATA without DEBUG; this states the same rule at run time.
        #if DEMO_DATA
        #if DEBUG
        XCTAssertTrue(true)
        #else
        XCTFail("DEMO_DATA must never be set outside Debug")
        #endif
        #endif
    }

    func testAPIEnvironmentHasNoDemoControls() {
        let environment = AppEnvironment.makeAPI()
        XCTAssertEqual(environment.kind, .api)
        XCTAssertNil(environment.demoControls)
    }

    func testRemoteAPIThrowsNotImplementedInsteadOfFakingSuccess() async {
        let api = RemoteAPI(baseURL: nil)
        do {
            _ = try await api.recordEntry(EntryRequest(mealID: MealID("m"),
                                                       student: StudentRef(id: StudentID("s"), maskedID: "••0000"),
                                                       method: .qrScan, idempotencyKey: IdempotencyKey("k")))
            XCTFail("RemoteAPI must not return a result yet")
        } catch let error as RepositoryError {
            guard case .notImplemented = error else { return XCTFail("Expected notImplemented, got \(error)") }
        } catch {
            XCTFail("Unexpected error \(error)")
        }
        do {
            _ = try await api.liveCount(for: MealID("m"))
            XCTFail("RemoteAPI must not return a count yet")
        } catch let error as RepositoryError {
            guard case .notImplemented = error else { return XCTFail("Expected notImplemented, got \(error)") }
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testNotImplementedFailureIsLabelledAsSuch() {
        let failure = LoadFailure(RepositoryError.notImplemented(feature: "Remote · live entries"))
        XCTAssertTrue(failure.isNotImplemented)
        XCTAssertEqual(failure.message, "Remote · live entries isn't available yet")
    }

    func testRemoteSignInFailureSaysItIsNotAvailable() async {
        do {
            _ = try await RemoteAPI(baseURL: nil).signInStaff(email: "a", password: "b")
            XCTFail("RemoteAPI must never show a sign-in as success")
        } catch {
            XCTAssertEqual(LoadFailure(error).message, "Remote sign in isn't available yet")
        }
    }
}
