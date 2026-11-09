import SwiftUI

/// A mess other than the Food Head's own (2259:6, 2259:160041, 2259:160423). SIMULATED: nothing reaches a vendor.
@MainActor
@Observable
final class AdminMessHeadcountViewModel {
    private(set) var state: LoadState<AdminMessHeadcount> = .idle
    private(set) var isSaving = false
    private(set) var errorText: String?

    private let id: String
    private let slot: MealSlot
    private let role: Role
    private let messes: any AdminMessRepository
    /// One key per screen, so a double tap sends once.
    private let key = IdempotencyKey.make()

    init(id: String, slot: MealSlot, role: Role, messes: any AdminMessRepository) {
        self.id = id
        self.slot = slot
        self.role = role
        self.messes = messes
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            state = .loaded(try await messes.messHeadcount(id, slot: slot))
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    func send() async -> Bool {
        await write { [messes, id, slot, key, role] in try await messes.sendHeadcount(mess: id, slot: slot, key: key, by: role) }
    }

    func adjust(to count: Int, reason: String?) async -> Bool {
        await write { [messes, id, slot, role] in try await messes.adjustHeadcount(mess: id, slot: slot, to: count, reason: reason, by: role) }
    }

    private func write(_ work: () async throws -> AdminMessHeadcount) async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        errorText = nil
        defer { isSaving = false }
        do {
            state = .loaded(try await work())
            return true
        } catch {
            errorText = AdminWriteError.text(error)
            return false
        }
    }
}

struct AdminMessHeadcountScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let id: String
    let slot: MealSlot
    let nav: AdminNav

    var body: some View {
        AdminMessHeadcountView(model: AdminMessHeadcountViewModel(id: id, slot: slot, role: nav.context.account.role,
                                                                  messes: environment.repositories.adminMesses),
                               slot: slot, nav: nav)
    }
}

struct AdminMessHeadcountView: View {
    @State private var model: AdminMessHeadcountViewModel
    let slot: MealSlot
    let nav: AdminNav

    @State private var isAdjusting = false
    @State private var isTellingVendor = false

    init(model: AdminMessHeadcountViewModel, slot: MealSlot, nav: AdminNav) {
        _model = State(initialValue: model)
        self.slot = slot
        self.nav = nav
    }

    private var timeZone: TimeZone { nav.timeZone }
    private var mealName: String { MLFormat.mealSlot(slot) }

    var body: some View {
        // Read here, not only in the sheet: a value read only inside the sheet closure is stale on first show.
        let mess = model.state.value
        AdminPageScaffold(title: AdminCopy.pageTitle(mess: AdminCopy.messName(mess?.name ?? ""), meal: mealName),
                          subtitle: mess.map(subtitle), onBack: nav.pop) {
            AsyncContentView(state: model.state, timeZone: timeZone, retry: { await model.load() }) { mess in
                content(mess)
            }
        }
        .task { await model.load() }
        .mlSheet(isPresented: $isAdjusting) {
            if let mess, let count = mess.expected {
                AdminAdjustHeadcountSheet(startCount: count, forecastLine: AdminCopy.forecastRangeLine(mess),
                                          saveTitle: AdminCopy.save, isSaving: model.isSaving, errorText: model.errorText,
                                          save: { await model.adjust(to: $0, reason: $1) }) { saved in
                    isAdjusting = false
                    nav.toast(AdminCopy.savedToast(saved))
                } onClose: {
                    isAdjusting = false
                }
            }
        }
        .mlSheet(isPresented: $isTellingVendor) {
            AdminTellVendorSheet(subtitle: AdminScreenCopy.preparedMessage,
                                 message: AdminCopy.vendorChaseMessage(mess: AdminCopy.messName(mess?.name ?? ""), meal: mealName,
                                                                       count: mess?.expected, name: nav.context.account.firstName),
                                 note: nil) { isTellingVendor = false }
        }
    }

