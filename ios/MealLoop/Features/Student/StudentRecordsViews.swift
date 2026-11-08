import SwiftUI

/// Frame colours these pages draw that the shared tokens don't have (warning-tint #FFF3DA, warning #91600A,
/// urgent-tint #FCEBED, chart-hatch-bg #EDEDE8). Local to the Student folder; the shared tokens are not edited.
enum RecordsTint {
    static let warningFill = Color(hex: 0xFFF3DA)
    static let warningText = Color(hex: 0x91600A)
    static let urgentFill = Color(hex: 0xFCEBED)
    static let hatchFill = Color(hex: 0xEDEDE8)
    static let cardRadius: CGFloat = 24
}

private extension View {
    /// The white card of these frames: radius 24 and the ML/Shadow/Card shadow.
    func recordsCard(padding: CGFloat = MLSpacing.s16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous).fill(MLColor.surface)
                .shadow(color: Color(red: 24 / 255, green: 32 / 255, blue: 51 / 255).opacity(0.06), radius: 8, y: 4))
    }
}

enum RecordsFormat {
    static func day(_ date: Date, in timeZone: TimeZone) -> String { YouFormat.shortDay(date, in: timeZone) }
    static func weekday(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date)
    }
    static func dayNumber(_ date: Date, in timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return String(calendar.component(.day, from: date))
    }
    static func monthShort(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.timeZone = timeZone
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    /// The drawn style per step: Sent and Fixed show the day, Seen and a reply the time, the rest nothing.
    static func when(_ event: StudentReportEvent, in timeZone: TimeZone) -> String? {
        guard let at = event.at else { return nil }
        switch event.kind {
        case .sent, .fixed: return day(at, in: timeZone)
        case .seen, .replied: return MLFormat.time(at, in: timeZone)
        case .askedQuestion, .workingOnIt: return nil
        }
    }
}

// MARK: - Shared pieces

/// CategoryIcon (131:42884): 40 pt, radius 12; urgent categories on the urgent tint.
struct RecordsCategoryIcon: View {
    let category: StudentReportCategory

    private var symbol: String {
        switch category {
        case .foundInFood: return "exclamationmark.triangle"
        case .smellsOrTastesOff: return "nose"
        case .notClean: return "drop"
        case .ranOut: return "fork.knife"
        case .staffOrService: return "person.2"
        case .somethingElse: return "ellipsis"
        }
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 18))
            .foregroundStyle(category.isUrgent ? MLColor.danger : MLColor.ink)
            .frame(width: 40, height: 40)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(category.isUrgent ? RecordsTint.urgentFill : MLColor.fillQuiet))
            .accessibilityHidden(true)
    }
}

/// StepBar (100:1045): done = ink, current = lime on a detail page (ink in a list), pending = hatched.
struct RecordsStepBar: View {
    let step: Int
    var total = 4
    let label: String
    var showsCount = true
    var limeCurrent = true
    var warning = false

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            HStack(spacing: MLSpacing.s4) {
                ForEach(1...total, id: \.self) { index in
                    segment(index)
                }
            }
            HStack {
                Text(label)
                    .font(StudentType.eyebrow.weight(.medium))
                    .foregroundStyle(warning ? RecordsTint.warningText : MLColor.ink)
                Spacer()
                if showsCount {
                    Text(RecordsCopy.stepCount(step))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(MLColor.inkSecondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(showsCount ? "\(label), step \(step) of \(total)" : label)
    }

    @ViewBuilder
    private func segment(_ index: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)
        if index < step || (index == step && !limeCurrent) {
            shape.fill(MLColor.ink).frame(height: 8)
        } else if index == step {
            shape.fill(MLColor.lime).overlay(shape.strokeBorder(MLColor.limeOutline, lineWidth: 1)).frame(height: 8)
        } else {
            shape.fill(RecordsTint.hatchFill)
                .overlay(RecordsHatch().stroke(MLColor.border, lineWidth: 1).clipShape(shape))
                .frame(height: 8)
        }
    }
}

/// The diagonal hatch of a pending segment.
private struct RecordsHatch: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var x = rect.minX - rect.height
        while x < rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.maxY))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            x += 4
        }
        return path
    }
}

/// TimelineStep (81:872): done = ink node, current = lime node; the line joins the steps.
struct RecordsTimelineRow: View {
    let title: String
    let detail: String
    let isCurrent: Bool
    let showsLine: Bool

