import SwiftUI

/// "Which food is short?" (K04). A dish is required; how bad and a note are optional.
struct KitchenShortageSheet: View {
    let model: KitchenHomeViewModel
    let onClose: () -> Void
    let onDone: (KitchenReportOutcome) -> Void

    @State private var dish: String?
    @State private var level: ShortageLevel = .gettingLow
    @State private var note = ""
    @State private var isAddingNote = false
    @State private var earlier: Shortage?
    @State private var isConfirming = false

    private var options: [SegmentedChoice<ShortageLevel>.Option] {
        ShortageLevel.allCases.map { .init(value: $0, title: KitchenCopy.level($0)) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: KitchenCopy.whichFood, onClose: onClose)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: MLSpacing.s12), GridItem(.flexible())], spacing: MLSpacing.s12) {
                ForEach(model.dishes) { item in
                    ChoiceChip(title: item.name, isSelected: dish == item.name) { dish = item.name }
                }
            }
            Text(KitchenCopy.howBad)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            SegmentedChoice(options: options, selection: $level)
            if isAddingNote {
                TextField(KitchenCopy.notePlaceholder, text: $note, axis: .vertical)
                    .font(MLType.staffBody)
                    .padding(MLSpacing.s12)
                    .background(RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous).fill(MLColor.surface))
            } else {
                TextLinkButton(title: KitchenCopy.addNote) { isAddingNote = true }
            }
            InkActionButton(title: KitchenCopy.sendTo(model.session.supervisorName), isLoading: model.isSending) {
                send(confirmed: false)
            }
            .disabled(dish == nil && !model.isSending)
        }
        .task { await model.loadDishes() }
        .mlConfirmDialog(isPresented: $isConfirming, content: dialog, isWorking: model.isSending) {
            send(confirmed: true)
        }
    }

    private var dialog: ConfirmDialogContent {
        let time = earlier.map { MLFormat.time($0.reportedAt, in: model.session.mess.timeZone) } ?? ""
        let title = earlier.map { KitchenCopy.shortageTitle(dish: $0.dishName, level: MLFormat.shortageLevel($0.level)) } ?? ""
        return ConfirmDialogContent(title: KitchenCopy.alreadyReported(time), detail: KitchenCopy.reportAgainDetail(title),
                                    cancelTitle: KitchenCopy.cancel, actionTitle: KitchenCopy.reportAgain)
    }

    private func send(confirmed: Bool) {
        Task {
            let outcome = await model.reportShortage(dish: dish, level: level, note: note, confirmed: confirmed)
            isConfirming = false
            if case .alreadyReported(let shortage) = outcome {
                earlier = shortage
                isConfirming = true
            } else {
                onDone(outcome)
            }
        }
    }
}

/// Every report of this meal (K03c), behind "See all".
struct KitchenShortagesView: View {
    let model: KitchenHomeViewModel
    let onBack: () -> Void

    var body: some View {
        KitchenPage(title: KitchenCopy.shortageReportsTitle, subtitle: model.session.mess.name, onBack: onBack) {
            ForEach(model.state.value?.allShortages ?? []) { shortage in
                KitchenShortageStatusRow(shortage: shortage, timeZone: model.session.mess.timeZone)
            }
        }
    }
}

/// The meal closed while a report was being written (K04g). It says plainly that nothing was sent.
struct KitchenMealEndedView: View {
    let mealName: String
    let endedAt: Date?
    let timeZone: TimeZone
    let onBack: () -> Void
    let onRecordWaste: () -> Void

    var body: some View {
        OutcomeScreen(badge: .quiet, symbol: "clock", title: KitchenCopy.hasEnded(mealName),
                      message: KitchenCopy.reportNotSent,
                      facts: [FactRow(label: KitchenCopy.mealEndedLabel, value: endedAt.map { MLFormat.time($0, in: timeZone) }),
                              FactRow(label: KitchenCopy.shortageReportLabel, value: KitchenCopy.notSent, isMono: false)],
                      primary: .init(title: KitchenCopy.recordWaste, handler: onRecordWaste),
                      secondary: .init(title: KitchenCopy.backToHome, handler: onBack),
                      footnote: KitchenCopy.leftOverGoesInWaste)
    }
}

/// A pushed Kitchen page: Back, a title and a subtitle, on the Orbit background.
struct KitchenPage<Content: View>: View {
    let title: String
    let subtitle: String
    let onBack: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    BackButton(action: onBack)
                    ScreenTitleBlock(title: title, subtitle: subtitle)
                    content
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, MLSpacing.s32)
            }
        }
    }
}
