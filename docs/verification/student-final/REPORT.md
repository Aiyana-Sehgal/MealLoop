# Student final: opening screens, Community, Report and SOS, compared with Figma

Pushed straight to `main` under the owner workflow of 7 November (no branch, tag or pull request). `CLAUDE.md` and
`docs/BRANCHING.md` say never to push to the default branch and to open a pull request; the brief overrides them, and
the mismatch is recorded here. Figma file `nzzTAm9YnJRSdKEeYUWUEb`, read with the Figma connector (`create_session`,
`get_screenshot`). The frame map was pasted by the owner and is not committed. Nothing in the Figma file was edited.

**Partial.** The 2-hour time box ended after Part A and Part B groups 1 and 2. Groups 3 to 6 are not built (below).

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
