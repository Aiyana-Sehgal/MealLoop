import SwiftUI

/// Root routing: Welcome until someone signs in, then that account's own area.
/// In Debug and Review the Demo sheet hangs here, so a role switch inside it never tears the sheet's host down.
struct AppRootView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(DemoMenu.self) private var demoMenu

    var body: some View {
        @Bindable var demoMenu = demoMenu
        Group {
            if let session = sessionStore.current {
                // A new account is a fresh root: no tab, path or sheet of the previous role survives.
                RoleRootView(session: session)
                    .id(session.account.id)
            } else {
                EntryFlowView()
            }
        }
        #if DEMO_DATA || REVIEW_DATA
        .sheet(isPresented: $demoMenu.isPresented) {
            DemoSheet()
        }
        #endif
    }
}
