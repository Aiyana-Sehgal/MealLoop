import SwiftUI

/// A small action inside a row ("Retry" K03e, "Review" and "Live" A01, the dashed "Enter kg" K06).
/// The capsule is 44 pt tall, so the whole visible shape is the target.
struct CompactPillButton: View {
    enum Style {
        case outline
        /// Nothing entered yet: a missing value, never a zero.
        case dashed
        /// The lime chip with its ink outline. Use it for at most one row kind per screen.
        case lime
    }

    let title: String
    var style: Style = .outline
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MLType.bodyEmphasis)
                .foregroundStyle(style == .lime ? MLColor.onLime : MLColor.ink)
                .padding(.horizontal, MLSpacing.s16)
                .frame(minWidth: MLSize.hit, minHeight: MLSize.hit)
                .background { background }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .outline:
            Capsule().stroke(MLColor.ink, lineWidth: 1.5)
        case .dashed:
            Capsule().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        case .lime:
            Capsule().fill(MLColor.lime).overlay(Capsule().stroke(MLColor.limeOutline, lineWidth: 1))
        }
    }
}

/// The quiet underlined action ("Report a problem" D10, "I can't go after all" D14, "Add a dish" K06).
struct TextLinkButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MLType.body)
                .underline()
                .foregroundStyle(MLColor.ink)
                .frame(minHeight: MLSize.hit)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// One choice in a set of pills (dishes on K04 and P12, reasons on G08). Black when selected.
struct ChoiceChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MLType.staffBody)
                .foregroundStyle(isSelected ? MLColor.onHero : MLColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, MLSpacing.s12)
                .frame(maxWidth: .infinity, minHeight: MLSize.staffButton)
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
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// The quiet track with one black segment ("How bad?" K04, the Results tabs A07).
struct SegmentedChoice<Value: Hashable>: View {
    struct Option: Identifiable {
        let value: Value
        let title: String

        var id: Value { value }
    }

    let options: [Option]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                segment(option)
            }
        }
        .padding(MLSpacing.s4)
        .background(Capsule().fill(MLColor.track))
    }

    private func segment(_ option: Option) -> some View {
        let isSelected = option.value == selection
        return Button {
            selection = option.value
        } label: {
            Text(option.title)
                .font(isSelected ? MLType.bodyEmphasis : MLType.body)
                .foregroundStyle(isSelected ? MLColor.onHero : MLColor.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, minHeight: MLSize.hit)
                .background {
                    if isSelected {
                        Capsule().fill(MLColor.ink)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
