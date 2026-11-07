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

/// Today (A01): the day line, the mess tile, the six headcount values and what needs the Food Head.
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
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    StaffHeader(initials: AdminCopy.initials(model.context.account.displayName), onAvatarTap: openMore)
                    AsyncContentView(state: model.state,
                                     emptyTitle: AdminCopy.noMealTitle,
                                     emptyMessage: AdminCopy.noMealDetail,
                                     timeZone: model.context.mess.timeZone,
                                     retry: { await model.load() }) { content in
                        AdminTodayBody(content: content, displayName: model.context.account.displayName,
                                       onSelect: { slot in Task { await model.select(slot) } },
                                       open: { path.append($0) },
                                       openCase: { safetyCase in
                                           Task { path.append(.page(await model.safetyPage(for: safetyCase))) }
                                       })
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, 120)
            }
            .refreshable { await model.load() }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: AdminRoute.self) { route in
            switch route {
            case .headcount:
                // A second tap during the pop finds the path already empty, and removeLast would crash.
                AdminHeadcountView(model: model) { _ = path.popLast() }
            case .live:
                AdminLiveMealView(model: model, nav: nav)
            case .page(let page):
                AdminPageDestination(page: page, nav: nav)
            case .notImplemented(let title):
                NotImplementedView(title: title)
            }
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
    }
}

/// The loaded screen. Pure layout: every value comes from `AdminTodayContent`.
struct AdminTodayBody: View {
    let content: AdminTodayContent
    let displayName: String
    let onSelect: (MealSlot) -> Void
    let open: (AdminRoute) -> Void
    let openCase: (SOSCase) -> Void

    private var timeZone: TimeZone { content.mess.timeZone }
    private var mealName: String { MLFormat.mealSlot(content.selectedSlot) }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s20) {
            HStack(alignment: .lastTextBaseline, spacing: MLSpacing.s12) {
                Text(AdminCopy.greeting(displayName))
                    .font(MLType.largeTitle)
                    .foregroundStyle(MLColor.ink)
                Spacer(minLength: 0)
                Text(AdminCopy.dayLine(content.now, in: timeZone))
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .fixedSize()
            }
            AdminDayLine(nodes: content.nodes, selected: content.selectedSlot, onSelect: onSelect)
            ForEach(content.safetyCases) { safetyCase in
                safetyCard(safetyCase)
            }
            if let due = content.otherMesses?.headcountDue {
                Text(AdminCopy.headcountDue(meal: mealName, time: MLFormat.time(due, in: timeZone)))
                    .font(MLType.bodyEmphasis)
                    .foregroundStyle(MLColor.ink)
            }
            AdminMessGrid(content: content, open: open)
            needsYou
            VStack(alignment: .leading, spacing: MLSpacing.s8) {
                AdminLabel(text: AdminCopy.headcountSection(mealName))
                AdminHeadcountValuesCard(values: content.values)
                AdminHeadcountStatusRows(headcount: content.meal?.headcount, timeZone: timeZone)
            }
        }
    }

    @ViewBuilder
    private func safetyCard(_ safetyCase: SOSCase) -> some View {
        HeroCard {
            HeroEyebrow(label: AdminCopy.safetyOpen(MLFormat.elapsed(minutes: MLFormat.minutes(from: safetyCase.raisedAt,
                                                                                                to: content.now))),
                        showsDot: true)
            Text(safetyCase.title)
                .font(MLType.title2)
                .foregroundStyle(MLColor.onHero)
                .padding(.top, MLSpacing.s8)
            Text(AdminCopy.safetyDetail(place: safetyCase.place, time: MLFormat.time(safetyCase.raisedAt, in: timeZone)))
                .font(MLType.body)
                .foregroundStyle(MLColor.onHeroSecondary)
                .padding(.top, MLSpacing.s4)
            Button {
                openCase(safetyCase)
            } label: {
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

    @ViewBuilder
    private var needsYou: some View {
        if content.visibleShortages.isEmpty && content.visibleReviews.isEmpty {
            Text(AdminCopy.nothingNeedsYou)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
                .padding(MLSpacing.s20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    AdminLabel(text: AdminCopy.needsYou)
                    Spacer()
                    if content.hasMoreShortages {
                        TextLinkButton(title: AdminCopy.seeAll) { open(.live) }
                    }
                }
                .padding(.bottom, 6)
                ForEach(content.visibleShortages) { shortage in
                    needsYouRow(title: AdminCopy.needsYouTitle(dish: shortage.dishName, level: MLFormat.shortageLevel(shortage.level)),
                                detail: AdminCopy.needsYouDetail(mess: content.mess.name, meal: mealName),
                                chip: AdminCopy.liveAction, style: .lime) { open(.live) }
                }
                ForEach(content.visibleReviews) { review in
                    needsYouRow(title: AdminCopy.reviewTitle(review.meal), detail: AdminCopy.reviewDetail(review.meal, in: timeZone),
                                chip: AdminScreenCopy.review, style: .outline) { open(.page(.meal(review.id))) }
                }
            }
        }
    }

    private func needsYouRow(title: String, detail: String, chip: String, style: AdminChipStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MLType.staffBody)
                        .foregroundStyle(MLColor.ink)
                    Text(detail)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: MLSpacing.s8)
                AdminChip(text: chip, style: style)
            }
            .padding(.vertical, MLSpacing.s12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(chip)
        .overlay(alignment: .top) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
    }
}
