#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

private final class ExtrasClock: StoryClock, @unchecked Sendable {
    private var current = Date(timeIntervalSince1970: 0)
    func now() -> Date { current }
    func set(_ date: Date) { current = date }
}

/// The additive Student operations on the prototype backend.
final class StudentExtrasRepositoryTests: XCTestCase {
    private let aarav = DemoSeed.sampleStudent.id
    private let mess = DemoSeed.mess.id
    private let lunch = DemoSeed.lunch.id

    private func make() -> (DemoDataProvider, ExtrasClock) {
        let clock = ExtrasClock()
        return (DemoDataProvider(scenario: .storyStart, clock: clock), clock)
    }

    private func entry(_ key: String) -> EntryRequest {
        EntryRequest(mealID: lunch, student: DemoSeed.sampleStudent, method: .typedLastFour, idempotencyKey: IdempotencyKey(key))
    }

    // MARK: Home extras

    func testTheSamplesAreTheOnesDrawnOnHome() async throws {
        let (demo, _) = make()
        let extras = try await demo.homeExtras(for: aarav, mess: mess)
        XCTAssertEqual(extras.credits, 120)
        XCTAssertEqual(extras.crowd?.level, .quiet)
        XCTAssertEqual(extras.crowd?.bars, [22, 38, 46, 46, 34, 17, 17])
        XCTAssertEqual(extras.crowd?.currentBar, 0)
        XCTAssertEqual(extras.crowd?.detailTime, DemoSeed.time(13, 30))
        XCTAssertEqual(extras.pass, StudentPassRow(meal: DemoSeed.lunch, status: .open))
        XCTAssertFalse(extras.isMessClosed)
        XCTAssertEqual(extras.laterMeal, DemoSeed.dinner)
    }

    func testTheCrowdIsBusyDuringServiceAndClosedBeforeTheDoorsOpen() async throws {
        let (demo, clock) = make()
        clock.set(DemoSeed.time(8, 10))
        var extras = try await demo.homeExtras(for: aarav, mess: mess)
        XCTAssertEqual(extras.crowd?.level, .busy)
        XCTAssertEqual(extras.crowd?.currentBar, 2)
        XCTAssertEqual(extras.crowd?.detailTime, DemoSeed.time(8, 45))

        clock.set(DemoSeed.time(6, 30))
        extras = try await demo.homeExtras(for: aarav, mess: mess)
        XCTAssertTrue(extras.isMessClosed)
        XCTAssertEqual(extras.crowd?.level, .closed)
        XCTAssertNil(extras.crowd?.currentBar)
        XCTAssertEqual(extras.crowd?.detailTime, DemoSeed.breakfast.startsAt)
    }

    func testAStudentWithNoPassHasNoRow() async throws {
        let (demo, _) = make()
        let extras = try await demo.homeExtras(for: StudentID("demo-student-0412"), mess: mess)
        XCTAssertNil(extras.pass)
    }

    func testThePassRowClosesWithItsMeal() async throws {
        let (demo, _) = make()
        _ = try await demo.startMeal(lunch, by: .supervisor)
        _ = try await demo.closeMeal(lunch, by: .supervisor)
        let extras = try await demo.homeExtras(for: aarav, mess: mess)
        XCTAssertEqual(extras.pass?.status, .closed)
    }

    func testExtrasAreNotServedOffline() async throws {
        let demo = DemoDataProvider(scenario: .offline)
        do {
            _ = try await demo.homeExtras(for: aarav, mess: mess)
            XCTFail("Expected offline")
        } catch RepositoryError.offline {}
    }

    // MARK: Menus and dinner

    func testTheStudentMenusAreTheDrawnOnes() async throws {
        let (demo, _) = make()
        let breakfast = try await demo.studentMenu(for: DemoSeed.breakfast.id)
        let lunchMenu = try await demo.studentMenu(for: lunch)
        let dinner = try await demo.studentMenu(for: DemoSeed.dinner.id)
        XCTAssertEqual(breakfast.map(\.name), ["Millet Idli", "Pongal"])
        XCTAssertEqual(lunchMenu.map(\.name), ["Bhindi Aloo Bujjiya", "Chappathi", "Veg Pulao", "Muttar Masala"])
        XCTAssertEqual(dinner.count, 5)
        XCTAssertEqual(dinner.first { $0.diet == .nonVeg }?.name, "Butter Chicken Masala")
    }

    func testTheKitchenMenuIsUnchanged() async throws {
        let (demo, _) = make()
        let menu = try await demo.menu(for: lunch)
        let breakfast = try await demo.menu(for: DemoSeed.breakfast.id)
        XCTAssertEqual(menu, DemoSeed.lunchMenu)
        XCTAssertEqual(breakfast, [])
    }

    func testDinnerTakesAnAnswerUntilItsOwnCutoff() async throws {
        let (demo, clock) = make()
        clock.set(DemoSeed.storyStartNow)
        _ = try await demo.setIntention(.attending, of: aarav, for: DemoSeed.dinner.id)
        let stored = try await demo.response(of: aarav, for: DemoSeed.dinner.id)
        guard case .answered(.attending, _) = stored else { return XCTFail("Expected the answer") }

        clock.set(IntentionPolicy.cutoff(for: DemoSeed.dinner).addingTimeInterval(1))
        do {
            _ = try await demo.setIntention(.skipping, of: aarav, for: DemoSeed.dinner.id)
            XCTFail("Expected the cutoff to refuse it")
        } catch RepositoryError.notAllowed {}
    }

    func testDinnerIsNotAStaffRunMeal() async throws {
        let (demo, _) = make()
        let meals = try await demo.meals(for: mess)
        XCTAssertEqual(meals.map(\.meal.slot), [.breakfast, .lunch])
    }

