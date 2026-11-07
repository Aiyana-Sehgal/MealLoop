#if DEMO_DATA || REVIEW_DATA
import SwiftUI
import UIKit
import XCTest
@testable import MealLoop

/// Captures the Door Scanner and Pass Desk states for docs/verification/staff-figma-fix/, one PNG per Figma frame,
/// named by node id so each pairs with its frame. Real views drawn on the simulator the tests run on.
/// Skipped unless TEST_RUNNER_STAFF_SHOTS names an output folder, so normal test runs write nothing.
/// Supervisor frames are captured by `SupervisorScreenshotTests`.
@MainActor
final class StaffFigmaScreenshotTests: XCTestCase {
    private var outputFolder: URL!

    @MainActor
    private final class World {
        let clock: DemoClock
        let demo: DemoDataProvider
        let repositories: Repositories
        let environment: AppEnvironment
        let router = AppRouter()
        let store = SessionStore()
        let session: Session
        let staff: StaffSession

        init(_ scenario: DemoScenario, role: Role) {
            clock = DemoClock(DemoSeed.storyStartNow)
            demo = DemoDataProvider(scenario: scenario, clock: clock)
            repositories = demo.makeRepositories()
            environment = AppEnvironment(kind: .review, repositories: repositories, clock: clock, demoControls: nil)
            staff = StaffSession(role: role, mess: DemoSeed.mess, staffInitials: DemoSeed.staffInitials(for: role),
                                 supervisorName: DemoSeed.supervisorName)
            session = Session(account: DemoSeed.accounts.first { $0.role == role }!, staff: staff)
            store.signIn(session)
        }

        func at(_ hour: Int, _ minute: Int) { clock.set(DemoSeed.time(hour, minute)) }

        func raiseSOS() async throws {
            clock.set(DemoSeed.sosRaisedAt)
            _ = try await demo.raise(SOSReport(messID: DemoSeed.mess.id, title: DemoSeed.sosTitle, place: DemoSeed.sosPlace,
                                               idempotencyKey: IdempotencyKey("sos")))
        }

        func close() async throws { _ = try await demo.closeMeal(DemoSeed.lunch.id, by: .supervisor) }

        func sosModel() async -> DoorSOSViewModel {
            let model = DoorSOSViewModel(sos: repositories.sos, mess: staff.mess.id, role: staff.role)
            await model.load()
            return model
        }
    }

