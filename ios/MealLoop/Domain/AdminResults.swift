import Foundation

// Read models for the Food Head's Results tab. A value the records do not have stays nil: it is never zero.

/// How sure MealLoop is about a reason. These three words are the whole scale: a reason has no percentage.
enum ReasonTag: String, Codable, Sendable, CaseIterable, Hashable {
    /// Measured from records.
    case sure
    /// Indirect evidence.
    case probably
    /// Key data is missing.
    case cantTell
}

enum ResultSegment: String, Codable, Sendable, CaseIterable, Hashable {
    case leftOver
    case ranOut
    case toCheck
}

enum ReasonKind: String, Codable, Sendable, CaseIterable, Hashable {
    case fewerCame
    case didntLikeDish
    case raisedLate
    case cantTellLeftOver
    case moreCame
    case lastThirtyMinutes
    case reportedLate
    case cantTellRanOut
}

/// One sentence with a count of meals. A meal can have more than one reason, so counts can add up to more than the total.
struct ResultReason: Codable, Sendable, Hashable, Identifiable {
    let kind: ReasonKind
    let title: String
    let detail: String?
    let meals: Int
    let tag: ReasonTag

    var id: ReasonKind { kind }
}

struct ResultGroup: Codable, Sendable, Hashable {
    let meals: Int
    let totalMeals: Int
    /// The first is the leading reason.
    let reasons: [ResultReason]
}

/// Evidence a meal may lack. Shown as missing, never as zero.
enum MissingEvidence: String, Codable, Sendable, CaseIterable, Hashable {
    case amountCooked
    case eventCount
    case scannerRecords
    case wasteRecord
}

/// A dish amount. A nil amount has not been recorded.
struct FoodAmount: Codable, Sendable, Hashable, Identifiable {
    let dish: String
    let amount: Double?
    let unit: WasteUnit

    var id: String { dish }
}

struct FoodRanOut: Codable, Sendable, Hashable, Identifiable {
    let dish: String
    let at: Date?

    var id: String { dish }
}

struct HeadcountChange: Codable, Sendable, Hashable {
    let from: Int
    let to: Int
    let at: Date?
    let reason: String
}

/// What the records say about one meal, for the rows, cards and the Meal report.
struct AdminMealFacts: Codable, Sendable, Hashable, Identifiable {
    let id: MealID
    let mess: String
    let slot: MealSlot
    /// Midnight of the day served, in the mess time zone.
    let day: Date
    /// The headcount sent to the vendor. "Planned for" always means this number.
    let headcountSent: Int?
    let sentAt: Date?
    /// Final entries. Nil until the meal has closed and the count exists.
    let finalEntries: Int?
    let closedAt: Date?
    let isClosed: Bool
    let leftovers: [FoodAmount]
    let plateWasteKg: Double?
    let ranOut: [FoodRanOut]
    let wasReportedLate: Bool
    /// The share of this meal's records that exist. Data completeness, never a reason.
    let dataCompletePercent: Int?
    let missing: [MissingEvidence]
    let headcountChange: HeadcountChange?
    /// Questions nobody recorded an answer to ("Did the event add diners?").
    let openQuestions: [String]
    let needsReview: Bool
    /// The change this meal already feeds, if there is one.
    let linkedCheck: CheckID?
    /// Filled into "Make it a change" when the pack gives wording for this meal.
    let suggestedChange: String?
}

struct ReviewMeal: Codable, Sendable, Hashable, Identifiable {
    let meal: AdminMealFacts

    var id: MealID { meal.id }
}

struct AdminResultsOverview: Codable, Sendable, Hashable {
    let periodTitle: String
    let leftOver: ResultGroup
    let ranOut: ResultGroup
    let toReview: [ReviewMeal]
    let changes: [CheckNextTime]
}

/// A food in the strip at the top of a reason. `meals` is a count of meals, `detail` a place and time.
struct ReasonFood: Codable, Sendable, Hashable, Identifiable {
    let dish: String
    let meals: Int?
    let at: Date?
    let mess: String?

    var id: String { dish }
}

struct DishFeedbackLine: Codable, Sendable, Hashable, Identifiable {
    let dish: String
    let problem: String
    let students: Int

    var id: String { dish + problem }
}

struct ReasonTimelineLine: Codable, Sendable, Hashable, Identifiable {
    let at: Date
    let text: String

    var id: Date { at }
}

/// Entries per 15 minutes for one meal, as relative bar heights from the reference. There are no counts behind them.
struct ArrivalShape: Codable, Sendable, Hashable {
    let barHeights: [Double]
    /// The dashed line sits after this many bars.
    let markerAfterBar: Int
    let markerText: String
    let axisLabels: [String]
}

