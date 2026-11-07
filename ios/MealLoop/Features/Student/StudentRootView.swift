import SwiftUI

/// The Student tabs, plus Search, which is selected like a tab.
enum StudentTab: String, CaseIterable, Hashable {
    case home = "Home"
    case meals = "Meals"
    case community = "Community"
    case you = "You"
    case search

    /// The four tabs in the pill. Search has its own round button.
    static let pillTabs: [StudentTab] = [.home, .meals, .community, .you]

    var symbol: String {
        switch self {
        case .home: return "house"
        case .meals: return "fork.knife"
        case .community: return "person.2"
        case .you: return "person.crop.circle"
        case .search: return "magnifyingglass"
        }
    }
}

/// The Student root. Home, Meals and Search are built; Community and You belong to a later part and stay Coming soon.
struct StudentRootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let session: Session
    @State private var tab: StudentTab = .home
    /// Where Back on Search returns to.
    @State private var lastTab: StudentTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            switch tab {
            case .home:
                StudentHomeScreen(session: session)
            case .meals:
                StudentMealsScreen(session: session)
            case .search:
                StudentSearchScreen(session: session) { tab = lastTab }
            case .community, .you:
                NotImplementedView(title: tab.rawValue, actionTitle: "Sign out") {
                    router.reset()
                    sessionStore.signOut()
                }
            }
            GlassTabBar(items: StudentTab.pillTabs.map { GlassTabItem(tab: $0, title: $0.rawValue, symbol: $0.symbol) },
                        selection: $tab, searchTab: .search)
                .onChange(of: tab) { old, _ in
                    if old != .search { lastTab = old }
                }
                .padding(.horizontal, MLSpacing.s16)
                .padding(.bottom, MLSpacing.s8)
        }
    }
}
