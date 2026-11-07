#if DEMO_DATA || REVIEW_DATA
import SwiftUI
import UIKit
import XCTest
@testable import MealLoop

/// Captures the Student Notifications, You, Credits, Attendance and Outings screens for
/// docs/verification/student-final-2/. Each screen is the real view over the prototype backend, inside the Student tab
/// bar as the root draws it. Skipped unless TEST_RUNNER_STUDENT_YOU_SHOTS names an output folder.
@MainActor
final class StudentYouScreenshotTests: XCTestCase {
    private var outputFolder: URL!

    @MainActor
    private final class World {
        let clock: DemoClock
        let demo: DemoDataProvider
        let environment: AppEnvironment
        let router = AppRouter()
        let store = SessionStore()
        let session: Session

        init(_ scenario: DemoScenario = .storyStart, repositories: ((Repositories) -> Repositories)? = nil) {
            clock = DemoClock(DemoSeed.storyStartNow)
            demo = DemoDataProvider(scenario: scenario, clock: clock)
            let base = demo.makeRepositories()
            environment = AppEnvironment(kind: .review, repositories: repositories?(base) ?? base, clock: clock, demoControls: nil)
            session = Session(account: DemoSeed.accounts.first { $0.role == .student }!, staff: nil,
                              student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
            store.signIn(session)
        }

        var youModel: StudentYouViewModel {
            StudentYouViewModel(session: session, repositories: environment.repositories, clock: clock)!
        }
    }

    override func setUp() async throws {
        guard let path = ProcessInfo.processInfo.environment["STUDENT_YOU_SHOTS"], !path.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_STUDENT_YOU_SHOTS to capture the Student You screenshots.")
        }
        let device = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? UIDevice.current.model
        outputFolder = URL(fileURLWithPath: path).appendingPathComponent(device.replacingOccurrences(of: " ", with: "_"))
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
    }

    private func shot<V: View>(_ name: String, _ world: World, tab: StudentTab, wait: Double = 1.2,
                               @ViewBuilder _ view: () -> V) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds
        window.windowLevel = .alert + 1
        window.overrideUserInterfaceStyle = .light
        let framed = ZStack(alignment: .bottom) {
            view()
            GlassTabBar(items: StudentTab.pillTabs.map { GlassTabItem(tab: $0, title: $0.rawValue, symbol: $0.symbol) },
                        selection: .constant(tab), searchTab: .search)
                .padding(.horizontal, MLSpacing.s16)
                .padding(.bottom, MLSpacing.s8)
        }
        window.rootViewController = UIHostingController(rootView: framed
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

    func testCaptureYouScreens() async throws {
        let world = World()
        try await shot("notifications_64480", world, tab: .home) { StudentNotificationsView(model: world.youModel) {} }
        try await shot("you_64576", world, tab: .you) { StudentYouView(model: world.youModel, session: world.session) {} }
        try await shot("credits_64313", world, tab: .you) {
            StudentCreditsView(model: world.youModel, onHistory: {}, onGet: { _ in }) {}
        }
        try await shot("credits_history_64443", world, tab: .you) { StudentCreditsHistoryView(model: world.youModel) {} }
        try await shot("attendance_64717", world, tab: .you) { StudentAttendanceView(model: world.youModel) {} }

        let offline = World(.offline)
        try await shot("notifications_offline_66026", offline, tab: .home) { StudentNotificationsView(model: offline.youModel) {} }
        try await shot("you_offline_66111", offline, tab: .you) { StudentYouView(model: offline.youModel, session: offline.session) {} }

        let empty = World { base in
            var repositories = base
            repositories.studentYou = EmptyInbox(base: base.studentYou)
            return repositories
        }
        try await shot("notifications_empty_65955", empty, tab: .home) { StudentNotificationsView(model: empty.youModel) {} }
    }

    /// The same backend with no notifications, for Notifications · Empty.
    private struct EmptyInbox: StudentYouRepository {
        let base: any StudentYouRepository
        func notifications(for student: StudentID) async throws -> [StudentNotification] { [] }
        func markRead(_ id: StudentNotificationID, for student: StudentID) async throws -> StudentNotification {
            try await base.markRead(id, for: student)
        }
        func profile(for student: StudentID, at mess: MessID) async throws -> StudentProfileSummary {
            try await base.profile(for: student, at: mess)
        }
        func credits(for student: StudentID) async throws -> StudentCredits { try await base.credits(for: student) }
        func attendance(for student: StudentID, at mess: MessID) async throws -> StudentAttendanceMonth {
            try await base.attendance(for: student, at: mess)
        }
    }
}
#endif
