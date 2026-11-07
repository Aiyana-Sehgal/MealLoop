import SwiftUI

/// The answer page (07): the meal's dishes above, the answer buttons below. Not sure is chosen here.
struct StudentAnswerView: View {
    let model: StudentHomeViewModel
    let mealID: MealID
    let onBack: () -> Void

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    BackButton(action: onBack)
                    if let card = model.card(id: mealID) {
                        ScreenTitleBlock(title: MLFormat.mealSlot(card.meal.slot), subtitle: subtitle(card))
                        dishes
                        MealAnswerButtons(state: model.answerState(for: card),
                                          attendingTitle: StudentCopy.imIn,
                                          lockedNote: StudentCopy.answersClosed(StudentFormat.shortTime(card.cutoff, in: model.timeZone))) { intention in
                            Task { await model.answer(intention, for: mealID) }
                        }
                        if let error = model.answerError {
                            FieldErrorText(text: error)
                        }
                        Text(StudentCopy.answerFooter)
                            .font(MLType.secondary)
                            .foregroundStyle(MLColor.inkSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, 120)
            }
        }
        .task { await model.loadMenu(for: mealID) }
    }

    private func subtitle(_ card: StudentMealCard) -> String {
        let range = MLFormat.timeRange(card.meal.startsAt, card.meal.endsAt, in: model.timeZone)
        guard card.isAnswerOpen else { return range }
        return StudentCopy.answerBy(range, time: StudentFormat.shortTime(card.cutoff, in: model.timeZone),
                                    left: MLFormat.elapsed(minutes: MLFormat.minutes(from: model.now, to: card.cutoff)))
    }

    private var dishes: some View {
        AsyncContentView(state: model.menu, emptyTitle: StudentCopy.menuUnavailable, timeZone: model.timeZone,
                         retry: { await model.loadMenu(for: mealID) }) { menu in
            DishSummary(menu: menu)
        }
    }
}

/// The highlighted dish on a black card, then up to three others as tiles (07).
private struct DishSummary: View {
    let menu: [Dish]

    private var highlight: Dish? { menu.first(where: \.isHighlight) }
    private var others: [Dish] { Array(menu.filter { !$0.isHighlight }.prefix(3)) }

    var body: some View {
        VStack(spacing: MLSpacing.s12) {
            if let highlight {
                HeroCard {
                    HStack(spacing: MLSpacing.s8) {
                        DietMark(diet: highlight.diet, color: MLColor.onHero)
                        HeroStatusChip(text: StudentCopy.highlight, style: .lime)
                    }
                    Text(highlight.name)
                        .font(MLType.heroTitle)
                        .foregroundStyle(MLColor.onHero)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, MLSpacing.s12)
                }
            }
            HStack(alignment: .top, spacing: MLSpacing.s12) {
                ForEach(others) { dish in
                    VStack(alignment: .leading, spacing: MLSpacing.s12) {
                        DietMark(diet: dish.diet, color: MLColor.ink)
                        Text(dish.name)
                            .font(MLType.bodyEmphasis)
                            .foregroundStyle(MLColor.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(MLSpacing.s12)
                    .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
                }
            }
        }
    }
}

/// The diet mark: a square with a dot, and a triangle for non-vegetarian. It is drawn in ink because no green token
/// exists yet, so the shape and the spoken label carry the meaning.
private struct DietMark: View {
    let diet: Diet
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .stroke(color, lineWidth: 1.5)
            .frame(width: 18, height: 18)
            .overlay {
                Image(systemName: diet == .veg ? "circle.fill" : "triangle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(color)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(diet == .veg ? StudentCopy.vegetarian : StudentCopy.nonVegetarian)
    }
}
