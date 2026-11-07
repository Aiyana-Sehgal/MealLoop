import SwiftUI

// Pieces the Figma staff frames draw that the shared components cannot, kept local (REPORT.md lists each).
// Door Scanner, Pass Desk and Supervisor use them. Each takes ready values and decides nothing.

/// Status on a light surface, drawn as a pill where a frame draws one (DS-6, PD-2, PD-4, PD-6).
struct StaffStatusPill: View {
    enum Style {
        /// Dashed outline: nothing has happened yet (Waiting, No pass).
        case dashed
        /// Ink outline: a settled state (Seen, Approved, Rejected, Used, Wrong meal).
        case outline
        /// Lime with the ink outline: done (Done, Valid).
        case lime
    }

    let text: String
    let style: Style

    var body: some View {
        Text(text)
            .font(MLType.body.weight(.medium))
            .foregroundStyle(MLColor.ink)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, MLSpacing.s16)
            .frame(minHeight: 36)
            .background {
                switch style {
                case .dashed:
                    Capsule().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                case .outline:
                    Capsule().stroke(MLColor.ink, lineWidth: 1.5)
                case .lime:
                    Capsule().fill(MLColor.lime).overlay(Capsule().stroke(MLColor.limeOutline, lineWidth: 1.5))
                }
            }
            .accessibilityLabel(text)
    }
}

/// A result that did not record, with its actions pinned to the bottom, outline above ink (DS-3, PD-3).
/// `OutcomeScreen` flows them under the content and is shared, so this keeps its parts and moves the actions.
struct StaffOutcomeScreen: View {
    /// One bullet of the "It may be" card (DS-3 QR not recognised).
    struct Reason: Identifiable {
        let title: String
        let detail: String

        var id: String { title }
    }

    var onBack: (() -> Void)?
    var badge: OutcomeScreen.Badge = .quiet
    let symbol: String
    let title: String
    let message: String
    var isMessageEmphasized: Bool = false
    var facts: [FactRow] = []
    var reasonsTitle: String?
    var reasons: [Reason] = []
    var note: String?
    let primary: OutcomeScreen.Action
    var secondary: OutcomeScreen.Action?
    var link: OutcomeScreen.Action?
    var footnote: String?

    private let badgeDiameter: CGFloat = 120

