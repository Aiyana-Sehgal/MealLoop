# Admin scopes, People and access, and per-mess Supervisor

8 November 2026. **Partial implementation; not a full readiness sign-off.** The latest owner ruling keeps Admin and Super Admin separate. The earlier combined-role proposal and older ZIP instructions do not apply where they conflict with it.

## Result

- Food Head uses the mess assigned by the seed: `demo-main-mess`, Main Mess. Today has one mess tile. People and access is absent from More and refused by the directory backend. Invited or allotted Food Heads for the other approved messes resolve their assigned mess; missing live data stays unavailable instead of falling back to Main. The role's data adapters carry its acting session and reject another mess, meal, audience, feedback record or check.
- Super Admin reaches the Admin presentation in all-mess mode, including Main, North, South and Annexe tiles, the combined Students/Results/More sources, and People and access. The flat Accounts root and its old account UI have been removed. `RoleRootView` and the Role cases were not edited.
- People and access has the eight approved states: roles with real directory counts, people in a role, person, temporary password, invite, revoke confirmation, allotment and revoked person. Give and invite return a temporary password once; closing the sheet clears it from the view model. The credential store keeps only a salted SHA-256 digest or a revoked flag. This is an in-memory prototype, not production authentication.
- Revoke blocks **new sign-ins**. Give restores access with the new temporary password and rejects the old shared password. Replacing a temporary password also rejects its predecessor. A relaunch resets the directory. **Existing sessions are not ended.** No new copy claims sign-out, delivery or a forced first-sign-in password change.
- The directory supports invite and allotment, with actor and injected-clock audit events for give, revoke, invite and allot. No Admin or Super Admin entry offers Revoke; the backend also refuses it. Existing records are not reassigned when a person moves.
- Supervisor Home calls the additive session-scoped start/close overloads. The repository compares the acting StaffSession's mess against the target meal's mess before calling the existing lifecycle operation. Cross-mess start and close are tested as refused.

## Not built or not fully verified

1. **Live pages for North, South and Annexe:** not built. Their existing tiles still open their own headcount page; Main opens the existing Main live page. The prototype's `MealStateRepository` supplies live service state only for Main. No other mess's attendance, shortages or live status was fabricated or substituted with Main's. This means the requested four-mess live-page completion is still outstanding.
2. **Per-mess answer totals and reason aggregates:** unavailable. The old Students sample holds 3,500 students / 2,310 yes / 420 no / 140 unsure across messes; these must not be labelled as Main's. The Food Head gets known Main feedback and community records and an unavailable message for counts. The Food Head's Results shows scoped meal records; global reason totals are not exposed as local totals.
3. **Reports:** Food Head gets the existing report's Main breakdown only (this week's plate waste, ran-out meals and completeness); periods without a breakdown show dashes. Global reasons, foods, safety narratives, vendor summary and totals are not relabelled as Main's. Super Admin retains the existing global reports. No file export was added.
4. **More:** the Food Head gets Weekly menu, Weekly report, the explicitly Main Wednesday-pass source, a Main-only announcement audience and Sign out. Other hub counts and global pages without a reliable per-mess breakdown are not presented as Main's. Super Admin retains the global hub. Additional per-mess More sources remain outstanding.
5. **Full manual tap-through:** not completed. General native control rejected Simulator by name and path. Xcode project access was subsequently approved and a dedicated device runtime opened successfully, but that runtime explicitly required the `device-interaction` skill/workflow, which was absent from the available skill catalog and filesystem resources. Xcode resource discovery was also unavailable. The unused device runtime was closed without synthesizing events. Approval is no longer the blocker; the missing required workflow is. Captures below are real SwiftUI views hosted in native simulator windows, not screenshots of a complete manually navigated journey. The audit table distinguishes source/model evidence from actual taps.
6. **Pixel parity:** not claimed. Native sheets, shared primitives, data-driven counts and corrected wording differ from the approved drawings; every reference has a comparison line below.
7. No change-password screen, delivery channel, live backend or production credentials were built. No physical-device, camera, Dynamic Type or VoiceOver check was performed. Keyboard scrolling and every control's touch reachability still need manual verification, especially on SE.

## Gate, references and workflow

`git fetch origin` and `git ls-tree origin/main docs/verification/admin-final/REPORT.md ios/MealLoop/Features/Admin` passed at `cb6bbd799d33f7f7c89deb6286eda829caeeefa2`. Both gate entries exist. The admin-figma-fix, staff-figma-fix and integration reports also exist. The pre-task admin-final report described the old recorded-only account actions; the code confirmed that status.

