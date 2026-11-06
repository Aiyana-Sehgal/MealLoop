import SwiftUI

/// The shared staff pattern: Home, Alerts, Me. Each role supplies its own Home; Alerts and Me are not built yet.
struct StaffTabsView: View {
    @Environment(AppRouter.self) private var router
    let session: StaffSession

    var body: some View {
        @Bindable var router = router
        ZStack(alignment: .bottom) {
            Group {
                switch router.selectedStaffTab {
                case .home:
                    NavigationStack(path: $router.staffHomePath) {
                        StaffHomeSwitch(session: session)
                            .toolbar(.hidden, for: .navigationBar)
                            .navigationDestination(for: StaffRoute.self) { route in
                                switch route {
                                case .notImplemented(let title):
                                    NotImplementedView(title: title)
                                }
                            }
                    }
                case .alerts:
                    NotImplementedView(title: "Alerts",
                                       detail: "Alerts for \(MLFormat.roleName(session.role)) are not built yet.")
                case .me:
                    StaffMePlaceholderView(session: session)
                }
            }
            StaffTabBar(selection: $router.selectedStaffTab)
                .padding(.horizontal, MLSpacing.s16)
                .padding(.bottom, MLSpacing.s8)
        }
    }
}

/// Picks the Home of the signed-in role. Only Kitchen Staff has a Home so far.
struct StaffHomeSwitch: View {
    let session: StaffSession

    var body: some View {
        switch session.role {
        case .kitchenStaff:
            KitchenHomeScreen(session: session)
        default:
            NotImplementedView(title: MLFormat.roleName(session.role),
                               detail: "This role's Home is not built yet.")
        }
    }
}

/// Not implemented: the Me page (K13, D18, S16). Only "Sign out" works so the flow can be left.
struct StaffMePlaceholderView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let session: StaffSession

    var body: some View {
        NotImplementedView(title: "Me",
                           detail: "\(session.staffInitials) · \(MLFormat.roleName(session.role)) · \(session.mess.name). The Me page is not built yet.",
                           actionTitle: "Sign out") {
            router.reset()
            sessionStore.signOut()
        }
    }
}
