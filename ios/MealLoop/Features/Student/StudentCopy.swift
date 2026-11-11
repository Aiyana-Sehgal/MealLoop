import Foundation

/// Interface copy for the Student root, Home, the answer page and Entry QR. This is wording, not data.
/// Sources: design/audit/export_redesign 03, 04, 07 and 08, and the redesign prompt's stage P5 for the locked state.
enum StudentCopy {
    static let brand = "MealLoop"
    /// The label of the leading Back on Search, which is a stack root.
    static let back = "Back"

    static func greeting(_ name: String) -> String { "Hey \(name)" }

    static let imIn = "I'm in"
    static let skipped = "Skipped"
    static let notSure = "Not sure"
    static let notAnswered = "Not answered"
    static let showEntryQR = "Show entry QR"
    static let answer = "Answer"
    static let change = "Change"

    static func eyebrow(_ slot: MealSlot) -> String {
        switch slot {
        case .breakfast: return "This morning"
        case .lunch: return "This afternoon"
        case .snacks, .dinner: return "This evening"
        }
    }

    private static func mealWord(_ slot: MealSlot) -> String { MLFormat.mealSlot(slot).lowercased() }

    static func youreIn(_ slot: MealSlot) -> String { "You're in for \(mealWord(slot))" }
    static func youSkipped(_ slot: MealSlot) -> String { "You skipped \(mealWord(slot))" }
    /// Not drawn: the owner asked for the Skip layout with its own wording.
    static func youreNotSure(_ slot: MealSlot) -> String { "Not sure about \(mealWord(slot))" }
    static func mealToday(_ slot: MealSlot) -> String { "\(MLFormat.mealSlot(slot)) today?" }
    static func youInFor(_ slot: MealSlot) -> String { "You in for \(mealWord(slot))?" }

    static func serving(_ range: String) -> String { "Serving \(range)" }
    static let canStillEat = "Changed your mind? You can still eat."
    static let notSureCanEat = "You can still eat."
    static func decideBy(_ time: String, left: String) -> String { "Decide by \(time) · \(unbroken("\(left) left"))" }
    static func changeBy(_ time: String, left: String) -> String { "Change by \(time) · \(unbroken("\(left) left"))" }
    static func answerBy(_ range: String, time: String, left: String) -> String { "\(range) · answer by \(time), \(left) left" }
    static func answersClosed(_ time: String) -> String { "Answers closed at \(time). Your QR still works." }

    /// Keeps a duration on one line, so "3 h left" never splits between the number and its unit.
    private static func unbroken(_ text: String) -> String { text.replacingOccurrences(of: " ", with: "\u{00A0}") }

    static let answerFooter = "You can still eat if you skip. Your QR always works."
    static let qrAlwaysWorks = "Your QR always works."
    static let highlight = "Highlight"
    static let highlightInfo = "Marked by the mess on the menu board"
    static let vegetarian = "Vegetarian"
    static let nonVegetarian = "Non-vegetarian"
    static let menuUnavailable = "The menu isn't available yet."

    // Home header and top card (Home frames, page 07).
    static let reportIssue = "Report an issue"
    /// The header button on Home opens SOS (2162:6).
    static let sos = "SOS"
    static let notifications = "Notifications"
    static let rewards = "Rewards"
    static func points(_ credits: Int?) -> String { credits.map { "\($0) pts" } ?? "— pts" }
    static func pointsLabel(_ credits: Int?) -> String { credits.map { "Rewards, \($0) points" } ?? "Rewards, not available" }
    static let nowServing = "Now serving"
    static let nextMealEyebrow = "Next meal"
    static func isOpen(_ slot: MealSlot) -> String { "\(MLFormat.mealSlot(slot)) is open" }
    static func till(_ time: String, mess: String) -> String { "Till \(time) · \(mess)" }
    static func mealAt(_ slot: MealSlot, time: String) -> String { "\(MLFormat.mealSlot(slot)) at \(time)" }
    static func servingAt(_ range: String, mess: String) -> String { "Serving \(range) · \(mess)" }
    static func messOpensAt(_ time: String) -> String { "Mess opens at \(time)" }
    static func mealRange(_ slot: MealSlot, range: String, mess: String) -> String { "\(MLFormat.mealSlot(slot)) \(range) · \(mess)" }
    static func savedQRWorks(_ range: String) -> String { "Saved QR works offline · \(range)" }
    static let entryQRShort = "Entry QR"
    static let skip = "Skip"

