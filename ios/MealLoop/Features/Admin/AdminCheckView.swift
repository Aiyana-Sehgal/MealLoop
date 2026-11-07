import SwiftUI

/// One change being tested. "Worked" is a judgement on comparable meals, so the button stays closed until there are enough.
@MainActor
@Observable
final class AdminCheckViewModel {
    private(set) var state: LoadState<CheckNextTime> = .idle
    private(set) var isSaving = false
    private(set) var errorText: String?

    private let id: CheckID
    private let role: Role
    private let results: any AdminResultsRepository

    init(id: CheckID, role: Role, results: any AdminResultsRepository) {
        self.id = id
        self.role = role
        self.results = results
    }

    var counted: Int { state.value.map(CheckNextTimePolicy.countedMeals) ?? 0 }
    var canCloseAsWorked: Bool { state.value.map(CheckNextTimePolicy.canCloseAsWorked) ?? false }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            state = .loaded(try await results.check(id))
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    func closeAsWorked() async {
        await write { [results, id, role] in try await results.closeAsWorked(id, by: role) }
    }

    func addNote(_ note: String) async {
        await write { [results, id, role] in try await results.addNote(note, to: id, by: role) }
    }

    private func write(_ work: () async throws -> CheckNextTime) async {
        guard !isSaving else { return }
        isSaving = true
        errorText = nil
        defer { isSaving = false }
        do {
            state = .loaded(try await work())
        } catch {
            errorText = AdminWriteError.text(error)
        }
    }
}

struct AdminCheckScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let check: CheckID
    let nav: AdminNav

    var body: some View {
        AdminCheckView(model: AdminCheckViewModel(id: check, role: nav.context.account.role, results: environment.repositories.adminResults), nav: nav)
    }
}

struct AdminCheckView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: AdminCheckViewModel
    let nav: AdminNav

    @State private var isAddingNote = false
    @State private var note = ""

    init(model: AdminCheckViewModel, nav: AdminNav) {
        _model = State(initialValue: model)
        self.nav = nav
    }

    private var timeZone: TimeZone { nav.timeZone }

    var body: some View {
        AdminPageScaffold(title: model.state.value?.title ?? AdminScreenCopy.checkNextTime, subtitle: subtitle, onBack: nav.pop) {
            AsyncContentView(state: model.state, timeZone: timeZone, retry: { await model.load() }) { check in
                content(check)
            }
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
        .mlSheet(isPresented: $isAddingNote) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                SheetHeader(title: AdminScreenCopy.noteTitle) { isAddingNote = false }
                AdminTextField(placeholder: AdminScreenCopy.notePlaceholder, text: $note, lines: 3)
                InkActionButton(title: AdminScreenCopy.save) {
                    let text = note
                    note = ""
                    isAddingNote = false
                    Task { await model.addNote(text) }
                }
                .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var subtitle: String? {
        model.state.value.map { AdminScreenCopy.startedBy(mess: $0.mess, day: AdminFormat.day($0.startedOn, in: timeZone), by: $0.startedBy) }
    }

    private func content(_ check: CheckNextTime) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            HeroCard {
                VStack(alignment: .leading, spacing: MLSpacing.s8) {
                    HeroEyebrow(label: AdminScreenCopy.wellChange)
                    Text(check.change)
                        .font(MLType.title2)
                        .foregroundStyle(MLColor.onHero)
                    Text(AdminScreenCopy.ownerAndPlan(check.owner, check.plan))
                        .font(MLType.body)
                        .foregroundStyle(MLColor.onHeroSecondary)
                }
            }
            AdminStageLine(stages: CheckStage.allCases.map(AdminScreenCopy.stage), current: CheckStage.allCases.firstIndex(of: check.stage) ?? 0)
            AdminCard {
                AdminLabel(text: check.comparableTitle)
                ForEach(check.comparable) { meal in
                    comparableRow(meal)
                }
                if check.closedAsWorked {
                    AdminChip(text: AdminScreenCopy.workedVerified, style: .lime)
                } else {
                    AdminChip(text: AdminScreenCopy.notEnoughData, style: .dashed)
                }
                AdminNote(text: check.footnote)
            }
            if check.isActionCompleted, !check.closedAsWorked {
                AdminNote(text: AdminScreenCopy.actionDoneNotResult)
            }
            ForEach(check.notes, id: \.self) { note in
                Text(note)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.ink)
            }
            if let error = model.errorText {
                FieldErrorText(text: error)
            }
            if !check.closedAsWorked {
                HStack(spacing: MLSpacing.s12) {
                    OutlineActionButton(title: AdminScreenCopy.addNote) { isAddingNote = true }
                    if model.canCloseAsWorked {
                        InkActionButton(title: AdminScreenCopy.closeAsWorked, isLoading: model.isSaving) {
                            Task { await model.closeAsWorked() }
                        }
                    } else {
                        CompactPillButton(title: AdminScreenCopy.closeAsWorked, style: .dashed) {}
                            .disabled(true)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func comparableRow(_ meal: ComparableMeal) -> some View {
        HStack {
            Text(AdminFormat.day(meal.day, in: timeZone))
                .font(MLType.staffBody)
                .foregroundStyle(meal.isRecorded ? MLColor.ink : MLColor.inkSecondary)
            Spacer()
            if meal.isRecorded {
                if let note = meal.note {
                    Text(note)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.ink)
                } else {
                    recorded(meal)
                }
            } else {
                Text(AdminScreenCopy.waiting)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
        }
        .frame(minHeight: MLSize.hit)
        .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }

    private func recorded(_ meal: ComparableMeal) -> some View {
        HStack(spacing: MLSpacing.s4) {
            Text(AdminFormat.count(meal.headcountSent)).font(MLType.monoBody)
            Text("\(AdminScreenCopy.sentWord) ·").font(MLType.body)
            Text(AdminFormat.count(meal.finalEntries)).font(MLType.monoBody)
            Text(AdminScreenCopy.cameWord).font(MLType.body)
        }
        .foregroundStyle(MLColor.ink)
    }
}