Worktree: `/Users/user49/MealLoop-admin-scopes`, detached from `origin/main`, initially clean. The separate reference clone is `/Users/user49/MealLoop-task-base`. No original checkout's modified files were touched. The large initial checkout download completed before repository edits.

The supplied common rules override CLAUDE.md and docs/BRANCHING.md on direct pushes to `main`. No feature branch, tag, pull request, force push or rewritten remote history was created. Author: `VeeraaVikash <veeraavikashs21@gmail.com>`. Rebase conflict hunks: none.

Design sources: approved `admin_people_00_roles` through `admin_people_07_person_revoked` from `review_additions_2026-11.zip`; Figma file `nzzTAm9YnJRSdKEeYUWUEb`, frames `2278:166146` and `2257:158261`, read through design context with screenshots. The existing `design/audit/export_admin_redesign/A01_today@2x.png` is included for Today comparison. No Figma edits were made. The ZIP's forced-change and sign-out copy was superseded by the latest explicit request. No protected docs, shared components, tokens, GlassTabBar, project settings, OpenAPI or other roles' folders were edited. The only Supervisor edit changes the start/close calls to use the acting StaffSession.

## Backend additions and compatibility

- `Data/Repositories/PeopleRepository.swift`: directory entries, one-time result, audit entries and repository contract; a Release/unavailable source refuses operations.
- `Data/Demo/DemoPeople.swift`: one in-memory account/credential store, seeded account list, four named prototype messes, unique temporary credentials, salted digests, revocation, invites, allotment and audit. New mess IDs are local prototype IDs corresponding to the four approved mess names; no live data for those additional messes is implied.
- `DemoDataProvider`: additive directory composition and prototype sign-in enforcement. A staff sign-in uses its assigned mess rather than always receiving Main.
- `Data/Repositories/AdminDataScope.swift`: session-bound adapters; source-mess provenance; resource and audience checks; per-mess report and student projections; additive scoped Supervisor lifecycle overloads.
- `Repositories`: defaulted People repository and a replaceable headcount adapter slot. All default callers retain compatibility.
- Existing role-only prototype APIs and their historical tests remain for compatibility. The Admin subtree uses session-bound adapters. The old recorded-only Super Admin repository/model remains unrouted; it is not the credential authority. These interfaces are not a production server authorization design.
- The legacy Admin operation adapters forward approved Admin roles into the existing Food Head operation implementation. Existing headcount operation histories remain role-based rather than account-based; the new People audit uses account IDs.
- Kitchen waste/shortage writes, Door entry writes and Pass Desk writes receive roles in their existing request/operation interfaces, not an acting session. They were not changed under the conditional scope instruction. Supervisor screens already query their StaffSession's mess.

Backend commits: `6a45ef2` (credentials), `40d357c` (session-bound scope and lifecycle), `05de827` (source provenance, safe aggregate handling and per-mess projections). Presentation: `543f09f`; cosmetic initials/plural correction: `2828abb`; assigned-mess lookup and regression test: `f93bddb`; live-read authorization: `69f6751`; loading-label guard: `73c2680`.

Full changed-file inventory: [CHANGED_FILES.txt](CHANGED_FILES.txt).

## Automated evidence

Xcode 27.2 (27B52). iPhone 18 Pro: `52D13036-EB53-4149-A22F-CD480026C61B`, iOS 27.0. Installed SE reused: `1001B885-6FB4-4E60-9AED-0D808FA0EDDA`, iPhone SE (3rd generation), iOS 27.2. No simulator was created. Runs were serial, with `-parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1`. `pgrep -x xcodebuild | wc -l` was checked before builds and reported 0. The 18 Pro was temporarily shut down for SE captures and its initial booted state restored afterward.

| Run / result bundle under `/tmp/` | Exit | Total | Passed | Failed | Skipped |
|---|---:|---:|---:|---:|---:|
| Credential group, `mealloop-admin-scopes-debug-1.xcresult` | 0 | 688 | 667 | 0 | 21 |
| Credential pre-push, `mealloop-admin-scopes-debug-2.xcresult` | 0 | 688 | 667 | 0 | 21 |
| Scope group, `mealloop-admin-scopes-debug-3.xcresult` | 0 | 693 | 672 | 0 | 21 |
| Presentation iteration, `mealloop-admin-scopes-debug-8.xcresult` | 0 | 696 | 674 | 0 | 22 |
| Final assignment-scope Debug, `mealloop-admin-scopes-live-scope.xcresult` | 0 | 698 | 676 | 0 | 22 |
| Earlier functional Debug, `mealloop-admin-scopes-debug-final.xcresult` | 0 | 697 | 675 | 0 | 22 |
| Functional pre-push Debug, `mealloop-admin-scopes-prepush.xcresult` | 0 | 697 | 675 | 0 | 22 |
| Initials correction Debug, `mealloop-admin-scopes-ui-fix.xcresult` | 0 | 697 | 675 | 0 | 22 |
| Final full Review with 15 native captures, `mealloop-admin-scopes-review-shipping.xcresult` | 0 | 697 | 676 | 0 | 21 |
| Release generic simulator build, `mealloop-admin-scopes-release-shipping.xcresult` | 0 | n/a | build succeeded | n/a | n/a |

