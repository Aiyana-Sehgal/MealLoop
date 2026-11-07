import SwiftUI

/// The prepared message for the vendor. Nothing is sent from here: it shows what would open on the phone.
struct AdminTellVendorSheet: View {
    @Environment(AppEnvironment.self) private var environment
    let subtitle: String
    let message: String
    let note: String?
    let onClose: () -> Void

    @State private var phone: String?
    @State private var didTry = false

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: AdminScreenCopy.tellTheVendor, subtitle: subtitle, onClose: onClose)
            Text(message)
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.ink)
                .padding(MLSpacing.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.fillQuiet))
            if let note {
                AdminNote(text: note)
            }
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                HStack(spacing: MLSpacing.s8) {
                    Text(AdminScreenCopy.vendor)
                        .font(MLType.staffPrimary)
                    Text(phone ?? AdminFormat.missing)
                        .font(MLType.monoBody)
                }
                .foregroundStyle(MLColor.ink)
                Text(AdminScreenCopy.vendorNothingSent)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            .padding(MLSpacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
                .stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            if didTry {
                AdminNote(text: AdminScreenCopy.vendorNotBuilt)
            }
            HStack(spacing: MLSpacing.s12) {
                InkActionButton(title: AdminScreenCopy.message) { didTry = true }
                OutlineActionButton(title: AdminScreenCopy.call) { didTry = true }
            }
        }
        .task {
            phone = (try? await environment.repositories.adminMore.people())?.vendor.phone
        }
    }
}

@MainActor
@Observable
final class AdminChangeViewModel {
    var text: String
    private(set) var isSaving = false
    private(set) var errorText: String?

    private let meal: MealID?
    private let context: AdminContext
    private let results: any AdminResultsRepository

    init(meal: MealID?, suggested: String, context: AdminContext, results: any AdminResultsRepository) {
        self.meal = meal
        self.text = suggested
        self.context = context
        self.results = results
    }

    var canSave: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving }

    func save() async -> CheckNextTime? {
        guard canSave else { return nil }
        isSaving = true
        errorText = nil
        defer { isSaving = false }
        do {
            return try await results.saveChange(ChangeDraft(meal: meal, change: text, owner: context.account.firstName), by: context.account.role)
        } catch {
            errorText = AdminWriteError.text(error)
            return nil
        }
    }
}

/// Make it a change (A04): what will change, who owns it, and when it can be judged.
struct AdminMakeChangeSheet: View {
    @Environment(AppEnvironment.self) private var environment
    let meal: MealID?
    let suggested: String
    let context: AdminContext
    let onClose: () -> Void
    let onSaved: (CheckNextTime) -> Void

    var body: some View {
        AdminMakeChangeForm(model: AdminChangeViewModel(meal: meal, suggested: suggested, context: context,
                                                        results: environment.repositories.adminResults),
                            ownerName: context.account.firstName, onClose: onClose, onSaved: onSaved)
    }
}

private struct AdminMakeChangeForm: View {
    @State private var model: AdminChangeViewModel
    let ownerName: String
    let onClose: () -> Void
    let onSaved: (CheckNextTime) -> Void

    init(model: AdminChangeViewModel, ownerName: String, onClose: @escaping () -> Void, onSaved: @escaping (CheckNextTime) -> Void) {
        _model = State(initialValue: model)
        self.ownerName = ownerName
        self.onClose = onClose
        self.onSaved = onSaved
    }

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: AdminScreenCopy.makeItAChange, subtitle: AdminScreenCopy.whatWillChange, onClose: onClose)
            AdminTextField(placeholder: AdminScreenCopy.whatWillChange, text: $model.text, lines: 2)
            AdminRow(title: AdminScreenCopy.ownerLabel, detail: AdminScreenCopy.you(ownerName), action: nil) { EmptyView() }
            AdminRow(title: AdminScreenCopy.checkAfter, detail: AdminScreenCopy.comparableAfter(CheckNextTimePolicy.requiredMeals), action: nil) {
                Text("\(CheckNextTimePolicy.requiredMeals)")
                    .font(MLType.monoBody)
                    .foregroundStyle(MLColor.ink)
            }
            AdminNote(text: AdminScreenCopy.canOnlyClose(CheckNextTimePolicy.requiredMeals))
            if let error = model.errorText {
                FieldErrorText(text: error)
            }
            InkActionButton(title: AdminScreenCopy.save, isLoading: model.isSaving) {
                Task {
                    if let check = await model.save() { onSaved(check) }
                }
            }
            .disabled(!model.canSave)
        }
    }
}
