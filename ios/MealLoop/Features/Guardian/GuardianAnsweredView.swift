import SwiftUI

/// After the guardian answered: GV-06 Sent (and its variants), GV-01 Already answered, and the G-3 status pages that
/// follow the warden's decision and the gate times. Which one shows comes only from the request's stage and times.
struct GuardianAnsweredView: View {
    let model: GuardianModel
    let justSent: Bool
    let onLanguage: () -> Void
    let onSheet: (GuardianSheet) -> Void

    var body: some View {
        if let request = model.request {
            page(request)
        } else {
            GuardianLayout(model: model, title: GuardianCopy.expiredTitle, subtitle: nil, onLanguage: onLanguage) {
                EmptyView()
            } footer: {
                EmptyView()
            }
        }
    }

    private var name: String { model.studentName }

    @ViewBuilder
    private func page(_ request: OutingCase) -> some View {
        switch request.stage {
        case .awaitingWarden:
            waiting(request)
        case .guardianCallRequested:
            callRequested(request)
        case .guardianRejected:
            rejected(request)
        case .withdrawn:
            withdrawn(request)
        case .guardianAskedChange:
            askedChange(request)
        case .passSigned:
            status(request, dial: .passReady, line: passReadyLine(request), dot: .green,
                   note: GuardianCopy.messageLeavesAndBack(name), showsWithdraw: true)
        case .out:
            status(request, dial: .out, line: leftLine(request), dot: .green, note: GuardianCopy.messageWhenBack(name))
        case .returned:
            returned(request)
        case .wardenRejected:
            notGoing(request)
        case .wardenAskedChange:
            notGoing(request)
        case .awaitingGuardian, .closed:
            GuardianLayout(model: model, title: GuardianCopy.expiredTitle, subtitle: nil, onLanguage: onLanguage) {
                EmptyView()
            } footer: {
                EmptyView()
            }
        }
    }

    // MARK: GV-06 and GV-01 Already answered

    private func waiting(_ request: OutingCase) -> some View {
        let decideBy = request.wardenDecideBy.map(OutingFormat.dayHour) ?? "—"
        return GuardianLayout(model: model, title: justSent ? GuardianCopy.sentTitle : GuardianCopy.alreadyAnswered,
                              subtitle: justSent ? GuardianCopy.decideBy(decideBy) : GuardianCopy.wardenDecidesBy(decideBy),
                              onLanguage: onLanguage) {
            answerCard(request)
            if justSent {
                GuardianStatusLine(text: GuardianCopy.waitingForWarden, dot: .lime)
            }
        } footer: {
            if justSent {
                HStack(spacing: MLSpacing.s32) {
                    TextLinkButton(title: GuardianCopy.withdrawApproval) { onSheet(.withdraw) }
                    OutingCallButton(title: GuardianCopy.callWarden, style: .link)
                }
            } else {
                HStack(spacing: MLSpacing.s32) {
                    TextLinkButton(title: GuardianCopy.withdrawApproval) { onSheet(.withdraw) }
                    TextLinkButton(title: GuardianCopy.pastAnswers) { model.showPastAnswers() }
                }
            }
            if justSent {
                TextLinkButton(title: GuardianCopy.pastAnswers) { model.showPastAnswers() }
            }
        }
    }

    private func answerCard(_ request: OutingCase) -> some View {
        let evidence = request.evidence
        return VStack(alignment: .leading, spacing: MLSpacing.s8) {
            if let evidence {
                OutingVideoTile(mode: evidence.method == .photoAndText ? .face : .ready, height: 176)
                    .padding(.bottom, MLSpacing.s8)
                Text(GuardianCopy.iAccept).font(MLType.title2).foregroundStyle(MLColor.ink)
                Text(GuardianCopy.method(evidence.method)).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            }
            Text(answerTime(request)).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }

    private func answerTime(_ request: OutingCase) -> String {
        guard let at = request.guardianAnswer?.at else { return "—" }
        return "\(OutingFormat.weekday(at)) \(OutingFormat.clock(at))"
    }

    private func iconCard(symbol: String, title: String, lines: [String]) -> some View {
        HStack(spacing: MLSpacing.s16) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(MLColor.ink)
                .frame(width: 88, height: 72)
                .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.fillQuiet))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(MLType.title2).foregroundStyle(MLColor.ink)
                ForEach(lines, id: \.self) { line in
                    Text(line).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }

