import Observation
import SwiftUI

// Pages that used to say "This isn't part of this prototype" (owner review, 7 to 8 November): Menu votes Rules, Decide,
// New proposals and a proposal; Rewards Rules and Redemptions; Today See all. Figma draws only the Success state of
// Menu voting (2277:2081) and Rewards (2277:2474); the design-brief images are missing, so these are the minimal honest
// versions built from the brief's wording and the Success frames' vocabulary, listed "needs design" in the report.

enum AdminVotesRewardsCopy {
    static let votingRulesTitle = "How voting works"
    static let votingRules = [
        "Students vote for or against a proposal.",
        "A vote lasts a set time.",
        "The result is advice only.",
        "The admin decides.",
    ]
    static let rewardRulesTitle = "How rewards work"
    static let rewardRules = [
        "Students earn small credits for definite meal answers.",
        "Not sure and No response earn none.",
        "Amounts are set by the institution.",
    ]
    static let decideTitle = "Decide"
    static func decideSubject(_ title: String, _ percent: Int) -> String { "\(title) · \(percent)% for" }
    static let addToMenu = "Add to the menu"
    static let notNow = "Not now"
    static let decisionLine = "Your decision is recorded on the vote. This prototype sends nothing."
    static let saveDecision = "Save decision"
    static func decided(_ decision: VoteDecision) -> String {
        "You decided: \(decision == .addToMenu ? "add to the menu" : "not now")."
    }
    static let newProposalsTitle = "New proposals"
    static func asked(_ count: String) -> String { "\(count) students asked" }
    static let studentsAsked = "students asked"
    static func notHeld(_ missing: Int) -> String {
        "\(missing) more \(missing == 1 ? "proposal is" : "proposals are") counted but not in this prototype's record."
    }
    static let adviceOnly = "Advice only · you decide"
    static let openVote = "Open a vote"
    static let decline = "Decline"
    static let voteOpened = "Vote opened. This prototype sends nothing."
    static let declined = "Declined. This prototype sends nothing."
    static let redemptionsTitle = "Redemptions"
    static func redeemedIn(_ period: String) -> String { "Redeemed in \(period)" }
    static let needsYouTitle = "Needs you"
    static let nothingNeedsYou = "Nothing needs you right now."
}

// MARK: - Rules sheets

/// A short rules sheet, sized to its content: a title and at most five one-line rules.
struct AdminRulesSheet: View {
    let title: String
    let rules: [String]
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: title, onClose: onClose)
            ForEach(Array(rules.enumerated()), id: \.offset) { index, rule in
                HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s12) {
                    Text("\(index + 1)")
                        .mlFont(.bodyEmphasis)
                        .foregroundStyle(MLColor.inkSecondary)
                        .frame(width: 20, alignment: .leading)
                    Text(rule)
                        .mlFont(.body)
                        .foregroundStyle(MLColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

// MARK: - Decide

@MainActor
@Observable
final class AdminVotesModel {
    private(set) var decision: VoteDecisionRecord?
    private(set) var proposals: LoadState<VoteProposals> = .idle
    private(set) var isSaving = false
    private(set) var errorText: String?

    private let repository: any AdminVotesRewardsRepository
    private let role: Role

    init(repository: any AdminVotesRewardsRepository, role: Role) {
        self.repository = repository
        self.role = role
    }

    func load() async {
        decision = try? await repository.decision()
        do {
            proposals = .loaded(try await repository.proposals())
        } catch RepositoryError.offline(let savedAt) {
            proposals = .offline(proposals.value, savedAt: savedAt)
        } catch {
            proposals = .failed(LoadFailure(error))
        }
    }

    func decide(_ choice: VoteDecision) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        do {
            decision = try await repository.decide(choice, by: role)
            errorText = nil
            return true
        } catch {
            errorText = AdminWriteError.text(error)
            return false
        }
    }

    func respond(to id: String, _ response: ProposalResponse) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await repository.respond(to: id, response, by: role)
            errorText = nil
            await load()
            return true
        } catch {
            errorText = AdminWriteError.text(error)
            return false
        }
    }
}

/// Decide on a closed vote: two options as large rows, one line, Save decision.
struct AdminDecideSheet: View {
    let model: AdminVotesModel
    let subject: String
    let onSaved: () -> Void
    let onClose: () -> Void
    @State private var choice: VoteDecision?

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: AdminVotesRewardsCopy.decideTitle, subtitle: subject, onClose: onClose)
            VStack(spacing: MLSpacing.s8) {
                option(.addToMenu, AdminVotesRewardsCopy.addToMenu)
                option(.notNow, AdminVotesRewardsCopy.notNow)
            }
            Text(AdminVotesRewardsCopy.decisionLine)
                .mlFont(.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let error = model.errorText {
                FieldErrorText(text: error)
            }
            InkActionButton(title: AdminVotesRewardsCopy.saveDecision, isLoading: model.isSaving) {
                guard let choice else { return }
                Task { if await model.decide(choice) { onSaved() } }
            }
            .disabled(choice == nil || model.isSaving)
        }
        .onAppear { choice = model.decision?.decision }
    }

    private func option(_ value: VoteDecision, _ title: String) -> some View {
        let selected = choice == value
        return Button {
            choice = value
        } label: {
            HStack {
                Text(title).mlFont(.staffBody).foregroundStyle(MLColor.ink)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(MLColor.ink)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, MLSpacing.s16)
            .frame(minHeight: 56)
            .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
                .fill(selected ? MLColor.lime : MLColor.canvas))
            .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
                .strokeBorder(selected ? MLColor.ink : MLColor.border, lineWidth: selected ? 1.5 : 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: selected)
    }
}

