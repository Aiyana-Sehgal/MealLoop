import SwiftUI

// The guardian's first-run flow, from page 13: G-0 Sign in (1929:131727), G-0 Verify code (1929:131799), G-A1 Activate
// account (1929:131872), G-A2 Confirm link (1929:131931) and G-A3 Done (1929:132000). It runs once per launch of the
// guardian@mealloop.example session, then opens the decision page; a relaunch starts it again.
//
// Simulated: guardian authentication is not decided (OPEN_DECISIONS P71). Nothing is sent and nobody is called. The
// phone number, student and hostel come from the seeded guardian link; the code length is the one the frame draws, and
// no expiry or retry rule is applied. Any complete code continues, and the page says so.

enum GuardianEntryCopy {
    static let signInTitle = "Sign in as a guardian"
    static let signInSubtitle = "We use the number SRM has on record."
    static let phoneLabel = "Your phone number"
    static let sendCode = "Send code"
    static let activateLink = "First time here? Activate with your invite link"
    static let howItWorks = "How it works"
    static func howSteps(student: String, block: String) -> [(String, String)] {
        [("\(student) asks to go out", "Day, time, place and reason."),
         ("You reply first", "Accept with a short video, or reject."),
         ("The \(block) warden reviews", "Only after you approve."),
         ("\(student) gets a pass", "Valid only for the approved time.")]
    }

    static let verifyBar = "Verify"
    /// Drawn in G-0 Verify code. It is the frame's wording, not a decided rule (P71).
    static let codeLength = 6
    static let verifyTitle = "Enter the 6-digit code"
    static func verifySubtitle(_ phone: String) -> String { "Sent to \(phone). It works for 10 minutes." }
    static let codeLabel = "Code"
    static let verify = "Verify"
    static let sendNewCode = "Send a new code"
    static let codeNotSent = "Prototype: no code is sent, so any 6 digits continue."
    static let nothingSent = "Prototype: nothing was sent."

    static let activateBar = "Activate"
    static let activateTitle = "Activate your guardian account"
    static let activateSubtitle = "The hostel office sent you this link by SMS. It works once, for 48 hours."
    static let student = "Student"
    static let hostel = "Hostel"
    static let yourNumber = "Your number"
    static let invitedBy = "Invited by"
    static let hostelOffice = "Hostel office"
    static let checkNumber = "We check your number against SRM's records before you can approve anything."
    static let continueTitle = "Continue"

    static func linkedTitle(_ student: String, _ block: String?) -> String {
        block.map { "You're linked to \(student) · \($0)" } ?? "You're linked to \(student)"
    }
    static let linkedSubtitle = "Is this your child or ward? Only say yes if it is."
    static let yesRight = "Yes, that's right"
    static let noCall = "No, call the hostel office"
    static let noStops = "Saying no stops the link. Nothing is shared with you."

    // Generated (no frame): what follows "No, call the hostel office". Owner to review.
    static let declinedTitle = "Call the hostel office"
    static let declinedDetail = "Nothing is shared with you. Ask the hostel office to check who this link belongs to."
    static let declinedPrototype = "Prototype: no call is placed and your answer is not recorded."
    static let backToSignIn = "Back to sign in"

    static let ready = "Ready"
    static let readyTitle = "Your account is ready"
    static func linkedTo(_ student: String, _ block: String?) -> String {
        block.map { "Linked to \(student) · \($0)" } ?? "Linked to \(student)"
    }
    static func readyDetail(_ student: String) -> String {
        "We'll send you a message when \(student) asks to go out. Reply before the time shown, or the request closes."
    }
    static let openRequest = "Open the request"
}

/// A step after Sign in. Sign in is the stack's root.
enum GuardianEntryStep: Hashable {
    case verify
    case activate
    case confirmLink
    case declined
    case done
}

