import SwiftUI

/// Everything before sign-in: Welcome, with Staff sign in and Sign in with SRM pushed on top.
struct EntryFlowView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.entryPath) {
            WelcomeView(model: WelcomeViewModel(auth: environment.repositories.auth))
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

/// 01_sign_in, plus the Staff sign in action and the recent accounts.
struct WelcomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    @State private var model: WelcomeViewModel

    init(model: WelcomeViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        ZStack {
            OrbitBackground()
            VStack(spacing: MLSpacing.s16) {
                Spacer(minLength: MLSpacing.s32)
                brand
                Spacer(minLength: MLSpacing.s16)
                if !sessionStore.recentAccounts.isEmpty {
                    recentAccounts
                }
                if let message = model.errorMessage {
                    InlineErrorText(message: message)
                }
                InkActionButton(title: EntryCopy.signInWithSRM) {
                    router.entryPath.append(.srmSignIn)
                }
                OutlineActionButton(title: EntryCopy.staffSignIn) {
                    router.entryPath.append(.staffSignIn)
                }
                Text(EntryCopy.terms)
                    .font(MLType.meta)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.bottom, MLSpacing.s16)
        }
    }

    private var brand: some View {
        VStack(spacing: MLSpacing.s12) {
            OrbitMarkView(size: 54)
            Text(EntryCopy.wordmark)
                .font(MLType.wordmark)
                .foregroundStyle(MLColor.ink)
            Text(EntryCopy.tagline)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var recentAccounts: some View {
        ScrollView {
            VStack(spacing: 0) {
                Rectangle().fill(MLColor.border).frame(height: 1)
                ForEach(sessionStore.recentAccounts) { recent in
                    QuietRow(title: EntryCopy.continueAs(name: recent.displayName, role: MLFormat.roleName(recent.role))) {
                        Task {
                            if let session = await model.resume(recent) {
                                router.reset()
                                sessionStore.signIn(session)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: MLSize.staffButton * 3.5)
        .scrollBounceBehavior(.basedOnSize)
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
