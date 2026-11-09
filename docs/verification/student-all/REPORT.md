# Student all: dish feedback, swipe-to-remind, restyled frames and a coverage audit

Run of 10 November 2026 (unattended). Brief: the dish feedback flow (G1), swipe-to-remind on Home (G2), the restyled
frames never built (G3), a Student coverage audit by node id (G4), the standards on everything built (G5), tests and a
walk (G6). Interactive prototype only: nothing here runs against a live backend, and nothing claims a message reached
anyone.

`~/Downloads/SWIFTUI_STANDARDS_SPEC.md`, `~/Downloads/FIGMA_FRAME_MAP.md` and `~/Downloads/blank_audit.py` were not on
this Mac: the repository copies (`docs/SWIFTUI_STANDARDS.md`, `docs/verification/student-standards/blank_audit.py`) and
`get_metadata` on the Student page `44:5359` were used. Figma was read through the connector (`create_session`,
`get_metadata`, `get_design_context`, `get_screenshot`). Captures stay in `~/mealloop-captures/student-all/` (iPhone 18
Pro simulator, iOS 27.2, created for this run).

## Progress

| Group | State | Commits | Notes |
|---|---|---|---|
| G1 Dish feedback flow | done | `49d3ad8` backend, see below | Not good no longer opens Report |
| G2 Swipe-to-remind | not started | | |
| G3 Restyled frames | not started | | |
| G4 Coverage audit | not started | | |
| G5 Standards and blank audit | not started | | |
| G6 Tests and walk | not started | | |

## G1 · Dish feedback (owner, 9 November)

Before: Not good on Rate a dish (Meals, Search, the dish page) and on the How was … Home card opened the general Report
form. Now:

| From | Good | Not good |
|---|---|---|
| Rate a dish | records the rating (unchanged rule), then Thanks (2159:159) | What's wrong for that dish (2159:149347 and siblings), no Which dish |
| How was … card on Home | records, hides the card, then Thanks | Which dish (2159:285, More dishes 2159:471), then What's wrong |
| How was … full page | records, Thanks, then back | Which dish, then What's wrong |

- What's wrong: header (Back only when Which dish is under it, the dish pictogram and name, Close); six choices per
  dish from its frame (Sambar 2159:149347, Pongal 2159:149553, Millet Idli 2159:149760, Masala Omelet 2159:149968, Milk
  2159:150172, five choices), seeded in `DemoDishProblemSeed` with the node id beside each set; How bad? A bit / Quite /
  Very with Quite preselected (2136:2382); Add a note (optional) opens the inline Note field (2159:150369 draws it inline,
  not as a separate sheet); Send / Sending… (2159:150579) / Couldn't send. Try again (2159:150911) / offline banner
  "You're offline. Saved. Will send." (2159:151121); the footnote; and the SOS link last.
- "N others" comes from the existing feedback data only: `AdminSeed.feedback` (Sambar · Too salty, 6 students, lunch Wed
  14 Aug) plus what other students sent in the run. The frame's "1 other" on Too spicy is not in any data, so it is not
  shown. A problem nobody reported has no count (never "0 others"). Offline the counts cannot be read, so none show.
- Sent (2159:150785) shows the dish, problem and how bad, the time, "See it in My feedback" and Done. The sent item is
  listed as Reported on My feedback and adds one student (and its how-bad) to the Admin's "Feedback to act on" item, or
  starts a new item; never a name (`DemoDishFeedbackTally`).
- Offline: the send is refused by the data source, kept on the device (`keepForLater`), nothing is counted, and it is
  sent the next time Home loads online (`sendKept`, then `environment.dataDidChange()`).
- "Unsafe or unwell? Use SOS" is the only way from these sheets to SOS (route `sos` on Home, Meals and Search). The
  general Report flow is unchanged and still opens from its own entry points (Home header, Meals error card, You).
- Rules kept: ratings open for 2 days after the meal and changeable; no credits for Good, Not good or feedback.
- Service › Community on Which dish switches to the Community tab (`studentSelectTab`, set by `StudentRootView`).

Deviations from the frames (each says why):
- Sent title: the frame says "The kitchen saw it"; the prototype sends to no one, so it says "Sent" (the receipt line
  and time are as drawn). Thanks: the frame says "The kitchen saw it."; the app says "Your rating is saved."
- Masala Sambar uses Sambar's set: a dish matches a set when its name contains the set's key, as the pictogram rule does.
- A dish no frame draws gets six choices generated from the five frames' shared vocabulary (Too salty, Too spicy, Hard,
  Stale, Cold, Too little): **generated, owner to review**.
- Which dish has no Back (it is the first sheet); the frame draws one back to How was …, which is a card here.
- The How was breakfast sheet (2159:6) is drawn as a sheet with two faces; Home keeps its existing How was … card
  (built from the owner's 7 November image), which now leads into these sheets.

Files: `Domain/DishFeedback.swift`, `Data/Repositories/DishFeedbackRepository.swift`, `Data/Demo/DemoDishFeedback.swift`
(new); `Repositories.swift`, `DemoDataProvider.swift`, `DemoStudentRecords.swift`, `AdminSeed.swift` (additive wiring);
`StudentDishFeedbackViewModel.swift`, `StudentDishFeedbackViews.swift`, `StudentSOSViews.swift` (new);
`StudentRatingsViews.swift`, `StudentHomeView.swift`, `StudentMealsView.swift`, `StudentSearchView.swift`,
`StudentRootView.swift`; six problem glyphs from ProblemGlyph 2129:2324 in `StudentAssets.xcassets`.

Tests: `DishFeedbackRepositoryTests` (6), `StudentDishFeedbackScreensTests` (8), and
`StudentRatingsScreensTests.testNotGoodRecordsNothingAndOpensThatDishsWhatsWrong` (replaces the hand-off-to-Report test).
Debug suite after G1: `xcodebuild … test` exit 0, 779 passed, 45 skipped, 0 failed.

Captures (`~/mealloop-captures/student-all/g1/`): Which dish, More dishes, What's wrong Sambar / Pongal / Milk, Note,
Sent, Thanks, Offline · Saved. Compared with the frames: layout, wording and states match except the deviations above;
the capture hosts the sheet over an empty screen, not over Home.
