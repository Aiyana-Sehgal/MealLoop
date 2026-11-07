# Kitchen report (Part 4)

Kitchen Home, shortage report, record waste, menu, history, Alerts, Me and SOS. Dated 2026-11-07. Base `feature/swiftui-foundation` at `2b2abee`, code at `22635c3`. Xcode 27.2, iOS 27.2.

Screenshots: [`small/`](small/) is a temporary iPhone SE (3rd generation), 375 x 667 pt. [`large/`](large/) is a temporary iPhone 18 Pro Max, 440 x 956 pt.

## Results

Run once on the final code, serially, with `-parallel-testing-enabled NO` and `-maximum-concurrent-test-simulator-destinations 1`. Counts are from the `.xcresult` bundles.

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug | 0 | 293 | 289 | 0 | 4 |
| Review | 0 | 292 | 288 | 0 | 4 |
| Release build | 0 | n/a | n/a | n/a | n/a |
| Review UI walk, small | 0 | 4 | 4 | 0 | 0 |
| Review UI walk, large | 0 | 4 | 4 | 0 | 0 |

The 4 skipped are the existing `SupervisorScreenshotTests`. The UI walks are temporary XCUITests in scratch copies, not in this branch. They used a launch hook to open a chosen moment and to raise an SOS ("Student feels faint" is walk-only text).

**Machine load:** other sessions pushed the load average above 200, and `pgrep -fl xcodebuild` reached 273. That count also matches any command line containing the word, and at that moment only 1 real `xcodebuild` process existed. The Review run waited 7 checks. The Release build and the large walk each waited 15 checks and then started with the count at 28 and 0 real `xcodebuild` processes. No run failed or was retried because of load.

**Not run:** a physical device, an iOS 17 runtime, VoiceOver and Dynamic Type.

## Reference table

Tab: H is Home, A is Alerts, M is Me. Images are in `design/reference/kitchen_2026-10/images/`, renders in `design/audit/export_kitchen/`. Inventory rows have the same names. **Shown** means a screenshot here shows it. **Tested** means a unit test covers it, with no screenshot.

| Reference | State | Tab | Component | Status |
|---|---|---|---|---|
| K00 | What you do sheet | none | none | Not built: the role picker flow is retired |
| K01 | Before the meal | H | `HeroCard`, `QuietRow` | Shown |
| K01b | Forecast loading | H | `AsyncContentView` | Built, spinner not skeleton |
| K01c | Forecast stale | H | none | **Not built** |
| K01d | Forecast not ready | H | `HeroCard` | Built, "—", not shown |
| K02 | During the meal | H | `HeroCard`, `LimeActionButton` | Shown |
| K02b | Entries stale | H | `StaleNote` | Shown |
| K02c | Offline | H | `OfflineBanner` | Built with the generic banner, see differences |
| K03 | Shortage sent | H | `ShortageRow` | Shown |
| K03b, K03c | Two reports, See all | H | `ShortageRow` | Built, not shown |
| K03d | Ravi saw it | H | `ShortageRow` | Tested. **Not reachable in the app**, see shared changes |
| K03e | Couldn't send, Retry | H | `ShortageRow`, warning triangle | Tested, not shown |
| K04, K04b | Report sheet | H | `mlSheet`, `ChoiceChip`, `SegmentedChoice` | Shown |
| K04c | Add a note | H | `mlSheet` | Tested, not shown |
| K04d | Sent toast | H | `mlToast` | Shown |
| K04e, K04f | Report again | H | `mlConfirmDialog` | Shown |
| K04g | Meal ended while reporting | H | `OutcomeScreen` | Tested, not shown |
| K05, K15, K16 | After: not started, recorded, draft | H | `HeroCard`, `StatusText` | Shown |
| K06, K06b to K06f | Record waste | pushed | Local rows | Shown |
| K06g | Save as draft? | pushed | `mlConfirmDialog` | Shown |
| K06h, K06i | Add a dish | pushed | `mlSheet` | Shown |
| K07, K07b, K07c | Quantity sheet, pieces, over limit | pushed | `mlSheet`, `KeyPad` | Shown |
| K07d, K07e | Not a number, negative | pushed | none | Not reachable: the keypad can't type them |
| K08, K08b | Check and save | pushed | `mlSheet` | Shown |
| K08c | Report saved | pushed | Local lime screen | Shown |
| K09 | Past meal, not recorded | pushed | Local | Shown, without Record waste, see differences |
| K09b | Record waste for Tue 13 Dinner | pushed | none | **Not reachable**, see decisions |
| K10, K10b, K10c | Breakfast past meal and edit | pushed | Local | Summary only: no rows seeded |
| K11 to K11f | Meal history | pushed | `AsyncContentView`, `StatusText` | K11 shown, others built |
| K12, K12b | Alerts | A | `AlertRow` | Shown |
| K12c | SOS on Alerts | A | `SOSCard` | Built, not shown |
| K12d, K12e | Empty, error | A | `StateBlock`, `AsyncContentView` | Built, not shown |
| K12f | Food short from the pass desk | A | `AlertRow` | Built, needs the pass desk to report |
| K13 | Me | M | Local | Shown |
| K14, K14b to K14f, K19, K20 | SOS tab and panel | H | `SOSEdgeTab`, `SOSPanel` | K19, K14c, K14d shown |
| K15b, K15c | Today's report, edit | pushed | Local | K15b shown; edit tested |
| K17 | Menu for Lunch | pushed | Local | Shown |
| K18 | Editing closed | pushed | Local | Tested: the story clock can't reach six hours on |

