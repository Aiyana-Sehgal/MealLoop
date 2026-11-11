import Observation
import SwiftUI
import UIKit

// Swipe-to-remind on Student Home (Figma file nzzTAm9YnJRSdKEeYUWUEb, page 07): Home · Not answered · Swipe revealed
// (2222:158038), Reminder set (2222:158135), Reminder fired (2222:158236), and the same three for the lunch row: Home ·
// Lunch row · Swipe revealed (2222:158351), Reminder set (2222:158445), Reminder fired (2222:158543). Home · Not answered
// (221:62529) is the card before the swipe.
// Rules: the reminder is local and simulated (nothing is sent to anyone); it fires when the app's story clock reaches
// now + 1 hour, never on a real timer; it never extends the answer cutoff, so the swipe is not offered when now + 1 hour
// is at or after the cutoff; answering the meal cancels it; one per meal, a second replaces the first; no credits.

/// Words of the reminder frames. Wording only.
enum ReminderCopy {
    static let remindMe = "Remind me in 1 hr"
    /// The accessibility action and context-menu item: the same action as the swipe.
    static let remindAction = "Remind me in 1 hour"
    static let reminderSet = "Reminder set"
    static func askAgain(_ time: String) -> String { "We'll ask again at \(time)" }
    static let undo = "Undo"
    static let reminder = "Reminder"
    static func setLabel(_ time: String) -> String { "Reminder set, we'll ask again at \(time)" }
}

/// Where a meal's reminder stands on Home.
enum StudentReminderState: Equatable {
    case none
    /// Set; the card is replaced by the Reminder set row until `at`.
    case set(at: Date)
    /// The hour is up: the card is back with the Reminder chip.
    case fired
}

/// The student's local reminders, one per meal. Owned by the Student root so they outlive a tab switch. Nothing here
/// is sent or stored anywhere else.
@MainActor
@Observable
final class StudentMealReminders {
    static let delay: TimeInterval = 60 * 60

    private(set) var times: [MealID: Date] = [:]

    /// The swipe is offered only for an open, unanswered meal whose cutoff is still more than an hour away.
    func canOffer(_ card: StudentMealCard, now: Date) -> Bool {
        card.isAnswerOpen && card.answer == nil && now.addingTimeInterval(Self.delay) < card.cutoff
    }

    /// Sets (or replaces) the meal's reminder at now + 1 hour. Nil when it is not offered.
    @discardableResult
    func set(_ card: StudentMealCard, now: Date) -> Date? {
        guard canOffer(card, now: now) else { return nil }
        let at = now.addingTimeInterval(Self.delay)
        times[card.id] = at
        return at
    }

    func undo(_ meal: MealID) { times[meal] = nil }

    /// Read from the clock each time Home draws or reloads: fired once the clock reaches the time. An answered meal
    /// has no reminder.
    func state(for card: StudentMealCard, now: Date) -> StudentReminderState {
        guard card.answer == nil, let at = times[card.id] else { return .none }
        return now >= at ? .fired : .set(at: at)
    }

    /// Answering cancels the meal's reminder.
    func cancelAnswered(_ cards: [StudentMealCard]) {
        for card in cards where card.answer != nil { times[card.id] = nil }
    }
}

/// Drag right to reveal the lime "Remind me in 1 hr" panel; letting go past a third of the width sets the reminder,
/// before it springs back. Horizontal only, and never from the left 20 pt edge, so the system swipe-back and the
/// vertical scroll keep working. Under Reduce Motion the card does not move: the panel cross-fades in instead.
struct StudentRemindSwipe<Content: View>: View {
    let enabled: Bool
    let radius: CGFloat
    let onRemind: () -> Void
    @ViewBuilder let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offset: CGFloat = 0
    @State private var width: CGFloat = 0
    /// Decided on the first movement: true when the drag is horizontal and did not start at the screen edge.
    @State private var tracking: Bool?
    @State private var crossed = false

    private static var edge: CGFloat { MLSpacing.s20 }
    private var threshold: CGFloat { max(width / 3, MLSize.hit) }

    var body: some View {
        content
            .offset(x: reduceMotion ? 0 : offset)
            .background(alignment: .leading) {
                if enabled && (offset > 0 || crossed) {
                    panel.opacity(reduceMotion ? (crossed ? 1 : 0) : 1)
                }
            }
            .background {
                GeometryReader { proxy in Color.clear.onAppear { width = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, new in width = new } }
            }
            .modifier(RemindSwipeGesture(enabled: enabled, edge: Self.edge, drag: drag,
                                         onChanged: { dx in track(dx) }, onEnded: { end() }))
            .sensoryFeedback(.impact(weight: .light), trigger: crossed) { _, new in new }
            .mlAnimation(.crossFade, value: crossed)
            .accessibilityActions {
                if enabled { Button(ReminderCopy.remindAction, action: onRemind) }
            }
            .contextMenu {
                if enabled {
                    Button(ReminderCopy.remindAction, systemImage: "clock", action: onRemind)
                }
            }
    }