    var body: some View {
        HStack(alignment: .top, spacing: MLSpacing.s12) {
            VStack(spacing: MLSpacing.s4) {
                Circle()
                    .fill(isCurrent ? MLColor.lime : MLColor.ink)
                    .overlay(Circle().strokeBorder(MLColor.ink, lineWidth: isCurrent ? 1.5 : 0))
                    .frame(width: 12, height: 12)
                if showsLine {
                    Rectangle().fill(isCurrent ? MLColor.border : MLColor.ink).frame(width: 2)
                }
            }
            .frame(width: 16)
            .padding(.top, MLSpacing.s4)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                Text(detail).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, MLSpacing.s16)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Page scaffold: the backdrop, a scroll view, the bottom fade.
private struct RecordsPage<Content: View>: View {
    @ViewBuilder let content: Content
    var onRefresh: (() async -> Void)?

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) { content }
                    .padding(.horizontal, MLSpacing.margin)
                    .padding(.top, MLSpacing.s8)
                    .padding(.bottom, StudentMetric.scrollBottom)
            }
            .refreshable { await onRefresh?() }
            StudentScrollFade()
        }
    }
}

// MARK: - My reports

/// Report · My reports (221:63573).
struct StudentMyReportsView: View {
    @State var model: StudentRecordsViewModel
    let onOpen: (StudentFiledReportID) -> Void
    let onBack: () -> Void

    var body: some View {
        RecordsPage(content: {
            MealsCompactHeader(title: RecordsCopy.myReports, onBack: onBack)
            content
        }, onRefresh: { await model.loadReports() })
        .task { await model.loadReports() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.reports {
        case .idle, .loading:
            YouSkeleton(heights: [142, 142, 142], label: RecordsCopy.myReports)
        case .failed(let failure):
            MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
        case .empty:
            MealsStateCard(title: RecordsCopy.noReportsTitle, detail: RecordsCopy.noReportsDetail)
        case .loaded, .stale:
            list
        case .offline(let saved, _):
            StudentOfflineBanner(text: RecordsCopy.reportsOffline)
            if saved != nil { list }
        }
    }

    @ViewBuilder
    private var list: some View {
        if model.activeReports.isEmpty && model.closedReports.isEmpty {
            MealsStateCard(title: RecordsCopy.noReportsTitle, detail: RecordsCopy.noReportsDetail)
        }
        if !model.activeReports.isEmpty {
            eyebrow(RecordsCopy.active)
            ForEach(model.activeReports) { card($0) }
        }
        if !model.closedReports.isEmpty {
            eyebrow(RecordsCopy.closed)
            ForEach(model.closedReports) { card($0) }
        }
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text).font(StudentType.eyebrow).tracking(0.9).foregroundStyle(MLColor.inkSecondary)
            .accessibilityAddTraits(.isHeader)
    }

    private func card(_ report: StudentFiledReport) -> some View {
        Button { onOpen(report.id) } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: MLSpacing.s12) {
                    RecordsCategoryIcon(category: report.category)
                    Text(StudentReportCategoryTitle.title(report.category))
                        .font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                RecordsStepBar(step: report.stage.step, label: RecordsCopy.stageLabel(report.stage), limeCurrent: false,
                               warning: report.stage == .needMoreInfo)
                Text(RecordsCopy.referenceLine(report.reference, RecordsFormat.day(report.sentAt, in: model.timeZone)))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            .recordsCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("student.report.\(report.reference)")
    }
}

// MARK: - A report

/// Report · Need more info (221:63587) and Report · Fixed (221:63606); other stages use the same page.
struct StudentFiledReportView: View {
    @State var model: StudentRecordsViewModel
    let id: StudentFiledReportID
    let onBack: () -> Void
    @State private var replying = false

