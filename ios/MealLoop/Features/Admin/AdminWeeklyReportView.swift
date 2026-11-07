import SwiftUI

/// The weekly report (F02). PDF and CSV generation are not built, so this never says a file exists.
@MainActor
@Observable
final class AdminWeeklyReportViewModel {
    enum ExportState: Equatable {
        case idle
        case preparing
        case preview
    }

    private(set) var state: LoadState<AdminWeeklyReport> = .idle
    private(set) var period: ReportPeriod = .thisWeek
    private(set) var exportState: ExportState = .idle
    private(set) var csvNote: String?

    private let results: any AdminResultsRepository
    private let preparingTime: Duration

    init(results: any AdminResultsRepository, preparingTime: Duration = .seconds(1)) {
        self.results = results
        self.preparingTime = preparingTime
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            state = .loaded(try await results.weeklyReport(period))
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    func select(_ period: ReportPeriod) async {
        self.period = period
        csvNote = nil
        await load()
    }

    /// A short wait as on F02, then a preview built from the data. Nothing is written to disk.
    func exportPDF() async {
        guard exportState == .idle else { return }
        exportState = .preparing
        try? await Task.sleep(for: preparingTime)
        exportState = .preview
    }

    func closePreview() {
        exportState = .idle
    }

    func exportCSV() {
        csvNote = AdminScreenCopy.csvNotBuilt
    }
}

struct AdminWeeklyReportScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        AdminWeeklyReportView(model: AdminWeeklyReportViewModel(results: environment.repositories.adminResults), nav: nav)
    }
}

struct AdminWeeklyReportView: View {
    @State private var model: AdminWeeklyReportViewModel
    let nav: AdminNav

    @State private var isSendingVendor = false

    init(model: AdminWeeklyReportViewModel, nav: AdminNav) {
        _model = State(initialValue: model)
        self.nav = nav
    }

    private var isPreviewOpen: Binding<Bool> {
        Binding(get: { model.exportState == .preview }, set: { if !$0 { model.closePreview() } })
    }

    var body: some View {
        AdminPageScaffold(title: AdminScreenCopy.weeklyReport, subtitle: model.state.value?.range, onBack: nav.pop) {
            AdminFlow {
                periodChip(.thisWeek, AdminScreenCopy.thisWeek)
                periodChip(.lastWeek, AdminScreenCopy.lastWeek)
                periodChip(.month, AdminScreenCopy.month)
            }
            AsyncContentView(state: model.state, timeZone: nav.timeZone, retry: { await model.load() }) { report in
                content(report)
            }
        }
        .task { await model.load() }
        .mlSheet(isPresented: isPreviewOpen) {
            if let report = model.state.value {
                AdminReportPreviewSheet(report: report, recipient: nav.context.account.firstName) { model.closePreview() }
            }
        }
        .mlSheet(isPresented: $isSendingVendor) {
            AdminTellVendorSheet(subtitle: AdminScreenCopy.preparedSummary, message: model.state.value?.vendorSummary ?? "",
                                 note: AdminScreenCopy.summaryRule) { isSendingVendor = false }
        }
    }

    private func periodChip(_ period: ReportPeriod, _ title: String) -> some View {
        ChoiceChip(title: title, isSelected: model.period == period) {
            Task { await model.select(period) }
        }
    }

