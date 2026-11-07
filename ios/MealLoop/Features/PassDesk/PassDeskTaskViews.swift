import SwiftUI

/// The shared frame of a pushed Pass Desk page: backdrop, Back, title, secondary line.
struct PassDeskPage<Content: View>: View {
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
                .padding(.bottom, MLSpacing.s32)
            }
        }
    }
}

/// Look up a student (P17). Status only: it says so, and it cannot record.
struct PassDeskLookUpView: View {
    @State private var model: PassDeskLookUpModel
    let session: StaffSession
    let meal: Meal
    let onBack: () -> Void

    private var mealName: String { MLFormat.mealSlot(meal.slot) }

    init(model: PassDeskLookUpModel, session: StaffSession, meal: Meal, onBack: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.session = session
        self.meal = meal
        self.onBack = onBack
    }

    var body: some View {
        PassDeskPage(title: PassDeskCopy.lookUp, subtitle: PassDeskCopy.lookUpSubtitle, onBack: onBack) {
            Text(PassDeskCopy.lastFourDigits)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            StaffDigitBoxes(entry: model.entry, accessibilityTitle: PassDeskCopy.lastFourDigits)
            if case .idle = model.state {
                KeyPad(keyHeight: PassDeskLayout.pageKeyHeight) { digit in
                    Task { await model.type(digit) }
                } onDelete: {
                    model.deleteLast()
                }
            } else {
                AsyncContentView(state: model.state, timeZone: session.mess.timeZone, retry: { model.reset() }) { lookup in
                    result(lookup)
                }
            }
        }
        .staffPinnedFooter {
            if !isIdle {
                InkActionButton(title: PassDeskCopy.lookUpAnother) { model.reset() }
            }
        }
    }

    private var isIdle: Bool {
        if case .idle = model.state { return true }
        return false
    }

    @ViewBuilder
    private func result(_ lookup: SpecialPassLookup) -> some View {
        let timeZone = session.mess.timeZone
        let name = PassDeskCopy.specialName(mealName)
        switch lookup {
        case .notFound:
            FieldErrorText(text: PassDeskCopy.noStudent(model.entry.text, mess: session.mess.name))
        case .valid(let holder, _):
            card(holder, status: StaffStatusPill(text: PassDeskCopy.valid, style: .lime),
                 rows: [FactRow(label: PassDeskCopy.pass, value: name, isMono: false),
                        FactRow(label: PassDeskCopy.used, value: PassDeskCopy.notYet, isMono: false)],
                 note: PassDeskCopy.notAnEntry)
        case .used(let holder, let at, _):
            card(holder, status: StaffStatusPill(text: PassDeskCopy.used, style: .outline),
                 rows: [FactRow(label: PassDeskCopy.pass, value: name, isMono: false),
                        FactRow(label: PassDeskCopy.used, value: MLFormat.time(at, in: timeZone))],
                 note: PassDeskCopy.notAnEntry)
        case .noPass(let holder):
            card(holder, status: StaffStatusPill(text: PassDeskCopy.noPass, style: .dashed),
                 rows: [FactRow(label: PassDeskCopy.pass, value: PassDeskCopy.noneFor(mealName), isMono: false)],
                 note: PassDeskCopy.regularMealNotEntry())
        case .wrongMeal(let holder, let slot):
            card(holder, status: StaffStatusPill(text: PassDeskCopy.wrongMeal, style: .outline),
                 rows: [FactRow(label: PassDeskCopy.pass, value: PassDeskCopy.specialName(MLFormat.mealSlot(slot)), isMono: false),
                        FactRow(label: PassDeskCopy.used, value: PassDeskCopy.notYet, isMono: false)],
                 note: PassDeskCopy.passIsForNotEntry(MLFormat.mealSlot(slot)))
        }
    }

