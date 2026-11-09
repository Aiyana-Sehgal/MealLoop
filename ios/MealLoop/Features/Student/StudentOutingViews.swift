import SwiftUI

/// Words of the Student outing frames (page 07, "O · Outings · new"). Wording, not data: places, times, codes and
/// stages come from `StudentOutingRepository`.
enum OutingStudentCopy {
    static let title = "Outings"
    static let subtitle = "Your guardian, then the warden, approve each one"
    static let newOuting = "New outing"
    static let now = "Now"
    static let earlier = "Earlier"
    static let noneTitle = "No outings yet"
    static let noneDetail = "Ask for one with New outing. Your guardian answers first, then the warden."
    static let offline = "You're offline. These are the outings you last saw."
    static let notOnTitle = "Outings aren't on yet"
    /// 1848:22321 names "the Block B warden"; the block of a student without outings is not known here.
    static let notOnDetail = "Opens when your hostel turns it on. Until then, ask your warden in person."
    static let noGuardianTitle = "Add your guardian first"
    static let noGuardianDetail = "Ask the hostel office. They link your guardian's number."
    static let cantSendNoGuardian = "Can't send without a guardian"
    static let duplicateTitle = "You already have an outing that day"
    static let duplicateDetail = "Change that one or pick another day."
    static func seeOuting(_ weekday: String) -> String { "See your \(weekday) outing" }
    static let pickAnotherDay = "Pick another day to send"
    static let needsConnection = "Needs a connection to send"
    static let newSubtitle = "Pick a day. The card below shows what happens next."
    static let outBetween = "Out between"
    static let destination = "Destination"
    static let reasons = ["Family", "Shopping", "Medical", "Other"]
    static let whatHappensNext = "What happens next"
    static let guardian = "Guardian"
    static let warden = "Warden"
    static let youreOut = "You're out"
    static let sendToGuardian = "Send to guardian"
    static let sending = "Sending…"
    static let sent = "Sent"
    static let pass = "Pass"
    /// 1848:22602 says "We'll tell you when your guardian replies"; the prototype sends no notification, so it says
    /// where the answer shows.
    static let sentNote = "Your guardian's answer shows on this request."
    static let seeRequest = "See your request"
    static func outingTitle(_ weekday: String) -> String { "\(weekday) outing" }
    static let needChange = "Need to change something?"
    static let editingAsksAgain = "Editing asks your guardian again."
    static let cancelRequest = "Cancel request"
    /// 1848:22912 says "Your guardian and the Block B warden are told."; nothing is sent in the prototype.
    static let cancelSheet = "The request is cancelled in the outing record. You can send a new request any time."
    static let cancelOuting = "Cancel outing"
    static let keepIt = "Keep it"
    static let cancelled = "Cancelled"
    static let guardianRepliesBy = "Guardian replies by"
    static let wardenDecidesBy = "Warden decides by"
    static func inTime(_ left: String) -> String { "in \(left)" }
    static let pastReplyTime = "Past the reply time"
    static let notApproved = "Not approved. A person looks at it."
    static let passTitle = "Outing pass"
    static let passSubtitle = "Approved by your guardian and warden"
    static let passBrand = "MEALLOOP · OUTING PASS"
    static let valid = "Valid"
    static let leave = "Leave"
    static let backBy = "Back by"
    static let gate = "Gate"
    static let passCode = "Pass"
    static let student = "Student"
    static let showAtGate = "Show at the gate"
    static let faceCheck = "Security checks your face with this pass."
    static let cancelPass = "Cancel pass"
    static let qrUnavailable = "The QR can't be drawn. Show the pass code."
    static func backAt(_ time: String, onTime: Bool) -> String { "Back \(time) · \(onTime ? "on time" : "late")" }
    static let wardenSaidNo = "The warden said no"
    static let guardianSaidNo = "Your guardian said no"
    static let returned = "Returned"
    static let rejected = "Rejected"

