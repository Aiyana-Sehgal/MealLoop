#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

/// The additive Student outing operations on the in-memory outing story, and the two Student records additions
/// (fix check, data requests).
final class StudentOutingRepositoryTests: XCTestCase {
    private let aarav = DemoSeed.sampleStudent.id
    private let stranger = StudentID("demo-student-unknown")

    private func draft(_ day: Int, leave: Int = 14, back: Int = 20, place: String = "Express Avenue Mall",
                       key: String = UUID().uuidString) -> StudentOutingDraft {
        StudentOutingDraft(leaveAt: OutingSeed.at(8, day, leave, 0), returnBy: OutingSeed.at(8, day, back, 0), place: place,
                           reason: "Family", idempotencyKey: IdempotencyKey(key))
    }

    func testTheSampleStudentSeesTheSeededRequestAndTheEarlierOnes() async throws {
        let repo = InMemoryOutingCaseRepository()
        let outings = try await repo.outings(for: aarav)
        XCTAssertEqual(outings.eligibility, .enabled)
        XCTAssertEqual(outings.current.map(\.id), [OutingSeed.aaravRequest.id])
        XCTAssertEqual(outings.current.first?.stage, .awaitingGuardian)
        XCTAssertEqual(outings.earlier.count, 4)
    }

    func testAStudentWithoutOutingsKeepsTheHostelProcess() async throws {
        let outings = try await InMemoryOutingCaseRepository().outings(for: stranger)
        XCTAssertEqual(outings.eligibility, .notEnabled)
        XCTAssertTrue(outings.current.isEmpty)
    }

    func testANewRequestEntersAtWaitingForGuardianAndTheGuardianSeesIt() async throws {
        let repo = InMemoryOutingCaseRepository()
        let made = try await repo.requestOuting(draft(18), by: aarav)
        XCTAssertEqual(made.stage, .awaitingGuardian)
        XCTAssertNil(made.guardianAnswer)
        XCTAssertNil(made.pass, "No pass exists before the warden approves.")
        XCTAssertNil(made.guardianReplyBy, "No deadline is invented.")
        let guardianSees = try await repo.guardianRequest(for: OutingSeed.guardianAccount)
        XCTAssertEqual(guardianSees?.id, made.id)
    }

    func testTheSameKeyReturnsTheFirstRequest() async throws {
        let repo = InMemoryOutingCaseRepository()
        let first = try await repo.requestOuting(draft(18, key: "k1"), by: aarav)
        let again = try await repo.requestOuting(draft(18, key: "k1"), by: aarav)
        XCTAssertEqual(first.id, again.id)
        let outings = try await repo.outings(for: aarav)
        XCTAssertEqual(outings.current.count, 2)
    }

    func testASecondOpenRequestForTheSameDayIsRefused() async {
        let repo = InMemoryOutingCaseRepository()
        do {
            _ = try await repo.requestOuting(draft(17), by: aarav)
            XCTFail("Saturday already has an open request.")
        } catch RepositoryError.notAllowed {} catch { XCTFail("\(error)") }
    }

    func testAPastTimeOrAnEmptyPlaceIsRefused() async {
        let repo = InMemoryOutingCaseRepository()
        do {
            _ = try await repo.requestOuting(draft(15), by: aarav)
            XCTFail("Thursday has passed on the outing clock.")
        } catch RepositoryError.validationFailed {} catch { XCTFail("\(error)") }
        do {
            _ = try await repo.requestOuting(draft(18, place: "  "), by: aarav)
            XCTFail("A place is needed.")
        } catch RepositoryError.validationFailed {} catch { XCTFail("\(error)") }
    }

    func testNoTimeoutApprovesARequest() async throws {
        let clock = DemoClock(OutingSeed.guardianMoment)
        let repo = InMemoryOutingCaseRepository(clock: clock)
        let made = try await repo.requestOuting(draft(18), by: aarav)
        clock.advance(to: OutingSeed.at(8, 25, 12, 0))
        let later = try await repo.outing(made.id, for: aarav)
        XCTAssertEqual(later.stage, .awaitingGuardian, "Time passing never moves a request forward.")
        let seeded = try await repo.outing(OutingSeed.aaravRequest.id, for: aarav)
        XCTAssertEqual(seeded.stage, .awaitingGuardian)
        XCTAssertNotNil(seeded.escalation(at: OutingSeed.at(8, 25, 12, 0)), "A missed deadline escalates to a person.")
    }

    func testCancellingWithdrawsBeforeExitOnly() async throws {
        let repo = InMemoryOutingCaseRepository()
        let made = try await repo.requestOuting(draft(18), by: aarav)
        let cancelled = try await repo.cancelOuting(made.id, by: aarav)
        XCTAssertEqual(cancelled.stage, .withdrawn)
        XCTAssertEqual(cancelled.withdrawnBy, .student)
        let outings = try await repo.outings(for: aarav)
        XCTAssertFalse(outings.current.contains { $0.id == made.id })
        do {
            _ = try await repo.cancelOuting(OutingSeed.meeraRequest.id, by: aarav)
            XCTFail("Another student's request is not found.")
        } catch RepositoryError.notFound {} catch { XCTFail("\(error)") }
    }

    func testOfflineNeverRecordsARequest() async throws {
        let repo = InMemoryOutingCaseRepository()
        await repo.setOffline(true)
        do {
            _ = try await repo.requestOuting(draft(18), by: aarav)
            XCTFail("Offline must throw.")
        } catch RepositoryError.offline {}
        await repo.setOffline(false)
        let outings = try await repo.outings(for: aarav)
        XCTAssertEqual(outings.current.count, 1)
    }

    // MARK: Student records additions (rulings on P-FINAL2-7 and P-FINAL2-9)

    func testAFixCheckIsRecordedOnceAndNeverChangesTheStage() async throws {
        let records = DemoDataProvider(scenario: .storyStart).makeRepositories().studentRecords
        let fixed = StudentFiledReportID("demo-report-0998")
        let first = try await records.answerFixCheck(fixed, .stillBad, by: aarav)
        XCTAssertEqual(first.fixCheck, .stillBad)
        XCTAssertEqual(first.stage, .fixed)
        let again = try await records.answerFixCheck(fixed, .better, by: aarav)
        XCTAssertEqual(again.fixCheck, .stillBad)
        do {
            _ = try await records.answerFixCheck(StudentFiledReportID("demo-report-1031"), .better, by: aarav)
            XCTFail("Not fixed yet.")
        } catch {}
    }

    func testADataRequestIsRecordedOnce() async throws {
        let records = DemoDataProvider(scenario: .storyStart).makeRepositories().studentRecords
        let first = try await records.recordDataRequest(.copy, by: aarav)
        let again = try await records.recordDataRequest(.copy, by: aarav)
        XCTAssertEqual(first, again)
        let list = try await records.dataRequests(for: aarav)
        XCTAssertEqual(list.map(\.kind), [.copy])
    }
}
#endif
