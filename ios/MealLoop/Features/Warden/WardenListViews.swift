import SwiftUI

// MARK: - Out now (WV-2)

struct WardenOutNowScreen: View {
    let model: WardenModel
    let onMe: () -> Void
    let onOpen: (WardenRoute) -> Void

    /// W02 draws four rows, then "See all 12".
    private let shownRows = 4

    var body: some View {
        WardenPage(initials: model.profile?.initials ?? "—", title: WardenCopy.outNowTitle, subtitle: subtitle, onMe: onMe) {
            heroCard
            if model.outNow.isEmpty {
                StateBlock(symbol: "figure.walk", title: WardenCopy.nobodyOut, message: WardenCopy.nobodyOutDetail)
                    .padding(.vertical, MLSpacing.s24)
            } else {
                VStack(spacing: 0) {
                    ForEach(model.outNow.prefix(shownRows)) { outing in
                        WardenOutRow(outing: outing, now: model.now) { onOpen(.outNowStudent(outing.id)) }
                    }
                }
                if model.outNow.count > shownRows {
                    QuietRow(title: WardenCopy.seeAll(model.outNow.count)) { onOpen(.outNowAll) }
                }
            }
        }
    }

    private var subtitle: String {
        WardenCopy.outNowSubtitle(block: model.profile?.block ?? "—", day: model.now.map(OutingFormat.dayLong) ?? "—")
    }

    private var heroCard: some View {
        HStack(alignment: .center, spacing: MLSpacing.s24) {
            VStack(alignment: .leading, spacing: MLSpacing.s8) {
                Text(WardenCopy.outNowEyebrow).font(MLType.eyebrow).foregroundStyle(MLColor.onHeroSecondary)
                Text("\(model.outNow.count)").font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundStyle(MLColor.onHero)
            }
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text(WardenCopy.dueBackBy(model.latestDue.map(OutingFormat.hour) ?? "—"))
                    .font(MLType.body).foregroundStyle(MLColor.onHeroSecondary)
                Text("\(model.outNow.count - model.lateCount)").font(MLType.monoBody).foregroundStyle(MLColor.onHero)
                HStack(spacing: MLSpacing.s8) {
                    Text(WardenCopy.late).font(MLType.body).foregroundStyle(MLColor.onHeroSecondary)
                    Text("\(model.lateCount)").font(MLType.monoBody).foregroundStyle(MLColor.lime)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.heroBackground))
        .accessibilityElement(children: .combine)
    }
}

/// One student out: initials, name, back-by, and Late (black) or Due in (outlined) as a label.
struct WardenOutRow: View {
    let outing: OutingCase
    let now: Date?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MLSpacing.s12) {
                OutingAvatar(initials: outing.student.initials)
                VStack(alignment: .leading, spacing: 2) {
                    Text(outing.student.displayName).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                    Text(WardenCopy.backBy(outing.returnBy.map(OutingFormat.hour) ?? "—"))
                        .font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: MLSpacing.s8)
                if let status = WardenOutStatus(outing: outing, now: now) {
                    OutingTag(text: status.text, style: status.isLate ? .ink : .outline)
                }
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
    }
}

/// "Late 12 min" or "Due in 48 min", from the back-by time and now.
struct WardenOutStatus {
    let text: String
    let isLate: Bool

    init?(outing: OutingCase, now: Date?) {
        guard let now, let returnBy = outing.returnBy else { return nil }
        isLate = now > returnBy
        text = isLate ? WardenCopy.lateBy(OutingFormat.span(from: returnBy, to: now))
            : WardenCopy.dueIn(OutingFormat.span(from: now, to: returnBy))
    }
}

struct WardenOutNowAllScreen: View {
    let model: WardenModel
    let onBack: () -> Void
    let onOpen: (OutingRequestID) -> Void

    var body: some View {
        WardenPushedPage(title: WardenCopy.outNowTitle,
                         subtitle: WardenCopy.outNowSubtitle(block: model.profile?.block ?? "—",
                                                             day: model.now.map(OutingFormat.dayLong) ?? "—"),
                         onBack: onBack) {
            VStack(spacing: 0) {
                ForEach(model.outNow) { outing in
                    WardenOutRow(outing: outing, now: model.now) { onOpen(outing.id) }
                }
            }
        }
    }
}

/// WV-2 Out now · one student: the pass and the gate times, and the calls.
struct WardenOutNowStudentScreen: View {
    let model: WardenModel
    let outingID: OutingRequestID
    let onBack: () -> Void

