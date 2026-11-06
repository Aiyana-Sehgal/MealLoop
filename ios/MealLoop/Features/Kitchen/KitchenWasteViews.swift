import SwiftUI

/// How one measurement reads. "0 kg · none left" and "not made" are distinct, and a missing value is never a number.
enum KitchenWasteText {
    static func value(_ row: DishLeftover) -> String? {
        switch row.measurement {
        case .entered(let value): return KitchenFormat.quantity(value, row.unit)
        case .noneLeft: return KitchenFormat.quantity(0, row.unit)
        case .notMade, .notEntered: return nil
        }
    }

    static func plate(_ plate: PlateWasteMeasurement) -> String? {
        plate.measuredKilograms.map { KitchenFormat.quantity($0, .kilograms) }
    }

    static func enterTitle(_ unit: WasteUnit) -> String {
        KitchenCopy.enter(unit == .pieces ? "pieces" : unit.symbol)
    }
}

/// Record waste (K06), after the meal only. Also Edit report, inside the six hours.
struct KitchenRecordWasteView: View {
    @State private var model: KitchenWasteViewModel
    let sos: KitchenSOSViewModel
    let onOpenSOS: () -> Void
    let onToast: (String) -> Void
    let onBack: () -> Void
    let onSaved: (WasteReport) -> Void

    @State private var field: KitchenWasteField?
    @State private var isAddingDish = false
    @State private var isChecking = false
    @State private var isConfirmingDraft = false

    init(model: KitchenWasteViewModel, sos: KitchenSOSViewModel, onOpenSOS: @escaping () -> Void, onToast: @escaping (String) -> Void,
         onBack: @escaping () -> Void, onSaved: @escaping (WasteReport) -> Void) {
        _model = State(initialValue: model)
        self.sos = sos
        self.onOpenSOS = onOpenSOS
        self.onToast = onToast
        self.onBack = onBack
        self.onSaved = onSaved
    }

    private var timeZone: TimeZone { model.session.mess.timeZone }
    private var mealName: String { MLFormat.mealSlot(model.meal.slot) }

