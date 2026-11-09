#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SAMPLE. The "What's wrong?" choices of each dish, copied from its Figma frame (file nzzTAm9YnJRSdKEeYUWUEb, page 07),
/// in the order the frame draws them. A dish matches a set when its name contains the set's key ("Masala Sambar" uses
/// Sambar's). The glyph follows the ProblemGlyph mapping (2129:2324).
enum DemoDishProblemSeed {
    static let sets: [(key: String, options: [DishProblemOption])] = [
        // Feedback · What's wrong · Sambar (2159:149347).
        ("sambar", [o("Too salty", .salt), o("Too spicy", .spicy), o("Too watery", .drop), o("Too sour", .sour),
                    o("Cold", .cold), o("Too little", .little)]),
        // Feedback · What's wrong · Pongal (2159:149553).
        ("pongal", [o("Undercooked", .little), o("Mushy", .drop), o("Hard", .little), o("Stale", .sour),
                    o("Cold", .cold), o("Too little", .little)]),
        // Feedback · What's wrong · Millet Idli (2159:149760).
        ("millet idli", [o("Hard", .little), o("Undercooked", .little), o("Burnt", .spicy), o("Stale", .sour),
                         o("Cold", .cold), o("Too little", .little)]),
        // Feedback · What's wrong · Masala Omelet (2159:149968).
        ("omelet", [o("Too oily", .spicy), o("Too spicy", .spicy), o("Too salty", .salt), o("Hard", .little),
                    o("Cold", .cold), o("Too little", .little)]),
        // Feedback · What's wrong · Milk (2159:150172): five choices.
        ("milk", [o("Too sour", .sour), o("Watery", .drop), o("Not fresh", .sour), o("Warm", .spicy),
                  o("Too little", .little)]),
    ]

    /// GENERATED, OWNER TO REVIEW. For a dish no frame draws: the six problems the five frames share most (Cold and
    /// Too little in all or most, Hard in three, Stale, Too salty and Too spicy in two). Not from a frame.
    static let generic: [DishProblemOption] = [o("Too salty", .salt), o("Too spicy", .spicy), o("Hard", .little),
                                               o("Stale", .sour), o("Cold", .cold), o("Too little", .little)]

    static func options(forDish name: String) -> [DishProblemOption] {
        let lowered = name.lowercased()
        return sets.first { lowered.contains($0.key) }?.options ?? generic
    }

    private static func o(_ title: String, _ glyph: DishProblemGlyph) -> DishProblemOption {
        DishProblemOption(title: title, glyph: glyph)
    }
}

/// SIMULATED. Dish feedback recorded in one run of the app, and what is kept on the device while offline. Nothing is
/// sent to anyone. Shared with My feedback and the Admin's Students overview, so a send shows in both.
actor DemoDishFeedbackStore {
    struct Sent: Sendable, Hashable {
        let receipt: DishFeedbackReceipt
        let mess: MessID
        let student: StudentID
    }

    private(set) var sent: [Sent] = []
    private var kept: [(submission: DishFeedbackSubmission, mess: MessID, student: StudentID)] = []

    /// The first receipt for a key wins.
    func record(_ submission: DishFeedbackSubmission, mess: MessID, student: StudentID, at now: Date) -> DishFeedbackReceipt {
        if let first = sent.first(where: { $0.receipt.submission.key == submission.key }) { return first.receipt }
        let receipt = DishFeedbackReceipt(submission: submission, sentAt: now)
        sent.append(Sent(receipt: receipt, mess: mess, student: student))
        return receipt
    }

    func keep(_ submission: DishFeedbackSubmission, mess: MessID, student: StudentID) {
        guard !kept.contains(where: { $0.submission.key == submission.key }),
              !sent.contains(where: { $0.receipt.submission.key == submission.key }) else { return }
        kept.append((submission, mess, student))
    }

    func kept(by student: StudentID) -> [(submission: DishFeedbackSubmission, mess: MessID)] {
        kept.filter { $0.student == student }.map { ($0.submission, $0.mess) }
    }

    func removeKept(_ key: IdempotencyKey) { kept.removeAll { $0.submission.key == key } }

    func sent(by student: StudentID) -> [DishFeedbackReceipt] { sent.filter { $0.student == student }.map(\.receipt) }
}

