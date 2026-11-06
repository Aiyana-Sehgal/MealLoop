#if DEMO_DATA || REVIEW_DATA
import SwiftUI
import UIKit
import XCTest
@testable import MealLoop

/// Captures every Supervisor state on the simulator the tests run on, for docs/verification/supervisor/.
/// Each state is reached through the prototype backend's own operations (start, report, raise, claim, check,
/// resolve, save, close), then the real Supervisor views are hosted in a window and drawn to a PNG.
/// Skipped unless TEST_RUNNER_SUPERVISOR_SHOTS names an output folder, so normal test runs write nothing.
@MainActor
final class SupervisorScreenshotTests: XCTestCase {
    private var outputFolder: URL!
    private var count = 0

    // MARK: World

    @MainActor
    private final class World {
        let clock: DemoClock
        let demo: DemoDataProvider
        let environment: AppEnvironment
        let router = AppRouter()
        let store = SessionStore()
        let session: Session
        let staff: StaffSession

        init(_ scenario: DemoScenario, mess: Mess = DemoSeed.mess, mealState: (any MealStateRepository)? = nil) {
            clock = DemoClock(DemoSeed.storyStartNow)
            demo = DemoDataProvider(scenario: scenario, clock: clock)
            let base = demo.makeRepositories()
            let repositories = Repositories(meals: base.meals, mealState: mealState ?? base.mealState,
                                            headcount: base.headcount, entries: base.entries, intentions: base.intentions,
                                            shortages: base.shortages, wasteReports: base.wasteReports, sos: base.sos,
                                            auth: base.auth)
            environment = AppEnvironment(kind: .review, repositories: repositories, clock: clock, demoControls: nil)
            staff = StaffSession(role: .supervisor, mess: mess, staffInitials: DemoSeed.staffInitials(for: .supervisor),
                                 supervisorName: DemoSeed.supervisorName)
            session = Session(account: DemoSeed.accounts.first { $0.role == .supervisor }!, staff: staff)
            store.signIn(session)
        }

        func at(_ hour: Int, _ minute: Int) { clock.set(DemoSeed.time(hour, minute)) }

        func reportRice() async throws -> Shortage {
            at(13, 30)
            return try await demo.reportShortage(ShortageReport(mealID: DemoSeed.lunch.id, dishName: DemoSeed.shortageDish,
                                                                level: DemoSeed.shortageLevel, note: nil,
                                                                reportedBy: .kitchenStaff, idempotencyKey: IdempotencyKey("rice")))
        }

        func raiseSOS() async throws -> SOSCase {
            clock.set(DemoSeed.sosRaisedAt)
            return try await demo.raise(SOSReport(messID: DemoSeed.mess.id, title: DemoSeed.sosTitle, place: DemoSeed.sosPlace,
                                                  idempotencyKey: IdempotencyKey("sos")))
        }

        func close() async throws {
            _ = try await demo.closeMeal(DemoSeed.lunch.id, by: .supervisor)
        }

        func sosModel() async -> SupervisorSOSModel {
            let model = SupervisorSOSModel(session: staff, repositories: environment.repositories, clock: clock)
            await model.load()
            return model
        }
    }

    /// A meal-state source whose history never answers (loading) or fails (error). Everything else is the demo's.
    private struct HistoryStub: MealStateRepository {
        let base: any MealStateRepository
        let hangs: Bool
        func currentMeal(for mess: MessID) async throws -> MealStatus? { try await base.currentMeal(for: mess) }
        func meals(for mess: MessID) async throws -> [MealStatus] { try await base.meals(for: mess) }
        func startMeal(_ meal: MealID, by role: Role) async throws -> MealStatus { try await base.startMeal(meal, by: role) }
        func closeMeal(_ meal: MealID, by role: Role) async throws -> MealStatus { try await base.closeMeal(meal, by: role) }
        func mealHistory(for mess: MessID) async throws -> [MealRecord] {
            if hangs { try await Task.sleep(for: .seconds(60)) }
            throw RepositoryError.offline(lastSavedAt: nil)
        }
    }

    // MARK: Capture

