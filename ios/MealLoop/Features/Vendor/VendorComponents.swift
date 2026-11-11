import SwiftUI

// Pieces the Vendor screens draw. Each takes ready values and decides nothing.
// Sizes follow Admin "Headcount · Sent" (2259:160041) and DS-1 Home during (2471:2437), in the repository's tokens.

enum VendorLayout {
    /// The black headcount card in 2259:160041 is about 250 pt tall at 393 pt wide.
    static let tabBarClearance: CGFloat = 120
    static let meAvatar: CGFloat = 92
    static let chipHeight: CGFloat = 36
    /// The headcount number in 2259:160041 is about 80 pt; `MLType.heroNumber` is 56.
    static let headcountNumber = Font.ml(size: 80, weight: .bold, design: .monospaced)
}

/// The status chip under the title: lime when the vendor has something, outlined while waiting.
struct VendorChip: View {
    enum Style { case lime, outline }

    let text: String
    let style: Style

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            if style == .lime {
                Circle().fill(MLColor.ink).frame(width: MLSize.statusDot, height: MLSize.statusDot)
            }
            Text(text)
                .font(MLType.bodyEmphasis)
                .foregroundStyle(MLColor.ink)
        }
        .padding(.horizontal, MLSpacing.s16)
        .frame(minHeight: VendorLayout.chipHeight)
        .background {
            if style == .lime {
                Capsule().fill(MLColor.lime).overlay(Capsule().stroke(MLColor.limeOutline, lineWidth: 1))
            } else {
                Capsule().stroke(MLColor.ink, lineWidth: 1.5)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// The black headcount card: eyebrow, the number (or "—"), its label, and an optional action inside.
struct VendorHeadcountCard<Action: View>: View {
    let eyebrow: String
    /// Nil shows "—", never 0.
    let count: Int?
    let label: String
    var line: String?
    @ViewBuilder let action: Action

    var body: some View {
        HeroCard {
            HeroEyebrow(label: eyebrow, showsDot: count != nil)
            Text(count.map(String.init) ?? "—")
                .font(count == nil ? MLType.heroNumber : VendorLayout.headcountNumber)
                .foregroundStyle(count == nil ? MLColor.onHeroSecondary : MLColor.onHero)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.top, MLSpacing.s12)
            Text(label)
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.onHeroSecondary)
            if let line {
                Text(line)
                    .font(MLType.staffBody)
                    .foregroundStyle(MLColor.onHero)
                    .padding(.top, MLSpacing.s16)
            }
            // The card wraps its content (vendor_03): no fixed height, so a card without an action has no empty band.
            if Action.self != EmptyView.self {
                action
                    .padding(.top, MLSpacing.s16)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// A white row: a title on the left and a status on the right (previous meal, Your reply, History rows).
struct VendorStatusRow<Trailing: View>: View {
    let title: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            Text(title)
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: MLSpacing.s8)
            trailing
                .layoutPriority(1)
        }
        .padding(.horizontal, MLSpacing.s20)
        .frame(minHeight: MLSize.staffButton)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }
}

/// The reply as a quiet word: "acknowledged 7:05" or "Pending", with the time in mono.
struct VendorReplyText: View {
    let prefix: String?
    let time: String?

    var body: some View {
        HStack(spacing: MLSpacing.s4) {
            if let prefix, let time {
                Text(prefix).font(MLType.body)
                Text(time).font(MLType.monoBody)
            } else {
                Text(VendorCopy.pending).font(MLType.body)
            }
        }
        .foregroundStyle(MLColor.inkSecondary)
        .lineLimit(1)
        .fixedSize()
    }
}

/// The outlined "Couldn't send" chip with a warning icon.
struct VendorFailedChip: View {
    var body: some View {
        HStack(spacing: MLSpacing.s4) {
            Image(systemName: "exclamationmark.triangle")
                .accessibilityHidden(true)
            Text(VendorCopy.couldNotSend)
        }
        .font(MLType.bodyEmphasis)
        .foregroundStyle(MLColor.ink)
        .padding(.horizontal, MLSpacing.s16)
        .frame(minHeight: VendorLayout.chipHeight)
        .overlay(Capsule().stroke(MLColor.ink, lineWidth: 1.5))
    }
}

/// The black line shown while a reply could not be sent.
struct VendorOfflineLine: View {
    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            Image(systemName: "wifi.slash")
                .accessibilityHidden(true)
            Text(VendorCopy.noConnection)
                .font(MLType.bodyEmphasis)
        }
        .foregroundStyle(MLColor.onHero)
        .padding(.horizontal, MLSpacing.s16)
        .padding(.vertical, MLSpacing.s8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.heroBackground))
        .accessibilityElement(children: .combine)
    }
}

/// A grey centred note under a card.
struct VendorNote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(MLType.body)
            .foregroundStyle(MLColor.inkSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}
