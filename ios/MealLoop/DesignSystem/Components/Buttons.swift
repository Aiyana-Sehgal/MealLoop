import SwiftUI

/// Lime primary action, 56 pt (staff). On a light surface it gets the 1 pt ink outline (brand rule V2).
struct LimeActionButton: View {
    let title: String
    var systemImage: String?
    var onLightSurface: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(MLType.staffPrimary)
            .foregroundStyle(MLColor.onLime)
            .frame(maxWidth: .infinity, minHeight: MLSize.staffButton)
            .background(Capsule().fill(MLColor.lime))
            .overlay {
                if onLightSurface {
                    Capsule().stroke(MLColor.limeOutline, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// Black primary action, 56 pt (staff). While `isLoading` it shows a spinner and ignores taps.
struct InkActionButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(MLColor.onHero)
                }
            }
            .font(MLType.staffPrimary)
            .foregroundStyle(MLColor.onHero)
            .frame(maxWidth: .infinity, minHeight: MLSize.staffButton)
            .background(Capsule().fill(MLColor.ink))
            .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(title)
        .accessibilityValue(isLoading ? "Loading" : "")
    }
}

/// Outlined secondary action, 56 pt, for the second choice next to a black primary.
struct OutlineActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
                .frame(maxWidth: .infinity, minHeight: MLSize.staffButton)
                .overlay(Capsule().stroke(MLColor.ink, lineWidth: 1.5))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// The one Back control: a 44 pt round glass circle with the system chevron, top left (design_intent.md, BackButton).
struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(MLColor.ink)
                .frame(width: MLSize.hit, height: MLSize.hit)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().stroke(MLColor.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}

/// The determinate-looking ring of 02_getting_details: a quiet track with a quarter arc in ink.
/// It stands still when Reduce Motion is on.
struct ProgressRing: View {
    var size: CGFloat = 96
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            Circle().stroke(MLColor.track, lineWidth: 8)
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(MLColor.ink, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(isSpinning ? 270 : -90))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                isSpinning = true
            }
        }
    }
}
