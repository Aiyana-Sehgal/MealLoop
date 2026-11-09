import SwiftUI

/// The Admin root: Today, Students, Results, More and the round Search (A01).
struct AdminRootView: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session

    var body: some View {
        if let context = AdminContext(session: session) {
            AdminTabsView(context: context)
                .environment(AppEnvironment(kind: environment.kind, repositories: environment.repositories.scopedAdmin(session, mess: context.mess), clock: environment.clock, demoControls: environment.demoControls))
        } else {
            PlaceholderRootView(root: .admin, role: .admin)
        }
    }
}

/// Pushed screens inside the Today tab.
enum AdminRoute: Hashable {
    case headcount
    case live
    case page(AdminPage)
    /// Today › See all: every row that needs the admin (admin_today_01_see_all in the design brief).
    case needsYou
    case notImplemented(title: String)
}

private struct AdminTabsView: View {
    let context: AdminContext

    private let root = RoleRoot.admin
    @State private var selectedTab = RoleRoot.admin.placeholderTabs.first ?? ""
    @State private var todayPath: [AdminRoute] = []
    @State private var studentsPath: [AdminPage] = []
    @State private var resultsPath: [AdminPage] = []
    @State private var morePath: [AdminPage] = []
    @State private var searchPath: [AdminPage] = []
    /// Where Cancel on Search returns to.
    @State private var lastTab = RoleRoot.admin.placeholderTabs.first ?? ""
    @State private var toast: String?
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        ZStack(alignment: .bottom) {
            if selectedTab == todayTab {
                NavigationStack(path: $todayPath) {
                    AdminTodayScreen(context: context, path: $todayPath, nav: todayNav) {
                        selectedTab = moreTab
                    }
                }
            } else if selectedTab == RoleRoot.searchTab {
                tab($searchPath) { nav in
                    AdminSearchView(model: AdminSearchModel(repositories: environment.repositories,
                                                            session: Session(account: context.account, staff: nil),
                                                            timeZone: context.mess.timeZone),
                                    nav: nav, openToday: { selectedTab = todayTab }, onCancel: { selectedTab = lastTab })
                }
            } else if selectedTab == studentsTab {
                tab($studentsPath) { nav in
                    if context.allMesses { AdminStudentsScreen(nav: nav) } else { AdminSingleMessStudentsScreen(nav: nav) }
                }
            } else if selectedTab == resultsTab {
                tab($resultsPath) { nav in
                    if context.allMesses { AdminResultsScreen(nav: nav) } else { AdminScopedResultsScreen(nav: nav) }
                }
            } else {
                tab($morePath) { nav in
                    if context.allMesses { AdminMoreScreen(nav: nav) } else { AdminSingleMessMoreScreen(nav: nav) }
                }
            }
            if !isEditingDay {
                // Scroll edge fade (2262:22): rows dissolve before they reach the tab bar.
                LinearGradient(colors: [MLColor.canvas.opacity(0), MLColor.canvas], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.6))
                    .frame(height: AdminLayout.scrollFadeHeight)
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                GlassTabBar(items: root.placeholderTabs.map { title in
                    GlassTabItem(tab: title, title: title, symbol: symbol(for: title))
                }, selection: $selectedTab, searchTab: RoleRoot.searchTab)
                .padding(.horizontal, MLSpacing.s16)
                .padding(.bottom, MLSpacing.s8)
                .onChange(of: selectedTab) { old, _ in
                    if old != RoleRoot.searchTab { lastTab = old }
                }
            }
        }
        .mlToast(message: $toast, bottomInset: AdminLayout.tabBarClearance)
    }

    /// The Edit day frames (2313:6 and family) have no tab bar: the page holds its own Save.
    private var isEditingDay: Bool {
        guard selectedTab == moreTab, case .editDay? = morePath.last else { return false }
        return true
    }

    /// Today's pages share the other tabs' screens, so a meal or a case opens the same page from anywhere.
    private var todayNav: AdminNav {
        AdminNav(context: context, push: { todayPath.append(.page($0)) }, pop: { _ = todayPath.popLast() }, toast: { toast = $0 })
    }

    private func tab<Root: View>(_ path: Binding<[AdminPage]>, @ViewBuilder root: @escaping (AdminNav) -> Root) -> some View {
        let nav = AdminNav(context: context, push: { path.wrappedValue.append($0) },
                           pop: { _ = path.wrappedValue.popLast() }, toast: { toast = $0 })
        return NavigationStack(path: path) {
            root(nav)
                .navigationDestination(for: AdminPage.self) { AdminPageDestination(page: $0, nav: nav) }
        }
    }

    private var todayTab: String { root.placeholderTabs.first ?? "" }
    private var studentsTab: String { root.placeholderTabs.dropFirst().first ?? "" }
    private var resultsTab: String { root.placeholderTabs.dropFirst(2).first ?? "" }
    private var moreTab: String { root.placeholderTabs.last ?? "" }

    private func symbol(for title: String) -> String {
        switch title {
        case "Today": return "calendar"
        case "Students": return "person.2"
        case "Results": return "chart.bar"
        default: return "ellipsis"
        }
    }
}

struct AdminPageDestination: View {
    let page: AdminPage
    let nav: AdminNav

    var body: some View {
        Group {
            switch page {
            case .reason(let kind): AdminReasonScreen(kind: kind, nav: nav)
            case .meal(let meal): AdminMealReportScreen(meal: meal, nav: nav)
            case .check(let check): AdminCheckScreen(check: check, nav: nav)
            case .findMeal: AdminFindMealScreen(nav: nav)
            case .safetyCases: AdminSafetyCasesScreen(nav: nav)
            case .safetyCase(let id): AdminSafetyCaseScreen(id: id, nav: nav)
            case .weeklyReport:
                if nav.context.allMesses { AdminWeeklyReportScreen(nav: nav) } else { AdminSingleMessReportScreen(nav: nav) }
            case .feedback(let id): AdminFeedbackScreen(id: id, nav: nav)
            case .community(let id): AdminCommunityScreen(id: id, nav: nav)
            case .skipReasons: AdminSkipReasonsScreen(nav: nav)
            case .weeklyMenu: AdminMenuScreen(nav: nav)
            case .checkDay(let date): AdminCheckDayScreen(date: date, nav: nav)
            case .editDay(let date): AdminEditDayScreen(date: date, nav: nav)
            case .people: AdminAccessScreen(nav: nav)
            case .peopleRole(let id): AdminAccessScreen(nav: nav, role: Role(rawValue: id))
            case .accessPerson(let id): AdminAccessScreen(nav: nav, personID: id)
            case .announce: AdminAnnounceScreen(nav: nav)
            case .passes: AdminPassesScreen(nav: nav)
            case .votes: AdminVotesScreen(nav: nav)
            case .rewards: AdminRewardsScreen(nav: nav)
            case .spareFood: AdminSpareFoodScreen(nav: nav)
            case .history: AdminHistoryScreen(nav: nav)
            case .outings: AdminOutingsScreen(nav: nav)
            case .messHeadcount(let id, let slot): AdminMessHeadcountScreen(id: id, slot: slot, nav: nav)
            case .notAnswered: AdminNotAnsweredScreen(nav: nav)
            case .proposals: AdminProposalsScreen(nav: nav)
            case .proposal(let id): AdminProposalScreen(id: id, nav: nav)
            case .redemptions: AdminRedemptionsScreen(nav: nav)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
