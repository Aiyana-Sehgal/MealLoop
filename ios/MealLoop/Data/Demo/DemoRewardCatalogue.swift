#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SIMULATED. The reward catalogue of one run, seeded with the labelled samples of Credits (221:64313). Shared with
/// `DemoStudentYou`, so Credits lists what the Admin left in it.
actor DemoRewardCatalogueStore {
    private(set) var items: [StudentCreditTicket] = DemoSeed.sampleCreditTickets
    private var nextNumber = 1

    func add(_ name: String, _ cost: Int) -> StudentCreditTicket {
        defer { nextNumber += 1 }
        // The place line is the wording every seeded reward offered now uses.
        let item = StudentCreditTicket(id: "demo-reward-item-\(nextNumber)", name: name, place: "At your mess counter",
                                       cost: cost, availability: .available)
        items.append(item)
        return item
    }

    func remove(_ id: String) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return false }
        items.remove(at: index)
        return true
    }
}

/// SIMULATED. The Admin's reward catalogue on the prototype data source. Nothing is sent to students.
struct DemoRewardCatalogue: RewardCatalogueRepository {
    let core: DemoDataProvider
    let store: DemoRewardCatalogueStore

    private func requireAdmin(_ role: Role) throws {
        guard role == .admin || role == .superAdmin else {
            throw RepositoryError.notAllowed(reason: "Only the admin manages rewards.")
        }
    }

    func items() async throws -> [StudentCreditTicket] {
        try await core.requireConnection()
        return await store.items
    }

    func add(name: String, cost: Int, by role: Role) async throws -> StudentCreditTicket {
        try await core.requireConnection()
        try requireAdmin(role)
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var problems: [String] = []
        if trimmed.isEmpty { problems.append("Add a name.") }
        if cost <= 0 { problems.append("Credits must be a whole number above 0.") }
        guard problems.isEmpty else { throw RepositoryError.validationFailed(problems) }
        return await store.add(trimmed, cost)
    }

    func delete(_ id: String, by role: Role) async throws {
        try await core.requireConnection()
        try requireAdmin(role)
        guard await store.remove(id) else { throw RepositoryError.notFound }
    }
}
#endif
