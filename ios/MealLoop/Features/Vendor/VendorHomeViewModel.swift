import Foundation
import Observation

/// Who can open the Vendor role: the vendor account only.
enum VendorAccess {
    static func canOpen(_ session: Session) -> Bool { session.account.role == .vendor }
}

/// Where the current meal's headcount stands, as the vendor may see it. No forecast and no dish quantities.
enum VendorPhase: Equatable {
    case notApproved
    case approvedNotSent
    case sent(count: Int, sentAt: Date)
    case acknowledged(count: Int, sentAt: Date, acknowledgedAt: Date)
}

struct VendorHomeContent: Equatable {
    let mess: Mess
    let meal: Meal
    let phase: VendorPhase
    /// The latest meal before this one whose headcount reached the vendor, if any.
    let previous: VendorHeadcountEntry?
}

/// Home (screens 1 to 4). It reads the headcount the Food Head reads and writes the acknowledgment through
/// `acknowledgeHeadcount`, which decides when acknowledging is allowed.
@MainActor
@Observable
final class VendorHomeViewModel {
    enum SendState: Equatable {
        case idle
        case sending
        /// The acknowledgment did not reach MealLoop. Nothing is shown as acknowledged.
        case failed
    }

    private(set) var state: LoadState<VendorHomeContent> = .idle
    private(set) var send: SendState = .idle
    let account: Account

    private let repositories: Repositories

    init(account: Account, repositories: Repositories) {
        self.account = account
        self.repositories = repositories
    }

    var mess: Mess? { state.value?.mess }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let mess = try await repositories.vendor.vendorMess(for: account.id)
            guard let status = try await repositories.mealState.currentMeal(for: mess.id) else {
                state = .empty
                return
            }
            let headcount = try await repositories.headcount.headcount(for: status.meal.id)
            let history = try await repositories.vendor.vendorHistory(for: account.id)
            let previous = history.filter { $0.meal.startsAt < status.meal.startsAt }.last
            state = .loaded(VendorHomeContent(mess: mess, meal: status.meal, phase: Self.phase(headcount), previous: previous))
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    /// Acknowledge, or retry a failed one. The backend keeps the first acknowledgment of a meal and returns it on a
    /// repeat, so a retry after a send that did arrive cannot count twice.
    func acknowledge() async {
        guard send != .sending, let meal = state.value?.meal else { return }
        send = .sending
        do {
            _ = try await repositories.headcount.acknowledgeHeadcount(for: meal.id, by: account.id)
            send = .idle
            await load()
        } catch {
            send = .failed
        }
    }

    static func phase(_ headcount: Headcount) -> VendorPhase {
        switch headcount.vendorAcknowledgmentStatus {
        case .acknowledged(let record):
            if case .sent(let sent) = headcount.sentToVendor {
                return .acknowledged(count: sent.count, sentAt: sent.sentAt, acknowledgedAt: record.acknowledgedAt)
            }
            return .notApproved
        case .pending:
            if case .sent(let sent) = headcount.sentToVendor { return .sent(count: sent.count, sentAt: sent.sentAt) }
            return .notApproved
        case .notPublished:
            return headcount.approved.count == nil ? .notApproved : .approvedNotSent
        }
    }
}

/// History (screen 5): today's headcounts that reached the vendor.
@MainActor
@Observable
final class VendorHistoryViewModel {
    private(set) var state: LoadState<[VendorHeadcountEntry]> = .idle
    private let account: Account
    private let vendor: any VendorRepository

    init(account: Account, vendor: any VendorRepository) {
        self.account = account
        self.vendor = vendor
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let entries = try await vendor.vendorHistory(for: account.id)
            state = entries.isEmpty ? .empty : .loaded(entries.reversed())
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }
}