    var body: some View {
        if let outing = model.outNow.first(where: { $0.id == outingID }) {
            let status = WardenOutStatus(outing: outing, now: model.now)
            WardenPushedPage(title: outing.student.displayName,
                             subtitle: "\(outing.student.block ?? "—") · \(status?.text.lowercased() ?? "—")",
                             onBack: onBack) {
                OutingCard {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(WardenCopy.pass(outing.pass?.code ?? "—"))
                            .font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                            .padding(.bottom, MLSpacing.s12)
                        OutingFactRow(label: WardenCopy.outBetween, value: window(outing))
                        OutingFactRow(label: WardenCopy.place, value: outing.place)
                        OutingFactRow(label: WardenCopy.leftGate(outing.exitGate ?? "—"), value: outing.exitAt.map(OutingFormat.clock),
                                      isMono: true)
                        OutingFactRow(label: WardenCopy.backByLabel, value: outing.returnBy.map(OutingFormat.clock),
                                      isMono: true)
                        OutingFactRow(label: WardenCopy.nowLabel, value: status?.text)
                    }
                }
                if let evidence = outing.evidence {
                    HStack {
                        Text(WardenCopy.guardianAnswered).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                        Spacer()
                        WardenMethodTag(method: evidence.method, seconds: evidence.videoSeconds)
                    }
                }
                let name = outing.student.firstName ?? outing.student.displayName
                OutingCallButton(title: WardenCopy.call(name), style: .ink)
                OutingCallButton(title: WardenCopy.callGuardian(name), style: .outline)
                Text(WardenCopy.returnAtGate)
                    .font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                    .frame(maxWidth: .infinity)
            }
        } else {
            WardenPushedPage(title: WardenCopy.outNowTitle, subtitle: nil, onBack: onBack) {
                StateBlock(symbol: "figure.walk", title: WardenCopy.nobodyOut)
            }
        }
    }

    private func window(_ outing: OutingCase) -> String? {
        guard let leave = outing.leaveAt, let back = outing.returnBy else { return nil }
        return OutingFormat.window(leave, back)
    }
}

/// The method label as the warden reads it (W01, W02, W03).
struct WardenMethodTag: View {
    let method: GuardianEvidenceMethod
    var seconds: Int?

    var body: some View {
        switch method {
        case .liveVideoAutoChecked:
            OutingTag(text: WardenCopy.live(seconds.map { String(format: "%d:%02d", $0 / 60, $0 % 60) } ?? "—"), style: .lime)
        case .videoNeedsReview: OutingTag(text: WardenCopy.pleaseWatch, style: .outline)
        case .photoAndText: OutingTag(text: WardenCopy.photoAndText, style: .dashed)
        case .confirmedByCall: OutingTag(text: WardenCopy.confirmedByCall, style: .dashed)
        }
    }
}

// MARK: - Escalated (WV-4)

struct WardenEscalatedScreen: View {
    let model: WardenModel
    let onMe: () -> Void
    let onToast: (String) -> Void
    let onOpenInQueue: (OutingRequestID) -> Void
    /// A call sheet to open on arrival (screenshot runs only).
    var initialCalling: OutingRequestID?

    @State private var calling: OutingCase?

    var body: some View {
        WardenPage(initials: model.profile?.initials ?? "—", title: WardenCopy.escalatedTitle,
                   subtitle: WardenCopy.escalatedSubtitle, onMe: onMe) {
            VStack(spacing: 0) {
                ForEach(model.escalated) { outing in
                    row(outing)
                }
            }
            .overlay(alignment: .top) { Rectangle().fill(MLColor.border).frame(height: 1) }
            Text(WardenCopy.nothingElse)
                .font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, MLSpacing.s16)
        }
        .task {
            if let initialCalling { calling = model.escalated.first { $0.id == initialCalling } }
        }
        .mlSheet(isPresented: Binding(get: { calling != nil }, set: { if !$0 { calling = nil } })) {
            if let calling { callSheet(calling) }
        }
    }

    private func row(_ outing: OutingCase) -> some View {
        let escalation = outing.escalation(at: model.now ?? .distantPast)
        return HStack(spacing: MLSpacing.s12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(outing.student.displayName).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                Text(detail(escalation)).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
            }
            Spacer(minLength: MLSpacing.s8)
            switch escalation {
            case .pleaseWatch?:
                CompactPillButton(title: WardenCopy.watch) { onOpenInQueue(outing.id) }
            default:
                CompactPillButton(title: WardenCopy.callAction) { calling = outing }
            }
        }
        .frame(minHeight: 56)
        .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }

    private func detail(_ escalation: OutingEscalation?) -> String {
        switch escalation {
        case .pastDeadline(let since)?:
            return WardenCopy.pastDeadline(OutingFormat.span(from: since, to: model.now ?? since))
        case .pleaseWatch?: return WardenCopy.videoPleaseWatch
        case .noCamera?: return WardenCopy.noCamera
        case nil: return "—"
        }
    }

    @ViewBuilder
    private func callSheet(_ outing: OutingCase) -> some View {
        let name = outing.student.firstName ?? outing.student.displayName
        let number = OutingFormat.orMissing(outing.guardianPhone)
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            if case .pastDeadline(let since)? = outing.escalation(at: model.now ?? .distantPast) {
                SheetHeader(title: WardenCopy.callSheetTitle(name),
                            subtitle: WardenCopy.callSheetPastDeadline(number,
                                                                       by: OutingFormat.span(from: since, to: model.now ?? since))) {
                    calling = nil
                }
                OutingCallButton(title: WardenCopy.callNumber(number), style: .ink)
                OutlineActionButton(title: WardenCopy.closeTheRequest) {
                    Task {
                        if await model.closeRequest(outing.id) { onToast(WardenCopy.requestClosed) }
                        calling = nil
                    }
                }
            } else {
                SheetHeader(title: WardenCopy.callSheetTitle(name), subtitle: WardenCopy.callSheetNoCamera(number)) {
                    calling = nil
                }
                OutingCallButton(title: WardenCopy.callNumber(number), style: .ink)
                OutlineActionButton(title: WardenCopy.recordTheAnswer) {
                    calling = nil
                    onOpenInQueue(outing.id)
                }
            }
        }
    }
}

