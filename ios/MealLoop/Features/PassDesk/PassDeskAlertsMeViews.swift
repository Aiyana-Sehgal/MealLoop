import SwiftUI

/// Turns SOS facts into the words the shared SOS components take.
enum PassDeskSOSText {
    static func incident(_ sos: SOSCase, eyebrow: String?, now: Date, timeZone: TimeZone) -> SOSIncident {
        SOSIncident(eyebrow: eyebrow, time: MLFormat.time(sos.raisedAt, in: timeZone),
                    age: PassDeskCopy.minutesAgo(max(0, MLFormat.minutes(from: sos.raisedAt, to: now))),
                    title: sos.title, place: sos.place)
    }

    static func status(_ stage: DoorSOSStage, timeZone: TimeZone) -> SOSCardStatus {
        switch stage {
        case .notTaken:
            return .notTaken(PassDeskCopy.nobodyTaken)
        case .takenByOther(let role):
            return .claimed(PassDeskCopy.isChecking(MLFormat.roleName(role)))
        case .claimedByYou:
            return .claimed(PassDeskCopy.youreChecking)
        case .checkedByYou(let at):
            return .checked(PassDeskCopy.checkedByDesk, time: MLFormat.time(at, in: timeZone))
        }
    }

    static func alertAction(_ stage: DoorSOSStage) -> String? {
        switch stage {
        case .notTaken, .takenByOther: return PassDeskCopy.illGoAndCheck
        case .claimedByYou: return PassDeskCopy.openTheSOS
        case .checkedByYou: return nil
        }
    }
}

/// The SOS panel for the desk (P16). The desk claims and marks checked; only the Supervisor closes a case.
struct PassDeskSOSPanel: View {
    let model: DoorSOSViewModel
    let session: StaffSession
    let now: Date
    let onClose: () -> Void
    let onChecked: () -> Void

    private var timeZone: TimeZone { session.mess.timeZone }

    var body: some View {
        VStack(spacing: MLSpacing.s12) {
            if let current = model.current, let stage = model.stage {
                panel(current, stage)
            }
            if model.didFail {
                FieldErrorText(text: PassDeskCopy.sosFailed)
            }
        }
    }

    @ViewBuilder
    private func panel(_ sos: SOSCase, _ stage: DoorSOSStage) -> some View {
        let incident = PassDeskSOSText.incident(sos, eyebrow: nil, now: now, timeZone: timeZone)
        let status = PassDeskSOSText.status(stage, timeZone: timeZone)
        let title = PassDeskCopy.sosActive(model.cases.count)
        switch stage {
        case .notTaken, .takenByOther:
            SOSPanel(title: title, incident: incident, status: status, helper: PassDeskCopy.sosHelper,
                     primary: .init(title: PassDeskCopy.illGoAndCheck) { Task { await model.claim() } },
                     secondary: .init(title: PassDeskCopy.notNow, handler: onClose),
                     isWorking: model.isWorking, onClose: onClose)
        case .claimedByYou:
            SOSPanel(title: title, incident: incident, status: status, note: PassDeskCopy.onYourWay(session.supervisorName),
                     primary: .init(title: PassDeskCopy.markAsChecked) {
                         Task { if await model.markChecked() { onChecked() } }
                     },
                     secondary: .init(title: PassDeskCopy.backToChecking, handler: onClose),
                     isWorking: model.isWorking, onClose: onClose)
        case .checkedByYou:
            SOSPanel(title: title, incident: incident, status: status,
                     primary: .init(title: PassDeskCopy.backToChecking, handler: onClose), onClose: onClose)
        }
    }
}

/// Alerts (P14): the SOS card on top while one is active, then at most three quiet rows.
struct PassDeskAlertsView: View {
    let model: PassDeskHomeViewModel
    let sos: DoorSOSViewModel
    let now: Date
    let onOpenSOS: () -> Void