    private var panel: some View {
        HStack(spacing: MLSpacing.s8) {
            Image(systemName: "clock").font(StudentType.section).accessibilityHidden(true)
            Text(ReminderCopy.remindMe)
                .font(StudentType.bodySemibold)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(MLColor.onLime)
        .padding(.horizontal, MLSpacing.s20)
        .frame(width: max(offset, crossed ? threshold : 0), alignment: .leading)
        .frame(maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(MLColor.lime))
        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(MLColor.limeOutline, lineWidth: 1.5))
        .clipped()
        .accessibilityHidden(true)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 16, coordinateSpace: .global)
            .onChanged { value in
                if tracking == nil {
                    let dx = value.translation.width, dy = value.translation.height
                    tracking = value.startLocation.x > Self.edge && dx > 0 && abs(dx) > abs(dy) * 1.5
                }
                guard tracking == true else { return }
                track(value.translation.width)
            }
            .onEnded { _ in
                defer { tracking = nil }
                guard tracking == true else { return }
                end()
            }
    }

    private func track(_ dx: CGFloat) {
        offset = max(0, dx)
        crossed = offset >= threshold
    }

    private func end() {
        let set = crossed
        MLMotion.animate(.snappy, reduceMotion: reduceMotion) {
            offset = 0
            crossed = false
        }
        if set { onRemind() }
    }
}

/// The swipe's gesture. On iOS 18 and later it is a UIKit pan that only begins for a rightward, mostly horizontal drag
/// away from the left edge, so a vertical drag that starts on the card scrolls the page (a SwiftUI DragGesture there
/// held the scroll view). iOS 17 keeps the SwiftUI drag.
private struct RemindSwipeGesture<G: Gesture>: ViewModifier {
    let enabled: Bool
    let edge: CGFloat
    let drag: G
    let onChanged: (CGFloat) -> Void
    let onEnded: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            if enabled {
                content.gesture(HorizontalSwipe(edge: edge, onChanged: onChanged, onEnded: onEnded))
            } else {
                content
            }
        } else {
            content.simultaneousGesture(drag, including: enabled ? .all : .subviews)
        }
    }
}

@available(iOS 18.0, *)
private struct HorizontalSwipe: UIGestureRecognizerRepresentable {
    let edge: CGFloat
    let onChanged: (CGFloat) -> Void
    let onEnded: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator(edge: edge) }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .changed: onChanged(recognizer.translation(in: recognizer.view).x)
        case .ended, .cancelled, .failed: onEnded()
        default: break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let edge: CGFloat
        init(edge: CGFloat) { self.edge = edge }

        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            let start = pan.location(in: pan.view?.window)
            return start.x > edge && velocity.x > 0 && abs(velocity.x) > abs(velocity.y) * 1.5
        }
    }
}

/// Reminder set (2222:158135, 2222:158445): a white row with a clock, "Reminder set", "We'll ask again at 8:00 AM" and
/// an underlined Undo.
struct StudentReminderSetRow: View {
    let time: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "clock")
                .font(.system(size: 19))
                .foregroundStyle(MLColor.ink)
                .frame(width: MLSize.hit, height: MLSize.hit)
                .background(Circle().fill(MLColor.fillQuiet))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(ReminderCopy.reminderSet).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                Text(ReminderCopy.askAgain(time)).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
            }
            Spacer(minLength: MLSpacing.s8)
            Button(action: onUndo) {
                Text(ReminderCopy.undo)
                    .font(StudentType.secondaryMedium)
                    .foregroundStyle(MLColor.ink)
                    .underline()
                    .frame(minWidth: MLSize.hit, minHeight: MLSize.hit)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, MLSpacing.s16)
        .padding(.trailing, MLSpacing.s12)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .ignore)
        // "Reminder set, we'll ask again at 8:00 AM, Undo"; a double tap undoes.
        .accessibilityLabel(ReminderCopy.setLabel(time) + ", " + ReminderCopy.undo)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, onUndo)
    }
}

/// The outlined "Reminder" chip above a card whose hour is up (2222:158236, 2222:158543).
struct StudentReminderChip: View {
    var body: some View {
        Label(ReminderCopy.reminder, systemImage: "clock")
            .font(StudentType.footnote)
            .foregroundStyle(MLColor.ink)
            .padding(.horizontal, MLSpacing.s12)
            .frame(height: 28)
            .overlay(Capsule().strokeBorder(MLColor.ink, lineWidth: 1.5))
    }
}

/// Lets the Student root share its reminders with Home.
extension View {
    func studentReminders(_ reminders: StudentMealReminders) -> some View {
        environment(reminders)
    }
}
