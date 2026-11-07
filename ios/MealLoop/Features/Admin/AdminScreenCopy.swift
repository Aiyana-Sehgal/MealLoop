import Foundation

/// Wording for the Students, Results and More tabs, from design/reference/admin_redesign_2026-10 and fix2_2026-10.
/// Sample values come from the repositories, never from here. REPORT.md lists wording the packs do not draw.
enum AdminScreenCopy {
    static let nothingYet = "Nothing here yet"
    static let couldNotSave = "Couldn't save. Nothing was changed."
    static let offlineNothingSaved = "No connection. Nothing was saved."
    static let cancel = "Cancel"
    static let sample = "All data is sample"
    static let brand = "MealLoop"

    static func meals(_ count: Int) -> String { count == 1 ? "meal" : "meals" }
    static func countMeals(_ count: Int) -> String { "\(count) \(meals(count))" }
    static func students(_ count: Int) -> String { count == 1 ? "student" : "students" }

    static func tag(_ tag: ReasonTag) -> String {
        switch tag {
        case .sure: return "Sure"
        case .probably: return "Probably"
        case .cantTell: return "Can't tell"
        }
    }

    // Results
    static let results = "Results"
    static let leftOver = "Left over"
    static let ranOut = "Ran out"
    static let toCheck = "To check"
    static let foodLeftOverAt = "Food was left over at"
    static let foodRanOutAt = "Food ran out at"
    static func mealsOf(_ meals: Int, _ total: Int) -> String { "\(meals) of \(total) meals" }
    static let why = "Why · a meal can have more than one reason"
    static func reviewTheseMeals(_ count: Int) -> String { "Review these meals · \(count)" }
    static func changesBeingTested(_ count: Int) -> String { "Changes being tested · \(count)" }
    static let review = "Review"
    static let weeklyReport = "Weekly report"
    static let findOlderMeal = "Find an older meal"
    static let safetyCases = "Safety cases"
    static func checked(_ counted: Int, _ required: Int) -> String { "\(counted) of \(required) meals checked" }
    static func owner(_ name: String) -> String { "Owner \(name)" }
    static func stage(_ stage: CheckStage) -> String {
        switch stage {
        case .open: return "Open"
        case .testing: return "Testing"
        case .result: return "Result"
        }
    }

    /// A row of To check. Nil facts say so rather than reading as nothing.
    static func reviewDetail(_ meal: AdminMealFacts) -> String {
        guard meal.isClosed else { return notClosedYet }
        if let ranOut = meal.ranOut.first, meal.leftovers.isEmpty {
            return meal.wasReportedLate ? "\(ranOut.dish) ran out · reported late" : "\(ranOut.dish) ran out"
        }
        let counts = "\(AdminFormat.count(meal.finalEntries)) of \(AdminFormat.count(meal.headcountSent))"
        guard let food = meal.leftovers.first else { return counts }
        return "\(food.dish) left over · \(counts)"
    }

    // Reason pages
    static func reasonLine(_ meals: Int) -> String { "\(countMeals(meals)) · last 4 weeks" }
    static func theMeals(_ count: Int) -> String { count == 1 ? "The meal" : "The \(count) meals" }
    static func moreMeals(_ count: Int) -> String { count == 1 ? "1 more meal" : "\(count) more meals" }
    static func inMeals(_ count: Int) -> String { "in \(countMeals(count))" }
    static func foodAt(time: String, mess: String) -> String { "at \(time) · \(mess)" }
    static let missing = "Missing"
    static let tellTheVendor = "Tell the vendor"
    static let entriesEvery15 = "Entries every 15 minutes"
    static let forecast = "forecast"
    static func raised(_ time: String) -> String { "raised \(time)" }
    static let came = "came"
    static func reasonGiven(_ reason: String) -> String { "Reason given: \(reason)." }
    static func ranOutAt(_ dish: String, _ time: String) -> String { "\(dish) ran out \(time)" }
    /// A09_reason_more_came draws "8% more"; a reason never carries a percentage, so this is the count.
    static func moreThanSent(came: Int, more: Int) -> String { "\(AdminFormat.count(came)) came, \(more) more than the headcount sent." }
    static func evidence(_ item: MissingEvidence) -> String {
        switch item {
        case .amountCooked: return "Amount cooked (vendor)"
        case .eventCount: return "Event count"
        case .scannerRecords: return "Scanner records"
        case .wasteRecord: return "Waste record"
        }
    }
    static func evidenceOnCard(_ item: MissingEvidence) -> String {
        switch item {
        case .amountCooked: return "Vendor cooked: not shared"
        case .eventCount: return "Event count: not recorded"
        case .scannerRecords: return "Scanner records: missing"
        case .wasteRecord: return "Waste: not recorded"
        }
    }
    static func evidenceLine(_ item: MissingEvidence) -> String {
        switch item {
        case .amountCooked: return "Quantity cooked: not shared by the vendor"
        case .eventCount: return "Event count: not recorded"
        case .scannerRecords: return "Scanner records: missing"
        case .wasteRecord: return "Waste record: not recorded by the kitchen"
        }
    }