    // Rows under the top card.
    static func howWas(_ slot: MealSlot) -> String { "How was \(mealWord(slot))?" }
    static let good = "Good"
    static let notGood = "Not good"
    static func answersClosedRow(_ slot: MealSlot) -> String { "\(MLFormat.mealSlot(slot)) answers closed" }
    static func cutoffPassed(_ time: String) -> String { "Cutoff \(time) passed · your QR still works" }
    static let closed = "Closed"
    static let specialPass = "Special pass"
    static func passWhen(_ day: String, range: String) -> String { "\(day) \(range)" }
    static let open = "Open"
    static let used = "Used"
    static func crowdAt(_ mess: String) -> String { "Crowd at \(mess)" }
    static func crowdLevel(_ level: CrowdLevel) -> String {
        switch level {
        case .quiet: return "Quiet now"
        case .busy: return "Busy now"
        case .closed: return "Closed now"
        }
    }
    static func crowdDetail(_ level: CrowdLevel, time: String) -> String {
        switch level {
        case .quiet: return "Best time \(time)"
        case .busy: return "Quieter after \(time)"
        case .closed: return "Opens \(time)"
        }
    }
    static let crowdUnavailable = "Crowd not available"
    static func crowdSpoken(_ level: CrowdLevel) -> String { "Estimate: \(crowdLevel(level))" }

    // Home states.
    static func offlineSaved(_ time: String?) -> String {
        time.map { "You're offline. Showing what was saved at \($0)." } ?? "You're offline. Showing what was saved."
    }
    static let noMealsTitle = "No meals planned today"
    static let noMealsDetail = "The mess hasn't put up today's menu yet. Your QR still works if it opens."
    static let gettingMeals = "Getting today's meals…"

    // The answer page.
    static func answerClosedSubtitle(_ range: String) -> String { "\(range) · answers closed" }
    static let saving = "Saving…"
    static func savedChangeUntil(_ saved: String, until: String) -> String { "Saved \(saved) · you can change this until \(until)." }
    static func youreSkipping(_ slot: MealSlot) -> String { "You're skipping \(mealWord(slot))" }
    static func reasonChangeUntil(_ reason: String, until: String) -> String { "Reason: \(reason) · change until \(until)." }
    static func changeUntil(_ until: String) -> String { "You can change this until \(until)." }
    static let markedNotSure = "Marked not sure"
    static func decideByTime(_ time: String) -> String { "Decide by \(time)." }
    static let youDidntAnswer = "You didn't answer"
    static let changeAnswer = "Change answer"
    static let tryAgain = "Try again"
    static let couldntSave = "Couldn't save your answer. Try again"
    static let answerWaiting = "You're offline. Your answer will send when you're back."

    // Why skipping? (221:62700)
    static let whySkipping = "Why skipping?"
    static let whySkippingDetail = "Optional. It helps the mess plan. Never shown with your name."
    static func skipMeal(_ slot: MealSlot) -> String { "Skip \(mealWord(slot))" }
    static let skipNoReason = "Skip without a reason"
    static func reason(_ reason: MealSkipReason) -> String {
        switch reason {
        case .classOrExam: return "Class or exam"
        case .homeOrLeave: return "Home or leave"
        case .eatingElsewhere: return "Eating elsewhere"
        case .dislikeDish: return "Don't like the dish"
        case .dietary: return "Dietary reason"
        case .notHungry: return "Not hungry"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        }
    }