struct AdminReasonDetail: Codable, Sendable, Hashable {
    let reason: ResultReason
    let explanation: String
    let foodsTitle: String?
    let foods: [ReasonFood]
    let feedback: [DishFeedbackLine]
    let missing: [MissingEvidence]
    let meals: [AdminMealFacts]
    /// Meals behind the count that are not listed here.
    let moreMeals: Int
    let arrivals: ArrivalShape?
    let timeline: [ReasonTimelineLine]
    let timelineNote: String?
}

// MARK: Check next time

struct CheckID: Hashable, Codable, Sendable {
    let rawValue: String

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

enum CheckStage: String, Codable, Sendable, CaseIterable, Hashable {
    case open
    case testing
    case result
}

/// One meal a change is judged against.
struct ComparableMeal: Codable, Sendable, Hashable, Identifiable {
    let day: Date
    /// Nil while the meal is still to come.
    let headcountSent: Int?
    let finalEntries: Int?
    /// A recorded fact shown in place of the two counts ("41 IDs typed by hand").
    let note: String?
    let isRecorded: Bool
    /// False when the meal happened but fails the check's own rule, such as IDs typed by hand.
    let isComparable: Bool
    let ranOut: Bool

    var id: Date { day }
}

/// A change being tested. Making the change is not the same as the change having worked.
struct CheckNextTime: Codable, Sendable, Hashable, Identifiable {
    let id: CheckID
    let title: String
    let listTitle: String
    let mess: String
    let startedOn: Date
    let startedBy: String
    let change: String
    let owner: String
    /// "check 2 Wednesday lunches"
    let plan: String
    let comparableTitle: String
    let comparable: [ComparableMeal]
    let footnote: String
    /// The action itself is done. This says nothing about the result.
    var isActionCompleted: Bool
    var stage: CheckStage
    var notes: [String]
    var closedAsWorked: Bool
}

enum CheckNextTimePolicy {
    /// admin_sample_data.md: "cannot be closed as 'worked' until 2 comparable meals are recorded".
    static let requiredMeals = 2

    static func countedMeals(_ check: CheckNextTime) -> Int {
        check.comparable.filter { $0.isRecorded && $0.isComparable }.count
    }

    /// A finished action counts for nothing here: only comparable meals do, and none of them may have run out.
    static func canCloseAsWorked(_ check: CheckNextTime) -> Bool {
        let counted = check.comparable.filter { $0.isRecorded && $0.isComparable }
        return counted.count >= requiredMeals && !counted.contains { $0.ranOut }
    }
}

struct ChangeDraft: Codable, Sendable, Hashable {
    let meal: MealID?
    let change: String
    let owner: String
}

// MARK: Safety cases

struct SafetyStep: Codable, Sendable, Hashable, Identifiable {
    let title: String
    let detail: String
    /// "Student", "Staff", "Vendor" or "You".
    let who: String
    let isDone: Bool
    let isCurrent: Bool

    var id: String { title }
}

/// A safety case as the Food Head reads it. The student is shown masked, never by a full ID.
struct AdminSafetyCase: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let title: String
    let dish: String
    let mess: String
    let place: String
    let slot: MealSlot
    let day: Date
    let reportedAt: Date
    let accuracyMetres: Int
    let closedAt: Date?
    let steps: [SafetyStep]
    let contactName: String
}

// MARK: Weekly report

enum ReportPeriod: String, Codable, Sendable, CaseIterable, Hashable {
    case thisWeek
    case lastWeek
    case month
}

struct ReportReasonLine: Codable, Sendable, Hashable, Identifiable {
    let title: String
    let meals: Int
    let tag: ReasonTag

    var id: String { title }
}

struct ReportFoodLine: Codable, Sendable, Hashable, Identifiable {
    let dish: String
    let meals: Int
    let amount: String

    var id: String { dish }
}

struct ReportMessLine: Codable, Sendable, Hashable, Identifiable {
    let mess: String
    let plateWasteKg: Int?
    let ranOutMeals: Int?
    let dataCompletePercent: Int?

    var id: String { mess }
}

struct ReportChangeLine: Codable, Sendable, Hashable, Identifiable {
    let title: String
    let detail: String
    let status: String

    var id: String { title }
}

/// The two pages of the printed report. Only This week has a drawn breakdown.
struct ReportPages: Codable, Sendable, Hashable {
    let reasons: [ReportReasonLine]
    let foods: [ReportFoodLine]
    let ranOutLines: [String]
    let byMess: [ReportMessLine]
    let changes: [ReportChangeLine]
    let safetyLines: [String]
    let dataGaps: [String]
}

struct ReportSection: Codable, Sendable, Hashable, Identifiable {
    let title: String
    let page: Int

    var id: String { title }
}

struct AdminWeeklyReport: Codable, Sendable, Hashable {
    let period: ReportPeriod
    let range: String
    let fullRange: String
    let eyebrow: String
    let mealsLeftOver: Int
    let mealsRanOut: Int
    let dataCompletePercent: Int?
    let sections: [ReportSection]
    let pages: ReportPages?
    let vendorSummary: String
}
