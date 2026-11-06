import Foundation
import Observation

/// The signed-in session. One instance, made at the composition root. Nothing about an account is kept on the device.
@Observable
final class SessionStore {
    private(set) var current: Session?

    func signIn(_ session: Session) {
        current = session
    }

    func signOut() {
        current = nil
    }
}