    private func content(_ report: AdminWeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            HeroCard {
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    HeroEyebrow(label: report.eyebrow)
                    HStack(alignment: .top, spacing: MLSpacing.s16) {
                        figure("\(report.mealsLeftOver)", AdminScreenCopy.mealsLeftOver(report.mealsLeftOver), color: MLColor.lime)
                        figure("\(report.mealsRanOut)", AdminScreenCopy.mealsRanOut(report.mealsRanOut), color: MLColor.onHero)
                        figure(report.dataCompletePercent.map { "\($0)%" } ?? AdminFormat.missing, AdminScreenCopy.dataComplete, color: MLColor.onHero)
                    }
                }
            }
            AdminLabel(text: AdminScreenCopy.inTheReport)
            VStack(spacing: 0) {
                ForEach(report.sections) { section in
                    AdminRow(title: section.title, action: nil) {
                        Text(AdminScreenCopy.page(section.page))
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                }
            }
            InkActionButton(title: model.exportState == .preparing ? AdminScreenCopy.preparing : AdminScreenCopy.exportPDF,
                            isLoading: model.exportState == .preparing) {
                Task { await model.exportPDF() }
            }
            HStack(spacing: MLSpacing.s12) {
                OutlineActionButton(title: AdminScreenCopy.exportCSV) { model.exportCSV() }
                OutlineActionButton(title: AdminScreenCopy.sendToVendor) { isSendingVendor = true }
            }
            if let note = model.csvNote {
                AdminNote(text: note)
            }
        }
    }

    private func figure(_ value: String, _ label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(value)
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(MLType.secondary)
                .foregroundStyle(MLColor.onHeroSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// F03 as a preview on the phone. No PDF is made.
struct AdminReportPreviewSheet: View {
    let report: AdminWeeklyReport
    let recipient: String
    let onClose: () -> Void

    /// A4 at 595 x 842, shrunk to fit the narrowest phone.
    private let scale: CGFloat = 0.55

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: AdminScreenCopy.reportPreview, subtitle: AdminScreenCopy.previewSubtitle(report.range, pages: 2), onClose: onClose)
            AdminNote(text: AdminScreenCopy.noFileMade)
            if let pages = report.pages {
                page(AdminReportPageOne(report: report, pages: pages, recipient: recipient))
                page(AdminReportPageTwo(report: report, pages: pages))
            } else {
                AdminNote(text: AdminScreenCopy.noBreakdownDrawn)
            }
        }
    }

    private func page<Page: View>(_ content: Page) -> some View {
        content
            .frame(width: 595, height: 842, alignment: .topLeading)
            .background(Color.white)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: 595 * scale, height: 842 * scale, alignment: .topLeading)
            .overlay(Rectangle().stroke(MLColor.border, lineWidth: 1))
            .frame(maxWidth: .infinity)
    }
}

private struct AdminReportHeader: View {
    var body: some View {
        HStack {
            Text(AdminScreenCopy.brand).font(.system(size: 20, weight: .semibold))
            Spacer()
            Text(AdminScreenCopy.reportTitle).font(.system(size: 13)).foregroundStyle(MLColor.inkSecondary)
        }
        .padding(.bottom, MLSpacing.s8)
        .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
    }
}

private struct AdminReportFooter: View {
    let page: Int

    var body: some View {
        HStack {
            Text(AdminScreenCopy.sample)
            Spacer()
            Text(AdminScreenCopy.pageOf(page, 2))
        }
        .font(.system(size: 12))
        .foregroundStyle(MLColor.inkSecondary)
    }
}

private struct AdminReportHeading: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(MLColor.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, MLSpacing.s4)
            .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
    }
}

