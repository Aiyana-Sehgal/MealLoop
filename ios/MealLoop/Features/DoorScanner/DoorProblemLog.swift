import Foundation
import Observation

/// The three things the door can report (door_scanner_spec.md, "Report a problem").
enum DoorProblemKind: String, CaseIterable, Identifiable, Sendable {
    case scanner
    case crowd
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scanner: return "Scanner not working"
        case .crowd: return "Crowd at the door"
        case .other: return "Something else"
        }
    }

    var detail: String {
        switch self {
        case .scanner: return "The camera or the phone has stopped working"
        case .crowd: return "The line is not moving"
        case .other: return "Anything else at the door"
        }
    }

    var symbol: String {
        switch self {
        case .scanner: return "camera"
        case .crowd: return "person.2"
        case .other: return "text.bubble"
        }
    }
}

struct DoorProblem: Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: DoorProblemKind
    let sentAt: Date
}

/// Problems reported in this sign-in. SIMULATED AND LOCAL: no repository takes a problem report yet, so nothing leaves
/// this phone, the Supervisor sees nothing, and a problem stays Waiting. The gap is in docs/verification/door-scanner/REPORT.md.
@MainActor
@Observable
final class DoorProblemLog {
    private(set) var problems: [DoorProblem] = []
    private(set) var isSending = false

    private let mealState: any MealStateRepository
    private let mess: MessID
    private let clock: any AppClock

    init(mealState: any MealStateRepository, mess: MessID, clock: any AppClock) {
        self.mealState = mealState
        self.mess = mess
        self.clock = clock
    }

    /// True when the report was kept. A read of the shared data stands in for delivery, so offline is refused, not "sent".
    func report(_ kind: DoorProblemKind) async -> Bool {
        guard !isSending else { return false }
        isSending = true
        defer { isSending = false }
        do {
            _ = try await mealState.currentMeal(for: mess)
        } catch {
            return false
        }
        problems.insert(DoorProblem(id: UUID(), kind: kind, sentAt: clock.now()), at: 0)
        return true
    }
}