// MARK: - New proposals

struct AdminProposalsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        AdminProposalsView(model: AdminVotesModel(repository: environment.repositories.adminVotesRewards,
                                                  role: nav.context.account.role), nav: nav)
    }
}

struct AdminProposalsView: View {
    @State var model: AdminVotesModel
    let nav: AdminNav

    var body: some View {
        AdminPageScaffold(title: AdminVotesRewardsCopy.newProposalsTitle, onBack: nav.pop) {
            AsyncContentView(state: model.proposals, timeZone: nav.timeZone, retry: { await model.load() }) { list in
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(list.proposals) { proposal in
                        AdminRow(title: proposal.title, detail: proposalDetail(proposal),
                                 action: { nav.push(.proposal(proposal.id)) }) { EmptyView() }
                    }
                    if list.counted > list.proposals.count {
                        Text(AdminVotesRewardsCopy.notHeld(list.counted - list.proposals.count))
                            .mlFont(.secondary)
                            .foregroundStyle(MLColor.inkSecondary)
                            .padding(.top, MLSpacing.s12)
                    }
                }
            }
        }
        .task { await model.load() }
    }

    private func proposalDetail(_ proposal: VoteProposal) -> String {
        let asked = AdminVotesRewardsCopy.asked(AdminFormat.count(proposal.askedCount))
        switch proposal.response {
        case .voteOpened: return "\(asked) · \(AdminVotesRewardsCopy.openVote)"
        case .declined: return "\(asked) · \(AdminVotesRewardsCopy.decline)"
        case nil: return asked
        }
    }
}

/// A proposal: the black card with the count, then Open a vote and Decline.
struct AdminProposalScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let id: String
    let nav: AdminNav

    var body: some View {
        AdminProposalView(model: AdminVotesModel(repository: environment.repositories.adminVotesRewards,
                                                 role: nav.context.account.role), id: id, nav: nav)
    }
}

struct AdminProposalView: View {
    @State var model: AdminVotesModel
    let id: String
    let nav: AdminNav

    var body: some View {
        AdminPageScaffold(title: AdminVotesRewardsCopy.newProposalsTitle, onBack: nav.pop) {
            if let proposal = model.proposals.value?.proposals.first(where: { $0.id == id }) {
                HeroCard {
                    VStack(alignment: .leading, spacing: MLSpacing.s8) {
                        Text(proposal.title).mlFont(.title2).foregroundStyle(MLColor.onHero)
                        HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                            Text(AdminFormat.count(proposal.askedCount))
                                .font(MLType.heroNumber)
                                .foregroundStyle(MLColor.onHero)
                                .mlNumericText(proposal.askedCount)
                            Text(AdminVotesRewardsCopy.studentsAsked).mlFont(.staffBody).foregroundStyle(MLColor.onHeroSecondary)
                        }
                        Text(AdminVotesRewardsCopy.adviceOnly).mlFont(.body).foregroundStyle(MLColor.onHeroSecondary)
                    }
                }
                if let response = proposal.response {
                    Text(response == .voteOpened ? AdminVotesRewardsCopy.voteOpened : AdminVotesRewardsCopy.declined)
                        .mlFont(.bodyEmphasis)
                        .foregroundStyle(MLColor.ink)
                } else {
                    if let error = model.errorText { FieldErrorText(text: error) }
                    InkActionButton(title: AdminVotesRewardsCopy.openVote, isLoading: model.isSaving) {
                        Task { _ = await model.respond(to: id, .voteOpened) }
                    }
                    OutlineActionButton(title: AdminVotesRewardsCopy.decline) {
                        Task { _ = await model.respond(to: id, .declined) }
                    }
                    .disabled(model.isSaving)
                }
            } else if case .failed(let failure) = model.proposals {
                AdminNote(text: failure.message)
            } else {
                ProgressView().frame(maxWidth: .infinity)
            }
        }
        .task { await model.load() }
    }
}

// MARK: - Redemptions

struct AdminRedemptionsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        let repository = environment.repositories.adminVotesRewards
        AdminPageScaffold(title: AdminVotesRewardsCopy.redemptionsTitle, onBack: nav.pop) {
            AdminLoadedPage(model: AdminPageModel { try await repository.redemptions() }, timeZone: nav.timeZone) { summary, _ in
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    HeroCard {
                        VStack(alignment: .leading, spacing: MLSpacing.s4) {
                            HeroEyebrow(label: AdminVotesRewardsCopy.redeemedIn(summary.period))
                            Text(AdminFormat.count(summary.total))
                                .font(MLType.heroNumber)
                                .foregroundStyle(MLColor.onHero)
                        }
                    }
                    VStack(spacing: 0) {
                        ForEach(summary.lines) { line in
                            AdminRow(title: line.reward, showsChevron: false, action: nil) {
                                Text(AdminFormat.count(line.count)).font(MLType.monoBody).foregroundStyle(MLColor.ink)
                            }
                        }
                    }
                }
            }
        }
    }
}
