import SwiftUI

/// Every end of a check (P05 to P08, the wrong meal, can't check, meal ended).
/// Only `.verified`, which only a saved entry makes, can show the lime screen.
struct PassDeskOutcomeView: View {
    let outcome: PassDeskOutcome
    let session: StaffSession
    let meal: Meal?
    let onDone: () -> Void
    let onRetry: () -> Void
    let onRequest: () -> Void
    let onReport: () -> Void

    private var timeZone: TimeZone { session.mess.timeZone }
    private var mealName: String { meal.map { MLFormat.mealSlot($0.slot) } ?? "" }

    var body: some View {
        switch outcome {
        case .verified(let holder, let count, let passes):
            LimeResultScreen(
                context: PassDeskCopy.context(mealName),
                title: PassDeskCopy.passVerified,
                subject: PassDeskCopy.holderLine(holder),
                lines: [.init(text: PassDeskCopy.validPass(mealName))],
                count: .init(label: PassDeskCopy.specialMealsRecorded, value: count, suffix: PassDeskCopy.ofPasses(passes),
                             change: PassDeskCopy.plusOne),
                autoReturn: .init(seconds: 1) { PassDeskCopy.backToCheck(in: $0) },
                actionTitle: PassDeskCopy.checkNext,
                onDone: onDone
            )
        case .noPass(let holder):
            OutcomeScreen(
                onBack: onDone, badge: .outlined, symbol: "ticket", title: PassDeskCopy.noSpecialPass,
                message: PassDeskCopy.noValidPass(PassDeskCopy.holderLine(holder), meal: mealName),
                facts: [FactRow(label: PassDeskCopy.pass, value: PassDeskCopy.noneFor(mealName), isMono: false),
                        FactRow(label: PassDeskCopy.recorded, value: PassDeskCopy.nothing, isMono: false)],
                note: PassDeskCopy.regularMeal,
                primary: .init(title: PassDeskCopy.checkNextStudent, handler: onDone),
                secondary: .init(title: PassDeskCopy.requestNewPass, handler: onRequest)
            )
        case .wrongMeal(_, let slot):
            OutcomeScreen(
                onBack: onDone, badge: .outlined, symbol: "ticket", title: PassDeskCopy.wrongMeal,
                message: PassDeskCopy.passIsFor(MLFormat.mealSlot(slot)),
                facts: [FactRow(label: PassDeskCopy.pass, value: PassDeskCopy.specialName(MLFormat.mealSlot(slot)), isMono: false),
                        FactRow(label: PassDeskCopy.recorded, value: PassDeskCopy.nothing, isMono: false)],
                note: PassDeskCopy.regularMeal,
                primary: .init(title: PassDeskCopy.checkNextStudent, handler: onDone),
                secondary: .init(title: PassDeskCopy.requestNewPass, handler: onRequest)
            )
        case .alreadyRecorded(let holder, let at, let count):
            OutcomeScreen(
                onBack: onDone, symbol: "person.fill.checkmark", title: PassDeskCopy.alreadyRecorded,
                message: PassDeskCopy.tookSpecial(PassDeskCopy.holderLine(holder), time: MLFormat.time(at, in: timeZone)),
                facts: [FactRow(label: PassDeskCopy.firstRecorded, value: MLFormat.time(at, in: timeZone)),
                        FactRow(label: PassDeskCopy.countStays, value: count.map(String.init))],
                note: PassDeskCopy.nothingAdded,
                primary: .init(title: PassDeskCopy.checkNextStudent, handler: onDone)
            )
        case .mismatch(let live):
            OutcomeScreen(
                onBack: onDone, badge: .outlined, symbol: "xmark.rectangle", title: PassDeskCopy.doesntMatchTitle,
                message: PassDeskCopy.codeOrColourDifferent,
                facts: [FactRow(label: PassDeskCopy.shouldShow, value: live.code),
                        FactRow(label: PassDeskCopy.colour, value: live.colourName, isMono: false)],
                note: PassDeskCopy.refreshAndRetry,
                primary: .init(title: PassDeskCopy.checkAgain, handler: onRetry),
                secondary: .init(title: PassDeskCopy.backToHome, handler: onDone)
            )
        case .cantCheck(let lastUpdate):
            OutcomeScreen(
                onBack: onDone, badge: .outlined, symbol: "wifi.slash", title: PassDeskCopy.cantCheck,
                message: PassDeskCopy.notChecked, isMessageEmphasized: true,
                facts: [FactRow(label: PassDeskCopy.lastUpdate, value: lastUpdate.map { MLFormat.time($0, in: timeZone) }),
                        FactRow(label: PassDeskCopy.recorded, value: PassDeskCopy.nothing, isMono: false)],
                primary: .init(title: PassDeskCopy.tryAgain, handler: onRetry),
                secondary: .init(title: PassDeskCopy.backToHome, handler: onDone),
                link: .init(title: PassDeskCopy.reportProblem, handler: onReport),
                footnote: PassDeskCopy.neverShownChecked
            )
        case .mealEnded(let closedAt, let count, let passes):
            OutcomeScreen(
                symbol: "clock", title: PassDeskCopy.specialHasEnded(mealName),
                message: closedAt.map { PassDeskCopy.endedWhileChecking(by: session.supervisorName, at: MLFormat.time($0, in: timeZone)) }
                    ?? PassDeskCopy.endedWhileCheckingNoTime,
                facts: [FactRow(label: PassDeskCopy.pass, value: PassDeskCopy.notRecorded, isMono: false),
                        FactRow(label: PassDeskCopy.specialMealsRecorded, value: PassDeskCopy.recordedOf(count, passes))],
                primary: .init(title: PassDeskCopy.backToHome, handler: onDone)
            )
        }
    }
}
