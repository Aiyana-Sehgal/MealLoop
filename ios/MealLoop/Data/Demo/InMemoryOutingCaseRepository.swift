#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SIMULATED: what the prototype's automatic check and upload do for one try. No camera, upload or speech-to-text
/// runs in this app; the outcome stands in for the server (spec steps 4 to 6).
enum SimulatedCaptureOutcome: Sendable, Hashable {
    case matched
    case notMatched(heard: String, missing: String)
    case uploadFails(progress: Double)
}

/// Chooses the simulated outcome for a recording try and an upload try (both start at 1).
protocol OutingCaptureSimulation: Sendable {
    func outcome(attempt: Int, uploadTry: Int) -> SimulatedCaptureOutcome
}

/// The prototype's default: every upload arrives and every check matches. The other outcomes are reached by tests
/// and screenshot runs that pass their own simulation.
struct MatchingCaptureSimulation: OutingCaptureSimulation {
    func outcome(attempt: Int, uploadTry: Int) -> SimulatedCaptureOutcome { .matched }
}

/// A fixed list of outcomes, one per call, then `.matched`. For tests and screenshots.
final class ScriptedCaptureSimulation: OutingCaptureSimulation, @unchecked Sendable {
    private let lock = NSLock()
    private var script: [SimulatedCaptureOutcome]

    init(_ script: [SimulatedCaptureOutcome]) {
        self.script = script
    }

    func outcome(attempt: Int, uploadTry: Int) -> SimulatedCaptureOutcome {
        lock.lock()
        defer { lock.unlock() }
        return script.isEmpty ? .matched : script.removeFirst()
    }
}

