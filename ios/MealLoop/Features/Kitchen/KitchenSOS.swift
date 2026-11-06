import Observation
import SwiftUI

/// Where the kitchen stands on a case. Words come from `KitchenCopy`; this holds the facts only.
enum KitchenSOSStage: Equatable {
    case notTaken
    case takenByOther(Role)
    case claimedByYou
    case checkedByYou(at: Date)
}

/// SOS for the kitchen: claim and mark checked. Only the Supervisor closes a case.
@MainActor
@Observable
final class KitchenSOSViewModel {
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

    var stage: KitchenSOSStage? {
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

/// Turns SOS facts into the words the shared SOS components take.
enum KitchenSOSText {
    static func incident(_ sos: SOSCase, eyebrow: String?, now: Date, timeZone: TimeZone) -> SOSIncident {
        SOSIncident(eyebrow: eyebrow, time: MLFormat.time(sos.raisedAt, in: timeZone),
                    age: KitchenCopy.minutesAgo(max(0, MLFormat.minutes(from: sos.raisedAt, to: now))),
                    title: sos.title, place: sos.place)
    }

    static func status(_ stage: KitchenSOSStage, timeZone: TimeZone) -> SOSCardStatus {
        switch stage {
        case .notTaken:
            return .notTaken(KitchenCopy.nobodyTaken)
        case .takenByOther(let role):
            return .claimed(KitchenCopy.isChecking(MLFormat.roleName(role)))
        case .claimedByYou:
            return .claimed(KitchenCopy.youreChecking)
        case .checkedByYou(let at):
            return .checked(KitchenCopy.checkedByKitchen, time: MLFormat.time(at, in: timeZone))
        }
    }

    /// The one action on the Alerts card: none once you have marked it checked.
    static func alertAction(_ stage: KitchenSOSStage) -> String? {
        switch stage {
        case .notTaken, .takenByOther: return KitchenCopy.illGoAndCheck
        case .claimedByYou: return KitchenCopy.openTheSOS
        case .checkedByYou: return nil
        }
    }
}

/// The SOS panel for the kitchen (K20). It claims and marks checked; it has no Close case.
struct KitchenSOSPanel: View {
    let model: KitchenSOSViewModel
    let session: StaffSession
    let now: Date
    let onClose: () -> Void
    let onChecked: () -> Void

    private var timeZone: TimeZone { session.mess.timeZone }

    var body: some View {
        VStack(spacing: MLSpacing.s12) {
            if let current = model.current, let stage = model.stage {
                panel(current, stage)
            }
            if model.didFail {
                FieldErrorText(text: KitchenCopy.sosFailed)
            }
        }
    }

    @ViewBuilder
    private func panel(_ sos: SOSCase, _ stage: KitchenSOSStage) -> some View {
        let incident = KitchenSOSText.incident(sos, eyebrow: nil, now: now, timeZone: timeZone)
        let status = KitchenSOSText.status(stage, timeZone: timeZone)
        let title = KitchenCopy.sosActive(model.cases.count)
        switch stage {
        case .notTaken, .takenByOther:
            SOSPanel(title: title, incident: incident, status: status, helper: KitchenCopy.sosHelper,
                     primary: .init(title: KitchenCopy.illGoAndCheck) { Task { await model.claim() } },
                     secondary: .init(title: KitchenCopy.notNow, handler: onClose),
                     isWorking: model.isWorking, onClose: onClose)
        case .claimedByYou:
            SOSPanel(title: title, incident: incident, status: status, note: KitchenCopy.onYourWay(session.supervisorName),
                     primary: .init(title: KitchenCopy.markAsChecked) {
                         Task { if await model.markChecked() { onChecked() } }
                     },
                     secondary: .init(title: KitchenCopy.backToKitchen, handler: onClose),
                     isWorking: model.isWorking, onClose: onClose)
        case .checkedByYou:
            SOSPanel(title: title, incident: incident, status: status,
                     primary: .init(title: KitchenCopy.backToKitchen, handler: onClose),
                     onClose: onClose)
        }
    }
}
