import SwiftUI

/// Pushed screens on the Student Home tab. The tab bar stays, as on 07 and 08.
enum StudentHomeRoute: Hashable {
    case answer(MealID)
    case entryQR
}

/// Builds the view model from the environment and reloads whenever the shared data changes.
struct StudentHomeScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session

    var body: some View {
        if let model = StudentHomeViewModel(session: session, repositories: environment.repositories, clock: environment.clock) {
            StudentHomeView(model: model)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// Student Home (03): the top card for the meal at hand, then the next meal's answer row.
struct StudentHomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: StudentHomeViewModel
    @State private var path: [StudentHomeRoute] = []

    init(model: StudentHomeViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                OrbitBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: MLSpacing.s16) {
                        header
                        AsyncContentView(state: model.state,
                                         emptyTitle: "No meals today",
                                         timeZone: model.timeZone,
                                         retry: { await model.load() }) { content in
                            StudentHomeBody(content: content, name: model.name, timeZone: model.timeZone,
                                            answerState: model.answerState(for: content.hero),
                                            onAnswer: { intention in Task { await model.answer(intention, for: content.hero.id) } },
                                            onShowEntry: { path.append(.entryQR) },
                                            onOpenAnswer: { path.append(.answer($0)) })
                        }
                        // With nothing loaded the top card is gone, and the QR must still be reachable.
                        if model.showsEntryFallback {
                            InkActionButton(title: StudentCopy.showEntryQR) { path.append(.entryQR) }
                        }
                    }
                    .padding(.horizontal, MLSpacing.margin)
                    .padding(.bottom, 120)
                }
                .refreshable { await model.load() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: StudentHomeRoute.self) { route in
                Group {
                    switch route {
                    case .answer(let meal):
                        StudentAnswerView(model: model, mealID: meal) { path.removeLast() }
                    case .entryQR:
                        EntryQRView(model: model) { path.removeLast() }
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
            }
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
    }

    private var header: some View {
        HStack(spacing: MLSpacing.s8) {
            OrbitMarkView()
            Text(StudentCopy.brand)
                .font(MLType.bodyEmphasis)
                .foregroundStyle(MLColor.ink)
        }
        .frame(minHeight: MLSize.hit)
        .accessibilityElement(children: .combine)
    }
}

/// The loaded screen. Pure layout: every value comes from `StudentHomeContent`.
struct StudentHomeBody: View {
    let content: StudentHomeContent
    let name: String
    let timeZone: TimeZone
    let answerState: MealAnswerState
    let onAnswer: (MealIntention) -> Void
    let onShowEntry: () -> Void
    let onOpenAnswer: (MealID) -> Void

    private var meal: Meal { content.hero.meal }
    private var serving: String {
        StudentCopy.serving(MLFormat.timeRange(meal.startsAt, meal.endsAt, in: timeZone))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            ScreenTitleBlock(title: StudentCopy.greeting(name), subtitle: StudentFormat.day(content.today, in: timeZone))
            topCard
            if let next = content.nextMeal {
                NextMealRow(card: next, now: content.today, timeZone: timeZone) { onOpenAnswer(next.id) }
            }
            VStack(spacing: MLSpacing.s4) {
                Text(StudentCopy.footerLocked)
                Text(StudentCopy.footerPlan)
            }
            .font(MLType.secondary)
            .foregroundStyle(MLColor.inkSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, MLSpacing.s8)
        }
    }

    private var topCard: some View {
        HeroCard {
            HStack(alignment: .center) {
                HeroEyebrow(label: StudentCopy.eyebrow(meal.slot))
                Spacer(minLength: MLSpacing.s8)
                chip
            }
            Text(title)
                .font(MLType.heroTitle)
                .foregroundStyle(MLColor.onHero)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, MLSpacing.s12)
            Text(detail)
                .font(MLType.body)
                .foregroundStyle(MLColor.onHeroSecondary)
                .padding(.top, MLSpacing.s4)
            if content.hero.answer == nil {
                HeroAnswerRow(state: answerState, attendingTitle: StudentCopy.imIn, onAnswer: onAnswer, onShowEntry: onShowEntry)
                    .padding(.top, MLSpacing.s16)
                if !content.hero.isAnswerOpen {
                    Text(StudentCopy.answersClosed(StudentFormat.shortTime(content.hero.cutoff, in: timeZone)))
                        .font(MLType.secondary)
                        .foregroundStyle(MLColor.onHeroSecondary)
                        .padding(.top, MLSpacing.s12)
                }
            } else {
                HeroSurfaceButton(title: StudentCopy.showEntryQR, action: onShowEntry)
                    .padding(.top, MLSpacing.s16)
            }
        }
    }

    @ViewBuilder
    private var chip: some View {
        switch content.hero.answer {
        case .attending?:
            HeroStatusChip(text: StudentCopy.imIn, style: .lime, showsCheck: true)
        case .skipping?:
            HeroStatusChip(text: StudentCopy.skipped, style: .outline)
        case .notSure?:
            HeroStatusChip(text: StudentCopy.notSure, style: .outline)
        case nil:
            HeroStatusChip(text: StudentCopy.notAnswered, style: .dashed)
        }
    }

    private var title: String {
        switch content.hero.answer {
        case .attending?: return StudentCopy.youreIn(meal.slot)
        case .skipping?: return StudentCopy.youSkipped(meal.slot)
        case .notSure?: return StudentCopy.youreNotSure(meal.slot)
        case nil: return StudentCopy.mealToday(meal.slot)
        }
    }

    private var detail: String {
        switch content.hero.answer {
        case .skipping?: return StudentCopy.canStillEat
        case .notSure?: return StudentCopy.notSureCanEat
        case .attending?, nil: return serving
        }
    }
}

/// The next meal's row (03): its question or the answer given, and one action.
struct NextMealRow: View {
    let card: StudentMealCard
    let now: Date
    let timeZone: TimeZone
    let onOpen: () -> Void

    private var slot: MealSlot { card.meal.slot }
    private var cutoffTime: String { StudentFormat.shortTime(card.cutoff, in: timeZone) }
    private var timeLeft: String { MLFormat.elapsed(minutes: MLFormat.minutes(from: now, to: card.cutoff)) }

    private var title: String {
        switch card.answer {
        case .attending?: return StudentCopy.youreIn(slot)
        case .skipping?: return StudentCopy.youSkipped(slot)
        case .notSure?: return StudentCopy.youreNotSure(slot)
        case nil: return StudentCopy.youInFor(slot)
        }
    }

    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 18))
                .foregroundStyle(MLColor.ink)
                .frame(width: MLSize.iconSquare, height: MLSize.iconSquare)
                .background(RoundedRectangle(cornerRadius: MLRadius.icon, style: .continuous).fill(MLColor.fillQuiet))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(card.answer == nil ? StudentCopy.decideBy(cutoffTime, left: timeLeft) : StudentCopy.changeBy(cutoffTime, left: timeLeft))
                    .font(MLType.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: MLSpacing.s8)
            action
        }
        .padding(MLSpacing.s12)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
    }

    @ViewBuilder
    private var action: some View {
        if card.answer == nil {
            Button(action: onOpen) {
                Text(StudentCopy.answer)
                    .font(MLType.bodyEmphasis)
                    .foregroundStyle(MLColor.onHero)
                    .padding(.horizontal, MLSpacing.s16)
                    .frame(minHeight: MLSize.hit)
                    .background(Capsule().fill(MLColor.ink))
            }
            .buttonStyle(.plain)
        } else {
            CompactPillButton(title: StudentCopy.change, action: onOpen)
        }
    }
}
