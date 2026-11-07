#if DEMO_DATA || REVIEW_DATA
import SwiftUI
import UIKit
import XCTest
@testable import MealLoop

/// Captures the six Vendor screens and the offline load for docs/verification/vendor/, on the simulator the tests run on.
/// Each state is reached through the prototype backend's own operations. Skipped unless TEST_RUNNER_VENDOR_SHOTS is set.
@MainActor
final class VendorScreenshotTests: XCTestCase {
    private var outputFolder: URL!

    private final class FailingAcknowledge: HeadcountRepository, @unchecked Sendable {
        let base: any HeadcountRepository
        init(_ base: any HeadcountRepository) { self.base = base }
        func headcount(for meal: MealID) async throws -> Headcount { try await base.headcount(for: meal) }
        func approveHeadcount(_ count: Int, reason: String?, for meal: MealID, by role: Role) async throws -> Headcount {
            try await base.approveHeadcount(count, reason: reason, for: meal, by: role)
        }
        func publishHeadcount(for meal: MealID, by role: Role) async throws -> Headcount { try await base.publishHeadcount(for: meal, by: role) }
        func acknowledgeHeadcount(for meal: MealID, by account: AccountID) async throws -> Headcount {
            throw RepositoryError.offline(lastSavedAt: nil)
        }
    }

    override func setUp() async throws {
        guard let path = ProcessInfo.processInfo.environment["VENDOR_SHOTS"], !path.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_VENDOR_SHOTS to capture the Vendor screens.")
        }
        let device = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? UIDevice.current.model
        outputFolder = URL(fileURLWithPath: path).appendingPathComponent(device.replacingOccurrences(of: " ", with: "_"))
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
    }

    private func shot<V: View>(_ name: String, _ demo: DemoDataProvider, wait: Double = 1.2, @ViewBuilder _ view: () -> V) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds
        window.windowLevel = .alert + 1
        window.overrideUserInterfaceStyle = .light
        let environment = AppEnvironment(kind: .review, repositories: demo.makeRepositories(), clock: demo.clock, demoControls: nil)
        window.rootViewController = UIHostingController(rootView: view()
            .environment(environment).environment(AppRouter()).environment(SessionStore()))
        window.makeKeyAndVisible()
        try await Task.sleep(for: .seconds(wait))
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        try XCTUnwrap(image.pngData()).write(to: outputFolder.appendingPathComponent("\(name).png"))
        window.isHidden = true
        window.rootViewController = nil
    }

    private var account: Account { DemoSeed.accounts.first { $0.role == .vendor }! }

    private func approveAndSend(_ demo: DemoDataProvider) async throws {
        _ = try await demo.approveHeadcount(DemoSeed.forecastDiners, reason: nil, for: DemoSeed.lunch.id, by: .admin)
        _ = try await demo.publishHeadcount(for: DemoSeed.lunch.id, by: .admin)
    }

    func testCaptureVendor() async throws {
        let demo = DemoDataProvider(scenario: .storyStart)
        demo.clock.set(DemoSeed.time(9, 30))
        try await shot("V1_home_waiting", demo) { VendorTabs(account: account, repositories: demo.makeRepositories()) }

        try await approveAndSend(demo)
        try await shot("V2_home_sent", demo) { VendorTabs(account: account, repositories: demo.makeRepositories()) }

        let failing = demo.makeRepositories()
        let broken = Repositories(meals: failing.meals, mealState: failing.mealState, headcount: FailingAcknowledge(failing.headcount),
                                  entries: failing.entries, intentions: failing.intentions, shortages: failing.shortages,
                                  wasteReports: failing.wasteReports, sos: failing.sos, auth: failing.auth, vendor: failing.vendor)
        let failed = VendorHomeViewModel(account: account, repositories: broken)
        await failed.load()
        await failed.acknowledge()
        try await shot("V4_home_could_not_send", demo) { VendorTabs(account: account, repositories: broken, home: failed) }

        demo.clock.set(demo.clock.now().addingTimeInterval(8 * 60))
        _ = try await demo.acknowledgeHeadcount(for: DemoSeed.lunch.id, by: account.id)
        try await shot("V3_home_acknowledged", demo) { VendorTabs(account: account, repositories: demo.makeRepositories()) }
        try await shot("V5_history", demo) { VendorTabs(account: account, repositories: demo.makeRepositories(), path: [.history]) }
        try await shot("V6_me", demo) { VendorTabs(account: account, repositories: demo.makeRepositories(), tab: .me) }

        let offline = DemoDataProvider(scenario: .storyStart)
        let offlineModel = VendorHomeViewModel(account: account, repositories: offline.makeRepositories())
        await offlineModel.load()
        await offline.setScenario(.offline)
        await offlineModel.load()
        try await shot("V7_home_offline", offline) { VendorTabs(account: account, repositories: offline.makeRepositories(), home: offlineModel) }
    }
}
#endif
