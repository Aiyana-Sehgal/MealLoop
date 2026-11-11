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
    /// "Dinner · headcount due 4:30 PM"
    static func headcountDue(meal: String, time: String) -> String { "\(meal) · headcount due \(time)" }
    /// "Main Mess" on a tile is "Main", as the frame writes it.
    static func tileName(_ mess: String) -> String { mess.components(separatedBy: " ").first ?? mess }
    static func messName(_ name: String) -> String { name.isEmpty ? "" : "\(name) Mess" }
    static func forecastAt(_ time: String) -> String { "Forecast at \(time)" }
    /// "11:30 AM" written "11:30", as the headcount frames write it.
    static func clock(_ time: String) -> String { time.components(separatedBy: " ").first ?? time }
    static func statusAt(_ status: String, _ time: String) -> String { "\(status) \(time)" }
    /// "Sambar left over", from the record. A meal with no food line says it needs a look.
    static func reviewTitle(_ meal: AdminMealFacts) -> String {
        if let food = meal.leftovers.first { return "\(food.dish) left over" }
        if let food = meal.ranOut.first { return "\(food.dish) ran out" }
        return AdminScreenCopy.needsReview
    }
    static func reviewDetail(_ meal: AdminMealFacts, in timeZone: TimeZone) -> String {
        "\(meal.mess) · \(AdminFormat.weekday(meal.day, in: timeZone).prefix(3)) \(MLFormat.mealSlot(meal.slot).lowercased())"
    }

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
    /// Names the forecast being approved, so the count is never read as live entries or the sent number.
    static func approve(_ count: Int, field: String) -> String { "Approve \(field.lowercased()) · \(count)" }
    static func send(_ count: Int) -> String { "Send \(count) to vendor" }
    static let adjustHeadcount = "Adjust headcount"
    static let history = "History"
    static let answersYes = "said yes"
    static let answersNo = "said no"
    static let answersNotSure = "not sure"
    static let answersNone = "no answer"
    /// The answers cover the sample roster, not the forecast (docs/OPEN_DECISIONS.md, P-STORY-2).
    static let answersScope = "Student answers so far · sample roster, not the forecast"
    static func historyApproved(_ count: Int) -> String { "Approved \(count)" }
    static func historySent(_ count: Int) -> String { "Sent \(count) to vendor" }
    static let historyAcknowledged = "Vendor acknowledged"
    static func historyAdjusted(from: Int, to: Int) -> String { "\(from) → \(to)" }
    static func historyAdjustedDetail(reason: String, role: String) -> String { "\(reason) · \(role)" }
    static let vendorAccount = "Vendor account"

    // Vendor reply and other messes
    static let vendorReply = "Vendor reply"
    static let sentBefore = "Sent before"
    static let callVendor = "Call vendor"
    static let notAcknowledged = "Not acknowledged"
    static let waiting = "Waiting"
    static let noReply = "No reply"
    static let noReplyLower = "no reply"
    static let eventsLower = "events"
    static let headcountSentLower = "headcount sent"
    static let save = "Save"
    static func savedToast(_ count: Int) -> String { "Saved \(count)" }
    static func sendBy(_ time: String) -> String { "Today · send by \(time)" }
    static func sentNoReply(_ time: String, minutes: Int) -> String { "Sent \(time) · no reply for \(minutes) min" }
    static func sentToVendorAt(_ time: String) -> String { "Sent to vendor · \(time)" }
    static func sentAndReplied(_ sent: String, _ replied: String) -> String { "Sent \(sent) · vendor replied \(replied)" }
    static func repliedLower(_ time: String) -> String { "replied \(time)" }
    static func minutes(_ count: Int) -> String { "\(count) min" }
    static func rangeSpoken(low: Int, high: Int) -> String { "Range \(low) to \(high)" }
    static func replyWord(_ reply: AdminVendorReply, in timeZone: TimeZone) -> String {
        switch reply {
        case .notSent: return notSent
        case .waiting: return waiting
        case .replied(let at): return "Replied \(MLFormat.time(at, in: timeZone))"
        case .noReply: return noReply
        }
    }
    /// "Forecast 700 · range 660–740 · usual Wed 692". Only what the record holds.
    static func forecastRangeLine(_ mess: AdminMessHeadcount) -> String? {
        guard let expected = mess.expected else { return nil }
        var parts = [forecastLine(expected)]
        if let low = mess.rangeLow, let high = mess.rangeHigh { parts.append("range \(low)–\(high)") }
        if let usual = mess.usual, let label = mess.usualLabel { parts.append("\(label) \(usual)") }
        return parts.joined(separator: " · ")
    }
    static func vendorChaseMessage(mess: String, meal: String, count: Int?, name: String) -> String {
        let number = count.map { " The headcount is \($0)." } ?? ""
        return "Hi, this is \(name) from MealLoop. \(mess) \(meal.lowercased()) today:\(number) Please confirm you have it."
    }

    // Live meal
    static let cameInSoFar = "Came in so far"
    static let notFinalCount = "This is not the final count."
    static let foodLeft = "Food left · reported by staff"
    /// Said for a dish no staff member has reported on. The frame's "OK" would claim a check nobody made.
    static let noReport = "No report"
    static let stageSent = "Sent"
    static let stageServing = "Serving"
    static func ofExpected(_ count: Int) -> String { "of \(count) expected" }
    static func usualByNow(_ count: Int) -> String { "usual by now ~\(count)" }
    /// "12–2 PM". The first time drops what the second repeats.
    static func mealHours(_ start: String, _ end: String) -> String {
        func tidy(_ time: String) -> String { time.replacingOccurrences(of: ":00", with: "") }
        let first = tidy(start)
        let last = tidy(end)
        let sameHalf = first.split(separator: " ").last == last.split(separator: " ").last
        let lead = (start.hasPrefix("12") && end.hasSuffix("PM")) || sameHalf ? clock(first) : first
        return "\(lead)–\(last)"
    }
    static func updatedAt(_ hours: String, _ time: String) -> String { "\(hours) · updated \(time)" }
    static func levelChip(_ level: ShortageLevel) -> String {
        switch level {
        case .gettingLow: return "Running low"
        case .almostOut: return "Almost out"
        case .out: return "Out"
        }
    }
    static func reportedBy(_ role: String, _ time: String, note: String?) -> String {
        [note, "\(role), \(time)"].compactMap { $0 }.joined(separator: " · ")
    }
    static func vendorShortageMessage(dish: String, level: String, mess: String, name: String) -> String {
        "Hi, this is \(name) from MealLoop. \(dish) is \(level) at \(mess). Could you send more?"
    }

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
