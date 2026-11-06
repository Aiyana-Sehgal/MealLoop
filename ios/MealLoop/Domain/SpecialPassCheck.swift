import Foundation

typealias PassReissueID = Identifier<PassReissueRequest>

/// A student as the desk sees them: a first name and a masked ID.
struct SpecialPassHolder: Codable, Sendable, Hashable {
    let student: StudentRef
    let name: String
}

/// What the pass service says about a typed last four. It records nothing; only `recordPassEntry` does.
enum SpecialPassLookup: Sendable, Hashable {
    case notFound
    case noPass(SpecialPassHolder)
    /// A real pass for another meal of the day.
    case wrongMeal(SpecialPassHolder, passFor: MealSlot)
    /// A pass for this meal, with what the student's phone should show right now.
    case valid(SpecialPassHolder, live: LivePassCode)
    /// Already recorded for this meal. `count` is the special-meal count, unchanged by this lookup.
    case used(SpecialPassHolder, firstRecordedAt: Date, count: Int?)
}

/// "Matches · record entry". `comparedCode` is the code on the desk's screen when staff tapped it.
struct SpecialPassEntryRequest: Codable, Sendable, Hashable {
    let mealID: MealID
    let student: StudentRef
    let comparedCode: String
    let recordedBy: Role
    let idempotencyKey: IdempotencyKey
}

/// A special-meal entry. It is separate from the door's entries: it counts toward "Special meals recorded" only.
struct SpecialPassEntry: Codable, Sendable, Hashable {
    let mealID: MealID
    let student: StudentRef
    let recordedAt: Date
    let recordedBy: Role
}

/// The outcome of "Matches · record entry". An offline attempt is an error, never a result.
enum SpecialPassEntryResult: Sendable, Hashable {
    case recorded(SpecialPassEntry, count: Int?)
    /// Nothing was added.
    case alreadyRecorded(firstRecordedAt: Date, count: Int?)
    /// The code staff compared is no longer the live one. Nothing was recorded.
    case codeChanged
    /// The Supervisor ended the meal first. Nothing was recorded.
    case mealEnded(closedAt: Date?, count: Int?)
}

/// "Special meals recorded 42 of 214". A missing value is nil or `.unavailable`, never zero.
struct SpecialMealCount: Codable, Sendable, Hashable {
    let recorded: CountReading
    let passes: Int?
}

enum PassReissueReason: String, Codable, Sendable, CaseIterable, Hashable {
    case phoneLost
    case appProblem
    case wrongCode
    case other
}

/// A request in the admin pass-exception flow. `updatedAt` is nil where the design gives no time.
struct PassReissueRequest: Codable, Sendable, Hashable, Identifiable {
    let id: PassReissueID
    let holder: SpecialPassHolder
    let reason: PassReissueReason?
    var status: PassReissueStatus
    var updatedAt: Date?
}

struct PassReissueSubmission: Codable, Sendable, Hashable {
    let student: StudentRef
    let reason: PassReissueReason
    let requestedBy: Role
    let idempotencyKey: IdempotencyKey
}
