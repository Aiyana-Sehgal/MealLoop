import SwiftUI

/// The pure rules `MLScreen` follows, kept apart so tests can check them.
enum MLScreenMetrics {
    /// The floating tab bar: `GlassTabBar` and `StaffTabBar` are 62 pt tall and sit 8 pt above the home indicator.
    static let floatingTabBarHeight: CGFloat = 62
    /// What a screen keeps clear under its content when the floating tab bar covers the bottom edge:
    /// the bar, its 8 pt gap and 16 pt of air (the same 86 pt the Admin pages use).
    static let tabBarClearance: CGFloat = floatingTabBarHeight + MLSpacing.s8 + MLSpacing.s16

    /// The large title has collapsed into the inline title once its bottom edge has scrolled under the bar,
    /// as an iOS large title does. `titleBottom` is the distance from the top of the content to the bottom of the
    /// large title; 0 means it has not been measured yet, and nothing collapses before that.
    static func isTitleCollapsed(scrollOffset: CGFloat, titleBottom: CGFloat) -> Bool {
        guard titleBottom > 0 else { return false }
        return scrollOffset >= titleBottom
    }

    /// The primary action is pinned to the bottom safe area, except at the accessibility text sizes, where a pinned
    /// bar would cover most of the screen; there it follows the content and scrolls with it.
    static func pinsBottomBar(isAccessibilitySize: Bool) -> Bool {
        !isAccessibilitySize
    }

    /// The pinned bottom bar gets a solid canvas only while content runs on underneath it,
    /// so the Orbit rings stay visible when everything fits.
    static func isContentUnderBottomBar(contentBottom: CGFloat, visibleBottom: CGFloat) -> Bool {
        contentBottom > visibleBottom + 1
    }
}

/// What `MLScreen` keeps clear at the bottom edge.
enum MLScreenBottomClearance: Equatable {
    /// Nothing beyond the safe area (a pushed screen with no tab bar, or one with a pinned action).
    case none
    /// The floating tab bar of a role root.
    case tabBar
}

/// How `MLScreen` follows the scroll offset. `.automatic` uses `onScrollGeometryChange` on iOS 18 and later and the
/// preference-key reader on iOS 17. `.legacy` forces the iOS 17 reader, so the gallery can check it on a newer simulator.
enum MLScreenScrollTracking: Equatable {
    case automatic
    case legacy
}

/// Where `MLScreen` puts its title and content when they are shorter than the screen.
enum MLScreenPlacement: Equatable {
    /// Directly under the bar, the usual place for a list or a detail screen.
    case top
    /// The header stays at the top; the space left over goes one part above the title and two parts below the
    /// content, so a short form sits in the upper middle instead of leaving an empty band above the pinned action
    /// (Staff sign in). The gaps shrink to nothing when the content or the keyboard needs the room.
    case upperMiddle

    /// The share of the leftover height above the title and below the content.
    var leftoverShares: (above: CGFloat, below: CGFloat) {
        switch self {
        case .top: (0, 1)
        case .upperMiddle: (1, 2)
        }
    }
}

/// The standard screen container (docs/SWIFTUI_STANDARDS.md):
/// - the Orbit background behind a `ScrollView`;
/// - native navigation: the system back button (a glass circle on iOS 26, chevron only on iOS 17 and 18), so the
///   interactive swipe-back keeps working; never hide it on a pushed screen;
/// - a large title in the app type that collapses into the inline title in the bar as it scrolls under it;
/// - optional trailing toolbar content;
/// - a pinned bottom bar for the primary action (`.safeAreaInset`), which rides above the keyboard,
///   or clearance for the floating tab bar;
/// - `.scrollDismissesKeyboard(.interactively)`.
///
/// Adoption is opt-in per screen. Example:
/// ```
/// MLScreen("Meal report", subtitle: "Lunch · Wed 14 Aug") {
///     rows
/// } bottom: {
///     InkActionButton(title: "Send") { … }
/// }
/// ```
struct MLScreen<Header: View, Trailing: View, Bottom: View, Content: View>: View {
    private let title: String?
    private let subtitle: String?
    private let showsNavigationBar: Bool
    private let fillsViewport: Bool
    private let placement: MLScreenPlacement
    private let bottomClearance: MLScreenBottomClearance
    private let scrollTracking: MLScreenScrollTracking
    private let header: Header
    private let trailing: Trailing
    private let bottom: Bottom
    private let content: Content

    @State private var scrollOffset: CGFloat = 0
    @State private var titleBottom: CGFloat = 0
    @State private var isContentUnderBottomBar = false
    /// The view a focused field asked to keep visible (`mlKeepsVisible`). Scrolled to again when the keyboard
    /// changes the visible height.
    @State private var scrollTarget: AnyHashable?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static var contentSpace: String { "MLScreen.content" }
    private static var viewportSpace: String { "MLScreen.viewport" }

