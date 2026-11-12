import SwiftUI

/// Headcount details for the signed-in mess's meal (A02, restored 12 Nov 2026): the page Approve opens in its approved
/// state, as the pack's flow says, and "Headcount details" opens at any time. Adjust the number, approve or send, see
/// the approval and vendor status, the six named values and the history. Shares Today's view model, so Today has
/// moved on by the time Back is tapped.
struct AdminHeadcountDetailView: View {
    let model: AdminTodayViewModel
    let onBack: () -> Void

    @State private var isAdjusting = false
    @State private var isConfirmingSend = false
    @State private var toast: String?

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    AdminBackButton(action: onBack)
                    AsyncContentView(state: model.state,
                                     emptyTitle: AdminCopy.noMealTitle,
                                     emptyMessage: AdminCopy.noMealDetail,
                                     timeZone: model.context.mess.timeZone,
                                     retry: { await model.load() }) { content in
                        if let meal = content.meal {
                            page(content, meal)
                        } else {
                            EmptyStateView(title: AdminCopy.noData)
                        }
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, 120)
            }
            .refreshable { await model.load() }
        }
        .toolbar(.hidden, for: .navigationBar)
        .mlToast(message: $toast, bottomInset: 92)
        .mlSheet(isPresented: $isAdjusting) {
            if let meal = model.state.value?.meal, let count = meal.adjustableCount {
                AdminAdjustHeadcountSheet(startCount: count,
                                          subtitle: model.state.value.map { AdminCopy.changeSubtitle(meal: MLFormat.mealSlot($0.selectedSlot),
                                                                                                     mess: AdminCopy.tileName($0.mess.name)) },
                                          forecast: meal.forecastToApprove, isSaving: model.isApproving, errorText: model.actionError,
                                          save: { await model.adjust(to: $0, reason: $1) }) { saved in
                    isAdjusting = false
                    toast = AdminCopy.approvedToast(saved)
                } onClose: {
                    isAdjusting = false
                }
            }
        }
        // A compact sheet naming the mess, the meal and the count. It stays open on a failure, so Send retries.
        .mlConfirmSheet(isPresented: $isConfirmingSend, content: sendDialog, isWorking: model.isSending,
                        errorText: model.actionError) {
            let count = model.state.value?.meal?.nextAction?.count
            Task {
                guard await model.send() else { return }
                isConfirmingSend = false
                if let count { toast = AdminCopy.sentToast(count) }
            }
        }
    }

    private var sendDialog: ConfirmDialogContent {
        let content = model.state.value
        let count = content?.meal?.nextAction?.count ?? 0
        return ConfirmDialogContent(title: AdminCopy.sendTitle(count),
                                    subject: AdminCopy.sendSubject(meal: MLFormat.mealSlot(content?.selectedSlot ?? .lunch),
                                                                   mess: model.context.mess.name),
                                    detail: AdminCopy.sendDetail,
                                    cancelTitle: AdminCopy.cancel,
                                    actionTitle: AdminCopy.sendAction)
    }

    @ViewBuilder
    private func page(_ content: AdminTodayContent, _ meal: AdminMealContent) -> some View {
        let timeZone = content.mess.timeZone
        let cutoff = MLFormat.time(IntentionPolicy.cutoff(for: meal.meal), in: timeZone)
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            ScreenTitleBlock(title: AdminCopy.pageTitle(mess: content.mess.name, meal: MLFormat.mealSlot(meal.meal.slot)),
                             subtitle: content.answersAreOpen ? AdminCopy.answersCloseAt(cutoff) : AdminCopy.answersClosedAt(cutoff))
            AdminChainStepper(stepIndex: AdminHeadcountDetailView.stepIndex(meal.headcount))
            hero(meal, timeZone: timeZone)
            primaryAction(meal)
            if let error = model.actionError {
                FieldErrorText(text: error)
            }
            VStack(spacing: 0) {
                if meal.adjustableCount != nil {
                    Rectangle().fill(MLColor.border).frame(height: 1)
                    QuietRow(title: AdminCopy.adjustHeadcount) {
                        model.clearActionError()
                        isAdjusting = true
                    }
                }
                AdminHeadcountStatusRows(headcount: meal.headcount, timeZone: timeZone)
            }
            AdminHeadcountValuesCard(values: meal.values)
            history(meal, timeZone: timeZone)
        }
    }

    @ViewBuilder
    private func hero(_ meal: AdminMealContent, timeZone: TimeZone) -> some View {
        let lead = heroValue(meal)
        HeroCard {
            HeroEyebrow(label: lead.label, time: lead.time.map { MLFormat.time($0, in: timeZone) })
            Text(lead.count.map { String($0) } ?? "—")
                .font(AdminType.heroMetric)
                .foregroundStyle(MLColor.onHero)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, MLSpacing.s8)
            if lead.count == nil {
                Text(AdminCopy.forecastNotReady)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.onHeroSecondary)
            }
            Text(AdminCopy.answersScope)
                .font(MLType.meta)
                .foregroundStyle(MLColor.onHeroSecondary)
                .padding(.top, MLSpacing.s16)
            HStack(alignment: .top, spacing: MLSpacing.s12) {
                answerStat(meal.answers.attending, AdminCopy.answersYes)
                answerStat(meal.answers.skipping, AdminCopy.answersNo)
                answerStat(meal.answers.notSure, AdminCopy.answersNotSure)
                answerStat(meal.answers.noResponse, AdminCopy.answersNone)
            }
            .padding(.top, MLSpacing.s8)
        }
    }

    /// What the hero leads with at each step, under that value's own name.
    private func heroValue(_ meal: AdminMealContent) -> (label: String, count: Int?, time: Date?) {
        if case .sent(let sent) = meal.headcount.sentToVendor {
            return (AdminCopy.sentToVendor, sent.count, sent.sentAt)
        }
        if case .approved(let approved) = meal.headcount.approved {
            return (AdminCopy.approvedHeadcount, approved.count, approved.approvedAt)
        }
        return (meal.forecastToApproveName, meal.forecastToApprove, nil)
    }

    private func answerStat(_ count: Int, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String(count))
                .font(MLType.monoBody)
                .foregroundStyle(MLColor.onHero)
            Text(label)
                .font(MLType.meta)
                .foregroundStyle(MLColor.onHeroSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func primaryAction(_ meal: AdminMealContent) -> some View {
        switch meal.nextAction {
        case .approve(let count)?:
            InkActionButton(title: AdminCopy.approve(count, field: meal.forecastToApproveName), isLoading: model.isApproving) {
                Task {
                    if await model.approve() { toast = AdminCopy.approvedToast(count) }
                }
            }
        case .send(let count)?:
            InkActionButton(title: AdminCopy.send(count), isLoading: model.isSending) {
                model.clearActionError()
                isConfirmingSend = true
            }
        case nil:
            EmptyView()
        }
    }

    @ViewBuilder
    private func history(_ meal: AdminMealContent, timeZone: TimeZone) -> some View {
        if !meal.history.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: AdminCopy.history)
                ForEach(Array(meal.history.enumerated()), id: \.offset) { _, event in
                    historyRow(event, timeZone: timeZone)
                }
            }
        }
    }

    private func historyRow(_ event: AdminHistoryEvent, timeZone: TimeZone) -> some View {
        let time = MLFormat.time(event.time, in: timeZone)
        switch event {
        case .adjusted(let change):
            return AlertRow(mark: .outlined(symbol: "pencil"),
                            title: AdminCopy.historyAdjusted(from: change.from, to: change.to), time: time,
                            detail: AdminCopy.historyAdjustedDetail(reason: change.reason,
                                                                    role: MLFormat.roleName(change.adjustedBy)))
        case .approved(let count, let role, _):
            return AlertRow(mark: .outlined(symbol: "checkmark"), title: AdminCopy.historyApproved(count), time: time,
                            detail: MLFormat.roleName(role))
        case .sent(let sent):
            return AlertRow(mark: .outlined(symbol: "paperplane"), title: AdminCopy.historySent(sent.count), time: time,
                            detail: MLFormat.roleName(sent.sentBy))
        case .acknowledged:
            return AlertRow(mark: .outlined(symbol: "checkmark.seal"), title: AdminCopy.historyAcknowledged, time: time,
                            detail: AdminCopy.vendorAccount)
        }
    }

    /// Forecast, Approve, Send, Vendor: the step waiting on someone; 4 once the vendor has acknowledged.
    static func stepIndex(_ headcount: Headcount) -> Int {
        if headcount.liveForecast.diners == nil && headcount.cutoffForecast.diners == nil { return 0 }
        if headcount.approved.count == nil { return 1 }
        switch headcount.vendorAcknowledgmentStatus {
        case .notPublished: return 2
        case .pending: return 3
        case .acknowledged: return 4
        }
    }
}

