import SwiftUI

// The Food Head's own-mess screens (single-mess scope). Same design language as the all-mess Admin: black hero cards,
// white grouped cards and hairline rows, filled with the data this mess has. Global totals are never shown as if they
// belonged to this mess.

enum AdminSingleMessCopy {
    static func answersFor(_ meal: String) -> String { "ANSWERS · \(meal.uppercased())" }
    static func answered(_ count: Int) -> String { "\(count) answered" }
    static let yes = "I'm in"
    static let no = "Skip"
    static let notSure = "Not sure"
    static let noReply = "No reply yet"
    static let feedback = "FEEDBACK"
    static let community = "COMMUNITY"
    static func students(_ count: Int) -> String { "\(count) \(count == 1 ? "student" : "students")" }
    static let noFeedback = "No feedback for this mess yet."
    static let noCommunity = "No community reports for this mess yet."
    static func stage(_ stage: CommunityStage) -> String {
        switch stage {
        case .raised: "Raised"
        case .owner: "Owner set"
        case .fixed: "Fixed"
        }
    }
    static let foodHead = "Food head"
    static let yourMess = "You see this mess only."
    static let planning = "PLANNING"
    static let account = "ACCOUNT"
    static let headcountPage = "Headcount"
    static let liveMeal = "Live meal"
}

/// White grouped card of hairline rows, as on More.
struct AdminGroupCard<Rows: View>: View {
    @ViewBuilder let rows: Rows

    var body: some View {
        VStack(spacing: 0) { rows }
            .padding(.horizontal, MLSpacing.s16)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
    }
}

