import SwiftUI

/// SOS, opened from "Unsafe or unwell? Use SOS" on the dish feedback sheets. The urgent categories of the report
/// page lead to the camera and raise the SOS (`SOSRepository.raise`).
struct StudentSOSScreen: View {
    let session: Session
    let onClose: () -> Void

    var body: some View {
        StudentReportScreen(session: session, onClose: onClose)
    }
}

/// Lets a pushed page switch the Student tab (Service › Community on Which dish 2159:285).
private struct StudentSelectTabKey: EnvironmentKey {
    static let defaultValue: ((StudentTab) -> Void)? = nil
}

extension EnvironmentValues {
    var studentSelectTab: ((StudentTab) -> Void)? {
        get { self[StudentSelectTabKey.self] }
        set { self[StudentSelectTabKey.self] = newValue }
    }
}
