import SwiftUI

/// Words of the Report and SOS frames (page 07). This is wording, not data.
enum ReportCopy {
    static let whatsWrong = "What's wrong?"
    static let urgent = "Urgent"
    static let urgentFootnote = "Urgent ones go straight to the counter staff."
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
    // SOS.
    static let takePhoto = "Take a photo of the problem"
    static let keepInFrame = "Keep the problem in the frame."
    static let liveOnly = "Live camera only. Gallery photos aren't accepted."
    static let cameraSimulated = "Camera preview. The simulator has no camera; capture is not verified on a device."
    static let shutter = "Take photo and send SOS"
    static let sosSent = "SOS sent"
    static let toldKitchen = "We've told the kitchen team."
    static let sosSteps = ["Reported", "Team told", "Food held", "Checked"]
    static let messageWhenChecked = "You'll get a message when it's checked."
    static let feelingUnwell = "Feeling unwell? Tell a warden or call for help now."
    static let sosFailed = "The SOS didn't send. Tell the counter staff now."
    static let close = "Close"
}

/// Builds the view model from the environment.
struct StudentReportScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session
    var onShowIssue: ((CommunityIssueID) -> Void)?
    /// The meal or dish a rating's Not good hands over, already selected on the form.
    var subject: StudentReportSubject?
    let onClose: () -> Void

    var body: some View {
        if let model = StudentReportViewModel(session: session, repositories: environment.repositories, clock: environment.clock) {
            StudentReportView(model: model, subject: subject, onShowIssue: onShowIssue, onClose: onClose)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// Report · What's wrong (221:63480), Details (221:63525), Sending (221:63541), Failed (221:65437), Receipt (221:63557),
/// No one on duty (221:65454), SOS · Camera (221:63493) and SOS · Sent (221:63509).
///
/// Each step is its own pushed page, so the system Back goes one step: What's wrong → Details → Receipt, and
/// What's wrong → SOS · Sent. The draft (category, note, send state) lives in `StudentReportViewModel`, shared by the
/// pages. Sending and Failed are states of the Details page, not pages: Back is hidden while a send is in flight.
/// The camera stays a full-screen cover, as its frame draws it over the tab bar; Close returns to What's wrong.
/// Receipt and SOS · Sent end the flow: they have no Back, and Done closes the whole report.
struct StudentReportView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: StudentReportViewModel
    @State private var details: StudentReportCategory?
    @State private var camera: StudentReportCategory?
    @State private var sosSent: StudentReportCategory?
    /// The SOS raised from the camera; pushed once the cover has gone.
    @State private var raised: StudentReportCategory?
    let onShowIssue: ((CommunityIssueID) -> Void)?
    let onClose: () -> Void

    init(model: StudentReportViewModel, subject: StudentReportSubject? = nil, onShowIssue: ((CommunityIssueID) -> Void)?,
         onClose: @escaping () -> Void) {
        if let subject { model.subject = subject }
        _model = State(initialValue: model)
        self.onShowIssue = onShowIssue
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
        .navigationDestination(item: $sosSent) { category in
            StudentSOSSentPage(model: model, category: category, onClose: onClose)
        }
        // The camera covers the whole screen, tab bar included, as SOS · Camera (221:63493) draws it.
        .fullScreenCover(isPresented: Binding(get: { camera != nil }, set: { if !$0 { camera = nil } }),
                         onDismiss: {
                             if let raised {
                                 sosSent = raised
                                 self.raised = nil
                             }
                         }) {
            if let category = camera {
                StudentSOSCameraPage(model: model, category: category, onClose: { camera = nil }) {
                    raised = category
                    camera = nil
                }
            }
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
        ForEach(StudentReportCategory.allCases, id: \.self) { category in
            ReportCategoryRow(category: category) {
                switch model.choose(category) {
                case .details(let picked): details = picked
                case .camera(let picked): camera = picked
                }
            }
        }
        Text(ReportCopy.urgentFootnote)
            .font(StudentType.secondary)
            .foregroundStyle(MLColor.inkSecondary)
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
                        .frame(height: 48)
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

/// SOS · Camera (221:63493). The simulator has no camera, so this is a static preview and the capture is not verified
/// on a device. The shutter raises the SOS (`SOSRepository.raise`), then tells every screen the data changed.
struct StudentSOSCameraPage: View {
    @Environment(AppEnvironment.self) private var environment
    @State var model: StudentReportViewModel
    let category: StudentReportCategory
    let onClose: () -> Void
    let onRaised: () -> Void

    var body: some View {
        ZStack {
            Color(hex: 0x1C1C1C).ignoresSafeArea()
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                HStack(spacing: MLSpacing.s12) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(MLColor.onHero)
                            .frame(width: MLSize.hit, height: MLSize.hit)
                            .overlay(Circle().strokeBorder(MLColor.onHeroSecondary, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(ReportCopy.close)
                    HStack(spacing: MLSpacing.s8) {
                        Circle().fill(MLColor.lime).frame(width: 10, height: 10)
                        Text(model.context.mess.name).font(StudentType.secondaryMedium)
                    }
                    .foregroundStyle(MLColor.onHero)
                    .padding(.horizontal, MLSpacing.s16)
                    .frame(height: MLSize.hit)
                    .overlay(Capsule().strokeBorder(MLColor.onHeroSecondary, lineWidth: 1))
                }
                Text(ReportCopy.takePhoto)
                    .font(StudentType.section)
                    .foregroundStyle(MLColor.onHero)
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0x2A2A2A))
                    Circle().fill(Color.white.opacity(0.06)).padding(40)
                    Circle().fill(Color.white.opacity(0.08)).padding(80)
                    Text(MLFormat.time(model.now, in: model.timeZone))
                        .font(StudentType.mono)
                        .foregroundStyle(MLColor.onHero)
                        .padding(.horizontal, MLSpacing.s12)
                        .frame(height: 32)
                        .background(Capsule().fill(Color.black.opacity(0.4)))
                        .padding(MLSpacing.s16)
                }
                .overlay(CameraCorners().stroke(MLColor.lime, lineWidth: 4))
                .frame(maxHeight: 420)
                .accessibilityLabel(ReportCopy.cameraSimulated)
                Text(ReportCopy.keepInFrame)
                    .font(StudentType.body)
                    .foregroundStyle(MLColor.onHero)
                    .frame(maxWidth: .infinity)
                Text(model.sosFailed ? ReportCopy.sosFailed : ReportCopy.liveOnly)
                    .font(StudentType.footnote)
                    .foregroundStyle(model.sosFailed ? MLColor.lime : MLColor.onHeroSecondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                Button {
                    Task {
                        if await model.raiseSOS(category) {
                            environment.dataDidChange()
                            onRaised()
                        }
                    }
                } label: {
                    Circle().fill(MLColor.fillQuiet).frame(width: 64, height: 64)
                        .overlay(Circle().strokeBorder(MLColor.onHero, lineWidth: 4).frame(width: 78, height: 78))
                        .frame(width: 80, height: 80)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(ReportCopy.shutter)
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.top, MLSpacing.s8)
        }
    }
}

/// SOS · Sent (221:63509). The SOS is raised, so the page ends the flow: no Back, Done closes it.
struct StudentSOSSentPage: View {
    @State var model: StudentReportViewModel
    let category: StudentReportCategory
    let onClose: () -> Void

    var body: some View {
        MLScreen(ReportCopy.sosSent, subtitle: StudentReportCategoryTitle.title(category)) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                if let sos = model.sos {
                    card(sos)
                    Text(ReportCopy.feelingUnwell)
                        .font(StudentType.secondaryMedium)
                        .foregroundStyle(MLColor.ink)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
        } bottom: {
            PassBottomButton(title: ReportCopy.done, action: onClose)
                .studentAboveTabBar()
        }
        .navigationBarBackButtonHidden(true)
    }

    private func card(_ sos: SOSCase) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            HStack(spacing: MLSpacing.s8) {
                Circle().fill(MLColor.lime).frame(width: 10, height: 10)
                Text(ReportCopy.sent(MLFormat.time(sos.raisedAt, in: model.timeZone))).font(StudentType.secondaryMedium)
            }
            .foregroundStyle(MLColor.onHeroSecondary)
            Text(ReportCopy.toldKitchen)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(MLColor.onHero)
                .fixedSize(horizontal: false, vertical: true)
            let times: [Date?] = [sos.raisedAt, sos.claim?.at, nil, sos.checks.first?.at]
            ForEach(Array(ReportCopy.sosSteps.enumerated()), id: \.offset) { index, title in
                HStack(spacing: MLSpacing.s12) {
                    SOSStepMark(done: index == 0 || times[index] != nil, current: index == 1 && times[1] == nil)
                    Text(title)
                        .font(index <= 1 ? StudentType.bodySemibold : StudentType.body)
                        .foregroundStyle(index <= 1 ? MLColor.onHero : MLColor.onHeroSecondary)
                    Spacer()
                    if let time = times[index] {
                        Text(MealsFormat.clock(time, in: model.timeZone))
                            .font(StudentType.mono)
                            .foregroundStyle(MLColor.onHeroSecondary)
                    }
                }
            }
            Text(ReportCopy.messageWhenChecked)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.onHeroSecondary)
        }
        .padding(MLSpacing.s20)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.heroBackground))
    }
}

