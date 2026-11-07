import SwiftUI

/// Find a meal: one mess and one meal slot at a time.
@MainActor
@Observable
final class AdminFindMealViewModel {
    private(set) var state: LoadState<[AdminMealFacts]> = .idle
    private(set) var messes: [String] = []
    /// Nil means every mess.
    private(set) var mess: String?
    private(set) var slot: MealSlot = .lunch

    private let results: any AdminResultsRepository

    init(defaultMess: String?, results: any AdminResultsRepository) {
        self.mess = defaultMess
        self.results = results
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            messes = try await results.messNames()
            let meals = try await results.findMeals(mess: mess, slot: slot)
            state = meals.isEmpty ? .empty : .loaded(meals)
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    func select(mess: String?) async {
        self.mess = mess
        await load()
    }

    func select(slot: MealSlot) async {
        self.slot = slot
        await load()
    }
}

struct AdminFindMealScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        // The mess name without "Mess", as the chips write it.
        AdminFindMealView(model: AdminFindMealViewModel(defaultMess: nav.context.mess.name.components(separatedBy: " ").first,
                                                        results: environment.repositories.adminResults), nav: nav)
    }
}

struct AdminFindMealView: View {
    @State private var model: AdminFindMealViewModel
    let nav: AdminNav

    init(model: AdminFindMealViewModel, nav: AdminNav) {
        _model = State(initialValue: model)
        self.nav = nav
    }

    private var slotBinding: Binding<MealSlot> {
        Binding(get: { model.slot }, set: { slot in Task { await model.select(slot: slot) } })
    }

    var body: some View {
        AdminPageScaffold(title: AdminScreenCopy.findAMeal, subtitle: AdminScreenCopy.anyMeal, onBack: nav.pop) {
            AdminFlow {
                ChoiceChip(title: AdminScreenCopy.allMesses, isSelected: model.mess == nil) {
                    Task { await model.select(mess: nil) }
                }
                ForEach(model.messes, id: \.self) { name in
                    ChoiceChip(title: name, isSelected: model.mess == name) {
                        Task { await model.select(mess: name) }
                    }
                }
            }
            SegmentedChoice(options: MealSlot.allCases.map { .init(value: $0, title: MLFormat.mealSlot($0)) }, selection: slotBinding)
            AsyncContentView(state: model.state, emptyTitle: AdminScreenCopy.noMealsFound, emptyMessage: AdminScreenCopy.noMealsFoundDetail,
                             timeZone: nav.timeZone, retry: { await model.load() }) { meals in
                VStack(spacing: 0) {
                    ForEach(meals) { meal in
                        AdminRow(title: AdminFormat.mealLine(meal, in: nav.timeZone), detail: AdminScreenCopy.findRowDetail(meal),
                                 action: { nav.push(.meal(meal.id)) }) { EmptyView() }
                    }
                }
            }
        }
        .task { await model.load() }
    }
}

/// Open and closed safety cases, from Results.
struct AdminSafetyCasesScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        let results = environment.repositories.adminResults
        let now = environment.clock.now()
        AdminPageScaffold(title: AdminScreenCopy.safetyCases, onBack: nav.pop) {
            AdminLoadedPage(model: AdminPageModel { try await results.safetyCases() }, timeZone: nav.timeZone) { cases, _ in
                let open = cases.filter { $0.closedAt == nil }
                let closed = cases.filter { $0.closedAt != nil }
                VStack(alignment: .leading, spacing: MLSpacing.s8) {
                    AdminLabel(text: AdminScreenCopy.open)
                    ForEach(open) { item in row(item, now: now) }
                    AdminLabel(text: AdminScreenCopy.closed)
                        .padding(.top, MLSpacing.s16)
                    if closed.isEmpty {
                        Text(AdminScreenCopy.noClosedCases)
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                    ForEach(closed) { item in row(item, now: now) }
                }
            }
        }
    }

    private func row(_ item: AdminSafetyCase, now: Date) -> some View {
        AdminRow(title: item.title,
                 detail: AdminScreenCopy.caseRow(mess: item.mess, day: AdminFormat.weekday(item.day, in: nav.timeZone).prefix(3).description,
                                                 slot: MLFormat.mealSlot(item.slot).lowercased(), dish: item.dish,
                                                 elapsed: item.closedAt == nil ? AdminSafetyText.elapsed(item, now: now) : nil),
                 action: { nav.push(.safetyCase(item.id)) }) {
            StatusText(text: item.closedAt == nil ? AdminScreenCopy.open : AdminScreenCopy.closed, dot: item.closedAt == nil ? .filled : .empty)
        }
    }
}

