#if DEBUG
import SwiftUI

/// Debug-only visual QA for the shared components: each component in each state, with clearly local sample values.
/// Everything here is inside `#if DEBUG`, so it is not compiled into Review or Release (`BuildConfigurationTests`
/// does not cover it; `SharedComponentsTests.testGalleryIsCompiledOnlyInDebug` does).
/// Open it from the `#Preview` blocks at the end of this file.
struct ComponentGalleryView: View {
    /// Opens straight on one page, for screenshots.
    var initialPage: GalleryPage?
    @State private var path: [GalleryPage] = []

    var body: some View {
        NavigationStack(path: $path) {
            List(GalleryPage.allCases) { page in
                NavigationLink(page.title, value: page)
            }
            .navigationTitle("Components")
            .navigationDestination(for: GalleryPage.self) { page in
                GalleryPageView(page: page)
            }
        }
        .onAppear {
            if let initialPage, path.isEmpty {
                path = [initialPage]
            }
        }
    }
}

enum GalleryPage: String, CaseIterable, Identifiable, Hashable {
    case dialogStartMeal, dialogCloseMeal, dialogWorking
    case sheetShortage, sheetDigits, sheetQuantity
    case sosNotTaken, sosClaimed, sosChecked
    case sosTab, sosCards
    case limeEntry, limePass, limeGate
    case outcomeAlreadyScanned, outcomeOffline
    case answerPage, answerLocked, answerHero
    case heroChips, statusRows, stateBlocks, listRows, facts, keypads, progress, controls, feedback

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dialogStartMeal: "Confirm dialog · Start meal"
        case .dialogCloseMeal: "Confirm dialog · Close meal"
        case .dialogWorking: "Confirm dialog · Working"
        case .sheetShortage: "Sheet · Which food is short?"
        case .sheetDigits: "Sheet · Last 4 digits"
        case .sheetQuantity: "Sheet · Quantity"
        case .sosNotTaken: "SOS panel · Not taken"
        case .sosClaimed: "SOS panel · Claimed"
        case .sosChecked: "SOS panel · Checked, close case"
        case .sosTab: "SOS edge tab"
        case .sosCards: "SOS card on Alerts"
        case .limeEntry: "Lime result · Entry recorded"
        case .limePass: "Lime result · Pass verified"
        case .limeGate: "Lime result · Exit recorded"
        case .outcomeAlreadyScanned: "Outcome · Already scanned"
        case .outcomeOffline: "Outcome · Can't check right now"
        case .answerPage: "Answer buttons · Open"
        case .answerLocked: "Answer buttons · Locked"
        case .answerHero: "Answer row on the hero card"
        case .heroChips: "Hero status chips"
        case .statusRows: "Status text and shortage rows"
        case .stateBlocks: "State blocks"
        case .listRows: "List rows and section header"
        case .facts: "Fact cards"
        case .keypads: "Digit boxes and keypads"
        case .progress: "Progress"
        case .controls: "Pills, chips, segmented, link"
        case .feedback: "Toast and inline error"
        }
    }
}

/// Local sample values. Nothing here is reachable from a real screen.
private enum Sample {
    static let incident = SOSIncident(time: "12:45 PM", age: "5 min ago", title: "Found something in food", place: "Main Mess · Block A")
    static let alertIncident = SOSIncident(eyebrow: "SOS", time: "12:45 PM", age: "5 min ago", title: "Found something in food", place: "Main Mess · Block A")
    static let startMeal = ConfirmDialogContent(
        title: "Start this meal?", subject: "Lunch · Main Mess", detail: "Door scanner and pass desk will open.",
        cancelTitle: "Cancel", actionTitle: "Start meal"
    )
    static let closeMeal = ConfirmDialogContent(
        title: "Close this meal?", subject: "Lunch · Main Mess", detail: "Door scanner and pass desk will stop.",
        cancelTitle: "Cancel", actionTitle: "Close meal"
    )
    static let dishes = ["Steamed Rice", "Masala Sambar", "Muttar Masala", "Chappathi", "Veg Pulao", "Tomato Dal"]
    static let digits: DigitEntry = {
        var entry = DigitEntry()
        [0, 2, 3, 8].forEach { entry.append($0) }
        return entry
    }()
    static let partialDigits: DigitEntry = {
        var entry = DigitEntry()
        [0, 2].forEach { entry.append($0) }
        return entry
    }()
}

