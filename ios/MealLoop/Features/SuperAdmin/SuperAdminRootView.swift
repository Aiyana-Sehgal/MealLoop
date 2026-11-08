import SwiftUI

/// Super Admin uses the all-mess Admin presentation; Food Head retains the single-mess mode.
struct SuperAdminRootView: View {
    let session: Session
    var body: some View { AdminRootView(session: session) }
}