// MARK: - History (WV-3)

struct WardenHistoryScreen: View {
    let model: WardenModel
    let onMe: () -> Void
    let onOpen: (String) -> Void
    /// Starts on All (screenshot runs only).
    var startsOnAll = false

    @State private var showsAll = false

    var body: some View {
        WardenPage(initials: model.profile?.initials ?? "—", title: WardenCopy.historyTitle,
                   subtitle: WardenCopy.historySubtitle(block: model.profile?.block ?? "—"), onMe: onMe) {
            HStack(spacing: MLSpacing.s8) {
                WardenFilterPill(title: WardenCopy.thisWeek, isSelected: !showsAll) { showsAll = false }
                WardenFilterPill(title: WardenCopy.all, isSelected: showsAll) { showsAll = true }
            }
            if items.isEmpty {
                StateBlock(symbol: "clock", title: WardenCopy.noHistory)
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        WardenHistoryRow(item: item) { onOpen(item.id) }
                    }
                }
                .overlay(alignment: .top) { Rectangle().fill(MLColor.border).frame(height: 1) }
            }
            Text(WardenCopy.retentionNote)
                .font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, MLSpacing.s16)
        }
        .task { if startsOnAll { showsAll = true } }
    }

    private var items: [WardenHistoryItem] {
        guard !showsAll, let now = model.now else { return model.history }
        return model.history.filter { OutingFormat.isSameWeek($0.decidedOn, now) }
    }
}

struct WardenFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MLType.staffBody)
                .foregroundStyle(isSelected ? MLColor.onHero : MLColor.ink)
                .padding(.horizontal, MLSpacing.s20)
                .frame(minHeight: 48)
                .background {
                    if isSelected { Capsule().fill(MLColor.ink) } else { Capsule().stroke(MLColor.ink, lineWidth: 1.2) }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct WardenHistoryRow: View {
    let item: WardenHistoryItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MLSpacing.s12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.student.displayName).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                    Text("\(OutingFormat.dayShort(item.decidedOn)) · \(WardenCopy.outcome(item.outcome))")
                        .font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: MLSpacing.s8)
                OutingTag(text: WardenCopy.historyMethod(item.method), style: style)
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
    }

    private var style: OutingTag.Style {
        switch item.method {
        case .liveVideoAutoChecked?, .videoNeedsReview?: return .outline
        case .photoAndText?, .confirmedByCall?: return .dashed
        case nil: return .quiet
        }
    }
}

/// WV-3 Record: the decision, the pass and the guardian's evidence; a dashed note once the video is deleted.
struct WardenHistoryRecordScreen: View {
    let model: WardenModel
    let itemID: String
    let onBack: () -> Void

