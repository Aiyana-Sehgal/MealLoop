import Foundation

/// Food Head wording from design/reference/admin_redesign_2026-10 and design/audit/export_admin_redesign.
/// Wording the pack does not draw follows docs/PRD (FR-HC, FR-VEN); REPORT.md lists it.
enum AdminCopy {
    // Today
    /// "Devi Raman" gives "Hey Devi", as on A01. The full name stays on the account, for the initials.
    static func greeting(_ name: String) -> String {
        "Hey \(name.split(separator: " ").first.map(String.init) ?? name)"
    }
    static let noMealTitle = "No meals today"
    static let noMealDetail = "Meals will show here when they are set."
    static let needsYou = "Needs you"
    static let seeAll = "See all"
    static let nothingNeedsYou = "Nothing needs you."
    static let liveAction = "Live"
    static let liveMeal = "Live meal"
    static let openCase = "Open case"
    static let safetyCase = "Safety case"
    static func safetyOpen(_ elapsed: String) -> String { "Open · \(elapsed)" }
    static func safetyDetail(place: String, time: String) -> String { "\(place) · reported \(time)" }
    static func needsYouTitle(dish: String, level: String) -> String { "\(dish), \(level)" }
    static func needsYouDetail(mess: String, meal: String) -> String { "\(mess) · \(meal)" }
    static func headcountSection(_ meal: String) -> String { "\(meal) headcount" }

    // Mess tile
    static let noData = "No data"
    static let reviewAndApprove = "Review and approve"
    static let reviewAndSend = "Review and send"
    static let seeHeadcount = "See headcount"
    static let waitingForApproval = "Waiting for your approval"
    static let approvedNotSent = "Approved · not sent yet"
    static let servingNotFinal = "Serving · not the final count"
    static func closedWithStatus(_ time: String, status: String) -> String { "Closed \(time) · \(status)" }
    static func sentPending(_ time: String) -> String { "Sent \(time) · Pending" }
    static func acknowledgedAt(_ time: String) -> String { "Acknowledged \(time)" }

    // The six headcount values. These names are fixed (FR-HC-002): never merge or relabel them.
    static let liveForecast = "Live forecast"
    static let cutoffForecast = "Cutoff forecast"
    static let approvedHeadcount = "Approved headcount"
    static let sentToVendor = "Sent to vendor"
    static let actualEntries = "Actual entries"
    static let finalEntries = "Final entries"
    static let notAvailableYet = "Not available yet"

    // Status
    static let approval = "Approval"
    static let vendor = "Vendor"
    static let notApproved = "Not approved"
    static let approved = "Approved"
    static let notSent = "Not sent"
    static let pending = "Pending"
    static let acknowledged = "Acknowledged"

    // Headcount page
    static let stepForecast = "Forecast"
    static let stepApprove = "Approve"
    static let stepSend = "Send"
    static let stepVendor = "Vendor"
    static let expectedDiners = "Expected diners"
    static let forecastNotReady = "Forecast not ready yet"
    static func pageTitle(mess: String, meal: String) -> String { "\(mess) · \(meal)" }
    static func answersCloseAt(_ time: String) -> String { "Today · answers close \(time)" }
    static func answersClosedAt(_ time: String) -> String { "Today · answers closed \(time)" }
    static func approve(_ count: Int) -> String { "Approve \(count)" }
    static func send(_ count: Int) -> String { "Send \(count) to vendor" }
    static let adjustHeadcount = "Adjust headcount"
    static let history = "History"
    static let answersYes = "said yes"
    static let answersNo = "said no"
    static let answersNotSure = "not sure"
    static let answersNone = "no answer"
    /// The answers cover the sample roster, not the forecast (docs/OPEN_DECISIONS.md, P-STORY-2).
    static let answersScope = "Answers so far, from the sample roster. The forecast is a separate number."
    static func historyApproved(_ count: Int) -> String { "Approved \(count)" }
    static func historySent(_ count: Int) -> String { "Sent \(count) to vendor" }
    static let historyAcknowledged = "Vendor acknowledged"
    static func historyAdjusted(from: Int, to: Int) -> String { "\(from) → \(to)" }
    static func historyAdjustedDetail(reason: String, role: String) -> String { "\(reason) · \(role)" }
    static let vendorAccount = "Vendor account"

    // Confirm send
    static func sendTitle(_ count: Int) -> String { "Send \(count) to the vendor?" }
    static func sendSubject(meal: String, mess: String) -> String { "\(meal) · \(mess)" }
    static let sendDetail = "The vendor gets this headcount only. It can't be changed here after sending."
    static let cancel = "Cancel"
    static let sendAction = "Send"

    // Adjust sheet
    static let reason = "Reason"
    static let reasonEvent = "Event"
    static let reasonExam = "Exam"
    static let reasonHoliday = "Holiday"
    static let reasonOther = "Other"
    static let reasonOtherPrompt = "Say why"
    static let adjustNote = "The vendor only gets the number. Say why so Results can explain it later."
    static let decrease = "One fewer"
    static let increase = "One more"
    static func forecastLine(_ count: Int) -> String { "Forecast \(count)" }

    // Results of an action
    static func approvedToast(_ count: Int) -> String { "Approved \(count)" }
    static func sentToast(_ count: Int) -> String { "Sent \(count) to vendor" }
    static let offlineNothingSaved = "No connection. Nothing was saved."

    /// "Wed 14 Aug" in the mess time zone.
    static func dayLine(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: date)
    }

    /// "Devi Raman" gives "DR". A one-word name gives one letter.
    static func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map { String($0).uppercased() }.joined()
    }
}
