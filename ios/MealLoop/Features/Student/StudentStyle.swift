import SwiftUI

/// Figma text styles the shared `MLType` has no match for, from the ML text styles in file nzzTAm9YnJRSdKEeYUWUEb.
/// Each is the Figma size at the default text size and grows with Dynamic Type through the matching system style.
/// The Student root caps the growth at the first accessibility size, where the designed rows still hold.
enum StudentType {
    static let brand = Font.mlScaled(size: 18, weight: .semibold, relativeTo: .headline)
    static let heroTitle = Font.mlScaled(size: 28, weight: .semibold, relativeTo: .title)
    static let section = Font.mlScaled(size: 22, weight: .semibold, relativeTo: .title2)
    static let bodySemibold = Font.mlScaled(size: 17, weight: .semibold, relativeTo: .body)
    static let body = Font.mlScaled(size: 17, weight: .regular, relativeTo: .body)
    static let secondary = Font.mlScaled(size: 15, weight: .regular, relativeTo: .subheadline)
    static let secondaryMedium = Font.mlScaled(size: 15, weight: .medium, relativeTo: .subheadline)
    static let dishName = Font.mlScaled(size: 15, weight: .semibold, relativeTo: .subheadline)
    static let tag = Font.mlScaled(size: 13, weight: .semibold, relativeTo: .footnote)
    static let footnote = Font.mlScaled(size: 13, weight: .medium, relativeTo: .footnote)
    static let eyebrow = Font.mlScaled(size: 12, weight: .semibold, relativeTo: .caption)
    static let mono = Font.mlScaled(size: 15, weight: .medium, design: .monospaced, relativeTo: .subheadline)

    /// The largest text size the Student screens draw at. Beyond it the designed rows and cards (ticket, crowd, dish
    /// tiles) start to split words on a 375 pt phone.
    static let largestSize = DynamicTypeSize.accessibility1
}

/// Sizes from the frames, where the shared tokens differ.
enum StudentMetric {
    static let heroRadius: CGFloat = 30
    static let heroPadding: CGFloat = 24
    static let rowRadius: CGFloat = 22
    static let highlightRadius: CGFloat = 26
    static let tileRadius: CGFloat = 20
    static let qrZone: CGFloat = 254
    static let answerPrimary: CGFloat = 64
    static let answerSecondary: CGFloat = 56
    /// The tab bar floats over the content, so every scrolling page keeps this clear (TabBar 74:236).
    static let scrollBottom: CGFloat = 124
    static let chipHeight: CGFloat = 36
}

/// The error tint of Answer · Lunch · Failed. Drawn on one card only, so it stays here and not in the tokens.
enum StudentTint {
    static let errorFill = MLColor.danger.opacity(0.09)
}

/// GlassButton 74:101: white glass, a soft edge and a small shadow.
struct StudentGlass<S: InsettableShape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        content
            .background(shape.fill(Color.white.opacity(0.85)))
            .overlay(shape.strokeBorder(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 4, y: 4)
    }
}

/// A 44 pt glass circle with one symbol: Report an issue, Notifications.
struct StudentGlassButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(MLColor.ink)
                .frame(width: MLSize.hit, height: MLSize.hit)
                .modifier(StudentGlass(shape: Circle()))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// HeroCard 2135:2336. The shared `HeroCard` has a smaller radius and padding, so this one is local.
struct StudentHeroCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            content
        }
        .padding(StudentMetric.heroPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.heroBackground))
    }
}

/// The 36 pt status chip on the top card. The shared `HeroStatusChip` is shorter and uses another text style.
struct StudentHeroChip: View {
    enum Style { case lime, outline, dashed }

    let text: String
    let style: Style
    var showsCheck = false

    var body: some View {
        HStack(spacing: MLSpacing.s4) {
            if showsCheck {
                Image(systemName: "checkmark").font(.system(size: 12, weight: .semibold))
            }
            Text(text).font(StudentType.tag)
        }
        .foregroundStyle(style == .lime ? MLColor.onLime : MLColor.onHero)
        .padding(.horizontal, 14)
        .frame(minHeight: StudentMetric.chipHeight)
        .background {
            switch style {
            case .lime:
                Capsule().fill(MLColor.lime)
            case .outline:
                Capsule().strokeBorder(MLColor.onHeroSecondary, lineWidth: 1.5)
            case .dashed:
                Capsule().strokeBorder(MLColor.onHeroSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

/// A solid or outlined pill on the black card, 56 pt.
struct StudentHeroButton: View {
    enum Style { case lime, outline, cream }

    let title: String
    let style: Style
    var expands = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(StudentType.bodySemibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(style == .outline ? MLColor.onHero : MLColor.ink)
                .padding(.horizontal, MLSpacing.s20)
                .frame(maxWidth: expands ? .infinity : nil)
                .frame(minHeight: MLSize.staffButton)
                .background {
                    switch style {
                    case .lime: Capsule().fill(MLColor.lime)
                    case .cream: Capsule().fill(MLColor.fillQuiet)
                    case .outline: Capsule().strokeBorder(MLColor.onHeroSecondary, lineWidth: 1.5)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// The black banner of the offline frames, with the wifi symbol and up to two lines.
struct StudentOfflineBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 17))
                .accessibilityHidden(true)
            Text(text)
                .font(StudentType.secondaryMedium)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(MLColor.onHero)
        .padding(.horizontal, MLSpacing.s16)
        .padding(.vertical, 6)
        .frame(minHeight: 48)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(MLColor.heroBackground))
    }
}

/// ScrollEdgeFade 164:57923: canvas colour behind the tab bar, so content fades out instead of running under it.
struct StudentScrollFade: View {
    var body: some View {
        VStack {
            Spacer()
            LinearGradient(stops: [.init(color: MLColor.canvas.opacity(0), location: 0),
                                   .init(color: MLColor.canvas, location: 0.37),
                                   .init(color: MLColor.canvas, location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 164)
        }
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A destination another Student part will build. It says so, and Back works.
struct StudentComingSoonView: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        NotImplementedView(title: title)
            .safeAreaInset(edge: .top, spacing: 0) {
                BackButton(action: onBack)
                    .padding(.horizontal, MLSpacing.s16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
    }
}

extension View {
    /// A pushed Student page. A page built on `MLScreen` keeps the system bar, so the back button and the swipe-back
    /// gesture work (docs/SWIFTUI_STANDARDS.md). A page that still draws its own back circle hides the bar.
    @ViewBuilder
    func studentPushedPage(usesSystemBar: Bool) -> some View {
        if usesSystemBar {
            self
        } else {
            self.toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        }
    }
}

extension View {
    /// A pinned primary action on a Student page: `MLScreen` pins it to the bottom safe area, and the Student tab bar
    /// floats over that area, so the action keeps the bar's height and gap clear.
    func studentAboveTabBar() -> some View {
        padding(.bottom, MLScreenMetrics.floatingTabBarHeight + MLSpacing.s8)
    }
}
