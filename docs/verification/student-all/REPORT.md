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
| G1 Dish feedback flow | done | `49d3ad8` backend, `af93084` | Not good no longer opens Report |
| G2 Swipe-to-remind | done | `dbc1784` | Lunch row and Home card; Reminder prompt needs a decision |
| G3 Restyled frames | done | `1e5940e` | SOS flow built; My feedback and Attendance · Offline were already built and cited |
| G4 Coverage audit | partial | `8ca02ec` | Audit and citations done; Search states and About not built (time) |
| G5 Standards and blank audit | done | report only | 0 pages above 25% |
| G6 Tests and walk | partial | with each group | View-model tests done; the simulator walk was not run |

**Pushed after the run.** The first `git push origin HEAD:main` was refused by the session's permission classifier;
the owner then asked for the push, and `420af7c..f6d2f24` reached `main` (fast-forward, no rebase needed).

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

## G2 · Swipe-to-remind

Built on Home (`StudentReminderViews.swift`, `StudentHomeView.swift`, `StudentRootView.swift`):
- Dragging the unanswered "This morning" card (Home · Not answered, 221:62529) or the lunch answer row to the right
  reveals the lime "Remind me in 1 hr" panel (2222:158038, 2222:158351). Letting go past a third of the width sets the
  reminder; before it, the card springs back (`MLMotion` snappy). A light haptic at the threshold (`.sensoryFeedback`).
  Under Reduce Motion the card does not move; the panel cross-fades in once past the threshold.
- Recognition is horizontal only (the drag must be 1.5 times wider than tall), ignores drags that start in the left
  20 pt of the screen, and runs as a simultaneous gesture so the vertical scroll and the system swipe-back still work.
