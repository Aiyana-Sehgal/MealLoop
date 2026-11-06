import Foundation

/// Interface copy for Welcome, Staff sign in and Sign in with SRM. This is wording, not data.
/// Welcome and "Getting your details" come from design/reference/redesign_2026-10/images/01 and 02.
enum EntryCopy {
    static let wordmark = "MealLoop"
    static let tagline = "Hostel meals, without the waste."
    static let signInWithSRM = "Sign in with SRM"
    static let staffSignIn = "Staff sign in"
    static let terms = "By continuing you agree to the Terms and Privacy Policy."

    static func continueAs(name: String, role: String) -> String {
        "Continue as \(name), \(role)"
    }

    static let staffSubtitle = "Use your MealLoop account."
    static let emailLabel = "Email"
    static let passwordLabel = "Password"
    static let showPassword = "Show password"
    static let hidePassword = "Hide password"
    static let forgotPassword = "Forgot password?"
    /// Placeholder until the owner confirms the reset path. No reset flow exists.
    static let forgotPasswordMessage = "Password reset isn't available yet. Ask your administrator."
    static let signIn = "Sign in"
    static let accountsNote = "Accounts are created by your administrator."
    static let wrongCredentials = "The email or password is incorrect."

    static let connecting = "Connecting to SRM"
    static let gettingDetails = "Getting your details"
    static let fewSeconds = "This takes a few seconds."
    static let tryAgain = "Try again"
}
