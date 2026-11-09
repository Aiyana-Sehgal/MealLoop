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
        try await shot("W6_warden_alerts", world) { warden(model, route: .alerts) }

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

    // MARK: Guardian

    private func guardianView(_ model: GuardianModel, sheet: GuardianSheet? = nil, elapsed: Int = 0, typed: String = "",
                              code: String = "") -> some View {
        GuardianPageView(account: OutingSeed.guardianAccount, preparedModel: model, initialSheet: sheet,
                         recordElapsed: elapsed, photoTyped: typed, photoCode: code)
    }

    private func guardianModel(_ world: World) async -> GuardianModel {
        _ = world.session(.guardian)
        let model = GuardianModel(account: OutingSeed.guardianAccount, repository: world.repository)
        await model.load()
        return model
    }

    func testCaptureGuardianEntry() async throws {
        let world = World()
        let model = await guardianModel(world)
        func entry(_ path: [GuardianEntryStep], code: String = "") -> some View {
            GuardianEntryFlow(account: OutingSeed.guardianAccount, preparedModel: model, initialPath: path,
                              initialCode: code) { _ in }
        }
        try await shot("G0_guardian_sign_in", world) { entry([]) }
        try await shot("G0_guardian_verify_code", world) { entry([.verify], code: "482916") }
        try await shot("GA1_guardian_activate", world) { entry([.activate]) }
        try await shot("GA2_guardian_confirm_link", world) { entry([.activate, .confirmLink]) }
        try await shot("GA2_guardian_declined", world) { entry([.activate, .confirmLink, .declined]) }
        try await shot("GA3_guardian_done", world) { entry([.activate, .confirmLink, .done]) }
    }

    func testCaptureGuardianNotificationsAndHelp() async throws {
        let world = World()
        try await world.guardianAcceptsByVideo()
        let model = await guardianModel(world)
        try await shot("G5_guardian_notifications", world) {
            GuardianPageView(account: OutingSeed.guardianAccount, preparedModel: model, initialInfo: .notifications)
        }
        try await shot("G6_guardian_help", world) {
            GuardianPageView(account: OutingSeed.guardianAccount, preparedModel: model, initialInfo: .help)
        }
    }

    func testCaptureGuardianChooseAndSheets() async throws {
        let world = World()
        var model = await guardianModel(world)
        try await shot("G01_guardian_choose", world) { guardianView(model) }
        try await shot("G01_guardian_choose_about_sheet", world) { guardianView(model, sheet: .about) }
        try await shot("G01_guardian_choose_ask_to_change_sheet", world) { guardianView(model, sheet: .askToChange) }
        try await shot("G01_guardian_choose_language_sheet", world) { guardianView(model, sheet: .language) }
        try await shot("G08_guardian_reject_sheet", world) { guardianView(model, sheet: .reject) }
        world.at(8, 16, 19, 40)
        await model.accept()
        try await shot("G00_guardian_consent", world) { guardianView(model) }
        await model.agreeAndContinue()
        try await shot("G02_guardian_record_ready", world) { guardianView(model) }
        model.step = .record(.recording)
        try await shot("G02_guardian_record", world) { guardianView(model, elapsed: 7) }
        await model.finishRecording(seconds: 3)
        try await shot("G02_guardian_record_too_short", world) { guardianView(model) }
        model.step = .record(.tooDark)
        try await shot("G02_guardian_record_too_dark", world) { guardianView(model) }
        model.step = .cameraBlocked
        try await shot("G02_guardian_record_camera_blocked", world) { guardianView(model) }
        world.at(8, 16, 19, 42)
        await model.finishRecording(seconds: 9)
        try await shot("G06_guardian_sent", world) { guardianView(model) }
        try await shot("G06_guardian_sent_withdraw_sheet", world) { guardianView(model, sheet: .withdraw) }
        world.at(8, 16, 19, 50)
        model.showPastAnswers()
        try await shot("G07_guardian_past_answers", world) { guardianView(model) }
        world.at(8, 16, 20, 10)
        model = await guardianModel(world)
        try await shot("G01_guardian_choose_already_answered", world) { guardianView(model) }
        world.at(8, 16, 20, 2)
        await model.withdraw()
        try await shot("G06_guardian_sent_withdrawn", world) { guardianView(model) }

        let late = World(at: OutingSeed.at(8, 16, 23, 5))
        let lateModel = await guardianModel(late)
        try await shot("G01_guardian_choose_deadline_passed", late) { guardianView(lateModel) }

        let rejecting = World()
        let rejectModel = await guardianModel(rejecting)
        await rejectModel.reject(reason: "Exam soon")
        try await shot("G06_guardian_sent_rejected", rejecting) { guardianView(rejectModel) }

        let calling = World(at: OutingSeed.at(8, 16, 19, 45))
        let callModel = await guardianModel(calling)
        await callModel.askWardenToCall()
        try await shot("G06_guardian_sent_call_requested", calling) { guardianView(callModel) }
    }

    func testCaptureGuardianRetriesAndFallbacks() async throws {
        let heard1 = SimulatedCaptureOutcome.notMatched(heard: "I accept Aarav's outing …", missing: "code 4 7 2")
        let heard2 = SimulatedCaptureOutcome.notMatched(heard: "I accept Aarav's outing, code 8 1 …",
                                                        missing: "the last digit of 8 1 5")
        let world = World(script: [heard1, heard2, heard2])
        let model = await guardianModel(world)
        await model.accept()
        await model.agreeAndContinue()
        await model.finishRecording(seconds: 9)
        try await shot("G03_guardian_retry", world) { guardianView(model) }
        await model.recordAgain()
        model.step = .record(.recording)
        try await shot("G02_guardian_record_try2", world) { guardianView(model, elapsed: 7) }
        await model.finishRecording(seconds: 9)
        try await shot("G03_guardian_retry_try3", world) { guardianView(model) }
        await model.recordAgain()
        model.step = .record(.recording)
        try await shot("G02_guardian_record_try3", world) { guardianView(model, elapsed: 7) }
        await model.finishRecording(seconds: 9)
        try await shot("G04_guardian_send_video", world) { guardianView(model) }
        world.at(8, 16, 19, 44)
        await model.sendForReview()
        try await shot("G06_guardian_sent_please_watch", world) { guardianView(model) }

        let upload = World(script: [.uploadFails(progress: 0.38), .uploadFails(progress: 0.38)])
        let uploadModel = await guardianModel(upload)
        await uploadModel.accept()
        await uploadModel.agreeAndContinue()
        await uploadModel.finishRecording(seconds: 9)
        try await shot("G02_guardian_record_upload_failed", upload) { guardianView(uploadModel) }
        uploadModel.step = .uploading
        try await shot("G02_guardian_record_uploading", upload) { guardianView(uploadModel) }
        uploadModel.step = .checking
        try await shot("G02_guardian_record_checking", upload) { guardianView(uploadModel) }
        await uploadModel.retryUpload()
        await uploadModel.takePhotoInstead()
        try await shot("G05_guardian_photo_and_code", upload) {
            guardianView(uploadModel, typed: "I accept 472", code: "4819")
        }
        upload.at(8, 16, 19, 48)
        await uploadModel.sendPhoto(typed: "I accept 472", phoneCode: "481926")
        try await shot("G06_guardian_sent_photo_and_text", upload) { guardianView(uploadModel) }
    }

    func testCaptureGuardianStatus() async throws {
        let aarav = OutingSeed.aaravRequest.id
        let warden = OutingSeed.wardenAccount
        let world = World()
        try await world.guardianAcceptsByVideo()
        world.at(8, 17, 10, 40)
        _ = try await world.repository.approve(aarav, warden: warden, by: .warden)
        var model = await guardianModel(world)
        try await shot("V5_guardian_status_pass_ready", world) { guardianView(model) }
        world.at(8, 17, 14, 4)
        _ = try await world.repository.recordExit(aarav, by: .gate)
        world.at(8, 17, 17, 10)
        model = await guardianModel(world)
        try await shot("V5_guardian_status_out", world) { guardianView(model) }
        world.at(8, 17, 19, 41)
        _ = try await world.repository.recordReturn(aarav, by: .gate)
        model = await guardianModel(world)
        try await shot("V5_guardian_status_back", world) { guardianView(model) }

        let late = World()
        try await late.guardianAcceptsByVideo()
        late.at(8, 17, 10, 40)
        _ = try await late.repository.approve(aarav, warden: warden, by: .warden)
        late.at(8, 17, 14, 4)
        _ = try await late.repository.recordExit(aarav, by: .gate)
        late.at(8, 17, 20, 40)
        _ = try await late.repository.recordReturn(aarav, by: .gate)
        let lateModel = await guardianModel(late)
        try await shot("V5_guardian_status_back_late", late) { guardianView(lateModel) }

        let no = World()
        try await no.guardianAcceptsByVideo()
        no.at(8, 17, 10, 40)
        _ = try await no.repository.reject(aarav, reason: "Block B has a fire drill on Saturday afternoon",
                                           warden: warden, by: .warden)
        let noModel = await guardianModel(no)
        try await shot("V5_guardian_status_not_going", no) { guardianView(noModel) }

        let change = World(at: OutingSeed.at(8, 16, 19, 41))
        let changeModel = await guardianModel(change)
        await changeModel.askToChange(fields: ["Time"])
        try await shot("V5_guardian_status_change_asked", change) { guardianView(changeModel) }
    }
}
#endif