    // Meal report
    static let mealReport = "Meal report"
    static func reportSubtitle(slot: String, mess: String, day: String) -> String { "\(slot) · \(mess) Mess · \(day)" }
    static let needsReview = "Needs review"
    static let reviewed = "Reviewed"
    static let headcountSent = "Headcount sent"
    static let cameInFinal = "Came in · final"
    static let notClosedYet = "Not closed yet: no final count"
    static func sentAt(_ time: String) -> String { "Sent \(time)" }
    static func closedAt(_ time: String) -> String { "Closed \(time)" }
    static func left(_ dish: String) -> String { "\(dish) left" }
    static let plateWaste = "Plate waste"
    static let data = "Data"
    static func raisedLine(from: Int, to: Int, reason: String) -> String { "Headcount raised \(from) → \(to) · \(reason)" }
    static func cameLine(came: Int, sent: Int) -> String {
        let difference = abs(came - sent)
        if came == sent { return "\(AdminFormat.count(came)) came in, the same as sent" }
        return "\(AdminFormat.count(came)) came in, \(difference) \(came < sent ? "fewer" : "more") than sent"
    }
    static func ranOutLine(_ dish: String, _ time: String, reported: String?) -> String {
        reported.map { "\(dish) ran out \(time) · \($0)" } ?? "\(dish) ran out \(time)"
    }
    static func notRecorded(_ question: String) -> String { "\(question) Not recorded" }
    static let checkNextTime = "Check next time"

    // Make it a change
    static let makeItAChange = "Make it a change"
    static let whatWillChange = "What will change"
    static let ownerLabel = "Owner"
    static func you(_ name: String) -> String { "\(name) (you)" }
    static let checkAfter = "Check after"
    static func comparableAfter(_ required: Int) -> String { "\(required) comparable meals" }
    static func canOnlyClose(_ required: Int) -> String {
        "It can only be closed as worked after \(required) comparable meals, and it also checks for running out."
    }
    static let save = "Save"

    // Check next time page
    static func startedBy(mess: String, day: String, by: String) -> String { "\(mess) · started \(day) by \(by)" }
    static let wellChange = "What we'll change"
    static func ownerAndPlan(_ owner: String, _ plan: String) -> String { "Owner \(owner) · \(plan)" }
    static func sentAndCame(sent: Int?, came: Int?) -> (sent: String, came: String) { (AdminFormat.count(sent), AdminFormat.count(came)) }
    static let sentWord = "sent"
    static let cameWord = "came"
    static let waiting = "waiting"
    static let notEnoughData = "Not enough data yet"
    static let workedVerified = "Worked"
    static let actionDoneNotResult = "The change is in place. That is not the same as it having worked."
    static let addNote = "Add a note"
    static let closeAsWorked = "Close as worked"
    static let noteTitle = "Add a note"
    static let notePlaceholder = "What did you see?"

    // Find a meal
    static let findAMeal = "Find a meal"
    static let anyMeal = "Any meal in the last 4 weeks"
    static let allMesses = "All"
    static let noMealsFound = "No meals found"
    static let noMealsFoundDetail = "Try another mess or meal."
    static func findRowDetail(_ meal: AdminMealFacts) -> String {
        var parts = ["\(AdminFormat.count(meal.headcountSent)) sent → \(AdminFormat.count(meal.finalEntries)) came"]
        if meal.needsReview {
            parts.append(needsReview)
        } else if !meal.leftovers.isEmpty {
            parts.append(meal.leftovers.map { "\($0.dish) \(AdminFormat.amount($0))" }.joined(separator: ", ") + " left")
        }
        return parts.joined(separator: " · ")
    }

