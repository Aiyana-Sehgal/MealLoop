import SwiftUI

/// WV-1 Queue: one card at a time, closest deadline first, with the guardian's evidence and Approve, Ask, No.
struct WardenQueueScreen: View {
    enum Sheet {
        case ask
        case reject
    }

    let model: WardenModel
    let onMe: () -> Void
    let onShowTab: (WardenTab) -> Void
    /// A sheet to open on arrival (screenshot runs only).
    var initialSheet: Sheet?
    var initialAskFields: Set<String> = []
    var initialAskNote = ""
    var initialRejectReason: String?

    @State private var isAsking = false
    @State private var isRejecting = false
    @State private var changeFields: Set<String> = []
    @State private var changeNote = ""
    @State private var rejectReason: String?
    @State private var callNote = ""
    @State private var undoVisible = false

    var body: some View {
        WardenPage(initials: model.profile?.initials ?? "—", title: WardenCopy.decideNext, subtitle: subtitle, onMe: onMe) {
            if model.phase == .offline {
                offlineBanner
            }
            if let result = model.result {
                resultCard(result)
            } else if let current = model.current {
                decisionCard(current)
            } else if model.phase == .loading {
                ProgressView().frame(maxWidth: .infinity, minHeight: 200)
            } else if case .failed(let failure) = model.phase {
                ErrorRetryView(failure: failure) { Task { await model.load() } }
            } else {
                emptyCard
            }
            if let error = model.actionError {
                FieldErrorText(text: error)
            }
        }
        .overlay(alignment: .bottom) {
            if model.result != nil, undoVisible {
                TextLinkButton(title: WardenCopy.undo) { Task { await model.undo() } }
                    .padding(.bottom, 96)
            }
        }
        .task(id: model.result?.outing.id) {
            guard model.result != nil else { return }
            undoVisible = true
            try? await Task.sleep(for: .seconds(10))
            undoVisible = false
        }
        .task {
            switch initialSheet {
            case .ask?:
                changeFields = initialAskFields
                changeNote = initialAskNote
                isAsking = true
            case .reject?:
                rejectReason = initialRejectReason
                isRejecting = true
            case nil:
                break
            }
        }
        .mlSheet(isPresented: $isAsking) { askSheet }
        .mlSheet(isPresented: $isRejecting) { rejectSheet }
    }

    private var block: String { model.profile?.block ?? "—" }

    private var subtitle: String {
        if model.result != nil { return WardenCopy.waitingSubtitle(block: block, count: model.queue.count) }
        guard let current = model.current else { return WardenCopy.nothingWaiting(block: block) }
        if let position = model.position {
            return WardenCopy.queueSubtitle(block: block, position: position, count: model.queue.count)
        }
        let why: String
        switch current.escalation(at: model.now ?? .distantPast) {
        case .noCamera?: why = WardenCopy.fromEscalatedNoCamera
        case .pleaseWatch?: why = WardenCopy.fromEscalatedPleaseWatch
        case .pastDeadline?: why = WardenCopy.fromEscalatedPastDeadline
        case nil: why = WardenCopy.fromEscalatedNoCamera
        }
        return WardenCopy.fromEscalated(block: block, why: why)
    }

    private var offlineBanner: some View {
        HStack(spacing: MLSpacing.s12) {
            Image(systemName: "wifi.slash").accessibilityHidden(true)
            Text(WardenCopy.offlineBanner).font(MLType.body)
            Spacer(minLength: 0)
        }
        .foregroundStyle(MLColor.onHero)
        .padding(.horizontal, MLSpacing.s16)
        .padding(.vertical, MLSpacing.s8)
        .frame(minHeight: MLSize.hit)
        .background(Capsule().fill(MLColor.heroBackground))
        .accessibilityElement(children: .combine)
    }

    // MARK: Card

