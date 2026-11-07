import Foundation
import Observation

/// The one Guardian page and the step it shows. Every answer goes through the outing repository: Reject is one tap
/// with no video; Accept always passes the live capture (video, or the photo and code after two failed uploads).
/// There is no text-only accept anywhere.
@MainActor
@Observable
final class GuardianModel {
    enum RecordPhase: Equatable {
        case ready
        case recording
        case tooShort(seconds: Int)
        /// Drawn (GV-02 Too dark); the prototype has no light sensor, so only a screenshot run reaches it.
        case tooDark
    }

    enum Step: Equatable {
        case loading
        case failed(LoadFailure)
        case choose
        case expired
        case consent
        case record(RecordPhase)
        /// Drawn (GV-02 Camera blocked); reached only where camera permission can be refused (not the simulator).
        case cameraBlocked
        case uploading
        case checking
        case uploadFailed(progress: Double, retriesLeft: Int)
        case retry(heard: String, missing: String, nextAttempt: Int)
        case sendVideo
        case photo(PhotoChallenge)
        /// The answer and what followed (GV-06, G-3). `justSent` is true right after this page sent it.
        case answered(justSent: Bool)
        case pastAnswers
    }

    var step: Step = .loading
    private(set) var link: GuardianLink?
    private(set) var request: OutingCase?
    private(set) var pastAnswers: [GuardianPastAnswer] = []
    private(set) var now: Date?
    private(set) var challenge: CaptureChallenge?
    private(set) var lastSeconds = 0
    private(set) var isWorking = false
    private(set) var actionError: String?
    /// The step to go back to from Past answers.
    private var stepBeforePast: Step = .choose

    let account: AccountID
    private let repository: any OutingCaseRepository
    private var hasBegun = false

    init(account: AccountID, repository: any OutingCaseRepository) {
        self.account = account
        self.repository = repository
    }

    var studentName: String { link?.student.firstName ?? link?.student.displayName ?? "—" }

    func load() async {
        do {
            if !hasBegun {
                try await repository.begin(as: .guardian)
                hasBegun = true
            }
            now = await repository.now()
            link = try await repository.guardianLink(for: account)
            request = try await repository.guardianRequest(for: account)
            pastAnswers = try await repository.guardianPastAnswers(for: account)
            step = restingStep(justSent: false)
        } catch {
            step = .failed(LoadFailure(error))
        }
    }

    /// Where the page rests for the request as it is now.
    private func restingStep(justSent: Bool) -> Step {
        guard let request else { return .expired }
        if request.stage == .awaitingGuardian {
            if let replyBy = request.guardianReplyBy, let now, now > replyBy { return .expired }
            return .choose
        }
        if request.stage == .closed { return .expired }
        return .answered(justSent: justSent)
    }

    private func refresh(justSent: Bool) async {
        now = await repository.now()
        request = try? await repository.guardianRequest(for: account)
        pastAnswers = (try? await repository.guardianPastAnswers(for: account)) ?? pastAnswers
        step = restingStep(justSent: justSent)
    }

    private func perform(_ work: () async throws -> Void) async {
        guard !isWorking else { return }
        isWorking = true
        actionError = nil
        defer { isWorking = false }
        do {
            try await work()
        } catch {
            actionError = LoadFailure(error).message
        }
    }

    // MARK: Accept: consent, then the live capture

    func accept() async {
        // Only an open request can be accepted; past the reply time the page stays on "expired".
        guard restingStep(justSent: false) == .choose else {
            step = restingStep(justSent: false)
            return
        }
        await perform {
            if try await repository.hasConsented(account) {
                try await beginCapture()
            } else {
                step = .consent
            }
        }
    }

    func agreeAndContinue() async {
        await perform {
            try await repository.recordConsent(account, by: .guardian)
            try await beginCapture()
        }
    }

    private func beginCapture() async throws {
        guard let request else { return }
        challenge = try await repository.startCapture(request.id, guardian: account, by: .guardian)
        step = .record(.ready)
    }

    func startRecording() { step = .record(.recording) }

    /// The recorder stopped (by the guardian or at the maximum). Sends the video and shows what happened.
    func finishRecording(seconds: Int) async {
        lastSeconds = seconds
        await submit()
    }

    private func submit() async {
        guard let challenge else { return }
        step = .uploading
        await perform {
            let result = try await repository.submitVideo(challenge, seconds: lastSeconds, guardian: account, by: .guardian)
            switch result {
            case .sent:
                step = .checking
                await refresh(justSent: true)
            case .tooShort:
                step = .record(.tooShort(seconds: lastSeconds))
            case .notMatched(let heard, let missing, let next):
                self.challenge = nil
                if let next {
                    step = .retry(heard: heard, missing: missing, nextAttempt: next)
                } else {
                    step = .sendVideo
                }
            case .uploadFailed(let progress, let retriesLeft):
                step = .uploadFailed(progress: progress, retriesLeft: retriesLeft)
            }
        }
        if case .uploading = step { step = .record(.ready) }
    }

    func recordAgain() async {
        await perform { try await beginCapture() }
    }

    func retryUpload() async { await submit() }

    func sendForReview() async {
        guard let request else { return }
        await perform {
            _ = try await repository.sendVideoForReview(request.id, guardian: account, by: .guardian)
            await refresh(justSent: true)
        }
    }

    func takePhotoInstead() async {
        guard let request else { return }
        await perform {
            step = .photo(try await repository.startPhotoFallback(request.id, guardian: account, by: .guardian))
        }
    }

    func sendPhoto(typed: String, phoneCode: String) async {
        guard let request else { return }
        await perform {
            _ = try await repository.submitPhoto(request.id, typed: typed, phoneCode: phoneCode, guardian: account,
                                                 by: .guardian)
            await refresh(justSent: true)
        }
    }

    func askWardenToCall() async {
        guard let request else { return }
        await perform {
            _ = try await repository.requestWardenCall(request.id, guardian: account, by: .guardian)
            await refresh(justSent: true)
        }
    }

    func closeRecorder() {
        challenge = nil
        step = restingStep(justSent: false)
    }

    // MARK: Reject, ask to change, withdraw

    func reject(reason: String?) async {
        guard let request else { return }
        await perform {
            _ = try await repository.rejectAsGuardian(request.id, reason: reason, guardian: account, by: .guardian)
            await refresh(justSent: true)
        }
    }

    func askToChange(fields: [String]) async {
        guard let request else { return }
        await perform {
            _ = try await repository.askStudentToChange(request.id, fields: fields, guardian: account, by: .guardian)
            await refresh(justSent: true)
        }
    }

    func withdraw() async {
        guard let request else { return }
        await perform {
            _ = try await repository.withdrawApproval(request.id, guardian: account, by: .guardian)
            await refresh(justSent: true)
        }
    }

    // MARK: Past answers

    func showPastAnswers() {
        stepBeforePast = step == .pastAnswers ? stepBeforePast : step
        step = .pastAnswers
    }

    func backFromPastAnswers() { step = stepBeforePast }
}
