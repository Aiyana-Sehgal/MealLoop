import SwiftUI

/// Kitchen Home: K01 (before), K02 (during), K03 (shortage reported) and K05 / K15 / K16 (after the meal).
struct KitchenHomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    let model: KitchenHomeViewModel
    let sos: KitchenSOSViewModel
    let open: (KitchenRoute) -> Void
    let onOpenSOS: () -> Void
    let onToast: (String) -> Void

    @State private var isReporting = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    KitchenHeader(initials: model.session.staffInitials) {
                        router.selectedStaffTab = .me
                    }
                    AsyncContentView(state: model.state,
                                     emptyTitle: "No meal today",
                                     emptyMessage: "The next meal will show here.",
                                     timeZone: model.session.mess.timeZone,
                                     retry: { await model.load() }) { content in
                        KitchenHomeBody(content: content, now: environment.clock.now(), failed: model.failedReports,
                                        open: open, onReport: { isReporting = true },
                                        onRetry: { failed in Task { await model.retry(failed) } })
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, KitchenLayout.scrollBottomInset)
            }
            .refreshable { await model.load() }
            if let current = sos.current {
                SOSEdgeTab(count: sos.cases.count, isClaimedByYou: sos.isClaimedByYou,
                           claimedStatus: KitchenCopy.tabChecking, action: onOpenSOS)
                    .padding(.top, MLSize.avatar + MLSpacing.s24)
                    .id(current.id)
            }
        }
        .mlSheet(isPresented: $isReporting) {
            KitchenShortageSheet(model: model, onClose: { isReporting = false }) { outcome in
                isReporting = false
                switch outcome {
                case .sent:
                    onToast(KitchenCopy.sentTo(model.session.supervisorName))
                case .mealEnded(let at):
                    open(.mealEndedWhileReporting(at))
                case .needsDish, .alreadyReported, .couldNotSend:
                    break
                }
            }
        }
    }
}

/// The staff header with its own avatar label, so it never reads the same as the Me tab.
struct KitchenHeader: View {
    let initials: String
    let onAvatarTap: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: MLSpacing.s8) {
                OrbitMarkView()
                Text("MealLoop")
                    .font(MLType.bodyEmphasis)
                    .foregroundStyle(MLColor.ink)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            Button(action: onAvatarTap) {
                Text(initials)
                    .font(MLType.bodyEmphasis)
                    .foregroundStyle(MLColor.lime)
                    .frame(width: MLSize.avatar, height: MLSize.avatar)
                    .background(Circle().fill(MLColor.ink))
            }
            .buttonStyle(.plain)
            .frame(minWidth: MLSize.hit, minHeight: MLSize.hit)
            .accessibilityLabel(KitchenCopy.avatarLabel)
        }
    }
}

/// The large count on a Kitchen card, regular weight as on K01 and K02. Shows "—" when missing, never 0.
struct KitchenHeroNumber: View {
    let value: Int?
    var size: CGFloat = KitchenLayout.heroNumber

    var body: some View {
        Text(value.map { String($0) } ?? "—")
            .font(.system(size: size, weight: .regular, design: .monospaced))
            .foregroundStyle(MLColor.onHero)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}

/// The loaded screen. Pure layout: every value comes from `KitchenHomeContent`.
struct KitchenHomeBody: View {
    let content: KitchenHomeContent
    let now: Date
    let failed: [KitchenFailedReport]
    let open: (KitchenRoute) -> Void
    let onReport: () -> Void
    let onRetry: (KitchenFailedReport) -> Void

