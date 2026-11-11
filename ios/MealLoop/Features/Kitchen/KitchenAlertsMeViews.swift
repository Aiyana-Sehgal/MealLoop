import Observation
import SwiftUI

/// One row on Alerts. No alerts feed exists, so rows are worked out from what the repositories hold.
struct KitchenAlert: Equatable, Identifiable {
    enum Kind: Equatable {
        case mealEnded(Meal)
        case shortageSeen
        case foodShort
        case wasteNotRecorded(MealID)
    }

    let kind: Kind
    let title: String
    let at: Date?
    /// Shown where a time is not known ("Tue").
    let timeText: String?
    let detail: String
    let isUnread: Bool

    var id: String { "\(title)-\(detail)" }

    static func alerts(status: MealStatus?, waste: WasteReportSummary?, shortages: [Shortage], history: [MealRecord],
                       timeZone: TimeZone) -> [KitchenAlert] {
        var rows: [KitchenAlert] = []
        if let status, status.state == .closed, let closedAt = status.closedAt, !isRecorded(waste) {
            let name = MLFormat.mealSlot(status.meal.slot)
            rows.append(KitchenAlert(kind: .mealEnded(status.meal), title: KitchenCopy.mealEnded, at: closedAt, timeText: nil,
                                     detail: KitchenCopy.recordWasteFor(name), isUnread: true))
        }
        for shortage in shortages {
            if case .seen(let at, let by) = shortage.delivery {
                rows.append(KitchenAlert(kind: .shortageSeen, title: KitchenCopy.shortageSeen, at: at, timeText: nil,
                                         detail: KitchenCopy.sawDish(by, dish: shortage.dishName), isUnread: false))
            }
            if shortage.reportedBy == .passDesk {
                rows.append(KitchenAlert(kind: .foodShort, title: KitchenCopy.foodShort, at: shortage.reportedAt, timeText: nil,
                                         detail: KitchenCopy.atPassDesk(shortage.dishName), isUnread: true))
            }
        }
        rows.sort { ($0.at ?? .distantPast) > ($1.at ?? .distantPast) }
        for record in history where record.waste == .notRecorded && record.mealID != status?.meal.id {
            let meal = "\(KitchenFormat.shortDay(record.day, in: timeZone)) \(MLFormat.mealSlot(record.slot))"
            rows.append(KitchenAlert(kind: .wasteNotRecorded(record.mealID), title: KitchenCopy.wasteNotRecorded, at: nil,
                                     timeText: KitchenFormat.dayLine(record.day, in: timeZone).components(separatedBy: " ").first,
                                     detail: KitchenCopy.notRecordedFor(meal), isUnread: false))
        }
        return rows
    }

    private static func isRecorded(_ waste: WasteReportSummary?) -> Bool {
        if case .recorded? = waste?.status { return true }
        return false
    }
}

@MainActor
@Observable
final class KitchenAlertsViewModel {
    private(set) var state: LoadState<[KitchenAlert]> = .idle
    /// Loaded with the rows; shown in the "This meal" block (R2). Nil until loaded.
    private(set) var status: MealStatus?
    private(set) var waste: WasteReportSummary?
    private(set) var shortageCount: Int?
    private(set) var history: [MealRecord] = []
    let session: StaffSession
    private let mealState: any MealStateRepository
    private let shortages: any ShortageRepository
    private let wasteReports: any WasteReportRepository

    init(session: StaffSession, repositories: Repositories) {
        self.session = session
        self.mealState = repositories.mealState
        self.shortages = repositories.shortages
        self.wasteReports = repositories.wasteReports
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let status = try await mealState.currentMeal(for: session.mess.id)
            var reports: [Shortage] = []
            var waste: WasteReportSummary?
            if let status {
                reports = try await shortages.shortages(for: status.meal.id)
                waste = try await wasteReports.summary(for: status.meal.id)
            }
            let history = try await mealState.mealHistory(for: session.mess.id)
            let rows = KitchenAlert.alerts(status: status, waste: waste, shortages: reports, history: history,
                                           timeZone: session.mess.timeZone)
            self.status = status
            self.waste = waste
            self.shortageCount = status == nil ? nil : reports.count
            self.history = history.filter { $0.mealID != status?.meal.id }
            state = rows.isEmpty ? .empty : .loaded(rows)
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }
}

