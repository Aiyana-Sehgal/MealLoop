import Foundation

/// Menu vote decisions, proposals and reward redemptions. Only the Admin and Super Admin may write; nothing is sent.
protocol AdminVotesRewardsRepository: Sendable {
    /// The closed vote's decision, nil until the admin decides.
    func decision() async throws -> VoteDecisionRecord?
    /// Records the decision; a second decision replaces the first.
    func decide(_ decision: VoteDecision, by role: Role) async throws -> VoteDecisionRecord
    func proposals() async throws -> VoteProposals
    /// Opens a vote on a proposal or declines it. A proposal answered once cannot be answered again (`notAllowed`).
    func respond(to proposal: String, _ response: ProposalResponse, by role: Role) async throws -> VoteProposal
    func redemptions() async throws -> RedemptionsSummary
}

/// The answer of any data source with no such service yet. It never fakes a result.
struct UnavailableAdminVotesRewards: AdminVotesRewardsRepository {
    private var unavailable: RepositoryError { .notImplemented(feature: "Menu votes and rewards") }

    func decision() async throws -> VoteDecisionRecord? { throw unavailable }
    func decide(_ decision: VoteDecision, by role: Role) async throws -> VoteDecisionRecord { throw unavailable }
    func proposals() async throws -> VoteProposals { throw unavailable }
    func respond(to proposal: String, _ response: ProposalResponse, by role: Role) async throws -> VoteProposal {
        throw unavailable
    }
    func redemptions() async throws -> RedemptionsSummary { throw unavailable }
}