struct GalleryPageView: View {
    let page: GalleryPage

    var body: some View {
        switch page {
        case .limeEntry:
            LimeResultScreen(
                context: "Door Scanner · Lunch", title: "Entry recorded", subject: "Aarav ••0238",
                count: .init(label: "Recorded in so far", value: 715, change: "+1"),
                autoReturn: .init(seconds: 60) { "Back to the camera in \($0) s" },
                actionTitle: "Scan next", onDone: {}
            )
            .toolbar(.hidden, for: .navigationBar)
        case .limePass:
            LimeResultScreen(
                context: "Pass Desk · Lunch special", title: "Pass verified", subject: "Aarav ••0238",
                lines: [.init(text: "Valid special-meal pass for Lunch.")],
                count: .init(label: "Special meals recorded", value: 42, suffix: "of 214", change: "+1"),
                autoReturn: .init(seconds: 60) { "Back to the pass check in \($0) s" },
                actionTitle: "Check next", onDone: {}
            )
            .toolbar(.hidden, for: .navigationBar)
        case .limeGate:
            LimeResultScreen(
                context: "Main Gate · Exit", title: "Exit recorded", subject: "Aarav ••0238", note: "ID checked",
                lines: [
                    .init(text: "Outing pass · Sat 2–8 PM"),
                    .init(text: "Back by Sat 8 PM", isEmphasized: true),
                    .init(text: "3 students out now"),
                ],
                actionTitle: "Scan next", onDone: {}
            )
            .toolbar(.hidden, for: .navigationBar)
        case .outcomeAlreadyScanned:
            OutcomeScreen(
                onBack: {}, symbol: "person.fill.checkmark", title: "Already scanned",
                message: "Aarav ••0238 was recorded for Lunch.",
                facts: [FactRow(label: "First scanned", value: "12:18 PM"), FactRow(label: "Count stays", value: "715")],
                note: "Nothing was added to the count.",
                primary: .init(title: "Scan next", handler: {})
            )
            .toolbar(.hidden, for: .navigationBar)
        case .outcomeOffline:
            OutcomeScreen(
                onBack: {}, badge: .outlined, symbol: "wifi.slash", title: "Can't check right now",
                message: "No connection. This entry is NOT recorded.", isMessageEmphasized: true,
                facts: [FactRow(label: "Last update", value: "12:41 PM"), FactRow(label: "Entries waiting", value: "0")],
                primary: .init(title: "Try again", handler: {}),
                secondary: .init(title: "Type the last 4 digits", handler: {}),
                link: .init(title: "Report a problem", handler: {}),
                footnote: "Entries are never shown as recorded until they are saved."
            )
            .toolbar(.hidden, for: .navigationBar)
        case .dialogStartMeal, .dialogCloseMeal, .dialogWorking, .sheetShortage, .sheetDigits, .sheetQuantity,
             .sosNotTaken, .sosClaimed, .sosChecked:
            GalleryModalPage(page: page)
        default:
            ZStack {
                OrbitBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: MLSpacing.s24) {
                        content
                    }
                    .padding(.horizontal, MLSpacing.margin)
                    .padding(.vertical, MLSpacing.s16)
                }
            }
            .navigationTitle(page.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case .sosTab:
            GalleryState("Not claimed") {
                GalleryEdge { SOSEdgeTab(count: 1) {} }
            }
            GalleryState("Claimed by you") {
                GalleryEdge { SOSEdgeTab(count: 1, isClaimedByYou: true, claimedStatus: "You're checking this") {} }
            }
            GalleryState("Two active") {
                GalleryEdge { SOSEdgeTab(count: 2) {} }
            }
        case .sosCards:
            GalleryState("Not taken, on Alerts") {
                SOSCard(incident: Sample.alertIncident, status: .notTaken("Nobody has taken this yet"), actionTitle: "I'll go and check", onAction: {})
            }
            GalleryState("Claimed") {
                SOSCard(incident: Sample.alertIncident, status: .claimed("You're checking this"), note: "Ravi and the kitchen team can see you're on your way.")
            }
            GalleryState("Checked by someone else") {
                SOSCard(incident: Sample.alertIncident, status: .checked("Checked by the door", time: "12:52 PM"))
            }
        case .answerPage:
            GalleryState("Unanswered") { MealAnswerButtons(state: .unanswered) { _ in } }
            GalleryState("I'm in selected") { MealAnswerButtons(state: .answered(.attending)) { _ in } }
            GalleryState("Skip selected") { MealAnswerButtons(state: .answered(.skipping)) { _ in } }
            GalleryState("Saving") { MealAnswerButtons(state: .saving(.notSure)) { _ in } }
        case .answerLocked:
            GalleryState("Locked, no answer") {
                MealAnswerButtons(state: .locked(nil), lockedNote: "Answers closed at 9 AM. Your QR still works.") { _ in }
            }
            GalleryState("Locked, answered I'm in") {
                MealAnswerButtons(state: .locked(.attending), lockedNote: "Answers closed at 9 AM. Your QR still works.") { _ in }
            }
        case .answerHero:
            GalleryState("Not answered") {
                HeroCard {
                    HeroAnswerRow(state: .unanswered, onAnswer: { _ in }, onShowEntry: {})
                }
            }
            GalleryState("Locked: Entry QR still works") {
                HeroCard {
                    HeroAnswerRow(state: .locked(nil), onAnswer: { _ in }, onShowEntry: {})
                }
            }
            GalleryState("Show entry QR") {
                HeroCard {
                    HeroSurfaceButton(title: "Show entry QR") {}
                }
            }
        case .heroChips:
            GalleryState("Styles") {
                HeroCard {
                    VStack(alignment: .leading, spacing: MLSpacing.s12) {
                        HeroStatusChip(text: "I'm in", style: .lime, showsCheck: true)
                        HeroStatusChip(text: "Skipped", style: .outline)
                        HeroStatusChip(text: "Not answered", style: .dashed)
                        HeroStatusChip(text: "Checked by the door", time: "12:52 PM", style: .lime)
                        HeroStatusChip(text: "Nobody has taken this yet")
                    }
                }
            }
        case .statusRows:
            GalleryState("StatusText") {
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    StatusText(text: "Recorded", time: "2:40 PM")
                    StatusText(text: "Not started", dot: .empty)
                    StatusText(text: "Draft", dot: .dashed)
                }
            }
            GalleryState("ShortageRow") {
                VStack(spacing: MLSpacing.s12) {
                    ShortageRow(title: "Steamed Rice, almost out", detail: "Sent", detailTime: "1:30 PM")
                    ShortageRow(title: "Steamed Rice, almost out", detail: "Ravi saw it")
                    ShortageRow(
                        title: "Steamed Rice, almost out", detail: "Couldn't send", retryTitle: "Retry",
                        onRetry: {}, systemImage: "exclamationmark.triangle"
                    )
                }
            }
        case .stateBlocks:
            GalleryState("Check") {
                StateBlock(symbol: "checkmark", title: "You're all caught up", message: "No active shortages or missing waste reports.")
            }
            GalleryState("Bell") {
                StateBlock(symbol: "bell", title: "Nothing new", message: "Alerts from your supervisor show here.")
            }
            GalleryState("With an action") {
                StateBlock(symbol: "fork.knife", title: "No past meals yet.", actionTitle: "Retry", onAction: {})
            }
        case .listRows:
            GalleryState("Alerts") {
                VStack(spacing: 0) {
                    SectionHeader(title: "Earlier", actionTitle: "See all", onAction: {})
                    AlertRow(mark: .done, title: "Meal started", time: "12:00 PM", detail: "Ravi opened Lunch.")
                    AlertRow(mark: .filled(symbol: "bell"), title: "Problem seen", time: "12:24 PM", detail: "Scanner not working · Ravi", isUnread: true, onTap: {})
                    AlertRow(mark: .outlined(symbol: "clock"), title: "Meal ends soon", time: "1:50 PM", detail: "Lunch ends at 2:00 PM.")
                }
            }
            GalleryState("IconCardRow") {
                VStack(spacing: MLSpacing.s12) {
                    IconCardRow(symbol: "exclamationmark.triangle", title: "Report a problem") {}
                    IconCardRow(symbol: "camera", title: "Scanner not working", detail: "The camera or the phone has stopped working") {}
                }
            }
        case .facts:
            GalleryState("Values") {
                FactCard(rows: [FactRow(label: "First scanned", value: "12:18 PM"), FactRow(label: "Count stays", value: "715")])
            }
            GalleryState("Missing value, never 0") {
                FactCard(rows: [FactRow(label: "Final entries", value: nil), FactRow(label: "Waste report", value: "Recorded", isMono: false)])
            }
        case .keypads:
            GalleryState("Boxes on a white surface") {
                DigitBoxes(entry: Sample.digits)
                    .padding(MLSpacing.s16)
                    .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
            }
            GalleryState("Boxes on the black card") {
                HeroCard { DigitBoxes(entry: Sample.partialDigits, surface: .hero) }
            }
            GalleryState("Keypad on the canvas") { KeyPad { _ in } onDelete: {} }
        case .progress:
            GalleryState("Light") { SegmentedProgress(current: 3, total: 4) }
            GalleryState("No data, not 0") { SegmentedProgress(current: nil, total: 4) }
            GalleryState("On the black card, with labels") {
                HeroCard {
                    SegmentedProgress(current: 2, total: 4, surface: .hero, labels: ["Reported", "Seen", "Fixing", "Fixed"])
                }
            }
            GalleryState("Ring (existing)") { ProgressRing() }
        case .controls:
            GalleryState("CompactPillButton") {
                HStack {
                    CompactPillButton(title: "Retry") {}
                    CompactPillButton(title: "Enter kg", style: .dashed) {}
                    CompactPillButton(title: "Live", style: .lime) {}
                }
            }
            GalleryState("ChoiceChip") {
                HStack {
                    ChoiceChip(title: "Steamed Rice", isSelected: true) {}
                    ChoiceChip(title: "Tomato Dal", isSelected: false) {}
                }
            }
            GalleryState("SegmentedChoice") { GallerySegmented() }
            GalleryState("TextLinkButton") { TextLinkButton(title: "Add a note (optional)") {} }
        case .feedback:
            GalleryState("Toast") { ToastBanner(text: "Sent to Ravi. It is under Open problems.") }
            GalleryState("Inline error") { FieldErrorText(text: "Enter a number up to 99.9.") }
            GalleryState("Live toast") { GalleryToast() }
        default:
            EmptyView()
        }
    }
}

