#if DEMO_DATA || REVIEW_DATA
import Foundation

/// DEMO DATA for the outing roles (Guardian, Warden, Gate). Debug and Review builds only; never pilot data.
/// Every value is copied from the guardian pack: design/reference/guardian_2026-10/data/guardian_video_spec.md ("spec"),
/// the frames in design/audit/export_guardian_video/ (named by file), and the Gate home render
/// design/audit/outings/o5/GA-1_Gate_home.png. A value no reference draws is left nil and shown as missing.
/// Names are the design's sample students. The pilot is a girls' mess; nothing is renamed here (open question).
enum OutingSeed {
    // MARK: Time

    /// A time in the mess time zone (India), in the sample year 2024.
    static func at(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        return calendar.date(from: DateComponents(year: 2024, month: month, day: day, hour: hour, minute: minute))
            ?? Date(timeIntervalSince1970: 0)
    }

    /// Spec: "the outing flow uses Fri 16 evening for the guardian reply". G01_guardian_choose is drawn at 7:41.
    static let guardianMoment = at(8, 16, 19, 41)
    /// W01_warden_decide_with_video and W04_warden_escalated are drawn at 10:00 on Saturday.
    static let wardenMoment = at(8, 17, 10, 0)
    /// V5_gate_verify_exit is drawn at 2:00 on Saturday.
    static let gateMoment = at(8, 17, 14, 0)

    // MARK: Rules from the spec (not thresholds of our own)

    /// Spec step 3: "10 seconds maximum, minimum 4 seconds".
    static let minimumVideoSeconds = 4
    static let maximumVideoSeconds = 10
    /// Spec step 5: "up to 3 tries".
    static let recordingTries = 3
    /// Spec step 6: "after 2 upload retries".
    static let uploadTries = 2
    /// Spec privacy: "draft 30 days". Not approved; shown as a draft value in the report.
    static let videoRetentionDays = 30
    /// G05: "enter the 6-digit code sent to the guardian's phone".
    static let phoneCodeLength = 6

    // MARK: People

    static let block = "Block B"
    static var guardianAccount: AccountID { account(.guardian) }
    static var wardenAccount: AccountID { account(.warden) }

    private static func account(_ role: Role) -> AccountID {
        DemoSeed.accounts.first { $0.role == role }?.id ?? AccountID("missing-\(role.rawValue)")
    }

    /// W01, GA-3, GA-5: "Aarav ••0238", "AA", Block B, SRM ID RA2411003010238.
    static let aarav = OutingStudent(id: StudentID("demo-outing-aarav"), firstName: "Aarav", maskedID: "••0238",
                                     initials: "AA", block: block, srmID: "RA2411003010238")
    /// W01_warden_decide_please_watch: "Meera ••0412", "MR".
    static let meera = OutingStudent(id: StudentID("demo-outing-meera"), firstName: "Meera", maskedID: "••0412",
                                     initials: "MR", block: block, srmID: nil)
    /// W01_warden_decide_photo_and_text: "Arjun ••0356", "AK".
    static let arjun = OutingStudent(id: StudentID("demo-outing-arjun"), firstName: "Arjun", maskedID: "••0356",
                                     initials: "AK", block: block, srmID: nil)
    /// W01_warden_decide_confirmed_by_call: "Kiran ••0377", "KS".
    static let kiran = OutingStudent(id: StudentID("demo-outing-kiran"), firstName: "Kiran", maskedID: "••0377",
                                     initials: "KS", block: block, srmID: nil)
    /// W04_warden_escalated, W02_warden_out_now: "Dev ••0190", "DK".
    static let dev = OutingStudent(id: StudentID("demo-outing-dev"), firstName: "Dev", maskedID: "••0190",
                                   initials: "DK", block: block, srmID: nil)
    /// W03_warden_history: "Riya ••0021".
    static let riya = OutingStudent(id: StudentID("demo-outing-riya"), firstName: "Riya", maskedID: "••0021",
                                    initials: nil, block: block, srmID: nil)

    /// The guardian account is linked to Aarav (G01 "Verified as Aarav's guardian"; spec "+91 98••• ••214").
    static var guardianLink: GuardianLink {
        GuardianLink(guardian: guardianAccount, student: aarav, phone: "+91 98••• ••214")
    }

    /// W01_warden_me: "Block B warden", "WB", Staff ID •••6390, "Block B · 412 students", 8 AM–8 PM, Senior warden.
    static let wardenProfile = WardenProfile(title: "Block B warden", initials: "WB", staffID: "•••6390", block: block,
                                             blockStudents: 412, hoursFrom: at(8, 17, 8, 0), hoursTo: at(8, 17, 20, 0),
                                             escalationsGoTo: "Senior warden")

