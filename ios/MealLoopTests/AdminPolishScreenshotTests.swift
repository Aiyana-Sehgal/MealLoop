#if DEMO_DATA || REVIEW_DATA
import SwiftUI
import UIKit
import XCTest
@testable import MealLoop

/// Captures the Admin screens changed by the Admin polish pass for docs/verification/admin-polish/. Real views over the
/// prototype backend, signed in as the all-mess Admin. Skipped unless TEST_RUNNER_ADMIN_POLISH_SHOTS names a folder.
@MainActor
final class AdminPolishScreenshotTests: XCTestCase {
    private var output: URL!

    struct World {
        let core: DemoDataProvider
        let session: Session
        let context: AdminContext
        let env: AppEnvironment
        let nav: AdminNav
    }

    override func setUp() async throws {
        guard let path = ProcessInfo.processInfo.environment["ADMIN_POLISH_SHOTS"], !path.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_ADMIN_POLISH_SHOTS to capture the Admin polish screens.")
        }
        output = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    }

    func world(_ scenario: DemoScenario = .duringMeal) async throws -> World {
        let core = DemoDataProvider(scenario: scenario)
        let session = try await core.signInStaff(email: "superadmin@mealloop.example", password: DemoSeed.prototypePassword)
        let context = try XCTUnwrap(AdminContext(session: session))
        let env = AppEnvironment(kind: .review, repositories: core.makeRepositories().scopedAdmin(session, mess: context.mess),
                                 clock: core.clock, demoControls: nil)
        return World(core: core, session: session, context: context, env: env,
                     nav: AdminNav(context: context, push: { _ in }, pop: {}, toast: { _ in }))
    }

    private enum Pushed: Hashable { case page }

    /// - pushed: on a navigation stack, so the system bar and back button show as in the app.
    func shot<V: View>(_ name: String, _ world: World, pushed: Bool = true, bar: Bool = true, tab: String = "More",
                       wait: Double = 1.4, largestText: Bool = false, @ViewBuilder _ view: () -> V) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds
        window.windowLevel = .alert + 1
        window.overrideUserInterfaceStyle = .light
        let page = view()
        let stack = NavigationStack(path: .constant(pushed ? [Pushed.page] : [])) {
            Group { if pushed { Color.clear } else { page } }
                .navigationDestination(for: Pushed.self) { _ in page }
        }
        let root = ZStack(alignment: .bottom) {
            if pushed { stack } else { page }
            if bar {
                GlassTabBar(items: RoleRoot.admin.placeholderTabs.map { title in
                    GlassTabItem(tab: title, title: title, symbol: title == "Today" ? "calendar" : title == "Students"
                                 ? "person.2" : title == "Results" ? "chart.bar" : "ellipsis")
                }, selection: .constant(tab), searchTab: RoleRoot.searchTab)
                .padding(.horizontal, MLSpacing.s16).padding(.bottom, MLSpacing.s8)
            }
        }
        .dynamicTypeSize(largestText ? .accessibility5 : .large)
        window.rootViewController = UIHostingController(rootView: root
            .environment(world.env).environment(AppRouter()).environment(SessionStore()))
        window.makeKeyAndVisible()
        try await Task.sleep(for: .seconds(wait))
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        try XCTUnwrap(image.pngData()).write(to: output.appendingPathComponent(name + ".png"))
        window.rootViewController?.dismiss(animated: false)
        try await Task.sleep(for: .seconds(0.3))
        window.isHidden = true
        window.rootViewController = nil
    }

    func testCaptureToday() async throws {
        let world = try await world(.storyStart)
        try await shot("today", world, pushed: false, bar: false) { AdminRootView(session: world.session) }
    }

    func testCaptureRemind() async throws {
        let world = try await world(.storyStart)
        try await shot("remind_sheet_2262-237", world, pushed: false, tab: "Students", wait: 2) {
            AdminStudentsView(model: AdminStudentsViewModel(students: world.env.repositories.adminStudents,
                                                            role: world.context.account.role),
                              nav: world.nav, remindOpen: true)
        }
    }

    func testCaptureBuiltPages() async throws {
        let world = try await world(.duringMeal)
        try await shot("votes_2277-2081", world) { AdminVotesScreen(nav: world.nav) }
        try await shot("proposals", world) { AdminProposalsScreen(nav: world.nav) }
        try await shot("proposal_detail", world) { AdminProposalScreen(id: "demo-proposal-dosa-fridays", nav: world.nav) }
        try await shot("redemptions", world) { AdminRedemptionsScreen(nav: world.nav) }
        let today = AdminTodayViewModel(context: world.context, repositories: world.env.repositories, clock: world.core.clock)
        await today.load()
        try await shot("today_see_all", world, tab: "Today") { AdminNeedsYouView(model: today, nav: world.nav) { _ in } }
    }

    func testCaptureSearchAndInvite() async throws {
        let world = try await world(.duringMeal)
        let model = AdminSearchModel(repositories: world.env.repositories, session: world.session,
                                     timeZone: world.context.mess.timeZone)
        try await shot("search_empty", world, pushed: false, tab: "Today") {
            AdminSearchView(model: model, nav: world.nav, openToday: {}, onCancel: {})
        }
        let typed = AdminSearchModel(repositories: world.env.repositories, session: world.session,
                                     timeZone: world.context.mess.timeZone)
        typed.text = "sam"
        try await shot("search_results", world, pushed: false, tab: "Today", wait: 2) {
            AdminSearchView(model: typed, nav: world.nav, openToday: {}, onCancel: {})
        }
        let access = AdminAccessModel(session: world.session, repository: world.env.repositories.people)
        await access.load()
        try await shot("invite_role_page", world, wait: 2) {
            AdminAccessView(model: access, nav: world.nav, role: .doorScanner, initialSheet: .invite)
        }
    }

    func testCaptureRewardsManage() async throws {
        let world = try await world(.duringMeal)
        try await shot("p5_rewards_manage", world, wait: 2) { AdminRewardsScreen(nav: world.nav) }
        try await shot("p5_rewards_add_sheet", world, wait: 2) {
            AdminPageScaffold(title: AdminScreenCopy.rewards) { AdminRewardCatalogueSection(nav: world.nav, addOpen: true) }
        }
    }

    func testCapturePassRequests() async throws {
        let world = try await world(.duringMeal)
        try await shot("p2_admin_passes_requests", world, wait: 2) { AdminPassesScreen(nav: world.nav) }
    }
}
#endif
