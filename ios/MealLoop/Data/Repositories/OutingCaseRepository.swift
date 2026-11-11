import Foundation

// The outing operations the Guardian, Warden and Gate screens use. Additive: the empty `OutingRepository` stub in
// Repositories.swift is left alone, and `Repositories` is unchanged, so no existing call site moves.
// Every write names the role that makes it; the data source refuses any other role and any step out of order.

/// A fresh challenge for one recording try: the phrase and a random 3-digit code, new for every try (spec step 3).
struct CaptureChallenge: Sendable, Hashable {
    let outing: OutingRequestID
    /// 1, 2 or 3.
    let attempt: Int
    let attemptsAllowed: Int
    /// Three digits, made fresh for this try.
    let code: String
    /// "I accept Aarav's outing."
    let phrase: String
    /// The seconds a video must last, and the most it may last (spec: 4 to 10).
    let minimumSeconds: Int
    let maximumSeconds: Int
}

/// What happened to one recorded video.
enum VideoSubmissionResult: Sendable, Hashable {
    /// The phrase and the code matched: sent to the warden as "Video, auto-checked".
    case sent(OutingCase)
    /// Under the minimum length. The try is not used up.
    case tooShort
    /// The check did not hear the phrase and the code. `nextAttempt` is nil when no tries are left.
    case notMatched(heard: String, missing: String, nextAttempt: Int?)
    /// The upload did not finish. `retriesLeft` counts the upload tries left before the photo path.
    case uploadFailed(progress: Double, retriesLeft: Int)
}

/// The photo path after the video could not upload (G05): a live photo, the typed phrase and a code sent by SMS.
struct PhotoChallenge: Sendable, Hashable {
    let outing: OutingRequestID
    /// "I accept 472": the text the guardian types exactly.
    let typedPhrase: String
    /// Where the 6-digit code was sent, masked.
    let sentTo: String?
    let codeLength: Int
}

/// What the gate sees after a scan or a typed code (GA-3, GA-6).
enum GateCheck: Sendable, Hashable {
    case exitReady(OutingCase)
    case returnReady(OutingCase)
    /// Not a MealLoop outing pass.
    case notValid
    case alreadyUsed(OutingCase)
    case withdrawn(OutingCase)
    case tooEarly(OutingCase)
    case tooLate(OutingCase)
}

/// The gate's record of an exit or a return, with the count of students out after it.
struct GateRecord: Sendable, Hashable {
    let outing: OutingCase
    let outNowCount: Int
}

enum GateProblem: String, Sendable, Hashable, CaseIterable {
    case scannerNotWorking
    case crowdAtTheGate
    case somethingElse
}

struct GateProblemReport: Sendable, Hashable {
    let problem: GateProblem
    let sentAt: Date
}

/// The gate home's numbers (GA-1). Each is counted from the records, never typed in.
struct GateOverview: Sendable, Hashable {
    let post: GatePost
    let typedCodesToday: Int
    let outNow: Int
    let overdue: Int
}

protocol OutingCaseRepository: Sendable {
    /// The time the outing screens show. In the prototype it is the outing story clock.
    func now() async -> Date
    /// Opens a role's screens. The prototype moves its story clock forward to the moment that role is drawn at
    /// (it never runs backwards); a real backend changes nothing.
    func begin(as role: Role) async throws

