import SwiftUI

/// GV-02 Record: dark, live video only, the phrase and a fresh 3-digit code, a countdown ring, 4 to 10 seconds.
/// The simulator has no camera, so the preview is a still face placeholder and no video is captured; the timer and
/// the length rules are real. Capture is not verified on a device (see the report).
struct GuardianRecordScreen: View {
    let model: GuardianModel
    let phase: GuardianModel.RecordPhase
    /// Screenshot runs show a fixed time and stop the clock.
    var initialElapsed = 0
    var runsTimer = true

    @State private var elapsed = 0
    @State private var timer: Task<Void, Never>?

    private var challenge: CaptureChallenge? { model.challenge }
    private var maxSeconds: Int { challenge?.maximumSeconds ?? 0 }

    var body: some View {
        ZStack {
            MLColor.heroBackground.ignoresSafeArea()
            VStack(spacing: MLSpacing.s16) {
                HStack {
                    Button {
                        stopTimer()
                        model.closeRecorder()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(MLColor.onHero)
                            .frame(width: MLSize.hit, height: MLSize.hit)
                            .background(Circle().fill(Color.white.opacity(0.14)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(GuardianCopy.close)
                    Spacer()
                    if let challenge {
                        Text(GuardianCopy.tryOf(challenge.attempt, challenge.attemptsAllowed))
                            .font(MLType.body).foregroundStyle(MLColor.onHeroSecondary)
                    }
                }
                GuardianPhraseCard(challenge: challenge, dark: true)
                preview
                Text(clock(elapsed))
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(MLColor.onHero)
                Text(helper).font(MLType.body).foregroundStyle(MLColor.onHeroSecondary)
                    .multilineTextAlignment(.center)
                recordButton
                    .padding(.bottom, MLSpacing.s8)
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.top, MLSpacing.s8)
        }
        .environment(\.colorScheme, .dark)
        .task {
            elapsed = initialElapsed
            if case .tooShort(let seconds) = phase { elapsed = seconds }
        }
        .onDisappear { stopTimer() }
    }

    private var isRecording: Bool { phase == .recording }

    private var helper: String {
        switch phase {
        case .ready: return GuardianCopy.tapToStart
        case .recording: return GuardianCopy.speakNow(clock(maxSeconds))
        case .tooShort: return GuardianCopy.tooShortHelp
        case .tooDark: return GuardianCopy.tooDarkHelp
        }
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(Color.white.opacity(0.12))
            FacePlaceholder(tint: Color.white.opacity(phase == .tooDark ? 0.12 : 0.22))
            GuardianCorners(color: MLColor.lime.opacity(phase == .tooDark ? 0.5 : 1))
        }
        .overlay(alignment: .topLeading) {
            if isRecording || phaseIsTooShort {
                HStack(spacing: MLSpacing.s8) {
                    Circle().fill(MLColor.onHero).frame(width: 10, height: 10)
                    Text("\(GuardianCopy.rec) \(clock(elapsed))").font(MLType.monoSecondary)
                }
                .foregroundStyle(MLColor.onHero)
                .padding(.horizontal, MLSpacing.s12)
                .frame(minHeight: 32)
                .background(Capsule().fill(MLColor.heroBackground.opacity(0.8)))
                .padding(MLSpacing.s20)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Text(GuardianCopy.liveVideoOnly)
                .font(MLType.secondary)
                .foregroundStyle(MLColor.onHero.opacity(phase == .tooDark ? 0.5 : 1))
                .padding(.horizontal, MLSpacing.s12)
                .frame(minHeight: 32)
                .background(Capsule().fill(MLColor.heroBackground.opacity(0.85)))
                .padding(MLSpacing.s20)
        }
        .overlay {
            if let warning {
                Label(warning, systemImage: "exclamationmark.triangle")
                    .font(MLType.body)
                    .foregroundStyle(MLColor.ink)
                    .padding(.horizontal, MLSpacing.s16)
                    .frame(minHeight: MLSize.hit)
                    .background(Capsule().fill(MLColor.surface))
            }
        }
        // Shrinks on a small phone so the record button stays on screen.
        .frame(minHeight: 150, maxHeight: 300)
        .layoutPriority(-1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(GuardianCopy.staticPreview)
    }

    private var phaseIsTooShort: Bool {
        if case .tooShort = phase { return true }
        return false
    }

    private var warning: String? {
        switch phase {
        case .tooShort: return GuardianCopy.tooShortChip
        case .tooDark: return GuardianCopy.tooDarkChip
        default: return nil
        }
    }

    private var recordButton: some View {
        Button {
            if isRecording { finish() } else { start() }
        } label: {
            ZStack {
                Circle().stroke(Color.white.opacity(0.25), lineWidth: 5)
                if isRecording || phaseIsTooShort {
                    Circle()
                        .trim(from: 0, to: maxSeconds > 0 ? CGFloat(elapsed) / CGFloat(maxSeconds) : 0)
                        .stroke(MLColor.lime, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    RoundedRectangle(cornerRadius: 6).fill(MLColor.onHero).frame(width: 30, height: 30)
                } else {
                    Circle().fill(MLColor.onHero).padding(10)
                }
            }
            .frame(width: 84, height: 84)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(challenge == nil || model.isWorking)
        .accessibilityLabel(isRecording ? GuardianCopy.stopRecording : GuardianCopy.startRecording)
    }

    private func start() {
        elapsed = 0
        model.startRecording()
        guard runsTimer else { return }
        timer?.cancel()
        timer = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                elapsed += 1
                if elapsed >= maxSeconds {
                    finish()
                    return
                }
            }
        }
    }

    private func finish() {
        stopTimer()
        let seconds = elapsed
        Task { await model.finishRecording(seconds: seconds) }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func clock(_ seconds: Int) -> String { String(format: "%d:%02d", seconds / 60, seconds % 60) }
}

/// The phrase and the code to say (GV-02 on dark, GV-02 Checking on light).
struct GuardianPhraseCard: View {
    let challenge: CaptureChallenge?
    var dark = false
    var eyebrow = GuardianCopy.sayThis

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            Text(eyebrow).font(MLType.body).foregroundStyle(dark ? MLColor.onHeroSecondary : MLColor.inkSecondary)
            Text(challenge?.phrase ?? "—").font(MLType.title2).foregroundStyle(dark ? MLColor.onHero : MLColor.ink)
            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s12) {
                Text(GuardianCopy.code).font(MLType.title2).foregroundStyle(dark ? MLColor.onHero : MLColor.ink)
                Text((challenge?.code ?? "—").map(String.init).joined(separator: " "))
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(dark ? MLColor.lime : MLColor.ink)
            }
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous)
            .fill(dark ? Color.white.opacity(0.12) : MLColor.surface))
        .accessibilityElement(children: .combine)
    }
}

/// Lime corner brackets around a live preview.
struct GuardianCorners: View {
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height, l: CGFloat = 34
            Path { path in
                path.move(to: CGPoint(x: 0, y: l)); path.addLine(to: CGPoint(x: 0, y: 0)); path.addLine(to: CGPoint(x: l, y: 0))
                path.move(to: CGPoint(x: w - l, y: 0)); path.addLine(to: CGPoint(x: w, y: 0)); path.addLine(to: CGPoint(x: w, y: l))
                path.move(to: CGPoint(x: 0, y: h - l)); path.addLine(to: CGPoint(x: 0, y: h)); path.addLine(to: CGPoint(x: l, y: h))
                path.move(to: CGPoint(x: w - l, y: h)); path.addLine(to: CGPoint(x: w, y: h)); path.addLine(to: CGPoint(x: w, y: h - l))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
        }
        .accessibilityHidden(true)
    }
}

