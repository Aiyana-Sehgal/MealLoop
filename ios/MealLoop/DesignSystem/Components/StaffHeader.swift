import SwiftUI

/// The MealLoop mark: an ink ring with a lime dot on its upper right, as in 01_sign_in.
/// Drawn from the reference until the final logo file exists (open decision).
struct OrbitMarkView: View {
    /// The ring's outer diameter. The stroke and the dot scale with it.
    var size: CGFloat = 24

    var body: some View {
        Circle()
            .stroke(MLColor.ink, lineWidth: size * 0.15)
            .frame(width: size * 0.85, height: size * 0.85)
            .frame(width: size, height: size)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(MLColor.lime)
                    .overlay(Circle().stroke(MLColor.limeOutline, lineWidth: size * 0.05))
                    .frame(width: size * 0.42, height: size * 0.42)
                    .offset(x: size * 0.06, y: -size * 0.06)
            }
            .accessibilityHidden(true)
    }
}

/// Header shared by the staff homes: mark and wordmark on the left, initials avatar on the right.
struct StaffHeader: View {
    let initials: String
    var onAvatarTap: (() -> Void)?

    var body: some View {
        HStack {
            HStack(spacing: MLSpacing.s8) {
                OrbitMarkView()
                Text("MealLoop")
                    .font(MLType.bodyEmphasis)
                    .foregroundStyle(MLColor.ink)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            Button {
                onAvatarTap?()
            } label: {
                Text(initials)
                    .font(MLType.bodyEmphasis)
                    .foregroundStyle(MLColor.lime)
                    .frame(width: MLSize.avatar, height: MLSize.avatar)
                    .background(Circle().fill(MLColor.ink))
            }
            .buttonStyle(.plain)
            .frame(minWidth: MLSize.hit, minHeight: MLSize.hit)
            .accessibilityLabel("Me")
        }
    }
}

/// Large title with one secondary line ("Lunch" / "Main Mess · 12–2 PM").
struct ScreenTitleBlock: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(title)
                .font(MLType.largeTitle)
                .foregroundStyle(MLColor.ink)
            Text(subtitle)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
