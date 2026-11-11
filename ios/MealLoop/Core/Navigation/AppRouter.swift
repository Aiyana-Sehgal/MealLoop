import Foundation
import Observation

/// Pushed screens before sign-in.
/// Students: Welcome (221:62499) → Getting your details (135:15587) → Home; a failure is Couldn't sign in (135:15825)
/// with Try again.
/// Mess staff: Welcome → Staff sign in, which is Choose your role (1508:235) → What you do (sheet) → Password
/// (2469:2102) → role Home. Accounts that are not mess staff (Food Head, Super Admin, Vendor, Guardian, Warden, Gate)
/// use "Sign in with email" on Choose your role.
enum EntryRoute: Hashable, Sendable {
    case chooseRole
    case emailSignIn
    case srmSignIn
    case rolePassword(Role)
}

/// The shared staff tab pattern: Home, Alerts, Me. There is no fourth tab.
enum StaffTab: String, CaseIterable, Identifiable, Hashable, Sendable {
    case home
    case alerts
    case me

    var id: String { rawValue }
}

/// Pushed screens inside a staff tab. Add cases here as screens are built; keep one enum for all staff roles.
enum StaffRoute: Hashable, Sendable {
    case notImplemented(title: String)
}

/// Navigation state only. Who is signed in lives in `SessionStore`.
@Observable
final class AppRouter {
    var entryPath: [EntryRoute] = []
    var selectedStaffTab: StaffTab = .home
    var staffHomePath: [StaffRoute] = []

    /// Clears every path, so the next account never inherits the previous account's position.
    func reset() {
        entryPath = []
        selectedStaffTab = .home
        staffHomePath = []
    }
}