    private func callRequested(_ request: OutingCase) -> some View {
        GuardianLayout(model: model, title: GuardianCopy.wardenWillCall,
                       subtitle: GuardianCopy.cameraDidNotWork(OutingFormat.orMissing(request.guardianPhone),
                                                               request.wardenDecideBy.map(OutingFormat.dayHour) ?? "—"),
                       onLanguage: onLanguage) {
            iconCard(symbol: "phone", title: GuardianCopy.callRequested, lines: [GuardianCopy.noCamera, answerTime(request)])
            GuardianStatusLine(text: GuardianCopy.waitingForCall, dot: .lime)
        } footer: {
            OutingCallButton(title: GuardianCopy.callWarden, style: .link)
            TextLinkButton(title: GuardianCopy.pastAnswers) { model.showPastAnswers() }
        }
    }

    private func rejected(_ request: OutingCase) -> some View {
        var reason: String?
        if case .rejected(let given)? = request.guardianAnswer?.answer { reason = given }
        return GuardianLayout(model: model, title: GuardianCopy.saidNo(name), subtitle: reason.map(GuardianCopy.reasonLine),
                              onLanguage: onLanguage) {
            iconCard(symbol: "xmark", title: GuardianCopy.iReject, lines: [GuardianCopy.oneTapNoVideoLine, answerTime(request)])
        } footer: {
            OutingCallButton(title: GuardianCopy.callWarden, style: .link)
            TextLinkButton(title: GuardianCopy.pastAnswers) { model.showPastAnswers() }
            GuardianFootnote(text: GuardianCopy.canSendNew(name))
        }
    }

    private func withdrawn(_ request: OutingCase) -> some View {
        GuardianLayout(model: model, title: GuardianCopy.withdrewTitle, subtitle: GuardianCopy.withdrewDetail(name),
                       onLanguage: onLanguage) {
            iconCard(symbol: "arrow.clockwise", title: GuardianCopy.withdrawn,
                     lines: [request.evidence.map { GuardianCopy.was($0.method) } ?? "—",
                             request.withdrawnAt.map { "\(OutingFormat.weekday($0)) \(OutingFormat.clock($0))" } ?? "—"])
        } footer: {
            OutingCallButton(title: GuardianCopy.callWarden, style: .link)
            TextLinkButton(title: GuardianCopy.pastAnswers) { model.showPastAnswers() }
            GuardianFootnote(text: GuardianCopy.canSendNew(name))
        }
    }

    // MARK: G-3 status

    private func askedChange(_ request: OutingCase) -> some View {
        GuardianLayout(model: model, title: GuardianCopy.youAskedChange, subtitle: GuardianCopy.canEdit(name),
                       onLanguage: onLanguage) {
            GuardianDial(request: request, mode: .range, now: model.now)
            GuardianStatusLine(text: GuardianCopy.waitingForChange(name), dot: .amber)
        } footer: {
            GuardianFootnote(text: GuardianCopy.replyAgain)
            OutingCallButton(title: GuardianCopy.callWarden, style: .link)
        }
    }

    private func decidedLine(_ request: OutingCase, approved: Bool) -> String? {
        guard let at = request.wardenDecision?.at else { return nil }
        return approved ? GuardianCopy.wardenApprovedAt(OutingFormat.clock(at)) : GuardianCopy.wardenDecidedAt(OutingFormat.clock(at))
    }

    private func passReadyLine(_ request: OutingCase) -> String {
        GuardianCopy.passIssuedNotLeft(request.pass.map { OutingFormat.clock($0.signedAt) } ?? "—", name)
    }

    private func leftLine(_ request: OutingCase) -> String {
        GuardianCopy.leftGate(name, request.exitGate ?? "—", request.exitAt.map(OutingFormat.clock) ?? "—")
    }

