import SwiftUI

/// Turns SOS facts into the words the shared SOS components take.
enum DoorSOSText {
    static func incident(_ sos: SOSCase, eyebrow: String?, now: Date, timeZone: TimeZone) -> SOSIncident {
        SOSIncident(eyebrow: eyebrow, time: MLFormat.time(sos.raisedAt, in: timeZone),
                    age: DoorScannerCopy.minutesAgo(max(0, MLFormat.minutes(from: sos.raisedAt, to: now))),
                    title: sos.title, place: sos.place)
    }

    static func status(_ stage: DoorSOSStage, timeZone: TimeZone) -> SOSCardStatus {
        switch stage {
        case .notTaken:
            return .notTaken(DoorScannerCopy.nobodyTaken)
        case .takenByOther(let role):
            return .claimed(DoorScannerCopy.isChecking(MLFormat.roleName(role)))
        case .claimedByYou:
            return .claimed(DoorScannerCopy.youreChecking)
        case .checkedByYou(let at):
            return .checked(DoorScannerCopy.checkedBy(.doorScanner), time: MLFormat.time(at, in: timeZone))
        }
    }

    /// The one action on the Alerts card: none once you have marked it checked.
    static func alertAction(_ stage: DoorSOSStage) -> String? {
        switch stage {
        case .notTaken, .takenByOther: return DoorScannerCopy.illGoAndCheck
        case .claimedByYou: return DoorScannerCopy.openTheSOS
        case .checkedByYou: return nil
        }
    }
}

/// The SOS panel for the door (D13, D14). The door claims and marks checked; it has no Close case.
/// "I can't go after all" is left out because the data source has no way to release a claim.
struct DoorSOSPanel: View {
    let model: DoorSOSViewModel
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
                FieldErrorText(text: DoorScannerCopy.sosFailed)
            }
        }
    }

    @ViewBuilder
    private func panel(_ sos: SOSCase, _ stage: DoorSOSStage) -> some View {
        let incident = DoorSOSText.incident(sos, eyebrow: nil, now: now, timeZone: timeZone)
        let status = DoorSOSText.status(stage, timeZone: timeZone)
        let title = DoorScannerCopy.sosActive(model.cases.count)
        switch stage {
        case .notTaken, .takenByOther:
            SOSPanel(title: title, incident: incident, status: status, helper: DoorScannerCopy.sosHelper,
                     primary: .init(title: DoorScannerCopy.illGoAndCheck) { Task { await model.claim() } },
                     secondary: .init(title: DoorScannerCopy.notNow, handler: onClose),
                     isWorking: model.isWorking, onClose: onClose)
        case .claimedByYou:
            SOSPanel(title: title, incident: incident, status: status, note: DoorScannerCopy.onYourWay(session.supervisorName),
                     primary: .init(title: DoorScannerCopy.markAsChecked) {
                         Task { if await model.markChecked() { onChecked() } }
                     },
                     secondary: .init(title: DoorScannerCopy.backToScanning, handler: onClose),
                     isWorking: model.isWorking, onClose: onClose)
        case .checkedByYou:
            SOSPanel(title: title, incident: incident, status: status,
                     primary: .init(title: DoorScannerCopy.backToScanning, handler: onClose),
                     onClose: onClose)
        }
    }
}
