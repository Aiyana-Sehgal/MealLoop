import SwiftUI

// W-6 Alerts (1855:1489): what needs the warden, from the warden's own records. Deadlines come from the queue's
// decide-by times, escalations from the escalated list, overdue returns from the students out now. The frame's
// "Review window opens" row is not drawn: no record holds review windows (a policy, listed in the report).

enum WardenAlertsCopy {
    static let title = "Alerts"
    static let deadline = "Deadline to decide"
    static let escalated = "Escalated to the senior warden"
    static let overdue = "Overdue return"
    static func decideBy(_ student: String, _ when: String) -> String { "\(student) · decide by \(when)" }
    static func missed(_ student: String, _ when: String?) -> String {
        when.map { "\(student) · missed \($0)" } ?? "\(student) · past the reply time"
    }
    static func lateBack(_ student: String, _ when: String) -> String { "\(student) · back by \(when)" }
    static let none = "Nothing needs you right now."
}

struct WardenAlert: Identifiable, Hashable {
    enum Kind: Hashable { case deadline, escalated, overdue }
    let id: String
    let kind: Kind
    let title: String
    let detail: String
    let time: Date?
}

enum WardenAlerts {
    /// Deadlines first, then escalations, then overdue returns, each newest time first. Built only from the records.
    static func alerts(queue: [OutingCase], escalated: [OutingCase], outNow: [OutingCase], now: Date) -> [WardenAlert] {
        func name(_ item: OutingCase) -> String { item.student.firstName.map { "\($0) \(item.student.maskedID)" } ?? "Student \(item.student.maskedID)" }
        let deadlines = queue.compactMap { item -> WardenAlert? in
            guard let by = item.wardenDecideBy, item.stage == .awaitingWarden, now <= by else { return nil }
            return WardenAlert(id: "deadline-\(item.id.rawValue)", kind: .deadline, title: WardenAlertsCopy.deadline,
                               detail: WardenAlertsCopy.decideBy(name(item), OutingFormat.dayHour(by)), time: by)
        }
        let escalations = escalated.map { item in
            let missedAt = item.wardenDecideBy ?? item.guardianReplyBy
            return WardenAlert(id: "escalated-\(item.id.rawValue)", kind: .escalated, title: WardenAlertsCopy.escalated,
                               detail: WardenAlertsCopy.missed(name(item), missedAt.map(OutingFormat.dayHour)), time: missedAt)
        }
        let overdue = outNow.filter { $0.isLate(at: now) }.compactMap { item -> WardenAlert? in
            guard let back = item.returnBy else { return nil }
            return WardenAlert(id: "overdue-\(item.id.rawValue)", kind: .overdue, title: WardenAlertsCopy.overdue,
                               detail: WardenAlertsCopy.lateBack(name(item), OutingFormat.dayHour(back)), time: back)
        }
        return deadlines.sorted { ($0.time ?? .distantPast) < ($1.time ?? .distantPast) } + escalations + overdue
    }
}

struct WardenAlertsScreen: View {
    let model: WardenModel
    let onBack: () -> Void

    private var alerts: [WardenAlert] {
        WardenAlerts.alerts(queue: model.queue, escalated: model.escalated, outNow: model.outNow, now: model.now ?? Date())
    }

    var body: some View {
        WardenPushedPage(title: WardenAlertsCopy.title, subtitle: nil, onBack: onBack) {
            if alerts.isEmpty {
                Text(WardenAlertsCopy.none).mlFont(.body).foregroundStyle(MLColor.inkSecondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(alerts) { alert in
                        row(alert, isLast: alert.id == alerts.last?.id)
                    }
                }
                .padding(.horizontal, MLSpacing.s16)
                .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
            }
        }
    }

    private func row(_ alert: WardenAlert, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: MLSpacing.s12) {
            // W-6 marks every row with the Orbit mark on a quiet tile.
            OrbitMarkView()
                .frame(width: 40, height: 40)
                .background(RoundedRectangle(cornerRadius: MLRadius.icon, style: .continuous).fill(MLColor.fillQuiet))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title).mlFont(.staffBody).fontWeight(.semibold).foregroundStyle(MLColor.ink)
                Text(alert.detail).mlFont(.body).foregroundStyle(MLColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: MLSpacing.s8)
            if let time = alert.time {
                Text(MLFormat.time(time, in: OutingFormat.timeZone)).font(MLType.monoSecondary).foregroundStyle(MLColor.inkSecondary)
            }
        }
        .padding(.vertical, MLSpacing.s16)
        .overlay(alignment: .bottom) { if !isLast { Rectangle().fill(MLColor.border).frame(height: 1) } }
        .accessibilityElement(children: .combine)
    }
}