    override func setUp() async throws {
        guard let path = ProcessInfo.processInfo.environment["SUPERVISOR_SHOTS"], !path.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_SUPERVISOR_SHOTS to capture the Supervisor screenshots.")
        }
        let device = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? UIDevice.current.model
        outputFolder = URL(fileURLWithPath: path).appendingPathComponent(device.replacingOccurrences(of: " ", with: "_"))
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
    }

    private func shot<V: View>(_ name: String, _ world: World, wait: Double = 1.2, @ViewBuilder _ view: () -> V) async throws {
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
        count += 1
    }

    private func root(_ world: World, tab: StaffTab) -> some View {
        world.router.selectedStaffTab = tab
        return SupervisorRootView(session: world.session)
    }

    // MARK: Home and meal control

    func testCaptureHome() async throws {
        // S01 · not started (11:55 AM): forecast, Start meal, Waste not recorded 1, Active shortages 0.
        let before = World(.beforeMeal)
        before.at(11, 55)
        try await shot("S01_home_not_started", before) { root(before, tab: .home) }
        // S14 · Start this meal?
        try await shot("S14_start_meal_dialog", before) {
            Presented(dialog: SupervisorCopy.startDialog(meal: "Lunch", mess: DemoSeed.mess.name)) { root(before, tab: .home) }
        }

        // S02 · in service at 1:40 PM with the kitchen's shortage.
        let during = World(.duringMeal)
        _ = try await during.reportRice()
        during.at(13, 40)
        try await shot("S02_home_in_service", during) { root(during, tab: .home) }
        try await shot("S15_close_meal_dialog", during) {
            Presented(dialog: SupervisorCopy.closeDialog(meal: "Lunch", mess: DemoSeed.mess.name)) { root(during, tab: .home) }
        }

        // S02b · offline after the page loaded: the last values stay, nothing is claimed as saved.
        let offline = World(.duringMeal)
        offline.at(13, 40)
        try await shot("S02b_home_in_service_offline", offline, wait: 2.0) {
            OfflineAfterLoad(goOffline: { await offline.demo.setScenario(.offline) }) { root(offline, tab: .home) }
        }

        // S06 · closed (2:05 PM): final entries 774, Waste not recorded 2, Active shortages 1.
        try await during.close()
        during.at(14, 5)
        try await shot("S06_home_closed", during) { root(during, tab: .home) }

        // S06c · closed, shortage resolved.
        let shortage = try await during.demo.shortages(for: DemoSeed.lunch.id)[0]
        _ = try await during.demo.markResolved(shortage.id, by: .supervisor)
        try await shot("S06c_home_closed_shortage_resolved", during) { root(during, tab: .home) }

        // S06b · the final count did not arrive. The prototype backend always has it after closing, so this one
        // state is drawn from a constructed content (CountReading.unavailable) through the same body.
        let content = SupervisorHomeContent(meal: DemoSeed.lunch, mess: DemoSeed.mess,
                                            phase: .closed(finalEntries: .unavailable, closedAt: DemoSeed.closedAt),
                                            followUps: SupervisorFollowUps(activeShortages: [], wasteNotRecorded: []))
        try await shot("S06b_home_closed_unavailable_constructed", during) {
            SupervisorPage {
                StaffHeader(initials: "RV")
                SupervisorHomeBody(content: content, actionError: nil, onStart: {}, onClose: {}, onFollowUps: {})
            }
        }
    }

    // MARK: SOS

    func testCaptureSOS() async throws {
        let world = World(.duringMeal)
        _ = try await world.reportRice()
        _ = try await world.raiseSOS()
        world.at(13, 40)
        try await shot("S03_home_in_service_sos_tab", world) { root(world, tab: .home) }
        let notTaken = await world.sosModel()
        try await shot("S04_sos_panel_not_taken", world, wait: 1.5) { panel(world, notTaken) }
        try await shot("S08_alerts_with_sos", world) { root(world, tab: .alerts) }

        _ = await notTaken.claim()
        try await shot("S03b_home_sos_claimed_by_you", world) { root(world, tab: .home) }
        try await shot("S04b_sos_panel_claimed_by_you", world, wait: 1.5) { panel(world, notTaken) }

        world.at(13, 48)
        _ = await notTaken.markChecked()
        try await shot("S05b_sos_panel_checked_by_supervisor", world, wait: 1.5) { panel(world, notTaken) }

        _ = await notTaken.close()
        try await shot("S05c_home_case_closed", world) {
            root(world, tab: .home).mlToast(message: .constant(SupervisorCopy.caseClosedToast), bottomInset: 86)
        }

        // S05 · checked by the door at 12:52 PM; only the Supervisor gets Close case.
        let door = World(.duringMeal)
        let sos = try await door.raiseSOS()
        door.at(12, 52)
        _ = try await door.demo.claim(sos.id, by: .doorScanner)
        _ = try await door.demo.markChecked(sos.id, by: .doorScanner)
        door.at(12, 59)
        let checked = await door.sosModel()
        try await shot("S05_sos_panel_checked_close_case", door, wait: 1.5) { panel(door, checked) }
    }

    private func panel(_ world: World, _ model: SupervisorSOSModel) -> some View {
        Sheeted(base: root(world, tab: .home)) {
            SupervisorSOSPanelView(model: model, timeZone: DemoSeed.mess.timeZone, onDismiss: {}, onCaseClosed: {}, onChange: {})
        }
    }

    // MARK: Alerts, shortage, Me

    func testCaptureAlertsShortageAndMe() async throws {
        let before = World(.beforeMeal)
        before.at(11, 55)
        try await shot("S07a_alerts_before_meal", before) { root(before, tab: .alerts) }
        try await shot("S16a_me_before_meal", before) { root(before, tab: .me) }

        let world = World(.duringMeal)
        let rice = try await world.reportRice()
        world.at(13, 40)
        try await shot("S07b_alerts_during_meal", world) { root(world, tab: .alerts) }
        try await shot("S16b_me_during_meal", world) { root(world, tab: .me) }

        try await world.close()
        world.at(14, 5)
        try await shot("S07_alerts_pending", world) { root(world, tab: .alerts) }
        try await shot("S16_me", world) { root(world, tab: .me) }
        try await shot("S17_signout_dialog", world) { Presented(dialog: SupervisorCopy.signOutDialog) { root(world, tab: .me) } }

        world.at(14, 8)
        try await shot("S12_shortage_details", world) { shortage(world, rice.id) }
        try await shot("S13_shortage_resolve_dialog", world) {
            Presented(dialog: SupervisorCopy.resolveDialog(item: rice.dishName)) { shortage(world, rice.id) }
        }

        _ = try await world.demo.markResolved(rice.id, by: .supervisor)
        try await shot("S07c_alerts_shortage_resolved", world) {
            root(world, tab: .alerts).mlToast(message: .constant(SupervisorCopy.shortageResolvedToast), bottomInset: 86)
        }
        try await shot("S16c_me_shortage_resolved", world) { root(world, tab: .me) }

        // S09 · all caught up. In the seed Dinner Tue 13 is never recorded, so the main mess always has one task;
        // this frame uses a mess with no open tasks (see REPORT.md).
        let quiet = World(.afterMeal, mess: Mess(id: MessID("demo-quiet-mess"), name: DemoSeed.mess.name,
                                                 timeZoneIdentifier: DemoSeed.mess.timeZoneIdentifier))
        quiet.at(21, 0)
        try await shot("S09_alerts_empty_other_mess", quiet) { root(quiet, tab: .alerts) }
    }

    private func shortage(_ world: World, _ id: ShortageID) -> some View {
        SupervisorShortageScreen(shortageID: id, staff: world.staff, onBack: {}, onResolved: {})
    }

    // MARK: Waste, history, past meals

    func testCaptureWasteAndHistory() async throws {
        let world = World(.duringMeal)
        let rice = try await world.reportRice()
        try await world.close()
        world.at(14, 5)
        try await shot("S11_waste_report_not_recorded", world) { waste(world, "demo-2024-08-13-dinner") }
        try await shot("S11b_waste_report_lunch_wed_not_recorded", world) { waste(world, DemoSeed.lunch.id.rawValue) }

        world.at(14, 6)
        try await shot("S18_meal_history", world) { history(world) }
        world.at(14, 20)
        try await shot("S19b_past_meal_wed_lunch", world) { past(world, DemoSeed.lunch.id.rawValue) }
        try await shot("S19_past_meal_summary", world) { past(world, "demo-2024-08-13-lunch") }
        try await shot("S19d_past_meal_wed_breakfast", world) { past(world, DemoSeed.breakfast.id.rawValue) }
        try await shot("S19e_past_meal_tue_dinner", world) { past(world, "demo-2024-08-13-dinner") }
        try await shot("S19f_past_meal_mon_dinner_unavailable", world) { past(world, "demo-2024-08-12-dinner") }
        try await shot("S10_waste_report_read_only", world) { waste(world, "demo-2024-08-13-lunch") }
        try await shot("S10b_waste_report_details_closed", world) { waste(world, "demo-2024-08-13-lunch", details: false) }

        _ = try await world.demo.markResolved(rice.id, by: .supervisor)
        try await shot("S18b_meal_history_shortage_resolved", world) { history(world) }
        try await shot("S19c_past_meal_wed_lunch_resolved", world) { past(world, DemoSeed.lunch.id.rawValue) }

        // S10c · the kitchen saves today's report at 2:40 PM (the Kitchen pack's sample) and the Supervisor reads it.
        world.at(14, 40)
        var report = try await world.demo.report(for: DemoSeed.lunch.id)
        let values: [String: LeftoverMeasurement] = [
            "bhindi-aloo-bujjiya": .entered(2), "steamed-rice": .entered(3), "chappathi": .entered(6),
            "muttar-masala": .noneLeft, "veg-pulao": .entered(2.5), "masala-sambar": .entered(4),
            "tomato-dal": .notMade, "garlic-rasam": .entered(3),
        ]
        report.leftovers = report.leftovers.map { var row = $0; row.measurement = values[row.dishID.rawValue] ?? .notEntered; return row }
        report.plateWaste = .entered(kilograms: 18)
        _ = try await world.demo.save(report, by: .kitchenStaff)
        world.at(14, 45)
        try await shot("S10c_waste_report_lunch_wed_recorded", world) { waste(world, DemoSeed.lunch.id.rawValue) }

        // S18c / S18d / S18e · loading, empty and error.
        let loading = World(.afterMeal, mealState: HistoryStub(base: world.demo, hangs: true))
        try await shot("S18c_meal_history_loading", loading, wait: 0.6) { history(loading) }
        let empty = World(.afterMeal, mess: Mess(id: MessID("demo-new-mess"), name: DemoSeed.mess.name,
                                                 timeZoneIdentifier: DemoSeed.mess.timeZoneIdentifier))
        try await shot("S18d_meal_history_empty", empty) { history(empty) }
        let failing = World(.afterMeal, mealState: HistoryStub(base: world.demo, hangs: false))
        try await shot("S18e_meal_history_error_offline", failing) { history(failing) }
    }

    private func waste(_ world: World, _ id: String, details: Bool = true) -> some View {
        SupervisorWasteReportView(model: SupervisorWasteReportViewModel(mealID: MealID(id), session: world.staff,
                                                                        repositories: world.environment.repositories),
                                  showsDetails: details, onBack: {})
    }

    private func history(_ world: World) -> some View {
        SupervisorHistoryScreen(staff: world.staff, onBack: {}, openMeal: { _ in })
    }

    private func past(_ world: World, _ id: String) -> some View {
        SupervisorPastMealScreen(mealID: MealID(id), staff: world.staff, onBack: {}, openReport: {})
    }
}

// MARK: - Presenting helpers (the real modifiers, opened on appear)

private struct Presented<Base: View>: View {
    let dialog: ConfirmDialogContent
    @ViewBuilder let base: Base
    @State private var isShown = false

    var body: some View {
        base
            .mlConfirmDialog(isPresented: $isShown, content: dialog) {}
            .task {
                try? await Task.sleep(for: .milliseconds(500))
                isShown = true
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

/// Loads the page, then the connection drops and the screens reload (S02b).
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
