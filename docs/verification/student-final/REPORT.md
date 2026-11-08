# Student final: opening screens, Community, Report and SOS, compared with Figma

Pushed straight to `main` under the owner workflow of 7 November (no branch, tag or pull request). `CLAUDE.md` and
`docs/BRANCHING.md` say never to push to the default branch and to open a pull request; the brief overrides them, and
the mismatch is recorded here. Figma file `nzzTAm9YnJRSdKEeYUWUEb`, read with the Figma connector (`create_session`,
`get_screenshot`). The frame map was pasted by the owner and is not committed. Nothing in the Figma file was edited.

**Partial.** The 2-hour time box ended after Part A and Part B groups 1 and 2. Groups 3 to 6 are not built (below).

## Progress (resumable; updated after every group)

Built on 8 November 2026 from facts: the files in `ios/MealLoop/Features/Student/` and the frame comparisons in this
report and in `docs/verification/student-final-2/REPORT.md`. A group is `done` only when its frames were compared side
by side in a report. SwiftUI standards adoption (`MLScreen`, sized sheets, `MLMotion`) is tracked in its own column.
Last updated by run 2 (8 to 9 November 2026), below.

| Group | What | Status | Standards | Evidence |
|---|---|---|---|---|
| A | Opening screens and tab bar | partial | entry: done (Prompt 0) | compared in run 1 below; Welcome and Staff sign in rebuilt on `MLScreen` by Prompt 0 (`docs/verification/foundation-standards/`), not recompared here. Owner correction 3 pending |
| B0 | Student 1 differences | not started | not started | `docs/verification/student-figma-1/REPORT.md` |
| B0b | Home routes that open the wrong page | done | n/a | run 2: Meals error card opens Report, Home recheck row opens My feedback; feedback icon opened Report already |
| B1 | Community | done | info sheet only | 9 frames compared in run 1; Community · Info sheet in run 2 |
| B2 | Report and SOS | done | not started | run 1, and student-final-2 |
| B2b | Feedback ratings | done | done | run 2, owner images (no Figma frame); rules owner to confirm |
| B2c | Spending add, edit, delete | done | done | run 2 |
| B2d | Credits Get to the ticket | done | done | run 2 |
| B2e | Special pass redesign | done | sheet only | run 2, owner images; owner approval pending, one revertible commit (`eaa9659`) |
| B3 | Notifications | done | done | student-final-2 run 1; `MLScreen` in run 2 |
| B4 | You, credits, attendance | done | Credits, history, Attendance done; You root not | student-final-2 run 1 and 2; run 2 |
| B5 | Student outing request | partial | not started | student-final-2 run 3: Edit, Emergency, pass states other than Valid not built |
| B6 | Student 2 gaps | partial | not started | unchanged since student-final-2 |
| B7 | Coming soon sweep | done | n/a | run 2: 0 destinations reachable from a signed-in session |
| B8 | Empty-space audit | not started | n/a | time box |

## How the frames were compared

Each frame was captured from the **Review** build on iPhone 18 Pro and iPhone SE (3rd generation) and put next to the
Figma screenshot at the same height. Both images were looked at before each line was written. Files in `compare/`:
Figma | iPhone 18 Pro | iPhone SE. Most states were reached through launch hooks in a scratch copy of the app (clock,
offline, a slow or failing service, a set step); the hooks were never committed.

Differences on every frame, not repeated per line: the system font stands in for Inter and JetBrains Mono; the device
is 402 pt wide with its own status bar, so content sits about 8 pt lower; the shared `GlassTabBar` draws larger icons.

## Results per frame

**21 frames compared: 6 match, 6 differ in text only, 9 differ in layout or content.**

