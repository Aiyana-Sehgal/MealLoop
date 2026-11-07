import SwiftUI

/// The Admin root: Today, Students, Results, More and the round Search (A01).
struct AdminRootView: View {
    let session: Session

    var body: some View {
        if let context = AdminContext(session: session) {
            AdminTabsView(context: context)
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
    @State private var toast: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            if selectedTab == todayTab {
                NavigationStack(path: $todayPath) {
                    AdminTodayScreen(context: context, path: $todayPath, nav: todayNav) {
                        selectedTab = moreTab
                    }
                }
            } else if selectedTab == RoleRoot.searchTab {
                SearchPlaceholderView(prompt: root.searchPrompt)
            } else if selectedTab == studentsTab {
                tab($studentsPath) { AdminStudentsScreen(nav: $0) }
            } else if selectedTab == resultsTab {
                tab($resultsPath) { AdminResultsScreen(nav: $0) }
            } else {
                tab($morePath) { AdminMoreScreen(nav: $0) }
            }
            GlassTabBar(items: root.placeholderTabs.map { title in
                GlassTabItem(tab: title, title: title, symbol: symbol(for: title))
            }, selection: $selectedTab, searchTab: RoleRoot.searchTab)
            .padding(.horizontal, MLSpacing.s16)
            .padding(.bottom, MLSpacing.s8)
        }
        .mlToast(message: $toast, bottomInset: AdminLayout.tabBarClearance)
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
            case .weeklyReport: AdminWeeklyReportScreen(nav: nav)
            case .feedback(let id): AdminFeedbackScreen(id: id, nav: nav)
            case .community(let id): AdminCommunityScreen(id: id, nav: nav)
            case .skipReasons: AdminSkipReasonsScreen(nav: nav)
            case .weeklyMenu: AdminMenuScreen(nav: nav)
            case .checkDay(let date): AdminCheckDayScreen(date: date, nav: nav)
            case .editDay(let date): AdminEditDayScreen(date: date, nav: nav)
            case .people: AdminPeopleScreen(nav: nav)
            case .peopleRole(let id): AdminRoleScreen(id: id, nav: nav)
            case .announce: AdminAnnounceScreen(nav: nav)
            case .passes: AdminPassesScreen(nav: nav)
            case .votes: AdminVotesScreen(nav: nav)
            case .rewards: AdminRewardsScreen(nav: nav)
            case .spareFood: AdminSpareFoodScreen(nav: nav)
            case .history: AdminHistoryScreen(nav: nav)
            case .outings: AdminOutingsScreen(nav: nav)
            case .messHeadcount(let id, let slot): AdminMessHeadcountScreen(id: id, slot: slot, nav: nav)
            case .notAnswered: AdminNotAnsweredScreen(nav: nav)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