    /// - Parameters:
    ///   - title: the large title. Nil for a screen without one (Welcome); then no inline title shows either.
    ///   - subtitle: one secondary line under the title.
    ///   - showsNavigationBar: false only on a stack root that has no bar in the design (Welcome). A pushed screen
    ///     keeps the bar, because the system back button and the swipe-back gesture live there.
    ///   - fillsViewport: the content is at least as tall as the visible area, so it can place a block in the
    ///     middle (Welcome's brand) and still scroll at large text sizes.
    ///   - placement: `.upperMiddle` for a short form; it implies `fillsViewport`.
    ///   - bottomClearance: `.tabBar` on a role root under the floating tab bar.
    ///   - header: drawn above the large title (a brand row, an eyebrow).
    ///   - trailing: the bar's trailing items.
    ///   - bottom: the pinned primary action. It sits on the bottom safe area and above the keyboard.
    init(
        _ title: String?,
        subtitle: String? = nil,
        showsNavigationBar: Bool = true,
        fillsViewport: Bool = false,
        placement: MLScreenPlacement = .top,
        bottomClearance: MLScreenBottomClearance = .none,
        scrollTracking: MLScreenScrollTracking = .automatic,
        @ViewBuilder header: () -> Header,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content,
        @ViewBuilder bottom: () -> Bottom
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsNavigationBar = showsNavigationBar
        self.fillsViewport = fillsViewport || placement == .upperMiddle
        self.placement = placement
        self.bottomClearance = bottomClearance
        self.scrollTracking = scrollTracking
        self.header = header()
        self.trailing = trailing()
        self.content = content()
        self.bottom = bottom()
    }

    private var isTitleCollapsed: Bool {
        title != nil && MLScreenMetrics.isTitleCollapsed(scrollOffset: scrollOffset, titleBottom: titleBottom)
    }

    private var hasBottomBar: Bool { Bottom.self != EmptyView.self }
    /// At the accessibility text sizes the actions would cover most of the screen if pinned, so they scroll with
    /// the content instead, after it (`MLScreenMetrics.pinsBottomBar`).
    private var pinsBottomBar: Bool {
        hasBottomBar && MLScreenMetrics.pinsBottomBar(isAccessibilitySize: dynamicTypeSize.isAccessibilitySize)
    }
    private var hasTrailing: Bool { Trailing.self != EmptyView.self }

    var body: some View {
        chrome(scrollArea)
    }

