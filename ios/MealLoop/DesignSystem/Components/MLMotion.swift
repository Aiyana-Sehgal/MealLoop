import SwiftUI

/// The shared motion tokens (docs/SWIFTUI_STANDARDS.md, section 4). Define a curve here once and use it everywhere.
/// Reduce Motion rule: when `accessibilityReduceMotion` is on, nothing moves. Every curve becomes a short cross-fade,
/// every insert or remove becomes an opacity change, and numbers change without rolling.
enum MLMotion {
    enum Curve: Equatable {
        /// State changes on controls: selection, toggles, a value appearing. `withAnimation(.snappy)`.
        case snappy
        /// Larger layout changes: a section expanding, a banner sliding in. `withAnimation(.smooth)`.
        case smooth
        /// The cross-fade every curve becomes under Reduce Motion.
        case crossFade

        /// The curve to use, given the Reduce Motion setting.
        func resolved(reduceMotion: Bool) -> Curve {
            reduceMotion ? .crossFade : self
        }

        var animation: Animation {
            switch self {
            case .snappy: .snappy(duration: 0.3)
            case .smooth: .smooth(duration: 0.4)
            case .crossFade: .easeInOut(duration: 0.2)
            }
        }
    }

    /// How an inserted or removed view arrives.
    enum Entrance: Equatable {
        /// Slides in from the top edge and fades (banners, inline errors).
        case fromTop
        /// Slides in from the bottom edge and fades (toasts, pinned bars).
        case fromBottom
        /// Scales up slightly and fades (chips, badges).
        case pop
        /// Opacity only. What every entrance becomes under Reduce Motion.
        case fade

        func resolved(reduceMotion: Bool) -> Entrance {
            reduceMotion ? .fade : self
        }

        var transition: AnyTransition {
            switch self {
            case .fromTop: .move(edge: .top).combined(with: .opacity)
            case .fromBottom: .move(edge: .bottom).combined(with: .opacity)
            case .pop: .scale(scale: 0.9).combined(with: .opacity)
            case .fade: .opacity
            }
        }
    }

    /// `withAnimation` with a shared curve. Pass the view's `accessibilityReduceMotion` value.
    @discardableResult
    static func animate<Result>(_ curve: Curve = .snappy, reduceMotion: Bool, _ body: () throws -> Result) rethrows -> Result {
        try withAnimation(curve.resolved(reduceMotion: reduceMotion).animation, body)
    }
}

/// The three haptics the standards allow, through `.sensoryFeedback`, once per action.
enum MLHaptic: Equatable {
    case selection
    case success
    case warning

    var feedback: SensoryFeedback {
        switch self {
        case .selection: .selection
        case .success: .success
        case .warning: .warning
        }
    }
}

private struct MLAnimationModifier<Value: Equatable>: ViewModifier {
    let curve: MLMotion.Curve
    let value: Value
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(curve.resolved(reduceMotion: reduceMotion).animation, value: value)
    }
}

private struct MLTransitionModifier: ViewModifier {
    let entrance: MLMotion.Entrance
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.transition(entrance.resolved(reduceMotion: reduceMotion).transition)
    }
}

private struct MLNumericTextModifier: ViewModifier {
    let value: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .contentTransition(reduceMotion ? .opacity : .numericText(value: value))
            .animation(MLMotion.Curve.snappy.resolved(reduceMotion: reduceMotion).animation, value: value)
    }
}

extension View {
    /// Animates changes of `value` with a shared curve, cross-fading under Reduce Motion.
    func mlAnimation<Value: Equatable>(_ curve: MLMotion.Curve = .snappy, value: Value) -> some View {
        modifier(MLAnimationModifier(curve: curve, value: value))
    }

    /// The insert and remove transition for a view shown with `if`. Opacity only under Reduce Motion.
    func mlTransition(_ entrance: MLMotion.Entrance) -> some View {
        modifier(MLTransitionModifier(entrance: entrance))
    }

    /// A number that rolls to its new value (`.numericText`), or cross-fades under Reduce Motion.
    func mlNumericText(_ value: Double) -> some View {
        modifier(MLNumericTextModifier(value: value))
    }

    /// A number that rolls to its new value (`.numericText`), or cross-fades under Reduce Motion.
    func mlNumericText(_ value: Int) -> some View {
        modifier(MLNumericTextModifier(value: Double(value)))
    }

    /// One haptic when `trigger` changes, through `.sensoryFeedback`.
    func mlHaptic<Trigger: Equatable>(_ haptic: MLHaptic, trigger: Trigger) -> some View {
        sensoryFeedback(haptic.feedback, trigger: trigger)
    }

    /// One haptic when `trigger` changes and `condition` says so (for example only when an error appears).
    func mlHaptic<Trigger: Equatable>(_ haptic: MLHaptic, trigger: Trigger, when condition: @escaping (Trigger, Trigger) -> Bool) -> some View {
        sensoryFeedback(haptic.feedback, trigger: trigger, condition: condition)
    }
}
