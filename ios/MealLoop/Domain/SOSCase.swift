import Foundation

/// Someone said "I'll go and check". Claiming does not close the case.
struct SOSClaim: Codable, Sendable, Hashable {
    let role: Role
    let at: Date
}

/// "Checked by the door", "Checked by the desk", "Checked by the kitchen" or "Checked by the supervisor".
/// A check does not close the case.
struct SOSCheck: Codable, Sendable, Hashable {
    let role: Role
    let at: Date
}

enum SOSStatus: Codable, Sendable, Hashable {
    case open
    /// Only the Supervisor closes a case in the staff app.
    case closed(at: Date, by: Role)
}

/// An urgent hygiene, contamination or illness report. It never waits for Community voting.
struct SOSCase: Codable, Sendable, Hashable, Identifiable {
    let id: SOSCaseID
    let messID: MessID
    let title: String
    let place: String
    let raisedAt: Date
    var claim: SOSClaim?
    var checks: [SOSCheck]
    var status: SOSStatus

    static let closingRole: Role = .supervisor
}

/// A new SOS from the person who saw the problem. Raising it opens a case for every staff role of the mess.
struct SOSReport: Codable, Sendable, Hashable {
    let messID: MessID
    let title: String
    let place: String
    /// The same key again returns the case already opened, so a retry never opens a second case.
    let idempotencyKey: IdempotencyKey
}
