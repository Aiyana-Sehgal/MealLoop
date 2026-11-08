import Observation
import SwiftUI

// Spending (221:63988) with Add expense (221:64118), Saving (221:64141), Failed (221:65703), Saved (221:64164), Edit
// expense (221:64238), Delete confirm (221:64262), Deleting (221:64288), Empty (221:65727), Loading (221:65739),
// Offline (221:65753) and Error (221:65828). Private: only the student sees it.

/// Words of the Spending frames. Wording only; every amount and day comes from `StudentSpendingRepository`.
enum SpendingCopy {
    static let addSpending = "Add spending"
    static let addExpense = "Add expense"
    static let editExpense = "Edit expense"
    static let amount = "Amount"
    static let date = "Date"
    static let category = "Category"
    static let place = "Place (optional)"
    static let placePrompt = "Add a place"
    static let note = "Note (optional)"
    static let notePrompt = "Add a note"
    static let save = "Save"
    static let tryAgain = "Try again"
    static let didNotSave = "Didn't save. Try again."
    static let deleteExpense = "Delete expense"
    static let deleteTitle = "Delete this expense?"
    static let deleteDetail = "You can't undo this."
    static let cancel = "Cancel"
    static let delete = "Delete"
    static let didNotDelete = "Didn't delete. Try again."
    static let emptyTitle = "Nothing added yet"
    static let emptyDetail = "Add what you spend outside the mess. Only you can see it."
    static let amountHint = "Amount in rupees"
    static func saved(_ category: StudentExpenseCategory, _ amount: Int) -> String {
        "Saved · \(title(category)) \(RecordsCopy.rupees(amount))"
    }

    static func title(_ category: StudentExpenseCategory) -> String {
        switch category {
        case .foodDelivery: "Food delivery"
        case .canteen: "Canteen"
        case .snacks: "Snacks"
        case .groceries: "Groceries"
        case .other: "Other"
        }
    }
}

// MARK: - View model

/// Spending screen state. Totals, weeks and what may be saved belong to the repository and `StudentSpendingMath`.
@MainActor
@Observable
final class StudentSpendingViewModel {
    enum Write: Equatable { case idle, working, failed }

    private(set) var state: LoadState<StudentSpendingSummary> = .idle
    private(set) var write: Write = .idle
    /// "Saved · Canteen ₹60" after a save, until the next change.
    private(set) var savedLine: String?

    let context: StudentContext
    private let spending: any StudentSpendingRepository
    private let clock: any AppClock

    init?(session: Session, repositories: Repositories, clock: any AppClock) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.spending = repositories.studentSpending
        self.clock = clock
    }

    var timeZone: TimeZone { context.mess.timeZone }
    var today: Date { clock.now() }
    private var student: StudentID { context.student.id }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let entries = try await spending.expenses(for: student)
            state = .loaded(StudentSpendingMath.summary(of: entries, today: today, timeZone: timeZone))
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    func beginEditing() {
        write = .idle
    }

    /// True when the repository saved it; the form then closes.
    func save(_ draft: StudentExpenseDraft, replacing id: StudentExpenseID?) async -> Bool {
        write = .working
        do {
            let saved = if let id {
                try await spending.updateExpense(id, with: draft, for: student)
            } else {
                try await spending.addExpense(draft, for: student)
            }
            savedLine = SpendingCopy.saved(saved.category, saved.amount)
            write = .idle
            await load()
            return true
        } catch {
            write = .failed
            return false
        }
    }

    func delete(_ id: StudentExpenseID) async -> Bool {
        write = .working
        do {
            try await spending.deleteExpense(id, for: student)
            savedLine = nil
            write = .idle
            await load()
            return true
        } catch {
            write = .failed
            return false
        }
    }

    func isSaveable(_ draft: StudentExpenseDraft) -> Bool {
        StudentSpendingMath.problems(in: draft, today: today, timeZone: timeZone).isEmpty
    }
}

// MARK: - Screen

/// What the expense form is open for.
enum SpendingForm: Identifiable, Hashable {
    case add
    case edit(StudentExpense)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let expense): expense.id.rawValue
        }
    }
}

struct StudentSpendingScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session

    var body: some View {
        if let model = StudentSpendingViewModel(session: session, repositories: environment.repositories,
                                                clock: environment.clock) {
            StudentSpendingView(model: model)
        } else {
            NotImplementedView(title: YouCopy.spending)
        }
    }
}

struct StudentSpendingView: View {
    @State private var model: StudentSpendingViewModel
    @State private var form: SpendingForm?
    /// A form to open once loaded (previews and the verification captures).
    private let opening: SpendingForm?

    init(model: StudentSpendingViewModel, opening: SpendingForm? = nil) {
        _model = State(initialValue: model)
        self.opening = opening
    }

