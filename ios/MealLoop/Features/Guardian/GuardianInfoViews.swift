import SwiftUI

// G-5 Notifications (1931:132246) and G-6 Help (1931:936), pushed from the Guardian page with the system back button.
// Notifications are built only from the guardian's own records: the current request's steps and the past answers.
// The frame's subtitle says the messages were sent by SMS; the prototype sends nothing, so the page says that instead.
// The frame's unread dots are not drawn: no record holds what the guardian has read.

enum GuardianInfoPage: Hashable {
    case notifications
    case help
}

enum GuardianInfoCopy {
    static let notifications = "Notifications"
    static let notificationsNote = "Newest first. This prototype sends no SMS."
    static let none = "Nothing yet."
    static let backHome = "Back at the hostel"
    static func backHomeDetail(_ name: String) -> String { "\(name) is back at the hostel." }
    static let exitRecorded = "Exit recorded"
    static func exitDetail(_ name: String, gate: String?, at: String, backBy: String) -> String {
        "\(name) left \(gate ?? "the gate") at \(at). Back by \(backBy)."
    }
    static let passIssued = "Pass issued"
    static func passDetail(_ name: String) -> String { "\(name)'s outing pass is ready." }
    static let youApproved = "You approved"
    static let youRejected = "You rejected"
    static let youAskedCall = "You asked the warden to call"
    static let youAskedChange = "You asked for a change"
    static func answerDetail(_ day: String, _ name: String, _ place: String?) -> String {
        place.map { "\(day) · \(name)'s outing to \($0)." } ?? "\(day) · \(name)'s outing."
    }
    static let withdrawn = "You withdrew your approval"
    static func withdrawnDetail(_ name: String) -> String { "\(name)'s pass is cancelled." }
    static let newRequest = "New request"
    static func newRequestDetail(_ name: String, _ when: String) -> String { "\(name) wants to go out on \(when)." }

    static let help = "Help"
    static let theOuting = "The outing"
    static let accepted = "Accepted"
    static let rejected = "Rejected"
    static let byVideo = "By video"
    static let place = "Place"
    static let callWarden = "Call the warden"
    static func helpItems(student: String, block: String?) -> [StaffHelpItem] {
        [StaffHelpItem(question: "What am I approving?",
                       answer: "That \(student) may leave the hostel for the day, time and place shown. Nothing else."),
         StaffHelpItem(question: "What if I don't reply?",
                       answer: "The request closes at the reply time. It is never approved for you."),
         StaffHelpItem(question: "Can I change my mind?",
                       answer: "Yes. Withdraw your approval before \(student) leaves. The pass is cancelled."),
         StaffHelpItem(question: "Who else approves?",
                       answer: "The \(block ?? "hostel") warden reviews it after you. Both of you must approve."),
         StaffHelpItem(question: "My number changed. What do I do?",
                       answer: "Call the hostel office. Only they can change guardian records.")]
    }
}

struct GuardianNotice: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let time: Date?
    /// True for the request in progress; false for an earlier answer.
    let isCurrent: Bool
}

enum GuardianNotices {
    /// The current request's steps, newest first, then the past answers, newest first.
    static func notices(request: OutingCase?, past: [GuardianPastAnswer], studentName name: String) -> [GuardianNotice] {
        var current: [GuardianNotice] = []
        if let request {
            let id = request.id.rawValue
            if let back = request.returnAt {
                current.append(.init(id: "\(id)-back", title: GuardianInfoCopy.backHome,
                                     detail: GuardianInfoCopy.backHomeDetail(name), time: back, isCurrent: true))
            }
            if let exit = request.exitAt {
                current.append(.init(id: "\(id)-exit", title: GuardianInfoCopy.exitRecorded,
                                     detail: GuardianInfoCopy.exitDetail(name, gate: request.exitGate, at: OutingFormat.clock(exit),
                                                                         backBy: request.returnBy.map(OutingFormat.hour) ?? "—"),
                                     time: exit, isCurrent: true))
            }
            if let withdrawn = request.withdrawnAt, request.withdrawnBy == .guardian {
                current.append(.init(id: "\(id)-withdrawn", title: GuardianInfoCopy.withdrawn,
                                     detail: GuardianInfoCopy.withdrawnDetail(name), time: withdrawn, isCurrent: true))
            }
            if let pass = request.pass {
                current.append(.init(id: "\(id)-pass", title: GuardianInfoCopy.passIssued,
                                     detail: GuardianInfoCopy.passDetail(name), time: pass.signedAt, isCurrent: true))
            }
            if let answer = request.guardianAnswer {
                let title: String
                switch answer.answer {
                case .accepted: title = GuardianInfoCopy.youApproved
                case .rejected: title = GuardianInfoCopy.youRejected
                case .callRequested: title = GuardianInfoCopy.youAskedCall
                case .changeAsked: title = GuardianInfoCopy.youAskedChange
                }
                let day = (answer.at ?? request.leaveAt).map(OutingFormat.weekday) ?? "—"
                current.append(.init(id: "\(id)-answer", title: title,
                                     detail: GuardianInfoCopy.answerDetail(day, name, request.place), time: answer.at,
                                     isCurrent: true))
            }
            let when: String
            if let leave = request.leaveAt, let back = request.returnBy {
                when = "\(OutingFormat.dayLong(leave)), \(OutingFormat.hours(leave, back))"
            } else {
                when = "—"
            }
            // No record holds when the request was made, so this row has no time.
            current.append(.init(id: "\(id)-new", title: GuardianInfoCopy.newRequest,
                                 detail: GuardianInfoCopy.newRequestDetail(name, when), time: nil, isCurrent: true))
        }
        // The past answers can hold the current request's own answer; it is already listed above.
        let currentDay = request?.guardianAnswer == nil ? nil : request?.leaveAt
        let earlier = past.filter { answer in
            guard let currentDay else { return true }
            return !(OutingFormat.isSameDay(answer.day, currentDay) && answer.place == request?.place)
        }
        .sorted { $0.day > $1.day }.map { answer in
            GuardianNotice(id: "past-\(answer.id)",
                           title: answer.kind == .accepted ? GuardianInfoCopy.youApproved : GuardianInfoCopy.youRejected,
                           detail: GuardianInfoCopy.answerDetail(OutingFormat.dayShort(answer.day), name, answer.place),
                           time: nil, isCurrent: false)
        }
        return current + earlier
    }
}

