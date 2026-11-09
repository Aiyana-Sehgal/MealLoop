import SwiftUI

/// Builds the view model from the environment.
struct StudentPassScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session
    var onOpenCrowd: (() -> Void)?
    let onBack: () -> Void

    var body: some View {
        if let model = StudentPassViewModel(session: session, repositories: environment.repositories, clock: environment.clock) {
            StudentPassView(model: model, onOpenCrowd: onOpenCrowd, onBack: onBack)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// The pass colours drawn on Pass · Live 1 to 3 (221:63212, 221:63219, 221:63226). The colour's name is always written
/// on the pill as well, so the colour is never the only signal.
enum PassColour {
    static func fill(_ name: String) -> Color {
        switch name.lowercased() {
        case "lime": return MLColor.lime
        case "blue": return Color(hex: 0x2446E0)
        case "orange": return Color(hex: 0xFF8A1F)
        default: return MLColor.fillQuiet
        }
    }

    static func text(_ name: String) -> Color {
        name.lowercased() == "blue" ? MLColor.onHero : MLColor.ink
    }

    /// Brand rule V2: lime on a light card is only ever ink-outlined.
    static func outlined(_ name: String) -> Bool { name.lowercased() == "lime" }
}

/// Special pass: Available (221:63168), Confirm (221:63180, 221:63196, 221:65276), Live 1 to 3 and Reduce Motion
/// (221:63212 to 221:63226, 221:65349), Used (221:63233) and the status frames (221:65293 to 221:65338).
struct StudentPassView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: StudentPassViewModel
    @State private var confirming = false
    @State private var hold = PassHoldTracker()
    /// Next week's pass request (StudentPassRequestViews.swift), shown when this week has no pass to use.
    @State private var request: StudentPassRequestModel?
    let onOpenCrowd: (() -> Void)?
    let onBack: () -> Void

    init(model: StudentPassViewModel, onOpenCrowd: (() -> Void)?, onBack: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onOpenCrowd = onOpenCrowd
        self.onBack = onBack
    }

    /// On `MLScreen`: the action is pinned above the tab bar, and the system back button and swipe-back pop the page.
    /// Hold-to-use is unchanged (owner decision, 9 November).
    var body: some View {
        MLScreen(MealsCopy.specialPass, subtitle: liveTicket.map(subtitle)) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                content
            }
        } bottom: {
            bottomButton
                .studentAboveTabBar()
        }
        .task(id: environment.dataRevision) {
            await model.load()
            if request == nil {
                request = StudentPassRequestModel(context: model.context, repositories: environment.repositories,
                                                  clock: environment.clock)
            }
            await request?.load()
        }
        .task(id: model.isLive) {
            guard model.isLive else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await model.tick()
            }
        }
        // Owner decision (9 November): the pass keeps hold-to-use, in a compact sheet (StudentPassUseFlow.swift).
        .mlSheet(isPresented: $confirming, isWorking: model.phase == .sending, onDismiss: { hold.reset() }) {
            PassHoldSheet(phase: model.phase, refusal: model.holdError, tracker: hold, onUse: {
                Task {
                    if await model.confirmHold() { confirming = false }
                }
            }, onCancel: { confirming = false })
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous)
                .fill(MLColor.track.opacity(0.8)).frame(height: 304)
        case .failed, .empty, .offline(nil, _):
            PassStatusCard(symbol: "wifi.slash", detail: MealsCopy.couldntLoadPass)
        case .loaded(let standing), .stale(let standing, _), .offline(let standing?, _):
            standingBody(standing)
        }
    }

    @ViewBuilder
    private func standingBody(_ standing: StudentPassStanding) -> some View {
        switch standing {
        case .available(let ticket):
            PassAvailableCard(ticket: ticket, timeZone: model.timeZone)
            PassHowItWorks(ticket: ticket, timeZone: model.timeZone)
            Text(MealsCopy.oneUse)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .frame(maxWidth: .infinity)
        case .live(let ticket, _):
            PassLiveTicket(ticket: ticket, code: model.liveCode, secondsLeft: model.secondsLeft, window: model.codeWindow,
                           reduceMotion: reduceMotion, usedAt: nil, timeZone: model.timeZone)
            PassFooter(title: MealsCopy.noScanNeeded, detail: MealsCopy.markedWhenYouComeIn)
        case .used(let ticket, _, _) where model.inUseSecondsLeft != nil:
            // Owner ruling (Prompt 2B): In use for the backend's validity, on the Live card the frames draw.
            PassLiveTicket(ticket: ticket, code: model.liveCode, secondsLeft: model.secondsLeft, window: model.codeWindow,
                           reduceMotion: reduceMotion, usedAt: nil, timeZone: model.timeZone)
            PassInUseLine(secondsLeft: model.inUseSecondsLeft ?? 0)
        case .used(let ticket, let at, true):
            PassLiveTicket(ticket: ticket, code: model.liveCode, secondsLeft: nil, window: nil, reduceMotion: reduceMotion,
                           usedAt: at, timeZone: model.timeZone)
            PassFooter(title: MealsCopy.thisPassIsUsed, detail: MealsCopy.markedUsedAt(MLFormat.time(at, in: model.timeZone)))
        case .used(_, let at, false):
            PassStatusCard(symbol: "checkmark.circle", detail: MealsCopy.alreadyUsed(MLFormat.time(at, in: model.timeZone)))
            requestSection
            nextRows
        case .expired(_, let endedAt):
            PassStatusCard(symbol: "clock", detail: MealsCopy.expired(MLFormat.time(endedAt, in: model.timeZone)))
            requestSection
            nextRows
        case .wrongMess(let passMess):
            PassStatusCard(symbol: "xmark", detail: MealsCopy.passIsFor(passMess), isWarning: true)
            nextRows
        case .notEligible:
            PassStatusCard(symbol: "minus", detail: MealsCopy.noPassThisWeek)
            requestSection
        }
    }

    @ViewBuilder
    private var requestSection: some View {
        if let request, request.isLoaded {
            StudentPassRequestSection(model: request)
        }
    }

    /// This week has no pass to use, so the page offers next week's request.
    private var showsRequest: Bool {
        switch model.state.value {
        case .used(_, _, false)?, .expired?, .notEligible?: return request?.isLoaded == true
        default: return false
        }
    }

    /// The ticket of the states whose frames draw the meal line under the title: Live, In use and Used.
    private var liveTicket: StudentPassTicket? {
        switch model.state.value {
        case .live(let ticket, _)?: return ticket
        case .used(let ticket, _, let mine)? where mine || model.inUseSecondsLeft != nil: return ticket
        default: return nil
        }
    }

    private func subtitle(_ ticket: StudentPassTicket) -> String {
        "\(MealsCopy.passWhen(StudentFormat.shortDay(ticket.meal.startsAt, in: model.timeZone), range: MLFormat.timeRange(ticket.meal.startsAt, ticket.meal.endsAt, in: model.timeZone))) · \(ticket.messName)"
    }

    @ViewBuilder
    private var nextRows: some View {
        if model.nextMeal != nil || model.crowd != nil {
            Text(MealsCopy.nextAtYourMess)
                .font(StudentType.eyebrow)
                .tracking(1.2)
                .foregroundStyle(MLColor.inkSecondary)
                .padding(.top, MLSpacing.s4)
        }
        if let next = model.nextMeal {
            PassNextMealRow(meal: next.meal, dishes: next.dishes, timeZone: model.timeZone)
        }
        if let crowd = model.crowd {
            PassCrowdRow(crowd: crowd, timeZone: model.timeZone, action: onOpenCrowd)
        }
    }

    @ViewBuilder
    private var bottomButton: some View {
        let failed: Bool = {
            switch model.state {
            case .failed, .empty, .offline(nil, _): return true
            default: return false
            }
        }()
        if failed {
            PassBottomButton(title: MealsCopy.tryAgain) { Task { await model.load() } }
        } else if case .available? = model.state.value {
            PassBottomButton(title: MealsCopy.usePass) {
                model.beginConfirm()
                confirming = true
            }
        } else if showsRequest, let request {
            switch request.request?.state {
            case .pending?:
                PassBottomButton(title: PassRequestCopy.cancelRequest, outlined: true) { Task { await request.cancel() } }
                    .disabled(request.isWriting)
            case .accepted?:
                EmptyView()
            case .declined?:
                PassBottomButton(title: PassRequestCopy.requestAgain) { Task { await request.ask() } }
                    .disabled(request.isWriting)
            case .cancelled?, nil:
                PassBottomButton(title: PassRequestCopy.request) { Task { await request.ask() } }
                    .disabled(request.isWriting)
            }
        }
    }
}

