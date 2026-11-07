import SwiftUI

/// The weekly menu (A12, F04, F05). The upload is a SIMULATED flow: no photo is taken and no text is read.
@MainActor
@Observable
final class AdminMenuViewModel {
    enum UploadPhase: Equatable {
        case idle
        case uploading
        case reading
    }

    private(set) var state: LoadState<WeekMenu> = .idle
    private(set) var phase: UploadPhase = .idle
    private(set) var errorText: String?

    private let more: any AdminMoreRepository
    private let role: Role
    private let stepTime: Duration

    init(more: any AdminMoreRepository, role: Role, stepTime: Duration = .seconds(1.5)) {
        self.more = more
        self.role = role
        self.stepTime = stepTime
    }

    var today: MenuDay? { state.value.flatMap { menu in menu.days.first { $0.day == menu.today } } }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            state = .loaded(try await more.weekMenu())
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    func simulateUpload() async {
        guard phase == .idle else { return }
        phase = .uploading
        try? await Task.sleep(for: stepTime)
        phase = .reading
        try? await Task.sleep(for: stepTime)
        phase = .idle
    }

    func apply(_ change: QuickChange) async -> Bool {
        errorText = nil
        do {
            state = .loaded(try await more.applyToTodaysDinner(change, by: role))
            return true
        } catch {
            errorText = AdminWriteError.text(error)
            return false
        }
    }
}

struct AdminMenuScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        AdminMenuView(model: AdminMenuViewModel(more: environment.repositories.adminMore, role: nav.context.account.role), nav: nav)
    }
}

