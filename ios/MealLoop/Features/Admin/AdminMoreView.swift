import SwiftUI

/// The More hub (A11).
struct AdminMoreScreen: View {
    @Environment(DemoMenu.self) private var demoMenu: DemoMenu?
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let nav: AdminNav

    var body: some View {
        let more = environment.repositories.adminMore
        AdminPageScaffold(title: AdminScreenCopy.moreTitle) {
            AdminLoadedPage(model: AdminPageModel { try await more.hub() }, timeZone: nav.timeZone) { hub, _ in
                VStack(spacing: MLSpacing.s16) {
                    group {
                        AdminHubRow(title: AdminScreenCopy.weeklyMenu, value: hub.menuStatus) { nav.push(.weeklyMenu) }
                        AdminHubRow(title: AdminScreenCopy.wednesdayPass, value: "\(hub.passUsed)/\(hub.passTotal)") { nav.push(.passes) }
                        AdminHubRow(title: AdminScreenCopy.outings, value: AdminScreenCopy.outCount(hub.outNow)) { nav.push(.outings) }
                        AdminHubRow(title: AdminScreenCopy.votes, value: AdminScreenCopy.openCount(hub.openVotes)) { nav.push(.votes) }
                        AdminHubRow(title: AdminScreenCopy.rewards, value: AdminScreenCopy.liveCount(hub.liveRewards)) { nav.push(.rewards) }
                        AdminHubRow(title: AdminScreenCopy.spareFood, value: AdminScreenCopy.pickups(hub.pickups), isLast: true) { nav.push(.spareFood) }
                    }
                    group {
                        if nav.context.canManagePeople {
                            AdminHubRow(title: AdminScreenCopy.peopleAndAccess, value: AdminScreenCopy.invited(hub.invited)) { nav.push(.people) }
                        }
                        AdminHubRow(title: AdminScreenCopy.announceToStudents) { nav.push(.announce) }
                        AdminHubRow(title: AdminScreenCopy.history) { nav.push(.history) }
                        #if DEMO_DATA || REVIEW_DATA
                        AdminHubRow(title: DemoCopy.rowTitle) { demoMenu?.isPresented = true }
                        #endif
                        AdminHubRow(title: AdminScreenCopy.signOut, isLast: true) {
                            router.reset()
                            sessionStore.signOut()
                        }
                    }
                }
            }
        }
    }

    private func group<Rows: View>(@ViewBuilder rows: () -> Rows) -> some View {
        VStack(spacing: 0) {
            rows()
        }
        .padding(.horizontal, MLSpacing.s16)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
    }
}

/// A hub row. The value mixes words and counts, so it stays in the body face: mono is for numbers alone.
struct AdminHubRow: View {
    let title: String
    var value: String?
    var isLast = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s12) {
                Text(title)
                    .font(MLType.staffBody)
                    .foregroundStyle(MLColor.ink)
                Spacer(minLength: MLSpacing.s8)
                if let value {
                    Text(value)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MLColor.inkSecondary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 59)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(MLColor.border).frame(height: 1)
            }
        }
    }
}

/// Announce to students (A11). SIMULATED: the screen records nothing a student can see yet.
@MainActor
@Observable
final class AdminAnnounceViewModel {
    private(set) var state: LoadState<AnnouncementDraft> = .idle
    private(set) var isSending = false
    private(set) var errorText: String?
    var message = ""
    var audienceID = ""

    private let more: any AdminMoreRepository
    private let role: Role

    init(more: any AdminMoreRepository, role: Role) {
        self.more = more
        self.role = role
    }

    var audience: AnnouncementAudience? { state.value?.audiences.first { $0.id == audienceID } }
    var isTooLong: Bool { message.count > (state.value?.maxCharacters ?? 0) }
    var canSend: Bool { !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTooLong && !isSending }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            let draft = try await more.announcementDraft()
            if message.isEmpty {
                message = draft.sampleMessage
                audienceID = draft.defaultAudience
            }
            state = .loaded(draft)
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    func send() async -> Bool {
        guard canSend else { return false }
        isSending = true
        errorText = nil
        defer { isSending = false }
        do {
            try await more.announce(message, to: audienceID, by: role)
            return true
        } catch {
            errorText = AdminWriteError.text(error)
            return false
        }
    }
}

