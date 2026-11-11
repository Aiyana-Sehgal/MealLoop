import SwiftUI

// SOS · new (2162:6), I feel unwell (2162:161), Camera · GPS unavailable (2162:405), Camera denied (2162:493), Review
// (2162:152142), Review · GPS unavailable (2162:152270), Review · No photo (2162:152398), Review · Offline
// (2162:152516), Review · Failed (2162:152648) and SOS Sent (221:63509). Reached from "Unsafe or unwell? Use SOS" on the
// dish feedback sheets. SOS → Review → Sent are pushed pages (Back goes one step); the camera covers the whole screen,
// tab bar included, as its frames draw it.

/// Builds the view model from the environment.
struct StudentSOSScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session
    let onClose: () -> Void

    var body: some View {
        if let context = session.student {
            StudentSOSView(model: StudentSOSViewModel(context: context, repositories: environment.repositories,
                                                      clock: environment.clock), onClose: onClose)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// SOS · new (2162:6) and I feel unwell (2162:161): pick one, optionally a dish, then the photo.
struct StudentSOSView: View {
    @State private var model: StudentSOSViewModel
    @State private var showsCamera = false
    @State private var showsReview = false
    let onClose: () -> Void

    init(model: StudentSOSViewModel, onClose: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onClose = onClose
    }

    var body: some View {
        MLScreen(StudentSOSCopy.title, subtitle: StudentSOSCopy.pickOne) {
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                ForEach(StudentSOSCategory.allCases, id: \.self) { category in
                    StudentSOSCategoryRow(category: category, selected: model.category == category) {
                        model.choose(category)
                    }
                }
                if !model.dishes.isEmpty {
                    Text(StudentSOSCopy.whichDish)
                        .font(StudentType.secondaryMedium)
                        .foregroundStyle(MLColor.inkSecondary)
                        .padding(.top, MLSpacing.s8)
                    StudentChipFlow(spacing: MLSpacing.s8) {
                        ForEach(model.dishes, id: \.self) { dish in
                            StudentSOSDishChip(dish: dish, selected: model.dish == dish) { model.toggle(dish: dish) }
                        }
                    }
                }
            }
        } bottom: {
            VStack(spacing: MLSpacing.s8) {
                PassBottomButton(title: StudentSOSCopy.next) { showsCamera = true }
                    .disabled(!model.canGoOn)
                    .opacity(model.canGoOn ? 1 : 0.4)
                Text(StudentSOSCopy.footnote)
                    .font(StudentType.footnote)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .studentAboveTabBar()
        }
        .task { await model.load() }
        .fullScreenCover(isPresented: $showsCamera, onDismiss: {
            if model.hasPhoto || model.withoutPhoto { showsReview = true }
        }) {
            StudentSOSCameraView(model: model) { showsCamera = false }
        }
        .navigationDestination(isPresented: $showsReview) {
            StudentSOSReviewPage(model: model, onRetake: { showsCamera = true }, onClose: onClose)
        }
        .mlAnimation(.snappy, value: model.category)
    }
}

private struct StudentSOSCategoryRow: View {
    let category: StudentSOSCategory
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s16) {
                Image(systemName: category.symbol)
                    .font(.system(size: 17))
                    .foregroundStyle(selected ? MLColor.onHero : MLColor.ink)
                    .frame(width: MLSize.hit, height: MLSize.hit)
                    .background(Circle().fill(selected ? MLColor.onHero.opacity(0.12) : MLColor.fillQuiet))
                    .accessibilityHidden(true)
                Text(category.title)
                    .font(StudentType.body)
                    .foregroundStyle(selected ? MLColor.onHero : MLColor.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: MLSpacing.s8)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(MLColor.onLime)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(MLColor.lime))
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, MLSpacing.s16)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous)
                .fill(selected ? MLColor.heroBackground : MLColor.surface))
            .overlay(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous)
                .strokeBorder(selected ? .clear : MLColor.border, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: selected) { _, new in new }
    }
}

