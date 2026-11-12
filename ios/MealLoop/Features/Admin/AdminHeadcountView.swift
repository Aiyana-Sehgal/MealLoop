import SwiftUI

/// Headcount · Lunch (owner mocks, 12 Nov 2026). The Food Head's Today, and the Super Admin's Today with a mess
/// switcher (Main, North, South, Annexe); also the page behind any route that pushes `.headcount`.
/// The next step comes first, then the values as tiles in the order they matter now: before approval the forecasts
/// lead, after it Approved and Sent to vendor lead. Every tile names its own value, so one never passes for another,
/// and every tile opens its own sheet. Shares Today's view model, so Today has moved on by the time Back is tapped.
struct AdminHeadcountView: View {
    @Environment(AppEnvironment.self) private var environment
    let model: AdminTodayViewModel
    let open: (AdminRoute) -> Void
    /// Nil on Today, a tab root, which has no Back.
    let onBack: (() -> Void)?
    /// Today: adds open safety cases at the top and Needs you below the values.
    var isTodayRoot = false
    var openCase: (SOSCase) -> Void = { _ in }

    /// The sheet open over the page. One at a time; Contact the vendor swaps the Sent sheet for the message.
    enum Detail: Equatable {
        case cutoff, live, approved, sent, actual, final, tellVendor
    }

    @State private var detail: Detail?
    @State private var isAdjusting = false
    @State private var isConfirmingSend = false
    @State private var toast: String?
    /// The Super Admin's switcher: nil is the signed-in mess (Main), otherwise another mess's id.
    @State private var selectedMess: String?
    @State private var other: AdminMessHeadcountViewModel?

    init(model: AdminTodayViewModel, open: @escaping (AdminRoute) -> Void = { _ in }, onBack: (() -> Void)?,
         isTodayRoot: Bool = false, openCase: @escaping (SOSCase) -> Void = { _ in }) {
        self.model = model
        self.open = open
        self.onBack = onBack
        self.isTodayRoot = isTodayRoot
        self.openCase = openCase
    }

