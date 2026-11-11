import SwiftUI

/// The Guardian root: one page, no tabs (spec: the guardian opens a link). Only a Guardian session reaches it; any
/// other session gets the plain placeholder. Guardian authority comes from the seeded SRM-verified contact only.
/// Production guardian sign-in is not decided (P71), so the sign-in and activation frames run as a simulated
/// first-run flow (`GuardianEntryFlow`) once per launch, then the decision page opens.
struct GuardianRootView: View {
    let session: Session
    /// The model the first-run flow loaded; nil until the flow is finished.
    @State private var entered: GuardianModel?

    /// The one check for who may see the Guardian page.
    static func allows(_ session: Session) -> Bool { session.account.role == .guardian }

    var body: some View {
        if Self.allows(session) {
            if let entered {
                GuardianPageView(account: session.account.id, preparedModel: entered)
                    // The Guardian page has no Me page; the Demo entry sits at the top, as on Welcome.
                    .overlay(alignment: .top) { DemoEntryButton() }
            } else {
                GuardianEntryFlow(account: session.account.id) { entered = $0 }
            }
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

enum GuardianSheet: Hashable {
    case about
    case askToChange
    case language
    case reject
    case withdraw
}

struct GuardianPageView: View {
    @Environment(AppEnvironment.self) private var environment
    let account: AccountID
    /// Screenshot runs pass a prepared model and the sheet to open.
    var preparedModel: GuardianModel?
    var initialSheet: GuardianSheet?
    var recordElapsed = 0
    var photoTyped = ""
    var photoCode = ""
    /// Screenshot runs pass a pushed page (G-5, G-6) to show.
    var initialInfo: GuardianInfoPage?

    @State private var holder: GuardianModel?
    @State private var infoPath: [GuardianInfoPage] = []
    @State private var sheet: GuardianSheet?
    @State private var rejectReason: String?
    @State private var changeFields: Set<String> = []

    var model: GuardianModel { holder ?? GuardianModel(account: account, repository: RemoteOutingCaseRepository()) }

    var body: some View {
        NavigationStack(path: $infoPath) {
            Group {
                if holder != nil {
                    content
                } else {
                    ZStack {
                        OrbitBackground()
                        ProgressView()
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: GuardianInfoPage.self) { page in
                switch page {
                case .notifications: GuardianNotificationsPage(model: model)
                case .help: GuardianHelpPage(model: model)
                }
            }
        }
        .task {
            guard holder == nil else { return }
            if let preparedModel {
                holder = preparedModel
            } else {
                let made = GuardianModel(account: account, repository: OutingCaseRepositories.source(for: environment))
                holder = made
                await made.load()
            }
            if let initialSheet {
                if initialSheet == .reject { rejectReason = GuardianCopy.rejectReasons.first }
                if initialSheet == .askToChange { changeFields = ["Time"] }
                sheet = initialSheet
            }
            if let initialInfo { infoPath = [initialInfo] }
        }
        .mlSheet(isPresented: Binding(get: { sheet != nil }, set: { if !$0 { sheet = nil } })) {
            GuardianSheetView(model: model, sheet: sheet, rejectReason: $rejectReason, changeFields: $changeFields) {
                sheet = nil
            }
        }
    }

    func openLanguage() { sheet = .language }

    @ViewBuilder
    private var content: some View {
        switch model.step {
        case .loading:
            ZStack {
                OrbitBackground()
                ProgressView()
            }
        case .failed(let failure):
            ZStack {
                OrbitBackground()
                ErrorRetryView(failure: failure) { Task { await model.load() } }
                    .padding(.horizontal, MLSpacing.margin)
            }
        case .choose:
            choose
        case .expired:
            expired
        case .consent:
            GuardianConsentStep(model: model, onLanguage: openLanguage)
        case .record(let phase):
            GuardianRecordScreen(model: model, phase: phase, initialElapsed: recordElapsed, runsTimer: recordElapsed == 0)
        case .cameraBlocked:
            cameraBlocked
        case .uploading:
            uploading
        case .checking:
            checking
        case .uploadFailed(let progress, let retriesLeft):
            uploadFailed(progress: progress, retriesLeft: retriesLeft)
        case .retry(let heard, let missing, let next):
            retry(heard: heard, missing: missing, nextAttempt: next)
        case .sendVideo:
            sendVideo
        case .photo(let challenge):
            GuardianPhotoStep(model: model, challenge: challenge, onLanguage: openLanguage, initialTyped: photoTyped,
                              initialCode: photoCode)
        case .answered(let justSent):
            GuardianAnsweredView(model: model, justSent: justSent, onLanguage: openLanguage) { sheet = $0 }
        case .pastAnswers:
            pastAnswers
        }
    }

    // MARK: Choose (GV-01)

    private var choose: some View {
        let request = model.request
        let name = model.studentName
        return GuardianLayout(model: model, title: GuardianCopy.wantsToGoOut(name), subtitle: nil, onLanguage: openLanguage) {
            GuardianOutingSummary(request: request)
            if let replyBy = request?.guardianReplyBy {
                GuardianReplyBy(text: GuardianCopy.replyBy(OutingFormat.dayHour(replyBy)))
            }
            Text(GuardianCopy.yourAnswer).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            GuardianAnswerButton(kind: .accept, isLoading: model.isWorking) { Task { await model.accept() } }
            GuardianAnswerButton(kind: .reject) { sheet = .reject }
            if let error = model.actionError { FieldErrorText(text: error) }
        } footer: {
            GuardianFootnote(text: GuardianCopy.seenOnlyByWarden)
            HStack(spacing: MLSpacing.s32) {
                TextLinkButton(title: GuardianCopy.askToChange) { sheet = .askToChange }
                TextLinkButton(title: GuardianCopy.pastAnswers) { model.showPastAnswers() }
            }
            TextLinkButton(title: GuardianCopy.moreAboutOuting) { sheet = .about }
            Label(GuardianCopy.verifiedAs(name), systemImage: "checkmark.circle")
                .font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
        }
    }

    // MARK: Expired (GV-01 Deadline passed) and closed

    private var expired: some View {
        let request = model.request
        let closed = request?.stage == .closed
        return GuardianLayout(model: model, title: closed ? GuardianCopy.closedTitle : GuardianCopy.expiredTitle,
                              subtitle: GuardianCopy.expiredDetail(request?.guardianReplyBy.map(OutingFormat.dayHour) ?? "—",
                                                                   model.studentName),
                              onLanguage: openLanguage) {
            GuardianOutingSummary(request: request)
            GuardianAnswerButton(kind: .accept, isDisabled: true) {}
            GuardianAnswerButton(kind: .reject, isDisabled: true) {}
        } footer: {
            GuardianFootnote(text: GuardianCopy.neverWithoutYou)
            TextLinkButton(title: GuardianCopy.pastAnswers) { model.showPastAnswers() }
        }
    }

    // MARK: Past answers (GV-07)

    private var pastAnswers: some View {
        GuardianLayout(model: model, title: GuardianCopy.pastAnswers, subtitle: GuardianCopy.forStudent(model.studentName),
                       onLanguage: openLanguage) {
            VStack(spacing: 0) {
                ForEach(model.pastAnswers) { answer in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(answer.place ?? "—").font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                            Text(GuardianCopy.pastLine(OutingFormat.dayShort(answer.day), accepted: answer.kind == .accepted))
                                .font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                        }
                        Spacer()
                        OutingTag(text: GuardianCopy.pastTag(answer.method), style: answer.method == nil ? .dashed : .outline)
                    }
                    .frame(minHeight: 56)
                    .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
                    .accessibilityElement(children: .combine)
                }
            }
            .overlay(alignment: .top) { Rectangle().fill(MLColor.border).frame(height: 1) }
            // Counts from the same past answers listed above (Prompt 5, R2).
            VStack(spacing: 0) {
                OutingFactRow(label: GuardianInfoCopy.accepted,
                              value: String(model.pastAnswers.filter { $0.kind == .accepted }.count))
                OutingFactRow(label: GuardianInfoCopy.rejected,
                              value: String(model.pastAnswers.filter { $0.kind == .rejected }.count))
                OutingFactRow(label: GuardianInfoCopy.byVideo,
                              value: String(model.pastAnswers.filter { $0.method == .liveVideoAutoChecked || $0.method == .videoNeedsReview }.count))
            }
            .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
            .padding(.top, MLSpacing.s16)
        } footer: {
            GuardianFootnote(text: GuardianCopy.videosDeleted)
            HStack(spacing: MLSpacing.s32) {
                TextLinkButton(title: GuardianCopy.messages) { infoPath.append(.notifications) }
                TextLinkButton(title: GuardianCopy.help) { infoPath.append(.help) }
            }
            TextLinkButton(title: GuardianCopy.backToRequest) { model.backFromPastAnswers() }
        }
    }
}

// MARK: - Layout pieces

/// The guardian page: mark, wordmark and the language pill; a large title; content; a footer at the bottom.
struct GuardianLayout<Content: View, Footer: View>: View {
    let model: GuardianModel
    let title: String
    let subtitle: String?
    let onLanguage: () -> Void
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    HStack {
                        HStack(spacing: MLSpacing.s8) {
                            OrbitMarkView()
                            Text("MealLoop").font(MLType.bodyEmphasis).foregroundStyle(MLColor.ink)
                        }
                        .accessibilityElement(children: .combine)
                        Spacer()
                        Button(action: onLanguage) {
                            Text(GuardianCopy.languagePill)
                                .font(MLType.body)
                                .foregroundStyle(MLColor.ink)
                                .padding(.horizontal, MLSpacing.s16)
                                .frame(minHeight: MLSize.hit)
                                .background(Capsule().fill(MLColor.surface))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(GuardianCopy.languageTitle)
                    }
                    VStack(alignment: .leading, spacing: MLSpacing.s8) {
                        Text(title)
                            .font(MLType.largeTitle)
                            .foregroundStyle(MLColor.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        if let subtitle {
                            Text(subtitle).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                        }
                    }
                    content
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: MLSpacing.s12) { footer }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, MLSpacing.margin)
                    .padding(.top, MLSpacing.s12)
                    .padding(.bottom, MLSpacing.s8)
                    // On a small phone the content scrolls under the footer; the canvas keeps the two apart.
                    .background(MLColor.canvas.opacity(0.96).ignoresSafeArea(edges: .bottom))
            }
        }
    }
}

