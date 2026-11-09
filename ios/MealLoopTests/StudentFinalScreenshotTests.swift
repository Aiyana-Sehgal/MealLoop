#if DEMO_DATA || REVIEW_DATA
import SwiftUI
import UIKit
import XCTest
@testable import MealLoop

/// Captures the Student screens built or changed by the Student final run for docs/verification/student-final/. Each
/// screen is the real view over the prototype backend, pushed onto a navigation stack (so the system bar and back
/// button show as in the app) inside the Student tab bar. Skipped unless TEST_RUNNER_STUDENT_FINAL_SHOTS names a folder.
@MainActor
final class StudentFinalScreenshotTests: XCTestCase {
    private var outputFolder: URL!
    private var device = ""

    @MainActor
    final class World {
        let clock: DemoClock
        let demo: DemoDataProvider
        let environment: AppEnvironment
        let router = AppRouter()
        let store = SessionStore()
        let session: Session

        init(_ scenario: DemoScenario = .storyStart, at now: Date? = nil) {
            clock = DemoClock(DemoSeed.storyStartNow)
            demo = DemoDataProvider(scenario: scenario, clock: clock)
            if let now { clock.set(now) }
            environment = AppEnvironment(kind: .review, repositories: demo.makeRepositories(), clock: clock, demoControls: nil)
            session = Session(account: DemoSeed.accounts.first { $0.role == .student }!, staff: nil,
                              student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
            store.signIn(session)
        }

        var you: StudentYouViewModel {
            StudentYouViewModel(session: session, repositories: environment.repositories, clock: clock)!
        }

        var rewards: StudentRewardsViewModel {
            StudentRewardsViewModel(session: session, repositories: environment.repositories, clock: clock)!
        }

        var spending: StudentSpendingViewModel {
            StudentSpendingViewModel(session: session, repositories: environment.repositories, clock: clock)!
        }
    }

    private enum Pushed: Hashable { case page }

    override func setUp() async throws {
        guard let path = ProcessInfo.processInfo.environment["STUDENT_FINAL_SHOTS"], !path.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_STUDENT_FINAL_SHOTS to capture the Student final screenshots.")
        }
        outputFolder = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        let bounds = UIScreen.main.bounds
        device = "\(Int(bounds.width))x\(Int(bounds.height))"
    }

