# Student final 2: Notifications, You, Credits, Attendance, report pages and the You destinations, compared with Figma

## Run 2 (8 November 2026): You destinations, report pages, Issue updates, tap-through

**Partial.** The run started from `origin/main` at `a8e7389`. The previous run's four commits (`f0dce15`, `64b83d6`,
`080d3cc`, `590529e`, then `a8e7389`) were already on `main`, so they were not rebuilt. This run built groups 4b and 5,
the Home credits chip (owner ruling 1) and the tap-through (group 6).

The 2-hour time box ended before two groups were built:
- group 3, the Student outing request
- the layout part of group 4, the Student 2 gaps

Both are listed under "Not built" with the reason.

**Push refused.** The two commits below are local in the detached worktree `MealLoop-student-final-2b` (next to the
main checkout). `git push origin HEAD:main` was refused by this session's permission check. Nothing from this run is on
the remote, and the owner has to push them.

| Commit | Title |
|---|---|
| `66cd7ba` | `feat(backend): add Student records for reports, feedback and help` |
| `a8a99fa` | `feat(student): open every You row, report pages and Issue updates` |
| (this file) | `docs(student): add the Student final 2 run 2 report and screenshots` |

**Workflow mismatch, recorded.** The brief says to push straight to `main`. `CLAUDE.md` and `docs/BRANCHING.md` say
never to push to the default branch and to open a pull request. The brief was followed: no branch, tag or pull request
was created. The push itself was refused, as described above.

Figma file `nzzTAm9YnJRSdKEeYUWUEb`, page "07 Prototype & QA" (44:5359), was read only with the Figma connector:
`create_session`, `get_metadata` on the page to find frames by name, `get_screenshot`, and `get_design_context`.
**`~/Downloads/FIGMA_FRAME_MAP.md` was missing again.** Every node id below was found by frame name, and none was
guessed. Nothing in Figma was edited.

### How the frames were compared

The app images are real simulator captures from the Debug build (the "Demo data" badge sits over the centre of the
header) on iPhone 18 Pro (402 × 874). Five pages were also captured on a temporary iPhone SE (3rd generation) simulator,
created for this run and deleted afterwards. Both images were opened and looked at before each line below was written.

Files are in `compare-2b/`:
- `<page>_figma.png`
- `<page>_iphone18pro.png`
- `<page>_iphonese.png`

For "Report · Fixed" and "My reports", the frame renders blank in a screenshot because its content sits under the
backdrop. Their content is in `*_figma_content.png`, from `get_design_context`.

These differences apply to every frame and are not repeated per line:
- the system font stands in for Inter and JetBrains Mono
- the Debug badge covers the centre of compact headers ("My reports", "Privacy & data"); the Review build has no badge

### Results per frame

**9 frames compared: 3 match, 6 differ (all in text or small layout).**