    var body: some View {
        if let item = model.history.first(where: { $0.id == itemID }) {
            WardenPushedPage(title: item.student.displayName,
                             subtitle: "\(OutingFormat.dayLong(item.decidedOn)) · \(WardenCopy.outcome(item.outcome))",
                             onBack: onBack) {
                OutingCard {
                    VStack(spacing: 0) {
                        OutingFactRow(label: WardenCopy.outing, value: outingText(item))
                        OutingFactRow(label: WardenCopy.place, value: item.place)
                        OutingFactRow(label: WardenCopy.youDecided, value: decidedText(item))
                        OutingFactRow(label: WardenCopy.passLabel, value: item.passCode)
                    }
                }
                if let evidence = item.evidence {
                    evidenceCard(evidence)
                    if let deletesAt = evidence.deletesAt {
                        Text(isDeleted(deletesAt) ? WardenCopy.deletedOn(OutingFormat.dayMonth(deletesAt))
                                                  : WardenCopy.deletesOn(OutingFormat.dayMonth(deletesAt)))
                            .font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                    }
                }
            }
        } else {
            WardenPushedPage(title: WardenCopy.historyTitle, subtitle: nil, onBack: onBack) {
                StateBlock(symbol: "clock", title: WardenCopy.noHistory)
            }
        }
    }

    private func isDeleted(_ deletesAt: Date) -> Bool { (model.now ?? .distantPast) >= deletesAt }

    private func outingText(_ item: WardenHistoryItem) -> String? {
        guard let leave = item.leaveAt, let back = item.returnBy else { return nil }
        return "\(OutingFormat.dayLong(leave)) · \(OutingFormat.hours(leave, back))"
    }

    private func decidedText(_ item: WardenHistoryItem) -> String {
        let when = item.decidedAtTime.map { "\(OutingFormat.weekday($0)) \(OutingFormat.clock($0))" }
            ?? OutingFormat.dayLong(item.decidedOn)
        return WardenCopy.decision(WardenCopy.decisionWord(item.outcome), when)
    }

    @ViewBuilder
    private func evidenceCard(_ evidence: OutingEvidence) -> some View {
        OutingCard {
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                HStack {
                    Text(WardenCopy.guardianVideo).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                    Spacer()
                    WardenMethodTag(method: evidence.method, seconds: evidence.videoSeconds)
                }
                if let deletesAt = evidence.deletesAt, isDeleted(deletesAt) {
                    Text(WardenCopy.videoDeleted)
                        .font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                        .padding(MLSpacing.s16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
                            .stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                } else if evidence.method != .confirmedByCall {
                    OutingVideoTile(mode: evidence.method == .photoAndText ? .face : .ready)
                }
                if let transcript = evidence.transcript {
                    Text("“\(transcript)”").font(MLType.body).foregroundStyle(MLColor.ink)
                }
                if !evidence.passedChecks.isEmpty {
                    WardenChecks(checks: evidence.passedChecks)
                }
            }
        }
    }
}

// MARK: - Me (WV-5)

struct WardenMeScreen: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let model: WardenModel
    let onBack: () -> Void
    let onAlerts: () -> Void

    @State private var isSigningOut = false
    @State private var page: StaffMePage?

    var body: some View {
        WardenPushedPage(title: WardenCopy.meTitle, subtitle: nil, onBack: onBack) {
            if let profile = model.profile {
                OutingCard {
                    HStack(spacing: MLSpacing.s16) {
                        Text(profile.initials)
                            .font(MLType.bodyEmphasis)
                            .foregroundStyle(MLColor.lime)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(MLColor.ink))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.title).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                            Text(WardenCopy.staffID(profile.staffID ?? "—"))
                                .font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                OutingCard {
                    VStack(spacing: 0) {
                        OutingFactRow(label: WardenCopy.role, value: WardenCopy.roleName)
                        OutingFactRow(label: WardenCopy.block, value: WardenCopy.blockStudents(profile.block,
                                                                                               profile.blockStudents))
                        OutingFactRow(label: WardenCopy.hours, value: hours(profile))
                        OutingFactRow(label: WardenCopy.escalationsGoTo, value: profile.escalationsGoTo)
                    }
                }
            }
            VStack(spacing: 0) {
                QuietRow(title: WardenCopy.alerts, action: onAlerts)
                QuietRow(title: WardenCopy.help) { page = .help }
                Button {
                    isSigningOut = true
                } label: {
                    Text(WardenCopy.signOut)
                        .font(MLType.staffBody)
                        .foregroundStyle(MLColor.ink)
                        .frame(maxWidth: .infinity, minHeight: MLSize.staffButton, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
            }
            .padding(.top, MLSpacing.s32)
        }
        .mlConfirmDialog(isPresented: $isSigningOut, content: WardenCopy.signOutDialog) {
            isSigningOut = false
            router.reset()
            sessionStore.signOut()
        }
        .staffMePages($page, role: WardenCopy.roleName, help: StaffHelpContent.warden)
    }

    private func hours(_ profile: WardenProfile) -> String? {
        guard let from = profile.hoursFrom, let to = profile.hoursTo else { return nil }
        return MLFormat.timeRange(from, to, in: OutingFormat.timeZone)
    }
}