    /// The status line, from the repository's stage only.
    static func status(_ item: OutingCase) -> String {
        switch item.stage {
        case .awaitingGuardian: return "Waiting for your guardian"
        case .guardianCallRequested: return "The warden will call your guardian"
        case .guardianAskedChange: return "Your guardian asked for a change"
        case .guardianRejected: return guardianSaidNo
        case .awaitingWarden:
            switch item.evidence?.method {
            case .liveVideoAutoChecked?: return "Guardian approved by video"
            case .videoNeedsReview?: return "Guardian approved by video · the warden watches it"
            case .photoAndText?: return "Guardian approved by photo and code"
            case .confirmedByCall?: return "Guardian confirmed by call"
            case nil: return "Waiting for the warden"
            }
        case .wardenAskedChange: return "The warden asked for a change"
        case .wardenRejected: return wardenSaidNo
        case .passSigned: return "Approved · show your pass at the gate"
        case .out: return "Out"
        case .returned: return "Back"
        case .withdrawn: return cancelled
        case .closed: return "Closed by the warden"
        }
    }

    /// The short chip on a card and the You row.
    static func chip(_ stage: OutingStage) -> String {
        switch stage {
        case .awaitingGuardian, .guardianCallRequested: return "Waiting for your guardian"
        case .guardianAskedChange, .wardenAskedChange: return "Change asked"
        case .awaitingWarden: return "Waiting for the warden"
        case .passSigned: return "Approved"
        case .out: return "Out"
        case .returned: return returned
        case .guardianRejected, .wardenRejected: return rejected
        case .withdrawn: return cancelled
        case .closed: return "Closed"
        }
    }
}

// MARK: - Outings list

/// You · Outings (1848:22270), Empty (1848:22303), Not enabled (1848:22321). The Emergency card is not built.
struct StudentOutingsView: View {
    @State var model: StudentOutingsViewModel
    let onNew: () -> Void
    let onOpen: (OutingRequestID) -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    YouLargeHeader(title: OutingStudentCopy.title, subtitle: OutingStudentCopy.subtitle, onBack: onBack)
                    content
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, StudentMetric.scrollBottom)
            }
            .refreshable { await model.load() }
            StudentScrollFade()
        }
        .task { await model.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.outings {
        case .idle, .loading:
            YouSkeleton(heights: [56, 127, 300], label: OutingStudentCopy.title)
        case .failed(let failure):
            MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
        case .empty:
            OutingNoticeCard(symbol: "lock", title: OutingStudentCopy.notOnTitle, detail: OutingStudentCopy.notOnDetail)
        case .loaded(let outings), .stale(let outings, _):
            page(outings)
        case .offline(let outings, _):
            StudentOfflineBanner(text: OutingStudentCopy.offline)
            if let outings { page(outings) }
        }
    }

    @ViewBuilder
    private func page(_ outings: StudentOutings) -> some View {
        switch outings.eligibility {
        case .notEnabled:
            OutingNoticeCard(symbol: "lock", title: OutingStudentCopy.notOnTitle, detail: OutingStudentCopy.notOnDetail)
        case .noGuardian:
            OutingNoticeCard(symbol: "exclamationmark.triangle", title: OutingStudentCopy.noGuardianTitle,
                             detail: OutingStudentCopy.noGuardianDetail)
        case .enabled:
            InkActionButton(title: OutingStudentCopy.newOuting, action: onNew)
                .accessibilityIdentifier("student.outings.new")
            if outings.current.isEmpty && outings.earlier.isEmpty {
                MealsStateCard(symbol: "figure.walk", title: OutingStudentCopy.noneTitle, detail: OutingStudentCopy.noneDetail)
            }
            if !outings.current.isEmpty {
                section(OutingStudentCopy.now)
                ForEach(outings.current) { item in currentCard(item) }
            }
            if !outings.earlier.isEmpty {
                section(OutingStudentCopy.earlier)
                VStack(spacing: 0) {
                    ForEach(Array(outings.earlier.enumerated()), id: \.element.id) { index, past in
                        if index > 0 { YouDivider() }
                        earlierRow(past)
                    }
                }
                .padding(.horizontal, MLSpacing.s16)
                .padding(.vertical, MLSpacing.s4)
                .background(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous).fill(MLColor.surface))
            }
        }
    }

    private func section(_ text: String) -> some View {
        Text(text).font(StudentType.section.weight(.regular)).foregroundStyle(MLColor.ink).accessibilityAddTraits(.isHeader)
    }

    private func currentCard(_ item: OutingCase) -> some View {
        Button { onOpen(item.id) } label: {
            HStack(spacing: MLSpacing.s16) {
                ZStack {
                    Circle().fill(MLColor.heroBackground).frame(width: 72, height: 72)
                    OutingLoopRing(stage: item.stage, size: 46, lineWidth: 5, showsLabels: false)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: MLSpacing.s4) {
                    Text(OutingStudentCopy.outingTitle(item.leaveAt.map { OutingFormat.format(long: $0) } ?? OutingStudentCopy.title))
                        .font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                    Text(OutingCardFormat.line(item)).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(OutingStudentCopy.chip(item.stage))
                        .font(StudentType.footnote).foregroundStyle(MLColor.onHero)
                        .padding(.horizontal, 10).frame(height: 26)
                        .background(Capsule().fill(MLColor.inkSecondary))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(MLColor.ink)
                    .accessibilityHidden(true)
            }
            .padding(MLSpacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous).fill(MLColor.surface))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("student.outings.current")
    }

    private func earlierRow(_ past: StudentPastOuting) -> some View {
        let isReturned: Bool
        let detail: String
        switch past.outcome {
        case .returned(let at, let onTime):
            isReturned = true
            detail = OutingStudentCopy.backAt(OutingFormat.clock(at), onTime: onTime)
        case .wardenSaidNo:
            isReturned = false
            detail = OutingStudentCopy.wardenSaidNo
        case .guardianSaidNo:
            isReturned = false
            detail = OutingStudentCopy.guardianSaidNo
        }
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text([OutingFormat.dayMonth(past.day), past.reason].compactMap { $0 }.joined(separator: " · "))
                    .font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                Text(detail).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
            }
            Spacer(minLength: MLSpacing.s8)
            Text(isReturned ? OutingStudentCopy.returned : OutingStudentCopy.rejected)
                .font(StudentType.footnote)
                .foregroundStyle(isReturned ? MLColor.onLime : MLColor.onHero)
                .padding(.horizontal, 12).frame(height: 26)
                .background(Capsule().fill(isReturned ? MLColor.lime : MLColor.ink))
        }
        .padding(.vertical, MLSpacing.s12)
        .accessibilityElement(children: .combine)
    }
}

