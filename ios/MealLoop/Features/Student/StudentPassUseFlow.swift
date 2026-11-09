import SwiftUI

// The Special pass use flow, redrawn (images student_pass_01_available, student_pass_02_use_confirm,
// student_pass_03_in_use). Owner decision (9 November): the pass keeps hold-to-use, so Use pass opens a compact sheet
// whose confirm control is the hold (221:63180) plus Cancel. The pass-use operation is unchanged
// (`StudentPassViewModel.confirmHold`).

/// Words of the redrawn pass flow. Wording only; times come from the pass's meal.
enum PassUseFlowCopy {
    static let howItWorks = "HOW IT WORKS"
    static let goToCounter = "Go to the counter"
    static let tapWhenThere = "Tap Use pass when you are there"
    static let notBefore = "Not before. It cannot be undone."
    static let showTheCode = "Show the code"
    static let staffCompare = "The staff compare it with their screen"
    static let useNowTitle = "Use your Special pass now?"
    static let useNow = "Use now"
    static let notYet = "Not yet"
    static let keepHolding = "Keep holding…"
    static let holdHint = "Touch and hold to use the pass."
}

/// "How it works" in three short steps under the Available card.
struct PassHowItWorks: View {
    let ticket: StudentPassTicket
    let timeZone: TimeZone

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(PassUseFlowCopy.howItWorks)
                .font(StudentType.eyebrow)
                .tracking(1.2)
                .foregroundStyle(MLColor.inkSecondary)
                .padding(.bottom, MLSpacing.s8)
                .accessibilityAddTraits(.isHeader)
            step(1, PassUseFlowCopy.goToCounter,
                 "\(StudentFormat.shortDay(ticket.meal.startsAt, in: timeZone)), "
                 + MLFormat.timeRange(ticket.meal.startsAt, ticket.meal.endsAt, in: timeZone))
            step(2, PassUseFlowCopy.tapWhenThere, PassUseFlowCopy.notBefore)
            step(3, PassUseFlowCopy.showTheCode, PassUseFlowCopy.staffCompare)
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
    }

    private func step(_ number: Int, _ title: String, _ detail: String) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(MLColor.border).frame(height: 1)
            HStack(spacing: MLSpacing.s16) {
                Text("\(number)")
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(MLColor.ink)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(MLColor.surface))
                    .overlay(Circle().strokeBorder(MLColor.border))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(StudentType.body).foregroundStyle(MLColor.ink)
                    Text(detail).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.vertical, MLSpacing.s12)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(number). \(title). \(detail)")
        }
    }
}

/// The hold behind Use pass (Pass · Confirm (holding) 221:63180): it completes only after the full hold; lifting the
/// finger early or Cancel uses nothing. Kept apart from the view so the rule is tested.
@MainActor
@Observable
final class PassHoldTracker {
    enum Outcome: Equatable { case idle, holding, completed, released, cancelled }

    static let holdSeconds: Double = 1.2

    private(set) var outcome: Outcome = .idle
    private var startedAt: Date?

    func press(at time: Date) {
        startedAt = time
        outcome = .holding
    }

    /// The full hold ran: the pass is used.
    func complete() {
        guard outcome == .holding else { return }
        startedAt = nil
        outcome = .completed
    }

    /// The finger lifted. Before the full hold, nothing is used.
    @discardableResult
    func release(at time: Date) -> Outcome {
        guard outcome == .holding, let startedAt else { return outcome }
        self.startedAt = nil
        outcome = time.timeIntervalSince(startedAt) >= Self.holdSeconds ? .completed : .released
        return outcome
    }

    func cancel() {
        startedAt = nil
        outcome = .cancelled
    }

    func reset() {
        startedAt = nil
        outcome = .idle
    }
}

/// "Hold to use": a pill that fills lime while held, releases to cancel and completes on the full hold. Under Reduce
/// Motion the fill does not sweep; the label says to keep holding. VoiceOver and Switch Control use it with one action.
struct PassHoldToUseButton: View {
    let tracker: PassHoldTracker
    let isFailed: Bool
    let onComplete: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fill: CGFloat = 0

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            Image(systemName: "hand.raised").accessibilityHidden(true)
            Text(tracker.outcome == .holding && reduceMotion ? PassUseFlowCopy.keepHolding : MealsCopy.holdToUse)
        }
        .font(StudentType.bodySemibold)
        .foregroundStyle(MLColor.ink)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(MLColor.surface)
                    Rectangle().fill(MLColor.lime).frame(width: geometry.size.width * fill)
                }
                .clipShape(Capsule())
            }
        }
        .overlay(Capsule().strokeBorder(isFailed ? MLColor.danger : MLColor.ink, lineWidth: 1.5))
        .contentShape(Capsule())
        .onLongPressGesture(minimumDuration: PassHoldTracker.holdSeconds, perform: {
            fill = 1
            tracker.complete()
            onComplete()
        }, onPressingChanged: { pressing in
            if pressing {
                tracker.press(at: Date())
                if reduceMotion {
                    fill = 0
                } else {
                    withAnimation(.linear(duration: PassHoldTracker.holdSeconds)) { fill = 1 }
                }
            } else if tracker.outcome == .holding {
                tracker.release(at: Date())
                withAnimation(reduceMotion ? nil : MLMotion.Curve.snappy.animation) { fill = 0 }
            }
        })
        .sensoryFeedback(.selection, trigger: tracker.outcome == .holding) { _, holding in holding }
        .sensoryFeedback(.success, trigger: tracker.outcome == .completed) { _, done in done }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(PassUseFlowCopy.holdHint)
        .accessibilityAction {
            tracker.press(at: Date())
            tracker.complete()
            onComplete()
        }
    }
}

/// Use pass: a compact sheet sized to its content. The confirm control is the hold; Cancel uses nothing.
struct PassHoldSheet: View {
    let phase: PassConfirmPhase
    let refusal: String?
    let tracker: PassHoldTracker
    let onUse: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            VStack(alignment: .leading, spacing: MLSpacing.s8) {
                Text(PassUseFlowCopy.useNowTitle)
                    .font(StudentType.section)
                    .foregroundStyle(MLColor.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(MealsCopy.oneUse)
                    .font(StudentType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            if phase == .failed {
                FieldErrorText(text: refusal ?? MealsCopy.couldntUse)
            }
            if phase == .sending {
                HStack(spacing: MLSpacing.s8) {
                    ProgressView().tint(MLColor.ink)
                    Text(MealsCopy.sending).font(StudentType.bodySemibold)
                }
                .foregroundStyle(MLColor.ink)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Capsule().fill(MLColor.lime))
                .accessibilityElement(children: .combine)
            } else {
                PassHoldToUseButton(tracker: tracker, isFailed: phase == .failed, onComplete: onUse)
            }
            Button {
                tracker.cancel()
                onCancel()
            } label: {
                Text(MealsCopy.cancel)
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(MLColor.ink)
                    .frame(maxWidth: .infinity, minHeight: MLSize.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(phase == .sending)
        }
        .sensoryFeedback(trigger: phase) { _, new in new == .failed ? .warning : nil }
    }
}
