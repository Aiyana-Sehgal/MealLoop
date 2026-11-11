import SwiftUI

/// Words of the Report and SOS frames (page 07). This is wording, not data.
enum ReportCopy {
    static let whatsWrong = "What's wrong?"
    static let noOneOnDuty = "No one reads reports right now. Urgent? Tell the counter."
    static let reportProblem = "Report a problem"
    static let whatHappened = "What happened? (optional)"
    static let addPhoto = "Add photo"
    static let whatHappensNext = "WHAT HAPPENS NEXT"
    static let sendReport = "Send report"
    static let sending = "Sending…"
    static let didntSend = "Didn't send. Try again."
    static let tryAgain = "Try again"
    static let reportSent = "Report sent"
    static func sent(_ time: String) -> String { "Sent \(time)" }
    static let sentStep = "Sent"
    static let viewReport = "View report"
    static let done = "Done"
    static let heldTitle = "The mess team checks it first"
    static let next: [(String, String)] = [("Seen", "The mess read it"), ("Working on it", "They're fixing it"),
                                           ("Fixed", "You check if it's better")]
    static let cameraSimulated = "Camera preview. The simulator has no camera; capture is not verified on a device."
    static let close = "Close"
}

/// Builds the view model from the environment.
struct StudentReportScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session
    var onShowIssue: ((CommunityIssueID) -> Void)?
    /// The meal or dish a rating's Not good hands over, already selected on the form.
    var subject: StudentReportSubject?
    /// Opens SOS (2162:6) from "Unsafe or unwell? Use SOS".
    let onSOS: () -> Void
    let onClose: () -> Void

    var body: some View {
        if let model = StudentReportViewModel(session: session, repositories: environment.repositories, clock: environment.clock) {
            StudentReportView(model: model, subject: subject, onShowIssue: onShowIssue, onSOS: onSOS, onClose: onClose)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// Report · What's wrong (221:63480), Details (221:63525), Sending (221:63541), Failed (221:65437), Receipt (221:63557)
/// and No one on duty (221:65454).
///
/// Each step is its own pushed page, so the system Back goes one step: What's wrong → Details → Receipt. The draft
/// (category, note, send state) lives in `StudentReportViewModel`, shared by the pages. Sending and Failed are states of
/// the Details page, not pages: Back is hidden while a send is in flight. Receipt ends the flow: Done closes the report.
/// Something unsafe in the food is an SOS, not a report: "Unsafe or unwell? Use SOS" opens SOS · new (2162:6). The old
/// red Urgent rows and their camera and Sent pages are gone.
struct StudentReportView: View {
    @State private var model: StudentReportViewModel
    @State private var details: StudentReportCategory?
    let onShowIssue: ((CommunityIssueID) -> Void)?
    let onSOS: () -> Void
    let onClose: () -> Void

    init(model: StudentReportViewModel, subject: StudentReportSubject? = nil, onShowIssue: ((CommunityIssueID) -> Void)?,
         onSOS: @escaping () -> Void, onClose: @escaping () -> Void) {
        if let subject { model.subject = subject }
        _model = State(initialValue: model)
        self.onShowIssue = onShowIssue
        self.onSOS = onSOS
        self.onClose = onClose
    }

    var body: some View {
        MLScreen(ReportCopy.whatsWrong, bottomClearance: .tabBar) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                choose
            }
        }
        .navigationDestination(item: $details) { category in
            StudentReportDetailsPage(model: model, category: category, onShowIssue: onShowIssue, onClose: onClose)
        }
        .task { await model.load() }
    }

    @ViewBuilder
    private var choose: some View {
        if !model.isDeskStaffed {
            HStack(alignment: .top, spacing: MLSpacing.s12) {
                Image(systemName: "clock").accessibilityHidden(true)
                Text(ReportCopy.noOneOnDuty).font(StudentType.footnote).fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(MLColor.ink)
            .padding(MLSpacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(hex: 0xFFF3D6)))
        }
        ForEach(StudentReportCategory.reportable, id: \.self) { category in
            ReportCategoryRow(category: category) {
                details = model.choose(category)
            }
        }
        Button(DishFeedbackCopy.useSOS, action: onSOS)
            .font(StudentType.secondary)
            .underline()
            .foregroundStyle(MLColor.ink)
            .frame(minHeight: MLSize.hit)
            .accessibilityHint("Opens SOS")
    }
}

