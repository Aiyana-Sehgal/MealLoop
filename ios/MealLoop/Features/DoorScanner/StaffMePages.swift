import SwiftUI

// Language and Help for the Kitchen, Door Scanner, Pass Desk and Warden Me pages, pushed with the system back button.
// Built from the mess staff frames MS-G4 Language (1520:122891) and MS-G5 Help (1520:122941). Owner rulings
// (9 November): only English is shown until translations exist (the frame's Tamil card is left out), and Help keeps
// each role's documented rules instead of the frame's Kitchen answers, which name times no record holds.

enum StaffMeCopy {
    static let language = "Language"
    static let languageNote = "Pick the language for this app. Dish names stay as on the menu."
    static let english = "English"
    static let englishInUse = "English · in use"
    static let changeAnyTime = "You can change this any time from Me."
    static let help = "Help"
    static func helpSubtitle(_ role: String, count: Int) -> String {
        let words = [1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six"]
        return "\(role) · \(words[count] ?? "\(count)") plain answers"
    }
}

/// Which Me page is pushed.
enum StaffMePage: String, Identifiable, Hashable {
    case language, help
    var id: String { rawValue }
}

/// One question and its answer.
struct StaffHelpItem: Identifiable, Hashable {
    let question: String
    let answer: String
    var id: String { question }
}

/// MS-G4 Language: the language in use on the black card, then a note.
struct StaffLanguagePage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                Text(StaffMeCopy.languageNote)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    VStack(alignment: .leading, spacing: MLSpacing.s4) {
                        Text(StaffMeCopy.english).font(MLType.title2).foregroundStyle(MLColor.onHero)
                        Text(StaffMeCopy.englishInUse).font(MLType.staffBody).foregroundStyle(MLColor.onHeroSecondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(MLType.bodyEmphasis)
                        .foregroundStyle(MLColor.onLime)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(MLColor.lime))
                        .accessibilityHidden(true)
                }
                .padding(MLSpacing.s20)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.heroBackground))
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isSelected)
                Label(StaffMeCopy.changeAnyTime, systemImage: "questionmark.circle")
                    .font(MLType.bodyEmphasis)
                    .foregroundStyle(MLColor.ink)
                    .padding(MLSpacing.s16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.top, MLSpacing.s8)
            .padding(.bottom, MLSpacing.s32)
        }
        .background(MLColor.canvas.ignoresSafeArea())
        .navigationTitle(StaffMeCopy.language)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

/// MS-G5 Help: "Kitchen · four plain answers", then one white card per question.
struct StaffHelpPage: View {
    let role: String
    let items: [StaffHelpItem]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                Text(StaffMeCopy.helpSubtitle(role, count: items.count))
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: MLSpacing.s8) {
                        Text(item.question).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text(item.answer).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(MLSpacing.s16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.top, MLSpacing.s8)
            .padding(.bottom, MLSpacing.s32)
        }
        .background(MLColor.canvas.ignoresSafeArea())
        .navigationTitle(StaffMeCopy.help)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

extension View {
    /// Pushes the Me page Language or Help from inside a navigation stack.
    func staffMePages(_ page: Binding<StaffMePage?>, role: String, help: [StaffHelpItem]) -> some View {
        navigationDestination(item: page) { page in
            switch page {
            case .language: StaffLanguagePage()
            case .help: StaffHelpPage(role: role, items: help)
            }
        }
    }
}

/// Help for each role, from that role's documented rules (Prompt 4 role context; docs/PRESENTER_ACCOUNTS.md).
enum StaffHelpContent {
    static let doorScanner = [
        StaffHelpItem(question: "How do I record an entry?",
                      answer: "Scan the student's entry QR. If it won't scan, type the last 4 digits of the SRM ID."),
        StaffHelpItem(question: "What if a scan can't be checked?",
                      answer: "Nothing is recorded. The screen says so; it never shows an unchecked scan as an entry."),
        StaffHelpItem(question: "What is an SOS?",
                      answer: "A student reported something urgent at your mess. Claim it, check it, then mark it as checked."),
        StaffHelpItem(question: "Something is wrong at the door?",
                      answer: "Use Report a problem on Home. The supervisor sees it."),
    ]
    static let passDesk = [
        StaffHelpItem(question: "How do I check a Special pass?",
                      answer: "Compare the student's code and colour with the ones on your Home. They change together."),
        StaffHelpItem(question: "What does Check last 4 digits do?",
                      answer: "It shows whether that student has a pass for this meal. It records nothing."),
        StaffHelpItem(question: "A student lost their pass?",
                      answer: "Use Request a new pass on Home. It records the request; this prototype sends nothing."),
        StaffHelpItem(question: "Something is wrong at the desk?",
                      answer: "Use Report a problem. The supervisor sees it."),
    ]
    static let kitchen = [
        StaffHelpItem(question: "What does Home show?",
                      answer: "Before the meal, the forecast. During it, how many students entered. After it, the waste to record."),
        StaffHelpItem(question: "When can I record waste?",
                      answer: "Only after the meal. You can change a saved report for 6 hours."),
        StaffHelpItem(question: "A value is missing?",
                      answer: "It shows a dash. A missing value is never counted as zero."),
        StaffHelpItem(question: "Food is running out?",
                      answer: "Use Which food is short. The supervisor sees it at once."),
    ]
    static let warden = [
        StaffHelpItem(question: "When do I decide?",
                      answer: "Only after the student's guardian has answered. The queue shows requests in that order."),
        StaffHelpItem(question: "Does a guardian's video approve the outing?",
                      answer: "No. It is the guardian's answer. It does not prove identity and it is not your approval."),
        StaffHelpItem(question: "What if nobody decides in time?",
                      answer: "Nothing is approved by waiting. A late request is escalated to the senior warden."),
        StaffHelpItem(question: "Can the gate let a student out early?",
                      answer: "Only with a signed pass and only in its window. The gate cannot record an exit without one."),
    ]
}
