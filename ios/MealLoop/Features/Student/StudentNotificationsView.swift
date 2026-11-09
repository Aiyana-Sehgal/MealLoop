import SwiftUI

/// Notifications (221:64480) and its states: Empty (221:65955), Loading (221:66014), Offline (221:66026),
/// Error (221:66048). Unread rows draw a filled icon; read rows an outlined one, as the frames do.
struct StudentNotificationsView: View {
    @State var model: StudentYouViewModel
    let onBack: () -> Void

    /// On `MLScreen`: the system back button and swipe-back pop the page; `onBack` stays for callers.
    var body: some View {
        MLScreen(YouCopy.notifications, bottomClearance: .tabBar) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                content
            }
        }
        .refreshable { await model.loadNotifications() }
        .task { await model.loadNotifications() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.notifications {
        case .idle, .loading:
            YouSkeleton(heights: [90, 72, 90, 90], label: YouCopy.gettingNotifications)
        case .failed(let failure):
            MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
        case .empty:
            empty
        case .loaded, .stale, .offline:
            if case .offline = model.notifications {
                StudentOfflineBanner(text: model.notifications.value == nil ? YouCopy.offline : YouCopy.notificationsOffline)
            }
            let groups = model.notificationGroups
            if model.notifications.value == nil {
                MealsStateCard(symbol: "wifi.slash", title: YouCopy.nothingSaved, detail: "")
            } else if groups.today.isEmpty && groups.earlier.isEmpty {
                empty
            } else {
                section(YouCopy.today, groups.today)
                section(YouCopy.earlier, groups.earlier)
            }
        }
    }

    private var empty: some View {
        MealsStateCard(title: YouCopy.noNotificationsTitle, detail: YouCopy.noNotificationsDetail)
    }

    @ViewBuilder
    private func section(_ title: String, _ notes: [StudentNotification]) -> some View {
        if !notes.isEmpty {
            Text(title)
                .font(StudentType.secondaryMedium)
                .foregroundStyle(MLColor.inkSecondary)
                .padding(.top, title == YouCopy.today ? 0 : MLSpacing.s4)
            ForEach(notes) { note in
                Button { Task { await model.open(note) } } label: {
                    NotificationRow(note: note, when: YouFormat.when(note.at, now: model.now, in: model.timeZone),
                                    isToday: title == YouCopy.today)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct NotificationRow: View {
    let note: StudentNotification
    let when: String
    let isToday: Bool

    private var symbol: String {
        switch note.kind {
        case .outingGuardianApproved: return "checkmark"
        case .outingUpdate: return "person.2.fill"
        case .mealQuestion, .menuChanged: return "fork.knife"
        case .feedbackSeen: return "text.bubble"
        case .specialPass: return "ticket"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: MLSpacing.s16) {
            icon
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(note.title)
                        .font(StudentType.dishName)
                        .foregroundStyle(MLColor.ink)
                    Spacer(minLength: MLSpacing.s8)
                    Text(when)
                        .font(isToday ? StudentType.mono : StudentType.secondary)
                        .foregroundStyle(MLColor.ink)
                }
                Text(note.detail)
                    .font(StudentType.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, MLSpacing.s16)
        .padding(.vertical, MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
        .accessibilityValue(note.isRead ? "" : YouCopy.unread)
    }

    @ViewBuilder
    private var icon: some View {
        let unread = !note.isRead
        let lime = unread && note.kind == .outingGuardianApproved
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(unread && !lime ? MLColor.onHero : MLColor.ink)
            .frame(width: 36, height: 36)
            .background {
                if lime {
                    Circle().fill(MLColor.lime).overlay(Circle().strokeBorder(MLColor.limeOutline, lineWidth: 1.5))
                } else if unread {
                    Circle().fill(MLColor.heroBackground)
                } else {
                    Circle().strokeBorder(MLColor.ink, lineWidth: 1.5)
                }
            }
            .accessibilityHidden(true)
    }
}

/// Times as the You frames write them: "6:52 AM" today, "Yesterday", then the weekday.
enum YouFormat {
    private static func calendar(_ timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func when(_ date: Date, now: Date, in timeZone: TimeZone) -> String {
        let calendar = calendar(timeZone)
        if calendar.isDate(date, inSameDayAs: now) { return StudentFormat.shortTime(date, in: timeZone) }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            return YouCopy.yesterday
        }
        return format(date, "EEE", timeZone)
    }

    /// "Mon 12 Aug".
    static func shortDay(_ date: Date, in timeZone: TimeZone) -> String { format(date, "EEE d MMM", timeZone) }
    /// "August".
    static func month(_ date: Date, in timeZone: TimeZone) -> String { format(date, "MMMM", timeZone) }

    private static func format(_ date: Date, _ template: String, _ timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.timeZone = timeZone
        formatter.dateFormat = template
        return formatter.string(from: date)
    }
}

/// Grey cards while a page loads.
struct YouSkeleton: View {
    let heights: [CGFloat]
    let label: String

    var body: some View {
        VStack(spacing: MLSpacing.s16) {
            ForEach(Array(heights.enumerated()), id: \.offset) { _, height in
                RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous)
                    .fill(MLColor.track.opacity(0.8))
                    .frame(height: height)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}
