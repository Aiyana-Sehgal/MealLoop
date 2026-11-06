#if DEMO_DATA
import Foundation
import Observation

/// The shared role password (4 digits, 3 tries, then locked). The check goes through AuthRepository;
/// in Debug it is SIMULATED by the demo provider.
@MainActor
@Observable
final class RolePasswordViewModel {
    enum Phase: Equatable {
        case entering
        case checking
        case wrong(triesLeft: Int)
        case locked(resetBy: String?)
        case failed(LoadFailure)
    }

    let role: Role
    private(set) var digits: String = ""
    private(set) var phase: Phase = .entering
    private let auth: any AuthRepository

    init(role: Role, auth: any AuthRepository) {
        self.role = role
        self.auth = auth
    }

    var isKeypadEnabled: Bool {
        switch phase {
        case .checking, .locked: return false
        case .entering, .wrong, .failed: return true
        }
    }

    /// Adds a digit; on the 4th digit checks the password and returns the session when it is accepted.
    func append(_ digit: Int) async -> StaffSession? {
        guard isKeypadEnabled, digits.count < RolePasswordPolicy.digits, (0...9).contains(digit) else { return nil }
        if case .wrong = phase { phase = .entering }
        digits.append(String(digit))
        guard digits.count == RolePasswordPolicy.digits else { return nil }

        phase = .checking
        do {
            let result = try await auth.verifyRolePassword(digits, for: role)
            digits = ""
            switch result {
            case .granted(let session):
                phase = .entering
                return session
            case .wrong(let triesLeft):
                phase = .wrong(triesLeft: triesLeft)
            case .locked(let resetBy):
                phase = .locked(resetBy: resetBy)
            }
        } catch {
            digits = ""
            phase = .failed(LoadFailure(error))
        }
        return nil
    }

    func deleteLast() {
        guard isKeypadEnabled, !digits.isEmpty else { return }
        digits.removeLast()
    }
}
#endif