    var body: some View {
        ZStack(alignment: .bottom) {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    BackButton(action: leave)
                    ScreenTitleBlock(title: model.isEditingRecorded ? KitchenCopy.editReport : KitchenCopy.recordWaste,
                                     subtitle: KitchenCopy.wasteSubtitle(meal: mealName, mess: model.session.mess.name,
                                                                         day: KitchenFormat.dayLine(model.meal.startsAt, in: timeZone)))
                    AsyncContentView(state: model.state, timeZone: timeZone, retry: { await model.load() }) { report in
                        rows(report)
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, KitchenLayout.scrollBottomInset)
            }
            if model.report != nil {
                actions
            }
        }
        .overlay(alignment: .topTrailing) {
            if let current = sos.current {
                SOSEdgeTab(count: sos.cases.count, isClaimedByYou: sos.isClaimedByYou,
                           claimedStatus: KitchenCopy.tabChecking, action: onOpenSOS)
                    .padding(.top, MLSize.avatar + MLSpacing.s24)
                    .id(current.id)
            }
        }
        .task { await model.load() }
        // Open follows `field` itself: with a separate flag the sheet could render before the field arrived, and be blank.
        .mlSheet(isPresented: Binding(get: { field != nil }, set: { if !$0 { field = nil } })) {
            if let field {
                KitchenQuantitySheet(model: model, field: field) { self.field = nil }
            }
        }
        .mlSheet(isPresented: $isAddingDish) {
            KitchenAddDishSheet(onClose: { isAddingDish = false }) { name, unit in
                model.addDish(name: name, unit: unit)
                isAddingDish = false
            }
        }
        .mlSheet(isPresented: $isChecking) {
            KitchenCheckSheet(model: model, onClose: { isChecking = false }) { report in
                isChecking = false
                onSaved(report)
            }
        }
        .mlConfirmDialog(isPresented: $isConfirmingDraft,
                         content: ConfirmDialogContent(title: KitchenCopy.saveThisAsDraft,
                                                       detail: KitchenCopy.draftPromptDetail(model.lastEntered),
                                                       cancelTitle: KitchenCopy.keepEditing, actionTitle: KitchenCopy.saveDraft),
                         isWorking: model.isSaving) {
            Task {
                let stored = await model.saveDraft()
                isConfirmingDraft = false
                if stored { onBack() }
            }
        }
    }

    private func leave() {
        if model.isDirty, !model.isEditingRecorded {
            isConfirmingDraft = true
        } else {
            onBack()
        }
    }

    private func open(_ target: KitchenWasteField) {
        field = target
    }

    private func rows(_ report: WasteReport) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Text(KitchenCopy.done(model.doneDishes, of: model.totalDishes))
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.inkSecondary)
            Text(KitchenCopy.foodLeftOver)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            VStack(spacing: 0) {
                Rectangle().fill(MLColor.border).frame(height: 1)
                ForEach(report.leftovers) { row in
                    Button { open(.dish(row.dishID)) } label: { dishRow(row) }
                        .buttonStyle(.plain)
                    Rectangle().fill(MLColor.border).frame(height: 1)
                }
            }
            TextLinkButton(title: KitchenCopy.addADish) { isAddingDish = true }
            Button { open(.plate) } label: { plateRow(report.plateWaste) }
                .buttonStyle(.plain)
            if let error = model.saveError {
                FieldErrorText(text: error)
            }
        }
    }

    private func dishRow(_ row: DishLeftover) -> some View {
        HStack(spacing: MLSpacing.s8) {
            Text(row.dishName)
                .font(MLType.staffPrimary)
                .foregroundStyle(row.measurement == .notMade ? MLColor.inkSecondary : MLColor.ink)
            Spacer(minLength: MLSpacing.s8)
            switch row.measurement {
            case .entered:
                value(KitchenWasteText.value(row))
            case .noneLeft:
                Image(systemName: "checkmark")
                    .font(MLType.meta)
                    .foregroundStyle(MLColor.onLime)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(MLColor.lime))
                    .overlay(Circle().stroke(MLColor.limeOutline, lineWidth: 1))
                    .accessibilityHidden(true)
                Text(KitchenCopy.noneLeft).font(MLType.body).foregroundStyle(MLColor.ink)
                value(KitchenWasteText.value(row))
            case .notMade:
                Text(KitchenCopy.notMade).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            case .notEntered:
                enterPill(KitchenWasteText.enterTitle(row.unit))
            }
        }
        .frame(minHeight: MLSize.staffButton)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func plateRow(_ plate: PlateWasteMeasurement) -> some View {
        HStack {
            Text(KitchenCopy.plateWaste).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
            Spacer(minLength: MLSpacing.s8)
            if let text = KitchenWasteText.plate(plate) {
                value(text)
            } else {
                enterPill(KitchenWasteText.enterTitle(.kilograms))
            }
        }
        .padding(MLSpacing.s16)
        .frame(minHeight: MLSize.staffButton)
        .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }

    private func value(_ text: String?) -> some View {
        Text(text ?? "—").font(MLType.monoBody).foregroundStyle(MLColor.ink)
    }

    private func enterPill(_ title: String) -> some View {
        Text(title)
            .font(MLType.body)
            .foregroundStyle(MLColor.ink)
            .padding(.horizontal, MLSpacing.s16)
            .frame(minHeight: MLSize.hit)
            .background(Capsule().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
    }

    private var actions: some View {
        HStack(spacing: MLSpacing.s8) {
            if !model.isEditingRecorded {
                OutlineActionButton(title: KitchenCopy.saveDraft) {
                    Task {
                        if await model.saveDraft() { onToast(KitchenCopy.draftSaved) }
                    }
                }
            }
            InkActionButton(title: KitchenCopy.reviewAndSave) { isChecking = true }
        }
        .padding(MLSpacing.s8)
        .background(Capsule().fill(MLColor.surface))
        .overlay(Capsule().stroke(MLColor.border, lineWidth: 1))
        .padding(.horizontal, MLSpacing.s16)
        .padding(.bottom, MLSpacing.s8)
    }
}

/// Enter a quantity (K07), in the dish's own unit. The plate total has no None left or Not made.
struct KitchenQuantitySheet: View {
    let model: KitchenWasteViewModel
    let field: KitchenWasteField
    let onClose: () -> Void

    @State private var input: KitchenQuantityInput
    @State private var showsError = false