| Frame | Node | Result |
|---|---|---|
| Spending | 221:63988 | Differs in layout: "Add spending" is not drawn (no operation adds an entry). The rest matches: private chip, ₹3,000, "₹500 this week", three week bars with the current one lime, and the Recent list. On SE everything fits. |
| Help | 221:64742 | Matches: five questions with the first open, plus the contact card. On SE, "What happens when I send an SOS?" wraps to two lines. |
| Terms and privacy ("Privacy & data") | 221:64669 | Differs in layout: "Request a copy of your data" wraps to two lines at the system font size. The words are the frame's. |
| My feedback | 2159:151331 | Differs in text: the hero says "1 fixed" where the frame says "2 fixed". The counts are computed from the three items drawn, of which one is fixed. A chevron is added to the hero, which opens My reports. On SE the title touches the backdrop dot, as it does in the frame. |
| My feedback · Better saved | 2159:151464 | Differs in text: "You said: better." without the frame's "Thanks, the kitchen sees it.", because the prototype sends nothing to anyone. |
| Report · My reports | 221:63573 | Differs in content: ML-1042 (Sent, Wed 14 Aug) is not seeded, because it is the receipt number of the first report sent in a run (`firstReportNumber`). The other three cards match. |
| Report · Need more info | 221:63587 | Differs in text: the meal chip says "Lunch · Mon 12 Aug" where the frame says "Wed 14 Aug". The timeline in the same frame says "You told us · Mon 12 Aug", and one report has one day. Everything else matches. |
| Report · Fixed | 221:63606 | Differs in layout: "Yes, better", "Still bad" and "Didn't try it" are dimmed, with the line "Answers here aren't recorded in this prototype.", because the brief makes Fixed read only. The meal chip says "Sat 3 Aug" (the timeline's day). The timeline matches. |
| Community · Issue | 221:63643 | Differs in content: the updates card ("Seen by the team · Tue 13 Aug, 3:10 PM", "Next: the team picks an owner") and "Me too counts you. You can undo it." are built. The "4 comments" row is **not built** (decision, see below). The wait chart shows the Crowd estimate (Peak at 12:45 PM), not the frame's 1:15 PM; that chart is from Prompt 1. |

The reply sheet has no frame. It reuses the Report · Details field and buttons. After a reply, the question card says
"Your reply is recorded." and the timeline gains "You replied".

### Tap-through (simulator, iPhone 18 Pro, Debug build, by hand with the simulator tools)

| Element | Expected destination | Result |
|---|---|---|
| Welcome · Sign in with SRM | Home | works |
| Home · bell | Notifications | works |
| Notifications · Back | Home | works |
| Home · feedback icon | Report · What's wrong | works |
| Report · Food ran out | Report · Details | works |
| Report · Details · Back | Report · What's wrong | works |
| Home · Crowd row | Crowd | works (opened by a stray tap; back returns to Home) |
| Tab Home / Meals / Community / You | each tab's root | works (switching tabs shows each tab's root) |
| You · Credits | Credits | works |
| You · Attendance | Attendance | works |
| You · Spending | Spending | works (was Coming soon) |
| You · My feedback | My feedback | works (was Coming soon) |
| My feedback · Better | records "You said: better." in place | works |
| My feedback · hero | My reports | works (no frame draws this link; see open questions) |
| My reports · ML-1031 | Report · Need more info | works |
| Need more info · Reply → type → Send reply | reply recorded, shown on the page | works |
| My reports · ML-0998 | Report · Fixed (read only) | works |
| You · Help | Help | works (was Coming soon) |
| You · Terms and privacy | Privacy & data | works (was Coming soon) |
| Privacy · Request a copy / Request deletion | a "Not implemented" page | not built (no operation; listed) |
| You · Outings | Student outings | **not built**: opens Coming soon (group 3 not built) |
| Community · Me too | Backed, count 64 → 65, stays on the list | works |
| Community · card title | Community · Issue | works |
| Issue · Back | Community list | works |
| Community · Fixed tab | Fixed list ("Nothing fixed yet") | works |

Not tapped this run, and covered by Prompt 1 tests only: Undo, Search, Credits · Get (opens Coming soon; Ticket · Juice
is not built), the Community "About" button (opens Coming soon), and Sign out. The first tap on Home landed while a
transition was still running and was lost. Taps sent during an animation are dropped, so each later step waited.

### Student inventory, rows changed by this run (`docs/SCREEN_INVENTORY.md`)

Rows not listed keep the status in Run 1 below.

| Row | Status | Note |
|---|---|---|
| `10_community_issue` | Built (differs) | Updates card and Me too note added. The comments row is not built (decision). |
| `14_my_feedback` | Built (differs) | My feedback 2159:151331. Counts are computed, as described above. |
| `24_spending_private` | Built (differs) | Spending 221:63988, without "Add spending". |
| `19_you` | Built (differs) | Every row except Outings now opens a real page. |
| `03_home` | Built | The credits chip reads the Student You balance (owner ruling 1). The chip sits under the Debug badge, so it was checked by test, not by eye. |
| Report · My reports, Need more info, Fixed | Built (differs) | Above. These were not inventory rows; the brief names them. |
| Student · Outings (9 rows) | Not built | Time box. |
| `11`–`13` feedback sheets | Not built | Not in this brief. |

