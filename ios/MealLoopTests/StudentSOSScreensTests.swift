#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// G3: the restyled SOS flow (2162:6 to 2162:152648, 221:63509) on `SOSRepository.raise`.
@MainActor
final class StudentSOSScreensTests: XCTestCase {
    private let context = StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess)

    /// An SOS source that always fails (not offline): the Failed state.
    private struct FailingSOS: SOSRepository {
        func raise(_ report: SOSReport) async throws -> SOSCase { throw RepositoryError.notFound }
        func activeCases(for mess: MessID) async throws -> [SOSCase] { [] }
        func claim(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase { throw RepositoryError.notFound }
        func markChecked(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase { throw RepositoryError.notFound }
        func close(_ sos: SOSCaseID, by role: Role) async throws -> SOSCase { throw RepositoryError.notFound }
    }

    private func make(_ scenario: DemoScenario = .duringMeal, camera: StudentSOSViewModel.Camera = .available,
                      location: StudentSOSViewModel.Location = .atMess) -> (StudentSOSViewModel, DemoDataProvider, Repositories) {
        let demo = DemoDataProvider(scenario: scenario)
        let repositories = demo.makeRepositories()
        return (StudentSOSViewModel(context: context, repositories: repositories, clock: demo.clock, camera: camera,
                                    location: location), demo, repositories)
    }

    func testAPhotoSOSIsRaisedForTheMessWithTheDish() async throws {
        let (model, _, repositories) = make()
        await model.load()
        let first = try XCTUnwrap(model.dishes.first, "Which dish? lists the current meal's dishes.")
        XCTAssertFalse(model.canGoOn)
        model.choose(.foundInFood)
        model.toggle(dish: first)
        model.takePhoto()
        let raised = await model.send()
        XCTAssertTrue(raised)
        XCTAssertEqual(model.sos?.title, "Found something in my food · \(first)")
        XCTAssertEqual(model.sos?.place, DemoSeed.mess.name)
        let open = try await repositories.sos.activeCases(for: DemoSeed.mess.id)
        XCTAssertTrue(open.contains { $0.id == model.sos?.id }, "Every staff role of the mess sees it.")
    }

    func testOfflineNothingIsSentOrShownAsSentAndItSendsOnceBack() async throws {
        let (model, demo, repositories) = make(.offline)
        model.choose(.spoiled)
        model.takePhoto()
        await model.checkConnection()
        XCTAssertEqual(model.sendState, .offline, "Review · Offline shows before any tap.")
        let first = await model.sendWhenOnline()
        XCTAssertFalse(first)
        XCTAssertNil(model.sos)
        XCTAssertEqual(model.sendState, .waitingForConnection)
        await demo.setScenario(.duringMeal)
        let again = await model.send()
        XCTAssertTrue(again, "Sent with the same key once back.")
        let open = try await repositories.sos.activeCases(for: DemoSeed.mess.id)
        XCTAssertEqual(open.filter { $0.id == model.sos?.id }.count, 1)
    }

    func testAFailedSendOffersTryAgainAndNeverOpensASecondCase() async throws {
        let demo = DemoDataProvider(scenario: .duringMeal)
        var repositories = demo.makeRepositories()
        let working = repositories.sos
        repositories = Repositories(people: repositories.people, meals: repositories.meals, mealState: repositories.mealState,
                                    headcount: repositories.headcount, entries: repositories.entries,
                                    intentions: repositories.intentions, shortages: repositories.shortages,
                                    wasteReports: repositories.wasteReports, sos: FailingSOS(), auth: repositories.auth)
        let failing = StudentSOSViewModel(context: context, repositories: repositories, clock: demo.clock)
        failing.choose(.otherSafety)
        failing.takePhoto()
        let sent = await failing.send()
        XCTAssertFalse(sent)
        XCTAssertEqual(failing.sendState, .failed)
        XCTAssertNil(failing.sos, "Nothing is shown as sent.")
        let (model, _, _) = make()
        model.choose(.otherSafety)
        model.takePhoto()
        _ = await model.send()
        _ = await model.send()
        let open = try await working.activeCases(for: DemoSeed.mess.id)
        XCTAssertLessThanOrEqual(open.filter { $0.title == "Another safety problem" }.count, 1)
    }

    func testCameraDeniedSendsWithoutAPhotoFlagged() async throws {
        let (model, _, _) = make(camera: .denied)
        await model.load()
        model.choose(.unwell)
        model.continueWithoutPhoto()
        XCTAssertFalse(model.hasPhoto)
        XCTAssertEqual(model.subject, "I feel unwell after eating · \(MLFormat.mealSlot(try XCTUnwrap(model.meal)))")
        let raised = await model.send()
        XCTAssertTrue(raised)
        XCTAssertTrue(model.sos?.title.hasSuffix("· no photo") == true, "Flagged for the team.")
    }

    func testNoGPSRecordsNoPlace() async {
        let (model, _, _) = make(location: .unavailable)
        model.choose(.foundInFood)
        model.takePhoto()
        _ = await model.send()
        XCTAssertEqual(model.sos?.place, StudentSOSCopy.placeNotRecorded, "Nothing is guessed.")
    }
}
#endif
