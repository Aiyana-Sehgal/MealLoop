import SwiftUI

/// What the bottom of the answer page shows.
enum StudentAnswerPhase: Equatable {
    case open
    case saving(MealIntention)
    case failed(MealIntention)
    case saved(MealIntention)
    case notSure
    case locked(MealIntention?)
}

/// The answer page (Answer · frames, page 07): the meal's dishes above, the answer below.
struct StudentAnswerView: View {
    let model: StudentHomeViewModel
    let mealID: MealID
    let onShowEntry: () -> Void
    let onBack: () -> Void

    @State private var isChanging = false
    @State private var isSkipping = false

    private var card: StudentMealCard? { model.card(id: mealID) }

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    if let card {
                        StudentNavHeader(title: MLFormat.mealSlot(card.meal.slot), subtitle: subtitle(card), onBack: onBack)
                        VStack(alignment: .leading, spacing: MLSpacing.s16) {
                            dishes
                            if model.isOffline {
                                StudentOfflineBanner(text: StudentCopy.answerWaiting)
                            } else {
                                Color.clear.frame(height: MLSpacing.s4)
                            }
                            answer(card)
                        }
                        .padding(.top, MLSpacing.s8)
                    } else {
                        BackButton(action: onBack).padding(.leading, -MLSpacing.s4)
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s4)
                .padding(.bottom, StudentMetric.scrollBottom)
            }
            StudentScrollFade()
        }
        .task(id: mealID) { await model.loadAnswerMenu(for: mealID) }
        .mlSheet(isPresented: $isSkipping) {
            if let card {
                WhySkippingSheet(slot: card.meal.slot, onClose: { isSkipping = false }) { reason in
                    isSkipping = false
                    send(.skipping, reason: reason)
                }
            }
        }
    }

    private func phase(_ card: StudentMealCard) -> StudentAnswerPhase {
        if let failed = model.failedAnswer, model.failedMeal == card.id { return .failed(failed) }
        switch model.answerState(for: card) {
        case .saving(let intention): return .saving(intention)
        case .locked(let answer): return .locked(answer)
        case .answered(let answer) where !isChanging:
            return answer == .notSure ? .notSure : .saved(answer)
        case .answered, .unanswered: return .open
        }
    }

    private func send(_ intention: MealIntention, reason: MealSkipReason? = nil) {
        isChanging = false
        Task { await model.answer(intention, for: mealID, reason: reason) }
    }

    private func choose(_ intention: MealIntention) {
        if intention == .skipping {
            isSkipping = true
        } else {
            send(intention)
        }
    }

    private func time(_ date: Date) -> String { StudentFormat.shortTime(date, in: model.timeZone) }

    private func subtitle(_ card: StudentMealCard) -> String {
        let range = MLFormat.timeRange(card.meal.startsAt, card.meal.endsAt, in: model.timeZone)
        guard card.isAnswerOpen else { return StudentCopy.answerClosedSubtitle(range) }
        return StudentCopy.answerBy(range, time: time(card.cutoff),
                                    left: MLFormat.elapsed(minutes: MLFormat.minutes(from: model.now, to: card.cutoff)))
    }

    @ViewBuilder
    private var dishes: some View {
        if let menu = model.menu.value {
            StudentDishGrid(menu: menu)
        } else {
            AsyncContentView(state: model.menu, emptyTitle: StudentCopy.menuUnavailable, timeZone: model.timeZone,
                             retry: { await model.loadAnswerMenu(for: mealID) }) { menu in
                StudentDishGrid(menu: menu)
            }
        }
    }

    @ViewBuilder
    private func answer(_ card: StudentMealCard) -> some View {
        let slot = card.meal.slot
        let cutoff = time(card.cutoff)
        switch phase(card) {
        case .open:
            AnswerButtons(saving: nil, onChoose: choose)
            footer(StudentCopy.answerFooter)
        case .saving(let intention):
            AnswerButtons(saving: intention, onChoose: choose)
            footer(StudentCopy.answerFooter)
        case .failed:
            AnswerErrorCard()
            AnswerButtons(saving: nil, primaryTitle: StudentCopy.tryAgain,
                          onPrimary: { Task { await model.retryFailedAnswer() } }, onChoose: choose)
            footer(StudentCopy.answerFooter)
        case .saved(let answer):
            AnswerStatusCard(title: answer == .attending ? StudentCopy.youreIn(slot) : StudentCopy.youreSkipping(slot),
                             detail: savedDetail(card, answer: answer, cutoff: cutoff))
            AnswerInkButton(title: StudentCopy.showEntryQR, action: onShowEntry)
            AnswerOutlineButton(title: StudentCopy.changeAnswer, height: StudentMetric.answerSecondary) { isChanging = true }
        case .notSure:
            AnswerStatusCard(title: StudentCopy.markedNotSure, detail: StudentCopy.decideByTime(cutoff))
            HStack(spacing: MLSpacing.s12) {
                AnswerInkButton(title: StudentCopy.imIn, height: StudentMetric.answerSecondary) { send(.attending) }
                AnswerOutlineButton(title: StudentCopy.skip, height: StudentMetric.answerSecondary) { isSkipping = true }
            }
            footer(StudentCopy.qrAlwaysWorks)
        case .locked(let answer):
            AnswerStatusCard(title: lockedTitle(answer, slot: slot), detail: StudentCopy.answersClosed(cutoff))
            HStack(spacing: MLSpacing.s8) {
                ForEach([StudentCopy.imIn, StudentCopy.skip, StudentCopy.notSure], id: \.self) { title in
                    Text(title)
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(MLColor.inkSecondary)
                        .frame(maxWidth: .infinity, minHeight: StudentMetric.answerSecondary)
                        .background(Capsule().strokeBorder(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                }
            }
            .accessibilityHidden(true)
            AnswerInkButton(title: StudentCopy.showEntryQR, height: 60, action: onShowEntry)
        }
    }

    private func savedDetail(_ card: StudentMealCard, answer: MealIntention, cutoff: String) -> String {
        if answer == .skipping {
            return model.skipReasons[card.id].map { StudentCopy.reasonChangeUntil(StudentCopy.reason($0), until: cutoff) }
                ?? StudentCopy.changeUntil(cutoff)
        }
        return card.answeredAt.map { StudentCopy.savedChangeUntil(time($0), until: cutoff) } ?? StudentCopy.changeUntil(cutoff)
    }

    private func lockedTitle(_ answer: MealIntention?, slot: MealSlot) -> String {
        switch answer {
        case .attending?: return StudentCopy.youreIn(slot)
        case .skipping?: return StudentCopy.youreSkipping(slot)
        case .notSure?: return StudentCopy.markedNotSure
        case nil: return StudentCopy.youDidntAnswer
        }
    }

    private func footer(_ text: String) -> some View {
        Text(text)
            .font(StudentType.footnote)
            .foregroundStyle(MLColor.inkSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

private struct AnswerInkButton: View {
    let title: String
    var height: CGFloat = 60
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(StudentType.bodySemibold)
                .foregroundStyle(MLColor.onHero)
                .frame(maxWidth: .infinity, minHeight: height)
                .background(Capsule().fill(MLColor.ink))
        }
        .buttonStyle(.plain)
    }
}

private struct AnswerOutlineButton: View {
    let title: String
    let height: CGFloat
    var isDimmed = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(StudentType.bodySemibold)
                .foregroundStyle(isDimmed ? MLColor.inkSecondary.opacity(0.6) : MLColor.ink)
                .frame(maxWidth: .infinity, minHeight: height)
                .background(Capsule().fill(MLColor.surface.opacity(isDimmed ? 0.4 : 1)))
                .overlay(Capsule().strokeBorder(isDimmed ? MLColor.border : MLColor.ink, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

/// I'm in on top, Skip and Not sure below (Answer · Lunch). While a write runs, the tapped one says Saving… and the
/// others are dimmed and ignore taps, so an answer can't be sent twice.
private struct AnswerButtons: View {
    let saving: MealIntention?
    var primaryTitle = StudentCopy.imIn
    var onPrimary: (() -> Void)?
    let onChoose: (MealIntention) -> Void

    var body: some View {
        VStack(spacing: MLSpacing.s16) {
            Button { (onPrimary ?? { onChoose(.attending) })() } label: {
                Text(saving == nil ? primaryTitle : StudentCopy.saving)
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(MLColor.onHero)
                    .frame(maxWidth: .infinity, minHeight: StudentMetric.answerPrimary)
                    .background(Capsule().fill(MLColor.ink))
            }
            .buttonStyle(.plain)
            HStack(spacing: MLSpacing.s12) {
                AnswerOutlineButton(title: StudentCopy.skip, height: StudentMetric.answerSecondary, isDimmed: saving != nil) { onChoose(.skipping) }
                AnswerOutlineButton(title: StudentCopy.notSure, height: StudentMetric.answerSecondary, isDimmed: saving != nil) { onChoose(.notSure) }
            }
        }
        // Not `.disabled`, which would grey the black button the frame keeps solid.
        .allowsHitTesting(saving == nil)
    }
}

/// "You're in for lunch" with one line under it (Answer · Lunch · I'm in).
private struct AnswerStatusCard: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(title)
                .font(StudentType.bodySemibold)
                .foregroundStyle(MLColor.ink)
            Text(detail)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, MLSpacing.s20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
        .overlay(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).strokeBorder(MLColor.border, lineWidth: 1))
    }
}

/// Answer · Lunch · Failed.
private struct AnswerErrorCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: MLSpacing.s12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 17))
                .foregroundStyle(MLColor.danger)
                .accessibilityHidden(true)
            Text(StudentCopy.couldntSave)
                .font(StudentType.bodySemibold)
                .foregroundStyle(MLColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, MLSpacing.s16)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(StudentTint.errorFill))
        .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
        .overlay(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).strokeBorder(MLColor.danger, lineWidth: 1))
    }
}