## Foundation differences against K01 to K05

| # | Area | Result |
|---|---|---|
| 1, 2 | Hero number, card height | **Fixed.** 108 pt regular on K01 and K02, 68 pt on K05 |
| 3 | Mono digits | Left: slashed zero is SF Mono |
| 4 | Title weight | Left: shared token |
| 5 | Logo mark | Fixed earlier |
| 6 | Tab bar | Fixed earlier, in the glass tab bar |
| 7 | Card colour | Left: documented token |
| 8 | Shortage row icon | Left: `frying.pan`. The drawn pot is not in the app |
| 9 | Shortage row time | Left: mono, per the rule that times are mono |
| 10 | Elapsed time | Left: sources disagree |
| 11 | K04 sheet | **Fixed.** Built |

Also done: the Draft state uses the shared dashed dot, "Couldn't send" uses the warning triangle, and the avatar is labelled "Your profile", so it no longer repeats "Me".

## Differences left

- **K02c offline:** uses the shared banner, not the drawn "OFFLINE · last count" card and its wording.
- **K01c forecast stale:** not built. The repository gives no way to tell a stale forecast.
- **K09:** the row says "add it", but the past meal offers no Record waste, because the repository can only save the story meal.
- **K13:** "On shift" has no "since 11:00 AM", because no shift time exists. Switch role, Language and Help open Coming soon.
- **K14d:** no "I can't go after all", because no operation releases a claim.
- **SOS "Back to cooking":** the spec's wording. The K14d export says "Back to the kitchen". The brief says the spec wins.
- **History:** Wed 14 Breakfast reads Unavailable, and breakfast has no report rows, because no spec gives them.
- **Alerts:** rows are derived from what the repositories hold, so "Shortage seen" and "Food short" appear only once those events exist.
- **Add a dish:** the "Done" count goes up to 9, where the drawn sample stays at 8.

## Backend operations

**Added:** `ShortageRepository.markSeen(_:by:)`, in `2ca7754`, with `ShortageSeenTests`. Supervisor only, a repeat keeps the first sighting, offline records nothing. No existing operation changed.

**Already there:** `reportShortage` (repeat-safe by key), `shortages(for:)`, `markResolved`, `summary`, `report`, `saveDraft`, `save`, `mealHistory`.

**Bug found by the walk and fixed:** the quantity sheet opened blank on first tap. Its open flag and its field were separate state, so it could render before the field arrived. The sheet now opens from the field itself. Unit tests could not catch this.

## Shared changes needed, not made

1. **`SupervisorShortageView`:** call `markSeen` when the Supervisor opens a report. Until then "Ravi saw it" cannot appear in the app.
2. **`PlaceholderMetricTests`:** `built` lists only Kitchen Home. Alerts and Me are now built, so the count reads two too high for Kitchen.
3. **Release an SOS claim:** an operation for "I can't go after all". SOS belongs to the Supervisor session.
4. **`docs/SCREEN_INVENTORY.md`:** the Kitchen status rows, which this task may not edit.

## Open questions

Proposed IDs for the owner to merge into `docs/OPEN_DECISIONS.md`.

| ID | Question | What the app does now |
|---|---|---|
| P-KITCHEN-1 | Should waste be recordable for an earlier meal such as Tue 13 Dinner (K09b)? Same as SV-Q4 | The repository saves the story meal only, so the row says "add it" with nothing to tap |
| P-KITCHEN-2 | How long can a missed meal's waste be recorded? Spec open item 1 | No limit is enforced |
| P-KITCHEN-3 | Should a report written while offline be kept after a relaunch? | Failed reports live in memory, and a relaunch loses them |
| P-KITCHEN-4 | "Back to cooking" or "Back to the kitchen"? | The spec's "Back to cooking" |
| P-KITCHEN-5 | Should the dashed "Enter kg" rows show for plate waste too? Not drawn | Yes, the same pill |
