import SwiftUI

/// Status on a black card (04, D13, S05). It reports, it does not act: it has no button trait, and it hugs its text
/// so it never reads as a full-width button. On a light surface use `StatusText` or `MealProgressChip`.
struct HeroStatusChip: View {
    enum Style {
        /// Lime fill and ink text: done, or yours.
        case lime
        /// Thin outline: a settled state that needs nothing ("Skipped").
        case outline
        /// Dashed outline: nothing yet ("Not answered").
        case dashed
    }

    let text: String
    /// Mono time after the text ("12:52 PM").
    var time: String?
    var style: Style = .outline
    /// Shows a small tick before the text (the "I'm in" chip on 04).
    var showsCheck: Bool = false

    private let verticalPadding: CGFloat = 6

    var body: some View {
        HStack(spacing: MLSpacing.s4) {
            if showsCheck {
                Image(systemName: "checkmark")
                    .font(MLType.meta)
            }
            Text(text).font(MLType.bodyEmphasis)
            if let time {
                Text("· \(time)").font(MLType.monoSecondary)
            }
        }
        .foregroundStyle(style == .lime ? MLColor.onLime : MLColor.onHero)
        .padding(.horizontal, MLSpacing.s12)
        .padding(.vertical, verticalPadding)
        .background {
            switch style {
            case .lime:
                Capsule().fill(MLColor.lime)
            case .outline:
                Capsule().stroke(MLColor.onHeroSecondary, lineWidth: 1)
            case .dashed:
                Capsule().stroke(MLColor.onHeroSecondary, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(time.map { "\(text), \($0)" } ?? text)
    }
}
