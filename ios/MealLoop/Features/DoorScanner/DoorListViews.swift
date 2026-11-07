import SwiftUI

/// The shared frame of a pushed Door Scanner page: backdrop, Back, title, secondary line.
struct DoorPage<Content: View>: View {
    let title: String
    let subtitle: String
    let onBack: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    VStack(alignment: .leading, spacing: MLSpacing.s8) {
                        BackButton(action: onBack)
                            .padding(.leading, -MLSpacing.s4)
                        ScreenTitleBlock(title: title, subtitle: subtitle)
                    }
                    content
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, DoorLayout.scrollBottomInset)
            }
        }
    }
}

/// Report a problem (D11). One tap sends. While offline it says nothing was sent.
struct DoorReportProblemView: View {
    let log: DoorProblemLog
    let onBack: () -> Void
    /// Runs after the toast has shown.
    let onSent: () -> Void

    @State private var toast: String?
    @State private var didFail = false

    var body: some View {
        DoorPage(title: DoorScannerCopy.reportProblem, subtitle: DoorScannerCopy.pickOne, onBack: onBack) {
            ForEach(DoorProblemKind.allCases) { kind in
                StaffReportRow(symbol: kind.symbol, title: kind.title, detail: kind.detail) {
                    Task { await send(kind) }
                }
            }
            if didFail {
                FieldErrorText(text: DoorScannerCopy.couldNotSend)
            }
            Text(DoorScannerCopy.sentOnTap)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .frame(maxWidth: .infinity)
        }
        .disabled(log.isSending || toast != nil)
        .mlToast(message: $toast, bottomInset: DoorLayout.tabBarClearance)
    }

    private func send(_ kind: DoorProblemKind) async {
        didFail = false
        guard await log.report(kind) else {
            didFail = true
            return
        }
        toast = DoorScannerCopy.savedToast
        try? await Task.sleep(for: .seconds(2))
        onSent()
    }
}

/// Open problems (D16). Status is the pill the frame draws. Nothing can mark a problem Seen or Fixed yet, so each stays Waiting.
struct DoorOpenProblemsView: View {
    let log: DoorProblemLog
    let session: StaffSession
    let subtitle: String
    let onBack: () -> Void
    let onReport: () -> Void

    var body: some View {
        DoorPage(title: DoorScannerCopy.openProblems, subtitle: subtitle, onBack: onBack) {
            if log.problems.isEmpty {
                StateBlock(symbol: "checkmark", title: DoorScannerCopy.noOpenProblems, message: DoorScannerCopy.noOpenProblemsDetail)
                    .padding(.vertical, MLSpacing.s32)
            } else {
                VStack(spacing: 0) {
                    Rectangle().fill(MLColor.border).frame(height: 1)
                    ForEach(log.problems) { problem in
                        row(problem)
                    }
                    Text(DoorScannerCopy.savedOnPhone)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                        .padding(.top, MLSpacing.s16)
                }
            }
        }
        .staffPinnedFooter(bottomInset: DoorLayout.footerAboveTabBar) {
            InkActionButton(title: DoorScannerCopy.reportProblem, action: onReport)
        }
    }

    private func row(_ problem: DoorProblem) -> some View {
        HStack(spacing: MLSpacing.s12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(problem.kind.title)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                HStack(spacing: MLSpacing.s4) {
                    Text(DoorScannerCopy.savedLine).font(MLType.body)
                    Text(MLFormat.time(problem.sentAt, in: session.mess.timeZone)).font(MLType.monoSecondary)
                }
                .foregroundStyle(MLColor.inkSecondary)
            }
            Spacer(minLength: MLSpacing.s8)
            StaffStatusPill(text: DoorScannerCopy.waiting, style: .dashed)
        }
        .padding(.vertical, MLSpacing.s12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Entered without voting (D15). Not a vote and never mixed with answers.
struct DoorWithoutVotingView: View {
    @State private var model: DoorWithoutVotingViewModel
    let meal: Meal
    let mess: Mess
    let onBack: () -> Void

    init(model: DoorWithoutVotingViewModel, meal: Meal, mess: Mess, onBack: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.meal = meal
        self.mess = mess
        self.onBack = onBack
    }

    private var count: Int { model.state.value?.count ?? 0 }

    var body: some View {
        DoorPage(title: DoorScannerCopy.enteredWithoutVoting,
                 subtitle: DoorScannerCopy.withoutVotingSubtitle(meal: MLFormat.mealSlot(meal.slot), mess: mess.name, count: count),
                 onBack: onBack) {
            switch model.state {
            case .empty:
                StateBlock(symbol: "person.2", title: DoorScannerCopy.nobodyWithoutVoting, message: DoorScannerCopy.nobodyWithoutVotingDetail)
                    .padding(.vertical, MLSpacing.s32)
            default:
                AsyncContentView(state: model.state, timeZone: mess.timeZone, retry: { await model.load() }) { list in
                    VStack(spacing: 0) {
                        Rectangle().fill(MLColor.border).frame(height: 1)
                        ForEach(list, id: \.student.id) { entry in
                            row(entry)
                        }
                        Text(DoorScannerCopy.addedAutomatically)
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                            .padding(.top, MLSpacing.s16)
                    }
                }
            }
        }
        .task { await model.load() }
    }

    private func row(_ entry: EnteredWithoutVoting) -> some View {
        HStack {
            Text(DoorScannerCopy.studentLine(entry.student, name: model.names[entry.student.id]))
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.ink)
            Spacer(minLength: MLSpacing.s8)
            Text(MLFormat.time(entry.enteredAt, in: mess.timeZone))
                .font(MLType.monoSecondary)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .frame(minHeight: MLSize.staffButton)
        .overlay(alignment: .bottom) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
