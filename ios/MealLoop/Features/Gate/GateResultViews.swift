import SwiftUI

/// A full-screen gate result (GA-6): lime when recorded, black when the gate must act, light when refused.
struct GateResultLayout: View {
    enum Surface {
        case lime
        case ink
        case light
    }

    enum Mark {
        /// Black disc with a lime tick (recorded).
        case recorded
        /// Lime disc with an ink tick (emergency, sent).
        case limeDisc
        /// White disc with a symbol, on black.
        case whiteDisc(String)
        /// Ink ring with a symbol, on the light surface.
        case ring(String)
    }

    let surface: Surface
    let mark: Mark
    let title: String
    var subject: String?
    var lines: [String] = []
    var secondaryTitle: String?
    var onSecondary: (() -> Void)?
    var showsCallWarden = false
    let primaryTitle: String
    let onPrimary: () -> Void

    var body: some View {
        ZStack {
            background
            VStack(spacing: MLSpacing.s16) {
                markView
                    .padding(.top, MLSpacing.s32 * 2)
                Text(title)
                    .font(.system(size: 40, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(foreground)
                    .accessibilityAddTraits(.isHeader)
                if let subject {
                    Text(subject).font(MLType.title2).foregroundStyle(foreground)
                }
                VStack(spacing: MLSpacing.s12) {
                    ForEach(lines, id: \.self) { line in
                        Text(line).font(MLType.staffBody).foregroundStyle(foreground)
                    }
                }
                .multilineTextAlignment(.center)
                Spacer(minLength: 0)
                if let secondaryTitle, let onSecondary {
                    OutlineActionButton(title: secondaryTitle, action: onSecondary)
                }
                if showsCallWarden {
                    OutingCallButton(title: GateCopy.callWarden, style: .ink)
                } else {
                    primaryButton
                }
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.bottom, MLSpacing.s16)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var background: some View {
        switch surface {
        case .lime: MLColor.lime.ignoresSafeArea()
        case .ink: MLColor.heroBackground.ignoresSafeArea()
        case .light: OrbitBackground()
        }
    }

    private var foreground: Color { surface == .ink ? MLColor.onHero : MLColor.ink }

    @ViewBuilder
    private var primaryButton: some View {
        if surface == .ink {
            LimeActionButton(title: primaryTitle, action: onPrimary)
        } else {
            InkActionButton(title: primaryTitle, action: onPrimary)
        }
    }

    @ViewBuilder
    private var markView: some View {
        let size: CGFloat = 148
        switch mark {
        case .recorded:
            Image(systemName: "checkmark").font(.system(size: 48, weight: .semibold)).foregroundStyle(MLColor.lime)
                .frame(width: size, height: size).background(Circle().fill(MLColor.ink))
                .accessibilityHidden(true)
        case .limeDisc:
            Image(systemName: "checkmark").font(.system(size: 48, weight: .light)).foregroundStyle(MLColor.ink)
                .frame(width: size, height: size).background(Circle().fill(MLColor.lime))
                .accessibilityHidden(true)
        case .whiteDisc(let symbol):
            Image(systemName: symbol).font(.system(size: 44, weight: .light)).foregroundStyle(MLColor.ink)
                .frame(width: size, height: size).background(Circle().fill(MLColor.surface))
                .accessibilityHidden(true)
        case .ring(let symbol):
            Image(systemName: symbol).font(.system(size: 44, weight: .regular)).foregroundStyle(MLColor.ink)
                .frame(width: size, height: size)
                .background(Circle().fill(MLColor.surface))
                .overlay(Circle().stroke(MLColor.ink, lineWidth: 6))
                .accessibilityHidden(true)
        }
    }
}

/// Maps a gate outcome to its GA-6 frame.
struct GateOutcomeScreen: View {
    let model: GateModel
    let outcome: GateOutcome
    let onScanNext: () -> Void
    let onRetry: (GateAttempt) -> Void

    var body: some View {
        switch outcome {
        case .exitRecorded(let record):
            let outing = record.outing
            GateResultLayout(surface: .lime, mark: .recorded, title: GateCopy.exitRecorded,
                             subject: outing.student.displayName,
                             lines: [GateCopy.idChecked, GateCopy.outingPass(window(outing)),
                                     GateCopy.backBy(outing.returnBy.map(OutingFormat.dayHour) ?? "—"),
                                     GateCopy.studentsOut(record.outNowCount)],
                             primaryTitle: GateCopy.scanNext, onPrimary: onScanNext)
        case .returnRecorded(let record):
            returnResult(record)
        case .refused(let check):
            refused(check)
        case .offline(let attempt):
            GateResultLayout(surface: .light, mark: .ring("wifi.slash"), title: GateCopy.cantVerify,
                             lines: [GateCopy.noConnection, GateCopy.askTheWarden],
                             secondaryTitle: GateCopy.tryAgain, onSecondary: { onRetry(attempt) },
                             showsCallWarden: true, primaryTitle: GateCopy.callWarden, onPrimary: {})
        }
    }

    @ViewBuilder
    private func returnResult(_ record: GateRecord) -> some View {
        let outing = record.outing
        let back = outing.returnAt.map(OutingFormat.clock) ?? "—"
        if let returnBy = outing.returnBy, let returnAt = outing.returnAt, returnAt > returnBy {
            GateResultLayout(surface: .ink, mark: .whiteDisc("clock"), title: GateCopy.backLate,
                             subject: outing.student.displayName,
                             lines: [GateCopy.backAtLate(back, OutingFormat.span(from: returnBy, to: returnAt)),
                                     GateCopy.sentToWarden(outing.student.block), GateCopy.outingClosed],
                             primaryTitle: GateCopy.scanNext, onPrimary: onScanNext)
        } else {
            GateResultLayout(surface: .lime, mark: .recorded, title: GateCopy.welcomeBack,
                             subject: outing.student.displayName,
                             lines: [GateCopy.backAt(back), GateCopy.outingClosed, GateCopy.studentsOut(record.outNowCount)],
                             primaryTitle: GateCopy.scanNext, onPrimary: onScanNext)
        }
    }

    @ViewBuilder
    private func refused(_ check: GateCheck) -> some View {
        switch check {
        case .alreadyUsed(let outing):
            GateResultLayout(surface: .ink, mark: .whiteDisc("xmark"), title: GateCopy.alreadyOut,
                             subject: outing.student.displayName,
                             lines: [GateCopy.usedAt(outing.exitAt.map(OutingFormat.clock) ?? "—"), GateCopy.dontLetOutAgain],
                             primaryTitle: GateCopy.scanNext, onPrimary: onScanNext)
        case .withdrawn(let outing):
            GateResultLayout(surface: .light, mark: .ring("hand.raised"), title: GateCopy.passWithdrawn,
                             subject: outing.student.displayName,
                             lines: [GateCopy.withdrewAt(outing.withdrawnBy, outing.withdrawnAt.map(OutingFormat.clock) ?? "—"),
                                     GateCopy.sendToWarden],
                             primaryTitle: GateCopy.scanNext, onPrimary: onScanNext)
        case .tooEarly(let outing):
            let from = outing.leaveAt.map(OutingFormat.hour) ?? "—"
            GateResultLayout(surface: .light, mark: .ring("clock"), title: GateCopy.tooEarly,
                             subject: outing.student.displayName,
                             lines: [GateCopy.leaveFrom(from, now: model.now.map(OutingFormat.clock) ?? "—"),
                                     GateCopy.comeBackAt(from)],
                             primaryTitle: GateCopy.scanNext, onPrimary: onScanNext)
        case .tooLate(let outing):
            GateResultLayout(surface: .light, mark: .ring("clock"), title: GateCopy.tooLate,
                             subject: outing.student.displayName,
                             lines: [GateCopy.windowClosed(outing.returnBy.map(OutingFormat.hour) ?? "—"),
                                     GateCopy.needsNewPass],
                             primaryTitle: GateCopy.scanNext, onPrimary: onScanNext)
        case .notValid, .exitReady, .returnReady:
            GateResultLayout(surface: .light, mark: .ring("xmark"), title: GateCopy.notValid,
                             lines: [GateCopy.notMealLoopPass, GateCopy.askToOpenPass],
                             primaryTitle: GateCopy.scanNext, onPrimary: onScanNext)
        }
    }

    private func window(_ outing: OutingCase) -> String {
        guard let leave = outing.leaveAt, let back = outing.returnBy else { return "—" }
        return OutingFormat.window(leave, back)
    }
}

// MARK: - Out now (GA-7) and Overdue returns (GA-8)

struct GateOutListScreen: View {
    let model: GateModel
    let isOverdue: Bool
    let onBack: () -> Void
    let onOpen: (OutingRequestID) -> Void

    var body: some View {
        GatePage(title: isOverdue ? GateCopy.overdueReturns : GateCopy.outNow, onBack: onBack) {
            Text(isOverdue ? GateCopy.overdueSubtitle(rows.count)
                           : GateCopy.outThrough(rows.count, model.overview?.post.name ?? "—"))
                .font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(rows) { outing in
                        Button { onOpen(outing.id) } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(outing.student.displayName).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                                Text(GateCopy.outRow(outing.exitAt.map(OutingFormat.clock) ?? "—",
                                                     outing.returnBy.map(OutingFormat.hour) ?? "—"))
                                    .font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                            }
                            .padding(.horizontal, MLSpacing.s16)
                            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, MLSpacing.s8)
                .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
                Text(GateCopy.gateRecordsNote)
                    .font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, MLSpacing.s16)
            }
        }
    }

    private var rows: [OutingCase] { isOverdue ? model.overdue : model.outNow }
}

// MARK: - Report a problem (GA-9)

struct GateReportScreen: View {
    let model: GateModel
    let onBack: () -> Void
    let onSent: (GateProblemReport) -> Void

