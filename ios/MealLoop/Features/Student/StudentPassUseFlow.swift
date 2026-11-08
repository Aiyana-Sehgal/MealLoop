import SwiftUI

// The Special pass use flow, redrawn (images student_pass_01_available, student_pass_02_use_confirm,
// student_pass_03_in_use; owner approval pending). Use pass opens a compact sheet with two explicit buttons, Use now
// and Not yet; there is no press-and-hold. The pass-use operation and its semantics are unchanged
// (`StudentPassViewModel.confirmHold`). Reverting the commit that added this file restores the hold sheet.

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

/// Use pass: a compact sheet sized to its content with two explicit buttons.
struct PassUseNowSheet: View {
    let phase: PassConfirmPhase
    let refusal: String?
    let onUse: () -> Void
    let onNotYet: () -> Void

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
            InkActionButton(title: phase == .failed ? MealsCopy.tryAgain : PassUseFlowCopy.useNow,
                            isLoading: phase == .sending, action: onUse)
                .disabled(phase == .sending)
            Button(action: onNotYet) {
                Text(PassUseFlowCopy.notYet)
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