struct AdminMenuView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: AdminMenuViewModel
    let nav: AdminNav

    @State private var isChangingDinner = false

    init(model: AdminMenuViewModel, nav: AdminNav) {
        _model = State(initialValue: model)
        self.nav = nav
    }

    private var timeZone: TimeZone { nav.timeZone }

    var body: some View {
        AdminPageScaffold(title: AdminScreenCopy.weeklyMenu, subtitle: AdminScreenCopy.menuSubtitle, onBack: nav.pop) {
            AsyncContentView(state: model.state, timeZone: timeZone, retry: { await model.load() }) { menu in
                content(menu)
            }
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
        .mlSheet(isPresented: $isChangingDinner) {
            if let today = model.today {
                AdminDinnerChangeSheet(model: model, today: today, nav: nav) { isChangingDinner = false }
            }
        }
    }

    private func moment(_ date: Date) -> String {
        "\(AdminFormat.weekday(date, in: timeZone).prefix(3)) \(MLFormat.time(date, in: timeZone))"
    }

    private func content(_ menu: WeekMenu) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            hero(menu)
            if model.phase == .idle {
                TextLinkButton(title: AdminScreenCopy.changeTodaysDinner) { isChangingDinner = true }
            }
            steps
            header
            VStack(spacing: 0) {
                ForEach(menu.days) { day in
                    row(day, menu: menu)
                }
            }
        }
    }

    private func hero(_ menu: WeekMenu) -> some View {
        HeroCard {
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                switch model.phase {
                case .idle:
                    HeroEyebrow(label: AdminScreenCopy.published(moment(menu.publishedAt)))
                case .uploading:
                    HeroEyebrow(label: AdminScreenCopy.uploading(moment(menu.publishedAt)))
                case .reading:
                    HeroEyebrow(label: AdminScreenCopy.readingBoard(moment(menu.publishedAt)))
                }
                Text(menu.range)
                    .font(MLType.heroTitle)
                    .foregroundStyle(MLColor.onHero)
                switch model.phase {
                case .idle:
                    LimeActionButton(title: AdminScreenCopy.uploadNextWeek) {
                        Task { await model.simulateUpload() }
                    }
                case .uploading:
                    SegmentedProgress(current: 1, total: 2, surface: .hero)
                    heroNote(AdminScreenCopy.photoLine(menu.photoSize))
                    heroNote(AdminScreenCopy.simulatedUpload)
                case .reading:
                    SegmentedProgress(current: 2, total: 2, surface: .hero)
                    heroNote(AdminScreenCopy.readingLine)
                    heroNote(AdminScreenCopy.simulatedUpload)
                }
            }
        }
    }

    private func heroNote(_ text: String) -> some View {
        Text(text)
            .font(MLType.body)
            .foregroundStyle(MLColor.onHeroSecondary)
    }

    private var currentStep: Int {
        switch model.phase {
        case .uploading: return 0
        case .reading: return 1
        case .idle: return -1
        }
    }

    private var steps: some View {
        HStack {
            ForEach(Array([AdminScreenCopy.stepPhoto, AdminScreenCopy.stepRead, AdminScreenCopy.stepCheck].enumerated()), id: \.offset) { index, title in
                HStack(spacing: MLSpacing.s8) {
                    Text("\(index + 1)")
                        .font(MLType.monoSecondary)
                        .foregroundStyle(index == currentStep ? MLColor.onHero : MLColor.ink)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(index == currentStep ? MLColor.ink : Color.clear))
                        .overlay(Circle().stroke(MLColor.ink, lineWidth: 1))
                    Text(title)
                        .font(MLType.secondary)
                        .foregroundStyle(index == currentStep ? MLColor.ink : MLColor.inkSecondary)
                }
                if index < 2 {
                    Spacer(minLength: MLSpacing.s4)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var header: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: AdminMenuLayout.dayColumn)
            ForEach(AdminScreenCopy.mealLetters, id: \.self) { letter in
                Text(letter)
                    .font(MLType.meta)
                    .foregroundStyle(MLColor.inkSecondary)
                    .frame(width: AdminMenuLayout.dotColumn)
            }
            Spacer()
        }
        .accessibilityHidden(true)
    }

    private func row(_ day: MenuDay, menu: WeekMenu) -> some View {
        let toCheck = day.wordsToCheck
        let open = {
            guard model.phase == .idle else { return }
            nav.push(.editDay(day.day))
        }
        return HStack(spacing: 0) {
            Button(action: open) {
                HStack(spacing: 0) {
                    HStack(spacing: MLSpacing.s4) {
                        Text(AdminFormat.shortDay(day.day, in: timeZone))
                            .font(MLType.staffBody)
                            .foregroundStyle(MLColor.ink)
                        if day.day == menu.today {
                            Text(AdminScreenCopy.today)
                                .font(MLType.secondary)
                                .foregroundStyle(MLColor.inkSecondary)
                        }
                    }
                    .frame(width: AdminMenuLayout.dayColumn, alignment: .leading)
                    ForEach(MealSlot.allCases, id: \.self) { slot in
                        dot(day, slot)
                            .frame(width: AdminMenuLayout.dotColumn)
                    }
                    Spacer(minLength: MLSpacing.s4)
                }
                .frame(minHeight: MLSize.staffButton)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AdminFormat.day(day.day, in: timeZone))
            if toCheck > 0, model.phase == .idle {
                CompactPillButton(title: AdminScreenCopy.check(toCheck)) { nav.push(.checkDay(day.day)) }
            }
            Button(action: open) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MLColor.inkSecondary)
                    .frame(width: MLSpacing.s24, height: MLSize.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)
        }
        .overlay(alignment: .top) { Rectangle().fill(MLColor.border).frame(height: 1) }
    }

    @ViewBuilder
    private func dot(_ day: MenuDay, _ slot: MealSlot) -> some View {
        if model.phase != .idle {
            Circle().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1, dash: [2, 2])).frame(width: 14, height: 14)
        } else if day.hasWordToCheck(slot) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 16))
                .foregroundStyle(MLColor.ink)
        } else {
            Circle().fill(MLColor.ink).frame(width: 14, height: 14)
        }
    }
}

enum AdminMenuLayout {
    static let dayColumn: CGFloat = 112
    static let dotColumn: CGFloat = 24
}

/// Check a day's hard words (A12_weekly_menu_check_thu_15).
@MainActor
@Observable
final class AdminDayEditViewModel {
    private(set) var state: LoadState<WeekMenu> = .idle
    private(set) var day: MenuDay?
    private(set) var earlier: [String] = []
    private(set) var isSaving = false
    private(set) var errorText: String?
    private(set) var copiedNote: String?
    var slot: MealSlot = .lunch
    var tellStudents = true

    private var undoStack: [MenuDay] = []
    private let date: Date
    private let more: any AdminMoreRepository
    private let role: Role

    init(date: Date, more: any AdminMoreRepository, role: Role) {
        self.date = date
        self.more = more
        self.role = role
    }