/// Words of the In use state (owner ruling, Prompt 2B). The seconds come from the backend.
enum PassUseCopy {
    static let inUse = "In use"
    static func validFor(_ seconds: Int) -> String { "Valid for \(seconds) s" }
}

/// The status line under the Live card while the pass is in use: a dot and "In use", then "Valid for N s".
struct PassInUseLine: View {
    let secondsLeft: Int

    var body: some View {
        VStack(spacing: 4) {
            StatusText(text: PassUseCopy.inUse)
            Text(PassUseCopy.validFor(secondsLeft))
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// The black pill above the tab bar: Use pass, Try again.
struct PassBottomButton: View {
    let title: String
    /// The outlined pill of "Cancel request" (student_pass_05_requested).
    var outlined = false
    let action: () -> Void

    var body: some View {
            Button(action: action) {
                Text(title)
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(outlined ? MLColor.ink : MLColor.onHero)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        if outlined {
                            Capsule().fill(MLColor.canvas).overlay(Capsule().strokeBorder(MLColor.ink, lineWidth: 1.5))
                        } else {
                            Capsule().fill(LinearGradient(colors: [MLColor.ink, Color(hex: 0x4A4A48)], startPoint: .top, endPoint: .bottom))
                        }
                    }
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
    }
}

/// Pass · Available: the black card with the lime edge.
struct PassAvailableCard: View {
    let ticket: StudentPassTicket
    let timeZone: TimeZone

    var body: some View {
        VStack(spacing: MLSpacing.s12) {
            PassTicketGlyph()
                .frame(width: 46, height: 30)
                .frame(width: 136, height: 136)
                .background(Circle().fill(MLColor.fillQuiet))
                .accessibilityHidden(true)
            StudentHeroChip(text: MealsCopy.available, style: .lime, showsCheck: true)
                .frame(height: 30)
            Text(MealsCopy.specialPass)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(MLColor.onHero)
            HStack(spacing: 6) {
                Image(systemName: "clock").font(.system(size: 13)).accessibilityHidden(true)
                Text("\(ticket.dishes.joined(separator: " · ")) · \(MealsCopy.passWhen(StudentFormat.shortDay(ticket.meal.startsAt, in: timeZone), range: MLFormat.timeRange(ticket.meal.startsAt, ticket.meal.endsAt, in: timeZone)))")
                    .font(StudentType.footnote)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(MLColor.onHeroSecondary)
        }
        .padding(.vertical, MLSpacing.s24)
        .padding(.horizontal, MLSpacing.s16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous).fill(MLColor.heroBackground))
        .overlay(RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous).strokeBorder(MLColor.lime, lineWidth: 2))
        .accessibilityElement(children: .combine)
    }
}

/// The ticket of Pass · Live and Pass · Used: code, colour, the perforation and the holder.
struct PassLiveTicket: View {
    let ticket: StudentPassTicket
    let code: LivePassCode?
    let secondsLeft: Int?
    let window: Int?
    let reduceMotion: Bool
    /// Set once the door recorded the entry: the ticket greys out.
    let usedAt: Date?
    let timeZone: TimeZone
    @State private var topHeight: CGFloat = 340

    private var isUsed: Bool { usedAt != nil }

    var body: some View {
        VStack(spacing: 0) {
            top
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { topHeight = $0 }
            DashedLine()
                .stroke(MLColor.border, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .padding(.horizontal, MLSpacing.s24)
                .frame(height: 16)
                .accessibilityHidden(true)
            bottom
        }
        .background(PassTicketShape(notchY: topHeight + 8).fill(MLColor.surface))
    }

    private var top: some View {
        VStack(spacing: MLSpacing.s8) {
            Text(isUsed ? MealsCopy.usedAtDoor : MealsCopy.showAtCounter)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .padding(.bottom, MLSpacing.s20)
            Text(MealsCopy.code)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
            Text(code?.code ?? "—")
                .font(.system(size: 76, weight: .bold, design: .monospaced))
                .foregroundStyle(isUsed ? MLColor.inkSecondary : MLColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(reduceMotion ? .identity : .numericText())
            Text(MealsCopy.colour)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
            colourPill
            Text(caption)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .padding(.top, 2)
        }
        .padding(.top, 44)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(code.map { MealsCopy.liveCodeLabel($0.code, colour: $0.colourName) + ". " + caption } ?? caption)
    }

    @ViewBuilder
    private var colourPill: some View {
        let name = code?.colourName ?? "—"
        Text(name)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(isUsed ? MLColor.inkSecondary : PassColour.text(name))
            .frame(width: 220, height: 56)
            .background(Capsule().fill(isUsed ? MLColor.fillQuiet : PassColour.fill(name)))
            .overlay { if !isUsed && PassColour.outlined(name) { Capsule().strokeBorder(MLColor.limeOutline, lineWidth: 1.5) } }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: name)
    }

    private var caption: String {
        if let usedAt { return MealsCopy.usedAt(MLFormat.time(usedAt, in: timeZone)) }
        if reduceMotion, let window { return MealsCopy.changesEvery(window) }
        return secondsLeft.map(MealsCopy.changesIn) ?? ""
    }

    private var bottom: some View {
        HStack(alignment: .center, spacing: MLSpacing.s12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(ticket.holderName) \(ticket.maskedID)")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(MLColor.ink)
                Text(ticket.dishes.joined(separator: " · "))
                    .font(StudentType.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Text(isUsed ? MealsCopy.used : MealsCopy.valid)
                .font(StudentType.secondaryMedium)
                .foregroundStyle(isUsed ? MLColor.inkSecondary : MLColor.onLime)
                .padding(.horizontal, MLSpacing.s16)
                .frame(height: 40)
                .background(Capsule().fill(isUsed ? MLColor.fillQuiet : MLColor.lime))
                .overlay { if !isUsed { Capsule().strokeBorder(MLColor.limeOutline, lineWidth: 1.5) } }
        }
        .padding(.horizontal, MLSpacing.s24)
        .padding(.top, 22)
        .padding(.bottom, 30)
        .accessibilityElement(children: .combine)
    }
}

/// The outline ticket in the circle of Pass · Available: notched sides and a dashed tear line, drawn thin as in the frame.
struct PassTicketGlyph: View {
    var body: some View {
        ZStack {
            PassGlyphOutline().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
            DashedLine()
                .stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1.8, dash: [3.5, 3]))
                .rotationEffect(.degrees(90))
                .frame(width: 22)
                .offset(x: 7)
        }
        .accessibilityHidden(true)
    }
}

private struct PassGlyphOutline: Shape {
    func path(in rect: CGRect) -> Path {
        let body = Path(roundedRect: rect, cornerRadius: 4, style: .continuous)
        let radius: CGFloat = 5
        var notches = Path()
        notches.addEllipse(in: CGRect(x: rect.minX - radius, y: rect.midY - radius, width: radius * 2, height: radius * 2))
        notches.addEllipse(in: CGRect(x: rect.maxX - radius, y: rect.midY - radius, width: radius * 2, height: radius * 2))
        return body.subtracting(notches)
    }
}

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// A rounded card with a half-circle notch on each side at `notchY`.
struct PassTicketShape: Shape {
    let notchY: CGFloat

    func path(in rect: CGRect) -> Path {
        let card = Path(roundedRect: rect, cornerRadius: 28, style: .continuous)
        let radius: CGFloat = 10
        var notches = Path()
        notches.addEllipse(in: CGRect(x: rect.minX - radius, y: rect.minY + notchY - radius, width: radius * 2, height: radius * 2))
        notches.addEllipse(in: CGRect(x: rect.maxX - radius, y: rect.minY + notchY - radius, width: radius * 2, height: radius * 2))
        return card.subtracting(notches)
    }
}

struct PassFooter: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(StudentType.bodySemibold)
                .foregroundStyle(MLColor.ink)
            Text(detail)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// The white card of the status frames: an icon tile, "Special pass" and one line.
struct PassStatusCard: View {
    let symbol: String
    let detail: String
    var isWarning = false

    var body: some View {
        HStack(spacing: MLSpacing.s16) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(isWarning ? MLColor.danger : MLColor.ink)
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isWarning ? StudentTint.errorFill : MLColor.fillQuiet))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(MealsCopy.specialPass)
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(MLColor.ink)
                Text(detail)
                    .font(StudentType.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, MLSpacing.s20)
        .padding(.vertical, MLSpacing.s16)
        .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }
}

