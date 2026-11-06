import SwiftUI

/// The shared staff pattern: Home, Alerts, Me. Each role's root supplies its own Home; Alerts and Me are placeholders.
struct StaffTabsView<Home: View>: View {
    @Environment(AppRouter.self) private var router
    let session: StaffSession
    @ViewBuilder let home: () -> Home

    var body: some View {
        @Bindable var router = router
        ZStack(alignment: .bottom) {
            Group {
                switch router.selectedStaffTab {
                case .home:
                    NavigationStack(path: $router.staffHomePath) {
                        home()
                            .toolbar(.hidden, for: .navigationBar)
                            .navigationDestination(for: StaffRoute.self) { route in
                                switch route {
                                case .notImplemented(let title):
                                    NotImplementedView(title: title)
                                }
                            }
                    }
                case .alerts:
                    NotImplementedView(title: "Alerts")
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

/// The root of a mess staff role: the shared tabs around that role's own Home.
struct StaffRootView<Home: View>: View {
    let session: Session
    @ViewBuilder let home: (StaffSession) -> Home

    var body: some View {
        if let staff = session.staff {
            StaffTabsView(session: staff) { home(staff) }
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// Placeholder for the Me page (K13, D18, S16). Only "Sign out" works so the flow can be left.
struct StaffMePlaceholderView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let session: StaffSession

    var body: some View {
        NotImplementedView(title: "Me",
                           detail: "\(session.staffInitials) · \(MLFormat.roleName(session.role)) · \(session.mess.name)",
                           actionTitle: "Sign out") {
            router.reset()
            sessionStore.signOut()
        }
    }
}
