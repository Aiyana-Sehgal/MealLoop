import SwiftUI

/// Adjust headcount (A02 sheet): a number, a reason and one action. The backend refuses a change without a
/// reason, so its answer is shown here instead of being guessed. On the Food Head's own mess, saving approves.
struct AdminAdjustHeadcountSheet: View {
    let forecastLine: String?
    /// Nil writes "Approve 860", for the headcount where saving is the approval.
    let saveTitle: String?
    let isSaving: Bool
    let errorText: String?
    let save: (Int, String?) async -> Bool
    let onSaved: (Int) -> Void
    let onClose: () -> Void

    @State private var count: Int
    @State private var chosenReason: String?
    @State private var otherReason = ""

    private let reasons = [AdminCopy.reasonEvent, AdminCopy.reasonExam, AdminCopy.reasonHoliday, AdminCopy.reasonOther]

    init(startCount: Int, forecastLine: String?, saveTitle: String?, isSaving: Bool, errorText: String?,
         save: @escaping (Int, String?) async -> Bool, onSaved: @escaping (Int) -> Void, onClose: @escaping () -> Void) {
        self.forecastLine = forecastLine
        self.saveTitle = saveTitle
        self.isSaving = isSaving
        self.errorText = errorText
        self.save = save
        self.onSaved = onSaved
        self.onClose = onClose
        _count = State(initialValue: startCount)
    }

    private var reasonToSend: String? {
        chosenReason == AdminCopy.reasonOther ? otherReason : chosenReason
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: AdminCopy.adjustHeadcount, onClose: onClose)
            HStack(spacing: MLSpacing.s24) {
                stepButton(symbol: "minus", label: AdminCopy.decrease) { count = max(0, count - 1) }
                Text(String(count))
                    .font(MLType.heroNumber)
                    .foregroundStyle(MLColor.ink)
                    .monospacedDigit()
                stepButton(symbol: "plus", label: AdminCopy.increase) { count += 1 }
            }
            .frame(maxWidth: .infinity)
            if let forecastLine {
                Text(forecastLine)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .frame(maxWidth: .infinity)
            }
            AdminLabel(text: AdminCopy.reason)
            AdminFlow {
                ForEach(reasons, id: \.self) { reason in
                    ChoiceChip(title: reason, isSelected: chosenReason == reason) { chosenReason = reason }
                }
            }
            if chosenReason == AdminCopy.reasonOther {
                TextField(AdminCopy.reasonOtherPrompt, text: $otherReason)
                    .font(MLType.body)
                    .padding(.horizontal, MLSpacing.s16)
                    .frame(minHeight: MLSize.hit)
                    .background(RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous).fill(MLColor.fillQuiet))
            }
            Text(AdminCopy.adjustNote)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            if let errorText {
                FieldErrorText(text: errorText)
            }
            InkActionButton(title: saveTitle.map { "\($0) \(count)" } ?? AdminCopy.approve(count), isLoading: isSaving) {
                Task {
                    if await save(count, reasonToSend) { onSaved(count) }
                }
            }
        }
    }

    private func stepButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(MLColor.ink)
                .frame(width: 56, height: 56)
                .overlay(Circle().stroke(MLColor.ink, lineWidth: 1.5))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .buttonRepeatBehavior(.enabled)
        .accessibilityLabel(label)
    }
}