/// The chips under the report's header card: the dish, the mess, the meal and the time.
@MainActor
private func reportChips(_ model: StudentReportViewModel, sentAt: Date?) -> [String] {
    var chips = [model.subject?.dishName, model.context.mess.name].compactMap { $0 }
    if let meal = model.meal {
        chips.append("\(MLFormat.mealSlot(meal.slot)) · \(StudentFormat.mediumDay(meal.startsAt, in: model.timeZone))")
    }
    chips.append(sentAt.map { ReportCopy.sent(MLFormat.time($0, in: model.timeZone)) } ?? MLFormat.time(model.now, in: model.timeZone))
    return chips
}

/// Report · Details (221:63525) with its Sending (221:63541) and Failed (221:65437) states. Send report is pinned above
/// the tab bar; the Receipt is pushed once the report is recorded.
struct StudentReportDetailsPage: View {
    @State var model: StudentReportViewModel
    let category: StudentReportCategory
    let onShowIssue: ((CommunityIssueID) -> Void)?
    let onClose: () -> Void
    @State private var showsReceipt = false
    @FocusState private var noteFocused: Bool

    var body: some View {
        MLScreen(ReportCopy.reportProblem) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                ReportHeaderCard(category: category, chips: reportChips(model, sentAt: nil))
                Text(ReportCopy.whatHappened)
                    .font(StudentType.footnote)
                    .foregroundStyle(MLColor.inkSecondary)
                TextField(ReportCopy.whatHappened, text: $model.note, prompt: nil, axis: .vertical)
                    .font(StudentType.body)
                    .lineLimit(2...5)
                    .focused($noteFocused)
                    .padding(.horizontal, MLSpacing.s16)
                    .padding(.vertical, MLSpacing.s8)
                    .frame(minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(MLColor.surface))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(MLColor.border, lineWidth: 1))
                    .disabled(model.send == .sending)
                    .mlKeepsVisible(id: "report.note", when: noteFocused)
                Button {} label: {
                    Label(ReportCopy.addPhoto, systemImage: "camera")
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(MLColor.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .overlay(Capsule().strokeBorder(MLColor.ink, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .disabled(true)
                .accessibilityHint(ReportCopy.cameraSimulated)
                if model.send == .failed {
                    HStack(spacing: MLSpacing.s12) {
                        Image(systemName: "exclamationmark.triangle").accessibilityHidden(true)
                        Text(ReportCopy.didntSend).font(StudentType.secondaryMedium)
                    }
                    .foregroundStyle(MLColor.danger)
                    .padding(.horizontal, MLSpacing.s20)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(StudentTint.errorFill))
                }
                ReportNextSteps()
            }
        } bottom: {
            PassBottomButton(title: model.send == .failed ? ReportCopy.tryAgain
                             : (model.send == .sending ? ReportCopy.sending : ReportCopy.sendReport)) {
                noteFocused = false
                Task {
                    await model.sendReport(category)
                    if model.receipt != nil { showsReceipt = true }
                }
            }
            .allowsHitTesting(model.send != .sending)
            .studentAboveTabBar()
        }
        // Back would abandon a send in flight, so it waits until the send has an answer.
        .navigationBarBackButtonHidden(model.send == .sending)
        .navigationDestination(isPresented: $showsReceipt) {
            StudentReportReceiptPage(model: model, onShowIssue: onShowIssue, onClose: onClose)
        }
    }
}

/// Report · Receipt (221:63557). The report is recorded, so the page ends the flow: no Back, Done closes it.
struct StudentReportReceiptPage: View {
    @State var model: StudentReportViewModel
    let onShowIssue: ((CommunityIssueID) -> Void)?
    let onClose: () -> Void