    private func decisionCard(_ outing: OutingCase) -> some View {
        OutingCard {
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                HStack(spacing: MLSpacing.s16) {
                    DeadlineRing(text: ringText(outing), remaining: model.remainingFraction(of: outing))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(WardenCopy.decideBy).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                        Text(outing.wardenDecideBy.map(OutingFormat.dayHour) ?? "—")
                            .font(MLType.title2)
                            .foregroundStyle(MLColor.ink)
                    }
                }
                .accessibilityElement(children: .combine)
                WardenStudentLine(outing: outing)
                Rectangle().fill(MLColor.border).frame(height: 1)
                WardenEvidenceBlock(outing: outing, videoMode: videoMode, callNote: $callNote,
                                    calledAt: outing.evidence?.capturedAt)
                if let past = WardenCopy.pastAnswers(outing.pastAnswerCounts) {
                    Text(past)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.ink)
                        .padding(.top, MLSpacing.s8)
                }
                actions(outing)
            }
        }
    }

    private var videoMode: OutingVideoTile.Mode {
        if model.phase == .offline { return .unavailable(WardenCopy.videoNeedsConnection) }
        if model.isRefreshing { return .loading(WardenCopy.loadingVideo) }
        return .ready
    }

    private func ringText(_ outing: OutingCase) -> String {
        guard let now = model.now, let deadline = outing.wardenDecideBy else { return "—" }
        return OutingFormat.shortLeft(from: now, to: deadline)
    }

    private var callNoteMissing: Bool {
        model.needsCallNote && callNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @ViewBuilder
    private func actions(_ outing: OutingCase) -> some View {
        let offline = model.phase == .offline
        HStack(spacing: MLSpacing.s8) {
            WardenDecisionButton(title: WardenCopy.approve, style: offline ? .dashed : .ink,
                                 isLoading: model.isWorking) {
                Task { await model.approve(note: callNote) }
            }
            .frame(maxWidth: .infinity)
            .layoutPriority(1)
            WardenDecisionButton(title: WardenCopy.ask, style: offline ? .dashed : .outline) { isAsking = true }
            WardenDecisionButton(title: WardenCopy.no, style: offline ? .dashed : .outline) { isRejecting = true }
        }
        .disabled(offline || callNoteMissing || model.isWorking)
        .padding(.top, MLSpacing.s8)
    }

    // MARK: Sheets

    private var askSheet: some View {
        WardenAskSheet(model: model, fields: $changeFields, note: $changeNote) {
            let fields = WardenCopy.changeOptions.filter { changeFields.contains($0) }
            Task {
                await model.askForChange(fields: fields, note: changeNote, callNote: callNote)
                isAsking = false
                changeFields = []
                changeNote = ""
            }
        } onClose: {
            isAsking = false
        }
    }

    private var rejectSheet: some View {
        WardenRejectSheet(model: model, reason: $rejectReason) {
            guard let reason = rejectReason else { return }
            Task {
                await model.reject(reason: reason, callNote: callNote)
                isRejecting = false
                rejectReason = nil
            }
        } onClose: {
            isRejecting = false
        }
    }

    // MARK: Result and empty

    private func resultCard(_ result: WardenResult) -> some View {
        let name = result.outing.student.firstName ?? result.outing.student.displayName
        let decision = result.outing.wardenDecision
        let title: String
        let detail: String
        switch result.kind {
        case .approved:
            title = WardenCopy.approved
            detail = WardenCopy.approvedDetail(pass: result.outing.pass?.code ?? "—", name: name)
        case .changeAsked:
            title = WardenCopy.changeAsked
            detail = WardenCopy.changeDetail(name: name, fields: decision?.reasons ?? [], note: decision?.note)
        case .rejected:
            title = WardenCopy.rejected
            detail = WardenCopy.rejectedDetail(name: name, reason: decision?.reasons.first ?? "—")
        case .closed:
            title = WardenCopy.closed
            detail = WardenCopy.closedDetail(name: name)
        }
        return VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(MLColor.onHero)
                .frame(width: 52, height: 52)
                .overlay(Circle().stroke(MLColor.onHero, lineWidth: 1.5))
                .accessibilityHidden(true)
            Text(title).font(MLType.heroTitle).foregroundStyle(MLColor.onHero)
            Text(detail).font(MLType.body).foregroundStyle(MLColor.onHeroSecondary)
            Button {
                model.dismissResult()
            } label: {
                Text(result.next.map { WardenCopy.next($0.student.displayName) } ?? WardenCopy.done)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.onHero)
                    .frame(maxWidth: .infinity, minHeight: MLSize.staffButton)
                    .overlay(Capsule().stroke(MLColor.onHero, lineWidth: 1.5))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.heroBackground))
        .accessibilityElement(children: .contain)
    }

    private var emptyCard: some View {
        VStack(spacing: MLSpacing.s12) {
            StateBlock(symbol: "checkmark", title: WardenCopy.nothingToDecide, message: WardenCopy.nothingToDecideDetail)
            HStack(spacing: MLSpacing.s24) {
                TextLinkButton(title: WardenCopy.seeOutNow) { onShowTab(.outNow) }
                TextLinkButton(title: WardenCopy.seeEscalated) { onShowTab(.escalated) }
            }
        }
        .padding(.vertical, MLSpacing.s32)
        .frame(maxWidth: .infinity, minHeight: 420)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
    }
}

