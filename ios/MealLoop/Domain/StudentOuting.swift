import Foundation

// The Student side of the outing journey: the student's own requests and a new request. Additive; `OutingCase` and the
// Guardian, Warden and Gate operations are unchanged. A request enters at Waiting for guardian, and only the guardian,
// the warden and the gate move it on. No timeout approves anything.

/// What the student fills in on New outing (1915:131160).
struct StudentOutingDraft: Codable, Sendable, Hashable {
    let leaveAt: Date
    let returnBy: Date
    let place: String
    /// "Family", "Shopping", "Medical", "Other". Nil when none is picked.
    let reason: String?
    let idempotencyKey: IdempotencyKey
}

/// Whether the student can ask for an outing in the app. Eligibility thresholds are open (P3): a student without a
/// linked guardian, or not enabled, keeps the existing hostel process.
enum StudentOutingEligibility: String, Codable, Sendable, Hashable {
    case enabled
    /// New outing · No guardian (1848:22466).
    case noGuardian
    /// Outings · Not enabled (1848:22321).
    case notEnabled
}

/// A finished outing on the "Earlier" list (You · Outings 1848:22270).
struct StudentPastOuting: Codable, Sendable, Hashable, Identifiable {
    enum Outcome: Codable, Sendable, Hashable {
        /// Back through the gate. `onTime` compares the return with the back-by time.
        case returned(at: Date, onTime: Bool)
        /// "The warden said no".
        case wardenSaidNo
        case guardianSaidNo
    }

    let id: String
    let day: Date
    let reason: String?
    let outcome: Outcome
}

/// The Outings page: what the student can do, the requests still open, and the earlier ones.
struct StudentOutings: Codable, Sendable, Hashable {
    let eligibility: StudentOutingEligibility
    /// Newest first. Requests that are still moving, or a pass not yet used up.
    let current: [OutingCase]
    let earlier: [StudentPastOuting]
}

extension OutingStage {
    /// Nothing more happens to a request in these stages.
    var isFinished: Bool {
        switch self {
        case .returned, .withdrawn, .closed, .guardianRejected, .wardenRejected: return true
        default: return false
        }
    }

    /// The student may cancel only before the gate records an exit.
    var studentCanCancel: Bool {
        switch self {
        case .awaitingGuardian, .guardianCallRequested, .guardianAskedChange, .awaitingWarden, .wardenAskedChange, .passSigned:
            return true
        default:
            return false
        }
    }
}