    private var showsSwitcher: Bool { model.context.allMesses }

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    if let onBack {
                        AdminBackButton(action: onBack)
                    } else {
                        // The tab root keeps the title where the pushed page has it.
                        Color.clear.frame(height: MLSize.hit)
                    }
                    AsyncContentView(state: model.state,
                                     emptyTitle: AdminCopy.noMealTitle,
                                     emptyMessage: AdminCopy.noMealDetail,
                                     timeZone: model.context.mess.timeZone,
                                     retry: { await model.load() }) { content in
                        if let snapshot = snapshot(content) {
                            page(content, snapshot)
                        } else {
                            EmptyStateView(title: AdminCopy.noData)
                        }
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, 120)
            }
            .refreshable { await reload() }
        }
        .toolbar(.hidden, for: .navigationBar)
        .mlToast(message: $toast, bottomInset: 92)
        .mlSheet(isPresented: $isAdjusting) {
            if let content = model.state.value, let snapshot = snapshot(content), let start = snapshot.approvedCount ?? snapshot.leadCount {
                AdminAdjustHeadcountSheet(startCount: start,
                                          subtitle: AdminCopy.changeSubtitle(meal: snapshot.mealName, mess: snapshot.mess),
                                          forecast: snapshot.cutoffForecast ?? snapshot.liveForecast, isSaving: isWorking, errorText: errorText,
                                          save: { await adjust(to: $0, reason: $1) }) { saved in
                    isAdjusting = false
                    toast = selectedMess == nil ? AdminCopy.approvedToast(saved) : AdminCopy.savedToast(saved)
                } onClose: {
                    isAdjusting = false
                }
            }
        }
        .mlSheet(isPresented: Binding(get: { detail != nil }, set: { if !$0 { detail = nil } })) {
            if let content = model.state.value, let snapshot = snapshot(content), let detail {
                AdminHeadcountDetailSheet(detail: detail, snapshot: snapshot, senderName: model.context.account.firstName,
                                          contactVendor: { self.detail = .tellVendor },
                                          changeNumber: snapshot.canChangeNumber ? {
                                              self.detail = nil
                                              isAdjusting = true
                                          } : nil,
                                          openReport: snapshot.mealID.map { id in {
                                              self.detail = nil
                                              open(.page(.meal(id)))
                                          } },
                                          onClose: { self.detail = nil })
            }
        }
        // A compact sheet naming the mess, the meal and the count. It stays open on a failure, so Send retries.
        .mlConfirmSheet(isPresented: $isConfirmingSend, content: sendDialog, isWorking: isWorking, errorText: errorText) {
            Task {
                guard let count = await send() else { return }
                isConfirmingSend = false
                toast = AdminCopy.sentToast(count)
            }
        }
    }

    // MARK: Source

    private func snapshot(_ content: AdminTodayContent) -> AdminHeadcountSnapshot? {
        if let selectedMess {
            let fresh = other?.state.value.flatMap { $0.id == selectedMess ? $0 : nil }
            guard let mess = fresh ?? content.otherMesses?.messes.first(where: { $0.id == selectedMess }) else { return nil }
            return .other(mess, content: content, context: model.context)
        }
        guard let meal = content.meal else { return nil }
        return .own(content, meal, context: model.context)
    }

    private func select(_ id: String?, slot: MealSlot) {
        guard id != selectedMess else { return }
        detail = nil
        selectedMess = id
        guard let id else {
            other = nil
            return
        }
        let next = AdminMessHeadcountViewModel(id: id, slot: slot, role: model.context.account.role,
                                               messes: environment.repositories.adminMesses)
        other = next
        Task { await next.load() }
    }

    private func reload() async {
        await model.load()
        await other?.load()
    }

    private var isWorking: Bool {
        selectedMess == nil ? (model.isApproving || model.isSending) : (other?.isSaving ?? false)
    }

    private var errorText: String? {
        selectedMess == nil ? model.actionError : other?.errorText
    }

    private func adjust(to count: Int, reason: String?) async -> Bool {
        guard let other, selectedMess != nil else { return await model.adjust(to: count, reason: reason) }
        let saved = await other.adjust(to: count, reason: reason)
        if saved { await model.load() }
        return saved
    }

    /// The count that went out, or nil when nothing was sent.
    private func send() async -> Int? {
        guard let content = model.state.value, let snapshot = snapshot(content), case .send(let count) = snapshot.next else { return nil }
        if let other, selectedMess != nil {
            guard await other.send() else { return nil }
            await model.load()
        } else {
            guard await model.send() else { return nil }
        }
        return count
    }

    private var sendDialog: ConfirmDialogContent {
        let content = model.state.value
        let snapshot = content.flatMap(snapshot)
        let count: Int = if case .send(let count)? = snapshot?.next { count } else { 0 }
        return ConfirmDialogContent(title: AdminCopy.sendTitle(count),
                                    subject: AdminCopy.sendSubject(meal: snapshot?.mealName ?? "", mess: AdminCopy.messName(snapshot?.mess ?? "")),
                                    detail: AdminCopy.sendDetail,
                                    cancelTitle: AdminCopy.cancel,
                                    actionTitle: AdminCopy.sendAction)
    }

    // MARK: Page

    @ViewBuilder
    private func page(_ content: AdminTodayContent, _ snapshot: AdminHeadcountSnapshot) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text(AdminCopy.headcountEyebrow(mess: AdminCopy.messName(snapshot.mess), day: snapshot.day))
                    .font(MLType.meta)
                    .tracking(1.5)
                    .foregroundStyle(MLColor.inkSecondary)
                Text(snapshot.mealName)
                    .font(MLType.largeTitle)
                    .foregroundStyle(MLColor.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(snapshot.subtitle)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            if showsSwitcher {
                AdminMessSwitcher(own: AdminCopy.tileName(content.mess.name),
                                  others: (content.otherMesses?.messes ?? []).map { ($0.id, $0.name) },
                                  selected: selectedMess) { select($0, slot: content.selectedSlot) }
            }
            AdminChainStepper(stepIndex: snapshot.stepIndex)
                .padding(.vertical, MLSpacing.s8)
            if isTodayRoot {
                ForEach(content.safetyCases) { safetyCase in
                    AdminSafetyCaseCard(safetyCase: safetyCase, now: content.now, timeZone: content.mess.timeZone) { openCase(safetyCase) }
                }
            }
            nextCard(snapshot)
            if let error = errorText {
                FieldErrorText(text: error)
            }
            if snapshot.isApproved {
                pair { approvedTile(snapshot) } trailing: { sentTile(snapshot) }
                pair { cutoffTile(snapshot) } trailing: { liveTile(snapshot) }
            } else {
                pair { cutoffTile(snapshot) } trailing: { liveTile(snapshot) }
                sendLockedTile(snapshot)
            }
            pair { actualTile(snapshot) } trailing: { finalTile(snapshot) }
            // The full page: adjust, approve or send, status, the six values and the history (other messes: theirs).
            AdminGroupCard {
                AdminHubRow(title: AdminCopy.headcountDetails, isLast: true) {
                    if let selectedMess { open(.page(.messHeadcount(selectedMess, content.selectedSlot))) } else { open(.headcount) }
                }
            }
            if isTodayRoot {
                needsYou(content)
            }
            if selectedMess == nil, let meal = content.meal {
                history(meal, timeZone: content.mess.timeZone)
            }
        }
    }

    private func pair<A: View, B: View>(@ViewBuilder leading: () -> A, @ViewBuilder trailing: () -> B) -> some View {
        HStack(alignment: .top, spacing: MLSpacing.s12) {
            leading()
            trailing()
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    /// The one primary action: Approve, then Send. Once nothing is left to do, the card shows where the meal stands.
    @ViewBuilder
    private func nextCard(_ snapshot: AdminHeadcountSnapshot) -> some View {
        let eyebrow: String = switch snapshot.next {
        case .approve: AdminCopy.nextStep(AdminCopy.stepApprove)
        case .send: AdminCopy.nextStep(AdminCopy.sendToVendorStep)
        case .none: snapshot.leadCount == nil ? AdminCopy.noData.uppercased() : snapshot.leadName.uppercased()
        }
        let number: Int? = switch snapshot.next {
        case .approve(let count), .send(let count): count
        case .none: snapshot.leadCount
        }
        let caption: String = switch snapshot.next {
        case .approve: AdminCopy.expectedDinersCaption
        case .send: AdminCopy.approvedHeadcountCaption
        case .none: snapshot.leadName.lowercased()
        }
        BentoTile(kind: .hero) {
            HeroEyebrow(label: eyebrow)
            HStack(alignment: .center, spacing: MLSpacing.s16) {
                BentoNumber(text: number.map(AdminFormat.count), kind: .hero, font: AdminType.heroMetric,
                            spoken: "\(caption), \(number.map(String.init) ?? AdminCopy.noData)")
                Spacer(minLength: 0)
                if number != nil {
                    Text(caption)
                        .font(MLType.staffBody)
                        .foregroundStyle(MLColor.onHeroSecondary)
                        .frame(maxWidth: 120, alignment: .leading)
                        .accessibilityHidden(true)
                }
            }
            switch snapshot.next {
            case .approve(let count):
                LimeActionButton(title: AdminCopy.approve(count)) {
                    Task {
                        // The pack's flow: Approve opens the headcount page in its approved state.
                        if await model.approve() { open(.headcount) }
                    }
                }
                .disabled(isWorking)
                if snapshot.canChangeNumber {
                    heroLink(AdminCopy.changeTheNumber) {
                        model.clearActionError()
                        isAdjusting = true
                    }
                }
            case .send(let count):
                LimeActionButton(title: "\(AdminCopy.sendAction) \(count)") {
                    model.clearActionError()
                    isConfirmingSend = true
                }
                .disabled(isWorking)
                heroLink(AdminCopy.contactTheVendor) { detail = .tellVendor }
            case .none:
                Text(snapshot.statusLine)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.onHeroSecondary)
                if snapshot.canContactVendor, snapshot.sentCount != nil {
                    heroLink(AdminCopy.contactTheVendor) { detail = .tellVendor }
                }
            }
        }
    }

    private func heroLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(MLType.staffBody)
                .underline()
                .foregroundStyle(MLColor.onHero)
                .frame(maxWidth: .infinity, minHeight: MLSize.hit)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Tiles

    private func approvedTile(_ snapshot: AdminHeadcountSnapshot) -> some View {
        AdminValueTile(title: AdminCopy.approvedShort, spokenName: AdminCopy.approvedHeadcount, kind: .standard,
                       number: snapshot.approvedCount, lines: snapshot.approvedLine.map { [$0] } ?? []) { detail = .approved }
    }

    private func sentTile(_ snapshot: AdminHeadcountSnapshot) -> some View {
        AdminValueTile(title: AdminCopy.sentToVendor, kind: snapshot.sentCount == nil ? .dashed : .standard,
                       number: snapshot.sentCount, lines: [snapshot.sentLine]) { detail = .sent }
    }

    private func sendLockedTile(_ snapshot: AdminHeadcountSnapshot) -> some View {
        AdminValueTile(title: AdminCopy.sendToVendorTitle, spokenName: AdminCopy.sentToVendor, kind: .dashed,
                       number: nil, showsNumber: false, lines: [AdminCopy.unlocksAfterApprove],
                       lockedAction: AdminCopy.sendAction) { detail = .sent }
    }

    private func cutoffTile(_ snapshot: AdminHeadcountSnapshot) -> some View {
        let value = snapshot.cutoffForecast
        var lines: [String]
        if value != nil {
            lines = [AdminCopy.lockedAt(snapshot.cutoffTime)]
            if !snapshot.isApproved { lines.append(AdminCopy.youApproveThis) }
        } else {
            lines = [selectedMess == nil ? AdminCopy.locksAt(snapshot.cutoffTime) : AdminCopy.notHeldFor(snapshot.mess)]
        }
        return AdminValueTile(title: AdminCopy.cutoffShort, spokenName: AdminCopy.cutoffForecast,
                              symbol: snapshot.isApproved ? nil : "lock", kind: value == nil ? .dashed : .standard,
                              number: value, lines: lines) { detail = .cutoff }
    }

    private func liveTile(_ snapshot: AdminHeadcountSnapshot) -> some View {
        let share = snapshot.answered.flatMap { answered in snapshot.notYet.map { (answered, answered + $0) } }
        return AdminValueTile(title: AdminCopy.liveForecast, kind: snapshot.liveForecast == nil ? .dashed : .standard,
                              number: snapshot.liveForecast, share: share,
                              lines: snapshot.answered.map { [AdminCopy.answeredCount(AdminFormat.count($0))] } ?? []) { detail = .live }
    }

    private func actualTile(_ snapshot: AdminHeadcountSnapshot) -> some View {
        AdminValueTile(title: AdminCopy.actualEntries, kind: snapshot.actualEntries == nil ? .dashed : .standard,
                       number: snapshot.actualEntries, lines: [snapshot.actualLine]) { detail = .actual }
    }

    private func finalTile(_ snapshot: AdminHeadcountSnapshot) -> some View {
        AdminValueTile(title: AdminCopy.finalEntries, kind: snapshot.finalEntries == nil ? .dashed : .standard,
                       number: snapshot.finalEntries,
                       lines: snapshot.finalEntries == nil ? [selectedMess == nil ? AdminCopy.afterTheMeal : AdminCopy.notHeldFor(snapshot.mess)] : [])
        { detail = .final }
    }

    // MARK: Needs you and history

    /// Needs you on Today: the same rows as before, under the values.
    @ViewBuilder
    private func needsYou(_ content: AdminTodayContent) -> some View {
        if !content.needsYouItems.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    AdminLabel(text: showsSwitcher ? AdminCopy.needsYouCount(content.needsYouItems.count) : AdminCopy.needsYou)
                    Spacer()
                    if content.hasMoreNeedsYou {
                        TextLinkButton(title: AdminCopy.seeAll) { open(.needsYou) }
                    }
                }
                .padding(.bottom, 6)
                ForEach(content.visibleNeedsYouItems) { item in
                    AdminNeedsYouRow(item: item, content: content, open: open)
                }
            }
            .padding(.top, MLSpacing.s8)
        }
    }

    @ViewBuilder
    private func history(_ meal: AdminMealContent, timeZone: TimeZone) -> some View {
        if !meal.history.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: AdminCopy.history)
                ForEach(Array(meal.history.enumerated()), id: \.offset) { _, event in
                    historyRow(event, timeZone: timeZone)
                }
            }
            .padding(.top, MLSpacing.s8)
        }
    }

    private func historyRow(_ event: AdminHistoryEvent, timeZone: TimeZone) -> some View {
        let time = MLFormat.time(event.time, in: timeZone)
        switch event {
        case .adjusted(let change):
            return AlertRow(mark: .outlined(symbol: "pencil"),
                            title: AdminCopy.historyAdjusted(from: change.from, to: change.to), time: time,
                            detail: AdminCopy.historyAdjustedDetail(reason: change.reason,
                                                                    role: MLFormat.roleName(change.adjustedBy)))
        case .approved(let count, let role, _):
            return AlertRow(mark: .outlined(symbol: "checkmark"), title: AdminCopy.historyApproved(count), time: time,
                            detail: MLFormat.roleName(role))
        case .sent(let sent):
            return AlertRow(mark: .outlined(symbol: "paperplane"), title: AdminCopy.historySent(sent.count), time: time,
                            detail: MLFormat.roleName(sent.sentBy))
        case .acknowledged:
            return AlertRow(mark: .outlined(symbol: "checkmark.seal"), title: AdminCopy.historyAcknowledged, time: time,
                            detail: AdminCopy.vendorAccount)
        }
    }
}

