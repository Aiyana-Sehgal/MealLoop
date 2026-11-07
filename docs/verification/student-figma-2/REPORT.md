# Student 2 of 3: Meals, Special pass and Crowd, compared with Figma

Branch `feat/ios-student-meals-pass`, base `feature/swiftui-foundation` at `42e8c6c` (the merge of PR #24, Student 1).
Figma file `nzzTAm9YnJRSdKEeYUWUEb`, page 07, read with the Figma connector (`create_session`, `get_screenshot`,
`get_metadata`, `get_design_context` on 221:62892 Content). Nothing in the Figma file was edited.

## How the frames were compared

Each frame below was captured from the **Review** build on an iPhone 18 Pro simulator (402 × 874 pt) and an iPhone SE
(3rd generation), and put next to the Figma screenshot at the same height. Both images were looked at before the line was
written. The files are in `compare/`: `<frame>.png` is Figma | iPhone 18 Pro | iPhone SE.

Many states need a time or a failure the Review story does not reach by tapping (the story starts at 7:00 AM). Those
were captured from a scratch copy of the app with launch hooks (clock, offline, a slow or failing menu, a started or
used pass). The hooks were never committed. "Hook" marks them below.

Differences on every frame, not repeated per line: the system font stands in for Inter and JetBrains Mono; the device is
402 pt wide with its own status bar and safe area, so content sits about 8 pt lower than on the 393 pt frame; the shared
`GlassTabBar` draws larger icons. A line says "matches" only when nothing else differs.

## Results per frame

**30 frames compared: 18 match, 6 differ in text only, 6 differ in layout or content. 1 frame not built.**

| Frame | Node | Result |
|---|---|---|
| Meals · Wed 14 · Lunch | 221:62892 | Matches. |
| Meals · Menu changed | 221:64980 | Matches. Hook: the 11:10 AM change time (in the app it is when the Food Head saves). |
| Meals · Service ended | 221:65007 | Matches. Hook: story clock 2:10 PM with Lunch picked. |
| Meals · Not published | 221:65026 | Matches. Hook: no seeded day is unpublished. |
| Meals · No menu | 221:65036 | Matches. Hook (in the app: the Food Head empties a meal). |
| Meals · Loading | 221:65046 | Matches. Hook: a slow menu. |
| Meals · Offline | 221:65059 | Differs in text: "saved at 7:00 AM" where the frame says 6:58 AM; the time is when this phone last loaded the menu. Hook. |
| Meals · Error | 221:65084 | Differs in layout: "Try again" is a button with a 44 pt tap area, so the card is about 20 pt taller. Hook. |
| Meals · Dish detail | 221:62916 | Matches. Hook: opened straight on Sambar. |
| Meals · Wed 14 · Breakfast | 1339:105019 | Matches. |
| Meals · Wed 14 · Snacks | 2150:136464 | Matches. |
| Meals · Wed 14 · Dinner | 1339:104742 | Matches. |
| Meals · Highlight info (sheet) | 2150:140175 | Differs in layout: the shared sheet starts about 20 pt lower and has no blurred page behind its lower part. |
| Search · No results | 430:80333 | Differs in text: "Search looks through this week's menu. Try another dish." and only "sambar" and "paneer" to try, because Search finds dishes only (P-STUDENT-M6). |
| Pass · Available | 221:63168 | Matches. |
| Pass · Confirm (holding) | 221:63180 | Differs in layout: the sheet edge sits about 20 pt lower, as on the highlight sheet. Hook: the hold drawn at 60 %. |
| Pass · Confirm (sending) | 221:63196 | Differs in layout: the same sheet edge. Hook. |
| Pass · Confirm (failed) | 221:65276 | Differs in layout: the same sheet edge. Hook. |
| Pass · Live 1 | 221:63212 | Matches (7A3F Lime). Hook: started pass, countdown held at 9 s. |
| Pass · Live 2 | 221:63219 | Matches (K2M9 Blue). Hook. |
| Pass · Live 3 | 221:63226 | Differs in content: 218 Lime where the frame draws 4XQD Orange, which is not a seeded code (P-STUDENT-M4). Hook. |
| Pass · Live (Reduce Motion) | 221:65349 | Matches. Hook: Reduce Motion forced on. |
| Pass · Used | 221:63233 | Matches. Hook: the door records the entry while the code shows. |
| Pass · Not eligible | 221:65293 | Matches. Hook: no pass. |
| Pass · Expired | 221:65302 | Differs in text: the crowd row says "Quiet now · Updated 2:15" (the estimate after lunch closed) where the frame says "Getting busy · Updated 12:08". Hook: lunch closed at 2:00 PM. |
| Pass · Already used | 221:65314 | Differs in text: "Updated 12:32" on the crowd row, the time it loaded, where the frame says 12:08. Hook. |
| Pass · Wrong mess | 221:65326 | Matches. Hook: another mess. |
| Pass · Unavailable | 221:65338 | Matches. Hook: the pass service offline. |
| Crowd · Main Mess | 221:63246 | Differs in text: "Busy now · Quieter after 1:30 PM" where the frame says "Quiet now · Best time 1:30 PM" (P-STUDENT-M1), and "· ESTIMATE" added to the top line (P-STUDENT-M2). Hook: lunch in service at 12:10. |
| Crowd · Main Mess · Offline | 221:65361 | Differs in text: "Busy at 12:02 · Quieter after" for the same reason; the tiles are not faded behind the tab bar. Hook. |

iPhone SE: every screen fits its width. The Live and Used tickets run under the tab bar and need a scroll to show the
holder row, and the large titles "Special pass" and "Crowd" touch the backdrop's dot, which is fixed on screen.

## Not built, and why

- **Search · Menu result (430:80315)** (`compare/menu_result_80315_not_built.png` shows the frame next to the results list that is built instead): the result page with "Ended", "Also on" and "Open in menu". A search result
  opens the Dish page instead. The owner ruling gives Search one function, finding dishes by name, and this page
  needs "Also on" logic and an "Open in menu" jump that no brief asks for. Proposed as P-STUDENT-M6.
- Frames outside the brief's list were not compared: the 24 other "Meals · <day> · <meal> · new" frames (the same
  screen, other days; they use the board's own tiers, see P-STUDENT-M8), Pass · Not today · new, the six
  "Crowd · Main Mess · <state> · new" frames, Search · Empty, Typing and Offline.

## Added backend pieces (all additive, commit `30d37ca`, with tests)

- `Domain/StudentMeals.swift`: `StudentWeek`, `StudentMenuStatus`, `StudentSpecialMeal`, `StudentMealMenu`,
  `StudentDishDetail`, `StudentDishMatch`, `StudentPassTicket`, `StudentPassStanding`, `StudentCrowdSlot`, `StudentCrowd`.
- `Data/Repositories/StudentMealsRepository.swift`: `week`, `mealMenu`, `dishDetail`, `findDishes`, `passStanding`,
  `startPass` (idempotent by key), `crowd`; `UnavailableStudentMeals` throws "not implemented" and never fakes a result.
- `Repositories.studentMeals`, defaulted, so fakes and the remote source do not change.
- `DemoDataProvider`: the implementation above, plus two state fields (`passStarts`, `passStartResults`). The live code
  still comes from the Pass Desk's `refreshPassCode`; the desk's `lookUpPass` and `recordPassEntry` are unchanged, and
  a desk record turns the student's pass to Used.
- `DemoAdminStore` notes when the Food Head changes a day's menu (`menuChangedAt`, `noteMenuChange`); `saveDay` and
  `applyToTodaysDinner` call it after saving and return exactly what they did before. This is what drives "The mess
  updated this menu at …".
- `Data/Demo/DemoStudentMealsSeed.swift`: samples, each cited to its frame or to `mess_menu_2024-08-12.md`.

The menu comes from `AdminMenuSeed`, the board of `mess_menu_2024-08-12.md` as the Food Head keeps it, so an admin edit
shows on the student's Meals tab.

## Sample, not measured

- Which Wednesday dishes are tiles, curries and "Comes with it" (the four Wednesday Meals frames).
- Snacks has no serving time: no document gives one, so none is shown and it is skipped in "Dinner opens …".
- Sambar's portion and allergens, "1 bowl, Mustard seeds, Curry leaves", "Verified by mess · Mon 12 Aug" (221:62916).
  No other dish has details; the Dish page says so.
- "Chicken Briyani · Panneer Briyani", "Alternate Wednesday special", "Limited" (board footer and 221:62892).
- "This pass is for Main Mess, Block A" (221:65326).
- Crowd: the eight bar heights, the best-time slot (1:30 PM), "2 min" wait now, "18 min" at 12:45 PM (221:63246).
- Pass codes and colours are the Pass Desk's existing samples (218 Lime, K2M9 Blue, 7A3F Lime). The 10 s window is the
  existing `passCodeWindow`.

## Open questions (proposed IDs)

- **P-STUDENT-M1 Crowd word during service.** Home's Crowd row says Busy while a meal is served. Crowd · Main Mess draws
  "Quiet now" at 12:10. The Crowd page uses the same estimate as Home so the two never disagree, so at 12:10 it says
  "Busy now · Quieter after 1:30 PM". Which should it be?
- **P-STUDENT-M2 Estimate label.** The brief asks for a clear estimate label; the frame has none. The Crowd card's top line
  reads "LUNCH · 12:10 PM · ESTIMATE", and VoiceOver says "Estimate from door entries, not a head count".
- **P-STUDENT-M3 Crowd bars.** The bars are the drawn pattern, not door entries counted per 15 minutes. Should the real
  service compute them from recorded entries, and how many entries count as "enough"? Too few shows "Not enough entries
  yet" (built and tested).
- **P-STUDENT-M4 4XQD Orange.** Pass · Live 3 draws 4XQD Orange, which is not among the Pass Desk's sample codes. Adding it
  would change the desk's rotation, which this brief does not allow. Live 3 is captured with the next seeded code.
- **P-STUDENT-M5 When "Use pass" works.** No document says how early a student may start the pass. The prototype allows it
  any time before the meal ends; the desk still records only during the meal.
- **P-STUDENT-M6 Search scope.** The No results frame says Search covers "Community and Help" and suggests "Special pass" and
  "Help". Per the owner ruling only dishes are searched, so the copy says "this week's menu" and the suggestions are
  "sambar" and "paneer". Search · Menu result is not built.
- **P-STUDENT-M7 "The mess usually posts it by 6 AM."** Frame copy on Not published, kept as drawn. No policy document
  gives the time.
- **P-STUDENT-M8 Tiers on other days.** Only the Wednesday frames say which dishes are tiles. Other days use the board's
  tiers (first highlighted veg dish on the black tile, other highlighted veg dishes as tiles, the rest "Comes with it",
  non-veg as slim rows). Should the Food Head mark mains in the admin Menu instead?
- P7, P8 and P9 follow their defaults: Snacks are menu only (with the frame's "(draft)" note), Highlight opens "Marked by
  the mess on the menu board" and says nothing more, and the `**` gravies are slim non-veg rows.

## Commands and counts

Final code `ddd496e` (the report commit adds only files under this folder). Xcode 27.2, iOS 27.2 simulators, one at a
time, `-parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1`, each run gated on
`pgrep -x xcodebuild`. Counts are from the `.xcresult` bundles.

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug, scheme `MealLoop`, `test` | 0 | 528 | 516 | 0 | 12 |
| Review, scheme `MealLoop Review`, `test` | 0 | 527 | 515 | 0 | 12 |
| Release, `-configuration Release build` | 0 | n/a | `** BUILD SUCCEEDED **` | n/a | n/a |

New tests: 19 in `StudentMealsRepositoryTests` and 13 in `StudentMealsScreensTests`; every existing test still passes
(the base had 496 in Debug).

Captures: 31 states on iPhone 18 Pro and 31 on iPhone SE (3rd generation), from the Review build with hooks. The
Review run of the capture script was interrupted once by the end of a session and run again in full; only the second
run is used.

Greps: no sample dish, name, code, time or `DemoSeed` in the Student views; no credential in the Student folder.
Files outside the Student folder and its tests: `Domain/StudentMeals.swift`, `Data/Repositories/StudentMealsRepository.swift`,
`Data/Repositories/Repositories.swift`, `Data/Demo/DemoDataProvider.swift`, `Data/Demo/DemoStudentMealsSeed.swift`,
`Data/Demo/AdminSeed.swift`.

## Not run

- A physical device, iOS 17, VoiceOver, Dynamic Type and real Reduce Motion (Reduce Motion was captured through a hook).
- A tap walk. Hold to use, the dish filter and the Home rows were checked by unit tests and captures, not by driving the
  UI; the hold gesture's timing on a real finger is not verified.
- The desk recording a pass while the student watches: tested in unit tests (`testTheLiveCodeTurnsUsedWhenTheDoorRecordsIt`),
  captured through a hook.
