import SwiftUI

/// Shows the signed-in account's root. `RoleRoot.destination(for:)` is the only thing that chooses it.
struct RoleRootView: View {
    let session: Session

    var body: some View {
        let root = RoleRoot.destination(for: session.account.role)
        if root.usesStaffTabs, let staff = session.staff {
            StaffTabsView(session: staff)
        } else {
            PlaceholderRootView(root: root, role: session.account.role)
        }
    }
}

/// The chrome of a role whose screens are not built yet. Each destination says so plainly; replace it when
/// that role's part lands. Every tab offers Sign out, so no role is ever a dead end.
struct PlaceholderRootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let root: RoleRoot
    let role: Role
    @State private var selectedTab: String

    init(root: RoleRoot, role: Role) {
        self.root = root
        self.role = role
        _selectedTab = State(initialValue: root.placeholderTabs.first ?? "")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if selectedTab == RoleRoot.searchTab {
                SearchPlaceholderView(prompt: root.searchPrompt)
            } else {
                NotImplementedView(title: selectedTab.isEmpty ? MLFormat.roleName(role) : selectedTab,
                                   detail: "\(MLFormat.roleName(role)) screens are not built yet.",
                                   actionTitle: "Sign out") {
                    router.reset()
                    sessionStore.signOut()
                }
            }
            if !root.placeholderTabs.isEmpty {
                GlassTabBar(items: root.placeholderTabs.map { title in
                    GlassTabItem(tab: title, title: title, symbol: root.showsTabIcons ? symbol(for: title) : nil)
                }, selection: $selectedTab, searchTab: root.hasSearch ? RoleRoot.searchTab : nil)
                .padding(.horizontal, MLSpacing.s16)
                .padding(.bottom, MLSpacing.s8)
            }
        }
    }

    private func symbol(for title: String) -> String {
        switch title {
        case "Home": return "house"
        case "Meals": return "fork.knife"
        case "Community": return "person.2"
        case "You", "Me": return "person.crop.circle"
        case "Today": return "calendar"
        case "Students": return "person.3"
        case "Results": return "chart.bar"
        case "More": return "ellipsis"
        default: return "circle"
        }
    }
}

/// Where Search lands. The designs (student S1 to S5, Admin AD-8c) need recent searches and results that no
/// repository provides yet, so this shows the title and field and says search is not built.
/// It never accepts a query it could not answer.
struct SearchPlaceholderView: View {
    let prompt: String

    var body: some View {
        ZStack {
            OrbitBackground()
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                Text("Search")
                    .font(MLType.largeTitle)
                    .foregroundStyle(MLColor.ink)
                HStack(spacing: MLSpacing.s8) {
                    Image(systemName: "magnifyingglass")
                    Text(prompt)
                    Spacer(minLength: 0)
                }
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .padding(.horizontal, MLSpacing.s16)
                .frame(minHeight: MLSize.hit)
                .background(Capsule().fill(MLColor.track))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Search field, not available yet")
                Text("Search is not built yet.")
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                Spacer()
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.top, MLSpacing.s32)
        }
    }
}