/// Runs the first-run flow, then hands the loaded model to the decision page.
struct GuardianEntryFlow: View {
    @Environment(AppEnvironment.self) private var environment
    let account: AccountID
    /// Screenshot runs pass a loaded model, the steps to show and a typed code.
    var preparedModel: GuardianModel?
    var initialPath: [GuardianEntryStep] = []
    var initialCode = ""
    let onFinish: (GuardianModel) -> Void

    @State private var holder: GuardianModel?
    @State private var path: [GuardianEntryStep] = []
    @State private var code = ""
    @State private var showsLanguage = false
    @State private var resent = false

    var body: some View {
        Group {
            if let model = holder {
                NavigationStack(path: $path) {
                    signIn(model)
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationDestination(for: GuardianEntryStep.self) { step in
                            destination(step, model: model)
                        }
                }
                .mlSheet(isPresented: $showsLanguage) {
                    GuardianSheetView(model: model, sheet: .language, rejectReason: .constant(nil),
                                      changeFields: .constant([])) { showsLanguage = false }
                }
            } else {
                ZStack {
                    OrbitBackground()
                    ProgressView()
                }
            }
        }
        .task {
            guard holder == nil else { return }
            code = initialCode
            if let preparedModel {
                holder = preparedModel
            } else {
                let made = GuardianModel(account: account, repository: OutingCaseRepositories.source(for: environment))
                await made.load()
                holder = made
            }
            path = initialPath
        }
    }

    private func student(_ model: GuardianModel) -> OutingStudent? { model.link?.student }

    // MARK: G-0 Sign in

    private func signIn(_ model: GuardianModel) -> some View {
        GuardianLayout(model: model, title: GuardianEntryCopy.signInTitle,
                              subtitle: GuardianEntryCopy.signInSubtitle, onLanguage: { showsLanguage = true }) {
            VStack(alignment: .leading, spacing: MLSpacing.s8) {
                Text(GuardianEntryCopy.phoneLabel).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                Text(model.link?.phone ?? "—")
                    .font(MLType.staffBody)
                    .foregroundStyle(MLColor.ink)
                    .padding(.horizontal, MLSpacing.s16)
                    .frame(maxWidth: .infinity, minHeight: MLSize.staffButton, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
                    .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
                        .stroke(MLColor.border, lineWidth: 1))
            }
            .accessibilityElement(children: .combine)
            InkActionButton(title: GuardianEntryCopy.sendCode) { push(.verify) }
                .padding(.top, MLSpacing.s16)
            TextLinkButton(title: GuardianEntryCopy.activateLink) { push(.activate) }
            howItWorks(model)
        } footer: {
            EmptyView()
        }
    }

    /// "How it works": the four steps, naming the student and block from the seeded link.
    private func howItWorks(_ model: GuardianModel) -> some View {
        let name = model.studentName
        return VStack(alignment: .leading, spacing: MLSpacing.s16) {
                Text(GuardianEntryCopy.howItWorks).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(GuardianEntryCopy.howSteps(student: name, block: student(model)?.block ?? "hostel")
                    .enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: MLSpacing.s12) {
                        Text("\(index + 1)")
                            .font(MLType.secondary)
                            .foregroundStyle(MLColor.ink)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(MLColor.fillQuiet))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.0).font(MLType.staffBody).foregroundStyle(MLColor.ink)
                            Text(step.1).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(MLSpacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
            .overlay(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).stroke(MLColor.border, lineWidth: 1))
            .padding(.top, MLSpacing.s16)
    }