/// The six named values. A missing one says so in words, and is never drawn as zero.
struct AdminHeadcountValuesCard: View {
    let values: [AdminHeadcountValue]

    var body: some View {
        FactCard(rows: values.map { value in
            FactRow(label: value.name, value: value.count.map { String($0) } ?? "—",
                    isMono: value.count != nil)
        })
    }
}

/// Approval and vendor status, as chips. Pending never reads as replied or agreed.
struct AdminHeadcountStatusRows: View {
    let headcount: Headcount?
    let timeZone: TimeZone

    var body: some View {
        VStack(spacing: 0) {
            row(AdminCopy.approval) { approval }
            Rectangle().fill(MLColor.border).frame(height: 1)
            row(AdminCopy.vendor) { vendor }
        }
    }

    private func row<Status: View>(_ title: String, @ViewBuilder status: () -> Status) -> some View {
        HStack(spacing: MLSpacing.s12) {
            Text(title)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            Spacer(minLength: MLSpacing.s8)
            status()
        }
        .frame(minHeight: MLSize.hit)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var approval: some View {
        if case .approved(let approved)? = headcount?.approved {
            AdminChip(text: AdminCopy.statusAt(AdminCopy.approved, MLFormat.time(approved.approvedAt, in: timeZone)), style: .outline)
        } else {
            AdminChip(text: AdminCopy.notApproved, style: .dashed)
        }
    }

    @ViewBuilder
    private var vendor: some View {
        switch headcount?.vendorAcknowledgmentStatus {
        case .acknowledged(let record)?:
            AdminChip(text: AdminCopy.statusAt(AdminCopy.acknowledged, MLFormat.time(record.acknowledgedAt, in: timeZone)), style: .outline)
        case .pending?:
            AdminChip(text: AdminCopy.pending, style: .quiet)
        case .notPublished?, nil:
            AdminChip(text: AdminCopy.notSent, style: .dashed)
        }
    }
}
