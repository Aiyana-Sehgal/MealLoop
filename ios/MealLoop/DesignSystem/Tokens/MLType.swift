import SwiftUI

/// Type tokens, in Inter and JetBrains Mono as the Figma styles draw them (bundled, see `MLFonts`). Icons sized with
/// `.system(size:)` stay on the system font, which SF Symbols need.
/// Rules: text never below 12 pt; staff primary content 17 pt or more; mono only for numbers, times, units and IDs.
enum MLType {
    /// Large title, 34 pt (titles across the staff and outing screens).
    static let largeTitle = Font.ml(size: 34, weight: .bold)
    /// Hero title on a black card ("Lunch has ended").
    static let heroTitle = Font.ml(size: 28, weight: .bold)
    /// Row and sheet titles, 22 pt ("Door Scanner" on role selection, "What you do").
    static let title2 = Font.ml(size: 22, weight: .bold)
    /// Primary staff content and buttons, 17 pt.
    static let staffPrimary = Font.ml(size: 17, weight: .semibold)
    static let staffBody = Font.ml(size: 17, weight: .regular)
    /// Body, 15 pt.
    static let body = Font.ml(size: 15, weight: .regular)
    static let bodyEmphasis = Font.ml(size: 15, weight: .semibold)
    /// Secondary, 13 pt.
    static let secondary = Font.ml(size: 13, weight: .regular)
    /// Eyebrow caps ("FORECASTED ATTENDANCE"). Sans, not mono: mono is only for numbers.
    static let eyebrow = Font.ml(size: 13, weight: .semibold)
    /// Meta, 12 pt: the smallest size allowed.
    static let meta = Font.ml(size: 12, weight: .medium)

    /// The big count on a hero card (860, 714, 774).
    static let heroNumber = Font.ml(size: 56, weight: .bold, design: .monospaced)
    /// Times and short numbers inside text ("1:40 PM").
    static let monoSecondary = Font.ml(size: 13, weight: .medium, design: .monospaced)
    static let monoBody = Font.ml(size: 15, weight: .medium, design: .monospaced)
}
