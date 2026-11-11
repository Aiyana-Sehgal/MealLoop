#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The outing journey on the prototype backend (guardian_video_spec.md): student request → guardian → warden →
/// signed pass → gate exit → gate return. No step skips the one before it and no timeout approves anything.
final class OutingCaseRepositoryTests: XCTestCase {
    private let guardian = OutingSeed.guardianAccount
    private let warden = OutingSeed.wardenAccount
    private let aarav = OutingSeed.aaravRequest.id

    private func make(_ script: [SimulatedCaptureOutcome] = [], at moment: Date = OutingSeed.guardianMoment)
        -> (InMemoryOutingCaseRepository, DemoClock) {
        let clock = DemoClock(moment)
        let repository = InMemoryOutingCaseRepository(clock: clock, simulation: ScriptedCaptureSimulation(script),
                                                      makeDigits: { String(repeating: "7", count: $0) },
                                                      makePassCode: { "TEST" })
        return (repository, clock)
    }

    private func acceptByVideo(_ repository: InMemoryOutingCaseRepository) async throws -> OutingCase {
        try await repository.recordConsent(guardian, by: .guardian)
        let challenge = try await repository.startCapture(aarav, guardian: guardian, by: .guardian)
        guard case .sent(let sent) = try await repository.submitVideo(challenge, seconds: 9, guardian: guardian,
                                                                      by: .guardian) else {
            XCTFail("Expected the video to be sent")
            throw CancellationError()
        }
        return sent
    }

    private func assertRefused(_ line: UInt = #line, _ work: () async throws -> Void) async {
        do {
            try await work()
            XCTFail("Expected a refusal", line: line)
        } catch RepositoryError.notAllowed {
        } catch RepositoryError.validationFailed {
        } catch {
            XCTFail("Unexpected error \(error)", line: line)
        }
    }

    // MARK: Sequence

    func testFullJourneyRunsInOrder() async throws {
        let (repository, clock) = make()
        let sent = try await acceptByVideo(repository)
        XCTAssertEqual(sent.stage, .awaitingWarden)
        XCTAssertEqual(sent.evidence?.method, .liveVideoAutoChecked)
        XCTAssertEqual(sent.evidence?.passedChecks, EvidenceCheck.allCases)
        XCTAssertEqual(sent.evidence?.transcript, "I accept Aarav's outing, code 7 7 7")

        clock.set(OutingSeed.wardenMoment)  // Opening a role no longer moves the clock; the story's time does.
        try await repository.begin(as: .warden)
        let queue = try await repository.wardenQueue(for: warden)
        XCTAssertTrue(queue.contains { $0.id == aarav })
        let approved = try await repository.approve(aarav, warden: warden, by: .warden)
        XCTAssertEqual(approved.stage, .passSigned)
        XCTAssertEqual(approved.pass?.code, "7F3K")

        clock.set(OutingSeed.gateMoment)
        try await repository.begin(as: .gate)
        guard case .exitReady = try await repository.checkPassCode("7f3k", by: .gate) else {
            return XCTFail("Expected the pass to be ready for exit")
        }
        let exit = try await repository.recordExit(aarav, by: .gate)
        XCTAssertEqual(exit.outing.stage, .out)
        XCTAssertEqual(exit.outing.exitAt, OutingSeed.gateMoment)
        guard case .returnReady = try await repository.checkPassCode("7F3K", by: .gate) else {
            return XCTFail("Expected the pass to be ready for return")
        }
        clock.set(OutingSeed.at(8, 17, 19, 41))
        let back = try await repository.recordReturn(aarav, by: .gate)
        XCTAssertEqual(back.outing.stage, .returned)
        XCTAssertFalse(back.outing.isLate(at: clock.now()))
        guard case .alreadyUsed = try await repository.checkPassCode("7F3K", by: .gate) else {
            return XCTFail("A used pass must not let the student out again")
        }
    }

    func testWardenCannotDecideBeforeTheGuardian() async throws {
        let (repository, _) = make()
        try await repository.begin(as: .warden)
        await assertRefused { _ = try await repository.approve(self.aarav, warden: self.warden, by: .warden) }
        await assertRefused { _ = try await repository.reject(self.aarav, reason: "Exam soon", warden: self.warden, by: .warden) }
        await assertRefused {
            _ = try await repository.askForChange(self.aarav, fields: ["Time"], note: nil, warden: self.warden, by: .warden)
        }
        let queue = try await repository.wardenQueue(for: warden)
        XCTAssertFalse(queue.contains { $0.id == aarav })
    }

