import SwiftUI

/// Type tokens. The design is drawn in Inter and JetBrains Mono as stand-ins for SF Pro and SF Mono
/// (design/README.md, "Known limits"), so the app uses the system fonts.
/// Rules: text never below 12 pt; staff primary content 17 pt or more; mono only for numbers, times, units and IDs.
enum MLType {
    /// Large title, 34 pt (titles across the staff and outing screens).
    static let largeTitle = Font.system(size: 34, weight: .bold)
    /// Hero title on a black card ("Lunch has ended").
    static let heroTitle = Font.system(size: 28, weight: .bold)
    /// Row and sheet titles, 22 pt ("Door Scanner" on role selection, "What you do").
    static let title2 = Font.system(size: 22, weight: .bold)
    /// Primary staff content and buttons, 17 pt.
    static let staffPrimary = Font.system(size: 17, weight: .semibold)
    static let staffBody = Font.system(size: 17, weight: .regular)
    /// Body, 15 pt.
    static let body = Font.system(size: 15, weight: .regular)
    static let bodyEmphasis = Font.system(size: 15, weight: .semibold)
    /// Secondary, 13 pt.
    static let secondary = Font.system(size: 13, weight: .regular)
    /// Eyebrow caps ("FORECASTED ATTENDANCE"). Sans, not mono: mono is only for numbers.
    static let eyebrow = Font.system(size: 13, weight: .semibold)
    /// Meta, 12 pt: the smallest size allowed.
    static let meta = Font.system(size: 12, weight: .medium)

    /// The big count on a hero card (860, 714, 774).
    static let heroNumber = Font.system(size: 56, weight: .bold, design: .monospaced)
    /// Times and short numbers inside text ("1:40 PM").
    static let monoSecondary = Font.system(size: 13, weight: .medium, design: .monospaced)
    static let monoBody = Font.system(size: 15, weight: .medium, design: .monospaced)
}