/// Why skipping? (221:62700). The reason is optional, and Skip works without one.
struct WhySkippingSheet: View {
    let slot: MealSlot
    let onClose: () -> Void
    let onSkip: (MealSkipReason?) -> Void

    @State private var reason: MealSkipReason?

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: StudentCopy.whySkipping, subtitle: StudentCopy.whySkippingDetail, onClose: onClose)
            StudentFlowLayout(spacing: MLSpacing.s8) {
                ForEach(MealSkipReason.allCases, id: \.self) { option in
                    Button { reason = reason == option ? nil : option } label: {
                        Text(StudentCopy.reason(option))
                            .font(StudentType.secondaryMedium)
                            .foregroundStyle(reason == option ? MLColor.onHero : MLColor.ink)
                            .padding(.horizontal, MLSpacing.s16)
                            .frame(height: MLSize.hit)
                            .background(Capsule().fill(reason == option ? MLColor.ink : Color.clear))
                            .overlay(Capsule().strokeBorder(MLColor.ink, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(reason == option ? .isSelected : [])
                }
            }
            AnswerInkButton(title: StudentCopy.skipMeal(slot)) { onSkip(reason) }
                .padding(.top, MLSpacing.s4)
            Button { onSkip(nil) } label: {
                Text(StudentCopy.skipNoReason)
                    .font(StudentType.secondaryMedium)
                    .underline()
                    .foregroundStyle(MLColor.ink)
                    .frame(minHeight: MLSize.hit)
            }
            .buttonStyle(.plain)
        }
    }
}

/// Wraps its children onto new lines, as the reason chips do.
struct StudentFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(in: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(in: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.items {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var items: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(in width: CGFloat, subviews: Subviews) -> [Row] {
        var rows = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].items.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > width, !rows[rows.count - 1].items.isEmpty {
                rows.append(Row(items: [index], width: size.width, height: size.height))
            } else {
                rows[rows.count - 1].items.append(index)
                rows[rows.count - 1].width = needed
                rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
            }
        }
        return rows
    }
}
