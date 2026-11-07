import SwiftUI

/// Builds the view model from the environment.
struct SupervisorHomeScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let staff: StaffSession
    let onToast: (String) -> Void

    var body: some View {
        SupervisorHomeView(model: SupervisorHomeViewModel(session: staff, repositories: environment.repositories,
                                                          clock: environment.clock),
                           onToast: onToast)
    }
}

/// Supervisor Home: S01 (not started), S02 (in service), S03 (SOS tab), S06 (closed), S06b (final count missing).
struct SupervisorHomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @State private var model: SupervisorHomeViewModel
    @State private var isConfirmingStart = false
    @State private var isConfirmingClose = false
    @State private var isShowingSOS = false
    let onToast: (String) -> Void

    init(model: SupervisorHomeViewModel, onToast: @escaping (String) -> Void) {
        _model = State(initialValue: model)
        self.onToast = onToast
    }

    private func homeBody(_ content: SupervisorHomeContent) -> some View {
        SupervisorHomeBody(content: content, actionError: model.actionError,
                           onStart: { isConfirmingStart = true },
                           onClose: { isConfirmingClose = true },
                           onFollowUps: { router.selectedStaffTab = .alerts })
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SupervisorPage {
                StaffHeader(initials: model.session.staffInitials) {
                    router.selectedStaffTab = .me
                }
                .overlay(alignment: .trailing) {
                    if case .offline = model.state {
                        SupervisorOfflineMark(text: SupervisorCopy.offlineMark)
                            .padding(.trailing, MLSize.hit + MLSpacing.s12)
                    }
                }
                // SV-1 Offline marks it beside the avatar, so last values show without the shared banner.
                if case .offline(let content?, _) = model.state {
                    homeBody(content)
                } else {
                    AsyncContentView(state: model.state,
                                     emptyTitle: SupervisorCopy.noMealToday,
                                     emptyMessage: SupervisorCopy.noMealTodayDetail,
                                     timeZone: model.session.mess.timeZone,
                                     retry: { await model.load() }) { content in
                        homeBody(content)
                    }
                }
            }
            .refreshable { await model.load() }

            // The SOS tab sits flush with the right edge under the avatar, only while a case is active.
            if !model.sosModel.cases.isEmpty {
                SOSEdgeTab(count: model.sosModel.cases.count, isClaimedByYou: model.sosModel.isClaimedByYou,
                           claimedStatus: SupervisorCopy.youreChecking) {
                    isShowingSOS = true
                }
                .padding(.top, 72)
            }
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
        .mlConfirmDialog(isPresented: $isConfirmingStart, content: dialog(SupervisorCopy.startDialog),
                         isWorking: model.isWriting) {
            Task {
                let started = await model.startMeal()
                isConfirmingStart = false
                if started { environment.dataDidChange() }
            }
        }
        .mlConfirmDialog(isPresented: $isConfirmingClose, content: dialog(SupervisorCopy.closeDialog),
                         isWorking: model.isWriting) {
            Task {
                let closed = await model.closeMeal()
                isConfirmingClose = false
                if closed { environment.dataDidChange() }
            }
        }
        .mlSheet(isPresented: $isShowingSOS) {
            SupervisorSOSPanelView(model: model.sosModel, timeZone: model.session.mess.timeZone,
                                   onDismiss: { isShowingSOS = false },
                                   onCaseClosed: { onToast(SupervisorCopy.caseClosedToast) },
                                   onChange: { environment.dataDidChange() })
        }
    }

    private func dialog(_ make: (String, String) -> ConfirmDialogContent) -> ConfirmDialogContent {
        let meal = model.state.value.map { MLFormat.mealSlot($0.meal.slot) } ?? ""
        return make(meal, model.session.mess.name)
    }
}

/// The loaded Home. Pure layout: every value comes from `SupervisorHomeContent`.
struct SupervisorHomeBody: View {
    let content: SupervisorHomeContent
    let actionError: String?
    let onStart: () -> Void
    let onClose: () -> Void
    let onFollowUps: () -> Void

