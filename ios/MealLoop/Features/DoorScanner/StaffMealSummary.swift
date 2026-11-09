import SwiftUI

// The "This meal" block for the mess staff pages that were mostly empty (Prompt 5, R2: owner ruling 6, 9 November).
// Everything in it comes from data the page already loads: the current meal status, a count the page already reads,
// and the mess's meal history. A missing value is a dash, never zero. Status is a dot and plain text (the Kitchen
// ruling), so the block reads the same on every staff role.

enum StaffSummaryCopy {
    static let thisMeal = "This meal"
    static let notStarted = "Not started"
    static let live = "Live"
    static let closed = "Closed"
    static let noMeal = "No meal today"
    static let opens = "Opens"
    static let started = "Started"
    static let closes = "Closes"
    static let closedAt = "Closed"
    static let earlierMeals = "Earlier meals"
    static let wasteRecorded = "Waste recorded"
    static let wasteNotRecorded = "Waste not recorded"
    static func entered(_ count: Int) -> String { "\(count) entered" }
    static func title(_ slot: MealSlot, _ mess: String) -> String { "\(MLFormat.mealSlot(slot)) · \(mess)" }
}

/// One label and value on a hairline row. A nil value shows a dash.
struct StaffFact: Identifiable, Hashable {
    let label: String
    let value: String?
    var id: String { label }
}

/// The black card (meal, state as a dot and text, one count) and the facts under it.
struct StaffMealSummary: View {
    let status: MealStatus?
    let mess: Mess
    /// The count this page already reads ("Recorded at the door"); nil shows a dash.
    let count: Int?
    let countCaption: String
    var facts: [StaffFact] = []

    private var timeZone: TimeZone { mess.timeZone }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            HeroCard {
                HeroEyebrow(label: stateLabel, showsDot: status?.state == .inService,
                            time: status.map { MLFormat.timeRange($0.meal.startsAt, $0.meal.endsAt, in: timeZone) })
                Text(status.map { StaffSummaryCopy.title($0.meal.slot, mess.name) } ?? mess.name)
                    .font(MLType.title2)
                    .foregroundStyle(MLColor.onHero)
                    .padding(.top, MLSpacing.s8)
                HeroCount(value: count, caption: countCaption)
                    .padding(.top, MLSpacing.s12)
            }
            .accessibilityElement(children: .combine)
            if !allFacts.isEmpty {
                StaffFactRows(facts: allFacts)
            }
        }
    }

    private var stateLabel: String {
        switch status?.state {
        case .notStarted?: return StaffSummaryCopy.notStarted
        case .inService?: return StaffSummaryCopy.live
        case .closed?: return StaffSummaryCopy.closed
        case nil: return StaffSummaryCopy.noMeal
        }
    }

    /// The meal's own times first, then the page's facts.
    private var allFacts: [StaffFact] {
        guard let status else { return facts }
        var rows: [StaffFact] = []
        switch status.state {
        case .notStarted:
            rows.append(StaffFact(label: StaffSummaryCopy.opens, value: MLFormat.time(status.meal.startsAt, in: timeZone)))
        case .inService:
            rows.append(StaffFact(label: StaffSummaryCopy.started, value: status.startedAt.map { MLFormat.time($0, in: timeZone) }))
            rows.append(StaffFact(label: StaffSummaryCopy.closes, value: MLFormat.time(status.meal.endsAt, in: timeZone)))
        case .closed:
            rows.append(StaffFact(label: StaffSummaryCopy.started, value: status.startedAt.map { MLFormat.time($0, in: timeZone) }))
            rows.append(StaffFact(label: StaffSummaryCopy.closedAt, value: status.closedAt.map { MLFormat.time($0, in: timeZone) }))
        }
        return rows + facts
    }
}

/// Hairline label and value rows.
struct StaffFactRows: View {
    let facts: [StaffFact]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(facts) { fact in
                HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s12) {
                    Text(fact.label).font(MLType.staffBody).foregroundStyle(MLColor.ink)
                    Spacer(minLength: MLSpacing.s8)
                    Text(fact.value ?? "—").font(MLType.monoBody).foregroundStyle(MLColor.inkSecondary)
                        .multilineTextAlignment(.trailing)
                }
                .frame(minHeight: 52)
                .overlay(alignment: .top) { Rectangle().fill(MLColor.border).frame(height: 1) }
                .accessibilityElement(children: .combine)
            }
        }
        .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
    }
}

/// The mess's earlier meals from its meal history: entries and whether waste was recorded, as plain text.
struct StaffEarlierMeals: View {
    let records: [MealRecord]
    let timeZone: TimeZone
    var limit = 3

    var body: some View {
        if !records.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: StaffSummaryCopy.earlierMeals)
                ForEach(Array(records.sorted { $0.day > $1.day }.prefix(limit))) { record in
                    HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(MLFormat.mealSlot(record.slot)) · \(day(record.day))")
                                .font(MLType.staffBody).foregroundStyle(MLColor.ink)
                            Text(waste(record.waste)).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                        }
                        Spacer(minLength: MLSpacing.s8)
                        Text(record.finalEntries.value.map(StaffSummaryCopy.entered) ?? "—")
                            .font(MLType.monoBody).foregroundStyle(MLColor.inkSecondary)
                    }
                    .padding(.vertical, MLSpacing.s12)
                    .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func waste(_ status: MealRecord.WasteStatus) -> String {
        if case .recorded = status { return StaffSummaryCopy.wasteRecorded }
        return StaffSummaryCopy.wasteNotRecorded
    }

    private func day(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEE d"
        return formatter.string(from: date)
    }
}