    private func subtitle(_ mess: AdminMessHeadcount) -> String {
        if let minutes = mess.noReplyMinutes, let sentAt = mess.sentAt, mess.reply == .noReply {
            return AdminCopy.sentNoReply(short(sentAt), minutes: minutes)
        }
        return mess.sendBy.map { AdminCopy.sendBy(short($0)) } ?? AdminCopy.noData
    }

    private func short(_ date: Date) -> String { AdminCopy.clock(MLFormat.time(date, in: timeZone)) }

    private func content(_ mess: AdminMessHeadcount) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            AdminStageLine(stages: [AdminCopy.stepForecast, AdminCopy.stepSend, AdminCopy.vendorReply], current: mess.sentAt == nil ? 1 : 2)
            hero(mess)
            if mess.canSend, let count = mess.expected {
                InkActionButton(title: AdminCopy.send(count), isLoading: model.isSaving) {
                    Task {
                        if await model.send() { nav.toast(AdminCopy.sentToast(count)) }
                    }
                }
            } else {
                replyRow(mess)
            }
            if let error = model.errorText {
                FieldErrorText(text: error)
            }
            if mess.reply == .noReply {
                HStack(spacing: MLSpacing.s12) {
                    InkActionButton(title: AdminCopy.callVendor) { isTellingVendor = true }
                    OutlineActionButton(title: AdminScreenCopy.message) { isTellingVendor = true }
                }
            } else if mess.canSend {
                AdminRow(title: AdminCopy.adjustHeadcount, action: { isAdjusting = true }) { EmptyView() }
            }
            if !mess.sentBefore.isEmpty {
                VStack(alignment: .leading, spacing: MLSpacing.s4) {
                    AdminLabel(text: AdminCopy.sentBefore)
                    ForEach(mess.sentBefore) { line in
                        sentBeforeRow(line)
                    }
                }
            }
        }
    }

    private func replyRow(_ mess: AdminMessHeadcount) -> some View {
        HStack {
            Text(AdminCopy.vendorReply)
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.ink)
            Spacer()
            AdminChip(text: AdminCopy.replyWord(mess.reply, in: timeZone), style: AdminChipRules.vendor(mess.reply))
        }
    }

    private func sentBeforeRow(_ line: AdminSentBefore) -> some View {
        HStack {
            Text(line.title)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
            Spacer()
            if let replied = line.repliedAt {
                Text(AdminCopy.repliedLower(short(replied)))
                    .font(MLType.monoBody)
                    .foregroundStyle(MLColor.inkSecondary)
            } else {
                AdminChip(text: AdminCopy.notAcknowledged, style: .dashed)
            }
        }
        .frame(minHeight: MLSize.staffButton)
        .overlay(alignment: .top) { Rectangle().fill(MLColor.border).frame(height: 1) }
    }

    private func hero(_ mess: AdminMessHeadcount) -> some View {
        HeroCard {
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                HeroEyebrow(label: eyebrow(mess))
                Text(mess.expected.map { String($0) } ?? AdminFormat.missing)
                    .font(AdminType.heroMetric)
                    .foregroundStyle(MLColor.onHero)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let low = mess.rangeLow, let high = mess.rangeHigh, let count = mess.expected {
                    AdminRangeBar(low: low, high: high, value: count)
                }
                HStack(alignment: .top, spacing: MLSpacing.s16) {
                    if let yes = mess.saidYes {
                        heroStat(AdminFormat.count(yes), AdminCopy.answersYes, isMono: true)
                    } else if let count = mess.expected {
                        heroStat(String(count), AdminCopy.headcountSentLower, isMono: true)
                    }
                    if let usual = mess.usual, let label = mess.usualLabel {
                        heroStat(AdminFormat.count(usual), label, isMono: true)
                    }
                    if let minutes = mess.noReplyMinutes, mess.reply == .noReply {
                        heroStat(AdminCopy.minutes(minutes), AdminCopy.noReplyLower, isMono: true)
                    }
                    if let events = mess.events {
                        heroStat(events, AdminCopy.eventsLower, isMono: false)
                    }
                }
            }
        }
    }

    private func eyebrow(_ mess: AdminMessHeadcount) -> String {
        guard let sentAt = mess.sentAt else { return AdminCopy.expectedDiners }
        let time = short(sentAt)
        if case .replied(let at) = mess.reply { return AdminCopy.sentAndReplied(time, short(at)) }
        return AdminCopy.sentToVendorAt(time)
    }

    private func heroStat(_ value: String, _ label: String, isMono: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(isMono ? AdminType.mono17 : MLType.staffPrimary)
                .foregroundStyle(MLColor.onHero)
            Text(label)
                .font(MLType.secondary)
                .foregroundStyle(MLColor.onHeroSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// The forecast range with the chosen number on it. Sized around the range, so the marker stays inside.
struct AdminRangeBar: View {
    let low: Int
    let high: Int
    let value: Int

    private var position: CGFloat {
        guard high > low else { return 0.5 }
        return min(max(CGFloat(value - low) / CGFloat(high - low), 0), 1)
    }

    var body: some View {
        VStack(spacing: MLSpacing.s4) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let start = width * 0.3
                let span = width * 0.4
                ZStack(alignment: .leading) {
                    Capsule().fill(MLColor.onHeroSecondary.opacity(0.5)).frame(height: 8)
                    Capsule().fill(MLColor.lime).frame(width: span, height: 8).offset(x: start)
                    Circle().fill(MLColor.onHero).frame(width: 16, height: 16).offset(x: start + span * position - 8)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 16)
            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .leading) {
                    label(low).position(x: width * 0.3, y: 8)
                    label(high).position(x: width * 0.7, y: 8)
                }
            }
            .frame(height: 16)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AdminCopy.rangeSpoken(low: low, high: high))
    }

    private func label(_ value: Int) -> some View {
        Text(String(value))
            .font(MLType.monoSecondary)
            .foregroundStyle(MLColor.onHeroSecondary)
    }
}

