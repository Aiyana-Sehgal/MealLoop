import SwiftUI

// "What happens next" (approved image student_outing_01_what_happens_next; owner decision, 9 November): three vertical
// steps, Your guardian, The warden, You are out. The current step is lime and marked, the others hollow; "You are out"
// is reached only once the warden has approved. Nothing is approved by waiting.

enum OutingNextStepsCopy {
    static let title = "WHAT HAPPENS NEXT"
    static let guardian = "Your guardian"
    static let warden = "The warden"
    static let youAreOut = "You are out"
    static let guardianLine = "They say yes or no."
    static let guardianSaidNo = "Said no. The request stops here."
    static let wardenLine = "Decides after your guardian."
    static let wardenSaidNo = "Said no. The request stops here."
    static func outLine(_ window: String?) -> String {
        window.map { "\($0), only after the warden says yes." } ?? "Only after the warden says yes."
    }
    static let nothingByWaiting = "Nothing is approved by waiting."
    static let done = "Done"
    static let now = "Now"
    static let stopped = "Stopped"
}

enum OutingNextSteps {
    enum State: Equatable { case done, current, upcoming, stopped }

    /// The three steps for a request at `stage`; nil is a request not sent yet (the guardian is next).
    static func states(for stage: OutingStage?) -> [State] {
        guard let stage else { return [.current, .upcoming, .upcoming] }
        switch stage {
        case .awaitingGuardian, .guardianCallRequested, .guardianAskedChange:
            return [.current, .upcoming, .upcoming]
        case .guardianRejected:
            return [.stopped, .upcoming, .upcoming]
        case .awaitingWarden, .wardenAskedChange:
            return [.done, .current, .upcoming]
        case .wardenRejected:
            return [.done, .stopped, .upcoming]
        case .passSigned, .out:
            return [.done, .done, .current]
        case .returned, .closed:
            return [.done, .done, .done]
        case .withdrawn:
            return [.upcoming, .upcoming, .upcoming]
        }
    }
}

struct OutingNextStepsCard: View {
    let stage: OutingStage?
    /// "6 PM – 9 PM", from the request or the chosen hours. Nil when none is known.
    let window: String?

    private var states: [OutingNextSteps.State] { OutingNextSteps.states(for: stage) }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Text(OutingNextStepsCopy.title)
                .font(StudentType.eyebrow)
                .tracking(1.2)
                .foregroundStyle(MLColor.onHeroSecondary)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 0) {
                step(0, OutingNextStepsCopy.guardian,
                     states[0] == .stopped ? OutingNextStepsCopy.guardianSaidNo : OutingNextStepsCopy.guardianLine)
                step(1, OutingNextStepsCopy.warden,
                     states[1] == .stopped ? OutingNextStepsCopy.wardenSaidNo : OutingNextStepsCopy.wardenLine)
                step(2, OutingNextStepsCopy.youAreOut, OutingNextStepsCopy.outLine(window), isLast: true)
            }
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous).fill(MLColor.heroBackground))
    }

    private func step(_ index: Int, _ title: String, _ line: String, isLast: Bool = false) -> some View {
        let state = states[index]
        return HStack(alignment: .top, spacing: MLSpacing.s12) {
            VStack(spacing: 0) {
                marker(state)
                if !isLast {
                    Rectangle().fill(MLColor.onHeroSecondary).frame(width: 1.5).frame(minHeight: 24)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(state == .current ? MLColor.lime : MLColor.onHero)
                Text(line)
                    .font(StudentType.secondary)
                    .foregroundStyle(MLColor.onHeroSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : MLSpacing.s12)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(label(state))
    }

    @ViewBuilder
    private func marker(_ state: OutingNextSteps.State) -> some View {
        switch state {
        case .current:
            Circle().fill(MLColor.lime).frame(width: 22, height: 22)
                .overlay(Circle().strokeBorder(MLColor.onHero, lineWidth: 1.5))
        case .done:
            Circle().fill(MLColor.onHero).frame(width: 22, height: 22)
                .overlay(Image(systemName: "checkmark").font(StudentType.tag).foregroundStyle(MLColor.ink))
        case .stopped:
            Circle().strokeBorder(MLColor.onHero, lineWidth: 1.5).frame(width: 22, height: 22)
                .overlay(Image(systemName: "xmark").font(StudentType.tag).foregroundStyle(MLColor.onHero))
        case .upcoming:
            Circle().strokeBorder(MLColor.onHero, lineWidth: 1.5).frame(width: 22, height: 22)
        }
    }

    private func label(_ state: OutingNextSteps.State) -> String {
        switch state {
        case .done: OutingNextStepsCopy.done
        case .current: OutingNextStepsCopy.now
        case .stopped: OutingNextStepsCopy.stopped
        case .upcoming: ""
        }
    }
}

/// "Nothing is approved by waiting." under the card.
struct OutingNothingByWaiting: View {
    var body: some View {
        Text(OutingNextStepsCopy.nothingByWaiting)
            .font(StudentType.secondary)
            .foregroundStyle(MLColor.inkSecondary)
    }
}
