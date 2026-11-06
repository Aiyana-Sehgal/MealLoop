import SwiftUI

struct SupervisorShortageScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let shortageID: ShortageID
    let staff: StaffSession
    let onBack: () -> Void
    let onResolved: () -> Void

    var body: some View {
        SupervisorShortageView(model: SupervisorShortageViewModel(shortageID: shortageID, session: staff,
                                                                  repositories: environment.repositories),
                               onBack: onBack, onResolved: onResolved)
    }
}

/// Shortage details (S12) and "Mark shortage as resolved?" (S13). One action: Mark resolved.
struct SupervisorShortageView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: SupervisorShortageViewModel
    @State private var isConfirming = false
    let onBack: () -> Void
    let onResolved: () -> Void

    init(model: SupervisorShortageViewModel, onBack: @escaping () -> Void, onResolved: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onBack = onBack
        self.onResolved = onResolved
    }

    private var timeZone: TimeZone { model.session.mess.timeZone }

    var body: some View {
        SupervisorPage(bottomInset: 120) {
            SupervisorPageHeader(title: SupervisorCopy.shortageTitle, onBack: onBack)
            AsyncContentView(state: model.state, timeZone: timeZone, retry: { await model.load() }) { shortage in
                details(shortage)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let shortage = model.state.value, shortage.status == .active {
                VStack(spacing: MLSpacing.s8) {
                    if let error = model.actionError {
                        FieldErrorText(text: error)
                    }
                    InkActionButton(title: SupervisorCopy.markResolved) { isConfirming = true }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, MLSpacing.s8)
            }
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
        .mlConfirmDialog(isPresented: $isConfirming,
                         content: SupervisorCopy.resolveDialog(item: model.state.value?.dishName ?? ""),
                         isWorking: model.isResolving) {
            Task {
                let resolved = await model.markResolved()
                isConfirming = false
                if resolved {
                    environment.dataDidChange()
                    onResolved()
                }
            }
        }
    }

    private func details(_ shortage: Shortage) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(SupervisorCopy.item)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .padding(.top, MLSpacing.s16)
            Text(shortage.dishName)
                .font(MLType.largeTitle)
                .foregroundStyle(MLColor.ink)
            Text(SupervisorFormat.sentenceCase(MLFormat.shortageLevel(shortage.level)))
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.ink)
                .padding(.top, MLSpacing.s4)
                .padding(.bottom, MLSpacing.s24)
            Rectangle().fill(MLColor.border).frame(height: 1)
            SupervisorFactRow(label: SupervisorCopy.posted) {
                HStack(spacing: MLSpacing.s4) {
                    Text(MLFormat.time(shortage.reportedAt, in: timeZone)).font(MLType.monoBody)
                    Text("· \(SupervisorCopy.byReporter(SupervisorFormat.who(shortage.reportedBy)))").font(MLType.staffBody)
                }
                .foregroundStyle(MLColor.ink)
            }
            SupervisorFactRow(label: SupervisorCopy.status) {
                switch shortage.status {
                case .active:
                    SupervisorStatus(text: SupervisorCopy.active, dot: .ink)
                case .resolved(let at):
                    SupervisorStatus(text: SupervisorCopy.resolved, dot: .lime, time: MLFormat.time(at, in: timeZone))
                }
            }
        }
    }
}