private struct SOSStepMark: View {
    let done: Bool
    let current: Bool

    var body: some View {
        ZStack {
            if done {
                Circle().fill(MLColor.lime)
                Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(MLColor.onLime)
            } else if current {
                Circle().strokeBorder(MLColor.lime, lineWidth: 2.5)
            } else {
                Circle().strokeBorder(MLColor.onHeroSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            }
        }
        .frame(width: 28, height: 28)
        .accessibilityHidden(true)
    }
}

private struct CameraCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let length: CGFloat = 40
        var path = Path()
        for (corner, dx, dy) in [(CGPoint(x: rect.minX, y: rect.minY), 1.0, 1.0), (CGPoint(x: rect.maxX, y: rect.minY), -1.0, 1.0),
                                 (CGPoint(x: rect.minX, y: rect.maxY), 1.0, -1.0), (CGPoint(x: rect.maxX, y: rect.maxY), -1.0, -1.0)] {
            path.move(to: CGPoint(x: corner.x, y: corner.y + dy * length))
            path.addLine(to: corner)
            path.addLine(to: CGPoint(x: corner.x + dx * length, y: corner.y))
        }
        return path
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
                    .foregroundStyle(category.isUrgent ? MLColor.danger : MLColor.ink)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(category.isUrgent ? StudentTint.errorFill : MLColor.fillQuiet))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    if category.isUrgent {
                        Text(ReportCopy.urgent)
                            .font(StudentType.tag)
                            .foregroundStyle(MLColor.danger)
                            .padding(.horizontal, MLSpacing.s8)
                            .frame(height: 24)
                            .background(Capsule().fill(StudentTint.errorFill))
                    }
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
        .accessibilityLabel([category.isUrgent ? ReportCopy.urgent : nil, StudentReportCategoryTitle.title(category),
                             StudentReportCategoryTitle.hint(category)].compactMap { $0 }.joined(separator: ", "))
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
