import SwiftUI

// Feedback · Which dish (2159:285), Which dish · More dishes (2159:471), What's wrong · Sambar (2159:149347), Pongal
// (2159:149553), Millet Idli (2159:149760), Masala Omelet (2159:149968), Milk (2159:150172), What's wrong · Sambar ·
// Note (2159:150369), Sending (2159:150579), Sent (2159:150785), Failed (2159:150911), Offline · Saved (2159:151121)
// and Thanks (2159:159). Each is a sheet over the screen that opened it, sized to its content.

/// Words of the Feedback sheets. Wording only.
enum DishFeedbackCopy {
    static let whichDish = "Which dish?"
    static func about(_ slot: MealSlot) -> String { "About \(MLFormat.mealSlot(slot).lowercased()) · Not good" }
    static let mostReported = "Most reported today"
    static func studentsSaid(_ count: Int) -> String { count == 1 ? "1 student said this" : "\(count) students said this" }
    static let meToo = "Me too"
    static let orPick = "Or pick the dish"
    static let moreDishes = "More dishes"
    static let service = "Service"
    static let community = "Community"
    static let useCommunity = "Waiting, cleanliness, staff: use Community."
    static let whatsWrong = "What's wrong?"
    static let howBad = "How bad?"
    static func severity(_ severity: DishFeedbackSeverity) -> String {
        switch severity {
        case .aBit: return "A bit"
        case .quite: return "Quite"
        case .very: return "Very"
        }
    }
    static func others(_ count: Int) -> String { count == 1 ? "1 other" : "\(count) others" }
    static let addNote = "Add a note (optional)"
    static let note = "Note (optional)"
    static let send = "Send"
    static let sending = "Sending…"
    static let tryAgain = "Try again"
    static let couldntSend = "Couldn't send. Try again"
    static let offlineSaved = "You're offline. Saved. Will send."
    static let neverYourName = "The kitchen sees the dish, the problem and how bad. Never your name."
    static let useSOS = "Unsafe or unwell? Use SOS"
    static let sent = "Sent"
    /// The frame says "The kitchen saw it"; the prototype sends to no one, so it says only that it was sent.
    static let sentTitle = "Sent"
    static func receipt(_ dish: String, _ problem: String, _ severity: DishFeedbackSeverity) -> String {
        "\(dish) · \(problem) · \(Self.severity(severity))"
    }
    static func sentAt(_ time: String) -> String { "Sent \(time)" }
    static let seeInMyFeedback = "See it in My feedback"
    static let done = "Done"
    static let thanks = "Thanks"
    /// The frame says "The kitchen saw it."; the prototype records the rating and tells no one, so it says that.
    static let ratingSaved = "Your rating is saved."
    static func goodAt(_ slot: MealSlot, _ time: String) -> String { "\(MLFormat.mealSlot(slot)) · Good · \(time)" }
    static let back = "Back"
}

/// Hosts the flow for a request, building its view model from the environment.
struct StudentDishFeedbackSheet: View {
    @State private var model: StudentDishFeedbackViewModel
    let onClose: () -> Void
    let onSOS: () -> Void
    var onCommunity: (() -> Void)?
    var onMyFeedback: (() -> Void)?