Final SE capture-only run `mealloop-admin-scopes-se-shipping.xcresult` exited 0: 1 test passed, 0 failed, 0 skipped, 15 native renders. Full summaries and source revisions are recorded in `VALIDATION.json`. The final loading-guard Debug run (`mealloop-admin-scopes-report-prepush.xcresult`) passed 698 tests: 676 passed, 22 skipped, 0 failed, exit 0. Counts above were taken from actual output and xcresulttool summaries, not inferred from test declarations. Review has one fewer Debug-only test; its opt-in capture test runs, while the normal Debug suite skips it. Existing unrelated opt-in screenshot suites remain skipped.

Commands used (project root as working directory):

```sh
xcodebuild -project ios/MealLoop.xcodeproj -scheme MealLoop \
  -destination 'platform=iOS Simulator,id=52D13036-EB53-4149-A22F-CD480026C61B' \
  -derivedDataPath /tmp/mealloop-admin-scopes-build \
  -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
  -resultBundlePath /tmp/mealloop-admin-scopes-prepush.xcresult test

TEST_RUNNER_ADMIN_SCOPES_SHOTS="$PWD/docs/verification/admin-scopes/captures" \
xcodebuild -project ios/MealLoop.xcodeproj -scheme 'MealLoop Review' \
  -destination 'platform=iOS Simulator,id=52D13036-EB53-4149-A22F-CD480026C61B' \
  -derivedDataPath /tmp/mealloop-admin-scopes-build \
  -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
  -resultBundlePath /tmp/mealloop-admin-scopes-review-shipping.xcresult test

xcodebuild -project ios/MealLoop.xcodeproj -scheme MealLoop -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/mealloop-admin-scopes-build \
  -resultBundlePath /tmp/mealloop-admin-scopes-release-shipping.xcresult build

# SE capture-only run: same Review scheme/derived-data/serial flags,
# destination 1001B885-6FB4-4E60-9AED-0D808FA0EDDA,
# TEST_RUNNER_ADMIN_SCOPES_SHOTS ending in captures-se,
# -only-testing:MealLoopTests/AdminScopeScreenshotTests, test-without-building.
xcrun xcresulttool get test-results summary --path /tmp/mealloop-admin-scopes-review-verified.xcresult --compact
```

Intermediate failures are not hidden: Debug-4 failed to compile an unavailable date formatter call; Debug-5 failed to compile an async call in an XCTest autoclosure. Both were corrected. Debug-6 and Debug-7 each reported one old assertion rejecting Super Admin from AdminContext; that assertion was updated, not deleted. Debug-8 and subsequent functional runs passed. Review captures were repeated after correcting source provenance, native sheet sizing, role wording and initials. Release was rebuilt during the final assignment and live-read corrections; the three local Release builds all succeeded. The shipping Review/Release/captures validate `69f6751`; `73c2680` only prevents an unsourced zero label during loading, leaves the captured loaded states unchanged, and is included in the report pre-push Debug run and final remote CI. Final Review had two AppIntents metadata-extraction warnings and no Swift warning. Release had one warning is AppIntents metadata extraction being skipped because there is no AppIntents dependency; no Release Swift error was reported.

### Existing tests updated honestly

- `AdminFigmaFixTests.testSuperAdminGridHoldsOtherMessesWithoutTouchingTheSixValues`: the four-mess grid assertion now uses a Super Admin session; six-value integrity assertions remain.
- `AdminResultsMoreTests.testOnlyFoodHeadAndSuperAdminSessionsMakeAdminContexts`: both presentation roles are accepted; other roles are still refused.
- `AdminTodayViewModelTests.testNoOtherRoleCanReachTheAdminRole`: excludes the two authorized presentation roles from the refusal loop; hostel-scoped Food Head remains refused.
- No test was deleted to make the suite pass. New `PeopleAccessTests`, `AdminDataScopeTests` and `AdminAccessModelTests` cover the changed behavior, including old-password refusal, invite/allotment scope, protected accounts, offline behavior, missing local breakdowns, audience scope, transient password clearing and cross-mess Supervisor writes.

