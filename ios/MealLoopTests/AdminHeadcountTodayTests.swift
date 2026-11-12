#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The Admin pack of 12 Nov 2026: Today as the headcount page for both roles, the Super Admin's mess switcher, and the
/// Food Head's own-mess Students, Results and More. Checked against the prototype backend through the scoped data layer.
@MainActor
final class AdminHeadcountTodayTests: XCTestCase {
    private func session(_ role: Role) throws -> Session {
        Session(account: try XCTUnwrap(DemoSeed.accounts.first { $0.role == role }), staff: nil)
    }

    private func scoped(_ role: Role, _ demo: DemoDataProvider = DemoDataProvider()) throws -> Repositories {
        demo.makeRepositories().scopedAdmin(try session(role), mess: DemoSeed.mess)
    }

    private func today(_ role: Role) async throws -> (AdminTodayViewModel, AdminContext) {
        // The scenario the app launches with: Wed 14 Aug, before lunch.
        let demo = DemoDataProvider(scenario: .storyStart)
        let context = try XCTUnwrap(AdminContext(session: try session(role)))
        let model = AdminTodayViewModel(context: context, repositories: try scoped(role, demo), clock: demo.clock)
        await model.load()
        return (model, context)
    }

    // MARK: Today

    func testFoodHeadTodayLeadsWithApproveAndHoldsNoOtherMess() async throws {
        let (model, context) = try await today(.admin)
        let content = try XCTUnwrap(model.state.value)
        let meal = try XCTUnwrap(content.meal)
        XCTAssertNil(content.otherMesses)
        let snapshot = AdminHeadcountSnapshot.own(content, meal, context: context)
        XCTAssertEqual(snapshot.mess, "Main")
        XCTAssertEqual(snapshot.stepIndex, 1)
        guard case .approve = snapshot.next else { return XCTFail("\(snapshot.next)") }
        XCTAssertNil(snapshot.approvedCount)
        XCTAssertFalse(snapshot.isApproved)
        XCTAssertNil(snapshot.actualEntries, "Entries are missing before the meal, never zero")
        XCTAssertNil(snapshot.finalEntries)
        XCTAssertEqual(snapshot.mealID, DemoSeed.lunch.id)
    }

    func testApprovingMovesTheTilesAndNamesTheApprover() async throws {
        let (model, context) = try await today(.admin)
        let approved = await model.approve()
        XCTAssertTrue(approved)
        let content = try XCTUnwrap(model.state.value)
        let snapshot = AdminHeadcountSnapshot.own(content, try XCTUnwrap(content.meal), context: context)
        XCTAssertTrue(snapshot.isApproved)
        guard case .send = snapshot.next else { return XCTFail("\(snapshot.next)") }
        XCTAssertEqual(snapshot.stepIndex, 2)
        XCTAssertTrue(snapshot.approvedLine?.hasPrefix("By \(context.account.firstName) · ") ?? false)
        XCTAssertNil(snapshot.sentCount, "Approved is not sent")
        XCTAssertEqual(snapshot.track.map(\.isDone), [true, false, false])
        XCTAssertFalse(snapshot.hasChanges)
    }

    func testSuperAdminSwitcherReadsNorthFromItsRecordOnly() async throws {
        let (model, context) = try await today(.superAdmin)
        let content = try XCTUnwrap(model.state.value)
        let north = try XCTUnwrap(content.otherMesses?.messes.first { $0.id == "North" })
        let snapshot = AdminHeadcountSnapshot.other(north, content: content, context: context)
        XCTAssertEqual(snapshot.next, .send(700))
        XCTAssertEqual(snapshot.stepIndex, 2)
        XCTAssertEqual(snapshot.approvedCount, 700)
        XCTAssertEqual(snapshot.cutoffForecast, 700)
        XCTAssertEqual(snapshot.answered, 588)
        XCTAssertNil(snapshot.notYet, "North's not-yet count is not held")
        XCTAssertTrue(snapshot.subtitle.hasPrefix("Approved by Food Head · "))
        XCTAssertNil(snapshot.actualEntries)
        XCTAssertNil(snapshot.mealID, "Another mess has no meal report here")

        let annexe = try XCTUnwrap(content.otherMesses?.messes.first { $0.id == "Annexe" })
        let empty = AdminHeadcountSnapshot.other(annexe, content: content, context: context)
        XCTAssertEqual(empty.next, .none)
        XCTAssertNil(empty.liveForecast)
        XCTAssertNil(empty.approvedCount)
        XCTAssertEqual(empty.stepIndex, 0)
    }

