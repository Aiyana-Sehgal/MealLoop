import SwiftUI

/// Root routing: Welcome until someone signs in, then that account's own area.
struct AppRootView: View {
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        ZStack(alignment: .top) {
            if let session = sessionStore.current {
                RoleRootView(session: session)
            } else {
                EntryFlowView()
            }
            #if DEMO_DATA
            // Top centre is the one spot free on every screen: Back and the logo sit left, the avatar right,
            // and buttons and the tab bar sit lower down.
            DemoDataBadge()
            #endif
        }
    }
}
