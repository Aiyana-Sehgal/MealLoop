import SwiftUI

struct SupervisorAlertsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let staff: StaffSession
    let open: (SupervisorRoute) -> Void

    var body: some View {
        SupervisorAlertsView(model: SupervisorAlertsViewModel(session: staff, repositories: environment.repositories,
                                                              clock: environment.clock),
                             open: open)
    }
}

/// Alerts: S07a (before the meal), S07b (during), S08 (SOS card on top), S07 (after), S07c (shortage resolved),
/// S09 (all caught up). No activity feed, no filters.
struct SupervisorAlertsView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: SupervisorAlertsViewModel
    let open: (SupervisorRoute) -> Void

    init(model: SupervisorAlertsViewModel, open: @escaping (SupervisorRoute) -> Void) {
        _model = State(initialValue: model)
        self.open = open
    }

    private var timeZone: TimeZone { model.session.mess.timeZone }

    var body: some View {
        SupervisorPage {
            ScreenTitleBlock(title: SupervisorCopy.alertsTitle, subtitle: model.session.mess.name)
                .padding(.top, MLSize.hit + MLSpacing.s4)
            if let sos = model.sosModel.current, let stage = model.sosModel.stage {
                SOSCard(incident: SupervisorSOSText.incident(sos, now: model.sosModel.now, timeZone: timeZone,
                                                             eyebrow: SupervisorCopy.sosWord),
                        status: SupervisorSOSText.status(stage, timeZone: timeZone),
                        note: stage.isChecked ? SupervisorCopy.closeWhenSatisfied : nil)
            }
            AsyncContentView(state: model.state, timeZone: timeZone, retry: { await model.load() }) { content in
                StaffMealSummary(status: content.current, mess: content.mess,
                                 count: content.current == nil ? nil : content.followUps.activeShortages.count,
                                 countCaption: SupervisorCopy.activeShortagesCaption,
                                 facts: [StaffFact(label: SupervisorCopy.wasteNotRecorded,
                                                   value: String(content.followUps.wasteNotRecorded.count))])
                groups(content.followUps)
                StaffEarlierMeals(records: content.history, timeZone: timeZone)
            }
        }
        .refreshable { await model.load() }
        .task(id: environment.dataRevision) {
            await model.load()
        }
    }

    @ViewBuilder
    private func groups(_ followUps: SupervisorFollowUps) -> some View {
        if followUps.isEmpty {
            if model.sosModel.current == nil {
                SupervisorCaughtUp(title: SupervisorCopy.caughtUp, message: SupervisorCopy.caughtUpDetail)
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                if !followUps.activeShortages.isEmpty {
                    SupervisorGroupLabel(title: SupervisorCopy.shortagesGroup)
                    ForEach(followUps.activeShortages) { shortage in
                        SupervisorTaskRow(
                            title: shortage.dishName,
                            detail: SupervisorCopy.shortageDetail(
                                level: SupervisorFormat.sentenceCase(MLFormat.shortageLevel(shortage.level)),
                                posted: MLFormat.time(shortage.reportedAt, in: timeZone)),
                            action: { open(.shortage(shortage.id)) }
                        ) {
                            SupervisorStatus(text: SupervisorCopy.active, dot: .ink)
                        }
                    }
                }
                if !followUps.wasteNotRecorded.isEmpty {
                    SupervisorGroupLabel(title: SupervisorCopy.wasteNotRecorded)
                        .padding(.top, followUps.activeShortages.isEmpty ? 0 : MLSpacing.s24)
                    ForEach(followUps.wasteNotRecorded) { record in
                        SupervisorTaskRow(title: mealTitle(record), detail: wasteDetail(record),
                                          action: { open(.wasteReport(record.mealID)) }) {
                            SupervisorStatus(text: SupervisorCopy.notRecorded, dot: .open)
                        }
                    }
                }
            }
        }
    }

    /// "Lunch · Wed 14"
    private func mealTitle(_ record: MealRecord) -> String {
        "\(MLFormat.mealSlot(record.slot)) · \(SupervisorFormat.shortDay(record.day, in: timeZone))"
    }

    /// "Closed 2:00 PM" when the closing time is known, else "598 entered", else nothing made up.
    private func wasteDetail(_ record: MealRecord) -> String {
        if let closedAt = record.closedAt {
            return SupervisorCopy.closedAt(MLFormat.time(closedAt, in: timeZone))
        }
        if let entered = record.finalEntries.value {
            return SupervisorCopy.entered(entered)
        }
        return SupervisorCopy.unavailable
    }
}