    private func status(_ request: OutingCase, dial: GuardianDial.Mode, line: String, dot: GuardianStatusLine.Dot,
                        note: String, showsWithdraw: Bool = false) -> some View {
        GuardianLayout(model: model, title: GuardianCopy.youApproved, subtitle: decidedLine(request, approved: true),
                       onLanguage: onLanguage) {
            GuardianDial(request: request, mode: dial, now: model.now)
            GuardianStatusLine(text: line, dot: dot)
        } footer: {
            GuardianFootnote(text: note)
            HStack(spacing: MLSpacing.s32) {
                if showsWithdraw {
                    TextLinkButton(title: GuardianCopy.withdrawApproval) { onSheet(.withdraw) }
                }
                OutingCallButton(title: GuardianCopy.callWarden, style: .link)
            }
        }
    }

    @ViewBuilder
    private func returned(_ request: OutingCase) -> some View {
        let back = request.returnAt.map(OutingFormat.clock) ?? "—"
        if let returnBy = request.returnBy, let returnAt = request.returnAt, returnAt > returnBy {
            let span = OutingFormat.span(from: returnBy, to: returnAt)
            GuardianLayout(model: model, title: GuardianCopy.youApproved, subtitle: decidedLine(request, approved: true),
                           onLanguage: onLanguage) {
                GuardianDial(request: request, mode: .backLate(span), now: model.now)
                GuardianStatusLine(text: GuardianCopy.wasLate(name, span), dot: .amber)
            } footer: {
                GuardianFootnote(text: GuardianCopy.wasBackAt(name, back))
                OutingCallButton(title: GuardianCopy.callWarden, style: .link)
            }
        } else {
            status(request, dial: .back, line: GuardianCopy.isBack(name, back), dot: .lime, note: GuardianCopy.outingClosed)
        }
    }

    private func notGoing(_ request: OutingCase) -> some View {
        let decision = request.wardenDecision
        let reasons = decision?.reasons.joined(separator: ", ") ?? "—"
        let isChange = request.stage == .wardenAskedChange
        return GuardianLayout(model: model, title: GuardianCopy.youApproved, subtitle: decidedLine(request, approved: false),
                              onLanguage: onLanguage) {
            GuardianDial(request: request, mode: isChange ? .range : .notGoing, now: model.now)
            GuardianStatusLine(text: isChange ? GuardianCopy.wardenAskedChange(reasons) : GuardianCopy.wardenDidNotApprove,
                               dot: isChange ? .amber : .red)
        } footer: {
            if !isChange {
                GuardianFootnote(text: GuardianCopy.wardenReason(reasons, name))
            }
            OutingCallButton(title: GuardianCopy.callWarden, style: .link)
        }
    }
}

/// A coloured dot and a line of plain text (G-3, GV-06). Status is never a button.
struct GuardianStatusLine: View {
    enum Dot {
        case lime
        case green
        case amber
        case red
    }

    let text: String
    let dot: Dot

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s12) {
            Circle()
                .fill(color)
                .overlay(Circle().stroke(dot == .lime ? MLColor.limeOutline : .clear, lineWidth: 1))
                .frame(width: 12, height: 12)
            Text(text).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
        }
        .accessibilityElement(children: .combine)
    }

    /// Green, amber and red are the drawn status colours of G-3; they are not in the token set (see the report).
    private var color: Color {
        switch dot {
        case .lime: return MLColor.lime
        case .green: return Color(hex: 0x1E7A55)
        case .amber: return Color(hex: 0x9A6A00)
        case .red: return MLColor.danger
        }
    }
}

/// The 12-hour dial of G-3: the outing's hours as a lime arc, with the state in the middle.
struct GuardianDial: View {
    enum Mode: Equatable {
        case passReady
        case out
        case back
        case backLate(String)
        case notGoing
        case range
    }

    let request: OutingCase
    let mode: Mode
    let now: Date?