    var body: some View {
        ZStack(alignment: .topLeading) {
            OrbitBackground()
            ScrollView {
                VStack(spacing: MLSpacing.s16) {
                    badgeView
                    VStack(spacing: MLSpacing.s8) {
                        Text(title)
                            .font(MLType.largeTitle)
                            .foregroundStyle(MLColor.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text(message)
                            .font(MLType.staffBody)
                            .foregroundStyle(isMessageEmphasized ? MLColor.ink : MLColor.inkSecondary)
                    }
                    .multilineTextAlignment(.center)
                    if !facts.isEmpty {
                        FactCard(rows: facts)
                    }
                    if !reasons.isEmpty {
                        reasonsCard
                    }
                    if let note {
                        grey(note)
                    }
                    if let link {
                        TextLinkButton(title: link.title, action: link.handler)
                            .padding(.top, MLSpacing.s8)
                    }
                    if let footnote {
                        grey(footnote)
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, onBack == nil ? 0 : MLSize.hit + MLSpacing.s8)
                .padding(.bottom, MLSpacing.s16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: MLSpacing.s12) {
                    if let secondary {
                        OutlineActionButton(title: secondary.title, action: secondary.handler)
                    }
                    InkActionButton(title: primary.title, action: primary.handler)
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.vertical, MLSpacing.s12)
            }
            if let onBack {
                BackButton(action: onBack)
                    .padding(.leading, MLSpacing.s16)
            }
        }
    }

    private func grey(_ text: String) -> some View {
        Text(text)
            .font(MLType.body)
            .foregroundStyle(MLColor.inkSecondary)
            .multilineTextAlignment(.center)
    }

    private var badgeView: some View {
        Image(systemName: symbol)
            .font(.system(size: 44, weight: .regular))
            .foregroundStyle(MLColor.ink)
            .frame(width: badgeDiameter, height: badgeDiameter)
            .background(Circle().fill(badge == .quiet ? MLColor.track : MLColor.surface))
            .overlay {
                if badge == .outlined {
                    Circle().stroke(MLColor.ink, lineWidth: 1.5)
                }
            }
            .accessibilityHidden(true)
    }

    private var reasonsCard: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            if let reasonsTitle {
                Text(reasonsTitle)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            ForEach(reasons) { reason in
                HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s12) {
                    Circle().fill(MLColor.ink).frame(width: MLSize.statusDot, height: MLSize.statusDot)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reason.title)
                            .font(MLType.staffBody)
                            .foregroundStyle(MLColor.ink)
                        Text(reason.detail)
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
    }
}

/// The large report option (DS-5, PD-5): 64 pt icon, 22 pt title. The shared `IconCardRow` is the smaller Home row.
struct StaffReportRow: View {
    let symbol: String
    let title: String
    let detail: String
    /// Lime icon: the one report that really goes somewhere (PD-5 Food running short).
    var isHighlighted: Bool = false
    let action: () -> Void

    private let iconDiameter: CGFloat = 64

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s16) {
                Image(systemName: symbol)
                    .font(.system(size: 22))
                    .foregroundStyle(MLColor.ink)
                    .frame(width: iconDiameter, height: iconDiameter)
                    .background(Circle().fill(isHighlighted ? MLColor.lime : MLColor.fillQuiet))
                    .overlay {
                        if isHighlighted {
                            Circle().stroke(MLColor.limeOutline, lineWidth: 1.5)
                        }
                    }
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: MLSpacing.s4) {
                    Text(title)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(MLColor.ink)
                    Text(detail)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MLColor.inkSecondary)
                    .accessibilityHidden(true)
            }
            .padding(MLSpacing.s20)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
            .contentShape(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// The Home option on the desk (PD-1): the frame keeps its detail on one line, which the shared row's 15 pt cannot.
struct StaffHomeRow: View {
    let symbol: String
    let title: String
    var detail: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s12) {
                Image(systemName: symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(MLColor.ink)
                    .frame(width: MLSize.hit, height: MLSize.hit)
                    .background(Circle().fill(MLColor.fillQuiet))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.ink)
                    if let detail {
                        Text(detail)
                            .font(MLType.secondary.leading(.tight))
                            .foregroundStyle(MLColor.inkSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MLColor.inkSecondary)
                    .accessibilityHidden(true)
            }
            .padding(MLSpacing.s16)
            .frame(minHeight: 76)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
            .contentShape(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// The white outlined boxes on Look up and Request (PD-2, PD-4). The shared `DigitBoxes` draws quiet ones.
struct StaffDigitBoxes: View {
    let entry: DigitEntry
    let accessibilityTitle: String

    private let boxHeight: CGFloat = 72

    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            ForEach(0..<entry.length, id: \.self) { index in
                let isFilled = index < entry.digits.count
                let shape = RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
                Text(isFilled ? String(entry.digits[index]) : " ")
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundStyle(MLColor.ink)
                    .frame(maxWidth: .infinity, minHeight: boxHeight)
                    .background(shape.fill(MLColor.surface))
                    .overlay(shape.stroke(isFilled ? MLColor.ink : MLColor.border, lineWidth: 1.5))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue(entry.spokenValue)
    }
}

/// Chips that hug their text and wrap (PD-4 Why). The shared `ChoiceChip` fills its cell.
struct StaffChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MLType.staffBody)
                .foregroundStyle(isSelected ? MLColor.onHero : MLColor.ink)
                .padding(.horizontal, MLSpacing.s20)
                .frame(minHeight: 46)
                .background {
                    if isSelected {
                        Capsule().fill(MLColor.ink)
                    } else {
                        Capsule().stroke(MLColor.ink, lineWidth: 1.5)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Lays children left to right and wraps at the edge.
struct StaffWrapLayout: Layout {
    var spacing: CGFloat = MLSpacing.s12

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(in: proposal.width ?? .infinity, subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(in: bounds.width, subviews) {
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

    private func rows(in width: CGFloat, _ subviews: Subviews) -> [Row] {
        var rows = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let isFirst = rows[rows.count - 1].indices.isEmpty
            rows[rows.count - 1].indices.append(index)
            rows[rows.count - 1].width += size.width + (isFirst ? 0 : spacing)
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
        }
        return rows
    }
}

/// The top of Me on the door and the desk (DS-8, PD-8).
struct StaffMeProfile: View {
    let initials: String
    let title: String
    let detail: String
    let chip: String

    private let avatarSize: CGFloat = 92

    var body: some View {
        HStack(spacing: MLSpacing.s16) {
            Text(initials)
                .font(MLType.heroTitle)
                .foregroundStyle(MLColor.lime)
                .frame(width: avatarSize, height: avatarSize)
                .background(Circle().fill(MLColor.ink))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MLSpacing.s8) {
                Text(title)
                    .font(MLType.heroTitle)
                    .foregroundStyle(MLColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(detail)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                MealProgressChip(text: chip)
            }
        }
        .padding(.bottom, MLSpacing.s12)
    }
}

/// A count tile on Me. A missing count shows "—", never 0.
struct StaffMeTile: View {
    let label: String
    let value: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(label)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(value.map(String.init) ?? "—")
                .font(MLType.heroTitle.monospaced())
                .foregroundStyle(MLColor.ink)
        }
        .padding(MLSpacing.s16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }
}

/// A Me row with a quiet word on the right ("English"). `QuietRow` draws values in mono, for numbers.
struct StaffMeRow: View {
    let title: String
    var value: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s12) {
                Text(title)
                    .font(MLType.staffBody)
                    .foregroundStyle(MLColor.ink)
                Spacer(minLength: MLSpacing.s8)
                if let value {
                    Text(value)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MLColor.inkSecondary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: MLSize.staffButton)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
    }
}

/// "● Meal ended" on a black card, in sentence case as DS-1 and PD-1 draw it. `HeroEyebrow` uppercases.
struct StaffHeroLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            Circle().fill(MLColor.lime).frame(width: MLSize.statusDot, height: MLSize.statusDot)
            Text(text)
                .font(MLType.bodyEmphasis)
                .foregroundStyle(MLColor.onHeroSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// Pins one action above the bottom edge or the tab bar, as the frames draw it.
    func staffPinnedFooter<Footer: View>(bottomInset: CGFloat = MLSpacing.s12, @ViewBuilder footer: () -> Footer) -> some View {
        safeAreaInset(edge: .bottom) {
            footer()
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, bottomInset)
        }
    }
}