    var body: some View {
        RecordsPage(content: {
            MealsCompactHeader(title: model.report.value?.reference ?? "", onBack: onBack)
            content
        }, onRefresh: { await model.loadReport(id) })
        .task { await model.loadReport(id) }
        .sheet(isPresented: $replying) {
            RecordsReplySheet(model: model, id: id) { replying = false }
                .presentationDetents([.medium])
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.report {
        case .idle, .loading:
            YouSkeleton(heights: [156, 66, 119, 206], label: RecordsCopy.myReports)
        case .failed(let failure):
            MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
        case .empty:
            MealsStateCard(title: RecordsCopy.noReportsTitle, detail: "")
        case .loaded(let report), .stale(let report, _):
            page(report, offline: false)
        case .offline(let report, _):
            StudentOfflineBanner(text: RecordsCopy.reportsOffline)
            if let report { page(report, offline: true) }
        }
    }

    @ViewBuilder
    private func page(_ report: StudentFiledReport, offline: Bool) -> some View {
        summary(report)
        RecordsStepBar(step: report.stage.step, label: RecordsCopy.stageLabel(report.stage),
                       warning: report.stage == .needMoreInfo)
            .recordsCard()
        if report.stage == .needMoreInfo, let question = report.question {
            questionCard(question, reply: report.reply, offline: offline)
        }
        if report.stage == .fixed {
            checkCard(report, offline: offline)
        }
        Text(RecordsCopy.timeline).font(StudentType.eyebrow).tracking(0.9).foregroundStyle(MLColor.inkSecondary)
            .accessibilityAddTraits(.isHeader)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(report.events.enumerated()), id: \.offset) { index, event in
                RecordsTimelineRow(title: RecordsCopy.eventTitle(event.kind),
                                   detail: RecordsCopy.withWhen(RecordsCopy.eventDetail(event.kind),
                                                                RecordsFormat.when(event, in: model.timeZone)),
                                   isCurrent: event.isCurrent, showsLine: index < report.events.count - 1)
            }
        }
        .recordsCard(padding: MLSpacing.s12)
    }

    /// ReportSummary (101:1177): the category, then place, meal and time chips. A chip with nothing recorded is left out.
    private func summary(_ report: StudentFiledReport) -> some View {
        var chips: [String] = []
        if let place = report.place { chips.append(place) }
        if let meal = report.meal {
            chips.append(RecordsCopy.mealDay(MLFormat.mealSlot(meal), RecordsFormat.day(report.sentAt, in: model.timeZone)))
            chips.append(MLFormat.time(report.sentAt, in: model.timeZone))
        }
        return VStack(alignment: .leading, spacing: MLSpacing.s12) {
            HStack(spacing: MLSpacing.s12) {
                RecordsCategoryIcon(category: report.category)
                Text(StudentReportCategoryTitle.title(report.category))
                    .font(.system(size: 18, weight: .semibold)).foregroundStyle(MLColor.onHero)
            }
            if !chips.isEmpty {
                StudentFlowLayout(spacing: 6) {
                    ForEach(chips, id: \.self) { chip in
                        Text(chip)
                            .font(StudentType.tag)
                            .foregroundStyle(MLColor.onHero)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .overlay(Capsule().strokeBorder(MLColor.onHeroSecondary, lineWidth: 1))
                    }
                }
            }
        }
        .padding(MLSpacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous).fill(MLColor.heroBackground))
        .accessibilityElement(children: .combine)
    }

    private func questionCard(_ question: String, reply: String?, offline: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(RecordsCopy.messAsked(question))
                .font(StudentType.secondaryMedium).foregroundStyle(MLColor.ink)
            if let reply {
                VStack(alignment: .leading, spacing: 2) {
                    Text(RecordsCopy.yourReply).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
                    Text(reply).font(StudentType.body).foregroundStyle(MLColor.ink)
                    Text(RecordsCopy.replyRecorded).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
                }
            } else {
                InkActionButton(title: RecordsCopy.reply) { replying = true }
                    .disabled(offline)
                    .accessibilityIdentifier("student.report.reply")
            }
        }
        .padding(MLSpacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(RecordsTint.warningFill))
    }

    /// "Is it better now?" The answer is recorded as the student's signal only (ruling on P-FINAL2-7); it never marks
    /// the fix as verified.
    private func checkCard(_ report: StudentFiledReport, offline: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(RecordsCopy.isItBetter).font(.system(size: 18, weight: .semibold)).foregroundStyle(MLColor.ink)
            if let answer = report.fixCheck {
                Text(RecordsCopy.youSaidFix(answer)).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
            } else {
                HStack(spacing: MLSpacing.s8) {
                    Button { answer(.better, report) } label: {
                        Text(RecordsCopy.yesBetter)
                            .font(StudentType.bodySemibold).foregroundStyle(MLColor.onHero)
                            .padding(.horizontal, MLSpacing.s24).frame(height: 56)
                            .background(Capsule().fill(MLColor.ink))
                    }
                    .accessibilityIdentifier("student.report.better")
                    Button { answer(.stillBad, report) } label: {
                        Text(RecordsCopy.stillBad)
                            .font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                            .padding(.horizontal, MLSpacing.s24).frame(height: 48)
                            .overlay(Capsule().strokeBorder(MLColor.ink, lineWidth: 1.5))
                    }
                }
                Button { answer(.didntTry, report) } label: {
                    Text(RecordsCopy.didntTry)
                        .font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                        .frame(maxWidth: .infinity).frame(height: 44)
                }
                if case .failed(let message) = model.fixSend {
                    Text(message).font(StudentType.footnote).foregroundStyle(MLColor.danger)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(offline || model.fixSend == .sending)
        .recordsCard()
    }

    private func answer(_ value: StudentFixCheckAnswer, _ report: StudentFiledReport) {
        Task { await model.answerFixCheck(value, for: report.id) }
    }
}

/// The reply to "The mess asked". No frame draws it; it reuses the Report · Details field and buttons.
struct RecordsReplySheet: View {
    @State var model: StudentRecordsViewModel
    let id: StudentFiledReportID
    let onClose: () -> Void
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            Text(RecordsCopy.yourReply).font(StudentType.section).foregroundStyle(MLColor.ink)
                .accessibilityAddTraits(.isHeader)
            TextField(RecordsCopy.replyPlaceholder, text: $text, axis: .vertical)
                .font(StudentType.body)
                .lineLimit(3...5)
                .padding(MLSpacing.s16)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(MLColor.fillQuiet))
                .accessibilityIdentifier("student.report.replyField")
            if case .failed(let message) = model.replySend {
                Text(message).font(StudentType.footnote).foregroundStyle(MLColor.danger)
            }
            InkActionButton(title: model.replySend == .sending ? RecordsCopy.sending : RecordsCopy.sendReply,
                            isLoading: model.replySend == .sending) {
                Task { if await model.reply(text, to: id) { onClose() } }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier("student.report.sendReply")
            Button(RecordsCopy.cancel, action: onClose)
                .font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                .frame(maxWidth: .infinity, minHeight: MLSize.hit)
        }
        .padding(MLSpacing.margin)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(MLColor.canvas)
    }
}