    var body: some View {
        ZStack {
            switch mode {
            case .back:
                Circle().stroke(MLColor.ink, lineWidth: 30)
            case .notGoing:
                Circle().stroke(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
            default:
                Circle().stroke(MLColor.track, lineWidth: 30)
                if let start, let end {
                    Circle().trim(from: start, to: end)
                        .stroke(MLColor.ink, style: StrokeStyle(lineWidth: 34, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Circle().trim(from: start, to: end)
                        .stroke(MLColor.lime, style: StrokeStyle(lineWidth: 30, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    knob(at: start)
                    knob(at: end)
                    // The dot is now, on the outing's arc (G-3 Out).
                    if mode == .out, let now {
                        dot(at: OutingFormat.dialFraction(now))
                    }
                }
            }
            VStack {
                Text("12").font(MLType.monoBody).foregroundStyle(MLColor.inkSecondary)
                Spacer()
                Text("6").font(MLType.monoBody).foregroundStyle(MLColor.inkSecondary)
            }
            .padding(.vertical, 34)
            center
        }
        .frame(width: 260, height: 260)
        .frame(maxWidth: .infinity)
        .padding(.vertical, MLSpacing.s8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var start: CGFloat? { request.leaveAt.map { CGFloat(OutingFormat.dialFraction($0)) } }
    private var end: CGFloat? { request.returnBy.map { CGFloat(OutingFormat.dialFraction($0)) } }

    private func point(_ fraction: CGFloat) -> CGPoint {
        let angle = (fraction * 2 * .pi) - .pi / 2
        return CGPoint(x: 130 + cos(angle) * 130, y: 130 + sin(angle) * 130)
    }

    private func knob(at fraction: CGFloat) -> some View {
        Circle().fill(MLColor.surface).overlay(Circle().stroke(MLColor.ink, lineWidth: 2))
            .frame(width: 30, height: 30).position(point(fraction))
    }

    private func dot(at fraction: Double) -> some View {
        Circle().fill(MLColor.ink).frame(width: 14, height: 14).position(point(CGFloat(fraction)))
    }

    @ViewBuilder
    private var center: some View {
        let name = request.student.firstName ?? request.student.displayName
        switch mode {
        case .passReady:
            VStack(spacing: 2) {
                Text(GuardianCopy.backByDial).font(MLType.staffBody).foregroundStyle(MLColor.inkSecondary)
                Text(request.returnBy.map(OutingFormat.hour) ?? "—").font(.system(size: 36, weight: .bold)).foregroundStyle(MLColor.ink)
                Text(GuardianCopy.dialName(name, request.leaveAt.map(OutingFormat.dayLong) ?? "—"))
                    .font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            }
        case .out:
            VStack(spacing: MLSpacing.s4) {
                Text(GuardianCopy.outSince(request.exitAt.map(OutingFormat.clock) ?? "—"))
                    .font(MLType.staffBody).foregroundStyle(MLColor.inkSecondary)
                Text(GuardianCopy.backByTime(request.returnBy.map(OutingFormat.hour) ?? "—"))
                    .font(MLType.title2).foregroundStyle(MLColor.ink)
            }
        case .back:
            VStack(spacing: MLSpacing.s8) {
                Image(systemName: "checkmark").font(.system(size: 28)).foregroundStyle(MLColor.ink)
                Text(GuardianCopy.backAt(request.returnAt.map(OutingFormat.clock) ?? "—"))
                    .font(MLType.title2).foregroundStyle(MLColor.ink)
            }
        case .backLate(let span):
            VStack(spacing: 2) {
                Text(GuardianCopy.back).font(MLType.staffBody).foregroundStyle(MLColor.inkSecondary)
                Text(GuardianCopy.minLate(span)).font(MLType.title2).foregroundStyle(Color(hex: 0x9A6A00))
            }
        case .notGoing:
            Text(GuardianCopy.notGoing).font(MLType.title2).foregroundStyle(MLColor.ink)
        case .range:
            VStack(spacing: 2) {
                Text(request.leaveAt.flatMap { leave in request.returnBy.map { OutingFormat.arrowHours(leave, $0) } } ?? "—")
                    .font(.system(size: 30, weight: .bold)).foregroundStyle(MLColor.ink)
                if let leave = request.leaveAt, let back = request.returnBy {
                    Text(GuardianCopy.hoursLong(Int(back.timeIntervalSince(leave) / 3600)))
                        .font(MLType.staffBody).foregroundStyle(MLColor.inkSecondary)
                }
            }
        }
    }

    private var accessibilityText: String {
        guard let leave = request.leaveAt, let back = request.returnBy else { return "Outing hours not available" }
        return "Outing \(OutingFormat.hours(leave, back))"
    }
}
