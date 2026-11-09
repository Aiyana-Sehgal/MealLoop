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

    func testEntryDoesNotAnswerTheRequest() async {
        // Finishing the flow only opens the decision page: the request still waits for the guardian's answer.
        let model = await loadedModel()
        XCTAssertEqual(model.step, .choose)
        XCTAssertEqual(model.request?.stage, .awaitingGuardian)
    }
}
#endif
