import SwiftUI

/// A quiet row: title, optional trailing value, chevron, hairline below. At least 56 pt tall for staff.
struct QuietRow: View {
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
                        .font(MLType.monoBody)
                        .foregroundStyle(MLColor.ink)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MLColor.inkSecondary)
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

/// Status in lists: a small dot plus plain text, never a pill.
struct StatusText: View {
    enum Dot {
        case filled
        case empty
        /// Started but not finished (Draft on K16).
        case dashed
    }

    let text: String
    var dot: Dot = .filled
    /// Mono time after the text ("Recorded · 2:40 PM").
    var time: String?

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            Group {
                switch dot {
                case .filled:
                    Circle().fill(MLColor.lime).overlay(Circle().stroke(MLColor.limeOutline, lineWidth: 1))
                case .empty:
                    Circle().stroke(MLColor.ink, lineWidth: 1.5)
                case .dashed:
                    Circle().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1.5, dash: [2.5, 2.5]))
                }
            }
            .frame(width: 12, height: 12)
            Text(text)
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.ink)
            if let time {
                Text("· \(time)")
                    .font(MLType.monoBody)
                    .foregroundStyle(MLColor.ink)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// "● Meal in progress · 1 h 40 min": lime chip with the ink outline required on light surfaces.
struct MealProgressChip: View {
    let text: String

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            Circle().fill(MLColor.ink).frame(width: MLSize.statusDot, height: MLSize.statusDot)
            Text(text)
                .font(MLType.bodyEmphasis)
                .foregroundStyle(MLColor.onLime)
        }
        .padding(.horizontal, MLSpacing.s16)
        .frame(minHeight: 36)
        .background(Capsule().fill(MLColor.lime))
        .overlay(Capsule().stroke(MLColor.limeOutline, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

/// A white card row for a reported shortage: icon, "<Dish>, <level>", and its delivery line.
struct ShortageRow: View {
    let title: String
    let detail: String
    /// Mono part of the detail line (a time), if any.
    var detailTime: String?
    var retryTitle: String?
    var onRetry: (() -> Void)?
    /// The pot by default; K03e swaps it for a warning when a report couldn't be sent.
    var systemImage: String = "frying.pan"

    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            Image(systemName: systemImage)
                .font(.system(size: 17))
                .foregroundStyle(MLColor.ink)
                .frame(width: MLSize.iconSquare, height: MLSize.iconSquare)
                .background(Circle().fill(MLColor.fillQuiet))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                HStack(spacing: MLSpacing.s4) {
                    Text(detail)
                    if let detailTime {
                        Text(detailTime).font(MLType.monoBody)
                    }
                }
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            }
            Spacer(minLength: 0)
            if let retryTitle, let onRetry {
                CompactPillButton(title: retryTitle, action: onRetry)
            }
        }
        .padding(MLSpacing.s16)
        .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
        // Retry stays its own element, so a screen reader can reach it apart from the row.
        .accessibilityElement(children: onRetry == nil ? .combine : .contain)
    }
}
