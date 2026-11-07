import CoreImage.CIFilterBuiltins
import SwiftUI

/// Draws a QR from a payload. A failure returns nil and the screen says so; it never shows a blank code as real.
enum EntryQRImage {
    static func make(_ payload: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage,
              let image = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: image)
    }
}

/// Entry QR (08), without the refresh countdown or the Live label: the code is static, so nothing here may look like
/// a live check. It is reachable in every answer state.
struct EntryQRView: View {
    let model: StudentHomeViewModel
    let onBack: () -> Void

    private var hero: StudentMealCard? { model.state.value?.hero }

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    BackButton(action: onBack)
                    ScreenTitleBlock(title: StudentCopy.entryQR,
                                     subtitle: StudentCopy.entrySubtitle(hero?.meal.slot, mess: model.context.mess.name))
                    AsyncContentView(state: model.entryCode, timeZone: model.timeZone,
                                     retry: { await model.loadEntryCode() }) { code in
                        card(code)
                    }
                    Text(StudentCopy.cantScan)
                        .font(MLType.secondary)
                        .foregroundStyle(MLColor.inkSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, 120)
            }
        }
        .task { await model.loadEntryCode() }
    }

    private func card(_ code: EntryCode) -> some View {
        VStack(spacing: MLSpacing.s16) {
            if hero?.answer == .attending {
                Text(StudentCopy.youreInChip)
                    .font(MLType.bodyEmphasis)
                    .foregroundStyle(MLColor.onLime)
                    .padding(.horizontal, MLSpacing.s16)
                    .padding(.vertical, MLSpacing.s8)
                    .background(Capsule().fill(MLColor.lime))
                    .overlay(Capsule().stroke(MLColor.limeOutline, lineWidth: 1))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            qr(code)
            VStack(spacing: MLSpacing.s4) {
                Text("\(model.name) \(model.context.student.maskedID)")
                    .font(MLType.title2)
                    .foregroundStyle(MLColor.ink)
                Text(StudentCopy.holdUp)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
    }

    @ViewBuilder
    private func qr(_ code: EntryCode) -> some View {
        if let image = EntryQRImage.make(code.payload) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(MLSpacing.s20)
                // 254 pt as on 08, smaller on a short phone so "Can't scan?" stays above the tab bar.
                .containerRelativeFrame(.vertical) { length, _ in min(254, length * 0.3) }
                .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).stroke(MLColor.border, lineWidth: 1))
                .accessibilityLabel(StudentCopy.qrLabel(model.name, maskedID: model.context.student.maskedID))
        } else {
            Text(StudentCopy.qrUnavailable)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
        }
    }
}
