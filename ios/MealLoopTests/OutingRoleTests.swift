#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// Role guards on the Guardian, Warden and Gate roots, and the three roles' models on the seeded outing source.
@MainActor
final class OutingRoleTests: XCTestCase {
    private func session(_ role: Role) -> Session {
        Session(account: DemoSeed.accounts.first { $0.role == role }!, staff: nil)
    }

    private func repository(at moment: Date = OutingSeed.guardianMoment,
                            script: [SimulatedCaptureOutcome] = []) -> (InMemoryOutingCaseRepository, DemoClock) {
        let clock = DemoClock(moment)
        return (InMemoryOutingCaseRepository(clock: clock, simulation: ScriptedCaptureSimulation(script),
                                             makeDigits: { String(repeating: "4", count: $0) }), clock)
    }

    // MARK: Role guards

    func testOnlyEachRoleReachesItsOutingRoot() {
        for role in Role.allCases {
            XCTAssertEqual(WardenRootView.allows(session(role)), role == .warden, "Warden root for \(role)")
            XCTAssertEqual(GateRootView.allows(session(role)), role == .gate, "Gate root for \(role)")
            XCTAssertEqual(GuardianRootView.allows(session(role)), role == .guardian, "Guardian root for \(role)")
        }
    }

    func testRoleRoutingStillSendsEachOutingRoleToItsOwnRoot() {
        XCTAssertEqual(RoleRoot.destination(for: .warden), .warden)
        XCTAssertEqual(RoleRoot.destination(for: .gate), .gate)
        XCTAssertEqual(RoleRoot.destination(for: .guardian), .guardian)
    }

    func testOutingSourceIsSeededInReviewAndRemoteForApi() {
        let demo = DemoDataProvider(scenario: .storyStart, clock: DemoClock(DemoSeed.storyStartNow))
        let review = AppEnvironment(kind: .review, repositories: demo.makeRepositories(), clock: SystemClock(),
                                    demoControls: nil)
        XCTAssertTrue(OutingCaseRepositories.source(for: review) is InMemoryOutingCaseRepository)
        XCTAssertTrue(OutingCaseRepositories.source(for: review) as AnyObject === OutingCaseRepositories.source(for: review) as AnyObject,
                      "One source per environment, so every role sees the same requests")
        let api = AppEnvironment.makeAPI()
        XCTAssertTrue(OutingCaseRepositories.source(for: api) is RemoteOutingCaseRepository)
    }

    // MARK: Guardian model

    func testGuardianAcceptGoesThroughConsentAndCapture() async {
        let (source, _) = repository()
        let model = GuardianModel(account: OutingSeed.guardianAccount, repository: source)
        await model.load()
        XCTAssertEqual(model.step, .choose)
        await model.accept()
        XCTAssertEqual(model.step, .consent)
        await model.agreeAndContinue()
        XCTAssertEqual(model.step, .record(.ready))
        XCTAssertEqual(model.challenge?.code, "444")
        await model.finishRecording(seconds: 2)
        XCTAssertEqual(model.step, .record(.tooShort(seconds: 2)))
        await model.finishRecording(seconds: 9)
        XCTAssertEqual(model.step, .answered(justSent: true))
        XCTAssertEqual(model.request?.evidence?.method, .liveVideoAutoChecked)
    }

    func testGuardianRejectIsOneTapWithoutVideo() async {
        let (source, _) = repository()
        let model = GuardianModel(account: OutingSeed.guardianAccount, repository: source)
        await model.load()
        await model.reject(reason: nil)
        XCTAssertEqual(model.step, .answered(justSent: true))
        XCTAssertEqual(model.request?.stage, .guardianRejected)
        XCTAssertNil(model.request?.evidence)
        XCTAssertNil(model.challenge)
    }

    func testGuardianPageShowsExpiredAfterTheReplyTime() async {
        let (source, _) = repository(at: OutingSeed.at(8, 17, 0, 5))
        let model = GuardianModel(account: OutingSeed.guardianAccount, repository: source)
        await model.load()
        XCTAssertEqual(model.step, .expired)
        await model.accept()
        XCTAssertEqual(model.step, .expired, "No capture after the reply time")
        await model.agreeAndContinue()
        XCTAssertNotNil(model.actionError, "The repository refuses a capture after the reply time too")
        XCTAssertNil(model.challenge)
    }

    // MARK: Warden model

    func testWardenQueueIsClosestDeadlineFirstAndCallPathNeedsANote() async {
        let (source, _) = repository(at: OutingSeed.wardenMoment)
        let model = WardenModel(account: OutingSeed.wardenAccount, repository: source)
        await model.load()
        XCTAssertEqual(model.queue.map(\.id), [OutingSeed.meeraRequest.id, OutingSeed.arjunRequest.id])
        XCTAssertEqual(model.escalated.map(\.id), [OutingSeed.aaravRequest.id, OutingSeed.devRequest.id,
                                                   OutingSeed.meeraRequest.id, OutingSeed.kiranRequest.id])
        await model.focus(on: OutingSeed.kiranRequest.id)
        XCTAssertTrue(model.needsCallNote)
        await model.approve(note: "")
        XCTAssertNotNil(model.actionError)
        XCTAssertNil(model.result)
        await model.approve(note: "Spoke to Kiran's father.")
        XCTAssertEqual(model.result?.kind, .approved)
        XCTAssertEqual(model.result?.outing.pass?.code, "4QZ8")
    }

    // MARK: Gate model

    func testGateRoutesAnUnsignedCodeToNotValidAndRecordsNothing() async throws {
        let (source, _) = repository(at: OutingSeed.gateMoment)
        let model = GateModel(repository: source)
        await model.load()
        let before = model.overview?.outNow
        let route = await model.run(.code("7F3K"))
        XCTAssertEqual(route, .outcome(.refused(.notValid)))
        XCTAssertEqual(model.overview?.outNow, before)
        XCTAssertEqual(model.overview?.typedCodesToday, 1)
    }
}
#endif
