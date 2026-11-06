import SwiftUI

/// Where a student's answer for one meal stands. Whether the cutoff has passed is decided by `IntentionPolicy`;
/// the caller passes the result in.
enum MealAnswerState: Equatable {
    case unanswered
    case answered(MealIntention)
    /// The write is running: every button ignores taps, so an answer can't be sent twice.
    case saving(MealIntention)
    /// The cutoff has passed. Carries the answer given, if any. The entry QR stays available.
    case locked(MealIntention?)

    /// How one button looks in this state.
    func appearance(of option: MealIntention) -> MealAnswerAppearance {
        switch self {
        case .unanswered:
            return option == .attending ? .primary : .outline
        case .answered(let chosen):
            return option == chosen ? .selected : .outline
        case .saving(let chosen):
            return option == chosen ? .saving : .outline
        case .locked(let chosen):
            return option == chosen ? .lockedSelected : .locked
        }
    }

    var acceptsTaps: Bool {
        switch self {
        case .unanswered, .answered:
            return true
        case .saving, .locked:
            return false
        }
    }

    /// The state in words, so it never depends on the fill or the dashes alone.
    func spokenValue(of option: MealIntention) -> String {
        switch appearance(of: option) {
        case .primary, .outline:
            return ""
        case .selected:
            return "Selected"
        case .saving:
            return "Saving"
        case .locked:
            return "Locked"
        case .lockedSelected:
            return "Selected, locked"
        }
    }
}

enum MealAnswerAppearance: Equatable {
    case primary
    case outline
    case selected
    case saving
    case locked
    case lockedSelected
}

/// Keeps a disabled label at full strength. `.plain` greys it, and a locked answer must stay readable
/// (redesign prompt, stage P5: "dashed outlines with readable text"). The dashes and the lock carry the state.
private struct ReadableWhenDisabledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

/// The filled light button on a black card ("Show entry QR", "Entry QR" on 04).
struct HeroSurfaceButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, MLSpacing.s8)
                .frame(maxWidth: .infinity, minHeight: MLSize.button)
                .background(Capsule().fill(MLColor.fillQuiet))
        }
        .buttonStyle(.plain)
    }
}

/// The answer buttons of the Lunch answer page (07): I'm in on its own row, then Skip and Not sure.
/// At most one is filled, so there is one primary action. Once locked they go dashed and stop taking taps.
struct MealAnswerButtons: View {
    let state: MealAnswerState
    var attendingTitle: String = "I'm in"
    var skippingTitle: String = "Skip"
    var notSureTitle: String = "Not sure"
    /// Why the buttons are locked, shown with a lock icon ("Answers closed at 9 AM. Your QR still works.").
    var lockedNote: String?
    let onAnswer: (MealIntention) -> Void

    var body: some View {
        VStack(spacing: MLSpacing.s12) {
            button(.attending, title: attendingTitle)
            HStack(spacing: MLSpacing.s12) {
                button(.skipping, title: skippingTitle)
                button(.notSure, title: notSureTitle)
            }
            if case .locked = state, let lockedNote {
                HStack(spacing: MLSpacing.s8) {
                    Image(systemName: "lock")
                        .accessibilityHidden(true)
                    Text(lockedNote)
                }
                .font(MLType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func button(_ option: MealIntention, title: String) -> some View {
        let appearance = state.appearance(of: option)
        return Button {
            onAnswer(option)
        } label: {
            ZStack {
                HStack(spacing: MLSpacing.s8) {
                    if appearance == .selected || appearance == .lockedSelected {
                        Image(systemName: "checkmark").accessibilityHidden(true)
                    }
                    Text(title)
                }
                .opacity(appearance == .saving ? 0 : 1)
                if appearance == .saving {
                    ProgressView().tint(MLColor.onHero)
                }
            }
            .font(MLType.staffPrimary)
            .foregroundStyle(isFilled(appearance) ? MLColor.onHero : MLColor.ink)
            .frame(maxWidth: .infinity, minHeight: MLSize.staffButton)
            .background { background(appearance) }
            .contentShape(Capsule())
        }
        .buttonStyle(ReadableWhenDisabledButtonStyle())
        .disabled(!state.acceptsTaps)
        .accessibilityLabel(title)
        .accessibilityValue(state.spokenValue(of: option))
        .accessibilityAddTraits(appearance == .selected || appearance == .lockedSelected ? .isSelected : [])
    }

    private func isFilled(_ appearance: MealAnswerAppearance) -> Bool {
        appearance == .primary || appearance == .selected || appearance == .saving
    }

    @ViewBuilder
    private func background(_ appearance: MealAnswerAppearance) -> some View {
        switch appearance {
        case .primary, .selected, .saving:
            Capsule().fill(MLColor.ink)
        case .outline:
            Capsule().stroke(MLColor.ink, lineWidth: 1.5)
        case .locked, .lockedSelected:
            Capsule().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        }
    }
}

/// The row on the black card while a meal is unanswered (04): lime I'm in, outlined Skip, and Entry QR.
/// Entry QR takes taps in every state: the QR is never locked.
struct HeroAnswerRow: View {
    let state: MealAnswerState
    var attendingTitle: String = "I'm in"
    var skippingTitle: String = "Skip"
    var entryTitle: String = "Entry QR"
    let onAnswer: (MealIntention) -> Void
    let onShowEntry: () -> Void

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            answerButton(.attending, title: attendingTitle)
            answerButton(.skipping, title: skippingTitle)
            HeroSurfaceButton(title: entryTitle, action: onShowEntry)
        }
    }

    private func answerButton(_ option: MealIntention, title: String) -> some View {
        let isLocked = state.appearance(of: option) == .locked || state.appearance(of: option) == .lockedSelected
        let isLime = option == .attending && !isLocked
        return Button {
            onAnswer(option)
        } label: {
            Text(title)
                .font(MLType.staffPrimary)
                .foregroundStyle(isLime ? MLColor.onLime : MLColor.onHero)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, minHeight: MLSize.button)
                .background {
                    if isLime {
                        Capsule().fill(MLColor.lime)
                    } else if isLocked {
                        Capsule().stroke(MLColor.onHeroSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    } else {
                        Capsule().stroke(MLColor.onHeroSecondary, lineWidth: 1.5)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(ReadableWhenDisabledButtonStyle())
        .disabled(!state.acceptsTaps)
        .accessibilityLabel(title)
        .accessibilityValue(state.spokenValue(of: option))
    }
}
