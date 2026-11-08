# Pass code (Student pass and Pass Desk) and Pass Desk Home, compared with Figma

**Partial.** Part A is built and pushed: one clock-derived pass code, shown by both the Student Special pass and the Pass
Desk. In Part B, Pass Desk Home during the meal was fitted to its frame. The rest of Part B relies on the frame-by-frame
comparison already on `main` (`docs/verification/staff-figma-fix/REPORT.md`, 46 Pass Desk frames). This run did not
repeat that comparison. It looked again only at Home during the meal and the check sheet.

Figma file `nzzTAm9YnJRSdKEeYUWUEb`, page "09 Mess Staff", was read only (`get_screenshot`). `~/Downloads/FIGMA_FRAME_MAP.md`
is missing, so node ids come from frame names and from the staff Figma report. None was guessed. Worktree:
`MealLoop-pass-desk` (detached at `cfa9a6b`).

**Workflow mismatch.** The owner workflow says to push straight to `main`, while `CLAUDE.md` and `docs/BRANCHING.md`
say to use pull requests. The owner workflow was followed, and no branch, tag or pull request was created.

## Part A: one clock-derived pass code (P-PASS-9, option a)

### Inspection (before any change)

- **The seed.** `DemoSeed.samplePassCodes` holds three samples: 218 Lime, K2M9 Blue and 7A3F Lime.
  `DemoSeed.passCodeWindow` is 10 s.
- **`refreshPassCode(for:meal:)`.** Each call moves `state.passCodeIndex` to the next sample and sets
  `passCodeIssuedAt = clock.now()`. Nothing moves it on a clock, so "Changes in 10 s" was a countdown kept by each
  screen.
- **`recordPassEntry`.** It compares the typed code with that same stepped state.
- **The Student pass.** `StudentPassViewModel.refreshCode()` called `refreshPassCode` after the hold and again whenever
  its own 1-second tick reached zero.
- **The Pass Desk.** `PassDeskCheckFlow` took the code from `lookUpPass` (`.valid(holder, live:)`), called
  `refreshPassCode` when its sheet countdown reached zero, and recorded with `recordPassEntry`. Each screen's refresh
  stepped the shared index, so the phone and the desk could show different codes.
- **Clocks.** `AppEnvironment.clock` is the provider's story clock (`DemoClock`). It moves only when the story does
  (scenario start, Start meal, Close meal, approval), and it stands still between those moments.

### What was built

