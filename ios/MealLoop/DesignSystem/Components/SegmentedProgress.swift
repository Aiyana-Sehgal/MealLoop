import SwiftUI

/// The row of short bars that shows how far something has got (the mess tiles on A01, Reported to Fixed on 10).
struct SegmentedProgress: View {
    enum Surface {
        case light
        /// On a black card the filled bars are lime (brand rule V2).
        case hero
    }

    /// `current` counts the filled bars. Nil means there is no data: every bar is dashed, which is not the same as 0.
    let current: Int?
    let total: Int
    var surface: Surface = .light
    /// One word per step, drawn under its bar. The current one is bold.
    var labels: [String] = []
    /// Said when `current` is nil.
    var missingText: String = "No data"

    private let barHeight: CGFloat = 6

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            HStack(spacing: MLSpacing.s8) {
                ForEach(0..<total, id: \.self) { index in
                    bar(index)
                }
            }
            if !labels.isEmpty {
                HStack(spacing: MLSpacing.s8) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(index + 1 == current ? MLType.bodyEmphasis : MLType.secondary)
                            .foregroundStyle(labelColor(isCurrent: index + 1 == current))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.spokenText(current: current, total: total, labels: labels, missingText: missingText))
    }

    /// The progress in words, because the bars alone say nothing to a screen reader.
    static func spokenText(current: Int?, total: Int, labels: [String], missingText: String) -> String {
        guard let current else { return missingText }
        let step = "Step \(current) of \(total)"
        guard current >= 1, current <= labels.count else { return step }
        return "\(step), \(labels[current - 1])"
    }

    @ViewBuilder
    private func bar(_ index: Int) -> some View {
        let shape = Capsule()
        Group {
            if current == nil {
                shape.stroke(surface == .hero ? MLColor.onHeroSecondary : MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            } else if index < (current ?? 0) {
                shape.fill(surface == .hero ? MLColor.lime : MLColor.ink)
            } else {
                shape.fill(trackColor)
            }
        }
        .frame(height: barHeight)
    }

    private var trackColor: Color {
        surface == .hero ? MLColor.onHero.opacity(0.2) : MLColor.track
    }

    private func labelColor(isCurrent: Bool) -> Color {
        switch surface {
        case .hero:
            return isCurrent ? MLColor.onHero : MLColor.onHeroSecondary
        case .light:
            return isCurrent ? MLColor.ink : MLColor.inkSecondary
        }
    }
}