struct AdminAnnounceScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        AdminAnnounceView(model: AdminAnnounceViewModel(more: environment.repositories.adminMore, role: nav.context.account.role), nav: nav)
    }
}

struct AdminAnnounceView: View {
    @State private var model: AdminAnnounceViewModel
    let nav: AdminNav

    @State private var isConfirming = false

    init(model: AdminAnnounceViewModel, nav: AdminNav) {
        _model = State(initialValue: model)
        self.nav = nav
    }

    var body: some View {
        @Bindable var model = model
        AdminPageScaffold(title: AdminScreenCopy.announceToStudents, subtitle: AdminScreenCopy.announceSubtitle, onBack: nav.pop) {
            AsyncContentView(state: model.state, timeZone: nav.timeZone, retry: { await model.load() }) { draft in
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    AdminLabel(text: AdminScreenCopy.who)
                    AdminFlow {
                        ForEach(draft.audiences) { audience in
                            ChoiceChip(title: audience.title, isSelected: model.audienceID == audience.id) { model.audienceID = audience.id }
                        }
                    }
                    AdminLabel(text: AdminScreenCopy.messageLabel)
                    AdminTextField(placeholder: AdminScreenCopy.messageLabel, text: $model.message, lines: 3)
                        .overlay(alignment: .bottomTrailing) {
                            Text(AdminScreenCopy.characters(model.message.count, draft.maxCharacters))
                                .font(MLType.monoSecondary)
                                .foregroundStyle(MLColor.inkSecondary)
                                .padding(MLSpacing.s12)
                        }
                    AdminRow(title: AdminScreenCopy.when, detail: AdminScreenCopy.nowTitle, action: nil) {
                        AdminChip(text: AdminScreenCopy.nowTitle, style: .outline)
                    }
                    InkActionButton(title: AdminScreenCopy.reviewAndSend) { isConfirming = true }
                        .disabled(!model.canSend)
                }
            }
        }
        .task { await model.load() }
        .mlSheet(isPresented: $isConfirming) {
            if let audience = model.audience {
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    SheetHeader(title: AdminScreenCopy.sendToAudience(audience.confirmName)) { isConfirming = false }
                    Text("\"\(model.message)\"")
                        .font(MLType.staffBody)
                        .foregroundStyle(MLColor.ink)
                    AdminNote(text: AdminScreenCopy.audienceReach(audience))
                    if let error = model.errorText {
                        FieldErrorText(text: error)
                    }
                    InkActionButton(title: AdminScreenCopy.sendNow, isLoading: model.isSending) {
                        Task {
                            if await model.send() {
                                isConfirming = false
                                nav.toast(AdminScreenCopy.announcementSent)
                                nav.pop()
                            }
                        }
                    }
                }
            }
        }
    }
}

