import SwiftUI

/// Pass Desk Home: P02 (before), during the meal (owner ruling, Prompt 2B: the live code and colour and three rows, no
/// keypad and no record), P15 (with the SOS tab) and P13 (after).
struct PassDeskHomeView: View {
    @Environment(AppRouter.self) private var router
    let model: PassDeskHomeViewModel
    let sos: DoorSOSViewModel
    let openProblems: Int
    let onReload: () async -> Void
    let onOpenSOS: () -> Void
    @Binding var path: [PassDeskRoute]

    var body: some View {
        GeometryReader { proxy in
            page(compact: proxy.size.height < PassDeskLayout.compactHeightLimit)
        }
        .task(id: model.state.value?.phase == .duringMeal) {
            guard model.state.value?.phase == .duringMeal else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await model.code.tick()
            }
        }
    }

    private func page(compact: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    StaffHeader(initials: model.session.staffInitials) {
                        router.selectedStaffTab = .me
                    }
                    AsyncContentView(state: model.state,
                                     emptyTitle: PassDeskCopy.noMealTitle,
                                     emptyMessage: PassDeskCopy.noMealDetail,
                                     timeZone: model.session.mess.timeZone,
                                     retry: onReload) { content in
                        PassDeskHomeBody(content: content, mess: model.session.mess, code: model.code,
                                         openProblems: openProblems, compact: compact, open: { path.append($0) })
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, PassDeskLayout.scrollBottomInset)
            }
            .refreshable { await onReload() }
            if let current = sos.current {
                SOSEdgeTab(count: sos.cases.count, isClaimedByYou: sos.isClaimedByYou,
                           claimedStatus: PassDeskCopy.youreChecking, action: onOpenSOS)
                    .padding(.top, MLSize.avatar + MLSpacing.s24)
                    .id(current.id)
            }
        }
    }
}

/// The loaded screen. Pure layout: every value comes from `PassDeskHomeContent`.
struct PassDeskHomeBody: View {
    let content: PassDeskHomeContent
    let mess: Mess
    let code: PassDeskLiveCodeModel
    let openProblems: Int
    let compact: Bool
    let open: (PassDeskRoute) -> Void

    private var mealName: String { MLFormat.mealSlot(content.meal.slot) }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            ScreenTitleBlock(title: content.phase == .duringMeal ? PassDeskSimpleCopy.title : mealName, subtitle: subtitle)
                .padding(.top, content.phase == .duringMeal ? 0 : MLSpacing.s4)
            switch content.phase {
            case .beforeMeal(let opensAt):
                waitingCard(opensAt)
                StaffHomeRow(symbol: "magnifyingglass", title: PassDeskSimpleCopy.checkLastFour) {
                    open(.checkDigits(content.meal))
                }
                StaffHomeRow(symbol: "arrow.right", title: PassDeskCopy.requestNewPass) {
                    open(.requestPass(content.meal, digits: nil))
                }
                StaffHomeRow(symbol: "exclamationmark.triangle", title: PassDeskCopy.reportProblem) {
                    open(.reportProblem)
                }
            case .duringMeal:
                PassDeskCodeCard(code: code.current, secondsLeft: code.secondsLeft, isUnavailable: code.isUnavailable)
                quietRows {
                    QuietRow(title: PassDeskCopy.requestNewPass) { open(.requestPass(content.meal, digits: nil)) }
                    QuietRow(title: PassDeskCopy.reportProblem) { open(.reportProblem) }
                    QuietRow(title: PassDeskSimpleCopy.checkLastFour) { open(.checkDigits(content.meal)) }
                        .accessibilityIdentifier("passdesk.checkLastFour")
                }
            case .afterMeal:
                endedCard
                quietRows {
                    StaffMeRow(title: PassDeskCopy.newPassRequests, value: PassDeskCopy.waitingCount(content.waitingRequests)) {
                        open(.requests)
                    }
                    QuietRow(title: PassDeskCopy.openProblems, value: String(openProblems)) { open(.openProblems) }
                    QuietRow(title: PassDeskCopy.reportProblem) { open(.reportProblem) }
                }
            }
        }
    }

    private var subtitle: String {
        if case .afterMeal(let closedAt?) = content.phase {
            return PassDeskCopy.endedSubtitle(mess: mess.name, time: MLFormat.time(closedAt, in: mess.timeZone))
        }
        if content.phase == .duringMeal {
            return PassDeskSimpleCopy.header(meal: mealName, hours: MLFormat.timeRange(content.meal.startsAt, content.meal.endsAt,
                                                                                       in: mess.timeZone), mess: mess.name)
        }
        return PassDeskCopy.homeSubtitle(mess: mess.name)
    }

    private func quietRows<Rows: View>(@ViewBuilder rows: () -> Rows) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(MLColor.border).frame(height: 1)
            rows()
        }
    }

    private func waitingCard(_ opensAt: Date) -> some View {
        VStack(spacing: MLSpacing.s24) {
            Image(systemName: "ticket")
                .font(.system(size: 44))
                .foregroundStyle(MLColor.onHeroSecondary.opacity(0.5))
                .accessibilityHidden(true)
            Text(PassDeskCopy.checkingOpens(MLFormat.time(opensAt, in: mess.timeZone)))
                .font(MLType.title2)
                .foregroundStyle(MLColor.onHero)
                .multilineTextAlignment(.center)
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, minHeight: compact ? PassDeskLayout.compactWaitingHeight : PassDeskLayout.waitingHeight)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.heroBackground))
        .accessibilityElement(children: .combine)
    }

    private var endedCard: some View {
        HeroCard {
            StaffHeroLabel(text: PassDeskCopy.mealEndedEyebrow)
            Text(PassDeskCopy.specialHasEnded(mealName))
                .font(MLType.heroTitle)
                .foregroundStyle(MLColor.onHero)
                .padding(.top, MLSpacing.s8)
            Text(PassDeskCopy.checkingClosed)
                .font(MLType.body)
                .foregroundStyle(MLColor.onHeroSecondary)
                .padding(.top, MLSpacing.s8)
            Text(PassDeskCopy.specialMealsRecorded)
                .font(MLType.body)
                .foregroundStyle(MLColor.onHeroSecondary)
                .padding(.top, MLSpacing.s24)
            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                Text(content.count.recorded.value.map(String.init) ?? "—")
                    .font(MLType.heroNumber)
                    .foregroundStyle(MLColor.onHero)
                if let passes = PassDeskCopy.ofPasses(content.count.passes) {
                    Text(passes)
                        .font(MLType.monoBody)
                        .foregroundStyle(MLColor.onHeroSecondary)
                }
            }
        }
    }
}

/// An outlined action on the black card.
struct PassDeskHeroOutlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.onHero)
                .frame(maxWidth: .infinity, minHeight: MLSize.buttonCompact)
                .overlay(Capsule().stroke(MLColor.onHero, lineWidth: 1.5))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
