#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

private final class MealsClock: StoryClock, @unchecked Sendable {
    private var current = Date(timeIntervalSince1970: 0)
    func now() -> Date { current }
    func set(_ date: Date) { current = date }
}

/// The additive Student Meals, Special pass and Crowd operations on the prototype backend.
final class StudentMealsRepositoryTests: XCTestCase {
    private let aarav = DemoSeed.sampleStudent.id
    private let mess = DemoSeed.mess.id
    private let wednesday = DemoSeed.date(14, 0, 0)

    private func make(_ scenario: DemoScenario = .storyStart) -> (DemoDataProvider, MealsClock) {
        let clock = MealsClock()
        return (DemoDataProvider(scenario: scenario, clock: clock), clock)
    }

    private func names(_ dishes: [Dish]) -> [String] { dishes.map(\.name) }

    // MARK: Week and menus

    func testTheWeekIsTheBoardsWeekWithWednesdayAsToday() async throws {
        let (demo, _) = make()
        let week = try await demo.week(for: mess)
        XCTAssertEqual(week.days.count, 7)
        XCTAssertEqual(week.days.first, DemoSeed.date(12, 0, 0))
        XCTAssertEqual(week.days.last, DemoSeed.date(18, 0, 0))
        XCTAssertEqual(week.today, wednesday)
    }

    func testWednesdayLunchIsLaidOutAsTheFrameDrawsIt() async throws {
        let (demo, _) = make()
        let menu = try await demo.mealMenu(on: wednesday, slot: .lunch, mess: mess)
        XCTAssertEqual(menu.status, .published)
        XCTAssertEqual(menu.highlight?.name, "Bhindi Aloo Bujjiya")
        XCTAssertEqual(names(menu.mains), ["Chappati", "Veg Pulao", "Muttar Masala"])
        XCTAssertEqual(names(menu.sides), ["Steamed Rice", "Masala Sambar", "Tomato Dal", "Garlic Rasam", "Pickle", "Poriyal",
                                           "Butter Milk", "Fryums"])
        XCTAssertTrue(menu.curries.isEmpty)
        XCTAssertTrue(menu.slimRows.isEmpty)
        XCTAssertEqual(menu.special?.dishes, ["Chicken Briyani", "Panneer Briyani"])
        XCTAssertEqual(menu.special?.isLimited, true)
        XCTAssertEqual(menu.servedFrom, DemoSeed.lunch.startsAt)
        XCTAssertEqual(menu.servedUntil, DemoSeed.lunch.endsAt)
        XCTAssertTrue(menu.isAnswerable)
        XCTAssertNil(menu.changedAt)
    }

    func testWednesdayDinnerHasCurriesAndTheGravyAsASlimRow() async throws {
        let (demo, _) = make()
        let menu = try await demo.mealMenu(on: wednesday, slot: .dinner, mess: mess)
        XCTAssertNil(menu.highlight, "The only highlighted dinner dish is a non-veg gravy, drawn as a slim row.")
        XCTAssertEqual(names(menu.mains), ["Chappathi", "Steamed Rice", "Dal Tadka"])
        XCTAssertEqual(names(menu.curries), ["Butter Chicken Masala", "Panneer Butter Masala"])
        XCTAssertEqual(names(menu.slimRows), ["Chicken Gravy"])
        XCTAssertEqual(menu.slimRows.first?.diet, .nonVeg)
        XCTAssertEqual(menu.slimRows.first?.isHighlight, true)
        XCTAssertEqual(names(menu.sides), ["Rasam", "Pickle", "Fryums", "Veg Salad", "Milk", "Banana"])
        XCTAssertNil(menu.special)
    }

    func testSnacksAreMenuOnlyAndHaveNoInventedTime() async throws {
        let (demo, _) = make()
        let menu = try await demo.mealMenu(on: wednesday, slot: .snacks, mess: mess)
        XCTAssertFalse(menu.isAnswerable)
        XCTAssertNil(menu.servedFrom)
        XCTAssertNil(menu.servedUntil)
        XCTAssertEqual(menu.highlight?.name, "Veg Puff")
        XCTAssertEqual(names(menu.mains), ["Sweet Puff"])
        XCTAssertEqual(names(menu.sides), ["Tea", "Coffee"])
    }

