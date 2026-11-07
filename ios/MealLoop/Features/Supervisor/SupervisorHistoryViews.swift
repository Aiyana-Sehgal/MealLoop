import SwiftUI

/// How a closed meal reads in one line: shortages, then the waste report (S18 "Shortage active · Waste not recorded").
enum SupervisorHistoryText {
    static func shortageSummary(_ lines: [MealRecord.ShortageLine]) -> String {
        if lines.isEmpty { return SupervisorCopy.noShortage }
        if lines.contains(where: { $0.outcome == .active }) { return SupervisorCopy.shortageActive }
        return SupervisorCopy.shortageResolved
    }

    static func wasteSummary(_ waste: MealRecord.WasteStatus) -> String {
        if case .recorded = waste { return SupervisorCopy.wasteRecorded }
        return SupervisorCopy.wasteNotRecorded
    }

    /// "Wed 14 · Lunch"
    static func title(_ record: MealRecord, in timeZone: TimeZone) -> String {
        SupervisorCopy.dayAndMeal(SupervisorFormat.shortDay(record.day, in: timeZone), MLFormat.mealSlot(record.slot))
    }
}

// MARK: - Meal history (S18, S18b to S18e)

struct SupervisorHistoryScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let staff: StaffSession
    let onBack: () -> Void
    let openMeal: (MealID) -> Void

    var body: some View {
        SupervisorHistoryView(model: SupervisorHistoryViewModel(session: staff, repositories: environment.repositories),
                              onBack: onBack, openMeal: openMeal)
    }
}

struct SupervisorHistoryView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: SupervisorHistoryViewModel
    let onBack: () -> Void
    let openMeal: (MealID) -> Void

    init(model: SupervisorHistoryViewModel, onBack: @escaping () -> Void, openMeal: @escaping (MealID) -> Void) {
        _model = State(initialValue: model)
        self.onBack = onBack
        self.openMeal = openMeal
    }

    private var timeZone: TimeZone { model.session.mess.timeZone }

    private var isLoading: Bool {
        switch model.state {
        case .idle, .loading: return true
        default: return false
        }
    }

    /// Nothing to show and no way to get it: SV-7 Error, never an empty history.
    private var didFail: Bool {
        switch model.state {
        case .failed, .offline(nil, _): return true
        default: return false
        }
    }

    var body: some View {
        SupervisorPage(bottomInset: MLSpacing.s32) {
            SupervisorPageHeader(title: SupervisorCopy.historyTitle, subtitle: model.session.mess.name, onBack: onBack)
            if isLoading {
                SupervisorHistorySkeleton(text: SupervisorCopy.loadingHistory)
            } else if didFail {
                VStack(spacing: MLSpacing.s8) {
                    Text(SupervisorCopy.couldntLoadHistory)
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.ink)
                    Text(SupervisorCopy.checkConnection)
                        .font(MLType.staffBody)
                        .foregroundStyle(MLColor.inkSecondary)
                        .multilineTextAlignment(.center)
                    OutlineActionButton(title: SupervisorCopy.retry) { Task { await model.load() } }
                        .frame(width: 130)
                        .padding(.top, MLSpacing.s12)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, MLSpacing.s32)
                .padding(.top, 110)
            } else {
                AsyncContentView(state: model.state, emptyTitle: SupervisorCopy.noMealsYet,
                                 emptyMessage: SupervisorCopy.noMealsYetDetail, timeZone: timeZone,
                                 retry: { await model.load() }) { content in
                    VStack(spacing: 0) {
                        Rectangle().fill(MLColor.border).frame(height: 1)
                        ForEach(content.records) { record in
                            SupervisorHistoryRow(
                                title: SupervisorHistoryText.title(record, in: timeZone),
                                detail: "\(SupervisorHistoryText.shortageSummary(record.shortages)) · \(SupervisorHistoryText.wasteSummary(record.waste))",
                                action: { openMeal(record.mealID) }
                            ) {
                                entered(record.finalEntries)
                            }
                        }
                    }
                }
            }
        }
        .refreshable { await model.load() }
        .task(id: environment.dataRevision) {
            await model.load()
        }
    }

    /// "774 entered" (number in mono), or "Unavailable": never zero.
    @ViewBuilder
    private func entered(_ reading: CountReading) -> some View {
        if let value = reading.value {
            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s4) {
                Text("\(value)").font(MLType.monoBody)
                Text(SupervisorCopy.enteredWord).font(MLType.body)
            }
            .foregroundStyle(MLColor.ink)
        } else {
            Text(SupervisorCopy.unavailable)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
        }
    }
}

// MARK: - Past meal (S19, S19b to S19f)