    /// - Parameters:
    ///   - pushed: true for a page pushed on a tab (system back button); false for a tab root.
    ///   - largestText: the largest accessibility Dynamic Type size.
    ///   - scrolledToEnd: the content scrolled to its end, so a large title has collapsed into the bar.
    func shot<V: View>(_ name: String, _ world: World, tab: StudentTab, pushed: Bool = true, wait: Double = 1.4,
                       largestText: Bool = false, scrolledToEnd: Bool = false,
                       @ViewBuilder _ view: () -> V) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds
        window.windowLevel = .alert + 1
        window.overrideUserInterfaceStyle = .light
        let page = view()
        let stack = NavigationStack(path: .constant(pushed ? [Pushed.page] : [])) {
            Group {
                if pushed { Color.clear } else { page }
            }
            .navigationDestination(for: Pushed.self) { _ in page }
        }
        let framed = ZStack(alignment: .bottom) {
            stack
            GlassTabBar(items: StudentTab.pillTabs.map { GlassTabItem(tab: $0, title: $0.rawValue, symbol: $0.symbol) },
                        selection: .constant(tab), searchTab: .search)
                .padding(.horizontal, MLSpacing.s16)
                .padding(.bottom, MLSpacing.s8)
        }
        .dynamicTypeSize(largestText ? .accessibility5 : .large)
        window.rootViewController = UIHostingController(rootView: framed
            .environment(world.environment).environment(world.router).environment(world.store))
        window.makeKeyAndVisible()
        try await Task.sleep(for: .seconds(wait))
        if scrolledToEnd, let scrollView = scrollViews(in: window).first(where: { $0.contentSize.height > $0.bounds.height }) {
            let end = scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
            scrollView.setContentOffset(CGPoint(x: 0, y: end), animated: false)
            try await Task.sleep(for: .seconds(0.8))
        }
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        try XCTUnwrap(image.pngData()).write(to: outputFolder.appendingPathComponent("\(name)_\(device).png"))
        window.rootViewController?.dismiss(animated: false)
        try await Task.sleep(for: .seconds(0.3))
        window.isHidden = true
        window.rootViewController = nil
    }

    private func scrollViews(in view: UIView) -> [UIScrollView] {
        ((view as? UIScrollView).map { [$0] } ?? []) + view.subviews.flatMap(scrollViews(in:))
    }

    // MARK: - B2c Spending

    func testCaptureSpending() async throws {
        let world = World()
        try await shot("spending_63988", world, tab: .you) { StudentSpendingView(model: world.spending) }
        try await shot("spending_collapsed", world, tab: .you, scrolledToEnd: true) { StudentSpendingView(model: world.spending) }
        try await shot("spending_add_64118", world, tab: .you, wait: 2) {
            StudentSpendingView(model: world.spending, opening: .add)
        }
        let expense = try XCTUnwrap(DemoSeed.sampleExpenses.first { $0.category == .canteen })
        try await shot("spending_edit_64238", world, tab: .you, wait: 2) {
            StudentSpendingView(model: world.spending, opening: .edit(expense))
        }
        let saved = World()
        let model = saved.spending
        _ = await model.save(StudentExpenseDraft(amount: 60, day: saved.clock.now(), category: .canteen, place: nil,
                                                 note: "snacks"), replacing: nil)
        try await shot("spending_saved_64164", saved, tab: .you) { StudentSpendingView(model: model) }
        try await shot("spending_largest_text", world, tab: .you, largestText: true) { StudentSpendingView(model: world.spending) }
        let offline = World(.offline)
        try await shot("spending_offline_65753", offline, tab: .you) { StudentSpendingView(model: offline.spending) }
    }

    // MARK: - B2d Credits Get to the ticket

    func testCaptureCreditsAndTicket() async throws {
        let world = World()
        try await shot("credits_64313", world, tab: .you) {
            StudentCreditsView(model: world.you, rewards: world.rewards, onHistory: {}, onTicket: { _ in })
        }
        let failed = world.rewards
        _ = await failed.get("biryani-coupon")
        try await shot("credits_failed_65873", world, tab: .you) {
            StudentCreditsView(model: world.you, rewards: failed, onHistory: {}, onTicket: { _ in })
        }
        let rewards = world.rewards
        let got = await rewards.get("juice")
        let id = try XCTUnwrap(got)
        try await shot("ticket_juice_1529-1901", world, tab: .you) { StudentRewardTicketView(model: world.rewards, id: id) }
        try await shot("credits_history_after_juice_64443", world, tab: .you) {
            StudentCreditsHistoryView(model: world.you, rewards: world.rewards) {}
        }
        world.clock.set(DemoSeed.time(12, 32))
        _ = try await world.environment.repositories.studentRewards.recordCounterUse(of: id, for: DemoSeed.sampleStudent.id)
        try await shot("ticket_juice_used_1529-2180", world, tab: .you) { StudentRewardTicketView(model: world.rewards, id: id) }
        try await shot("ticket_juice_used_largest_text", world, tab: .you, largestText: true) {
            StudentRewardTicketView(model: world.rewards, id: id)
        }
    }

    // MARK: - B2b Feedback ratings

    func testCaptureRatings() async throws {
        let world = World(.afterMeal)
        let matches = try await world.environment.repositories.studentMeals.findDishes("Steamed Rice", mess: DemoSeed.mess.id)
        let match = try XCTUnwrap(matches.first { $0.slot == .lunch && $0.day >= DemoSeed.time(0, 0) && $0.day <= DemoSeed.time(23, 59) })
        let rice = match.dish
        func rating(_ dish: DishID? = nil) -> StudentRatingViewModel {
            StudentRatingViewModel(session: world.session, repositories: world.environment.repositories,
                                   day: DemoSeed.lunch.startsAt, slot: .lunch, dish: dish)!
        }
        try await shot("rate_meal_how_was_lunch", world, tab: .home) {
            StudentRateMealView(model: rating(), onNotGood: { _ in }) {}
        }
        let meals = StudentMealsViewModel(session: world.session, repositories: world.environment.repositories,
                                          clock: world.clock)!
        try await shot("rate_dish", world, tab: .meals) {
            StudentRateDishView(model: rating(rice.id),
                                loadDish: { try await meals.dishDetail(rice.id, day: match.day, slot: .lunch) },
                                onNotGood: { _ in }) {}
        }
        let good = rating(rice.id)
        _ = await good.rate(.good)
        try await shot("rate_dish_good", world, tab: .meals) {
            StudentRateDishView(model: good,
                                loadDish: { try await meals.dishDetail(rice.id, day: match.day, slot: .lunch) },
                                onNotGood: { _ in }) {}
        }
        try await shot("rate_dish_largest_text", world, tab: .meals, largestText: true) {
            StudentRateDishView(model: rating(rice.id),
                                loadDish: { try await meals.dishDetail(rice.id, day: match.day, slot: .lunch) },
                                onNotGood: { _ in }) {}
        }
        try await shot("report_from_not_good", world, tab: .meals) {
            StudentReportScreen(session: world.session,
                                subject: StudentReportSubject(slot: .lunch, day: DemoSeed.lunch.startsAt, dishName: rice.name)) {}
                .studentPushedPage(usesSystemBar: false)
        }
        let early = World()
        try await shot("rate_meal_not_yet", early, tab: .home) {
            StudentRateMealView(model: StudentRatingViewModel(session: early.session, repositories: early.environment.repositories,
                                                              day: DemoSeed.lunch.startsAt, slot: .lunch)!,
                                onNotGood: { _ in }) {}
        }
        let home = World(at: DemoSeed.time(10, 0))
        try await shot("home_how_was_breakfast_card", home, tab: .home, pushed: false) {
            StudentHomeScreen(session: home.session)
        }
    }

    // MARK: - B2e Special pass use flow (redrawn)

    func testCapturePassUseFlow() async throws {
        let world = World(at: DemoSeed.time(12, 32))
        try await shot("pass_available_redrawn", world, tab: .home) {
            StudentPassScreen(session: world.session) {}
                .studentPushedPage(usesSystemBar: false)
        }
        try await shot("pass_hold_sheet", world, tab: .home, wait: 2) {
            StudentPassScreen(session: world.session) {}
                .studentPushedPage(usesSystemBar: false)
                .mlSheet(isPresented: .constant(true)) {
                    PassHoldSheet(phase: .holding, refusal: nil, tracker: PassHoldTracker(), onUse: {}, onCancel: {})
                }
        }
        try await shot("pass_available_largest_text", world, tab: .home, largestText: true) {
            StudentPassScreen(session: world.session) {}
                .studentPushedPage(usesSystemBar: false)
        }
    }

    // MARK: - B7 Community info

    func testCaptureCommunityInfo() async throws {
        let world = World()
        try await shot("community_info_sheet_1535-114372", world, tab: .community, pushed: false, wait: 2) {
            StudentCommunityScreen(session: world.session)
                .mlSheet(isPresented: .constant(true)) { CommunityInfoSheet {} }
        }
    }

    // MARK: - Standards: pages moved to MLScreen

    func testCaptureStandardsPages() async throws {
        let world = World()
        try await shot("notifications_mlscreen", world, tab: .home) { StudentNotificationsView(model: world.you) {} }
        try await shot("notifications_collapsed", world, tab: .home, scrolledToEnd: true) {
            StudentNotificationsView(model: world.you) {}
        }
        try await shot("attendance_mlscreen", world, tab: .you) { StudentAttendanceView(model: world.you) {} }
        try await shot("attendance_largest_text", world, tab: .you, largestText: true) { StudentAttendanceView(model: world.you) {} }
        try await shot("credits_history_mlscreen", world, tab: .you) {
            StudentCreditsHistoryView(model: world.you, rewards: world.rewards) {}
        }
    }

    // MARK: - Follow-ups P2: next week's pass request

    func testCapturePassRequest() async throws {
        let world = World(.afterMeal)
        try await shot("p2_pass_request", world, tab: .home, wait: 2) {
            StudentPassScreen(session: world.session) {}.studentPushedPage(usesSystemBar: false)
        }
        _ = try await world.environment.repositories.passRequests.request(for: DemoSeed.sampleStudent, at: DemoSeed.mess)
        try await shot("p2_pass_requested", world, tab: .home, wait: 2) {
            StudentPassScreen(session: world.session) {}.studentPushedPage(usesSystemBar: false)
        }
    }

    // MARK: - Follow-ups P4: What happens next

    func testCaptureOutingNextSteps() async throws {
        let world = World()
        let outings = try XCTUnwrap(StudentOutingsViewModel(session: world.session,
                                                            repository: OutingCaseRepositories.studentSource(for: world.environment)))
        await outings.load()
        try await shot("p4_new_outing", world, tab: .you, wait: 2) {
            StudentNewOutingView(model: outings, onSent: { _ in }, onOpen: { _ in }) {}.studentPushedPage(usesSystemBar: false)
        }
        if let first = outings.outings.value?.current.first {
            try await shot("p4_outing_request", world, tab: .you, wait: 2) {
                StudentOutingDetailView(model: outings, id: first.id) {}.studentPushedPage(usesSystemBar: false)
            }
        }
    }
}
#endif