/// "Dinner · 7:30–9:30 PM · 5 DISHES", which opens to the dish names.
struct PassNextMealRow: View {
    let meal: Meal
    let dishes: [Dish]
    let timeZone: TimeZone
    @State private var isOpen = false

    var body: some View {
        Button { isOpen.toggle() } label: {
            VStack(alignment: .leading, spacing: MLSpacing.s8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(MLFormat.mealSlot(meal.slot))
                            .font(StudentType.bodySemibold)
                            .foregroundStyle(MLColor.ink)
                        Text(([MLFormat.timeRange(meal.startsAt, meal.endsAt, in: timeZone)]
                              + (dishes.isEmpty ? [] : [MealsCopy.dishesCount(dishes.count)])).joined(separator: " · ").uppercased())
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .tracking(0.6)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MLColor.ink)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                        .accessibilityHidden(true)
                }
                if isOpen {
                    Text(dishes.map(\.name).joined(separator: " · "))
                        .font(StudentType.secondary)
                        .foregroundStyle(MLColor.ink)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, MLSpacing.s16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}

/// "Getting busy · Updated 12:08", which opens Crowd.
struct PassCrowdRow: View {
    let crowd: StudentCrowd
    let timeZone: TimeZone
    let action: (() -> Void)?

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: MLSpacing.s12) {
                Image(systemName: "rays")
                    .font(.system(size: 20))
                    .foregroundStyle(MLColor.ink)
                    .accessibilityHidden(true)
                Text(MealsCopy.crowdShort(crowd.level))
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(MLColor.ink)
                Spacer(minLength: 0)
                Text(MealsCopy.updated(MealsFormat.clock(crowd.observedAt, in: timeZone)))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(MLColor.inkSecondary)
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MLColor.ink)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, MLSpacing.s16)
            .frame(minHeight: 54)
            .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .accessibilityElement(children: .combine)
        .accessibilityHint(MealsCopy.estimateSpoken)
    }
}