    init(model: StudentDishFeedbackViewModel, onClose: @escaping () -> Void, onSOS: @escaping () -> Void,
         onCommunity: (() -> Void)? = nil, onMyFeedback: (() -> Void)? = nil) {
        _model = State(initialValue: model)
        self.onClose = onClose
        self.onSOS = onSOS
        self.onCommunity = onCommunity
        self.onMyFeedback = onMyFeedback
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            switch model.step {
            case .whichDish: whichDish
            case .whatsWrong(let dish): whatsWrong(dish)
            case .sent(let receipt): sent(receipt)
            case .thanks(let at): thanks(at)
            }
        }
        .mlAnimation(.snappy, value: model.step)
        .task { await model.load() }
    }

    // MARK: Header

    private func header(back: Bool, dish: String?, title: String) -> some View {
        HStack(spacing: MLSpacing.s12) {
            if back {
                StudentGlassButton(symbol: "chevron.left", label: DishFeedbackCopy.back) { model.back() }
            }
            if let dish {
                Image(StudentPictogram.asset(for: dish))
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(MLColor.ink)
                    .frame(width: 36, height: 36)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(dish == nil && !back ? StudentType.section : StudentType.heroTitle)
                .foregroundStyle(MLColor.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: MLSpacing.s8)
            SheetCloseButton(action: onClose)
                .disabled(model.isSending)
        }
    }

    private var sosLink: some View {
        Button(DishFeedbackCopy.useSOS, action: onSOS)
            .font(StudentType.secondaryMedium)
            .foregroundStyle(MLColor.ink)
            .underline()
            .frame(maxWidth: .infinity, minHeight: MLSize.hit)
            .buttonStyle(.plain)
    }

    // MARK: Which dish

    private var whichDish: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            header(back: false, dish: nil, title: DishFeedbackCopy.whichDish)
            Text(DishFeedbackCopy.about(model.slot))
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
            if let top = model.mostReported {
                Text(DishFeedbackCopy.mostReported).font(StudentType.secondaryMedium).foregroundStyle(MLColor.inkSecondary)
                VStack(alignment: .leading, spacing: MLSpacing.s8) {
                    Text(RecordsCopy.dishProblem(top.dishName, top.problem))
                        .font(StudentType.section)
                        .foregroundStyle(MLColor.ink)
                    Text(DishFeedbackCopy.studentsSaid(top.students))
                        .font(StudentType.secondary)
                        .foregroundStyle(MLColor.inkSecondary)
                    PassBottomButton(title: DishFeedbackCopy.meToo) {
                        let dish = model.dishes.first { StudentDishFeedbackSheet.same($0.name, top.dishName) }?.name ?? top.dishName
                        Task { await model.choose(dish: dish, problem: top.problem) }
                    }
                    .padding(.top, MLSpacing.s4)
                }
                .padding(MLSpacing.s16)
                .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
                .overlay(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous)
                    .strokeBorder(MLColor.ink, lineWidth: 1.5))
            }
            Text(DishFeedbackCopy.orPick).font(StudentType.secondaryMedium).foregroundStyle(MLColor.inkSecondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MLSpacing.s12), count: 3),
                      spacing: MLSpacing.s12) {
                ForEach(model.visibleDishes) { dish in
                    dishTile(dish)
                }
                if model.hasMoreDishes {
                    dashedTile(symbol: "plus", title: DishFeedbackCopy.moreDishes, detail: nil, dashed: false) {
                        model.showMoreDishes()
                    }
                }
                if let onCommunity {
                    dashedTile(symbol: nil, title: DishFeedbackCopy.service, detail: DishFeedbackCopy.community + " ›",
                               dashed: true, action: onCommunity)
                }
            }
            Text(DishFeedbackCopy.useCommunity)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            sosLink
        }
    }

    static func same(_ a: String, _ b: String) -> Bool {
        let a = a.lowercased(), b = b.lowercased()
        return a == b || a.contains(b) || b.contains(a)
    }

    private func dishTile(_ dish: Dish) -> some View {
        Button {
            Task { await model.choose(dish: dish.name) }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    StudentDietMark(diet: dish.diet, onDark: false)
                    Spacer(minLength: 0)
                    Image(StudentPictogram.asset(for: dish.name))
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(MLColor.ink)
                        .frame(width: 32, height: 32)
                        .accessibilityHidden(true)
                }
                Spacer(minLength: MLSpacing.s8)
                Text(dish.name)
                    .font(StudentType.dishName)
                    .foregroundStyle(MLColor.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(MLSpacing.s12)
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: StudentMetric.tileRadius, style: .continuous).fill(MLColor.surface))
            .overlay(RoundedRectangle(cornerRadius: StudentMetric.tileRadius, style: .continuous)
                .strokeBorder(MLColor.border, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dish.name)
    }

    private func dashedTile(symbol: String?, title: String, detail: String?, dashed: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: MLSpacing.s4) {
                if let symbol {
                    Image(systemName: symbol).font(StudentType.section).accessibilityHidden(true)
                }
                Text(title).font(StudentType.dishName)
                if let detail {
                    Text(detail).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
                }
            }
            .foregroundStyle(MLColor.ink)
            .frame(maxWidth: .infinity, minHeight: 104)
            .background(RoundedRectangle(cornerRadius: StudentMetric.tileRadius, style: .continuous)
                .fill(dashed ? MLColor.surface : MLColor.fillQuiet))
            .overlay(RoundedRectangle(cornerRadius: StudentMetric.tileRadius, style: .continuous)
                .strokeBorder(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1, dash: dashed ? [4, 4] : [])))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: What's wrong

    private func whatsWrong(_ dish: String) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            header(back: model.canGoBack, dish: dish, title: dish)
            if model.sendState == .keptOffline {
                StudentOfflineBanner(text: DishFeedbackCopy.offlineSaved)
                    .mlTransition(.fromTop)
            }
            Text(DishFeedbackCopy.whatsWrong).font(StudentType.secondaryMedium).foregroundStyle(MLColor.inkSecondary)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: MLSpacing.s12), GridItem(.flexible())], spacing: MLSpacing.s12) {
                ForEach(model.options) { option in
                    ProblemTile(option: option, others: model.others(option), selected: model.problem == option.title) {
                        model.problem = option.title
                    }
                }
            }
            .disabled(model.isSending)
            Text(DishFeedbackCopy.howBad).font(StudentType.secondaryMedium).foregroundStyle(MLColor.inkSecondary)
            SeverityControl(value: $model.severity)
                .disabled(model.isSending)
            whatsWrongBottom
        }
        .mlAnimation(.snappy, value: model.sendState)
        .mlAnimation(.snappy, value: model.showsNote)
    }

    @ViewBuilder
    private var whatsWrongBottom: some View {
            if model.showsNote {
                VStack(alignment: .leading, spacing: MLSpacing.s4) {
                    Text(DishFeedbackCopy.note).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
                    TextField(DishFeedbackCopy.note, text: $model.note, axis: .vertical)
                        .font(StudentType.body)
                        .lineLimit(2...4)
                        .submitLabel(.done)
                        .padding(MLSpacing.s12)
                        .background(RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous).fill(MLColor.surface))
                        .overlay(RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous)
                            .strokeBorder(MLColor.border, lineWidth: 1))
                }
                .mlTransition(.fade)
            } else {
                Button(DishFeedbackCopy.addNote) { model.showsNote = true }
                    .font(StudentType.secondaryMedium)
                    .foregroundStyle(MLColor.ink)
                    .underline()
                    .frame(minHeight: MLSize.hit)
                    .buttonStyle(.plain)
            }
            if model.sendState == .failed {
                HStack(spacing: MLSpacing.s8) {
                    Image(systemName: "exclamationmark.triangle").accessibilityHidden(true)
                    Text(DishFeedbackCopy.couldntSend).font(StudentType.bodySemibold)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(MLColor.danger)
                .padding(MLSpacing.s16)
                .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(StudentTint.errorFill))
                .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
                    .strokeBorder(MLColor.danger.opacity(0.4), lineWidth: 1))
                .accessibilityElement(children: .combine)
                .mlTransition(.fade)
            }
            PassBottomButton(title: sendTitle) {
                Task { _ = await model.send() }
            }
            .disabled(!model.canSend)
            .opacity(model.canSend || model.isSending ? 1 : 0.4)
            .sensoryFeedback(.warning, trigger: model.sendState) { _, new in new == .failed }
            Text(DishFeedbackCopy.neverYourName)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
            sosLink
    }

    private var sendTitle: String {
        switch model.sendState {
        case .sending: return DishFeedbackCopy.sending
        case .failed: return DishFeedbackCopy.tryAgain
        default: return DishFeedbackCopy.send
        }
    }

    // MARK: Sent and Thanks

    private func sent(_ receipt: DishFeedbackReceipt) -> some View {
        VStack(spacing: MLSpacing.s12) {
            header(back: false, dish: nil, title: DishFeedbackCopy.sent)
            confirmation(title: DishFeedbackCopy.sentTitle, lines: sentLines(receipt))
            if let onMyFeedback {
                Button(action: onMyFeedback) {
                    Text(DishFeedbackCopy.seeInMyFeedback)
                        .font(StudentType.secondaryMedium)
                        .foregroundStyle(MLColor.ink)
                        .underline()
                        .frame(minHeight: MLSize.hit)
                }
                .buttonStyle(.plain)
            }
            PassBottomButton(title: DishFeedbackCopy.done, action: onClose)
        }
        .sensoryFeedback(.success, trigger: receipt.sentAt)
    }

    private func sentLines(_ receipt: DishFeedbackReceipt) -> [String] {
        let submission = receipt.submission
        return [DishFeedbackCopy.receipt(submission.dishName, submission.problem, submission.severity),
                DishFeedbackCopy.sentAt(MLFormat.time(receipt.sentAt, in: model.timeZone))]
    }

    private func thanks(_ at: Date) -> some View {
        VStack(spacing: MLSpacing.s12) {
            header(back: false, dish: nil, title: DishFeedbackCopy.thanks)
            confirmation(title: DishFeedbackCopy.thanks, lines: [
                DishFeedbackCopy.ratingSaved,
                DishFeedbackCopy.goodAt(model.slot, MLFormat.time(at, in: model.timeZone)),
            ])
            PassBottomButton(title: DishFeedbackCopy.done, action: onClose)
                .padding(.top, MLSpacing.s8)
        }
    }

    private func confirmation(title: String, lines: [String]) -> some View {
        VStack(spacing: MLSpacing.s8) {
            Image(systemName: "checkmark")
                .font(StudentType.section)
                .foregroundStyle(MLColor.onLime)
                .frame(width: 88, height: 44)
                .background(Capsule().fill(MLColor.lime))
                .overlay(Capsule().strokeBorder(MLColor.limeOutline, lineWidth: 1.5))
                .accessibilityHidden(true)
            Text(title)
                .font(StudentType.heroTitle)
                .foregroundStyle(MLColor.ink)
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                Text(line)
                    .font(index == 0 ? StudentType.secondary : StudentType.footnote)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// ProblemTile 2136:2360: glyph, the problem, and how many others said it. Selected = lime with an ink outline.
private struct ProblemTile: View {
    let option: DishProblemOption
    let others: Int?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s12) {
                Image("student-problem-\(option.glyph.rawValue)")
                    .renderingMode(.template)
                    .foregroundStyle(MLColor.ink)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(MLColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let others {
                        Text(DishFeedbackCopy.others(others))
                            .font(StudentType.footnote)
                            .foregroundStyle(selected ? MLColor.onLime : MLColor.inkSecondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.leading, MLSpacing.s16)
            .padding(.trailing, MLSpacing.s12)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous)
                .fill(selected ? MLColor.lime : MLColor.surface))
            .overlay(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous)
                .strokeBorder(selected ? MLColor.limeOutline : MLColor.border, lineWidth: selected ? 2 : 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: selected) { _, new in new }
    }
}

/// SeveritySegmented 2136:2382: A bit / Quite / Very on a track; the chosen one is a black pill.
private struct SeverityControl: View {
    @Binding var value: DishFeedbackSeverity

    var body: some View {
        HStack(spacing: 2) {
            ForEach(DishFeedbackSeverity.allCases, id: \.self) { severity in
                Button { value = severity } label: {
                    Text(DishFeedbackCopy.severity(severity))
                        .font(value == severity ? StudentType.bodySemibold : StudentType.body)
                        .foregroundStyle(value == severity ? MLColor.onHero : MLColor.inkSecondary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Capsule().fill(value == severity ? MLColor.ink : .clear))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(value == severity ? .isSelected : [])
            }
        }
        .padding(MLSpacing.s4)
        .background(Capsule().fill(MLColor.track))
        .mlAnimation(.snappy, value: value)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(DishFeedbackCopy.howBad)
    }
}

extension View {
    /// Presents the dish feedback flow for `request`. Nothing here opens Report; `onSOS` is the only way to SOS.
    func studentDishFeedback(_ request: Binding<StudentDishFeedbackRequest?>, context: StudentContext?,
                             repositories: Repositories, clock: any AppClock, onSOS: @escaping () -> Void,
                             onCommunity: (() -> Void)? = nil, onMyFeedback: (() -> Void)? = nil,
                             onClosed: (() -> Void)? = nil) -> some View {
        mlSheet(item: request, onDismiss: onClosed) { value in
            if let context {
                StudentDishFeedbackSheet(
                    model: StudentDishFeedbackViewModel(context: context, repositories: repositories, clock: clock, request: value),
                    onClose: { request.wrappedValue = nil },
                    onSOS: { request.wrappedValue = nil; onSOS() },
                    onCommunity: onCommunity.map { go in { request.wrappedValue = nil; go() } },
                    onMyFeedback: onMyFeedback.map { go in { request.wrappedValue = nil; go() } })
            }
        }
    }
}
