import SwiftUI

/// Owns one entry attempt. Each opening of the sheet builds a new host, so a new attempt starts empty, and the flow
/// lives here rather than in the parent because a value read only inside a sheet's closure can be stale on first show.
struct DoorEntrySheetHost: View {
    @State private var flow: DoorEntryFlow
    let meal: Meal
    let session: StaffSession
    let onClose: () -> Void
    let onReport: () -> Void

    init(meal: Meal, session: StaffSession, repositories: Repositories, onClose: @escaping () -> Void, onReport: @escaping () -> Void) {
        _flow = State(initialValue: DoorEntryFlow(meal: meal.id, mess: session.mess.id, repositories: repositories))
        self.meal = meal
        self.session = session
        self.onClose = onClose
        self.onReport = onReport
    }

    var body: some View {
        DoorEntrySheet(flow: flow, session: session, meal: meal, onClose: onClose, onReport: onReport)
    }
}

/// Type the last 4 digits (D06). A lookup shows who matched and records nothing; only Record entry records.
struct DoorEntrySheet: View {
    @Bindable var flow: DoorEntryFlow
    let session: StaffSession
    let meal: Meal?
    let onClose: () -> Void
    let onReport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: DoorScannerCopy.typeLastFour, onClose: onClose)
            DigitBoxes(entry: flow.entry, accessibilityTitle: DoorScannerCopy.lastFourField)
            statusArea
            KeyPad(isEnabled: flow.lookup != .checking && !flow.isRecording, keyHeight: 54, keyFill: MLColor.fillQuiet) { digit in
                Task { await flow.append(digit) }
            } onDelete: {
                flow.deleteLast()
            }
        }
        .fullScreenCover(item: $flow.outcome) { outcome in
            DoorResultView(outcome: outcome, session: session, meal: meal, names: flow.names,
                           onDone: onClose,
                           onRetry: { Task { await flow.retry() } },
                           onTypeDigits: {
                               flow.clear()
                               flow.outcome = nil
                           },
                           onReport: onReport)
        }
    }

    @ViewBuilder
    private var statusArea: some View {
        switch flow.lookup {
        case .typing:
            DoorStatusCard(title: nil, detail: DoorScannerCopy.matchesShowHere)
            InkActionButton(title: DoorScannerCopy.recordEntry) {}
                .disabled(true)
        case .checking:
            LoadingStateView().frame(maxHeight: MLSize.staffButton)
        case .match(let student):
            DoorMatchCard(student: student, name: flow.names[student.id], detail: session.mess.name)
            InkActionButton(title: DoorScannerCopy.recordEntry, isLoading: flow.isRecording) {
                Task { await flow.recordMatch() }
            }
        case .noMatch:
            DoorStatusCard(title: DoorScannerCopy.noStudent(flow.entry.text, mess: session.mess.name),
                           detail: DoorScannerCopy.checkCard)
            InkActionButton(title: DoorScannerCopy.tryAgain) { flow.clear() }
        case .offline:
            DoorStatusCard(title: DoorScannerCopy.cantCheck(flow.entry.text), detail: DoorScannerCopy.cantCheckDetail)
            InkActionButton(title: DoorScannerCopy.recordEntry) {}
                .disabled(true)
        }
    }
}

/// The quiet card between the boxes and the keypad.
struct DoorStatusCard: View {
    let title: String?
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            if let title {
                Text(title)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
            }
            Text(detail)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .padding(MLSpacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.fillQuiet))
        .accessibilityElement(children: .combine)
    }
}

/// Who matched (D06 One match): initials, name and masked ID. With no name known it shows the masked ID alone.
struct DoorMatchCard: View {
    let student: StudentRef
    let name: String?
    let detail: String

    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            if let name {
                Text(String(name.prefix(2)).uppercased())
                    .font(MLType.bodyEmphasis)
                    .foregroundStyle(MLColor.ink)
                    .frame(width: MLSize.hit, height: MLSize.hit)
                    .background(Circle().fill(MLColor.surface))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(DoorScannerCopy.studentLine(student, name: name))
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                Text(detail)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(MLSpacing.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.fillQuiet))
        .accessibilityElement(children: .combine)
    }
}

/// Every result of a scan (D07 to D10, D12 during a scan). Only `.recorded` can show the lime screen.
struct DoorResultView: View {
    let outcome: DoorScanOutcome
    let session: StaffSession
    let meal: Meal?
    var names: [StudentID: String] = [:]
    let onDone: () -> Void
    let onRetry: () -> Void
    let onTypeDigits: () -> Void
    let onReport: () -> Void

    private var timeZone: TimeZone { session.mess.timeZone }
    private var mealName: String { meal.map { MLFormat.mealSlot($0.slot) } ?? "" }