    /// GA-1_Gate_home: "Main Gate", "Day shift · started 8:00 AM".
    static let gatePost = GatePost(name: "Main Gate", shiftName: "Day shift", shiftStartedAt: at(8, 17, 8, 0))

    // MARK: Requests

    /// The open requests and the gate's out list, as the story starts (Fri 16 Aug, 7:41 PM).
    static var cases: [OutingCase] {
        [aaravRequest, meeraRequest, arjunRequest, kiranRequest, devRequest] + mainGateOut
    }

    /// Spec "Sample outing": Express Avenue Mall, Sat 17 Aug 2024, 2 to 8 PM, Shopping; reply by Fri 11 PM;
    /// warden decides by Sat 12 PM. Pass 7F3K (W01_warden_decide_approved, V5_gate_pass_code). W01: "3 by video".
    static let aaravRequest = request("aarav", aarav, place: "Express Avenue Mall", reason: "Shopping",
                                      leave: at(8, 17, 14, 0), back: at(8, 17, 20, 0), replyBy: at(8, 16, 23, 0),
                                      decideBy: at(8, 17, 12, 0), phone: "+91 98••• ••214", pass: "7F3K",
                                      past: [.liveVideoAutoChecked: 3], stage: .awaitingGuardian)

    /// W01_warden_decide_please_watch: Sat 3–6 PM, Phoenix Marketcity, decide by Sat 1 PM, "Please watch",
    /// “I accept Meera's outing …”, "Not matched after 3 tries", "Past answers: 2 by video".
    static let meeraRequest = request("meera", meera, place: "Phoenix Marketcity", reason: nil,
                                      leave: at(8, 17, 15, 0), back: at(8, 17, 18, 0), replyBy: nil,
                                      decideBy: at(8, 17, 13, 0), phone: nil, pass: nil,
                                      past: [.liveVideoAutoChecked: 2], stage: .awaitingWarden,
                                      answer: .accepted(OutingEvidence(method: .videoNeedsReview, capturedAt: nil,
                                                                       videoSeconds: nil,
                                                                       transcript: "I accept Meera's outing …",
                                                                       passedChecks: [], calledNumber: nil,
                                                                       callNote: nil, deletesAt: nil)))

    /// W01_warden_decide_photo_and_text: Sat 4–8 PM, "Home, Tambaram", decide by Sat 2 PM, "Live photo · typed",
    /// “I accept 472”, checks Code and Number, "Past answers: 1 by video, 1 by photo".
    static let arjunRequest = request("arjun", arjun, place: "Home, Tambaram", reason: nil,
                                      leave: at(8, 17, 16, 0), back: at(8, 17, 20, 0), replyBy: nil,
                                      decideBy: at(8, 17, 14, 0), phone: nil, pass: nil,
                                      past: [.liveVideoAutoChecked: 1, .photoAndText: 1], stage: .awaitingWarden,
                                      answer: .accepted(OutingEvidence(method: .photoAndText, capturedAt: nil,
                                                                       videoSeconds: nil, transcript: "I accept 472",
                                                                       passedChecks: [.code, .number],
                                                                       calledNumber: nil, callNote: nil,
                                                                       deletesAt: nil)))

    /// W04_warden_escalated: "No camera · call the guardian"; W04 call Kiran sheet: +91 98••• ••557.
    /// W01_warden_decide_confirmed_by_call: Sat 1–5 PM, Express Avenue Mall, decide by Sat 11 AM.
    /// W02_warden_out_now_student: Pass 4QZ8.
    static let kiranRequest = request("kiran", kiran, place: "Express Avenue Mall", reason: nil,
                                      leave: at(8, 17, 13, 0), back: at(8, 17, 17, 0), replyBy: nil,
                                      decideBy: at(8, 17, 11, 0), phone: "+91 98••• ••557", pass: "4QZ8",
                                      past: [:], stage: .guardianCallRequested, answer: .callRequested)

    /// W04_warden_escalated at 10:00: "Past deadline · 1 h ago", so the reply time was Sat 9 AM.
    /// W04 call Dev sheet: +91 97••• ••031. W02_warden_out_now: back by 8 PM. No place or leave time is drawn.
    static let devRequest = request("dev", dev, place: nil, reason: nil, leave: nil, back: at(8, 17, 20, 0),
                                    replyBy: at(8, 17, 9, 0), decideBy: nil, phone: "+91 97••• ••031", pass: nil,
                                    past: [:], stage: .awaitingGuardian)