    private var timeZone: TimeZone { content.mess.timeZone }
    private var mealName: String { MLFormat.mealSlot(content.meal.slot) }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            ScreenTitleBlock(title: mealName, subtitle: subtitle)
            switch content.phase {
            case .beforeMeal(let forecast):
                beforeMeal(forecast)
            case .duringMeal(let entered, let minutes, _):
                duringMeal(entered: entered, minutes: minutes)
            case .afterMeal(let finalEntries, _, let waste):
                afterMeal(finalEntries: finalEntries, waste: waste)
            }
        }
    }

    private var subtitle: String {
        if case .afterMeal(_, let closedAt?, _) = content.phase {
            return "\(content.mess.name) · \(KitchenCopy.ended(at: MLFormat.time(closedAt, in: timeZone)))"
        }
        return "\(content.mess.name) · \(MLFormat.timeRange(content.meal.startsAt, content.meal.endsAt, in: timeZone))"
    }

    // MARK: K01 · before the meal

    @ViewBuilder
    private func beforeMeal(_ forecast: Forecast) -> some View {
        HeroCard {
            HeroEyebrow(label: KitchenCopy.forecastEyebrow)
            KitchenHeroNumber(value: forecast.diners)
                .padding(.top, MLSpacing.s12)
            Text(KitchenCopy.forecastCaption)
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.onHeroSecondary)
            if forecast.diners == nil {
                Text(KitchenCopy.forecastNotReady)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.onHeroSecondary)
                    .padding(.top, MLSpacing.s4)
            }
        }
        VStack(spacing: 0) {
            Rectangle().fill(MLColor.border).frame(height: 1)
            QuietRow(title: "\(KitchenCopy.menuRow) \(mealName)") {
                open(.menu(content.meal))
            }
            QuietRow(title: KitchenCopy.pastMealsRow) {
                open(.history)
            }
        }
    }

    // MARK: K02 / K03 · during the meal

    @ViewBuilder
    private func duringMeal(entered: CountReading, minutes: Int) -> some View {
        MealProgressChip(text: KitchenCopy.mealInProgress(MLFormat.elapsed(minutes: minutes)))
        HeroCard {
            HeroEyebrow(label: KitchenCopy.liveEyebrow, showsDot: true,
                        time: entered.asOf.map { MLFormat.time($0, in: timeZone) })
            KitchenHeroNumber(value: entered.value)
                .padding(.top, MLSpacing.s4)
            Text(KitchenCopy.liveCaption)
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.onHeroSecondary)
            LimeActionButton(title: KitchenCopy.reportShortage, systemImage: "exclamationmark.triangle", action: onReport)
                .padding(.top, MLSpacing.s20)
        }
        // No row at all when nothing has been reported.
        ForEach(failed) { report in
            ShortageRow(title: KitchenCopy.shortageTitle(dish: report.report.dishName, level: MLFormat.shortageLevel(report.report.level)),
                        detail: KitchenCopy.couldNotSend, retryTitle: KitchenCopy.retry,
                        onRetry: { onRetry(report) }, systemImage: "exclamationmark.triangle")
        }
        ForEach(content.visibleShortages) { shortage in
            KitchenShortageStatusRow(shortage: shortage, timeZone: timeZone)
        }
        if content.hiddenShortageCount > 0 {
            QuietRow(title: KitchenCopy.seeAll, value: "\(content.hiddenShortageCount)") {
                open(.shortages)
            }
        }
        VStack(spacing: 0) {
            Rectangle().fill(MLColor.border).frame(height: 1)
            QuietRow(title: KitchenCopy.pastMealsRow) {
                open(.history)
            }
        }
    }

    // MARK: K05 / K15 / K16 · after the meal

    @ViewBuilder
    private func afterMeal(finalEntries: CountReading, waste: WasteReportSummary) -> some View {
        HeroCard {
            HeroEyebrow(label: KitchenCopy.mealClosedEyebrow, showsDot: true)
            Text(KitchenCopy.hasEnded(mealName))
                .font(MLType.heroTitle)
                .foregroundStyle(MLColor.onHero)
                .padding(.top, MLSpacing.s8)
            Text(KitchenCopy.finalEntriesLabel)
                .font(MLType.body)
                .foregroundStyle(MLColor.onHeroSecondary)
                .padding(.top, MLSpacing.s16)
            if let value = finalEntries.value {
                KitchenHeroNumber(value: value, size: KitchenLayout.finalNumber)
            } else {
                // Missing is never shown as zero.
                Text(KitchenCopy.unavailable)
                    .font(MLType.heroTitle)
                    .foregroundStyle(MLColor.onHero)
            }
        }
        wasteCard(waste)
        VStack(spacing: 0) {
            Rectangle().fill(MLColor.border).frame(height: 1)
            QuietRow(title: KitchenCopy.pastMealsRow) {
                open(.history)
            }
        }
    }

    private func wasteCard(_ waste: WasteReportSummary) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            HStack(alignment: .firstTextBaseline) {
                Text(KitchenCopy.wasteReportTitle)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                Spacer()
                wasteStatus(waste)
            }
            switch waste.status {
            case .notStarted:
                InkActionButton(title: KitchenCopy.recordWaste) { open(.recordWaste(content.meal)) }
            case .draft(let savedAt):
                HStack(spacing: MLSpacing.s4) {
                    Text(KitchenCopy.draftProgress(done: waste.completedFieldCount, total: waste.totalFieldCount))
                    Text(MLFormat.time(savedAt, in: timeZone)).font(MLType.monoBody)
                }
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                InkActionButton(title: KitchenCopy.continueWaste) { open(.recordWaste(content.meal)) }
            case .recorded:
                if let until = WasteReportPolicy.editableUntil(waste.status) {
                    Text(now < until ? KitchenCopy.editUntil(MLFormat.time(until, in: timeZone)) : KitchenCopy.editingClosed)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                InkActionButton(title: KitchenCopy.viewReport) { open(.pastMeal(content.meal.id)) }
            }
        }
        .padding(MLSpacing.s20)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
    }

    @ViewBuilder
    private func wasteStatus(_ waste: WasteReportSummary) -> some View {
        switch waste.status {
        case .notStarted:
            StatusText(text: "Not started", dot: .empty)
        case .draft:
            StatusText(text: "Draft", dot: .dashed)
        case .recorded(let savedAt):
            StatusText(text: "\(KitchenCopy.recorded()) \(MLFormat.time(savedAt, in: timeZone))", dot: .filled)
        }
    }
}

/// One report's status: Sent with its time, or "Ravi saw it" once that is confirmed.
struct KitchenShortageStatusRow: View {
    let shortage: Shortage
    let timeZone: TimeZone

    private var title: String {
        KitchenCopy.shortageTitle(dish: shortage.dishName, level: MLFormat.shortageLevel(shortage.level))
    }

    var body: some View {
        switch shortage.delivery {
        case .sent(let at):
            ShortageRow(title: title, detail: "Sent", detailTime: MLFormat.time(at, in: timeZone))
        case .seen(_, let by):
            ShortageRow(title: title, detail: KitchenCopy.seenBy(by))
        case .couldNotSend:
            ShortageRow(title: title, detail: KitchenCopy.couldNotSend, systemImage: "exclamationmark.triangle")
        }
    }
}