    var dishes: [MenuDish] { day?.meals[slot] ?? [] }
    var canUndo: Bool { !undoStack.isEmpty }
    var wordsToCheck: [(slot: MealSlot, dish: MenuDish)] {
        MealSlot.allCases.flatMap { slot in (day?.meals[slot] ?? []).filter(\.needsCheck).map { (slot, $0) } }
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            let menu = try await more.weekMenu()
            earlier = try await more.earlierDishes()
            if day == nil { day = menu.days.first { $0.day == date } }
            state = day == nil ? .failed(LoadFailure(RepositoryError.notFound)) : .loaded(menu)
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    private func edit(_ change: (inout [MenuDish]) -> Void) {
        guard var current = day else { return }
        undoStack.append(current)
        var rows = current.meals[slot] ?? []
        change(&rows)
        current.meals[slot] = rows
        day = current
    }

    func toggleHighlight(_ id: String) {
        edit { rows in
            if let index = rows.firstIndex(where: { $0.id == id }) { rows[index].isHighlight.toggle() }
        }
    }

    func toggleVeg(_ id: String) {
        edit { rows in
            if let index = rows.firstIndex(where: { $0.id == id }) { rows[index].isNonVeg.toggle() }
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        edit { $0.move(fromOffsets: source, toOffset: destination) }
    }

    func delete(_ id: String) {
        edit { $0.removeAll { $0.id == id } }
    }

    func add(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        edit { rows in
            guard !rows.contains(where: { $0.name == trimmed }) else { return }
            rows.append(MenuDish(id: trimmed, name: trimmed, isHighlight: false, isNonVeg: false, needsCheck: false, suggestions: [], isLimited: false))
        }
    }

    /// For a word on Check a day, which lists every meal at once.
    func toggle(_ change: (String) -> Void, id: String, in slot: MealSlot) {
        let previous = self.slot
        self.slot = slot
        change(id)
        self.slot = previous
    }

    func dish(_ id: String, in slot: MealSlot) -> MenuDish? {
        day?.meals[slot]?.first { $0.id == id }
    }

    func useWord(_ word: String, for id: String, in slot: MealSlot) {
        let previous = self.slot
        self.slot = slot
        edit { rows in
            if let index = rows.firstIndex(where: { $0.id == id }) {
                rows[index].name = word
                rows[index].needsCheck = false
            }
        }
        self.slot = previous
    }

    /// "Copy last Thursday": the seeded board stands in for last week, and the note says what came across.
    func copyLastWeek(sourceDay: String) async {
        do {
            let source = try await more.copySource(for: date, slot: slot)
            edit { $0 = source }
            copiedNote = AdminScreenCopy.copiedFrom(day: sourceDay, slot: MLFormat.mealSlot(slot).lowercased(), count: source.count,
                                                    kept: source.contains(where: \.needsCheck))
        } catch {
            errorText = AdminWriteError.text(error)
        }
    }

    func undo() {
        guard let last = undoStack.popLast() else { return }
        day = last
        copiedNote = nil
    }

    func suggestions(for text: String) -> [String] {
        let wanted = text.trimmingCharacters(in: .whitespaces)
        guard !wanted.isEmpty else { return [] }
        return Array(earlier.filter { $0.localizedCaseInsensitiveContains(wanted) }.prefix(3))
    }

    func save() async -> Bool {
        guard let day, !isSaving else { return false }
        isSaving = true
        errorText = nil
        defer { isSaving = false }
        do {
            _ = try await more.saveDay(day, by: role)
            undoStack = []
            return true
        } catch {
            errorText = AdminWriteError.text(error)
            return false
        }
    }
}

struct AdminCheckDayScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let date: Date
    let nav: AdminNav

    var body: some View {
        AdminCheckDayView(model: AdminDayEditViewModel(date: date, more: environment.repositories.adminMore, role: nav.context.account.role),
                          date: date, nav: nav)
    }
}

struct AdminCheckDayView: View {
    @State private var model: AdminDayEditViewModel
    let date: Date
    let nav: AdminNav

    @State private var words: [String: String] = [:]

    init(model: AdminDayEditViewModel, date: Date, nav: AdminNav) {
        _model = State(initialValue: model)
        self.date = date
        self.nav = nav
    }