/// Main, North, South, Annexe (Super Admin Today, owner mock 12 Nov 2026). The selected mess is the black pill.
struct AdminMessSwitcher: View {
    let own: String
    let others: [(id: String, name: String)]
    let selected: String?
    let onSelect: (String?) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            row
            ScrollView(.horizontal, showsIndicators: false) { row }
        }
    }

    private var row: some View {
        HStack(spacing: MLSpacing.s8) {
            pill(own, isSelected: selected == nil) { onSelect(nil) }
            ForEach(others, id: \.id) { mess in
                pill(mess.name, isSelected: selected == mess.id) { onSelect(mess.id) }
            }
        }
    }

    private func pill(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(isSelected ? MLType.staffPrimary : MLType.staffBody)
                .foregroundStyle(isSelected ? MLColor.onHero : MLColor.ink)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, MLSpacing.s16)
                .frame(minHeight: MLSize.hit)
                .background {
                    if isSelected {
                        Capsule().fill(MLColor.ink)
                    } else {
                        Capsule().stroke(MLColor.ink, lineWidth: 1.5)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// One headcount value as a tile: its own name, its number (a dash when missing, never zero), a line or two, and the
/// round ↗ that opens its sheet. Dashed while the value does not exist yet.
struct AdminValueTile: View {
    let title: String
    var spokenName: String?
    var symbol: String?
    let kind: BentoKind
    let number: Int?
    var showsNumber = true
    /// Answered of everyone, drawn as a bar under the number.
    var share: (part: Int, total: Int)?
    let lines: [String]
    /// A step that is not open yet ("Send" until approved): drawn as a dashed pill, never as a working button.
    var lockedAction: String?
    let openDetail: () -> Void

    var body: some View {
        BentoTile(kind: kind, fillsHeight: true) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(MLType.staffBody)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(kind.secondary)
            // The ↗ sits in the corner over the label's end, as on the mocks, so a label never breaks mid-word.
            .padding(.trailing, 28)
            .frame(maxWidth: .infinity, minHeight: MLSize.hit, alignment: .leading)
            if showsNumber {
                BentoNumber(text: number.map(AdminFormat.count), kind: kind, font: AdminType.tileMetric,
                            spoken: "\(spokenName ?? title), \(number.map(String.init) ?? AdminCopy.noData)")
            }
            if let share, share.total > 0, number != nil {
                AdminShareBar(part: share.part, total: share.total, height: 8)
            }
            ForEach(lines, id: \.self) { line in
                BentoCaption(text: line, kind: kind)
            }
            if let lockedAction {
                AdminChip(text: lockedAction, style: .dashed)
                    .opacity(0.6)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .topTrailing) {
            RoundGoButton(label: AdminCopy.openDetail(spokenName ?? title), action: openDetail)
                .padding(MLSpacing.s12)
        }
    }
}

/// Answered of everyone, ink on the track. The numbers are always written next to it.
struct AdminShareBar: View {
    let part: Int
    let total: Int
    var height: CGFloat = 14

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(MLColor.track)
                Capsule().fill(MLColor.ink).frame(width: proxy.size.width * CGFloat(part) / CGFloat(max(total, 1)))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// The six sheets behind the tiles (owner mocks, 12 Nov 2026), plus the prepared vendor message. Every figure reads
/// its own field. The hourly answers and 15-minute entries charts need real series, which are not held, so they are
/// left out rather than drawn from invented numbers.
struct AdminHeadcountDetailSheet: View {
    let detail: AdminHeadcountView.Detail
    let snapshot: AdminHeadcountSnapshot
    let senderName: String
    let contactVendor: () -> Void
    let changeNumber: (() -> Void)?
    let openReport: (() -> Void)?
    let onClose: () -> Void

    private var subtitle: String { AdminCopy.sheetSubtitle(mess: snapshot.mess, meal: snapshot.mealName, day: snapshot.day) }

    var body: some View {
        switch detail {
        case .cutoff: cutoffSheet
        case .live: liveSheet
        case .approved: approvedSheet
        case .sent: sentSheet
        case .actual: actualSheet
        case .final: finalSheet
        case .tellVendor:
            AdminTellVendorSheet(subtitle: AdminScreenCopy.preparedMessage,
                                 message: AdminCopy.vendorChaseMessage(mess: AdminCopy.messName(snapshot.mess), meal: snapshot.mealName,
                                                                       count: snapshot.sentCount ?? snapshot.approvedCount,
                                                                       name: senderName),
                                 note: nil, onClose: onClose)
        }
    }

    private func figure(_ value: Int?, caption: String?) -> some View {
        HStack(alignment: .center, spacing: MLSpacing.s16) {
            Text(value.map(AdminFormat.count) ?? "—")
                .font(AdminType.stat)
                .foregroundStyle(value == nil ? MLColor.inkSecondary : MLColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let caption {
                Text(caption)
                    .font(MLType.staffBody)
                    .foregroundStyle(MLColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private func section(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            Text(title).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var answersBlock: some View {
        if let answered = snapshot.answered {
            if let notYet = snapshot.notYet, answered + notYet > 0 {
                AdminShareBar(part: answered, total: answered + notYet)
            }
            HStack(spacing: MLSpacing.s24) {
                legend(AdminFormat.count(answered), AdminCopy.answeredWord, color: MLColor.ink)
                if let notYet = snapshot.notYet {
                    legend(AdminFormat.count(notYet), AdminCopy.notYetWord, color: MLColor.track)
                }
            }
        }
    }

    private func legend(_ count: String, _ label: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
            Circle().fill(color).frame(width: 10, height: 10).accessibilityHidden(true)
            Text(count).font(AdminType.mono20).bold().foregroundStyle(MLColor.ink)
            Text(label).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var cutoffSheet: some View {
        let value = snapshot.cutoffForecast
        return VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: AdminCopy.cutoffForecast, subtitle: subtitle, onClose: onClose)
            figure(value, caption: value == nil ? nil : AdminCopy.lockedAtCaption(snapshot.cutoffTime))
            if value != nil { answersBlock }
            section(AdminCopy.whatThisMeans)
            Text(value == nil ? AdminCopy.cutoffPendingNote : AdminCopy.cutoffMeaning)
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            StatusText(text: value == nil ? AdminCopy.locksAt(snapshot.cutoffTime) : AdminCopy.lockedAt(snapshot.cutoffTime),
                       dot: value == nil ? .dashed : .empty)
        }
    }

    private var liveSheet: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: AdminCopy.liveForecast, subtitle: subtitle, onClose: onClose)
            figure(snapshot.liveForecast, caption: AdminCopy.expectedDinersCaption)
            answersBlock
            StatusText(text: snapshot.answersOpen ? AdminCopy.openClosesAt(snapshot.cutoffTime) : AdminCopy.closedBecameCutoff(snapshot.cutoffTime),
                       dot: snapshot.answersOpen ? .filled : .empty)
        }
    }

    private var approvedSheet: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: AdminCopy.approvedHeadcountTitle, subtitle: subtitle, onClose: onClose)
            figure(snapshot.approvedCount, caption: snapshot.approvedCaption)
            if !snapshot.approvalHistory.isEmpty {
                section(AdminCopy.historyLabel)
                AdminHistoryTrack(steps: snapshot.approvalHistory)
            }
            if !snapshot.hasChanges, snapshot.approvedCount != nil {
                Text(AdminCopy.noChangesMade).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            }
            if let changeNumber {
                Button(action: changeNumber) {
                    Text(AdminCopy.changeTheNumber)
                        .font(MLType.staffBody)
                        .underline()
                        .foregroundStyle(MLColor.ink)
                        .frame(minHeight: MLSize.hit)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sentSheet: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: AdminCopy.sentToVendor, subtitle: subtitle, onClose: onClose)
            figure(snapshot.approvedCount, caption: snapshot.approvedCount == nil ? nil : AdminCopy.approvedHeadcountCaption)
            AdminVendorTrack(steps: snapshot.track)
                .padding(.vertical, MLSpacing.s8)
            Text(AdminCopy.vendorSeesOnly)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            if snapshot.canContactVendor {
                OutlineActionButton(title: AdminCopy.contactTheVendor, action: contactVendor)
            }
        }
    }

    private var actualSheet: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: AdminCopy.actualEntries, subtitle: subtitle, onClose: onClose)
            figure(snapshot.actualEntries, caption: snapshot.actualEntries == nil ? nil : AdminCopy.studentsEntered)
            StatusText(text: snapshot.actualAsOf ?? snapshot.actualLine, dot: snapshot.actualAsOf == nil ? .empty : .filled)
            Text(snapshot.actualEntries == nil && snapshot.mealID != nil ? AdminCopy.entriesNotStarted : AdminCopy.countedAtDoor)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var finalSheet: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: AdminCopy.finalEntries, subtitle: subtitle, onClose: onClose)
            figure(snapshot.finalEntries, caption: snapshot.closedCaption)
            section(AdminCopy.comparedWith)
            // Side by side, with no verdict: whether fewer than approved is good or bad is not a decision made here.
            HStack(alignment: .top) {
                compared(AdminCopy.approvedShort, snapshot.approvedCount)
                compared(AdminCopy.finalEntries, snapshot.finalEntries)
            }
            Text(snapshot.finalEntries == nil ? AdminCopy.finalNotYet : AdminCopy.finalFixed)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            if let openReport {
                OutlineActionButton(title: AdminCopy.openMealReport, action: openReport)
            }
        }
    }

    private func compared(_ label: String, _ value: Int?) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(label).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            Text(value.map(AdminFormat.count) ?? "—")
                .font(AdminType.count)
                .foregroundStyle(value == nil ? MLColor.inkSecondary : MLColor.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// A vertical history (Approved headcount sheet): a filled check per step, joined by a line, oldest first.
struct AdminHistoryTrack: View {
    let steps: [AdminVendorTrack.Step]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: MLSpacing.s16) {
                    VStack(spacing: 0) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(MLColor.onHero)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(MLColor.ink))
                        if index < steps.count - 1 {
                            Rectangle().fill(MLColor.ink).frame(width: 2).frame(minHeight: 28)
                        }
                    }
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                        Text(step.detail).mlFont(.secondary).foregroundStyle(MLColor.inkSecondary)
                    }
                    .padding(.bottom, MLSpacing.s12)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

