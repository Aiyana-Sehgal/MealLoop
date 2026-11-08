import Foundation

// A reward ticket the student gets with credits (Credits · Getting a ticket 221:64396, Ticket · Juice 1529:1901,
// Ticket · Juice · Used 1529:2180) and a balance question (Rewards · Balance issue 221:64463). Additive: nothing
// existing uses it. No credit formula (P1): costs and balances come from the source.

enum StudentRewardTicketTag {}
typealias StudentRewardTicketID = Identifier<StudentRewardTicketTag>

/// A ticket the student got. The counter checks the code and the colour; no scan is needed.
struct StudentRewardTicket: Codable, Sendable, Hashable, Identifiable {
    let id: StudentRewardTicketID
    /// The `StudentCreditTicket` it was got for ("juice").
    let rewardID: String
    let name: String
    let cost: Int
    /// The balance right after it was got.
    let balanceAfter: Int
    /// Issued by the source. The prototype issues one fixed code per ticket; it does not rotate.
    let code: String
    /// The colour's name, which the counter reads ("Lime").
    let colourName: String
    let holderName: String?
    let holderMaskedID: String
    let gotAt: Date
    /// Set when the counter records the use. Nil while the ticket is valid.
    var usedAt: Date?

    var isUsed: Bool { usedAt != nil }
}

/// "Something wrong with your balance?" as the student wrote it. Recorded only; nobody is said to have read it.
struct StudentBalanceIssueReceipt: Codable, Sendable, Hashable {
    let text: String
    let recordedAt: Date
}