    var body: some View {
        let rows = model.wordsToCheck
        AdminPageScaffold(title: AdminScreenCopy.checkDayTitle(AdminFormat.shortDay(date, in: nav.timeZone)),
                          subtitle: AdminScreenCopy.wordsHard(rows.count), onBack: nav.pop) {
            AsyncContentView(state: model.state, timeZone: nav.timeZone, retry: { await model.load() }) { _ in
                VStack(spacing: MLSpacing.s16) {
                    ForEach(rows, id: \.dish.id) { row in
                        AdminCard {
                            AdminLabel(text: AdminScreenCopy.weRead(MLFormat.mealSlot(row.slot)))
                            AdminTextField(placeholder: row.dish.name, text: binding(row.dish))
                                .overlay(alignment: .trailing) {
                                    Text(AdminScreenCopy.unsureMark)
                                        .font(MLType.monoSecondary)
                                        .foregroundStyle(MLColor.ink)
                                        .frame(width: 42, height: 32)
                                        .overlay(Capsule().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])))
                                        .padding(.trailing, MLSpacing.s12)
                                        .accessibilityHidden(true)
                                }
                            Toggle(AdminScreenCopy.highlightOnBoard, isOn: flag(row.dish, row.slot, \.isHighlight, model.toggleHighlight))
                                .toggleStyle(AdminSwitchStyle(isInk: true))
                                .font(MLType.staffBody)
                                .foregroundStyle(MLColor.ink)
                            Toggle(AdminScreenCopy.nonVeg, isOn: flag(row.dish, row.slot, \.isNonVeg, model.toggleVeg))
                                .toggleStyle(AdminSwitchStyle(isInk: true))
                                .font(MLType.staffBody)
                                .foregroundStyle(MLColor.ink)
                        }
                    }
                    if let error = model.errorText {
                        FieldErrorText(text: error)
                    }
                    InkActionButton(title: AdminScreenCopy.confirmWords(rows.count), isLoading: model.isSaving) {
                        Task {
                            for row in rows {
                                model.useWord(words[row.dish.id] ?? row.dish.name, for: row.dish.id, in: row.slot)
                            }
                            if await model.save() {
                                nav.toast(AdminScreenCopy.wordsConfirmed)
                                nav.pop()
                            }
                        }
                    }
                }
            }
        }
        .task { await model.load() }
    }

    private func binding(_ dish: MenuDish) -> Binding<String> {
        Binding(get: { words[dish.id] ?? dish.name }, set: { words[dish.id] = $0 })
    }

    private func flag(_ dish: MenuDish, _ slot: MealSlot, _ path: KeyPath<MenuDish, Bool>, _ change: @escaping (String) -> Void) -> Binding<Bool> {
        Binding(get: { model.dish(dish.id, in: slot)?[keyPath: path] ?? dish[keyPath: path] },
                set: { _ in model.toggle(change, id: dish.id, in: slot) })
    }
}

/// Edit a day (F04).
struct AdminEditDayScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let date: Date
    let nav: AdminNav

    var body: some View {
        AdminEditDayView(model: AdminDayEditViewModel(date: date, more: environment.repositories.adminMore, role: nav.context.account.role),
                         date: date, nav: nav)
    }
}

struct AdminEditDayView: View {
    @State private var model: AdminDayEditViewModel
    let date: Date
    let nav: AdminNav

    @State private var wordToCheck: MenuDish?
    @State private var isAddingDish = false

    init(model: AdminDayEditViewModel, date: Date, nav: AdminNav) {
        _model = State(initialValue: model)
        self.date = date
        self.nav = nav
    }

    private var timeZone: TimeZone { nav.timeZone }
    private var isCheckingWord: Binding<Bool> {
        Binding(get: { wordToCheck != nil }, set: { if !$0 { wordToCheck = nil } })
    }

