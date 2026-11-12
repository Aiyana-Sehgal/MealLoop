import SwiftUI

/// The round outlined ↗ control in a tile's top-right corner (Skipped on SA02). It opens the page behind the tile;
/// 44 pt so it meets the tap-target minimum.
struct RoundGoButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MLColor.ink)
                .frame(width: MLSize.hit, height: MLSize.hit)
                .overlay(Circle().stroke(MLColor.border, lineWidth: 1.5))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
