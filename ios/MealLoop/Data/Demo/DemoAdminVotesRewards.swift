#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SIMULATED. Decisions and proposal answers made in one run of the app.
actor DemoAdminVotesRewardsStore {
    var decision: VoteDecisionRecord?
    var responses: [String: ProposalResponse] = [:]

    func setDecision(_ record: VoteDecisionRecord) { decision = record }
    func setResponse(_ response: ProposalResponse, for id: String) { responses[id] = response }
}

/// SIMULATED. Votes and rewards on top of the prototype data source. Nothing is sent to students.
struct DemoAdminVotesRewards: AdminVotesRewardsRepository {
    let core: DemoDataProvider
    let store: DemoAdminVotesRewardsStore

    private func requireAdmin(_ role: Role) throws {
        guard role == .admin || role == .superAdmin else {
            throw RepositoryError.notAllowed(reason: "Only the admin decides.")
        }
    }

    func decision() async throws -> VoteDecisionRecord? {
        try await core.requireConnection()
        return await store.decision
    }

    func decide(_ decision: VoteDecision, by role: Role) async throws -> VoteDecisionRecord {
        try await core.requireConnection()
        try requireAdmin(role)
        let record = VoteDecisionRecord(decision: decision, decidedAt: core.clock.now())
        await store.setDecision(record)
        return record
    }

    func proposals() async throws -> VoteProposals {
        try await core.requireConnection()
        var list: [VoteProposal] = []
        for var proposal in AdminSeed.sampleProposals {
            proposal.response = await store.responses[proposal.id]
            list.append(proposal)
        }
        return VoteProposals(proposals: list, counted: AdminSeed.votes.newProposals)
    }

    func respond(to proposal: String, _ response: ProposalResponse, by role: Role) async throws -> VoteProposal {
        try await core.requireConnection()
        try requireAdmin(role)
        guard var found = AdminSeed.sampleProposals.first(where: { $0.id == proposal }) else { throw RepositoryError.notFound }
        if let answered = await store.responses[proposal] {
            found.response = answered
            throw RepositoryError.notAllowed(reason: "This proposal is already answered.")
        }
        await store.setResponse(response, for: proposal)
        found.response = response
        return found
    }

    func redemptions() async throws -> RedemptionsSummary {
        try await core.requireConnection()
        return AdminSeed.sampleRedemptions
    }
}

extension AdminSeed {
    /// SAMPLE, from the owner's design brief (admin_votes_03_proposals: "Dosa on Fridays", "212 students asked"). The
    /// votes page counts 3 new proposals (2277:2081); the brief names only this one, so only this one is held.
    static let sampleProposals: [VoteProposal] = [
        VoteProposal(id: "demo-proposal-dosa-fridays", title: "Dosa on Fridays", askedCount: 212, response: nil),
    ]

    /// SAMPLE, from Rewards (2277:2474): "Pilot budget · August", "63 juices · 12 ice creams", "Biryani coupon · 0 claimed".
    static let sampleRedemptions = RedemptionsSummary(period: "August", lines: [
        RedemptionLine(reward: "Juice", count: 63),
        RedemptionLine(reward: "Ice cream", count: 12),
        RedemptionLine(reward: "Biryani coupon", count: 0),
    ])
}
#endif