/// The restyled pages (A11, A14): new backdrop and header, the same content.
struct AdminPassesScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        let more = environment.repositories.adminMore
        AdminPageScaffold(title: AdminScreenCopy.passes, onBack: nav.pop) {
            AdminLoadedPage(model: AdminPageModel { try await more.passes() }, timeZone: nav.timeZone) { page, _ in
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    Color.clear.frame(height: MLSpacing.s4)
                    HStack(spacing: MLSpacing.s8) {
                        AdminChip(text: page.mess, symbol: "fork.knife", isSmall: true)
                        AdminChip(text: AdminScreenCopy.rules, symbol: "info.circle", isSmall: true)
                    }
                    // Requests for next week (admin_passes_01_requests), before this week's pass card.
                    AdminPassRequestsSection(nav: nav)
                    HeroCard {
                        VStack(spacing: MLSpacing.s12) {
                            HeroEyebrow(label: page.title)
                            ZStack {
                                Circle().stroke(MLColor.onHero.opacity(0.2), lineWidth: 14)
                                Circle().trim(from: 0, to: CGFloat(page.used) / CGFloat(max(page.total, 1)))
                                    .stroke(MLColor.lime, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                VStack(spacing: 0) {
                                    Text("\(page.used)")
                                        .font(MLType.heroNumber)
                                        .foregroundStyle(MLColor.onHero)
                                    Text(AdminScreenCopy.ofTotalUsed(page.total))
                                        .font(MLType.body)
                                        .foregroundStyle(MLColor.onHeroSecondary)
                                }
                            }
                            .frame(width: 176, height: 176)
                            Text(AdminScreenCopy.expiredUnused(page.expiredUnused))
                                .font(MLType.body)
                                .foregroundStyle(MLColor.onHeroSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    // The request is shown as the record holds it; deciding a pass request is not in this brief.
                    AdminCard {
                        Group {
                            HStack(spacing: MLSpacing.s8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(page.requestName)
                                        .font(MLType.staffPrimary)
                                        .foregroundStyle(MLColor.ink)
                                    Text(page.requestDetail)
                                        .font(MLType.body)
                                        .foregroundStyle(MLColor.inkSecondary)
                                }
                                Spacer(minLength: MLSpacing.s8)
                                AdminChip(text: page.requestStatus, style: .filled, isSmall: true)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
    }
}

struct AdminVotesScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav
    @State private var showsRules = false
    @State private var decideSubject: String?
    @State private var votesModel: AdminVotesModel?

    var body: some View {
        let more = environment.repositories.adminMore
        AdminPageScaffold(title: AdminScreenCopy.menuVotes, onBack: nav.pop) {
            AdminLoadedPage(model: AdminPageModel { try await more.votes() }, timeZone: nav.timeZone) { page, _ in
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    Color.clear.frame(height: MLSpacing.s4)
                    Button { showsRules = true } label: {
                        AdminChip(text: AdminScreenCopy.rules, symbol: "info.circle", isSmall: true)
                    }
                    .buttonStyle(.plain)
                    HeroCard {
                        VStack(alignment: .leading, spacing: MLSpacing.s12) {
                            AdminChip(text: AdminScreenCopy.voteClosed, style: .filled, isSmall: true)
                            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                                Text("\(page.forPercent)%")
                                    .font(MLType.heroNumber)
                                    .foregroundStyle(MLColor.onHero)
                                Text(AdminScreenCopy.forWord)
                                    .font(MLType.staffBody)
                                    .foregroundStyle(MLColor.onHeroSecondary)
                            }
                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(MLColor.onHeroSecondary)
                                    Capsule().fill(MLColor.lime).frame(width: proxy.size.width * CGFloat(page.forPercent) / 100)
                                }
                            }
                            .frame(height: 8)
                            .accessibilityHidden(true)
                            Text(AdminScreenCopy.forAgainst(AdminFormat.count(page.forCount), AdminFormat.count(page.againstCount)))
                                .font(MLType.monoSecondary)
                                .foregroundStyle(MLColor.onHeroSecondary)
                            Text(page.closedTitle)
                                .font(MLType.title2)
                                .foregroundStyle(MLColor.onHero)
                            Text(page.advice)
                                .font(MLType.body)
                                .foregroundStyle(MLColor.onHeroSecondary)
                            if let decided = votesModel?.decision {
                                Text(AdminVotesRewardsCopy.decided(decided.decision))
                                    .mlFont(.bodyEmphasis)
                                    .foregroundStyle(MLColor.onHero)
                            }
                            Button {
                                decideSubject = AdminVotesRewardsCopy.decideSubject(page.closedTitle, page.forPercent)
                            } label: {
                                Text(AdminScreenCopy.decide)
                                    .font(MLType.staffPrimary)
                                    .foregroundStyle(MLColor.ink)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(Capsule().fill(MLColor.surface))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    AdminCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(page.inProgressDetail)
                                    .font(MLType.staffPrimary)
                                    .foregroundStyle(MLColor.ink)
                                Text(page.inProgressTitle)
                                    .font(MLType.body)
                                    .foregroundStyle(MLColor.inkSecondary)
                            }
                            Spacer()
                            Text(page.timeLeft)
                                .font(MLType.monoBody)
                                .foregroundStyle(MLColor.ink)
                        }
                    }
                    AdminCard {
                        Button {
                            nav.push(.proposals)
                        } label: {
                            HStack {
                                Text(AdminScreenCopy.newProposals(page.newProposals))
                                    .font(MLType.staffPrimary)
                                    .foregroundStyle(MLColor.ink)
                                Spacer()
                                AdminChevron()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .task {
            if votesModel == nil {
                votesModel = AdminVotesModel(repository: environment.repositories.adminVotesRewards,
                                             role: nav.context.account.role)
            }
            await votesModel?.load()
        }
        .mlSheet(isPresented: $showsRules) {
            AdminRulesSheet(title: AdminVotesRewardsCopy.votingRulesTitle, rules: AdminVotesRewardsCopy.votingRules) {
                showsRules = false
            }
        }
        .mlSheet(item: Binding(get: { decideSubject.map(SheetSubject.init) }, set: { decideSubject = $0?.text }),
                 isWorking: votesModel?.isSaving ?? false) { subject in
            if let votesModel {
                AdminDecideSheet(model: votesModel, subject: subject.text, onSaved: {
                    decideSubject = nil
                    nav.toast(AdminVotesRewardsCopy.decisionLine)
                }, onClose: { decideSubject = nil })
            }
        }
    }
}

/// A string as a sheet item.
struct SheetSubject: Identifiable {
    let text: String
    var id: String { text }
}

struct AdminRewardsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav
    @State private var showsRules = false

    var body: some View {
        let more = environment.repositories.adminMore
        AdminPageScaffold(title: AdminScreenCopy.rewards, onBack: nav.pop) {
            AdminLoadedPage(model: AdminPageModel { try await more.rewards() }, timeZone: nav.timeZone) { page, _ in
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    Color.clear.frame(height: MLSpacing.s4)
                    Button { showsRules = true } label: {
                        AdminChip(text: AdminScreenCopy.rules, symbol: "info.circle", isSmall: true)
                    }
                    .buttonStyle(.plain)
                    HStack(spacing: MLSpacing.s8) {
                        AdminChip(text: AdminScreenCopy.catalogue, style: .ink, isSmall: true)
                        Button { nav.push(.redemptions) } label: {
                            AdminChip(text: AdminScreenCopy.redemptions, isSmall: true)
                        }
                        .buttonStyle(.plain)
                    }
                    HeroCard {
                        HStack(spacing: MLSpacing.s16) {
                            ZStack {
                                Circle().stroke(MLColor.onHero.opacity(0.2), lineWidth: 6)
                                Circle().trim(from: 0, to: CGFloat(page.spentShare))
                                    .stroke(MLColor.onHero, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                            }
                            .frame(width: 64, height: 64)
                            .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                                HeroEyebrow(label: page.budgetTitle)
                                HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                                    Text(page.spent)
                                        .font(AdminType.count)
                                        .foregroundStyle(MLColor.onHero)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    Text(AdminScreenCopy.ofBudget(page.budget))
                                        .font(MLType.body)
                                        .foregroundStyle(MLColor.onHeroSecondary)
                                        .fixedSize()
                                }
                                Text(page.detail)
                                    .font(MLType.body)
                                    .foregroundStyle(MLColor.onHeroSecondary)
                            }
                        }
                    }
                    // Manage the catalogue (admin_rewards_03_manage): what students can get, with add and delete.
                    AdminLabel(text: AdminRewardsCopy.subtitle.uppercased())
                    AdminRewardCatalogueSection(nav: nav)
                }
            }
        }
        .mlSheet(isPresented: $showsRules) {
            AdminRulesSheet(title: AdminVotesRewardsCopy.rewardRulesTitle, rules: AdminVotesRewardsCopy.rewardRules) {
                showsRules = false
            }
        }
    }
}

struct AdminSpareFoodScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        let more = environment.repositories.adminMore
        AdminPageScaffold(title: AdminScreenCopy.spareFood, onBack: nav.pop) {
            AdminLoadedPage(model: AdminPageModel { try await more.spareFood() }, timeZone: nav.timeZone) { page, _ in
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    Color.clear.frame(height: MLSpacing.s4)
                    AdminChip(text: page.mess, symbol: "fork.knife", isSmall: true)
                    HeroCard {
                        VStack(alignment: .leading, spacing: MLSpacing.s8) {
                            HStack(spacing: MLSpacing.s12) {
                                Image(systemName: "clock")
                                    .font(.system(size: 20))
                                    .foregroundStyle(MLColor.onHero)
                                    .frame(width: 44, height: 44)
                                    .overlay(Circle().stroke(MLColor.onHero, lineWidth: 1.5))
                                    .accessibilityHidden(true)
                                AdminChip(text: page.status, style: .filled, isSmall: true)
                            }
                            Text(page.title)
                                .font(MLType.title2)
                                .foregroundStyle(MLColor.onHero)
                            Text(AdminScreenCopy.byTime(page.partner, page.collectBy))
                                .font(MLType.body)
                                .foregroundStyle(MLColor.onHeroSecondary)
                            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                                Text("\(page.dishes)")
                                    .font(MLType.heroNumber)
                                    .foregroundStyle(MLColor.onHero)
                                Text(AdminScreenCopy.dishes)
                                    .font(MLType.staffBody)
                                    .foregroundStyle(MLColor.onHeroSecondary)
                            }
                            AdminStageLine(stages: page.steps.map(\.title), current: page.steps.lastIndex(where: \.isDone) ?? 0, onHero: true)
                            HStack(alignment: .top) {
                                ForEach(page.steps) { step in
                                    Text(step.time)
                                        .font(MLType.monoSecondary)
                                        .foregroundStyle(MLColor.onHeroSecondary)
                                        .frame(maxWidth: .infinity, alignment: step.id == page.steps.first?.id ? .leading : (step.id == page.steps.last?.id ? .trailing : .center))
                                }
                            }
                        }
                    }
                    // The steps are drawn above; the record holds no dish list, so there is no page to open.
                    AdminNote(text: page.note)
                }
            }
        }
    }
}

