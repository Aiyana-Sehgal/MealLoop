import Foundation

/// Door Scanner wording from design/reference/door_scanner_2026-10/data/door_scanner_spec.md and the D04–D18 exports.
enum DoorScannerCopy {
    // Home
    static func mealInProgress(_ elapsed: String) -> String { "Meal in progress · \(elapsed)" }
    static func scanningOpens(at time: String) -> String { "Scanning opens at \(time)" }
    /// The camera is not connected in this build, so the card says so instead of "Point at the student's QR".
    static let cameraOff = "Camera is off. Use Type ID."
    static let recordedIn = "Recorded in"
    static let typeID = "Type ID"
    static let reportProblem = "Report a problem"
    static let noConnection = "No connection"
    static let noConnectionDetail = "Scans can't be checked right now. Nothing is recorded."
    static let mealEndedEyebrow = "Meal ended"
    static func hasEnded(_ meal: String) -> String { "\(meal) has ended" }
    static let scanningClosed = "Scanning is closed."
    static let finalEntries = "Final recorded entries"
    static let unavailable = "Unavailable"
    static func ended(at time: String) -> String { "ended \(time)" }
    static let enteredWithoutVoting = "Entered without voting"
    static let openProblems = "Open problems"
    static let noMealTitle = "No meal today"
    static let noMealDetail = "The next meal will show here."

    // Type the last 4 digits
    static let typeLastFour = "Type the last 4 digits"
    static let lastFourField = "Student's last 4 digits"
    static let recordEntry = "Record entry"
    static let tryAgain = "Try again"
    static func noStudent(_ digits: String, mess: String) -> String { "No student with \(digits) in \(mess)." }
    static let checkCard = "Check the last 4 digits on the SRM ID card."
    static func cantCheck(_ digits: String) -> String { "Can't check \(digits) right now" }
    static let cantCheckDetail = "No connection. This entry is NOT recorded. Ask the student to wait or try again when the connection is back."

    // Results
    static func context(_ meal: String) -> String { "Door Scanner · \(meal)" }
    static let entryRecorded = "Entry recorded"
    static let recordedSoFar = "Recorded in so far"
    static let plusOne = "+1"
    static func backHome(in seconds: Int) -> String { "Back to Home in \(seconds) s" }
    static let scanNext = "Scan next"
    static func addedWithoutVoting(_ student: String) -> String { "No meal response, so \(student) is added to Entered without voting." }
    static let alreadyScanned = "Already scanned"
    static func wasRecorded(_ student: String, meal: String) -> String { "\(student) was recorded for \(meal)." }
    static let firstScanned = "First scanned"
    static let countStays = "Count stays"
    static let nothingAdded = "Nothing was added to the count."
    static let qrNotRecognised = "QR not recognised"
    static let notEntryCode = "This is not a MealLoop entry code."
    static let notRecognisedNote = "It may be a QR for another meal or an old screenshot. Ask them to open Entry QR in the app."
    static let scanAgain = "Scan again"
    static let wrongMeal = "Wrong meal"
    static let wrongMealDetail = "This code isn't for the meal being served."
    static let scanningNow = "Scanning now"
    static let noMealServed = "No meal"
    static func askForEntryQR(_ meal: String) -> String { "Ask the student to open Entry QR for \(meal)." }
    static let cantCheckNow = "Can't check right now"
    static let notRecorded = "No connection. This entry is NOT recorded."
    static let lastUpdate = "Last update"
    static let entriesWaiting = "Entries waiting"
    static let neverShownRecorded = "Entries are never shown as recorded until they are saved."
    static func endedWhileScanning(by name: String, at time: String) -> String { "\(name) ended the meal at \(time) while you were scanning. This scan was not recorded." }
    static let endedWhileScanningNoTime = "The meal ended while you were scanning. This scan was not recorded."
    static let thisScan = "This scan"
    static let notRecordedValue = "Not recorded"
    static let backToHome = "Back to Home"

    // Report a problem
    static func pickOne(_ name: String) -> String { "Pick one. \(name) gets it at once." }
    static let sentOnTap = "It is sent as soon as you tap."
    static func sentToast(_ name: String) -> String { "Sent to \(name). It is under Open problems." }
    static let couldNotSend = "Couldn't send. No connection, so nothing was sent."
    static func sentLine(to name: String) -> String { "Sent to \(name) ·" }
    static let waiting = "Waiting"
    static let noOpenProblems = "No open problems"
    static let noOpenProblemsDetail = "Problems you report show here."

    // Entered without voting
    static func withoutVotingSubtitle(meal: String, mess: String, count: Int) -> String {
        "\(meal) · \(mess) · \(count) \(count == 1 ? "student" : "students")"
    }
    static let addedAutomatically = "Added automatically when scanned."
    static let nobodyWithoutVoting = "Nobody yet"
    static let nobodyWithoutVotingDetail = "Students with no meal response are added here when scanned."

    // Alerts
    static let alerts = "Alerts"
    static let earlier = "Earlier"
    static let nothingNew = "Nothing new"
    static func alertsShowHere(_ name: String) -> String { "Alerts from \(name) show here." }
    static let mealStarted = "Meal started"
    static func opened(by name: String, meal: String) -> String { "\(name) opened \(meal)." }
    static func closed(_ meal: String) -> String { "\(meal) closed" }
    static func recordedAtDoor(_ count: Int) -> String { "\(count) recorded at the door." }

    // SOS
    static let sosEyebrow = "SOS"
    static func sosActive(_ count: Int) -> String { "SOS · \(count) active" }
    static func minutesAgo(_ minutes: Int) -> String { "\(minutes) min ago" }
    static let nobodyTaken = "Nobody has taken this yet"
    static let youreChecking = "You're checking this"
    static func isChecking(_ role: String) -> String { "\(role) is checking this" }
    static func onYourWay(_ name: String) -> String { "\(name) and the kitchen team can see you're on your way." }
    static let sosHelper = "Only if you're free. Keep scanning first if the door is busy."
    static let illGoAndCheck = "I'll go and check"
    static let openTheSOS = "Open the SOS"
    static let notNow = "Not now"
    static let markAsChecked = "Mark as checked"
    static let backToScanning = "Back to scanning"
    static let markedAsChecked = "Marked as checked"
    static func checkedBy(_ role: Role) -> String {
        switch role {
        case .doorScanner: return "Checked by the door"
        case .passDesk: return "Checked by the desk"
        case .kitchenStaff: return "Checked by the kitchen"
        case .supervisor: return "Checked by the supervisor"
        default: return "Checked"
        }
    }
    static let sosFailed = "Couldn't update the SOS. Nothing was changed."

    // Me
    static let me = "Me"
    static let onShift = "On shift"
    static let problemsReported = "Problems reported"
    static let switchRole = "Switch role"
    static let language = "Language"
    static let help = "Help"
    static let signOut = "Sign out"
}