    @ViewBuilder
    private func destination(_ step: GuardianEntryStep, model: GuardianModel) -> some View {
        switch step {
        case .verify:
            verify(model).entryBar(GuardianEntryCopy.verifyBar)
        case .activate:
            activate(model).entryBar(GuardianEntryCopy.activateBar)
        case .confirmLink:
            confirmLink(model).entryBar(GuardianEntryCopy.activateBar)
        case .declined:
            declined(model).entryBar(GuardianEntryCopy.activateBar)
        case .done:
            done(model)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: G-0 Verify code

    private func verify(_ model: GuardianModel) -> some View {
        GuardianLayout(model: model, title: GuardianEntryCopy.verifyTitle,
                       subtitle: GuardianEntryCopy.verifySubtitle(model.link?.phone ?? "—"),
                       onLanguage: { showsLanguage = true }) {
            GuardianCodeField(code: $code, length: GuardianEntryCopy.codeLength)
            Text(resent ? GuardianEntryCopy.nothingSent : GuardianEntryCopy.codeNotSent)
                .font(MLType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
            howItWorks(model)
        } footer: {
            InkActionButton(title: GuardianEntryCopy.verify) { onFinish(model) }
                .disabled(code.count < GuardianEntryCopy.codeLength)
            TextLinkButton(title: GuardianEntryCopy.sendNewCode) { resent = true }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: G-A1 Activate account

    private func activate(_ model: GuardianModel) -> some View {
        GuardianLayout(model: model, title: GuardianEntryCopy.activateTitle,
                       subtitle: GuardianEntryCopy.activateSubtitle, onLanguage: { showsLanguage = true }) {
            VStack(spacing: 0) {
                factRow(GuardianEntryCopy.student, student(model)?.displayName)
                factRow(GuardianEntryCopy.hostel, student(model)?.block)
                factRow(GuardianEntryCopy.yourNumber, model.link?.phone)
                factRow(GuardianEntryCopy.invitedBy, GuardianEntryCopy.hostelOffice, isLast: true)
            }
            .padding(.horizontal, MLSpacing.s16)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
            .overlay(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).stroke(MLColor.border, lineWidth: 1))
        } footer: {
            Text(GuardianEntryCopy.checkNumber).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            InkActionButton(title: GuardianEntryCopy.continueTitle) { push(.confirmLink) }
        }
    }

    private func factRow(_ label: String, _ value: String?, isLast: Bool = false) -> some View {
        HStack(spacing: MLSpacing.s12) {
            Text(label).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                .frame(width: 112, alignment: .leading)
            Text(value ?? "—").font(MLType.staffBody).foregroundStyle(MLColor.ink)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 52)
        .overlay(alignment: .bottom) { if !isLast { Rectangle().fill(MLColor.border).frame(height: 1) } }
        .accessibilityElement(children: .combine)
    }

    // MARK: G-A2 Confirm link

    private func confirmLink(_ model: GuardianModel) -> some View {
        GuardianLayout(model: model, title: GuardianEntryCopy.linkedTitle(model.studentName, student(model)?.block),
                       subtitle: GuardianEntryCopy.linkedSubtitle, onLanguage: { showsLanguage = true }) {
            studentCard(model)
        } footer: {
            InkActionButton(title: GuardianEntryCopy.yesRight) { push(.done) }
            OutlineActionButton(title: GuardianEntryCopy.noCall) { push(.declined) }
            Text(GuardianEntryCopy.noStops).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The linked student, as G-A2 draws it. The year of study is not shown: no record holds it.
    private func studentCard(_ model: GuardianModel) -> some View {
        HStack(spacing: MLSpacing.s16) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(MLColor.ink)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(student(model)?.displayName ?? "—").font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                // G-A2 also draws the year of study; no record holds it, so only the block is shown.
                Text(student(model)?.block ?? "—").font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(MLSpacing.s20)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        .overlay(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).stroke(MLColor.border, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    // MARK: Declined (generated)

    private func declined(_ model: GuardianModel) -> some View {
        GuardianLayout(model: model, title: GuardianEntryCopy.declinedTitle, subtitle: GuardianEntryCopy.declinedDetail,
                       onLanguage: { showsLanguage = true }) {
            studentCard(model)
            // What the hostel office will ask about: the guardian's own number and who sent the link (G-A1 rows).
            VStack(spacing: 0) {
                OutingFactRow(label: GuardianEntryCopy.yourNumber, value: model.link?.phone)
                OutingFactRow(label: GuardianEntryCopy.invitedBy, value: GuardianEntryCopy.hostelOffice)
            }
            .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
            Text(GuardianEntryCopy.declinedPrototype).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
        } footer: {
            InkActionButton(title: GuardianEntryCopy.backToSignIn) { path = [] }
        }
    }

    // MARK: G-A3 Done

    private func done(_ model: GuardianModel) -> some View {
        GuardianEntryDoneLayout(model: model, onLanguage: { showsLanguage = true }) {
            onFinish(model)
        }
    }

    private func push(_ step: GuardianEntryStep) { path.append(step) }
}

private extension View {
    /// The pushed steps' bar: the system back button (swipe-back works) and the small centred title.
    func entryBar(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

/// G-A3 Done: no large title, the black card says the account is ready.
private struct GuardianEntryDoneLayout: View {
    let model: GuardianModel
    let onLanguage: () -> Void
    let onOpen: () -> Void

    var body: some View {
        let student = model.link?.student
        ZStack {
            OrbitBackground()
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                HStack {
                    HStack(spacing: MLSpacing.s8) {
                        OrbitMarkView()
                        Text("MealLoop").font(MLType.bodyEmphasis).foregroundStyle(MLColor.ink)
                    }
                    .accessibilityElement(children: .combine)
                    Spacer()
                    Button(action: onLanguage) {
                        Text(GuardianCopy.languagePill)
                            .font(MLType.body)
                            .foregroundStyle(MLColor.ink)
                            .padding(.horizontal, MLSpacing.s16)
                            .frame(minHeight: MLSize.hit)
                            .background(Capsule().fill(MLColor.surface))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(GuardianCopy.languageTitle)
                }
                HeroCard {
                    HStack(spacing: MLSpacing.s12) {
                        Image(systemName: "checkmark")
                            .font(MLType.title2)
                            .foregroundStyle(MLColor.onLime)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(MLColor.lime))
                            .accessibilityHidden(true)
                        HeroStatusChip(text: GuardianEntryCopy.ready, style: .lime)
                    }
                    Text(GuardianEntryCopy.readyTitle)
                        .font(MLType.title2)
                        .foregroundStyle(MLColor.onHero)
                        .padding(.top, MLSpacing.s16)
                        .accessibilityAddTraits(.isHeader)
                    Text(GuardianEntryCopy.linkedTo(student?.displayName ?? "—", student?.block))
                        .font(MLType.staffBody)
                        .foregroundStyle(MLColor.onHeroSecondary)
                        .padding(.top, MLSpacing.s4)
                }
                Text(GuardianEntryCopy.readyDetail(model.studentName))
                    .font(MLType.staffBody)
                    .foregroundStyle(MLColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if model.request != nil {
                    GuardianOutingFacts(request: model.request)
                }
                Spacer(minLength: 0)
                InkActionButton(title: GuardianEntryCopy.openRequest, action: onOpen)
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.top, MLSpacing.s8)
            .padding(.bottom, MLSpacing.s8)
        }
    }
}

/// The six code boxes drawn in G-0 Verify code over one number field, so the system keyboard, paste and the one-time
/// code suggestion all work. A screen reader hears the field, not the boxes.
struct GuardianCodeField: View {
    @Binding var code: String
    let length: Int
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            HStack(spacing: MLSpacing.s8) {
                ForEach(0..<length, id: \.self) { index in
                    Text(character(at: index))
                        .font(MLType.title2.monospaced())
                        .foregroundStyle(MLColor.ink)
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
                        .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
                            .stroke(index == code.count && isFocused ? MLColor.ink : MLColor.border,
                                    lineWidth: index == code.count && isFocused ? 2 : 1))
                }
            }
            .accessibilityHidden(true)
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .frame(maxWidth: .infinity, minHeight: 64)
                .accessibilityLabel(GuardianEntryCopy.codeLabel)
                .accessibilityValue("\(code.count) of \(length) entered")
                .onChange(of: code) { _, new in
                    let digits = String(new.filter(\.isNumber).prefix(length))
                    if digits != new { code = digits }
                }
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }

    private func character(at index: Int) -> String {
        guard index < code.count else { return " " }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }
}