struct AdminHistoryScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        let more = environment.repositories.adminMore
        AdminPageScaffold(title: AdminScreenCopy.history, onBack: nav.pop) {
            AdminLoadedPage(model: AdminPageModel { try await more.history() }, timeZone: nav.timeZone) { page, _ in
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    Color.clear.frame(height: MLSpacing.s4)
                    AdminChip(text: AdminScreenCopy.allTypes, symbol: "flag", isSmall: true)
                    HeroCard {
                        VStack(alignment: .leading, spacing: MLSpacing.s12) {
                            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                                Text("\(page.entriesToday)")
                                    .font(MLType.heroNumber)
                                    .foregroundStyle(MLColor.onHero)
                                Text(AdminScreenCopy.entriesToday)
                                    .font(MLType.staffBody)
                                    .foregroundStyle(MLColor.onHeroSecondary)
                            }
                            AdminHistoryStrip()
                        }
                    }
                    AdminCard {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(page.lines) { line in
                                historyRow(line, isLast: line.id == page.lines.last?.id)
                            }
                        }
                    }
                    // The page lists every entry the record holds; when it holds fewer than today's count, it says so.
                    if page.lines.count < page.entriesToday {
                        Text(AdminScreenCopy.historyNotHeld(page.lines.count, page.entriesToday))
                            .mlFont(.secondary)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                }
            }
        }
    }
}

