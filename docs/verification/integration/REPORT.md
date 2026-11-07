# Integration batch and core-story walk (Part 7a)

Date: 7 November 2026. Branch `fix/ios-integration-batch`, base `origin/feature/swiftui-foundation` at `91b1ce9`.

## 1. Base gate and base result

`git merge-base --is-ancestor` passes for all five required tips: `feat/ios-kitchen` 0e798e3, `feat/ios-pass-desk` 3035e27, `feat/ios-admin-results-more` 909b5ab, `feat/ios-outings` a6909c4 and `feat/ios-student-home` ed69e29. Supervisor, Door Scanner and Admin Today were already merged.

Debug tests on the untouched base (simulator "Supervisor Pro Max", `-parallel-testing-enabled NO`): exit 0, **445 executed, 433 passed, 0 failed, 12 skipped**. The base was green, so no base fix was needed.

## 2. Items

| # | Item | Result | Commit | Files |
|---|---|---|---|---|
| 1 | "Ravi saw it" | Done | 34cb2b0 | `Features/Supervisor/SupervisorTaskViewModels.swift`, `MealLoopTests/SupervisorViewModelTests.swift` |
| 2 | Placeholder metric | Done | a955192 | `MealLoopTests/PlaceholderMetricTests.swift` |
| 3 | Kitchen dead end | Done | 3617c3d | `Features/Kitchen/KitchenCopy.swift`, `Features/Kitchen/KitchenAlertsMeViews.swift` |
| 4 | Admin and Supervisor numbers agree | Partly: figures agree; Admin's missing glyph is still "—" (see decisions) | f937041 | `Data/Demo/AdminSeed.swift`, `MealLoopTests/AdminBackendTests.swift` |
| 5 | Admin wording, thresholds, comparable rule | Done | e62ca74 | `Features/Admin/AdminScreenCopy.swift`, `Data/Demo/AdminSeed.swift`, `Domain/AdminResults.swift`, `MealLoopTests/AdminResultsMoreTests.swift` |
| 6 | Pass Desk code window | Done (value unchanged, citation fixed) | 4143d3b | `Data/Demo/DemoSeed.swift`, `MealLoopTests/SpecialPassOperationTests.swift` |
| 7 | Student entry QR "Live" label | Done, no change needed | none | none |
| 8 | Docs | Done | this commit | `docs/SCREEN_INVENTORY.md`, `docs/verification/integration/` |
| opt | SOS release-claim operation (K14d) | Not done (time) | none | none |

### Item 1: "Ravi saw it"
`SupervisorShortageViewModel.load()` now calls `repositories.shortages.markSeen(_:by:)` when the Supervisor opens a report that is still only sent. Other roles only read. The repository keeps the first sighting and writes `DemoSeed.supervisorName` ("Ravi"). New tests:
- `testOpeningAReportMarksItSeenSoTheKitchenSaysRaviSawIt`: the Supervisor writes the sighting; the Kitchen reads it from the same repository and gets "Ravi saw it"; reopening keeps the first time.
- `testAnotherRoleOpeningAReportDoesNotMarkItSeen`.

The walk shows "Steamed Rice, almost out, Ravi saw it" on Kitchen Home (W05g).

### Item 2: placeholder metric
The built map now matches the combined base. Gate's reachable set is overridden to its single home page because it has no tab bar (GA-1); `RoleRoot.placeholderTabs` still says Home and Me. A new test, `testBuiltDestinationsAreReachable`, stops a built name from hiding a renamed tab. Nothing asserts zero. Printed output from the final Debug run:

```
PLACEHOLDERS admin: 1 of 5 ["Search"]
PLACEHOLDERS doorScanner: 0 of 3 []
PLACEHOLDERS gate: 0 of 1 []
PLACEHOLDERS guardian: 0 of 1 []
PLACEHOLDERS kitchen: 0 of 3 []
PLACEHOLDERS passDesk: 0 of 3 []
PLACEHOLDERS student: 4 of 5 ["Meals", "Community", "You", "Search"]
PLACEHOLDERS superAdmin: 2 of 2 ["Home", "Me"]
PLACEHOLDERS supervisor: 0 of 3 []
PLACEHOLDERS vendor: 2 of 2 ["Home", "Me"]
PLACEHOLDERS warden: 0 of 4 []
PLACEHOLDERS total: 9 of 32
```

