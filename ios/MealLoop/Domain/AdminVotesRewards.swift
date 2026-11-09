import Foundation

// Menu votes (Decide, New proposals, a proposal) and Rewards (Redemptions) for the all-mess Admin. Figma draws only the
// Success state of Menu voting (2277:2081) and Rewards (2277:2474); these pages follow the owner's design brief and are
// listed "needs design" in docs/verification/admin-polish/REPORT.md. Additive: nothing existing uses them.
// A vote is advice only: the admin decides. Students are never named. Nothing is sent to anyone.

/// What the admin decided on a closed vote.
enum VoteDecision: String, Codable, Sendable, Hashable, CaseIterable {
    case addToMenu
    case notNow
}

struct VoteDecisionRecord: Codable, Sendable, Hashable {
    let decision: VoteDecision
    let decidedAt: Date
}

/// What the admin did with a proposal.
enum ProposalResponse: String, Codable, Sendable, Hashable {
    case voteOpened
    case declined
}

/// A dish students asked for. A count only, never who.
struct VoteProposal: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let title: String
    let askedCount: Int
    var response: ProposalResponse?
}

/// New proposals: the ones the record holds, and how many the votes page counts.
struct VoteProposals: Codable, Sendable, Hashable {
    let proposals: [VoteProposal]
    /// From the votes page ("3 new proposals"). Can be more than the record holds; the page says so.
    let counted: Int
}

/// Redemptions by reward, for a period. Counts only, no names.
struct RedemptionLine: Codable, Sendable, Hashable, Identifiable {
    var id: String { reward }
    let reward: String
    let count: Int
}

struct RedemptionsSummary: Codable, Sendable, Hashable {
    /// "August".
    let period: String
    let lines: [RedemptionLine]

    var total: Int { lines.reduce(0) { $0 + $1.count } }
}
