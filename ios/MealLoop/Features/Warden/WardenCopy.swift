import Foundation

/// Warden wording from design/reference/guardian_2026-10 (W01–W04, data/guardian_video_spec.md) and the WV frames in
/// design/audit/export_guardian_video/. Lines no frame draws are marked "Not drawn" and listed in
/// docs/verification/outings/REPORT.md. The student is "their" student here: the frames say "his", and these screens
/// serve every student.
enum WardenCopy {
    // MARK: Tabs (W01: words only)
    static let queueTab = "Queue"
    static let outNowTab = "Out now"
    static let escalatedTab = "Escalated"
    static let historyTab = "History"

    // MARK: Queue (WV-1)
    static let decideNext = "Decide next"
    static func queueSubtitle(block: String, position: Int, count: Int) -> String {
        "\(block) · \(position) of \(count) · closest deadline first"
    }
    static func fromEscalated(block: String, why: String) -> String { "\(block) · from Escalated · \(why)" }
    static func waitingSubtitle(block: String, count: Int) -> String {
        "\(block) · \(count) waiting · closest deadline first"
    }
    static func nothingWaiting(block: String) -> String { "\(block) · nothing waiting" }
    static let decideBy = "Decide by"
    static let guardianVideo = "Guardian video"
    static let guardianPhoto = "Guardian photo"
    static let guardianCall = "Guardian call"
    static func live(_ duration: String) -> String { "Live · \(duration)" }
    static let pleaseWatch = "Please watch"
    static let photoAndText = "Photo and text"
    static let confirmedByCall = "Confirmed by call"
    static let notMatched = "Not matched after 3 tries. Watch before deciding."
    static let livePhotoTyped = "Live photo · typed"
    static let noVideo = "No video"
    static func called(_ number: String, at time: String) -> String { "Called \(number) · \(time)" }
    /// Not drawn: before the call is recorded there is no time yet.
    static func toCall(_ number: String) -> String { "Call \(number), then write what was said." }
    static let noteRequired = "Note (required)"
    static let phrase = "Phrase"
    static let code = "Code"
    static let number = "Number"
    static let approve = "Approve"
    static let ask = "Ask"
    static let no = "No"
    static let loadingVideo = "Loading video …"
    static let videoNeedsConnection = "The video needs a connection"
    static let offlineBanner = "You're offline. Decisions send when you're back."
    static let nothingToDecide = "Nothing to decide"
    static let nothingToDecideDetail = "New requests appear here, closest deadline first. Escalated shows anything past its time."
    static let seeOutNow = "See Out now"
    static let seeEscalated = "See Escalated"

    static func pastAnswers(_ counts: [GuardianEvidenceMethod: Int]) -> String? {
        let order: [(GuardianEvidenceMethod, String)] = [(.liveVideoAutoChecked, "by video"), (.videoNeedsReview, "by video"),
                                                         (.photoAndText, "by photo"), (.confirmedByCall, "by call")]
        var totals: [String: Int] = [:]
        var labels: [String] = []
        for (method, label) in order {
            guard let count = counts[method], count > 0 else { continue }
            if totals[label] == nil { labels.append(label) }
            totals[label, default: 0] += count
        }
        guard !labels.isEmpty else { return nil }
        return "Past answers: " + labels.map { "\(totals[$0] ?? 0) \($0)" }.joined(separator: ", ")
    }

    // MARK: Ask and No sheets (WV-1)
    static let askTitle = "Ask for a change"
    static func askDetail(_ name: String) -> String { "\(name) and their guardian see what to change." }
    static let changeOptions = ["Day", "Time", "Place", "Other"]
    static let noteOptional = "Note (optional)"
    static let send = "Send"
    static let rejectTitle = "Reject this outing?"
    static func rejectDetail(_ name: String) -> String { "A reason is required. \(name) and their guardian see it." }
    static let rejectReasons = ["Exam soon", "Not safe", "Back too late", "Other"]
    static let rejectOuting = "Reject outing"
    static let cancel = "Cancel"

    // MARK: Results (WV-1 Approved, Change asked, Rejected)
    static let approved = "Approved."
    static let changeAsked = "Change asked."
    static let rejected = "Rejected."
    static let closed = "Closed."
    static func approvedDetail(pass: String, name: String) -> String {
        "Pass \(pass) is signed. \(name) and their guardian are told."
    }
    static func changeDetail(name: String, fields: [String], note: String?) -> String {
        let trimmedNote = note.map { $0.hasSuffix(".") ? String($0.dropLast()) : $0 }
        let what = ([fields.joined(separator: ", ")] + [trimmedNote].compactMap { $0 }).joined(separator: ". ")
        return "\(name) and their guardian see: \(what)."
    }
    static func rejectedDetail(name: String, reason: String) -> String { "\(name) and their guardian are told: \(reason)." }
    /// Not drawn.
    static func closedDetail(name: String) -> String { "\(name)'s request is closed without approval." }
    static func next(_ name: String) -> String { "Next: \(name)" }
    /// Not drawn: the result when nobody else is waiting.
    static let done = "Done"
    static let undo = "Undo for 10 seconds"

