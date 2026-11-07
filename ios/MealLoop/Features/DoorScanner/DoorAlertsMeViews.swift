import SwiftUI

/// One row on Alerts. No alerts feed exists yet, so rows are worked out from the meal state and nothing is made up.
struct DoorAlert: Equatable, Identifiable {
    enum Kind: Equatable {
        case mealStarted
        case mealClosed
    }

    let kind: Kind
    let title: String
    let at: Date
    let detail: String

    var id: String { title }

    /// Newest first, at most three (door_scanner_spec.md).
    static func alerts(for content: DoorHomeContent?, supervisorName: String) -> [DoorAlert] {
        guard let content else { return [] }
        let meal = MLFormat.mealSlot(content.meal.slot)
        var alerts: [DoorAlert] = []
        if let startedAt = content.status.startedAt {
            alerts.append(DoorAlert(kind: .mealStarted, title: DoorScannerCopy.mealStarted, at: startedAt,
                                    detail: DoorScannerCopy.opened(by: supervisorName, meal: meal)))
        }
        if case .afterMeal(let finalEntries, let closedAt?, _) = content.phase {
            alerts.append(DoorAlert(kind: .mealClosed, title: DoorScannerCopy.closed(meal), at: closedAt,
                                    detail: finalEntries.value.map(DoorScannerCopy.recordedAtDoor) ?? DoorScannerCopy.unavailable))
        }
        return Array(alerts.sorted { $0.at > $1.at }.prefix(3))
    }
}

/// Alerts (D17): the SOS card on top while one is active, then "Earlier".
struct DoorAlertsView: View {
    let model: DoorHomeViewModel
    let sos: DoorSOSViewModel
    let now: Date
    let onOpenSOS: () -> Void

    private var mess: Mess { model.session.mess }
    private var alerts: [DoorAlert] {
        DoorAlert.alerts(for: model.state.value, supervisorName: model.session.supervisorName)
    }

    private var subtitle: String {
        guard let meal = model.state.value?.meal else { return mess.name }
        return "\(mess.name) · \(MLFormat.mealSlot(meal.slot))"
    }

    /// DS-8 draws a checked case as an outline, with no time. Only the Supervisor closes it.
    private func alertStatus(_ stage: DoorSOSStage) -> SOSCardStatus {
        if case .checkedByYou = stage { return .notTaken(DoorScannerCopy.checkedAlert(model.session.supervisorName)) }
        return DoorSOSText.status(stage, timeZone: mess.timeZone)
    }

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    ScreenTitleBlock(title: DoorScannerCopy.alerts, subtitle: subtitle)
                        .padding(.top, MLSize.hit + MLSpacing.s8)
                    if let current = sos.current, let stage = sos.stage {
                        SOSCard(incident: DoorSOSText.incident(current, eyebrow: DoorScannerCopy.sosEyebrow, now: now, timeZone: mess.timeZone),
                                status: alertStatus(stage),
                                actionTitle: DoorSOSText.alertAction(stage),
                                onAction: DoorSOSText.alertAction(stage) == nil ? nil : onOpenSOS)
                    }
                    if !alerts.isEmpty {
                        VStack(spacing: 0) {
                            SectionHeader(title: DoorScannerCopy.earlier)
                            ForEach(alerts) { alert in
                                AlertRow(mark: alert.kind == .mealStarted ? .done : .outlined(symbol: "clock"), title: alert.title,
                                         time: MLFormat.time(alert.at, in: mess.timeZone), detail: alert.detail)
                            }
                        }
                    } else if sos.current == nil {
                        StateBlock(symbol: "bell", title: DoorScannerCopy.nothingNew, message: DoorScannerCopy.alertsShowHere)
                            .padding(.top, DoorLayout.emptyStateTop)
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, DoorLayout.scrollBottomInset)
            }
        }
    }
}

/// Me (D18). Language and Help have no screens yet, so they say so; Sign out works.
/// Switch role is left out by owner ruling, although the frame draws it: the role comes from the account.
struct DoorMeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let model: DoorHomeViewModel
    let problems: DoorProblemLog
    @State private var comingSoon: DoorComingSoon?

    private var session: StaffSession { model.session }

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    Text(DoorScannerCopy.me)
                        .font(MLType.largeTitle)
                        .foregroundStyle(MLColor.ink)
                        .padding(.top, MLSize.hit + MLSpacing.s8)
                    StaffMeProfile(initials: session.staffInitials, title: MLFormat.roleName(session.role), detail: session.mess.name,
                                   chip: model.shiftStartedAt.map { DoorScannerCopy.onShift(since: MLFormat.time($0, in: session.mess.timeZone)) }
                                       ?? DoorScannerCopy.onShift)
                    HStack(spacing: MLSpacing.s12) {
                        StaffMeTile(label: DoorScannerCopy.recordedIn, value: model.state.value?.recordedCount?.value)
                        StaffMeTile(label: DoorScannerCopy.problemsReported, value: problems.problems.count)
                    }
                    VStack(spacing: 0) {
                        Rectangle().fill(MLColor.border).frame(height: 1)
                        StaffMeRow(title: DoorScannerCopy.language, value: DoorScannerCopy.english) {
                            comingSoon = DoorComingSoon(title: DoorScannerCopy.language)
                        }
                        StaffMeRow(title: DoorScannerCopy.help) { comingSoon = DoorComingSoon(title: DoorScannerCopy.help) }
                        signOutRow
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, DoorLayout.scrollBottomInset)
            }
        }
        .fullScreenCover(item: $comingSoon) { page in
            NotImplementedView(title: page.title, actionTitle: DoorScannerCopy.backToHome) { comingSoon = nil }
        }
    }

    private var signOutRow: some View {
        Button {
            router.reset()
            sessionStore.signOut()
        } label: {
            Text(DoorScannerCopy.signOut)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
                .frame(maxWidth: .infinity, minHeight: MLSize.staffButton, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
    }
}

/// A title to show a "Coming soon" page for.
private struct DoorComingSoon: Identifiable {
    let title: String

    var id: String { title }
}
