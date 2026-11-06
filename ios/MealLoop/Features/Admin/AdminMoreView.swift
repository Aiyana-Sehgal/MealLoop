import SwiftUI

/// The More hub (A11).
struct AdminMoreScreen: View {
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
                        AdminHubRow(title: AdminScreenCopy.spareFood, value: AdminScreenCopy.pickups(hub.pickups)) { nav.push(.spareFood) }
                    }
                    group {
                        AdminHubRow(title: AdminScreenCopy.peopleAndAccess, value: AdminScreenCopy.invited(hub.invited)) { nav.push(.people) }
                        AdminHubRow(title: AdminScreenCopy.announceToStudents) { nav.push(.announce) }
                        AdminHubRow(title: AdminScreenCopy.history) { nav.push(.history) }
                        AdminHubRow(title: AdminScreenCopy.signOut) {
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
private struct AdminHubRow: View {
    let title: String
    var value: String?
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
            .frame(minHeight: MLSize.staffButton)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle().fill(MLColor.border).frame(height: 1)
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
                    Text(AdminScreenCopy.characters(model.message.count, draft.maxCharacters))
                        .font(MLType.monoSecondary)
                        .foregroundStyle(MLColor.inkSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    AdminRow(title: AdminScreenCopy.when, detail: AdminScreenCopy.nowTitle, action: nil) { EmptyView() }
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
                    AdminFactChip(text: page.mess)
                    HeroCard {
                        VStack(spacing: MLSpacing.s12) {
                            HeroEyebrow(label: page.title)
                            ZStack {
                                Circle().stroke(MLColor.onHero.opacity(0.2), lineWidth: 12)
                                Circle().trim(from: 0, to: CGFloat(page.used) / CGFloat(max(page.total, 1)))
                                    .stroke(MLColor.lime, style: StrokeStyle(lineWidth: 12, lineCap: .round))
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
                            .frame(width: 180, height: 180)
                            Text(AdminScreenCopy.expiredUnused(page.expiredUnused))
                                .font(MLType.body)
                                .foregroundStyle(MLColor.onHeroSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    AdminCard {
                        AdminRow(title: page.requestName, detail: page.requestDetail, action: nil) {
                            StatusText(text: page.requestStatus, dot: .empty)
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

    var body: some View {
        let more = environment.repositories.adminMore
        AdminPageScaffold(title: AdminScreenCopy.menuVotes, onBack: nav.pop) {
            AdminLoadedPage(model: AdminPageModel { try await more.votes() }, timeZone: nav.timeZone) { page, _ in
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    HeroCard {
                        VStack(alignment: .leading, spacing: MLSpacing.s12) {
                            HeroEyebrow(label: AdminScreenCopy.voteClosed)
                            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                                Text("\(page.forPercent)%")
                                    .font(MLType.heroNumber)
                                    .foregroundStyle(MLColor.onHero)
                                Text(AdminScreenCopy.forWord)
                                    .font(MLType.staffBody)
                                    .foregroundStyle(MLColor.onHeroSecondary)
                            }
                            Text(AdminScreenCopy.forAgainst(AdminFormat.count(page.forCount), AdminFormat.count(page.againstCount)))
                                .font(MLType.monoSecondary)
                                .foregroundStyle(MLColor.onHeroSecondary)
                            Text(page.closedTitle)
                                .font(MLType.title2)
                                .foregroundStyle(MLColor.onHero)
                            Text(page.advice)
                                .font(MLType.body)
                                .foregroundStyle(MLColor.onHeroSecondary)
                        }
                    }
                    AdminCard {
                        AdminRow(title: page.inProgressDetail, detail: page.inProgressTitle, action: nil) {
                            Text(page.timeLeft)
                                .font(MLType.monoBody)
                                .foregroundStyle(MLColor.ink)
                        }
                        AdminRow(title: AdminScreenCopy.newProposals(page.newProposals), action: nil) { EmptyView() }
                    }
                }
            }
        }
    }
}

struct AdminRewardsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        let more = environment.repositories.adminMore
        AdminPageScaffold(title: AdminScreenCopy.rewards, onBack: nav.pop) {
            AdminLoadedPage(model: AdminPageModel { try await more.rewards() }, timeZone: nav.timeZone) { page, _ in
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    HeroCard {
                        VStack(alignment: .leading, spacing: MLSpacing.s8) {
                            HeroEyebrow(label: page.budgetTitle)
                            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                                Text(page.spent)
                                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                                    .foregroundStyle(MLColor.onHero)
                                Text(AdminScreenCopy.ofBudget(page.budget))
                                    .font(MLType.body)
                                    .foregroundStyle(MLColor.onHeroSecondary)
                            }
                            Text(page.detail)
                                .font(MLType.body)
                                .foregroundStyle(MLColor.onHeroSecondary)
                        }
                    }
                    ForEach(page.rewards) { reward in
                        AdminCard {
                            AdminRow(title: reward.title, detail: reward.detail, action: nil) {
                                VStack(alignment: .trailing, spacing: MLSpacing.s4) {
                                    StatusText(text: reward.status, dot: reward.isLive ? .filled : .dashed)
                                    Text("\(reward.points) \(AdminScreenCopy.pts)")
                                        .font(MLType.monoBody)
                                        .foregroundStyle(MLColor.ink)
                                }
                            }
                        }
                    }
                }
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
                    AdminFactChip(text: page.mess)
                    HeroCard {
                        VStack(alignment: .leading, spacing: MLSpacing.s8) {
                            HeroEyebrow(label: page.status, showsDot: true)
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
                            HStack(alignment: .top) {
                                ForEach(page.steps) { step in
                                    VStack(alignment: .leading, spacing: MLSpacing.s4) {
                                        Text(step.title)
                                            .font(MLType.body)
                                            .foregroundStyle(MLColor.onHero)
                                        Text(step.time)
                                            .font(MLType.monoSecondary)
                                            .foregroundStyle(MLColor.onHeroSecondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
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
                    HeroCard {
                        HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                            Text("\(page.entriesToday)")
                                .font(MLType.heroNumber)
                                .foregroundStyle(MLColor.onHero)
                            Text(AdminScreenCopy.entriesToday)
                                .font(MLType.staffBody)
                                .foregroundStyle(MLColor.onHeroSecondary)
                        }
                    }
                    AdminCard {
                        ForEach(page.lines) { line in
                            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s12) {
                                Text(line.time)
                                    .font(MLType.monoSecondary)
                                    .foregroundStyle(MLColor.inkSecondary)
                                    .frame(width: 72, alignment: .leading)
                                VStack(alignment: .leading, spacing: MLSpacing.s4) {
                                    Text(line.title)
                                        .font(MLType.staffBody)
                                        .foregroundStyle(MLColor.ink)
                                    if let tag = line.tag {
                                        StatusText(text: tag, dot: .empty)
                                    }
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
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
                                .font(MLType.heroNumber)
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
                        AdminRow(title: line.title, detail: line.detail, action: nil) {
                            if let count = line.count {
                                Text("\(count)")
                                    .font(MLType.monoBody)
                                    .foregroundStyle(MLColor.ink)
                            }
                            if let status = line.status {
                                StatusText(text: status, dot: .dashed)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
