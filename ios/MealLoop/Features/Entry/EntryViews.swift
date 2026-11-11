import SwiftUI

/// Everything before sign-in (see `EntryRoute` for both paths). Every screen is pushed on one stack, so the system
/// back button and swipe-back work, and a demo shortcut can open any step by setting the path.
struct EntryFlowView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.entryPath) {
            WelcomeView()
                .navigationDestination(for: EntryRoute.self) { route in
                    switch route {
                    case .chooseRole:
                        RoleSelectionView()
                    case .emailSignIn:
                        StaffSignInView(model: StaffSignInViewModel(auth: environment.repositories.auth))
                    case .srmSignIn:
                        SRMSignInView(model: SRMSignInViewModel(auth: environment.repositories.auth))
                            .toolbar(.hidden, for: .navigationBar)
                            .navigationBarBackButtonHidden(true)
                    case .rolePassword(let role):
                        RolePasswordScreen(role: role)
                    }
                }
        }
    }
}

/// Onboarding · Sign in (221:62499), plus the Staff sign in action that opens Choose your role. The brand sits in the middle
/// of the space above the actions, and the actions and the terms are pinned to the bottom safe area.
/// It scrolls at large text sizes.
struct WelcomeView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        WelcomeLayout {
            InkActionButton(title: EntryCopy.signInWithSRM) {
                router.entryPath.append(.srmSignIn)
            }
            OutlineActionButton(title: EntryCopy.staffSignIn) {
                router.entryPath.append(.chooseRole)
            }
        }
    }
}

