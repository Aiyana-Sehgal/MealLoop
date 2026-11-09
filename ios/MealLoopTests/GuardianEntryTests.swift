#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The guardian's simulated first-run flow (G-0, G-A1 to G-A3) reads only the seeded guardian link.
@MainActor
final class GuardianEntryTests: XCTestCase {
    private func loadedModel() async -> GuardianModel {
        let clock = DemoClock(OutingSeed.guardianMoment)
        let repository = InMemoryOutingCaseRepository(clock: clock, simulation: ScriptedCaptureSimulation([]),
                                                      makeDigits: { String(repeating: "4", count: $0) })
        let model = GuardianModel(account: OutingSeed.guardianAccount, repository: repository)
        await model.load()
        return model
    }

    func testEntryShowsTheSeededLinkOnly() async {
        let model = await loadedModel()
        XCTAssertEqual(model.link?.phone, "+91 98••• ••214")
        XCTAssertEqual(model.link?.student.displayName, "Aarav ••0238")
        XCTAssertEqual(GuardianEntryCopy.linkedTitle(model.studentName, model.link?.student.block), "You're linked to Aarav · Block B")
        XCTAssertEqual(GuardianEntryCopy.linkedTo("Aarav ••0238", nil), "Linked to Aarav ••0238")
    }

    func testHowItWorksNamesTheStudentAndBlockFromTheLink() {
        let steps = GuardianEntryCopy.howSteps(student: "Aarav", block: "Block B")
        XCTAssertEqual(steps.map(\.0), ["Aarav asks to go out", "You reply first", "The Block B warden reviews", "Aarav gets a pass"])
    }

    func testNotificationsComeFromTheRecordsNewestFirst() async throws {
        let clock = DemoClock(OutingSeed.at(8, 16, 19, 42))
        let repository = InMemoryOutingCaseRepository(clock: clock, simulation: ScriptedCaptureSimulation([]),
                                                      makeDigits: { String(repeating: "4", count: $0) })
        let guardian = OutingSeed.guardianAccount
        try await repository.recordConsent(guardian, by: .guardian)
        let challenge = try await repository.startCapture(OutingSeed.aaravRequest.id, guardian: guardian, by: .guardian)
        _ = try await repository.submitVideo(challenge, seconds: 9, guardian: guardian, by: .guardian)
        let model = GuardianModel(account: guardian, repository: repository)
        await model.load()
        let notices = GuardianNotices.notices(request: model.request, past: model.pastAnswers, studentName: model.studentName)
        XCTAssertEqual(Array(notices.prefix(2).map(\.title)), [GuardianInfoCopy.youApproved, GuardianInfoCopy.newRequest])
        // No record holds when the request was made: that row shows no time rather than an invented one.
        XCTAssertNil(notices[1].time)
        XCTAssertEqual(notices.filter { $0.title == GuardianInfoCopy.youApproved && $0.isCurrent }.count, 1)
        XCTAssertLessThanOrEqual(notices.dropFirst(2).count, model.pastAnswers.count)
        XCTAssertFalse(notices.contains { $0.title == GuardianInfoCopy.passIssued }, "No pass before the warden signs")
    }

    func testEntryDoesNotAnswerTheRequest() async {
        // Finishing the flow only opens the decision page: the request still waits for the guardian's answer.
        let model = await loadedModel()
        XCTAssertEqual(model.step, .choose)
        XCTAssertEqual(model.request?.stage, .awaitingGuardian)
    }
}
#endif
