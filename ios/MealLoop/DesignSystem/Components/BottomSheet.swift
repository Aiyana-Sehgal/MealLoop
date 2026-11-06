import SwiftUI

/// The round Close (×) of every sheet. The circle is 44 pt, the minimum target.
struct SheetCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MLColor.ink)
                .frame(width: MLSize.hit, height: MLSize.hit)
                .background(Circle().fill(MLColor.fillQuiet))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }
}

/// Title, optional secondary line and Close, as at the top of D06, K04 and K07.
/// Leave `onClose` nil for a sheet that closes with its own buttons (G08).
struct SheetHeader: View {
    let title: String
    var subtitle: String?
    var onClose: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: MLSpacing.s12) {
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text(title)
                    .font(MLType.title2)
                    .foregroundStyle(MLColor.ink)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let onClose {
                SheetCloseButton(action: onClose)
            }
        }
    }
}

/// Sizes a sheet to its content, and scrolls when the content is taller than the screen.
private struct SheetContainer<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var height: CGFloat = 0

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s32)
                .padding(.bottom, MLSpacing.s20)
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(key: SheetHeightKey.self, value: proxy.size.height)
                    }
                }
        }
        .scrollBounceBehavior(.basedOnSize)
        .onPreferenceChange(SheetHeightKey.self) { height = $0 }
        .presentationDetents(height > 0 ? [.height(height)] : [.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(MLRadius.card)
        .presentationBackground(MLColor.surface)
    }
}

private struct SheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension View {
    /// The standard sheet: grab handle, white surface, as tall as its content, and it closes on a tap outside.
    /// Start the content with `SheetHeader`.
    func mlSheet<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        sheet(isPresented: isPresented) {
            SheetContainer(content: content)
        }
    }
}