/// Initials, name and the outing in one line ("Sat 2–8 PM · Express Avenue Mall").
struct WardenStudentLine: View {
    let outing: OutingCase

    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            OutingAvatar(initials: outing.student.initials)
            VStack(alignment: .leading, spacing: 2) {
                Text(outing.student.displayName).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                Text(summary).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        let window = outing.leaveAt.flatMap { leave in outing.returnBy.map { OutingFormat.window(leave, $0) } }
        return [window ?? "—", outing.place ?? "—"].joined(separator: " · ")
    }
}

/// The guardian's evidence on W01: video, photo and text, or call, with its tag, transcript and checks.
struct WardenEvidenceBlock: View {
    let outing: OutingCase
    var videoMode: OutingVideoTile.Mode = .ready
    @Binding var callNote: String
    var calledAt: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            if outing.stage == .guardianCallRequested {
                callBlock(evidence: nil)
            } else if let evidence = outing.evidence {
                switch evidence.method {
                case .liveVideoAutoChecked, .videoNeedsReview: videoBlock(evidence)
                case .photoAndText: photoBlock(evidence)
                case .confirmedByCall: callBlock(evidence: evidence)
                }
            }
        }
    }

    private func header(_ title: String, tag: String, style: OutingTag.Style) -> some View {
        HStack {
            Text(title).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            Spacer()
            OutingTag(text: tag, style: style)
        }
    }

    private func videoBlock(_ evidence: OutingEvidence) -> some View {
        let checked = evidence.method == .liveVideoAutoChecked
        return VStack(alignment: .leading, spacing: MLSpacing.s12) {
            if checked {
                header(WardenCopy.guardianVideo, tag: WardenCopy.live(duration(evidence)), style: .lime)
            } else {
                header(WardenCopy.guardianVideo, tag: WardenCopy.pleaseWatch, style: .outline)
            }
            OutingVideoTile(mode: videoMode)
            if let transcript = evidence.transcript {
                Text("“\(transcript)”").font(MLType.body).foregroundStyle(MLColor.ink)
            }
            if checked {
                WardenChecks(checks: evidence.passedChecks)
            } else if videoMode == .ready {
                Text(WardenCopy.notMatched).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
            }
        }
    }

    private func photoBlock(_ evidence: OutingEvidence) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            header(WardenCopy.guardianPhoto, tag: WardenCopy.photoAndText, style: .dashed)
            HStack(alignment: .top, spacing: MLSpacing.s12) {
                OutingVideoTile(mode: .face, height: 96)
                    .frame(width: 96)
                VStack(alignment: .leading, spacing: MLSpacing.s4) {
                    Text(WardenCopy.livePhotoTyped).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                    Text("“\(evidence.transcript ?? "—")”").font(MLType.staffBody).foregroundStyle(MLColor.ink)
                    Text(WardenCopy.noVideo).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                }
            }
            WardenChecks(checks: evidence.passedChecks)
        }
    }

    private func callBlock(evidence: OutingEvidence?) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            header(WardenCopy.guardianCall, tag: WardenCopy.confirmedByCall, style: .dashed)
            let number = OutingFormat.orMissing(evidence?.calledNumber ?? outing.guardianPhone)
            if let at = evidence?.capturedAt {
                Text(WardenCopy.called(number, at: "\(OutingFormat.weekday(at)) \(OutingFormat.clock(at))"))
                    .font(MLType.body).foregroundStyle(MLColor.ink)
            } else {
                Text(WardenCopy.toCall(number)).font(MLType.body).foregroundStyle(MLColor.ink)
            }
            if let note = evidence?.callNote {
                WardenNoteBox(label: WardenCopy.noteRequired, text: note)
            } else {
                WardenNoteField(label: WardenCopy.noteRequired, text: $callNote)
            }
        }
    }

    private func duration(_ evidence: OutingEvidence) -> String {
        guard let seconds = evidence.videoSeconds else { return "—" }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

struct WardenChecks: View {
    let checks: [EvidenceCheck]

    var body: some View {
        EvidenceChecksRow(checks: checks.map { ($0, title($0)) })
    }

    private func title(_ check: EvidenceCheck) -> String {
        switch check {
        case .phrase: return WardenCopy.phrase
        case .code: return WardenCopy.code
        case .number: return WardenCopy.number
        }
    }
}

/// Approve (black), Ask and No (outlined); dashed while offline (WV-1 Offline). Each is at least 56 pt tall.
struct WardenDecisionButton: View {
    enum Style {
        case ink
        case outline
        case dashed
    }

    let title: String
    var style: Style
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading { ProgressView().tint(MLColor.onHero) }
            }
            .font(MLType.staffPrimary)
            .foregroundStyle(style == .ink ? MLColor.onHero : (style == .dashed ? MLColor.inkSecondary : MLColor.ink))
            .padding(.horizontal, MLSpacing.s20)
            .frame(minWidth: 72, minHeight: MLSize.staffButton)
            .frame(maxWidth: style == .ink ? .infinity : nil)
            .background {
                switch style {
                case .ink: Capsule().fill(MLColor.ink)
                case .outline: Capsule().stroke(MLColor.ink, lineWidth: 1.5)
                case .dashed: Capsule().stroke(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Reason chips that wrap onto two rows (WV-1 No sheet).
struct WardenChipGrid: View {
    let options: [String]
    let selection: String?
    let onSelect: (String) -> Void

    var body: some View {
        let rows = stride(from: 0, to: options.count, by: 2).map { Array(options[$0..<min($0 + 2, options.count)]) }
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: MLSpacing.s8) {
                    ForEach(row, id: \.self) { option in
                        ChoiceChip(title: option, isSelected: selection == option) { onSelect(option) }
                    }
                }
            }
        }
    }
}

/// A labelled text box ("Note (optional)", "Note (required)").
struct WardenNoteField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(label).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
            TextField("", text: $text, axis: .vertical)
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.ink)
                .lineLimit(1...3)
                .accessibilityLabel(label)
        }
        .padding(MLSpacing.s16)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
        .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).stroke(MLColor.ink, lineWidth: 1.2))
    }
}