private extension AdminHistoryScreen {
    func historyRow(_ line: HistoryLine, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: MLSpacing.s12) {
            Text(line.time)
                .font(MLType.monoSecondary)
                .foregroundStyle(MLColor.inkSecondary)
                .frame(width: 68, alignment: .leading)
            VStack(spacing: 0) {
                Circle().fill(line.tag == nil ? MLColor.lime : MLColor.ink)
                    .overlay(Circle().stroke(MLColor.ink, lineWidth: 1.5))
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)
                if !isLast {
                    Rectangle().fill(MLColor.ink).frame(width: 1.5)
                }
            }
            VStack(alignment: .leading, spacing: MLSpacing.s8) {
                Text(line.title)
                    .font(MLType.staffBody)
                    .foregroundStyle(MLColor.ink)
                if let tag = line.tag {
                    AdminChip(text: tag, style: .black, isSmall: true)
                }
            }
            .padding(.bottom, isLast ? 0 : 56)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The small mark under "entries today". It decorates; the entries are in the card below.
struct AdminHistoryStrip: View {
    var body: some View {
        HStack(spacing: 0) {
            Circle().stroke(MLColor.onHero, lineWidth: 1.5).frame(width: 18, height: 18)
            Rectangle().fill(MLColor.onHero).frame(width: 12, height: 1.5)
            Circle().fill(MLColor.onHero).frame(width: 10, height: 10)
            Rectangle().fill(MLColor.onHero).frame(width: 12, height: 1.5)
            Color.clear.frame(width: 12, height: 1)
            Rectangle().fill(MLColor.onHero).frame(width: 12, height: 1.5)
            Circle().fill(MLColor.onHero).frame(width: 10, height: 10)
            Rectangle().fill(MLColor.onHero).frame(width: 12, height: 1.5)
            Circle().stroke(MLColor.onHero, lineWidth: 1.5).frame(width: 12, height: 12)
        }
        .accessibilityHidden(true)
    }
}

/// A reward as a ticket: name and status, then a torn stub with the points.
struct AdminRewardTicket: View {
    let reward: RewardLine

