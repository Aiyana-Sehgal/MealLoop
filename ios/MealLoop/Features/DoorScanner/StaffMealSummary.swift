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
    static let reportedFromThisPhone = "reported from this phone"
    static let reported = "Reported"
    static let sent = "Sent"
    static let savedOnPhone = "Saved on this phone"
    static let enteredWithoutVotingCaption = "entered without voting"
    static let firstEntry = "First entry"
    static let latestEntry = "Latest entry"
    static let students = "Students"
    static func title(_ slot: MealSlot, _ mess: String) -> String { "\(MLFormat.mealSlot(slot)) · \(mess)" }
}

/// One label and value on a hairline row. A nil value shows a dash.
struct StaffFact: Identifiable, Hashable {
    let label: String
    let value: String?
    var id: String { label }
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


/// A black card with one count the page already holds ("2 problems reported from this phone").
struct StaffCountCard: View {
    let eyebrow: String
    var time: String?
    let count: Int?
    let caption: String

    var body: some View {
        HeroCard {
            HeroEyebrow(label: eyebrow, time: time)
            HeroCount(value: count, caption: caption)
                .padding(.top, MLSpacing.s12)
        }
        .accessibilityElement(children: .combine)
    }
}
