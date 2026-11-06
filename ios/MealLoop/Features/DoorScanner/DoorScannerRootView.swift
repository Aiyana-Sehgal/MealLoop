import SwiftUI

/// The DoorScanner root: the staff tabs around this role's Home. Its Home is coming soon until this role's part replaces it here.
struct DoorScannerRootView: View {
    let session: Session

    var body: some View {
        StaffRootView(session: session) { staff in
            NotImplementedView(title: MLFormat.roleName(staff.role))
        }
    }
}