/// G-5 Notifications.
struct GuardianNotificationsPage: View {
    let model: GuardianModel

    private var notices: [GuardianNotice] {
        GuardianNotices.notices(request: model.request, past: model.pastAnswers, studentName: model.studentName)
    }

    var body: some View {
        GuardianInfoLayout(note: GuardianInfoCopy.notificationsNote) {
            if notices.isEmpty {
                Text(GuardianInfoCopy.none).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(notices) { notice in
                        row(notice, isLast: notice.id == notices.last?.id)
                    }
                }
                .padding(.horizontal, MLSpacing.s16)
                .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
                .overlay(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).stroke(MLColor.border, lineWidth: 1))
            }
        }
        .navigationTitle(GuardianInfoCopy.notifications)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ notice: GuardianNotice, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: MLSpacing.s12) {
            OrbitMarkView()
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: MLRadius.icon, style: .continuous).fill(MLColor.fillQuiet))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(notice.title).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                Text(notice.detail).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: MLSpacing.s8)
            Text(notice.time.map(OutingFormat.clock) ?? "—")
                .font(MLType.monoSecondary)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .padding(.vertical, MLSpacing.s16)
        .overlay(alignment: .bottom) { if !isLast { Rectangle().fill(MLColor.border).frame(height: 1) } }
        .accessibilityElement(children: .combine)
    }
}

/// G-6 Help: white question cards, then Call the warden (shown, not active: the prototype places no calls).
struct GuardianHelpPage: View {
    let model: GuardianModel

    var body: some View {
        GuardianInfoLayout(note: nil) {
            ForEach(GuardianInfoCopy.helpItems(student: model.studentName, block: model.link?.student.block)) { item in
                VStack(alignment: .leading, spacing: MLSpacing.s4) {
                    Text(item.question).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(item.answer).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(MLSpacing.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
                .overlay(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).stroke(MLColor.border, lineWidth: 1))
                .accessibilityElement(children: .combine)
            }
            OutingCallButton(title: GuardianInfoCopy.callWarden, style: .outline)
        }
        .navigationTitle(GuardianInfoCopy.help)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The pushed guardian page: mark and wordmark, an optional note, then the content, on the Orbit canvas.
private struct GuardianInfoLayout<Content: View>: View {
    let note: String?
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    HStack(spacing: MLSpacing.s8) {
                        OrbitMarkView()
                        Text("MealLoop").font(MLType.bodyEmphasis).foregroundStyle(MLColor.ink)
                    }
                    .accessibilityElement(children: .combine)
                    if let note {
                        Text(note).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                    }
                    content
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, MLSpacing.s24)
            }
        }
    }
}

/// The outing this guardian is answering for, from the request record already loaded: place, leave, back by and
/// reason, as the About sheet shows them. Prompt 5 R2 uses it to fill pages that were mostly empty. Missing is a dash.
struct GuardianOutingFacts: View {
    let request: OutingCase?

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            Text(GuardianInfoCopy.theOuting).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                OutingFactRow(label: GuardianInfoCopy.place, value: request?.place)
                OutingFactRow(label: GuardianCopy.leave,
                              value: request?.leaveAt.map { "\(OutingFormat.dayLong($0)) · \(OutingFormat.clock($0))" })
                OutingFactRow(label: GuardianCopy.backBy,
                              value: request?.returnBy.map { "\(OutingFormat.dayLong($0)) · \(OutingFormat.clock($0))" })
                OutingFactRow(label: GuardianCopy.reason, value: request?.reason)
            }
            .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
        }
    }
}
