import Foundation

// Read models for the Food Head's More tab.

struct MenuDish: Codable, Sendable, Hashable, Identifiable {
    let id: String
    var name: String
    var isHighlight: Bool
    var isNonVeg: Bool
    /// The word was hard to read on the board: "(?)" until someone checks it.
    var needsCheck: Bool
    var suggestions: [String]
    var isLimited: Bool
}

struct MenuDay: Codable, Sendable, Hashable, Identifiable {
    let day: Date
    var meals: [MealSlot: [MenuDish]]

    var id: Date { day }

    var wordsToCheck: Int {
        meals.values.reduce(0) { $0 + $1.filter(\.needsCheck).count }
    }

    func hasWordToCheck(_ slot: MealSlot) -> Bool {
        meals[slot]?.contains(where: \.needsCheck) ?? false
    }
}

struct WeekMenu: Codable, Sendable, Hashable {
    let range: String
    let publishedAt: Date
    let today: Date
    /// The same weekday last week, for "Copy last Thursday".
    let copySourceDay: Date
    let photoSize: String
    var days: [MenuDay]
}

/// A change to today's dinner (F05).
enum QuickChange: Codable, Sendable, Hashable {
    case swap(dish: String, with: String)
    case addSpecial(name: String, isLimited: Bool, isNonVeg: Bool)
    case remove(dish: String)
}

struct PeopleRole: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let title: String
    let singular: String
    let count: Int
    let messes: String?
    /// Only Kitchen staff is written out in the pack; the others stay nil.
    let permissions: String?
    let named: [PersonLine]
}

struct PersonLine: Codable, Sendable, Hashable, Identifiable {
    let name: String
    let detail: String

    var id: String { name }
}

enum VendorChannel: String, Codable, Sendable, CaseIterable, Hashable {
    case message
    case call
}

struct VendorContact: Codable, Sendable, Hashable {
    var phone: String
    var channel: VendorChannel
}

struct AdminPeople: Codable, Sendable, Hashable {
    let roles: [PeopleRole]
    var invited: Int
    var vendor: VendorContact
}

struct AnnouncementAudience: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let title: String
    let confirmName: String
    /// Nil when the pack gives no number for this group. Never zero.
    let students: Int?
}

struct AnnouncementDraft: Codable, Sendable, Hashable {
    let audiences: [AnnouncementAudience]
    let defaultAudience: String
    let sampleMessage: String
    let maxCharacters: Int
}

struct PassesPage: Codable, Sendable, Hashable {
    let mess: String
    let title: String
    let used: Int
    let total: Int
    let expiredUnused: Int
    let requestName: String
    let requestStatus: String
    let requestDetail: String
}

struct VotesPage: Codable, Sendable, Hashable {
    let closedTitle: String
    let forPercent: Int
    let forCount: Int
    let againstCount: Int
    let advice: String
    let inProgressTitle: String
    let inProgressDetail: String
    let timeLeft: String
    let newProposals: Int
}

struct RewardLine: Codable, Sendable, Hashable, Identifiable {
    let title: String
    let status: String
    let isLive: Bool
    let detail: String
    let points: Int

    var id: String { title }
}

struct RewardsPage: Codable, Sendable, Hashable {
    let budgetTitle: String
    let spent: String
    let budget: String
    let spentShare: Double
    let detail: String
    let rewards: [RewardLine]
}

struct SpareStep: Codable, Sendable, Hashable, Identifiable {
    let title: String
    let time: String
    let isDone: Bool

    var id: String { title }
}

struct SpareFoodPage: Codable, Sendable, Hashable {
    let mess: String
    let status: String
    let title: String
    let partner: String
    let collectBy: String
    let dishes: Int
    let steps: [SpareStep]
    let note: String
}

struct HistoryLine: Codable, Sendable, Hashable, Identifiable {
    let time: String
    let title: String
    let tag: String?

    var id: String { time + title }
}

struct HistoryPage: Codable, Sendable, Hashable {
    let entriesToday: Int
    let lines: [HistoryLine]
}

struct OutingLine: Codable, Sendable, Hashable, Identifiable {
    let title: String
    let detail: String
    let count: Int?
    let status: String?

    var id: String { title }
}

struct OutingsPage: Codable, Sendable, Hashable {
    let subtitle: String
    let outNow: Int
    let dueBackTitle: String
    let dueBack: Int
    let late: Int
    let lines: [OutingLine]
}

struct AdminMoreHub: Codable, Sendable, Hashable {
    let menuStatus: String
    let passUsed: Int
    let passTotal: Int
    let outNow: Int
    let openVotes: Int
    let liveRewards: Int
    let pickups: Int
    let invited: Int
}