    init(model: KitchenWasteViewModel, field: KitchenWasteField, onClose: @escaping () -> Void) {
        self.model = model
        self.field = field
        self.onClose = onClose
        var start: Double?
        var unit = WasteUnit.kilograms
        switch field {
        case .dish(let id):
            if let row = model.leftover(id) {
                unit = row.unit
                if case .entered(let value) = row.measurement { start = value }
            }
        case .plate:
            start = model.report?.plateWaste.measuredKilograms
        }
        _input = State(initialValue: KitchenQuantityInput(unit: unit, value: start))
    }

    private var dishID: DishID? {
        if case .dish(let id) = field { return id }
        return nil
    }

    private var title: String {
        dishID.flatMap { model.leftover($0)?.dishName } ?? KitchenCopy.plateWaste
    }

    private var unitName: String { input.unit == .pieces ? "pieces" : input.unit.symbol }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: title,
                        subtitle: dishID == nil ? KitchenCopy.plateWasteDetail : KitchenCopy.leftOverIn(unitName),
                        onClose: onClose)
            HStack(alignment: .firstTextBaseline) {
                Text(input.text.isEmpty ? "—" : input.text)
                    .font(MLType.heroNumber)
                    .foregroundStyle(MLColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                Text(unitName).font(MLType.monoBody).foregroundStyle(MLColor.inkSecondary)
            }
            .padding(MLSpacing.s16)
            .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.fillQuiet))
            .accessibilityElement(children: .combine)
            if showsError {
                FieldErrorText(text: KitchenCopy.enterNumberUpTo(input.limitText))
            } else {
                Text(KitchenCopy.upTo(input.limitText, unit: unitName))
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            if let dishID {
                HStack(spacing: MLSpacing.s12) {
                    OutlineActionButton(title: KitchenCopy.noneLeft) {
                        model.set(.noneLeft, for: dishID)
                        onClose()
                    }
                    OutlineActionButton(title: KitchenCopy.notMade) {
                        model.set(.notMade, for: dishID)
                        onClose()
                    }
                }
            }
            KeyPad(keyHeight: KitchenLayout.keyHeight, keyFill: MLColor.fillQuiet,
                   onDigit: { input.append($0); showsError = false },
                   onDelete: { input.deleteLast(); showsError = false },
                   onDecimal: input.allowsDecimal ? { input.appendDecimal() } : nil)
            InkActionButton(title: KitchenCopy.save) {
                guard let value = input.value else {
                    showsError = true
                    return
                }
                model.saveQuantity(value, for: field)
                onClose()
            }
        }
    }
}

/// Add a dish (K06h), for one that is not on the menu.
struct KitchenAddDishSheet: View {
    let onClose: () -> Void
    let onAdd: (String, WasteUnit) -> Void

    @State private var name = ""
    @State private var unit: WasteUnit = .kilograms

    private let options: [SegmentedChoice<WasteUnit>.Option] = [
        .init(value: .kilograms, title: WasteUnit.kilograms.symbol),
        .init(value: .litres, title: WasteUnit.litres.symbol),
        .init(value: .pieces, title: WasteUnit.pieces.symbol),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: KitchenCopy.addADish, subtitle: KitchenCopy.addDishDetail, onClose: onClose)
            Text(KitchenCopy.dishName).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            TextField(KitchenCopy.dishName, text: $name, prompt: nil)
                .font(MLType.staffBody)
                .padding(.horizontal, MLSpacing.s16)
                .frame(minHeight: MLSize.staffButton)
                .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.fillQuiet))
            Text(KitchenCopy.unit).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            SegmentedChoice(options: options, selection: $unit)
            InkActionButton(title: KitchenCopy.addDish) { onAdd(name, unit) }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

