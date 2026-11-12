import SwiftUI

/// The four tile looks of the Admin bento layout (design/reference/admin_full_2026-11, DESIGN_SPEC "Tile kinds").
enum BentoKind: Equatable {
    /// Black: the one thing that needs action, or the screen's headline figure.
    case hero
    /// Lime, black text: an action tile with a black button.
    case action
    /// White: a figure that needs nothing right now.
    case standard
    /// Dashed outline: only for data that is genuinely not available. Never used for decoration.
    case dashed

    var foreground: Color {
        self == .hero ? MLColor.onHero : MLColor.ink
    }

    var secondary: Color {
        switch self {
        case .hero: return MLColor.onHeroSecondary
        case .action: return MLColor.onLime
        case .standard, .dashed: return MLColor.inkSecondary
        }
    }
}

/// A bento tile: one job each (a label, one big mono number, one caption, at most one action).
struct BentoTile<Content: View>: View {
    let kind: BentoKind
    var minHeight: CGFloat?
    /// Fills the height it is offered, so two tiles in a row share one height (the SA02 and AD03 pairs).
    var fillsHeight = false
    @ViewBuilder let content: Content

    init(kind: BentoKind, minHeight: CGFloat? = nil, fillsHeight: Bool = false, @ViewBuilder content: () -> Content) {
        self.kind = kind
        self.minHeight = minHeight
        self.fillsHeight = fillsHeight
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            content
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: fillsHeight ? .infinity : nil, alignment: .topLeading)
        .background { background }
        .contentShape(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous))
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous)
        switch kind {
        case .hero: shape.fill(MLColor.heroBackground)
        case .action: shape.fill(MLColor.lime)
        case .standard: shape.fill(MLColor.surface)
        case .dashed: shape.stroke(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
        }
    }
}

/// The tile's label, in the body face at 17 pt, secondary.
struct BentoLabel: View {
    let text: String
    let kind: BentoKind

    var body: some View {
        Text(text)
            .font(MLType.staffBody)
            .foregroundStyle(kind == .hero ? MLColor.onHero : kind.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// The tile's one big number, in mono. A missing value (nil) is a dash in the secondary colour, never a zero.
struct BentoNumber: View {
    /// Already formatted ("2,870"). Nil draws the dash.
    let text: String?
    let kind: BentoKind
    let font: Font
    /// What VoiceOver reads: the figure's name and value, or that it is not available.
    let spoken: String

    var body: some View {
        Text(text ?? "—")
            .font(font)
            .foregroundStyle(text == nil ? MLColor.inkSecondary : kind.foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .accessibilityLabel(spoken)
    }
}

/// The tile's caption, 15 pt.
struct BentoCaption: View {
    let text: String
    let kind: BentoKind

    var body: some View {
        Text(text)
            .mlFont(.secondary)
            .foregroundStyle(kind.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