/// Approved → Sent → Acknowledged, as on the Sent to vendor mock: a filled check for a step done, a dashed ring for
/// one not reached, a solid line into a done step and a dotted one into a step still waiting.
struct AdminVendorTrack: View {
    struct Step: Equatable {
        let title: String
        let detail: String
        let isDone: Bool
    }

    let steps: [Step]
    private let marker: CGFloat = 28

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                VStack(spacing: MLSpacing.s4) {
                    Group {
                        if step.isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(MLColor.onHero)
                                .frame(width: marker, height: marker)
                                .background(Circle().fill(MLColor.ink))
                        } else {
                            Circle()
                                .fill(MLColor.surface)
                                .overlay(Circle().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])))
                                .frame(width: marker, height: marker)
                        }
                    }
                    Text(step.title)
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(step.detail)
                        .mlFont(.secondary)
                        .foregroundStyle(MLColor.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityValue(step.isDone ? "Done" : "")
            }
        }
        .background(alignment: .top) {
            GeometryReader { proxy in
                let column = proxy.size.width / CGFloat(max(steps.count, 1))
                ForEach(0..<max(steps.count - 1, 0), id: \.self) { index in
                    Path { path in
                        path.move(to: CGPoint(x: column * (CGFloat(index) + 0.5) + marker / 2, y: marker / 2))
                        path.addLine(to: CGPoint(x: column * (CGFloat(index) + 1.5) - marker / 2, y: marker / 2))
                    }
                    .stroke(MLColor.ink, style: StrokeStyle(lineWidth: 2.5, dash: steps[index + 1].isDone ? [] : [2, 3]))
                }
            }
            .accessibilityHidden(true)
        }
    }
}