Pushed pages that still say "Not implemented" are outside this metric: the Warden Me sub-pages (`WardenRoute.notBuilt`) and the Kitchen and Supervisor Me rows for Switch role, Language and Help.

### Item 3: Kitchen dead end
On Alerts, the earlier-meal row read "Tue dinner · add it". It now reads "Tue dinner · not recorded" (`KitchenCopy.addIt` is replaced by `KitchenCopy.notRecordedFor`). The row still opens the past meal, which offers Record waste only for the meal that is still editable (`model.editableMeal`), so an earlier meal shows read only. No recording flow was added.

### Item 4: Admin and Supervisor figures
| Meal | Admin before | Supervisor | Spec source | Now (both roles) |
|---|---|---|---|---|
| Tue 13 dinner, Main: final entries | 691 | 598 | `design/reference/supervisor_2026-10/data/supervisor_spec.md` line 19 ("598 entered") | 598 |
| Tue 13 dinner, Main: plate waste | 11 kg | waste not recorded | none: `design/audit/prototype_gaps.md` #425 (line 1078) says 640, 691 and 11 kg are not in the data file | not recorded; Admin shows "—" and lists "Waste record: not recorded by the kitchen" |
| Tue 13 dinner, Main: headcount sent | 640 (4:30 PM) | not shown | none (#425) | missing ("—") |
| Tue 13 dinner, Main: closing time | 9:30 PM | not given | none | missing |
| Wed 14 lunch: final entries | live `finalCount(for:)` | live `finalCount(for:)` | 774: `kitchen_spec.md` line 3 and `supervisor_spec.md` line 3. **786**: `admin_sample_data.md` lines 25 and 65 | Unchanged: one source (`finalCount(for:)`). The story-start Review build counts recorded entries only, so the walk shows 1 on both roles (W06b, W07e) |

One source: `AdminSeed.tueDinnerMain` is now the Supervisor's meal id (`demo-2024-08-13-dinner`). `DemoAdminRepositories.allMeals()` takes final entries, closing time and waste for every Admin past meal that the meal history also holds. The Data percentage and the plate waste follow the waste record, using the same rule `storyLunch()` already used. No other Admin past meal is in the Supervisor's history (the others are North, South or Mon lunch). Tests: `testAdminAndSupervisorAgreeOnTuesdayDinner` and `testAdminAndSupervisorAgreeOnTheClosedStoryLunch`. Walk: W07g shows Tue dinner "598, Came in · final", "Headcount sent —", "Plate waste —".

### Item 5: Admin wording
Every string changed in `ios/MealLoop/Features/Admin/AdminScreenCopy.swift`:

| Constant | Before | After |
|---|---|---|
| `reminderSent` | "Reminder sent · <time>" | "Reminder recorded · <time>" |
| `remindNote` | "Sends one notification. Students who already answered get nothing." | "One notification, only to students who haven't answered. This prototype records it and sends nothing." |
| `reminderToast` | "Reminder sent" | "Reminder recorded" |
| `notePlaceholderStudents` | "Add a note students will see on this issue" | "Add a note on this issue" |
| `menuSubtitle` | "The menu students see in Meals" | "The menu for the students' Meals page" |
| `savedTold` | "Saved. Students see it now." | "Saved. This prototype sends nothing to students." |
| `studentsSee` | "Students see" | "Students would see" |
| `everyoneGets` | "All <n> students get this now, in Notifications and on Home." | "All <n> students would get this in Notifications and on Home. This prototype sends nothing." |
| `sentDinner` | "Sent. Students see the new dinner." | "Dinner change saved. This prototype sends nothing to students." |
| `inviteSent` | "Invite sent" | "Invite recorded" |
| `audienceReach` (no count) | "Students at <mess> get a notification now." | "Students at <mess> would get a notification. This prototype sends nothing." |
| `audienceReach` (count) | "About <n> students at <mess> get a notification now." | "About <n> students at <mess> would get a notification. This prototype sends nothing." |
| `announcementSent` | "Announcement sent" | "Announcement recorded" |

Kept on purpose:
- The vendor sheets already say "Nothing is sent for you" or "Nothing was sent".
- "Sent to vendor" on Today is the headcount's real repository state.
- `announceSubtitle` ("Shows on students' Home and as a notification") and `limitedNote` describe where a message is meant to go and claim no delivery.

Safety cases stay read only: the repository has only a read, and the case page's two buttons are a call attempt and the vendor sheet.

Reason thresholds:
- The pack gives the thresholds as drafts in `design/reference/admin_redesign_2026-10/data/admin_sample_data.md` lines 53 to 61 ("Rules behind the tags (DRAFT, owner to confirm the numbers)").
- They are kept, and each explanation that states a rule now ends with "(draft, SRM approval required)" in `AdminSeed.detail`.
- The 5% margin (fewer or more came) and the 40% share (last 30 minutes) stay in words ("well below", "most"). The existing test `testNoReasonCarriesAPercentage` forbids "%" in any reason text.
- The pack's open item 2 (line 86) leaves these numbers to the owner.

Comparable meal rule (owner-proposed, recorded as proposed): `CheckNextTimePolicy.countedMeals` now leaves out a meal that ran out, and `canCloseAsWorked` needs 2 counted meals. Before, any ran-out meal blocked "worked" outright. The backend refusal now reads "A change needs 2 comparable meals that did not run out before it can be called worked." Tests: `testAMealThatRanOutIsNotCountedAsComparable`, `testSimulatedSendsNeverClaimDelivery`, `testEveryReasonRuleIsLabelledDraft`.

**Test changed:** in `AdminResultsMoreTests.testTheBackendAndTheScreenBothRefuseWorkedWithOneMeal`, the expected `counted` goes from 1 to 0. The Wednesday plan's only recorded meal (the closed story lunch) ran out of rice (`AdminSeed.storyLunch`, A09), so under the proposed rule it is not comparable. The test now also asserts that this meal is recorded and ran out, and it still checks that the screen and the backend both refuse "worked". No test was deleted.

### Item 6: Pass Desk code window
- The code is shown on the student's Special pass: the BigTicket Live state with "Changes in N s" (`design/audit/PROJECT_CONTEXT.md` line 187).
- Its window is in `design/audit/final2_report.md` line 26, decision 5: "the live code changes every 10 s".
- `DemoSeed.passCodeWindow` stays 10 s. Its comment used to say "No document gives the real window", and now cites those two files.
- New test: `testTheCodeWindowIsTheOneTheStudentPassShows`.
- Special-meal entries remain a separate count (P-PASS-1), as `SpecialPassOperationTests.testPassEntriesStayOutOfTheDoorCount` already checks.

### Item 7: entry QR
`EntryQRView` draws no "Live" label or refresh countdown (its doc comment says so), and no component it uses draws one. The walk asserts no "Live" element on the entry QR (W01e). Nothing changed in Student.

## 3. Core-story walk

How it ran:
- Review build, simulator "Supervisor Pro Max", one continuous run from a fresh launch, signing out between roles. The in-memory demo state must carry over between roles, so a relaunch per step would reset it.
- Driven by a temporary XCUITest target (`MealLoopWalk`) added only to a scratch copy of the final code in the session scratchpad. It was never committed.
- The simulator panel could not be used because device access was not granted, so all driving went through `xcodebuild test -only-testing:MealLoopWalk`.
- The final run: `** TEST SUCCEEDED **`, 1 test, 0 failures, 404 s.
- Screenshots: `walk/` (43 PNGs, scaled to 1434 px).

| Step | What | Result | Screenshots |
|---|---|---|---|
| 1 | Student: Sign in with SRM, open lunch (Answer), I'm in, open the entry QR | Passed. Lunch shows "You're in for lunch · Change by 10 AM". At 7:00 AM the Home's QR button is breakfast's (the meal in service), so the QR opened is "Breakfast · Main Mess"; no Live label | W01a to W01e |
| 2 | Food Head: Today, Review and approve, Approve 860, Send 860 to vendor, Send | Passed. "SENT TO VENDOR · 10:05 AM", 860 | W02a to W02e |
| 2b | Student again: lunch answers locked | Passed. Lunch shows "You're in for lunch" with no Change or Answer button | W02f |
| 3 | Supervisor: Start meal, confirm | Passed. "LIVE · 12:00 PM", 0 students entered, Close meal offered | W03a to W03c |
| 4 | Door Scanner: Type ID, keys 0 2 3 8 | Passed. "Recorded in" 0 → 1 | W04a to W04e |
| 5 | Kitchen: live count rose; report Steamed Rice almost out to Ravi; Supervisor opens it in Alerts; Kitchen shows it | Passed. Kitchen LIVE 1 students entered; Supervisor shortage details; Kitchen row "Steamed Rice, almost out, Ravi saw it" | W05a to W05g |
| 6 | Supervisor: Close meal, confirm. Kitchen: Record waste (8 dishes None left, plate waste 18 kg), Review and save, Save report | Passed. Supervisor "Closed · 2:00 PM", Final entries 1. Kitchen "Report saved", Home shows Recorded | W06a to W06i |
| 7 | Supervisor and Admin: waste read only | Passed. Supervisor Waste report "Recorded by the kitchen · 2:00 PM", 18 kg, no Save, Edit or Record. Admin meal report shows Plate waste 18 kg, no edit action | W07a to W07g |
| 7b | Vendor acknowledgment | Skipped: the Vendor role is a placeholder root (not built) | none |

## 4. Validation

| Command | Exit | Counts (.xcresult) |
|---|---|---|
| Debug tests on the base (91b1ce9) | 0 | 445 total, 433 passed, 0 failed, 12 skipped |
| Debug tests, final code (4143d3b) | 0 | 454 total, 442 passed, 0 failed, 12 skipped |
| Review tests, final code | 0 | 453 total, 441 passed, 0 failed, 12 skipped (one Debug-only test fewer than Debug) |
| Release build, generic iOS Simulator, final code | 0 | BUILD SUCCEEDED |
| Review build plus the temporary walk test (scratch copy) | 0 | 1 test, 0 failed |

An intermediate Debug run (items 1 to 6 before the test update) had 1 failure: the expected-count change described under item 5. It passed after that change.

Diff against the base:
- Source: only the files named in section 2.
- Docs: `docs/SCREEN_INVENTORY.md` and `docs/verification/integration/`.
- No package, design-system component, token, `openapi.yaml`, ADR or project-setting change.
- `Domain/AdminResults.swift` changed only for the item 5 comparable rule.

Checked by eye or not run:
- Walk screenshots were checked mainly through the accessibility tree saved with each one; W02a was also looked at as an image.
- No frame-by-frame visual comparison was done.
- The optional SOS release operation was not built.

## 5. Bugs and observations outside this scope (not fixed)

1. **Admin meal report shows a percentage for a story meal with very few entries.** `ios/MealLoop/Features/Admin/AdminMealReportView.swift:48-50` draws "-100%" for 1 came against 860 sent (W07e), which reads as a measured result. It is a count comparison, not a reason, but it may mislead in review.
2. **The story lunch carries seeded facts after a live walk.** `ios/MealLoop/Data/Demo/AdminSeed.swift:43-44` gives the story lunch "Rice ran out 1:34 PM" and "Data 80%" from A09. In the walk the Kitchen only reported "almost out" and nothing ran out, yet Admin shows "Rice ran out 1:34 PM" (W07e). This seeded ran-out also makes the Wednesday plan's first meal non-comparable under the item 5 rule.
3. **Tue 13 dinner ran out on Admin but not on the Supervisor.** Admin shows "Rice ran out 8:34 PM" (`AdminSeed.swift`, Tue dinner seed, and `AdminSeed.swift:175` in the weekly report). The Supervisor's history for the same meal lists no shortage. 8:34 PM is a frame value moved from 1:34 PM (`prototype_gaps.md` #426); it is not a spec figure.
4. **Admin shows missing numbers as "—".** `ios/MealLoop/Features/Admin/AdminPageKit.swift:299` (`AdminFormat.missing`) differs from the other roles' "Unavailable". Not changed here because the Admin views are being reworked on `fix/ios-admin-figma-match`.
5. Final entries in the Review build are the recorded door entries (1 in the walk), not the spec's 774 (`DemoDataProvider.finalCount`, `countsRecordedEntriesOnly`). This is consistent across roles and recorded here only so reviewers expect it.

## 6. Decisions needed

- **D-INT-1**: Wed 14 lunch final entries: 774 (`kitchen_spec.md`, `supervisor_spec.md`) or 786 (`admin_sample_data.md`). The code shows 774 in the seeded closed state.
- **D-INT-2**: Approve the proposed rule "a comparable meal that ran out does not count as comparable" (implemented as proposed).
- **D-INT-3**: The draft reason thresholds (5%, 40%, 30 min, 15 min, 3 "not good"): SRM approval required (pack open item 2).
- **D-INT-4**: Admin's missing-number glyph: "—" or "Unavailable" (observation 4).
- **D-INT-5**: Whether the story lunch's seeded "Rice ran out 1:34 PM" stays once the meal is run live (observation 2), and the Tue dinner ran-out (observation 3).
