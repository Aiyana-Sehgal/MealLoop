import SwiftUI

/// `MLType` styles that scale with Dynamic Type. `MLType` fonts are fixed sizes, so text drawn with them does not grow
/// at larger accessibility sizes. `.mlFont(_:)` draws the same size and weight at the default size, and scales it
/// with the matching system text style. `MLDynamicTypeTests` checks that each base matches its `MLType` token,
/// so the two cannot drift apart. This adds no new size: every value below is an `MLType` value.
enum MLDynamicType: CaseIterable {
    case largeTitle, heroTitle, title2, staffPrimary, staffBody, body, bodyEmphasis, secondary, eyebrow, meta

    /// The `MLType` size this style starts from.
    var baseSize: CGFloat {
        switch self {
        case .largeTitle: 34
        case .heroTitle: 28
        case .title2: 22
        case .staffPrimary, .staffBody: 17
        case .body, .bodyEmphasis: 15
        case .secondary, .eyebrow: 13
        case .meta: 12
        }
    }

    var weight: Font.Weight {
        switch self {
        case .largeTitle, .heroTitle, .title2: .bold
        case .staffPrimary, .bodyEmphasis, .eyebrow: .semibold
        case .staffBody, .body, .secondary: .regular
        case .meta: .medium
        }
    }

    /// The system text style it scales with.
    var textStyle: Font.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .heroTitle: .title
        case .title2: .title2
        case .staffPrimary, .staffBody: .body
        case .body, .bodyEmphasis: .subheadline
        case .secondary, .eyebrow: .footnote
        case .meta: .caption
        }
    }

    /// The matching `MLType` token, at the default text size.
    var token: Font {
        switch self {
        case .largeTitle: MLType.largeTitle
        case .heroTitle: MLType.heroTitle
        case .title2: MLType.title2
        case .staffPrimary: MLType.staffPrimary
        case .staffBody: MLType.staffBody
        case .body: MLType.body
        case .bodyEmphasis: MLType.bodyEmphasis
        case .secondary: MLType.secondary
        case .eyebrow: MLType.eyebrow
        case .meta: MLType.meta
        }
    }

    /// The font at a given size, in this style's weight. At `baseSize` it equals `token`.
    func font(size: CGFloat) -> Font {
        .ml(size: size, weight: weight)
    }
}

private struct MLDynamicFontModifier: ViewModifier {
    let style: MLDynamicType
    @ScaledMetric private var size: CGFloat

    init(style: MLDynamicType) {
        self.style = style
        _size = ScaledMetric(wrappedValue: style.baseSize, relativeTo: style.textStyle)
    }

    func body(content: Content) -> some View {
        content.font(style.font(size: size))
    }
}

extension View {
    /// An `MLType` style that grows with Dynamic Type.
    func mlFont(_ style: MLDynamicType) -> some View {
        modifier(MLDynamicFontModifier(style: style))
    }
}
