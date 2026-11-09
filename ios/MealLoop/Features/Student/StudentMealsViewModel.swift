import Foundation
import Observation

/// The Meals tab: a week strip, four meals and the menu of the one picked. Screen state only; the menu, its layout and
/// whether it is published all come from `StudentMealsRepository`.
@MainActor
@Observable
final class StudentMealsViewModel {
    private(set) var week: StudentWeek?
    private(set) var selectedDay: Date?
    private(set) var selectedSlot: MealSlot = .lunch
    private(set) var state: LoadState<StudentMealMenu> = .idle
    /// The day's other meals, kept so "Dinner opens 7:30 PM" can be said without asking again.
    private(set) var dayMenus: [MealSlot: StudentMealMenu] = [:]

    let context: StudentContext
    private let repository: any StudentMealsRepository
    private let clock: any AppClock
    /// Menus already shown, so an offline tap still shows what was saved, with when.
    private var saved: [String: (menu: StudentMealMenu, at: Date)] = [:]
    private var hasPickedSlot = false

    static let slots: [MealSlot] = [.breakfast, .lunch, .snacks, .dinner]

    init?(session: Session, repositories: Repositories, clock: any AppClock) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.repository = repositories.studentMeals
        self.clock = clock
    }

    var timeZone: TimeZone { context.mess.timeZone }
    var now: Date { clock.now() }

    var isToday: Bool { selectedDay != nil && selectedDay == week?.today }

    /// "Lunch service has ended for today." Only for today, and only when the backend gives the meal a time.
    var serviceEnded: (slot: MealSlot, next: (slot: MealSlot, from: Date)?)? {
        guard isToday, let menu = state.value, menu.status == .published, let until = menu.servedUntil, until <= now else { return nil }
        let later = Self.slots.drop { $0 != selectedSlot }.dropFirst()
            .compactMap { slot in dayMenus[slot]?.servedFrom.map { (slot: slot, from: $0) } }
            .first { $0.from > now }
        return (selectedSlot, later)
    }

    private func key(_ day: Date, _ slot: MealSlot) -> String { "\(day.timeIntervalSince1970)-\(slot.rawValue)" }

    /// The other dishes of the meal a dish belongs to, from a menu this model has already loaded (the one on screen or
    /// another meal of that day). Empty when that menu is not loaded or not published: nothing is fetched or invented.
    func otherDishes(than dish: DishID, day: Date, slot: MealSlot) -> [Dish] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let menus = [state.value].compactMap { $0 } + Array(dayMenus.values)
        guard let menu = menus.first(where: { $0.slot == slot && $0.status == .published
                                              && calendar.isDate($0.day, inSameDayAs: day) }) else { return [] }
        return ([menu.highlight].compactMap { $0 } + menu.mains + menu.curries + menu.slimRows).filter { $0.id != dish }
    }

    func load() async {
        do {
            if week == nil {
                let loaded = try await repository.week(for: context.mess.id)
                week = loaded
                selectedDay = loaded.today
            }
            guard let day = selectedDay else { return }
            if !hasPickedSlot && day == week?.today {
                await loadDay(day)
                selectedSlot = defaultSlot()
            }
            await loadMenu()
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(nil, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    /// The meal still to answer, as Home leads with: the first whose cutoff has not passed; then the first still being
    /// served; otherwise the last of the day. Snacks are never answered (P7), so they are never the default.
    private func defaultSlot() -> MealSlot {
        // With no times to go by, the meal on screen stays.
        guard !dayMenus.isEmpty else { return selectedSlot }
        let answerable = Self.slots.filter { $0 != .snacks }
        if let open = answerable.first(where: { slot in
            dayMenus[slot]?.servedFrom.map { now < $0.addingTimeInterval(-IntentionPolicy.cutoffBeforeMeal) } ?? false
        }) { return open }
        if let serving = answerable.first(where: { dayMenus[$0]?.servedUntil.map { now < $0 } ?? false }) { return serving }
        return .dinner
    }

    private func loadDay(_ day: Date) async {
        for slot in Self.slots {
            if let menu = try? await repository.mealMenu(on: day, slot: slot, mess: context.mess.id) {
                dayMenus[slot] = menu
            }
        }
    }

    private func loadMenu() async {
        guard let day = selectedDay else { return }
        let slot = selectedSlot
        if state.value?.day != day || state.value?.slot != slot {
            state = .loading
        }
        do {
            let menu = try await repository.mealMenu(on: day, slot: slot, mess: context.mess.id)
            guard day == selectedDay, slot == selectedSlot else { return }
            dayMenus[slot] = menu
            saved[key(day, slot)] = (menu, clock.now())
            state = .loaded(menu)
        } catch RepositoryError.offline {
            guard day == selectedDay, slot == selectedSlot else { return }
            let kept = saved[key(day, slot)]
            state = .offline(kept?.menu, savedAt: kept?.at)
        } catch {
            guard day == selectedDay, slot == selectedSlot else { return }
            state = .failed(LoadFailure(error))
        }
    }

    func select(day: Date) async {
        guard day != selectedDay else { return }
        selectedDay = day
        dayMenus = [:]
        if day == week?.today { await loadDay(day) }
        await loadMenu()
    }

    func select(slot: MealSlot) async {
        guard slot != selectedSlot else { return }
        hasPickedSlot = true
        selectedSlot = slot
        await loadMenu()
    }

    /// Opens a search result in the menu: its day and its meal.
    func show(day: Date, slot: MealSlot) async {
        if week == nil { await load() }
        hasPickedSlot = true
        selectedSlot = slot
        selectedDay = day
        dayMenus = [:]
        if day == week?.today { await loadDay(day) }
        await loadMenu()
    }

    func dishDetail(_ dish: DishID, day: Date, slot: MealSlot) async throws -> StudentDishDetail {
        try await repository.dishDetail(dish, on: day, slot: slot, mess: context.mess.id)
    }
}

/// Search: one function only, finding dishes of this week's menu by name (owner ruling).
@MainActor
@Observable
final class StudentSearchViewModel {
    var text = ""
    private(set) var state: LoadState<[StudentDishMatch]> = .idle
    private(set) var searchedText = ""

    let context: StudentContext
    private let repository: any StudentMealsRepository

    init?(session: Session, repositories: Repositories) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.repository = repositories.studentMeals
    }

    var timeZone: TimeZone { context.mess.timeZone }

    func search() async {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            state = .idle
            searchedText = ""
            return
        }
        state = .loading
        do {
            let found = try await repository.findDishes(query, mess: context.mess.id)
            guard query == text.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            searchedText = query
            state = found.isEmpty ? .empty : .loaded(found)
        } catch RepositoryError.offline(let savedAt) {
            searchedText = query
            state = .offline(nil, savedAt: savedAt)
        } catch {
            searchedText = query
            state = .failed(LoadFailure(error))
        }
    }

    func clear() {
        text = ""
        searchedText = ""
        state = .idle
    }
}
