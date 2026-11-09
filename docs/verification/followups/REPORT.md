# Follow-ups from the owner's review (9 November 2026)

Pushed straight to `main` (owner workflow). `CLAUDE.md` and `docs/BRANCHING.md` say never to push to the default branch
and to open a pull request; the brief overrides them. No branch, tag or pull request was created. Lean mode: one
capture per changed screen on iPhone 18 Pro at about 480 px high.

## Progress (resumable)

| Group | What | Status | Evidence |
|---|---|---|---|
| P1 | Special pass keeps the long press | done | `iphone18pro/p1_pass_hold_sheet.png`; PassHoldTrackerTests (complete, release early, cancel) |
| P2 | Special pass approval for next week | not started | |
| P3 | Ratings open for 2 days | done | FeedbackRatingRepositoryTests: open after the next meal starts, Monday open, Sunday closed; Home card hidden when rated or closed |
| P4 | Outing "What happens next" | not started | |
| P5 | Rewards add and delete | done | `p5_rewards_manage.png`, `p5_rewards_add_sheet.png`; RewardCatalogueRepositoryTests |
| P6 | Food Head gets the Super Admin's scope | done | below |
| P7 | Spacing audit, Admin and Student | not started | |
| P8 | Open item P-FINAL-10 | not started | |

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
