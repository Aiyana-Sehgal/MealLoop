import SwiftUI

/// Live meal (2260:160216, 2260:160412). It shares Today's view model, so it never disagrees with Today.
/// A dish with no report says so: "OK" would claim a check nobody made.
struct AdminLiveMealView: View {
    @Environment(AppEnvironment.self) private var environment
    let model: AdminTodayViewModel
    let nav: AdminNav

    @State private var dishes: [Dish] = []
    @State private var usualByNow: Int?
    @State private var tellingVendorAbout: Shortage?

    private var timeZone: TimeZone { nav.timeZone }
    private var isTellingVendor: Binding<Bool> {
        Binding(get: { tellingVendorAbout != nil }, set: { if !$0 { tellingVendorAbout = nil } })
    }

    var body: some View {
        // Read here, not only in the sheet: a value read only inside the sheet closure is stale on first show.
        let telling = tellingVendorAbout
        let meal = model.state.value?.meal
        AdminPageScaffold(title: AdminCopy.pageTitle(mess: model.context.mess.name, meal: meal.map { MLFormat.mealSlot($0.meal.slot) } ?? ""),
                          subtitle: meal.map(subtitle), onBack: nav.pop) {
            AsyncContentView(state: model.state, timeZone: timeZone, retry: { await model.load() }) { content in
                if let meal = content.meal {
                    page(meal)
                } else {
                    EmptyStateView(title: AdminCopy.noData)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if meal?.status.state == .inService {
                AdminChip(text: AdminCopy.liveAction, style: .lime)
                    .padding(.top, 118)
                    .padding(.trailing, MLSpacing.margin)
            }
        }
        .task(id: meal?.meal.id) {
            guard let id = meal?.meal.id else { return }
            dishes = (try? await environment.repositories.meals.menu(for: id)) ?? []
            usualByNow = (try? await environment.repositories.adminMesses.liveReference(for: id))?.usualByNow
        }
        .mlSheet(isPresented: isTellingVendor) {
            if let telling {
                AdminTellVendorSheet(subtitle: AdminScreenCopy.preparedMessage,
                                     message: AdminCopy.vendorShortageMessage(dish: telling.dishName, level: MLFormat.shortageLevel(telling.level),
                                                                              mess: model.context.mess.name, name: nav.context.account.firstName),
                                     note: nil) { tellingVendorAbout = nil }
            }
        }
    }

    private func subtitle(_ meal: AdminMealContent) -> String {
        let hours = AdminCopy.mealHours(MLFormat.time(meal.meal.startsAt, in: timeZone), MLFormat.time(meal.meal.endsAt, in: timeZone))
        guard let asOf = meal.headcount.actualEntries.asOf else { return hours }
        return AdminCopy.updatedAt(hours, MLFormat.time(asOf, in: timeZone))
    }

    private func stageIndex(_ meal: AdminMealContent) -> Int {
        if meal.status.state != .notStarted { return 3 }
        switch meal.headcount.vendorAcknowledgmentStatus {
        case .notPublished: return 0
        case .pending: return 1
        case .acknowledged: return 2
        }
    }

    private func page(_ meal: AdminMealContent) -> some View {
        let reported = meal.shortages
        let quiet = dishes.filter { dish in !reported.contains { $0.dishName == dish.name } }
        return VStack(alignment: .leading, spacing: MLSpacing.s16) {
            AdminStageLine(stages: [AdminCopy.stepForecast, AdminCopy.stageSent, AdminCopy.stepVendor, AdminCopy.stageServing],
                           current: stageIndex(meal))
            hero(meal)
            AdminLabel(text: AdminCopy.foodLeft)
            ForEach(reported) { shortage in
                shortageCard(shortage)
            }
            VStack(spacing: 0) {
                ForEach(quiet) { dish in
                    foodRow(dish)
                }
            }
        }
    }

    private func hero(_ meal: AdminMealContent) -> some View {
        let reading = meal.headcount.actualEntries
        let expected = meal.headcount.sentToVendor.count ?? meal.headcount.approved.count ?? meal.forecastToApprove
        return HeroCard {
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                HeroEyebrow(label: AdminCopy.cameInSoFar, time: reading.asOf.map { MLFormat.time($0, in: timeZone) })
                HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                    Text(reading.value.map { String($0) } ?? AdminFormat.missing)
                        .font(AdminType.heroMetric)
                        .foregroundStyle(MLColor.onHero)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if let expected {
                        Text(AdminCopy.ofExpected(expected))
                            .font(MLType.staffBody)
                            .foregroundStyle(MLColor.onHeroSecondary)
                            .fixedSize()
                    }
                }
                if let value = reading.value, let expected, expected > 0 {
                    AdminLiveBar(value: value, expected: expected, usual: usualByNow)
                }
                Text(AdminCopy.notFinalCount)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.onHero)
            }
        }
    }

    private func shortageCard(_ shortage: Shortage) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            HStack(spacing: MLSpacing.s8) {
                AdminDishPictogram(dish: shortage.dishName)
                Text(shortage.dishName)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                Spacer()
                AdminChip(text: AdminCopy.levelChip(shortage.level), style: .lime)
            }
            Text(AdminCopy.reportedBy(MLFormat.roleName(shortage.reportedBy), MLFormat.time(shortage.reportedAt, in: timeZone), note: shortage.note))
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            InkActionButton(title: AdminScreenCopy.tellTheVendor) { tellingVendorAbout = shortage }
        }
        .padding(MLSpacing.s16)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        .overlay(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).stroke(MLColor.ink, lineWidth: 1.5))
    }

    private func foodRow(_ dish: Dish) -> some View {
        HStack(spacing: MLSpacing.s12) {
            AdminDishPictogram(dish: dish.name)
            Text(dish.name)
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.ink)
            Spacer()
            Text(AdminCopy.noReport)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .frame(minHeight: MLSize.staffButton)
        .overlay(alignment: .top) { Rectangle().fill(MLColor.border).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }
}

/// How far the count has come, with a tick at the usual count for this point of the meal.
struct AdminLiveBar: View {
    let value: Int
    let expected: Int
    let usual: Int?

    var body: some View {
        VStack(alignment: .trailing, spacing: MLSpacing.s4) {
            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(MLColor.onHeroSecondary.opacity(0.5))
                    Capsule().fill(MLColor.onHero).frame(width: width * min(CGFloat(value) / CGFloat(expected), 1))
                    if let usual {
                        Rectangle().fill(MLColor.lime).frame(width: 3)
                            .offset(x: width * min(CGFloat(usual) / CGFloat(expected), 1))
                    }
                }
            }
            .frame(height: 10)
            if let usual {
                Text(AdminCopy.usualByNow(usual))
                    .font(MLType.secondary)
                    .foregroundStyle(MLColor.onHeroSecondary)
            }
        }
    }
}
