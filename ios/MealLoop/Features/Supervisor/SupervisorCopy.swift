import Foundation

/// Supervisor wording from design/reference/supervisor_2026-10/data/supervisor_spec.md and the S00–S19 exports
/// (design/audit/export_supervisor/). Lines the pack does not draw are marked "Not drawn" and listed in
/// docs/verification/supervisor/REPORT.md.
enum SupervisorCopy {
    /// "This meal" block on Alerts (Prompt 5, R2).
    // MARK: Tabs and titles
    static let alertsTitle = "Alerts"
    static let meTitle = "Me"
    static let shortageTitle = "Shortage details"
    static let wasteReportTitle = "Waste report"
    static let historyTitle = "Meal history"
    static let loadingHistory = "Loading meal history…"
    static let couldntLoadHistory = "Couldn't load meal history"
    static let checkConnection = "Check the connection and try again."
    static let retry = "Retry"
    static let offlineMark = "Offline"

    // MARK: Home (S01, S02, S06)
    static let notStarted = "Not started"
    static let forecastEyebrow = "Forecasted attendance"
    static let forecastCaption = "expected diners"
    static let forecastNotReady = "Forecast not ready yet"
    static let startMeal = "Start meal"
    static let liveEyebrow = "Live"
    static let liveCaption = "students entered"
    static let closeMeal = "Close meal"
    static let closed = "Closed"
    static let mealClosedEyebrow = "Meal closed"
    static let finalEntries = "Final entries"
    static let unavailable = "Unavailable"
    /// S06b.
    static let finalCountMissing = "The final count did not arrive."
    static let wasteNotRecorded = "Waste not recorded"
    static let activeShortages = "Active shortages"
    static let noMealToday = "No meal today"
    static let noMealTodayDetail = "The next meal will show here."
    static let offline = "Offline"

    static func inService(_ elapsed: String) -> String { "In service · \(elapsed)" }
    static func hasEnded(_ meal: String) -> String { "\(meal) has ended" }
    static func mealAndMess(_ meal: String, _ mess: String) -> String { "\(meal) · \(mess)" }

    // MARK: Dialogs (S13, S14, S15, S17)
    static func startDialog(meal: String, mess: String) -> ConfirmDialogContent {
        ConfirmDialogContent(title: "Start this meal?", subject: mealAndMess(meal, mess),
                             detail: "Door scanner and pass desk will open.", cancelTitle: cancel, actionTitle: startMeal)
    }

    static func closeDialog(meal: String, mess: String) -> ConfirmDialogContent {
        ConfirmDialogContent(title: "Close this meal?", subject: mealAndMess(meal, mess),
                             detail: "Door scanner and pass desk will stop.", cancelTitle: cancel, actionTitle: closeMeal)
    }

    static func resolveDialog(item: String) -> ConfirmDialogContent {
        ConfirmDialogContent(title: "Mark shortage as resolved?", subject: item, cancelTitle: cancel, actionTitle: markResolved)
    }

    static let signOutDialog = ConfirmDialogContent(title: "Sign out?", cancelTitle: cancel, actionTitle: signOut)
    static let cancel = "Cancel"

    // MARK: Alerts (S07, S08, S09)
    static let shortagesGroup = "Shortages"
    static let active = "Active"
    static let notRecorded = "Not recorded"
    static let caughtUp = "You're all caught up"
    static let caughtUpDetail = "No active shortages or missing waste reports."
    static let shortageResolvedToast = "Shortage marked resolved"

    static func shortageDetail(level: String, posted: String) -> String { "\(level) · posted \(posted)" }
    static func closedAt(_ time: String) -> String { "Closed \(time)" }
    static let enteredWord = "entered"
    static func entered(_ count: Int) -> String { "\(count) \(enteredWord)" }

    // MARK: Shortage (S12)
    static let item = "Item"
    static let posted = "Posted"
    static let status = "Status"
    static let markResolved = "Mark resolved"
    static let resolved = "Resolved"

    static func byReporter(_ who: String) -> String { "by \(who)" }

    // MARK: Waste report (S10, S11)
    static let recordedByKitchen = "Recorded by the kitchen"
    static let unservedFood = "Unserved food"
    static let plateWaste = "Plate waste"
    static let reportDetails = "Report details"
    static let foodLeftOver = "Food left over, by dish"
    static let plateWasteWholeMeal = "Plate waste, whole meal"
    static let noneLeft = "none left"
    static let notMade = "not made"
    static let readOnlyKitchen = "Read only. The kitchen records this report."
    static let notSavedYet = "The kitchen has not saved this report yet. Nothing to do here."
    /// Not drawn: a recorded report whose quantities the record does not hold (S19f, S19d have no View report).
    static let quantitiesMissing = "The kitchen's quantities for this report are not available here."

    static func dishes(_ count: Int) -> String { count == 1 ? "dish" : "dishes" }

    // MARK: SOS (S03, S04, S05; spec "SOS")
    static func sosActive(_ count: Int) -> String { "SOS · \(count) active" }
    static let sosWord = "SOS"
    static let nobodyYet = "Nobody has taken this yet"
    static let illGo = "I'll go and check"
    static let notNow = "Not now"
    static let freeHelper = "Only if you're free. Keep the meal running first if it is busy."
    static let youreChecking = "You're checking this"
    /// Decision 7 of design/audit/supervisor/decisions.md (no image of this helper).
    static let claimedHelper = "When you have seen it, mark it as checked. You can close the case after."
    static let markChecked = "Mark as checked"
    static let backToMeal = "Back to meal"
    static let closeWhenSatisfied = "Close the case when you are satisfied."
    static let closeCase = "Close case"
    static let notYet = "Not yet"
    static let caseClosedToast = "Case closed"

    static func checkedBy(_ who: String) -> String { "Checked by \(who)" }
    /// Not drawn: someone else claimed the case but has not checked it yet.
    static func isChecking(_ who: String) -> String { "\(who.prefix(1).uppercased())\(who.dropFirst()) is checking this" }
    static func ago(_ elapsed: String) -> String { "\(elapsed) ago" }

    // MARK: Me (S16, S17)
    static let followUps = "Follow-ups"
    static let signOut = "Sign out"

    // MARK: History (S18, S19)
    static let noMealsYet = "No meals yet"
    static let noMealsYetDetail = "Meals show here after they are closed."
    static let noShortage = "No shortage"
    static let shortageActive = "Shortage active"
    static let shortageResolved = "Shortage resolved"
    static let wasteRecorded = "Waste recorded"
    static let byKitchen = "By the kitchen"
    static let recorded = "Recorded"
    static let viewReport = "View report"
    static let readOnly = "Read only."
    static let wasteReportGroup = "Waste report"

    static func shortageCount(_ count: Int) -> String { count == 1 ? "1 shortage" : "\(count) shortages" }
    static func dayAndMeal(_ day: String, _ meal: String) -> String { "\(day) · \(meal)" }
}
