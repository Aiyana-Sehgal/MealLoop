import SwiftUI

/// Everything before sign-in: Welcome, with Staff sign in and Sign in with SRM pushed on top.
struct EntryFlowView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.entryPath) {
            WelcomeView()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: EntryRoute.self) { route in
                    Group {
                        switch route {
                        case .staffSignIn:
                            StaffSignInView(model: StaffSignInViewModel(auth: environment.repositories.auth))
                        case .srmSignIn:
                            SRMSignInView(model: SRMSignInViewModel(auth: environment.repositories.auth))
                        }
                    }
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationBarBackButtonHidden(true)
                }
        }
    }
}

/// 01_sign_in, plus the Staff sign in action. The brand sits at the optical centre of the space above the buttons,
/// and the buttons and footnote stay together at the bottom. It scrolls only if larger text no longer fits.
struct WelcomeView: View {
    @Environment(AppRouter.self) private var router
    // Onboarding · Sign in (221:62499): wordmark 34 pt semibold, mark 44 pt.
    @ScaledMetric(relativeTo: .largeTitle) private var wordmarkSize: CGFloat = 34
    @ScaledMetric(relativeTo: .body) private var taglineSize: CGFloat = 17
    @ScaledMetric(relativeTo: .caption) private var termsSize: CGFloat = 12

    var body: some View {
        ZStack {
            OrbitBackground()
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: MLSpacing.s32)
                        brand
                            // Sits a little above true centre, where the eye reads it as centred.
                            .padding(.bottom, MLSpacing.s32)
                        Spacer(minLength: MLSpacing.s16)
                        actions
                    }
                    .frame(minHeight: proxy.size.height)
                    .padding(.horizontal, MLSpacing.margin)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private var brand: some View {
        VStack(spacing: MLSpacing.s12) {
            OrbitMarkView(size: 44)
            Text(EntryCopy.wordmark)
                .font(.system(size: wordmarkSize, weight: .semibold))
                .foregroundStyle(MLColor.ink)
                // A brand name never wraps; at the largest text sizes it shrinks to fit.
                .lineLimit(1)
                .minimumScaleFactor(0.4)
            Text(EntryCopy.tagline)
                .font(.system(size: taglineSize))
                .foregroundStyle(MLColor.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        VStack(spacing: MLSpacing.s12) {
            InkActionButton(title: EntryCopy.signInWithSRM) {
                router.entryPath.append(.srmSignIn)
            }
            OutlineActionButton(title: EntryCopy.staffSignIn) {
                router.entryPath.append(.staffSignIn)
            }
            VStack(spacing: 2) {
                Text(EntryCopy.termsLead)
                Text(EntryCopy.termsLink).underline()
            }
            .font(.system(size: termsSize, weight: .medium))
            .foregroundStyle(MLColor.inkSecondary)
            .multilineTextAlignment(.center)
            .padding(.top, MLSpacing.s4)
            .accessibilityElement(children: .combine)
        }
        .padding(.bottom, MLSpacing.s16)
    }
}

/// Staff sign in. No reference image exists; it follows the Orbit language and the entry brief.
struct StaffSignInView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    @State private var model: StaffSignInViewModel
    @State private var isPasswordVisible = false

    init(model: StaffSignInViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    BackButton { router.entryPath.removeLast() }
                    VStack(alignment: .leading, spacing: MLSpacing.s4) {
                        Text(EntryCopy.staffSignIn)
                            .font(MLType.largeTitle)
                            .foregroundStyle(MLColor.ink)
                        Text(EntryCopy.staffSubtitle)
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                    SignInField(label: EntryCopy.emailLabel) {
                        TextField(EntryCopy.emailLabel, text: $model.email, prompt: nil)
                            .keyboardType(.emailAddress)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    SignInField(label: EntryCopy.passwordLabel) {
                        HStack(spacing: MLSpacing.s8) {
                            Group {
                                if isPasswordVisible {
                                    TextField(EntryCopy.passwordLabel, text: $model.password, prompt: nil)
                                } else {
                                    SecureField(EntryCopy.passwordLabel, text: $model.password, prompt: nil)
                                }
                            }
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(MLColor.inkSecondary)
                                    .frame(width: MLSize.hit, height: MLSize.hit)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(isPasswordVisible ? EntryCopy.hidePassword : EntryCopy.showPassword)
                        }
                    }
                    forgotPassword
                    if let message = model.errorMessage {
                        InlineErrorText(message: message)
                    }
                    InkActionButton(title: EntryCopy.signIn, isLoading: model.isSubmitting) {
                        Task {
                            if let session = await model.submit() {
                                router.reset()
                                sessionStore.signIn(session)
                            }
                        }
                    }
                    .disabled(!model.canSubmit && !model.isSubmitting)
                    Text(EntryCopy.accountsNote)
                        .font(MLType.secondary)
                        .foregroundStyle(MLColor.inkSecondary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    @ViewBuilder
    private var forgotPassword: some View {
        Button {
            model.showForgotPasswordMessage()
        } label: {
            Text(EntryCopy.forgotPassword)
                .font(MLType.body)
                .underline()
                .foregroundStyle(MLColor.ink)
                .frame(minHeight: MLSize.hit)
        }
        .buttonStyle(.plain)
        if model.showsForgotPasswordMessage {
            Text(EntryCopy.forgotPasswordMessage)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
        }
    }
}

/// A labelled field on a white surface.
private struct SignInField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(label)
                .font(MLType.bodyEmphasis)
                .foregroundStyle(MLColor.ink)
                .accessibilityHidden(true)
            content
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.ink)
                .padding(.horizontal, MLSpacing.s16)
                .frame(minHeight: MLSize.button)
                .background(RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous).fill(MLColor.surface))
                .overlay(RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous).stroke(MLColor.border, lineWidth: 1))
        }
    }
}

/// An error under a form. It has an icon as well as colour, so it does not rely on colour alone.
private struct InlineErrorText: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle")
            .font(MLType.body)
            .foregroundStyle(MLColor.danger)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Sign in with SRM: a brief connecting step, then 02_getting_details, then the Student root.
struct SRMSignInView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    @State private var model: SRMSignInViewModel

    init(model: SRMSignInViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        ZStack {
            OrbitBackground()
            switch model.phase {
            case .connecting:
                progress(title: EntryCopy.connecting, detail: nil)
            case .gettingDetails:
                progress(title: EntryCopy.gettingDetails, detail: EntryCopy.fewSeconds)
            case .failed(let message):
                failure(message)
            }
        }
        .task { await run() }
    }

    private func run() async {
        if let session = await model.start() {
            router.reset()
            sessionStore.signIn(session)
        }
    }

    private func progress(title: String, detail: String?) -> some View {
        VStack(spacing: MLSpacing.s8) {
            ProgressRing()
                .padding(.bottom, MLSpacing.s16)
            Text(title)
                .font(MLType.largeTitle)
                .foregroundStyle(MLColor.ink)
                .multilineTextAlignment(.center)
            if let detail {
                Text(detail)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
        }
        .padding(.horizontal, MLSpacing.margin)
    }

    private func failure(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            BackButton { router.entryPath.removeLast() }
            Spacer()
            InlineErrorText(message: message)
            InkActionButton(title: EntryCopy.tryAgain) {
                Task { await run() }
            }
        }
        .padding(MLSpacing.margin)
    }
}
