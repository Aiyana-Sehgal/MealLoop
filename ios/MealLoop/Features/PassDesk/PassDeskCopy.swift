import Foundation

/// Pass Desk wording from design/reference/pass_desk_2026-10 (P01 to P17, data/pass_desk_spec.md)
/// and design/audit/export_pass_desk. This is wording, not data.
enum PassDeskCopy {
    // Home
    static let specialMeal = "Special meal"
    static let noMealTitle = "No meal today"
    static let noMealDetail = "The next meal will show here."
    static func homeSubtitle(mess: String) -> String { "\(mess) · \(specialMeal)" }
    static func endedSubtitle(mess: String, time: String) -> String { "\(mess) · special meal ended \(time)" }
    static func checkingOpens(_ time: String) -> String { "Checking opens at \(time)" }
    static func mealInProgress(_ count: String) -> String { "Meal in progress · \(count)" }
    static func recordedOf(_ recorded: Int?, _ passes: Int?) -> String {
        "\(recorded.map(String.init) ?? "—") of \(passes.map(String.init) ?? "—")"
    }
    static let lastFourDigits = "Student's last 4 digits"
    static func noStudent(_ digits: String, mess: String) -> String { "No student with \(digits) in \(mess)." }
    static let tryAgain = "Try again"
    static let lookUp = "Look up a student"
    static let lookUpDetail = "Status only. Nothing is recorded."
    static let requestNewPass = "Request a new pass"
    static let reportProblem = "Report a problem"
    static let newPassRequests = "New pass requests"
    static let openProblems = "Open problems"
    static func waitingCount(_ count: Int) -> String { "\(count) waiting" }
    static let mealEndedEyebrow = "Meal ended"
    static func specialHasEnded(_ meal: String) -> String { "\(meal) special has ended" }
    static let checkingClosed = "Checking is closed."
    static let specialMealsRecorded = "Special meals recorded"

    // Check this pass
    static let checkThisPass = "Check this pass"
    static func holderLine(_ holder: SpecialPassHolder) -> String { "\(holder.name) \(holder.student.maskedID)" }
    static func specialLine(meal: String, mess: String) -> String { "\(meal) special · \(mess)" }
    static let screenShouldShow = "Their screen should show"
    static let justChanged = "Just changed"
    static let changesIn = "Changes in"
    static func seconds(_ value: Int) -> String { "\(value) s" }
    static let matchPrompt = "Match the code and the colour on their phone."
    static let matchesRecord = "Matches · record entry"
    static let doesntMatch = "Doesn't match"
    static let codeExpired = "Code expired"
    static let codeExpiredDetail = "Check again for the new code."
    static let codeExpiredNote = "The code window ran out. Check again to get the current code."
    static let checkAgain = "Check again"
    static let backToHome = "Back to Home"

    // Outcomes
    static func context(_ meal: String) -> String { "Pass Desk · \(meal) special" }
    static let passVerified = "Pass verified"
    static func validPass(_ meal: String) -> String { "Valid special-meal pass for \(meal)." }
    static let plusOne = "+1"
    static func ofPasses(_ passes: Int?) -> String? { passes.map { "of \($0)" } }
    static func backToCheck(in seconds: Int) -> String { "Back to the pass check in \(seconds) s" }
    static let checkNext = "Check next"
    static let noSpecialPass = "No special pass"
    static func noValidPass(_ id: String, meal: String) -> String { "\(id) has no valid special-meal pass for \(meal)." }
    static let pass = "Pass"
    static let recorded = "Recorded"
    static let nothing = "Nothing"
    static func noneFor(_ meal: String) -> String { "None for \(meal)" }
    static let regularMeal = "They can still have the regular meal."
    static let checkNextStudent = "Check next student"
    static let wrongMeal = "Wrong meal"
    static func passIsFor(_ meal: String) -> String { "This pass is for \(meal)." }
    static func specialName(_ meal: String) -> String { "\(meal) special" }
    static let alreadyRecorded = "Already recorded"
    static func tookSpecial(_ id: String, time: String) -> String { "\(id) took the special meal at \(time)." }
    static let firstRecorded = "First recorded"
    static let countStays = "Count stays"
    static let nothingAdded = "Nothing was added to the count."
    static let doesntMatchTitle = "Doesn't match"
    static let codeOrColourDifferent = "The code or colour on their phone is different."
    static let shouldShow = "Should show"
    static let colour = "Colour"
    static let refreshAndRetry = "Ask them to refresh their pass and try again. Nothing was recorded."
    static let cantCheck = "Can't check right now"
    static let notChecked = "No connection. This pass is NOT checked."
    static let lastUpdate = "Last update"
    static let neverShownChecked = "A pass is never shown as checked until the pass service answers."
    static func endedWhileChecking(by name: String, at time: String) -> String {
        "\(name) ended the meal at \(time). This pass was not recorded."
    }
    static let endedWhileCheckingNoTime = "The meal has ended. This pass was not recorded."
    static let notRecorded = "Not recorded"

