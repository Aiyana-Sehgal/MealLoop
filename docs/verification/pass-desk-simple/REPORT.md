# Pass Desk simplified to code and colour, with a 30 second student validity

**Done, with the gaps listed below.** The owner ruling (Prompt 2B) replaces Figma PD-1, the pass desk pack, the PRD and
Prompt 2 Part B for Pass Desk Home:
- The desk shows only the live code and colour, and records nothing.
- The student's hold of "Use pass" is the entry. The pass is In use for 30 s, then Used for good.

Worktree: `MealLoop-pass-desk-simple`, detached at `f2bddf5`.

**Workflow mismatch.** The owner workflow says to push straight to `main`, while `CLAUDE.md` and `docs/BRANCHING.md`
say to use pull requests. The owner workflow was followed, and no branch, tag or pull request was created.

**Reference images.** `~/Downloads/pass_desk_simple_2026-11/images/` does not exist on this Mac, so the two named files
(`PD-home_code_and_colour.png` and `PD-check_last_4_digits.png`) were not found. The owner sent one combined image with
the request, showing both screens. It is committed as
`design/reference/pass_desk_simple_2026-11/images/PD-home_and_check_last_4_digits.webp`, and a copy is here as
`reference_owner_image.webp`.

## Part 3 inspection (before any change)

- **The button.** "Use pass" is a press-and-hold (`PassHoldButton`, 1.2 s, on the Confirm sheet). It shows only in the
  Available state, above the tab bar and reachable without scrolling on iPhone 18 Pro
  (`student_pass_available_iphone18pro.png`). Prompt 2 recorded the same finding.
- **The operations before this change.**
  - `startPass` turned Available into Live.
  - Used came only from the desk's `recordPassEntry`.
- **The Figma Student pass frames** (page 07):
  - Available (221:63168)
  - Confirm (221:63180)
  - Live 1, 2 and 3 (221:63212, 221:63219, 221:63226)
  - Live with Reduce Motion (221:65349)
  - Used (221:63233)

  **No frame draws an In use or 30 second state.** So In use is the existing Live card, plus a status line ("In use",
  with a dot) and "Valid for N s".

## What was built

- **Backend** (commit `96530a9`, `feat(backend)`, additive): `PassUseRepository`.
  - `usePass` is the student's hold. It records the use at the pass-code instant, and records the special-meal entry
    (`recordedBy: .student`). The same key returns the first result, and a second use is refused with "Already used".
    It is allowed any time before the meal ends, as before (open: P-PASS-11).
  - `passUseState(at:)` returns not used, In use with the seconds left, or Used. The 30 s is
    `PassUsePolicy.validity`, owned by the backend; no view types the number.
  - `checkLastFour(at:)` is read only.
  - `deskCode(at:)` is the meal's live code, from the same window as every pass.
  - `startPass`, `recordPassEntry`, `refreshPassCode` and `LivePassCodeRepository` are unchanged.
- **Pass desk Home** (`PassDeskLiveCode.swift`, `PassDeskHomeView.swift`):
  - The title "Pass desk" and "Lunch 12–2 PM · Main Mess", with the times from the meal.
  - The code card, a local copy of the Student `PassLiveTicket` top half: "Code", the 76 pt code, "Colour", the colour
    pill with its name, and "Changes in N s". It uses the Student `PassColour` and `StudentType` without editing the
    Student files.
  - Three rows with hairlines and chevrons: Request a new pass, Report a problem, and Check last 4 digits.
  - Before and after the meal keep their existing cards and show no code. Offline shows no code.
- **Removed from the Pass Desk folder:**
  - the Home keypad and digit card
  - the check sheet (`PassDeskCheckSheet.swift`)
  - the outcome screens (`PassDeskOutcomeView.swift`)
  - `PassDeskCheckFlow` with its record path
  - `PassDeskCompare` and `PassDeskOutcome`
  - the old Look up page

  The desk has no record call anywhere: a test checks every Pass Desk file.