    func testADayWithNoFrameUsesTheBoardsHighlightsAsTiles() async throws {
        let (demo, _) = make()
        let monday = DemoSeed.date(12, 0, 0)
        let menu = try await demo.mealMenu(on: monday, slot: .lunch, mess: mess)
        XCTAssertEqual(menu.highlight?.name, "Chappathi")
        XCTAssertEqual(names(menu.mains), ["Rajma Masala", "Drumstick Brinjal", "Veg Subji"])
        XCTAssertFalse(menu.sides.contains { $0.isHighlight })
        XCTAssertEqual(menu.servedFrom, DemoSeed.lunch.startsAt.addingTimeInterval(-2 * 86_400))
        XCTAssertNil(menu.special)
    }

    func testAMealTheFoodHeadEmptiesHasNoMenuAndSaysWhenItChanged() async throws {
        let (demo, clock) = make()
        let repositories = demo.makeRepositories()
        var day = try await repositories.adminMore.weekMenu().days.first { $0.day == self.wednesday }!
        day.meals[.snacks] = []
        clock.set(DemoSeed.time(11, 10))
        _ = try await repositories.adminMore.saveDay(day, by: .admin)

        let snacks = try await demo.mealMenu(on: wednesday, slot: .snacks, mess: mess)
        XCTAssertEqual(snacks.status, .noMeal)
        XCTAssertTrue(snacks.allDishes.isEmpty)
        let lunch = try await demo.mealMenu(on: wednesday, slot: .lunch, mess: mess)
        XCTAssertEqual(lunch.changedAt, DemoSeed.time(11, 10))
        let thursday = try await demo.mealMenu(on: DemoSeed.date(15, 0, 0), slot: .lunch, mess: mess)
        XCTAssertNil(thursday.changedAt)
    }

    func testADayOutsideTheWeekIsNotPublished() async throws {
        let (demo, _) = make()
        let menu = try await demo.mealMenu(on: DemoSeed.date(19, 0, 0), slot: .lunch, mess: mess)
        XCTAssertEqual(menu.status, .notPublished)
        XCTAssertTrue(menu.allDishes.isEmpty)
    }

    func testOfflineMenusThrowAndNeverComeBackEmpty() async throws {
        let (demo, _) = make(.offline)
        do {
            _ = try await demo.mealMenu(on: wednesday, slot: .lunch, mess: mess)
            XCTFail("Offline must throw")
        } catch RepositoryError.offline {}
    }

    // MARK: Dish detail and search

    func testSambarHasTheDrawnDetailsAndOtherDishesHaveNone() async throws {
        let (demo, _) = make()
        let sambar = try await demo.dishDetail(DishID("sambar"), on: wednesday, slot: .breakfast, mess: mess)
        XCTAssertEqual(sambar.portion, "1 bowl")
        XCTAssertEqual(sambar.allergens, ["Mustard seeds", "Curry leaves"])
        XCTAssertEqual(sambar.verifiedOn, DemoSeed.date(12, 0, 0))
        XCTAssertEqual(sambar.servedFrom, DemoSeed.breakfast.startsAt)

        let pongal = try await demo.dishDetail(DishID("pongal"), on: wednesday, slot: .breakfast, mess: mess)
        XCTAssertNil(pongal.portion)
        XCTAssertTrue(pongal.allergens.isEmpty)
        XCTAssertNil(pongal.verifiedOn)
    }

    func testFindingADishNarrowsByNameAndEmptiesCorrectly() async throws {
        let (demo, _) = make()
        let sambar = try await demo.findDishes("SAMBAR", mess: mess)
        XCTAssertFalse(sambar.isEmpty)
        XCTAssertTrue(sambar.allSatisfy { $0.dish.name.lowercased().contains("sambar") })
        XCTAssertTrue(sambar.contains { $0.day == self.wednesday && $0.slot == .breakfast })

        let narrower = try await demo.findDishes("masala sambar", mess: mess)
        XCTAssertLessThan(narrower.count, sambar.count)
        XCTAssertTrue(narrower.allSatisfy { $0.dish.name == "Masala Sambar" })

        let none = try await demo.findDishes("biryani", mess: mess)
        XCTAssertTrue(none.isEmpty)
        let blank = try await demo.findDishes("   ", mess: mess)
        XCTAssertTrue(blank.isEmpty)
    }