struct GuardianFootnote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(MLType.body)
            .foregroundStyle(MLColor.inkSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

/// "Express Avenue Mall" and "Sat 17 Aug · Shopping · 2 → 8 PM".
struct GuardianOutingSummary: View {
    let request: OutingCase?

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(request?.place ?? "—").font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
            Text(line).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var line: String {
        guard let request, let leave = request.leaveAt, let back = request.returnBy else { return "—" }
        return GuardianCopy.outingLine(day: OutingFormat.dayLong(leave), reason: request.reason,
                                       hours: OutingFormat.arrowHours(leave, back))
    }
}

/// "● Reply by Fri 11 PM": a dot and plain text, not a button.
struct GuardianReplyBy: View {
    let text: String

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            Circle().fill(MLColor.ink).frame(width: MLSize.statusDot, height: MLSize.statusDot)
            Text(text).font(MLType.bodyEmphasis).foregroundStyle(MLColor.ink)
        }
        .accessibilityElement(children: .combine)
    }
}

/// I accept (black, camera) and I reject (outlined), the two answers (GV-01).
struct GuardianAnswerButton: View {
    enum Kind {
        case accept
        case reject
    }

    let kind: Kind
    var isLoading = false
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s16) {
                if kind == .accept {
                    Image(systemName: "camera")
                        .font(.system(size: 20))
                        .foregroundStyle(MLColor.ink)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(isDisabled ? MLColor.fillQuiet : MLColor.lime))
                        .overlay(Circle().stroke(isDisabled ? MLColor.inkSecondary : .clear, lineWidth: 1))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind == .accept ? GuardianCopy.iAccept : GuardianCopy.iReject).font(MLType.title2)
                    Text(kind == .accept ? GuardianCopy.recordVideo : GuardianCopy.oneTapNoVideo).font(MLType.body)
                        .opacity(0.8)
                }
                Spacer()
                if isLoading { ProgressView().tint(MLColor.onHero) }
            }
            .foregroundStyle(foreground)
            .padding(MLSpacing.s20)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .background { background }
            .contentShape(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
    }

    private var foreground: Color {
        if isDisabled { return MLColor.inkSecondary }
        return kind == .accept ? MLColor.onHero : MLColor.ink
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous)
        if isDisabled {
            if kind == .accept {
                shape.fill(MLColor.fillQuiet)
            } else {
                shape.stroke(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            }
        } else if kind == .accept {
            shape.fill(MLColor.ink)
        } else {
            shape.stroke(MLColor.ink, lineWidth: 1.5)
        }
    }
}

