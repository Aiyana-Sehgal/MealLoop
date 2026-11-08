import SwiftUI

/// Everything before sign-in: Welcome, with Staff sign in and Sign in with SRM pushed on top.
/// Welcome and Staff sign in are `MLScreen`s: Staff sign in keeps the navigation bar, so the system back button and
/// the swipe-back gesture work on it. Sign in with SRM still hides the bar (not migrated in this change).
struct EntryFlowView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.entryPath) {
            WelcomeView()
                .navigationDestination(for: EntryRoute.self) { route in
                    switch route {
                    case .staffSignIn:
                        StaffSignInView(model: StaffSignInViewModel(auth: environment.repositories.auth))
                    case .srmSignIn:
                        SRMSignInView(model: SRMSignInViewModel(auth: environment.repositories.auth))
                            .toolbar(.hidden, for: .navigationBar)
                            .navigationBarBackButtonHidden(true)
                    }
                }
        }
    }
}

/// Onboarding · Sign in (221:62499), plus the Staff sign in action. The brand sits in the middle of the space above
/// the actions, and the actions and the terms are pinned to the bottom safe area. It scrolls at large text sizes.
struct WelcomeView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        MLScreen(nil, showsNavigationBar: false, fillsViewport: true) {
            brand
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, MLSpacing.s32)
        } bottom: {
            actions
        }
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

    @ViewBuilder
    private var actions: some View {
        InkActionButton(title: EntryCopy.signInWithSRM) {
            router.entryPath.append(.srmSignIn)
        }
        OutlineActionButton(title: EntryCopy.staffSignIn) {
            router.entryPath.append(.staffSignIn)
        }
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

/// Staff sign in, laid out as a standard iOS sign-in on the proportions of MS-0 (1508:45): the brand row at the top,
/// the title and the form in the upper middle with "Forgot password?" beside the password, and the Sign in button
/// with its helper line pinned to the bottom safe area, above the keyboard.
/// It keeps the email and password form; whether staff use SRM sign-in is open question P-FINAL-2.
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
