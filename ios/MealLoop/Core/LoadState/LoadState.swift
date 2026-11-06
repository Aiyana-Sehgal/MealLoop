import Foundation

/// Why a load failed, in words a screen can show.
struct LoadFailure: Error, Equatable, Sendable {
    let message: String
    /// True when the data source has no implementation yet (labelled "Coming soon", not "Error").
    let isNotImplemented: Bool

    init(message: String, isNotImplemented: Bool = false) {
        self.message = message
        self.isNotImplemented = isNotImplemented
    }

    init(_ error: Error) {
        switch error {
        case RepositoryError.notImplemented(let feature):
            self.init(message: "\(feature) isn't available yet", isNotImplemented: true)
        case RepositoryError.notAllowed(let reason):
            self.init(message: reason)
        case RepositoryError.notFound:
            self.init(message: "We couldn't find this.")
        case RepositoryError.validationFailed(let problems):
            self.init(message: problems.joined(separator: " "))
        default:
            self.init(message: "Something went wrong. Try again.")
        }
    }
}

/// Every screen loads through these states, so loading, empty, error, stale and offline look the same everywhere.
enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(LoadFailure)
    /// Data shown may be out of date ("Updated 1:12 PM · reconnecting").
    case stale(Value, asOf: Date)
    /// No connection. The last saved value, if any, is shown under the offline banner. Nothing is claimed as saved.
    case offline(Value?, savedAt: Date?)

    var value: Value? {
        switch self {
        case .loaded(let value), .stale(let value, _): return value
        case .offline(let value, _): return value
        case .idle, .loading, .empty, .failed: return nil
        }
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

extension LoadState: Equatable where Value: Equatable {}