// MARK: - My feedback

/// My feedback (2159:151331), Better saved (2159:151464), Empty (2159:151588), Offline (2159:151689).
struct StudentMyFeedbackView: View {
    @State var model: StudentRecordsViewModel
    let onReports: () -> Void
    let onBack: () -> Void

    var body: some View {
        RecordsPage(content: {
            YouLargeHeader(title: YouCopy.myFeedback, subtitle: RecordsCopy.feedbackSubtitle, onBack: onBack)
            content
        }, onRefresh: { await model.loadFeedback() })
        .task { await model.loadFeedback() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.feedback {
        case .idle, .loading:
            YouSkeleton(heights: [168, 165, 105], label: YouCopy.myFeedback)
        case .failed(let failure):
            MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
        case .empty:
            MealsStateCard(title: RecordsCopy.noFeedbackTitle, detail: RecordsCopy.noFeedbackDetail)
        case .loaded(let summary), .stale(let summary, _):
            page(summary, offline: false)
        case .offline(let summary, _):
            StudentOfflineBanner(text: RecordsCopy.feedbackOffline)
            if let summary { page(summary, offline: true) }
        }
    }

    @ViewBuilder
    private func page(_ summary: StudentFeedbackSummary, offline: Bool) -> some View {
        if summary.items.isEmpty {
            MealsStateCard(title: RecordsCopy.noFeedbackTitle, detail: RecordsCopy.noFeedbackDetail)
        } else {
            hero(summary)
            ForEach(summary.items) { item in
                if item.stage == .fixed {
                    fixedCard(item, offline: offline)
                } else {
                    progressCard(item)
                }
            }
        }
    }

    /// The black hero. It opens My reports, where the reports and their pages are.
    private func hero(_ summary: StudentFeedbackSummary) -> some View {
        Button(action: onReports) {
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                Text(RecordsCopy.yourReports).font(StudentType.eyebrow).tracking(1.0).foregroundStyle(MLColor.onHeroSecondary)
                HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s12) {
                    Text("\(summary.total)").font(.system(size: 48, weight: .medium)).foregroundStyle(MLColor.onHero)
                    Text(RecordsCopy.thisMonth).font(StudentType.body).foregroundStyle(MLColor.onHeroSecondary)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MLColor.onHeroSecondary).accessibilityHidden(true)
                }
                HStack(spacing: MLSpacing.s8) {
                    Text(RecordsCopy.fixedCount(summary.fixed))
                        .font(StudentType.secondaryMedium).foregroundStyle(MLColor.onLime)
                        .padding(.horizontal, MLSpacing.s16).frame(height: 36)
                        .background(Capsule().fill(MLColor.lime))
                    Text(RecordsCopy.withKitchen(summary.withTheKitchen))
                        .font(StudentType.secondaryMedium).foregroundStyle(MLColor.onHero)
                        .padding(.horizontal, MLSpacing.s16).frame(height: 36)
                        .overlay(Capsule().strokeBorder(MLColor.onHeroSecondary, lineWidth: 1.5))
                }
            }
            .padding(MLSpacing.s20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.heroBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(RecordsCopy.myReports)
        .accessibilityIdentifier("student.feedback.reports")
    }