## Frame comparison

Open [comparison.html](comparison.html). Approved references are beside native iPhone 18 Pro renders in identical 393 × 852 comparison boxes; original PNGs are retained. Native phone viewports differ in size from the 393-point drawing and the capture window omits system status/home indicators. Existing OrbitBackground and GlassTabBar were reused. **No row below claims a pixel match.**

| Approved frame/image | Observed result / differences |
|---|---|
| `admin_people_00_roles` | Eight roles and Invite present. Actual directory counts are one per seeded role, not the placeholder totals in the drawing. Shared row spacing/tab-bar glyphs and system chrome differ. |
| `admin_people_01_door_staff` | One seeded SK record in Main, with status and Add action. No invented three extra named rows. Initials preserve SK; singular person wording is corrected. This leaves more empty space than the drawing. |
| `admin_people_02_person` | Sign-in card, Mess, Role, Give, Revoke and record-retention text present. Revoke text blocks new sign-ins and makes no sign-out claim. Row typography and status-pill outline differ. |
| `admin_people_03_give_password` | Password shown once, Copy, Done and close available. Random 32-character credential is smaller than the drawing's sample code. Corrected honest copy; native white content-sized sheet covers the tab bar rather than reproducing the sketch's cream overlay. |
| `admin_people_04_invite` | Name/contact, role/mess selections and add action present. All eight assignable roles are available, versus six drawn chips; chip order/wrapping, outlined fields and sheet surface differ. Button says Add person and give password, not Send invite. No first-sign-in-change or delivery claim. SE requires scrolling. |
| `admin_people_05_revoke_confirm` | Cancel/Revoke modal and retention warning present. Copy intentionally omits sign-out. Native viewport/modal geometry differs. Success toast uses the required wording only after the backend accepts. |
| `admin_people_06_allot_mess` | Four mess choices, selected check, retention note and Save present. Shared circle size, sheet surface/height and missing current-allotment explanatory sublabel differ. |
| `admin_people_07_person_revoked` | Revoked state, lime Give, disabled Revoke and new-sign-in warning present. Outlined revoked pill from the drawing is not reproduced; spacing differs. |
| Figma `2257:158261` / `A01_today@2x` | Super Admin renders four tiles using its seeded display name. The during-meal capture shows actual prototype approval/entry state, not a fabricated Replied state. Only Main has a live page; other tile destinations remain headcount pages. |
| Food Head Today | Single Main tile and six distinct values. Uses the existing tile/live presentation at full width, not the four-mess composition. No separate exact single-mess Today frame was supplied. |
| Food Head Students / Results / Report / More | Scoped adaptations and explicit missing-data messages, not claimed to match a separate approved single-mess design. No global student totals or People row. |
| Super Admin More | Existing global hub, with People destination replaced by the new access flow. Existing layout retained; no new exact match claimed. |

15 native renders are saved for each phone size. Final capture runs re-rendered all 15 states on each phone from `69f6751`. The later loading-only label guard does not change these loaded states. SE initial viewports demonstrate scrolling is needed on tall sheets; they do not prove every off-screen element was tapped or tested with the keyboard open. The pictured temporary credentials belong to isolated in-memory test providers that no longer exist.

## Element/destination audit

**These are source wiring, backend/view-model tests and render evidence, not a completed manual tap-through.** Native tap result remains unverified for every row because the dedicated device runtime required an unavailable device-interaction workflow after project approval.