// MARK: - Consent (GV-00)

struct GuardianConsentStep: View {
    let model: GuardianModel
    let onLanguage: () -> Void
    @State private var agreed = false

    var body: some View {
        GuardianLayout(model: model, title: GuardianCopy.consentTitle, subtitle: GuardianCopy.consentSubtitle,
                       onLanguage: onLanguage) {
            GuardianSteps(steps: GuardianCopy.consentSteps.map { ($0.0, $0.1) })
        } footer: {
            Button {
                agreed.toggle()
            } label: {
                HStack(spacing: MLSpacing.s12) {
                    Image(systemName: agreed ? "checkmark.square" : "square")
                        .font(.system(size: 26))
                    Text(GuardianCopy.agree).font(MLType.staffBody)
                    Spacer()
                }
                .foregroundStyle(MLColor.ink)
                .frame(minHeight: MLSize.hit)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(agreed ? .isSelected : [])
            InkActionButton(title: GuardianCopy.continueTitle, isLoading: model.isWorking) {
                Task { await model.agreeAndContinue() }
            }
            .disabled(!agreed)
            if let error = model.actionError { FieldErrorText(text: error) }
            GuardianFootnote(text: GuardianCopy.consentFooter)
        }
    }
}

// MARK: - Sheets

/// GV-01 About, Ask to change, Language; GV-08 Reject; GV-06 Withdraw.
struct GuardianSheetView: View {
    let model: GuardianModel
    let sheet: GuardianSheet?
    @Binding var rejectReason: String?
    @Binding var changeFields: Set<String>
    let onClose: () -> Void

