import Foundation
import Observation

/// Where the door stands on a case. Words come from `DoorScannerCopy`; this holds the facts only.
enum DoorSOSStage: Equatable {
    case notTaken
    case takenByOther(Role)
    case claimedByYou
    case checkedByYou(at: Date)
}

/// SOS for the door: claim and mark checked. The door never closes a case; only the Supervisor does.
@MainActor
@Observable
final class DoorSOSViewModel {
    private(set) var cases: [SOSCase] = []
    private(set) var isWorking = false
    private(set) var didFail = false

    private let sos: any SOSRepository
    private let mess: MessID
    private let role: Role

    init(sos: any SOSRepository, mess: MessID, role: Role) {
        self.sos = sos
        self.mess = mess
        self.role = role
    }

    /// The tab exists only while this is non-nil.
    var current: SOSCase? { cases.first }

    var isClaimedByYou: Bool { current?.claim?.role == role }

    var stage: DoorSOSStage? {
        guard let current else { return nil }
        if let check = current.checks.last(where: { $0.role == role }) { return .checkedByYou(at: check.at) }
        guard let claim = current.claim else { return .notTaken }
        return claim.role == role ? .claimedByYou : .takenByOther(claim.role)
    }

    /// A failed read leaves the last known cases in place. SOS never blocks Home.
    func load() async {
        if let active = try? await sos.activeCases(for: mess) {
            cases = active
        }
    }

    func claim() async {
        await change { [sos, role] id in try await sos.claim(id, by: role) }
    }

    /// True when the check was saved, so the screen can say so.
    func markChecked() async -> Bool {
        await change { [sos, role] id in try await sos.markChecked(id, by: role) }
    }

    @discardableResult
    private func change(_ work: (SOSCaseID) async throws -> SOSCase) async -> Bool {
        guard !isWorking, let id = current?.id else { return false }
        isWorking = true
        didFail = false
        defer { isWorking = false }
        do {
            let updated = try await work(id)
            cases = cases.map { $0.id == updated.id ? updated : $0 }
            return true
        } catch {
            didFail = true
            return false
        }
    }
}