    // Safety
    static let open = "Open"
    static let closed = "Closed"
    static let noClosedCases = "No closed cases in the last 4 weeks."
    static let safetyCase = "Safety case"
    static func caseSubtitle(mess: String, day: String, slot: String, dish: String) -> String { "\(mess) Mess · \(day) \(slot) · \(dish)" }
    static func caseRow(mess: String, day: String, slot: String, dish: String, elapsed: String?) -> String {
        [mess, "\(day) \(slot)", dish, elapsed.map { "open \($0)" }].compactMap { $0 }.joined(separator: " · ")
    }
    static func caseOpen(_ elapsed: String) -> String { "Open · \(elapsed)" }
    static func caseClosed(_ time: String) -> String { "Closed · \(time)" }
    static func proofPlace(_ place: String, metres: Int) -> String { "\(place) · ±\(metres) m" }
    static func proofTime(_ time: String) -> String { "\(time) · photo taken live" }
    static let whoDidWhat = "Who did what"
    static func call(_ name: String) -> String { "Call \(name)" }
    static let callNotBuilt = "Calling isn't part of this prototype. Nothing happened."

    // Tell the vendor
    static let preparedMessage = "Prepared message"
    static let preparedSummary = "Prepared summary · meal counts only"
    static let summaryRule = "Only meal counts and reasons. No student names or IDs."
    static let vendor = "Vendor"
    static let vendorNothingSent = "MealLoop opens your phone; nothing is sent for you."
    static let message = "Message"
    static let call = "Call"
    static let vendorNotBuilt = "Opening your phone isn't part of this prototype. Nothing was sent."
    static func vendorMessage(_ meal: AdminMealFacts, today: String, name: String) -> String {
        var text = "Hi, this is \(name) from MealLoop. \(meal.mess) Mess \(MLFormat.mealSlot(meal.slot).lowercased()) (\(today)): "
        text += "headcount \(AdminFormat.count(meal.headcountSent)), \(AdminFormat.count(meal.finalEntries)) came."
        if let food = meal.leftovers.first { text += " \(food.dish) \(AdminFormat.amount(food)) was left." }
        return text + " Could you share how much was cooked, so we can plan better?"
    }
    static func vendorSafety(_ item: AdminSafetyCase, day: String, name: String) -> String {
        "Hi, this is \(name) from MealLoop. \(item.mess) Mess, \(day): a student reported \"\(item.title.lowercased())\" in the \(item.dish.lowercased()). Please hold it until we have checked."
    }
    static func vendorFeedback(_ item: FeedbackItem, name: String) -> String {
        "Hi, this is \(name) from MealLoop. \(item.students) students said the \(item.dish.lowercased()) was \(item.problem) at \(item.mess) Mess. Could you look into it?"
    }

    // Weekly report
    static let thisWeek = "This week"
    static let lastWeek = "Last week"
    static let month = "Month"
    static func mealsLeftOver(_ count: Int) -> String { "\(meals(count)) left over" }
    static func mealsRanOut(_ count: Int) -> String { "\(meals(count)) ran out" }
    static let dataComplete = "data complete"
    static let inTheReport = "In the report"
    static func page(_ number: Int) -> String { "page \(number)" }
    static let exportPDF = "Export PDF"
    static let exportCSV = "Export CSV"
    static let sendToVendor = "Send to vendor"
    static let preparing = "Preparing the preview..."
    /// F02 draws "Report ready", "Save to Files", "Share" and saved toasts. No file exists, so this is a preview.
    static let reportPreview = "Report preview"
    static func previewSubtitle(_ range: String, pages: Int) -> String { "\(range) · \(pages) pages" }
    static let noFileMade = "PDF and CSV files aren't built. This is a preview: no file was made."
    static let csvNotBuilt = "CSV export isn't built. No file was made."
    static let noBreakdownDrawn = "Only This week has a page breakdown in this prototype."
    static let pageOne = "Page 1"
    static let pageTwo = "Page 2"
    static let reportTitle = "Weekly report"
    static let reportContinued = "Weekly report, continued"
    static func reportFor(_ range: String, _ name: String) -> String { "\(range) · For \(name), food head" }
    static let recordsComplete = "of records complete"
    static let whyLeftOver = "Why food was left over"
    static let countsAreMeals = "Counts are meals. A meal can have more than one reason."
    static let foodsLeftOver = "Foods left over"
    static let byMess = "By mess"
    static let mess = "Mess"
    static let ranOutMeals = "Ran out (meals)"
    static let noData = "No data"
    static let changesWeTested = "Changes we tested"
    static let dataGaps = "Data gaps"
    static func pageOf(_ page: Int, _ total: Int) -> String { "Page \(page) of \(total)" }
    static func foodLine(_ food: ReportFoodLine) -> String { "\(countMeals(food.meals)) · \(food.amount)" }