    /// One card as the frame draws it: holder and pill, a hairline, then the facts.
    private func card(_ holder: SpecialPassHolder, status: StaffStatusPill, rows: [FactRow], note: String) -> some View {
        VStack(spacing: MLSpacing.s12) {
            VStack(spacing: 0) {
                HStack(spacing: MLSpacing.s8) {
                    PassDeskHolderRow(holder: holder, detail: session.mess.name)
                    status
                }
                .padding(.bottom, MLSpacing.s12)
                ForEach(rows) { row in
                    Rectangle().fill(MLColor.border).frame(height: 1)
                    HStack {
                        Text(row.label)
                            .font(MLType.staffBody)
                            .foregroundStyle(MLColor.inkSecondary)
                        Spacer(minLength: MLSpacing.s8)
                        Text(row.value ?? "—")
                            .font(row.isMono ? MLType.monoBody : MLType.staffPrimary)
                            .foregroundStyle(MLColor.ink)
                    }
                    .frame(minHeight: 50)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, MLSpacing.s16)
            .padding(.top, MLSpacing.s16)
            .padding(.bottom, MLSpacing.s4)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
            Text(note)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }
}

/// Request a new pass (P09). "Send request" goes to the admin pass-exception flow; nothing here approves anything.
struct PassDeskRequestView: View {
    @State private var form: PassDeskRequestForm
    @State private var toast: String?
    let digits: String?
    let onBack: () -> Void
    /// Runs after the toast has shown.
    let onSent: () -> Void

    init(form: PassDeskRequestForm, digits: String?, onBack: @escaping () -> Void, onSent: @escaping () -> Void) {
        _form = State(initialValue: form)
        self.digits = digits
        self.onBack = onBack
        self.onSent = onSent
    }

    var body: some View {
        @Bindable var form = form
        PassDeskPage(title: PassDeskCopy.requestNewPass, subtitle: PassDeskCopy.requestSubtitle, onBack: onBack) {
            Text(PassDeskCopy.lastFourDigits)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            StaffDigitBoxes(entry: form.entry, accessibilityTitle: PassDeskCopy.lastFourDigits)
            if let holder = form.holder {
                PassDeskHolderRow(holder: holder, detail: form.messName)
                    .padding(MLSpacing.s16)
                    .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
                Text(PassDeskCopy.why)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .accessibilityAddTraits(.isHeader)
                StaffWrapLayout {
                    ForEach(PassReissueReason.allCases, id: \.self) { reason in
                        StaffChip(title: PassDeskCopy.reason(reason), isSelected: form.reason == reason) {
                            form.reason = reason
                        }
                    }
                }
                if let problem = form.problem {
                    FieldErrorText(text: problem)
                }
                Text(PassDeskCopy.passAdminApproves)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            } else {
                if let problem = form.problem {
                    FieldErrorText(text: problem)
                }
                KeyPad(keyHeight: PassDeskLayout.pageKeyHeight) { digit in
                    Task { await form.type(digit) }
                } onDelete: {
                    form.deleteLast()
                }
            }
        }
        .staffPinnedFooter {
            if form.holder != nil {
                InkActionButton(title: PassDeskCopy.sendRequest, isLoading: form.isSending) {
                    Task {
                        if await form.send() {
                            toast = PassDeskCopy.requestSent
                            try? await Task.sleep(for: .seconds(1))
                            onSent()
                        }
                    }
                }
                .disabled(!form.canSend)
            }
        }
        .mlToast(message: $toast, bottomInset: PassDeskLayout.footerAboveTabBar)
        .task {
            if let digits, form.entry.digits.isEmpty { await form.prefill(digits) }
        }
    }
}

/// New pass requests (P10). Approved and Done are different words and different pills: Approved is never Done.
struct PassDeskRequestsView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: PassDeskRequestsModel
    let session: StaffSession
    let mealName: String?
    let onBack: () -> Void

    init(model: PassDeskRequestsModel, session: StaffSession, mealName: String?, onBack: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.session = session
        self.mealName = mealName
        self.onBack = onBack
    }

    var body: some View {
        PassDeskPage(title: PassDeskCopy.newPassRequests,
                     subtitle: PassDeskCopy.requestsSubtitle(meal: mealName, mess: session.mess.name), onBack: onBack) {
            AsyncContentView(state: model.state, emptyTitle: PassDeskCopy.noRequests, timeZone: session.mess.timeZone,
                             retry: { await model.load() }) { requests in
                VStack(spacing: 0) {
                    Rectangle().fill(MLColor.border).frame(height: 1)
                    ForEach(requests) { request in
                        row(request)
                    }
                }
                Text(PassDeskCopy.requestsNote)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, MLSpacing.s16)
            }
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
    }

    private func row(_ request: PassReissueRequest) -> some View {
        HStack(spacing: MLSpacing.s12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(PassDeskCopy.holderLine(request.holder))
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                Text(detail(request))
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            Spacer(minLength: MLSpacing.s8)
            StaffStatusPill(text: PassDeskCopy.status(request.status), style: pill(request.status))
        }
        .padding(.vertical, MLSpacing.s12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private func detail(_ request: PassReissueRequest) -> String {
        let time = request.updatedAt.map { MLFormat.time($0, in: session.mess.timeZone) } ?? "—"
        switch request.status {
        case .waiting: return request.reason.map { PassDeskCopy.sent(time, reason: PassDeskCopy.reason($0)) } ?? PassDeskCopy.sent(time)
        case .approved: return PassDeskCopy.approvedAt(time)
        case .done: return PassDeskCopy.issuedAt(time)
        case .rejected: return PassDeskCopy.rejectedLine
        }
    }

    /// Done alone is lime: Approved is never drawn as Done.
    private func pill(_ status: PassReissueStatus) -> StaffStatusPill.Style {
        switch status {
        case .waiting: return .dashed
        case .approved, .rejected: return .outline
        case .done: return .lime
        }
    }
}

/// Report a problem (P11) and Which food is short? (P12).
struct PassDeskReportProblemView: View {
    let log: PassDeskProblemLog
    let session: StaffSession
    let meal: Meal?
    let onBack: () -> Void
    /// Runs after the toast has shown.
    let onSent: () -> Void

    @State private var toast: String?
    @State private var didFail = false
    @State private var isChoosingFood = false

    var body: some View {
        PassDeskPage(title: PassDeskCopy.reportProblem, subtitle: PassDeskCopy.pickOne, onBack: onBack) {
            ForEach(PassDeskProblemKind.allCases) { kind in
                StaffReportRow(symbol: kind.symbol, title: kind.title, detail: kind.detail, isHighlighted: kind == .foodShort) {
                    Task { await choose(kind) }
                }
            }
            if didFail {
                FieldErrorText(text: PassDeskCopy.couldNotSend)
            }
            Text(PassDeskCopy.sentOnTap)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .frame(maxWidth: .infinity)
        }
        .disabled(log.isSending || toast != nil)
        .mlToast(message: $toast, bottomInset: MLSpacing.s32)
        .mlSheet(isPresented: $isChoosingFood) {
            PassDeskFoodSheet(log: log, meal: meal, supervisorName: session.supervisorName,
                              onClose: { isChoosingFood = false }) { dish in
                Task { await sendFood(dish) }
            }
        }
    }

    private func choose(_ kind: PassDeskProblemKind) async {
        didFail = false
        if kind == .foodShort {
            isChoosingFood = true
            return
        }
        await finish(await log.report(kind), toastText: PassDeskCopy.savedToast)
    }

    private func sendFood(_ dish: String) async {
        guard let meal else { return }
        let didSend = await log.reportFoodShort(dish, meal: meal.id)
        isChoosingFood = false
        await finish(didSend, toastText: PassDeskCopy.foodShortSent(session.supervisorName))
    }

    private func finish(_ didSend: Bool, toastText: String) async {
        guard didSend else {
            didFail = true
            return
        }
        toast = toastText
        try? await Task.sleep(for: .seconds(1))
        onSent()
    }
}

/// Which food is short? (P12). Its own view, loading its own dishes: state read only inside a sheet's closure is not
/// a dependency of the parent's body, so the sheet would open with the stale empty list.
struct PassDeskFoodSheet: View {
    let log: PassDeskProblemLog
    let meal: Meal?
    let supervisorName: String
    let onClose: () -> Void
    let onSend: (String) -> Void

    @State private var dishes: [String] = []
    @State private var chosenDish: String?

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: PassDeskCopy.whichFood, onClose: onClose)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MLSpacing.s8) {
                ForEach(dishes + [PassDeskCopy.somethingElse], id: \.self) { dish in
                    ChoiceChip(title: dish, isSelected: chosenDish == dish) { chosenDish = dish }
                }
            }
            InkActionButton(title: PassDeskCopy.sendToKitchen, isLoading: log.isSending) {
                if let chosenDish { onSend(chosenDish) }
            }
            .disabled(chosenDish == nil)
            Text(PassDeskCopy.kitchenGetsIt(supervisorName))
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .frame(maxWidth: .infinity)
        }
        .task {
            if let meal { dishes = await log.dishes(for: meal.id) }
        }
    }
}

