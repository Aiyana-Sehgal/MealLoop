import SwiftUI

/// A hairline row on the canvas (no container): a title, a subtitle and one pill on the right (Needs you on Today,
/// SA01 and AD04). The whole row is the button; the pill names what it does.
struct NeedsYouRow<Pill: View>: View {
    let title: String
    let detail: String
    let actionName: String
    let action: () -> Void
    @ViewBuilder let pill: Pill

    init(title: String, detail: String, actionName: String, action: @escaping () -> Void, @ViewBuilder pill: () -> Pill) {
        self.title = title
        self.detail = detail
        self.actionName = actionName
        self.action = action
        self.pill = pill()
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(detail)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: MLSpacing.s8)
                pill
            }
            .padding(.vertical, MLSpacing.s12)
            .frame(minHeight: MLSize.hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(detail)")
        .accessibilityHint(actionName)
        .accessibilityAddTraits(.isButton)
        .overlay(alignment: .top) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
    }
}

/// The pill on a Needs you row: what tapping the row does, as a word. Outlined, or lime with the ink outline for a
/// live problem (the only lime on a light surface the design allows).
struct NeedsYouPill: View {
    let title: String
    var isLime = false

    var body: some View {
        Text(title)
            .font(MLType.staffPrimary)
            .foregroundStyle(MLColor.ink)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, MLSpacing.s20)
            .frame(minHeight: MLSize.hit)
            .background {
                if isLime {
                    Capsule().fill(MLColor.lime)
                }
            }
            .overlay(Capsule().stroke(MLColor.ink, lineWidth: 1.5))
            .accessibilityHidden(true)
    }
}
