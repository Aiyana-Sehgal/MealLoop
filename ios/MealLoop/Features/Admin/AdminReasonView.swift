import SwiftUI

/// A reason opened (A09): what it means, the foods or the evidence, and the meals behind the count.
struct AdminReasonScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let kind: ReasonKind
    let nav: AdminNav

    var body: some View {
        let results = environment.repositories.adminResults
        AdminLoadedPage(model: AdminPageModel { [kind] in try await results.reason(kind) }, timeZone: nav.timeZone) { detail, _ in
            AdminReasonBody(detail: detail, nav: nav)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct AdminReasonBody: View {
    let detail: AdminReasonDetail
    let nav: AdminNav
    @State private var isTellingVendor = false

    private var timeZone: TimeZone { nav.timeZone }
    private var isCantTell: Bool { detail.reason.tag == .cantTell }

    var body: some View {
        AdminPageScaffold(title: detail.reason.title, onBack: nav.pop) {
            HStack(spacing: MLSpacing.s8) {
                ReasonTagDot(tag: detail.reason.tag)
                Text("· \(AdminScreenCopy.reasonLine(detail.reason.meals))")
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            Text(detail.explanation)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            if let title = detail.foodsTitle {
                AdminLabel(text: title)
                foods
            }
            ForEach(detail.feedback) { line in
                feedback(line)
            }
            if !detail.missing.isEmpty {
                AdminLabel(text: AdminScreenCopy.missing)
                AdminFlow {
                    ForEach(detail.missing, id: \.self) { item in
                        AdminFactChip(text: AdminScreenCopy.evidence(item), isMissing: true)
                    }
                }
                InkActionButton(title: AdminScreenCopy.tellTheVendor) { isTellingVendor = true }
            }
            if let arrivals = detail.arrivals {
                AdminArrivalBars(shape: arrivals)
            }
            if detail.reason.kind == .raisedLate {
                raisedCards
            } else if !detail.timeline.isEmpty {
                timeline
            } else if !detail.meals.isEmpty {
                AdminLabel(text: AdminScreenCopy.theMeals(detail.reason.meals))
                ForEach(detail.meals) { meal in
                    AdminMealCard(meal: meal, timeZone: timeZone, showsEvidence: isCantTell || (meal.leftovers.isEmpty && meal.ranOut.isEmpty)) {
                        nav.push(.meal(meal.id))
                    }
                }
            }
            if detail.reason.kind == .moreCame, let line = moreCameLine {
                AdminLabel(text: line)
            }
            if detail.moreMeals > 0 {
                QuietRow(title: AdminScreenCopy.moreMeals(detail.moreMeals)) { nav.push(.findMeal) }
            }
        }
        .mlSheet(isPresented: $isTellingVendor) {
            AdminTellVendorSheet(subtitle: AdminScreenCopy.preparedMessage, message: vendorMessage, note: nil) { isTellingVendor = false }
        }
    }

    private var vendorMessage: String {
        guard let meal = detail.meals.first else { return "" }
        return AdminScreenCopy.vendorMessage(meal, today: AdminFormat.day(meal.day, in: timeZone), name: nav.context.account.firstName)
    }

    private var moreCameLine: String? {
        guard let meal = detail.meals.first, let came = meal.finalEntries, let sent = meal.headcountSent else { return nil }
        return AdminScreenCopy.moreThanSent(came: came, more: came - sent)
    }

    private var foods: some View {
        HStack(alignment: .top, spacing: MLSpacing.s8) {
            ForEach(detail.foods) { food in
                VStack(alignment: .leading, spacing: MLSpacing.s4) {
                    AdminDishPictogram(dish: food.dish, size: 36)
                    Text(food.dish)
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.ink)
                    Text(foodDetail(food))
                        .font(MLType.secondary)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                .padding(MLSpacing.s12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func foodDetail(_ food: ReasonFood) -> String {
        if let meals = food.meals { return AdminScreenCopy.inMeals(meals) }
        if let at = food.at, let mess = food.mess { return AdminScreenCopy.foodAt(time: MLFormat.time(at, in: timeZone), mess: mess) }
        return AdminFormat.missing
    }

    private func feedback(_ line: DishFeedbackLine) -> some View {
        AdminCard {
            HStack(spacing: MLSpacing.s12) {
                AdminDishPictogram(dish: line.dish)
                Text(line.dish)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
            }
            HStack(spacing: MLSpacing.s8) {
                AdminProblemIcon()
                Text(line.problem)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.ink)
                Spacer()
                Text(AdminScreenCopy.studentCount(line.students))
                    .font(MLType.body)
                    .foregroundStyle(MLColor.ink)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var raisedCards: some View {
        ForEach(detail.meals) { meal in
            Button {
                nav.push(.meal(meal.id))
            } label: {
                AdminCard {
                    Text(AdminFormat.mealLine(meal, in: timeZone))
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.ink)
                    if let change = meal.headcountChange {
                        HStack(alignment: .top, spacing: MLSpacing.s16) {
                            figure(AdminFormat.count(change.from), AdminScreenCopy.forecast)
                            figure(AdminFormat.count(change.to),
                                   AdminScreenCopy.raised(change.at.map { MLFormat.time($0, in: timeZone) } ?? AdminFormat.missing))
                            figure(AdminFormat.count(meal.finalEntries), AdminScreenCopy.came)
                        }
                        Text(AdminScreenCopy.reasonGiven(change.reason))
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                    if !meal.isClosed {
                        Text(AdminScreenCopy.notClosedYet)
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                    ForEach(meal.openQuestions, id: \.self) { question in
                        Text(AdminScreenCopy.notRecorded(question))
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func figure(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(MLColor.ink)
            Text(label)
                .font(MLType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            AdminCard {
                if let meal = detail.meals.first {
                    Text(AdminFormat.mealLine(meal, in: timeZone))
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.ink)
                }
                ForEach(detail.timeline) { line in
                    HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s12) {
                        Text(MLFormat.time(line.at, in: timeZone))
                            .font(MLType.monoBody)
                            .foregroundStyle(MLColor.ink)
                        Text(line.text)
                            .font(MLType.body)
                            .foregroundStyle(MLColor.ink)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            if let note = detail.timelineNote {
                AdminLabel(text: note)
            }
        }
    }
}

/// Bars for one meal's arrivals. The heights are relative: no count sits behind them, so none is shown.
struct AdminArrivalBars: View {
    let shape: ArrivalShape

    private let chartHeight: CGFloat = 150

    var body: some View {
        AdminCard {
            AdminLabel(text: AdminScreenCopy.entriesEvery15)
            let tallest = shape.barHeights.max() ?? 1
            HStack(alignment: .bottom, spacing: MLSpacing.s8) {
                ForEach(Array(shape.barHeights.enumerated()), id: \.offset) { index, height in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(index >= shape.markerAfterBar - 1 ? MLColor.ink : MLColor.inkSecondary)
                        .frame(height: chartHeight * CGFloat(height / tallest))
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .trailing) {
                            if index == shape.markerAfterBar - 1 {
                                Rectangle()
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                    .foregroundStyle(MLColor.ink)
                                    .frame(width: 1, height: chartHeight)
                                    .offset(x: MLSpacing.s4)
                                    .frame(maxHeight: .infinity, alignment: .bottom)
                            }
                        }
                }
            }
            .frame(height: chartHeight, alignment: .bottom)
            HStack {
                ForEach(Array(shape.axisLabels.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(MLType.monoSecondary)
                        .foregroundStyle(MLColor.inkSecondary)
                    if index < shape.axisLabels.count - 1 {
                        Spacer()
                    }
                }
            }
            Text(shape.markerText)
                .font(MLType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}