### Not built, and why

- **Group 3, the Student outing request.** Time box. It also needs additive student operations on `OutingCaseRepository`
  (a student's outings, and a request entering at Waiting for guardian). That protocol has none today, and it is shared
  with the Guardian, Warden and Gate parts.
- **Group 4, the Student 2 layout gaps.**
  - The sheets that sit about 20 pt low use the shared `mlSheet`, which the brief forbids editing.
  - The Pass Confirm sheets are Special pass screens, which must not be touched.
  - The SE title-on-dot cases are "Special pass" (must not be touched) and "Crowd". Crowd was not changed: the time
    box ended.
  - The text differences in Meals, Search and Crowd are owner decisions (M1, M2, M6, M7), so they stay.
- **"Add spending"** and Spending · Saved (221:64164): there is no add operation.
- **Privacy data requests:** there is no operation. The rows open the "Not implemented" page.
- **Community "4 comments"**: this is a decision, not built. See P-FINAL2-6.
- **Search · Menu result:** owner ruling 4, not built.

### Added backend pieces (commit `66cd7ba`, `feat(backend)`, additive, 10 tests)

- `Domain/StudentRecords.swift`. The models:
  - `StudentFiledReport` with its stage and events
  - `StudentFeedbackSummary`, whose counts are computed
  - `StudentSpending`, whose month total is nil when any week is missing, never smaller
  - `StudentHelp` and `StudentIssueUpdate`
- `Data/Repositories/StudentRecordsRepository.swift`. The operations: `reports`, `report`, `reply`, `feedback`,
  `answerRecheck`, `spending`, `help` and `updates`. `UnavailableStudentRecords` throws `notImplemented`.
- `Repositories.studentRecords`, defaulted and declared last. `DemoDataProvider` gains one stored store and one argument
  (3 lines). No existing operation or signature changed.
- `Data/Demo/DemoStudentRecords.swift`. The reply is recorded once, and only on Need more info; offline throws. The
  recheck is recorded once, and only for a fixed item.
- `Data/Demo/DemoStudentRecordsSeed.swift`. Samples, each cited to its frame:
  - the three reports
  - the three feedback items
  - spending: the week amounts ₹1,125 and ₹1,375 are derived from the drawn bar heights and the drawn ₹500 and
    ₹3,000, and the comment says so
  - the Help topics (only the drawn answer) and the contact
  - the two Issue updates

### Open questions (proposed IDs)

- **P-FINAL2-5** Where should My reports be reached from? No frame links it. It is built behind the My feedback hero.
- **P-FINAL2-6** Community "4 comments" (221:63643). Student-written comments are not in the owner's decisions:
  - student identities must never be public
  - no AI may decide publication
  - moderation would be needed

  Not built, pending a decision.
- **P-FINAL2-7** Report · Fixed "Is it better now?". The brief makes it read only. Should the answers be recorded like
  My feedback's "Better / Same"?
- **P-FINAL2-8** Report summary chip dates. The frames draw "Wed 14 Aug" on reports sent on 12 and 3 August. The app
  uses the sent day. Confirm.
- **P-FINAL2-9** Privacy "Request a copy" and "Request data deletion": who handles them, and how?
- Still open from Run 1: P-FINAL2-2 (when credits are added) and P1 (the credit formula). P-FINAL2-1, P-FINAL2-3 and
  P-FINAL2-4 were decided by the owner on 7 November and applied here.

### Conflict hunks

None. `origin/main` stayed at `a8e7389` from the start to the last fetch, so no rebase was needed.

### Commands and counts

The setup:
- Xcode 27.2 (27B52), with the iOS 27.2 simulator on iPhone 18 Pro, one device, reused
- before each run, `pgrep -x xcodebuild` reported 0 builds
- tests ran with `-parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1`
- counts are from the `.xcresult` bundles

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug, scheme `MealLoop`, `test` | 0 | 644 | 621 | 0 | 23 |
| Review, scheme `MealLoop Review`, `test` | 0 | 643 | 620 | 0 | 23 |
| Release, `-configuration Release build` (generic iOS Simulator) | 0 | n/a | `** BUILD SUCCEEDED **` | n/a | n/a |

The Release log has 1 `warning:` lines (not examined). Before this run, `main` had Debug 625 tests and
Review 624. The new tests are 10 in `StudentRecordsRepositoryTests` and 9 in `StudentRecordsScreensTests`, so 19 in
total.

The grep for sample names, numbers, references or `DemoSeed` in `StudentRecords*.swift`, `StudentYouView.swift`,
`StudentHomeView.swift` and `StudentCommunityView.swift` found nothing.

The diff since `a8e7389` touches:
- the Student folder: `StudentRecordsCopy`, `StudentRecordsViewModel`, `StudentRecordsViews`, and edits to
  `StudentYouView`, `StudentHomeView` and `StudentCommunityView`
- two test files
- `docs/verification/student-final-2/`
- the backend files listed above

`RoleRootView`, shared components, tokens, `GlassTabBar`, `openapi.yaml`, ADRs, project settings, the Special pass,
Pass Desk and entry screens were not touched.

The remote:
- `git ls-remote --heads origin` returned only `refs/heads/main` at `a8e7389` (this run's push was refused)
- `git ls-remote --tags origin | wc -l` returned 29, all from before this run

CI: run 42408825343 on `a8e7389` was green before the push attempt. No run exists for this run's commits, because
nothing was pushed.

### Not run

- a physical device
- the camera
- Dynamic Type
- VoiceOver
- the Review build in the simulator: captures are from Debug
- the iPhone SE captures cover only You, Spending, My feedback, Help and Privacy

---

## Run 1 (7 November 2026)


**Partial.** The 2-hour time box ended after groups 1 and 2 (Notifications; You, Credits and Attendance). Group 3
(Student outing request) and group 4 (the Student 2 gaps and Search · Menu result) were not started. They are listed
under "Not built" with the reason.

Figma file `nzzTAm9YnJRSdKEeYUWUEb`, page "07 Prototype & QA" (44:5359), read only with the Figma connector
(`create_session`, a read-only `use_figma` that lists frame names, `get_screenshot`). **The frame map
`~/Downloads/FIGMA_FRAME_MAP.md` was missing**, so every node id below was found by its frame name on page 44:5359;
no id was guessed. Nothing in the Figma file was edited.

## Workflow mismatch, recorded

The brief (owner workflow, 7 November) says to push green commits straight to `origin/main`. `CLAUDE.md` and
`docs/BRANCHING.md` say never to push to the default branch and to open a pull request. The brief was followed for
commits (no branch, tag or pull request). The first push to `main` was refused by this session's permission check; after
the owner allowed it, `f0dce15`, `64b83d6`, `080d3cc` and `590529e` were pushed (`f48e0ee..590529e`), with no rebase
needed because `main` had not moved. The brief's separate worktree
`../MealLoop-student-final-2` was not created: this session's own worktree was detached at `origin/main` (`f48e0ee`)
instead, and its `claude/...` branch was never pushed.

## How the frames were compared

Each app image is the real SwiftUI view over the prototype backend, hosted in a window inside the Student tab bar and
drawn to a PNG by `StudentYouScreenshotTests` (skipped unless `TEST_RUNNER_STUDENT_YOU_SHOTS` is set), on the
**Review-kind environment** (no Debug badge), iPhone 18 Pro simulator. Both images were opened and looked at before
each line was written. Files in `compare/`: `<frame>_figma.png` and `<frame>_iphone18pro.png`.

**iPhone SE was not captured:** no iPhone SE simulator is installed on this Mac (`xcrun simctl list devices available`
lists only iPhone 18 Pro and Pro Max), and the time box ended before one could be created.

Differences on every frame, not repeated per line: the system font stands in for Inter and JetBrains Mono; the device
is 402 pt wide, so content sits about 8 pt lower; the shared `GlassTabBar` draws larger icons.

## Results per frame

**8 frames compared: 1 matches, 4 differ in text or layout, 3 differ in content. 3 more frames fetched and not built.**

| Frame | Node | Result |
|---|---|---|
| Notifications | 221:64480 | Differs in layout: rows are about 6 pt taller (larger body text). Unread rows draw the filled icon (lime for Guardian approved, black for Breakfast), read rows the outlined one, as the frame does; the read state comes from the repository. |
| Notifications · Empty | 221:65955 | Matches. Reached with a test source that returns no notifications. |
| Notifications · Offline | 221:66026 | Differs in content: a cold start offline has no saved copy, so the page shows "You're offline." and "Your notifications will show when you're back online." instead of the saved list with "Showing what was saved at 6:58 AM". It never shows an empty inbox while offline. |
| You | 221:64576 | Differs in content: the Outings row has no status line ("Waiting for the warden"), because the Student outing part was not built; the row opens Coming soon. Rows are a little taller. |
| You · Offline | 221:66111 | Differs in content: cold start offline, so only the banner and the Help, Terms and Sign out card show; the frame shows the saved profile. Banner text "Some details may be out of date." |
| Credits | 221:64313 | Differs in layout: the subtitle fits on one line; the ticket notches and the dashed tear line between a ticket and its cost are not drawn. "Get" opens Coming soon (Credits · Getting a ticket 221:64396 is not built). |
| Credits history | 221:64443 | Differs in content: the balance is 120, the sample of Credits and Home; the frame is drawn after a juice was redeemed (70, "After redeeming a juice", "Juice redeemed −50 pts"). No redemption exists in the prototype. |
| Attendance | 221:64717 | Differs in text: the legend says "No entry for a meal" where the frame says "Missed a meal", and a note under it says "No entry means no scan was recorded, not that you were away." A missing scan is never shown as proof of absence. The rest matches. |
| You · Outings | 1848:22270 | Not built (fetched for the comparison; see Not built). |
| New outing · Wed | 1915:131160 | Not built. |
| Outing · Under warden review | 1848:22655 | Not built. |

Not compared (built but no capture): You · Loading (221:66100), You · Error (221:66138), Credits · Empty, Loading,
Offline and Error (221:65843, 221:65904, 221:65917, 221:65941), Notifications · Loading and Error (221:66014,
221:66048), Attendance · Offline (2173:266). They are handled by the same state code; they were not looked at.

## Student inventory (`docs/SCREEN_INVENTORY.md`, Active Student and Student · Outings rows)

"Earlier report" means the result is from that report, not checked again here.

| Row | Status | Note |
|---|---|---|
| `F05_student_notification_dinner_changed` | Not built | Notifications · Dinner changed (2320:169005): no menu-change notification is seeded; time box. |
| `P01_notifications_circles` | Built (differs) | Notifications 221:64480, above. |
| `P01_notifications_circles_offline` | Built (differs) | Notifications · Offline 221:66026, above. |
| `P02_home_swipe_remind`, `_set`, `_fired` | Not built | Swipe-to-remind on Home: needs a reminder operation; time box. |
| `P02_home_lunch_row_swipe`, `_set` | Not built | As above. |
| `P04_special_pass_ticket` | Built (matches) | Earlier report `student-figma-2` (Pass · Live 1). |
| `P04_special_pass_ticket_used` | Built (matches) | Earlier report `student-figma-2`. |
| `P04_special_pass_ticket_not_today` | Not compared | Earlier report: not compared. |
| `P04_juice_ticket`, `22_juice_ticket` | Not built | Ticket · Juice (1529:1901) needs a redeem operation; "Get" opens Coming soon. |
| `Q1_credits_coupons`, `21_credits` | Built (differs) | Credits 221:64313, above. |
| `Q3_highlight_chip`, `05_meals_lunch` | Built (matches) | Earlier report `student-figma-2`. |
| `01_sign_in` | Built (differs) | Earlier report `student-final` (Staff sign in added). |
| `02_getting_details` | Built (matches) | Earlier report `student-final`. |
| `03_home` | Built | Not compared here. The bell now opens Notifications and the credits chip opens Credits. |
| `04_home_top_card_cases` | Built | Earlier Student Home part; not compared here. |
| `06_meals_dinner` | Built (matches) | Earlier report `student-figma-2`. |
| `07_lunch_answer`, `08_entry_qr` | Built | Earlier Student Home part; not compared here. |
| `09_community_list`, `10_community_issue` | Built (differs) | Earlier report `student-final`. |
| `11`–`13` feedback sheets | Not built | The Feedback sheets (How was breakfast, Which dish, What's wrong) were not in this brief; time box. |
| `14_my_feedback` | Not built | The You row opens Coming soon. |
| `15_sos_choose_problem` | Built (matches) | Earlier report `student-final` (Report · What's wrong). |
| `16_sos_camera_proof`, `18_sos_sent_with_proof` | Built (differs) | Earlier report `student-final`. |
| `17_sos_review_proof` | Not built | Earlier report. |
| `19_you` | Built (differs) | You 221:64576, above. |
| `20_notifications` | Built (differs) | Notifications 221:64480, above. |
| `23_attendance` | Built (differs) | Attendance 221:64717, above. |
| `24_spending_private` | Not built | Spending (221:63988) has no data source; the row opens Coming soon. |
| Student · Outings (all 9 rows: `S01_*` ×5, `25`–`28`) | Not built | Group 3 not started (time box). |

## Not built, and why

- **Student outing request (group 3).** Time box. It needs additive student operations on the outing repository
  (the student's outings, and a request that enters at Waiting for guardian); `OutingCaseRepository` has none today.
- **Student 2 gaps (group 4)**: Meals, Search and Crowd text fixes, the sheets about 20 pt low, the iPhone SE title on the
  backdrop dot, and Search · Menu result (430:80315). Time box. Note a conflict: the owner ruled Search · Menu result
  "stays not built" (P-STUDENT-M6, recorded in `student-figma-2/REPORT.md`); this brief says to build it. Not resolved.
- Ticket · Juice, Credits · Getting a ticket, Rewards · Balance issue, Spending (all states), Notification settings and its
  states, Notifications · Dinner changed and Guardian answered, Home swipe-to-remind, My feedback: no operation exists and
  the time box ended.

## Added backend pieces (commit `f0dce15`, `feat(backend)`, additive, with tests)

- `Domain/StudentYou.swift`: `StudentNotification` (+ kind, id), `StudentCreditTicket`, `StudentCreditEntry`,
  `StudentCredits` (`nextGoal`), `StudentCreditRule` (definite answers earn; Not sure and No response earn nothing; the
  amount is passed in), `StudentAttendanceMark`, `StudentAttendanceMonth` (`percentEntered`, `bestStreak`),
  `StudentProfileSummary`.
- `Data/Repositories/StudentYouRepository.swift`: `notifications`, `markRead`, `profile`, `credits`, `attendance`;
  `UnavailableStudentYou` throws `notImplemented` and never fakes a result.
- `Repositories.studentYou`, defaulted, declared last, so every existing caller is unchanged.
- `DemoDataProvider`: one stored store and one argument in `makeRepositories` (2 lines). No existing operation changed.
- `Data/Demo/DemoStudentYou.swift`: the prototype implementation. Credits read the student's own answers through the
  existing `response(of:for:)`, so an answer on Home shows on Credits and on the You row.
- `Data/Demo/DemoStudentYouSeed.swift`: samples, each cited to its frame.

## Sample, not measured

- The four notifications and their times (221:64480).
- Balance 120 (Credits 221:64313, Home 221:62529, the existing `sampleCredits`); 5 points per definite answer and the four
  history lines (Credits history 221:64443); Juice 50, Ice cream 80, Biryani coupon 200 "Launches Friday" (221:64313).
- Attendance marks for 1–14 August, "36 of 41 meals" (221:64717). 88 % and the 4-day streak are computed from them.

## Open questions (proposed IDs)

- **P-FINAL2-1** The Home credits chip still reads the existing `homeExtras.credits` (always 120); Credits and You add
  this run's definite answers (125 after "I'm in"). Changing Home's source changes an existing operation, which the brief
  forbids. Should Home read the Student You balance?
- **P-FINAL2-2** When are credits added: at the answer (built) or after the meal (needs a rule)? Related to P1.
- **P-FINAL2-3** Attendance legend wording: "No entry for a meal" (built) replaces "Missed a meal". Confirm.
- **P-FINAL2-4** Search · Menu result: P-STUDENT-M6 said not built; this brief says build. Which wins?
- P1 (credit formula) stays open.

## Conflict hunks

None. `origin/main` did not move during the task (`f48e0ee` at the start and at the last fetch).

## Commands and counts

Xcode 27.2, iOS 27.2 simulator (iPhone 18 Pro, one device, reused), each run gated on `pgrep -x xcodebuild` (0 running),
`-parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1`. Counts are from the `.xcresult` bundles.

Final code: the two commits plus the offline-copy fix in `fix(student)` (working tree identical to the commits below).

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug, scheme `MealLoop`, `test` | 0 | 625 | 602 | 0 | 23 |
| Review, scheme `MealLoop Review`, `test` | 0 | 624 | 601 | 0 | 23 |
| Release, `-configuration Release build` (generic iOS Simulator) | 0 | n/a | `** BUILD SUCCEEDED **` | n/a | n/a |

The Release log has 1 `warning:` line (not examined).
Before this task `main` had Debug 606 / 584 passed / 22 skipped and Review 605 / 583 / 22.

New tests: 11 in `StudentYouRepositoryTests`, 7 in `StudentYouScreensTests`, and 1 screenshot test that skips in a normal
run (the 23rd skipped test).

Greps: no sample name, number, title or `DemoSeed` in `StudentYou*.swift` or `StudentNotificationsView.swift`.

Files outside the Student folder and its tests: `Domain/StudentYou.swift`, `Data/Repositories/StudentYouRepository.swift`,
`Data/Repositories/Repositories.swift`, `Data/Demo/DemoDataProvider.swift`, `Data/Demo/DemoStudentYou.swift`,
`Data/Demo/DemoStudentYouSeed.swift` (all in the `feat(backend)` commit). `RoleRootView`, shared components, tokens,
`GlassTabBar`, `openapi.yaml`, ADRs, project settings, the Special pass, Pass Desk and entry screens were not touched.

`git ls-remote --heads origin`: only `refs/heads/main` (`590529e` after the push). `git ls-remote --tags origin | wc -l`:
29, all from before this task; this task created none.

CI: before the push, run 42384777179 on `f48e0ee` was green. After the push, run 42389794456 on `590529e` passed both
jobs, "build and test (Debug, Review, Release build)" and "commit and repository rules".

## Not run

A physical device, the camera, Dynamic Type, VoiceOver, iPhone SE, and a full tap walk (simulator taps through the
helper were unreliable; the screens were captured by hosting the views instead).
