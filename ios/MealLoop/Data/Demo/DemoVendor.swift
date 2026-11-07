#if DEMO_DATA || REVIEW_DATA
import Foundation

extension DemoDataProvider: VendorRepository {
    func vendorMess(for account: AccountID) async throws -> Mess {
        try requireConnection()
        try requireVendor(account)
        return DemoSeed.mess
    }

    func vendorHistory(for account: AccountID) async throws -> [VendorHeadcountEntry] {
        try requireConnection()
        try requireVendor(account)
        // Breakfast is the pack's sample. Its reply shows only once the story clock has reached it.
        let repliedAt = DemoSeed.vendorBreakfastRepliedAt
        var entries = [VendorHeadcountEntry(meal: DemoSeed.breakfast, sentCount: DemoSeed.vendorBreakfastSentCount, sentAt: nil,
                                            acknowledgedAt: clock.now() >= repliedAt ? repliedAt : nil, isSample: true)]
        // The story meal is read through the same headcount the Food Head reads, so both see one reply.
        let lunch = try await headcount(for: DemoSeed.lunch.id)
        if case .sent(let sent) = lunch.sentToVendor {
            entries.append(VendorHeadcountEntry(meal: DemoSeed.lunch, sentCount: sent.count, sentAt: sent.sentAt,
                                                acknowledgedAt: lunch.acknowledgment?.acknowledgedAt, isSample: false))
        }
        return entries
    }

    private func requireVendor(_ account: AccountID) throws {
        guard DemoSeed.accounts.first(where: { $0.id == account })?.role == .vendor else {
            throw RepositoryError.notAllowed(reason: "Only the vendor account reads vendor headcounts.")
        }
    }
}
#endif