enum AdminSafetyText {
    /// Nil before the case exists on the story clock, so the row never shows a negative time.
    static func elapsed(_ item: AdminSafetyCase, now: Date) -> String? {
        guard now >= item.reportedAt else { return nil }
        return MLFormat.elapsed(minutes: MLFormat.minutes(from: item.reportedAt, to: now))
    }
}

/// A safety case across student, staff, vendor and the Food Head (A05). Read here: the rail moves in the roles that act on it.
struct AdminSafetyCaseScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let id: String
    let nav: AdminNav

    var body: some View {
        let results = environment.repositories.adminResults
        AdminLoadedPage(model: AdminPageModel(fetch: { try await results.safetyCases() }), timeZone: nav.timeZone) { cases, _ in
            if let item = cases.first(where: { $0.id == id }) {
                AdminSafetyCaseBody(item: item, now: environment.clock.now(), nav: nav)
            } else {
                EmptyStateView(title: AdminScreenCopy.nothingYet, message: "")
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct AdminSafetyCaseBody: View {
    let item: AdminSafetyCase
    let now: Date
    let nav: AdminNav

    @State private var isTellingVendor = false
    @State private var didTryCall = false

    private var timeZone: TimeZone { nav.timeZone }

    var body: some View {
        AdminPageScaffold(title: AdminScreenCopy.safetyCase,
                          subtitle: AdminScreenCopy.caseSubtitle(mess: item.mess, day: AdminFormat.weekday(item.day, in: timeZone).prefix(3).description,
                                                                 slot: MLFormat.mealSlot(item.slot).lowercased(), dish: item.dish),
                          onBack: nav.pop) {
            HeroCard {
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    HeroEyebrow(label: status, showsDot: item.closedAt == nil)
                    Text(item.title)
                        .font(MLType.title2)
                        .foregroundStyle(MLColor.onHero)
                    VStack(alignment: .leading, spacing: MLSpacing.s4) {
                        Text(AdminScreenCopy.proofPlace(item.place, metres: item.accuracyMetres))
                            .font(MLType.body)
                            .foregroundStyle(MLColor.onHero)
                        Text(AdminScreenCopy.proofTime(MLFormat.time(item.reportedAt, in: timeZone)))
                            .font(MLType.secondary)
                            .foregroundStyle(MLColor.onHeroSecondary)
                    }
                    .padding(MLSpacing.s12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.onHero.opacity(0.2)))
                }
            }
            AdminLabel(text: AdminScreenCopy.whoDidWhat)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(item.steps) { step in
                    stepRow(step)
                }
            }
            if item.closedAt == nil {
                if didTryCall {
                    AdminNote(text: AdminScreenCopy.callNotBuilt)
                }
                HStack(spacing: MLSpacing.s12) {
                    OutlineActionButton(title: AdminScreenCopy.call(item.contactName)) { didTryCall = true }
                    InkActionButton(title: AdminScreenCopy.tellTheVendor) { isTellingVendor = true }
                }
            }
        }
        .mlSheet(isPresented: $isTellingVendor) {
            AdminTellVendorSheet(subtitle: AdminScreenCopy.preparedMessage,
                                 message: AdminScreenCopy.vendorSafety(item, day: AdminFormat.day(item.day, in: timeZone), name: nav.context.account.firstName),
                                 note: nil) { isTellingVendor = false }
        }
    }

    private var status: String {
        if let closed = item.closedAt { return AdminScreenCopy.caseClosed(MLFormat.time(closed, in: timeZone)) }
        return AdminSafetyText.elapsed(item, now: now).map(AdminScreenCopy.caseOpen) ?? AdminScreenCopy.open
    }

    private func stepRow(_ step: SafetyStep) -> some View {
        HStack(alignment: .top, spacing: MLSpacing.s12) {
            Group {
                if step.isCurrent {
                    Circle().fill(MLColor.lime).overlay(Circle().stroke(MLColor.ink, lineWidth: 1.5))
                } else if step.isDone {
                    Circle().fill(MLColor.ink).padding(MLSpacing.s4)
                } else {
                    Circle().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1, dash: [3, 3])).padding(2)
                }
            }
            .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text(step.title)
                    .font(step.isDone ? MLType.staffPrimary : MLType.staffBody)
                    .foregroundStyle(MLColor.ink)
                Text(step.detail)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            Spacer()
            Text(step.who)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .padding(.vertical, MLSpacing.s8)
        .accessibilityElement(children: .combine)
    }
}
