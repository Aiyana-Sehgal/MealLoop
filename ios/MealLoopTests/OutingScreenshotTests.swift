#if DEMO_DATA || REVIEW_DATA
import SwiftUI
import UIKit
import XCTest
@testable import MealLoop

/// Captures every outing state (Warden, Gate, Guardian) for docs/verification/outings/. Each state is reached through
/// the outing repository's own operations, then the real views are hosted in a window and drawn to a PNG.
/// Skipped unless TEST_RUNNER_OUTINGS_SHOTS names an output folder, so normal test runs write nothing.
@MainActor
final class OutingScreenshotTests: XCTestCase {
    private var outputFolder: URL!

    // MARK: World

    @MainActor
    final class World {
        let clock: DemoClock
        let repository: InMemoryOutingCaseRepository
        let environment: AppEnvironment
        let router = AppRouter()
        let store = SessionStore()

        init(at moment: Date = OutingSeed.guardianMoment, cases: [OutingCase] = OutingSeed.cases,
             script: [SimulatedCaptureOutcome] = [], codes: [String] = ["472", "815", "309"]) {
            clock = DemoClock(moment)
            final class Codes: @unchecked Sendable {
                var values: [String]
                init(_ values: [String]) { self.values = values }
                func next(_ count: Int) -> String {
                    if count == 3, !values.isEmpty { return values.removeFirst() }
                    return count == 6 ? "481926" : String(repeating: "4", count: count)
                }
            }
            let source = Codes(codes)
            repository = InMemoryOutingCaseRepository(clock: clock, cases: cases,
                                                      simulation: ScriptedCaptureSimulation(script),
                                                      makeDigits: { source.next($0) })
            let demo = DemoDataProvider(scenario: .storyStart, clock: DemoClock(DemoSeed.storyStartNow))
            environment = AppEnvironment(kind: .review, repositories: demo.makeRepositories(), clock: clock,
                                         demoControls: nil)
            OutingCaseRepositories.register(repository, for: environment)
        }

        func at(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int) { clock.set(OutingSeed.at(month, day, hour, minute)) }

        func session(_ role: Role) -> Session {
            let account = DemoSeed.accounts.first { $0.role == role }!
            store.signIn(Session(account: account, staff: nil))
            return Session(account: account, staff: nil)
        }

        /// The guardian accepts Aarav's outing by video at 7:42 PM on Friday.
        func guardianAcceptsByVideo() async throws {
            at(8, 16, 19, 42)
            let guardian = OutingSeed.guardianAccount
            try await repository.recordConsent(guardian, by: .guardian)
            let challenge = try await repository.startCapture(OutingSeed.aaravRequest.id, guardian: guardian, by: .guardian)
            _ = try await repository.submitVideo(challenge, seconds: 9, guardian: guardian, by: .guardian)
        }

        func wardenModel() async -> WardenModel {
            let model = WardenModel(account: OutingSeed.wardenAccount, repository: repository)
            await model.load()
            return model
        }
    }

    // MARK: Capture

