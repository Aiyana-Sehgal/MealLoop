# Admin Today and headcount approval: verification

Base `feature/swiftui-foundation` (a4ae9c7), which contains the tips of `feat/ios-core-story-contracts` and `feat/ios-shared-components`. Xcode 27.2.

## Results

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug, clean, iPhone 18 Pro iOS 27.2 | 0 | 175 | 175 | 0 | 0 |
| Review, clean, same device | 0 | 174 | 174 | 0 | 0 |
| Release, clean build | 0 | n/a | n/a | n/a | n/a |

Before this work: 145 Debug and 144 Review. This adds 30 tests in `AdminTodayViewModelTests.swift`. The race test was confirmed to fail with its guard removed.

**Simulator walk:** six walks passed on iPhone 17e (iOS 27.2, `small/`) and iPhone 18 Pro Max (iOS 27.0, `large/`), 33 screenshots each. They were driven by a temporary XCUITest target in a scratch copy, which is not in this repository. That copy also removed the system Save Password prompt, which otherwise covers the app after sign-in.

**Scratch-seeded screenshots** (names end `_scratch`): no repository can reach these states yet, so the scratch copy seeded them. Acknowledged (18, 19; Part 6 builds the Vendor side), safety case (20; the seed has no case, and "0 MIN" comes from its sample time being after the clock) and loading (21; a forced delay). They show layout, not a reachable story state.

**Not run:** a physical device, an iOS 17 runtime, VoiceOver by hand, largest Dynamic Type, Reduce Motion.

## Reference table

Exports are in `design/audit/export_admin_redesign/`. Tabs confirmed: Today, Students, Results, More and the round Search.

| Reference | State | Inventory row | Tab | Components | Data-driven | Screenshot |
|---|---|---|---|---|---|---|
| A01_today | Lunch, action tile | `A01_today` | Today | local tile and day line, `SegmentedProgress`, `FactCard` | Yes, Main Mess only | 01, 17 |
| A01_today_breakfast | Values missing | none | Today | same | Yes | 02 |
| A01_today_snacks, _dinner | No meal seeded | `A01_today_dinner` | Today | same | Yes, shows No data | 03 |
| A01_today_north_sent | Sent, Pending | none | Today | same | Yes | 11 |
| A01_today_north_replied | Acknowledged | none | Today | same | Yes | 18 |
| A01_today_safety_case_open | Safety card | `A01_today_safety_case_open` | Today | `HeroCard` | Yes, no seeded case | 20 |
| A01_today_offline | Offline | `A01_today_offline` | Today | `AsyncContentView` | Yes | 35 |
| A01_today_loading | Loading | none | Today | `AsyncContentView` | Yes | 21 |
| A01_today_nothing_needs_you | Nothing needs you | none | Today | local | Yes, no "Next" line | 01b |
| A01_today_needs_you_all | Shortage | none | Today | `SectionHeader`, `CompactPillButton` | Yes | 31, 31b |
| A01_today_mess_closed | Meal closed | none | Today | tile | Yes | 33 |
| A02_headcount_north | Approve, then send | `A02_headcount_north` | Today | `HeroCard`, `InkActionButton`, `mlConfirmDialog` | Yes | 04, 08, 09, 16 |
| A02_headcount_adjust_headcount_sheet | Adjust, reason | `A02_headcount_adjust_headcount_sheet` | Today | `mlSheet`, `ChoiceChip`, `FieldErrorText` | Yes | 05, 06, 07 |
| A02_headcount_sent | Pending | `A02_headcount_sent` | Today | `StatusText` | Yes | 10 |
| A02_headcount_vendor_replied | Acknowledged | `A02_headcount_vendor_replied` | Today | `StatusText` | Yes | 19 |
| A02_headcount_failed | Write failed | none | Today | `FieldErrorText` | Yes | 36 |
| A03 to A14, F01, F02 | Other screens | their own rows | various | none | Later parts | 12 to 15 |

## Differences left

- One tile, not four: only Main Mess is seeded. North, South and Annexe are not invented.
- "Hey Mess food head" wraps to two lines, and the avatar reads MF, because of the seeded display name.
- The stepper has four steps, not A02's three, because approval is its own step (FR-HC-004).
- The adjust sheet's button says "Approve 862", not "Save 720", because saving approves.
- Status is a dot and text, not A02's pills, per the brief. The word is Pending, not Waiting or Not acknowledged.
- Missing from the hero: the range bar, usual Wednesday and events, because no repository has them. Answer counts from the sample roster take their place, labelled as such.
- Missing: "Sent before", "send by 11:30", "Next: Dinner 4:30 PM", Sambar left over row, Tell the vendor sheet, Call vendor. No data or an open decision behind each.
- Loading is a spinner, not a skeleton. Tab icons and pictograms are SF Symbols (T7).
- "Not available yet" is semibold because `FactCard` styles words that way, so missing values read stronger than the numbers.
- Reminders and escalation are not built: nothing is designed and the times are open (P25, FR-HC-005).

## Conflicts resolved

- Vendor: the pack says no vendor login; PRD FR-VEN-001 to 005 give a restricted account. The PRD is later and matches the Domain, so it was followed.
- No reply: the pack prompt says 30 minutes; P64 and P65 leave the deadline and fallback open, and the brief forbids inventing them. A missing acknowledgment stays Pending.

## Shared changes needed (not made)

1. **Mess for the admin session.** `Session` gives an admin a `MessID` only, so there is no name or time zone. `AdminContext.swift` reads `DemoSeed.mess` behind `#if DEMO_DATA || REVIEW_DATA` as a temporary bridge; Release falls back to Coming soon. Proposed, in `Repositories.swift`, with `DemoDataProvider`, `RemoteAPI` and the `Repositories` struct updated:
   ```swift
   protocol MessRepository: Sendable {
       func messes(for scope: AccountScope) async throws -> [Mess]
   }
   ```
2. **Display name.** `DemoSeed.accounts`: `account("foodhead", "Devi", .admin, .mess(mess.id))` gives "Hey Devi" (`admin_sample_data.md`).
3. **More messes** in the seed, for the four tiles, if the owner wants them.
4. **Safety case** in a scenario, so Today's safety state can be reached.
5. **`docs/PRESENTER_ACCOUNTS.md`** still lists Food Head / Admin as placeholder.
6. **`EntryViews.swift:110`:** `router.entryPath.removeLast()` crashed once on an empty path (report 2026-11-06 19:54:58), in Staff sign in. Not reproduced, and no walk step explains it. `popLast()` would be safe.

## Open questions (proposed IDs for `OPEN_DECISIONS.md`)

| ID | Question | What the prototype does now |
|---|---|---|
| P-ADMIN-1 | Can a headcount be approved or sent once the meal has started or closed? | The backend allows it, so Today offers it (32, 33). The view model does not invent a rule |
| P-ADMIN-2 | Must the headcount be approved before the Supervisor starts the meal? | `startMeal` does not check |
| P-ADMIN-3 | What should the Food Head see for reminders and escalation (P25)? | Nothing |
| P-ADMIN-4 | How is a change made after sending (FR-VEN-004, P66)? | The backend refuses it, so Adjust is hidden once sent |
| P-ADMIN-5 | Where do the forecast's rule version and time show (FR-HC-003)? | Not shown: the model has no rule version |
| P-ADMIN-6 | Should `KitchenHomeViewModel.staleAfter` (T9) move somewhere shared? | Admin reads it directly rather than repeating the number |

## Later parts

Students, Results and More; Live meal, Meal report and Safety case pages (Today opens Coming soon for these); real Search; Vendor acknowledgment (Part 6).