/// Not answered, by mess (the row on 2262:6). Counts only, never a name.
struct AdminNotAnsweredScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        let messes = environment.repositories.adminMesses
        let students = environment.repositories.adminStudents
        AdminLoadedPage(model: AdminPageModel { () -> ([AdminMessCount], AdminStudentsOverview) in
            (try await messes.notAnsweredByMess(), try await students.studentsOverview())
        }, timeZone: nav.timeZone) { value, _ in
            AdminPageScaffold(title: AdminScreenCopy.notAnswered,
                              subtitle: AdminScreenCopy.notAnsweredSubtitle(value.1.mealTitle, AdminFormat.count(value.1.notAnswered)), onBack: nav.pop) {
                // Blank-band audit (P7): who has answered, from the same overview the Students tab reads.
                HeroCard {
                    VStack(alignment: .leading, spacing: MLSpacing.s8) {
                        HeroEyebrow(label: AdminScreenCopy.answeredSoFar)
                        Text("\(AdminFormat.count(value.1.answered)) \(AdminScreenCopy.ofStudents(AdminFormat.count(value.1.totalStudents)))")
                            .font(AdminType.count)
                            .foregroundStyle(MLColor.onHero)
                        FactLine(label: AdminScreenCopy.answerYes, value: AdminFormat.count(value.1.yes))
                        FactLine(label: AdminScreenCopy.answerNo, value: AdminFormat.count(value.1.no))
                        FactLine(label: AdminScreenCopy.answerNotSure, value: AdminFormat.count(value.1.notSure))
                    }
                }
                AdminLabel(text: AdminScreenCopy.notAnsweredPerMess)
                VStack(spacing: 0) {
                    ForEach(value.0) { mess in
                        AdminRow(title: mess.name, action: nil) {
                            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s4) {
                                Text(String(mess.students)).font(AdminType.mono17)
                                Text(AdminScreenCopy.students(mess.students)).font(MLType.secondary)
                            }
                            .foregroundStyle(MLColor.ink)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

/// One white-on-black fact: a label and a mono number.
private struct FactLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).mlFont(.body).foregroundStyle(MLColor.onHeroSecondary)
            Spacer()
            Text(value).font(MLType.monoBody).foregroundStyle(MLColor.onHero)
        }
        .accessibilityElement(children: .combine)
    }
}