    private var scrollArea: some View {
        GeometryReader { viewport in
            scrollView(viewportHeight: viewport.size.height)
        }
        .coordinateSpace(.named(Self.viewportSpace))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if pinsBottomBar {
                bottomBar
            }
        }
        .background { OrbitBackground() }
    }

    private func scrollView(viewportHeight: CGFloat) -> some View {
        ScrollViewReader { proxy in
            trackedScrollView(viewportHeight: viewportHeight)
                .onChange(of: scrollTarget) { _, target in
                    scroll(proxy, to: target)
                }
                .onChange(of: viewportHeight) { _, _ in
                    scroll(proxy, to: scrollTarget)
                }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy, to target: AnyHashable?) {
        guard let target else { return }
        MLMotion.animate(.smooth, reduceMotion: reduceMotion) {
            proxy.scrollTo(target, anchor: .center)
        }
    }

    private func trackedScrollView(viewportHeight: CGFloat) -> some View {
        ScrollView {
            stack(viewportHeight: viewportHeight)
                .environment(\.mlScrollTargetAction, MLScrollTargetAction { scrollTarget = $0 })
        }
        .modifier(ModernScrollReader(enabled: scrollTracking == .automatic) { offset, overflow in
            updateScroll(offset: offset, contentUnderBar: overflow)
        })
        .onPreferenceChange(LegacyScrollKey.self) { frame in
            guard usesLegacyReader else { return }
            updateScroll(offset: -frame.minY, contentUnderBar: MLScreenMetrics.isContentUnderBottomBar(
                contentBottom: frame.maxY, visibleBottom: viewportHeight))
        }
        // Always bounces, as an iOS scroll view does, so a drag can pull the keyboard away even when the form fits.
        .scrollDismissesKeyboard(.interactively)
    }

    private func stack(viewportHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBlock
            leftover(share: placement.leftoverShares.above)
            titleBlock
            content
                .frame(maxWidth: .infinity, maxHeight: fillsViewport && placement == .top ? .infinity : nil,
                       alignment: .topLeading)
            leftover(share: placement.leftoverShares.below)
            if hasBottomBar && !pinsBottomBar {
                VStack(spacing: MLSpacing.s12) {
                    bottom
                }
                .frame(maxWidth: .infinity)
                .padding(.top, MLSpacing.s24)
            }
        }
        .padding(.horizontal, MLSpacing.margin)
        .padding(.top, title == nil ? 0 : MLSpacing.s8)
        .padding(.bottom, bottomPadding)
        .frame(maxWidth: .infinity, minHeight: fillsViewport ? viewportHeight : nil, alignment: .top)
        .coordinateSpace(.named(Self.contentSpace))
        .background(legacyReader)
    }

    /// The bar: native back button, inline title once collapsed, trailing items.
    private func chrome<V: View>(_ view: V) -> some View {
        view
            .navigationTitle(title ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarRole(.editor)
            .toolbar(showsNavigationBar ? .automatic : .hidden, for: .navigationBar)
            .toolbar { toolbarContent }
            .toolbarBackground(MLColor.canvas, for: .navigationBar)
            .toolbarBackground(isTitleCollapsed ? .visible : .hidden, for: .navigationBar)
            .tint(MLColor.ink)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            inlineTitle
        }
        if hasTrailing {
            ToolbarItem(placement: .topBarTrailing) {
                trailing
            }
        }
    }

    @ViewBuilder
    private var inlineTitle: some View {
        if let title {
            Text(title)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
                .lineLimit(1)
                .opacity(isTitleCollapsed ? 1 : 0)
                // The large title is read while it is visible; the inline one only once it has taken over.
                .accessibilityHidden(!isTitleCollapsed)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var usesLegacyReader: Bool {
        if scrollTracking == .legacy { return true }
        if #available(iOS 18, *) { return false }
        return true
    }

    private var bottomPadding: CGFloat {
        switch bottomClearance {
        case .none: pinsBottomBar ? MLSpacing.s16 : MLSpacing.s32
        case .tabBar: MLScreenMetrics.tabBarClearance
        }
    }

    /// A share of the height left over when `fillsViewport` makes the stack taller than its content.
    /// Equal flexible frames split the leftover equally, so `share` of them gives a weighted gap.
    @ViewBuilder
    private func leftover(share: CGFloat) -> some View {
        if fillsViewport && placement != .top {
            ForEach(0..<Int(share), id: \.self) { _ in
                Color.clear.frame(minHeight: 0, maxHeight: .infinity).accessibilityHidden(true)
            }
        }
    }

    @ViewBuilder
    private var headerBlock: some View {
        if Header.self != EmptyView.self {
            header
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, MLSpacing.s16)
        }
    }

    @ViewBuilder
    private var titleBlock: some View {
        if title != nil {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                if let title {
                    VStack(alignment: .leading, spacing: MLSpacing.s4) {
                        Text(title)
                            .mlFont(.largeTitle)
                            .foregroundStyle(MLColor.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHidden(isTitleCollapsed)
                            .onGeometryChange(for: CGFloat.self) { proxy in
                                proxy.frame(in: .named(Self.contentSpace)).maxY
                            } action: { bottom in
                                titleBottom = bottom
                            }
                        if let subtitle {
                            Text(subtitle)
                                .mlFont(.body)
                                .foregroundStyle(MLColor.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, MLSpacing.s24)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: MLSpacing.s12) {
            bottom
        }
        .padding(.horizontal, MLSpacing.margin)
        .padding(.top, MLSpacing.s12)
        .padding(.bottom, MLSpacing.s8)
        .frame(maxWidth: .infinity)
        .background {
            if isContentUnderBottomBar {
                VStack(spacing: 0) {
                    Rectangle().fill(MLColor.border).frame(height: 1)
                    MLColor.canvas
                }
                .ignoresSafeArea(edges: .bottom)
                .mlTransition(.fade)
            }
        }
        .mlAnimation(.crossFade, value: isContentUnderBottomBar)
    }

    /// The iOS 17 reader: the content's frame in the viewport, published through a preference key.
    @ViewBuilder
    private var legacyReader: some View {
        if usesLegacyReader {
            GeometryReader { proxy in
                Color.clear.preference(key: LegacyScrollKey.self, value: proxy.frame(in: .named(Self.viewportSpace)))
            }
        }
    }

    private func updateScroll(offset: CGFloat, contentUnderBar: Bool) {
        if scrollOffset != offset { scrollOffset = offset }
        if isContentUnderBottomBar != contentUnderBar { isContentUnderBottomBar = contentUnderBar }
    }
}

// MARK: - Shorter initialisers

extension MLScreen where Header == EmptyView, Trailing == EmptyView, Bottom == EmptyView {
    init(
        _ title: String?,
        subtitle: String? = nil,
        showsNavigationBar: Bool = true,
        fillsViewport: Bool = false,
        bottomClearance: MLScreenBottomClearance = .none,
        scrollTracking: MLScreenScrollTracking = .automatic,
        @ViewBuilder content: () -> Content
    ) {
        self.init(title, subtitle: subtitle, showsNavigationBar: showsNavigationBar, fillsViewport: fillsViewport,
                  bottomClearance: bottomClearance, scrollTracking: scrollTracking,
                  header: { EmptyView() }, trailing: { EmptyView() }, content: content, bottom: { EmptyView() })
    }
}

extension MLScreen where Header == EmptyView, Trailing == EmptyView {
    init(
        _ title: String?,
        subtitle: String? = nil,
        showsNavigationBar: Bool = true,
        fillsViewport: Bool = false,
        scrollTracking: MLScreenScrollTracking = .automatic,
        @ViewBuilder content: () -> Content,
        @ViewBuilder bottom: () -> Bottom
    ) {
        self.init(title, subtitle: subtitle, showsNavigationBar: showsNavigationBar, fillsViewport: fillsViewport,
                  scrollTracking: scrollTracking,
                  header: { EmptyView() }, trailing: { EmptyView() }, content: content, bottom: bottom)
    }
}

extension MLScreen where Header == EmptyView, Bottom == EmptyView {
    init(
        _ title: String?,
        subtitle: String? = nil,
        bottomClearance: MLScreenBottomClearance = .none,
        scrollTracking: MLScreenScrollTracking = .automatic,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.init(title, subtitle: subtitle, bottomClearance: bottomClearance, scrollTracking: scrollTracking,
                  header: { EmptyView() }, trailing: trailing, content: content, bottom: { EmptyView() })
    }
}

extension MLScreen where Header == EmptyView {
    init(
        _ title: String?,
        subtitle: String? = nil,
        scrollTracking: MLScreenScrollTracking = .automatic,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content,
        @ViewBuilder bottom: () -> Bottom
    ) {
        self.init(title, subtitle: subtitle, scrollTracking: scrollTracking,
                  header: { EmptyView() }, trailing: trailing, content: content, bottom: bottom)
    }
}

// MARK: - Scroll readers

private struct LegacyScrollKey: PreferenceKey {
    static let defaultValue: CGRect = .zero

    /// Only one view publishes it; siblings that do not publish it pass the default, which must not win.
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

/// The scroll offset and whether content runs under the bottom bar, from `onScrollGeometryChange` (iOS 18 and later).
private struct ModernScrollReader: ViewModifier {
    let enabled: Bool
    let onChange: (CGFloat, Bool) -> Void

    private struct Snapshot: Equatable {
        var offset: CGFloat
        var contentUnderBar: Bool
    }

    func body(content: Content) -> some View {
        if #available(iOS 18, *), enabled {
            content.onScrollGeometryChange(for: Snapshot.self) { geometry in
                // 0 at rest. `containerSize` is already the area inside the bars and the bottom inset.
                let offset = geometry.contentOffset.y + geometry.contentInsets.top
                let visibleBottom = offset + geometry.containerSize.height
                return Snapshot(offset: offset, contentUnderBar: MLScreenMetrics.isContentUnderBottomBar(
                    contentBottom: geometry.contentSize.height, visibleBottom: visibleBottom))
            } action: { _, snapshot in
                onChange(snapshot.offset, snapshot.contentUnderBar)
            }
        } else {
            content
        }
    }
}

// MARK: - Keeping a focused field visible

/// Asks the enclosing `MLScreen` to scroll a view into the visible area, above the pinned bar and the keyboard.
struct MLScrollTargetAction {
    fileprivate let action: (AnyHashable) -> Void

    func callAsFunction(_ id: AnyHashable) {
        action(id)
    }
}

private struct MLScrollTargetActionKey: EnvironmentKey {
    static let defaultValue: MLScrollTargetAction? = nil
}

extension EnvironmentValues {
    var mlScrollTargetAction: MLScrollTargetAction? {
        get { self[MLScrollTargetActionKey.self] }
        set { self[MLScrollTargetActionKey.self] = newValue }
    }
}

private struct MLKeepsVisibleModifier<ID: Hashable>: ViewModifier {
    let id: ID
    let isActive: Bool
    @Environment(\.mlScrollTargetAction) private var scrollTo

    func body(content: Content) -> some View {
        content
            .id(id)
            .onChange(of: isActive) { _, active in
                if active { scrollTo?(AnyHashable(id)) }
            }
    }
}

extension View {
    /// Inside an `MLScreen`: while `isActive` (usually "this field has focus"), keep this view in the visible area,
    /// above the pinned bottom bar and the keyboard. Outside an `MLScreen` it only sets the id.
    func mlKeepsVisible<ID: Hashable>(id: ID, when isActive: Bool) -> some View {
        modifier(MLKeepsVisibleModifier(id: id, isActive: isActive))
    }
}
