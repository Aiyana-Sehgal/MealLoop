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
            NotImplementedView(title: selectedTab.isEmpty ? MLFormat.roleName(role) : selectedTab,
                               detail: "\(MLFormat.roleName(role)) screens are not built yet.",
                               actionTitle: "Sign out") {
                router.reset()
                sessionStore.signOut()
            }
            if !root.placeholderTabs.isEmpty {
                CapsuleTabBar(items: root.placeholderTabs.map { title in
                    CapsuleTabItem(tab: title, title: title, symbol: symbol(for: title))
                }, selection: $selectedTab)
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
        case "Queue": return "tray"
        case "Out now": return "figure.walk"
        case "Escalated": return "exclamationmark.triangle"
        case "History": return "clock"
        default: return "circle"
        }
    }
}