    var body: some View {
        @Bindable var model = model
        // Read here, not only in the sheet: a value read only inside the sheet closure is stale on first show.
        let checking = wordToCheck
        ZStack {
            OrbitBackground()
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                AdminBackButton(action: nav.pop)
                ScreenTitleBlock(title: AdminFormat.day(date, in: timeZone),
                                 subtitle: AdminScreenCopy.editDaySubtitle(model.state.value?.range ?? AdminFormat.missing))
                AsyncContentView(state: model.state, timeZone: timeZone, retry: { await model.load() }) { menu in
                    editor(menu)
                }
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.bottom, MLSpacing.s16)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await model.load() }
        .mlSheet(isPresented: isCheckingWord) {
            if let dish = checking {
                AdminCheckWordSheet(dish: dish, slot: MLFormat.mealSlot(model.slot), day: AdminFormat.day(date, in: timeZone), onClose: { wordToCheck = nil }) { word in
                    model.useWord(word, for: dish.id, in: model.slot)
                    wordToCheck = nil
                }
            }
        }
        .mlSheet(isPresented: $isAddingDish) {
            AdminAddDishSheet(model: model, slot: MLFormat.mealSlot(model.slot), day: AdminFormat.day(date, in: timeZone)) { isAddingDish = false }
        }
    }

    private func editor(_ menu: WeekMenu) -> some View {
        @Bindable var model = model
        let weekday = AdminFormat.weekday(date, in: timeZone)
        return VStack(alignment: .leading, spacing: MLSpacing.s8) {
            SegmentedChoice(options: MealSlot.allCases.map { .init(value: $0, title: MLFormat.mealSlot($0)) }, selection: $model.slot)
            HStack {
                TextLinkButton(title: AdminScreenCopy.copyLast(weekday)) {
                    Task { await model.copyLastWeek(sourceDay: AdminFormat.day(menu.copySourceDay, in: timeZone)) }
                }
                Spacer()
                TextLinkButton(title: AdminScreenCopy.undo) { model.undo() }
                    .disabled(!model.canUndo)
                    .opacity(model.canUndo ? 1 : 0.5)
            }
            if let note = model.copiedNote {
                Text(note)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.ink)
                    .padding(MLSpacing.s12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.fillQuiet))
            }
            HStack {
                TextLinkButton(title: AdminScreenCopy.addADish) { isAddingDish = true }
                Spacer()
                Text(AdminScreenCopy.highlightAndVeg)
                    .font(MLType.meta)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            List {
                ForEach(model.dishes) { dish in
                    dishRow(dish)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparatorTint(MLColor.border)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                model.delete(dish.id)
                                nav.toast(AdminScreenCopy.deleted(dish.name))
                            } label: {
                                Label(AdminScreenCopy.delete, systemImage: "trash")
                            }
                            .tint(MLColor.ink)
                        }
                }
                .onMove { model.move(from: $0, to: $1) }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            Toggle(AdminScreenCopy.tellStudentsChange, isOn: $model.tellStudents)
                .toggleStyle(AdminSwitchStyle())
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.ink)
            if let error = model.errorText {
                FieldErrorText(text: error)
            }
            InkActionButton(title: AdminScreenCopy.saveChanges, isLoading: model.isSaving) {
                let told = model.tellStudents
                Task {
                    if await model.save() {
                        nav.toast(told ? AdminScreenCopy.savedTold : AdminScreenCopy.saved)
                    }
                }
            }
        }
    }

    private func dishRow(_ dish: MenuDish) -> some View {
        HStack(spacing: MLSpacing.s8) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 17))
                .foregroundStyle(MLColor.inkSecondary)
                .accessibilityHidden(true)
            Text(dish.name)
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.ink)
            Spacer(minLength: MLSpacing.s4)
            if dish.needsCheck {
                iconButton("exclamationmark.circle", label: AdminScreenCopy.checkThisWord, isOn: false) { wordToCheck = dish }
            }
            iconButton(dish.isHighlight ? "star.fill" : "star", label: AdminScreenCopy.highlightOnBoard, isOn: dish.isHighlight) {
                model.toggleHighlight(dish.id)
            }
            Button {
                model.toggleVeg(dish.id)
            } label: {
                AdminVegMark(isNonVeg: dish.isNonVeg)
                    .frame(width: MLSize.hit, height: MLSize.hit)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(dish.isNonVeg ? AdminScreenCopy.nonVeg : AdminScreenCopy.veg)
        }
        .frame(minHeight: MLSize.hit + MLSpacing.s8)
        .accessibilityActions {
            Button(AdminScreenCopy.remove) { model.delete(dish.id) }
        }
    }

    private func iconButton(_ symbol: String, label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .foregroundStyle(isOn ? MLColor.onHero : MLColor.ink)
                .frame(width: MLSize.hit, height: MLSize.hit)
                .background(Circle().fill(isOn ? MLColor.ink : Color.clear).padding(5))
                .overlay {
                    if !isOn, symbol == "star" {
                        Circle().stroke(MLColor.inkSecondary, lineWidth: 1).padding(7)
                    }
                }
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(label)
    }
}

