# Component catalog

The shared UI components for Parts 3 to 6. Search here before you build anything. They live in `ios/MealLoop/DesignSystem/Components/`.

Every component takes data and closures. None of them fetch, decide a business rule or hold sample data, so all wording comes from your feature's `<Feature>Copy` enum.

To change one, or to add one, see [Shared files](PARTS_AND_OWNERSHIP.md#shared-files-one-owner-only).

**See them:** open `ios/MealLoop/DesignSystem/Gallery/ComponentGalleryView.swift` in Xcode and use the `#Preview` canvas. The gallery exists in Debug only, and the app has no route to it yet. Screenshots of every state are in [`docs/verification/shared-components/`](verification/shared-components/).

## Which one do I need?

| I need to show | Use |
|---|---|
| A question before an action that affects other people | `mlConfirmDialog` |
| A task over the current screen | `mlSheet` with `SheetHeader` |
| Something verified and saved | `LimeResultScreen` |
| Something that did **not** record | `OutcomeScreen` |
| A status on a black card | `HeroStatusChip` |
| A status on a light surface | `StatusText` |
| Something that just happened and worked | `mlToast` |
| Something that failed | `FieldErrorText`, or a row with Retry. Never a toast, which disappears |
| A value that is missing | `nil`, which every component shows as "—" or dashed. Never 0 |

## How to adopt MLScreen

`MLScreen.swift`, `MLMotion.swift`, `MLDynamicType.swift`. The scaffold for [the SwiftUI standards](SWIFTUI_STANDARDS.md). Adoption is opt-in, one screen at a time; nothing changes for a screen until you wrap it. **See it:** the gallery page "Screen · MLScreen scaffold" (`MLScreenGalleryView`, Debug only) and the captures in [`docs/verification/foundation-standards/`](verification/foundation-standards/). **First adopters:** Welcome and Staff sign in (`Features/Entry/EntryViews.swift`).

1. **Replace the screen's own `ZStack { OrbitBackground(); ScrollView { … } }`** with `MLScreen`. It draws the Orbit background, the `ScrollView`, the large title and subtitle, and `.scrollDismissesKeyboard(.interactively)`.
   ```swift
   MLScreen("Meal report", subtitle: "Lunch · Wed 14 Aug") {
       rows                                   // content
   } bottom: {
       InkActionButton(title: "Send") { … }   // pinned primary action
   }
   ```
   Other forms: `MLScreen(title) { content }`, `MLScreen(title, trailing: { … }) { content }`, and the full form with `header:` (a brand row or eyebrow above the title).
2. **Delete the drawn title and `BackButton`, and stop hiding the bar** on pushed screens: remove `.toolbar(.hidden, for: .navigationBar)` and `.navigationBarBackButtonHidden(true)` from the destination. `MLScreen` uses the system back button (the glass circle on iOS 26, chevron only on iOS 17 and 18 through `.toolbarRole(.editor)`), so the left-edge swipe-back works. The large title collapses into the bar once it scrolls under it: `onScrollGeometryChange` on iOS 18 and later, a preference key on iOS 17.
3. **Pinned action:** put the screen's primary button in `bottom:`. It sits on the bottom safe area and rides above the keyboard; the bar gets a canvas and a hairline only while content runs underneath it.
4. **Tab roots:** pass `bottomClearance: .tabBar` (86 pt: the 62 pt floating bar, its 8 pt gap and 16 pt of air) instead of a hand-made bottom padding.
5. **Short forms:** `placement: .upperMiddle` keeps the header at the top and splits the leftover height one part above the title and two below the form, so no empty band opens above the pinned button. `fillsViewport: true` makes the content at least the visible height (Welcome centres its brand this way).
6. **Fields:** add `.mlKeepsVisible(id:when:)` to each field (`when: focus == .email`), so the focused field scrolls above the pinned bar and the keyboard.
7. **Text that scales:** `.mlFont(.body)` and the other `MLDynamicType` styles are the `MLType` sizes, growing with Dynamic Type. `MLType` itself is fixed.
8. **Motion:** `MLMotion.animate(.snappy, reduceMotion:) { … }`, `.mlAnimation(.smooth, value:)`, `.mlTransition(.fromTop)`, `.mlNumericText(count)` and `.mlHaptic(.success, trigger:)`. Under Reduce Motion every curve becomes a cross-fade and every entrance an opacity change.
9. **Sheets:** keep `mlSheet`; it sizes to its measured content. New: `mlSheet(isPresented:isWorking:onDismiss:)` (no swipe-away while a send is in flight), `mlSheet(item:)`, and `mlConfirmSheet` (`ConfirmSheet`: title, subject, detail, Cancel and the action side by side) for a compact confirmation at the bottom.

Check each adopted screen as the standards say: swipe back from the left edge, scroll until the title collapses, and capture it at the largest Dynamic Type size.

## Dialogs and sheets

### ConfirmDialog, `mlConfirmDialog`
`ConfirmDialog.swift`. **States:** ready, working (spinner, both buttons ignore taps). **References:** S13, S14, S15, S17. **Parts:** 4c, and any "Save this as a draft?" or "Report again?" in 4b.

```swift
.mlConfirmDialog(isPresented: $isConfirming, content: SupervisorCopy.startMeal, isWorking: model.isStarting) {
    Task { await model.startMeal(); isConfirming = false }
}
```
Confirm leaves the dialog open, so you can show `isWorking` and close it when the write ends. Cancel closes it.

### `mlSheet`, SheetHeader, SheetCloseButton
`BottomSheet.swift`. **States:** sized to content, scrolling when taller than the screen, with or without Close. **References:** D02, D06, K04, K07, P01, P04, P12, S00, G08, 11 to 13. **Parts:** 3c, 3d, 4a to 4d, 6a.

```swift
.mlSheet(isPresented: $isReporting) {
    VStack(alignment: .leading, spacing: MLSpacing.s16) {
        SheetHeader(title: KitchenCopy.whichFood) { isReporting = false }
        // your content
    }
}
```

## Result screens

### LimeResultScreen
`LimeResultScreen.swift`. **States:** with count and auto-return (D07, P05), with note and lines and no timer (33), count missing ("—"). **Parts:** 4a, 4d, 6c.

```swift
LimeResultScreen(
    context: DoorCopy.context, title: DoorCopy.recorded, subject: result.maskedName,
    count: .init(label: DoorCopy.soFar, value: result.count, change: "+1"),
    autoReturn: .init(seconds: 1) { DoorCopy.backIn($0) },
    actionTitle: DoorCopy.scanNext, onDone: returnToCamera
)
```
`onDone` runs once, from the button or the timer. With VoiceOver on, the timer does not run and the button returns. **Only show this for a saved result.**

### OutcomeScreen, FactCard, FactRow
`OutcomeScreen.swift`. **States:** quiet or outlined badge; with or without facts, note, second action, link and footnote. **References:** D08, D09, D10, P06, P07, P08. **Parts:** 4a, 4d.

```swift
OutcomeScreen(
    onBack: goHome, badge: .outlined, symbol: "wifi.slash", title: DoorCopy.cantCheck,
    message: DoorCopy.notRecorded, isMessageEmphasized: true,
    facts: [FactRow(label: DoorCopy.lastUpdate, value: time)],
    primary: .init(title: DoorCopy.tryAgain, handler: retry)
)
```
`FactCard` also works alone, for label and value rows on any screen. A nil value shows "—" and is spoken as "Not available". Set `isMono: false` for words.

## SOS

`SOSComponents.swift`. **References:** D05, D13, D14, D17, K19, K20, P15, P16, S03, S04, S05, S08. **Parts:** 4a to 4d.

### SOSEdgeTab
**States:** not claimed, claimed by you, any count. Place it flush with the right edge under the avatar, and only while an SOS is active. Its lime is the recorded SOS exception to the lime count.

```swift
SOSEdgeTab(count: sos.activeCount, isClaimedByYou: sos.isMine, claimedStatus: Copy.checking) { showPanel = true }
```

### SOSCard
**States:** `.notTaken`, `.claimed`, `.checked`, each with or without a note and the lime action. Use the action on Alerts only, and set `eyebrow: "SOS"` there.

### SOSPanel
**States:** not taken, claimed (with link), checked by someone else (Close case). It holds no rule about who may claim or close, so your role decides which buttons to pass.

```swift
.mlSheet(isPresented: $showPanel) {
    SOSPanel(
        title: Copy.active(1), incident: incident, status: .notTaken(Copy.nobody), helper: Copy.helper,
        primary: .init(title: Copy.illGo, handler: claim),
        secondary: .init(title: Copy.notNow) { showPanel = false },
        onClose: { showPanel = false }
    )
}
```
Only the Supervisor passes a Close case action. Door Scanner, Pass Desk and Kitchen mark it checked (`door_scanner_spec.md`, `supervisor_spec.md`).

## Student answer

### MealAnswerButtons, HeroAnswerRow, HeroSurfaceButton
`MealAnswerButtons.swift`. **States (`MealAnswerState`):** `.unanswered`, `.answered`, `.saving`, `.locked` with or without an answer. **References:** 04, 07, and prompt stage P5 for the locked state, which has no drawn image. **Parts:** 3a, 3b.

```swift
MealAnswerButtons(
    state: IntentionPolicy.canAnswer(meal, at: now) ? model.answerState : .locked(model.answer),
    lockedNote: StudentCopy.answersClosed
) { model.answer($0) }

HeroAnswerRow(state: model.answerState, onAnswer: model.answer, onShowEntry: showQR)
```
`HeroAnswerRow` keeps Entry QR working in every state, because the QR is never locked. Set `.saving` while a write runs; it blocks repeat taps.

## Status

### HeroStatusChip
`HeroStatusChip.swift`. **Styles:** `.lime`, `.outline`, `.dashed`; optional tick and mono time. **References:** 04, D13, D14, S05. **Parts:** 3a, 4a to 4d. For black cards only. It has no button trait and hugs its text.

```swift
HeroStatusChip(text: StudentCopy.notAnswered, style: .dashed)
```

### StatusText (extended)
`Rows.swift`. **Dots:** `.filled`, `.empty`, `.dashed` (new); optional mono `time` (new). **References:** K05, K11, K15, K16, S01, S06. **Parts:** 4b, 4c.

### ShortageRow (extended)
`Rows.swift`. **States:** sent, seen, couldn't send with Retry. `systemImage` is new: pass `"exclamationmark.triangle"` for couldn't send (K03e). **Part:** 4b.

## Empty and offline

### StateBlock
`StateBlock.swift`. **States:** icon, title, optional message, optional action. **References:** S09, S18d, D17 empty, K11d, K12d, W01 empty. **Parts:** 4a to 4d, 6b.

```swift
StateBlock(symbol: "checkmark", title: SupervisorCopy.caughtUp, message: SupervisorCopy.caughtUpDetail)
```
`EmptyStateView` stays the plain text form used by `AsyncContentView`. Offline stays `OfflineBanner` (reused, unchanged).

## Lists

`ListRows.swift`. **Parts:** 3e, 4a to 4d, 5.

- **SectionHeader:** title, hairline, optional action. **References:** D17, A01, K06.
- **AlertRow:** `.done`, `.filled`, `.outlined` marks; read or unread; tappable or not. A row with no `onTap` has no button trait. **References:** D17, P14, K12.
- **IconCardRow:** icon circle, title, optional detail, chevron. **References:** D05, D11, P11.

```swift
SectionHeader(title: Copy.earlier)
AlertRow(mark: .done, title: Copy.mealStarted, time: time, detail: Copy.opened, isUnread: true) { open() }
IconCardRow(symbol: "exclamationmark.triangle", title: Copy.reportProblem) { report() }
```

## Number entry

### DigitBoxes, DigitEntry
`DigitBoxes.swift`. **States:** empty, partial, complete, on a light or hero surface. **References:** D06, P03, P17. **Parts:** 4a, 4d.

### KeyPad (extended)
`KeyPad.swift`. `keyHeight`, `keyFill` and `onDecimal` are new, and the defaults are unchanged. In a sheet, pass `MLColor.fillQuiet`, because white keys vanish on white. **References:** D03, D06, K07, P03. **Parts:** 4a, 4b, 4d.

```swift
@State private var entry = DigitEntry()

DigitBoxes(entry: entry, accessibilityTitle: Copy.lastFour)
KeyPad(keyHeight: 54, keyFill: MLColor.fillQuiet) { entry.append($0) } onDelete: { entry.deleteLast() }
```

## Progress

### SegmentedProgress
`SegmentedProgress.swift`. **States:** a step of N, no data (dashed, not 0), light or hero, with or without labels. **References:** A01, 10. **Parts:** 3c, 5.

```swift
SegmentedProgress(current: issue.step, total: 4, surface: .hero, labels: StudentCopy.issueSteps)
```
`ProgressRing` (existing) stays the ring for loading.

## Small controls

`CompactControls.swift`. **Parts:** all.

- **CompactPillButton:** `.outline`, `.dashed`, `.lime`, 44 pt. **References:** K03e, K06, A01.
- **TextLinkButton:** the quiet underlined action. **References:** D10, D14, K04, K06.
- **ChoiceChip:** one of a set of pills. **References:** K04, P12, G08.
- **SegmentedChoice:** a track with one black segment. **References:** K04, A07.

```swift
ChoiceChip(title: dish.name, isSelected: dish == selected) { selected = dish }
SegmentedChoice(options: levels, selection: $level)
```

## Toast and field error

`ToastAndFieldError.swift`. **Parts:** all.

- **`mlToast`, ToastBanner:** shows, then clears the binding after 2 s. Pass `bottomInset` to clear a tab bar. **References:** D11, K04d, P09, P11, F02.
- **FieldErrorText:** icon and danger text under a field. **References:** D03, K07.

```swift
.mlToast(message: $toast, bottomInset: tabBarClearance)
```

## Not here

These are left to the owning part: the mess tile and day line (A01), the pass code comparison (P04), the student SOS flow (15 to 18), tickets, and the deck and dial screens. Two patterns are used by more than one role but weren't in this round: the stat tile (D05, D18) and the Me profile block (D18, K13). If you reach one first, propose it to the shared-file owner.
