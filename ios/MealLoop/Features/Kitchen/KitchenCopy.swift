import Foundation

/// Kitchen Staff wording from design/reference/kitchen_2026-10/data/kitchen_spec.md and the K01–K05 exports.
enum KitchenCopy {
    static let forecastEyebrow = "Forecasted attendance"
    static let forecastCaption = "expected diners"
    static let forecastNotReady = "Forecast not ready yet"
    static let liveEyebrow = "Live"
    /// Students entered at the door. Never "meals served" and never "recorded at the door".
    static let liveCaption = "students entered"
    static let reportShortage = "Report food running short"
    static let mealClosedEyebrow = "Meal closed"
    static let finalEntriesLabel = "Final entries"
    static let unavailable = "Unavailable"
    static let menuRow = "Menu for"
    static let pastMealsRow = "Past meals"
    static let seeAll = "See all"
    static let wasteReportTitle = "Waste report"
    static let recordWaste = "Record waste"
    static let continueWaste = "Continue"
    static let viewReport = "View report"
    static let retry = "Retry"
    static let couldNotSend = "Couldn't send"

    static func mealInProgress(_ elapsed: String) -> String { "Meal in progress · \(elapsed)" }
    static func hasEnded(_ mealName: String) -> String { "\(mealName) has ended" }
    static func ended(at time: String) -> String { "ended \(time)" }
    static func shortageTitle(dish: String, level: String) -> String { "\(dish), \(level)" }
    static func seenBy(_ name: String) -> String { "\(name) saw it" }
    static func draftProgress(done: Int, total: Int) -> String { "\(done) of \(total) done · saved" }
    static func recorded() -> String { "Recorded ·" }
    static func editUntil(_ time: String) -> String { "You can edit until \(time)." }
    static let editingClosed = "Editing closed after 6 hours."
    static let avatarLabel = "Your profile"

    // Shortage report (K04, K04f, K04g)
    static let whichFood = "Which food is short?"
    static let howBad = "How bad? (optional)"
    static let addNote = "Add a note (optional)"
    static let notePlaceholder = "Note"
    static func sendTo(_ name: String) -> String { "Send to \(name)" }
    static func sentTo(_ name: String) -> String { "Sent to \(name)" }
    static func alreadyReported(_ time: String) -> String { "Already reported at \(time)." }
    static func reportAgainDetail(_ title: String) -> String { "\(title). Report it again?" }
    static let reportAgain = "Report again"
    static let cancel = "Cancel"
    static let reportNotSent = "Your shortage report was not sent."
    static let mealEndedLabel = "Meal ended"
    static let shortageReportLabel = "Shortage report"
    static let notSent = "Not sent"
    static let leftOverGoesInWaste = "Food left over goes in Record waste."
    static let backToHome = "Back to Home"
    static let shortageReportsTitle = "Shortage reports"

    static func level(_ level: ShortageLevel) -> String {
        switch level {
        case .gettingLow: return "Getting low"
        case .almostOut: return "Almost out"
        case .out: return "Out"
        }
    }

    // Record waste (K06, K07, K08)
    static let editReport = "Edit report"
    static func wasteSubtitle(meal: String, mess: String, day: String) -> String { "\(meal) · \(mess) · \(day)" }
    static func done(_ done: Int, of total: Int) -> String { "Done \(done) of \(total)" }
    static let foodLeftOver = "Food left over · each dish in its own unit"
    static let foodLeftOverShort = "Food left over"
    static let noneLeft = "None left"
    static let noneLeftLower = "none left"
    static let notMade = "Not made"
    static let notMadeLower = "not made"
    static let notEntered = "Not entered"
    static func enter(_ unit: String) -> String { "Enter \(unit)" }
    static let addADish = "Add a dish"
    static let plateWaste = "Plate waste"
    static let plateWasteWhole = "Plate waste, whole meal"
    static let saveDraft = "Save draft"
    static let keepEditing = "Keep editing"
    static let reviewAndSave = "Review and save"
    static let saveThisAsDraft = "Save this as a draft?"
    static func draftPromptDetail(_ dish: String?) -> String {
        dish.map { "You entered \($0). Save it and finish later, or keep editing." } ?? "Save it and finish later, or keep editing."
    }
    static let draftSaved = "Draft saved"
    static func leftOverIn(_ unit: String) -> String { "Left over, in \(unit)" }
    static let plateWasteDetail = "One total for the whole meal, in kg"
    static func upTo(_ limit: String, unit: String) -> String { "Up to \(limit) \(unit)" }
    static func enterNumberUpTo(_ limit: String) -> String { "Enter a number up to \(limit)." }
    static let save = "Save"
    static let addDishDetail = "For a dish that is not on the menu today."
    static let dishName = "Dish name"
    static let unit = "Unit"
    static let addDish = "Add dish"
    static let checkAndSave = "Check and save"
    static func mealAndMess(_ meal: String, _ mess: String) -> String { "\(meal) · \(mess)" }
    static let youCanEditLater = "You can edit this later."
    static let saveReport = "Save report"
    static let backToEdit = "Back to edit"
    static let everyDishNeeds = "Every dish needs an amount, None left or Not made."
    static func enterMore(_ count: Int) -> String { "Enter \(count) more" }
    static let saveFailed = "Couldn't save. Nothing was changed."
    static func contextLine(_ meal: String) -> String { "Kitchen · \(meal)" }
    static let reportSaved = "Report saved"
    static func editItUntil(_ time: String) -> String { "You can edit it until \(time)." }
    static let saved = "Saved"
    static let dishes = "Dishes"
    static func dishCount(_ done: Int, of total: Int) -> String { "\(done) of \(total)" }