    // MARK: Special pass

    func testThePassIsAvailableThenLiveWhenHeld() async throws {
        let (demo, _) = make()
        guard case .available(let ticket) = try await demo.passStanding(of: aarav, at: mess) else { return XCTFail("Available") }
        XCTAssertEqual(ticket.holderName, "Aarav")
        XCTAssertEqual(ticket.maskedID, "••0238")
        XCTAssertEqual(ticket.dishes, ["Chicken Briyani", "Panneer Briyani"])
        XCTAssertEqual(ticket.meal, DemoSeed.lunch)

        let first = try await demo.startPass(of: aarav, key: IdempotencyKey("hold-1"))
        guard case .live(_, let startedAt) = first else { return XCTFail("Live") }
        XCTAssertEqual(startedAt, DemoSeed.storyStartNow)
        let again = try await demo.startPass(of: aarav, key: IdempotencyKey("hold-1"))
        XCTAssertEqual(again, first, "The same key returns the first result.")
        do {
            _ = try await demo.startPass(of: aarav, key: IdempotencyKey("hold-2"))
            XCTFail("A live pass cannot be started twice")
        } catch RepositoryError.notAllowed {}
        guard case .live = try await demo.passStanding(of: aarav, at: mess) else { return XCTFail("Still live") }
    }

    func testTheLiveCodeAndColourRotate() async throws {
        let (demo, _) = make()
        _ = try await demo.startPass(of: aarav, key: IdempotencyKey("hold"))
        let one = try await demo.refreshPassCode(for: aarav, meal: DemoSeed.lunch.id)
        let two = try await demo.refreshPassCode(for: aarav, meal: DemoSeed.lunch.id)
        XCTAssertNotEqual(one.code, two.code)
        XCTAssertNotEqual(one.colourName, two.colourName)
        XCTAssertEqual(two.changesAt.timeIntervalSince(DemoSeed.storyStartNow), DemoSeed.passCodeWindow)
    }

    func testThePassIsUsedOnceTheDeskRecordsIt() async throws {
        let (demo, _) = make()
        _ = try await demo.startPass(of: aarav, key: IdempotencyKey("hold"))
        demo.clock.set(DemoSeed.lunch.startsAt)  // The clock no longer jumps; move it as the story does.

        _ = try await demo.startMeal(DemoSeed.lunch.id, by: .supervisor)
        guard case .valid(_, let live) = try await demo.lookUpPass(lastFour: "0238", for: DemoSeed.lunch.id) else {
            return XCTFail("The desk sees a valid pass")
        }
        _ = try await demo.recordPassEntry(SpecialPassEntryRequest(mealID: DemoSeed.lunch.id, student: DemoSeed.sampleStudent,
                                                                   comparedCode: live.code, recordedBy: .passDesk,
                                                                   idempotencyKey: IdempotencyKey("desk")))
        guard case .used(_, let at, let wasShowing) = try await demo.passStanding(of: aarav, at: mess) else { return XCTFail("Used") }
        XCTAssertEqual(at, DemoSeed.lunch.startsAt)
        XCTAssertTrue(wasShowing)
        do {
            _ = try await demo.startPass(of: aarav, key: IdempotencyKey("hold-again"))
            XCTFail("A used pass cannot be held again")
        } catch RepositoryError.notAllowed {}
    }