    override func setUp() async throws {
        guard let path = ProcessInfo.processInfo.environment["STAFF_SHOTS"], !path.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_STAFF_SHOTS to capture the staff frames.")
        }
        outputFolder = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
    }

    private func shot<V: View>(_ node: String, _ world: World, wait: Double = 1.0, @ViewBuilder _ view: () -> V) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds
        window.windowLevel = .alert + 1
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: view()
            .environment(world.environment).environment(world.router).environment(world.store))
        window.makeKeyAndVisible()
        try await Task.sleep(for: .seconds(wait))
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        try XCTUnwrap(image.pngData()).write(to: outputFolder.appendingPathComponent("\(node).png"))
        window.isHidden = true
        window.rootViewController = nil
    }

    private func door(_ world: World, tab: StaffTab = .home) -> some View {
        world.router.selectedStaffTab = tab
        return DoorScannerRootView(session: world.session)
    }

    private func desk(_ world: World, tab: StaffTab = .home) -> some View {
        world.router.selectedStaffTab = tab
        return PassDeskRootView(session: world.session)
    }

    // MARK: Door Scanner

    func testDoorHomeAlertsAndMe() async throws {
        let before = World(.beforeMeal, role: .doorScanner)
        before.at(11, 50)
        try await shot("2471_2234", before) { door(before) }
        try await shot("2512_173545", before) { door(before, tab: .alerts) }

        let during = World(.duringMeal, role: .doorScanner)
        during.at(12, 55)
        try await shot("2471_2437", during) { door(during) }
        try await shot("2512_173100", during) { door(during, tab: .alerts) }
        try await shot("2512_173663", during) { door(during, tab: .me) }

        let offline = World(.duringMeal, role: .doorScanner)
        offline.at(12, 55)
        try await shot("2471_3146", offline, wait: 1.8) {
            OfflineAfterLoad(goOffline: { await offline.demo.setScenario(.offline) }) { door(offline) }
        }

        let after = World(.duringMeal, role: .doorScanner)
        after.at(13, 55)
        try await after.close()
        after.at(14, 5)
        try await shot("2471_2732", after) { door(after) }
        try await shot("2512_173241", after) { door(after, tab: .alerts) }
    }

    func testDoorSOS() async throws {
        let world = World(.duringMeal, role: .doorScanner)
        try await world.raiseSOS()
        world.at(12, 50)
        try await shot("2471_2581", world) { door(world) }
        try await shot("2512_3778", world) { door(world, tab: .alerts) }
        let model = await world.sosModel()
        try await shot("2476_3498", world, wait: 1.4) {
            Sheeted(base: door(world)) {
                DoorSOSPanel(model: model, session: world.staff, now: world.clock.now(), onClose: {}, onChecked: {})
            }
        }
        await model.claim()
        world.at(12, 51)
        try await shot("2476_3747", world, wait: 1.4) {
            Sheeted(base: door(world)) {
                DoorSOSPanel(model: model, session: world.staff, now: world.clock.now(), onClose: {}, onChecked: {})
            }
        }
        try await shot("2512_172793", world) { door(world, tab: .alerts) }
        world.at(12, 52)
        try await shot("2476_3925", world) { door(world) }
        _ = await model.markChecked()
        try await shot("2512_172948", world) { door(world, tab: .alerts) }
        world.at(12, 58)
        try await shot("2476_4075", world, wait: 0.8) {
            Toasted(text: DoorScannerCopy.markedAsChecked(world.staff.supervisorName), inset: DoorLayout.tabBarClearance) { door(world) }
        }
    }

    private func entrySheet(_ world: World, digits: [Int]) async -> DoorEntryFlow {
        let flow = DoorEntryFlow(meal: DemoSeed.lunch.id, mess: world.staff.mess.id, repositories: world.repositories)
        for digit in digits { await flow.append(digit) }
        return flow
    }

    private func entryShot(_ node: String, _ world: World, _ flow: DoorEntryFlow) async throws {
        try await shot(node, world, wait: 1.4) {
            Sheeted(base: door(world)) {
                DoorEntrySheet(flow: flow, session: world.staff, meal: DemoSeed.lunch, onClose: {}, onReport: {})
            }
        }
    }

    func testDoorEntrySheet() async throws {
        let world = World(.duringMeal, role: .doorScanner)
        world.at(12, 55)
        try await entryShot("2472_2645", world, await entrySheet(world, digits: [0]))
        try await entryShot("2472_2910", world, await entrySheet(world, digits: [0, 2, 3, 8]))
        try await entryShot("2472_3317", world, await entrySheet(world, digits: [0, 9, 9, 9]))
        let flow = await entrySheet(world, digits: [0, 2, 3])
        await world.demo.setScenario(.offline)
        await flow.append(8)
        try await entryShot("2482_186231", world, flow)
    }

    func testDoorResults() async throws {
        let world = World(.duringMeal, role: .doorScanner)
        world.at(12, 55)
        let aarav = DemoSeed.sampleStudent
        func result(_ node: String, _ outcome: DoorScanOutcome) async throws {
            try await shot(node, world, wait: 0.5) {
                DoorResultView(outcome: outcome, session: world.staff, meal: DemoSeed.lunch, names: [aarav.id: "Aarav"],
                               onDone: {}, onRetry: {}, onTypeDigits: {}, onReport: {})
            }
        }
        try await result("2472_172058", .recorded(student: aarav, count: 715, withoutVoting: false))
        try await result("2472_172162", .recorded(student: aarav, count: 715, withoutVoting: true))
        try await result("2472_172269", .alreadyScanned(student: aarav, firstAt: DemoSeed.time(12, 55), count: 715))
        try await result("2472_172371", .notRecognised)
        try await result("2472_172486", .wrongMeal(servingNow: .lunch))
        try await result("2472_172595", .offline(lastUpdate: DemoSeed.time(12, 54)))
        try await result("2471_3284", .mealEnded(closedAt: DemoSeed.closedAt, finalEntries: .available(774, asOf: DemoSeed.closedAt)))
    }

    func testDoorProblemsAndWithoutVoting() async throws {
        let world = World(.duringMeal, role: .doorScanner)
        world.at(12, 56)
        let log = DoorProblemLog(mealState: world.repositories.mealState, mess: world.staff.mess.id, clock: world.clock)
        try await shot("2474_3212", world) {
            DoorReportProblemView(log: log, onBack: {}, onSent: {})
        }
        try await shot("2474_3359", world, wait: 0.8) {
            Toasted(text: DoorScannerCopy.savedToast, inset: MLSpacing.s32) {
                DoorReportProblemView(log: log, onBack: {}, onSent: {})
            }
        }
        _ = await log.report(.scanner)
        try await shot("2474_3490", world) {
            DoorOpenProblemsView(log: log, session: world.staff, subtitle: "Lunch · Main Mess", onBack: {}, onReport: {})
        }
        _ = await log.report(.crowd)
        try await shot("2474_3613", world) {
            DoorOpenProblemsView(log: log, session: world.staff, subtitle: "Lunch · Main Mess", onBack: {}, onReport: {})
        }
        let flow = await entrySheet(world, digits: [0, 2, 3, 8])
        await flow.recordMatch()
        let afterMeal = World(.duringMeal, role: .doorScanner)
        afterMeal.at(13, 55)
        let late = await entrySheet(afterMeal, digits: [0, 2, 3, 8])
        await late.recordMatch()
        try await afterMeal.close()
        afterMeal.at(14, 5)
        try await shot("2474_3748", afterMeal) {
            DoorWithoutVotingView(model: DoorWithoutVotingViewModel(entries: afterMeal.repositories.entries, meal: DemoSeed.lunch.id, directory: afterMeal.repositories.staffDirectory),
                                  meal: DemoSeed.lunch, mess: afterMeal.staff.mess, onBack: {})
        }
        try await shot("2474_3886", world) {
            DoorWithoutVotingView(model: DoorWithoutVotingViewModel(entries: world.repositories.entries, meal: DemoSeed.lunch.id, directory: world.repositories.staffDirectory),
                                  meal: DemoSeed.lunch, mess: world.staff.mess, onBack: {})
        }
    }

    // MARK: Pass Desk

    func testDeskHomeAlertsAndMe() async throws {
        let before = World(.beforeMeal, role: .passDesk)
        before.at(11, 50)
        try await shot("2530_4250", before) { desk(before) }
        try await shot("2545_7026", before) { desk(before, tab: .alerts) }

        let during = World(.duringMeal, role: .passDesk)
        during.at(12, 56)
        try await shot("2545_6885", during) { desk(during, tab: .alerts) }
        try await shot("2545_7144", during) { desk(during, tab: .me) }

        try await during.close()
        during.at(14, 5)
        try await shot("2531_5101", during) { desk(during) }
    }

    func testDeskSOS() async throws {
        let world = World(.duringMeal, role: .passDesk)
        try await world.raiseSOS()
        world.at(12, 50)
        try await shot("2545_6435", world) { desk(world, tab: .alerts) }
        let model = await world.sosModel()
        try await shot("2544_6222", world, wait: 1.4) {
            Sheeted(base: desk(world)) {
                PassDeskSOSPanel(model: model, session: world.staff, now: world.clock.now(), onClose: {}, onChecked: {})
            }
        }
        await model.claim()
        world.at(12, 51)
        try await shot("2544_6417", world, wait: 1.4) {
            Sheeted(base: desk(world)) {
                PassDeskSOSPanel(model: model, session: world.staff, now: world.clock.now(), onClose: {}, onChecked: {})
            }
        }
        try await shot("2545_6596", world) { desk(world, tab: .alerts) }
        _ = await model.markChecked()
        world.at(12, 53)
        try await shot("2545_6742", world) { desk(world, tab: .alerts) }
    }

    private func checkFlow(_ world: World, digits: [Int]) async -> PassDeskCheckFlow {
        let flow = PassDeskCheckFlow(session: world.staff, passes: world.repositories.specialPasses, clock: world.clock)
        flow.meal = DemoSeed.lunch
        for digit in digits { await flow.type(digit) }
        return flow
    }

    private func checkShot(_ node: String, _ world: World, _ flow: PassDeskCheckFlow, compare: PassDeskCompare) async throws {
        try await shot(node, world, wait: 1.4) {
            Sheeted(base: desk(world)) {
                PassDeskCheckSheet(flow: flow, compare: compare, session: world.staff, meal: DemoSeed.lunch)
            }
        }
    }

    func testDeskCheckSheet() async throws {
        let world = World(.duringMeal, role: .passDesk)
        world.at(12, 50)
        let flow = await checkFlow(world, digits: [0, 2, 3, 8])
        var compare = try XCTUnwrap(flow.compare)
        try await checkShot("2533_4953", world, flow, compare: compare)
        compare.live = try await world.repositories.specialPasses.refreshPassCode(for: compare.holder.student.id, meal: DemoSeed.lunch.id)
        compare.justChanged = true
        try await checkShot("2533_5217", world, flow, compare: compare)
        compare.justChanged = false
        compare.isExpired = true
        try await checkShot("2533_5411", world, flow, compare: compare)
    }

    func testDeskOutcomes() async throws {
        let world = World(.duringMeal, role: .passDesk)
        world.at(12, 50)
        let flow = await checkFlow(world, digits: [0, 2, 3, 8])
        let compare = try XCTUnwrap(flow.compare)
        let holder = compare.holder
        func outcome(_ node: String, _ value: PassDeskOutcome) async throws {
            try await shot(node, world, wait: 0.5) {
                PassDeskOutcomeView(outcome: value, session: world.staff, meal: DemoSeed.lunch,
                                    onDone: {}, onRetry: {}, onRequest: {}, onReport: {})
            }
        }
        try await outcome("2533_5598", .verified(holder, count: 42, passes: 214))
        try await outcome("2534_5241", .noPass(holder))
        try await outcome("2534_5359", .wrongMeal(holder, passFor: .dinner))
        try await outcome("2534_5466", .alreadyRecorded(holder, firstRecordedAt: DemoSeed.time(12, 18), count: 42))
        try await outcome("2534_5568", .mismatch(compare.live))
        try await outcome("2534_5675", .cantCheck(lastUpdate: DemoSeed.time(12, 49)))
        try await outcome("2531_5403", .mealEnded(closedAt: DemoSeed.closedAt, count: 196, passes: 214))
    }

    func testDeskLookUpRequestAndProblems() async throws {
        let world = World(.duringMeal, role: .passDesk)
        world.at(12, 52)
        func lookUp(_ node: String, _ digits: [Int]) async throws {
            let model = PassDeskLookUpModel(passes: world.repositories.specialPasses, meal: DemoSeed.lunch.id)
            for digit in digits { await model.type(digit) }
            try await shot(node, world) {
                PassDeskLookUpView(model: model, session: world.staff, meal: DemoSeed.lunch, onBack: {})
            }
        }
        try await lookUp("2535_5422", [])
        try await lookUp("2535_5570", [0, 2, 3, 8])
        try await lookUp("2535_5824", [0, 4, 1, 2])
        try await lookUp("2535_5948", [0, 3, 7, 7])

        let used = await checkFlow(world, digits: [0, 2, 3, 8])
        await used.matches()
        try await lookUp("2535_5697", [0, 2, 3, 8])

        let form = PassDeskRequestForm(session: world.staff, passes: world.repositories.specialPasses, meal: DemoSeed.lunch.id)
        await form.prefill("0238")
        form.reason = .phoneLost
        try await shot("2538_5464", world) {
            PassDeskRequestView(form: form, digits: "0238", onBack: {}, onSent: {})
        }
        try await shot("2538_5739", world) {
            PassDeskRequestsView(model: PassDeskRequestsModel(passes: world.repositories.specialPasses, mess: world.staff.mess.id),
                                 session: world.staff, mealName: "Lunch", onBack: {})
        }
        let log = PassDeskProblemLog(session: world.staff, repositories: world.repositories, clock: world.clock)
        try await shot("2539_6389", world) {
            PassDeskOpenProblemsView(log: log, session: world.staff, mealName: "Lunch", onBack: {}, onReport: {})
        }
        try await shot("2539_5555", world) {
            PassDeskReportProblemView(log: log, session: world.staff, meal: DemoSeed.lunch, onBack: {}, onSent: {})
        }
        try await shot("2539_5848", world, wait: 1.4) {
            Sheeted(base: PassDeskReportProblemView(log: log, session: world.staff, meal: DemoSeed.lunch, onBack: {}, onSent: {})) {
                PassDeskFoodSheet(log: log, meal: DemoSeed.lunch, supervisorName: world.staff.supervisorName,
                                  onClose: {}, onSend: { _ in })
            }
        }
        try await shot("2539_5708", world, wait: 0.8) {
            Toasted(text: PassDeskCopy.savedToast, inset: MLSpacing.s32) {
                PassDeskReportProblemView(log: log, session: world.staff, meal: DemoSeed.lunch, onBack: {}, onSent: {})
            }
        }
        try await shot("2539_6005", world, wait: 0.8) {
            Toasted(text: PassDeskCopy.foodShortSent(world.staff.supervisorName), inset: MLSpacing.s32) {
                PassDeskReportProblemView(log: log, session: world.staff, meal: DemoSeed.lunch, onBack: {}, onSent: {})
            }
        }
        try await shot("2538_5607", world, wait: 0.8) {
            Toasted(text: PassDeskCopy.requestSent, inset: PassDeskLayout.footerAboveTabBar) {
                PassDeskRequestView(form: form, digits: "0238", onBack: {}, onSent: {})
            }
        }
        _ = await log.report(.crowd)
        try await shot("2539_6145", world) {
            PassDeskOpenProblemsView(log: log, session: world.staff, mealName: "Lunch", onBack: {}, onReport: {})
        }
        _ = await log.reportFoodShort(DemoSeed.shortageDish, meal: DemoSeed.lunch.id)
        try await shot("2539_6267", world) {
            PassDeskOpenProblemsView(log: log, session: world.staff, mealName: "Lunch", onBack: {}, onReport: {})
        }
    }
}

private struct Sheeted<Base: View, Sheet: View>: View {
    let base: Base
    @ViewBuilder let sheet: () -> Sheet
    @State private var isShown = false

    var body: some View {
        base
            .mlSheet(isPresented: $isShown, content: sheet)
            .task {
                try? await Task.sleep(for: .milliseconds(400))
                isShown = true
            }
    }
}

private struct Toasted<Base: View>: View {
    let text: String
    let inset: CGFloat
    @ViewBuilder let base: Base
    @State private var message: String?

    var body: some View {
        base
            .mlToast(message: $message, bottomInset: inset)
            .task {
                try? await Task.sleep(for: .milliseconds(200))
                message = text
            }
    }
}

/// Loads the page, then the connection drops and the screens reload.
private struct OfflineAfterLoad<Base: View>: View {
    let goOffline: () async -> Void
    @ViewBuilder let base: Base
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        base.task {
            try? await Task.sleep(for: .milliseconds(600))
            await goOffline()
            environment.dataDidChange()
        }
    }
}
#endif