    override func setUp() async throws {
        guard let path = ProcessInfo.processInfo.environment["OUTINGS_SHOTS"], !path.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_OUTINGS_SHOTS to capture the outing screenshots.")
        }
        let device = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? UIDevice.current.model
        outputFolder = URL(fileURLWithPath: path).appendingPathComponent(device.replacingOccurrences(of: " ", with: "_"))
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
    }

    func shot<V: View>(_ name: String, _ world: World, wait: Double = 1.2, @ViewBuilder _ view: () -> V) async throws {
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
        try XCTUnwrap(image.pngData()).write(to: outputFolder.appendingPathComponent("\(name).png"))
        window.isHidden = true
        window.rootViewController = nil
    }

    private func warden(_ model: WardenModel, tab: WardenTab = .queue, route: WardenRoute? = nil,
                        sheet: WardenQueueScreen.Sheet? = nil, askFields: Set<String> = [], askNote: String = "",
                        reason: String? = nil, calling: OutingRequestID? = nil, all: Bool = false) -> some View {
        WardenTabsView(account: OutingSeed.wardenAccount, initialTab: tab, initialRoute: route, preparedModel: model,
                       queueSheet: sheet, askFields: askFields, askNote: askNote, rejectReason: reason,
                       callingID: calling, historyStartsOnAll: all)
    }

    // MARK: Warden

    func testCaptureWardenQueue() async throws {
        let world = World()
        try await world.guardianAcceptsByVideo()
        world.at(8, 17, 10, 0)
        _ = world.session(.warden)
        try await world.repository.begin(as: .warden)

        var model = await world.wardenModel()
        try await shot("W01_warden_decide_with_video", world) { warden(model) }

        model = await world.wardenModel()
        await model.focus(on: OutingSeed.meeraRequest.id)
        try await shot("W01_warden_decide_please_watch", world) { warden(model) }

        model = await world.wardenModel()
        await model.focus(on: OutingSeed.arjunRequest.id)
        try await shot("W01_warden_decide_photo_and_text", world) { warden(model) }

        model = await world.wardenModel()
        await model.focus(on: OutingSeed.kiranRequest.id)
        try await shot("W01_warden_decide_call_note_needed", world) { warden(model) }

        model = await world.wardenModel()
        model.isRefreshing = true
        try await shot("W01_warden_decide_video_loading", world) { warden(model) }

        model = await world.wardenModel()
        try await shot("W01_warden_decide_ask_sheet", world) {
            warden(model, sheet: .ask, askFields: ["Time"], askNote: "Back by 6 PM instead of 8 PM.")
        }
        model = await world.wardenModel()
        try await shot("W01_warden_decide_no_sheet", world) { warden(model, sheet: .reject, reason: "Exam soon") }

        model = await world.wardenModel()
        await world.repository.setOffline(true)
        await model.load()
        try await shot("W01_warden_decide_offline", world) { warden(model) }
        await world.repository.setOffline(false)

        world.at(8, 17, 10, 3)
        model = await world.wardenModel()
        await model.approve()
        try await shot("W01_warden_decide_approved", world) { warden(model) }
        await model.undo()

        model = await world.wardenModel()
        await model.askForChange(fields: ["Time"], note: "Back by 6 PM instead of 8 PM.")
        try await shot("W01_warden_decide_change_asked", world) { warden(model) }
        await model.undo()

        model = await world.wardenModel()
        await model.reject(reason: "Exam soon")
        try await shot("W01_warden_decide_rejected", world) { warden(model) }
        await model.undo()

        // Kiran, answered by call: the warden records the note, then decides.
        _ = try await world.repository.recordGuardianCall(OutingSeed.kiranRequest.id,
                                                          note: "Spoke to Kiran's father. He agreed to Sat 1–5 PM.",
                                                          warden: OutingSeed.wardenAccount, by: .warden)
        model = await world.wardenModel()
        try await shot("W01_warden_decide_confirmed_by_call", world) { warden(model) }

        model = await world.wardenModel()
        try await shot("W01_warden_me", world) { warden(model, route: .me) }
    }

    func testCaptureWardenEmptyAndEscalated() async throws {
        let empty = World(at: OutingSeed.wardenMoment, cases: [])
        _ = empty.session(.warden)
        let emptyModel = await empty.wardenModel()
        try await shot("W01_warden_decide_empty", empty) { warden(emptyModel) }

        let world = World()
        try await world.guardianAcceptsByVideo()
        world.at(8, 17, 10, 0)
        _ = world.session(.warden)
        let model = await world.wardenModel()
        try await shot("W04_warden_escalated", world) { warden(model, tab: .escalated) }
        try await shot("W04_warden_escalated_call_kiran_sheet", world) {
            warden(model, tab: .escalated, calling: OutingSeed.kiranRequest.id)
        }
        try await shot("W04_warden_escalated_call_dev_sheet", world) {
            warden(model, tab: .escalated, calling: OutingSeed.devRequest.id)
        }
    }

    func testCaptureWardenOutNowAndHistory() async throws {
        let world = World()
        let warden = OutingSeed.wardenAccount
        try await world.guardianAcceptsByVideo()
        world.at(8, 17, 10, 2)
        _ = world.session(.warden)
        _ = try await world.repository.approve(OutingSeed.aaravRequest.id, warden: warden, by: .warden)
        _ = try await world.repository.recordGuardianCall(OutingSeed.kiranRequest.id,
                                                          note: "Spoke to Kiran's father. He agreed to Sat 1–5 PM.",
                                                          warden: warden, by: .warden)
        _ = try await world.repository.approve(OutingSeed.kiranRequest.id, warden: warden, by: .warden)
        _ = try await world.repository.approve(OutingSeed.meeraRequest.id, warden: warden, by: .warden)
        world.at(8, 17, 13, 4)
        _ = try await world.repository.recordExit(OutingSeed.kiranRequest.id, by: .gate)
        world.at(8, 17, 14, 4)
        _ = try await world.repository.recordExit(OutingSeed.aaravRequest.id, by: .gate)
        world.at(8, 17, 15, 0)
        _ = try await world.repository.recordExit(OutingSeed.meeraRequest.id, by: .gate)
        world.at(8, 17, 17, 12)

        let model = await world.wardenModel()
        try await shot("W02_warden_out_now", world) { self.warden(model, tab: .outNow) }
        try await shot("W02_warden_out_now_student", world) {
            self.warden(model, tab: .outNow, route: .outNowStudent(OutingSeed.kiranRequest.id))
        }
        world.at(8, 17, 21, 0)
        await model.load()
        try await shot("W03_warden_history", world) { self.warden(model, tab: .history) }
        try await shot("W03_warden_history_all", world) { self.warden(model, tab: .history, all: true) }
        try await shot("W03_warden_history_record", world) {
            self.warden(model, tab: .history, route: .historyRecord(OutingSeed.aaravRequest.id.rawValue))
        }
        try await shot("W03_warden_history_record_video_expired", world) {
            self.warden(model, tab: .history, route: .historyRecord("aarav-jul-13"))
        }
    }

    // MARK: Gate

    private func gate(_ model: GateModel, _ path: [GateRoute] = [], code: String = "", srmID: String = "") -> some View {
        GateFlowView(initialPath: path, preparedModel: model, initialCode: code, initialSRMID: srmID)
    }

    /// Aarav's pass signed by the warden, the gate at 2:00 PM on Saturday.
    private func gateWorld() async throws -> (World, GateModel) {
        let world = World()
        try await world.guardianAcceptsByVideo()
        world.at(8, 17, 10, 40)
        _ = try await world.repository.approve(OutingSeed.aaravRequest.id, warden: OutingSeed.wardenAccount, by: .warden)
        world.at(8, 17, 14, 0)
        _ = world.session(.gate)
        let model = GateModel(repository: world.repository)
        await model.load()
        return (world, model)
    }

    func testCaptureGate() async throws {
        let (world, model) = try await gateWorld()
        let aarav = OutingSeed.aaravRequest.id
        try await shot("GA1_gate_home", world) { gate(model) }
        try await shot("V5_gate_scan", world) { gate(model, [.scan]) }
        try await shot("V5_gate_pass_code", world) { gate(model, [.scan, .passCode], code: "7F3K") }
        try await shot("V5_gate_find_student", world) { gate(model, [.scan, .passCode, .findStudent], srmID: "RA2411003010238") }
        let exitCheck = try await world.repository.checkPassCode("7F3K", by: .gate)
        try await shot("V5_gate_verify_exit", world) { gate(model, [.scan, .verify(exitCheck)]) }
        world.at(8, 17, 14, 4)
        guard let exit = await model.run(.exit(aarav)) else { return XCTFail("Exit not recorded") }
        try await shot("V5_gate_exit_recorded", world) { gate(model, [exit]) }
        let usedCheck = try await world.repository.checkPassCode("7F3K", by: .gate)
        try await shot("V5_gate_verify_return", world) { gate(model, [.scan, .verify(usedCheck)]) }
        try await shot("V5_gate_out_now", world) { gate(model, [.outNow]) }
        try await shot("V5_gate_report_a_problem", world) { gate(model, [.report]) }
        world.at(8, 17, 14, 41)
        let report = try await world.repository.reportGateProblem(.scannerNotWorking, by: .gate)
        try await shot("V5_gate_sent_to_duty_warden", world) { gate(model, [.reportSent(report)]) }
        let notValid = try await world.repository.checkPassCode("ZZZZ", by: .gate)
        try await shot("V5_gate_not_valid", world) { gate(model, [.outcome(.refused(notValid))]) }
        try await shot("V5_gate_offline", world) { gate(model, [.outcome(.offline(.code("7F3K")))]) }

        world.at(8, 17, 19, 41)
        guard let back = await model.run(.back(aarav)) else { return XCTFail("Return not recorded") }
        try await shot("V5_gate_return_recorded", world) { gate(model, [back]) }
        let again = try await world.repository.checkPassCode("7F3K", by: .gate)
        try await shot("V5_gate_already_exited", world) { gate(model, [.outcome(.refused(again))]) }
    }

    func testCaptureGateRefusals() async throws {
        let (world, model) = try await gateWorld()
        let aarav = OutingSeed.aaravRequest.id
        world.at(8, 17, 13, 40)
        let early = try await world.repository.checkPassCode("7F3K", by: .gate)
        await model.load()
        try await shot("V5_gate_too_early", world) { gate(model, [.outcome(.refused(early))]) }
        world.at(8, 17, 20, 5)
        let late = try await world.repository.checkPassCode("7F3K", by: .gate)
        try await shot("V5_gate_too_late", world) { gate(model, [.outcome(.refused(late))]) }

        // Back late: out at 2:04 PM, back at 8:25 PM.
        let (lateWorld, lateModel) = try await gateWorld()
        lateWorld.at(8, 17, 14, 4)
        _ = await lateModel.run(.exit(aarav))
        lateWorld.at(8, 17, 20, 25)
        await lateModel.load()
        try await shot("GA8_gate_overdue_returns", lateWorld) { gate(lateModel, [.overdue]) }
        guard let back = await lateModel.run(.back(aarav)) else { return XCTFail("Return not recorded") }
        try await shot("V5_gate_back_late", lateWorld) { gate(lateModel, [back]) }

        // Withdrawn by the guardian after the pass was signed.
        let (withdrawWorld, withdrawModel) = try await gateWorld()
        withdrawWorld.at(8, 17, 13, 0)
        _ = try await withdrawWorld.repository.withdrawApproval(aarav, guardian: OutingSeed.guardianAccount, by: .guardian)
        withdrawWorld.at(8, 17, 14, 0)
        let withdrawn = try await withdrawWorld.repository.checkPassCode("7F3K", by: .gate)
        try await shot("V5_gate_pass_withdrawn", withdrawWorld) { gate(withdrawModel, [.outcome(.refused(withdrawn))]) }
    }
}
#endif
