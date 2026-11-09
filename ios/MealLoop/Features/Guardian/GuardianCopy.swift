import Foundation

/// Guardian wording from design/reference/guardian_2026-10 (G00–G08, data/guardian_video_spec.md) and the GV and
/// G-3 frames in design/audit/export_guardian_video/. Lines no frame draws are marked "Not drawn" and listed in
/// docs/verification/outings/REPORT.md. Where a frame says "he" for the student, these lines use the name instead.
/// Nothing here says the video proves who the guardian is, or that it is the warden's approval.
enum GuardianCopy {
    // MARK: Header and language (GV-01 Language sheet)
    /// The frame's pill offers தமிழ். Owner ruling (9 November): only English is shown until translations exist, so the
    /// pill names the language in use and the sheet lists English alone.
    static let languagePill = "English"
    static let languageTitle = "Language"
    static let languages = ["English"]
    static let languageNote = "Messages and this page use this language."

    // MARK: Consent (GV-00)
    static let consentTitle = "Before you\nrecord."
    static let consentSubtitle = "Please read this once."
    static let consentSteps: [(String, String)] = [
        ("We record 10 seconds", "of you saying a short phrase."),
        ("Only the hostel warden", "can watch it."),
        ("The video is deleted", "after 30 days."),
    ]
    static let agree = "I understand and agree"
    static let continueTitle = "Continue"
    static let consentFooter = "No video, no approval.\nYou can say no with one tap."

    // MARK: Choose (GV-01)
    static func wantsToGoOut(_ name: String) -> String { "\(name) wants\nto go out." }
    static func outingLine(day: String, reason: String?, hours: String) -> String {
        [day, reason, hours].compactMap { $0 }.joined(separator: " · ")
    }
    static func replyBy(_ time: String) -> String { "Reply by \(time)" }
    static let yourAnswer = "Your answer"
    static let iAccept = "I accept"
    static let recordVideo = "Record a 10-second video"
    static let iReject = "I reject"
    static let oneTapNoVideo = "One tap. No video needed."
    static let seenOnlyByWarden = "Your video is seen only by the warden."
    static let askToChange = "Ask to change"
    static let pastAnswers = "Past answers"
    static let moreAboutOuting = "More about this outing"
    static func verifiedAs(_ name: String) -> String { "Verified as \(name)'s guardian" }

    // MARK: About (GV-01 sheet)
    static let aboutTitle = "About this outing"
    static let leave = "Leave"
    static let backBy = "Back by"
    static let reason = "Reason"
    static let youAnswer = "You answer"
    static func youAnswerDetail(_ time: String) -> String { "By \(time). Accept with a short video, or reject." }
    static let wardenDecides = "The warden decides"
    static func wardenDecidesDetail(_ time: String) -> String { "By \(time)." }
    static func passIssued(_ name: String) -> String { "A pass is issued to \(name)" }
    static func passValidOnly(_ window: String) -> String { "Valid only for \(window)." }

    // MARK: Ask to change (GV-01 sheet)
    static let whatShouldChange = "What should change?"
    static func changeDetail(_ name: String) -> String { "\(name) edits the request and sends it again. You answer once more." }
    static let changeOptions = ["Day", "Time", "Place", "Other"]
    static func sendTo(_ name: String) -> String { "Send to \(name)" }

    // MARK: Reject (GV-08)
    static let rejectTitle = "Reject this outing?"
    static func rejectDetail(_ name: String) -> String { "\(name) will be told. You can add a reason." }
    static let rejectReasons = ["Exam soon", "Not safe", "Other"]
    static let rejectOuting = "Reject outing"
    static let goBack = "Go back"

    // MARK: Expired and already answered (GV-01)
    static let expiredTitle = "This request\nhas expired."
    static func expiredDetail(_ time: String, _ name: String) -> String {
        "The reply time (\(time)) passed. \(name) can send a new one."
    }
    static let neverWithoutYou = "A request is never approved without your answer."
    static let alreadyAnswered = "You already\nanswered."
    static func wardenDecidesBy(_ time: String) -> String { "The warden decides by \(time). We will message you." }

