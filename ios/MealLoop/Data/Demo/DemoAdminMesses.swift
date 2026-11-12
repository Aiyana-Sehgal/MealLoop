#if DEMO_DATA || REVIEW_DATA
import Foundation

/// DEMO DATA for the mess tiles on Today. Sample values only, never measured results.
/// Figma file nzzTAm9YnJRSdKEeYUWUEb, page "12 Admin Redesign". Each value cites its frame.
enum AdminMessSeed {
    private static func mess(_ id: String, slot: MealSlot, expected: Int? = nil, low: Int? = nil, high: Int? = nil, saidYes: Int? = nil,
                             usual: Int? = nil, usualLabel: String? = nil, events: String? = nil, sendBy: Date? = nil, forecastAt: Date? = nil,
                             sentAt: Date? = nil, reply: AdminVendorReply = .notSent, noReplyMinutes: Int? = nil,
                             sentBefore: [AdminSentBefore] = [], approvedAt: Date? = nil, cutoff: Int? = nil,
                             answered: Int? = nil) -> AdminMessHeadcount {
        AdminMessHeadcount(id: id, name: id, slot: slot, expected: expected, rangeLow: low, rangeHigh: high, saidYes: saidYes, usual: usual,
                           usualLabel: usualLabel, events: events, sendBy: sendBy, forecastAt: forecastAt, sentAt: sentAt, reply: reply,
                           noReplyMinutes: noReplyMinutes, sentBefore: sentBefore, adjustmentReason: nil,
                           approvedBy: approvedAt == nil ? nil : .admin, approvedAt: approvedAt, cutoffForecast: cutoff, answered: answered)
    }

    /// 2259:6 and 2259:160423 both list this row under "Sent before".
    private static let mainBreakfast = AdminSentBefore(title: "Main · Breakfast · 410", repliedAt: DemoSeed.time(7, 5))

    static let days: [MealSlot: AdminMessDay] = [
        .lunch: AdminMessDay(slot: .lunch, headcountDue: nil, messes: [
            // 2257:158261 tile and 2259:6 Headcount · North: 700, range 660–740, 2,310 said yes, usual Wed 692, no events, send by 11:30.
            // SAMPLE, owner mock of 12 Nov 2026 (Super Admin Today, North): approved 700 at 10:12 AM by the Food Head,
            // cutoff 700 locked at 10:00 AM, 588 answered.
            mess("North", slot: .lunch, expected: 700, low: 660, high: 740, saidYes: 2310, usual: 692, usualLabel: "usual Wed", events: "None",
                 sendBy: DemoSeed.time(11, 30), sentBefore: [mainBreakfast], approvedAt: DemoSeed.time(10, 12), cutoff: 700, answered: 588),
            // 2257:158261 tile and 2259:160423 Headcount · South · No reply: 612, sent 10:15, no reply for 55 min.
            mess("South", slot: .lunch, expected: 612, sentAt: DemoSeed.time(10, 15), reply: .noReply, noReplyMinutes: 55, sentBefore: [mainBreakfast]),
            // 2257:158261 tile: dashed, "No data".
            mess("Annexe", slot: .lunch),
        ]),
        // 2258:460 Today · Dinner: "headcount due 4:30 PM", North and South "Forecast at 3:30", Annexe "No data".
        .dinner: AdminMessDay(slot: .dinner, headcountDue: DemoSeed.time(16, 30), messes: [
            mess("North", slot: .dinner, forecastAt: DemoSeed.time(15, 30)),
            mess("South", slot: .dinner, forecastAt: DemoSeed.time(15, 30)),
            mess("Annexe", slot: .dinner),
        ], ownForecastAt: DemoSeed.time(15, 30)),
    ]

    /// No frame draws these meals for the other messes, so every tile is missing data.
    static func missingDay(_ slot: MealSlot) -> AdminMessDay {
        AdminMessDay(slot: slot, headcountDue: nil, messes: ["North", "South", "Annexe"].map { mess($0, slot: slot) })
    }

    /// 2260:160216 Live meal · Main · Serving: "usual by now ~690". Lunch only.
    static let usualByNowLunch = 690

