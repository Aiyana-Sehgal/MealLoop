import Foundation

/// Gate Security wording from the V5 gate frames in design/audit/export_guardian_video/ (GA-2 to GA-9) and the gate
/// home render design/audit/outings/o5/GA-1_Gate_home.png. Lines no frame draws are marked "Not drawn" and listed in
/// docs/verification/outings/REPORT.md.
enum GateCopy {
    // MARK: Home (GA-1)
    static func homeSubtitle(_ shift: String) -> String { "\(shift) · exits and returns" }
    static let scanPass = "Scan pass"
    static let scanPassDetail = "Exit or return. Tap to open the camera"
    static let cantScan = "Can’t scan?"
    static let typedCodesToday = "typed codes today"
    static let outNow = "Out now"
    static let studentsOutNow = "students out now"
    static let overdueReturns = "Overdue returns"
    static let overdueDetail = "past their time · call the warden"
    static let endShift = "End shift"
    static func shiftStarted(_ shift: String, _ time: String) -> String { "\(shift) · started \(time)" }
    static let reportProblem = "Report a problem"
    /// Not drawn: the confirmation before End shift signs out.
    static let endShiftDialog = ConfirmDialogContent(title: "End shift?", cancelTitle: "Cancel", actionTitle: "End shift")

    // MARK: Scan (GA-2)
    static let pointAtPass = "Point at the student’s outing pass"
    static let torch = "Torch"
    static func outCount(_ count: Int) -> String { "\(count) out now" }
    static let viewfinderLabel = "Camera view. The prototype has no camera; type the pass code instead."

    // MARK: Pass code (GA-4)
    static let typeCode = "Type the pass code"
    static let codeHelp = "The 4-character code under the QR on their pass. Same result as a scan."
    static let findBySRM = "No phone? Find the student by SRM ID"
    static let checkCode = "Check code"
    static let letters = "ABC"
    static let digits = "123"
    static let delete = "Delete"

    // MARK: Find student (GA-5)
    static let findStudent = "Find student"
    static func findHelp(_ gate: String) -> String {
        "For a student without a phone. You are signed in as \(gate) security; every lookup is recorded."
    }
    static let srmID = "SRM ID"
    static func matches(_ count: Int) -> String { count == 1 ? "1 match" : "\(count) matches" }
    static func passValid(_ block: String?, _ window: String) -> String {
        [block, "pass valid \(window)"].compactMap { $0 }.joined(separator: " · ")
    }
    static let noMatch = "No match? Don’t let the student out. Call the warden."

    // MARK: Verify (GA-3)
    static func gateExit(_ gate: String) -> String { "\(gate) · Exit" }
    static func gateReturn(_ gate: String) -> String { "\(gate) · Return" }
    static let isThisTheStudent = "Is this the student in front of you?"
    static func passValidLeave(_ window: String) -> String { "Pass valid · leave \(window)" }
    static let bothApproved = "Guardian and warden approved"
    static let notUsedYet = "Not used yet"
    static func outSince(_ time: String) -> String { "Out since \(time)" }
    static func backByOnTime(_ time: String) -> String { "Back by \(time) · on time" }
    /// Not drawn: the return check when the student is already late.
    static func backByLate(_ time: String, _ span: String) -> String { "Back by \(time) · \(span) late" }
    static let passMatches = "Pass matches this student"
    static let yesLetOut = "Yes, let out"
    static let yesRecordReturn = "Yes, record return"
    static let doesntMatch = "Doesn't match"

    // MARK: Results (GA-6)
    static let exitRecorded = "Exit recorded"
    static let idChecked = "ID checked"
    static func outingPass(_ window: String) -> String { "Outing pass · \(window)" }
    static func backBy(_ time: String) -> String { "Back by \(time)" }
    static func studentsOut(_ count: Int) -> String { count == 1 ? "1 student out now" : "\(count) students out now" }
    static let welcomeBack = "Welcome back"
    static func backAt(_ time: String) -> String { "Back at \(time)" }
    static let outingClosed = "Outing closed"
    static let backLate = "Back late · flagged"
    static func backAtLate(_ time: String, _ span: String) -> String { "Back at \(time) · \(span) late" }
    static func sentToWarden(_ block: String?) -> String { block.map { "Sent to the \($0) warden" } ?? "Sent to the warden" }
    static let alreadyOut = "Already out"
    static func usedAt(_ time: String) -> String { "This pass was used at \(time)." }
    static let dontLetOutAgain = "Don’t let out again. Call the warden if unsure."
    static let notValid = "Not valid"
    static let notMealLoopPass = "This is not a MealLoop outing pass."
    static let askToOpenPass = "Don’t let out. Ask the student to open their pass."
    static let passWithdrawn = "Pass withdrawn"
    static func withdrewAt(_ who: Role?, _ time: String) -> String {
        // The frame draws the warden. The guardian line is not drawn.
        who == .guardian ? "The guardian withdrew it at \(time)." : "The warden withdrew it at \(time)."
    }
    static let sendToWarden = "Don’t let out. Send the student to the warden."
    static let tooEarly = "Too early"
    static func leaveFrom(_ from: String, now: String) -> String { "Leave from \(from). It is \(now)." }
    static func comeBackAt(_ time: String) -> String { "Ask the student to come back at \(time)." }
    static let tooLate = "Too late"
    static func windowClosed(_ time: String) -> String { "The window closed at \(time)." }
    static let needsNewPass = "Don’t let out. The student needs a new pass."
    static let cantVerify = "Can’t verify"
    static let noConnection = "No connection, so nobody goes out."
    static let askTheWarden = "Ask the warden."
    static let tryAgain = "Try again"
    static let callWarden = "Call the warden"
    static let scanNext = "Scan next"

    // MARK: Out now (GA-7) and overdue (GA-8, not exported)
    static func outThrough(_ count: Int, _ gate: String) -> String {
        "\(count) \(count == 1 ? "student" : "students") out through \(gate). Back-by time first."
    }
    static func outRow(_ out: String, _ back: String) -> String { "Out \(out) · back by \(back)" }
    static let gateRecordsNote = "Times are the gate's own records."
    /// Not drawn in the repository (GA-8 is not exported).
    static func overdueSubtitle(_ count: Int) -> String { "\(count) past their time · call the warden" }

    // MARK: Report a problem (GA-9)
    static let pickOne = "Pick one. The duty warden gets it at once."
    static func problemTitle(_ problem: GateProblem) -> String {
        switch problem {
        case .scannerNotWorking: return "Scanner not working"
        case .crowdAtTheGate: return "Crowd at the gate"
        case .somethingElse: return "Something else"
        }
    }
    static func problemDetail(_ problem: GateProblem) -> String {
        switch problem {
        case .scannerNotWorking: return "The camera or the phone has stopped"
        case .crowdAtTheGate: return "The line is not moving"
        case .somethingElse: return "Anything else at the gate"
        }
    }
    static let sentToDutyWarden = "Sent to the duty warden"
    static func sentAt(_ time: String, problem: GateProblem) -> String {
        problem == .scannerNotWorking ? "Sent \(time) · type pass codes for now" : "Sent \(time)"
    }
    static let done = "Done"
}
