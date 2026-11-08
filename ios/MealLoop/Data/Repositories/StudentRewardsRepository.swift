import Foundation

/// Getting a reward ticket with credits, and the ticket afterwards. The balance never goes below zero: a ticket the
/// balance does not cover is refused and nothing is taken.
protocol StudentRewardsRepository: Sendable {
    /// Takes the ticket's cost from the balance and issues the ticket. Refused (`notAllowed`) when the ticket is not
    /// offered yet, the balance is unknown or does not cover the cost.
    func getTicket(_ rewardID: String, for student: StudentID) async throws -> StudentRewardTicket
    /// Newest first.
    func tickets(for student: StudentID) async throws -> [StudentRewardTicket]
    func ticket(_ id: StudentRewardTicketID, for student: StudentID) async throws -> StudentRewardTicket
    /// The counter's side: records that the ticket was used. A used ticket cannot be used again (`notAllowed`).
    func recordCounterUse(of id: StudentRewardTicketID, for student: StudentID) async throws -> StudentRewardTicket
    /// Records "Something wrong with your balance?". An empty text is refused.
    func reportBalanceIssue(_ text: String, for student: StudentID) async throws -> StudentBalanceIssueReceipt
}

/// The answer of any data source with no such service yet. It never fakes a result.
struct UnavailableStudentRewards: StudentRewardsRepository {
    private var unavailable: RepositoryError { .notImplemented(feature: "Reward tickets") }

    func getTicket(_ rewardID: String, for student: StudentID) async throws -> StudentRewardTicket { throw unavailable }
    func tickets(for student: StudentID) async throws -> [StudentRewardTicket] { throw unavailable }
    func ticket(_ id: StudentRewardTicketID, for student: StudentID) async throws -> StudentRewardTicket {
        throw unavailable
    }
    func recordCounterUse(of id: StudentRewardTicketID, for student: StudentID) async throws -> StudentRewardTicket {
        throw unavailable
    }
    func reportBalanceIssue(_ text: String, for student: StudentID) async throws -> StudentBalanceIssueReceipt {
        throw unavailable
    }
}
