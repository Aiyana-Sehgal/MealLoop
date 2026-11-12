import SwiftUI

/// Builds the view model from the environment, and owns it so Today and the headcount page show the same state.
struct AdminTodayScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let context: AdminContext
    @Binding var path: [AdminRoute]
    let nav: AdminNav
    let openMore: () -> Void

    var body: some View {
        AdminTodayView(model: AdminTodayViewModel(context: context, repositories: environment.repositories,
                                                  clock: environment.clock),
                       path: $path, nav: nav, openMore: openMore)
    }
}

/// Today (owner mocks, 12 Nov 2026): the meal's headcount for the signed-in mess as a tab root, with Needs you below.
/// The Super Admin's adds a switcher for the other messes.
struct AdminTodayView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: AdminTodayViewModel
    @Binding var path: [AdminRoute]
    let nav: AdminNav
    let openMore: () -> Void

    init(model: AdminTodayViewModel, path: Binding<[AdminRoute]>, nav: AdminNav, openMore: @escaping () -> Void) {
        _model = State(initialValue: model)
        _path = path
        self.nav = nav
        self.openMore = openMore
    }

    var body: some View {
        // Both roles (owner mocks, 12 Nov 2026): the Super Admin's adds the mess switcher.
        AdminHeadcountView(model: model, open: { path.append($0) }, onBack: nil, isTodayRoot: true,
                           openCase: { safetyCase in Task { path.append(.page(await model.safetyPage(for: safetyCase))) } })
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: AdminRoute.self) { route in
            switch route {
            case .headcount:
                // A second tap during the pop finds the path already empty, and removeLast would crash.
                AdminHeadcountDetailView(model: model) { _ = path.popLast() }
            case .live:
                AdminLiveMealView(model: model, nav: nav)
            case .page(let page):
                AdminPageDestination(page: page, nav: nav)
            case .needsYou:
                AdminNeedsYouView(model: model, nav: nav) { path.append($0) }
            case .notImplemented(let title):
                NotImplementedView(title: title)
            }
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
    }
}

/// An open safety case, at the top of Today until it is handled.
struct AdminSafetyCaseCard: View {
    let safetyCase: SOSCase
    let now: Date
    let timeZone: TimeZone
    let open: () -> Void

    var body: some View {
        HeroCard {
            HeroEyebrow(label: AdminCopy.safetyOpen(MLFormat.elapsed(minutes: MLFormat.minutes(from: safetyCase.raisedAt, to: now))),
                        showsDot: true)
            Text(safetyCase.title)
                .font(MLType.title2)
                .foregroundStyle(MLColor.onHero)
                .padding(.top, MLSpacing.s8)
            Text(AdminCopy.safetyDetail(place: safetyCase.place, time: MLFormat.time(safetyCase.raisedAt, in: timeZone)))
                .font(MLType.body)
                .foregroundStyle(MLColor.onHeroSecondary)
                .padding(.top, MLSpacing.s4)
            Button(action: open) {
                Text(AdminCopy.openCase)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.onHero)
                    .frame(maxWidth: .infinity, minHeight: MLSize.staffButton)
                    .overlay(Capsule().stroke(MLColor.onHero, lineWidth: 1.5))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, MLSpacing.s16)
        }
    }
}

/// One Needs you row, the same on Today and on See all.
struct AdminNeedsYouRow: View {
    let item: AdminNeedsYouItem
    let content: AdminTodayContent
    let open: (AdminRoute) -> Void

    private var timeZone: TimeZone { content.mess.timeZone }

    var body: some View {
        switch item {
        case .shortage(let shortage):
            NeedsYouRow(title: AdminCopy.needsYouTitle(dish: shortage.dishName, level: MLFormat.shortageLevel(shortage.level)),
                        detail: AdminCopy.needsYouDetail(mess: content.mess.name, meal: MLFormat.mealSlot(content.selectedSlot)),
                        actionName: AdminCopy.liveAction, action: { open(.live) }) {
                NeedsYouPill(title: AdminCopy.liveAction, isLime: true)
            }
        case .review(let review):
            NeedsYouRow(title: AdminCopy.reviewTitle(review.meal), detail: AdminCopy.reviewDetail(review.meal, in: timeZone),
                        actionName: AdminScreenCopy.review, action: { open(.page(.meal(review.id))) }) {
                NeedsYouPill(title: AdminScreenCopy.review)
            }
        case .noReply(let mess):
            // The South headcount page holds the reminder and the vendor's contact.
            NeedsYouRow(title: AdminCopy.notReplied(mess.name),
                        detail: AdminCopy.vendorSince(mess.sentAt.map { MLFormat.time($0, in: timeZone) } ?? AdminFormat.missing),
                        actionName: AdminCopy.remind, action: { open(.page(.messHeadcount(mess.id, mess.slot))) }) {
                NeedsYouPill(title: AdminCopy.remind)
            }
        }
    }
}

/// Today › See all: every shortage and review waiting for the admin, as hairline rows with their chips. Fills the
/// screen with the list; one honest line when nothing is waiting.
struct AdminNeedsYouView: View {
    let model: AdminTodayViewModel
    let nav: AdminNav
    let open: (AdminRoute) -> Void

    var body: some View {
        AdminPageScaffold(title: AdminVotesRewardsCopy.needsYouTitle, onBack: nav.pop) {
            if let content = model.state.value {
                if content.needsYouItems.isEmpty {
                    Text(AdminVotesRewardsCopy.nothingNeedsYou).mlFont(.body).foregroundStyle(MLColor.inkSecondary)
                }
                VStack(spacing: 0) {
                    ForEach(content.needsYouItems) { item in
                        AdminNeedsYouRow(item: item, content: content, open: open)
                    }
                }
                // Blank-band audit: the pages that hold the rest of the day, so the list never ends in empty space.
                AdminLabel(text: AdminSearchCopy.jumpTo).padding(.top, MLSpacing.s16)
                AdminGroupCard {
                    AdminHubRow(title: AdminSingleMessCopy.liveMeal) { open(.live) }
                    AdminHubRow(title: AdminScreenCopy.notAnswered) { open(.page(.notAnswered)) }
                    AdminHubRow(title: AdminScreenCopy.safetyCases) { open(.page(.safetyCases)) }
                    AdminHubRow(title: AdminScreenCopy.weeklyReport, isLast: true) { open(.page(.weeklyReport)) }
                }
            }
        }
    }
}