- **`LivePassCodeRepository`** (commit `ad05507`, `feat(backend)`, additive):
  - `currentPassCode(for:meal:at:)` is read only. It picks the sample at `floor(instant / 10 s)` and returns the code,
    the colour, the window end, the seconds left and the window length. The code is stable within a window and changes
    at the boundary. There is one code per window for everyone: the seed has no per-student codes. **Prototype limit.**
  - `recordPassEntryForCurrentCode` checks the typed code against the backend's own current window. An earlier window's
    code comes back as `.codeChanged` and is never recorded. The other rules are the same as `recordPassEntry`: once
    per student per meal, the same key returns the first result, and offline records nothing.
  - `passCodeInstant()` returns the instant both screens read at: the story time plus the seconds since the story
    clock last moved (`PassCodeTicker`, which uses the device's monotonic uptime, injected). Without it, the code would
    never change on screen, because the story clock stands still between story moments.
  - `refreshPassCode`, `recordPassEntry` and their tests are unchanged.
- **The screens** (commit `9f3475b`):
  - The Student pass view model and the Pass Desk flow both read `currentPassCode` at `passCodeInstant()`.
  - The desk records through `recordPassEntryForCurrentCode` and never calls `refreshPassCode`.

### Seen in the simulator (iPhone 18 Pro, Debug)

The check sheet showed 7A3F Lime with "Changes in 10 s". At the window boundary it changed to K2M9 Blue, with
"Just changed", and the countdown went on: `check_sheet_*.png`.

### "Use pass" press-and-hold (step 5): finding, no change

- **Pass · Available** (221:63168) draws a "Use pass" footer button. **Pass · Confirm (holding)** (221:63180) draws
  "Hold to use".
- **Pass · Live 1, 2 and 3** (221:63212, 221:63219, 221:63226) and **Pass · Used** (221:63233) draw no control. They
  draw only the note "No scan needed. Marked used when you come in at the door."
- The build does the same. `StudentPassView.swift:174` shows "Use pass" in the Available state only. Holding it starts
  the Live pass. The owner's screenshot (Live, K2M9 Blue, "Changes in 6 s") is the Live state, after the hold, where no
  frame draws a button. So nothing was added.
- How a pass moves on:
  - the student's hold turns Available into Live (`startPass`)
  - Used comes only from staff recording the entry at the desk ("Marked used when you come in at the door")

  The frames show both. The hold itself never marks a pass used.
- When a pass may be started stays as it is in the backend: any time before the meal ends. This is open (P-STUDENT-M5).

## Part B: Pass Desk Home

### Results per frame (this run)

| Frame | Node | Result |
|---|---|---|
| PD-1 Home during | 2530:4460 | Matches: 52 pt keys on the quiet fill, and a local digit card with the frame's 53 pt boxes, so "Request a new pass" and "Report a problem" both sit above the tab bar. Before this run the keys were 56 pt and white, the card was about 19 pt taller, and "Report a problem" sat under the tab bar. The "Demo data" badge covers the header centre in Debug. |
| PD-2 Code fresh (check sheet) | 2533:4953 | Differs in data only: the code is the clock window's sample (7A3F, then K2M9 Blue), and the countdown is the 10 s window. The frame draws 7A3F and "7 s" (P-PASS-3). After a change, the sheet shows "Just changed", as PD-2 Code changed (2533:5217) draws. |

`home_during_figma.png` is next to `home_during_iphone18pro.png`, and `check_sheet_figma.png` is next to
`check_sheet_iphone18pro.png`.

### Inventory of the other Pass Desk frames

Status is as of the staff Figma report on `main`, which this run did not repeat. Of 46 frames, 13 match and 22 differ.
Most differences are owner wording rules ("saved", not "sent"), or come from shared components and seeded data. One
frame, PD-0 What you do (sheet), is not built: it sits in the Staff entry folder, outside this brief.

The other Home states (2530:4652, 2530:4844 and 2530:5008 for typing; 2531:4666 student not found; 2531:4933 offline;
2531:5239 for 42 of 214; 2544:5980, 2544:6614 and 2544:6784 for SOS) use the same card and keypad as 2530:4460. They
**were not captured** this run.

### Not built, and why

- PD-7 "I can't go after all": no release operation exists for a claimed SOS.
- PD-0 What you do (sheet): it belongs to the Staff entry folder.
- A per-student live code: the seed has none (prototype limit, above).
- The full tap-through of every Pass Desk element: **not done this run, because of the time box.** Tapped here: the
  keypad, the check sheet opening on the fourth digit, and the Home tab.

## Tests (fake clock)

| File | Tests | What they show |
|---|---|---|
| `LivePassCodeTests` (new) | 8 | Same code within a window. A new code and colour at the boundary. An expired window is never current. The phone and the desk read the same instant and code. Reading never records. A student without a pass for this meal gets no code. The current code records once, a stale code never, and a repeat is refused. Offline reads and records nothing. The ticker adds elapsed time and restarts when the story moves. |
| `PassCodeScreensTests` (new) | 3 | The Student pass view model and the desk sheet show the same code, colour, end and seconds. After the boundary, both move to the same next code. Typing and showing the sheet records nothing, and a match records one entry. |
| Existing tests changed | 3 | `StudentMealsScreensTests.testHoldingStartsTheLiveCodeWhichRotatesWithItsColour` and `PassDeskViewModelTests.testTheCodeChangesWhenTheWindowRunsOut` now move the clock across the window, because the code follows the clock, not the ticks. `testAnotherRoleCannotRecordThroughTheFlow` builds the flow with the live source. |

Covered by existing tests and unchanged: Approved is never shown as Done, a repeat is refused (`alreadyRecorded`),
and offline is never recorded.

## Commands and counts (final code)

Xcode 27.2 (27B52), iOS 27.2 simulator on iPhone 18 Pro, with one device, reused. `pgrep -x xcodebuild` reported 0
before each run, and tests ran serially.

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug, `MealLoop`, `test` | 0 | 674 | 651 | 0 | 23 |
| Review, `MealLoop Review`, `test` | 0 | 673 | 650 | 0 | 23 |
| Release build (generic iOS Simulator) | 0 | n/a | `** BUILD SUCCEEDED **` | n/a | n/a |

The Release log has 1 `warning:` line. Before this run, `main` had Debug 663 and Review 662.

The commits on `main` from this run:
- `ad05507` `feat(backend): add a clock-derived live pass code for phone and desk`
- `9f3475b` `feat(pass-desk): show one clock-derived code on the pass and the desk` (Part A, pushed on its own)
- `65d63fd` `fix(pass-desk): fit Home during the meal to the PD-1 frame`
- this report

Conflict hunks: none. `main` had not moved since `cfa9a6b` at each fetch.

## Open questions (proposed IDs)

- **P-PASS-10** One code per window for everyone (prototype). Should a production code be per student?
- **P-PASS-11** The pass-code instant moves with real time between story moments. Is that acceptable for the review
  story?
- P-PASS-3 (the window length: 10 s built, the frame shows 7 s) and P-STUDENT-M5 (when a pass may be started) stay open.

## Not run

- a physical device
- the camera (the desk has no camera by design)
- Dynamic Type
- VoiceOver
- iPhone SE captures: no SE simulator is installed; the one created in the Student run was deleted