struct AdminReportPageOne: View {
    let report: AdminWeeklyReport
    let pages: ReportPages
    let recipient: String

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            AdminReportHeader()
            VStack(alignment: .leading, spacing: 2) {
                Text(AdminScreenCopy.reportTitle).font(.system(size: 28, weight: .bold))
                Text(AdminScreenCopy.reportFor(report.fullRange, recipient)).font(.system(size: 13)).foregroundStyle(MLColor.inkSecondary)
            }
            HStack(spacing: MLSpacing.s8) {
                box("\(report.mealsLeftOver)", AdminScreenCopy.mealsLeftOver(report.mealsLeftOver), isLime: true)
                box("\(report.mealsRanOut)", AdminScreenCopy.mealsRanOut(report.mealsRanOut), isLime: false)
                box(report.dataCompletePercent.map { "\($0)%" } ?? AdminFormat.missing, AdminScreenCopy.recordsComplete, isLime: false)
            }
            AdminReportHeading(text: AdminScreenCopy.whyLeftOver)
            ForEach(pages.reasons) { reason in
                HStack {
                    Text("\(reason.meals)").font(.system(size: 15, weight: .semibold)).frame(width: 28, alignment: .leading)
                    Text(reason.title).font(.system(size: 13))
                    Spacer()
                    Text(AdminScreenCopy.tag(reason.tag)).font(.system(size: 12)).foregroundStyle(MLColor.inkSecondary)
                }
            }
            Text(AdminScreenCopy.countsAreMeals).font(.system(size: 12)).foregroundStyle(MLColor.inkSecondary)
            AdminReportHeading(text: AdminScreenCopy.foodsLeftOver)
            HStack(spacing: MLSpacing.s8) {
                ForEach(pages.foods) { food in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(food.dish).font(.system(size: 13, weight: .semibold))
                        Text(AdminScreenCopy.foodLine(food)).font(.system(size: 12)).foregroundStyle(MLColor.inkSecondary)
                    }
                    .padding(MLSpacing.s8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(MLColor.border))
                }
            }
            AdminReportHeading(text: AdminScreenCopy.ranOut)
            ForEach(pages.ranOutLines, id: \.self) { line in
                Text(line).font(.system(size: 13))
            }
            Spacer()
            AdminReportFooter(page: 1)
        }
        .foregroundStyle(MLColor.ink)
        .padding(MLSpacing.s32)
    }

    private func box(_ value: String, _ label: String, isLime: Bool) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(value).font(.system(size: 28, weight: .bold))
            Text(label).font(.system(size: 12))
        }
        .padding(MLSpacing.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(isLime ? MLColor.lime : Color.white))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isLime ? MLColor.ink : MLColor.border))
    }
}

struct AdminReportPageTwo: View {
    let report: AdminWeeklyReport
    let pages: ReportPages

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            AdminReportHeader()
            VStack(alignment: .leading, spacing: 2) {
                Text(AdminScreenCopy.reportContinued).font(.system(size: 22, weight: .bold))
                Text(report.fullRange).font(.system(size: 13)).foregroundStyle(MLColor.inkSecondary)
            }
            AdminReportHeading(text: AdminScreenCopy.byMess)
            row(AdminScreenCopy.mess, AdminScreenCopy.plateWaste, AdminScreenCopy.ranOutMeals, AdminScreenCopy.data, isHeader: true)
            ForEach(pages.byMess) { mess in
                row(mess.mess, mess.plateWasteKg.map { "\($0) kg" } ?? AdminScreenCopy.noData,
                    mess.ranOutMeals.map(String.init) ?? AdminFormat.missing,
                    mess.dataCompletePercent.map { "\($0)%" } ?? AdminFormat.missing, isHeader: false)
            }
            AdminReportHeading(text: AdminScreenCopy.changesWeTested)
            ForEach(pages.changes) { change in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(change.title).font(.system(size: 13))
                        Text(change.detail).font(.system(size: 12)).foregroundStyle(MLColor.inkSecondary)
                    }
                    Spacer()
                    Text(change.status).font(.system(size: 12))
                }
            }
            AdminReportHeading(text: AdminScreenCopy.safetyCases)
            ForEach(pages.safetyLines, id: \.self) { line in
                Text(line).font(.system(size: 13))
            }
            AdminReportHeading(text: AdminScreenCopy.dataGaps)
            ForEach(pages.dataGaps, id: \.self) { line in
                Text("• \(line)").font(.system(size: 13))
            }
            Spacer()
            AdminReportFooter(page: 2)
        }
        .foregroundStyle(MLColor.ink)
        .padding(MLSpacing.s32)
    }

    private func row(_ a: String, _ b: String, _ c: String, _ d: String, isHeader: Bool) -> some View {
        HStack {
            Text(a).font(.system(size: isHeader ? 12 : 13, weight: isHeader ? .regular : .semibold)).frame(maxWidth: .infinity, alignment: .leading)
            Text(b).frame(maxWidth: .infinity, alignment: .leading)
            Text(c).frame(maxWidth: .infinity, alignment: .leading)
            Text(d).frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: isHeader ? 12 : 13))
        .foregroundStyle(isHeader ? MLColor.inkSecondary : MLColor.ink)
    }
}