struct SupervisorPastMealScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let mealID: MealID
    let staff: StaffSession
    let onBack: () -> Void
    let openReport: () -> Void

    var body: some View {
        SupervisorPastMealView(model: SupervisorPastMealViewModel(mealID: mealID, session: staff,
                                                                  repositories: environment.repositories),
                               onBack: onBack, openReport: openReport)
    }
}

struct SupervisorPastMealView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: SupervisorPastMealViewModel
    let onBack: () -> Void
    let openReport: () -> Void

    init(model: SupervisorPastMealViewModel, onBack: @escaping () -> Void, openReport: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onBack = onBack
        self.openReport = openReport
    }

    private var timeZone: TimeZone { model.session.mess.timeZone }

    var body: some View {
        SupervisorPage(bottomInset: MLSpacing.s32) {
            SupervisorPageHeader(title: model.state.value.map { SupervisorHistoryText.title($0, in: timeZone) } ?? "",
                                 subtitle: model.session.mess.name, onBack: onBack)
            AsyncContentView(state: model.state, timeZone: timeZone, retry: { await model.load() }) { record in
                summary(record)
            }
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
    }

    private func summary(_ record: MealRecord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SupervisorStatus(text: SupervisorCopy.closed, dot: .ink)
                .padding(.bottom, MLSpacing.s16)
            Rectangle().fill(MLColor.border).frame(height: 1)
            SupervisorFactRow(label: SupervisorCopy.finalEntries) {
                if let value = record.finalEntries.value {
                    Text("\(value)")
                        .font(MLType.heroTitle.monospaced())
                        .foregroundStyle(MLColor.ink)
                } else {
                    Text(SupervisorCopy.unavailable)
                        .font(MLType.staffBody)
                        .foregroundStyle(MLColor.inkSecondary)
                }
            }
            .frame(minHeight: 64)

            Text(SupervisorCopy.shortagesGroup)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .padding(.top, MLSpacing.s16)
            shortages(record.shortages)

            Text(SupervisorCopy.wasteReportGroup)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .padding(.top, MLSpacing.s16)
            waste(record)

            Text(SupervisorCopy.readOnly)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, MLSpacing.s32)
        }
    }

    @ViewBuilder
    private func shortages(_ lines: [MealRecord.ShortageLine]) -> some View {
        let named = lines.filter { $0.dishName != nil }
        let unnamed = lines.filter { $0.dishName == nil }
        if lines.isEmpty {
            line { Text(SupervisorCopy.noShortage).font(MLType.staffBody).foregroundStyle(MLColor.inkSecondary) }
        }
        ForEach(Array(named.enumerated()), id: \.offset) { _, shortage in
            line {
                Text(shortage.dishName ?? "").font(MLType.staffBody).foregroundStyle(MLColor.ink)
                Spacer(minLength: MLSpacing.s8)
                outcome(shortage.outcome)
            }
        }
        if !unnamed.isEmpty {
            // The record does not name the item (S19d): count them rather than invent a name.
            line {
                Text(SupervisorCopy.shortageCount(unnamed.count)).font(MLType.staffBody).foregroundStyle(MLColor.ink)
                Spacer(minLength: MLSpacing.s8)
                if unnamed.contains(where: { $0.outcome == .active }) {
                    SupervisorStatus(text: SupervisorCopy.active, dot: .ink)
                } else {
                    SupervisorStatus(text: SupervisorCopy.resolved, dot: .lime)
                }
            }
        }
    }

    @ViewBuilder
    private func outcome(_ outcome: MealRecord.ShortageOutcome) -> some View {
        switch outcome {
        case .active:
            SupervisorStatus(text: SupervisorCopy.active, dot: .ink)
        case .resolved(let at):
            SupervisorStatus(text: SupervisorCopy.resolved, dot: .lime, time: at.map { MLFormat.time($0, in: timeZone) })
        }
    }

    @ViewBuilder
    private func waste(_ record: MealRecord) -> some View {
        line {
            Text(SupervisorCopy.byKitchen).font(MLType.staffBody).foregroundStyle(MLColor.ink)
            Spacer(minLength: MLSpacing.s8)
            switch record.waste {
            case .recorded(let at):
                SupervisorStatus(text: SupervisorCopy.recorded, dot: .lime, time: at.map { MLFormat.time($0, in: timeZone) })
            case .notRecorded:
                SupervisorStatus(text: SupervisorCopy.notRecorded, dot: .open)
            }
        }
        // A report page exists when there is something to read: the rows, or the honest "not recorded" page.
        if record.wasteReport != nil || record.waste == .notRecorded {
            TextLinkButton(title: SupervisorCopy.viewReport, action: openReport)
        }
    }

    private func line<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: MLSpacing.s12) { content() }
            .frame(minHeight: MLSize.staffButton)
            .overlay(alignment: .bottom) {
                Rectangle().fill(MLColor.border).frame(height: 1)
            }
            .accessibilityElement(children: .combine)
    }
}
