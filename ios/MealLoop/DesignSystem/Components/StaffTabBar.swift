import SwiftUI

/// One tab in the glass tab bar. A nil symbol makes a text-only tab, as the Warden design has.
struct GlassTabItem<Tab: Hashable>: Identifiable {
    let tab: Tab
    let title: String
    var symbol: String?

    var id: Tab { tab }
}

/// The floating tab bar shared by every role: a glass capsule of tabs, with an optional round glass Search beside it.
/// Sizes come from TabBar 74:236 and TabSearchButton in design/audit/prototype_contract.md: 62 pt tall, 8 pt gap,
/// a 54 pt selected highlight. Search is one more value of `Tab`, so it is selected like a tab (Selected=Search).
struct GlassTabBar<Tab: Hashable>: View {
    let items: [GlassTabItem<Tab>]
    @Binding var selection: Tab
    /// The value Search selects. Nil for the roles whose design has no Search.
    var searchTab: Tab?

    private let height: CGFloat = 62
    private let highlightHeight: CGFloat = 54

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            HStack(spacing: 0) {
                ForEach(items) { item in
                    tabButton(item)
                }
            }
            .padding(.horizontal, MLSpacing.s4)
            .frame(height: height)
            .background(GlassBackground(shape: Capsule()))
            if let searchTab {
                searchButton(searchTab)
            }
        }
        // The tokens are light only, so the glass stays light even when the device is in Dark Mode.
        .environment(\.colorScheme, .light)
    }

    private func tabButton(_ item: GlassTabItem<Tab>) -> some View {
        let isSelected = selection == item.tab
        return Button {
            selection = item.tab
        } label: {
            VStack(spacing: 2) {
                if let symbol = item.symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .symbolVariant(isSelected ? .fill : .none)
                        // Symbols differ in height; a fixed row keeps every label on one baseline.
                        .frame(height: 24)
                        .accessibilityHidden(true)
                }
                Text(item.title)
                    .font(item.symbol == nil ? MLType.staffBody : MLType.meta)
                    .fontWeight(isSelected ? .semibold : nil)
                    .lineLimit(1)
                    .fixedSize()
            }
            .foregroundStyle(isSelected ? MLColor.ink : MLColor.inkSecondary)
            .padding(.horizontal, MLSpacing.s4)
            .frame(maxWidth: .infinity, minHeight: highlightHeight)
            .background {
                if isSelected {
                    Capsule().fill(MLColor.ink.opacity(0.08))
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func searchButton(_ tab: Tab) -> some View {
        let isSelected = selection == tab
        return Button {
            selection = tab
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                .foregroundStyle(MLColor.ink)
                .frame(width: highlightHeight, height: highlightHeight)
                .background {
                    if isSelected {
                        Circle().fill(MLColor.ink.opacity(0.08))
                    }
                }
                .frame(width: height, height: height)
                .background(GlassBackground(shape: Circle()))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Search")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// The glass of the tab bar: translucent, with a hairline edge and a soft shadow.
/// The white tint keeps ink labels readable over dark content, because glass on its own would go dark there.
private struct GlassBackground<S: InsettableShape>: View {
    let shape: S

    var body: some View {
        glass
            .overlay(shape.strokeBorder(MLColor.surface.opacity(0.7), lineWidth: 1))
            .overlay(shape.strokeBorder(MLColor.ink.opacity(0.07), lineWidth: 1))
            .shadow(color: MLColor.ink.opacity(0.1), radius: 12, y: 4)
    }

    @ViewBuilder
    private var glass: some View {
        if #available(iOS 26.0, *) {
            Color.clear.glassEffect(.regular.tint(MLColor.surface.opacity(0.7)), in: shape)
        } else {
            shape.fill(.regularMaterial).overlay(shape.fill(MLColor.surface.opacity(0.55)))
        }
    }
}

/// The staff tab bar: Home, Alerts, Me in one wide capsule. Staff designs have no Search.
struct StaffTabBar: View {
    @Binding var selection: StaffTab

    private let items = [
        GlassTabItem(tab: StaffTab.home, title: "Home", symbol: "house"),
        GlassTabItem(tab: StaffTab.alerts, title: "Alerts", symbol: "bell"),
        GlassTabItem(tab: StaffTab.me, title: "Me", symbol: "person.crop.circle"),
    ]

    var body: some View {
        GlassTabBar(items: items, selection: $selection)
    }
}