    func testGateCannotRecordExitWithoutASignedPass() async throws {
        let (repository, clock) = make()
        _ = try await acceptByVideo(repository)
        clock.set(OutingSeed.gateMoment)
        await assertRefused { _ = try await repository.recordExit(self.aarav, by: .gate) }
        guard case .notValid = try await repository.checkPassCode("7F3K", by: .gate) else {
            return XCTFail("An unsigned pass is not valid")
        }
        await assertRefused { _ = try await repository.recordReturn(self.aarav, by: .gate) }
    }

    func testGateRefusesOutsideTheWindow() async throws {
        let (repository, clock) = make()
        _ = try await acceptByVideo(repository)
        try await repository.begin(as: .warden)
        _ = try await repository.approve(aarav, warden: warden, by: .warden)
        clock.set(OutingSeed.at(8, 17, 13, 40))
        guard case .tooEarly = try await repository.checkPassCode("7F3K", by: .gate) else { return XCTFail("Too early") }
        await assertRefused { _ = try await repository.recordExit(self.aarav, by: .gate) }
        clock.set(OutingSeed.at(8, 17, 20, 30))
        guard case .tooLate = try await repository.checkPassCode("7F3K", by: .gate) else { return XCTFail("Too late") }
    }

    // MARK: Guardian rules

    func testRejectNeedsNoVideo() async throws {
        let (repository, _) = make()
        let rejected = try await repository.rejectAsGuardian(aarav, reason: "Exam soon", guardian: guardian, by: .guardian)
        XCTAssertEqual(rejected.stage, .guardianRejected)
        XCTAssertNil(rejected.evidence)
        XCTAssertEqual(rejected.guardianAnswer?.answer, .rejected(reason: "Exam soon"))
        // A rejected request never reaches the warden.
        try await repository.begin(as: .warden)
        await assertRefused { _ = try await repository.approve(self.aarav, warden: self.warden, by: .warden) }
    }

    func testAcceptRequiresConsentAndTheCaptureStep() async throws {
        let (repository, _) = make()
        await assertRefused { _ = try await repository.startCapture(self.aarav, guardian: self.guardian, by: .guardian) }
        try await repository.recordConsent(guardian, by: .guardian)
        let challenge = try await repository.startCapture(aarav, guardian: guardian, by: .guardian)
        XCTAssertEqual(challenge.code.count, 3)
        XCTAssertEqual(challenge.phrase, "I accept Aarav's outing.")
        // Under 4 seconds is too short and uses no try.
        let short = try await repository.submitVideo(challenge, seconds: 3, guardian: guardian, by: .guardian)
        XCTAssertEqual(short, .tooShort)
        await assertRefused {
            _ = try await repository.submitVideo(challenge, seconds: 11, guardian: self.guardian, by: .guardian)
        }
        let stillWaiting = try await repository.guardianRequest(for: guardian)
        XCTAssertEqual(stillWaiting?.stage, .awaitingGuardian)
    }

    func testEveryTryGetsAFreshCodeAndAnOldCodeFails() async throws {
        final class Codes: @unchecked Sendable {
            var values = ["472", "815", "309"]
            func next() -> String { values.isEmpty ? "000" : values.removeFirst() }
        }
        let codes = Codes()
        let repository = InMemoryOutingCaseRepository(
            clock: DemoClock(OutingSeed.guardianMoment),
            simulation: ScriptedCaptureSimulation([.notMatched(heard: "I accept Aarav's outing …", missing: "code 4 7 2")]),
            makeDigits: { _ in codes.next() })
        try await repository.recordConsent(guardian, by: .guardian)
        let first = try await repository.startCapture(aarav, guardian: guardian, by: .guardian)
        let result = try await repository.submitVideo(first, seconds: 9, guardian: guardian, by: .guardian)
        XCTAssertEqual(result, .notMatched(heard: "I accept Aarav's outing …", missing: "code 4 7 2", nextAttempt: 2))
        let second = try await repository.startCapture(aarav, guardian: guardian, by: .guardian)
        XCTAssertEqual(second.attempt, 2)
        XCTAssertNotEqual(first.code, second.code)
        await assertRefused { _ = try await repository.submitVideo(first, seconds: 9, guardian: self.guardian, by: .guardian) }
    }

