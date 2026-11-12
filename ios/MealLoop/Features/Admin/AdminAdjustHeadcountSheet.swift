import SwiftUI

/// Change the number (AD05, design/reference/admin_full_2026-11): a stepper, what the forecast was, one required reason
/// and one action. Save stays disabled until a reason is chosen, and the backend also refuses a change without one.
/// On the Food Head's own mess, saving approves the changed number; the toast says so.
struct AdminAdjustHeadcountSheet: View {
    /// "Lunch · Main"
    let subtitle: String?
    /// The forecast the number started from. Nil when there was none.
    let forecast: Int?
    let isSaving: Bool
    let errorText: String?
    let save: (Int, String?) async -> Bool
    let onSaved: (Int) -> Void
    let onClose: () -> Void

    @State private var count: Int
    @State private var chosenReason: String?

    init(startCount: Int, subtitle: String?, forecast: Int?, isSaving: Bool, errorText: String?,
         save: @escaping (Int, String?) async -> Bool, onSaved: @escaping (Int) -> Void, onClose: @escaping () -> Void) {
        self.subtitle = subtitle
        self.forecast = forecast
        self.isSaving = isSaving
        self.errorText = errorText
        self.save = save
        self.onSaved = onSaved
        self.onClose = onClose
        _count = State(initialValue: startCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                SheetHeader(title: AdminCopy.changeTheNumber, onClose: onClose)
                if let subtitle {
                    Text(subtitle)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
            }
            HStack {
                stepButton(symbol: "minus", label: AdminCopy.decrease) { count = max(0, count - 1) }
                Spacer(minLength: MLSpacing.s8)
                Text(String(count))
                    .font(AdminType.stat)
                    .foregroundStyle(MLColor.ink)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: MLSpacing.s8)
                stepButton(symbol: "plus", label: AdminCopy.increase) { count += 1 }
            }
            .padding(MLSpacing.s16)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.canvas))
            if let forecast {
                Text(AdminCopy.forecastWas(forecast))
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            Text(AdminCopy.whyChanging)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
                .accessibilityAddTraits(.isHeader)
            AdminFlow {
                ForEach(AdminCopy.changeReasons, id: \.self) { reason in
                    ChoiceChip(title: reason, isSelected: chosenReason == reason) { chosenReason = reason }
                }
            }
            if let errorText {
                FieldErrorText(text: errorText)
            }
            InkActionButton(title: AdminCopy.saveChange, isLoading: isSaving) {
                Task {
                    if await save(count, chosenReason) { onSaved(count) }
                }
            }
            .disabled(chosenReason == nil)
            .accessibilityHint(chosenReason == nil ? AdminCopy.chooseReason : "")
            Text(AdminCopy.changeNote)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
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