/// The Welcome layout: the brand in the middle, then the actions and the terms. Onboarding · Sign in failed
/// (135:15825) is the same page with the error card above Try again.
struct WelcomeLayout<Actions: View>: View {
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        MLScreen(nil, showsNavigationBar: false, fillsViewport: true) {
            brand
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, MLSpacing.s32)
        } bottom: {
            actions()
            EntryTermsText()
        }
        .overlay(alignment: .top) { DemoEntryButton().padding(.top, MLSpacing.s4) }
    }

    private var brand: some View {
        VStack(spacing: MLSpacing.s12) {
            // OrbitMark 2144:56770 is 48 pt: the 40 pt icon square plus 8.
            OrbitMarkView(size: MLSize.iconSquare + MLSpacing.s8)
            Text(EntryCopy.wordmark)
                .mlFont(.largeTitle)
                .foregroundStyle(MLColor.ink)
                // A brand name never wraps; at the largest text sizes it shrinks to fit.
                .lineLimit(1)
                .minimumScaleFactor(0.4)
            Text(EntryCopy.tagline)
                .mlFont(.staffBody)
                .foregroundStyle(MLColor.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// "By continuing, you agree to the / Terms and Privacy Policy", drawn on two lines, the second underlined.
struct EntryTermsText: View {
    var body: some View {
        VStack(spacing: MLSpacing.s4) {
            Text(EntryCopy.termsLead)
            Text(EntryCopy.termsLink).underline()
        }
        .mlFont(.meta)
        .foregroundStyle(MLColor.inkSecondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

/// "Couldn't sign in. Try again" (135:15825): a tinted card with an icon, so it does not rely on colour alone.
struct SignInFailureCard: View {
    let message: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s12) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(MLColor.danger)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text(EntryCopy.couldntSignIn)
                    .mlFont(.bodyEmphasis)
                    .foregroundStyle(MLColor.ink)
                Text(message)
                    .mlFont(.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(MLSpacing.s16)
        .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.danger.opacity(0.09)))
        .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).stroke(MLColor.danger, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

/// Staff sign in, laid out as a standard iOS sign-in on the proportions of MS-0 (1508:45): the brand row at the top,
/// the title and the form in the upper middle with "Forgot password?" beside the password, and the Sign in button
/// with its helper line pinned to the bottom safe area, above the keyboard.
/// The email and password form for accounts that are not mess staff (Food Head, Super Admin, Vendor, Guardian,
/// Warden, Gate). It opens from "Sign in with email" on Choose your role; no frame draws it.
struct StaffSignInView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    @State private var model: StaffSignInViewModel
    @State private var isPasswordVisible = false
    @FocusState private var focus: Field?

    enum Field: Hashable {
        case email, password
    }

    init(model: StaffSignInViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        MLScreen(EntryCopy.staffSignIn, subtitle: EntryCopy.staffSubtitle, placement: .upperMiddle) {
            brandRow
        } trailing: {
            EmptyView()
        } content: {
            form
        } bottom: {
            InkActionButton(title: EntryCopy.signIn, isLoading: model.isSubmitting, action: submit)
                .disabled(!model.canSubmit && !model.isSubmitting)
            Text(EntryCopy.accountsNote)
                .mlFont(.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The App wordmark of MS-0 (1508:47): the mark and the name, 44 pt tall.
    private var brandRow: some View {
        HStack(spacing: MLSpacing.s8) {
            OrbitMarkView(size: MLSize.avatar)
            Text(EntryCopy.wordmark)
                .mlFont(.heroTitle)
                .foregroundStyle(MLColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .accessibilityElement(children: .combine)
    }

    private var form: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SignInField(label: EntryCopy.emailLabel) {
                TextField(EntryCopy.emailLabel, text: $model.email, prompt: nil)
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focus, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focus = .password }
            }
            .mlKeepsVisible(id: Field.email, when: focus == .email)
            SignInField(label: EntryCopy.passwordLabel) {
                forgotPasswordButton
            } field: {
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
                    .focused($focus, equals: .password)
                    .submitLabel(.go)
                    .onSubmit(submit)
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundStyle(MLColor.inkSecondary)
                            .frame(width: MLSize.hit, height: MLSize.hit)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isPasswordVisible ? EntryCopy.hidePassword : EntryCopy.showPassword)
                }
            }
            .mlKeepsVisible(id: Field.password, when: focus == .password)
            if model.showsForgotPasswordMessage {
                Text(EntryCopy.forgotPasswordMessage)
                    .mlFont(.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .mlTransition(.fromTop)
            }
            if let message = model.errorMessage {
                InlineErrorText(message: message)
                    .mlTransition(.fromTop)
            }
        }
        .mlAnimation(.snappy, value: model.errorMessage)
        .mlAnimation(.snappy, value: model.showsForgotPasswordMessage)
        .mlHaptic(.warning, trigger: model.errorMessage) { _, new in new != nil }
    }

    private var forgotPasswordButton: some View {
        Button {
            model.showForgotPasswordMessage()
        } label: {
            Text(EntryCopy.forgotPassword)
                .mlFont(.body)
                .underline()
                .foregroundStyle(MLColor.ink)
                .fixedSize()
                .frame(minHeight: MLSize.hit)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func submit() {
        guard model.canSubmit else { return }
        focus = nil
        Task {
            if let session = await model.submit() {
                router.reset()
                sessionStore.signIn(session)
            }
        }
    }
}

/// A labelled field on a white surface, with an optional control at the end of the label row.
private struct SignInField<Accessory: View, Field: View>: View {
    let label: String
    let accessory: Accessory
    let field: Field

    init(label: String, @ViewBuilder accessory: () -> Accessory, @ViewBuilder field: () -> Field) {
        self.label = label
        self.accessory = accessory()
        self.field = field()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            // Side by side while both fit on one line; at the largest text sizes the control drops under the label.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .lastTextBaseline, spacing: MLSpacing.s8) {
                    labelText
                        .frame(maxWidth: .infinity, alignment: .leading)
                    accessory
                }
                VStack(alignment: .leading, spacing: 0) {
                    labelText
                    accessory
                }
            }
            field
                .mlFont(.staffBody)
                .foregroundStyle(MLColor.ink)
                .padding(.horizontal, MLSpacing.s16)
                .frame(minHeight: MLSize.button)
                .background(RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous).fill(MLColor.surface))
                .overlay(RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous).stroke(MLColor.border, lineWidth: 1))
        }
    }
}

private extension SignInField {
    var labelText: some View {
        Text(label)
            .mlFont(.bodyEmphasis)
            .foregroundStyle(MLColor.ink)
            .accessibilityHidden(true)
    }
}

extension SignInField where Accessory == EmptyView {
    init(label: String, @ViewBuilder field: () -> Field) {
        self.init(label: label, accessory: { EmptyView() }, field: field)
    }
}

/// An error under a form. It has an icon as well as colour, so it does not rely on colour alone.
private struct InlineErrorText: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle")
            .mlFont(.body)
            .foregroundStyle(MLColor.danger)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Sign in with SRM: "Getting your details" (135:15587), then Home, or Couldn't sign in with Try again (135:15825).
struct SRMSignInView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    @State private var model: SRMSignInViewModel

    init(model: SRMSignInViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        Group {
            switch model.phase {
            case .gettingDetails:
                gettingDetails
            case .failed(let message):
                WelcomeLayout {
                    SignInFailureCard(message: message)
                    InkActionButton(title: EntryCopy.tryAgain) { Task { await run() } }
                }
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

    private var gettingDetails: some View {
        ZStack {
            OrbitBackground()
            VStack(spacing: MLSpacing.s8) {
                ProgressRing()
                    .padding(.bottom, MLSpacing.s16)
                Text(EntryCopy.gettingDetails)
                    .mlFont(.heroTitle)
                    .foregroundStyle(MLColor.ink)
                    .multilineTextAlignment(.center)
                Text(EntryCopy.fewSeconds)
                    .mlFont(.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            .padding(.horizontal, MLSpacing.margin)
        }
    }
}

#if DEMO_DATA
/// Previews only: the local demo sign-in, never shown in Review or Release.
private struct EntryPreviewHost<Content: View>: View {
    @State private var router = AppRouter()
    @State private var store = SessionStore()
    @ViewBuilder let content: () -> Content

    var body: some View {
        NavigationStack { content() }
            .environment(router)
            .environment(store)
            .environment(AppEnvironment.make())
    }
}

#Preview("Welcome") {
    EntryPreviewHost { WelcomeView() }
}

#Preview("Staff sign in · empty") {
    EntryPreviewHost { StaffSignInView(model: StaffSignInViewModel(auth: DemoDataProvider())) }
}

#Preview("Staff sign in · filled") {
    let model = StaffSignInViewModel(auth: DemoDataProvider())
    model.email = "supervisor@mealloop.example"
    model.password = "password"
    return EntryPreviewHost { StaffSignInView(model: model) }
}

#Preview("Staff sign in · forgot password") {
    let model = StaffSignInViewModel(auth: DemoDataProvider())
    model.showForgotPasswordMessage()
    return EntryPreviewHost { StaffSignInView(model: model) }
}
#endif
