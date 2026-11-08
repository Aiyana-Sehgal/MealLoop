# Admin (Food Head) completion and a minimal Super Admin

**Partial.** Part A (the inventory) is done from the code and the Admin Figma comparison already on `main`. In Part B,
no Admin frame was changed: the earlier work covers every Admin frame, and the gaps that remain have no frame or a
recorded reason. Part C is built: Super Admin Accounts, an account page, and a simulated password reset and
deactivation.

Worktree: `MealLoop-admin`, detached at `9b20b8a`. Figma file `nzzTAm9YnJRSdKEeYUWUEb`, page "12 Admin Redesign"
(`2237:2`), read only with `get_metadata`. `~/Downloads/FIGMA_FRAME_MAP.md` is missing, so frame ids come from that
page and from `docs/verification/admin-figma-fix/REPORT.md`.

**Workflow mismatch.** The owner workflow says to push straight to `main`, while `CLAUDE.md` and `docs/BRANCHING.md`
say to use pull requests. The owner workflow was followed, and no branch, tag or pull request was created.

## Part A: inventory

- **"Not implemented" in the roots.** `AdminRootView` still declares `AdminRoute.notImplemented`, but no Admin page
  routes to it any more (checked with `grep`). `SuperAdminRootView` showed `PlaceholderRootView` (Coming soon) before
  this run; it now shows Accounts.
- **Admin frames.** Page 12 has 84 Admin frames, compared one by one in `docs/verification/admin-figma-fix/REPORT.md`
  (final code `c049fcc`, on `main` through PR #23): **17 match, 63 differ, 4 not built.** That covers every tab and
  page: Today, Students, Results, More, People and access, Outings, Special passes, Menu voting, Rewards, Announce, the
  menu editor, and the weekly report. This run **did not recompare** those frames and claims no new match.
- **The 4 not built:**
  - `2260:162800` Safety case · Closed: no closed case exists in the seed.
  - `2313:167848` Edit day · Reordering: a mid-drag state.
  - `2311:104` and `2311:202` CSV and PDF saved toasts: no file is made, so nothing may say one was saved.
- **Controls with no frame behind them**, which say "This isn't part of this prototype.": Rules, Redemptions, Decide,
  New proposals, the Passes request row, See dishes and steps, See all, and the Outings rows. They stay not built:
  there is no frame to build from.
- **The rules in this brief, already covered by tests on `main`:**

  | Rule | Tests |
  |---|---|
  | No percentages in reasons | `AdminFigmaFixTests.testEveryReasonStaysFreeOfPercentages`, `AdminResultsMoreTests.testNoReasonCarriesAPercentage` |
  | Reasons tagged Sure, Probably or Can't tell | `testEveryReasonUsesOnlyTheThreeTags` |
  | "Worked" needs two comparable meals | `testWorkedNeedsTwoComparableMeals`, `testTheBackendAndTheScreenBothRefuseWorkedWithOneMeal` |
  | Missing is a dash, never zero | `testMissingCountsAreDashesNotZero`, `testMissingEvidenceIsListedAsMissing` |
  | The six values stay separate | `testTheGridHoldsTheOtherMessesWithoutTouchingTheSixValues` |
  | Never auto-approved; an adjustment needs a reason and keeps its history | `AdminTodayViewModelTests.testAdjustWithoutAReasonIsRejectedAndChangesNothing`, `testAdjustWithAReasonIsApprovedAndKeptInTheHistory`, `AdminMessRepositoryTests.testAChangedNumberNeedsAReason` |

## Part B: Admin

No Admin code changed this run. The tap-through of every Admin screen was **not done**: the time box was spent on the
two earlier prompts and Part C.

## Part C: minimal Super Admin

**Built from the design system, no approved design, owner approval needed.** No Figma frame exists for this role, so
no frame comparison is claimed.

- **Accounts.** Every seeded account (`DemoSeed.accounts`), with its display name and role. A deactivated account says
  "Deactivated in this prototype".
- **Account page.**
  - It shows the role, the email, and the scope ("One mess" or "One hostel").
  - **Start password reset** is recorded only, and the page says "This prototype sends nothing, and no password is
    ever shown here."
  - **Deactivate account** asks for confirmation, then records the deactivation. Sign-in does not change, and the page
    says so.
  - A Super Admin account can't be deactivated.
- **Sign out** is at the bottom of Accounts.
- **What a Super Admin cannot do.**
  - Every operation is refused for any other role, including the Food Head.
  - The model (`ManagedAccount` over `Account`) has no password or token field. A test encodes it and finds no
    password.
  - The Super Admin root opens no Food Head page.
- **Signing in.** Super Admin still uses Staff sign in (P-ENTRY-1, unchanged). The entry screens were not edited.

### Added backend pieces (commit `ea81c9d`, `feat(backend)`, additive)

- `Domain/SuperAdmin.swift`: `ManagedAccount`.
- `Data/Repositories/SuperAdminRepository.swift`: `accounts`, `account`, `deactivate` and `startPasswordReset`, plus
  `UnavailableSuperAdmin`.
- `Repositories.superAdmin`, defaulted. In `DemoDataProvider`: one stored store and one argument.
- `Data/Demo/DemoSuperAdmin.swift`: the store and the prototype implementation. Every seeded account starts active,
  because every seeded account can sign in.

### Seen in the simulator

**Not captured.** Staff sign in as `superadmin@mealloop.example` was refused twice in the simulator ("The email or
password is incorrect."). The sign-in code accepts that account, and the new test
`testTheSuperAdminSignsInOnStaffSignIn` passes, so the cause is most likely the simulator's typed input. It was not
retried a third time (common rules). The pages are checked by tests only.

## Tests

| File | Tests | What they show |
|---|---|---|
| `SuperAdminRepositoryTests` (new) | 6 | Every account is listed and active. Every other role is refused, and the Food Head can't deactivate. No password in the model. A deactivation is recorded once, and never for a Super Admin. A reset is recorded and never deactivates. Offline records nothing. |
| `SuperAdminScreensTests` (new) | 4 | Staff sign in returns the Super Admin with no staff powers. The list shows every account. A Food Head gets no list. A reset and a deactivation show only after the repository records them. |

## Commands and counts (final code)

Xcode 27.2 (27B52), iOS 27.2 simulator on iPhone 18 Pro, with one device, reused. `pgrep -x xcodebuild` reported 0,
and tests ran serially.

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug, `MealLoop`, `test` | 0 | 684 | 661 | 0 | 23 |
| Review, `MealLoop Review`, `test` | 0 | 683 | 660 | 0 | 23 |
| Release build (generic iOS Simulator) | 0 | n/a | `** BUILD SUCCEEDED **` | n/a | n/a |

The Release log has 1 `warning:` line. Conflict hunks: none.

## Open questions (proposed IDs)

- **P-SADMIN-1** A design for Super Admin: these pages need the owner's approval or frames.
- **P-SADMIN-2** Should a deactivation block sign-in in the prototype? Today it is recorded only.
- **P-SADMIN-3** Who receives a password reset, and through what channel? Nothing is sent today.
- P-ENTRY-1 (Super Admin signs in through Staff sign in) stays open.

## Not run

- a physical device
- the camera
- Dynamic Type
- VoiceOver
- iPhone SE: no SE simulator is installed
- the Admin tap-through
- a Super Admin capture (see above)