    // Students
    static let studentsTitle = "Students"
    static let whatNeedsYou = "What needs you"
    static func answered(_ meal: String) -> String { "\(meal) · answered" }
    static func ofTotal(_ total: String) -> String { "of \(total)" }
    static let yes = "Yes"
    static let no = "No"
    static let notSure = "Not sure"
    static func remind(_ count: String) -> String { "Remind \(count) students" }
    static func reminderSent(_ time: String) -> String { "Reminder recorded · \(time)" }
    static let feedbackToActOn = "Feedback to act on"
    static let community = "Community"
    static let new = "New"
    static let needsAnOwner = "Needs an owner"
    static let whyStudentsSkip = "Why students skip"
    static func feedbackRowTitle(_ item: FeedbackItem) -> String { "\(item.dish) · \(item.problem)" }
    static func feedbackRowDetail(_ item: FeedbackItem, day: String) -> String {
        "\(item.mess) · \(day) \(MLFormat.mealSlot(item.slot).lowercased()) · \(item.students) \(students(item.students))"
    }
    static func studentCount(_ count: Int) -> String { "\(count) \(students(count))" }
    static let remindStudents = "Remind students"
    static let who = "Who"
    static let messageLabel = "Message"
    static func remindWho(_ count: String, meal: String) -> String { "\(count) students who haven't answered for \(meal), all messes." }
    static let remindNote = "One notification, only to students who haven't answered. This prototype records it and sends nothing."
    static func sendTo(_ count: String) -> String { "Send to \(count) students" }
    static let reminderToast = "Reminder recorded"

    static func feedbackSubtitle(_ item: FeedbackItem, day: String) -> String {
        "\(item.mess) · \(day) \(MLFormat.mealSlot(item.slot).lowercased()) · \(item.students) \(students(item.students))"
    }
    static func feedbackContext(_ item: FeedbackItem, day: String) -> String { "\(MLFormat.mealSlot(item.slot)) · \(item.mess) Mess · \(day)" }
    static let problemsReported = "Problems reported"
    static let mealsLabel = "Meals"
    static let logAFix = "Log a fix"
    static let vendorSheetNote = "Sending to the vendor opens the prepared message. Nothing is sent for you."

    static func communitySubtitle(_ count: Int) -> String { "Community · \(studentCount(count))" }
    static let saidMeToo = "students said \"me too\""
    static func raisedOn(_ day: String, _ context: String) -> String { "Raised \(day) · \(context)" }
    static let stageRaised = "Raised"
    static let stageOwner = "Owner"
    static let stageFixed = "Fixed"
    static let assignOwner = "Assign owner"
    static let nobodyOwns = "Nobody owns this yet"
    static func ownedBy(_ name: String) -> String { "Owned by \(name)" }
    static let noteToStudents = "Note to students"
    static let notePlaceholderStudents = "Add a note on this issue"
    static let postNote = "Post note"
    static let notePosted = "Note posted"
    static let ownerAssigned = "Owner assigned"

    static func skipSubtitle(_ meal: String, _ count: Int) -> String { "\(meal) · \(count) said no" }
    static let skipIntro = "From students who said no and gave a reason. A student can give one reason."
    static func hiddenGroups(_ names: [String], noReason: Int) -> String {
        "Groups under 10 are hidden (\(names.joined(separator: ", "))). \(noReason) gave no reason."
    }

