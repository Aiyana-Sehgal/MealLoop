import Observation
import SwiftUI

// MARK: - Menu (K17)

/// The day's menu: dish names only, with no units.
@MainActor
@Observable
final class KitchenMenuViewModel {
    private(set) var state: LoadState<[Dish]> = .idle
    let meal: Meal
    private let meals: any MealRepository

    init(meal: Meal, meals: any MealRepository) {
        self.meal = meal
        self.meals = meals
    }

    func load() async {
        state = .loading
        do {
            let dishes = try await meals.menu(for: meal.id)
            state = dishes.isEmpty ? .empty : .loaded(dishes)
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(nil, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }
}

struct KitchenMenuView: View {
    @State private var model: KitchenMenuViewModel
    let mess: Mess
    let day: Date
    let onBack: () -> Void

    init(model: KitchenMenuViewModel, mess: Mess, day: Date, onBack: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.mess = mess
        self.day = day
        self.onBack = onBack
    }

    var body: some View {
        KitchenPage(title: "\(KitchenCopy.menuRow) \(MLFormat.mealSlot(model.meal.slot))",
                    subtitle: "\(mess.name) · \(KitchenFormat.dayLine(day, in: mess.timeZone))", onBack: onBack) {
            AsyncContentView(state: model.state, timeZone: mess.timeZone, retry: { await model.load() }) { dishes in
                VStack(spacing: 0) {
                    Rectangle().fill(MLColor.border).frame(height: 1)
                    ForEach(dishes) { dish in
                        Text(dish.name)
                            .font(dish.isHighlight ? MLType.staffPrimary : MLType.staffBody)
                            .foregroundStyle(MLColor.ink)
                            .frame(maxWidth: .infinity, minHeight: MLSize.staffButton, alignment: .leading)
                        Rectangle().fill(MLColor.border).frame(height: 1)
                    }
                }
            }
        }
        .task { await model.load() }
    }
}

// MARK: - Meal history (K11)

/// Ended meals only: `mealHistory` holds nothing else.
@MainActor
@Observable
final class KitchenHistoryViewModel {
    private(set) var state: LoadState<[MealRecord]> = .idle
    let session: StaffSession
    private let mealState: any MealStateRepository

    init(session: StaffSession, repositories: Repositories) {
        self.session = session
        self.mealState = repositories.mealState
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let records = try await mealState.mealHistory(for: session.mess.id)
            state = records.isEmpty ? .empty : .loaded(records)
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }
}

enum KitchenHistoryText {
    /// "Wed 14 · Lunch"
    static func title(_ record: MealRecord, in timeZone: TimeZone) -> String {
        KitchenCopy.dayAndMeal(KitchenFormat.shortDay(record.day, in: timeZone), MLFormat.mealSlot(record.slot))
    }
}

struct KitchenHistoryView: View {
    @State private var model: KitchenHistoryViewModel
    let onBack: () -> Void
    let openMeal: (MealID) -> Void

    init(model: KitchenHistoryViewModel, onBack: @escaping () -> Void, openMeal: @escaping (MealID) -> Void) {
        _model = State(initialValue: model)
        self.onBack = onBack
        self.openMeal = openMeal
    }

    private var timeZone: TimeZone { model.session.mess.timeZone }

    var body: some View {
        KitchenPage(title: KitchenCopy.historyTitle, subtitle: model.session.mess.name, onBack: onBack) {
            AsyncContentView(state: model.state, emptyTitle: KitchenCopy.noMealsYet, emptyMessage: KitchenCopy.noMealsYetDetail,
                             timeZone: timeZone, retry: { await model.load() }) { records in
                VStack(spacing: MLSpacing.s16) {
                    VStack(spacing: 0) {
                        Rectangle().fill(MLColor.border).frame(height: 1)
                        ForEach(records) { record in
                            Button { openMeal(record.mealID) } label: { row(record) }
                                .buttonStyle(.plain)
                            Rectangle().fill(MLColor.border).frame(height: 1)
                        }
                    }
                    Text(KitchenCopy.historyFooter)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
            }
        }
        .task { await model.load() }
    }

    private func row(_ record: MealRecord) -> some View {
        HStack(spacing: MLSpacing.s8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(KitchenHistoryText.title(record, in: timeZone))
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                entered(record.finalEntries)
            }
            Spacer(minLength: MLSpacing.s8)
            if case .recorded = record.waste {
                StatusText(text: KitchenCopy.recordedWord)
            } else {
                StatusText(text: KitchenCopy.notRecorded, dot: .empty)
            }
        }
        .frame(minHeight: MLSize.staffButton)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// "774 entered", or "Unavailable": never zero.
    @ViewBuilder
    private func entered(_ reading: CountReading) -> some View {
        if let value = reading.value {
            HStack(spacing: MLSpacing.s4) {
                Text("\(value)").font(MLType.monoBody)
                Text(KitchenCopy.enteredWord).font(MLType.body)
            }
            .foregroundStyle(MLColor.inkSecondary)
        } else {
            Text(KitchenCopy.unavailable).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
        }
    }
}

// MARK: - Past meal (K09, K10, K15b, K18)

/// One ended meal. Record and Edit are offered only where the repository can take them: the current meal.
@MainActor
@Observable
final class KitchenPastMealViewModel {
    private(set) var state: LoadState<MealRecord> = .idle
    /// The meal to open Record waste or Edit report on, when that is possible.
    private(set) var editableMeal: Meal?
    let mealID: MealID
    let session: StaffSession
    private let mealState: any MealStateRepository
    private let clock: any AppClock

    init(mealID: MealID, session: StaffSession, repositories: Repositories, clock: any AppClock) {
        self.mealID = mealID
        self.session = session
        self.mealState = repositories.mealState
        self.clock = clock
    }

    var now: Date { clock.now() }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            guard let record = try await mealState.mealHistory(for: session.mess.id).first(where: { $0.mealID == mealID }) else {
                state = .empty
                return
            }
            let current = try await mealState.currentMeal(for: session.mess.id)
            editableMeal = current?.meal.id == mealID ? current?.meal : nil
            state = .loaded(record)
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    /// True while a recorded report can still be edited (six hours; the repository enforces it on save).
    func canEdit(savedAt: Date?) -> Bool {
        guard let savedAt else { return false }
        return WasteReportPolicy.canEdit(.recorded(savedAt: savedAt), at: clock.now())
    }
}

struct KitchenPastMealView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: KitchenPastMealViewModel
    let onBack: () -> Void
    let onRecord: (Meal) -> Void

    init(model: KitchenPastMealViewModel, onBack: @escaping () -> Void, onRecord: @escaping (Meal) -> Void) {
        _model = State(initialValue: model)
        self.onBack = onBack
        self.onRecord = onRecord
    }

    private var timeZone: TimeZone { model.session.mess.timeZone }
    private var title: String { model.state.value.map { KitchenHistoryText.title($0, in: timeZone) } ?? KitchenCopy.historyTitle }

    var body: some View {
        KitchenPage(title: title, subtitle: model.session.mess.name, onBack: onBack) {
            AsyncContentView(state: model.state, timeZone: timeZone, retry: { await model.load() }) { record in
                content(record)
            }
        }
        .task(id: environment.dataRevision) { await model.load() }
    }

    private func content(_ record: MealRecord) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            HStack {
                Text(KitchenCopy.finalEntriesLabel).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                Spacer()
                if let value = record.finalEntries.value {
                    Text("\(value)").font(MLType.monoBody).foregroundStyle(MLColor.ink)
                } else {
                    Text(KitchenCopy.unavailable).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                }
            }
            Rectangle().fill(MLColor.border).frame(height: 1)
            HStack {
                Text(KitchenCopy.wasteReportTitle).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                Spacer(minLength: MLSpacing.s8)
                status(record.waste)
            }
            switch record.waste {
            case .notRecorded:
                if let meal = model.editableMeal {
                    Text(KitchenCopy.youCanStillAdd).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                    InkActionButton(title: KitchenCopy.recordWaste) { onRecord(meal) }
                }
            case .recorded(let at):
                recorded(record, savedAt: at)
            }
        }
    }