private struct StudentSOSDishChip: View {
    let dish: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(dish)
                .font(StudentType.secondaryMedium)
                .foregroundStyle(selected ? MLColor.onHero : MLColor.ink)
                .padding(.horizontal, MLSpacing.s16)
                .frame(minHeight: MLSize.hit)
                .background(Capsule().fill(selected ? MLColor.heroBackground : .clear))
                .overlay(Capsule().strokeBorder(MLColor.ink, lineWidth: selected ? 0 : 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// SOS · Camera (221:63493), GPS unavailable (2162:405) and Camera denied (2162:493). A static preview: the simulator
/// has no camera, so the capture is not verified on a device.
struct StudentSOSCameraView: View {
    let model: StudentSOSViewModel
    let onClose: () -> Void

    var body: some View {
        ZStack {
            StudentSOSDark.background.ignoresSafeArea()
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
                    .accessibilityLabel(StudentSOSCopy.close)
                    StudentSOSPlaceChip(model: model)
                }
                if model.camera == .denied {
                    StudentSOSCameraDenied(model: model, onClose: onClose)
                } else {
                    StudentSOSCameraLive(model: model, onClose: onClose)
                }
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.top, MLSpacing.s8)
        }
    }
}

/// The dark camera surfaces, as the existing SOS · Camera page draws them.
enum StudentSOSDark {
    static let background = Color(hex: 0x1C1C1C)
    static let preview = Color(hex: 0x2A2A2A)
}

private struct StudentSOSCameraLive: View {
    let model: StudentSOSViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: MLSpacing.s16) {
            Text(StudentSOSCopy.takePhoto)
                .font(StudentType.section)
                .foregroundStyle(MLColor.onHero)
                .frame(maxWidth: .infinity, alignment: .leading)
            StudentSOSPreview(time: MLFormat.time(model.now, in: model.timeZone), model: model)
                .frame(maxHeight: 420)
            Text(StudentSOSCopy.keepInFrame).font(StudentType.body).foregroundStyle(MLColor.onHero)
            Text(StudentSOSCopy.liveOnly)
                .font(StudentType.footnote)
                .foregroundStyle(MLColor.onHeroSecondary)
                .multilineTextAlignment(.center)
            Button {
                model.takePhoto()
                onClose()
            } label: {
                Circle().fill(MLColor.fillQuiet).frame(width: 64, height: 64)
                    .overlay(Circle().strokeBorder(MLColor.onHero, lineWidth: 4).frame(width: 78, height: 78))
                    .frame(width: 80, height: 80)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(StudentSOSCopy.takePhoto)
            .accessibilityHint(ReportCopy.cameraSimulated)
        }
    }
}

private struct StudentSOSCameraDenied: View {
    let model: StudentSOSViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: MLSpacing.s16) {
            Text(StudentSOSCopy.cameraOff)
                .font(StudentType.section)
                .foregroundStyle(MLColor.onHero)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: MLSpacing.s16) {
                Image(systemName: "camera").font(StudentType.section).accessibilityHidden(true)
                Text(StudentSOSCopy.cameraOffDetail)
                    .font(StudentType.body)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                } label: {
                    Text(StudentSOSCopy.openSettings)
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(MLColor.ink)
                        .padding(.horizontal, MLSpacing.s20)
                        .frame(minHeight: 48)
                        .background(Capsule().fill(MLColor.canvas))
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(MLColor.onHero)
            .padding(MLSpacing.s24)
            .frame(maxWidth: .infinity, minHeight: 360)
            .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(StudentSOSDark.preview))
            Button {
                model.continueWithoutPhoto()
                onClose()
            } label: {
                Text(StudentSOSCopy.sendWithoutPhoto)
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(MLColor.onHero)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .overlay(Capsule().strokeBorder(MLColor.onHero, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            Text(StudentSOSCopy.flagged)
                .font(StudentType.footnote)
                .foregroundStyle(MLColor.onHeroSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

/// The place chip: the mess, or "No GPS · place not recorded". No distance is shown: nothing is measured.
private struct StudentSOSPlaceChip: View {
    let model: StudentSOSViewModel

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            Circle().fill(model.location == .atMess ? MLColor.lime : MLColor.danger).frame(width: 10, height: 10)
                .accessibilityHidden(true)
            Text(model.location == .atMess ? model.context.mess.name : StudentSOSCopy.noGPS)
                .font(StudentType.secondaryMedium)
        }
        .foregroundStyle(MLColor.onHero)
        .padding(.horizontal, MLSpacing.s16)
        .frame(height: MLSize.hit)
        .overlay(Capsule().strokeBorder(MLColor.onHeroSecondary, lineWidth: 1))
    }
}

/// The static preview with its corners, time and place.
private struct StudentSOSPreview: View {
    let time: String
    let model: StudentSOSViewModel

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: MLSpacing.s8).fill(StudentSOSDark.preview)
            Circle().fill(MLColor.onHero.opacity(0.06)).padding(40)
            Circle().fill(MLColor.onHero.opacity(0.08)).padding(80)
            HStack(spacing: MLSpacing.s8) {
                Text(time).font(StudentType.mono)
                Spacer(minLength: 0)
                Circle().fill(model.location == .atMess ? MLColor.lime : MLColor.danger).frame(width: 8, height: 8)
                Text(model.location == .atMess ? model.context.mess.name : StudentSOSCopy.noGPSShort)
                    .font(StudentType.footnote)
            }
            .foregroundStyle(MLColor.onHero)
            .padding(MLSpacing.s16)
        }
        .overlay(StudentSOSCorners().stroke(MLColor.onHeroSecondary, lineWidth: 2).padding(MLSpacing.s8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ReportCopy.cameraSimulated)
    }
}