    var body: some View {
        MLScreen(YouCopy.spending, bottomClearance: .tabBar) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                content
            }
        }
        .task {
            await model.load()
            if let opening { form = opening }
        }
        .refreshable { await model.load() }
        .mlSheet(item: $form, isWorking: model.write == .working) { form in
            ExpenseFormSheet(model: model, form: form) { self.form = nil }
        }
        .sensoryFeedback(trigger: model.savedLine) { _, line in line == nil ? nil : .success }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            SpendingPrivateChip()
            YouSkeleton(heights: [259, 216], label: YouCopy.spending)
        case .failed(let failure):
            SpendingPrivateChip()
            MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
        case .empty:
            page(nil)
        case .loaded(let summary), .stale(let summary, _):
            page(summary)
        case .offline(let summary, _):
            StudentOfflineBanner(text: RecordsCopy.spendingOffline)
            if let summary { page(summary, canAdd: false) }
        }
    }

    @ViewBuilder
    private func page(_ summary: StudentSpendingSummary?, canAdd: Bool = true) -> some View {
        SpendingPrivateChip()
        if let line = model.savedLine {
            SpendingSavedBanner(text: line)
                .mlTransition(.fromTop)
        }
        if let summary, !summary.isEmpty {
            SpendingHero(summary: summary, timeZone: model.timeZone)
            Text(RecordsCopy.recent)
                .font(StudentType.secondaryMedium)
                .foregroundStyle(MLColor.inkSecondary)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, MLSpacing.s4)
            VStack(spacing: 0) {
                ForEach(summary.recent) { expense in
                    Rectangle().fill(MLColor.border).frame(height: 1)
                    SpendingRow(expense: expense, timeZone: model.timeZone) {
                        model.beginEditing()
                        form = .edit(expense)
                    }
                    .disabled(!canAdd)
                }
            }
        } else {
            SpendingEmptyCard()
        }
        if canAdd {
            InkActionButton(title: SpendingCopy.addSpending) {
                model.beginEditing()
                form = .add
            }
            .padding(.top, MLSpacing.s4)
        }
    }
}

// MARK: - Parts

struct SpendingPrivateChip: View {
    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            Image(systemName: "lock").font(StudentType.secondaryMedium).accessibilityHidden(true)
            Text(RecordsCopy.privateChip).font(StudentType.secondaryMedium)
        }
        .foregroundStyle(MLColor.ink)
        .padding(.horizontal, MLSpacing.s16)
        .frame(minHeight: 40)
        .overlay(Capsule().strokeBorder(MLColor.ink, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
    }
}

/// "Saved · Canteen ₹60" (Spending · Saved 221:64164).
struct SpendingSavedBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            Image(systemName: "checkmark.circle").font(StudentType.bodySemibold).accessibilityHidden(true)
            Text(text).font(StudentType.bodySemibold)
            Spacer(minLength: 0)
        }
        .foregroundStyle(MLColor.ink)
        .padding(.horizontal, MLSpacing.s16)
        .frame(minHeight: 48)
        .background(Capsule().fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }
}

/// The empty card of Spending · Empty (221:65727).
struct SpendingEmptyCard: View {
    var body: some View {
        VStack(spacing: MLSpacing.s12) {
            Image(systemName: "checkmark.circle")
                .font(StudentType.section)
                .foregroundStyle(MLColor.ink)
                .frame(width: 52, height: 52)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(MLColor.fillQuiet))
                .accessibilityHidden(true)
            Text(SpendingCopy.emptyTitle).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
            Text(SpendingCopy.emptyDetail)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MLSpacing.s24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }
}

/// The black month card: total, this week and one bar per week.
struct SpendingHero: View {
    let summary: StudentSpendingSummary
    let timeZone: TimeZone

