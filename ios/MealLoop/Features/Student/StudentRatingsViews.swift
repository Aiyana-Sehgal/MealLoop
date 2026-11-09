import Observation
import SwiftUI

// How was lunch? (image student_feedback_01_how_was_lunch) and Rate a dish (student_feedback_02_rate_a_dish), the
// owner's design of 7 November 2026; no Figma frame. Proportions and wording from the images, colours and sizes from
// the tokens. Rules are in `StudentRatings.swift` (owner to confirm).

// Report · From feedback (221:63738) is superseded: Not good opens the dish feedback sheets (owner, 9 November).

/// Words of the rating images. Wording only.
enum RatingCopy {
    static let good = "Good"
    static let notGood = "Not good"
    static let itWasFine = "It was fine"
    static let tellUs = "Tell us what was wrong"
    /// Not good opens What's wrong (Feedback · Which dish 2159:285, What's wrong 2159:149347), never the Report form.
    static let notGoodOpensForm = "Not good asks which dish and what was wrong."
    static let notGoodOpensFormDish = "Not good asks what was wrong with this dish."
    static let skipForNow = "Skip for now"
    static let done = "Done"
    static let rated = "You said Good. Thanks."
    static func notYet(_ slot: MealSlot) -> String { "You can rate \(MLFormat.mealSlot(slot).lowercased()) after it ends." }
    static func closed(_ slot: MealSlot) -> String {
        "Ratings for \(MLFormat.mealSlot(slot).lowercased()) closed 2 days after it ended."
    }
    static let didNotSave = "Didn't save. Try again."
    static func dayAndMess(_ day: String, _ mess: String) -> String { "\(day) · \(mess)" }
    static func slotAndDay(_ slot: MealSlot, _ day: String) -> String { "\(MLFormat.mealSlot(slot)) · \(day)" }
}

// MARK: - View model

@MainActor
@Observable
final class StudentRatingViewModel {
    enum Write: Equatable { case idle, saving, failed }

    let target: StudentRatingTarget
    let context: StudentContext
    private(set) var window: StudentRatingWindow?
    private(set) var rating: StudentRating?
    private(set) var write: Write = .idle
    /// The dish name, once loaded (Rate a dish).
    var dishName: String?

    private let ratings: any FeedbackRatingRepository

    init?(session: Session, repositories: Repositories, day: Date, slot: MealSlot, dish: DishID? = nil) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.ratings = repositories.feedbackRatings
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = context.mess.timeZone
        target = StudentRatingTarget(day: calendar.startOfDay(for: day), slot: slot, dish: dish)
    }

    var timeZone: TimeZone { context.mess.timeZone }
    var isGood: Bool { rating != nil }
    var canRate: Bool { window?.isOpen == true && write != .saving }

    /// What Good (Thanks) or Not good (Which dish, or this dish's What's wrong) opens next.
    func feedbackRequest(after answer: StudentRatingAnswer) -> StudentDishFeedbackRequest {
        switch answer {
        case .good: return StudentDishFeedbackRequest(day: target.day, slot: target.slot, kind: .thanks)
        case .notGood:
            if target.dish != nil, let dishName {
                return StudentDishFeedbackRequest(day: target.day, slot: target.slot, kind: .dish(dishName))
            }
            return StudentDishFeedbackRequest(day: target.day, slot: target.slot, kind: .meal)
        }
    }

    func load() async {
        window = try? await ratings.ratingWindow(day: target.day, slot: target.slot, at: context.mess.id)
        rating = try? await ratings.myRating(target, for: context.student.id)
    }

    /// True when the repository recorded the answer (Not good records nothing but takes back a Good).
    @discardableResult
    func rate(_ answer: StudentRatingAnswer) async -> Bool {
        write = .saving
        do {
            rating = if let dish = target.dish {
                try await ratings.rateDish(dish, day: target.day, slot: target.slot, answer, at: context.mess.id,
                                           for: context.student.id)
            } else {
                try await ratings.rateMeal(day: target.day, slot: target.slot, answer, at: context.mess.id,
                                           for: context.student.id)
            }
            write = .idle
            return true
        } catch {
            write = .failed
            return false
        }
    }
}

// MARK: - Home card

