import SwiftUI

/// Home: waiting for approval, approved and sent, acknowledged, and couldn't send.
struct VendorHomeView: View {
    let model: VendorHomeViewModel
    let onReload: () async -> Void
    let onAvatar: () -> Void
    let onHistory: () -> Void

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    StaffHeader(initials: VendorFormat.initials(model.account.displayName), onAvatarTap: onAvatar)
                    AsyncContentView(state: model.state,
                                     emptyTitle: VendorCopy.noMealTitle,
                                     emptyMessage: VendorCopy.noMealDetail,
                                     timeZone: model.mess?.timeZone ?? .current,
                                     retry: onReload) { content in
                        VendorHomeBody(content: content, send: model.send,
                                       onAcknowledge: { Task { await model.acknowledge() } },
                                       onHistory: onHistory)
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, 2)
                .padding(.bottom, VendorLayout.tabBarClearance)
            }
            .refreshable { await onReload() }
        }
    }
}

/// The loaded Home. Pure layout: every value comes from `VendorHomeContent`.
struct VendorHomeBody: View {
    let content: VendorHomeContent
    let send: VendorHomeViewModel.SendState
    let onAcknowledge: () -> Void
    let onHistory: () -> Void

    private var timeZone: TimeZone { content.mess.timeZone }
    private func time(_ date: Date) -> String { MLFormat.time(date, in: timeZone) }
    private var hasFailed: Bool { send == .failed }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            ScreenTitleBlock(title: MLFormat.mealSlot(content.meal.slot),
                             subtitle: "\(content.mess.name) · \(MLFormat.timeRange(content.meal.startsAt, content.meal.endsAt, in: timeZone))")
                .padding(.top, MLSpacing.s4)
            chip
            if hasFailed {
                VendorOfflineLine()
            }
            card
            if hasFailed {
                VendorStatusRow(title: VendorCopy.yourReply) { VendorFailedChip() }
                InkActionButton(title: VendorCopy.retry, isLoading: send == .sending, action: onAcknowledge)
                VendorNote(text: VendorCopy.notReached)
            } else if isSentOrAcknowledged {
                VendorNote(text: VendorCopy.approvedOnly)
            }
            if let previous = content.previous {
                VendorStatusRow(title: VendorFormat.previousTitle(previous)) {
                    VendorReplyText(prefix: previous.acknowledgedAt == nil ? nil : VendorCopy.acknowledgedWord,
                                    time: previous.acknowledgedAt.map(time))
                }
            }
            VStack(spacing: 0) {
                Rectangle().fill(MLColor.border).frame(height: 1)
                QuietRow(title: VendorCopy.history, action: onHistory)
            }
        }
    }

    private var isSentOrAcknowledged: Bool {
        switch content.phase {
        case .sent, .acknowledged: return true
        case .notApproved, .approvedNotSent: return false
        }
    }

    @ViewBuilder
    private var chip: some View {
        switch content.phase {
        case .notApproved:
            VendorChip(text: VendorCopy.notApprovedYet, style: .outline)
        case .approvedNotSent:
            VendorChip(text: VendorCopy.notSentYet, style: .outline)
        case .sent:
            VendorChip(text: VendorCopy.sentWaiting, style: .lime)
        case .acknowledged(_, _, let at):
            VendorChip(text: VendorCopy.acknowledged(time(at)), style: .lime)
        }
    }

    @ViewBuilder
    private var card: some View {
        switch content.phase {
        case .notApproved:
            VendorHeadcountCard(eyebrow: VendorCopy.approvedHeadcount, count: nil, label: VendorCopy.waitingForApproval) { EmptyView() }
        case .approvedNotSent:
            VendorHeadcountCard(eyebrow: VendorCopy.approvedHeadcount, count: nil, label: VendorCopy.waitingForSend) { EmptyView() }
        case .sent(let count, let sentAt):
            VendorHeadcountCard(eyebrow: VendorCopy.sent(time(sentAt)), count: count, label: VendorCopy.approvedHeadcount) {
                if !hasFailed {
                    LimeActionButton(title: VendorCopy.acknowledgeReceipt, action: onAcknowledge)
                        .disabled(send == .sending)
                }
            }
        case .acknowledged(let count, let sentAt, let at):
            VendorHeadcountCard(eyebrow: VendorCopy.sentAndAcknowledged(VendorCopy.sent(time(sentAt)), time(at)), count: count,
                                label: VendorCopy.approvedHeadcount) { EmptyView() }
        }
    }
}

/// Small formatting the Vendor screens share.
enum VendorFormat {
    /// "Mess vendor" → "MV". Empty when there is no name, never made up.
    static func initials(_ name: String) -> String {
        String(name.split(separator: " ").prefix(2).compactMap(\.first)).uppercased()
    }

    /// "Breakfast · 410", or "Breakfast · unavailable" with no count.
    static func previousTitle(_ entry: VendorHeadcountEntry) -> String {
        "\(MLFormat.mealSlot(entry.meal.slot)) · \(entry.sentCount.map(String.init) ?? VendorCopy.unavailable)"
    }

    /// "Breakfast · Today · 410".
    static func historyTitle(_ entry: VendorHeadcountEntry) -> String {
        "\(MLFormat.mealSlot(entry.meal.slot)) · \(VendorCopy.today) · \(entry.sentCount.map(String.init) ?? VendorCopy.unavailable)"
    }
}
