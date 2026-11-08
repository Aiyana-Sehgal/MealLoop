import SwiftUI

/// Words of the simplified Pass Desk (owner ruling, Prompt 2B). Plain words; no instructions on Home.
enum PassDeskSimpleCopy {
    static let title = "Pass desk"
    static let code = "Code"
    static let colour = "Colour"
    static func changesIn(_ seconds: Int) -> String { "Changes in \(seconds) s" }
    static let codeUnavailable = "Can't show the code right now"
    static let checkLastFour = "Check last 4 digits"
    static func header(meal: String, hours: String, mess: String) -> String { "\(meal) \(hours) · \(mess)" }
    static func validNotUsed(_ meal: String) -> String { "Valid for \(meal.lowercased()) · not used yet" }
    static func inUse(_ seconds: Int) -> String { "In use · valid for \(seconds) s" }
    static let used = "Used"
    static let notFound = "Not found"
    static let noPass = "No special pass"
    static let wrongMeal = "Wrong meal"
    static let cantCheck = "Can't check right now"
}

/// The live code on Home: the same clock-derived code and colour the student's phone shows. Read only.
@MainActor
@Observable
final class PassDeskLiveCodeModel {
    private(set) var current: CurrentPassCode?
    private(set) var secondsLeft: Int?
    /// True when the code can't be trusted (offline or no answer): no code is shown as valid.
    private(set) var isUnavailable = false
    private var meal: MealID?
    private let use: any PassUseRepository
    private let live: any LivePassCodeRepository

    init(use: any PassUseRepository, live: any LivePassCodeRepository) {
        self.use = use
        self.live = live
    }

    func load(meal: MealID) async {
        self.meal = meal
        await refresh()
    }

    func clear() {
        meal = nil
        current = nil
        secondsLeft = nil
        isUnavailable = false
    }

    private func refresh() async {
        guard let meal else { return }
        do {
            let code = try await use.deskCode(for: meal, at: await live.passCodeInstant())
            current = code
            secondsLeft = code.secondsLeft
            isUnavailable = false
        } catch {
            current = nil
            secondsLeft = nil
            isUnavailable = true
        }
    }

    /// One second. At the end of the window the next code comes from the backend, never from a count on this phone.
    func tick() async {
        guard meal != nil else { return }
        guard let left = secondsLeft, left > 1, !isUnavailable else {
            await refresh()
            return
        }
        secondsLeft = left - 1
    }
}

/// The Student pass ticket's code half (StudentPassView `PassLiveTicket`, Figma Pass · Live 221:63212), copied here so the
/// Student files stay as they are: "Code", the code, "Colour", the colour pill with its name, "Changes in N s". No holder
/// row and no "Show this at the counter".
struct PassDeskCodeCard: View {
    let code: CurrentPassCode?
    let secondsLeft: Int?
    let isUnavailable: Bool

    var body: some View {
        VStack(spacing: MLSpacing.s8) {
            if let code, !isUnavailable {
                Text(PassDeskSimpleCopy.code).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
                Text(code.live.code)
                    .font(.system(size: 76, weight: .bold, design: .monospaced))
                    .foregroundStyle(MLColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
                Text(PassDeskSimpleCopy.colour).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
                Text(code.live.colourName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(PassColour.text(code.live.colourName))
                    .frame(width: 220, height: 56)
                    .background(Capsule().fill(PassColour.fill(code.live.colourName)))
                    .overlay {
                        if PassColour.outlined(code.live.colourName) {
                            Capsule().strokeBorder(MLColor.limeOutline, lineWidth: 1.5)
                        }
                    }
                Text(PassDeskSimpleCopy.changesIn(secondsLeft ?? code.secondsLeft))
                    .font(StudentType.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
                    .monospacedDigit()
                    .padding(.top, 2)
            } else {
                Text(PassDeskSimpleCopy.codeUnavailable)
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, MLSpacing.s32)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("passdesk.codeCard")
    }
}

/// Check last 4 digits: a lookup that never records. The answer comes from the repository at the pass-code instant.
@MainActor
@Observable
final class PassDeskCheckDigitsModel {
    private(set) var entry = DigitEntry()
    private(set) var result: LoadState<PassDigitCheck> = .idle
    private let use: any PassUseRepository
    private let live: any LivePassCodeRepository
    private let meal: MealID

    init(use: any PassUseRepository, live: any LivePassCodeRepository, meal: MealID) {
        self.use = use
        self.live = live
        self.meal = meal
    }

    func type(_ digit: Int) async {
        guard !entry.isComplete else { return }
        entry.append(digit)
        guard entry.isComplete else { return }
        result = .loading
        do {
            result = .loaded(try await use.checkLastFour(entry.text, meal: meal, at: await live.passCodeInstant()))
        } catch RepositoryError.offline(let savedAt) {
            result = .offline(nil, savedAt: savedAt)
        } catch {
            result = .failed(LoadFailure(error))
        }
    }

    func deleteLast() {
        entry.deleteLast()
        result = .idle
    }

    /// The one status line. Offline or any failure says only that it can't check; never a success.
    var statusLine: String? {
        switch result {
        case .idle, .loading: return nil
        case .failed, .empty, .offline: return PassDeskSimpleCopy.cantCheck
        case .loaded(let check), .stale(let check, _):
            switch check {
            case .validNotUsed(_, let slot): return PassDeskSimpleCopy.validNotUsed(MLFormat.mealSlot(slot))
            case .inUse(_, let left): return PassDeskSimpleCopy.inUse(left)
            case .used: return PassDeskSimpleCopy.used
            case .notFound: return PassDeskSimpleCopy.notFound
            case .noPass: return PassDeskSimpleCopy.noPass
            case .wrongMeal: return PassDeskSimpleCopy.wrongMeal
            }
        }
    }
}

/// Check last 4 digits (reference image 2): Back, the title, four boxes, one status line in a card, the keypad. No buttons.
struct PassDeskCheckDigitsView: View {
    @State var model: PassDeskCheckDigitsModel
    let onBack: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    BackButton(action: onBack).padding(.leading, -MLSpacing.s4)
                    Text(PassDeskSimpleCopy.checkLastFour)
                        .font(MLType.largeTitle)
                        .foregroundStyle(MLColor.ink)
                        .accessibilityAddTraits(.isHeader)
                    StaffDigitBoxes(entry: model.entry, accessibilityTitle: PassDeskSimpleCopy.checkLastFour)
                    if let line = model.statusLine {
                        StatusText(text: line, dot: line == PassDeskSimpleCopy.cantCheck ? .empty : .filled)
                            .padding(.horizontal, MLSpacing.s20)
                            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
                            .accessibilityIdentifier("passdesk.checkStatus")
                    }
                    KeyPad(keyHeight: PassDeskLayout.keyHeight, keyFill: MLColor.fillQuiet) { digit in
                        Task { await model.type(digit) }
                    } onDelete: {
                        model.deleteLast()
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, MLSpacing.s32)
            }
        }
    }
}
