import SwiftUI

/// One horizontal bar split into parts (the answered split on Students, SA02). Each part's width is its share of the
/// sum; a part with a value of zero is not drawn. The numbers sit beside the bar, so the bar never carries meaning alone.
struct StackedBar: View {
    struct Part: Identifiable {
        let id: String
        let value: Int
        let color: Color
    }

    let parts: [Part]
    var height: CGFloat = 14
    var gap: CGFloat = 4

    private var visible: [Part] { parts.filter { $0.value > 0 } }
    private var total: Int { visible.reduce(0) { $0 + $1.value } }

    var body: some View {
        GeometryReader { proxy in
            let usable = max(proxy.size.width - gap * CGFloat(max(visible.count - 1, 0)), 0)
            HStack(spacing: gap) {
                ForEach(visible) { part in
                    Capsule()
                        .fill(part.color)
                        // A small part stays visible as a dot rather than vanishing.
                        .frame(width: max(height, usable * CGFloat(part.value) / CGFloat(max(total, 1))))
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
