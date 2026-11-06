import Foundation

// The outing journey as the Guardian, Warden and Gate screens read it (design/reference/guardian_2026-10/data/
// guardian_video_spec.md): student request → guardian decision → warden decision → signed pass → gate exit → gate return.
// Additive: `OutingState` in Outing.swift stays as it is. This file adds the records those screens need (who answered,
// how, the pass and the gate times) and a stage machine with the call path the spec draws.
// Nothing here moves a request forward because time passed: a missed deadline only escalates it to a person.

/// A student as the outing roles see them: first name and masked ID only, never the full ID.
struct OutingStudent: Codable, Sendable, Hashable {
    let id: StudentID
    /// Nil when the reference shows only a masked ID ("Student ·3471", GA-7).
    let firstName: String?
    /// "••0238" or "·3471", exactly as drawn.
    let maskedID: String
    /// Nil when the reference draws no avatar for this student.
    let initials: String?
    /// "Block B". Nil when the reference does not say.
    let block: String?
    /// The SRM ID, only where a reference shows one (GA-5).
    let srmID: String?

    /// "Aarav ••0238", or "Student ·3471" when no name is known.
    var displayName: String {
        if let firstName { return "\(firstName) \(maskedID)" }
        return "Student \(maskedID)"
    }
}

/// One automatic check on the guardian's evidence (W01: Phrase, Code, Number).
enum EvidenceCheck: String, Codable, Sendable, Hashable, CaseIterable {
    case phrase
    case code
    case number
}

/// What the guardian's answer was captured with. Evidence, not proof: it never says who the person is.
struct OutingEvidence: Codable, Sendable, Hashable {
    let method: GuardianEvidenceMethod
    /// Nil when the reference gives no time.
    let capturedAt: Date?
    /// Length of the video in seconds, when there is one.
    let videoSeconds: Int?
    /// What the check heard ("I accept Aarav's outing, code 4 7 2"), or the typed text for a photo.
    let transcript: String?
    /// The checks that passed. Empty for "please watch".
    let passedChecks: [EvidenceCheck]
    /// The number the warden phoned, for "Confirmed by call".
    let calledNumber: String?
    /// The warden's note after the call (required on that path).
    let callNote: String?
    /// When the video or photo is deleted (the draft retention period). Nil when nothing was recorded.
    let deletesAt: Date?

    /// The face is always captured, except on the call path, which the warden records.
    var capturesGuardianFace: Bool { method != .confirmedByCall }
}

/// The guardian's own answer. There is no text-only accept: accepting always carries evidence.
enum GuardianAnswer: Codable, Sendable, Hashable {
    case accepted(OutingEvidence)
    /// One tap, with an optional reason chip. No video.
    case rejected(reason: String?)
    /// The camera did not work; the warden phones the guardian. Not an approval.
    case callRequested
    /// The guardian asked the student to change the request (G01 Ask to change).
    case changeAsked(fields: [String])
}

struct GuardianAnswerRecord: Codable, Sendable, Hashable {
    let answer: GuardianAnswer
    /// Nil when the reference gives no time.
    let at: Date?
}

/// What the warden decided (W01).
enum WardenDecisionKind: String, Codable, Sendable, Hashable {
    /// Approve signs the pass.
    case approved
    case changeAsked
    case rejected
    /// Closed after a missed deadline (W04 "Close the request"). Never an approval.
    case closed
}

struct WardenDecision: Codable, Sendable, Hashable {
    let kind: WardenDecisionKind
    let at: Date
    /// The reason chip on No, or the change chips on Ask.
    let reasons: [String]
    let note: String?
}

/// Where a request is. Only the operations below move it, one step at a time.
enum OutingStage: String, Codable, Sendable, Hashable {
    case awaitingGuardian
    case guardianCallRequested
    case guardianAskedChange
    case guardianRejected
    case awaitingWarden
    case wardenAskedChange
    case wardenRejected
    case passSigned
    case out
    case returned
    case withdrawn
    case closed
}

/// The signed pass. It exists only after the warden approved.
struct OutingPass: Codable, Sendable, Hashable {
    /// The 4-character code under the QR (GA-4).
    let code: String
    let signedAt: Date
}