    // More
    static let moreTitle = "More"
    static let weeklyMenu = "Weekly menu"
    static let wednesdayPass = "Wednesday pass"
    static let outings = "Outings"
    static let votes = "Votes"
    static let rewards = "Rewards"
    static let spareFood = "Spare food"
    static let peopleAndAccess = "People and access"
    static let announceToStudents = "Announce to students"
    static let history = "History"
    static let signOut = "Sign out"
    static func outCount(_ count: Int) -> String { "\(count) out" }
    static func openCount(_ count: Int) -> String { "\(count) open" }
    static func liveCount(_ count: Int) -> String { "\(count) live" }
    static func pickups(_ count: Int) -> String { "\(count) pickups" }
    static func invited(_ count: Int) -> String { "\(count) invited" }

    // Weekly menu
    static let menuSubtitle = "The menu for the students' Meals page"
    static func published(_ moment: String) -> String { "Published · \(moment)" }
    static func uploading(_ moment: String) -> String { "Uploading · \(moment)" }
    static func readingBoard(_ moment: String) -> String { "Reading the board · \(moment)" }
    static let uploadNextWeek = "Upload next week's menu"
    static let changeTodaysDinner = "Change today's dinner"
    static func photoLine(_ size: String) -> String { "Photo of the printed board · \(size)" }
    static let readingLine = "Reading 7 days × 4 meals. Words that are hard to read get a (?)."
    static let simulatedUpload = "Sample flow: no photo is uploaded or read. The sample board is shown."
    static let stepPhoto = "Photo"
    static let stepRead = "We read it"
    static let stepCheck = "You check"
    static func check(_ count: Int) -> String { "Check \(count)" }
    static let today = "today"
    static let mealLetters = ["B", "L", "S", "D"]
    static func checkDayTitle(_ day: String) -> String { "Check \(day)" }
    static func wordsHard(_ count: Int) -> String { "\(count) \(count == 1 ? "word was" : "words were") hard to read" }
    static func weRead(_ slot: String) -> String { "\(slot) · we read" }
    static let highlightOnBoard = "Highlight on the board"
    static let nonVeg = "Non-veg"
    static let veg = "Veg"
    static func confirmWords(_ count: Int) -> String { "Confirm \(count) \(count == 1 ? "word" : "words")" }
    static let wordsConfirmed = "Words confirmed"

    static func editDaySubtitle(_ range: String) -> String { "Edit day · week of \(range)" }
    static func copyLast(_ weekday: String) -> String { "Copy last \(weekday)" }
    static let undo = "Undo"
    static func copiedFrom(day: String, slot: String, count: Int, kept: Bool) -> String {
        let base = "Copied from \(day) \(slot): \(count) dishes."
        return kept ? "\(base) The word to check is kept." : base
    }
    static let highlightAndVeg = "Highlight · Veg"
    static let addADish = "Add a dish"
    static let tellStudentsChange = "Tell students about this change"
    static let saveChanges = "Save changes"
    static let savedTold = "Saved. This prototype sends nothing to students."
    static let saved = "Saved."
    static func deleted(_ dish: String) -> String { "\(dish) removed" }
    static let checkThisWord = "Check this word"
    static func checkWordDetail(slot: String, day: String) -> String { "We read this from the board photo and are not sure. \(slot), \(day)." }
    static let didYouMean = "Did you mean"
    static let useThisWord = "Use this word"
    static func addDishDetail(slot: String, day: String) -> String { "\(slot), \(day). Type a dish or pick one served before." }
    static let fromEarlierWeeks = "From earlier weeks"
    static let add = "Add"
    static let dishName = "Dish name"

