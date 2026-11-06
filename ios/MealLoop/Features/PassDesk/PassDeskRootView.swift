import SwiftUI

/// The PassDesk root: the staff tabs around this role's Home. Its Home is coming soon until this role's part replaces it here.
struct PassDeskRootView: View {
    let session: Session

    var body: some View {
        StaffRootView(session: session) { staff in
            NotImplementedView(title: MLFormat.roleName(staff.role))
        }
    }
}