    /// A06_students_not_answered_by_mess, the page behind the row on 2262:6. The four add up to the 630 on that frame.
    static let notAnswered = [AdminMessCount(name: "Main Mess", students: 210), AdminMessCount(name: "North Mess", students: 180),
                              AdminMessCount(name: "South Mess", students: 160), AdminMessCount(name: "Annexe Mess", students: 80)]
}

actor DemoAdminMessStore {
    private var days = AdminMessSeed.days
    private var sendKeys: Set<IdempotencyKey> = []

    func day(_ slot: MealSlot) -> AdminMessDay { days[slot] ?? AdminMessSeed.missingDay(slot) }

    func mess(_ id: String, slot: MealSlot) throws -> AdminMessHeadcount {
        guard let mess = day(slot).messes.first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        return mess
    }

    private func update(_ changed: AdminMessHeadcount) {
        let current = day(changed.slot)
        days[changed.slot] = AdminMessDay(slot: current.slot, headcountDue: current.headcountDue,
                                          messes: current.messes.map { $0.id == changed.id ? changed : $0 },
                                          ownForecastAt: current.ownForecastAt)
    }

    func send(_ id: String, slot: MealSlot, key: IdempotencyKey, at now: Date) throws -> AdminMessHeadcount {
        var mess = try mess(id, slot: slot)
        guard !sendKeys.contains(key) else { return mess }
        guard mess.expected != nil else { throw RepositoryError.notAllowed(reason: "There is no headcount to send yet.") }
        guard mess.sentAt == nil else { throw RepositoryError.notAllowed(reason: "This headcount was already sent.") }
        sendKeys.insert(key)
        mess.sentAt = now
        mess.reply = .waiting
        update(mess)
        return mess
    }

    func adjust(_ id: String, slot: MealSlot, to count: Int, reason: String?) throws -> AdminMessHeadcount {
        var mess = try mess(id, slot: slot)
        guard mess.sentAt == nil else { throw RepositoryError.notAllowed(reason: "This headcount was already sent.") }
        guard count >= 0 else { throw RepositoryError.validationFailed(["A headcount can't be below zero."]) }
        let said = reason?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if count != mess.expected, said.isEmpty { throw RepositoryError.validationFailed(["Say why the number changed."]) }
        mess.expected = count
        mess.adjustmentReason = said.isEmpty ? mess.adjustmentReason : said
        update(mess)
        return mess
    }
}

/// Reads and writes the sample messes, with the same connection and role rules as the other Admin repositories.
struct DemoAdminMesses: AdminMessRepository {
    let core: DemoDataProvider
    let store: DemoAdminMessStore

    private func requireFoodHead(_ role: Role) throws {
        guard role == .admin else { throw RepositoryError.notAllowed(reason: "Only the Food Head can do this.") }
    }

    func messDay(for slot: MealSlot) async throws -> AdminMessDay {
        try await core.requireConnection()
        return await store.day(slot)
    }

    func messHeadcount(_ id: String, slot: MealSlot) async throws -> AdminMessHeadcount {
        try await core.requireConnection()
        return try await store.mess(id, slot: slot)
    }

    func sendHeadcount(mess id: String, slot: MealSlot, key: IdempotencyKey, by role: Role) async throws -> AdminMessHeadcount {
        try await core.requireConnection()
        try requireFoodHead(role)
        return try await store.send(id, slot: slot, key: key, at: core.clock.now())
    }

    func adjustHeadcount(mess id: String, slot: MealSlot, to count: Int, reason: String?, by role: Role) async throws -> AdminMessHeadcount {
        try await core.requireConnection()
        try requireFoodHead(role)
        return try await store.adjust(id, slot: slot, to: count, reason: reason)
    }

    func liveReference(for meal: MealID) async throws -> AdminLiveReference {
        try await core.requireConnection()
        return AdminLiveReference(usualByNow: meal == DemoSeed.lunch.id ? AdminMessSeed.usualByNowLunch : nil)
    }

    func notAnsweredByMess() async throws -> [AdminMessCount] {
        try await core.requireConnection()
        return AdminMessSeed.notAnswered
    }
}
#endif