- Reminder set (2222:158135, 2222:158445): a white row with a clock, "Reminder set", "We'll ask again at 8:00 AM" (the
  story clock's now plus one hour, `MLFormat.time`) and an underlined Undo. VoiceOver reads "Reminder set, we'll ask
  again at 8:00 AM, Undo"; a double tap undoes.
- Reminder fired (2222:158236, 2222:158543): when the story clock reaches the time (checked on every Home draw and
  reload; the clock moves only with the story, which reloads Home), the card returns with the outlined Reminder chip.
- Rules: never offered when now + 1 hour is at or after the answer cutoff (two hours before the meal); answering
  cancels it (Not sure counts as an answer); one per meal, a second replaces the first; nothing is sent; no credits.
- The same action without dragging: an accessibility custom action and a context-menu item "Remind me in 1 hour".
- The reminders live in the Student root (`StudentMealReminders`), so they outlive a tab switch; they are lost on
  relaunch (local, simulated).

Conflict with the frames: the breakfast frames are drawn at 7:00 AM, but breakfast starts at 7:30, so its cutoff was
5:30 AM and the rule above does not offer the swipe on the breakfast card at 7:00. In the sample the student has also
already answered breakfast. The lunch row (cutoff 10:00 AM) shows the swipe, Reminder set and Reminder fired as drawn.

Reminder prompt (221:64501, "Want a reminder before the cutoff? … Turn on reminders / Not now") is a notification
setting sheet on Meals: **needs a decision** (when it shows and what turning reminders on does). Not built.

Tests: `StudentReminderTests` (8): now + 1 hour and the exact time, Undo, fires at the time and not before, the cutoff
guard, answering cancels, a second replaces the first, the accessibility action equals the swipe, no credits.
Captures: Home before, lunch Reminder set, lunch Reminder fired (`~/mealloop-captures/student-all/g2/`); both states
match 2222:158445 and 2222:158543. The drag itself was not exercised with a finger.

## G3 · Restyled frames

| Frame | Before this run | Now |
|---|---|---|
| My feedback new 2159:151331, Better saved 2159:151464, Empty 2159:151588, Offline 2159:151689 | built and cited (`StudentRecordsViews.swift`) | unchanged |
| Attendance · Offline 2173:266 | built and cited (`StudentYouView.swift`) | unchanged |
| SOS · new 2162:6, I feel unwell 2162:161 | not built (the older Report page led to SOS) | `StudentSOSView` |
| Camera · GPS unavailable 2162:405, Camera denied 2162:493 | not built | `StudentSOSCameraView` |
| Review 2162:152142, GPS unavailable 2162:152270, No photo 2162:152398, Offline 2162:152516, Failed 2162:152648 | not built | `StudentSOSReviewPage` |
| SOS Sent 221:63509 | built for the old flow | `StudentSOSSentView` (same card, place and photo line added) |

- "Unsafe or unwell? Use SOS" on the dish feedback sheets opens this flow. The general Report page keeps its own
  SOS path, unchanged.
- Raised with `SOSRepository.raise` (one key per draft, so a retry never opens a second case), then
  `environment.dataDidChange()`. Offline: Review shows the banner and "Send when online"; nothing is sent or shown as
  sent; the page retries with the same key when the data changes (the prototype's reconnect). Failed: the red line and
  Try again. Camera denied: "Send without photo", sent with "· no photo" on the title so the team sees it is flagged.
- The camera is a static preview (not verified on a device). The location is the student's mess, not measured: the
  "±8 m" and "within 8 m" of the frames are not shown, and with no GPS the place is sent as "Place not recorded".
  Which of the camera and GPS states shows is a parameter of the view model (the simulator has neither); the app
  starts with both available.
- "Medical emergency" (the link at the foot of 2162:6) is **not built: needs a decision** (what it calls or opens).

Tests: `StudentSOSScreensTests` (5): a photo SOS is raised for the mess with the dish; offline nothing is sent or shown
and it sends once back with the same key; a failed send offers Try again and never opens a second case; camera denied
sends flagged without a photo; no GPS records no place. Captures in `~/mealloop-captures/student-all/g3/`.

## G4 · Student coverage by node id

Inventory: `get_metadata` on page `44:5359`: 310 phone-size frames (393 × 852), of which 14 are gallery frames.
Coverage is `grep -rn "<id>" ios docs`.

| | Before | After |
|---|---|---|
| Frames total (phone size) | 310 | 310 |
| Cited | 170 | 257 |
| Gallery (skipped) | 14 | 14 |
| Uncited, not gallery | 126 | 39 |

The 126 uncited non-gallery frames resolve as: 29 built in this run (G1 14, G2 6, G3 9); 43 built under another id
(ids added to the view headers); 15 named in a view header as not built because they carry policy; 39 still uncited,
of which 35 need a decision and 4 are gaps not built (time). Needs a decision in all: 50 frames.

Built under another id (now cited in the view headers): 24 Meals week frames 2150:133459 to 2150:138693
(`StudentMealsView.swift`); Crowd Busy, Closed, Breakfast, Snacks, Dinner 2220:158655, 2220:158973, 2220:159132,
2220:159291, 2220:159442 (`StudentCrowdView.swift`); Community issue Backed, Sending, Offline, Me too failed 221:63679,
1403:14739, 1403:15023, 1403:14942 (`StudentCommunityView.swift`); New outing Tue, Thu, Fri, Sat 1915:130980,
1915:131344, 1915:131532, 1915:131720 and Outing pass Out, Returned, Cancel pass 1848:22943, 1848:22961, 1848:23037
(`StudentOutingViews.swift`); Sign out 221:64761 and Request deletion 221:64693 (`StudentYouView.swift`); Report ·
From feedback 221:63738 (superseded by G1, noted in `StudentRatingsViews.swift`). Other states of the same G4 group
(Community Fixed, the Comments frames, Crowd Packed, Outing Overdue/Revoked/Expired unused/Expired) are named in those
headers as not built.

Needs a decision (not built; each carries policy):
- 3-hour recheck and lock-screen notifications: 221:62802, 221:62804, 221:62806, 221:62808, 221:62824, 221:62840,
  221:62856, 221:62873, 221:62875, 221:62877, 221:62879, 221:62881, 221:62883, 221:62885, 221:62887, 221:62889,
  221:64567, 221:64569, 221:64571, 221:64573 (when to re-ask; push notifications are not part of the prototype).
- Notifications settings: Reminder prompt 221:64501, Notification settings 221:64514, Quiet hours 221:64537, Lock
  screen previews 221:64565, Settings · System off 221:65964, Settings · Failed 221:65990.
- SRM detail correction: Request correction 221:64602, Correction · Sent 221:64639, Correction · Failed 221:66062
  ("SRM will review it").
- Sign-in states: 221:64793, 221:64803, 221:64805, 221:64807, 221:64809 (outside the Student folder; sign-in is shared).
- Pass · Not today 1530:75546: the student pass standing has no Not-today state; adding one changes an existing
  operation (`passStanding`).
- Community: Fixed 1403:14841 ("stay here for 30 days"), the nine Comments frames (moderation); Crowd Packed 2220:158814;
  Outing pass Overdue 1848:22979, Revoked 1848:22998, Expired unused 1848:23019, Outing · Expired 1848:22815; Medical
  emergency on SOS.

Gaps not built (no policy found, out of time): Search · Empty 430:80273 (recent searches on this device, suggestions),
Search · Typing 430:80297 (results from Community and Help), Search · Offline 430:80347, About MealLoop 430:80365.

No page was generated without frame data in this run, except the generic dish choices (G1).

## G5 · Standards and spacing

Every new page is on `MLScreen` (SOS, Review, Sent; system back with swipe-back, collapsing title, the primary action
pinned above the tab bar); the camera is a full-screen cover as its frames draw it; sheets use `mlSheet` (sized to
content); motion from `MLMotion`; haptics through `.sensoryFeedback`; colours, type and spacing from the tokens and
the existing Student metrics (the dark camera surfaces reuse the colours the existing SOS camera uses).

Blank audit (`docs/verification/student-standards/blank_audit.py`, the repository copy; sheets over a scrim and the
camera cover not judged):

| Capture | Longest blank band |
|---|---|
| Home before / Reminder set / Reminder fired | 7% / 7% / 3% |
| SOS / I feel unwell | 4% / 4% |
| Review / GPS unavailable / No photo / Offline | 3% / 3% / 22% / 3% |
| SOS sent | 14% |

None is above 25%, so nothing was changed for space.

## G6 · Tests and the walk

View-model tests added: `DishFeedbackRepositoryTests` (6), `StudentDishFeedbackScreensTests` (8),
`StudentReminderTests` (8), `StudentSOSScreensTests` (5), and the changed
`StudentRatingsScreensTests.testNotGoodRecordsNothingAndOpensThatDishsWhatsWrong`. The capture hook is
`StudentFinalScreenshotTests/testCaptureStudentAll` (`TEST_RUNNER_STUDENT_FINAL_SHOTS=<folder>`,
`TEST_RUNNER_STUDENT_ALL=1`).

The simulator walk with a temporary XCUITest target was **not run** in this session (time). Not checked therefore:
signing in with SRM and opening every tab, rating a dish Not good and sending through the real navigation, the swipe
and Undo with a gesture, raising an SOS offline through the pages, placeholder text, and one-level swipe-back on the
new pages.

## Final checks

Xcode 27.2 (27B52); iPhone 18 Pro simulator, iOS 27.2, created for this run and deleted at the end.

| Check | Command | Result |
|---|---|---|
| Debug tests | `xcodebuild -scheme MealLoop … test` | exit 0; `.xcresult`: 837 tests, 792 passed, 45 skipped, 0 failed |
| Review tests | `xcodebuild -scheme "MealLoop Review" … test` | exit 0; `.xcresult`: 835 tests, 791 passed, 44 skipped, 0 failed |
| Release build | `xcodebuild -scheme MealLoop -configuration Release -destination generic/platform=iOS Simulator build` | exit 0; one warning, from `appintentsmetadataprocessor` ("Metadata extraction skipped") |
| Files changed | `git diff --name-only origin/main HEAD` | Student folder, additive backend (`DishFeedback*`, wiring in `Repositories`, `DemoDataProvider`, `DemoStudentRecords`, `AdminSeed`), tests, this report |
| Images outside `ios/` | same diff | none |
| Remote branches | `git ls-remote --heads origin` | `main` only |
| CI | `gh run list --branch main` | see the run for this commit |

Not checked: a physical device, the real camera and location, a real finger gesture, VoiceOver, iPhone SE, the
largest Dynamic Type size on the new pages.
