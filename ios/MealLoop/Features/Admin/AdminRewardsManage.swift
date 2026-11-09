import Observation
import SwiftUI

// Rewards › manage (approved images admin_rewards_03_manage and admin_rewards_04_add_sheet): every reward with its
// credit cost and a delete button, Add a reward in a sheet sized to its content, and delete confirmed in the shared
// compact dialog. The Student Credits screen reads the same catalogue.

enum AdminRewardsCopy {
    static let subtitle = "What students can get with credits"
    static func credits(_ cost: Int) -> String { "\(cost) credits" }
    static let addReward = "Add a reward"
    static let changesStraightAway = "Students see changes straight away."
    static let name = "Name"
    static let creditsItCosts = "Credits it costs"
    static let showsInCredits = "It shows in Credits as soon as you save."
    static let saveReward = "Save reward"
    static func deleteTitle(_ name: String) -> String { "Delete \(name)?" }
    static let deleteDetail = "Students stop seeing it. Tickets already got stay valid."
    static let cancel = "Cancel"
    static let delete = "Delete"
    static func added(_ name: String) -> String { "\(name) added" }
    static func deleted(_ name: String) -> String { "\(name) deleted" }
    static let nothingYet = "No rewards yet. Add one for students to get with credits."
    static func deleteLabel(_ name: String) -> String { "Delete \(name)" }
}

@MainActor
@Observable
final class AdminRewardCatalogueModel {
    private(set) var items: LoadState<[StudentCreditTicket]> = .idle
    private(set) var isWriting = false
    private(set) var errorText: String?

    private let repository: any RewardCatalogueRepository
    private let role: Role

    init(repository: any RewardCatalogueRepository, role: Role) {
        self.repository = repository
        self.role = role
    }

    func load() async {
        do {
            let list = try await repository.items()
            items = list.isEmpty ? .empty : .loaded(list)
        } catch RepositoryError.offline(let savedAt) {
            items = .offline(items.value, savedAt: savedAt)
        } catch {
            items = .failed(LoadFailure(error))
        }
    }

    func clearError() { errorText = nil }

    func add(name: String, cost: Int?) async -> Bool {
        isWriting = true
        defer { isWriting = false }
        do {
            _ = try await repository.add(name: name, cost: cost ?? 0, by: role)
            errorText = nil
            await load()
            return true
        } catch {
            errorText = AdminWriteError.text(error)
            return false
        }
    }

    func delete(_ id: String) async -> Bool {
        isWriting = true
        defer { isWriting = false }
        do {
            try await repository.delete(id, by: role)
            errorText = nil
            await load()
            return true
        } catch {
            errorText = AdminWriteError.text(error)
            return false
        }
    }
}

/// The catalogue list, Add a reward and the delete confirmation, under the Rewards page's budget card.
struct AdminRewardCatalogueSection: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: AdminRewardCatalogueModel?
    let nav: AdminNav
    var addOpen = false
    @State private var adding = false
    @State private var deleting: StudentCreditTicket?

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            if let model {
                switch model.items {
                case .loaded(let items), .stale(let items, _), .offline(let items?, _):
                    VStack(spacing: 0) {
                        ForEach(items) { item in row(item) }
                    }
                case .empty:
                    Text(AdminRewardsCopy.nothingYet).mlFont(.body).foregroundStyle(MLColor.inkSecondary)
                case .failed(let failure):
                    AdminNote(text: failure.message)
                default:
                    ProgressView().frame(maxWidth: .infinity)
                }
                InkActionButton(title: AdminRewardsCopy.addReward) {
                    model.clearError()
                    adding = true
                }
                Text(AdminRewardsCopy.changesStraightAway)
                    .mlFont(.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .task {
            if model == nil {
                model = AdminRewardCatalogueModel(repository: environment.repositories.rewardCatalogue,
                                                  role: nav.context.account.role)
                adding = addOpen
            }
            await model?.load()
        }
        .mlSheet(isPresented: $adding, isWorking: model?.isWriting ?? false) {
            if let model {
                AdminAddRewardSheet(model: model) { name in
                    adding = false
                    nav.toast(AdminRewardsCopy.added(name))
                } onClose: { adding = false }
            }
        }
        .mlConfirmDialog(isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
                         content: ConfirmDialogContent(title: AdminRewardsCopy.deleteTitle(deleting?.name ?? ""),
                                                       detail: AdminRewardsCopy.deleteDetail,
                                                       cancelTitle: AdminRewardsCopy.cancel,
                                                       actionTitle: AdminRewardsCopy.delete),
                         isWorking: model?.isWriting ?? false) {
            guard let item = deleting, let model else { return }
            Task {
                if await model.delete(item.id) {
                    deleting = nil
                    nav.toast(AdminRewardsCopy.deleted(item.name))
                }
            }
        }
    }

    private func row(_ item: StudentCreditTicket) -> some View {
        HStack(spacing: MLSpacing.s12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).mlFont(.staffBody).foregroundStyle(MLColor.ink)
                Text(AdminRewardsCopy.credits(item.cost)).mlFont(.body).foregroundStyle(MLColor.inkSecondary)
            }
            Spacer(minLength: MLSpacing.s8)
            Button {
                deleting = item
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(MLColor.ink)
                    .frame(width: MLSize.hit, height: MLSize.hit)
                    .background(Circle().fill(MLColor.surface))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AdminRewardsCopy.deleteLabel(item.name))
        }
        .padding(.vertical, MLSpacing.s12)
        .overlay(alignment: .top) { Rectangle().fill(MLColor.border).frame(height: 1) }
        .accessibilityElement(children: .contain)
    }
}

/// Add a reward: name, credits it costs, Save reward. Sized to its content.
struct AdminAddRewardSheet: View {
    let model: AdminRewardCatalogueModel
    let onSaved: (String) -> Void
    let onClose: () -> Void
    @State private var name = ""
    @State private var cost = ""
    @FocusState private var focus: Field?

    private enum Field { case name, cost }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: AdminRewardsCopy.addReward, onClose: onClose)
            AdminTextField(placeholder: AdminRewardsCopy.name, text: $name)
                .focused($focus, equals: .name)
                .submitLabel(.next)
                .onSubmit { focus = .cost }
            AdminTextField(placeholder: AdminRewardsCopy.creditsItCosts, text: $cost)
                .keyboardType(.numberPad)
                .focused($focus, equals: .cost)
                .onChange(of: cost) { _, text in
                    let digits = String(text.filter(\.isNumber).prefix(5))
                    if digits != text { cost = digits }
                }
            Text(AdminRewardsCopy.showsInCredits).mlFont(.secondary).foregroundStyle(MLColor.inkSecondary)
            if let error = model.errorText { FieldErrorText(text: error) }
            InkActionButton(title: AdminRewardsCopy.saveReward, isLoading: model.isWriting) {
                let saved = name.trimmingCharacters(in: .whitespacesAndNewlines)
                Task { if await model.add(name: name, cost: Int(cost)) { onSaved(saved) } }
            }
            .disabled(model.isWriting || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Int(cost) ?? 0) <= 0)
        }
    }
}
