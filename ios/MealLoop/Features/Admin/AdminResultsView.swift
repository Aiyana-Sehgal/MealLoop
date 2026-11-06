import SwiftUI

/// Results (A07, A08, F01): reasons in plain words, and what is left to check.
struct AdminResultsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        let results = environment.repositories.adminResults
        AdminPageScaffold(title: AdminScreenCopy.results) {
            AdminLoadedPage(model: AdminPageModel { try await results.overview() }, timeZone: nav.timeZone) { overview, _ in
                AdminResultsBody(overview: overview, nav: nav)
            }
        }
    }
}

struct AdminResultsBody: View {
    let overview: AdminResultsOverview
    let nav: AdminNav
    @State private var segment: ResultSegment = .leftOver

    private var options: [SegmentedChoice<ResultSegment>.Option] {
        [.init(value: .leftOver, title: AdminScreenCopy.leftOver), .init(value: .ranOut, title: AdminScreenCopy.ranOut),
         .init(value: .toCheck, title: AdminScreenCopy.toCheck)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            Text(overview.periodTitle)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .padding(.top, -MLSpacing.s12)
            SegmentedChoice(options: options, selection: $segment)
            switch segment {
            case .leftOver: reasons(overview.leftOver, heading: AdminScreenCopy.foodLeftOverAt)
            case .ranOut: reasons(overview.ranOut, heading: AdminScreenCopy.foodRanOutAt)
            case .toCheck: toCheck
            }
        }
    }

    private func reasons(_ group: ResultGroup, heading: String) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                AdminLabel(text: heading)
                Text(AdminScreenCopy.mealsOf(group.meals, group.totalMeals))
                    .font(MLType.title2)
                    .foregroundStyle(MLColor.ink)
            }
            AdminLabel(text: AdminScreenCopy.why)
            if let lead = group.reasons.first {
                leadCard(lead)
            }
            VStack(spacing: 0) {
                ForEach(group.reasons.dropFirst()) { reason in
                    reasonRow(reason)
                }
            }
        }
    }

    private func leadCard(_ reason: ResultReason) -> some View {
        Button {
            nav.push(.reason(reason.kind))
        } label: {
            HeroCard {
                HStack(alignment: .center, spacing: MLSpacing.s16) {
                    VStack(spacing: 0) {
                        Text("\(reason.meals)")
                            .font(MLType.heroNumber)
                            .foregroundStyle(MLColor.lime)
                        Text(AdminScreenCopy.meals(reason.meals))
                            .font(MLType.secondary)
                            .foregroundStyle(MLColor.onHeroSecondary)
                    }
                    VStack(alignment: .leading, spacing: MLSpacing.s8) {
                        Text(reason.title)
                            .font(MLType.staffPrimary)
                            .foregroundStyle(MLColor.onHero)
                            .multilineTextAlignment(.leading)
                        ReasonTagOnHero(tag: reason.tag)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(spoken(reason))
    }

    private func spoken(_ reason: ResultReason) -> String {
        [reason.title, reason.detail, AdminScreenCopy.countMeals(reason.meals), AdminScreenCopy.tag(reason.tag)]
            .compactMap { $0 }.joined(separator: ", ")
    }

    private func reasonRow(_ reason: ResultReason) -> some View {
        Button {
            nav.push(.reason(reason.kind))
        } label: {
            HStack(spacing: MLSpacing.s12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(reason.meals)")
                        .font(MLType.title2)
                        .foregroundStyle(MLColor.ink)
                    Text(AdminScreenCopy.meals(reason.meals))
                        .font(MLType.meta)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                .frame(width: 56, alignment: .leading)
                VStack(alignment: .leading, spacing: MLSpacing.s4) {
                    Text(reason.title)
                        .font(MLType.staffBody)
                        .foregroundStyle(MLColor.ink)
                        .multilineTextAlignment(.leading)
                    if let detail = reason.detail {
                        Text(detail)
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                }
                Spacer(minLength: MLSpacing.s8)
                ReasonTagText(tag: reason.tag)
            }
            .padding(.vertical, MLSpacing.s12)
            .frame(minHeight: MLSize.staffButton)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(spoken(reason))
        .overlay(alignment: .top) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
    }

    private var toCheck: some View {
        VStack(alignment: .leading, spacing: 0) {
            AdminLabel(text: AdminScreenCopy.reviewTheseMeals(overview.toReview.count))
            ForEach(overview.toReview) { row in
                AdminRow(title: "\(AdminFormat.weekday(row.meal.day, in: nav.timeZone).prefix(3)) \(MLFormat.mealSlot(row.meal.slot).lowercased()) · \(row.meal.mess)",
                         detail: AdminScreenCopy.reviewDetail(row.meal), action: { nav.push(.meal(row.id)) }) {
                    StatusText(text: AdminScreenCopy.review, dot: .empty)
                }
            }
            AdminLabel(text: AdminScreenCopy.changesBeingTested(overview.changes.count))
                .padding(.top, MLSpacing.s16)
            ForEach(overview.changes) { check in
                AdminRow(title: check.listTitle, detail: changeDetail(check), action: { nav.push(.check(check.id)) }) {
                    StatusText(text: AdminScreenCopy.stage(check.stage), dot: check.stage == .open ? .empty : .filled)
                }
            }
            VStack(spacing: 0) {
                QuietRow(title: AdminScreenCopy.weeklyReport) { nav.push(.weeklyReport) }
                QuietRow(title: AdminScreenCopy.findOlderMeal) { nav.push(.findMeal) }
                QuietRow(title: AdminScreenCopy.safetyCases) { nav.push(.safetyCases) }
            }
            .padding(.top, MLSpacing.s16)
        }
    }

    private func changeDetail(_ check: CheckNextTime) -> String {
        guard check.stage == .testing else { return AdminScreenCopy.owner(check.owner) }
        let counted = CheckNextTimePolicy.countedMeals(check)
        return "\(check.mess) · \(AdminScreenCopy.checked(counted, CheckNextTimePolicy.requiredMeals))"
    }
}

/// A meal on a white card: where and when, sent to came, and what the records say.
struct AdminMealCard: View {
    let meal: AdminMealFacts
    let timeZone: TimeZone
    var showsEvidence: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AdminCard {
                HStack(alignment: .firstTextBaseline) {
                    Text(AdminFormat.mealLine(meal, in: timeZone))
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.ink)
                    Spacer(minLength: MLSpacing.s8)
                    Text(AdminFormat.sentToCame(meal))
                        .font(MLType.monoBody)
                        .foregroundStyle(MLColor.ink)
                }
                AdminFlow {
                    ForEach(meal.leftovers) { food in
                        AdminFactChip(text: "\(food.dish) \(AdminFormat.amount(food))")
                    }
                    ForEach(meal.ranOut) { food in
                        AdminFactChip(text: AdminScreenCopy.ranOutAt(food.dish, food.at.map { MLFormat.time($0, in: timeZone) } ?? AdminFormat.missing))
                    }
                    if showsEvidence {
                        ForEach(meal.missing, id: \.self) { item in
                            AdminFactChip(text: AdminScreenCopy.evidenceOnCard(item), isMissing: true)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