    private func fixedCard(_ item: StudentFeedbackItem, offline: Bool) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            HStack(alignment: .firstTextBaseline) {
                Text(RecordsCopy.dishProblem(item.dish, item.problem))
                    .font(StudentType.section).foregroundStyle(MLColor.ink)
                Spacer(minLength: MLSpacing.s8)
                Text(RecordsCopy.fixedOn(RecordsFormat.weekday(item.at, in: model.timeZone)))
                    .font(StudentType.footnote).foregroundStyle(MLColor.onLime)
                    .padding(.horizontal, 10).frame(height: 28)
                    .background(Capsule().fill(MLColor.lime))
                    .overlay(Capsule().strokeBorder(MLColor.limeOutline, lineWidth: 1))
            }
            if let note = item.fixNote {
                Text(note).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
            }
            if let answer = item.recheck {
                Text(RecordsCopy.youSaid(answer)).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
            } else {
                HStack(spacing: MLSpacing.s12) {
                    Text(RecordsCopy.betterToday).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button { Task { await model.answerRecheck(item.id, .better) } } label: {
                        Text(RecordsCopy.better).font(StudentType.bodySemibold).foregroundStyle(MLColor.onHero)
                            .frame(width: 100, height: 48).background(Capsule().fill(MLColor.ink))
                    }
                    .accessibilityIdentifier("student.feedback.better")
                    Button { Task { await model.answerRecheck(item.id, .same) } } label: {
                        Text(RecordsCopy.same).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                            .frame(width: 92, height: 48).overlay(Capsule().strokeBorder(MLColor.ink, lineWidth: 1.5))
                    }
                }
                .buttonStyle(.plain)
                .disabled(offline || model.recheckSend == .sending)
                if case .failed(let message) = model.recheckSend {
                    Text(message).font(StudentType.footnote).foregroundStyle(MLColor.danger)
                }
            }
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous).fill(MLColor.surface))
        .overlay(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous).strokeBorder(MLColor.ink, lineWidth: 1.5))
    }

    private func progressCard(_ item: StudentFeedbackItem) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Text(RecordsCopy.dishProblem(item.dish, item.problem)).font(StudentType.section).foregroundStyle(MLColor.ink)
            Text(RecordsCopy.feedbackStage(item.stage, RecordsFormat.day(item.at, in: model.timeZone)))
                .font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
            HStack(spacing: 6) {
                ForEach(1...3, id: \.self) { index in
                    Capsule().fill(index <= item.stage.step ? MLColor.ink : MLColor.track).frame(height: 8)
                }
            }
            .accessibilityHidden(true)
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }
}

// Spending is in StudentSpendingViews.swift, on the private ledger.

// MARK: - Help

/// Help (221:64742). Only the first answer is drawn; the others open to "Not published yet".
struct StudentHelpView: View {
    @State var model: StudentRecordsViewModel
    let onBack: () -> Void
    @State private var open: Set<String> = []
    @State private var seeded = false

