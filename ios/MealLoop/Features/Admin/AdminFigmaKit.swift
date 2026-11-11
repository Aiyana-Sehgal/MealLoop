import SwiftUI

// Local pieces drawn on Figma page 12 that the shared components don't have. Shared files stay as they are.

/// Sizes the type tokens don't hold. From the Figma text styles (ML/Hero Metric and friends).
enum AdminType {
    static let chip = Font.ml(size: 15, weight: .medium)
    static let smallChip = Font.ml(size: 13, weight: .medium)
    static let heroMetric = Font.ml(size: 80, weight: .bold, design: .monospaced)
    static let heroLarge = Font.ml(size: 72, weight: .bold, design: .monospaced)
    static let tileMetric = Font.ml(size: 46, weight: .bold, design: .monospaced)
    static let stat = Font.ml(size: 52, weight: .bold, design: .monospaced)
    static let count = Font.ml(size: 28, weight: .bold, design: .monospaced)
    static let mono17 = Font.ml(size: 17, weight: .medium, design: .monospaced)
    static let mono20 = Font.ml(size: 20, weight: .medium, design: .monospaced)
}

/// AdminChip (2240:213). Display only: a chip names a status, it never changes one.
enum AdminChipStyle: Equatable {
    case lime
    case outline
    case dashed
    case black
    /// White on black, for the selected chip of a pair.
    case ink
    case filled
    case quiet
}

/// Which chip each status draws. Words and states come from the records; this only picks a look.
enum AdminChipRules {
    static func reason(_ tag: ReasonTag) -> AdminChipStyle {
        switch tag {
        case .sure: return .lime
        case .probably: return .outline
        case .cantTell: return .dashed
        }
    }

    static func stage(_ stage: CheckStage) -> AdminChipStyle { stage == .testing ? .lime : .outline }
    static func review(needsReview: Bool) -> AdminChipStyle { needsReview ? .black : .outline }
    static func safety(isOpen: Bool) -> AdminChipStyle { isOpen ? .lime : .outline }
    static func community(hasOwner: Bool) -> AdminChipStyle { hasOwner ? .quiet : .outline }

    static func vendor(_ reply: AdminVendorReply) -> AdminChipStyle {
        switch reply {
        case .notSent: return .dashed
        case .waiting: return .quiet
        case .replied, .noReply: return .outline
        }
    }
}

struct AdminChip: View {
    let text: String
    var style: AdminChipStyle = .outline
    var symbol: String?
    /// The restyled pages draw chips a step smaller.
    var isSmall = false

    private var foreground: Color {
        switch style {
        case .black: return MLColor.lime
        case .filled, .ink: return MLColor.onHero
        case .lime: return MLColor.onLime
        default: return MLColor.ink
        }
    }

    var body: some View {
        HStack(spacing: MLSpacing.s4) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .medium))
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(isSmall ? AdminType.smallChip : AdminType.chip)
                .lineLimit(1)
                .fixedSize()
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, isSmall ? 10 : 14)
        .padding(.vertical, isSmall ? 4 : 6)
        .background { background }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .lime:
            // The small chips on the restyled pages have no outline.
            Capsule().fill(MLColor.lime).overlay(Capsule().stroke(isSmall ? Color.clear : MLColor.ink, lineWidth: 1.5))
        case .outline:
            Capsule().stroke(MLColor.ink, lineWidth: 1.5)
        case .dashed:
            Capsule().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        case .black, .ink:
            Capsule().fill(MLColor.ink)
        case .filled:
            Capsule().fill(MLColor.inkSecondary)
        case .quiet:
            Capsule().fill(MLColor.fillQuiet)
        }
    }
}

/// DishPictogram (2129:2299). Which of the five a dish gets is a keyword rule, as in the component's notes.
enum AdminDishKind: Equatable {
    case bread, rice, paneer, curd, curry

    static func kind(for dish: String) -> AdminDishKind {
        let name = dish.lowercased()
        func has(_ words: [String]) -> Bool { words.contains { name.contains($0) } }
        if has(["paneer", "panneer"]) { return .paneer }
        if has(["curd", "raita", "buttermilk", "ice cream"]) { return .curd }
        if has(["dosa", "idli", "chapathi", "chappathi", "chapati", "paratha", "poori", "bhature", "idiyappam", "bread"]) { return .bread }
        if has(["rice", "pulao", "briyani", "biryani"]) { return .rice }
        return .curry
    }
}

/// Drawn from design/reference/redesign_2026-10/assets/pictograms, on the same 40 unit grid.
struct AdminDishPictogram: View {
    let dish: String
    var size: CGFloat = 28
    var color: Color = MLColor.ink