    static let swapADish = "Swap a dish"
    static let swapDetail = "Replace one with another"
    static let addASpecial = "Add a special"
    static let specialDetail = "Like Chicken Biryani, marked Limited"
    static let removeADish = "Remove a dish"
    static let removeDetail = "It will not be served today"
    static let tellStudents = "Tell students"
    static let continueTitle = "Continue"
    static func whichDish(_ day: String) -> String { "Which dish? Today's dinner, \(day)." }
    static func replace(_ dish: String) -> String { "Replace \(dish)" }
    static let withWhich = "With which dish?"
    static let swap = "Swap"
    static let name = "Name"
    static let limited = "Limited"
    static let limitedNote = "Shows a Limited tag. Students know it may run out."
    static let addSpecial = "Add special"
    static let removeThisDish = "Remove this dish?"
    static func removeBody(_ dish: String) -> String { "\(dish) will not be served at dinner today. The rest of the week stays the same." }
    static let keepIt = "Keep it"
    static let remove = "Remove"
    static let sendToStudents = "Send to students?"
    static let studentsSee = "Students would see"
    static let dinnerChanged = "Dinner changed"
    static let now = "now"
    static let nowTitle = "Now"
    static func everyoneGets(_ total: String) -> String { "All \(total) students would get this in Notifications and on Home. This prototype sends nothing." }
    static let send = "Send"
    static let sentDinner = "Dinner change saved. This prototype sends nothing to students."
    static let dinnerChangedSaved = "Dinner changed."
    static func changeLine(_ change: QuickChange) -> String {
        switch change {
        case .swap(let dish, let replacement): return "\(replacement) replaces \(dish)."
        case .addSpecial(let name, let isLimited, _): return isLimited ? "\(name) added (limited)." : "\(name) added."
        case .remove(let dish): return "\(dish) removed."
        }
    }
    static func dinnerChangedLine(_ change: QuickChange) -> String { "Dinner changed: \(changeLine(change))" }

    // People
    static let whoCanDoWhat = "Who can do what"
    static let roles = "Roles"
    static let vendorContact = "Vendor contact"
    static let edit = "Edit"
    static let headcountByMessage = "Headcount goes by message"
    static let headcountByCall = "Headcount goes by call"
    static let inviteSomeone = "Invite someone"
    static func invite(_ role: String) -> String { "Invite \(role)" }
    static func peopleCount(_ count: Int, messes: String?) -> String {
        [count == 1 ? "1 person" : "\(count) people", messes].compactMap { $0 }.joined(separator: " · ")
    }
    static func morePeople(_ count: Int) -> String { "\(count) more" }
    static let namesOnList = "Names are on the staff list"
    static let phoneNumber = "Phone number"
    static let phonePrefix = "+91"
    static let role = "Role"
    static let sendInvite = "Send invite"
    static let inviteSent = "Invite recorded"
    static let vendorSheetDetail = "Headcounts and messages go to this number from your phone."
    static let sendHeadcountsBy = "Send headcounts by"
    static let vendorSaved = "Vendor contact saved"

    // Announce
    static let announceSubtitle = "Shows on students' Home and as a notification"
    static let when = "When"
    static let reviewAndSend = "Review and send"
    static func sendToAudience(_ name: String) -> String { "Send to \(name)?" }
    static func audienceReach(_ audience: AnnouncementAudience) -> String {
        guard let count = audience.students else { return "Students at \(audience.confirmName) would get a notification. This prototype sends nothing." }
        return "About \(AdminFormat.count(count)) students at \(audience.confirmName) would get a notification. This prototype sends nothing."
    }
    static let sendNow = "Send now"
    static let announcementSent = "Announcement recorded"
    static func characters(_ used: Int, _ limit: Int) -> String { "\(used) / \(limit)" }

    // Secondary pages
    static let passes = "Passes"
    static let ofUsed = "used"
    static func ofTotalUsed(_ total: Int) -> String { "of \(total) used" }
    static func expiredUnused(_ count: Int) -> String { "\(count) expired unused" }
    static let menuVotes = "Menu votes"
    static let voteClosed = "Vote closed"
    static let forWord = "for"
    static func forAgainst(_ yes: String, _ no: String) -> String { "\(yes) for · \(no) against" }
    static func newProposals(_ count: Int) -> String { "New proposals · \(count)" }
    static func ofBudget(_ budget: String) -> String { "of \(budget)" }
    static let pts = "pts"
    static let dishes = "dishes"
    static func byTime(_ partner: String, _ time: String) -> String { "\(partner) · by \(time)" }
    static let entriesToday = "entries today"
    static let late = "Late"
    static let outNow = "Out now"
}
