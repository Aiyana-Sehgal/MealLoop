import SwiftUI

/// The wording of one confirmation. All of it comes from the feature's copy.
struct ConfirmDialogContent: Equatable {
    let title: String
    /// Ink line under the title ("Lunch · Main Mess").
    var subject: String?
    /// Grey line saying what will happen ("Door scanner and pass desk will open.").
    var detail: String?
    let cancelTitle: String
    let actionTitle: String
}

/// The centred iOS-style card with Cancel and the action side by side (S13, S14, S15, S17).
/// While `isWorking` both buttons ignore taps, so a write can't be sent twice.
struct ConfirmDialog: View {
    let content: ConfirmDialogContent
    var isWorking: Bool = false
    let onCancel: () -> Void
    let onConfirm: () -> Void

    /// Measured from the S14 export: the button row is 64 pt tall.
    private let buttonHeight: CGFloat = 64

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: MLSpacing.s8) {
                Text(content.title)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                    .accessibilityAddTraits(.isHeader)
                if let subject = content.subject {
                    Text(subject)
                        .font(MLType.staffBody)
                        .foregroundStyle(MLColor.ink)
                }
                if let detail = content.detail {
                    Text(detail)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .padding(MLSpacing.s24)
            .frame(maxWidth: .infinity)

            Rectangle().fill(MLColor.border).frame(height: 1)

            HStack(spacing: 0) {
                Button(action: onCancel) {
                    Text(content.cancelTitle)
                        .font(MLType.staffBody)
                        .foregroundStyle(MLColor.ink)
                        .frame(maxWidth: .infinity, minHeight: buttonHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isWorking)

                Rectangle().fill(MLColor.border).frame(width: 1, height: buttonHeight)

                Button(action: onConfirm) {
                    ZStack {
                        Text(content.actionTitle).opacity(isWorking ? 0 : 1)
                        if isWorking {
                            ProgressView().tint(MLColor.ink)
                        }
                    }
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                    .frame(maxWidth: .infinity, minHeight: buttonHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isWorking)
                .accessibilityLabel(content.actionTitle)
                .accessibilityValue(isWorking ? "In progress" : "")
            }
        }
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}

extension View {
    /// Shows `ConfirmDialog` above everything, including the tab bar. A tap outside does nothing, as on an iOS alert.
    /// Cancel closes it. `onConfirm` leaves it open, so the caller can show `isWorking` and close it when the write ends.
    func mlConfirmDialog(
        isPresented: Binding<Bool>,
        content: ConfirmDialogContent,
        isWorking: Bool = false,
        onConfirm: @escaping () -> Void
    ) -> some View {
        fullScreenCover(isPresented: isPresented) {
            ZStack {
                // The scrim measures ink at 40% in the S14 export.
                MLColor.ink.opacity(0.4).ignoresSafeArea()
                ConfirmDialog(
                    content: content,
                    isWorking: isWorking,
                    onCancel: { isPresented.wrappedValue = false },
                    onConfirm: onConfirm
                )
                .padding(.horizontal, MLSpacing.s16)
            }
            .presentationBackground(.clear)
        }
        // A dialog appears in place. The system cover would slide it up from the bottom.
        .transaction { $0.disablesAnimations = true }
    }
}
