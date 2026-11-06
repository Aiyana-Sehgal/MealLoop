import SwiftUI

/// One tab in the capsule tab bar.
struct CapsuleTabItem<Tab: Hashable>: Identifiable {
    let tab: Tab
    let title: String
    let symbol: String

    var id: Tab { tab }
}

/// The tab bar shared by every role: a white capsule whose selected tab sits on a quiet pill.
/// SF Symbols stand in for the drawn icons (design gap 386).
struct CapsuleTabBar<Tab: Hashable>: View {
    let items: [CapsuleTabItem<Tab>]
    @Binding var selection: Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    selection = item.tab
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 20, weight: .regular))
                        Text(item.title)
                            .font(MLType.meta)
                    }
                    .foregroundStyle(MLColor.ink)
                    .frame(maxWidth: .infinity, minHeight: MLSize.staffButton)
                    .background {
                        if selection == item.tab {
                            Capsule().fill(MLColor.fillQuiet)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == item.tab ? .isSelected : [])
            }
        }
        .padding(MLSpacing.s4)
        .background(Capsule().fill(MLColor.surface))
        .overlay(Capsule().stroke(MLColor.border, lineWidth: 1))
    }
}

/// The staff tab bar: Home, Alerts, Me.
struct StaffTabBar: View {
    @Binding var selection: StaffTab

    private let items = [
        CapsuleTabItem(tab: StaffTab.home, title: "Home", symbol: "house"),
        CapsuleTabItem(tab: StaffTab.alerts, title: "Alerts", symbol: "bell"),
        CapsuleTabItem(tab: StaffTab.me, title: "Me", symbol: "person.crop.circle"),
    ]

    var body: some View {
        CapsuleTabBar(items: items, selection: $selection)
    }
}