/// Puts a modal over a stand-in screen and opens it at once, so the scrim and the sheet can be judged in place.
private struct GalleryModalPage: View {
    let page: GalleryPage
    @State private var isOpen = false
    @State private var dish = Sample.dishes[0]
    @State private var level = "Almost out"

    var body: some View {
        ZStack(alignment: .topLeading) {
            OrbitBackground()
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                ScreenTitleBlock(title: "Lunch", subtitle: "Main Mess · 12–2 PM")
                InkActionButton(title: "Open again") { isOpen = true }
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.top, MLSpacing.s16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { isOpen = true }
        .modifier(GalleryPresenter(page: page, isOpen: $isOpen, sheet: AnyView(sheetContent)))
    }

    @ViewBuilder
    private var sheetContent: some View {
        switch page {
        case .sheetShortage:
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                SheetHeader(title: "Which food is short?") { isOpen = false }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MLSpacing.s12) {
                    ForEach(Sample.dishes, id: \.self) { name in
                        ChoiceChip(title: name, isSelected: name == dish) { dish = name }
                    }
                }
                Text("How bad? (optional)").font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                SegmentedChoice(
                    options: ["Getting low", "Almost out", "Out"].map { .init(value: $0, title: $0) },
                    selection: $level
                )
                TextLinkButton(title: "Add a note (optional)") {}
                InkActionButton(title: "Send to Ravi") {}
            }
        case .sheetDigits:
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                SheetHeader(title: "Type the last 4 digits") { isOpen = false }
                DigitBoxes(entry: Sample.digits)
                InkActionButton(title: "Record entry") {}
                KeyPad(keyHeight: 54, keyFill: MLColor.fillQuiet) { _ in } onDelete: {}
            }
        case .sheetQuantity:
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                SheetHeader(title: "Veg Pulao", subtitle: "Left over, in kg") { isOpen = false }
                FieldErrorText(text: "Enter a number up to 99.9.")
                HStack(spacing: MLSpacing.s12) {
                    OutlineActionButton(title: "None left") {}
                    OutlineActionButton(title: "Not made") {}
                }
                KeyPad(keyHeight: 48, keyFill: MLColor.fillQuiet, onDigit: { _ in }, onDelete: {}, onDecimal: {})
                InkActionButton(title: "Save") {}
            }
        case .sosNotTaken:
            SOSPanel(
                title: "SOS · 1 active", incident: Sample.incident, status: .notTaken("Nobody has taken this yet"),
                helper: "Only if you're free. Keep scanning first if the door is busy.",
                primary: .init(title: "I'll go and check", handler: {}),
                secondary: .init(title: "Not now") { isOpen = false },
                onClose: { isOpen = false }
            )
        case .sosClaimed:
            SOSPanel(
                title: "SOS · 1 active", incident: Sample.incident, status: .claimed("You're checking this"),
                note: "Ravi and the kitchen team can see you're on your way.",
                primary: .init(title: "Mark as checked", handler: {}),
                secondary: .init(title: "Back to scanning") { isOpen = false },
                link: .init(title: "I can't go after all", handler: {}),
                onClose: { isOpen = false }
            )
        case .sosChecked:
            SOSPanel(
                title: "SOS · 1 active", incident: Sample.incident, status: .checked("Checked by the door", time: "12:52 PM"),
                note: "Close the case when you are satisfied.",
                primary: .init(title: "Close case", handler: {}),
                secondary: .init(title: "Not yet") { isOpen = false },
                onClose: { isOpen = false }
            )
        default:
            EmptyView()
        }
    }
}