    // MARK: Out now (WV-2)
    static let outNowTitle = "Out now"
    static func outNowSubtitle(block: String, day: String) -> String { "\(block) · \(day)" }
    static let outNowEyebrow = "OUT NOW"
    static func dueBackBy(_ time: String) -> String { "Due back by \(time)" }
    static let late = "Late"
    static func backBy(_ time: String) -> String { "Back by \(time)" }
    static func lateBy(_ span: String) -> String { "Late \(span)" }
    static func dueIn(_ span: String) -> String { "Due in \(span)" }
    static func seeAll(_ count: Int) -> String { "See all \(count)" }
    /// Not drawn.
    static let nobodyOut = "Nobody is out"
    /// Not drawn.
    static let nobodyOutDetail = "Students show here after the gate records their exit."
    static func pass(_ code: String) -> String { "Pass  \(code)" }
    static let outBetween = "Out between"
    static let place = "Place"
    static func leftGate(_ gate: String) -> String { "Left \(gate)" }
    static let backByLabel = "Back by"
    static let nowLabel = "Now"
    static func onTime(_ span: String) -> String { "Due in \(span)" }
    static let guardianAnswered = "Guardian answered"
    static func call(_ name: String) -> String { "Call \(name)" }
    static func callGuardian(_ name: String) -> String { "Call \(name)'s guardian" }
    static let returnAtGate = "Return is recorded at the gate."

    // MARK: Escalated (WV-4)
    static let escalatedTitle = "Escalated"
    static let escalatedSubtitle = "Needs a decision or a call"
    static func pastDeadline(_ ago: String) -> String { "Past deadline · \(ago) ago" }
    static let videoPleaseWatch = "Video, please watch"
    static let noCamera = "No camera · call the guardian"
    static let callAction = "Call"
    static let watch = "Watch"
    static let nothingElse = "Nothing else needs you."
    static func callSheetTitle(_ name: String) -> String { "Call \(name)'s guardian" }
    static func callSheetNoCamera(_ number: String) -> String {
        "\(number) · no camera. After the call, record the answer with a note."
    }
    static func callSheetPastDeadline(_ number: String, by span: String) -> String {
        "\(number) · past deadline by \(span). A request is never approved by a timeout."
    }
    static func callNumber(_ number: String) -> String { "Call \(number)" }
    static let recordTheAnswer = "Record the answer"
    static let closeTheRequest = "Close the request"
    static let fromEscalatedNoCamera = "no camera"
    static let fromEscalatedPleaseWatch = "please watch"
    static let fromEscalatedPastDeadline = "past deadline"

    // MARK: History (WV-3)
    static let historyTitle = "History"
    static func historySubtitle(block: String) -> String { "Your decisions · \(block)" }
    static let thisWeek = "This week"
    static let all = "All"
    static func outcome(_ outcome: WardenHistoryItem.Outcome) -> String {
        switch outcome {
        case .approved: return "You approved"
        case .changeAsked: return "You asked to change"
        case .rejected: return "You said no"
        case .guardianSaidNo: return "Guardian said no"
        case .closed: return "You closed it"
        }
    }
    static func historyMethod(_ method: GuardianEvidenceMethod?) -> String {
        switch method {
        case .liveVideoAutoChecked?, .videoNeedsReview?: return "Video"
        case .photoAndText?: return "Photo and text"
        case .confirmedByCall?: return "Call"
        case nil: return "No video"
        }
    }
    static let retentionNote = "Videos are kept 30 days.\nAfter that, only the transcript stays."
    /// Not drawn.
    static let noHistory = "No decisions yet"
    static let outing = "Outing"
    static let youDecided = "You decided"
    static func decision(_ kind: String, _ time: String) -> String { "\(kind) · \(time)" }
    static func decisionWord(_ outcome: WardenHistoryItem.Outcome) -> String {
        switch outcome {
        case .approved: return "Approve"
        case .changeAsked: return "Ask"
        case .rejected: return "No"
        case .guardianSaidNo: return "Guardian said no"
        case .closed: return "Closed"
        }
    }
    static let passLabel = "Pass"
    static let videoDeleted = "Video deleted after 30 days. Transcript kept."
    static func deletesOn(_ day: String) -> String { "The video is deleted on \(day) (after 30 days). The transcript stays." }
    static func deletedOn(_ day: String) -> String { "Deleted on \(day)." }

    // MARK: Me (WV-5)
    static let meTitle = "Me"
    static func staffID(_ id: String) -> String { "Staff ID \(id)" }
    static let role = "Role"
    static let roleName = "Warden"
    static let block = "Block"
    static func blockStudents(_ block: String, _ count: Int?) -> String {
        count.map { "\(block) · \($0) students" } ?? block
    }
    static let hours = "Hours"
    static let escalationsGoTo = "Escalations go to"
    static let alerts = "Alerts"
    static let help = "Help"
    static let signOut = "Sign out"
    static let signOutDialog = ConfirmDialogContent(title: "Sign out?", cancelTitle: cancel, actionTitle: signOut)

    // MARK: Errors and toasts (not drawn)
    static let requestClosed = "Request closed"
    static let couldNotSend = "That didn't send. Try again."
}