/// A numbered step list in a white card (GV-00, GV-02 Camera blocked, GV-04).
struct GuardianSteps: View {
    let steps: [(String, String?)]

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: MLSpacing.s12) {
                    Text("\(index + 1)")
                        .font(MLType.secondary)
                        .foregroundStyle(MLColor.ink)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(MLColor.ink, lineWidth: 1))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.0).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                        if let detail = step.1 {
                            Text(detail).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
    }
}

/// A progress bar card ("Your video · 0:09 64%", "Upload stopped 38%").
struct GuardianProgressCard: View {
    let title: String
    let progress: Double?
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            HStack {
                Text(title).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                Spacer()
                if let progress {
                    Text("\(Int((progress * 100).rounded()))%").font(MLType.monoSecondary).foregroundStyle(MLColor.ink)
                }
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(MLColor.track)
                    if let progress {
                        Capsule().fill(MLColor.ink).frame(width: proxy.size.width * progress)
                    } else {
                        ProgressView().progressViewStyle(.linear).tint(MLColor.ink)
                    }
                }
            }
            .frame(height: 8)
            Text(detail).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Fallback steps

extension GuardianPageView {
    /// GV-02 Camera blocked.
    var cameraBlocked: some View {
        GuardianLayout(model: model, title: GuardianCopy.cameraBlockedTitle, subtitle: GuardianCopy.cameraBlockedDetail,
                       onLanguage: openLanguage) {
            GuardianSteps(steps: GuardianCopy.cameraSteps.map { ($0, nil) })
        } footer: {
            InkActionButton(title: GuardianCopy.openSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            OutlineActionButton(title: GuardianCopy.askWardenToCall) { Task { await model.askWardenToCall() } }
            GuardianFootnote(text: GuardianCopy.noTextOnly)
        }
    }

    /// GV-02 Uploading.
    var uploading: some View {
        GuardianLayout(model: model, title: GuardianCopy.sendingTitle, subtitle: GuardianCopy.sendingDetail,
                       onLanguage: openLanguage) {
            GuardianProgressCard(title: GuardianCopy.yourVideo(duration(model.lastSeconds)), progress: nil,
                                 detail: model.challenge.map {
                                     GuardianCopy.tryCode($0.attempt, $0.attemptsAllowed,
                                                          $0.code.map(String.init).joined(separator: " "))
                                 } ?? "—")
            GuardianOutingFacts(request: model.request)
        } footer: {
            GuardianFootnote(text: GuardianCopy.onlyBlockWarden(model.link?.student.block))
        }
    }

    /// GV-02 Checking.
    var checking: some View {
        GuardianLayout(model: model, title: GuardianCopy.checkingTitle, subtitle: GuardianCopy.checkingDetail,
                       onLanguage: openLanguage) {
            GuardianPhraseCard(challenge: model.challenge, eyebrow: GuardianCopy.youWereAsked)
        } footer: {
            VStack(spacing: MLSpacing.s12) {
                ForEach([GuardianCopy.phrase, GuardianCopy.code, GuardianCopy.number], id: \.self) { item in
                    HStack {
                        Circle().stroke(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                            .frame(width: 22, height: 22)
                        Text(item).font(MLType.staffBody).foregroundStyle(MLColor.ink)
                        Spacer()
                        Text(GuardianCopy.checking).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                    }
                }
            }
            .padding(MLSpacing.s20)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        }
    }

    /// GV-02 Upload failed.
    func uploadFailed(progress: Double, retriesLeft: Int) -> some View {
        let total = 2
        let failed = total - retriesLeft
        return GuardianLayout(model: model, title: GuardianCopy.uploadFailedTitle,
                              subtitle: GuardianCopy.uploadFailedDetail, onLanguage: openLanguage) {
            GuardianProgressCard(title: GuardianCopy.uploadStopped, progress: progress,
                                 detail: GuardianCopy.uploadTryFailed(failed, total))
        } footer: {
            if retriesLeft > 0 {
                InkActionButton(title: GuardianCopy.tryAgainLeft(retriesLeft), isLoading: model.isWorking) {
                    Task { await model.retryUpload() }
                }
                OutlineActionButton(title: GuardianCopy.takePhotoInstead) { Task { await model.takePhotoInstead() } }
            } else {
                InkActionButton(title: GuardianCopy.takePhotoInstead, isLoading: model.isWorking) {
                    Task { await model.takePhotoInstead() }
                }
            }
            GuardianFootnote(text: GuardianCopy.photoAfterTwo)
        }
    }

    /// GV-03 Retry.
    func retry(heard: String, missing: String, nextAttempt: Int) -> some View {
        GuardianLayout(model: model, title: GuardianCopy.couldntHear, subtitle: GuardianCopy.speakClearly,
                       onLanguage: openLanguage) {
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                Text(GuardianCopy.whatWeHeard).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                Text("“\(heard)”").font(MLType.staffBody).foregroundStyle(MLColor.ink)
                OutingTag(text: GuardianCopy.missing(missing), style: .dashed)
            }
            .padding(MLSpacing.s20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        } footer: {
            InkActionButton(title: GuardianCopy.recordAgain(nextAttempt, model.challenge?.attemptsAllowed ?? 3),
                            isLoading: model.isWorking) {
                Task { await model.recordAgain() }
            }
            GuardianFootnote(text: GuardianCopy.afterThreeTries)
        }
    }

    /// GV-04 Send video to the warden.
    var sendVideo: some View {
        GuardianLayout(model: model, title: GuardianCopy.stillCouldnt, subtitle: GuardianCopy.canStillGo,
                       onLanguage: openLanguage) {
            GuardianSteps(steps: GuardianCopy.sendSteps.map { ($0, nil) })
            OutingVideoTile(mode: .ready, height: 200, label: GuardianCopy.yourRecording(duration(model.lastSeconds)))
        } footer: {
            InkActionButton(title: GuardianCopy.sendVideo, isLoading: model.isWorking) {
                Task { await model.sendForReview() }
            }
            GuardianFootnote(text: GuardianCopy.noMoreTries)
        }
    }

    func duration(_ seconds: Int) -> String { String(format: "%d:%02d", seconds / 60, seconds % 60) }
}

/// GV-05 Photo and code: a live photo (a still placeholder in the prototype), the typed phrase and the SMS code.
struct GuardianPhotoStep: View {
    let model: GuardianModel
    let challenge: PhotoChallenge
    let onLanguage: () -> Void
    var initialTyped = ""
    var initialCode = ""

    @State private var typed = ""
    @State private var code = DigitEntry()
    @FocusState private var codeFocused: Bool

    private func entry(from text: String) -> DigitEntry {
        var made = DigitEntry()
        made.length = challenge.codeLength
        for character in text.filter(\.isNumber).prefix(challenge.codeLength) {
            if let digit = Int(String(character)) { made.append(digit) }
        }
        return made
    }

    var body: some View {
        GuardianLayout(model: model, title: GuardianCopy.didntUpload, subtitle: GuardianCopy.takePhoto,
                       onLanguage: onLanguage) {
            ZStack {
                RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.heroBackground)
                FacePlaceholder()
                GuardianCorners(color: MLColor.lime)
            }
            .overlay(alignment: .bottomTrailing) {
                Text(GuardianCopy.livePhotoOnly)
                    .font(MLType.secondary).foregroundStyle(MLColor.onHero)
                    .padding(.horizontal, MLSpacing.s12).frame(minHeight: 32)
                    .background(Capsule().fill(MLColor.heroBackground))
                    .padding(MLSpacing.s16)
            }
            .frame(height: 220)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(GuardianCopy.staticPreview)
            Text(GuardianCopy.typeExactly).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            TextField(challenge.typedPhrase, text: $typed)
                .font(MLType.staffBody)
                .autocorrectionDisabled()
                .padding(.horizontal, MLSpacing.s16)
                .frame(minHeight: 56)
                .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
                .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).stroke(MLColor.ink, lineWidth: 1.2))
                .accessibilityLabel(GuardianCopy.typeExactly)
            Text(GuardianCopy.codeSentTo(challenge.sentTo ?? "—")).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            DigitBoxes(entry: code, accessibilityTitle: GuardianCopy.codeSentTo(challenge.sentTo ?? "—"))
                .onTapGesture { codeFocused = true }
            TextField("", text: Binding(get: { code.text }, set: { code = entry(from: $0) }))
            .keyboardType(.numberPad)
            .focused($codeFocused)
            .frame(width: 1, height: 1)
            .opacity(0.02)
            .accessibilityHidden(true)
            if let error = model.actionError {
                FieldErrorText(text: error)
            }
        } footer: {
            InkActionButton(title: GuardianCopy.sendPhotoAndCode, isLoading: model.isWorking) {
                Task { await model.sendPhoto(typed: typed, phoneCode: code.text) }
            }
            .disabled(typed.isEmpty || !code.isComplete)
            GuardianFootnote(text: GuardianCopy.wardenSeesPhoto)
        }
        .task {
            if typed.isEmpty { typed = initialTyped }
            if code.digits.isEmpty { code = entry(from: initialCode) }
        }
    }
}
