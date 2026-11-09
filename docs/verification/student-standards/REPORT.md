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
| S3 Attendance to Discrepancy | Pending | | |
| S4 Student Search above the keyboard | Pending | | |
| S5 Cheap empty-space audit | Pending | | |
| S6 Student walk | Pending | | |

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

## Validation so far

| Run | Command | Result |
|---|---|---|
| Baseline, before changes | Debug tests, `MealLoop` scheme | exit 0; 804 tests, 760 passed, 0 failed, 44 skipped |
| After S1 | Debug tests | exit 0; 804, 760, 0, 44 |
| After S2 | Debug tests | exit 0; 806, 762, 0, 44 |
| S1/S2 captures | `StudentFinalScreenshotTests/testCaptureStudentAudit` with `TEST_RUNNER_STUDENT_FINAL_SHOTS`, `TEST_RUNNER_AUDIT` | exit 0; 34 captures |

The S1 commit was not built on its own; S1 and S2 were pushed together and tested at the S2 tip.
