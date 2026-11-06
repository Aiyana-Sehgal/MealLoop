import SwiftUI

/// A centred block with an outlined icon circle, for a screen with nothing to list (S09, D17 empty, K12d).
/// `EmptyStateView` is the plain text form that `AsyncContentView` uses; this one is for screens drawn with the icon.
struct StateBlock: View {
    let symbol: String
    let title: String
    var message: String?
    var actionTitle: String?
    var onAction: (() -> Void)?

    /// Measured from the D17 empty export.
    private let circleDiameter: CGFloat = 64

    var body: some View {
        VStack(spacing: MLSpacing.s12) {
            VStack(spacing: MLSpacing.s12) {
                Image(systemName: symbol)
                    .font(.system(size: 24))
                    .foregroundStyle(MLColor.ink)
                    .frame(width: circleDiameter, height: circleDiameter)
                    .overlay(Circle().stroke(MLColor.ink, lineWidth: 1))
                    .accessibilityHidden(true)
                Text(title)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                if let message {
                    Text(message)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            if let actionTitle, let onAction {
                CompactPillButton(title: actionTitle, action: onAction)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, MLSpacing.margin)
    }
}
