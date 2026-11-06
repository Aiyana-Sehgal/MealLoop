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

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    ScreenTitleBlock(title: DoorScannerCopy.alerts, subtitle: subtitle)
                        .padding(.top, MLSize.hit + MLSpacing.s16)
                    if let current = sos.current, let stage = sos.stage {
                        SOSCard(incident: DoorSOSText.incident(current, eyebrow: DoorScannerCopy.sosEyebrow, now: now, timeZone: mess.timeZone),
                                status: DoorSOSText.status(stage, timeZone: mess.timeZone),
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
                        StateBlock(symbol: "bell", title: DoorScannerCopy.nothingNew,
                                   message: DoorScannerCopy.alertsShowHere(model.session.supervisorName))
                            .padding(.top, MLSpacing.s32 * 3)
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, DoorLayout.scrollBottomInset)
            }
        }
    }
}

/// Me (D18). Switch role, Language and Help have no screens yet, so they say so; Sign out works.
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
                        .padding(.top, MLSize.hit + MLSpacing.s16)
                    profile
                    HStack(spacing: MLSpacing.s12) {
                        DoorCountTile(label: DoorScannerCopy.recordedIn, value: model.state.value?.recordedCount?.value)
                        DoorCountTile(label: DoorScannerCopy.problemsReported, value: problems.problems.count)
                    }
                    VStack(spacing: 0) {
                        Rectangle().fill(MLColor.border).frame(height: 1)
                        ForEach([DoorScannerCopy.switchRole, DoorScannerCopy.language, DoorScannerCopy.help], id: \.self) { title in
                            QuietRow(title: title) { comingSoon = DoorComingSoon(title: title) }
                        }
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

    private var profile: some View {
        HStack(spacing: MLSpacing.s16) {
            Text(session.staffInitials)
                .font(MLType.title2)
                .foregroundStyle(MLColor.lime)
                .frame(width: DoorLayout.meAvatar, height: DoorLayout.meAvatar)
                .background(Circle().fill(MLColor.ink))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text(MLFormat.roleName(session.role))
                    .font(MLType.title2)
                    .foregroundStyle(MLColor.ink)
                Text(session.mess.name)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                MealProgressChip(text: DoorScannerCopy.onShift)
            }
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
    }
}

/// A title to show a "Coming soon" page for.
private struct DoorComingSoon: Identifiable {
    let title: String

    var id: String { title }
}