private struct GalleryPresenter: ViewModifier {
    let page: GalleryPage
    @Binding var isOpen: Bool
    let sheet: AnyView

    func body(content: Content) -> some View {
        switch page {
        case .dialogStartMeal:
            content.mlConfirmDialog(isPresented: $isOpen, content: Sample.startMeal) { isOpen = false }
        case .dialogCloseMeal:
            content.mlConfirmDialog(isPresented: $isOpen, content: Sample.closeMeal) { isOpen = false }
        case .dialogWorking:
            content.mlConfirmDialog(isPresented: $isOpen, content: Sample.startMeal, isWorking: true) {}
        default:
            content.mlSheet(isPresented: $isOpen) { sheet }
        }
    }
}

private struct GalleryState<Content: View>: View {
    let name: String
    @ViewBuilder let content: Content

    init(_ name: String, @ViewBuilder content: () -> Content) {
        self.name = name
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            Text(name).font(MLType.meta).foregroundStyle(MLColor.inkSecondary)
            content
        }
    }
}

/// Holds a view against the right edge of the screen, past the page margin, where the SOS tab lives.
private struct GalleryEdge<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, -MLSpacing.margin)
            .padding(.top, MLSpacing.s12)
    }
}

private struct GallerySegmented: View {
    @State private var selection = "Left over"

    var body: some View {
        SegmentedChoice(options: ["Left over", "Ran out", "To check"].map { .init(value: $0, title: $0) }, selection: $selection)
    }
}

private struct GalleryToast: View {
    @State private var message: String?

    var body: some View {
        OutlineActionButton(title: "Show toast") { message = "Case closed" }
            .frame(height: 120, alignment: .top)
            .mlToast(message: $message)
    }
}

#Preview("Gallery") { ComponentGalleryView() }
#Preview("Confirm dialog") { GalleryPageView(page: .dialogStartMeal) }
#Preview("Sheet") { GalleryPageView(page: .sheetShortage) }
#Preview("SOS panel") { GalleryPageView(page: .sosClaimed) }
#Preview("Lime result") { GalleryPageView(page: .limeEntry) }
#Preview("Outcome") { GalleryPageView(page: .outcomeOffline) }
#Preview("Answer buttons") { GalleryPageView(page: .answerPage) }
#Preview("Rows") { GalleryPageView(page: .listRows) }
#endif
