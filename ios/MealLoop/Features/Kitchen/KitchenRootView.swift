import SwiftUI

/// The Kitchen root: the staff tabs around this role's Home. Kitchen Home is built; its part adds the rest here.
struct KitchenRootView: View {
    let session: Session

    var body: some View {
        StaffRootView(session: session) { staff in
            KitchenHomeScreen(session: staff)
        }
    }
}