    // MARK: Guardian (G00–G08, G-3)
    func guardianLink(for guardian: AccountID) async throws -> GuardianLink
    /// The newest request for the guardian's student.
    func guardianRequest(for guardian: AccountID) async throws -> OutingCase?
    func guardianPastAnswers(for guardian: AccountID) async throws -> [GuardianPastAnswer]
    func hasConsented(_ guardian: AccountID) async throws -> Bool
    /// G00 "I understand and agree". Recording is refused until this is given.
    func recordConsent(_ guardian: AccountID, by role: Role) async throws
    /// A new random code for the next try. Refused before consent, after the reply time and after an answer.
    func startCapture(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> CaptureChallenge
    func submitVideo(_ challenge: CaptureChallenge, seconds: Int, guardian: AccountID, by role: Role) async throws
        -> VideoSubmissionResult
    /// After the third failed check: the last video goes to the warden as "please watch" (G04).
    func sendVideoForReview(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> OutingCase
    func startPhotoFallback(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> PhotoChallenge
    func submitPhoto(_ outing: OutingRequestID, typed: String, phoneCode: String, guardian: AccountID, by role: Role)
        async throws -> OutingCase
    /// No working camera: the warden phones the guardian (G02 camera blocked). Never an approval.
    func requestWardenCall(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> OutingCase
    /// One tap, no video, optional reason (G08).
    func rejectAsGuardian(_ outing: OutingRequestID, reason: String?, guardian: AccountID, by role: Role) async throws
        -> OutingCase
    func askStudentToChange(_ outing: OutingRequestID, fields: [String], guardian: AccountID, by role: Role) async throws
        -> OutingCase
    /// Before the student has left. Cancels the request.
    func withdrawApproval(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> OutingCase

    // MARK: Warden (W01–W04, WV-5), own block only
    func wardenProfile(for warden: AccountID) async throws -> WardenProfile
    /// Waiting for this warden, closest deadline first.
    func wardenQueue(for warden: AccountID) async throws -> [OutingCase]
    func wardenOutNow(for warden: AccountID) async throws -> [OutingCase]
    func wardenEscalated(for warden: AccountID) async throws -> [OutingCase]
    func wardenHistory(for warden: AccountID) async throws -> [WardenHistoryItem]
    func outing(_ outing: OutingRequestID, for warden: AccountID) async throws -> OutingCase
    /// Records the guardian's answer given by phone ("Confirmed by call"). The note is required.
    func recordGuardianCall(_ outing: OutingRequestID, note: String, warden: AccountID, by role: Role) async throws
        -> OutingCase
    /// Signs the pass. Only after the guardian accepted.
    func approve(_ outing: OutingRequestID, warden: AccountID, by role: Role) async throws -> OutingCase
    func askForChange(_ outing: OutingRequestID, fields: [String], note: String?, warden: AccountID, by role: Role)
        async throws -> OutingCase
    /// A reason is required.
    func reject(_ outing: OutingRequestID, reason: String, warden: AccountID, by role: Role) async throws -> OutingCase
    /// Only for a request past its deadline. Never an approval.
    func closeRequest(_ outing: OutingRequestID, warden: AccountID, by role: Role) async throws -> OutingCase
    /// Takes back the last decision while nothing has happened since (the pass is unused).
    func undoDecision(_ outing: OutingRequestID, warden: AccountID, by role: Role) async throws -> OutingCase

    // MARK: Gate (GA-1–GA-9)
    func gateOverview(by role: Role) async throws -> GateOverview
    /// Checks a typed pass code. It records nothing.
    func checkPassCode(_ code: String, by role: Role) async throws -> GateCheck
    /// Checks the pass of a request already found (Find student, Out now). It records nothing.
    func checkPass(of outing: OutingRequestID, by role: Role) async throws -> GateCheck
    func findStudent(srmID: String, by role: Role) async throws -> [OutingCase]
    func recordExit(_ outing: OutingRequestID, by role: Role) async throws -> GateRecord
    func recordReturn(_ outing: OutingRequestID, by role: Role) async throws -> GateRecord
    /// Students out through this gate, back-by time first.
    func gateOutNow(by role: Role) async throws -> [OutingCase]
    func gateOverdue(by role: Role) async throws -> [OutingCase]
    func reportGateProblem(_ problem: GateProblem, by role: Role) async throws -> GateProblemReport
}

/// The not-yet-built backend. Every call throws `notImplemented`; nothing is faked as success.
struct RemoteOutingCaseRepository: OutingCaseRepository {
    private func missing(_ feature: String) -> RepositoryError { .notImplemented(feature: "Remote · \(feature)") }

    func now() async -> Date { Date() }
    func begin(as role: Role) async throws { throw missing("outings") }
    func guardianLink(for guardian: AccountID) async throws -> GuardianLink { throw missing("guardian link") }
    func guardianRequest(for guardian: AccountID) async throws -> OutingCase? { throw missing("guardian request") }
    func guardianPastAnswers(for guardian: AccountID) async throws -> [GuardianPastAnswer] { throw missing("past answers") }
    func hasConsented(_ guardian: AccountID) async throws -> Bool { throw missing("consent") }
    func recordConsent(_ guardian: AccountID, by role: Role) async throws { throw missing("consent") }
    func startCapture(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> CaptureChallenge {
        throw missing("video capture")
    }
    func submitVideo(_ challenge: CaptureChallenge, seconds: Int, guardian: AccountID, by role: Role) async throws
        -> VideoSubmissionResult { throw missing("video check") }
    func sendVideoForReview(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> OutingCase {
        throw missing("send video")
    }
    func startPhotoFallback(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> PhotoChallenge {
        throw missing("photo and code")
    }
    func submitPhoto(_ outing: OutingRequestID, typed: String, phoneCode: String, guardian: AccountID, by role: Role)
        async throws -> OutingCase { throw missing("photo and code") }
    func requestWardenCall(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> OutingCase {
        throw missing("warden call")
    }
    func rejectAsGuardian(_ outing: OutingRequestID, reason: String?, guardian: AccountID, by role: Role) async throws
        -> OutingCase { throw missing("guardian reject") }
    func askStudentToChange(_ outing: OutingRequestID, fields: [String], guardian: AccountID, by role: Role) async throws
        -> OutingCase { throw missing("ask to change") }
    func withdrawApproval(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> OutingCase {
        throw missing("withdraw approval")
    }
    func wardenProfile(for warden: AccountID) async throws -> WardenProfile { throw missing("warden profile") }
    func wardenQueue(for warden: AccountID) async throws -> [OutingCase] { throw missing("warden queue") }
    func wardenOutNow(for warden: AccountID) async throws -> [OutingCase] { throw missing("out now") }
    func wardenEscalated(for warden: AccountID) async throws -> [OutingCase] { throw missing("escalated") }
    func wardenHistory(for warden: AccountID) async throws -> [WardenHistoryItem] { throw missing("history") }
    func outing(_ outing: OutingRequestID, for warden: AccountID) async throws -> OutingCase { throw missing("outing") }
    func recordGuardianCall(_ outing: OutingRequestID, note: String, warden: AccountID, by role: Role) async throws
        -> OutingCase { throw missing("record call") }
    func approve(_ outing: OutingRequestID, warden: AccountID, by role: Role) async throws -> OutingCase {
        throw missing("approve")
    }
    func askForChange(_ outing: OutingRequestID, fields: [String], note: String?, warden: AccountID, by role: Role)
        async throws -> OutingCase { throw missing("ask for change") }
    func reject(_ outing: OutingRequestID, reason: String, warden: AccountID, by role: Role) async throws -> OutingCase {
        throw missing("reject")
    }
    func closeRequest(_ outing: OutingRequestID, warden: AccountID, by role: Role) async throws -> OutingCase {
        throw missing("close request")
    }
    func undoDecision(_ outing: OutingRequestID, warden: AccountID, by role: Role) async throws -> OutingCase {
        throw missing("undo")
    }
    func gateOverview(by role: Role) async throws -> GateOverview { throw missing("gate") }
    func checkPassCode(_ code: String, by role: Role) async throws -> GateCheck { throw missing("pass check") }
    func checkPass(of outing: OutingRequestID, by role: Role) async throws -> GateCheck { throw missing("pass check") }
    func findStudent(srmID: String, by role: Role) async throws -> [OutingCase] { throw missing("find student") }
    func recordExit(_ outing: OutingRequestID, by role: Role) async throws -> GateRecord { throw missing("record exit") }
    func recordReturn(_ outing: OutingRequestID, by role: Role) async throws -> GateRecord { throw missing("record return") }
    func gateOutNow(by role: Role) async throws -> [OutingCase] { throw missing("out now") }
    func gateOverdue(by role: Role) async throws -> [OutingCase] { throw missing("overdue") }
    func reportGateProblem(_ problem: GateProblem, by role: Role) async throws -> GateProblemReport {
        throw missing("report a problem")
    }
}

/// Hands the outing screens their data source. `AppEnvironment` and `Repositories` are shared files, so the outing
/// source is kept beside them, one per environment: seeded in Debug and Review, the remote stub everywhere else.
@MainActor
enum OutingCaseRepositories {
    private static var sources: [ObjectIdentifier: any OutingCaseRepository] = [:]

    static func source(for environment: AppEnvironment) -> any OutingCaseRepository {
        let key = ObjectIdentifier(environment)
        if let existing = sources[key] { return existing }
        let made = makeSource(for: environment)
        sources[key] = made
        return made
    }

    /// Lets a test or a screenshot run supply its own source for an environment.
    static func register(_ source: any OutingCaseRepository, for environment: AppEnvironment) {
        sources[ObjectIdentifier(environment)] = source
    }

    private static func makeSource(for environment: AppEnvironment) -> any OutingCaseRepository {
        #if DEMO_DATA || REVIEW_DATA
        switch environment.kind {
        case .demo, .review:
            guard let clock = environment.clock as? any StoryClock else { return InMemoryOutingCaseRepository() }
            return InMemoryOutingCaseRepository.app(clock: clock)
        case .api: return RemoteOutingCaseRepository()
        }
        #else
        return RemoteOutingCaseRepository()
        #endif
    }
}