struct AdminCheckWordSheet: View {
    let dish: MenuDish
    let slot: String
    let day: String
    let onClose: () -> Void
    let onUse: (String) -> Void

    @State private var word: String

    init(dish: MenuDish, slot: String, day: String, onClose: @escaping () -> Void, onUse: @escaping (String) -> Void) {
        self.dish = dish
        self.slot = slot
        self.day = day
        self.onClose = onClose
        self.onUse = onUse
        _word = State(initialValue: dish.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: AdminScreenCopy.checkThisWord, subtitle: AdminScreenCopy.checkWordDetail(slot: slot, day: day), onClose: onClose)
            AdminTextField(placeholder: dish.name, text: $word)
            if !dish.suggestions.isEmpty {
                AdminLabel(text: AdminScreenCopy.didYouMean)
                AdminFlow {
                    ForEach(dish.suggestions, id: \.self) { suggestion in
                        ChoiceChip(title: suggestion, isSelected: word == suggestion) { word = suggestion }
                    }
                }
            }
            InkActionButton(title: AdminScreenCopy.useThisWord) { onUse(word) }
        }
    }
}

struct AdminAddDishSheet: View {
    let model: AdminDayEditViewModel
    let slot: String
    let day: String
    let onClose: () -> Void

    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: AdminScreenCopy.addADish, subtitle: AdminScreenCopy.addDishDetail(slot: slot, day: day), onClose: onClose)
            AdminTextField(placeholder: AdminScreenCopy.dishName, text: $name)
            let suggestions = model.suggestions(for: name)
            if !suggestions.isEmpty {
                AdminLabel(text: AdminScreenCopy.fromEarlierWeeks)
                AdminFlow {
                    ForEach(suggestions, id: \.self) { suggestion in
                        ChoiceChip(title: suggestion, isSelected: name == suggestion) { name = suggestion }
                    }
                }
            }
            InkActionButton(title: AdminScreenCopy.add) {
                model.add(name)
                onClose()
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}

enum AdminDishSuggestions {
    /// Dishes served before that share the dish's last word, as "Dal Tadka" brings up other dals on F05.
    static func similar(to dish: String, in earlier: [String]) -> [String] {
        let words = dish.split(separator: " ").map(String.init)
        return Array(earlier.filter { name in name != dish && words.contains { name.contains($0) } }.prefix(3))
    }
}

/// Change today's dinner (F05): pick a change, then preview what students see.
struct AdminDinnerChangeSheet: View {
    private enum Step: Equatable {
        case choose
        case swapPick
        case swapReplace(String)
        case special
        case removePick
        case removeConfirm(String)
        case preview(QuickChange)
    }

    let model: AdminMenuViewModel
    let today: MenuDay
    let nav: AdminNav
    let onClose: () -> Void

    @State private var step: Step = .choose
    @State private var tellStudents = true
    @State private var text = ""
    @State private var isLimited = true
    @State private var isNonVeg = true
    @State private var totalStudents: Int?
    @State private var earlier: [String] = []
    @Environment(AppEnvironment.self) private var environment

