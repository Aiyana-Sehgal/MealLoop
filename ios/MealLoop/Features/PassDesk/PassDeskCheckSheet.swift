import SwiftUI

/// Check this pass (P04): compare the code and the colour on the student's phone, then record or not.
/// The states: fresh, code changed under the sheet, window expired.
struct PassDeskCheckSheet: View {
    let flow: PassDeskCheckFlow
    let compare: PassDeskCompare
    let session: StaffSession
    let meal: Meal?

    var body: some View {
        VStack(spacing: MLSpacing.s16) {
            SheetHeader(title: PassDeskCopy.checkThisPass) { flow.reset() }
            PassDeskHolderRow(holder: compare.holder,
                              detail: PassDeskCopy.specialLine(meal: meal.map { MLFormat.mealSlot($0.slot) } ?? "",
                                                               mess: session.mess.name))
            if compare.isExpired {
                expiredCard
                note(PassDeskCopy.codeExpiredNote)
                InkActionButton(title: PassDeskCopy.checkAgain) { Task { await flow.checkAgain() } }
                OutlineActionButton(title: PassDeskCopy.backToHome) { flow.reset() }
            } else {
                PassDeskCodeCard(compare: compare)
                note(PassDeskCopy.matchPrompt)
                if let error = flow.actionError {
                    FieldErrorText(text: error)
                }
                InkActionButton(title: PassDeskCopy.matchesRecord, isLoading: flow.isRecording) {
                    Task { await flow.matches() }
                }
                OutlineActionButton(title: PassDeskCopy.doesntMatch) { flow.doesNotMatch() }
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if !Task.isCancelled { await flow.tick() }
            }
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(MLType.body)
            .foregroundStyle(MLColor.inkSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var expiredCard: some View {
        VStack(spacing: MLSpacing.s4) {
            Text(PassDeskCopy.codeExpired)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
            Text(PassDeskCopy.codeExpiredDetail)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .padding(MLSpacing.s32)
        .frame(maxWidth: .infinity)
        .overlay(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous)
            .stroke(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])))
        .accessibilityElement(children: .combine)
    }
}

/// The initials circle, name and one line (P04, P09, P17).
struct PassDeskHolderRow: View {
    let holder: SpecialPassHolder
    let detail: String

    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            Text(String(holder.name.prefix(2)).uppercased())
                .font(MLType.bodyEmphasis)
                .foregroundStyle(MLColor.ink)
                .frame(width: MLSize.hit, height: MLSize.hit)
                .background(Circle().fill(MLColor.fillQuiet))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(PassDeskCopy.holderLine(holder))
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                Text(detail)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// What the student's phone should show: the code, the colour and the countdown.
struct PassDeskCodeCard: View {
    let compare: PassDeskCompare

    var body: some View {
        VStack(spacing: MLSpacing.s8) {
            if compare.justChanged {
                StaffStatusPill(text: PassDeskCopy.justChanged, style: .outline)
            }
            Text(PassDeskCopy.screenShouldShow)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            Text(compare.live.code)
                .font(MLType.heroNumber)
                .foregroundStyle(MLColor.ink)
            PassDeskColourPill(name: compare.live.colourName)
            HStack(spacing: MLSpacing.s4) {
                Text(PassDeskCopy.changesIn).font(MLType.secondary)
                Text(PassDeskCopy.seconds(max(0, compare.secondsLeft))).font(MLType.monoSecondary)
            }
            .foregroundStyle(MLColor.inkSecondary)
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.fillQuiet))
        .overlay {
            if compare.justChanged {
                RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).stroke(MLColor.ink, lineWidth: 1.5)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// The colour to compare. It is a swatch with its name, not a button and not a status.
struct PassDeskColourPill: View {
    /// Measured from export P04_check_this_pass_code_changed. The tokens have no blue, and only this pill needs one.
    private static let blue = Color(hex: 0x2F61E6)

    let name: String

    private var fill: Color {
        switch name {
        case "Lime": return MLColor.lime
        case "Blue": return Self.blue
        default: return MLColor.surface
        }
    }

    var body: some View {
        Text(name)
            .font(MLType.staffPrimary)
            .foregroundStyle(name == "Blue" ? MLColor.onHero : MLColor.ink)
            .frame(maxWidth: 220, minHeight: MLSize.buttonCompact)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(fill).frame(maxWidth: 220))
            .overlay(Capsule().stroke(name == "Blue" ? .clear : MLColor.limeOutline, lineWidth: 1).frame(maxWidth: 220))
    }
}