    /// V5_gate_out_now (GA-7): students already out through Main Gate on Saturday, with the times drawn.
    /// Aarav, the seventh row, is not seeded here: his exit comes from the story.
    static let mainGateOut: [OutingCase] = [
        gateOut("3471", out: at(8, 17, 11, 20), back: at(8, 17, 15, 0)),
        gateOut("9375", out: at(8, 17, 10, 2), back: at(8, 17, 16, 0)),
        gateOut("5167", out: at(8, 17, 12, 40), back: at(8, 17, 17, 0)),
        gateOut("5841", out: at(8, 17, 9, 5), back: at(8, 17, 18, 0)),
        gateOut("6832", out: at(8, 17, 13, 15), back: at(8, 17, 19, 0)),
        gateOut("7405", out: at(8, 17, 13, 50), back: at(8, 17, 21, 0)),
    ]

    // MARK: History

    /// W03_warden_history and W03_warden_history_all. Riya's and Meera's 6 Jul lines draw only the day and method.
    /// W03_warden_history_record_video_expired: Aarav, Sat 13 Jul, 3–8 PM, Home, Tambaram, pass 2HX9, Live 0:09.
    static var wardenHistory: [WardenHistoryItem] {
        [
            history("meera-16", meera, .approved, on: at(8, 16, 12, 0), method: .photoAndText),
            history("kiran-15", kiran, .changeAsked, on: at(8, 15, 12, 0), method: .liveVideoAutoChecked),
            history("dev-15", dev, .guardianSaidNo, on: at(8, 15, 12, 0), method: nil),
            history("riya-14", riya, .approved, on: at(8, 14, 12, 0), method: .confirmedByCall),
            WardenHistoryItem(id: "aarav-jul-13", student: aarav, outcome: .approved, decidedOn: at(7, 13, 12, 0),
                              decidedAtTime: nil, method: .liveVideoAutoChecked, place: "Home, Tambaram",
                              leaveAt: at(7, 13, 15, 0), returnBy: at(7, 13, 20, 0), passCode: "2HX9",
                              evidence: OutingEvidence(method: .liveVideoAutoChecked, capturedAt: nil,
                                                       videoSeconds: 9,
                                                       transcript: "I accept Aarav's outing, code 4 7 2",
                                                       passedChecks: EvidenceCheck.allCases, calledNumber: nil,
                                                       callNote: nil, deletesAt: at(8, 12, 12, 0))),
            history("meera-jul-6", meera, .approved, on: at(7, 6, 12, 0), method: .liveVideoAutoChecked),
        ]
    }

    /// G07_guardian_past_answers, before this request's answer: Home, Sat 10, accepted, video;
    /// Express Avenue Mall, Aug 3, rejected, one tap.
    static let guardianPastAnswers: [GuardianPastAnswer] = [
        GuardianPastAnswer(id: "home-aug-10", place: "Home", day: at(8, 10, 12, 0), kind: .accepted,
                           method: .liveVideoAutoChecked),
        GuardianPastAnswer(id: "mall-aug-3", place: "Express Avenue Mall", day: at(8, 3, 12, 0), kind: .rejected,
                           method: nil),
    ]

    // MARK: Builders

    private static func request(_ id: String, _ student: OutingStudent, place: String?, reason: String?, leave: Date?,
                                back: Date?, replyBy: Date?, decideBy: Date?, phone: String?, pass: String?,
                                past: [GuardianEvidenceMethod: Int], stage: OutingStage,
                                answer: GuardianAnswer? = nil) -> OutingCase {
        OutingCase(id: OutingRequestID("demo-outing-\(id)"), student: student, place: place, reason: reason,
                   leaveAt: leave, returnBy: back, guardianReplyBy: replyBy, wardenDecideBy: decideBy,
                   guardianPhone: phone, seededPassCode: pass, pastAnswerCounts: past, stage: stage,
                   guardianAnswer: answer.map { GuardianAnswerRecord(answer: $0, at: nil) })
    }

    private static func gateOut(_ masked: String, out: Date, back: Date) -> OutingCase {
        let student = OutingStudent(id: StudentID("demo-outing-gate-\(masked)"), firstName: nil, maskedID: "·\(masked)",
                                    initials: nil, block: nil, srmID: nil)
        return OutingCase(id: OutingRequestID("demo-outing-gate-\(masked)"), student: student, place: nil, reason: nil,
                          leaveAt: nil, returnBy: back, guardianReplyBy: nil, wardenDecideBy: nil, guardianPhone: nil,
                          seededPassCode: nil, pastAnswerCounts: [:], stage: .out, exitAt: out)
    }

    private static func history(_ id: String, _ student: OutingStudent, _ outcome: WardenHistoryItem.Outcome, on day: Date,
                                method: GuardianEvidenceMethod?) -> WardenHistoryItem {
        WardenHistoryItem(id: id, student: student, outcome: outcome, decidedOn: day, decidedAtTime: nil, method: method,
                          place: nil, leaveAt: nil, returnBy: nil, passCode: nil, evidence: nil)
    }
}
#endif
