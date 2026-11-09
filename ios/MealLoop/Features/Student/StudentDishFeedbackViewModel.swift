import Observation
import SwiftUI

// The dish feedback flow after Not good (Figma file nzzTAm9YnJRSdKEeYUWUEb, page 07): Feedback · Which dish (2159:285),
// Which dish · More dishes (2159:471), What's wrong · Sambar (2159:149347), Pongal (2159:149553), Millet Idli
// (2159:149760), Masala Omelet (2159:149968), Milk (2159:150172), What's wrong · Sambar · Note (2159:150369), Sending
// (2159:150579), Sent (2159:150785), Failed (2159:150911), Offline · Saved (2159:151121) and Thanks (2159:159).
// Rules: one problem, how bad, an optional note; the kitchen never sees the name; no credits; offline keeps it on the
// device and sends nothing; "Unsafe or unwell? Use SOS" is the only way from here to SOS and Report.

/// What opens the flow.
struct StudentDishFeedbackRequest: Identifiable, Hashable {
    enum Kind: Hashable {
        /// Good was recorded: the Thanks sheet.
        case thanks
        /// Not good on a meal (the How was … card): Which dish first.
        case meal
        /// Not good on a dish (Rate a dish): straight to its What's wrong.
        case dish(String)
    }

    let id = UUID()
    let day: Date
    let slot: MealSlot
    let kind: Kind
}

@MainActor
@Observable
final class StudentDishFeedbackViewModel {
    enum Step: Equatable {
        case whichDish
        case whatsWrong(String)
        case sent(DishFeedbackReceipt)
        case thanks(Date)
    }

    enum SendState: Equatable { case idle, sending, failed, keptOffline }

    let context: StudentContext
    let day: Date
    let slot: MealSlot
    private(set) var steps: [Step]
    /// The meal's dishes, in menu order. Empty until the menu loads.
    private(set) var dishes: [Dish] = []
    private(set) var showsMoreDishes = false
    private(set) var mostReported: DishMostReported?
    private(set) var options: [DishProblemOption] = []
    /// Others per problem. Absent means nobody, never zero.
    private(set) var counts: [String: Int] = [:]
    var problem: String?
    var severity: DishFeedbackSeverity = .quite
    var note = ""
    var showsNote = false
    private(set) var sendState: SendState = .idle
    /// One key per draft: a retry sends the same feedback once.
    private var key = IdempotencyKey.make()

    private let feedback: any DishFeedbackRepository
    private let meals: any StudentMealsRepository
    private let clock: any AppClock

    init(context: StudentContext, repositories: Repositories, clock: any AppClock, request: StudentDishFeedbackRequest) {
        self.context = context
        self.clock = clock
        feedback = repositories.dishFeedback
        meals = repositories.studentMeals
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = context.mess.timeZone
        day = calendar.startOfDay(for: request.day)
        slot = request.slot
        switch request.kind {
        case .thanks: steps = [.thanks(clock.now())]
        case .meal: steps = [.whichDish]
        case .dish(let name): steps = [.whatsWrong(name)]
        }
    }

    var step: Step { steps.last ?? .whichDish }
    var timeZone: TimeZone { context.mess.timeZone }
    /// Back shows on What's wrong only when Which dish is under it, and never while a send is in flight.
    var canGoBack: Bool { steps.count > 1 && sendState != .sending }
    var isSending: Bool { sendState == .sending }
    var canSend: Bool { problem != nil && sendState != .sending }
    var visibleDishes: [Dish] { showsMoreDishes ? dishes : Array(dishes.prefix(3)) }
    var hasMoreDishes: Bool { dishes.count > 3 && !showsMoreDishes }
    var currentDish: String? { if case .whatsWrong(let dish) = step { return dish } else { return nil } }

    func load() async {
        switch step {
        case .whichDish: await loadMeal()
        case .whatsWrong(let dish): await loadChoices(dish)
        default: break
        }
    }

    func loadMeal() async {
        if let menu = try? await meals.mealMenu(on: day, slot: slot, mess: context.mess.id) {
            let all = [menu.highlight].compactMap { $0 } + menu.mains + menu.curries + menu.slimRows
            var seen = Set<String>()
            dishes = all.filter { seen.insert($0.name).inserted }
        }
        mostReported = try? await feedback.mostReported(day: day, slot: slot, at: context.mess.id)
    }

    func showMoreDishes() { showsMoreDishes = true }

    /// Which dish → What's wrong. `problem` preselects a choice ("Me too" on Most reported today).
    func choose(dish: String, problem: String? = nil) async {
        steps.append(.whatsWrong(dish))
        resetDraft()
        await loadChoices(dish)
        if let problem, let match = options.first(where: { $0.title.lowercased() == problem.lowercased() }) {
            self.problem = match.title
        }
    }

    func back() {
        guard canGoBack else { return }
        steps.removeLast()
        resetDraft()
    }

    func others(_ option: DishProblemOption) -> Int? { counts[option.title] }

    func send() async -> Bool {
        guard let dish = currentDish, let problem, sendState != .sending else { return false }
        sendState = .sending
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let submission = DishFeedbackSubmission(dishName: dish, day: day, slot: slot, problem: problem, severity: severity,
                                                note: trimmed.isEmpty ? nil : trimmed, key: key)
        do {
            let receipt = try await feedback.send(submission, at: context.mess.id, by: context.student.id)
            sendState = .idle
            steps = [.sent(receipt)]
            return true
        } catch RepositoryError.offline {
            await feedback.keepForLater(submission, at: context.mess.id, by: context.student.id)
            sendState = .keptOffline
            return false
        } catch {
            sendState = .failed
            return false
        }
    }

    /// Reads the dish's choices and counts. It never clears what the student already picked.
    private func loadChoices(_ dish: String) async {
        options = (try? await feedback.problems(forDish: dish)) ?? []
        counts = (try? await feedback.otherCounts(dish: dish, day: day, slot: slot, at: context.mess.id,
                                                  excluding: context.student.id)) ?? [:]
    }

    private func resetDraft() {
        problem = nil
        severity = .quite
        note = ""
        showsNote = false
        sendState = .idle
        key = IdempotencyKey.make()
    }
}