    var body: some View {
        MLScreen(ReportCopy.reportSent) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                if let receipt = model.receipt {
                    ReceiptCard(receipt: receipt, chips: reportChips(model, sentAt: receipt.sentAt))
                    ReportNextSteps()
                }
            }
        } bottom: {
            HStack(spacing: MLSpacing.s12) {
                if case .published(let id)? = model.receipt?.outcome, let onShowIssue {
                    OutlineActionButton(title: ReportCopy.viewReport) { onShowIssue(id) }
                }
                InkActionButton(title: ReportCopy.done, action: onClose)
            }
            .studentAboveTabBar()
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct ReportCategoryRow: View {
    let category: StudentReportCategory
    let action: () -> Void

    private var symbol: String {
        switch category {
        case .foundInFood: return "exclamationmark.triangle"
        case .smellsOrTastesOff: return "nose"
        case .notClean: return "drop"
        case .ranOut: return "fork.knife"
        case .staffOrService: return "person.2"
        case .somethingElse: return "ellipsis"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s16) {
                Image(systemName: symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(MLColor.ink)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(MLColor.fillQuiet))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(StudentReportCategoryTitle.title(category))
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(MLColor.ink)
                    Text(StudentReportCategoryTitle.hint(category))
                        .font(StudentType.footnote)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MLColor.ink)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, MLSpacing.s16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(StudentReportCategoryTitle.title(category)), \(StudentReportCategoryTitle.hint(category))")
    }
}

/// The black card at the top of Details: the category and where and when.
struct ReportHeaderCard: View {
    let category: StudentReportCategory
    let chips: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            HStack(spacing: MLSpacing.s12) {
                ReportCategoryIcon(category: category)
                Text(StudentReportCategoryTitle.title(category))
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(MLColor.onHero)
            }
            StudentFlowLayout(spacing: MLSpacing.s8) {
                ForEach(chips, id: \.self) { chip in
                    Text(chip)
                        .font(StudentType.tag)
                        .foregroundStyle(MLColor.onHero)
                        .padding(.horizontal, MLSpacing.s12)
                        .frame(height: 32)
                        .overlay(Capsule().strokeBorder(MLColor.onHeroSecondary, lineWidth: 1.5))
                }
            }
        }
        .padding(MLSpacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous).fill(MLColor.heroBackground))
    }
}

private struct ReportCategoryIcon: View {
    let category: StudentReportCategory

    var body: some View {
        Image(systemName: category == .notClean ? "drop" : "exclamationmark.bubble")
            .font(.system(size: 17))
            .foregroundStyle(MLColor.ink)
            .frame(width: 40, height: 40)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(MLColor.surface))
            .accessibilityHidden(true)
    }
}

/// Report · Receipt: the reference, the category, and where it stands.
struct ReceiptCard: View {
    let receipt: StudentReportReceipt
    let chips: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Text(ReportCopy.reportSent)
                .font(StudentType.secondaryMedium)
                .foregroundStyle(MLColor.onHeroSecondary)
            Text(receipt.reference)
                .font(.system(size: 52, weight: .bold, design: .monospaced))
                .foregroundStyle(MLColor.onHero)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            ReportHeaderCard(category: receipt.category, chips: chips)
                .padding(-MLSpacing.s16)
                .padding(.vertical, MLSpacing.s8)
            if case .heldForReview(let reason) = receipt.outcome {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ReportCopy.heldTitle).font(StudentType.bodySemibold).foregroundStyle(MLColor.onHero)
                    Text(reason).font(StudentType.secondary).foregroundStyle(MLColor.onHeroSecondary)
                }
            }
            DashedRule().stroke(MLColor.onHeroSecondary, style: StrokeStyle(lineWidth: 1, dash: [4, 3])).frame(height: 1)
            HStack {
                Text(ReportCopy.sentStep.uppercased()).font(StudentType.eyebrow).tracking(0.8)
                Spacer()
                Text("1 / 4").font(StudentType.eyebrow)
            }
            .foregroundStyle(MLColor.onHero)
        }
        .padding(MLSpacing.s20)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.heroBackground))
        .accessibilityElement(children: .combine)
    }
}

private struct DashedRule: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// "WHAT HAPPENS NEXT": Seen, Working on it, Fixed.
struct ReportNextSteps: View {
    var body: some View {
        Text(ReportCopy.whatHappensNext)
            .font(StudentType.eyebrow)
            .tracking(1.2)
            .foregroundStyle(MLColor.inkSecondary)
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            ForEach(ReportCopy.next, id: \.0) { title, detail in
                HStack(alignment: .top, spacing: MLSpacing.s12) {
                    Circle().strokeBorder(MLColor.ink, lineWidth: 1.5).frame(width: 12, height: 12).padding(.top, 5)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(StudentType.body).foregroundStyle(MLColor.ink)
                        Text(detail).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
                    }
                }
            }
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous).fill(MLColor.surface))
    }
}