    var body: some View {
        GatePage(title: GateCopy.reportProblem, onBack: onBack) {
            Text(GateCopy.pickOne).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            ForEach(GateProblem.allCases, id: \.self) { problem in
                Button {
                    Task { if let report = await model.report(problem) { onSent(report) } }
                } label: {
                    HStack(spacing: MLSpacing.s16) {
                        Image(systemName: symbol(problem))
                            .font(.system(size: 20))
                            .foregroundStyle(MLColor.ink)
                            .frame(width: 64, height: 64)
                            .background(Circle().fill(MLColor.fillQuiet))
                        VStack(alignment: .leading, spacing: MLSpacing.s4) {
                            Text(GateCopy.problemTitle(problem)).font(MLType.title2).foregroundStyle(MLColor.ink)
                            Text(GateCopy.problemDetail(problem)).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(MLSpacing.s20)
                    .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
            }
            Spacer(minLength: 0)
        }
    }

    private func symbol(_ problem: GateProblem) -> String {
        switch problem {
        case .scannerNotWorking: return "camera"
        case .crowdAtTheGate: return "person.3"
        case .somethingElse: return "text.bubble"
        }
    }
}

struct GateReportSentScreen: View {
    let report: GateProblemReport
    let onDone: () -> Void

    var body: some View {
        GateResultLayout(surface: .light, mark: .recorded, title: GateCopy.sentToDutyWarden,
                         subject: GateCopy.problemTitle(report.problem),
                         lines: [GateCopy.sentAt(OutingFormat.clock(report.sentAt), problem: report.problem)],
                         primaryTitle: GateCopy.done, onPrimary: onDone)
    }
}