/// Confirm (holding, sending, failed): hold the button down to use the pass.
struct PassConfirmSheet: View {
    let phase: PassConfirmPhase
    let onHold: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            Text(MealsCopy.useYourPass)
                .font(StudentType.section)
                .foregroundStyle(MLColor.ink)
                .accessibilityAddTraits(.isHeader)
            Text(MealsCopy.oneUse)
                .font(StudentType.body)
                .foregroundStyle(MLColor.ink)
            if phase == .failed {
                HStack(spacing: MLSpacing.s12) {
                    Image(systemName: "exclamationmark.triangle")
                        .accessibilityHidden(true)
                    Text(MealsCopy.couldntUse)
                        .font(StudentType.secondaryMedium)
                }
                .foregroundStyle(MLColor.danger)
                .padding(.horizontal, MLSpacing.s20)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(StudentTint.errorFill))
            }
            if phase == .sending {
                HStack(spacing: MLSpacing.s8) {
                    ProgressView().tint(MLColor.ink)
                    Text(MealsCopy.sending).font(StudentType.bodySemibold)
                }
                .foregroundStyle(MLColor.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Capsule().fill(MLColor.lime))
                .overlay(Capsule().strokeBorder(MLColor.limeOutline, lineWidth: 1.5))
                .accessibilityElement(children: .combine)
            } else {
                PassHoldButton(isFailed: phase == .failed, action: onHold)
            }
            Button(action: onCancel) {
                Text(MealsCopy.cancel)
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(MLColor.ink)
                    .padding(.horizontal, MLSpacing.s12)
                    .frame(height: MLSize.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // Not greyed while sending, as drawn; it only stops taking taps.
            .allowsHitTesting(phase != .sending)
        }
        // The frames draw the sheet from mid-screen down; the shared sheet fits its content.
        .frame(maxWidth: .infinity, minHeight: 330, alignment: .topLeading)
    }
}

/// "Hold to use": lime fills the button while it is held. VoiceOver and Switch Control use it with one activation.
struct PassHoldButton: View {
    let isFailed: Bool
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    static let holdSeconds = 1.2

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            Image(systemName: "hand.raised").accessibilityHidden(true)
            Text(MealsCopy.holdToUse)
        }
        .font(StudentType.bodySemibold)
        .foregroundStyle(MLColor.ink)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(MLColor.surface)
                    Rectangle().fill(MLColor.lime).frame(width: geometry.size.width * progress)
                }
                .clipShape(Capsule())
            }
        }
        .overlay(Capsule().strokeBorder(isFailed ? MLColor.danger : MLColor.ink, lineWidth: 1.5))
        .contentShape(Capsule())
        .onLongPressGesture(minimumDuration: Self.holdSeconds, perform: {
            progress = 1
            action()
        }, onPressingChanged: { pressing in
            withAnimation(pressing ? .linear(duration: Self.holdSeconds) : (reduceMotion ? nil : .easeOut(duration: 0.2))) {
                progress = pressing ? 1 : 0
            }
        })
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { action() }
    }
}