    private var mess: Mess { model.session.mess }
    private var alerts: [PassDeskAlert] { PassDeskAlert.alerts(for: model.state.value) }
    private var mealName: String { model.state.value.map { MLFormat.mealSlot($0.meal.slot) } ?? "" }

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    ScreenTitleBlock(title: PassDeskCopy.alerts,
                                     subtitle: model.state.value == nil ? mess.name : "\(mess.name) · \(mealName)")
                        .padding(.top, MLSize.hit + MLSpacing.s16)
                    if let current = sos.current, let stage = sos.stage {
                        SOSCard(incident: PassDeskSOSText.incident(current, eyebrow: PassDeskCopy.sosEyebrow, now: now, timeZone: mess.timeZone),
                                status: PassDeskSOSText.status(stage, timeZone: mess.timeZone),
                                actionTitle: PassDeskSOSText.alertAction(stage),
                                onAction: PassDeskSOSText.alertAction(stage) == nil ? nil : onOpenSOS)
                    }
                    if !alerts.isEmpty {
                        VStack(spacing: 0) {
                            SectionHeader(title: PassDeskCopy.earlier)
                            ForEach(alerts) { row($0) }
                        }
                    } else if sos.current == nil {
                        StateBlock(symbol: "bell", title: PassDeskCopy.nothingNew,
                                   message: PassDeskCopy.alertsShowHere(model.session.supervisorName))
                            .padding(.top, MLSpacing.s32 * 3)
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, PassDeskLayout.scrollBottomInset)
            }
        }
    }

    private func row(_ alert: PassDeskAlert) -> AlertRow {
        let time = MLFormat.time(alert.at, in: mess.timeZone)
        switch alert.kind {
        case .mealStarted:
            return AlertRow(mark: .done, title: PassDeskCopy.mealStarted, time: time,
                            detail: PassDeskCopy.opened(by: model.session.supervisorName, meal: mealName))
        case .newPassApproved(let maskedID):
            return AlertRow(mark: .filled(symbol: "ticket"), title: PassDeskCopy.newPassApproved, time: time,
                            detail: PassDeskCopy.canGetPass(maskedID))
        case .shortageSeen:
            return AlertRow(mark: .outlined(symbol: "frying.pan"), title: PassDeskCopy.foodShortageSeen, time: time,
                            detail: PassDeskCopy.kitchenOnIt)
        }
    }
}

/// Me (PD_me). Language and Help have no screens yet, so they say so; Sign out works.
/// Switch role is left out: the role comes from the account, and the role flow it opened is retired (P-ENTRY-4).
struct PassDeskMeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let model: PassDeskHomeViewModel
    let problems: PassDeskProblemLog
    @State private var comingSoon: PassDeskComingSoon?

    private var session: StaffSession { model.session }

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    Text(PassDeskCopy.me)
                        .font(MLType.largeTitle)
                        .foregroundStyle(MLColor.ink)
                        .padding(.top, MLSize.hit + MLSpacing.s16)
                    profile
                    HStack(spacing: MLSpacing.s12) {
                        tile(PassDeskCopy.passesChecked, value: model.state.value?.count.recorded.value)
                        tile(PassDeskCopy.problemsReported, value: problems.problems.count)
                    }
                    VStack(spacing: 0) {
                        Rectangle().fill(MLColor.border).frame(height: 1)
                        ForEach([PassDeskCopy.language, PassDeskCopy.help], id: \.self) { title in
                            QuietRow(title: title) { comingSoon = PassDeskComingSoon(title: title) }
                        }
                        signOutRow
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, PassDeskLayout.scrollBottomInset)
            }
        }
        .fullScreenCover(item: $comingSoon) { page in
            NotImplementedView(title: page.title, actionTitle: PassDeskCopy.backToHome) { comingSoon = nil }
        }
    }

    private var profile: some View {
        HStack(spacing: MLSpacing.s16) {
            Text(session.staffInitials)
                .font(MLType.title2)
                .foregroundStyle(MLColor.lime)
                .frame(width: PassDeskLayout.meAvatar, height: PassDeskLayout.meAvatar)
                .background(Circle().fill(MLColor.ink))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text(MLFormat.roleName(session.role))
                    .font(MLType.title2)
                    .foregroundStyle(MLColor.ink)
                Text(session.mess.name)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                MealProgressChip(text: PassDeskCopy.onShift)
            }
        }
    }

    /// A missing count shows "—", never 0.
    private func tile(_ label: String, value: Int?) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(label)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(value.map(String.init) ?? "—")
                .font(MLType.heroTitle.monospaced())
                .foregroundStyle(MLColor.ink)
        }
        .padding(MLSpacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }

    private var signOutRow: some View {
        Button {
            router.reset()
            sessionStore.signOut()
        } label: {
            Text(PassDeskCopy.signOut)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
                .frame(maxWidth: .infinity, minHeight: MLSize.staffButton, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A title to show a "Coming soon" page for.
private struct PassDeskComingSoon: Identifiable {
    let title: String

    var id: String { title }
}
