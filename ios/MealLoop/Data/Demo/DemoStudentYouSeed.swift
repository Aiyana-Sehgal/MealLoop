#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SAMPLE, NOT MEASURED. Student Notifications, Credits and Attendance, each value cited to its Figma frame (file
/// nzzTAm9YnJRSdKEeYUWUEb, page 07). No value here is a real balance, a real message or a real attendance record.
extension DemoSeed {
    /// Notifications (221:64480): two unread today (filled icon), two read earlier (outlined icon).
    /// "Guardian approved · 6:52 AM", "Breakfast today? · 5:30 AM", "Feedback seen · Yesterday", "Special pass · Mon".
    static let sampleNotifications: [StudentNotification] = [
        StudentNotification(id: StudentNotificationID("demo-note-guardian-approved"), kind: .outingGuardianApproved,
                            title: "Guardian approved", detail: "Your Sat 17 Aug outing, 2–8 PM. Now waiting for the warden.",
                            at: time(6, 52), isRead: false),
        StudentNotification(id: StudentNotificationID("demo-note-breakfast"), kind: .mealQuestion,
                            title: "Breakfast today?", detail: "Tell us by 6 AM so the kitchen can plan.",
                            at: time(5, 30), isRead: false),
        StudentNotification(id: StudentNotificationID("demo-note-feedback-seen"), kind: .feedbackSeen,
                            title: "Feedback seen", detail: "The kitchen saw it. 6 others said the sambar was too salty.",
                            at: date(13, 20, 10), isRead: true),
        StudentNotification(id: StudentNotificationID("demo-note-special-pass"), kind: .specialPass,
                            title: "Special pass", detail: "Wednesday 14 Aug, 12–2 PM at the pass desk.",
                            at: date(12, 9, 0), isRead: true),
    ]

    /// Credits history (221:64443): "Answered dinner · +5 pts", "Answered lunch · +5 pts". The amount per definite
    /// answer is this sample; no formula exists (open decision P1).
    static let samplePointsPerDefiniteAnswer = 5

    /// Credits (221:64313): Juice 50 pts and Ice cream 80 pts "At your mess counter"; Biryani coupon 200 pts,
    /// "Launches Friday".
    static let sampleCreditTickets: [StudentCreditTicket] = [
        StudentCreditTicket(id: "juice", name: "Juice", place: "At your mess counter", cost: 50, availability: .available),
        StudentCreditTicket(id: "ice-cream", name: "Ice cream", place: "At your mess counter", cost: 80,
                            availability: .available),
        StudentCreditTicket(id: "biryani-coupon", name: "Biryani coupon", place: "Launches Friday", cost: 200,
                            availability: .notYet(note: "Launches Friday")),
    ]

    /// Credits history (221:64443): the August lines as drawn. The balance stays `sampleCredits` (120, Credits
    /// 221:64313 and Home 221:62529): the history frame is drawn after a juice, at 70.
    static let sampleCreditHistory: [StudentCreditEntry] = [
        StudentCreditEntry(id: "demo-credit-rated", title: "Rated a dish", day: date(12, 13, 0), points: 2),
        StudentCreditEntry(id: "demo-credit-dinner", title: "Answered dinner", day: date(11, 17, 0), points: 5),
        StudentCreditEntry(id: "demo-credit-recheck", title: "Answered a recheck", day: date(11, 13, 0), points: 2),
        StudentCreditEntry(id: "demo-credit-lunch", title: "Answered lunch", day: date(10, 9, 0), points: 5),
    ]

    /// Attendance (221:64717), August: filled days 1, 2, 4, 5, 6, 7, 9, 11, 12; outlined days 3, 8, 10, 13;
    /// day 14 is today. "36 of 41 meals". The percentage and the best streak are computed from these.
    static let sampleAttendanceMarks: [Int: StudentAttendanceMark] = {
        var marks: [Int: StudentAttendanceMark] = [:]
        for day in [1, 2, 4, 5, 6, 7, 9, 11, 12] { marks[day] = .everyMeal }
        for day in [3, 8, 10, 13] { marks[day] = .noEntryForAMeal }
        marks[14] = .today
        return marks
    }()
    static let sampleMealsEntered = 36
    static let sampleMealsServed = 41
    /// August 2024 has 31 days and starts on a Thursday (Monday = 0, so 3).
    static let sampleMonthStart = date(1, 0, 0)
    static let sampleMonthDays = 31
    static let sampleMonthFirstWeekday = 3
}
#endif