    private var timeZone: TimeZone { content.mess.timeZone }
    private var mealName: String { MLFormat.mealSlot(content.meal.slot) }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            ScreenTitleBlock(title: mealName,
                             subtitle: "\(content.mess.name) · \(MLFormat.timeRange(content.meal.startsAt, content.meal.endsAt, in: timeZone))")
            switch content.phase {
            case .notStarted(let forecast):
                SupervisorStatus(text: SupervisorCopy.notStarted, dot: .open)
                notStartedCard(forecast)
            case .inService(let entered, let minutes):
                MealProgressChip(text: SupervisorCopy.inService(MLFormat.elapsed(minutes: minutes)))
                inServiceCard(entered)
            case .closed(let finalEntries, let closedAt):
                SupervisorStatus(text: SupervisorCopy.closed, dot: .ink, time: closedAt.map { MLFormat.time($0, in: timeZone) })
                closedCard(finalEntries)
            }
            if let actionError {
                FieldErrorText(text: actionError)
            }
            followUpRows
        }
    }

    // MARK: S01 · not started

    private func notStartedCard(_ forecast: Forecast) -> some View {
        HeroCard {
            HeroEyebrow(label: SupervisorCopy.forecastEyebrow)
            HeroCount(value: forecast.diners, caption: SupervisorCopy.forecastCaption)
                .padding(.top, MLSpacing.s12)
            if forecast.diners == nil {
                Text(SupervisorCopy.forecastNotReady)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.onHeroSecondary)
                    .padding(.top, MLSpacing.s4)
            }
            LimeActionButton(title: SupervisorCopy.startMeal, action: onStart)
                .padding(.top, MLSpacing.s20)
        }
    }

    // MARK: S02 · in service (students entered only, never the forecast beside it)

    private func inServiceCard(_ entered: CountReading) -> some View {
        HeroCard {
            HeroEyebrow(label: SupervisorCopy.liveEyebrow, showsDot: true,
                        time: entered.asOf.map { MLFormat.time($0, in: timeZone) })
            HeroCount(value: entered.value, caption: SupervisorCopy.liveCaption)
                .padding(.top, MLSpacing.s12)
            SupervisorHeroOutlineButton(title: SupervisorCopy.closeMeal, action: onClose)
                .padding(.top, MLSpacing.s20)
        }
    }

    // MARK: S06 / S06b · closed

    private func closedCard(_ finalEntries: CountReading) -> some View {
        HeroCard {
            HeroEyebrow(label: SupervisorCopy.mealClosedEyebrow, showsDot: true)
            Text(SupervisorCopy.hasEnded(mealName))
                .font(MLType.heroTitle)
                .foregroundStyle(MLColor.onHero)
                .padding(.top, MLSpacing.s8)
            Text(SupervisorCopy.finalEntries)
                .font(MLType.body)
                .foregroundStyle(MLColor.onHeroSecondary)
                .padding(.top, MLSpacing.s16)
            if let value = finalEntries.value {
                Text("\(value)")
                    .font(MLType.heroNumber)
                    .foregroundStyle(MLColor.onHero)
            } else {
                // Missing is never shown as zero.
                Text(SupervisorCopy.unavailable)
                    .font(MLType.heroTitle)
                    .foregroundStyle(MLColor.onHero)
                Text(SupervisorCopy.finalCountMissing)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.onHeroSecondary)
                    .padding(.top, MLSpacing.s4)
            }
        }
    }

    // MARK: Follow-ups (the same tasks Alerts and Me list)

    private var followUpRows: some View {
        VStack(spacing: 0) {
            Rectangle().fill(MLColor.border).frame(height: 1)
            QuietRow(title: SupervisorCopy.wasteNotRecorded, value: "\(content.followUps.wasteNotRecorded.count)",
                     action: onFollowUps)
            QuietRow(title: SupervisorCopy.activeShortages, value: "\(content.followUps.activeShortages.count)",
                     action: onFollowUps)
        }
    }
}