    private var isAwaiting: Bool { reward.status == AdminScreenCopy.awaitingSRM }
    private let shape = RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous)

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                HStack(spacing: MLSpacing.s8) {
                    Text(reward.title)
                        .font(MLType.staffPrimary)
                        .foregroundStyle(isAwaiting ? MLColor.inkSecondary : MLColor.ink)
                    AdminChip(text: reward.status, style: isAwaiting ? .filled : .lime, isSmall: true)
                }
                Text(reward.detail)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            .padding(MLSpacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .foregroundStyle(MLColor.inkSecondary)
                .frame(width: 1)
            VStack(spacing: 0) {
                Text("\(reward.points)")
                    .font(AdminType.count)
                    .foregroundStyle(isAwaiting ? MLColor.inkSecondary : MLColor.ink)
                Text(AdminScreenCopy.pts)
                    .font(MLType.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            .frame(width: 72)
        }
        .background { background }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var background: some View {
        if isAwaiting {
            shape.stroke(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
        } else {
            shape.fill(MLColor.surface)
        }
    }
}

struct AdminOutingsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        let more = environment.repositories.adminMore
        AdminLoadedPage(model: AdminPageModel { try await more.outings() }, timeZone: nav.timeZone) { page, _ in
            AdminPageScaffold(title: AdminScreenCopy.outings, subtitle: page.subtitle, onBack: nav.pop) {
                HeroCard {
                    HStack(alignment: .top, spacing: MLSpacing.s24) {
                        VStack(alignment: .leading, spacing: MLSpacing.s4) {
                            HeroEyebrow(label: AdminScreenCopy.outNow)
                            Text("\(page.outNow)")
                                .font(AdminType.heroMetric)
                                .foregroundStyle(MLColor.onHero)
                        }
                        VStack(alignment: .leading, spacing: MLSpacing.s4) {
                            Text(page.dueBackTitle)
                                .font(MLType.body)
                                .foregroundStyle(MLColor.onHeroSecondary)
                            Text("\(page.dueBack)")
                                .font(MLType.monoBody)
                                .foregroundStyle(MLColor.onHero)
                            Text(AdminScreenCopy.late)
                                .font(MLType.body)
                                .foregroundStyle(MLColor.onHeroSecondary)
                            Text("\(page.late)")
                                .font(MLType.monoBody)
                                .foregroundStyle(MLColor.onHero)
                        }
                    }
                }
                VStack(spacing: 0) {
                    ForEach(page.lines) { line in
                        AdminRow(title: line.title, detail: line.detail, showsChevron: false, action: nil) {
                            if let count = line.count {
                                Text("\(count)")
                                    .font(MLType.monoBody)
                                    .foregroundStyle(MLColor.ink)
                            }
                            if let status = line.status {
                                AdminChip(text: status, style: .dashed)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
