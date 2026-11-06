import Foundation
import Observation

/// Staff sign in. The disabled, loading and error states of the form all live here.
@MainActor
@Observable
final class StaffSignInViewModel {
    var email = ""
    var password = ""
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?
    private(set) var showsForgotPasswordMessage = false
    private let auth: any AuthRepository

    init(auth: any AuthRepository) {
        self.auth = auth
    }

    var canSubmit: Bool {
        !isSubmitting && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }

    func showForgotPasswordMessage() {
        showsForgotPasswordMessage = true
    }

    /// Returns the session when the sign-in is accepted. A second tap during a request does nothing.
    func submit() async -> Session? {
        guard canSubmit else { return nil }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            return try await auth.signInStaff(email: email, password: password)
        } catch RepositoryError.invalidCredentials {
            errorMessage = EntryCopy.wrongCredentials
        } catch {
            errorMessage = LoadFailure(error).message
        }
        return nil
    }
}

/// Sign in with SRM. UNVERIFIED AND SIMULATED: see `AuthRepository.signInWithSRM`.
/// The two pauses only pace the simulated steps; a real integration would replace them.
@MainActor
@Observable
final class SRMSignInViewModel {
    enum Phase: Equatable {
        case connecting
        case gettingDetails
        case failed(String)
    }

    private(set) var phase: Phase = .connecting
    private let auth: any AuthRepository
    private let pause: @Sendable () async -> Void

    init(auth: any AuthRepository,
         pause: @escaping @Sendable () async -> Void = { try? await Task.sleep(for: .seconds(1)) }) {
        self.auth = auth
        self.pause = pause
    }

    /// Runs the steps and returns the session. A failure stays on screen and is never shown as signed in.
    func start() async -> Session? {
        phase = .connecting
        await pause()
        phase = .gettingDetails
        await pause()
        do {
            return try await auth.signInWithSRM()
        } catch {
            phase = .failed(LoadFailure(error).message)
            return nil
        }
    }
}