    func testSouthHasNotRepliedIsANeedsYouRowForTheSuperAdminOnly() async throws {
        let (superAdmin, _) = try await today(.superAdmin)
        let rows = try XCTUnwrap(superAdmin.state.value).needsYouItems
        XCTAssertTrue(rows.contains { if case .noReply(let mess) = $0 { mess.id == "South" } else { false } })

        let (foodHead, _) = try await today(.admin)
        XCTAssertFalse(try XCTUnwrap(foodHead.state.value).needsYouItems.contains { if case .noReply = $0 { true } else { false } })
    }

    // MARK: Students

    func testFoodHeadStudentsHoldMainsRollButNotItsSplit() async throws {
        let source = try XCTUnwrap(try scoped(.admin).adminStudents as? any SingleMessStudentsRepository)
        let main = try await source.singleMessStudents()
        XCTAssertEqual(main.mess, "Main")
        XCTAssertEqual(main.students, 860)
        XCTAssertEqual(main.notAnswered, 210)
        XCTAssertEqual(main.answered, 650)
        XCTAssertTrue(main.feedback.allSatisfy { $0.mess == "Main" })
    }

    func testFoodHeadRemindsTheirMessOnceAndTheSuperAdminSeesEveryMess() async throws {
        let demo = DemoDataProvider()
        let source = try XCTUnwrap(try scoped(.admin, demo).adminStudents as? any SingleMessStudentsRepository)
        let key = IdempotencyKey.make()
        let first = try await source.remindMess(key: key, by: .admin)
        let sentAt = try XCTUnwrap(first.reminderSentAt)
        let again = try await source.remindMess(key: key, by: .admin)
        XCTAssertEqual(again.reminderSentAt, sentAt)

        let all = try await scoped(.superAdmin, demo).adminStudents.studentsOverview()
        XCTAssertNil(all.reminderSentAt, "Main's reminder is not every mess's")
        let rolls = try XCTUnwrap(all.byMess)
        XCTAssertEqual(rolls.map(\.mess), ["Main", "North", "South", "Annexe"])
        XCTAssertEqual(rolls.compactMap(\.notAnswered).reduce(0, +), all.notAnswered)
        XCTAssertEqual(rolls.compactMap(\.students), [860], "Only Main's size is held")
    }

    // MARK: Results and More

    func testFoodHeadResultsAreMainsOwnSummary() async throws {
        let overview = try await scoped(.admin).adminResults.overview()
        XCTAssertEqual(overview.periodTitle, "Last 4 weeks · Main")
        XCTAssertEqual(overview.leftOver.meals, 3)
        XCTAssertEqual(overview.leftOver.totalMeals, 14)
        XCTAssertEqual(overview.ranOut.meals, 1)
        XCTAssertTrue(overview.toReview.allSatisfy { $0.meal.mess.replacingOccurrences(of: " Mess", with: "") == "Main" })
        XCTAssertTrue(overview.changes.allSatisfy { $0.mess == "Main" })
        do {
            _ = try await scoped(.admin).adminResults.reason(.fewerCame)
            XCTFail("Reason pages hold every mess's meals")
        } catch {}
    }

    func testFoodHeadMoreShowsOnlyRowsWithFiguresForTheirMess() async throws {
        let values = try await AdminHubValues.load(try scoped(.admin).adminMore, allMesses: false)
        XCTAssertEqual(values.menuStatus, "Published")
        XCTAssertEqual(values.passUsed, 196)
        XCTAssertEqual(values.passTotal, 214)
        XCTAssertNil(values.outNow)
        XCTAssertNil(values.openVotes)
        XCTAssertNil(values.liveRewards)
        XCTAssertNil(values.invited, "People and access stays the Super Admin's")

        let all = try await AdminHubValues.load(try scoped(.superAdmin).adminMore, allMesses: true)
        XCTAssertNotNil(all.outNow)
        XCTAssertNotNil(all.invited)
    }
}
#endif
