# Follow-ups from the owner's review (9 November 2026)

Pushed straight to `main` (owner workflow). `CLAUDE.md` and `docs/BRANCHING.md` say never to push to the default branch
and to open a pull request; the brief overrides them. No branch, tag or pull request was created. Lean mode: one
capture per changed screen on iPhone 18 Pro at about 480 px high.

## Progress (resumable)

| Group | What | Status | Evidence |
|---|---|---|---|
| P1 | Special pass keeps the long press | done | `iphone18pro/p1_pass_hold_sheet.png`; PassHoldTrackerTests (complete, release early, cancel) |
| P2 | Special pass approval for next week | done | `p2_pass_request.png`, `p2_pass_requested.png`, `p2_admin_passes_requests.png`; PassRequestRepositoryTests (6) |
| P3 | Ratings open for 2 days | done | FeedbackRatingRepositoryTests: open after the next meal starts, Monday open, Sunday closed; Home card hidden when rated or closed |
| P4 | Outing "What happens next" | done | `p4_new_outing.png`, `p4_outing_request.png`; OutingNextStepsTests (5) |
| P5 | Rewards add and delete | done | `p5_rewards_manage.png`, `p5_rewards_add_sheet.png`; RewardCatalogueRepositoryTests |
| P6 | Food Head gets the Super Admin's scope | done | below |
| P7 | Spacing audit, Admin and Student | done | 48 screens measured; 7 flagged, 6 fixed, 1 is the keyboard's space; table below |
| P8 | Open item P-FINAL-10 | done | recorded below; Get unchanged |

## P6. Food Head has the Super Admin's scope

Where the scope is set and enforced: `AdminContext.allMesses` (presentation), `AdminDataScope.allMesses` (the data
scope every scoped Admin repository checks), `AdminAccessModel.canAccess` and `DemoPeople.require` (People and access).
Each now accepts the Food Head (`admin`) as well as the Super Admin. Supervisor, Kitchen and Door roles stay per mess.

Test assertions changed (each encoded the old one-mess rule):
- `AdminAccessModelTests.testFoodHeadOnlyOwnMessAndNoPeople` → `testFoodHeadSeesAllMessesAndPeopleLikeTheSuperAdmin`
  (allMesses, canManagePeople, otherMesses present, People and access loads).
- `AdminAccessModelTests.testInvitedFoodHeadGetsAssignedMessWithoutMainFallback`: an invited Food Head keeps the
  assigned mess but has the all-mess scope; Main is read as Main.
- `AdminDataScopeTests.testFoodHeadBackendRefusesOtherMessAndOtherMessMeal` → `testFoodHeadCanReadAndAdjustOtherMesses`.
- `AdminDataScopeTests.testFoodHeadHasNoAccountPowersAndNoNorthCommunity` → `testFoodHeadGetsTheGlobalTotalsTheSuperAdminGets`.
- `AdminDataScopeTests.testReportAndAnnouncementsNeverExposeOtherMesses` → `testFoodHeadAnnouncesToEveryMessAsTheAdmin`.
- `AdminDataScopeTests.testScopeRejectsOtherRolesAndMismatchedAssignedMess`: the Food Head on another mess no longer
  throws; every non-admin role still does.
- `PeopleAccessTests.testFoodHeadAndEveryOtherRoleCannotManagePeople` → `testEveryRoleButTheAdminCannotManagePeople`.


## P7. Blank-band audit

