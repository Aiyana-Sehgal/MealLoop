import Foundation
import Observation

/// Pushed screens before sign-in: Welcome → Staff sign in, or Welcome → Sign in with SRM.
enum EntryRoute: Hashable, Sendable {
    case staffSignIn
    case srmSignIn
}

#if DEMO_DATA
/// Routes inside the retired role selection flow. Debug only; nothing opens it (see StaffEntryViews.swift).
enum StaffEntryRoute: Hashable, Sendable {
    case password(Role)
}
#endif

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
    #if DEMO_DATA
    var staffEntryPath: [StaffEntryRoute] = []
    #endif

    /// Clears every path, so the next account never inherits the previous account's position.
    func reset() {
        entryPath = []
        selectedStaffTab = .home
        staffHomePath = []
        #if DEMO_DATA
        staffEntryPath = []
        #endif
    }
}
