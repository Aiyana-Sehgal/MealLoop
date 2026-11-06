import SwiftUI

/// The digits typed so far, up to a fixed length. It only holds them: what a complete entry means is the caller's job.
struct DigitEntry: Equatable {
    private(set) var digits: [Int] = []
    var length: Int = 4

    var isComplete: Bool { digits.count == length }

    /// The digits as one string, with any leading zeros kept ("0238").
    var text: String { digits.map(String.init).joined() }

    /// Says how far the entry has got, then the digits, so a screen reader needs no sight of the boxes.
    var spokenValue: String {
        let progress = "\(digits.count) of \(length) entered"
        return digits.isEmpty ? progress : "\(progress). \(text)"
    }

    /// A digit outside 0 to 9, or one past the length, is ignored.
    mutating func append(_ digit: Int) {
        guard (0...9).contains(digit), !isComplete else { return }
        digits.append(digit)
    }

    mutating func deleteLast() {
        _ = digits.popLast()
    }

    mutating func clear() {
        digits.removeAll()
    }
}

/// The row of digit boxes above a keypad (D06 in a sheet, P03 on a black card, P17). Pair it with `KeyPad`.
struct DigitBoxes: View {
    enum Surface {
        /// Quiet boxes on a white sheet or card.
        case light
        /// Dark boxes on the black card.
        case hero
    }

    let entry: DigitEntry
    var surface: Surface = .light
    /// What the digits are, for a screen reader ("Student's last 4 digits").
    var accessibilityTitle: String = "Digits"

    /// Measured from D06 at 1.346.
    private let boxHeight: CGFloat = 64

    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            ForEach(0..<entry.length, id: \.self) { index in
                Text(index < entry.digits.count ? String(entry.digits[index]) : " ")
                    .font(MLType.title2.monospaced())
                    .foregroundStyle(surface == .hero ? MLColor.onHero : MLColor.ink)
                    .frame(maxWidth: .infinity, minHeight: boxHeight)
                    .background(
                        RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
                            .fill(surface == .hero ? MLColor.onHero.opacity(0.15) : MLColor.fillQuiet)
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue(entry.spokenValue)
    }
}