| Frame | Node | Result |
|---|---|---|
| Onboarding · Sign in (Welcome) | 221:62499 | Differs in layout: the build adds the Staff sign in button the frame does not draw (staff need a way in). Wordmark, mark and two-line terms now match. |
| Onboarding · Getting your details | 221:62501 | Matches. Hook: the step held on screen. |
| MS-0 · Sign in (Staff sign in) | 1508:45 | Differs in content: the frame is a branded page with the 3D loop and "Sign in with SRM" for staff; the build keeps the email and password form. Not changed: whether staff sign in with SRM is a product decision (P-FINAL-2). |
| Student tab bar (on Home · You're in) | 221:62548 | Matches. `StudentRootView` already used the glass capsule with Home, Meals, Community, You and the separate round glass Search; nothing was changed. |
| Community | 221:63630 | Differs in content: the cut-off third card "Curd runs out by 8:45 PM" is not seeded (the frame shows no stage or count for it). |
| Community · Issue | 221:63643 | Differs in content: "Peak at 12:45 PM" and the bar pattern come from the Crowd estimate (the frame says 1:15 PM); the timeline row under the chart is not built. Hook. |
| Community · Me too sending | 221:63655 | Differs in content: the third card, as on Community. Hook. |
| Community · Backed | 221:63667 | Differs in text: the count reads 39 after backing; the frame keeps 38. The backend counts the new backer. Hook. |
| Community · Empty | 221:65474 | Matches. Hook. |
| Community · Issue · Hidden | 221:65484 | Differs in content: the peak time and pattern, as on Issue. Hook. |
| Community · Fixed · Empty | 221:65493 | Differs in text: "Fixed problems show here." The frame says "stay here for 30 days"; no document sets a time. |
| Community · Loading | 221:65506 | Matches. Hook. |
| Community · Offline | 221:65518 | Differs in content: the third card. Hook. |
| Report · What's wrong | 221:63480 | Matches. |
| SOS · Camera | 221:63493 | Differs in text: "Main Mess" without "· ±8 m" (no location fix exists) and the time without seconds. A static preview: the simulator has no camera. Hook. |
| SOS · Sent | 221:63509 | Differs in content: the "photo attached · within 8 m" row and the Team told time are not built (no photo or location exists); the subtitle has no dish. Hook. |
| Report · Details | 221:63525 | Differs in text: chip "Main Mess" (the frame "Main Mess · Block A") and the time is the clock's. Add photo is shown disabled: no camera. Hook. |
| Report · Sending | 221:63541 | Differs in text: as Details. Hook. |
| Report · Receipt | 221:63557 | Differs in layout: the chips sit in their own rows and the hatched progress bar is not drawn. Hook. |
| Report · Failed | 221:65437 | Differs in text: as Details. Hook. |
| Report · No one on duty | 221:65454 | Matches. Hook: clock 6:30 AM, before the mess opens. |

## Not built, and why

- **Time box.** Notifications, You (credits, attendance), Student outing request, the Student 2 gaps and the Search
  menu-result screen (Part B groups 3 to 6) were not started.
- **Report · My reports (221:63573).** The frame renders blank in Figma, like Entry · Under review in Student 1.
- **Report · Need more info (221:63587), Report · Fixed (221:63606).** They need a mess reply flow that does not exist.
- **Community · Comments and the info sheet.** Not in the brief's list; the info button opens Coming soon.
- **Owner correction 3 pending.** The owner made one more correction on the first build review that was not captured.

## Part A notes

- **Recent account.** No "Continue as Aarav, Student" row or recent-account code exists on `main`; `SessionStore` keeps
  only the current session. Tests check that nothing about an account is kept for Welcome to offer.
- **Debug badge.** It sits at the top centre and does not cover a Welcome button in the Debug capture; it is compiled only
  with `DEMO_DATA`, so the Review build has none. Not changed.
- **Other roles' tab bars, checked in code, not against their images:** Admin and the shell roles use the glass bar with
  the round Search; the Warden's glass bar has no Search; Door Scanner, Pass Desk, Kitchen and Supervisor use
  `StaffTabBar` with no Search. Nothing was changed.

## Added backend pieces (additive, commits `aa09f60` and `a56a324`, with tests)

- `Domain/StudentCommunity.swift`: `StudentIssueStage`, `StudentIssue`, `StudentReportCategory`, `StudentReportRequest`,
  `StudentReportOutcome`, `StudentReportReceipt`, `StudentReportCategoryTitle`.
- `StudentCommunityRepository` (`issues`, `issue`, `back`, `unback`, `submitReport`, `isReportDeskStaffed`) as a defaulted
  slot on `Repositories`; `UnavailableStudentCommunity` never fakes a result.
- `DemoDataProvider`: the implementation and four state fields. Me too is a set per problem, so each student counts once.
  A non-urgent report is published after deterministic checks; one that names someone on the staff list or carries a
  phone number is held for the mess team. Urgent categories are refused here and go through `SOSRepository.raise`; the
  screen then calls `environment.dataDidChange()`, so the Door Scanner and Supervisor see the case. Students are never
  named on Community. No AI decides anything.
- `DemoStudentCommunitySeed.swift`: samples cited to their frames (the two problems, 64 and 38 backers, "ML-1042").

## Open questions (proposed IDs)

- **P-FINAL-1** How long Fixed problems stay on Community (the frame says 30 days; no document).
- **P-FINAL-2** Whether staff sign in with SRM as MS-0 draws, or keep email and password.
- **P-FINAL-3** Which words hold a report for moderation (the prototype uses staff names and phone numbers).
- **P-FINAL-4** When "No one reads reports right now" applies (the prototype uses before 7:00 AM, the only known opening time).
- P2 (support threshold) stays unset.

## Conflict hunks

None. `main` did not move during the task.

## Commands and counts

Final code `04e01b3`, Xcode 27.2, iOS 27.2 simulator, one at a time, gated on `pgrep -x xcodebuild`. Counts from `.xcresult`.

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug | 0 | 606 | 584 | 0 | 22 |
| Review | 0 | 605 | 583 | 0 | 22 |
| Release build | 0 | n/a | `** BUILD SUCCEEDED **` | n/a | n/a |

The 22 skipped are the screenshot tests that skip in a normal run. 16 tests were added (3 entry, 8 community backend,
5 community screens). CI on `main`: run 42382933593 for `df54c92` passed both jobs; the run for `4b73a64` was cancelled
by the next push (its commit-rules job passed).

Greps: no sample name, count, reference or problem title in the Community or Report views.

`git ls-remote --heads origin`: only `refs/heads/main`. `git ls-remote --tags origin | wc -l`: 29, all from before this
task; this task created none.

## Not run

A physical device, the camera (the capture is a static preview), Dynamic Type, VoiceOver, a tap walk.

## Run 2 (8 to 9 November 2026): Spending, Credits Get, ratings, Special pass redesign, Coming soon sweep

Pushed straight to `main` (owner workflow of 7 November). `CLAUDE.md` and `docs/BRANCHING.md` say never to push to the
default branch and to open a pull request; the brief overrides them. No branch, tag or pull request was created.
`~/Downloads/FIGMA_FRAME_MAP.md` was missing: frame ids were read from the Figma file by name (`get_metadata` on page
07 "Prototype & QA", 44:5359) or taken from the brief; none was guessed. Nothing in Figma was edited.

### Commits

| Commit | Title |
|---|---|
| `b2b1781` | feat(backend): add the private Student spending ledger |
| `538a5db` | feat(student): add, edit and delete Spending on MLScreen |
| `061206e` | fix(student): open Report from the Meals error card |
| `c636774` | feat(backend): add Student reward tickets got with credits |
| `7fa81a3` | feat(student): get a reward ticket from Credits |
| `de1922b` | feat(backend): add Student meal and dish ratings |
| `1d0fef0` | feat(student): rate a meal and a dish, Not good opens the report |
| `eaa9659` | feat(student): redraw the Special pass use flow with Use now |
| `4e775de` | feat(student): open How Community works from the info button |
| `a11730d` | refactor(student): move Notifications, Attendance, history to MLScreen |
| (this file) | docs(student): record Student final run 2 |

### How the frames were compared

Real views over the prototype backend, captured by `StudentFinalScreenshotTests` (pushed onto a navigation stack inside
the Student tab bar, as in the app) on iPhone 18 Pro (402 × 874) and iPhone SE 3rd generation (375 × 667). Figma
screenshots were taken with `get_screenshot`. Both images were looked at before each line. Files: `compare-final/figma`,
`compare-final/iphone18pro`, `compare-final/iphonese` (downscaled to 900 px high).

### Results per frame

**22 frames or images compared: 7 match, 13 differ in text or small layout, 2 differ in content.**

| Frame | Node | Result |
|---|---|---|
| Spending | 221:63988 | Differs in content: two "Other" sample entries (1–4 Aug ₹1,125, 5–11 Aug ₹1,285) are listed under Recent; the frame draws only three rows. Totals, bars and the private chip match; Add spending sits at the end as drawn. No canvas fade behind the tab bar (`MLScreen` draws none). |
| Add expense | 221:64118 | Differs in text: the date is the system compact picker ("14 Aug 2024"), the frame "Sat 17 Aug"; the amount starts empty. On SE the sheet scrolls to reach Save. |
| Add expense · Saving | 221:64141 | Matches: Save shows the spinner while the write is in flight; the sheet cannot be swiped away. |
| Add expense · Failed | 221:65703 | Matches: "Didn't save. Try again." and Try again (unit-tested, offline). |
| Spending · Saved | 221:64164 | Matches: "Saved · Canteen ₹60", ₹3,060, ₹560 this week. |
| Edit expense | 221:64238 | Differs in text: date picker as Add expense. Delete expense matches. |
| Delete confirm | 221:64262 | Matches in wording; it is the native alert (red Delete), as drawn. |
| Deleting | 221:64288 | Differs in layout: the spinner is on Delete expense in the sheet. |
| Spending · Offline | 221:65753 | Differs in content: a cold start offline has no saved copy, so only the banner shows; Add spending is hidden offline. |
| Credits | 221:64313 | Matches (moved to `MLScreen`). |
| Credits · Getting a ticket | 221:64396 | Differs in layout: other Get buttons are dimmed while one ticket is being got, not dashed. |
| Credits · Failed | 221:65873 | Matches the card; captured with the Biryani coupon refused (the frame names Juice). |
| Ticket · Juice | 1529:1901 | Differs in content: no "Changes in 9 s" line, because no rotating code exists for rewards (the pass-code operations were not touched); the holder line says "Juice · got Wed 14 Aug", not "valid today", because no expiry rule exists. |
| Ticket · Juice · Used | 1529:2180 | Matches, with "used Wed 14 Aug" as above. Used appears when the counter records the use (`recordCounterUse`); no counter screen for rewards exists. |
| Rewards history | 221:64443 | Matches after a juice: "Juice redeemed · −50 pts" on top, balance 70. Adds a "Something wrong with your balance?" row. |
| Rewards · Balance issue | 221:64463 | Differs in text: "Tell us what looks off." without "We'll reply in My reports" (no reply flow); after Send, "Recorded. This prototype sends nothing." Not captured. |
| How was lunch? (image 01) | owner image | Matches; colours from tokens. Before the meal ends it says "You can rate lunch after it ends." |
| Rate a dish (image 02) | owner image | Matches; Done pinned above the tab bar; Good outlined when chosen. |
| Home card after a meal | owner spec | Built: How was … with Good, Not good and Skip for now; the title opens the full page. |
| Special pass Available (image 01) | owner image | Matches: card, How it works in three steps, the one-use line, pinned Use pass. On SE Use pass covers the steps until scrolled. |
| Use confirm (image 02) | owner image | Matches: compact sheet, Use now and Not yet, no press-and-hold. |
| In use (image 03) | owner image | Unchanged live ticket and In use line from the existing screen; not recaptured. |
| Community · Info sheet | 1535:114372 | Matches the wording; the sheet is sized to its content (the frame draws it taller). |

### Coming soon sweep (B7)

Student destinations that still say Coming soon when signed in: **0**. Replaced this run: Rate a dish (Meals and Search),
the Home follow-up row, Credits Get (Home and You), the Community info button, the Meals error card's Report, the Home
recheck row. `StudentComingSoonView` remains only as the fallback when no student session exists (previews).

### SwiftUI standards per screen (run 2)

| Screen | Swipe-back | Title collapses | Sheet sized to content | Largest Dynamic Type |
|---|---|---|---|---|
| Spending | yes (system bar) | yes (`spending_collapsed`) | Add / Edit expense | `spending_largest_text` |
| Credits, Credits history | yes | yes | Balance issue | not captured |
| Reward ticket | yes | yes | n/a | `ticket_juice_used_largest_text` |
| How was …, Rate a dish | yes | yes / no title (dish page) | n/a | `rate_dish_largest_text` |
| Notifications, Attendance | yes | yes (`notifications_collapsed`) | n/a | `attendance_largest_text` |
| Special pass | no (still its own back circle) | no | Use now sheet | `pass_available_largest_text` |
| Community info | n/a (sheet) | n/a | yes | not captured |

How it was checked: pages on `MLScreen` keep the system navigation bar (`studentPushedPage(usesSystemBar: true)`), whose
back button carries the interactive pop gesture; the capture with the content scrolled to its end shows the inline title
in the bar. A live edge swipe was not performed this run. Not on `MLScreen` yet: Home, Meals, Community, You and Search
roots, Answer, Entry QR, Dish, Crowd, Special pass, Report and SOS, Community issue, My feedback, My reports, a report
page, Help, Privacy and the outing pages. They still hide the bar, so swipe-back does not work there.

### Owner to confirm (ratings, applied as proposed)

- Good records a positive rating and nothing else.
- Not good records nothing by itself and opens the report form with the meal or dish selected; it takes back an earlier Good.
- Skip for now records nothing; the card stays hidden for the rest of the run.
- One rating per meal and one per dish per meal; a change replaces it.
- Allowed only after the meal's service ends; closed when the next meal starts (no deadline when no next meal is known).
- Private to the student; staff get a count only (`goodCount`). No credits. No AI decides anything.
- Conflict: Credits history (221:64443) draws "Rated a dish +2 pts", kept as the frame's sample; the rule says ratings earn none.

### Added backend pieces (additive, each in its own commit with tests)

- `b2b1781`: `StudentSpendingRepository` (expenses, add, update, delete), `StudentSpendingMath` (weeks Monday to Sunday,
  month total, this week, all from the entries; an empty week is nil), `DemoStudentSpending`, labelled samples cited to
  221:63988. 8 tests.
- `c636774`: `StudentRewardsRepository` (getTicket, tickets, ticket, recordCounterUse, reportBalanceIssue),
  `DemoStudentRewards`; `DemoStudentYou` gains a defaulted `rewards` store so a ticket's cost comes off the balance and
  shows as "Juice redeemed". Sample code "7A3F" and "Lime" cited to 1529:1901. 6 tests.
- `de1922b`: `FeedbackRatingRepository` (ratingWindow, rateMeal, rateDish, myRating, goodCount), `DemoFeedbackRatings`;
  `StudentReportRequest` gains a defaulted `dish`. Nothing seeded. 6 tests.

### Open questions (proposed IDs)

- **P-FINAL-5** Do reward tickets rotate their code like the Special pass, and does the Pass Desk check them?
- **P-FINAL-6** How long is a reward ticket valid ("valid today" in 1529:1901)?
- **P-FINAL-7** Who answers a balance question, and where does the reply show?
- **P-FINAL-8** Ratings earning credits: the history frame shows +2 for a rating; the ratings spec says none.
- **P-FINAL-9** Approval of the Special pass redesign (B2e).

### Conflict hunks

None. `main` did not move during the run except by this run's own pushes.

### Commands and counts (final code `a11730d` plus this report)

Xcode 27.2, iOS 27.2 simulators, one at a time, gated on `pgrep -x xcodebuild`. Counts from `.xcresult`.

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug, `MealLoop` | 0 | 754 | 725 | 0 | 29 |
| Review, `MealLoop Review` | 0 | 752 | 724 | 0 | 28 |
| Release build (generic iOS Simulator) | 0 | n/a | `** BUILD SUCCEEDED **` | n/a | n/a |

The skipped tests are the screenshot tests, which run only with a capture folder set. 46 tests were added this run.
Grep of the new view files for sample amounts, codes or names: only two doc comments quoting the frame's wording.
`git ls-remote --heads origin`: only `refs/heads/main`. `git ls-remote --tags origin | wc -l`: 29, none created here.

### Not run

A physical device, a live edge-swipe gesture, VoiceOver, the camera. B0, B5, B6 and B8 for the time box.