/// Open problems. Each stays Waiting, as a dashed pill: nothing reports back yet, and "seen" is never made up.
struct PassDeskOpenProblemsView: View {
    let log: PassDeskProblemLog
    let session: StaffSession
    let mealName: String?
    let onBack: () -> Void
    let onReport: () -> Void

    var body: some View {
        PassDeskPage(title: PassDeskCopy.openProblems,
                     subtitle: PassDeskCopy.requestsSubtitle(meal: mealName, mess: session.mess.name), onBack: onBack) {
            if log.problems.isEmpty {
                StateBlock(symbol: "checkmark", title: PassDeskCopy.noOpenProblems, message: PassDeskCopy.noOpenProblemsDetail)
                    .padding(.top, PassDeskLayout.noProblemsTop)
            } else {
                VStack(spacing: 0) {
                    ForEach(log.problems) { problem in
                        row(problem)
                    }
                }
                Text(PassDeskCopy.savedOnPhone)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .staffPinnedFooter(bottomInset: PassDeskLayout.footerAboveTabBar) {
            InkActionButton(title: PassDeskCopy.reportProblem, action: onReport)
        }
    }

    private func row(_ problem: PassDeskProblem) -> some View {
        HStack(spacing: MLSpacing.s12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(problem.title)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                HStack(spacing: MLSpacing.s4) {
                    Text(problem.dish.map { "\($0) ·" } ?? PassDeskCopy.savedLine).font(MLType.body)
                    Text(MLFormat.time(problem.sentAt, in: session.mess.timeZone)).font(MLType.monoSecondary)
                }
                .foregroundStyle(MLColor.inkSecondary)
            }
            Spacer(minLength: MLSpacing.s8)
            StaffStatusPill(text: PassDeskCopy.waiting, style: .dashed)
        }
        .padding(.vertical, MLSpacing.s12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