/// Forecast, Approve, Send, Vendor: a filled check for a step done, lime for the step waiting, dashed after.
struct AdminChainStepper: View {
    /// The step waiting on someone; 4 when every step is done.
    let stepIndex: Int

    private let steps = [AdminCopy.stepForecast, AdminCopy.stepApprove, AdminCopy.stepSend, AdminCopy.stepVendor]
    private let size: CGFloat = 32

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                VStack(spacing: MLSpacing.s4) {
                    marker(index)
                        .frame(height: size)
                    Text(step)
                        .font(index == stepIndex ? MLType.bodyEmphasis : MLType.body)
                        .foregroundStyle(index == stepIndex ? MLColor.ink : MLColor.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(alignment: .top) {
            GeometryReader { proxy in
                let inset = proxy.size.width / CGFloat(steps.count * 2)
                let width = proxy.size.width - inset * 2
                let reached = CGFloat(min(stepIndex, steps.count - 1)) / CGFloat(steps.count - 1)
                ZStack(alignment: .leading) {
                    Rectangle().fill(MLColor.track).frame(width: width, height: 3)
                    Rectangle().fill(MLColor.ink).frame(width: width * reached, height: 3)
                }
                .padding(.leading, inset)
                .frame(height: size)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stepIndex < steps.count ? "Step \(stepIndex + 1) of \(steps.count), \(steps[stepIndex])"
                                                    : "All \(steps.count) steps done")
    }

    @ViewBuilder
    private func marker(_ index: Int) -> some View {
        if index == stepIndex {
            Circle()
                .fill(MLColor.lime)
                .overlay(Circle().stroke(MLColor.limeOutline, lineWidth: 2))
                .frame(width: size, height: size)
        } else if index < stepIndex {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(MLColor.onHero)
                .frame(width: size, height: size)
                .background(Circle().fill(MLColor.ink))
        } else {
            Circle()
                .fill(MLColor.canvas)
                .overlay(Circle().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])))
                .frame(width: size, height: size)
        }
    }
}