- **Check last 4 digits:** Back, the title, four boxes, one status card (a dot plus plain text) and the keypad. The
  status lines are:
  - "Valid for lunch · not used yet"
  - "In use · valid for N s"
  - "Used"
  - "Not found"
  - "No special pass" (a student with no pass; not in the brief's list)
  - "Wrong meal"
  - "Can't check right now" (offline or any failure)
- **Student Special pass:** the hold calls `usePass`. While In use, the Live card shows the live code and colour, with
  "In use" and "Valid for N s" from the repository. At 30 s the pass shows the existing Used ticket with no code. A
  second hold is refused, and a tap alone does nothing.

## Results per image and frame (iPhone 18 Pro, Debug)

| Image or frame | Result |
|---|---|
| Reference: Pass desk Home | Differs in styling only, as the ruling asks: the card is the white Student ticket style, not the reference's black card. The title, the meal line, the code, colour pill, "Changes in N s" and the three rows match the reference's layout. The Debug badge covers the header centre. `home_iphone18pro.png` |
| Reference: Check last 4 digits | Matches the layout: Back, the title, four white boxes, the status card ("Valid for lunch · not used yet") and the keypad. The boxes span the full width, where the reference draws them narrower, and the status dot is lime. `check_empty_iphone18pro.png`, `check_valid_iphone18pro.png` |
| Figma Pass · Live 1 (221:63212) vs the desk card | Same fonts, code size, labels and colour pill. The desk card has no "Show this at the counter" line and no holder row, as the ruling asks. |
| Figma Pass · Live 1 (221:63212) vs the Student In use | Matches the Live card. Added under it: the dot plus "In use" and "Valid for N s" (no frame draws them). `student_pass_in_use_iphone18pro.png` |
| Figma Pass · Used (221:63233) | Differs: the code and colour show "—" instead of the greyed code, because the ruling says a used pass can't be shown again. The rest matches. "Used 1:40 PM" is the story clock's time. `student_pass_used_iphone18pro.png` |

There is no Figma frame for the two Pass Desk screens, so no Figma match is claimed for them.

## Tap-through

| Element | Expected destination | Result |
|---|---|---|
| Home · Request a new pass | Request a new pass | works |
| Request · Back | Home | works |
| Home · Report a problem | Report a problem | works |
| Home · Check last 4 digits | Check last 4 digits | works |
| Check · keypad 0, 2, 3, 8 | status "Valid for lunch · not used yet" | works |
| Check · Back | Home | works |
| Student pass · Use pass | the hold sheet | works |
| Sheet · a tap on Hold to use | nothing | works (nothing happened) |
| Sheet · hold 1.8 s | In use, Valid for 26 s, the live code | works |
| Student pass after 30 s | Used, no code | works |
| Student pass · Back | Home | works (checked in the earlier run; not re-tapped) |

Not tapped here: the reissue status list, Open problems, Alerts, Me and the SOS tab. They are unchanged and covered by
the existing tests.

## Tests (fake clock)

- `PassUseTests` (new, 6):
  - In use with 30 s left, still In use at 29 s, Used at 30 s
  - a second hold is refused, and the same key returns the first result
  - the hold records one entry
  - the last-four check follows the state, never records, and handles not found and wrong meal
  - the desk code is the phone's code and changes at the boundary
  - offline neither uses nor checks
- `PassDeskViewModelTests`: 18 tests drove the removed keypad, check sheet and "Matches" path, or the old Look up.
  They were replaced by 12 tests of the new behaviour:
  - Home shows the code during the meal and none outside it
  - Home has no keypad, digit boxes or record button (checked in the source and the model)
  - the desk code is the phone's code and changes at the boundary
  - losing the connection hides the code
  - the desk records nothing, and the hold records one
  - the check covers valid, In use then Used, not found, no pass, wrong meal and offline
  - an offline hold is never recorded
  - no Pass Desk file calls a record operation
  - a student's hold is visible through the repository
- `PassCodeScreensTests`: 3 tests, rewritten to compare the Student pass with the desk Home model.
- `StudentMealsScreensTests`:
  - the failed-hold test now fails by losing the connection
  - "the door records it" is replaced by "a tap alone does nothing" and "In use 30 s, then Used, and a second hold is
    refused"
- `StaffFigmaScreenshotTests` (skipped unless an environment variable is set): `testDeskCheckSheet` and
  `testDeskOutcomes` are removed, because the frames they captured (2533_*, 2534_*, 2531_5403) are superseded by the
  ruling. The look-up captures use the new page.

No test was removed to make the suite pass. The removed and replaced tests covered behaviour the ruling deletes.

## Commands and counts (final code)

Xcode 27.2 (27B52), iOS 27.2 simulator on iPhone 18 Pro, with one device, reused. `pgrep -x xcodebuild` reported 0,
and tests ran serially.

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug, `MealLoop`, `test` | 0 | 683 | 662 | 0 | 21 |
| Review, `MealLoop Review`, `test` | 0 | 682 | 661 | 0 | 21 |
| Release build (generic iOS Simulator) | 0 | n/a | `** BUILD SUCCEEDED **` | n/a | n/a |

The Release log has 1 `warning:` line. Before this run, `main` had Debug 684 and Review 683 (23 skipped). Conflict
hunks: none.

## Open questions (as the brief asks; not decided)

- **P-PASS-10** Does the student's phone show the code before the hold, or only during the 30 seconds? Built: only after
  the hold.
- **P-PASS-11** How early may a pass be used? Built: any time before the meal ends, as before.
- **P-PASS-12** The Figma frames for the Pass Desk (PD-1 to PD-3) and the Student pass (no In use state; Used shows the
  code) need updating to match this ruling. Owner decision: a small design run, or accept the difference.
- **P-PASS-13** The PRD, the handoff and the Pass Desk spec still say "type the last 4 digits, then Matches · record
  entry".
- **P-PASS-14** The In use clock is the pass-code instant: the story time plus the real seconds since the story clock
  last moved. Confirm this is right for the review story.

## Not run

- a physical device
- Dynamic Type
- VoiceOver
- iPhone SE: no SE simulator is installed