/// The seeded outing source for Debug and Review. It enforces the order of the journey: the guardian answers first,
/// then the warden, then the gate records the exit and the return. A missed deadline escalates a request to a
/// person and never approves it.
actor InMemoryOutingCaseRepository: OutingCaseRepository {
    private let clock: any StoryClock
    private let simulation: any OutingCaptureSimulation
    private let makeDigits: @Sendable (Int) -> String
    private let makePassCode: @Sendable () -> String

    private var cases: [OutingRequestID: OutingCase] = [:]
    private var order: [OutingRequestID] = []
    private var seededHistory: [WardenHistoryItem]
    private var seededPastAnswers: [GuardianPastAnswer]
    private var links: [AccountID: GuardianLink]
    private var wardens: [AccountID: WardenProfile]
    private var consented: Set<AccountID> = []
    private var failedChecks: [OutingRequestID: Int] = [:]
    private var failedUploads: [OutingRequestID: Int] = [:]
    private var challenges: [OutingRequestID: CaptureChallenge] = [:]
    private var lastVideo: [OutingRequestID: (heard: String?, seconds: Int)] = [:]
    private var phoneCodes: [OutingRequestID: String] = [:]
    private var undoSnapshots: [OutingRequestID: OutingCase] = [:]
    private var typedCodes = 0
    /// Every Find student lookup, with its time (GA-5: "every lookup is recorded").
    private(set) var lookups: [(srmID: String, at: Date)] = []
    private var offline = false

    init(clock: any StoryClock = DemoClock(OutingSeed.guardianMoment),
         cases: [OutingCase] = OutingSeed.cases,
         history: [WardenHistoryItem] = OutingSeed.wardenHistory,
         pastAnswers: [GuardianPastAnswer] = OutingSeed.guardianPastAnswers,
         links: [GuardianLink] = [OutingSeed.guardianLink],
         wardens: [AccountID: WardenProfile] = [OutingSeed.wardenAccount: OutingSeed.wardenProfile],
         simulation: any OutingCaptureSimulation = MatchingCaptureSimulation(),
         makeDigits: @escaping @Sendable (Int) -> String = InMemoryOutingCaseRepository.randomDigits,
         makePassCode: @escaping @Sendable () -> String = InMemoryOutingCaseRepository.randomPassCode) {
        self.clock = clock
        self.simulation = simulation
        self.makeDigits = makeDigits
        self.makePassCode = makePassCode
        self.seededHistory = history
        self.seededPastAnswers = pastAnswers
        self.links = Dictionary(uniqueKeysWithValues: links.map { ($0.guardian, $0) })
        self.wardens = wardens
        for item in cases {
            self.cases[item.id] = item
            self.order.append(item.id)
        }
    }

    static func randomDigits(_ count: Int) -> String {
        String((0..<count).map { _ in Character(String(Int.random(in: 0...9))) })
    }

    /// Four characters from letters and digits that cannot be misread (no O, 0, I, 1).
    static func randomPassCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<4).map { _ in alphabet[Int.random(in: 0..<alphabet.count)] })
    }

    // MARK: Test hooks

    func setOffline(_ isOffline: Bool) { offline = isOffline }

    // MARK: Clock

    func now() async -> Date { clock.now() }

    func begin(as role: Role) async throws {
        switch role {
        case .guardian: clock.advance(to: OutingSeed.guardianMoment)
        case .warden: clock.advance(to: OutingSeed.wardenMoment)
        case .gate: clock.advance(to: OutingSeed.gateMoment)
        default: throw RepositoryError.notAllowed(reason: "Outings are for the guardian, the warden and the gate.")
        }
    }

    // MARK: Guards

    private func require(_ role: Role, is expected: Role) throws {
        guard role == expected else {
            throw RepositoryError.notAllowed(reason: "Only the \(MLFormat.roleName(expected).lowercased()) can do this.")
        }
        if offline { throw RepositoryError.offline(lastSavedAt: nil) }
    }

    private func link(_ guardian: AccountID) throws -> GuardianLink {
        guard let link = links[guardian] else {
            throw RepositoryError.notAllowed(reason: "This account is not linked to a student.")
        }
        return link
    }

    private func guardianCase(_ id: OutingRequestID, _ guardian: AccountID) throws -> OutingCase {
        let link = try link(guardian)
        guard let item = cases[id], item.student.id == link.student.id else { throw RepositoryError.notFound }
        return item
    }

    /// The request is still open for the guardian's first answer: waiting, and the reply time has not passed.
    private func openForGuardian(_ item: OutingCase) throws {
        guard item.stage == .awaitingGuardian else {
            throw RepositoryError.notAllowed(reason: "This request already has an answer.")
        }
        if let replyBy = item.guardianReplyBy, clock.now() > replyBy {
            throw RepositoryError.notAllowed(reason: "The reply time has passed.")
        }
    }

    private func profile(_ warden: AccountID) throws -> WardenProfile {
        guard let profile = wardens[warden] else {
            throw RepositoryError.notAllowed(reason: "This account is not a block warden.")
        }
        return profile
    }

    private func wardenCase(_ id: OutingRequestID, _ warden: AccountID) throws -> OutingCase {
        let block = try profile(warden).block
        guard let item = cases[id], item.student.block == block else { throw RepositoryError.notFound }
        return item
    }

    private func save(_ item: OutingCase) -> OutingCase {
        cases[item.id] = item
        return item
    }

    private func deletionDate(from date: Date) -> Date {
        date.addingTimeInterval(TimeInterval(OutingSeed.videoRetentionDays) * 24 * 60 * 60)
    }

    // MARK: Guardian

    func guardianLink(for guardian: AccountID) async throws -> GuardianLink {
        if offline { throw RepositoryError.offline(lastSavedAt: nil) }
        return try link(guardian)
    }

    func guardianRequest(for guardian: AccountID) async throws -> OutingCase? {
        if offline { throw RepositoryError.offline(lastSavedAt: nil) }
        let student = try link(guardian).student.id
        return order.compactMap { cases[$0] }.last { $0.student.id == student }
    }

    func guardianPastAnswers(for guardian: AccountID) async throws -> [GuardianPastAnswer] {
        if offline { throw RepositoryError.offline(lastSavedAt: nil) }
        let student = try link(guardian).student.id
        let live: [GuardianPastAnswer] = order.compactMap { cases[$0] }.filter { $0.student.id == student }.compactMap {
            guard let record = $0.guardianAnswer, let day = record.at ?? $0.leaveAt else { return nil }
            switch record.answer {
            case .accepted(let evidence):
                return GuardianPastAnswer(id: $0.id.rawValue, place: $0.place, day: $0.leaveAt ?? day, kind: .accepted,
                                          method: evidence.method)
            case .rejected:
                return GuardianPastAnswer(id: $0.id.rawValue, place: $0.place, day: $0.leaveAt ?? day, kind: .rejected,
                                          method: nil)
            case .callRequested, .changeAsked:
                return nil
            }
        }
        return (live + seededPastAnswers).sorted { $0.day > $1.day }
    }

    func hasConsented(_ guardian: AccountID) async throws -> Bool {
        _ = try link(guardian)
        return consented.contains(guardian)
    }

    func recordConsent(_ guardian: AccountID, by role: Role) async throws {
        try require(role, is: .guardian)
        _ = try link(guardian)
        consented.insert(guardian)
    }

    func startCapture(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> CaptureChallenge {
        try require(role, is: .guardian)
        let item = try guardianCase(outing, guardian)
        try openForGuardian(item)
        guard consented.contains(guardian) else {
            throw RepositoryError.notAllowed(reason: "Read and agree before you record.")
        }
        let failed = failedChecks[outing, default: 0]
        guard failed < OutingSeed.recordingTries else {
            throw RepositoryError.notAllowed(reason: "No more tries left.")
        }
        let name = item.student.firstName ?? item.student.displayName
        let challenge = CaptureChallenge(outing: outing, attempt: failed + 1, attemptsAllowed: OutingSeed.recordingTries,
                                         code: makeDigits(3), phrase: "I accept \(name)'s outing.",
                                         minimumSeconds: OutingSeed.minimumVideoSeconds,
                                         maximumSeconds: OutingSeed.maximumVideoSeconds)
        challenges[outing] = challenge
        failedUploads[outing] = 0
        return challenge
    }

    func submitVideo(_ challenge: CaptureChallenge, seconds: Int, guardian: AccountID, by role: Role) async throws
        -> VideoSubmissionResult {
        try require(role, is: .guardian)
        var item = try guardianCase(challenge.outing, guardian)
        try openForGuardian(item)
        // Only the newest code counts, so an old or replayed video fails.
        guard challenges[challenge.outing] == challenge else {
            throw RepositoryError.notAllowed(reason: "This code is no longer valid. Record again.")
        }
        guard seconds >= challenge.minimumSeconds else { return .tooShort }
        guard seconds <= challenge.maximumSeconds else {
            throw RepositoryError.validationFailed(["A video lasts at most \(challenge.maximumSeconds) seconds."])
        }
        let uploadTry = failedUploads[challenge.outing, default: 0] + 1
        switch simulation.outcome(attempt: challenge.attempt, uploadTry: uploadTry) {
        case .uploadFails(let progress):
            failedUploads[challenge.outing] = uploadTry
            return .uploadFailed(progress: progress, retriesLeft: max(0, OutingSeed.uploadTries - uploadTry))
        case .notMatched(let heard, let missing):
            let failed = failedChecks[challenge.outing, default: 0] + 1
            failedChecks[challenge.outing] = failed
            lastVideo[challenge.outing] = (heard, seconds)
            challenges[challenge.outing] = nil
            return .notMatched(heard: heard, missing: missing,
                               nextAttempt: failed < OutingSeed.recordingTries ? failed + 1 : nil)
        case .matched:
            let now = clock.now()
            let spoken = challenge.code.map(String.init).joined(separator: " ")
            let phrase = challenge.phrase.hasSuffix(".") ? String(challenge.phrase.dropLast()) : challenge.phrase
            let evidence = OutingEvidence(method: .liveVideoAutoChecked, capturedAt: now, videoSeconds: seconds,
                                          transcript: "\(phrase), code \(spoken)", passedChecks: EvidenceCheck.allCases,
                                          calledNumber: nil, callNote: nil, deletesAt: deletionDate(from: now))
            item.guardianAnswer = GuardianAnswerRecord(answer: .accepted(evidence), at: now)
            item.stage = .awaitingWarden
            challenges[challenge.outing] = nil
            return .sent(save(item))
        }
    }

    func sendVideoForReview(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> OutingCase {
        try require(role, is: .guardian)
        var item = try guardianCase(outing, guardian)
        try openForGuardian(item)
        guard failedChecks[outing, default: 0] >= OutingSeed.recordingTries, let video = lastVideo[outing] else {
            throw RepositoryError.notAllowed(reason: "Record again first. The video goes as it is only after 3 tries.")
        }
        let now = clock.now()
        let evidence = OutingEvidence(method: .videoNeedsReview, capturedAt: now, videoSeconds: video.seconds,
                                      transcript: video.heard, passedChecks: [], calledNumber: nil, callNote: nil,
                                      deletesAt: deletionDate(from: now))
        item.guardianAnswer = GuardianAnswerRecord(answer: .accepted(evidence), at: now)
        item.stage = .awaitingWarden
        return save(item)
    }

    func startPhotoFallback(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> PhotoChallenge {
        try require(role, is: .guardian)
        let item = try guardianCase(outing, guardian)
        try openForGuardian(item)
        guard failedUploads[outing, default: 0] >= OutingSeed.uploadTries, let challenge = challenges[outing] else {
            throw RepositoryError.notAllowed(reason: "The photo is used only after the video failed to upload twice.")
        }
        phoneCodes[outing] = makeDigits(OutingSeed.phoneCodeLength)
        return PhotoChallenge(outing: outing, typedPhrase: "I accept \(challenge.code)", sentTo: item.guardianPhone,
                              codeLength: OutingSeed.phoneCodeLength)
    }

    func submitPhoto(_ outing: OutingRequestID, typed: String, phoneCode: String, guardian: AccountID, by role: Role)
        async throws -> OutingCase {
        try require(role, is: .guardian)
        var item = try guardianCase(outing, guardian)
        try openForGuardian(item)
        guard let challenge = challenges[outing], let expectedCode = phoneCodes[outing] else {
            throw RepositoryError.notAllowed(reason: "Take a photo first.")
        }
        let expected = "I accept \(challenge.code)"
        let normalized = typed.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        var problems: [String] = []
        if normalized.caseInsensitiveCompare(expected) != .orderedSame { problems.append("Type exactly: \(expected)") }
        if phoneCode != expectedCode { problems.append("The code from your phone does not match.") }
        guard problems.isEmpty else { throw RepositoryError.validationFailed(problems) }
        let now = clock.now()
        let evidence = OutingEvidence(method: .photoAndText, capturedAt: now, videoSeconds: nil, transcript: expected,
                                      passedChecks: [.code, .number], calledNumber: nil, callNote: nil,
                                      deletesAt: deletionDate(from: now))
        item.guardianAnswer = GuardianAnswerRecord(answer: .accepted(evidence), at: now)
        item.stage = .awaitingWarden
        challenges[outing] = nil
        phoneCodes[outing] = nil
        return save(item)
    }

    func requestWardenCall(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> OutingCase {
        try require(role, is: .guardian)
        var item = try guardianCase(outing, guardian)
        try openForGuardian(item)
        item.guardianAnswer = GuardianAnswerRecord(answer: .callRequested, at: clock.now())
        item.stage = .guardianCallRequested
        return save(item)
    }

    func rejectAsGuardian(_ outing: OutingRequestID, reason: String?, guardian: AccountID, by role: Role) async throws
        -> OutingCase {
        try require(role, is: .guardian)
        var item = try guardianCase(outing, guardian)
        try openForGuardian(item)
        item.guardianAnswer = GuardianAnswerRecord(answer: .rejected(reason: reason), at: clock.now())
        item.stage = .guardianRejected
        return save(item)
    }

    func askStudentToChange(_ outing: OutingRequestID, fields: [String], guardian: AccountID, by role: Role) async throws
        -> OutingCase {
        try require(role, is: .guardian)
        var item = try guardianCase(outing, guardian)
        try openForGuardian(item)
        guard !fields.isEmpty else { throw RepositoryError.validationFailed(["Choose what should change."]) }
        item.guardianAnswer = GuardianAnswerRecord(answer: .changeAsked(fields: fields), at: clock.now())
        item.stage = .guardianAskedChange
        return save(item)
    }

    func withdrawApproval(_ outing: OutingRequestID, guardian: AccountID, by role: Role) async throws -> OutingCase {
        try require(role, is: .guardian)
        var item = try guardianCase(outing, guardian)
        guard item.evidence != nil, item.stage == .awaitingWarden || item.stage == .passSigned else {
            throw RepositoryError.notAllowed(reason: "There is no approval to withdraw.")
        }
        item.stage = .withdrawn
        item.withdrawnAt = clock.now()
        item.withdrawnBy = .guardian
        undoSnapshots[outing] = nil
        return save(item)
    }

    // MARK: Warden

    func wardenProfile(for warden: AccountID) async throws -> WardenProfile {
        if offline { throw RepositoryError.offline(lastSavedAt: nil) }
        return try profile(warden)
    }

    private func blockCases(_ warden: AccountID) throws -> [OutingCase] {
        let block = try profile(warden).block
        return order.compactMap { cases[$0] }.filter { $0.student.block == block }
    }

    func wardenQueue(for warden: AccountID) async throws -> [OutingCase] {
        if offline { throw RepositoryError.offline(lastSavedAt: nil) }
        return try blockCases(warden).filter { $0.stage == .awaitingWarden }
            .sorted { ($0.wardenDecideBy ?? .distantFuture) < ($1.wardenDecideBy ?? .distantFuture) }
    }

    func wardenOutNow(for warden: AccountID) async throws -> [OutingCase] {
        if offline { throw RepositoryError.offline(lastSavedAt: nil) }
        let now = clock.now()
        return try blockCases(warden).filter { $0.stage == .out }.sorted {
            let late0 = $0.isLate(at: now), late1 = $1.isLate(at: now)
            if late0 != late1 { return late0 }
            return ($0.returnBy ?? .distantFuture) < ($1.returnBy ?? .distantFuture)
        }
    }

    func wardenEscalated(for warden: AccountID) async throws -> [OutingCase] {
        if offline { throw RepositoryError.offline(lastSavedAt: nil) }
        let now = clock.now()
        func rank(_ item: OutingCase) -> Int {
            switch item.escalation(at: now) {
            case .pastDeadline?: return 0
            case .pleaseWatch?: return 1
            case .noCamera?: return 2
            case nil: return 3
            }
        }
        func since(_ item: OutingCase) -> Date {
            if case .pastDeadline(let since)? = item.escalation(at: now) { return since }
            return item.wardenDecideBy ?? .distantFuture
        }
        // Past deadline first (longest overdue first), then "please watch", then the calls to make.
        return try blockCases(warden).filter { $0.escalation(at: now) != nil }.sorted {
            rank($0) != rank($1) ? rank($0) < rank($1) : since($0) < since($1)
        }
    }

    func wardenHistory(for warden: AccountID) async throws -> [WardenHistoryItem] {
        if offline { throw RepositoryError.offline(lastSavedAt: nil) }
        let block = try profile(warden).block
        let live: [WardenHistoryItem] = try blockCases(warden).compactMap { item in
            let outcome: WardenHistoryItem.Outcome
            let at: Date
            if let decision = item.wardenDecision {
                switch decision.kind {
                case .approved: outcome = .approved
                case .changeAsked: outcome = .changeAsked
                case .rejected: outcome = .rejected
                case .closed: outcome = .closed
                }
                at = decision.at
            } else if item.stage == .guardianRejected, let answeredAt = item.guardianAnswer?.at {
                outcome = .guardianSaidNo
                at = answeredAt
            } else {
                return nil
            }
            return WardenHistoryItem(id: item.id.rawValue, student: item.student, outcome: outcome, decidedOn: at,
                                     decidedAtTime: at, method: item.evidence?.method, place: item.place,
                                     leaveAt: item.leaveAt, returnBy: item.returnBy, passCode: item.pass?.code,
                                     evidence: item.evidence)
        }
        let seeded = seededHistory.filter { $0.student.block == block }
        return (live + seeded).sorted { $0.decidedOn > $1.decidedOn }
    }

    func outing(_ outing: OutingRequestID, for warden: AccountID) async throws -> OutingCase {
        if offline { throw RepositoryError.offline(lastSavedAt: nil) }
        return try wardenCase(outing, warden)
    }

    func recordGuardianCall(_ outing: OutingRequestID, note: String, warden: AccountID, by role: Role) async throws
        -> OutingCase {
        try require(role, is: .warden)
        var item = try wardenCase(outing, warden)
        guard item.stage == .guardianCallRequested else {
            throw RepositoryError.notAllowed(reason: "Only a guardian without a camera is answered by call.")
        }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RepositoryError.validationFailed(["Write what the guardian said."]) }
        let now = clock.now()
        let evidence = OutingEvidence(method: .confirmedByCall, capturedAt: now, videoSeconds: nil, transcript: nil,
                                      passedChecks: [], calledNumber: item.guardianPhone, callNote: trimmed,
                                      deletesAt: nil)
        item.guardianAnswer = GuardianAnswerRecord(answer: .accepted(evidence), at: now)
        item.stage = .awaitingWarden
        return save(item)
    }

    /// Every warden decision needs the guardian's acceptance first.
    private func decidable(_ id: OutingRequestID, _ warden: AccountID, _ role: Role) throws -> OutingCase {
        try require(role, is: .warden)
        let item = try wardenCase(id, warden)
        guard item.stage == .awaitingWarden, item.evidence != nil else {
            throw RepositoryError.notAllowed(reason: "The guardian has not accepted this request.")
        }
        return item
    }

    func approve(_ outing: OutingRequestID, warden: AccountID, by role: Role) async throws -> OutingCase {
        var item = try decidable(outing, warden, role)
        undoSnapshots[outing] = item
        let now = clock.now()
        item.pass = OutingPass(code: item.seededPassCode ?? makePassCode(), signedAt: now)
        item.wardenDecision = WardenDecision(kind: .approved, at: now, reasons: [], note: nil)
        item.stage = .passSigned
        return save(item)
    }

    func askForChange(_ outing: OutingRequestID, fields: [String], note: String?, warden: AccountID, by role: Role)
        async throws -> OutingCase {
        var item = try decidable(outing, warden, role)
        guard !fields.isEmpty else { throw RepositoryError.validationFailed(["Choose what should change."]) }
        undoSnapshots[outing] = item
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        item.wardenDecision = WardenDecision(kind: .changeAsked, at: clock.now(), reasons: fields,
                                             note: trimmed?.isEmpty == false ? trimmed : nil)
        item.stage = .wardenAskedChange
        return save(item)
    }

    func reject(_ outing: OutingRequestID, reason: String, warden: AccountID, by role: Role) async throws -> OutingCase {
        var item = try decidable(outing, warden, role)
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RepositoryError.validationFailed(["A reason is required."]) }
        undoSnapshots[outing] = item
        item.wardenDecision = WardenDecision(kind: .rejected, at: clock.now(), reasons: [trimmed], note: nil)
        item.stage = .wardenRejected
        return save(item)
    }

    func closeRequest(_ outing: OutingRequestID, warden: AccountID, by role: Role) async throws -> OutingCase {
        try require(role, is: .warden)
        var item = try wardenCase(outing, warden)
        guard case .pastDeadline? = item.escalation(at: clock.now()) else {
            throw RepositoryError.notAllowed(reason: "Only a request past its deadline can be closed.")
        }
        item.wardenDecision = WardenDecision(kind: .closed, at: clock.now(), reasons: [], note: nil)
        item.stage = .closed
        return save(item)
    }

    func undoDecision(_ outing: OutingRequestID, warden: AccountID, by role: Role) async throws -> OutingCase {
        try require(role, is: .warden)
        let item = try wardenCase(outing, warden)
        let undoable: Set<OutingStage> = [.passSigned, .wardenAskedChange, .wardenRejected]
        guard undoable.contains(item.stage), item.exitAt == nil, let snapshot = undoSnapshots[outing] else {
            throw RepositoryError.notAllowed(reason: "This decision can no longer be undone.")
        }
        undoSnapshots[outing] = nil
        return save(snapshot)
    }

    // MARK: Gate

    func gateOverview(by role: Role) async throws -> GateOverview {
        try require(role, is: .gate)
        let now = clock.now()
        let out = order.compactMap { cases[$0] }.filter { $0.stage == .out }
        return GateOverview(post: OutingSeed.gatePost, typedCodesToday: typedCodes, outNow: out.count,
                            overdue: out.filter { $0.isLate(at: now) }.count)
    }

    private func evaluate(_ item: OutingCase) -> GateCheck {
        let now = clock.now()
        switch item.stage {
        case .withdrawn where item.pass != nil:
            return .withdrawn(item)
        case .passSigned:
            guard let leaveAt = item.leaveAt, let returnBy = item.returnBy else { return .notValid }
            if now < leaveAt { return .tooEarly(item) }
            if now > returnBy { return .tooLate(item) }
            return .exitReady(item)
        case .out:
            return .returnReady(item)
        case .returned:
            return .alreadyUsed(item)
        default:
            return .notValid
        }
    }

    func checkPassCode(_ code: String, by role: Role) async throws -> GateCheck {
        try require(role, is: .gate)
        typedCodes += 1
        let wanted = code.trimmingCharacters(in: .whitespaces).uppercased()
        guard !wanted.isEmpty, let item = order.compactMap({ cases[$0] }).first(where: { $0.pass?.code == wanted }) else {
            return .notValid
        }
        return evaluate(item)
    }

    func checkPass(of outing: OutingRequestID, by role: Role) async throws -> GateCheck {
        try require(role, is: .gate)
        guard let item = cases[outing], item.pass != nil else { return .notValid }
        return evaluate(item)
    }

    func findStudent(srmID: String, by role: Role) async throws -> [OutingCase] {
        try require(role, is: .gate)
        let wanted = srmID.trimmingCharacters(in: .whitespaces).uppercased()
        guard !wanted.isEmpty else { return [] }
        lookups.append((wanted, clock.now()))
        return order.compactMap { cases[$0] }.filter { $0.student.srmID == wanted && $0.pass != nil }
    }

    private func outCount() -> Int { cases.values.filter { $0.stage == .out }.count }

    func recordExit(_ outing: OutingRequestID, by role: Role) async throws -> GateRecord {
        try require(role, is: .gate)
        guard var item = cases[outing], case .exitReady = evaluate(item) else {
            throw RepositoryError.notAllowed(reason: "No valid signed pass for an exit now.")
        }
        item.exitAt = clock.now()
        item.exitGate = OutingSeed.gatePost.name
        item.stage = .out
        undoSnapshots[outing] = nil
        let saved = save(item)
        return GateRecord(outing: saved, outNowCount: outCount())
    }

    func recordReturn(_ outing: OutingRequestID, by role: Role) async throws -> GateRecord {
        try require(role, is: .gate)
        guard var item = cases[outing], item.stage == .out else {
            throw RepositoryError.notAllowed(reason: "This student has no exit to return from.")
        }
        item.returnAt = clock.now()
        item.stage = .returned
        let saved = save(item)
        return GateRecord(outing: saved, outNowCount: outCount())
    }

    func gateOutNow(by role: Role) async throws -> [OutingCase] {
        try require(role, is: .gate)
        return order.compactMap { cases[$0] }.filter { $0.stage == .out }
            .sorted { ($0.returnBy ?? .distantFuture) < ($1.returnBy ?? .distantFuture) }
    }

    func gateOverdue(by role: Role) async throws -> [OutingCase] {
        let now = clock.now()
        return try await gateOutNow(by: role).filter { $0.isLate(at: now) }
    }

    func reportGateProblem(_ problem: GateProblem, by role: Role) async throws -> GateProblemReport {
        try require(role, is: .gate)
        return GateProblemReport(problem: problem, sentAt: clock.now())
    }
}
#endif