Method (owner's, kept cheap): every Admin page and Student route captured once at 1x on iPhone 18 Pro by the opt-in
audit walks (`AdminPolishScreenshotTests.testCaptureAdminAudit`, `StudentFinalScreenshotTests.testCaptureStudentAudit`;
skipped unless `AUDIT` is set), then `blank_audit.py` (the owner's script with the same thresholds; PIL is not
installed, so `sips` shrinks each PNG and writes a BMP that the script reads). Only the flagged screens were looked at.
Not walked: Answer, Entry QR, a dish page and the Edit day page (their views need state the walk does not build).

| Screen | Longest blank before | after | Trailing blank before | after | Added |
|---|---|---|---|---|---|
| admin_announce.png | 6% | 6% | 1% | 1% |  |
| admin_community_issue.png | 6% | 6% | 1% | 1% |  |
| admin_feedback.png | 10% | 10% | 1% | 1% |  |
| admin_find_meal.png | 25% | 25% | 1% | 1% |  |
| admin_headcount.png | 4% | 4% | 1% | 1% |  |
| admin_history.png | 6% | 6% | 1% | 1% |  |
| admin_live_meal.png | 7% | 7% | 0% | 0% |  |
| admin_mess_north_lunch.png | 5% | 5% | 0% | 0% |  |
| admin_more.png | 3% | 3% | 1% | 1% |  |
| admin_not_answered.png | 42% | 7% | 1% | 1% |  |
| admin_outings.png | 5% | 5% | 1% | 1% |  |
| admin_passes.png | 6% | 6% | 0% | 0% |  |
| admin_people.png | 7% | 7% | 1% | 1% |  |
| admin_people_door_staff.png | 55% | 13% | 1% | 1% |  |
| admin_proposals.png | 62% | 8% | 1% | 1% |  |
| admin_redemptions.png | 33% | 12% | 1% | 1% |  |
| admin_results.png | 6% | 6% | 1% | 1% |  |
| admin_rewards.png | 6% | 6% | 1% | 1% |  |
| admin_safety_cases.png | 47% | 19% | 1% | 1% |  |
| admin_search.png | 37% | 7% | 1% | 1% |  |
| admin_skip_reasons.png | 7% | 7% | 1% | 1% |  |
| admin_spare_food.png | 16% | 16% | 1% | 1% |  |
| admin_students.png | 6% | 6% | 0% | 0% |  |
| admin_today.png | 5% | 5% | 5% | 5% |  |
| admin_votes.png | 6% | 6% | 1% | 1% |  |
| admin_weekly_menu.png | 7% | 7% | 1% | 1% |  |
| admin_weekly_report.png | 5% | 5% | 0% | 0% |  |
| student_attendance.png | 3% | 3% | 1% | 1% |  |
| student_community.png | 14% | 14% | 14% | 14% |  |
| student_credits.png | 3% | 3% | 0% | 0% |  |
| student_credits_history.png | 6% | 6% | 1% | 1% |  |
| student_crowd.png | 3% | 3% | 0% | 0% |  |
| student_help.png | 13% | 13% | 13% | 13% |  |
| student_home.png | 7% | 7% | 7% | 7% |  |
| student_meals.png | 4% | 4% | 1% | 1% |  |
| student_my_feedback.png | 6% | 6% | 6% | 6% |  |
| student_my_reports.png | 14% | 14% | 14% | 14% |  |
| student_new_outing.png | 3% | 3% | 0% | 0% |  |
| student_notifications.png | 6% | 6% | 1% | 1% |  |
| student_outings.png | 4% | 4% | 0% | 0% |  |
| student_pass.png | 5% | 5% | 1% | 1% |  |
| student_pass_request.png | 3% | 3% | 0% | 0% |  |
| student_privacy.png | 9% | 9% | 9% | 9% |  |
| student_rate_meal.png | 16% | 16% | 1% | 1% |  |
| student_report.png | 3% | 3% | 0% | 0% |  |
| student_search.png | 30% | 30% | 14% | 14% |  |
| student_spending.png | 6% | 6% | 1% | 1% |  |
| student_you.png | 4% | 4% | 4% | 4% |  |

Result: no screen above 25% except Student Search, whose band is the keyboard's place (not a defect on a device).

## P8. Open questions

- **P-FINAL-10** "in get 3 can make card too change 3 times" (Credits Get) is unclear. Get is unchanged. Candidate
  readings: a reward can be got at most 3 times; or a ticket card can be exchanged 3 times.
- **P-FOLLOWUP-1** Added rewards show "At your mess counter" as their place line, the wording of every seeded reward
  offered now. Should the Admin enter a place?
- **P-FOLLOWUP-2** Next week's pass requests: is there a request deadline, and a limit on how many the Admin accepts?
- **P-FOLLOWUP-3** Rewards › the earlier ₹ budget lines per reward (₹30 each, 57 left) are no longer listed; the
  catalogue holds the credit cost only. Keep the ₹ line?
- Parallel Student session: its 5 unpushed commits (outing pages on MLScreen) will meet P4's outing edits when it
  rebases; keep both: the MLScreen move and the What happens next card.

## Commands and counts (final code `84b0a1f`)

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug, `MealLoop` | 0 | 792 | 753 | 0 | 39 |
| Review, `MealLoop Review` | 0 | 790 | 752 | 0 | 38 |
| Release build | 0 | n/a | `** BUILD SUCCEEDED **` | n/a | n/a |

Skipped: the opt-in screenshot and audit captures. Diff: Student and Admin feature folders, additive `Domain` and
`Data` pieces (pass requests, reward catalogue), the Food Head scope rule (`AdminDataScope`, `DemoPeople`), tests and
this folder. Not checked: a live edge swipe, VoiceOver, the camera, a physical device.
