import SwiftUI

/// Number keypad shared by the role password, the Door Scanner "Type the last 4 digits" sheet and the Pass Desk.
/// In a sheet pass `MLColor.fillQuiet` as `keyFill`, because white keys vanish on the white surface, and a smaller
/// `keyHeight` so the keys fit (D06, K07). Pass `onDecimal` for the quantity keypad, which fills the empty key (K07).
struct KeyPad: View {
    var isEnabled: Bool = true
    var keyHeight: CGFloat = 72
    var keyFill: Color = MLColor.surface
    let onDigit: (Int) -> Void
    let onDelete: () -> Void
    var onDecimal: (() -> Void)?

    private let rows: [[Int]] = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

    var body: some View {
        VStack(spacing: MLSpacing.s12) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: MLSpacing.s12) {
                    ForEach(row, id: \.self) { digit in
                        key(digit)
                    }
                }
            }
            HStack(spacing: MLSpacing.s12) {
                if let onDecimal {
                    Button(action: onDecimal) {
                        Text(".")
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .foregroundStyle(MLColor.ink)
                            .frame(maxWidth: .infinity, minHeight: keyHeight)
                            .background(keyShape.fill(keyFill))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Decimal point")
                } else {
                    Color.clear.frame(maxWidth: .infinity, minHeight: keyHeight)
                }
                key(0)
                Button(action: onDelete) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 22))
                        .foregroundStyle(MLColor.ink)
                        .frame(maxWidth: .infinity, minHeight: keyHeight)
                        .background(keyShape.fill(onDecimal == nil ? Color.clear : keyFill))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete")
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }

    private func key(_ digit: Int) -> some View {
        Button {
            onDigit(digit)
        } label: {
            Text("\(digit)")
                .font(.system(size: 24, weight: .medium, design: .monospaced))
                .foregroundStyle(MLColor.ink)
                .frame(maxWidth: .infinity, minHeight: keyHeight)
                .background(keyShape.fill(keyFill))
        }
        .buttonStyle(.plain)
    }

    private var keyShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
    }
}
