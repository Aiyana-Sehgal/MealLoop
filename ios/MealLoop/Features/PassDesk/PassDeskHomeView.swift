import SwiftUI

/// Pass Desk Home: P02 (before), P03 (during, keypad on Home), P15 (with the SOS tab) and P13 (after).
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
            page(keyHeight: proxy.size.height < PassDeskLayout.compactHeightLimit
                 ? PassDeskLayout.compactKeyHeight : PassDeskLayout.keyHeight)
        }
    }

    private func page(keyHeight: CGFloat) -> some View {
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
                        PassDeskHomeBody(content: content, mess: model.session.mess, flow: model.flow,
                                         openProblems: openProblems, keyHeight: keyHeight, open: { path.append($0) })
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
    let flow: PassDeskCheckFlow
    let openProblems: Int
    let keyHeight: CGFloat
    let open: (PassDeskRoute) -> Void

    private var mealName: String { MLFormat.mealSlot(content.meal.slot) }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            ScreenTitleBlock(title: mealName, subtitle: subtitle)
            switch content.phase {
            case .beforeMeal(let opensAt):
                waitingCard(opensAt)
                IconCardRow(symbol: "magnifyingglass", title: PassDeskCopy.lookUp, detail: PassDeskCopy.lookUpDetail) {
                    open(.lookUp(content.meal))
                }
                IconCardRow(symbol: "arrow.right", title: PassDeskCopy.requestNewPass) {
                    open(.requestPass(content.meal, digits: nil))
                }
                IconCardRow(symbol: "exclamationmark.triangle", title: PassDeskCopy.reportProblem) {
                    open(.reportProblem)
                }
            case .duringMeal:
                MealProgressChip(text: PassDeskCopy.mealInProgress(PassDeskCopy.recordedOf(content.count.recorded.value,
                                                                                           content.count.passes)))
                PassDeskDigitCard(flow: flow, mess: mess)
                KeyPad(isEnabled: !flow.isChecking, keyHeight: keyHeight) { digit in
                    Task { await flow.type(digit) }
                } onDelete: {
                    flow.deleteLast()
                }
                quietRows {
                    QuietRow(title: PassDeskCopy.requestNewPass) { open(.requestPass(content.meal, digits: nil)) }
                    QuietRow(title: PassDeskCopy.reportProblem) { open(.reportProblem) }
                }
            case .afterMeal:
                endedCard
                quietRows {
                    QuietRow(title: PassDeskCopy.newPassRequests, value: PassDeskCopy.waitingCount(content.waitingRequests)) {
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
        return PassDeskCopy.homeSubtitle(mess: mess.name)
    }

    private func quietRows<Rows: View>(@ViewBuilder rows: () -> Rows) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(MLColor.border).frame(height: 1)
            rows()
        }
    }

    private func waitingCard(_ opensAt: Date) -> some View {
        VStack(spacing: MLSpacing.s16) {
            Image(systemName: "ticket")
                .font(.system(size: 44))
                .foregroundStyle(MLColor.onHeroSecondary.opacity(0.5))
                .accessibilityHidden(true)
            Text(PassDeskCopy.checkingOpens(MLFormat.time(opensAt, in: mess.timeZone)))
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.onHero)
                .multilineTextAlignment(.center)
        }
        .padding(MLSpacing.s32)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.heroBackground))
        .accessibilityElement(children: .combine)
    }

    private var endedCard: some View {
        HeroCard {
            HeroEyebrow(label: PassDeskCopy.mealEndedEyebrow, showsDot: true)
            Text(PassDeskCopy.specialHasEnded(mealName))
                .font(MLType.title2)
                .foregroundStyle(MLColor.onHero)
                .padding(.top, MLSpacing.s8)
            Text(PassDeskCopy.checkingClosed)
                .font(MLType.body)
                .foregroundStyle(MLColor.onHeroSecondary)
            Text(PassDeskCopy.specialMealsRecorded)
                .font(MLType.body)
                .foregroundStyle(MLColor.onHeroSecondary)
                .padding(.top, MLSpacing.s16)
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

/// The black card with the four boxes (P03). A last four nobody holds is said here, with Try again.
struct PassDeskDigitCard: View {
    let flow: PassDeskCheckFlow
    let mess: Mess

    var body: some View {
        HeroCard {
            HeroEyebrow(label: PassDeskCopy.lastFourDigits)
            DigitBoxes(entry: flow.entry, surface: .hero, accessibilityTitle: PassDeskCopy.lastFourDigits)
                .padding(.top, MLSpacing.s12)
            if let digits = flow.notFoundDigits {
                Text(PassDeskCopy.noStudent(digits, mess: mess.name))
                    .font(MLType.bodyEmphasis)
                    .foregroundStyle(MLColor.onHero)
                    .padding(.top, MLSpacing.s12)
                PassDeskHeroOutlineButton(title: PassDeskCopy.tryAgain) { flow.reset() }
                    .padding(.top, MLSpacing.s12)
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