    // History and past meal (K09 to K11, K18)
    static let historyTitle = "Meal history"
    static let enteredWord = "entered"
    static let recordedWord = "Recorded"
    static let notRecorded = "Not recorded"
    static let historyFooter = "Today's meal appears here after it ends."
    static let noMealsYet = "No meals yet"
    static let noMealsYetDetail = "Ended meals show here."
    static func dayAndMeal(_ day: String, _ meal: String) -> String { "\(day) · \(meal)" }
    static let youCanStillAdd = "You can still add it."
    static let quantitiesUnavailable = "The quantities for this report are not available here."

    // Alerts (K12)
    static let alerts = "Alerts"
    static let mealEnded = "Meal ended"
    static func recordWasteFor(_ meal: String) -> String { "Record waste for \(meal)." }
    static let shortageSeen = "Shortage seen"
    static func sawDish(_ name: String, dish: String) -> String { "\(name) saw: \(dish)." }
    static let foodShort = "Food short"
    static func atPassDesk(_ dish: String) -> String { "\(dish) · pass desk" }
    static let wasteNotRecorded = "Waste not recorded"
    static func addIt(_ meal: String) -> String { "\(meal) · add it" }
    static let nothingNew = "Nothing new"
    static let alertsShowHere = "Meal and shortage updates show here."

    // Me (K13)
    static let me = "Me"
    static let onShift = "On shift"
    static let switchRole = "Switch role"
    static let language = "Language"
    static let english = "English"
    static let help = "Help"
    static let signOut = "Sign out"

    // SOS (K14, K19, K20)
    static let sosEyebrow = "SOS"
    static func sosActive(_ count: Int) -> String { "SOS · \(count) active" }
    static let nobodyTaken = "Nobody has taken this yet"
    static func isChecking(_ role: String) -> String { "\(role) is checking" }
    static let youreChecking = "You're checking this"
    /// The edge tab is 58 pt wide, so it keeps the short form.
    static let tabChecking = "You're checking"
    static let checkedByKitchen = "Checked by the kitchen"
    static let sosHelper = "Only if you're free. Keep cooking first if the kitchen is busy."
    static let illGoAndCheck = "I'll go and check"
    static let notNow = "Not now"
    static func onYourWay(_ name: String) -> String { "\(name) and the kitchen team can see you're on your way." }
    static let markAsChecked = "Mark as checked"
    static let markedAsChecked = "Marked as checked"
    static let backToCooking = "Back to cooking"
    static let openTheSOS = "Open the SOS"
    static let sosFailed = "Couldn't update the SOS. Nothing was changed."
    static func minutesAgo(_ minutes: Int) -> String { "\(minutes) min ago" }
}

/// Sizes the design draws for this role.
enum KitchenLayout {
    /// The count on the before and during cards: 65 pt per digit on K01 and K02 at 393 pt.
    static let heroNumber: CGFloat = 108
    /// Final entries on the closed card, smaller on K05.
    static let finalNumber: CGFloat = 68
    static let tabBarClearance: CGFloat = 96
    static let scrollBottomInset: CGFloat = 120
    static let meAvatar: CGFloat = 92
    static let keyHeight: CGFloat = 52
    static let savedTick: CGFloat = 160
}

/// Quantities with their own unit, and short dates. Units are never converted.
enum KitchenFormat {
    static func number(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }

    static func quantity(_ value: Double, _ unit: WasteUnit) -> String { "\(number(value)) \(unit.symbol)" }

    /// "Wed 14 Aug"
    static func dayLine(_ date: Date, in timeZone: TimeZone) -> String { format("EEE d MMM", date, timeZone) }

    /// "Wed 14"
    static func shortDay(_ date: Date, in timeZone: TimeZone) -> String { format("EEE d", date, timeZone) }

    private static func format(_ pattern: String, _ date: Date, _ timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}