    private func line(_ student: StudentRef) -> String { DoorScannerCopy.studentLine(student, name: names[student.id]) }

    var body: some View {
        switch outcome {
        case .recorded(let student, let count, let withoutVoting):
            LimeResultScreen(
                context: DoorScannerCopy.context(mealName),
                title: DoorScannerCopy.entryRecorded,
                subject: line(student),
                lines: withoutVoting ? [.init(text: DoorScannerCopy.addedWithoutVoting(names[student.id] ?? student.maskedID))] : [],
                count: .init(label: DoorScannerCopy.recordedSoFar, value: count, change: DoorScannerCopy.plusOne),
                autoReturn: .init(seconds: 1) { DoorScannerCopy.backHome(in: $0) },
                actionTitle: DoorScannerCopy.scanNext,
                onDone: onDone
            )
        case .alreadyScanned(let student, let firstAt, let count):
            StaffOutcomeScreen(
                onBack: onDone, symbol: "person.fill.checkmark", title: DoorScannerCopy.alreadyScanned,
                message: DoorScannerCopy.wasRecorded(line(student), meal: mealName),
                facts: [FactRow(label: DoorScannerCopy.firstScanned, value: MLFormat.time(firstAt, in: timeZone)),
                        FactRow(label: DoorScannerCopy.countStays, value: String(count))],
                note: DoorScannerCopy.nothingAdded,
                primary: .init(title: DoorScannerCopy.scanNext, handler: onDone)
            )
        case .notRecognised:
            StaffOutcomeScreen(
                onBack: onDone, badge: .outlined, symbol: "qrcode", title: DoorScannerCopy.qrNotRecognised,
                message: DoorScannerCopy.notEntryCode, reasonsTitle: DoorScannerCopy.itMayBe,
                reasons: [.init(title: DoorScannerCopy.anotherMealQR, detail: DoorScannerCopy.anotherMealDetail),
                          .init(title: DoorScannerCopy.oldScreenshot, detail: DoorScannerCopy.oldScreenshotDetail)],
                primary: .init(title: DoorScannerCopy.scanAgain, handler: onDone),
                secondary: .init(title: DoorScannerCopy.typeLastFour, handler: onTypeDigits),
                link: .init(title: DoorScannerCopy.reportProblem, handler: onReport)
            )
        case .wrongMeal(let servingNow):
            StaffOutcomeScreen(
                onBack: onDone, badge: .outlined, symbol: "qrcode", title: DoorScannerCopy.wrongMeal,
                message: DoorScannerCopy.wrongMealDetail,
                facts: [FactRow(label: DoorScannerCopy.scanningNow, value: MLFormat.mealSlot(servingNow), isMono: false)],
                note: DoorScannerCopy.askForEntryQR(MLFormat.mealSlot(servingNow)),
                primary: .init(title: DoorScannerCopy.scanAgain, handler: onDone),
                secondary: .init(title: DoorScannerCopy.typeLastFour, handler: onTypeDigits),
                link: .init(title: DoorScannerCopy.reportProblem, handler: onReport)
            )
        case .offline(let lastUpdate):
            StaffOutcomeScreen(
                onBack: onDone, badge: .outlined, symbol: "wifi.slash", title: DoorScannerCopy.cantCheckNow,
                message: DoorScannerCopy.notRecorded, isMessageEmphasized: true,
                facts: [FactRow(label: DoorScannerCopy.lastUpdate, value: lastUpdate.map { MLFormat.time($0, in: timeZone) }),
                        FactRow(label: DoorScannerCopy.entriesWaiting, value: String(DoorEntryFlow.entriesWaiting))],
                primary: .init(title: DoorScannerCopy.tryAgain, handler: onRetry),
                secondary: .init(title: DoorScannerCopy.typeLastFour, handler: onTypeDigits),
                link: .init(title: DoorScannerCopy.reportProblem, handler: onReport),
                footnote: DoorScannerCopy.neverShownRecorded
            )
        case .mealEnded(let closedAt, let finalEntries):
            StaffOutcomeScreen(
                symbol: "clock", title: DoorScannerCopy.hasEnded(mealName),
                message: closedAt.map { DoorScannerCopy.endedWhileScanning(by: session.supervisorName, at: MLFormat.time($0, in: timeZone)) }
                    ?? DoorScannerCopy.endedWhileScanningNoTime,
                facts: [FactRow(label: DoorScannerCopy.finalEntries, value: finalEntries.value.map { String($0) }),
                        FactRow(label: DoorScannerCopy.thisScan, value: DoorScannerCopy.notRecordedValue, isMono: false)],
                primary: .init(title: DoorScannerCopy.backToHome, handler: onDone)
            )
        }
    }
}
