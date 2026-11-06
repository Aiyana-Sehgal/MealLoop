import SwiftUI

/// The words and times of an SOS case for the shared SOS card and panel.
enum SupervisorSOSText {
    static func incident(_ sos: SOSCase, now: Date, timeZone: TimeZone, eyebrow: String? = nil) -> SOSIncident {
        let minutes = MLFormat.minutes(from: sos.raisedAt, to: now)
        return SOSIncident(eyebrow: eyebrow, time: MLFormat.time(sos.raisedAt, in: timeZone),
                           age: SupervisorCopy.ago(MLFormat.elapsed(minutes: minutes)), title: sos.title, place: sos.place)
    }

    static func status(_ stage: SupervisorSOSStage, timeZone: TimeZone) -> SOSCardStatus {
        switch stage {
        case .notTaken:
            return .notTaken(SupervisorCopy.nobodyYet)
        case .claimedByYou:
            return .claimed(SupervisorCopy.youreChecking)
        case .claimedBy(let role):
            return .notTaken(SupervisorCopy.isChecking(SupervisorFormat.who(role)))
        case .checked(let role, let at):
            return .checked(SupervisorCopy.checkedBy(SupervisorFormat.who(role)), time: MLFormat.time(at, in: timeZone))
        }
    }
}

/// The SOS panel as the Supervisor sees it (S04, S04b, S05, S05b). Only the Supervisor gets Close case.
struct SupervisorSOSPanelView: View {
    let model: SupervisorSOSModel
    let timeZone: TimeZone
    let onDismiss: () -> Void
    /// Called after the case closed, so the caller can show "Case closed".
    let onCaseClosed: () -> Void
    /// Called after any change, so every screen reloads.
    let onChange: () -> Void

    var body: some View {
        if let sos = model.current, let stage = model.stage {
            VStack(spacing: MLSpacing.s12) {
                panel(sos: sos, stage: stage)
                if let error = model.actionError {
                    FieldErrorText(text: error)
                }
            }
        }
    }

    private func panel(sos: SOSCase, stage: SupervisorSOSStage) -> some View {
        let actions = self.actions(for: stage)
        return SOSPanel(
            title: SupervisorCopy.sosActive(model.cases.count),
            incident: SupervisorSOSText.incident(sos, now: model.now, timeZone: timeZone),
            status: SupervisorSOSText.status(stage, timeZone: timeZone),
            note: stage.isChecked ? SupervisorCopy.closeWhenSatisfied : nil,
            helper: helper(for: stage),
            primary: actions.primary,
            secondary: actions.secondary,
            isWorking: model.isWorking,
            onClose: onDismiss
        )
    }

    private func helper(for stage: SupervisorSOSStage) -> String? {
        switch stage {
        case .notTaken, .claimedBy: return SupervisorCopy.freeHelper
        case .claimedByYou: return SupervisorCopy.claimedHelper
        case .checked: return nil
        }
    }

    private func actions(for stage: SupervisorSOSStage) -> (primary: SOSPanel.Action, secondary: SOSPanel.Action) {
        switch stage {
        case .notTaken, .claimedBy:
            return (.init(title: SupervisorCopy.illGo) { run { await model.claim() } },
                    .init(title: SupervisorCopy.notNow, handler: onDismiss))
        case .claimedByYou:
            return (.init(title: SupervisorCopy.markChecked) { run { await model.markChecked() } },
                    .init(title: SupervisorCopy.backToMeal, handler: onDismiss))
        case .checked:
            return (.init(title: SupervisorCopy.closeCase) {
                        run {
                            let closed = await model.close()
                            if closed {
                                onDismiss()
                                onCaseClosed()
                            }
                            return closed
                        }
                    },
                    .init(title: SupervisorCopy.notYet, handler: onDismiss))
        }
    }

    private func run(_ work: @escaping () async -> Bool) {
        Task {
            if await work() { onChange() }
        }
    }
}

extension SupervisorSOSStage {
    var isChecked: Bool {
        if case .checked = self { return true }
        return false
    }
}
