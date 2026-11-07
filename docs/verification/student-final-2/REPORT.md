# Student final 2: Notifications, You, Credits and Attendance, compared with Figma

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
