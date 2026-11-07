import SwiftUI

/// Orbit background, Back, title and a scrolling body, as on every Admin page. The tab bar stays over it.
struct AdminPageScaffold<Content: View>: View {
    let title: String
    var subtitle: String?
    var onBack: (() -> Void)?
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    if let onBack {
                        BackButton(action: onBack)
                    } else {
                        Color.clear.frame(height: MLSize.hit)
                    }
                    VStack(alignment: .leading, spacing: MLSpacing.s4) {
                        Text(title)
                            .font(MLType.largeTitle)
                            .foregroundStyle(MLColor.ink)
                            .accessibilityAddTraits(.isHeader)
                        if let subtitle {
                            Text(subtitle)
                                .font(MLType.body)
                                .foregroundStyle(MLColor.inkSecondary)
                        }
                    }
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, AdminLayout.scrollBottomInset)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

enum AdminLayout {
    /// Clears the floating tab bar (62 pt, 8 pt gap, a little air).
    static let scrollBottomInset: CGFloat = 120
    static let tabBarClearance: CGFloat = 86
}

/// Wraps its children like text, for chips.
struct AdminFlow: Layout {
    var spacing: CGFloat = MLSpacing.s8

    private func rows(_ subviews: Subviews, width: CGFloat) -> [[(index: Int, size: CGSize)]] {
        var rows: [[(index: Int, size: CGSize)]] = [[]]
        var used: CGFloat = 0
        for (index, view) in subviews.enumerated() {
            let size = view.sizeThatFits(.unspecified)
            if used + size.width > width, !(rows.last?.isEmpty ?? true) {
                rows.append([])
                used = 0
            }
            rows[rows.count - 1].append((index, size))
            used += size.width + spacing
        }
        return rows
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let all = rows(subviews, width: width)
        let height = all.reduce(0) { $0 + ($1.map(\.size.height).max() ?? 0) } + spacing * CGFloat(max(all.count - 1, 0))
        let widest = all.map { row in row.reduce(0) { $0 + $1.size.width } + spacing * CGFloat(max(row.count - 1, 0)) }.max() ?? 0
        return CGSize(width: proposal.width ?? widest, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(subviews, width: bounds.width) {
            var x = bounds.minX
            let height = row.map(\.size.height).max() ?? 0
            for item in row {
                subviews[item.index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += height + spacing
        }
    }
}

/// A fact on a card, not a control. Dashed means the fact is missing.
struct AdminFactChip: View {
    let text: String
    var isMissing: Bool = false

    var body: some View {
        Text(text)
            .font(MLType.body)
            .foregroundStyle(MLColor.ink)
            .padding(.horizontal, MLSpacing.s12)
            .padding(.vertical, MLSpacing.s8)
            .background {
                if isMissing {
                    Capsule().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                } else {
                    Capsule().stroke(MLColor.ink, lineWidth: 1)
                }
            }
    }
}

/// A white rounded card.
struct AdminCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            content
        }
        .padding(MLSpacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
    }
}

/// The small grey label above a block.
struct AdminLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(MLType.body)
            .foregroundStyle(MLColor.inkSecondary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Status as a dot and plain words. Sure is filled, Probably is a ring and Can't tell is dashed.
struct ReasonTagText: View {
    let tag: ReasonTag

    private var dot: StatusText.Dot {
        switch tag {
        case .sure: return .filled
        case .probably: return .empty
        case .cantTell: return .dashed
        }
    }

    var body: some View {
        StatusText(text: AdminScreenCopy.tag(tag), dot: dot)
    }
}

/// The same tag on a black card, where lime can be the dot.
struct ReasonTagOnHero: View {
    let tag: ReasonTag

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            Circle().fill(MLColor.lime).frame(width: MLSize.statusDot, height: MLSize.statusDot)
            Text(AdminScreenCopy.tag(tag))
                .font(MLType.body)
                .foregroundStyle(MLColor.onHeroSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Title, detail and a trailing view in one tappable row with a hairline.
struct AdminRow<Trailing: View>: View {
    let title: String
    var detail: String?
    var showsChevron: Bool = true
    let action: (() -> Void)?
    @ViewBuilder let trailing: Trailing

    private var label: some View {
        HStack(spacing: MLSpacing.s12) {
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text(title)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                if let detail {
                    Text(detail)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
            }
            Spacer(minLength: MLSpacing.s8)
            trailing
            if showsChevron, action != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MLColor.inkSecondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, MLSpacing.s12)
        .frame(minHeight: MLSize.staffButton)
        .contentShape(Rectangle())
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) { label }
                    .buttonStyle(.plain)
            } else {
                label.accessibilityElement(children: .combine)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
    }
}

/// Stops along a line, as on Check next time and the Community issue.
struct AdminStageLine: View {
    let stages: [String]
    /// Zero-based. Stops before it are done, it is lime, the rest are dashed.
    let current: Int

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                VStack(spacing: MLSpacing.s8) {
                    marker(index)
                        .frame(height: 28)
                    Text(stage)
                        .font(index == current ? MLType.bodyEmphasis : MLType.body)
                        .foregroundStyle(index == current ? MLColor.ink : MLColor.inkSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(alignment: .top) {
            GeometryReader { proxy in
                let inset = proxy.size.width / CGFloat(max(stages.count, 1) * 2)
                let width = proxy.size.width - inset * 2
                let reached = width * CGFloat(current) / CGFloat(max(stages.count - 1, 1))
                ZStack(alignment: .leading) {
                    Rectangle().fill(MLColor.track).frame(width: width, height: 3)
                    Rectangle().fill(MLColor.ink).frame(width: reached, height: 3)
                }
                .padding(.leading, inset)
                .frame(height: 28)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stages.indices.contains(current) ? stages[current] : "")
    }

    @ViewBuilder
    private func marker(_ index: Int) -> some View {
        if index < current {
            Circle().fill(MLColor.ink).frame(width: 14, height: 14)
        } else if index == current {
            Circle().fill(MLColor.lime).overlay(Circle().stroke(MLColor.ink, lineWidth: 1.5)).frame(width: 26, height: 26)
        } else {
            Circle().fill(MLColor.canvas)
                .overlay(Circle().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
                .frame(width: 22, height: 22)
        }
    }
}

/// A quiet note that says what did not happen. Never a toast, which would disappear.
struct AdminNote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(MLType.secondary)
            .foregroundStyle(MLColor.inkSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A rounded text field with a dark outline.
struct AdminTextField: View {
    let placeholder: String
    @Binding var text: String
    var lines: Int = 1

    var body: some View {
        TextField(placeholder, text: $text, axis: lines > 1 ? .vertical : .horizontal)
            .lineLimit(lines > 1 ? lines...(lines + 3) : 1...1)
            .font(MLType.staffBody)
            .foregroundStyle(MLColor.ink)
            .padding(MLSpacing.s16)
            .frame(minHeight: MLSize.button)
            .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
            .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).stroke(MLColor.ink, lineWidth: 1))
    }
}

/// How Admin writes values. Missing values stay "—".
enum AdminFormat {
    static let missing = "—"

    private static func formatter(_ pattern: String, _ timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter
    }

    /// "Wed 14"
    static func shortDay(_ date: Date, in timeZone: TimeZone) -> String { formatter("EEE d", timeZone).string(from: date) }
    /// "Wed 14 Aug"
    static func day(_ date: Date, in timeZone: TimeZone) -> String { formatter("EEE d MMM", timeZone).string(from: date) }
    /// "Thu"
    static func weekday(_ date: Date, in timeZone: TimeZone) -> String { formatter("EEEE", timeZone).string(from: date) }

    /// "2,870"
    static func count(_ value: Int?) -> String {
        guard let value else { return missing }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// "4", "4.5"
    static func number(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }

    static func unit(_ unit: WasteUnit) -> String {
        switch unit {
        case .kilograms: return "kg"
        case .litres: return "L"
        case .pieces: return "pieces"
        }
    }

    /// "4 L", or "—" when nothing was recorded.
    static func amount(_ food: FoodAmount) -> String {
        guard let amount = food.amount else { return missing }
        return "\(number(amount)) \(unit(food.unit))"
    }

    /// "Wed 14 · lunch · Main"
    static func mealLine(_ meal: AdminMealFacts, in timeZone: TimeZone) -> String {
        "\(shortDay(meal.day, in: timeZone)) · \(MLFormat.mealSlot(meal.slot).lowercased()) · \(meal.mess)"
    }

    /// "860 → 786", with a dash for a count that does not exist.
    static func sentToCame(_ meal: AdminMealFacts) -> String {
        "\(count(meal.headcountSent)) → \(count(meal.finalEntries))"
    }
}
