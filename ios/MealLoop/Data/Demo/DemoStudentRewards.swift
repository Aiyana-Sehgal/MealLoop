#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SIMULATED. Reward tickets got in one run of the app, per student. Shared with `DemoStudentYou`, so a ticket's cost
/// comes off the Credits balance and shows in Credits history.
actor DemoStudentRewardsStore {
    private var tickets: [StudentID: [StudentRewardTicket]] = [:]
    private var issues: [StudentID: [StudentBalanceIssueReceipt]] = [:]
    private var nextNumber = 0

    func list(for student: StudentID) -> [StudentRewardTicket] { tickets[student] ?? [] }

    func add(_ ticket: StudentRewardTicket, for student: StudentID) { tickets[student, default: []].append(ticket) }

    func replace(_ ticket: StudentRewardTicket, for student: StudentID) {
        guard let index = tickets[student]?.firstIndex(where: { $0.id == ticket.id }) else { return }
        tickets[student]?[index] = ticket
    }

    func record(_ issue: StudentBalanceIssueReceipt, for student: StudentID) { issues[student, default: []].append(issue) }

    /// The next ticket number in this run, from 0.
    func takeNumber() -> Int {
        defer { nextNumber += 1 }
        return nextNumber
    }
}

/// SIMULATED. Reward tickets on top of the prototype data source. The cost comes off the same balance Credits shows;
/// nothing is sent to a counter.
struct DemoStudentRewards: StudentRewardsRepository {
    let core: DemoDataProvider
    let store: DemoStudentRewardsStore
    let you: DemoStudentYou

    func getTicket(_ rewardID: String, for student: StudentID) async throws -> StudentRewardTicket {
        try await core.requireConnection()
        let credits = try await you.credits(for: student)
        guard let reward = credits.tickets.first(where: { $0.id == rewardID }) else { throw RepositoryError.notFound }
        if case .notYet = reward.availability {
            throw RepositoryError.notAllowed(reason: "This ticket isn't offered yet.")
        }
        guard let balance = credits.balance, balance >= reward.cost else {
            throw RepositoryError.notAllowed(reason: "Your balance doesn't cover this ticket.")
        }
        let number = await store.takeNumber()
        let sample = DemoSeed.sampleRewardCodes[number % DemoSeed.sampleRewardCodes.count]
        let isSample = student == DemoSeed.sampleStudent.id
        let ticket = StudentRewardTicket(id: StudentRewardTicketID("demo-reward-\(number + 1)"), rewardID: reward.id,
                                         name: reward.name, cost: reward.cost, balanceAfter: balance - reward.cost,
                                         code: sample.code, colourName: sample.colour,
                                         holderName: isSample ? "Aarav" : nil,
                                         holderMaskedID: isSample ? DemoSeed.sampleStudent.maskedID : "",
                                         gotAt: core.clock.now(), usedAt: nil)
        await store.add(ticket, for: student)
        return ticket
    }

    func tickets(for student: StudentID) async throws -> [StudentRewardTicket] {
        try await core.requireConnection()
        return await store.list(for: student).sorted { $0.gotAt > $1.gotAt }
    }

    func ticket(_ id: StudentRewardTicketID, for student: StudentID) async throws -> StudentRewardTicket {
        try await core.requireConnection()
        guard let ticket = await store.list(for: student).first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        return ticket
    }

    func recordCounterUse(of id: StudentRewardTicketID, for student: StudentID) async throws -> StudentRewardTicket {
        try await core.requireConnection()
        guard var ticket = await store.list(for: student).first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        guard !ticket.isUsed else { throw RepositoryError.notAllowed(reason: "This ticket is already used.") }
        ticket.usedAt = core.clock.now()
        await store.replace(ticket, for: student)
        return ticket
    }

    func reportBalanceIssue(_ text: String, for student: StudentID) async throws -> StudentBalanceIssueReceipt {
        try await core.requireConnection()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RepositoryError.validationFailed(["text"]) }
        let receipt = StudentBalanceIssueReceipt(text: trimmed, recordedAt: core.clock.now())
        await store.record(receipt, for: student)
        return receipt
    }
}

extension DemoSeed {
    /// SAMPLE, not measured. Ticket · Juice (1529:1901) draws the code "7A3F" and the colour "Lime". Later tickets in a
    /// run reuse the list in turn; the prototype has no code service for rewards.
    static let sampleRewardCodes: [(code: String, colour: String)] = [("7A3F", "Lime")]
}
#endif