    var body: some View {
        let name = model.studentName
        let request = model.request
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            switch sheet {
            case .about?:
                SheetHeader(title: GuardianCopy.aboutTitle, onClose: onClose)
                VStack(spacing: 0) {
                    OutingFactRow(label: GuardianCopy.leave, value: request?.leaveAt.map { "\(OutingFormat.dayLong($0)) · \(OutingFormat.clock($0))" })
                    OutingFactRow(label: GuardianCopy.backBy, value: request?.returnBy.map { "\(OutingFormat.dayLong($0)) · \(OutingFormat.clock($0))" })
                    OutingFactRow(label: GuardianCopy.reason, value: request?.reason)
                }
                GuardianSteps(steps: [
                    (GuardianCopy.youAnswer, GuardianCopy.youAnswerDetail(request?.guardianReplyBy.map(OutingFormat.dayHour) ?? "—")),
                    (GuardianCopy.wardenDecides, GuardianCopy.wardenDecidesDetail(request?.wardenDecideBy.map(OutingFormat.dayHour) ?? "—")),
                    (GuardianCopy.passIssued(name), GuardianCopy.passValidOnly(window(request))),
                ])
                .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.fillQuiet))
            case .askToChange?:
                SheetHeader(title: GuardianCopy.whatShouldChange, subtitle: GuardianCopy.changeDetail(name), onClose: onClose)
                HStack(spacing: MLSpacing.s8) {
                    ForEach(GuardianCopy.changeOptions, id: \.self) { option in
                        ChoiceChip(title: option, isSelected: changeFields.contains(option)) {
                            if changeFields.contains(option) { changeFields.remove(option) } else { changeFields.insert(option) }
                        }
                    }
                }
                InkActionButton(title: GuardianCopy.sendTo(name), isLoading: model.isWorking) {
                    let fields = GuardianCopy.changeOptions.filter { changeFields.contains($0) }
                    Task {
                        await model.askToChange(fields: fields)
                        onClose()
                    }
                }
                .disabled(changeFields.isEmpty)
            case .language?:
                SheetHeader(title: GuardianCopy.languageTitle, onClose: onClose)
                VStack(spacing: 0) {
                    ForEach(GuardianCopy.languages, id: \.self) { language in
                        HStack {
                            Text(language).font(MLType.staffBody).foregroundStyle(MLColor.ink)
                            Spacer()
                            Image(systemName: "checkmark").foregroundStyle(MLColor.ink)
                        }
                        .frame(minHeight: 64)
                        .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isSelected)
                    }
                }
                Text(GuardianCopy.languageNote).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            case .reject?:
                SheetHeader(title: GuardianCopy.rejectTitle, subtitle: GuardianCopy.rejectDetail(name), onClose: onClose)
                HStack(spacing: MLSpacing.s8) {
                    ForEach(GuardianCopy.rejectReasons, id: \.self) { reason in
                        ChoiceChip(title: reason, isSelected: rejectReason == reason) {
                            rejectReason = rejectReason == reason ? nil : reason
                        }
                    }
                }
                InkActionButton(title: GuardianCopy.rejectOuting, isLoading: model.isWorking) {
                    Task {
                        await model.reject(reason: rejectReason)
                        onClose()
                    }
                }
                OutlineActionButton(title: GuardianCopy.goBack, action: onClose)
            case .withdraw?:
                SheetHeader(title: GuardianCopy.withdrawTitle, subtitle: GuardianCopy.withdrawDetail(name), onClose: onClose)
                InkActionButton(title: GuardianCopy.withdrawApproval, isLoading: model.isWorking) {
                    Task {
                        await model.withdraw()
                        onClose()
                    }
                }
                OutlineActionButton(title: GuardianCopy.keepIt, action: onClose)
            case nil:
                EmptyView()
            }
        }
    }

    private func window(_ request: OutingCase?) -> String {
        guard let leave = request?.leaveAt, let back = request?.returnBy else { return "—" }
        return "\(OutingFormat.dayLong(leave)), \(OutingFormat.hours(leave, back))"
    }
}