    private var dishes: [MenuDish] { today.meals[.dinner] ?? [] }
    private var dayName: String { AdminFormat.day(today.day, in: nav.timeZone) }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            switch step {
            case .choose: choose
            case .swapPick: pick(AdminScreenCopy.swapADish) { dish in text = ""; step = .swapReplace(dish) }
            case .swapReplace(let dish): replace(dish)
            case .special: special
            case .removePick: pick(AdminScreenCopy.removeADish) { step = .removeConfirm($0) }
            case .removeConfirm(let dish): confirmRemove(dish)
            case .preview(let change): preview(change)
            }
            if let error = model.errorText {
                FieldErrorText(text: error)
            }
        }
        .task {
            totalStudents = (try? await environment.repositories.adminStudents.studentsOverview())?.totalStudents
            earlier = (try? await environment.repositories.adminMore.earlierDishes()) ?? []
        }
    }

    private var choose: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: AdminScreenCopy.changeTodaysDinner, onClose: onClose)
            optionCard("arrow.left.arrow.right", AdminScreenCopy.swapADish, AdminScreenCopy.swapDetail) { step = .swapPick }
            optionCard("plus", AdminScreenCopy.addASpecial, AdminScreenCopy.specialDetail, isLime: true) { text = ""; step = .special }
            optionCard("minus", AdminScreenCopy.removeADish, AdminScreenCopy.removeDetail) { step = .removePick }
            Toggle(AdminScreenCopy.tellStudents, isOn: $tellStudents)
                .toggleStyle(AdminSwitchStyle())
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
        }
    }

    /// A quiet filled card, as drawn. The shared `IconCardRow` has no fill or lime mark.
    private func optionCard(_ symbol: String, _ title: String, _ detail: String, isLime: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s12) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MLColor.ink)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(isLime ? MLColor.lime : MLColor.surface))
                    .overlay(Circle().stroke(isLime ? MLColor.ink : Color.clear, lineWidth: 1.5))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.ink)
                    Text(detail)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(MLSpacing.s12)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.fillQuiet))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func pick(_ title: String, onPick: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: title, subtitle: AdminScreenCopy.whichDish(dayName), onClose: onClose)
            ForEach(dishes) { dish in
                QuietRow(title: dish.name) { onPick(dish.name) }
            }
        }
    }

    private func replace(_ dish: String) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: AdminScreenCopy.replace(dish), subtitle: AdminScreenCopy.withWhich, onClose: onClose)
            AdminTextField(placeholder: AdminScreenCopy.dishName, text: $text)
            let similar = AdminDishSuggestions.similar(to: dish, in: earlier)
            if !similar.isEmpty {
                AdminLabel(text: AdminScreenCopy.fromEarlierWeeks)
                AdminFlow {
                    ForEach(similar, id: \.self) { suggestion in
                        ChoiceChip(title: suggestion, isSelected: text == suggestion) { text = suggestion }
                    }
                }
            }
            InkActionButton(title: AdminScreenCopy.swap) { finish(.swap(dish: dish, with: text)) }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var special: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: AdminScreenCopy.addASpecial, subtitle: AdminScreenCopy.name, onClose: onClose)
            AdminTextField(placeholder: AdminScreenCopy.dishName, text: $text)
            Toggle(AdminScreenCopy.limited, isOn: $isLimited)
                .toggleStyle(AdminSwitchStyle())
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
            AdminNote(text: AdminScreenCopy.limitedNote)
            SegmentedChoice(options: [.init(value: false, title: AdminScreenCopy.veg), .init(value: true, title: AdminScreenCopy.nonVeg)], selection: $isNonVeg)
            InkActionButton(title: AdminScreenCopy.addSpecial) {
                finish(.addSpecial(name: text.trimmingCharacters(in: .whitespaces), isLimited: isLimited, isNonVeg: isNonVeg))
            }
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func confirmRemove(_ dish: String) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: AdminScreenCopy.removeThisDish, onClose: onClose)
            Text(AdminScreenCopy.removeBody(dish))
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.ink)
            HStack(spacing: MLSpacing.s12) {
                OutlineActionButton(title: AdminScreenCopy.keepIt) { step = .choose }
                InkActionButton(title: AdminScreenCopy.remove) { finish(.remove(dish: dish)) }
            }
        }
    }

    private func finish(_ change: QuickChange) {
        if tellStudents {
            step = .preview(change)
        } else {
            Task {
                if await model.apply(change) {
                    onClose()
                    nav.toast(AdminScreenCopy.dinnerChangedSaved)
                }
            }
        }
    }

    private func preview(_ change: QuickChange) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: AdminScreenCopy.sendToStudents, subtitle: AdminScreenCopy.studentsSee, onClose: onClose)
            AdminCard {
                HStack(alignment: .top, spacing: MLSpacing.s12) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(MLColor.onHero)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(MLColor.ink))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: MLSpacing.s4) {
                        Text(AdminScreenCopy.dinnerChanged)
                            .font(MLType.staffPrimary)
                            .foregroundStyle(MLColor.ink)
                        Text(AdminScreenCopy.changeLine(change))
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                    Spacer()
                    Text(AdminScreenCopy.now)
                        .font(MLType.secondary)
                        .foregroundStyle(MLColor.inkSecondary)
                }
            }
            AdminNote(text: AdminScreenCopy.everyoneGets(AdminFormat.count(totalStudents)))
            InkActionButton(title: AdminScreenCopy.send) {
                Task {
                    if await model.apply(change) {
                        onClose()
                        nav.toast(AdminScreenCopy.sentDinner)
                    }
                }
            }
        }
    }
}