/// Check and save (K08, K08b). The report saves only when every field has an answer.
struct KitchenCheckSheet: View {
    let model: KitchenWasteViewModel
    let onClose: () -> Void
    let onSaved: (WasteReport) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: KitchenCopy.checkAndSave,
                        subtitle: KitchenCopy.mealAndMess(MLFormat.mealSlot(model.meal.slot), model.session.mess.name),
                        onClose: onClose)
            Rectangle().fill(MLColor.border).frame(height: 1)
            ForEach(model.report?.leftovers ?? []) { row in
                KitchenWasteLine(row: row)
            }
            Rectangle().fill(MLColor.border).frame(height: 1)
            HStack {
                Text(KitchenCopy.plateWasteWhole).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                Spacer(minLength: MLSpacing.s8)
                if let text = model.report.flatMap({ KitchenWasteText.plate($0.plateWaste) }) {
                    Text(text).font(MLType.monoBody).foregroundStyle(MLColor.ink)
                } else {
                    Text(KitchenCopy.notEntered).font(MLType.bodyEmphasis).foregroundStyle(MLColor.ink)
                }
            }
            Text(model.canSave ? KitchenCopy.youCanEditLater : KitchenCopy.everyDishNeeds)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            if let error = model.saveError {
                FieldErrorText(text: error)
            }
            if model.canSave {
                InkActionButton(title: KitchenCopy.saveReport, isLoading: model.isSaving) {
                    Task {
                        if let report = await model.save() { onSaved(report) }
                    }
                }
                OutlineActionButton(title: KitchenCopy.backToEdit, action: onClose)
            } else {
                Text(KitchenCopy.enterMore(model.missingCount))
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.inkSecondary)
                    .frame(maxWidth: .infinity, minHeight: MLSize.staffButton)
                    .background(Capsule().stroke(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])))
                InkActionButton(title: KitchenCopy.backToEdit, action: onClose)
            }
        }
    }
}

/// One dish in a report, read only: amount, "0 kg · none left", "not made" or "Not entered".
struct KitchenWasteLine: View {
    let row: DishLeftover

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            Text(row.dishName)
                .font(MLType.staffBody)
                .foregroundStyle(row.measurement == .notMade ? MLColor.inkSecondary : MLColor.ink)
            Spacer(minLength: MLSpacing.s8)
            switch row.measurement {
            case .entered:
                Text(KitchenWasteText.value(row) ?? "—").font(MLType.monoBody).foregroundStyle(MLColor.ink)
            case .noneLeft:
                HStack(spacing: MLSpacing.s4) {
                    Text(KitchenWasteText.value(row) ?? "—").font(MLType.monoBody)
                    Text("· \(KitchenCopy.noneLeftLower)").font(MLType.body)
                }
                .foregroundStyle(MLColor.ink)
            case .notMade:
                Text(KitchenCopy.notMadeLower).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            case .notEntered:
                Text(KitchenCopy.notEntered).font(MLType.bodyEmphasis).foregroundStyle(MLColor.ink)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Report saved (K08c). Shown only for a report the repository stored.
struct KitchenReportSavedView: View {
    let report: WasteReport
    let meal: Meal
    let timeZone: TimeZone
    let onViewReport: () -> Void
    let onDone: () -> Void

    private var savedAt: Date? {
        if case .recorded(let at) = report.status { return at }
        return nil
    }

    var body: some View {
        ZStack {
            MLColor.lime.ignoresSafeArea()
            VStack(spacing: MLSpacing.s16) {
                Text(KitchenCopy.contextLine(MLFormat.mealSlot(meal.slot)))
                    .font(MLType.body)
                    .foregroundStyle(MLColor.onLime)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "checkmark")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(MLColor.onHero)
                    .frame(width: KitchenLayout.savedTick, height: KitchenLayout.savedTick)
                    .background(Circle().fill(MLColor.ink))
                    .accessibilityHidden(true)
                Text(KitchenCopy.reportSaved)
                    .font(MLType.largeTitle)
                    .foregroundStyle(MLColor.onLime)
                if let until = WasteReportPolicy.editableUntil(report.status) {
                    Text(KitchenCopy.editItUntil(MLFormat.time(until, in: timeZone)))
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.onLime)
                }
                FactCard(rows: [
                    FactRow(label: KitchenCopy.saved, value: savedAt.map { MLFormat.time($0, in: timeZone) }),
                    FactRow(label: KitchenCopy.dishes, value: KitchenCopy.dishCount(report.leftovers.filter(\.measurement.isComplete).count,
                                                                                     of: report.leftovers.count), isMono: false),
                    FactRow(label: KitchenCopy.plateWaste, value: KitchenWasteText.plate(report.plateWaste)),
                ])
                Spacer(minLength: 0)
                OutlineActionButton(title: KitchenCopy.viewReport, action: onViewReport)
                InkActionButton(title: KitchenCopy.backToHome, action: onDone)
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.bottom, MLSpacing.s16)
        }
    }
}
