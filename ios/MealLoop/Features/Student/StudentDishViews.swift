import SwiftUI

/// Which pictogram a dish gets, by the keyword rule of DishPictogram 2129:2299.
enum StudentPictogram {
    private static let keywords: [(asset: String, words: [String])] = [
        ("student-dish-bread", ["dosa", "idli", "chapathi", "chappathi", "chappati", "paratha", "poori", "bhature", "idiyappam", "bread"]),
        ("student-dish-rice", ["rice", "pulao", "briyani"]),
        ("student-dish-paneer", ["paneer", "panneer"]),
        ("student-dish-curd", ["curd", "raita", "buttermilk", "ice cream"]),
    ]

    static func asset(for name: String) -> String {
        let lowered = name.lowercased()
        return keywords.first { $0.words.contains(where: lowered.contains) }?.asset ?? "student-dish-curry"
    }
}

/// The highlighted dish on a black tile, then the others in rows (DishTile 2132:2406): three across, or two across
/// when the row has fewer.
struct StudentDishGrid: View {
    let menu: [Dish]

    private var highlight: Dish? { menu.first(where: \.isHighlight) }
    private var others: [Dish] { menu.filter { !$0.isHighlight } }

    private var rows: [[Dish]] {
        guard others.count > 3 else { return others.isEmpty ? [] : [others] }
        return [Array(others.prefix(3)), Array(others.dropFirst(3))]
    }

    var body: some View {
        VStack(spacing: MLSpacing.s16) {
            if let highlight {
                HighlightTile(dish: highlight)
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .top, spacing: MLSpacing.s12) {
                    ForEach(row) { dish in
                        DishTile(dish: dish, isWide: row.count < 3)
                    }
                    if row.count == 1 {
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                    }
                }
            }
        }
    }
}

private struct HighlightTile: View {
    let dish: Dish
    @State private var showsInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                StudentDietMark(diet: dish.diet, onDark: true)
                Button { showsInfo.toggle() } label: {
                    HStack(spacing: 6) {
                        Text(StudentCopy.highlight).font(StudentType.tag)
                        Image(systemName: "info.circle").font(.system(size: 18))
                    }
                    .foregroundStyle(MLColor.onLime)
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(Capsule().fill(MLColor.lime))
                    .frame(height: MLSize.hit)
                }
                .buttonStyle(.plain)
                .accessibilityHint(StudentCopy.highlightInfo)
                Spacer(minLength: 0)
                StudentDishPicture(name: dish.name, size: 48, color: MLColor.onHero)
            }
            Spacer(minLength: 0)
            Text(showsInfo ? StudentCopy.highlightInfo : dish.name)
                .font(showsInfo ? StudentType.secondary : StudentType.heroTitle)
                .foregroundStyle(MLColor.onHero)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, MLSpacing.s12)
        .padding(.horizontal, MLSpacing.s20)
        .padding(.bottom, MLSpacing.s20)
        .frame(maxWidth: .infinity, minHeight: 129, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous).fill(MLColor.heroBackground))
    }
}

private struct DishTile: View {
    let dish: Dish
    let isWide: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                StudentDietMark(diet: dish.diet, onDark: false)
                Spacer(minLength: 0)
                StudentDishPicture(name: dish.name, size: isWide ? 40 : 32, color: MLColor.ink)
            }
            Spacer(minLength: MLSpacing.s4)
            Text(dish.name)
                .font(isWide ? StudentType.bodySemibold : StudentType.dishName)
                .foregroundStyle(MLColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, MLSpacing.s12)
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, minHeight: isWide ? 116 : 113, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.tileRadius, style: .continuous).fill(MLColor.surface))
        .overlay(RoundedRectangle(cornerRadius: StudentMetric.tileRadius, style: .continuous).strokeBorder(MLColor.border, lineWidth: 1))
    }
}

private struct StudentDishPicture: View {
    let name: String
    let size: CGFloat
    let color: Color

    var body: some View {
        Image(StudentPictogram.asset(for: name))
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// VegMark and NonVegMark, 20 pt (DietMark 2129:2198). The shape and the spoken label carry the meaning as well.
struct StudentDietMark: View {
    let diet: Diet
    let onDark: Bool

    private var asset: String {
        switch diet {
        case .veg: return onDark ? "student-diet-veg-dark" : "student-diet-veg"
        case .nonVeg: return "student-diet-nonveg"
        }
    }

    var body: some View {
        Image(asset)
            .resizable()
            .frame(width: 20, height: 20)
            .accessibilityLabel(diet == .veg ? StudentCopy.vegetarian : StudentCopy.nonVegetarian)
    }
}
