import Foundation

/// An estimate of how busy the mess is. It never claims how many people are inside.
enum CrowdLevel: String, Codable, Sendable, Hashable {
    case quiet
    case busy
    case closed
}

/// The Crowd row on Student Home: seven hourly bars and one estimated level.
struct CrowdReading: Codable, Sendable, Hashable {
    let level: CrowdLevel
    /// Bar heights for the seven hours, in points as drawn.
    let bars: [Int]
    /// The hour the student is in. Nil while the mess is closed.
    let currentBar: Int?
    /// Quiet: the best time. Busy: when it gets quieter. Closed: when it opens. Nil when nothing is known.
    let detailTime: Date?
}

enum StudentPassRowStatus: String, Codable, Sendable, Hashable {
    case open
    case used
    case closed
}

/// The Special pass row on Student Home.
struct StudentPassRow: Codable, Sendable, Hashable {
    let meal: Meal
    let status: StudentPassRowStatus
}

/// "You said the sambar was too salty." A follow-up on the student's own earlier feedback.
struct StudentRecheck: Codable, Sendable, Hashable {
    let title: String
    let detail: String
}

/// Everything on Student Home that is not the meal answer. Each part is optional: a missing value is hidden or
/// shown as missing, never as zero.
struct StudentHomeExtras: Codable, Sendable, Hashable {
    let credits: Int?
    let crowd: CrowdReading?
    let pass: StudentPassRow?
    let recheck: StudentRecheck?
    let isMessClosed: Bool
    /// A meal of the day after the staff-run ones, which the student can still answer.
    let laterMeal: Meal?
}

/// The "Why skipping?" list. It equals the admin list exactly (design_intent.md, "Reasons for absence").
enum MealSkipReason: String, Codable, Sendable, CaseIterable, Hashable {
    case classOrExam
    case homeOrLeave
    case eatingElsewhere
    case dislikeDish
    case dietary
    case notHungry
    case other
    case preferNotToSay
}

/// Where the student's entry stands for one meal, as the Entry QR shows it.
enum StudentEntryStanding: Sendable, Hashable {
    case notScanned
    case scanned(at: Date)
    /// The code was shown again after the entry was recorded. Nothing was added to any count.
    case scannedAgain(firstAt: Date)
    /// The student opened the code at another mess. `homeMess` is the mess it belongs to.
    case wrongMess(homeMess: String)
}

/// What the QR carries for one 12-second window: the seeded code plus a changing token.
/// SIMULATED: nothing verifies the token, because QR scanning is not built. The typed last four is unchanged.
struct RotatingEntryCode: Codable, Sendable, Hashable {
    let payload: String
    let lastFour: String
    let step: Int
}

/// A meal on the student's attendance record that they can ask to have checked.
struct AttendanceRecord: Codable, Sendable, Hashable {
    let mealID: MealID
    let slot: MealSlot
    let day: Date
    let wasScanned: Bool
}

enum EntryCorrectionReason: String, Codable, Sendable, CaseIterable, Hashable {
    case ateButNotScanned
    case wrongMeal
    case other
}

struct EntryCorrectionRequest: Codable, Sendable, Hashable {
    let student: StudentID
    let mealID: MealID
    let reason: EntryCorrectionReason
    let note: String?
    let idempotencyKey: IdempotencyKey
}

/// A correction request as stored. It is a request only: it changes no entry and no count.
struct EntryCorrection: Codable, Sendable, Hashable {
    let request: EntryCorrectionRequest
    let sentAt: Date
}