private struct StudentSOSCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let length: CGFloat = 18
        var path = Path()
        let corners: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(rect.minX, rect.minY, 1, 1), (rect.maxX, rect.minY, -1, 1),
                                                               (rect.minX, rect.maxY, 1, -1), (rect.maxX, rect.maxY, -1, -1)]
        for (x, y, dx, dy) in corners {
            path.move(to: CGPoint(x: x, y: y + dy * length))
            path.addLine(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + dx * length, y: y))
        }
        return path
    }
}

/// Review SOS (2162:152142) with GPS unavailable (2162:152270), No photo (2162:152398), Offline (2162:152516) and Failed
/// (2162:152648).
struct StudentSOSReviewPage: View {
    @Environment(AppEnvironment.self) private var environment
    @State var model: StudentSOSViewModel
    @State private var sent = false
    let onRetake: () -> Void
    let onClose: () -> Void

    var body: some View {
        MLScreen(StudentSOSCopy.review, subtitle: StudentSOSCopy.checkProof) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                if model.isOffline {
                    StudentOfflineBanner(text: StudentSOSCopy.offline).mlTransition(.fromTop)
                }
                StudentSOSProofCard(model: model, onRetake: onRetake)
                StudentSOSChecks(model: model)
                if model.sendState == .failed {
                    HStack(alignment: .top, spacing: MLSpacing.s8) {
                        Image(systemName: "exclamationmark.triangle").accessibilityHidden(true)
                        Text(StudentSOSCopy.failed).font(StudentType.bodySemibold).fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(MLColor.danger)
                    .padding(MLSpacing.s16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(StudentTint.errorFill))
                    .accessibilityElement(children: .combine)
                    .mlTransition(.fade)
                }
            }
        } bottom: {
            VStack(spacing: MLSpacing.s8) {
                PassBottomButton(title: buttonTitle) {
                    Task {
                        let raised = model.isOffline ? await model.sendWhenOnline() : await model.send()
                        if raised { finish() }
                    }
                }
                .disabled(model.isSending || model.sendState == .waitingForConnection)
                Text(StudentSOSCopy.toldAtOnce)
                    .font(StudentType.footnote)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .studentAboveTabBar()
        }
        .navigationBarBackButtonHidden(model.isSending)
        // On appear and whenever the data changes (the prototype's reconnect): a kept SOS is sent with the same key.
        .task(id: environment.dataRevision) { await retryOrCheck() }
        .navigationDestination(isPresented: $sent) {
            StudentSOSSentView(model: model, onClose: onClose)
        }
        .sensoryFeedback(.warning, trigger: model.sendState) { _, new in new == .failed }
        .mlAnimation(.snappy, value: model.sendState)
    }

    private func retryOrCheck() async {
        if model.sendState == .waitingForConnection {
            if await model.send() { finish() }
        } else {
            await model.checkConnection()
        }
    }

    private func finish() {
        environment.dataDidChange()
        sent = true
    }

    private var buttonTitle: String {
        switch model.sendState {
        case .sending: return StudentSOSCopy.sending
        case .failed: return StudentSOSCopy.tryAgain
        case .offline, .waitingForConnection: return StudentSOSCopy.sendWhenOnline
        case .idle: return StudentSOSCopy.sendSOS
        }
    }
}

private struct StudentSOSProofCard: View {
    let model: StudentSOSViewModel
    let onRetake: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            if let at = model.photoAt {
                StudentSOSPreview(time: MLFormat.time(at, in: model.timeZone), model: model)
                    .frame(height: 150)
            } else {
                VStack(spacing: MLSpacing.s4) {
                    Image(systemName: "camera").accessibilityHidden(true)
                    Text(StudentSOSCopy.noPhoto).font(StudentType.secondary)
                }
                .foregroundStyle(MLColor.inkSecondary)
                .frame(maxWidth: .infinity, minHeight: 72)
                .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.fillQuiet))
                .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
                    .strokeBorder(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            }
            Text(model.subject)
                .font(StudentType.bodySemibold)
                .foregroundStyle(MLColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            if model.hasPhoto {
                Button(action: onRetake) {
                    Text(StudentSOSCopy.retake).font(StudentType.secondaryMedium).foregroundStyle(MLColor.ink).underline()
                        .frame(minHeight: MLSize.hit)
                }
                .buttonStyle(.plain)
                .disabled(model.isSending)
            } else {
                Text(StudentSOSCopy.cameraWasOff).font(StudentType.secondaryMedium).foregroundStyle(MLColor.danger)
            }
        }
        .padding(MLSpacing.s16)
        .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
    }
}