/// Alerts (K12): the SOS card on top while one is active, then the rows.
struct KitchenAlertsView: View {
    let model: KitchenAlertsViewModel
    let sos: KitchenSOSViewModel
    let now: Date
    let onOpenSOS: () -> Void
    let open: (KitchenRoute) -> Void

    private var mess: Mess { model.session.mess }

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    ScreenTitleBlock(title: KitchenCopy.alerts, subtitle: mess.name)
                        .padding(.top, MLSize.hit + MLSpacing.s16)
                    if let current = sos.current, let stage = sos.stage {
                        SOSCard(incident: KitchenSOSText.incident(current, eyebrow: KitchenCopy.sosEyebrow, now: now, timeZone: mess.timeZone),
                                status: KitchenSOSText.status(stage, timeZone: mess.timeZone),
                                actionTitle: KitchenSOSText.alertAction(stage),
                                onAction: KitchenSOSText.alertAction(stage) == nil ? nil : onOpenSOS)
                    }
                    switch model.state {
                    case .empty where sos.current == nil:
                        StateBlock(symbol: "bell", title: KitchenCopy.nothingNew, message: KitchenCopy.alertsShowHere)
                    case .empty:
                        EmptyView()
                    default:
                        AsyncContentView(state: model.state, timeZone: mess.timeZone, retry: { await model.load() }) { rows in
                            VStack(spacing: 0) {
                                Rectangle().fill(MLColor.border).frame(height: 1)
                                ForEach(rows) { row($0) }
                            }
                        }
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, KitchenLayout.scrollBottomInset)
            }
            .refreshable { await model.load() }
        }
    }


    @ViewBuilder
    private func row(_ alert: KitchenAlert) -> some View {
        let time = alert.at.map { MLFormat.time($0, in: mess.timeZone) } ?? alert.timeText ?? ""
        switch alert.kind {
        case .mealEnded(let meal):
            AlertRow(mark: .filled(symbol: "checkmark"), title: alert.title, time: time, detail: alert.detail,
                     isUnread: alert.isUnread) { open(.recordWaste(meal)) }
        case .shortageSeen:
            AlertRow(mark: .outlined(symbol: "checkmark"), title: alert.title, time: time, detail: alert.detail, isUnread: alert.isUnread)
        case .foodShort:
            AlertRow(mark: .outlined(symbol: "frying.pan"), title: alert.title, time: time, detail: alert.detail, isUnread: alert.isUnread)
        case .wasteNotRecorded(let id):
            AlertRow(mark: .outlined(symbol: "clock"), title: alert.title, time: time, detail: alert.detail,
                     isUnread: alert.isUnread) { open(.pastMeal(id)) }
        }
    }
}

/// Me (K13). Meal history, Language, Help and Sign out. No Switch role row (owner ruling, 7 November).
struct KitchenMeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let session: StaffSession
    let open: (KitchenRoute) -> Void
    @State private var page: StaffMePage?

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    Text(KitchenCopy.me)
                        .font(MLType.largeTitle)
                        .foregroundStyle(MLColor.ink)
                        .padding(.top, MLSize.hit + MLSpacing.s16)
                    profile
                    VStack(spacing: 0) {
                        Rectangle().fill(MLColor.border).frame(height: 1)
                        QuietRow(title: KitchenCopy.historyTitle) { open(.history) }
                        QuietRow(title: KitchenCopy.language, value: KitchenCopy.english) { page = .language }
                        QuietRow(title: KitchenCopy.help) { page = .help }
                        DemoEntryRow()
                        signOutRow
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, KitchenLayout.scrollBottomInset)
            }
        }
        .staffMePages($page, role: MLFormat.roleName(session.role), help: StaffHelpContent.kitchen)
    }

    private var profile: some View {
        HStack(spacing: MLSpacing.s16) {
            Text(session.staffInitials)
                .font(MLType.title2)
                .foregroundStyle(MLColor.lime)
                .frame(width: KitchenLayout.meAvatar, height: KitchenLayout.meAvatar)
                .background(Circle().fill(MLColor.ink))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text(MLFormat.roleName(session.role)).font(MLType.title2).foregroundStyle(MLColor.ink)
                Text(session.mess.name).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                MealProgressChip(text: KitchenCopy.onShift)
            }
        }
    }

    private var signOutRow: some View {
        Button {
            router.reset()
            sessionStore.signOut()
        } label: {
            Text(KitchenCopy.signOut)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
                .frame(maxWidth: .infinity, minHeight: MLSize.staffButton, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