    // Look up
    static let lookUpSubtitle = "Status only. Nothing is recorded."
    static let lookUpAnother = "Look up another"
    static let notAnEntry = "This does not count as an entry."
    static let used = "Used"
    static let notYet = "Not yet"
    static let valid = "Valid"
    static let noPass = "No pass"
    static func regularMealNotEntry() -> String { "They can still have the regular meal. This does not count as an entry." }
    static func passIsForNotEntry(_ meal: String) -> String { "This pass is for \(meal). This does not count as an entry." }

    // Request a new pass
    static let requestSubtitle = "For a student who can't show a valid pass."
    static let why = "Why"
    static let sendRequest = "Send request"
    static let passAdminApproves = "The pass admin approves it. You can follow it under New pass requests."
    static let requestSent = "Request sent to the pass admin."
    static let requestsSeparator = " · "
    static func requestsSubtitle(meal: String?, mess: String) -> String { meal.map { "\($0) · \(mess)" } ?? mess }
    static let noRequests = "No requests yet"
    static let requestsNote = "Approved means the admin said yes. Done means the student has the new pass. The student's Special pass page shows the new pass only when it is Done."
    static func reason(_ reason: PassReissueReason) -> String {
        switch reason {
        case .phoneLost: return "Phone lost"
        case .appProblem: return "App problem"
        case .wrongCode: return "Wrong code"
        case .other: return "Other"
        }
    }
    static func status(_ status: PassReissueStatus) -> String {
        switch status {
        case .waiting: return "Waiting"
        case .approved: return "Approved"
        case .done: return "Done"
        case .rejected: return "Rejected"
        }
    }
    static func sent(_ time: String) -> String { "Sent \(time)" }
    static func sent(_ time: String, reason: String) -> String { "Sent \(time) · \(reason)" }
    static func approvedAt(_ time: String) -> String { "Approved \(time)" }
    static func issuedAt(_ time: String) -> String { "New pass issued \(time)" }
    static let rejectedLine = "Rejected · ask the pass admin"

    // Report a problem
    // Only Food running short leaves this phone (PassDeskProblemLog), so the others say saved, whatever the frame draws.
    static let pickOne = "Pick what went wrong."
    static let sentOnTap = "It is saved as soon as you tap."
    static let savedToast = "Report saved. It is under Open problems."
    static let savedLine = "Saved ·"
    static let couldNotSend = "Couldn't save. Nothing was saved."
    static let whichFood = "Which food is short?"
    static let somethingElse = "Something else"
    static let sendToKitchen = "Send to the kitchen"
    static func kitchenGetsIt(_ name: String) -> String { "\(name) and the kitchen team get it at once." }
    static func foodShortSent(_ name: String) -> String { "Sent to the kitchen and \(name)." }
    static let foodRunningShort = "Food running short"
    static let waiting = "Waiting"
    static let savedOnPhone = "Reports are saved on this phone. Food shortages go to the kitchen."
    static let noOpenProblems = "No open problems"
    static let noOpenProblemsDetail = "Anything you report shows here."

    // Alerts
    static let alerts = "Alerts"
    static let earlier = "Earlier"
    static let mealStarted = "Meal started"
    static func opened(by name: String, meal: String) -> String { "\(name) opened \(meal)." }
    static let newPassApproved = "New pass approved"
    static func canGetPass(_ id: String) -> String { "\(id) can get the pass." }
    static let foodShortageSeen = "Food shortage seen"
    static let kitchenOnIt = "The kitchen is on it."
    static let nothingNew = "Nothing new"
    static let alertsShowHere = "Alerts from your supervisor show here."

    // SOS
    static let sosEyebrow = "SOS"
    static func sosActive(_ count: Int) -> String { "SOS · \(count) active" }
    static func minutesAgo(_ minutes: Int) -> String { "\(minutes) min ago" }
    static let nobodyTaken = "Nobody has taken this yet"
    static let youreChecking = "You're checking this"
    static func isChecking(_ role: String) -> String { "\(role) is checking this" }
    static let checkedByDesk = "Checked by the desk"
    static let sosHelper = "Only if you're free. Keep checking passes first if the desk is busy."
    static func onYourWay(_ name: String) -> String { "\(name) and the kitchen team can see you're on your way." }
    static let illGoAndCheck = "I'll go and check"
    static let notNow = "Not now"
    static let markAsChecked = "Mark as checked"
    static let backToChecking = "Back to checking passes"
    static let openTheSOS = "Open the SOS"
    static func markedAsChecked(_ name: String) -> String { "Marked as checked. \(name) will close it." }
    static let sosFailed = "Couldn't save that. Try again."

    // Me
    static let me = "Me"
    static let onShift = "On shift"
    static func onShift(since time: String) -> String { "On shift · since \(time)" }
    static let passesChecked = "Passes checked"
    static let problemsReported = "Problems reported"
    static let language = "Language"
    static let english = "English"
    static let help = "Help"
    static let signOut = "Sign out"
}