/// SIMULATED. Dish feedback on top of the prototype data source. The "others" counts are the Admin seed's labelled
/// sample (`AdminSeed.feedback`) plus what other students sent in this run; nothing is invented and nothing is
/// confirmed by a server.
struct DemoDishFeedback: DishFeedbackRepository {
    let core: DemoDataProvider
    let store: DemoDishFeedbackStore

    func problems(forDish name: String) async throws -> [DishProblemOption] {
        DemoDishProblemSeed.options(forDish: name)
    }

    func otherCounts(dish name: String, day: Date, slot: MealSlot, at mess: MessID, excluding student: StudentID)
        async throws -> [String: Int] {
        try await core.requireConnection()
        guard mess == DemoSeed.mess.id else { return [:] }
        var counts: [String: Int] = [:]
        for item in AdminSeed.feedback where Self.sameMeal(item.day, item.slot, day, slot) && Self.sameDish(item.dish, name) {
            for problem in item.problems { counts[problem.title, default: 0] += problem.students }
        }
        for sent in await store.sent where sent.student != student && sent.mess == mess {
            let s = sent.receipt.submission
            if Self.sameMeal(s.day, s.slot, day, slot), Self.sameDish(s.dishName, name) { counts[s.problem, default: 0] += 1 }
        }
        return counts.filter { $0.value > 0 }
    }

    func mostReported(day: Date, slot: MealSlot, at mess: MessID) async throws -> DishMostReported? {
        try await core.requireConnection()
        guard mess == DemoSeed.mess.id else { return nil }
        var tally: [String: (dish: String, problem: String, students: Int)] = [:]
        for item in AdminSeed.feedback where Self.sameMeal(item.day, item.slot, day, slot) {
            for problem in item.problems {
                let key = "\(item.dish.lowercased())|\(problem.title.lowercased())"
                tally[key, default: (item.dish, problem.title, 0)].students += problem.students
            }
        }
        for sent in await store.sent where sent.mess == mess {
            let s = sent.receipt.submission
            guard Self.sameMeal(s.day, s.slot, day, slot) else { continue }
            let key = tally.first { Self.sameDish($0.value.dish, s.dishName)
                && $0.value.problem.lowercased() == s.problem.lowercased() }?.key
                ?? "\(s.dishName.lowercased())|\(s.problem.lowercased())"
            tally[key, default: (s.dishName, s.problem, 0)].students += 1
        }
        guard let top = tally.values.max(by: { $0.students < $1.students }), top.students > 0 else { return nil }
        return DishMostReported(dishName: top.dish, problem: top.problem, students: top.students)
    }

    func send(_ submission: DishFeedbackSubmission, at mess: MessID, by student: StudentID) async throws -> DishFeedbackReceipt {
        try await core.requireConnection()
        let receipt = await store.record(submission, mess: mess, student: student, at: core.clock.now())
        await store.removeKept(submission.key)
        return receipt
    }

    func keepForLater(_ submission: DishFeedbackSubmission, at mess: MessID, by student: StudentID) async {
        await store.keep(submission, mess: mess, student: student)
    }

    func kept(by student: StudentID) async -> [DishFeedbackSubmission] {
        await store.kept(by: student).map(\.submission)
    }

    func sendKept(by student: StudentID) async throws -> [DishFeedbackReceipt] {
        try await core.requireConnection()
        var receipts: [DishFeedbackReceipt] = []
        for item in await store.kept(by: student) {
            receipts.append(try await send(item.submission, at: item.mess, by: student))
        }
        return receipts
    }

    static func sameMeal(_ dayA: Date, _ slotA: MealSlot, _ dayB: Date, _ slotB: MealSlot) -> Bool {
        guard slotA == slotB else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DemoSeed.mess.timeZone
        return calendar.isDate(dayA, inSameDayAs: dayB)
    }

