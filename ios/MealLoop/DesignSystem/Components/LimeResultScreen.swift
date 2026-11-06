import SwiftUI

/// The time arithmetic of a result screen that returns by itself. Kept apart from the view so it can be tested.
struct AutoReturnCountdown: Equatable {
    let seconds: Double

    /// How far the bar has filled, from 0 to 1.
    func fraction(elapsed: Double) -> Double {
        guard seconds > 0 else { return 1 }
        return min(max(elapsed / seconds, 0), 1)
    }

    /// Whole seconds still to wait, rounded up, so the caption never says 0 while the screen is still up.
    func secondsLeft(elapsed: Double) -> Int {
        max(Int((seconds - elapsed).rounded(.up)), 1)
    }

    func isFinished(elapsed: Double) -> Bool {
        elapsed >= seconds
    }

    /// A screen reader needs longer than the wait to reach the text, so with VoiceOver on only the button returns.
    static func runsAutomatically(voiceOverEnabled: Bool) -> Bool {
        !voiceOverEnabled
    }
}

/// The full-lime "it worked" screen (D07, P05, 33). Show it only for an action that was verified and saved:
/// a failed or offline result uses `OutcomeScreen`. This is the one screen with no Orbit backdrop.
struct LimeResultScreen: View {
    /// The white count card ("Recorded in so far 715 +1"). A nil value shows "—", never 0.
    struct Count: Equatable {
        let label: String
        let value: Int?
        /// Mono text after the number ("of 214").
        var suffix: String?
        /// The small chip on the right ("+1").
        var change: String?
    }

    /// One centred line below the subject.
    struct Line: Equatable, Identifiable {
        let text: String
        var isEmphasized: Bool = false

        var id: String { text }
    }

    /// Set this to return by itself. `caption` gets the whole seconds left ("Back to the camera in 1 s").
    struct AutoReturn {
        let seconds: Double
        let caption: (Int) -> String
    }

    /// Where this happened ("Door Scanner · Lunch").
    let context: String
    let title: String
    /// Who it happened to ("Aarav ••0238").
    let subject: String
    /// A non-interactive outlined note under the subject ("ID checked").
    var note: String?
    var lines: [Line] = []
    var count: Count?
    var autoReturn: AutoReturn?
    let actionTitle: String
    /// Runs once, from the button or the timer, whichever comes first.
    let onDone: () -> Void

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var elapsed: Double = 0
    @State private var didFinish = false

    /// Measured from the D07 and 33 exports.
    private let tickDiameter: CGFloat = 160
    private let barHeight: CGFloat = 6

    var body: some View {
        ZStack {
            MLColor.lime.ignoresSafeArea()
            ScrollView {
                VStack(spacing: MLSpacing.s24) {
                    Text(context)
                        .font(MLType.staffBody)
                        .foregroundStyle(MLColor.onLime)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    tick
                    heading
                    if let count {
                        countCard(count)
                    }
                    if let autoReturn, runsAutomatically {
                        progress(autoReturn)
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom) {
                InkActionButton(title: actionTitle, action: finish)
                    .padding(.horizontal, MLSpacing.margin)
                    .padding(.vertical, MLSpacing.s12)
            }
        }
        .task(id: autoReturn?.seconds) {
            await runCountdown()
        }
        .onAppear {
            AccessibilityNotification.Announcement("\(title). \(subject)").post()
        }
    }

    private var runsAutomatically: Bool {
        AutoReturnCountdown.runsAutomatically(voiceOverEnabled: voiceOverEnabled)
    }

    private var tick: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 64, weight: .bold))
            .foregroundStyle(MLColor.onHero)
            .frame(width: tickDiameter, height: tickDiameter)
            .background(Circle().fill(MLColor.ink))
            .accessibilityHidden(true)
    }

    private var heading: some View {
        VStack(spacing: MLSpacing.s8) {
            Text(title)
                .font(MLType.largeTitle)
                .accessibilityAddTraits(.isHeader)
            Text(subject)
                .font(MLType.title2)
            if let note {
                Text(note)
                    .font(MLType.body)
                    .padding(.horizontal, MLSpacing.s20)
                    .padding(.vertical, MLSpacing.s8)
                    .overlay(Capsule().stroke(MLColor.ink, lineWidth: 1.5))
            }
            ForEach(lines) { line in
                Text(line.text)
                    .font(line.isEmphasized ? MLType.staffPrimary : MLType.staffBody)
            }
        }
        .foregroundStyle(MLColor.onLime)
        .multilineTextAlignment(.center)
    }

    private func countCard(_ count: Count) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(count.label)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            HStack(spacing: MLSpacing.s8) {
                HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                    Text(count.value.map { String($0) } ?? "—")
                        .font(MLType.heroNumber)
                        .foregroundStyle(MLColor.ink)
                    if let suffix = count.suffix {
                        Text(suffix)
                            .font(MLType.monoBody)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                }
                Spacer(minLength: MLSpacing.s8)
                if let change = count.change {
                    Text(change)
                        .font(MLType.monoBody)
                        .foregroundStyle(MLColor.onLime)
                        .padding(.horizontal, MLSpacing.s16)
                        .padding(.vertical, MLSpacing.s8)
                        .background(Capsule().fill(MLColor.lime))
                        .overlay(Capsule().stroke(MLColor.limeOutline, lineWidth: 1))
                }
            }
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }

    private func progress(_ autoReturn: AutoReturn) -> some View {
        let countdown = AutoReturnCountdown(seconds: autoReturn.seconds)
        return VStack(spacing: MLSpacing.s12) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(MLColor.ink.opacity(0.15))
                    Capsule().fill(MLColor.ink)
                        .frame(width: proxy.size.width * countdown.fraction(elapsed: elapsed))
                }
            }
            .frame(height: barHeight)
            .accessibilityHidden(true)
            Text(autoReturn.caption(countdown.secondsLeft(elapsed: elapsed)))
                .font(MLType.body)
                .foregroundStyle(MLColor.onLime)
        }
    }

    /// Steps in small jumps rather than an animation, so it behaves the same with Reduce Motion on.
    private func runCountdown() async {
        guard let autoReturn, runsAutomatically else { return }
        let countdown = AutoReturnCountdown(seconds: autoReturn.seconds)
        let step = 0.05
        while !countdown.isFinished(elapsed: elapsed) {
            try? await Task.sleep(for: .seconds(step))
            if Task.isCancelled { return }
            elapsed += step
        }
        finish()
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onDone()
    }
}
