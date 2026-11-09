import Foundation

/// The rewards students can get with credits, managed by the Admin (approved images admin_rewards_03_manage and
/// admin_rewards_04_add_sheet). The Student Credits screen reads the same list, so a change shows there at once.
/// Costs are entered by the Admin: there is no formula (P1 stays open).
protocol RewardCatalogueRepository: Sendable {
    func items() async throws -> [StudentCreditTicket]
    /// Refused (`validationFailed`) when the name is empty or the cost is not a positive whole number; only the Admin
    /// and Super Admin may add (`notAllowed`).
    func add(name: String, cost: Int, by role: Role) async throws -> StudentCreditTicket
    /// Tickets already got for this reward stay valid. `notFound` when it is not in the catalogue.
    func delete(_ id: String, by role: Role) async throws
}

/// The answer of any data source with no such service yet. It never fakes a result.
struct UnavailableRewardCatalogue: RewardCatalogueRepository {
    private var unavailable: RepositoryError { .notImplemented(feature: "Reward catalogue") }

    func items() async throws -> [StudentCreditTicket] { throw unavailable }
    func add(name: String, cost: Int, by role: Role) async throws -> StudentCreditTicket { throw unavailable }
    func delete(_ id: String, by role: Role) async throws { throw unavailable }
}