private struct StudentSOSChecks: View {
    let model: StudentSOSViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            if model.hasPhoto {
                check(ok: true, StudentSOSCopy.takenLive)
            } else {
                check(ok: false, StudentSOSCopy.noPhotoFlagged)
            }
            check(ok: model.location == .atMess,
                  model.location == .atMess ? StudentSOSCopy.atPlace(model.context.mess.name) : StudentSOSCopy.noGPSAsk)
            check(ok: true, StudentSOSCopy.timeRecorded(MLFormat.time(model.photoAt ?? model.now, in: model.timeZone)))
        }
        .padding(MLSpacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
    }

    private func check(ok: Bool, _ text: String) -> some View {
        HStack(spacing: MLSpacing.s12) {
            Image(systemName: ok ? "checkmark" : "exclamationmark.triangle")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ok ? MLColor.onLime : MLColor.danger)
                .frame(width: 28, height: 28)
                .background(Circle().fill(ok ? MLColor.lime : StudentTint.errorFill))
                .overlay(Circle().strokeBorder(ok ? MLColor.limeOutline : MLColor.danger, lineWidth: 1))
                .accessibilityHidden(true)
            Text(text).font(StudentType.body).foregroundStyle(MLColor.ink).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

/// SOS Sent (221:63509). The SOS is raised, so the page ends the flow: no Back, Done closes it.
struct StudentSOSSentView: View {
    let model: StudentSOSViewModel
    let onClose: () -> Void

    var body: some View {
        MLScreen(StudentSOSCopy.sosSent, subtitle: model.subject) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                if let sos = model.sos {
                    StudentSOSSentCard(sos: sos, hasPhoto: model.hasPhoto, timeZone: model.timeZone)
                    Text(StudentSOSCopy.feelingUnwell)
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
}

private struct StudentSOSSentCard: View {
    let sos: SOSCase
    let hasPhoto: Bool
    let timeZone: TimeZone

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            HStack(spacing: MLSpacing.s8) {
                Circle().fill(MLColor.lime).frame(width: 10, height: 10).accessibilityHidden(true)
                Text(ReportCopy.sent(MLFormat.time(sos.raisedAt, in: timeZone))).font(StudentType.secondaryMedium)
            }
            .foregroundStyle(MLColor.onHeroSecondary)
            Text(StudentSOSCopy.toldKitchen)
                .font(StudentType.heroTitle)
                .foregroundStyle(MLColor.onHero)
                .fixedSize(horizontal: false, vertical: true)
            Text(StudentSOSCopy.placeAndPhoto(sos.place, photo: hasPhoto))
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.onHeroSecondary)
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                HStack(spacing: MLSpacing.s12) {
                    Image(systemName: step.at != nil ? "checkmark.circle.fill" : "circle.dashed")
                        .font(StudentType.section)
                        .foregroundStyle(step.at != nil ? MLColor.lime : MLColor.onHeroSecondary)
                        .accessibilityHidden(true)
                    Text(step.title)
                        .font(step.at != nil ? StudentType.bodySemibold : StudentType.body)
                        .foregroundStyle(step.at != nil ? MLColor.onHero : MLColor.onHeroSecondary)
                    Spacer()
                    if let at = step.at {
                        Text(MealsFormat.clock(at, in: timeZone)).font(StudentType.mono).foregroundStyle(MLColor.onHeroSecondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            Text(StudentSOSCopy.messageWhenChecked).font(StudentType.secondary).foregroundStyle(MLColor.onHeroSecondary)
        }
        .padding(MLSpacing.s20)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.heroBackground))
    }

    /// Reported, Team told, Food held, Checked: a time only where the case has one; Food held has none recorded.
    private var steps: [(title: String, at: Date?)] {
        let times: [Date?] = [sos.raisedAt, sos.claim?.at, nil, sos.checks.first?.at]
        return zip(StudentSOSCopy.sosSteps, times).map { ($0, $1) }
    }
}

/// Chips that wrap onto as many lines as they need.
struct StudentChipFlow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(proposal.width ?? .infinity, subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(bounds.width, subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ width: CGFloat, _ subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row(indices: [index], width: size.width, height: size.height)
            } else {
                current = Row(indices: current.indices + [index], width: needed, height: max(current.height, size.height))
            }
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

/// Lets a pushed page switch the Student tab (Service › Community on Which dish 2159:285).
private struct StudentSelectTabKey: EnvironmentKey {
    static let defaultValue: ((StudentTab) -> Void)? = nil
}

extension EnvironmentValues {
    var studentSelectTab: ((StudentTab) -> Void)? {
        get { self[StudentSelectTabKey.self] }
        set { self[StudentSelectTabKey.self] = newValue }
    }
}
