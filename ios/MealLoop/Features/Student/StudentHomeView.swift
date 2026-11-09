import SwiftUI

/// Pushed screens on the Student Home tab. The tab bar stays, as on Answer and Entry QR.
enum StudentHomeRoute: Hashable {
    case answer(MealID)
    case entryQR
    case pass
    case crowd
    case report
    case notifications
    case credits
    case creditsHistory
    /// Ticket · Juice (1529:1901), after Get on Credits.
    case rewardTicket(StudentRewardTicketID)
    /// How was lunch? (image student_feedback_01_how_was_lunch).
    case rateMeal(day: Date, slot: MealSlot)
    /// SOS, from "Unsafe or unwell? Use SOS" on the dish feedback sheets (the only way there from them).
    case sos
    /// My feedback, from the follow-up row on the student's own feedback.
    case myFeedback
    /// A page another Student part builds. Until then it says Coming soon.
    case comingSoon(String)

    /// Pages built on `MLScreen`: the system bar, its back button and the swipe-back gesture.
    var usesSystemBar: Bool {
        switch self {
        case .comingSoon: false
        default: true
        }
    }
}

/// Builds the view model from the environment and reloads whenever the shared data changes.
struct StudentHomeScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session

    var body: some View {
        if let model = StudentHomeViewModel(session: session, repositories: environment.repositories, clock: environment.clock) {
            StudentHomeView(model: model, session: session,
                            you: StudentYouViewModel(session: session, repositories: environment.repositories, clock: environment.clock))
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// Student Home: header, greeting, the top card and the rows under it (Home frames, page 07).
struct StudentHomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: StudentHomeViewModel
    @State private var path: [StudentHomeRoute] = []
    /// Meals whose How was … card was answered Good or skipped in this run. Skip for now records nothing.
    @State private var skippedRatings: Set<String> = []
    @State private var skipping: MealID?
    /// Thanks after Good, or Which dish after Not good, on the How was … card (2159:159, 2159:285).
    @State private var feedback: StudentDishFeedbackRequest?
    @Environment(\.studentSelectTab) private var selectTab
    /// For the pages that build their own view models: Special pass and Crowd.
    private let session: Session?
    /// The credits chip reads the Student You balance, so Home, You and Credits show one number (owner ruling,
    /// 7 November). Without it (previews, older tests) the chip keeps the Home extras value.
    @State private var you: StudentYouViewModel?

    init(model: StudentHomeViewModel, session: Session? = nil, you: StudentYouViewModel? = nil) {
        _model = State(initialValue: model)
        self.session = session
        _you = State(initialValue: you)
    }

    /// Nil while the balance is unknown: a missing balance is never shown as zero.
    private var credits: Int? {
        guard let you else { return model.state.value?.extras?.credits }
        return you.credits.value?.balance
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                OrbitBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: MLSpacing.s16) {
                        StudentHomeHeader(credits: credits,
                                          onRewards: { path.append(.credits) },
                                          onReport: { path.append(.report) },
                                          onNotifications: { path.append(.notifications) })
                        greeting
                        content
                    }
                    .padding(.horizontal, MLSpacing.margin)
                    .padding(.top, MLSpacing.s8)
                    .padding(.bottom, StudentMetric.scrollBottom)
                }
                .refreshable { await model.load() }
                StudentScrollFade()
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: StudentHomeRoute.self) { route in
                destination(route)
                    .studentPushedPage(usesSystemBar: route.usesSystemBar)
            }
        }
        .task(id: model.state.value?.lastClosedMeal?.id) {
            await hideRatingCardIfDone()
        }
        .task(id: environment.dataRevision) {
            await model.load()
            await you?.loadCredits()
            await sendKeptFeedback()
        }
        .studentDishFeedback($feedback, context: model.context, repositories: environment.repositories,
                             clock: environment.clock, onSOS: { path.append(.sos) },
                             onCommunity: selectTab.map { select in { select(.community) } },
                             onMyFeedback: { path.append(.myFeedback) })
        .mlSheet(isPresented: Binding(get: { skipping != nil }, set: { if !$0 { skipping = nil } })) {
            if let meal = skipping, let card = model.card(id: meal) {
                WhySkippingSheet(slot: card.meal.slot, onClose: { skipping = nil }) { reason in
                    skipping = nil
                    Task { await model.answer(.skipping, for: meal, reason: reason) }
                }
            }
        }
    }

    @ViewBuilder
    private func destination(_ route: StudentHomeRoute) -> some View {
        switch route {
        case .answer(let meal):
            StudentAnswerView(model: model, mealID: meal, onShowEntry: { path.append(.entryQR) }) { path.removeLast() }
        case .entryQR:
            EntryQRView(model: model) { path.removeLast() }
        case .pass:
            if let session {
                StudentPassScreen(session: session, onOpenCrowd: { path.append(.crowd) }) { path.removeLast() }
            } else {
                StudentComingSoonView(title: StudentCopy.specialPass) { path.removeLast() }
            }
        case .crowd:
            if let session {
                StudentCrowdScreen(session: session) { path.removeLast() }
            } else {
                StudentComingSoonView(title: MealsCopy.crowd) { path.removeLast() }
            }
        case .report:
            if let session {
                StudentReportScreen(session: session) { path.removeLast() }
            } else {
                StudentComingSoonView(title: StudentCopy.reportIssue) { path.removeLast() }
            }
        case .notifications:
            if let session, let you = StudentYouViewModel(session: session, repositories: environment.repositories,
                                                          clock: environment.clock) {
                StudentNotificationsView(model: you) { path.removeLast() }
            } else {
                StudentComingSoonView(title: StudentCopy.notifications) { path.removeLast() }
            }
        case .credits:
            if let session, let you = StudentYouViewModel(session: session, repositories: environment.repositories,
                                                          clock: environment.clock),
               let rewards = StudentRewardsViewModel(session: session, repositories: environment.repositories,
                                                     clock: environment.clock) {
                StudentCreditsView(model: you, rewards: rewards, onHistory: { path.append(.creditsHistory) },
                                   onTicket: { path.append(.rewardTicket($0)) })
            } else {
                StudentComingSoonView(title: StudentCopy.rewards) { path.removeLast() }
            }
        case .creditsHistory:
            if let session, let you = StudentYouViewModel(session: session, repositories: environment.repositories,
                                                          clock: environment.clock) {
                StudentCreditsHistoryView(model: you, rewards: StudentRewardsViewModel(
                    session: session, repositories: environment.repositories, clock: environment.clock)) { path.removeLast() }
            } else {
                StudentComingSoonView(title: YouCopy.creditsHistory) { path.removeLast() }
            }
        case .rateMeal(let day, let slot):
            if let session, let rating = StudentRatingViewModel(session: session, repositories: environment.repositories,
                                                                day: day, slot: slot) {
                StudentRateMealView(model: rating, onSOS: { path.append(.sos) },
                                    onMyFeedback: { path.append(.myFeedback) }) {
                    skippedRatings.insert(Self.ratingKey(day, slot))
                    path.removeLast()
                }
            }
        case .sos:
            if let session {
                StudentSOSScreen(session: session) { path.removeLast() }
            }
        case .myFeedback:
            if let session, let records = StudentRecordsViewModel(session: session, repositories: environment.repositories,
                                                                  clock: environment.clock) {
                StudentMyFeedbackView(model: records, onReports: {}) { path.removeLast() }
            }
        case .rewardTicket(let id):
            if let session, let rewards = StudentRewardsViewModel(session: session, repositories: environment.repositories,
                                                                  clock: environment.clock) {
                StudentRewardTicketView(model: rewards, id: id)
            } else {
                StudentComingSoonView(title: YouCopy.credits) { path.removeLast() }
            }
        case .comingSoon(let title):
            StudentComingSoonView(title: title) { path.removeLast() }
        }
    }

    /// The How was … card shows only while the 2-day window is open and the meal is unrated.
    private func hideRatingCardIfDone() async {
        guard let session, let meal = model.state.value?.lastClosedMeal,
              let rating = StudentRatingViewModel(session: session, repositories: environment.repositories,
                                                  day: meal.startsAt, slot: meal.slot) else { return }
        await rating.load()
        if rating.window?.isOpen != true || rating.isGood {
            skippedRatings.insert(Self.ratingKey(meal.startsAt, meal.slot))
        }
    }

    /// Dish feedback kept while offline is sent once the app is back online. Nothing is sent while offline.
    private func sendKeptFeedback() async {
        let student = model.context.student.id
        guard !(await environment.repositories.dishFeedback.kept(by: student)).isEmpty,
              let sent = try? await environment.repositories.dishFeedback.sendKept(by: student), !sent.isEmpty else { return }
        environment.dataDidChange()
    }

    static func ratingKey(_ day: Date, _ slot: MealSlot) -> String {
        "\(Int(day.timeIntervalSince1970 / 86_400))-\(slot.rawValue)"
    }

    /// The How was … card: Good records, hides the card and shows Thanks; Not good records nothing and opens Which
    /// dish; Skip for now hides the card and records nothing. Not good never opens the Report form.
    private func rating(_ meal: Meal, _ action: StudentHomeRatingAction) {
        let key = Self.ratingKey(meal.startsAt, meal.slot)
        switch action {
        case .open:
            path.append(.rateMeal(day: meal.startsAt, slot: meal.slot))
        case .skip:
            skippedRatings.insert(key)
        case .good, .notGood:
            guard let session, let rating = StudentRatingViewModel(session: session, repositories: environment.repositories,
                                                                   day: meal.startsAt, slot: meal.slot) else { return }
            Task {
                let answer: StudentRatingAnswer = action == .good ? .good : .notGood
                guard await rating.rate(answer) else { return }
                if action == .good { skippedRatings.insert(key) }
                feedback = rating.feedbackRequest(after: answer)
            }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(StudentCopy.greeting(model.name))
                .font(MLType.largeTitle)
                .foregroundStyle(MLColor.ink)
                .accessibilityAddTraits(.isHeader)
            Text(StudentFormat.day(model.state.value?.today ?? model.now, in: model.timeZone))
                .font(StudentType.body)
                .foregroundStyle(MLColor.inkSecondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let content = model.state.value {
            StudentHomeBody(content: content, mess: model.context.mess.name, timeZone: model.timeZone, isOffline: model.isOffline,
                            savedAt: savedAtText,
                            heroAnswerState: model.answerState(for: content.shownHero),
                            onAnswer: { intention in
                                if intention == .skipping {
                                    skipping = content.shownHero.id
                                } else {
                                    Task { await model.answer(intention, for: content.shownHero.id) }
                                }
                            },
                            onShowEntry: { path.append(.entryQR) },
                            onOpenAnswer: { path.append(.answer($0)) },
                            onOpenPass: { path.append(.pass) },
                            onOpenCrowd: { path.append(.crowd) },
                            showsRating: { !skippedRatings.contains(Self.ratingKey($0.startsAt, $0.slot)) },
                            onRating: rating,
                            onOpenMyFeedback: { path.append(.myFeedback) })
        } else if model.isLoadingHome {
            StudentHomeLoading()
        } else {
            if case .empty = model.state {
                StudentHomeEmpty()
            } else {
                AsyncContentView(state: model.state, timeZone: model.timeZone, retry: { await model.load() }) { _ in EmptyView() }
            }
            // With nothing loaded the top card is gone, and the QR must still be reachable.
            if model.showsEntryFallback {
                InkActionButton(title: StudentCopy.showEntryQR) { path.append(.entryQR) }
            }
        }
    }

    private var savedAtText: String? {
        guard case .offline(_, let savedAt) = model.state else { return nil }
        return savedAt.map { MLFormat.time($0, in: model.timeZone) }
    }
}

/// Mark, wordmark, credits and two glass buttons (Home header 2147:539).
struct StudentHomeHeader: View {
    let credits: Int?
    let onRewards: () -> Void
    let onReport: () -> Void
    let onNotifications: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 6) {
                OrbitMarkView(size: 32)
                Text(StudentCopy.brand)
                    .font(StudentType.brand)
                    .foregroundStyle(MLColor.ink)
                    .lineLimit(1)
                    // On a 375 pt phone the header is a few points too wide: shrink, never cut the name.
                    .minimumScaleFactor(0.75)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
            Button(action: onRewards) {
                HStack(spacing: 6) {
                    Image("student-star").resizable().frame(width: 16, height: 16).accessibilityHidden(true)
                    Text(StudentCopy.points(credits))
                        .font(StudentType.mono)
                        .foregroundStyle(MLColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .padding(.leading, MLSpacing.s8)
                .padding(.trailing, MLSpacing.s12)
                .frame(height: MLSize.hit)
                .modifier(StudentGlass(shape: Capsule()))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(StudentCopy.pointsLabel(credits))
            StudentGlassButton(symbol: "exclamationmark.bubble", label: StudentCopy.reportIssue, action: onReport)
            StudentGlassButton(symbol: "bell", label: StudentCopy.notifications, action: onNotifications)
        }
    }
}

/// The loaded screen. Pure layout: every value comes from `StudentHomeContent`.
struct StudentHomeBody: View {
    let content: StudentHomeContent
    let mess: String
    let timeZone: TimeZone
    let isOffline: Bool
    let savedAt: String?
    let heroAnswerState: MealAnswerState
    let onAnswer: (MealIntention) -> Void
    let onShowEntry: () -> Void
    let onOpenAnswer: (MealID) -> Void
    var onOpenPass: () -> Void = {}
    var onOpenCrowd: () -> Void = {}
    /// Whether the How was … card shows for a closed meal (hidden after Good or Skip for now).
    var showsRating: (Meal) -> Bool = { _ in true }
    var onRating: (Meal, StudentHomeRatingAction) -> Void = { _, _ in }
    var onOpenMyFeedback: () -> Void = {}

    private var extras: StudentHomeExtras? { content.extras }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            if isOffline {
                StudentOfflineBanner(text: StudentCopy.offlineSaved(savedAt))
            }
            StudentHomeHero(content: content, mess: mess, timeZone: timeZone, isOffline: isOffline, answerState: heroAnswerState,
                            onAnswer: onAnswer, onShowEntry: onShowEntry)
            if let closed = content.lastClosedMeal, content.heroCase == .nextMeal, showsRating(closed) {
                StudentHowWasCard(slot: closed.slot, onOpen: { onRating(closed, .open) },
                                  onGood: { onRating(closed, .good) }, onNotGood: { onRating(closed, .notGood) },
                                  onSkip: { onRating(closed, .skip) })
                    .mlTransition(.fade)
            }
            Group {
                if let row = content.answerRow {
                    StudentAnswerRow(card: row, now: content.today, timeZone: timeZone) { onOpenAnswer(row.id) }
                }
                if let pass = extras?.pass {
                    StudentTicketRow(pass: pass, timeZone: timeZone, onOpen: onOpenPass)
                }
            }
            .opacity(isOffline ? 0.5 : 1)
            .disabled(isOffline)
            Button(action: onOpenCrowd) {
                StudentCrowdRow(crowd: isOffline ? nil : extras?.crowd, mess: mess, timeZone: timeZone)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isButton)
            if let recheck = extras?.recheck {
                Rectangle().fill(MLColor.border).frame(height: 1)
                StudentRecheckRow(recheck: recheck, onOpen: onOpenMyFeedback)
            }
        }
    }
}

