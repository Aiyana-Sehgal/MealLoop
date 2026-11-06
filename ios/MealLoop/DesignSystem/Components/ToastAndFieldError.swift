import SwiftUI

/// The short floating confirmation at the bottom (D11, K04d, F02). Use it for something that really happened:
/// a failure stays on screen as `FieldErrorText` or a row with Retry, because a toast disappears.
struct ToastBanner: View {
    let text: String
    var symbol: String = "checkmark.circle"

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            Image(systemName: symbol)
                .font(MLType.staffPrimary)
                .accessibilityHidden(true)
            Text(text)
                .font(MLType.bodyEmphasis)
        }
        .foregroundStyle(MLColor.ink)
        .padding(.horizontal, MLSpacing.s16)
        .frame(minHeight: MLSize.hit)
        .background(Capsule().fill(MLColor.surface))
        .shadow(color: MLColor.ink.opacity(0.1), radius: 12, y: 4)
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: String?
    let duration: Duration
    let bottomInset: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    ToastBanner(text: message)
                        .padding(.horizontal, MLSpacing.s16)
                        .padding(.bottom, bottomInset)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: message)
            .task(id: message) {
                guard let shown = message else { return }
                AccessibilityNotification.Announcement(shown).post()
                try? await Task.sleep(for: duration)
                // A newer message restarts this task, which cancels the old wait.
                if !Task.isCancelled {
                    self.message = nil
                }
            }
    }
}

extension View {
    /// Shows `message` as a toast, then sets it back to nil. The prototype holds toasts for 2 s (2.5 s for "Marked as checked").
    /// Pass `bottomInset` to clear a tab bar.
    func mlToast(message: Binding<String?>, duration: Duration = .seconds(2), bottomInset: CGFloat = MLSpacing.s16) -> some View {
        modifier(ToastModifier(message: message, duration: duration, bottomInset: bottomInset))
    }
}

/// An error under a field ("Enter a number up to 99.9."). The icon means it never rests on the red alone.
struct FieldErrorText: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s4) {
            Image(systemName: "exclamationmark.circle")
                .accessibilityHidden(true)
            Text(text)
        }
        .font(MLType.secondary)
        .foregroundStyle(MLColor.danger)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Error: \(text)")
    }
}