    var body: some View {
        RecordsPage(content: {
            YouLargeHeader(title: YouCopy.help, subtitle: RecordsCopy.helpSubtitle, onBack: onBack)
            content
        }, onRefresh: { await model.loadHelp() })
        .task {
            await model.loadHelp()
            if !seeded, let first = model.help.value?.topics.first {
                open.insert(first.id)
                seeded = true
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.help {
        case .idle, .loading:
            YouSkeleton(heights: [345, 81], label: YouCopy.help)
        case .failed(let failure):
            MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
        case .empty:
            MealsStateCard(title: RecordsCopy.notPublishedYet, detail: "")
        case .loaded(let help), .stale(let help, _):
            page(help)
        case .offline(let help, _):
            StudentOfflineBanner(text: YouCopy.youOffline)
            if let help { page(help) }
        }
    }

    @ViewBuilder
    private func page(_ help: StudentHelp) -> some View {
        if help.topics.isEmpty {
            MealsStateCard(title: RecordsCopy.notPublishedYet, detail: "")
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(help.topics.enumerated()), id: \.element.id) { index, topic in
                    if index > 0 { YouDivider() }
                    topicRow(topic)
                }
            }
            .padding(.horizontal, MLSpacing.s16)
            .padding(.vertical, MLSpacing.s4)
            .background(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous).fill(MLColor.surface))
        }
        if let contact = help.contact {
            VStack(alignment: .leading, spacing: MLSpacing.s8) {
                Text(RecordsCopy.contactOffice).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                Text(contact).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
            }
            .padding(MLSpacing.s20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous).fill(MLColor.surface))
            .accessibilityElement(children: .combine)
        }
    }

    private func topicRow(_ topic: StudentHelpTopic) -> some View {
        let isOpen = open.contains(topic.id)
        return VStack(alignment: .leading, spacing: MLSpacing.s8) {
            Button {
                if isOpen { open.remove(topic.id) } else { open.insert(topic.id) }
            } label: {
                HStack {
                    Text(topic.question).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: MLSpacing.s8)
                    Image(systemName: isOpen ? "minus" : "plus").font(.system(size: 15, weight: .medium))
                        .foregroundStyle(MLColor.ink).accessibilityHidden(true)
                }
                .frame(minHeight: MLSize.hit)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")
            if isOpen {
                Text(topic.answer ?? RecordsCopy.notPublishedYet)
                    .font(StudentType.secondary)
                    .foregroundStyle(topic.answer == nil ? MLColor.inkSecondary : MLColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, MLSpacing.s4)
    }
}

// MARK: - Terms and privacy

/// Terms and privacy (221:64669): the frame's own words, titled "Privacy & data". The two data requests are recorded
/// in the prototype only (ruling on P-FINAL2-9): nothing is sent, and no person or time is promised.
struct StudentPrivacyView: View {
    @State var model: StudentRecordsViewModel
    let onBack: () -> Void

    var body: some View {
        RecordsPage(content: {
            MealsCompactHeader(title: RecordsCopy.privacyTitle, onBack: onBack)
            listCard(RecordsCopy.sharedWithMess, RecordsCopy.shared)
            listCard(RecordsCopy.onlyYou, RecordsCopy.onlyYouItems)
            Text(RecordsCopy.noNames).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
            Text(RecordsCopy.yourData).font(StudentType.eyebrow).tracking(0.9).foregroundStyle(MLColor.inkSecondary)
                .accessibilityAddTraits(.isHeader)
            YouCard {
                requestRow(.copy, symbol: "square.and.arrow.up", title: RecordsCopy.requestCopy)
                YouDivider()
                requestRow(.deletion, symbol: "trash", title: RecordsCopy.requestDeletion)
            }
            if case .failed(let message) = model.dataRequestSend {
                Text(message).font(StudentType.footnote).foregroundStyle(MLColor.danger)
            }
        }, onRefresh: { await model.loadDataRequests() })
        .task { await model.loadDataRequests() }
    }

    private func requestRow(_ kind: StudentDataRequestKind, symbol: String, title: String) -> some View {
        let recorded = model.dataRequests.contains { $0.kind == kind }
        return YouRow(symbol: symbol, title: title, status: recorded ? RecordsCopy.requestRecorded : nil,
                      showsChevron: !recorded) {
            if !recorded { Task { await model.recordDataRequest(kind) } }
        }
        .disabled(model.dataRequestSend == .sending)
    }

    private func listCard(_ title: String, _ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            Text(title).font(.system(size: 18, weight: .semibold)).foregroundStyle(MLColor.ink)
                .accessibilityAddTraits(.isHeader)
            ForEach(items, id: \.self) { item in
                Text("· \(item)").font(StudentType.secondary).foregroundStyle(MLColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: RecordsTint.cardRadius, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }
}