    @ViewBuilder
    private func status(_ waste: MealRecord.WasteStatus) -> some View {
        switch waste {
        case .notRecorded:
            StatusText(text: KitchenCopy.notRecorded, dot: .empty)
        case .recorded(let at):
            StatusText(text: KitchenCopy.recordedWord, time: at.map { MLFormat.time($0, in: timeZone) })
        }
    }

    @ViewBuilder
    private func recorded(_ record: MealRecord, savedAt: Date?) -> some View {
        if let savedAt {
            let canEdit = model.canEdit(savedAt: savedAt)
            Text(canEdit ? KitchenCopy.editUntil(MLFormat.time(savedAt.addingTimeInterval(WasteReportPolicy.editWindow), in: timeZone))
                         : KitchenCopy.editingClosed)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
        }
        Rectangle().fill(MLColor.border).frame(height: 1)
        if let report = record.wasteReport {
            Text(KitchenCopy.foodLeftOverShort).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            ForEach(report.leftovers) { row in
                KitchenWasteLine(row: row)
                    .frame(minHeight: MLSize.hit)
            }
            Rectangle().fill(MLColor.border).frame(height: 1)
            HStack {
                Text(KitchenCopy.plateWasteWhole).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                Spacer(minLength: MLSpacing.s8)
                Text(KitchenWasteText.plate(report.plateWaste) ?? "—").font(MLType.monoBody).foregroundStyle(MLColor.ink)
            }
            Rectangle().fill(MLColor.border).frame(height: 1)
            if model.canEdit(savedAt: savedAt), let meal = model.editableMeal {
                TextLinkButton(title: KitchenCopy.editReport) { onRecord(meal) }
            }
        } else {
            Text(KitchenCopy.quantitiesUnavailable).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
        }
    }
}
