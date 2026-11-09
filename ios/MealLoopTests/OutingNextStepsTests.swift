import XCTest
@testable import MealLoop

/// "What happens next": where the request is, and You are out reached only after the warden approves.
final class OutingNextStepsTests: XCTestCase {
    func testANewRequestHasTheGuardianNext() {
        XCTAssertEqual(OutingNextSteps.states(for: nil), [.current, .upcoming, .upcoming])
    }

    func testWaitingForTheGuardianOrAChange() {
        for stage in [OutingStage.awaitingGuardian, .guardianCallRequested, .guardianAskedChange] {
            XCTAssertEqual(OutingNextSteps.states(for: stage), [.current, .upcoming, .upcoming], "\(stage)")
        }
    }

    func testAfterTheGuardianTheWardenIsCurrent() {
        XCTAssertEqual(OutingNextSteps.states(for: .awaitingWarden), [.done, .current, .upcoming])
        XCTAssertEqual(OutingNextSteps.states(for: .wardenAskedChange), [.done, .current, .upcoming])
    }

    func testYouAreOutIsNeverReachedBeforeTheWardenApproves() {
        let beforeApproval: [OutingStage] = [.awaitingGuardian, .guardianCallRequested, .guardianAskedChange,
                                             .guardianRejected, .awaitingWarden, .wardenAskedChange, .wardenRejected, .withdrawn]
        for stage in beforeApproval {
            XCTAssertEqual(OutingNextSteps.states(for: stage)[2], .upcoming, "\(stage)")
        }
        XCTAssertEqual(OutingNextSteps.states(for: .passSigned), [.done, .done, .current])
        XCTAssertEqual(OutingNextSteps.states(for: .returned), [.done, .done, .done])
    }

    func testARefusalStopsAtThatStep() {
        XCTAssertEqual(OutingNextSteps.states(for: .guardianRejected), [.stopped, .upcoming, .upcoming])
        XCTAssertEqual(OutingNextSteps.states(for: .wardenRejected), [.done, .stopped, .upcoming])
    }
}
