# Student standards: SwiftUI standards on every Student screen

Run of 9 November 2026 (MealLoop Prompt 1, final). Brief: the SwiftUI standards in `docs/SWIFTUI_STANDARDS.md`
(the owner's `SWIFTUI_STANDARDS_SPEC.md` was not in `~/Downloads`; the repository copy was used) on every Student
screen, the last flow fixes, and a cheap empty-space audit. Interactive prototype only: nothing here runs against a
live backend.

Captures stay outside the repository, in `~/mealloop-captures/student-standards/` (iPhone 18 Pro simulator, iOS 27.2,
402 × 874 pt, captured at 1x).

## Progress

| Group | State | Commit | Notes |
|---|---|---|---|
| S1 Standards on every Student screen | Done | `03ad4fb` | 22 pages and 3 tab roots moved onto `MLScreen` |
| S2 Report and SOS as pushed pages | Done | `206f644` | Back goes one step; draft in the view model |
| S3 Attendance to Discrepancy | Done | `3b30ebe` | Tue 13 Aug dinner opens the sheet; VM tests |
| S4 Student Search above the keyboard | Done | `a8769f6` | Menu rows above the keyboard; tab bar under it |
| S5 Cheap empty-space audit | Done | see below | 2 flagged before (Search 48%, Dish 41%); 0 after |
| S6 Student walk | Done | report only | 41 of 41 pages reached; 0 crashes; 0 placeholders; 4 swipe-backs one level |

## S1 Standards on every Student screen

Before this run, the Student pages that drew their own chrome (a hidden system bar and a hand-drawn back circle:
`StudentNavHeader`, `YouLargeHeader`, `MealsLargeHeader`, `MealsCompactHeader`, `RecordsPage`) were found by searching
the Student folder for `.toolbar(.hidden`, `navigationBarBackButtonHidden` and `BackButton(`, and compared with the
`usesSystemBar` route lists. Already on `MLScreen` before this run: Notifications, Credits, Credits history, the
reward ticket, Attendance, Spending, How was lunch? and Rate a dish.

Moved onto `MLScreen` in this run (system back button with swipe-back, large title collapsing into the bar, bottom
actions pinned to the safe area above the floating tab bar):

| # | Screen | File | Pinned action |
|---|---|---|---|
| 1 | Answer | `StudentAnswerView.swift` | none (the answer buttons belong to the content) |
| 2 | Entry QR | `EntryQRView.swift` | none |
| 3 | Dish | `StudentMealsView.swift` | Rate a dish |
| 4 | Crowd | `StudentCrowdView.swift` | none |
| 5 | Search (stack root; Back in the leading bar slot returns to the last tab) | `StudentSearchView.swift` | none |
| 6 | Community issue (the issue's title is the large title) | `StudentCommunityView.swift` | none |
| 7 | My feedback | `StudentRecordsViews.swift` | none |
| 8 | My reports | `StudentRecordsViews.swift` | none |
| 9 | A filed report (its reference is the title) | `StudentRecordsViews.swift` | none |
| 10 | Help | `StudentRecordsViews.swift` | none |
| 11 | Privacy & data | `StudentRecordsViews.swift` | none |
| 12 | Outings | `StudentOutingViews.swift` | none |
| 13 | New outing | `StudentOutingViews.swift` | Send to guardian |
| 14 | Sent | `StudentOutingViews.swift` | See your request |
| 15 | An outing request (title follows the state, pass title once signed) | `StudentOutingViews.swift` | none |
| 16 | Special pass (every state; hold-to-use unchanged) | `StudentPassView.swift` | Use pass / Request / Cancel request / Try again |
| 17 | Meals tab root | `StudentMealsView.swift` | none |
| 18 | Community tab root (info button in the bar) | `StudentCommunityView.swift` | none |
| 19 | You tab root | `StudentYouView.swift` | none |
| 20–25 | Report: What's wrong, Details, Receipt; SOS sent (S2) | `StudentReportView.swift` | Send report / Done |

Sheets: the outing cancel sheet (was a fixed 300 pt `.sheet`) and the report reply sheet (was `.medium`) now use
`mlSheet`, sized to their content, and cannot be swiped away while their send is in flight.

What a page shows did not change, with these differences in how it is drawn:
- Pages whose frames draw a small centred bar title (Dish, Search, Community issue, the Special pass status frames,
  My reports, a filed report, Privacy) now show a large title that collapses into that bar title on scroll, as
  section 1 of the standards asks. The issue page uses the issue's title as the large title instead of drawing
  "Issue" in the bar and the issue title under it; the filed report uses its reference.
- The hand-drawn headers (`StudentNavHeader`, `YouLargeHeader`, `MealsLargeHeader`, `MealsCompactHeader`) are deleted;
  nothing uses them.
- After sending a New outing, the Sent page is pushed straight after Outings, so the system Back returns to the list
  as the old custom Back did.
- Home keeps its own header (brand row, credits chip, report and bell buttons): the frame has no title to collapse.

Motion: `MLScreen` uses `MLMotion` and respects Reduce Motion. No new animation was added.

## S2 Report and SOS as pushed pages

The steps used to replace each other on one screen, so the system Back would leave the whole flow. Now:

| Step | Built as | Back |
|---|---|---|
| What's wrong | the pushed route's root page (`StudentReportView`) | pops the report |
| Details (with its Sending and Failed states) | pushed (`StudentReportDetailsPage`, `navigationDestination(item:)`) | one step to What's wrong; hidden while a send is in flight |
| Receipt | pushed from Details (`StudentReportReceiptPage`) | none: the report is recorded; Done closes the flow |
| SOS · Camera | full-screen cover, as the frame draws it over the tab bar (`StudentSOSCameraPage`) | Close returns to What's wrong |
| SOS · Sent | pushed after the cover closes (`StudentSOSSentPage`) | none: the SOS is raised; Done closes the flow |

- The draft (category, note, send state, receipt) is in `StudentReportViewModel`; `choose(_:)` decides the next page
  and keeps the typed note when the same category is picked again after Back.
- Unchanged rules: urgent reports bypass Community and raise an SOS (`SOSRepository.raise`, then
  `environment.dataDidChange()`); a failed send keeps the text and retries with the same key; the camera is a static
  preview, marked not verified on a device.
- From Community, View report replaces the finished report with the issue page, so Back from the issue returns to
  Community.
- Tests added: `StudentCommunityScreensTests.testChoosingACategoryPicksThePageAndBackKeepsTheDraft`,
  `testAReportSentStartsANewDraftNextTime`.

Deviation from the brief: Sending is a state of the Details page, not a pushed page. Its frame (221:63541) is the
Details form with the button in its sending state, and a separate page would let Back abandon a send in flight.

## S3 Attendance to Discrepancy

- `StudentYouViewModel` reads the correctable record (`StudentExtrasRepository.correctableRecord`) with the attendance
  month. `correctableDay(in:)` gives the day it falls on only when the calendar marks that day "No entry for a meal";
  in the sample that is Tue 13 Aug, Dinner, the record the Discrepancy frame (221:63082) draws. Days 3, 8 and 10 are
  also missed but have no correctable record, so they stay plain.
- That day is a button on the calendar and opens "Something's wrong?" (`EntryDiscrepancySheet`, now given the record,
  the time zone and a send closure instead of the Home view model, which never hosted it).
- After sending, the calendar card says "Request recorded. This prototype sends nothing." (`RecordsCopy.requestRecorded`,
  the existing wording). It changes no entry and no count. Offline the record cannot be read, so no day opens the
  sheet; a send that fails offline records nothing and the sheet says it did not send.
- While a day can be corrected, one line under the calendar says so: "Ate but not scanned? Tap the circled day to ask
  for a correction." This wording is not from a frame; it only points at the existing control.
- Tests: `StudentYouScreensTests.testTheMissedDayWithACorrectableRecordOpensTheDiscrepancySheet`,
  `testOfflineNoDayOpensTheSheetAndNothingIsRecorded`.

## S4 Student Search

- Before anything is typed, under the hint and the TRY chips, Search lists the dishes of the meal the Meals tab leads
  with ("LUNCH ON THE MENU" in the sample), from the menu `StudentMealsViewModel` already loads. Each row opens the
  dish. No results shows its card, the chips and the same list. Nothing is listed until that menu is published.
- Content is anchored to the top (`MLScreen`), and the scroll view dismisses the keyboard interactively.
- The Student tab bar now ignores the keyboard's safe area (`StudentRootView`), so it stays at the bottom edge under
  the keyboard as an iOS tab bar does, instead of riding up over the results.

## S5 Cheap empty-space audit

Script: `docs/verification/student-standards/blank_audit.py`, a copy of `docs/verification/followups/blank_audit.py`
(the owner's script; `~/Downloads/blank_audit.py` was not on this Mac). It reports the longest blank band between the
header and the tab bar and flags a screen above 25%. Captures: every Student route once at 1x on iPhone 18 Pro, from
`StudentFinalScreenshotTests/testCaptureStudentAudit` (`TEST_RUNNER_STUDENT_FINAL_SHOTS`, `TEST_RUNNER_AUDIT`), which
this run extended with the moved pages. Output kept in `~/mealloop-captures/student-standards/audit_s1.tsv` (before,
after S1/S2) and `audit_s5.tsv` (after S4 and S5).

Flagged full-screen pages and their fixes:

| Screen | Blank before | Blank after | Fix |
|---|---|---|---|
| Search (idle) | 48% | 8% | S4: the leading meal's dishes from the menu `StudentMealsViewModel` already loads |
| Dish | 41% | 6% | "Also at lunch": the meal's other dishes from the menu the host already loaded (`otherDishes(than:day:slot:)`); each opens its page. Rate a dish stays pinned |

Every other route was at or below 16% before and is unchanged:

| Screen | Before | After |
|---|---|---|
| Answer | 6% | 6% |
| Attendance | 3% | 3% |
| Attendance with the Discrepancy sheet (sheet over a scrim, not judged) | n/a | 0% |
| Attendance after a request | n/a | 3% |
| Community | 6% | 6% |
| Community, scrolled | 3% | 3% |
| Credits | 3% | 3% |
| Credits history | 6% | 6% |
| Crowd | 3% | 3% |
| Entry QR | 3% | 3% |
| A filed report | 4% | 4% |
| Help | 6% | 6% |
| Home | 7% | 7% |
| Community issue | 4% | 4% |
| Meals | 3% | 3% |
| Meals, scrolled | 3% | 3% |
| My feedback | 3% | 3% |
| My reports | 4% | 4% |
| New outing | 3% | 3% |
| Notifications | 6% | 6% |
| An outing request | 3% | 3% |
| Outing sent | 3% | 3% |
| Outings | 4% | 4% |
| Special pass | 5% | 5% |
| Special pass, request for next week | 5% | 5% |
| Privacy & data | 4% | 4% |
| How was lunch? | 16% | 16% |
| Report · What's wrong | 4% | 4% |
| Report · Details | 4% | 4% |
| Report · Receipt | 4% | 4% |
| SOS · Sent | 14% | 14% |
| Spending | 6% | 6% |
| You | 4% | 4% |
| You, scrolled | 4% | 4% |

The "scrolled" captures did not scroll in the hosted test window (they match the unscrolled ones), so the title
collapse on those tab roots was checked in the S6 walk instead.

Test added: `StudentMealsScreensTests.testTheDishPageListsTheRestOfItsMealFromTheLoadedMenu`.

## S6 Student walk

A scratch copy of this worktree (outside the repository) with a temporary XCUITest target, `MealLoopWalk`, grafted into
its `project.pbxproj` and the `MealLoop Review` scheme. Never committed. It signs in with SRM as the Student, opens
every tab and the deepest pages of each flow, and logs each page as reached, crashed or placeholder ("Coming soon",
"Not implemented", "isn't part of this prototype"). Simulator: a temporary iPhone 18 Pro, iOS 27.2, Review build.
Screenshots in `~/mealloop-captures/student-standards/walk/`.

| Area | Pages opened | Result |
|---|---|---|
| Home | Home; Answer; Entry QR; Special pass; Crowd; Notifications (system Back, then edge swipe); Credits > Get > ticket | all reached |
| Report | What's wrong > Details > Send report > Receipt > Done | all reached |
| Meals | Meals; Dish (Chappati) > Also at lunch > Dish (Veg Pulao) | all reached |
| Community | Community; an issue; How Community works sheet | all reached |
| You | You; Outings > New outing; Outings > a request; Credits; Attendance > 13 Aug > Something's wrong? > Send request; Spending; My feedback > My reports > ML-1031; Help; Privacy | all reached |
| Search | Search with the keyboard up; results for "sambar"; a result's dish | all reached |

- Pages reached: 41 of 41. Crashed: 0. Placeholder text: 0.
- One lookup was "not found": the Crowd row inside the Special pass page. The available pass draws no Crowd row (it
  shows only on used, expired and wrong-mess states), so this is not a defect.
- Swipe-back, checked by a drag from the left screen edge (`press(forDuration:thenDragTo:)` from x = 2 pt) on a pushed
  page, then checking which page is hittable:

  | From | To | Result |
  |---|---|---|
  | Notifications | Home | one level |
  | Report · Details | What's wrong? (not out of the report) | one level |
  | Dish (Veg Pulao, opened from Also at lunch) | Dish (Chappati) | one level |
  | Community issue | Community | one level |

- Title collapse: after scrolling up, the large title of Meals, Community and You is gone and the same title shows in
  the bar (walk screenshots `collapse_Meals`, `collapse_Community`, `collapse_You`).
- S3 in the app: the 13 Aug cell opens "Something's wrong?" with Dinner · Tue 13 Aug; after Send request the
  calendar card says "Request recorded. This prototype sends nothing."
- S4 in the app: with the software keyboard up, the tab bar is under the keyboard and "LUNCH ON THE MENU" fills the
  space between the field and the keyboard; typing "sambar" lists the matches there.
- A first walk run stopped short on the You tab because swiping down did not close the Community info sheet in the
  test; the second run closes it with its Close button. Both logs are kept (`walk_run1/`, `walk/`).

## Validation

All runs on a temporary iPhone 18 Pro simulator (iOS 27.2), one at a time, with
`-parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1`.

| Run | Command | Result |
|---|---|---|
| Baseline, before changes | `xcodebuild test`, scheme `MealLoop` (Debug) | exit 0; 804 tests, 760 passed, 0 failed, 44 skipped |
| After S1 | Debug tests | exit 0; 804, 760, 0, 44 |
| After S2, before the first push | Debug tests | exit 0; 806, 762, 0, 44 |
| After S3 and S4, before the second push | Debug tests | exit 0; 808, 764, 0, 44 |
| After S5, before the third push | Debug tests | exit 0; 809, 765, 0, 44 |
| Final | `xcodebuild test`, scheme `MealLoop Review` | exit 0; 807 tests, 764 passed, 0 failed, 43 skipped |
| Final | `xcodebuild build`, scheme `MealLoop`, `-configuration Release` | exit 0; BUILD SUCCEEDED |
| Captures | `StudentFinalScreenshotTests/testCaptureStudentAudit` with `TEST_RUNNER_STUDENT_FINAL_SHOTS`, `TEST_RUNNER_AUDIT` | exit 0; 36 captures |
| Walk | scratch copy, `MealLoopWalk/StudentWalk`, scheme `MealLoop Review` | exit 0; 41 of 41 pages reached |

The S1 commit was not built on its own; it was pushed together with S2 and tested at the S2 commit.

- Files changed (all allowed): the Student feature folder, four Student test files, and
  `docs/verification/student-standards/`. No backend, shared component, token, `GlassTabBar`, `MLScreen`,
  `RoleRootView`, `openapi.yaml`, ADR, `docs/OPEN_DECISIONS.md` or other role's file changed.
- No image file was added anywhere; captures stay in `~/mealloop-captures/student-standards/`.
- `git ls-remote --heads origin`: `refs/heads/main` only.

Not checked: a physical device; the camera (the SOS camera is a static preview); VoiceOver; iPhone SE; Dynamic Type at
the largest size for the pages moved in this run (`MLScreen` already moves pinned actions into the scroll at
accessibility sizes, and earlier runs captured Spending, Attendance and the ticket at that size). The edge swipe was
driven by XCUITest in the simulator, not by a finger.

## Open questions

- Pages whose frames draw a small centred bar title now open with a large title that collapses into it (standards,
  section 1). If the owner wants those frames kept compact, `MLScreen` would need an inline-only title option, which
  is a shared-component change outside this run.
- The hint under the Attendance calendar ("Ate but not scanned? Tap the circled day to ask for a correction.") and the
  "LUNCH ON THE MENU" and "ALSO AT LUNCH" labels are wording this run added; no frame draws them.
- Receipt and SOS · Sent have no Back (Done closes the report). Whether the owner wants Back there, and to where, is
  not decided by a frame.
