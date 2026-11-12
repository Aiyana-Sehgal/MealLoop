import SwiftUI

// Results for the Food Head's own mess. Meal records reuse the meal report; reason totals are global, so they are not
// shown here as if they belonged to this mess.

enum AdminScopedResultsCopy {
    static let lastMeal = "LAST MEAL"
    static func planned(_ count: String) -> String { "planned \(count)" }
    static let came = "came"
    static let plateWaste = "Plate waste"
    static let ranOut = "Ran out"
    static let notClosed = "Not closed yet"
    static let meals = "MEALS"
    static let noMeals = "No meal records for this meal slot yet."
    static func mealDetail(_ day: String, sent: String, came: String) -> String { "\(day) · sent \(sent) · came \(came)" }
    static let thisWeek = "This week"
    static let lastWeek = "Last week"
    static let month = "Month"
    static let mealsThatRanOut = "Meals that ran out"
    static let dataComplete = "Data complete"
    static let figures = "FIGURES"
    static let globalNote = "Only this mess. A figure the record does not hold shows a dash."
}

struct AdminSingleMessReportScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav
    @State private var period: ReportPeriod = .thisWeek

    var body: some View {
        let results = environment.repositories.adminResults
        AdminPageScaffold(title: AdminScreenCopy.weeklyReport, subtitle: nav.context.mess.name, onBack: nav.pop) {
            AdminFlow {
                ForEach(ReportPeriod.allCases, id: \.self) { value in
                    ChoiceChip(title: value == .thisWeek ? AdminScopedResultsCopy.thisWeek
                               : value == .lastWeek ? AdminScopedResultsCopy.lastWeek : AdminScopedResultsCopy.month,
                               isSelected: period == value) { period = value }
                }
            }
            AdminLoadedPage(model: AdminPageModel {
                guard let source = results as? any SingleMessReportRepository else {
                    throw RepositoryError.notImplemented(feature: "Single-mess report")
                }
                return try await source.singleMessReport(period)
            }, timeZone: nav.timeZone) { report, _ in
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    HeroCard {
                        VStack(alignment: .leading, spacing: MLSpacing.s8) {
                            HeroEyebrow(label: report.dates.uppercased())
                            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                                Text(report.line?.plateWasteKg.map(String.init) ?? AdminFormat.missing)
                                    .font(MLType.heroNumber).foregroundStyle(MLColor.onHero)
                                Text("kg \(AdminScopedResultsCopy.plateWaste.lowercased())").mlFont(.staffBody)
                                    .foregroundStyle(MLColor.onHeroSecondary)
                            }
                        }
                    }
                    AdminLabel(text: AdminScopedResultsCopy.figures)
                    AdminGroupCard {
                        row(AdminScopedResultsCopy.mealsThatRanOut, report.line?.ranOutMeals.map(String.init))
                        row(AdminScopedResultsCopy.dataComplete, report.line?.dataCompletePercent.map { "\($0)%" }, isLast: true)
                    }
                    Text(AdminScopedResultsCopy.globalNote).mlFont(.secondary).foregroundStyle(MLColor.inkSecondary)
                }
            }
            .id(period)
        }
    }

    private func row(_ title: String, _ value: String?, isLast: Bool = false) -> some View {
        HStack {
            Text(title).mlFont(.staffBody).foregroundStyle(MLColor.ink)
            Spacer()
            Text(value ?? AdminFormat.missing).font(MLType.monoBody).foregroundStyle(MLColor.ink)
        }
        .frame(minHeight: 56)
        .overlay(alignment: .bottom) { if !isLast { Rectangle().fill(MLColor.border).frame(height: 1) } }
        .accessibilityElement(children: .combine)
    }
}