    // MARK: Record (GV-02)
    static func tryOf(_ attempt: Int, _ total: Int) -> String { "Try \(attempt) of \(total)" }
    static let sayThis = "Say this out loud"
    static let code = "Code"
    static let liveVideoOnly = "Live video only"
    static let tapToStart = "Tap to start · 10 seconds"
    static func speakNow(_ max: String) -> String { "Speak now · stops at \(max)" }
    static let tooShortChip = "Too short · under 4 seconds"
    static let tooShortHelp = "Too short. Say the whole phrase and the code."
    static let tooDarkChip = "Too dark. Find more light."
    static let tooDarkHelp = "Find more light, then tap to start."
    static let rec = "REC"
    static let close = "Close"
    static let startRecording = "Start recording"
    static let stopRecording = "Stop recording"
    /// Not drawn: said to VoiceOver and in the report. The simulator has no camera.
    static let staticPreview = "Camera preview. The prototype shows a still picture; no video is recorded."

    // MARK: Camera blocked, uploading, checking, upload failed (GV-02)
    static let cameraBlockedTitle = "Your camera\nis blocked."
    static let cameraBlockedDetail = "MealLoop needs your camera to record the 10-second video."
    static let cameraSteps = ["Open Settings", "Allow the camera for this browser", "Come back and tap I accept"]
    static let openSettings = "Open Settings"
    static let askWardenToCall = "Ask the warden to call me"
    static let noTextOnly = "Without a camera the warden phones you and notes your answer. There is no text-only approval."
    static let sendingTitle = "Sending your\nvideo …"
    static let sendingDetail = "Keep this page open. It takes a few seconds."
    static func yourVideo(_ duration: String) -> String { "Your video · \(duration)" }
    static func tryCode(_ attempt: Int, _ total: Int, _ code: String) -> String { "Try \(attempt) of \(total) · code \(code)" }
    static func onlyBlockWarden(_ block: String?) -> String {
        block.map { "Only the warden of \($0) can watch it." } ?? "Only the warden can watch it."
    }
    static let checkingTitle = "Checking the\nphrase and code …"
    static let checkingDetail = "We listen for the phrase and the 3 digits."
    static let youWereAsked = "You were asked to say"
    static let phrase = "Phrase"
    static let number = "Number"
    static let checking = "Checking"
    static let uploadFailedTitle = "Your video\ndidn't send."
    static let uploadFailedDetail = "The network dropped. Your video is still on this phone."
    static let uploadStopped = "Upload stopped"
    static func uploadTryFailed(_ attempt: Int, _ total: Int) -> String { "Try \(attempt) of \(total) failed" }
    static func tryAgainLeft(_ left: Int) -> String { "Try again · \(left) left" }
    static let takePhotoInstead = "Take a photo instead"
    static let photoAfterTwo = "After 2 failed tries, a live photo of your face and a code sent to your phone are used instead."

    // MARK: Retry and send video (GV-03, GV-04)
    static let couldntHear = "We couldn't\nhear that."
    static let speakClearly = "Try again. Speak clearly and say the code."
    static let whatWeHeard = "What we heard"
    static func missing(_ text: String) -> String { "Missing: \(text)" }
    static func recordAgain(_ attempt: Int, _ total: Int) -> String { "Record again · try \(attempt) of \(total)" }
    static let afterThreeTries = "After 3 tries your video still goes to the warden, who will watch it."
    static let stillCouldnt = "Still couldn't\nhear the code."
    static let canStillGo = "Your video can still go to the warden."
    static let sendSteps = ["Your video is sent as it is", "The warden watches it", "You get a message when decided"]
    static func yourRecording(_ duration: String) -> String { "Your recording · \(duration)" }
    static let sendVideo = "Send video to the warden"
    static let noMoreTries = "No more tries left. The warden sees: Video, please watch."

    // MARK: Photo and code (GV-05)
    static let didntUpload = "Your video\ndidn't upload."
    static let takePhoto = "Take a photo of your face instead."
    static let livePhotoOnly = "Live photo only"
    static let typeExactly = "Then type exactly"
    static func codeSentTo(_ phone: String) -> String { "Code sent to \(phone)" }
    static let sendPhotoAndCode = "Send photo and code"
    static let wardenSeesPhoto = "The warden sees: Photo and text, no video."

