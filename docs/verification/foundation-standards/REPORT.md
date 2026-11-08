# Foundation standards: verification report

Scope: Prompt 0 (SwiftUI standards foundation, Welcome and Staff sign in).
Checklist: `docs/SWIFTUI_STANDARDS.md`. Adoption guide: `docs/COMPONENT_CATALOG.md` ("How to adopt MLScreen").

## What was added

- `MLScreen`: Orbit background, system navigation integration with the native back button (glass circle on iOS 26+), so the interactive swipe-back gesture keeps working. A large title that collapses to the inline title on scroll (`onScrollGeometryChange` on iOS 18+, a preference-key reader on iOS 17). A bottom safe-area inset for the tab bar or a pinned primary action that stays above the keyboard, an "upper middle" placement for short forms, and the focused field kept visible.
- At the accessibility text sizes, the pinned primary action scrolls with the content instead (`MLScreenMetrics.pinsBottomBar`). On iPhone SE at the largest size, a pinned bar covered about 60% of the screen. **Owner to confirm.**
- `MLMotion`: the shared curves; under Reduce Motion they become a cross-fade only. A numeric text helper and haptics through `.sensoryFeedback`.
- `mlFont` (`MLDynamicType.swift`): `MLType` sizes that scale with Dynamic Type. Token values are unchanged.
- `mlSheet` (additive): sized to the measured content height, a visible drag indicator, the shared corner radius, swipe-to-dismiss blocked while a send is in flight, an item-based variant, and a compact two-button confirmation sheet. Existing callers are unchanged.
- A Debug-only gallery page (`MLScreenGalleryView`) with a long scrolling example.

## Per screen

| Screen | Swipe-back | Title collapses | Largest Dynamic Type |
|---|---|---|---|
| Welcome (`221:62499`) | n/a (root screen) | n/a (no title) | captured, 18 Pro and SE |
| Staff sign in (`1508:45`) | works on 18 Pro and SE (mid-gesture capture); before this change the swipe did nothing | yes, checked live with the keyboard up and on SE at the largest size | captured, 18 Pro and SE |
| MLScreen gallery (Debug) | works | yes, with both the iOS 18 and the iOS 17 reader | captured, 18 Pro and SE |

How it was checked: a left-edge drag on the simulator in the Review build, with a capture taken mid-gesture. For the collapse, the content was scrolled and the inline title checked in the bar. The iOS 17 reader was forced on iOS 27 to check it.

Staff sign in, empty form: about 23% of the screen is blank below the form, down from about 33%.

## For the role prompts

- Sheets with oversized fixed detents: `StaffEntryViews` (medium), `StudentRecordsViews` (medium), `StudentOutingViews` (fixed height 300).
- Pushed screens with the navigation bar hidden, so there is no swipe-back: Admin, Door Scanner, Gate, Kitchen, Pass Desk, Staff, Student (5 files), Supervisor, Warden. Also the Sign in with SRM screen, which was outside this task's scope.
- Possible empty gaps, from reading the code only: `GateRootView`, `AdminWeeklyReportView`, `AdminMenuView`, `GuardianRootView`, `StudentOutingViews`.

## Known differences

- The Welcome buttons are 56 pt tall; the Figma frame draws 60 pt.
- Whether staff use SRM sign-in is still open question P-FINAL-2. The build keeps the email and password form.

## Could not check

- A real iOS 17 or 18 device or simulator: only iOS 26.5 to 27.2 simulators are installed.
- VoiceOver order on a physical device.
