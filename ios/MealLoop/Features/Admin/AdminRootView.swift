import SwiftUI

/// The Admin root: Today, Students, Results, More and the round Search (A01). Today is built here;
/// Students, Results and More stay Coming soon until their parts land.
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
    case notImplemented(title: String)
}

private struct AdminTabsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let context: AdminContext

    private let root = RoleRoot.admin
    @State private var selectedTab = RoleRoot.admin.placeholderTabs.first ?? ""
    @State private var todayPath: [AdminRoute] = []

    var body: some View {
        ZStack(alignment: .bottom) {
            if selectedTab == todayTab {
                NavigationStack(path: $todayPath) {
                    AdminTodayScreen(context: context, path: $todayPath) {
                        selectedTab = moreTab
                    }
                }
            } else if selectedTab == RoleRoot.searchTab {
                SearchPlaceholderView(prompt: root.searchPrompt)
            } else {
                NotImplementedView(title: selectedTab, actionTitle: "Sign out") {
                    router.reset()
                    sessionStore.signOut()
                }
            }
            GlassTabBar(items: root.placeholderTabs.map { title in
                GlassTabItem(tab: title, title: title, symbol: symbol(for: title))
            }, selection: $selectedTab, searchTab: RoleRoot.searchTab)
            .padding(.horizontal, MLSpacing.s16)
            .padding(.bottom, MLSpacing.s8)
        }
    }

    private var todayTab: String { root.placeholderTabs.first ?? "" }
    private var moreTab: String { root.placeholderTabs.last ?? "" }

    private func symbol(for title: String) -> String {
        switch title {
        case "Today": return "calendar"
        case "Students": return "person.3"
        case "Results": return "chart.bar"
        default: return "ellipsis"
        }
    }
}