/// "Sat 17 Aug · 2–8 PM · Express Avenue Mall", leaving out what the request does not have.
enum OutingCardFormat {
    static func line(_ item: OutingCase) -> String {
        var parts: [String] = []
        if let leave = item.leaveAt {
            parts.append(OutingFormat.dayMonth(leave))
            if let back = item.returnBy { parts.append(OutingFormat.hours(leave, back)) }
        }
        if let place = item.place { parts.append(place) }
        return parts.joined(separator: " · ")
    }
}

private extension OutingFormat {
    /// "Saturday".
    static func format(long date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

/// The dashed notice card (Not enabled 1848:22324, Blocked 1874:136570).
struct OutingNoticeCard: View {
    let symbol: String
    let title: String
    let detail: String
    var link: (title: String, action: () -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            HStack(alignment: .top, spacing: MLSpacing.s8) {
                Image(systemName: symbol).font(.system(size: 17)).foregroundStyle(MLColor.ink).accessibilityHidden(true)
                Text(title).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
            }
            Text(detail).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let link {
                Button(link.title, action: link.action)
                    .font(StudentType.secondaryMedium).underline().foregroundStyle(MLColor.ink)
                    .frame(minHeight: MLSize.hit)
            }
        }
        .padding(MLSpacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(MLColor.surface))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(MLColor.ink, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
        .accessibilityElement(children: .contain)
    }
}

// MARK: - New outing

/// New outing (1915:130814–1915:131873), Offline (1848:22423), No guardian (1848:22466), Duplicate (1848:22513),
/// Sending (1848:22561). The rule tag and the ribbon's deadline times are not drawn: the rules are open (P3).
struct StudentNewOutingView: View {
    @State var model: StudentOutingsViewModel
    let onSent: (OutingCase) -> Void
    let onOpen: (OutingRequestID) -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    YouLargeHeader(title: OutingStudentCopy.newOuting, subtitle: OutingStudentCopy.newSubtitle, onBack: onBack)
                    if model.isOffline { StudentOfflineBanner(text: OutingStudentCopy.needsConnection) }
                    if model.outings.value?.eligibility == .noGuardian {
                        OutingNoticeCard(symbol: "exclamationmark.triangle", title: OutingStudentCopy.noGuardianTitle,
                                         detail: OutingStudentCopy.noGuardianDetail)
                    }
                    if let duplicate = model.duplicate {
                        OutingNoticeCard(symbol: "exclamationmark.triangle", title: OutingStudentCopy.duplicateTitle,
                                         detail: OutingStudentCopy.duplicateDetail,
                                         link: (OutingStudentCopy.seeOuting(duplicate.leaveAt.map(OutingFormat.weekdayLong) ?? ""),
                                                { onOpen(duplicate.id) }))
                    }
                    dayStrip
                    HStack {
                        Text(OutingStudentCopy.outBetween).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
                        Spacer()
                        Text("\(OutingRangeSlider.label(model.leaveHour)) – \(OutingRangeSlider.label(model.backHour))")
                            .font(StudentType.mono).foregroundStyle(MLColor.ink)
                    }
                    OutingRangeSlider(low: $model.leaveHour, high: $model.backHour)
                    TextField(OutingStudentCopy.destination, text: $model.place)
                        .font(StudentType.body)
                        .padding(.horizontal, MLSpacing.s20)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(MLColor.surface))
                        .accessibilityIdentifier("student.outings.destination")
                    reasonChips
                    // What happens next (student_outing_01_what_happens_next): the guardian is next; nothing is reached early.
                    OutingNextStepsCard(stage: nil, window: model.selectedDay == nil ? nil
                                        : "\(OutingRangeSlider.label(model.leaveHour)) – \(OutingRangeSlider.label(model.backHour))")
                    OutingNothingByWaiting()
                    if case .failed(let message) = model.send {
                        Text(message).font(StudentType.footnote).foregroundStyle(MLColor.danger)
                    }
                    sendButton
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, StudentMetric.scrollBottom)
            }
            StudentScrollFade()
        }
        .task { await model.load() }
    }

    private var dayStrip: some View {
        HStack(spacing: 6) {
            ForEach(model.weekDays, id: \.self) { day in
                let selected = model.selectedDay.map { OutingFormat.isSameDay($0, day) } == true
                let past = model.isPast(day)
                Button { model.selectedDay = day } label: {
                    VStack(spacing: 2) {
                        Text(String(OutingFormat.weekday(day).prefix(1))).font(StudentType.footnote)
                        Text(OutingFormat.dayNumber(day)).font(StudentType.bodySemibold)
                    }
                    .foregroundStyle(selected ? MLColor.onHero : (past ? MLColor.inkSecondary : MLColor.ink))
                    .frame(maxWidth: .infinity).frame(height: 64)
                    .background(Capsule().fill(selected ? MLColor.ink : (past ? MLColor.track : MLColor.surface)))
                }
                .buttonStyle(.plain)
                .disabled(past)
                .accessibilityLabel(OutingFormat.dayMonth(day))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private var reasonChips: some View {
        HStack(spacing: MLSpacing.s8) {
            ForEach(OutingStudentCopy.reasons, id: \.self) { reason in
                let selected = model.reason == reason
                Button { model.reason = selected ? nil : reason } label: {
                    Text(reason).font(StudentType.secondaryMedium).foregroundStyle(MLColor.ink)
                        .lineLimit(1).minimumScaleFactor(0.8)
                        .padding(.horizontal, 12).frame(height: 44).frame(maxWidth: .infinity)
                        .background(Capsule().fill(selected ? MLColor.lime : MLColor.surface))
                        .overlay(Capsule().strokeBorder(MLColor.ink, lineWidth: selected ? 1 : 1.5))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    @ViewBuilder
    private var sendButton: some View {
        if model.outings.value?.eligibility == .noGuardian {
            dashedButton(OutingStudentCopy.cantSendNoGuardian)
        } else if model.isOffline {
            dashedButton(OutingStudentCopy.needsConnection)
        } else if model.duplicate != nil {
            dashedButton(OutingStudentCopy.pickAnotherDay)
        } else {
            InkActionButton(title: model.send == .sending ? OutingStudentCopy.sending : OutingStudentCopy.sendToGuardian,
                            isLoading: model.send == .sending) {
                Task { if let made = await model.sendRequest() { onSent(made) } }
            }
            .disabled(!model.canSend)
            .accessibilityIdentifier("student.outings.send")
        }
    }

    private func dashedButton(_ text: String) -> some View {
        Text(text).font(StudentType.bodySemibold).foregroundStyle(MLColor.inkSecondary)
            .frame(maxWidth: .infinity).frame(height: 56)
            .overlay(Capsule().strokeBorder(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
            .accessibilityAddTraits(.isStaticText)
    }
}

private extension OutingFormat {
    static func dayNumber(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return String(calendar.component(.day, from: date))
    }

    static func weekdayLong(_ date: Date) -> String { format(long: date) }
}

/// RangeSlider (New outing): two thumbs on whole hours, 6 AM to 10 PM as drawn.
struct OutingRangeSlider: View {
    @Binding var low: Int
    @Binding var high: Int
    static let range = 6...22

    static func label(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        return "\(h) \(hour < 12 ? "AM" : "PM")"
    }

    var body: some View {
        VStack(spacing: MLSpacing.s4) {
            GeometryReader { geometry in
                let width = geometry.size.width - 32
                let span = CGFloat(Self.range.upperBound - Self.range.lowerBound)
                let x: (Int) -> CGFloat = { 16 + width * CGFloat($0 - Self.range.lowerBound) / span }
                let hour: (CGFloat) -> Int = { location in
                    let value = Int(((location - 16) / width * span).rounded()) + Self.range.lowerBound
                    return min(max(value, Self.range.lowerBound), Self.range.upperBound)
                }
                ZStack(alignment: .leading) {
                    Capsule().fill(MLColor.surface).overlay(Capsule().strokeBorder(MLColor.ink, lineWidth: 1))
                        .frame(height: 10).padding(.horizontal, 10)
                    Capsule().fill(MLColor.lime).frame(width: max(0, x(high) - x(low)), height: 10).offset(x: x(low))
                    thumb.position(x: x(low), y: 16)
                        .gesture(DragGesture().onChanged { low = min(hour($0.location.x), high - 1) })
                        .accessibilityElement()
                        .accessibilityLabel(OutingStudentCopy.leave)
                        .accessibilityValue(Self.label(low))
                        .accessibilityAdjustableAction { direction in
                            switch direction {
                            case .increment: low = min(low + 1, high - 1)
                            case .decrement: low = max(low - 1, Self.range.lowerBound)
                            @unknown default: break
                            }
                        }
                    thumb.position(x: x(high), y: 16)
                        .gesture(DragGesture().onChanged { high = max(hour($0.location.x), low + 1) })
                        .accessibilityElement()
                        .accessibilityLabel(OutingStudentCopy.backBy)
                        .accessibilityValue(Self.label(high))
                        .accessibilityAdjustableAction { direction in
                            switch direction {
                            case .increment: high = min(high + 1, Self.range.upperBound)
                            case .decrement: high = max(high - 1, low + 1)
                            @unknown default: break
                            }
                        }
                }
            }
            .frame(height: 32)
            HStack {
                ForEach([6, 12, 18, 22], id: \.self) { hour in
                    Text(Self.label(hour)).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
                    if hour != 22 { Spacer() }
                }
            }
        }
    }

    private var thumb: some View {
        Circle().fill(MLColor.surface).overlay(Circle().strokeBorder(MLColor.ink, lineWidth: 1.5)).frame(width: 30, height: 30)
    }
}

// MARK: - Sent and the request page

/// New outing · Sent (1848:22602).
struct StudentOutingSentView: View {
    let outing: OutingCase
    let now: Date
    let onSee: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    YouLargeHeader(title: OutingStudentCopy.sent, subtitle: OutingCardFormat.line(outing), onBack: onBack)
                    OutingTrackerCard(item: outing, now: now)
                    OutingNextStepsCard(stage: outing.stage, window: OutingFormat.window(outing))
                    OutingNothingByWaiting()
                    Text(OutingStudentCopy.sentNote).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
                    InkActionButton(title: OutingStudentCopy.seeRequest, action: onSee)
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, StudentMetric.scrollBottom)
            }
        }
    }
}

/// Outing · Waiting for guardian (1848:22622), Under warden review (1848:22655), Escalated (1848:22689), Changes
/// requested (1848:22723), Rejected (1848:22754), Approved and the pass (1848:22785, 1848:22925). "Edit request" is not
/// built: no edit operation exists.
struct StudentOutingDetailView: View {
    @State var model: StudentOutingsViewModel
    let id: OutingRequestID
    let onBack: () -> Void
    @State private var confirmingCancel = false

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    content
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, StudentMetric.scrollBottom)
            }
            .refreshable { await model.loadDetail(id) }
            StudentScrollFade()
        }
        .task { await model.loadDetail(id) }
        .sheet(isPresented: $confirmingCancel) {
            VStack(alignment: .leading, spacing: 14) {
                Text(OutingStudentCopy.cancelSheet).font(StudentType.body).foregroundStyle(MLColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let error = model.cancelError {
                    Text(error).font(StudentType.footnote).foregroundStyle(MLColor.danger)
                }
                InkActionButton(title: OutingStudentCopy.cancelOuting, isLoading: model.cancelling) {
                    Task { if await model.cancel(id) { confirmingCancel = false } }
                }
                .accessibilityIdentifier("student.outings.confirmCancel")
                OutlineActionButton(title: OutingStudentCopy.keepIt) { confirmingCancel = false }
            }
            .padding(MLSpacing.margin)
            .presentationDetents([.height(300)])
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.detail {
        case .idle, .loading:
            YouLargeHeader(title: OutingStudentCopy.title, subtitle: nil, onBack: onBack)
            YouSkeleton(heights: [360, 145], label: OutingStudentCopy.title)
        case .failed(let failure):
            YouLargeHeader(title: OutingStudentCopy.title, subtitle: nil, onBack: onBack)
            MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
        case .empty:
            YouLargeHeader(title: OutingStudentCopy.title, subtitle: nil, onBack: onBack)
        case .loaded(let item), .stale(let item, _):
            page(item, offline: false)
        case .offline(let item, _):
            YouLargeHeader(title: OutingStudentCopy.title, subtitle: nil, onBack: onBack)
            StudentOfflineBanner(text: OutingStudentCopy.offline)
            if let item { page(item, offline: true) }
        }
    }

    @ViewBuilder
    private func page(_ item: OutingCase, offline: Bool) -> some View {
        if let pass = item.pass, item.stage == .passSigned || item.stage == .out {
            YouLargeHeader(title: OutingStudentCopy.passTitle, subtitle: OutingStudentCopy.passSubtitle, onBack: onBack)
            OutingPassCard(item: item, pass: pass, onCancel: item.stage.studentCanCancel && !offline ? { confirmingCancel = true } : nil)
        } else {
            YouLargeHeader(title: OutingStudentCopy.outingTitle(item.leaveAt.map { OutingFormat.weekdayLong($0) } ?? OutingStudentCopy.title),
                           subtitle: [item.place, item.leaveAt.flatMap { leave in item.returnBy.map { OutingFormat.window(leave, $0) } }]
                            .compactMap { $0 }.joined(separator: " · "), onBack: onBack)
            OutingTrackerCard(item: item, now: model.now)
            OutingNextStepsCard(stage: item.stage, window: OutingFormat.window(item))
            OutingNothingByWaiting()
            if item.stage.studentCanCancel && !offline {
                VStack(alignment: .leading, spacing: MLSpacing.s8) {
                    Text(OutingStudentCopy.needChange).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                    Text(OutingStudentCopy.editingAsksAgain).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
                    Button(OutingStudentCopy.cancelRequest) { confirmingCancel = true }
                        .font(StudentType.secondaryMedium).underline().foregroundStyle(MLColor.ink)
                        .frame(minHeight: MLSize.hit)
                        .accessibilityIdentifier("student.outings.cancel")
                }
                .padding(MLSpacing.s20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous).fill(MLColor.surface))
            }
        }
    }
}

/// LoopTracker: the status line, the ring (Sent, Guardian, Warden, Pass) and the deadline in the middle.
struct OutingTrackerCard: View {
    let item: OutingCase
    let now: Date

    var body: some View {
        VStack(spacing: MLSpacing.s12) {
            HStack(spacing: MLSpacing.s8) {
                Circle().fill(MLColor.lime).frame(width: 8, height: 8).accessibilityHidden(true)
                Text(OutingStudentCopy.status(item)).font(StudentType.secondaryMedium).foregroundStyle(MLColor.onHero)
                Spacer(minLength: 0)
            }
            ZStack {
                OutingLoopRing(stage: item.stage, size: 200, lineWidth: 20, showsLabels: true)
                center
            }
            .frame(height: 260)
        }
        .padding(MLSpacing.s20)
        .background(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous).fill(MLColor.heroBackground))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var center: some View {
        VStack(spacing: 2) {
            if case .pastDeadline? = item.escalation(at: now) {
                Text(OutingStudentCopy.pastReplyTime).font(StudentType.bodySemibold).foregroundStyle(MLColor.onHero)
                Text(OutingStudentCopy.notApproved).font(StudentType.footnote).foregroundStyle(MLColor.lime)
                    .multilineTextAlignment(.center)
            } else if item.stage == .awaitingGuardian, let by = item.guardianReplyBy {
                deadline(OutingStudentCopy.guardianRepliesBy, by)
            } else if item.stage == .awaitingWarden, let by = item.wardenDecideBy {
                deadline(OutingStudentCopy.wardenDecidesBy, by)
            } else {
                Text(OutingStudentCopy.chip(item.stage)).font(StudentType.bodySemibold).foregroundStyle(MLColor.onHero)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 140)
    }

    private func deadline(_ label: String, _ by: Date) -> some View {
        Group {
            Text(label).font(StudentType.footnote).foregroundStyle(MLColor.onHeroSecondary)
            Text(OutingFormat.dayHour(by)).font(.system(size: 26, weight: .bold)).foregroundStyle(MLColor.onHero)
            Text(OutingStudentCopy.inTime(OutingFormat.shortLeft(from: now, to: by))).font(StudentType.footnote)
                .foregroundStyle(MLColor.lime)
        }
    }
}

/// The ring: Sent at the top, Guardian right, Warden bottom, Pass left. Lime up to where the request is.
struct OutingLoopRing: View {
    let stage: OutingStage
    let size: CGFloat
    let lineWidth: CGFloat
    let showsLabels: Bool

    /// Cancelled, closed or refused: the arc is grey, so it never reads as progress.
    private var stopped: Bool {
        switch stage {
        case .withdrawn, .closed, .guardianRejected, .wardenRejected: return true
        default: return false
        }
    }

    /// How many of the four points are reached (Sent = 1).
    private var reached: Int {
        switch stage {
        case .awaitingGuardian, .guardianCallRequested, .guardianAskedChange, .guardianRejected, .withdrawn, .closed: return 1
        case .awaitingWarden, .wardenAskedChange, .wardenRejected: return 2
        case .passSigned: return 3
        case .out, .returned: return 4
        }
    }

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.25), lineWidth: lineWidth)
            Circle().trim(from: 0, to: CGFloat(reached) / 4)
                .stroke(stopped ? MLColor.onHeroSecondary : MLColor.lime, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            ForEach(0..<4, id: \.self) { index in
                let angle = Angle.degrees(Double(index) * 90 - 90)
                node(index)
                    .offset(x: size / 2 * CGFloat(cos(angle.radians)), y: size / 2 * CGFloat(sin(angle.radians)))
                if showsLabels {
                    Text([OutingStudentCopy.sent, OutingStudentCopy.guardian, OutingStudentCopy.warden, OutingStudentCopy.pass][index])
                        .font(StudentType.footnote).foregroundStyle(MLColor.onHeroSecondary)
                        .fixedSize()
                        .offset(x: (size / 2 + 44) * CGFloat(cos(angle.radians)), y: (size / 2 + 26) * CGFloat(sin(angle.radians)))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func node(_ index: Int) -> some View {
        let dot = max(12, lineWidth * 1.4)
        if index < reached {
            Circle().fill(MLColor.lime).frame(width: dot, height: dot)
                .overlay(Image(systemName: "checkmark").font(.system(size: dot * 0.45, weight: .bold)).foregroundStyle(MLColor.ink))
        } else if index == reached {
            Circle().fill(MLColor.ink).overlay(Circle().strokeBorder(MLColor.lime, lineWidth: 3)).frame(width: dot, height: dot)
        } else {
            Circle().fill(MLColor.ink)
                .overlay(Circle().strokeBorder(MLColor.onHeroSecondary, style: StrokeStyle(lineWidth: 1, dash: [3, 2])))
                .frame(width: dot, height: dot)
        }
    }
}

/// OutingPass (1848:22925). It exists only once the warden signed it; the code is the repository's.
struct OutingPassCard: View {
    let item: OutingCase
    let pass: OutingPass
    let onCancel: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(OutingStudentCopy.passBrand).font(StudentType.eyebrow).tracking(0.8)
                    if let leave = item.leaveAt { Text(OutingFormat.dayMonth(leave)).font(StudentType.footnote) }
                }
                .foregroundStyle(MLColor.onLime)
                Spacer()
                Text(OutingStudentCopy.valid).font(StudentType.footnote).foregroundStyle(MLColor.onHero)
                    .padding(.horizontal, 12).frame(height: 28).background(Capsule().fill(MLColor.ink))
            }
            .padding(MLSpacing.s20)
            .background(MLColor.lime)
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                HStack(alignment: .top) {
                    Text(item.student.block ?? "—").font(StudentType.section)
                    Spacer()
                    Text(item.place ?? "—").font(StudentType.section).multilineTextAlignment(.trailing)
                }
                .foregroundStyle(MLColor.ink)
                HStack {
                    field(OutingStudentCopy.leave, item.leaveAt.map(OutingFormat.clock), big: true)
                    Spacer()
                    field(OutingStudentCopy.backBy, item.returnBy.map(OutingFormat.clock), big: true, trailing: true)
                }
                HStack(alignment: .top) {
                    if let gate = item.exitGate { field(OutingStudentCopy.gate, gate, big: false) }
                    Spacer()
                    field(OutingStudentCopy.passCode, pass.code, big: false)
                    Spacer()
                    field(OutingStudentCopy.student, item.student.displayName, big: false)
                }
            }
            .padding(MLSpacing.s20)
            Rectangle().fill(MLColor.border).frame(height: 1).padding(.horizontal, MLSpacing.s20)
            HStack(alignment: .top, spacing: MLSpacing.s16) {
                if let image = EntryQRImage.make(pass.code) {
                    Image(uiImage: image).interpolation(.none).resizable().frame(width: 136, height: 136)
                        .accessibilityLabel(OutingStudentCopy.passCode)
                } else {
                    Text(OutingStudentCopy.qrUnavailable).font(StudentType.footnote).foregroundStyle(MLColor.danger)
                        .frame(width: 136)
                }
                VStack(alignment: .leading, spacing: MLSpacing.s8) {
                    Text(OutingStudentCopy.showAtGate).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                    Text(OutingStudentCopy.faceCheck).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let onCancel {
                        Button(OutingStudentCopy.cancelPass, action: onCancel)
                            .font(StudentType.secondaryMedium).underline().foregroundStyle(MLColor.ink)
                            .frame(minHeight: MLSize.hit)
                    }
                }
            }
            .padding(MLSpacing.s20)
        }
        .background(MLColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous).strokeBorder(MLColor.border, lineWidth: 1))
    }

    private func field(_ label: String, _ value: String?, big: Bool, trailing: Bool = false) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 2) {
            Text(label).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
            Text(value ?? "—").font(big ? .system(size: 28, weight: .medium, design: .monospaced) : StudentType.secondaryMedium)
                .foregroundStyle(MLColor.ink).lineLimit(1).minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .combine)
    }
}

extension OutingFormat {
    /// "6 PM – 9 PM", from the request's own times. Nil when the request holds none.
    static func window(_ item: OutingCase) -> String? {
        guard let leave = item.leaveAt, let back = item.returnBy else { return nil }
        return "\(windowHour(leave)) – \(windowHour(back))"
    }

    private static func windowHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }
}