    var body: some View {
        let maxAmount = max(summary.weeks.compactMap(\.amount).max() ?? 1, 1)
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Text(RecordsCopy.monthSoFar).font(StudentType.secondary).foregroundStyle(MLColor.onHeroSecondary)
            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s12) {
                if let total = summary.monthTotal {
                    Text(RecordsCopy.rupees(total))
                        .font(.system(size: 48, weight: .medium, design: .monospaced))
                        .foregroundStyle(MLColor.onHero)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .mlNumericText(total)
                } else {
                    Text(RecordsCopy.totalMissing).font(StudentType.bodySemibold).foregroundStyle(MLColor.onHero)
                }
                if let week = summary.thisWeek {
                    Text(RecordsCopy.thisWeek(week)).font(StudentType.secondary).foregroundStyle(MLColor.onHeroSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            HStack(alignment: .bottom, spacing: MLSpacing.s16) {
                ForEach(summary.weeks) { week in
                    VStack(spacing: MLSpacing.s8) {
                        Spacer(minLength: 0)
                        if let amount = week.amount {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(week.isCurrent ? MLColor.lime : MLColor.track)
                                .frame(height: max(16, 88 * CGFloat(amount) / CGFloat(maxAmount)))
                        } else {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(MLColor.onHeroSecondary, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                .frame(height: 16)
                        }
                        Text(range(week))
                            .font(StudentType.footnote)
                            .foregroundStyle(week.isCurrent ? MLColor.onHero : MLColor.onHeroSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(range(week))
                    .accessibilityValue(week.amount.map(RecordsCopy.rupees) ?? "")
                }
            }
            .frame(height: 118)
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.heroBackground))
    }

    private func range(_ week: StudentSpendingWeek) -> String {
        let start = RecordsFormat.dayNumber(week.start, in: timeZone)
        let end = RecordsFormat.dayNumber(week.end, in: timeZone) + " " + RecordsFormat.monthShort(week.end, in: timeZone)
        return week.start == week.end ? end : RecordsCopy.weekRange(start, end)
    }
}

/// One Recent row. A tap opens Edit expense.
struct SpendingRow: View {
    let expense: StudentExpense
    let timeZone: TimeZone
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: MLSpacing.s4) {
                    Text(SpendingCopy.title(expense.category)).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                    Text([RecordsFormat.day(expense.day, in: timeZone), expense.place, expense.note].compactMap { $0 }
                        .joined(separator: " · "))
                        .font(StudentType.secondary)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: MLSpacing.s8)
                Text(RecordsCopy.rupees(expense.amount)).font(StudentType.mono).foregroundStyle(MLColor.ink)
            }
            .padding(.vertical, MLSpacing.s12)
            .frame(minHeight: MLSize.hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(SpendingCopy.editExpense)
    }
}

// MARK: - Add and Edit expense

/// Add expense (221:64118) and Edit expense (221:64238) in a sheet sized to its content.
struct ExpenseFormSheet: View {
    enum Field: Hashable { case amount, place, note }

    let model: StudentSpendingViewModel
    let form: SpendingForm
    let onClose: () -> Void

    @State private var amountText = ""
    @State private var day = Date()
    @State private var category: StudentExpenseCategory = .foodDelivery
    @State private var place = ""
    @State private var note = ""
    @State private var confirmsDelete = false
    @State private var lastAction: Action = .save
    @FocusState private var focus: Field?

    private enum Action { case save, delete }

    private var editing: StudentExpense? {
        if case .edit(let expense) = form { return expense }
        return nil
    }

    private var draft: StudentExpenseDraft {
        StudentExpenseDraft(amount: Int(amountText) ?? 0, day: day, category: category, place: place, note: note)
    }

