import SwiftUI

/// Builds the view model from the environment, and owns it so Today and the headcount page show the same state.
struct AdminTodayScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let context: AdminContext
    @Binding var path: [AdminRoute]
    let openMore: () -> Void

    var body: some View {
        AdminTodayView(model: AdminTodayViewModel(context: context, repositories: environment.repositories,
                                                  clock: environment.clock),
                       path: $path, openMore: openMore)
    }
}

/// Today (A01): the day line, the mess tile, the six headcount values and what needs the Food Head.
struct AdminTodayView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: AdminTodayViewModel
    @Binding var path: [AdminRoute]
    let openMore: () -> Void

    init(model: AdminTodayViewModel, path: Binding<[AdminRoute]>, openMore: @escaping () -> Void) {
        _model = State(initialValue: model)
        _path = path
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
                                       open: { path.append($0) })
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
            AdminMessTile(content: content, openHeadcount: { open(.headcount) })
            VStack(alignment: .leading, spacing: MLSpacing.s8) {
                SectionHeader(title: AdminCopy.headcountSection(mealName))
                AdminHeadcountValuesCard(values: content.values)
                AdminHeadcountStatusRows(headcount: content.meal?.headcount, timeZone: timeZone)
            }
            needsYou
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
                open(.notImplemented(title: AdminCopy.safetyCase))
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
        if content.visibleShortages.isEmpty {
            Text(AdminCopy.nothingNeedsYou)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
                .padding(MLSpacing.s20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: AdminCopy.needsYou,
                              actionTitle: content.hasMoreShortages ? AdminCopy.seeAll : nil,
                              onAction: content.hasMoreShortages ? { open(.notImplemented(title: AdminCopy.needsYou)) } : nil)
                ForEach(content.visibleShortages) { shortage in
                    needsYouRow(shortage)
                }
            }
        }
    }

    private func needsYouRow(_ shortage: Shortage) -> some View {
        HStack(spacing: MLSpacing.s12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(AdminCopy.needsYouTitle(dish: shortage.dishName, level: MLFormat.shortageLevel(shortage.level)))
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                Text(AdminCopy.needsYouDetail(mess: content.mess.name, meal: mealName))
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            Spacer(minLength: MLSpacing.s8)
            CompactPillButton(title: AdminCopy.liveAction) {
                open(.notImplemented(title: AdminCopy.liveMeal))
            }
        }
        .padding(.vertical, MLSpacing.s12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
    }
}