/// The top card, in the five cases of HeroCard 2135:2336.
struct StudentHomeHero: View {
    let content: StudentHomeContent
    let mess: String
    let timeZone: TimeZone
    let isOffline: Bool
    let answerState: MealAnswerState
    let onAnswer: (MealIntention) -> Void
    let onShowEntry: () -> Void

    private var card: StudentMealCard { content.shownHero }
    private var meal: Meal { card.meal }
    private var range: String { MLFormat.timeRange(meal.startsAt, meal.endsAt, in: timeZone) }

    var body: some View {
        StudentHeroCard {
            HStack {
                Text(eyebrow.uppercased())
                    .font(StudentType.eyebrow)
                    .tracking(0.72)
                    .foregroundStyle(MLColor.onHeroSecondary)
                Spacer(minLength: MLSpacing.s8)
                chip
            }
            .frame(minHeight: StudentMetric.chipHeight)
            Text(title)
                .font(StudentType.heroTitle)
                .foregroundStyle(MLColor.onHero)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.onHeroSecondary)
                .fixedSize(horizontal: false, vertical: true)
            actions.padding(.top, MLSpacing.s16)
        }
    }

    private var eyebrow: String {
        switch content.heroCase {
        case .nowServing: return StudentCopy.nowServing
        case .nextMeal: return StudentCopy.nextMealEyebrow
        case .messClosed, .question, .answered: return StudentCopy.eyebrow(meal.slot)
        }
    }

    private var title: String {
        switch content.heroCase {
        case .messClosed: return StudentCopy.messOpensAt(StudentFormat.clock(meal.startsAt, in: timeZone))
        case .nowServing: return StudentCopy.isOpen(meal.slot)
        case .nextMeal: return StudentCopy.mealAt(meal.slot, time: StudentFormat.shortTime(meal.startsAt, in: timeZone))
        case .question: return StudentCopy.mealToday(meal.slot)
        case .answered:
            switch card.answer {
            case .attending?: return StudentCopy.youreIn(meal.slot)
            case .skipping?: return StudentCopy.youSkipped(meal.slot)
            case .notSure?: return StudentCopy.youreNotSure(meal.slot)
            case nil: return StudentCopy.mealToday(meal.slot)
            }
        }
    }

    private var detail: String {
        if isOffline { return StudentCopy.savedQRWorks(range) }
        switch content.heroCase {
        case .messClosed: return StudentCopy.mealRange(meal.slot, range: range, mess: mess)
        case .nowServing: return StudentCopy.till(StudentFormat.shortTime(meal.endsAt, in: timeZone), mess: mess)
        case .nextMeal: return StudentCopy.servingAt(range, mess: mess)
        case .question: return StudentCopy.serving(range)
        case .answered:
            switch card.answer {
            case .skipping?: return StudentCopy.canStillEat
            case .notSure?: return StudentCopy.notSureCanEat
            case .attending?, nil: return StudentCopy.serving(range)
            }
        }
    }

    @ViewBuilder
    private var chip: some View {
        if content.heroCase != .messClosed {
            switch card.answer {
            case .attending?:
                StudentHeroChip(text: StudentCopy.imIn, style: .lime, showsCheck: true)
            case .skipping?:
                StudentHeroChip(text: StudentCopy.skipped, style: .outline)
            case .notSure?:
                StudentHeroChip(text: StudentCopy.notSure, style: .outline)
            case nil:
                if content.heroCase == .question {
                    StudentHeroChip(text: StudentCopy.notAnswered, style: .dashed)
                }
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        if content.heroCase == .question && card.isAnswerOpen && !isOffline {
            HStack(spacing: MLSpacing.s8) {
                StudentHeroButton(title: answerState == .saving(.attending) ? StudentCopy.saving : StudentCopy.imIn, style: .lime) { onAnswer(.attending) }
                StudentHeroButton(title: StudentCopy.skip, style: .outline, expands: false) { onAnswer(.skipping) }
                StudentHeroButton(title: StudentCopy.entryQRShort, style: .cream, action: onShowEntry)
            }
            .disabled(isSaving)
        } else {
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                StudentHeroButton(title: StudentCopy.showEntryQR, style: .cream, action: onShowEntry)
                if content.heroCase == .question {
                    Text(StudentCopy.answersClosed(StudentFormat.shortTime(card.cutoff, in: timeZone)))
                        .font(MLType.secondary)
                        .foregroundStyle(MLColor.onHeroSecondary)
                }
            }
        }
    }

    private var isSaving: Bool {
        if case .saving = answerState { return true }
        return false
    }
}

/// Home · Loading (221:64894): quiet blocks where the cards will be.
struct StudentHomeLoading: View {
    private let blocks: [CGFloat] = [214, 72, 72, 103]

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, height in
                RoundedRectangle(cornerRadius: index == 0 ? StudentMetric.heroRadius : StudentMetric.rowRadius, style: .continuous)
                    .fill(MLColor.track.opacity(0.8))
                    .frame(height: height)
            }
            Text(StudentCopy.gettingMeals)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(StudentCopy.gettingMeals)
    }
}

/// Home · Empty (221:64850).
struct StudentHomeEmpty: View {
    var body: some View {
        VStack(spacing: MLSpacing.s12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 24))
                .foregroundStyle(MLColor.ink)
                .frame(width: 64, height: 64)
                .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.fillQuiet))
                .accessibilityHidden(true)
            Text(StudentCopy.noMealsTitle)
                .font(StudentType.bodySemibold)
                .foregroundStyle(MLColor.ink)
            Text(StudentCopy.noMealsDetail)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, MLSpacing.s24)
        .padding(.vertical, MLSpacing.s32)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.surface))
    }
}

/// What the How was … card on Home asks for.
enum StudentHomeRatingAction: Equatable {
    case open, good, notGood, skip
}