/// The card on Home after a meal: How was lunch?, Good, Not good and Skip for now. The title opens the full page.
struct StudentHowWasCard: View {
    let slot: MealSlot
    let onOpen: () -> Void
    let onGood: () -> Void
    let onNotGood: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Button(action: onOpen) {
                HStack {
                    Text(StudentCopy.howWas(slot)).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                    Spacer(minLength: MLSpacing.s8)
                    Image(systemName: "chevron.right").font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: MLSize.hit)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            HStack(spacing: MLSpacing.s12) {
                RatingPill(symbol: "hand.thumbsup", title: RatingCopy.good, filled: true, action: onGood)
                RatingPill(symbol: "hand.thumbsdown", title: RatingCopy.notGood, filled: false, action: onNotGood)
            }
            Button(RatingCopy.skipForNow, action: onSkip)
                .font(StudentType.secondaryMedium)
                .foregroundStyle(MLColor.inkSecondary)
                .underline()
                .frame(maxWidth: .infinity, minHeight: MLSize.hit)
        }
        .padding(.horizontal, MLSpacing.s20)
        .padding(.vertical, MLSpacing.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
    }
}

private struct RatingPill: View {
    let symbol: String
    let title: String
    let filled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(StudentType.bodySemibold)
                .foregroundStyle(filled ? MLColor.onLime : MLColor.ink)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Capsule().fill(filled ? MLColor.lime : MLColor.surface))
                .overlay(Capsule().strokeBorder(MLColor.ink, lineWidth: filled ? 1 : 1.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - How was lunch?

/// The full page (student_feedback_01_how_was_lunch). Good shows Thanks (2159:159); Not good opens Which dish
/// (2159:285). Only "Unsafe or unwell? Use SOS" leads from there to SOS.
struct StudentRateMealView: View {
    @Environment(AppEnvironment.self) private var environment
    @State var model: StudentRatingViewModel
    @State private var feedback: StudentDishFeedbackRequest?
    @State private var doneAfterThanks = false
    let onSOS: () -> Void
    var onMyFeedback: (() -> Void)?
    let onDone: () -> Void

    var body: some View {
        MLScreen(StudentCopy.howWas(model.target.slot),
                 subtitle: RatingCopy.dayAndMess(StudentFormat.mediumDay(model.target.day, in: model.timeZone),
                                                 model.context.mess.name),
                 bottomClearance: .tabBar) {
            VStack(spacing: MLSpacing.s16) {
                RatingChoiceRow(symbol: "hand.thumbsup", title: RatingCopy.good, detail: RatingCopy.itWasFine,
                                accent: true, selected: model.isGood) {
                    Task {
                        if await model.rate(.good) {
                            doneAfterThanks = true
                            feedback = model.feedbackRequest(after: .good)
                        }
                    }
                }
                RatingChoiceRow(symbol: "hand.thumbsdown", title: RatingCopy.notGood, detail: RatingCopy.tellUs,
                                accent: false, selected: false) {
                    Task { if await model.rate(.notGood) { feedback = model.feedbackRequest(after: .notGood) } }
                }
                RatingStatusLine(model: model, helper: RatingCopy.notGoodOpensForm)
                Button(RatingCopy.skipForNow, action: onDone)
                    .font(StudentType.body)
                    .foregroundStyle(MLColor.ink)
                    .underline()
                    .frame(minHeight: MLSize.hit)
                    .padding(.top, MLSpacing.s24)
            }
            .disabled(!model.canRate)
        }
        .task { await model.load() }
        .sensoryFeedback(.success, trigger: model.isGood) { _, good in good }
        .studentDishFeedback($feedback, context: model.context, repositories: environment.repositories,
                             clock: environment.clock, onSOS: onSOS, onMyFeedback: onMyFeedback) {
            if doneAfterThanks {
                doneAfterThanks = false
                onDone()
            }
        }
    }
}

private struct RatingChoiceRow: View {
    let symbol: String
    let title: String
    let detail: String
    let accent: Bool
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s16) {
                Image(systemName: symbol)
                    .font(StudentType.section)
                    .foregroundStyle(MLColor.ink)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(accent ? MLColor.lime : MLColor.fillQuiet))
                    .overlay(Circle().strokeBorder(accent ? MLColor.ink : .clear, lineWidth: 1))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: MLSpacing.s4) {
                    Text(title).font(StudentType.section).foregroundStyle(MLColor.ink)
                    Text(detail).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: MLSpacing.s8)
                Image(systemName: selected ? "checkmark.circle.fill" : "chevron.right")
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(selected ? MLColor.ink : MLColor.inkSecondary)
                    .accessibilityHidden(true)
            }
            .padding(MLSpacing.s20)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
            .overlay(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous)
                .strokeBorder(selected ? MLColor.ink : .clear, lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// The helper line, or why the meal can't be rated now, or the failure.
private struct RatingStatusLine: View {
    let model: StudentRatingViewModel
    let helper: String

    var body: some View {
        Group {
            if model.write == .failed {
                FieldErrorText(text: RatingCopy.didNotSave)
            } else {
                switch model.window {
                case .notYet: Text(RatingCopy.notYet(model.target.slot))
                case .closed: Text(RatingCopy.closed(model.target.slot))
                default: Text(helper)
                }
            }
        }
        .font(StudentType.secondary)
        .foregroundStyle(MLColor.inkSecondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, MLSpacing.s8)
    }
}

// MARK: - Rate a dish

/// Rate a dish (student_feedback_02_rate_a_dish), from the dish page in Meals and from Search. Good shows Thanks
/// (2159:159); Not good opens this dish's What's wrong (2159:149347) straight away, never the Report form.
struct StudentRateDishView: View {
    @Environment(AppEnvironment.self) private var environment
    @State var model: StudentRatingViewModel
    @State private var feedback: StudentDishFeedbackRequest?
    let loadDish: () async throws -> StudentDishDetail
    let onSOS: () -> Void
    var onMyFeedback: (() -> Void)?
    let onDone: () -> Void

    var body: some View {
        MLScreen(nil) {
            VStack(spacing: MLSpacing.s24) {
                VStack(spacing: MLSpacing.s12) {
                    Image(systemName: "fork.knife")
                        .font(StudentType.heroTitle)
                        .foregroundStyle(MLColor.ink)
                        .frame(width: 128, height: 128)
                        .background(Circle().fill(MLColor.fillQuiet))
                        .accessibilityHidden(true)
                    Text(model.dishName ?? " ")
                        .font(MLType.largeTitle)
                        .foregroundStyle(MLColor.ink)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text(RatingCopy.slotAndDay(model.target.slot, StudentFormat.mediumDay(model.target.day, in: model.timeZone)))
                        .font(StudentType.secondary)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, MLSpacing.s24)
                HStack(spacing: MLSpacing.s16) {
                    tile(symbol: "hand.thumbsup", title: RatingCopy.good, accent: true, selected: model.isGood) {
                        Task { if await model.rate(.good) { feedback = model.feedbackRequest(after: .good) } }
                    }
                    tile(symbol: "hand.thumbsdown", title: RatingCopy.notGood, accent: false, selected: false) {
                        Task { if await model.rate(.notGood) { feedback = model.feedbackRequest(after: .notGood) } }
                    }
                }
                .disabled(!model.canRate)
                RatingStatusLine(model: model, helper: RatingCopy.notGoodOpensFormDish)
            }
        } bottom: {
            InkActionButton(title: RatingCopy.done, action: onDone)
                .studentAboveTabBar()
        }
        .task {
            if model.dishName == nil { model.dishName = try? await loadDish().dish.name }
            await model.load()
        }
        .sensoryFeedback(.success, trigger: model.isGood) { _, good in good }
        .studentDishFeedback($feedback, context: model.context, repositories: environment.repositories,
                             clock: environment.clock, onSOS: onSOS, onMyFeedback: onMyFeedback)
    }

    private func tile(symbol: String, title: String, accent: Bool, selected: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: MLSpacing.s12) {
                Image(systemName: symbol)
                    .font(StudentType.section)
                    .foregroundStyle(MLColor.ink)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(accent ? MLColor.lime : MLColor.fillQuiet))
                    .overlay(Circle().strokeBorder(accent ? MLColor.ink : .clear, lineWidth: 1))
                    .accessibilityHidden(true)
                Text(title).font(StudentType.section).foregroundStyle(MLColor.ink)
            }
            .frame(maxWidth: .infinity, minHeight: 168)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
            .overlay(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous)
                .strokeBorder(selected ? MLColor.ink : .clear, lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