    private var isWorking: Bool { model.write == .working }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: editing == nil ? SpendingCopy.addExpense : SpendingCopy.editExpense, onClose: onClose)
            labelled(SpendingCopy.amount) {
                HStack(spacing: MLSpacing.s8) {
                    Image(systemName: "indianrupeesign").font(StudentType.section).foregroundStyle(MLColor.inkSecondary)
                        .accessibilityHidden(true)
                    TextField("", text: $amountText, prompt: Text(verbatim: "0"))
                        .font(.system(size: 28, weight: .medium, design: .monospaced))
                        .keyboardType(.numberPad)
                        .focused($focus, equals: .amount)
                        .accessibilityLabel(SpendingCopy.amountHint)
                        .onChange(of: amountText) { _, text in
                            let digits = String(text.filter(\.isNumber).prefix(6))
                            if digits != text { amountText = digits }
                        }
                }
                .padding(.horizontal, MLSpacing.s16)
                .frame(minHeight: 64)
                .background(fieldBackground)
            }
            labelled(SpendingCopy.date) {
                DatePicker(SpendingCopy.date, selection: $day, in: ...model.today, displayedComponents: .date)
                    .labelsHidden()
                    .environment(\.timeZone, model.timeZone)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, MLSpacing.s12)
                    .frame(minHeight: 52)
                    .background(fieldBackground)
            }
            labelled(SpendingCopy.category) {
                StudentFlowLayout(spacing: MLSpacing.s8) {
                    ForEach(StudentExpenseCategory.allCases, id: \.self) { option in
                        categoryChip(option)
                    }
                }
            }
            labelled(SpendingCopy.place) {
                textField(SpendingCopy.placePrompt, text: $place, field: .place, submit: .next)
            }
            labelled(SpendingCopy.note) {
                textField(SpendingCopy.notePrompt, text: $note, field: .note, submit: .done)
            }
            if model.write == .failed {
                HStack(spacing: MLSpacing.s8) {
                    Image(systemName: "exclamationmark.triangle").accessibilityHidden(true)
                    Text(lastAction == .delete ? SpendingCopy.didNotDelete : SpendingCopy.didNotSave)
                        .font(StudentType.secondaryMedium)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(MLColor.danger)
                .padding(.horizontal, MLSpacing.s16)
                .frame(minHeight: 48)
                .background(RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous).fill(StudentTint.errorFill))
                .mlTransition(.fade)
            }
            InkActionButton(title: model.write == .failed && lastAction == .save ? SpendingCopy.tryAgain : SpendingCopy.save,
                            isLoading: isWorking && lastAction == .save) {
                focus = nil
                lastAction = .save
                Task {
                    if await model.save(draft, replacing: editing?.id) { onClose() }
                }
            }
            .disabled(!model.isSaveable(draft) || isWorking)
            if editing != nil {
                Button {
                    focus = nil
                    confirmsDelete = true
                } label: {
                    HStack(spacing: MLSpacing.s8) {
                        if isWorking && lastAction == .delete {
                            ProgressView().tint(MLColor.ink)
                        } else {
                            Image(systemName: "trash").accessibilityHidden(true)
                        }
                        Text(SpendingCopy.deleteExpense).font(StudentType.bodySemibold)
                    }
                    .foregroundStyle(MLColor.ink)
                    .frame(maxWidth: .infinity, minHeight: MLSize.hit)
                }
                .buttonStyle(.plain)
                .disabled(isWorking)
            }
        }
        .onAppear(perform: fill)
        .alert(SpendingCopy.deleteTitle, isPresented: $confirmsDelete) {
            Button(SpendingCopy.cancel, role: .cancel) {}
            Button(SpendingCopy.delete, role: .destructive) {
                guard let id = editing?.id else { return }
                lastAction = .delete
                Task {
                    if await model.delete(id) { onClose() }
                }
            }
        } message: {
            Text(SpendingCopy.deleteDetail)
        }
    }

    private func fill() {
        if let editing {
            amountText = String(editing.amount)
            day = editing.day
            category = editing.category
            place = editing.place ?? ""
            note = editing.note ?? ""
        } else {
            day = model.today
            focus = .amount
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous)
            .fill(MLColor.surface)
            .overlay(RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous).strokeBorder(MLColor.border))
    }

    private func labelled<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            Text(label).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
            content()
        }
    }

    private func textField(_ prompt: String, text: Binding<String>, field: Field, submit: SubmitLabel) -> some View {
        TextField(prompt, text: text)
            .font(StudentType.body)
            .textInputAutocapitalization(.sentences)
            .submitLabel(submit)
            .focused($focus, equals: field)
            .onSubmit { focus = field == .place ? .note : nil }
            .padding(.horizontal, MLSpacing.s16)
            .frame(minHeight: 52)
            .background(fieldBackground)
    }

    private func categoryChip(_ option: StudentExpenseCategory) -> some View {
        let selected = option == category
        return Button {
            category = option
        } label: {
            HStack(spacing: MLSpacing.s4) {
                if selected {
                    Image(systemName: "checkmark").font(StudentType.tag).accessibilityHidden(true)
                }
                Text(SpendingCopy.title(option)).font(StudentType.bodySemibold)
            }
            .foregroundStyle(MLColor.ink)
            .padding(.horizontal, MLSpacing.s16)
            .frame(minHeight: MLSize.hit)
            .background(Capsule().fill(selected ? MLColor.lime : MLColor.surface))
            .overlay(Capsule().strokeBorder(MLColor.ink, lineWidth: selected ? 1 : 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: selected)
    }
}

#if DEMO_DATA || REVIEW_DATA
#Preview("Spending") {
    let demo = DemoDataProvider(scenario: .storyStart)
    let session = Session(account: DemoSeed.accounts.first { $0.role == .student }!, staff: nil,
                          student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
    return NavigationStack {
        StudentSpendingView(model: StudentSpendingViewModel(session: session, repositories: demo.makeRepositories(),
                                                            clock: demo.clock)!)
    }
}

#Preview("Add expense") {
    let demo = DemoDataProvider(scenario: .storyStart)
    let session = Session(account: DemoSeed.accounts.first { $0.role == .student }!, staff: nil,
                          student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
    return NavigationStack {
        StudentSpendingView(model: StudentSpendingViewModel(session: session, repositories: demo.makeRepositories(),
                                                            clock: demo.clock)!, opening: .add)
    }
}

#Preview("Offline") {
    let demo = DemoDataProvider(scenario: .offline)
    let session = Session(account: DemoSeed.accounts.first { $0.role == .student }!, staff: nil,
                          student: StudentContext(student: DemoSeed.sampleStudent, mess: DemoSeed.mess))
    return NavigationStack {
        StudentSpendingView(model: StudentSpendingViewModel(session: session, repositories: demo.makeRepositories(),
                                                            clock: demo.clock)!)
    }
}
#endif