/// The note after it was recorded, read only.
struct WardenNoteBox: View {
    let label: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(label).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
            Text(text).font(MLType.staffBody).foregroundStyle(MLColor.ink)
        }
        .padding(MLSpacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).stroke(MLColor.ink, lineWidth: 1.2))
        .accessibilityElement(children: .combine)
    }
}

/// WV-1 Ask (sheet): what should change, an optional note, Send.
struct WardenAskSheet: View {
    let model: WardenModel
    @Binding var fields: Set<String>
    @Binding var note: String
    let onSend: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: WardenCopy.askTitle,
                        subtitle: WardenCopy.askDetail(model.current?.student.firstName ?? "—"), onClose: onClose)
            HStack(spacing: MLSpacing.s8) {
                ForEach(WardenCopy.changeOptions, id: \.self) { option in
                    ChoiceChip(title: option, isSelected: fields.contains(option)) {
                        if fields.contains(option) { fields.remove(option) } else { fields.insert(option) }
                    }
                }
            }
            WardenNoteField(label: WardenCopy.noteOptional, text: $note)
            InkActionButton(title: WardenCopy.send, isLoading: model.isWorking, action: onSend)
                .disabled(fields.isEmpty)
        }
    }
}

/// WV-1 No (sheet): a reason is required.
struct WardenRejectSheet: View {
    let model: WardenModel
    @Binding var reason: String?
    let onReject: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: WardenCopy.rejectTitle,
                        subtitle: WardenCopy.rejectDetail(model.current?.student.firstName ?? "—"), onClose: onClose)
            WardenChipGrid(options: WardenCopy.rejectReasons, selection: reason) { reason = $0 }
            InkActionButton(title: WardenCopy.rejectOuting, isLoading: model.isWorking, action: onReject)
                .disabled(reason == nil)
            OutlineActionButton(title: WardenCopy.cancel, action: onClose)
        }
    }
}