    // MARK: Skip reasons

    func testAReasonIsKeptForASkip() async throws {
        let (demo, _) = make()
        _ = try await demo.setIntention(.skipping, of: aarav, for: lunch)
        try await demo.setSkipReason(.eatingElsewhere, of: aarav, for: lunch)
        let reason = try await demo.skipReason(of: aarav, for: lunch)
        XCTAssertEqual(reason, .eatingElsewhere)
    }

    func testAReasonIsRefusedWithoutASkip() async throws {
        let (demo, _) = make()
        _ = try await demo.setIntention(.attending, of: aarav, for: lunch)
        do {
            try await demo.setSkipReason(.notHungry, of: aarav, for: lunch)
            XCTFail("Expected a refusal")
        } catch RepositoryError.notAllowed {}
    }

    func testTheReasonListEqualsTheAdminList() {
        XCTAssertEqual(MealSkipReason.allCases.map(StudentCopy.reason),
                       ["Class or exam", "Home or leave", "Eating elsewhere", "Don't like the dish", "Dietary reason",
                        "Not hungry", "Other", "Prefer not to say"])
    }

    // MARK: Entry standing and the rotating code

    func testStandingFollowsTheDoor() async throws {
        let (demo, clock) = make()
        var standing = try await demo.entryStanding(of: aarav, for: lunch, at: mess)
        XCTAssertEqual(standing, .notScanned)

        _ = try await demo.startMeal(lunch, by: .supervisor)
        let at = clock.now()
        _ = try await demo.recordEntry(entry("first"))
        standing = try await demo.entryStanding(of: aarav, for: lunch, at: mess)
        XCTAssertEqual(standing, .scanned(at: at))

        _ = try await demo.recordEntry(entry("second"))
        standing = try await demo.entryStanding(of: aarav, for: lunch, at: mess)
        XCTAssertEqual(standing, .scannedAgain(firstAt: at))
    }

    func testARepeatOfTheSameRequestIsNotASecondScan() async throws {
        let (demo, clock) = make()
        _ = try await demo.startMeal(lunch, by: .supervisor)
        let at = clock.now()
        _ = try await demo.recordEntry(entry("same"))
        _ = try await demo.recordEntry(entry("same"))
        let standing = try await demo.entryStanding(of: aarav, for: lunch, at: mess)
        XCTAssertEqual(standing, .scanned(at: at))
    }

    func testARepeatScanAddsNothingToTheCount() async throws {
        let (demo, _) = make()
        _ = try await demo.startMeal(lunch, by: .supervisor)
        _ = try await demo.recordEntry(entry("first"))
        _ = try await demo.recordEntry(entry("second"))
        let count = try await demo.liveCount(for: lunch)
        XCTAssertEqual(count.value, 1)
    }

    func testAnotherMessIsTheWrongMess() async throws {
        let (demo, _) = make()
        let standing = try await demo.entryStanding(of: aarav, for: lunch, at: MessID("another-mess"))
        XCTAssertEqual(standing, .wrongMess(homeMess: "Main Mess"))
    }

    func testEachWindowHasItsOwnPayloadAndTheSameLastFour() async throws {
        let (demo, _) = make()
        let first = try await demo.rotatingEntryCode(for: aarav, step: 0)
        let second = try await demo.rotatingEntryCode(for: aarav, step: 1)
        let again = try await demo.rotatingEntryCode(for: aarav, step: 0)
        XCTAssertNotEqual(first.payload, second.payload)
        XCTAssertEqual(first, again)
        XCTAssertEqual(first.lastFour, "0238")
        XCTAssertEqual(second.lastFour, "0238")
    }

    func testTheRotatingCodeWorksOffline() async throws {
        let demo = DemoDataProvider(scenario: .offline)
        let code = try await demo.rotatingEntryCode(for: aarav, step: 3)
        XCTAssertEqual(code.step, 3)
    }

    func testTheTypedLastFourStillResolvesToTheStudent() async throws {
        let (demo, _) = make()
        _ = try await demo.startMeal(lunch, by: .supervisor)
        _ = try await demo.rotatingEntryCode(for: aarav, step: 7)
        let result = try await demo.resolveEntry(.lastFour("0238"), for: lunch)
        XCTAssertEqual(result, .student(DemoSeed.sampleStudent))
    }

    // MARK: Corrections

    private func correction(_ key: String, note: String? = nil) throws -> EntryCorrectionRequest {
        EntryCorrectionRequest(student: aarav, mealID: DemoSeed.sampleCorrectableRecord.mealID, reason: .ateButNotScanned,
                               note: note, idempotencyKey: IdempotencyKey(key))
    }

    func testTheSameKeyKeepsTheFirstRequest() async throws {
        let (demo, clock) = make()
        let first = try await demo.requestEntryCorrection(try correction("k", note: "first"))
        clock.set(DemoSeed.time(8, 0))
        let second = try await demo.requestEntryCorrection(try correction("k", note: "second"))
        XCTAssertEqual(first, second)
    }

    func testAnOfflineCorrectionIsNotStored() async throws {
        let demo = DemoDataProvider(scenario: .offline)
        do {
            _ = try await demo.requestEntryCorrection(try correction("k"))
            XCTFail("Expected offline")
        } catch RepositoryError.offline {}
    }

    func testOnlyTheSampleStudentHasARecordToCorrect() async throws {
        let (demo, _) = make()
        let mine = try await demo.correctableRecord(for: aarav)
        let other = try await demo.correctableRecord(for: StudentID("demo-student-0412"))
        XCTAssertEqual(mine, DemoSeed.sampleCorrectableRecord)
        XCTAssertNil(other)
    }
}
#endif
