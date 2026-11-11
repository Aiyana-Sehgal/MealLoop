import CoreText
import SwiftUI
import UIKit

/// The app's typefaces: Inter for text and JetBrains Mono for numbers, as the Figma styles use them (01 Foundations).
/// The files and their OFL notices are in Resources/Fonts. They are registered once at launch, so no Info.plist entry is
/// needed. Only the weights the app draws are bundled.
enum MLFonts {
    static let textWeights: [Font.Weight: String] = [
        .light: "Inter-Light", .regular: "Inter-Regular", .medium: "Inter-Medium",
        .semibold: "Inter-SemiBold", .bold: "Inter-Bold",
    ]
    static let monoWeights: [Font.Weight: String] = [
        .regular: "JetBrainsMono-Regular", .medium: "JetBrainsMono-Medium",
        .semibold: "JetBrainsMono-SemiBold", .bold: "JetBrainsMono-Bold",
    ]

    private static let registration: Void = {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
    }()

    /// Registers the bundled fonts. Safe to call more than once.
    static func register() { _ = registration }

    /// The PostScript name for a weight, or nil when that weight is not bundled.
    static func name(weight: Font.Weight, monospaced: Bool) -> String? {
        (monospaced ? monoWeights : textWeights)[weight]
    }

    /// True when the font can be drawn (registered and present).
    static func isAvailable(_ name: String) -> Bool {
        register()
        return UIFont(name: name, size: 12) != nil
    }
}

extension Font {
    /// A type token in the app's typeface, at a fixed size: Dynamic Type scaling stays with `mlFont` (MLDynamicType),
    /// as it was with the system font. Falls back to the system font if a weight is missing.
    static func ml(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        let monospaced = design == .monospaced
        guard let name = MLFonts.name(weight: weight, monospaced: monospaced), MLFonts.isAvailable(name) else {
            return .system(size: size, weight: weight, design: design)
        }
        return .custom(name, fixedSize: size)
    }
}

extension Font {
    /// A type token that grows with Dynamic Type: the app's typeface at `size` for the default text size, scaled with
    /// `textStyle` as the system styles are. Falls back to the scaled system font if a weight is missing.
    static func mlScaled(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default,
                         relativeTo textStyle: Font.TextStyle) -> Font {
        guard let name = MLFonts.name(weight: weight, monospaced: design == .monospaced), MLFonts.isAvailable(name) else {
            return .system(textStyle, design: design, weight: weight)
        }
        return .custom(name, size: size, relativeTo: textStyle)
    }
}