    /// "Sambar" in the Admin seed is the lunch menu's "Masala Sambar": one name contains the other.
    static func sameDish(_ a: String, _ b: String) -> Bool {
        let a = a.lowercased(), b = b.lowercased()
        return a == b || a.contains(b) || b.contains(a)
    }
}
/// SIMULATED. Adds the dish feedback sent in this run to the Admin seed's "Feedback to act on" (`AdminSeed.feedback`).
/// A send for a dish and problem the seed already lists adds one student to it; any other starts a new item. Counts
/// only: no item ever carries who sent it.
enum DemoDishFeedbackTally {
    static func merge(_ seed: [FeedbackItem], with sent: [DemoDishFeedbackStore.Sent]) -> [FeedbackItem] {
        var items = seed
        var added: [String: (submission: DishFeedbackSubmission, severities: [DishFeedbackSeverity])] = [:]
        var order: [String] = []
        for entry in sent {
            let s = entry.receipt.submission
            if let index = items.firstIndex(where: { item in
                DemoDishFeedback.sameMeal(item.day, item.slot, s.day, s.slot) && DemoDishFeedback.sameDish(item.dish, s.dishName)
                    && item.problems.contains { $0.title.lowercased() == s.problem.lowercased() }
            }) {
                items[index] = adding(s, to: items[index])
            } else {
                let key = "\(s.dishName.lowercased())|\(s.problem.lowercased())|\(s.slot.rawValue)|\(Int(s.day.timeIntervalSince1970))"
                if added[key] == nil { order.append(key) }
                added[key, default: (s, [])].severities.append(s.severity)
            }
        }
        for key in order {
            guard let group = added[key] else { continue }
            let s = group.submission
            let problem = FeedbackProblem(title: s.problem, severity: severityLine(counts(group.severities)),
                                          students: group.severities.count)
            items.append(FeedbackItem(id: FeedbackItemID("sent-\(key)"), dish: s.dishName, problem: s.problem.lowercased(),
                                      mess: mess, slot: s.slot, day: s.day, students: group.severities.count, isNew: true,
                                      problems: [problem], meal: mealID(day: s.day, slot: s.slot)))
        }
        return items
    }

    /// The Admin seed writes the mess without "Mess" ("Main").
    private static var mess: String { DemoSeed.mess.name.replacingOccurrences(of: " Mess", with: "") }

    private static func adding(_ s: DishFeedbackSubmission, to item: FeedbackItem) -> FeedbackItem {
        let problems = item.problems.map { problem -> FeedbackProblem in
            guard problem.title.lowercased() == s.problem.lowercased() else { return problem }
            var counts = parse(problem.severity)
            counts[s.severity, default: 0] += 1
            return FeedbackProblem(title: problem.title, severity: severityLine(counts), students: problem.students + 1)
        }
        return FeedbackItem(id: item.id, dish: item.dish, problem: item.problem, mess: item.mess, slot: item.slot, day: item.day,
                            students: item.students + 1, isNew: item.isNew, problems: problems, meal: item.meal)
    }

    private static let words: [(DishFeedbackSeverity, String)] = [(.aBit, "a bit"), (.quite, "quite"), (.very, "very")]

    /// Reads the seed's own line, "How bad: quite (5), very (1)".
    static func parse(_ line: String) -> [DishFeedbackSeverity: Int] {
        var counts: [DishFeedbackSeverity: Int] = [:]
        for (severity, word) in words {
            guard let range = line.range(of: "\(word) (") else { continue }
            let digits = line[range.upperBound...].prefix { $0.isNumber }
            if let value = Int(digits) { counts[severity] = value }
        }
        return counts
    }

    static func severityLine(_ counts: [DishFeedbackSeverity: Int]) -> String {
        let parts = words.compactMap { severity, word in counts[severity].map { "\(word) (\($0))" } }
        return "How bad: " + parts.joined(separator: ", ")
    }

    private static func counts(_ severities: [DishFeedbackSeverity]) -> [DishFeedbackSeverity: Int] {
        severities.reduce(into: [:]) { $0[$1, default: 0] += 1 }
    }

    /// The story day's meals keep their seeded ids; another day gets one in the same shape.
    private static func mealID(day: Date, slot: MealSlot) -> MealID {
        for meal in [DemoSeed.breakfast, DemoSeed.lunch, DemoSeed.dinner] where meal.slot == slot
            && DemoDishFeedback.sameMeal(meal.startsAt, meal.slot, day, slot) { return meal.id }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = DemoSeed.mess.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return MealID("demo-\(formatter.string(from: day))-\(slot.rawValue)")
    }
}
#endif