    static let entryQR = "Entry QR"
    static let youreInChip = "You're in"
    static let live = "Live"
    static let offline = "Offline"
    static func refreshesIn(_ seconds: Int) -> String { "Refreshes in \(seconds) s" }
    static let refreshing = "Refreshing…"
    static let newCodeSoon = "New code in a moment"
    static let walkIn = "Walk-in"
    static let walkInDetail = "You didn't answer. You can still eat."
    static let scanned = "Scanned"
    static func entryRecorded(_ time: String) -> String { "Entry recorded · \(time)" }
    static func enjoy(_ slot: MealSlot?) -> String { slot.map { "Enjoy your \(mealWord($0))." } ?? "Enjoy your meal." }
    static let scannedEarlier = "Scanned earlier"
    static let alreadyScanned = "Already scanned"
    static func alreadyScannedAt(_ time: String) -> String { "Already scanned at \(time)" }
    static let askDoorStaff = "Ask the door staff if this is wrong."
    static let wrongMess = "Wrong mess"
    static func qrIsFor(_ mess: String) -> String { "This QR is for \(mess)" }
    static let differentMess = "You are at a different mess. Ask the door staff."
    static let savedQR = "Saved QR"
    static let offlineQRBanner = "You're offline. Your saved QR still works."
    static func savedUntil(_ saved: String?, until: String) -> String {
        saved.map { "Saved at \($0) · works until \(until)" } ?? "Works until \(until)"
    }
    static let showSavedQR = "Show this saved QR. It works without internet."

    // Entry · Discrepancy (221:63082)
    static let somethingWrong = "Something's wrong?"
    static let mealEyebrow = "Meal"
    static let recordEyebrow = "Record"
    static let notScanned = "Not scanned"
    static let whatsWrong = "What's wrong?"
    static func correctionReason(_ reason: EntryCorrectionReason) -> String {
        switch reason {
        case .ateButNotScanned: return "I ate, but it says not scanned"
        case .wrongMeal: return "Wrong meal recorded"
        case .other: return "Other"
        }
    }
    static let addNote = "Add a note (optional)"
    static let sendRequest = "Send request"
    static let sending = "Sending…"
    static let didntSend = "Didn't send. Try again."
    static let holdUp = "Hold this up to the scanner."
    static let cantScan = "Can't scan? Give the door staff your SRM ID."
    static let qrUnavailable = "The QR can't be shown right now."
    static func qrLabel(_ name: String, maskedID: String) -> String { "Entry QR code for \(name), \(maskedID)" }
    static func entrySubtitle(_ slot: MealSlot?, mess: String) -> String {
        slot.map { "\(MLFormat.mealSlot($0)) · \(mess)" } ?? mess
    }
}

/// Short times for the student screens, in the mess's time zone. "10 AM", "5:30 AM".
enum StudentFormat {
    static func shortTime(_ date: Date, in timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = calendar.component(.minute, from: date) == 0 ? "h a" : "h:mm a"
        return formatter.string(from: date)
    }

    /// "7:30": the clock without AM or PM, as "Mess opens at 7:30" draws it.
    static func clock(_ date: Date, in timeZone: TimeZone) -> String {
        shortTime(date, in: timeZone).components(separatedBy: " ").first ?? ""
    }

    /// "Wed"
    static func shortDay(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    /// "Tue 13 Aug"
    static func mediumDay(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: date)
    }

    /// "3h" and "1h 50m", as Home draws "2h left". The answer page keeps "3 h".
    static func compactLeft(_ text: String) -> String {
        text.replacingOccurrences(of: " h", with: "h").replacingOccurrences(of: " min", with: "m")
    }

    /// "Wednesday 14 Aug"
    static func day(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEEE d MMM"
        return formatter.string(from: date)
    }
}
