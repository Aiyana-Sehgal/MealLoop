import SwiftUI

/// Single-mess records reuse the meal report drill-in. Global reason totals have no per-mess provenance.
struct AdminScopedResultsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav
    @State private var slot: MealSlot = .lunch
    var body: some View {
        let results = environment.repositories.adminResults
        return AdminPageScaffold(title: AdminScreenCopy.results, subtitle: nav.context.mess.name) {
            AdminFlow {
                ForEach(MealSlot.allCases, id: \.self) { value in
                    ChoiceChip(title: MLFormat.mealSlot(value), isSelected: slot == value) { slot = value }
                }
            }
            AdminLoadedPage(model: AdminPageModel { try await results.findMeals(mess: nil, slot: slot) }, timeZone: nav.timeZone,
                            emptyTitle: "No meal records for this mess") { meals, _ in
                ForEach(meals) { meal in
                    QuietRow(title: "\(meal.mess) · \(MLFormat.mealSlot(meal.slot))", value: AdminCopy.dayLine(meal.day, in: nav.timeZone)) { nav.push(.meal(meal.id)) }
                }
            }.id(slot)
            QuietRow(title: "Weekly report") { nav.push(.weeklyReport) }
            Text("Reason summaries for this mess are unavailable.").font(MLType.body).foregroundStyle(MLColor.inkSecondary)
        }
    }
}

struct AdminSingleMessReportScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav
    @State private var period: ReportPeriod = .thisWeek
    var body: some View {
        let results = environment.repositories.adminResults
        return AdminPageScaffold(title: "Weekly report", subtitle: nav.context.mess.name, onBack: nav.pop) {
            AdminFlow {
                ForEach(ReportPeriod.allCases, id: \.self) { value in
                    ChoiceChip(title: value == .thisWeek ? "This week" : value == .lastWeek ? "Last week" : "Month", isSelected: period == value) { period = value }
                }
            }
            AdminLoadedPage(model: AdminPageModel {
                guard let source = results as? any SingleMessReportRepository else { throw RepositoryError.notImplemented(feature: "Single-mess report") }
                return try await source.singleMessReport(period)
            }, timeZone: nav.timeZone) { report, _ in
                Text(report.dates).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                QuietRow(title: "Plate waste", value: report.line?.plateWasteKg.map { "\($0) kg" } ?? "—") {}
                    .disabled(true)
                QuietRow(title: "Meals that ran out", value: report.line?.ranOutMeals.map(String.init) ?? "—") {}
                    .disabled(true)
                QuietRow(title: "Data complete", value: report.line?.dataCompletePercent.map { "\($0)%" } ?? "—") {}
                    .disabled(true)
                Text("Missing figures are unavailable. Global totals are not included.").font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            }.id(period)
        }
    }
}
