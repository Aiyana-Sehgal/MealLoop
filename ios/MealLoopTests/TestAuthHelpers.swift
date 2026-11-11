#if DEMO_DATA || REVIEW_DATA
import XCTest
@testable import MealLoop

extension AuthRepository {
    /// Welcome's Sign in with SRM, which signs in the seeded student.
    func srmStudentSession() async throws -> Session {
        try await signInWithSRM()
    }
}
#endif