    func testThreeFailedChecksSendTheVideoAsPleaseWatch() async throws {
        let miss = SimulatedCaptureOutcome.notMatched(heard: "I accept Aarav's outing …", missing: "code")
        let (repository, _) = make([miss, miss, miss])
        try await repository.recordConsent(guardian, by: .guardian)
        await assertRefused { _ = try await repository.sendVideoForReview(self.aarav, guardian: self.guardian, by: .guardian) }
        var last: VideoSubmissionResult?
        for _ in 1...3 {
            let challenge = try await repository.startCapture(aarav, guardian: guardian, by: .guardian)
            last = try await repository.submitVideo(challenge, seconds: 9, guardian: guardian, by: .guardian)
        }
        XCTAssertEqual(last, .notMatched(heard: "I accept Aarav's outing …", missing: "code", nextAttempt: nil))
        await assertRefused { _ = try await repository.startCapture(self.aarav, guardian: self.guardian, by: .guardian) }
        let sent = try await repository.sendVideoForReview(aarav, guardian: guardian, by: .guardian)
        XCTAssertEqual(sent.evidence?.method, .videoNeedsReview)
        XCTAssertEqual(sent.evidence?.passedChecks, [])
        XCTAssertTrue(sent.evidence?.capturesGuardianFace == true)
    }

    func testPhotoPathOnlyAfterTwoFailedUploadsAndNeedsTheTypedPhraseAndPhoneCode() async throws {
        let (repository, _) = make([.uploadFails(progress: 0.38), .uploadFails(progress: 0.38)])
        try await repository.recordConsent(guardian, by: .guardian)
        let challenge = try await repository.startCapture(aarav, guardian: guardian, by: .guardian)
        await assertRefused { _ = try await repository.startPhotoFallback(self.aarav, guardian: self.guardian, by: .guardian) }
        let first = try await repository.submitVideo(challenge, seconds: 9, guardian: guardian, by: .guardian)
        XCTAssertEqual(first, .uploadFailed(progress: 0.38, retriesLeft: 1))
        let second = try await repository.submitVideo(challenge, seconds: 9, guardian: guardian, by: .guardian)
        XCTAssertEqual(second, .uploadFailed(progress: 0.38, retriesLeft: 0))
        let photo = try await repository.startPhotoFallback(aarav, guardian: guardian, by: .guardian)
        XCTAssertEqual(photo.typedPhrase, "I accept 777")
        XCTAssertEqual(photo.sentTo, "+91 98••• ••214")
        // Text alone is never enough: the phone code must match too.
        await assertRefused {
            _ = try await repository.submitPhoto(self.aarav, typed: "I accept 777", phoneCode: "000000",
                                                 guardian: self.guardian, by: .guardian)
        }
        let sent = try await repository.submitPhoto(aarav, typed: "i accept  777", phoneCode: "777777", guardian: guardian,
                                                    by: .guardian)
        XCTAssertEqual(sent.evidence?.method, .photoAndText)
        XCTAssertTrue(sent.evidence?.capturesGuardianFace == true)
    }

    func testNoTimeoutApprovesAnything() async throws {
        let (repository, clock) = make()
        // The guardian never answers. Days pass.
        clock.set(OutingSeed.at(8, 18, 12, 0))
        let request = try await repository.guardianRequest(for: guardian)
        XCTAssertEqual(request?.stage, .awaitingGuardian)
        XCTAssertEqual(request?.escalation(at: clock.now()), .pastDeadline(since: OutingSeed.at(8, 16, 23, 0)))
        XCTAssertNil(request?.pass)
        await assertRefused { _ = try await repository.rejectAsGuardian(self.aarav, reason: nil, guardian: self.guardian, by: .guardian) }
        let escalated = try await repository.wardenEscalated(for: warden)
        XCTAssertTrue(escalated.contains { $0.id == aarav })
        await assertRefused { _ = try await repository.approve(self.aarav, warden: self.warden, by: .warden) }
        let closed = try await repository.closeRequest(aarav, warden: warden, by: .warden)
        XCTAssertEqual(closed.stage, .closed)
        XCTAssertNil(closed.pass)
        // A request awaiting the warden past its deadline is escalated, still not approved.
        let meera = try await repository.outing(OutingSeed.meeraRequest.id, for: warden)
        XCTAssertEqual(meera.stage, .awaitingWarden)
        XCTAssertNil(meera.pass)
    }

    func testCallPathNeedsANoteThenTheWardenDecides() async throws {
        let (repository, _) = make(at: OutingSeed.wardenMoment)
        let kiran = OutingSeed.kiranRequest.id
        await assertRefused { _ = try await repository.approve(kiran, warden: self.warden, by: .warden) }
        await assertRefused { _ = try await repository.recordGuardianCall(kiran, note: " ", warden: self.warden, by: .warden) }
        let called = try await repository.recordGuardianCall(kiran, note: "Spoke to Kiran's father.", warden: warden,
                                                             by: .warden)
        XCTAssertEqual(called.evidence?.method, .confirmedByCall)
        XCTAssertEqual(called.evidence?.calledNumber, "+91 98••• ••557")
        let approved = try await repository.approve(kiran, warden: warden, by: .warden)
        XCTAssertEqual(approved.pass?.code, "4QZ8")
    }

