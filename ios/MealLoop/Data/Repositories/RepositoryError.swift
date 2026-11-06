import Foundation

/// Errors every repository may throw. Screens map them to LoadState (failed, offline).
enum RepositoryError: Error, Equatable, Sendable {
    /// The feature has no implementation yet (every Remote repository today). Never faked as success.
    case notImplemented(feature: String)
    /// No connection or the data could not be verified. Nothing was recorded.
    case offline(lastSavedAt: Date?)
    case notFound
    /// The email or password is wrong. Never says which, so an email cannot be probed.
    case invalidCredentials
    /// The action is not allowed in the current state or for this role.
    case notAllowed(reason: String)
    case validationFailed([String])
}
