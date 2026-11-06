import SwiftUI

/// The small label above a group, with a hairline under it ("Earlier" D17, "Needs you" A01, "Food left over" K06).
struct SectionHeader: View {
    let title: String
    /// An optional action on the right ("See all").
    var actionTitle: String?
    var onAction: (() -> Void)?

    var body: some View {
        VStack(spacing: MLSpacing.s4) {
            HStack {
                Text(title)
                    .font(MLType.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: MLSpacing.s8)
                if let actionTitle, let onAction {
                    TextLinkButton(title: actionTitle, action: onAction)
                }
            }
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
    }
}

/// One alert: a circle on a shared axis, a short title, the time on the right and one line (D17, P14, K12).
struct AlertRow: View {
    enum Mark {
        /// Lime circle with a tick: something finished.
        case done
        /// Black circle: something that happened.
        case filled(symbol: String)
        /// Outlined circle: something coming up.
        case outlined(symbol: String)
    }

    let mark: Mark
    let title: String
    /// Mono time, right aligned.
    let time: String
    let detail: String
    var isUnread: Bool = false
    /// Leave nil for a row that opens nothing; it then has no button trait.
    var onTap: (() -> Void)?

    var body: some View {
        if let onTap {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: MLSpacing.s12) {
            markView
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: MLSpacing.s8) {
                    if isUnread {
                        Circle()
                            .fill(MLColor.lime)
                            .overlay(Circle().stroke(MLColor.limeOutline, lineWidth: 1))
                            .frame(width: MLSize.statusDot, height: MLSize.statusDot)
                    }
                    Text(title)
                        .font(isUnread ? MLType.staffPrimary : MLType.staffBody)
                        .foregroundStyle(MLColor.ink)
                    Spacer(minLength: MLSpacing.s8)
                    Text(time)
                        .font(MLType.monoSecondary)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Text(detail)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
        }
        .padding(.vertical, MLSpacing.s12)
        .frame(minHeight: MLSize.staffButton)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isUnread ? "Unread. \(title)" : title)
        .accessibilityValue("\(time). \(detail)")
    }

    @ViewBuilder
    private var markView: some View {
        let diameter = MLSize.iconSquare
        switch mark {
        case .done:
            Image(systemName: "checkmark")
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.onLime)
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(MLColor.lime))
                .overlay(Circle().stroke(MLColor.limeOutline, lineWidth: 1))
        case .filled(let symbol):
            Image(systemName: symbol)
                .font(MLType.body)
                .foregroundStyle(MLColor.onHero)
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(MLColor.ink))
        case .outlined(let symbol):
            Image(systemName: symbol)
                .font(MLType.body)
                .foregroundStyle(MLColor.ink)
                .frame(width: diameter, height: diameter)
                .overlay(Circle().stroke(MLColor.ink, lineWidth: 1))
        }
    }
}

/// A white card row with an icon circle and a chevron ("Report a problem" D05, its options on D11 and P11).
struct IconCardRow: View {
    let symbol: String
    let title: String
    var detail: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s16) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
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
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MLColor.inkSecondary)
                    .accessibilityHidden(true)
            }
            .padding(MLSpacing.s16)
            .frame(minHeight: MLSize.staffButton)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
            .contentShape(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
