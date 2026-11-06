import SwiftUI

/// Root routing: Welcome until someone signs in, then that account's own area.
struct AppRootView: View {
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let session = sessionStore.current {
                RoleRootView(session: session)
            } else {
                EntryFlowView()
            }
            #if DEMO_DATA
            DemoDataBadge()
                .padding(.leading, MLSpacing.s16)
                .padding(.bottom, 96)
            #endif
        }
    }
}