    // MARK: Sent and after (GV-06)
    static let sentTitle = "Sent to\nthe warden."
    static func decideBy(_ time: String) -> String { "They decide by \(time). We will message you." }
    static func method(_ method: GuardianEvidenceMethod) -> String {
        switch method {
        case .liveVideoAutoChecked: return "Video, checked"
        case .videoNeedsReview: return "Video, please watch"
        case .photoAndText: return "Photo and text, no video"
        case .confirmedByCall: return "By call"
        }
    }
    static let waitingForWarden = "Waiting for the warden"
    static let withdrawApproval = "Withdraw approval"
    static let callWarden = "Call the warden"
    static let wardenWillCall = "The warden\nwill call you."
    static func cameraDidNotWork(_ phone: String, _ time: String) -> String {
        "Your camera did not work. The warden phones \(phone) before \(time)."
    }
    static let callRequested = "Call requested"
    static let noCamera = "No camera"
    static let waitingForCall = "Waiting for the warden's call"
    static func saidNo(_ name: String) -> String { "You said no.\n\(name) is told." }
    static func reasonLine(_ reason: String) -> String { "Reason: \(reason)." }
    static let oneTapNoVideoLine = "One tap, no video"
    static func canSendNew(_ name: String) -> String { "\(name) can send a new request." }
    static let withdrawTitle = "Withdraw your approval?"
    static func withdrawDetail(_ name: String) -> String { "This cancels \(name)'s request. \(name) is told." }
    static let keepIt = "Keep it"
    static let withdrewTitle = "You withdrew\nyour approval."
    static func withdrewDetail(_ name: String) -> String { "\(name)'s request is cancelled. \(name) is told." }
    static let withdrawn = "Withdrawn"
    static let wasAcceptVideo = "Was: I accept, video"
    static func was(_ method: GuardianEvidenceMethod) -> String {
        switch method {
        case .liveVideoAutoChecked, .videoNeedsReview: return wasAcceptVideo
        case .photoAndText: return "Was: I accept, photo"
        case .confirmedByCall: return "Was: I accept, by call"
        }
    }

    // MARK: Past answers (GV-07)
    static func forStudent(_ name: String) -> String { "For \(name)" }
    static func pastLine(_ day: String, accepted: Bool) -> String { "\(day) · \(accepted ? "You accepted" : "You rejected")" }
    static func pastTag(_ method: GuardianEvidenceMethod?) -> String {
        switch method {
        case .liveVideoAutoChecked?, .videoNeedsReview?: return "Video"
        case .photoAndText?: return "Photo"
        case .confirmedByCall?: return "Call"
        case nil: return "One tap"
        }
    }
    static let videosDeleted = "Videos are deleted after 30 days."
    static let messages = "Messages"
    static let help = "Help"
    static let backToRequest = "Back to the request"

    // MARK: Status after the warden (G-3)
    static let youApproved = "You approved."
    static func wardenApprovedAt(_ time: String) -> String { "The warden approved at \(time)." }
    static func wardenDecidedAt(_ time: String) -> String { "The warden decided at \(time)." }
    static let backByDial = "Back by"
    static func dialName(_ name: String, _ day: String) -> String { "\(name) · \(day)" }
    static func passIssuedNotLeft(_ time: String, _ name: String) -> String { "Pass issued \(time) · \(name) hasn't left yet" }
    static func messageLeavesAndBack(_ name: String) -> String { "We'll message you when \(name) leaves and comes back." }
    static func outSince(_ time: String) -> String { "Out since \(time)" }
    static func backByTime(_ time: String) -> String { "Back by \(time)" }
    static func leftGate(_ name: String, _ gate: String, _ time: String) -> String { "\(name) left \(gate) at \(time)" }
    static func messageWhenBack(_ name: String) -> String { "We'll message you when \(name) is back." }
    static func backAt(_ time: String) -> String { "Back \(time)" }
    static func isBack(_ name: String, _ time: String) -> String { "\(name) is back at the hostel (\(time))" }
    static let outingClosed = "This outing is closed. Nothing else to do."
    static let back = "Back"
    static func minLate(_ span: String) -> String { "\(span) late" }
    static func wasLate(_ name: String, _ span: String) -> String { "\(name) was \(span) late. The warden has been told." }
    static func wasBackAt(_ name: String, _ time: String) -> String { "\(name) was back at \(time)." }
    static let notGoing = "Not going"
    static let wardenDidNotApprove = "The warden didn't approve this outing"
    static func wardenReason(_ reason: String, _ name: String) -> String {
        "Reason from the warden: \(reason). \(name) can ask for another day."
    }
    /// Not drawn: the warden asked the student to change the request.
    static func wardenAskedChange(_ fields: String) -> String { "The warden asked for a change: \(fields)." }
    static let youAskedChange = "You asked for a\nchange."
    static func canEdit(_ name: String) -> String { "\(name) can edit it and send it again." }
    static func hoursLong(_ hours: Int) -> String { hours == 1 ? "1 hour" : "\(hours) hours" }
    static func waitingForChange(_ name: String) -> String { "Waiting for \(name) to change it" }
    static let replyAgain = "You reply again when it comes back."
    /// Not drawn: a request the warden closed after its deadline.
    static let closedTitle = "This request\nwas closed."
}