    func testWardenRejectNeedsAReasonAndUndoRestores() async throws {
        let (repository, _) = make(at: OutingSeed.wardenMoment)
        let meera = OutingSeed.meeraRequest.id
        await assertRefused { _ = try await repository.reject(meera, reason: "", warden: self.warden, by: .warden) }
        let rejected = try await repository.reject(meera, reason: "Exam soon", warden: warden, by: .warden)
        XCTAssertEqual(rejected.stage, .wardenRejected)
        let undone = try await repository.undoDecision(meera, warden: warden, by: .warden)
        XCTAssertEqual(undone.stage, .awaitingWarden)
        XCTAssertNil(undone.wardenDecision)
    }

    func testGuardianWithdrawalStopsTheGate() async throws {
        let (repository, clock) = make()
        _ = try await acceptByVideo(repository)
        clock.set(OutingSeed.wardenMoment)
        _ = try await repository.approve(aarav, warden: warden, by: .warden)
        let withdrawn = try await repository.withdrawApproval(aarav, guardian: guardian, by: .guardian)
        XCTAssertEqual(withdrawn.stage, .withdrawn)
        clock.set(OutingSeed.gateMoment)
        guard case .withdrawn = try await repository.checkPassCode("7F3K", by: .gate) else {
            return XCTFail("A withdrawn pass must be refused")
        }
        await assertRefused { _ = try await repository.recordExit(self.aarav, by: .gate) }
    }

    // MARK: Role guards and scope

    func testEveryWriteRefusesTheWrongRole() async throws {
        let (repository, _) = make(at: OutingSeed.wardenMoment)
        await assertRefused { try await repository.recordConsent(self.guardian, by: .warden) }
        await assertRefused { _ = try await repository.rejectAsGuardian(self.aarav, reason: nil, guardian: self.guardian, by: .student) }
        await assertRefused { _ = try await repository.approve(OutingSeed.meeraRequest.id, warden: self.warden, by: .guardian) }
        await assertRefused { _ = try await repository.approve(OutingSeed.meeraRequest.id, warden: self.warden, by: .gate) }
        await assertRefused { _ = try await repository.recordExit(self.aarav, by: .warden) }
        await assertRefused { _ = try await repository.gateOverview(by: .supervisor) }
        await assertRefused { try await repository.begin(as: .student) }
        // An account that is not a warden, or not this student's guardian, is refused too.
        await assertRefused { _ = try await repository.wardenQueue(for: self.guardian) }
        await assertRefused { _ = try await repository.guardianRequest(for: self.warden) }
    }

    func testWardenSeesOwnBlockOnly() async throws {
        let (repository, _) = make(at: OutingSeed.gateMoment)
        let other = OutingSeed.mainGateOut[0].id
        do {
            _ = try await repository.outing(other, for: warden)
            XCTFail("Another block's request must not be visible")
        } catch RepositoryError.notFound {}
        let outNow = try await repository.wardenOutNow(for: warden)
        XCTAssertTrue(outNow.allSatisfy { $0.student.block == OutingSeed.block })
        let gateOut = try await repository.gateOutNow(by: .gate)
        XCTAssertEqual(gateOut.count, OutingSeed.mainGateOut.count)
    }

    func testGateLookupsAreRecordedAndFindOnlyPasses() async throws {
        let (repository, clock) = make()
        let none = try await repository.findStudent(srmID: "RA2411003010238", by: .gate)
        XCTAssertTrue(none.isEmpty, "No pass yet, so no match")
        _ = try await acceptByVideo(repository)
        clock.set(OutingSeed.wardenMoment)
        _ = try await repository.approve(aarav, warden: warden, by: .warden)
        let found = try await repository.findStudent(srmID: "ra2411003010238", by: .gate)
        XCTAssertEqual(found.map(\.id), [aarav])
        let lookups = await repository.lookups
        XCTAssertEqual(lookups.count, 2)
        await assertRefused { _ = try await repository.findStudent(srmID: "RA2411003010238", by: .warden) }
    }

    func testClockOnlyMovesForward() async throws {
        let (repository, _) = make(at: OutingSeed.gateMoment)
        try await repository.begin(as: .guardian)
        let now = await repository.now()
        XCTAssertEqual(now, OutingSeed.gateMoment)
    }

    func testSeedHasNoTextOnlyMethod() {
        XCTAssertFalse(GuardianEvidenceMethod.allCases.map(\.rawValue).contains { $0.lowercased().contains("text") && !$0.contains("photo") })
        for item in OutingSeed.cases {
            if let evidence = item.evidence, evidence.method != .confirmedByCall {
                XCTAssertTrue(evidence.capturesGuardianFace)
            }
        }
    }
}
#endif
