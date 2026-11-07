#if DEMO_DATA || REVIEW_DATA
import Foundation

extension DemoDataProvider: StaffDirectoryRepository {
    func studentName(_ student: StudentID) async throws -> String? {
        DemoSeed.sampleStudents.first { $0.ref.id == student }?.name
    }

    func shiftStartedAt(for role: Role, mess: MessID) async throws -> Date? {
        switch role {
        case .doorScanner, .passDesk: return DemoSeed.deskShiftStartedAt
        default: return nil
        }
    }
}
#endif