| Element | Expected destination/effect | Evidence / result |
|---|---|---|
| Food heads / Mess supervisors / Kitchen staff / Door staff / Pass desk staff / Wardens / Gate security / Vendors | Role-filtered directory across messes | Each uses its Role raw-value route; data filtering and seeded counts rendered. Native taps unverified. |
| Person row | Person page for that account ID | Account-ID route wired; SK person state rendered. Native tap unverified. |
| Back on roles/person pages | Pop the current Admin stack | Uses the tab's existing nav.pop. Native tap unverified. |
| Invite someone / Add role staff | Invite sheet with role preselected | Sheet state and data-driven choices wired; rendered. Native taps unverified. |
| Name/contact fields | Edit invite input | Native fields rendered; validation rejects empty inputs in backend. Keyboard interaction unverified. |
| Each role chip | Select that role | State binding wired; no unsupported Super Admin creation chip. Native taps unverified. |
| Main / North / South / Annexe invite chips | Select requested mess | Data-driven IDs; backend invite and new sign-in assignment tested. Native taps unverified. |
| Add person and give password | Create person and show temporary password | Backend and model tests pass; no delivered-message claim. Native tap unverified. |
| Mess on person | Allot sheet | Current assigned mess initializes selection; rendered. Native tap unverified. |
| Each allotment row / Save allotment | Save new assignment; leave old records untouched | Backend audit and subsequent sign-in scope tested. Native taps unverified. |
| Role on person | Open that person's role list | Role route wired, not a role-change control. Native tap unverified. |
| Give password / revoked-card Give | Generate a replacement and open one-time sheet | Auth and model tests pass. Native taps unverified. |
| Copy password | Copy current transient credential | UIPasteboard action wired; clipboard contents not manually tested. |
| Password Done / close / sheet dismissal | Dismiss and clear transient credential | Model clear-and-reload test passes; dismissal binding clears. Native taps/swipe unverified. |
| Revoke password | Open confirmation | Rendered; absent for protected Admin roles; disabled when already revoked. Native tap unverified. |
| Confirmation Cancel | Close without mutation | Closure only dismisses. Native tap unverified. |
| Confirmation Revoke | Revoke, refresh state and show success wording | Backend refusal/restoration tests and revoked render pass. Native tap unverified. |
| Today / Students / Results / More / Search | Corresponding tab or existing Search placeholder | Existing tab bar reused; two scope modes wired. Full tab tap-through unverified. |
| Main tile | Existing Main headcount/live page | Existing routes retained; scoped headcount tested. Native tap unverified. |
| North / South / Annexe tiles | Their own mess headcount page | Existing ID-specific routes retained. Requested live pages are not built. |
| Food Head meal-record rows | Own mess's meal report | Scoped result IDs and backend refusal tested; native taps unverified. |
| Food Head Weekly report / period chips | Own report breakdown; unavailable periods stay missing | Main-only breakdown and nil missing period tested; renders saved. Native taps unverified. |
| Food Head Weekly menu / Wednesday pass / Announce | Known Main sources only | Backend source provenance and Main-only audience tested. Native taps unverified. |
| Sign out | Clear current session | Existing router/session-store action retained. Native tap unverified. |

## Open questions (proposed IDs)

- P-ADMIN-SCOPE-1: Provide live prototype meal states/records and approved missing-data states for North, South and Annexe; until then do not show Main data as theirs.
- P-ADMIN-SCOPE-2: Provide per-mess tomorrow-answer totals, reason aggregates and the remaining More-page sources. Missing figures must stay unavailable.
- P-ADMIN-SCOPE-3: Existing sessions are not ended or dynamically re-scoped after revoke/allot. Revisit shared session invalidation and assignment refresh after the review; it was explicitly excluded here.
- P-ADMIN-SCOPE-4: Who may revoke an Admin account? No such screen action or backend action is allowed here.
- P-ADMIN-SCOPE-5: Vendor contact versus restricted Vendor login remains a document/design conflict. A plain Vendors role row is used; no Not a login wording.
- P-ADMIN-SCOPE-6: Restore the required device-interaction workflow or arrange manual touch/keyboard verification. Project approval has been granted. Dynamic Type, VoiceOver and the documented design differences still require review.
- P-ADMIN-SCOPE-7: Password delivery and a possible change-password screen remain future decisions. Nothing is delivered today.
- P-ADMIN-SCOPE-8: Legacy Account uses an email field for contact; phone contacts can use the same prototype sign-in input, but its older label remains Email. Hostel-role assignment semantics and production credential/session policies need separate review.

## CI and remote inventory

The first credential push's run was superseded by a newer push under the existing cancel-in-progress workflow. Code run [42447799431](https://github.com/VeeraaVikash/MealLoop/actions/runs/42447799431), at `543f09f`, completed **successfully**, including repository rules, Debug, Review and Release. It was watched with `gh run watch 42447799431 --repo VeeraaVikash/MealLoop --exit-status` (exit 0). Later scoped-read/assignment fixes were locally checked as listed above and are included in the final report push; its workflow is watched separately.

Remote inventory immediately before the report commit (no new remote branch/tag created):

```text
$ git ls-remote --heads origin
543f09f5a52941b6b42734c458eeb82a4e6b5ebe refs/heads/main
$ git ls-remote --tags origin | wc -l
29
```

Both commands exited 0. The tag result is 29 ref lines, including peeled annotated-tag refs if any; no tag was created or removed.

The final report push is watched separately, since a report cannot contain the result of the workflow its own commit triggers. No completion claim is made from an in-progress workflow.

## Verdict

BLOCKED on the missing four-mess live-page completion and full manual tap-through (required device-interaction workflow unavailable). The verified parts are pushed for review; this report does not assert ADMIN SCOPES READY FOR REVIEW.
