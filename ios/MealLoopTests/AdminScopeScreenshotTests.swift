#if DEMO_DATA || REVIEW_DATA
import SwiftUI
import UIKit
import XCTest
@testable import MealLoop

/// Native simulator renders of isolated states, not a claim of a physical-device or tap-through check.
@MainActor final class AdminScopeScreenshotTests: XCTestCase {
    func testCaptureAdminScopes() async throws {
        guard let path = ProcessInfo.processInfo.environment["ADMIN_SCOPES_SHOTS"] else { throw XCTSkip("Opt-in simulator captures") }
        let output = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let core = DemoDataProvider(scenario: .duringMeal)
        let session = try await core.signInStaff(email: "superadmin@mealloop.example", password: DemoSeed.prototypePassword)
        let context = try XCTUnwrap(AdminContext(session: session))
        let env = AppEnvironment(kind: .review, repositories: core.makeRepositories().scopedAdmin(session, mess: context.mess), clock: core.clock, demoControls: nil)
        let nav = AdminNav(context: context, push: { _ in }, pop: {}, toast: { _ in })
        let model = AdminAccessModel(session: session, repository: env.repositories.people)
        await model.load()
        let door = try XCTUnwrap(model.people(.doorScanner).first)
        try await shot("admin_people_00_roles", output, env, AdminAccessView(model: model, nav: nav))
        try await shot("admin_people_01_door_staff", output, env, AdminAccessView(model: model, nav: nav, role: .doorScanner))
        try await shot("admin_people_02_person", output, env, AdminAccessView(model: model, nav: nav, personID: door.id))
        _ = await model.give(door.id)
        try await shot("admin_people_03_give_password", output, env, AdminAccessView(model: model, nav: nav, personID: door.id, initialSheet: .password))
        model.clearPassword()
        try await shot("admin_people_04_invite", output, env, AdminAccessView(model: model, nav: nav, initialSheet: .invite))
        try await shot("admin_people_05_revoke_confirm", output, env, AdminAccessView(model: model, nav: nav, personID: door.id, initiallyConfirming: true))
        try await shot("admin_people_06_allot_mess", output, env, AdminAccessView(model: model, nav: nav, personID: door.id, initialSheet: .allot))
        _ = await model.revoke(door.id)
        try await shot("admin_people_07_person_revoked", output, env, AdminAccessView(model: model, nav: nav, personID: door.id))
        try await shot("superadmin_today", output, env, AdminRootView(session: session), bar: false)
        let head = try await core.signInStaff(email: "foodhead@mealloop.example", password: DemoSeed.prototypePassword)
        let own = try XCTUnwrap(AdminContext(session: head))
        let ownEnv = AppEnvironment(kind: .review, repositories: core.makeRepositories().scopedAdmin(head, mess: own.mess), clock: core.clock, demoControls: nil)
        let ownNav = AdminNav(context: own, push: { _ in }, pop: {}, toast: { _ in })
        try await shot("foodhead_today", output, ownEnv, AdminRootView(session: head), bar: false)
        try await shot("foodhead_students", output, ownEnv, AdminSingleMessStudentsScreen(nav: ownNav))
        try await shot("foodhead_results", output, ownEnv, AdminScopedResultsScreen(nav: ownNav))
        try await shot("foodhead_report", output, ownEnv, AdminSingleMessReportScreen(nav: ownNav))
        try await shot("foodhead_more", output, ownEnv, AdminSingleMessMoreScreen(nav: ownNav))
        try await shot("superadmin_more", output, env, AdminMoreScreen(nav: nav))
    }
    private func shot<V: View>(_ name: String, _ output: URL, _ env: AppEnvironment, _ view: V, bar: Bool = true) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds; window.windowLevel = .alert + 1; window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView:
            ZStack(alignment: .bottom) {
                view
                if bar {
                    GlassTabBar(items: RoleRoot.admin.placeholderTabs.map { title in
                        GlassTabItem(tab: title, title: title, symbol: title == "Today" ? "calendar" : title == "Students" ? "person.2" : title == "Results" ? "chart.bar" : "ellipsis")
                    }, selection: .constant("More"), searchTab: RoleRoot.searchTab)
                    .padding(.horizontal, MLSpacing.s16).padding(.bottom, MLSpacing.s8)
                }
            }.environment(env).environment(AppRouter()).environment(SessionStore()))
        window.makeKeyAndVisible()
        try await Task.sleep(for: .seconds(1.2))
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
        try XCTUnwrap(image.pngData()).write(to: output.appendingPathComponent(name + ".png"))
        window.isHidden = true; window.rootViewController = nil
    }
}
#endif
