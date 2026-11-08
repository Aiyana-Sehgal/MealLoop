# MealLoop SwiftUI standards (the checklist every screen must meet)

A copy of the owner's spec of 8 November 2026 (`SWIFTUI_STANDARDS_SPEC.md`), as pasted into the Prompt 0 brief.
The original file was not in `~/Downloads`, so this copy was made from the pasted text. The shared helpers that meet it
are described in [COMPONENT_CATALOG.md](COMPONENT_CATALOG.md#how-to-adopt-mlscreen).

Deployment target iOS 17. Use newer APIs only behind `#available`, with an iOS 17 fallback. These are the owner's
complaints turned into rules: transitions that feel native, titles that collapse like iOS titles, no empty gaps,
nothing hand-rolled where a platform control exists.

## 1. Navigation and titles
- One `NavigationStack` per tab with a typed `NavigationPath`. Screens are pushed, never swapped in place.
- The native back gesture must work on every pushed screen (swipe from the left edge). If a custom back circle is
  drawn, the interactive pop gesture must stay enabled; test it. Prefer the native toolbar back button (a glass circle
  on iOS 26), which matches the design.
- Large titles collapse into the inline title as the content scrolls, automatically, the way iOS titles do: use
  `.navigationTitle` with `.navigationBarTitleDisplayMode(.large)`, or a shared large-title view that measures the
  scroll offset (`onScrollGeometryChange` on iOS 18, a preference key on iOS 17) and shows the same text inline in
  the toolbar when collapsed. Titles use the app typeface and tokens. Never a fixed-position title that stays put
  while content scrolls.
- Push and pop use the system transition. No custom slide animations on top of it.

## 2. Sheets and dialogs
- Use `.sheet` with `.presentationDetents` sized to the content (`.height(measured)` or `.fraction`),
  `.presentationDragIndicator(.visible)`, a corner radius from `MLRadius`, and the screen's background. A sheet is
  never taller than its content needs: no half-empty sheets.
- Confirmations use `.confirmationDialog` or a compact sheet with two explicit buttons. Never a press-and-hold gesture
  as the only way to confirm.
- `interactiveDismissDisabled` only while a send is in flight.

## 3. Layout and spacing
- Screens are `ScrollView` + `.safeAreaInset(edge: .bottom)` for the tab bar or a pinned primary button. A primary
  button that belongs to the form is pinned at the bottom safe area, not floating after a large gap.
- No large empty areas. Compare against the Figma frame: if the build leaves more than about a quarter of the screen
  blank where the frame does not, it is a defect. Fix with real content, proper stacking and `containerRelativeFrame`,
  not with `Spacer` that stretches to nothing.
- Spacing and sizes only from `MLLayout`; type only from `MLType`; colours only from `MLColor`. No magic numbers in
  views.

## 4. Motion and feedback
- State changes animate with `withAnimation(.snappy)` or `.smooth`. Numbers use `.contentTransition(.numericText())`.
  Insert and remove use `.transition`. Define the curves once in an `MLMotion` token and use it everywhere.
- Respect `accessibilityReduceMotion`: no movement, cross-fade only.
- Haptics through `.sensoryFeedback` (selection, success, warning), once per action.

## 5. Input
- `@FocusState` for forms, `.submitLabel`, `.scrollDismissesKeyboard(.interactively)`, the correct `.keyboardType`,
  `.textContentType`. Search uses a real field with a debounced query.

## 6. Accessibility
- Every control has an accessibility label and trait; status never by colour alone; targets at least 44 pt; Dynamic
  Type works up to the largest size without clipping (test the screens with the largest size); VoiceOver reads a
  screen in a sensible order.

## 7. Structure
- `@MainActor @Observable` view models, `.task` for loading with cancellation, `LoadState` and `AsyncContentView`.
  Views are layout only. A `#Preview` for every screen and its states.

## 8. How to check
- Each screen gets: a screenshot beside its frame, a note that swipe-back works, a note that the title collapses, and
  the largest Dynamic Type capture. State what could not be checked.