/// Why a request needs a person now (W04). Derived from the request and the time; it never changes the stage.
enum OutingEscalation: Sendable, Hashable {
    case pastDeadline(since: Date)
    case pleaseWatch
    case noCamera
}

struct OutingCase: Codable, Sendable, Hashable, Identifiable {
    let id: OutingRequestID
    let student: OutingStudent
    /// Nil wherever the reference does not draw the value. Missing data is shown as missing, never invented.
    let place: String?
    let reason: String?
    let leaveAt: Date?
    let returnBy: Date?
    let guardianReplyBy: Date?
    let wardenDecideBy: Date?
    /// Masked, as drawn ("+91 98••• ••214").
    let guardianPhone: String?
    /// A pass code the reference draws for this request (7F3K). Nil means one is made when the pass is signed.
    let seededPassCode: String?
    /// "Past answers: 3 by video" on W01, by method. Empty when the reference draws none.
    let pastAnswerCounts: [GuardianEvidenceMethod: Int]

    var stage: OutingStage
    var guardianAnswer: GuardianAnswerRecord?
    var wardenDecision: WardenDecision?
    var pass: OutingPass?
    var exitAt: Date?
    /// The gate that recorded the exit ("Main Gate").
    var exitGate: String?
    var returnAt: Date?
    var withdrawnAt: Date?
    var withdrawnBy: Role?

    var evidence: OutingEvidence? {
        if case .accepted(let evidence)? = guardianAnswer?.answer { return evidence }
        return nil
    }

    /// True once a gate exit is recorded. An approval alone never says the student left.
    var hasLeft: Bool { stage == .out || stage == .returned }

    func isLate(at now: Date) -> Bool {
        guard let returnBy else { return false }
        switch stage {
        case .out: return now > returnBy
        case .returned: return (returnAt ?? now) > returnBy
        default: return false
        }
    }

    /// Why this request needs a person at `now`, or nil. Time can escalate a request; it never approves one.
    func escalation(at now: Date) -> OutingEscalation? {
        switch stage {
        case .guardianCallRequested:
            return .noCamera
        case .awaitingGuardian:
            if let guardianReplyBy, now > guardianReplyBy { return .pastDeadline(since: guardianReplyBy) }
            return nil
        case .awaitingWarden:
            if let wardenDecideBy, now > wardenDecideBy { return .pastDeadline(since: wardenDecideBy) }
            if evidence?.method == .videoNeedsReview { return .pleaseWatch }
            return nil
        default:
            return nil
        }
    }
}

/// A past warden decision kept for History (W03). Seeded past entries and live decisions read the same way.
struct WardenHistoryItem: Sendable, Hashable, Identifiable {
    enum Outcome: String, Sendable, Hashable {
        case approved
        case changeAsked
        case rejected
        case guardianSaidNo
        case closed
    }

    let id: String
    let student: OutingStudent
    let outcome: Outcome
    /// The day the decision belongs to.
    let decidedOn: Date
    /// Nil when the reference draws only the day.
    let decidedAtTime: Date?
    /// How the guardian answered. Nil means no video (the guardian said no).
    let method: GuardianEvidenceMethod?
    let place: String?
    let leaveAt: Date?
    let returnBy: Date?
    let passCode: String?
    let evidence: OutingEvidence?
}

/// One line of the guardian's Past answers (G07).
struct GuardianPastAnswer: Sendable, Hashable, Identifiable {
    enum Kind: String, Sendable, Hashable {
        case accepted
        case rejected
    }

    let id: String
    let place: String?
    let day: Date
    let kind: Kind
    /// Nil for a one-tap reject.
    let method: GuardianEvidenceMethod?
}

/// Who the guardian account is linked to (G01 "Verified as Aarav's guardian"). Comes from the seeded account only:
/// production guardian authentication is not decided.
struct GuardianLink: Sendable, Hashable {
    let guardian: AccountID
    let student: OutingStudent
    let phone: String?
}

/// The warden's own profile (WV-5 Me).
struct WardenProfile: Sendable, Hashable {
    let title: String
    let initials: String
    let staffID: String?
    let block: String
    let blockStudents: Int?
    let hoursFrom: Date?
    let hoursTo: Date?
    let escalationsGoTo: String?
}

/// The gate post (GA-1).
struct GatePost: Sendable, Hashable {
    let name: String
    let shiftName: String
    let shiftStartedAt: Date?
}