    func testAPassUsedWithoutTheAppSaysSoAndAnUnusedOneExpiresWithTheMeal() async throws {
        let (demo, _) = make()
        demo.clock.set(DemoSeed.lunch.startsAt)  // The clock no longer jumps; move it as the story does.

        _ = try await demo.startMeal(DemoSeed.lunch.id, by: .supervisor)
        demo.clock.set(DemoSeed.lunch.endsAt)  // The clock no longer jumps; move it as the story does.

        _ = try await demo.closeMeal(DemoSeed.lunch.id, by: .supervisor)
        guard case .expired(_, let endedAt) = try await demo.passStanding(of: aarav, at: mess) else { return XCTFail("Expired") }
        XCTAssertEqual(endedAt, DemoSeed.lunch.endsAt)

        let (desk, _) = make()
        desk.clock.set(DemoSeed.lunch.startsAt)  // The clock no longer jumps; move it as the story does.

        _ = try await desk.startMeal(DemoSeed.lunch.id, by: .supervisor)
        guard case .valid(_, let live) = try await desk.lookUpPass(lastFour: "0238", for: DemoSeed.lunch.id) else { return XCTFail("Valid") }
        _ = try await desk.recordPassEntry(SpecialPassEntryRequest(mealID: DemoSeed.lunch.id, student: DemoSeed.sampleStudent,
                                                                   comparedCode: live.code, recordedBy: .passDesk,
                                                                   idempotencyKey: IdempotencyKey("desk")))
        guard case .used(_, _, let wasShowing) = try await desk.passStanding(of: aarav, at: mess) else { return XCTFail("Used") }
        XCTAssertFalse(wasShowing)
    }

    func testNoPassAndAnotherMess() async throws {
        let (demo, _) = make()
        let meera = try await demo.passStanding(of: StudentID("demo-student-0412"), at: mess)
        XCTAssertEqual(meera, .notEligible)
        let elsewhere = try await demo.passStanding(of: aarav, at: MessID("another-mess"))
        XCTAssertEqual(elsewhere, .wrongMess(passMess: "Main Mess, Block A"))
    }

    func testAnOfflinePassNeitherLoadsNorStarts() async throws {
        let (demo, _) = make(.offline)
        do {
            _ = try await demo.startPass(of: aarav, key: IdempotencyKey("hold"))
            XCTFail("Offline must throw")
        } catch RepositoryError.offline {}
    }

    // MARK: Crowd

    func testTheCrowdIsTheHomeEstimateWithTheDrawnPattern() async throws {
        let (demo, _) = make()
        let crowd = try await demo.crowd(at: mess)
        let home = try await demo.homeExtras(for: aarav, mess: mess).crowd
        XCTAssertEqual(crowd.level, home?.level)
        XCTAssertEqual(crowd.detailTime, home?.detailTime)
        XCTAssertEqual(crowd.level, .quiet)
        XCTAssertEqual(crowd.slots.count, 8)
        XCTAssertEqual(crowd.slots.map(\.activity).max(), 1)
        XCTAssertEqual(crowd.slots.first?.startsAt, DemoSeed.lunch.startsAt)
        XCTAssertEqual(crowd.slots.last?.startsAt, DemoSeed.time(13, 45))
        XCTAssertNil(crowd.currentSlot, "Before lunch the clock is in no slot.")
        XCTAssertNil(crowd.waitNowMinutes, "No wait is claimed while the mess is not serving.")
        XCTAssertEqual(crowd.bestSlot, 6)
        XCTAssertEqual(crowd.busiestWaitMinutes, 18)
        XCTAssertEqual(crowd.busiestAt, DemoSeed.time(12, 45))
    }

    func testDuringLunchTheCrowdIsBusyInTheCurrentSlot() async throws {
        let (demo, clock) = make()
        _ = try await demo.startMeal(DemoSeed.lunch.id, by: .supervisor)
        clock.set(DemoSeed.time(12, 40))
        let crowd = try await demo.crowd(at: mess)
        XCTAssertEqual(crowd.level, .busy)
        XCTAssertEqual(crowd.currentSlot, 2)
        XCTAssertEqual(crowd.waitNowMinutes, 2)
        XCTAssertEqual(crowd.observedAt, DemoSeed.time(12, 40))
    }

    func testTheCrowdIsClosedBeforeTheDoorsOpen() async throws {
        let (demo, clock) = make()
        clock.set(DemoSeed.time(6, 30))
        let crowd = try await demo.crowd(at: mess)
        XCTAssertEqual(crowd.level, .closed)
        XCTAssertEqual(crowd.detailTime, DemoSeed.breakfast.startsAt)
    }
}
#endif