    var body: some View {
        Canvas { context, canvas in
            let unit = canvas.width / 40
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * unit, y: y * unit) }
            func bowl(_ left: CGFloat, _ right: CGFloat, _ y: CGFloat) {
                var path = Path()
                path.addArc(center: point((left + right) / 2, y), radius: (right - left) / 2 * unit,
                            startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                path.closeSubpath()
                context.fill(path, with: .color(color))
            }
            func dot(_ x: CGFloat, _ y: CGFloat) {
                let r = 2.2 * unit
                context.fill(Path(ellipseIn: CGRect(x: x * unit - r, y: y * unit - r, width: r * 2, height: r * 2)), with: .color(color))
            }
            func steam(_ x: CGFloat) {
                var path = Path()
                path.move(to: point(x, 20))
                path.addQuadCurve(to: point(x, 12), control: point(x + 3, 16))
                path.addQuadCurve(to: point(x, 4), control: point(x - 3, 8))
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 2.2 * unit, lineCap: .round))
            }
            func cube(_ x: CGFloat, _ y: CGFloat, _ angle: Double) {
                let side = 7 * unit
                let rect = CGRect(x: -side / 2, y: -side / 2, width: side, height: side)
                let turn = CGAffineTransform(rotationAngle: angle * .pi / 180).concatenating(CGAffineTransform(translationX: (x + 3.5) * unit, y: (y + 3.5) * unit))
                context.stroke(Path(rect).applying(turn), with: .color(color), lineWidth: 2 * unit)
            }
            switch AdminDishKind.kind(for: dish) {
            case .bread:
                let r = 15 * unit
                context.stroke(Path(ellipseIn: CGRect(x: 20 * unit - r, y: 20 * unit - r, width: r * 2, height: r * 2)), with: .color(color), lineWidth: 2.4 * unit)
                dot(14, 16); dot(25, 22); dot(17, 26)
            case .rice:
                bowl(4, 36, 24)
                dot(12, 19); dot(20, 15); dot(28, 19); dot(16, 11); dot(24, 11)
            case .paneer:
                bowl(4, 36, 28)
                cube(9, 17, -10); cube(17, 12, 8); cube(25, 17, -6)
            case .curd:
                bowl(8, 32, 28)
                let r = 7 * unit
                context.stroke(Path(ellipseIn: CGRect(x: 20 * unit - r, y: 19 * unit - r, width: r * 2, height: r * 2)), with: .color(color), lineWidth: 2.2 * unit)
            case .curry:
                bowl(4, 36, 26)
                steam(14); steam(26)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Back, as a white 46 pt circle with a soft shadow.
struct AdminBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(MLColor.ink)
                .frame(width: 46, height: 46)
                .background(Circle().fill(MLColor.surface).shadow(color: MLColor.ink.opacity(0.08), radius: 8, y: 2))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}

/// The switch as drawn. Lime with an ink knob on Edit day; black with a white knob on Check a day.
struct AdminSwitchStyle: ToggleStyle {
    var isInk = false

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                Spacer(minLength: MLSpacing.s8)
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(configuration.isOn ? (isInk ? MLColor.ink : MLColor.lime) : MLColor.fillQuiet)
                        .overlay(Capsule().stroke(configuration.isOn ? MLColor.ink : Color.clear, lineWidth: 1.5))
                    Circle()
                        .fill(configuration.isOn ? (isInk ? MLColor.surface : MLColor.ink) : MLColor.surface)
                        .padding(3)
                }
                .frame(width: 48, height: 30)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
    }
}

/// The Veg mark on Edit day: a lime-filled square with a green edge. Non-veg is the red triangle, as drawn.
struct AdminVegMark: View {
    let isNonVeg: Bool

    private let green = Color(red: 0.13, green: 0.55, blue: 0.27)
    private let red = Color(red: 0.80, green: 0.20, blue: 0.16)

    var body: some View {
        Group {
            if isNonVeg {
                Image(systemName: "arrowtriangle.up.square.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(red)
            } else {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(MLColor.lime)
                    .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(green, lineWidth: 2))
                    .overlay(Circle().fill(green).padding(5))
                    .frame(width: 20, height: 20)
            }
        }
    }
}

/// The dashed arrow on the Meal report ticket.
struct AdminCurvedArrow: View {
    var body: some View {
        Canvas { context, size in
            let start = CGPoint(x: 2, y: size.height - 3)
            let end = CGPoint(x: size.width - 4, y: size.height * 0.55)
            var curve = Path()
            curve.move(to: start)
            curve.addQuadCurve(to: end, control: CGPoint(x: size.width / 2, y: -size.height * 0.2))
            context.stroke(curve, with: .color(MLColor.ink), style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
            var head = Path()
            head.move(to: CGPoint(x: end.x - 6, y: end.y - 4))
            head.addLine(to: end)
            head.addLine(to: CGPoint(x: end.x - 7, y: end.y + 2))
            context.stroke(head, with: .color(MLColor.ink), lineWidth: 1.2)
        }
        .frame(width: 72, height: 22)
        .accessibilityHidden(true)
    }
}

/// The salt mark on a "too salty" problem row. SF Symbols has none.
struct AdminProblemIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(MLColor.ink, lineWidth: 1.8)
                .frame(width: 15, height: 22)
                .offset(y: 3)
            Capsule().fill(MLColor.ink).frame(width: 9, height: 3).offset(y: -11)
            VStack(spacing: 3) {
                Circle().fill(MLColor.ink).frame(width: 2.5, height: 2.5)
                Circle().fill(MLColor.ink).frame(width: 2.5, height: 2.5)
            }
            .offset(y: 3)
        }
        .frame(width: 28, height: 28)
        .accessibilityHidden(true)
    }
}

/// The trailing chevron, for rows that draw one themselves.
struct AdminChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(MLColor.inkSecondary)
            .accessibilityHidden(true)
    }
}
