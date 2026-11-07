#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SAMPLE, NOT MEASURED. The student's reports, feedback, spending, help and Community updates, each value cited to its
/// Figma frame (file nzzTAm9YnJRSdKEeYUWUEb, page 07). No value here is a real report, a real rupee or a real answer.
/// Where a frame draws only a day, only the day is shown; the hour stored with it is never displayed.
extension DemoSeed {
    /// The place chip of ReportSummary (221:63587, 221:63606): "Main Mess · Block A".
    static let sampleReportPlace = "Main Mess · Block A"

    /// My reports (221:63573). ML-1042 (Sent, Wed 14 Aug) is not seeded: it is the receipt number of the first report
    /// sent in a run (`firstReportNumber`), so seeding it would give two reports one reference.
    static let sampleFiledReports: [StudentFiledReport] = [
        // Report · Need more info (221:63587): "Food ran out", ML-1031, "You told us · Mon 12 Aug", "The mess read it ·
        // 1:50 PM", "The mess asked: Which counter was it?". The summary chip time 12:40 PM is the frame's.
        StudentFiledReport(id: StudentFiledReportID("demo-report-1031"), reference: "ML-1031", category: .ranOut,
                           place: sampleReportPlace, meal: .lunch, sentAt: date(12, 12, 40), stage: .needMoreInfo,
                           question: "Which counter was it?", reply: nil,
                           events: [StudentReportEvent(kind: .sent, at: date(12, 12, 40), isCurrent: false),
                                    StudentReportEvent(kind: .seen, at: date(12, 13, 50), isCurrent: false),
                                    StudentReportEvent(kind: .askedQuestion, at: nil, isCurrent: true)]),
        // My reports (221:63573): "Staff or service problem", ML-1017, Working on it, "FRI 9 AUG". No detail frame
        // draws its place, meal or times, so they stay empty.
        StudentFiledReport(id: StudentFiledReportID("demo-report-1017"), reference: "ML-1017", category: .staffOrService,
                           place: nil, meal: nil, sentAt: date(9, 12, 0), stage: .workingOnIt, question: nil, reply: nil,
                           events: [StudentReportEvent(kind: .sent, at: date(9, 12, 0), isCurrent: false),
                                    StudentReportEvent(kind: .seen, at: nil, isCurrent: false),
                                    StudentReportEvent(kind: .workingOnIt, at: nil, isCurrent: true)]),
        // Report · Fixed (221:63606): "Food smells or tastes off", ML-0998, "You told us · Sat 3 Aug", "The mess read it ·
        // 1:20 PM", "They're fixing it", "You check if it's better · Tue 6 Aug". Read only.
        StudentFiledReport(id: StudentFiledReportID("demo-report-0998"), reference: "ML-0998", category: .smellsOrTastesOff,
                           place: sampleReportPlace, meal: .lunch, sentAt: date(3, 12, 40), stage: .fixed, question: nil,
                           reply: nil,
                           events: [StudentReportEvent(kind: .sent, at: date(3, 12, 40), isCurrent: false),
                                    StudentReportEvent(kind: .seen, at: date(3, 13, 20), isCurrent: false),
                                    StudentReportEvent(kind: .workingOnIt, at: nil, isCurrent: false),
                                    StudentReportEvent(kind: .fixed, at: date(6, 12, 0), isCurrent: true)]),
    ]

    /// My feedback (2159:151331): "Sambar · Too salty", Fixed Thu, "Less salt from Thursday 8 Aug."; "Chappathi · Hard",
    /// "Seen by the kitchen · Mon 12 Aug"; "Veg Pulao · Mushy", "Reported · Fri 9 Aug". The frame's hero says "2 fixed";
    /// the app counts the items, so it shows 1.
    static let sampleFeedback: [StudentFeedbackItem] = [
        StudentFeedbackItem(id: StudentFeedbackID("demo-feedback-sambar"), dish: "Sambar", problem: "Too salty",
                            stage: .fixed, at: date(8, 12, 0), fixNote: "Less salt from Thursday 8 Aug.", recheck: nil),
        StudentFeedbackItem(id: StudentFeedbackID("demo-feedback-chappathi"), dish: "Chappathi", problem: "Hard",
                            stage: .seenByKitchen, at: date(12, 12, 0), fixNote: nil, recheck: nil),
        StudentFeedbackItem(id: StudentFeedbackID("demo-feedback-pulao"), dish: "Veg Pulao", problem: "Mushy",
                            stage: .reported, at: date(9, 12, 0), fixNote: nil, recheck: nil),
    ]

    /// Spending (221:63988): "₹3,000" this month, "₹500 this week", bars 1–4 Aug, 5–11 Aug, 12–14 Aug. The frame draws the
    /// bars 72, 88 and 32 pt tall; with the current week at ₹500 those heights give ₹1,125 and ₹1,375, which add up to
    /// the drawn ₹3,000.
    static let sampleSpendingWeeks: [StudentSpendingWeek] = [
        StudentSpendingWeek(start: date(1, 0, 0), end: date(4, 0, 0), amount: 1125, isCurrent: false),
        StudentSpendingWeek(start: date(5, 0, 0), end: date(11, 0, 0), amount: 1375, isCurrent: false),
        StudentSpendingWeek(start: date(12, 0, 0), end: date(14, 0, 0), amount: 500, isCurrent: true),
    ]

    /// Spending (221:63988), Recent: "Food delivery · Wed 14 Aug · dinner order · ₹320", "Canteen · Mon 12 Aug · snacks ·
    /// ₹180", "Snacks · Sat 10 Aug · ₹90".
    static let sampleSpendingRecent: [StudentSpendingEntry] = [
        StudentSpendingEntry(id: "demo-spend-delivery", title: "Food delivery", day: date(14, 12, 0), note: "dinner order",
                             amount: 320),
        StudentSpendingEntry(id: "demo-spend-canteen", title: "Canteen", day: date(12, 12, 0), note: "snacks", amount: 180),
        StudentSpendingEntry(id: "demo-spend-snacks", title: "Snacks", day: date(10, 12, 0), note: nil, amount: 90),
    ]

    /// Help (221:64742). Only the first answer is drawn; the others are collapsed with no text, so none is written here.
    static let sampleHelpTopics: [StudentHelpTopic] = [
        StudentHelpTopic(question: "How do meal answers work?",
                         answer: "Tell us I'm in, Skip or Not sure before the cutoff. It only helps the kitchen plan. You can always eat."),
        StudentHelpTopic(question: "Is my entry QR ever locked?", answer: nil),
        StudentHelpTopic(question: "How does the Special pass work?", answer: nil),
        StudentHelpTopic(question: "What happens when I send an SOS?", answer: nil),
        StudentHelpTopic(question: "Who sees my feedback?", answer: nil),
    ]
    /// Help (221:64742): "Mess office, Block A · 9 AM–5 PM".
    static let sampleHelpContact = "Mess office, Block A · 9 AM–5 PM"

    /// Community · Issue (221:63643), Timeline: "Seen by the team · Tue 13 Aug, 3:10 PM", "Next: the team picks an owner".
    static let sampleIssueUpdates: [CommunityIssueID: [StudentIssueUpdate]] = [
        CommunityIssueID("demo-issue-long-wait"): [
            StudentIssueUpdate(title: "Seen by the team", at: date(13, 15, 10), isNext: false),
            StudentIssueUpdate(title: "the team picks an owner", at: nil, isNext: true),
        ],
    ]
}
#endif
