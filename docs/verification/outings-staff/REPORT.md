# Outings and mess staff roles: finish, generate what is missing, audit (Prompt 4)

Pushed straight to `main` under the owner workflow in the Prompt 4 brief. `CLAUDE.md` and `docs/BRANCHING.md` say
never to push to the default branch; the brief overrides them. No branch, tag or pull request was created. Work ran
in the detached worktree `../MealLoop-outings-staff`. Figma `nzzTAm9YnJRSdKEeYUWUEb` was read only.
`~/Downloads/SWIFTUI_STANDARDS_SPEC.md`, `~/Downloads/FIGMA_FRAME_MAP.md` and `~/Downloads/blank_audit.py` were missing:
the standards come from `docs/SWIFTUI_STANDARDS.md`, frames were listed with `get_metadata`, and the audit script is
the copy in `docs/verification/followups/blank_audit.py` (same thresholds: a blank band above 25% is flagged).

The first run stopped at its usage limit with uncommitted work and a build broken by three stray braces. The resumed
run fixed the braces, rebuilt and continued.

## Progress

| Group | State | Commits | Notes |
|---|---|---|---|
| M Missing-page sweep | Done | `4c0df2f`, `8674c38`, `f589be6` | 0 reachable Coming soon or Not implemented pages left. Kitchen Switch role reads "Not available yet". |
| O1 Guardian entry flow | Done | `841d898` | Five frames, simulated first-run flow; one generated step after "No". |
| O2 Guardian audit | Partial | `f6cdba3` | G-5 and G-6 built. GV-00 to GV-07 and G-3 were built by the outings pass and not re-compared frame by frame. |
| O3 Warden audit | Partial | `8674c38`, `9dae694` | 25 frames listed. W-6 Alerts built and matched. W-0 (3 frames) not built (Needs a decision 4). WV-1 to WV-5 unchanged, not re-compared. |
| O4 Gate audit | Partial | none | 23 frames listed. GA-1 to GA-9 are built. GA-6 Emergency exit recorded and GA-0 (3 frames) not built (Needs a decision 3, 4). |
| S1 to S4 Mess staff | Partial | `4c0df2f`, `f589be6` | Me pages: Language (MS-G4) and Help (MS-G5) built for Kitchen, Door Scanner, Pass Desk. The 261 frames on page 09 were not re-compared one by one; the staff-figma-fix and supervisor passes cover them. |
| A Spacing audit | Done (no layout fixes) | none | 198 screens: 67 flagged. All checked categories are sparse in their frames too (below). |
| F Final audit | Partial | this file | No live walk through the simulator UI; the capture hooks and unit tests stand in (below). |

## Missing-page sweep (M)

Searched the eight feature folders for `Coming soon`, `ComingSoon`, `Not implemented`, `NotImplementedView`,
`isn't part of this prototype`, `notBuilt` and empty actions.

| Found | Opened from | Resolution |
|---|---|---|
| Language, Help (Coming soon page) | Kitchen Me, Door Scanner Me, Pass Desk Me | Pushed pages from MS-G4 `1520:122891` and MS-G5 `1520:122941` |
| Switch role (Coming soon page) | Kitchen Me | Row reads "Not available yet" (Needs a decision 1) |
| Alerts (Not implemented page) | Warden Me | Built from W-6 `1855:1489` |
| Help (Not implemented page) | Warden Me | MS-G5 layout with Warden answers (generated content) |
| Messages, Help (disabled links) | Guardian Past answers | G-5 `1931:132246` and G-6 `1931:936` |
| `NotImplementedView` in each role's root | Only a session of another role | Not reachable from a signed-in role; kept as the guard |

Intentionally disabled, not placeholders: Door Scanner Record entry until a match or while offline; Guardian answer
buttons after the deadline; every call button (the prototype places no calls), including Gate's offline Call the warden.

**Reachable placeholders left per role:** Warden 0, Guardian 0, Gate 0, Kitchen 1 (Switch role, honest "Not available
yet"), Door Scanner 0, Pass Desk 0, Supervisor 0.

## Changed or built screens (captures in `~/mealloop-captures/outings-staff/iphone18pro/`, not committed)

| Screen | Frame | Result |
|---|---|---|
| G-0 Sign in | `1929:131727` | Matches: phone from the seeded link, How it works names the student and block. |
| G-0 Verify code | `1929:131799` | Matches; adds "Prototype: no code is sent, so any 6 digits continue." |
| G-A1 Activate account | `1929:131872` | Matches. |
| G-A2 Confirm link | `1929:131931` | Differs: "2nd year" left out (no record holds the year). |
| G-A3 Done | `1929:132000` | Matches; Open the request opens the decision page. |
| G-5 Notifications | `1931:132246` | Differs: says the prototype sends no SMS; no unread dots; New request has no time (none recorded). |
| G-6 Help | `1931:936` | Matches; Call the warden shown but not active. |
| W-6 Alerts | `1855:1489` | Matches the rows. Differs: large title (the shared Warden page wrapper); no "Review window opens" row. |
| Language (staff) | MS-G4 `1520:122891` | Matches; Tamil shown as "Not translated yet"; no Hindi (the frame shows none). |
| Help (staff) | MS-G5 `1520:122941` | Layout matches; answers differ (below). |
| Kitchen Me | K13 | Switch role "Not available yet"; Language and Help push pages. |

Simulated guardian sign in (P71): nothing is sent, nobody is called; the 6 digits, 10 minutes and 48 hours are the
frames' wording, not rules the app applies. The flow runs once per launch; a relaunch starts it again.

## Generated pages (generated by the session, owner to review)

| Page | Role | Reason | Capture |
|---|---|---|---|
| After "No, call the hostel office" | Guardian | G-A2 has no next frame. Says nothing is shared, no call is placed and the answer is not recorded; Back to sign in. | `GA2_guardian_declined.png` |
| Help answers | Warden | No Warden Help frame. MS-G5 layout; four answers repeat the outing rules (guardian first, video is not approval, no timeout approves, gate needs a signed pass). | not captured |

## Needs a decision

1. **Kitchen Switch role.** Who may hold two staff roles, and how they switch.
2. **Warden Alerts, "Review window opens".** W-6 draws it; no record holds review windows and the window is policy.
3. **Gate emergency exit.** GA-6 "Emergency exit recorded" exists, but no frame says how the duty warden authorises
   it. Not built, and no entry point offers it.
4. **Sign-in frames for Warden (W-0), Gate (GA-0) and mess staff (MS-0, MS-1).** Staff sign in stays the way in;
   a second sign in waits for the authentication decision (P71).
5. **Staff Help answers.** MS-G5's Kitchen answers name a 9:00 AM plan, an 11:30 change cut-off and a "Waiting to send"
   queue. No record or screen holds them, so the app shows answers from each role's documented rules instead.
6. **Sparse screens.** 67 of 198 screens have a blank band above 25%. The ones checked are sparse in their frames too;
   adding content would invent it. Decide whether any of these should carry more (for example Alerts lists).
7. **Translations.** Tamil and Hindi are listed but have no text.

## Spacing audit (A)

198 screens of the seven roles captured once on iPhone 18 Pro (OutingScreenshotTests, StaffFigmaScreenshotTests with a
new Kitchen capture, SupervisorScreenshotTests). Output kept in `~/mealloop-captures/outings-staff/audit-before/`.

| Category (flagged count) | Example, blank before | Frame checked | Result |
|---|---|---|---|
| Result screens with a pinned action: Gate GA-6, Guardian record and sent states, Warden decided | `V5_gate_offline` 45%, `G00_guardian_consent` 40% | GV-00 `2387:1408`; GA-6 metadata (result block ends at y 499, button at 754) | Sparse in the frame; action pinned as drawn. Unchanged. |
| Short lists: Alerts on Kitchen, Door Scanner, Pass Desk, Supervisor; Entered without voting; meal history | `kitchen_alerts_before` 70%, Door `2512_173100` 66% | Door Alerts `2512:173100` | Frame is sparse too (3 rows); the seed holds 1 at that moment. Unchanged. |
| Empty, loading and error states | `S18d_meal_history_empty` 60% | not checked | Unchanged. |

After this run's changes, the changed screens measure: G-0 Sign in 7%, G-5 24%, G-6 5%, G-A1 24%, W-6 4%, Kitchen Me
22% (not flagged); Verify code 52%, Confirm link 48%, Done 53%, Declined 60%, Language 44%, Help 29% (flagged, each
matching its frame's own blank or, for Declined, a generated page with a pinned action). Flagged screens before 67,
after 67: no layout was changed to satisfy the metric.

## Final audit (F)

| Role | Screens captured | Placeholders left | Flagged | Standards on screens touched |
|---|---|---|---|---|
| Guardian | 44 | 0 | 18 | Entry flow and info pages: NavigationStack with system back (swipe-back), inline titles, sheets sized to content |
| Warden | 24 | 0 | 4 | Alerts and Help pushed in the Warden stack |
| Gate | 19 | 0 | 7 | unchanged |
| Kitchen | 7 | 1 | 2 | Language and Help pushed with the system back button |
| Door Scanner | 35 | 0 | 13 | same |
| Pass Desk | 25 | 0 | 7 | same |
| Supervisor | 44 | 0 | 16 | unchanged |

Counts are from the before-audit captures (198 screens, 67 flagged), grouped by file name; Door Scanner and Pass
Desk captures are named by frame node and were grouped by node range. The category split of the 67 was not counted.
The core-story walk in `docs/verification/integration/REPORT.md` has no UI harness here: `CoreStoryTests` and the rest
of the unit tests ran instead (below). Not checked: a physical device, the camera, a live edge swipe, VoiceOver, the
largest Dynamic Type, iPhone SE.

## Tests

| Run | Result |
|---|---|
| Debug tests after M | exit 0: 793 tests, 753 passed, 0 failed, 40 skipped |
| Debug tests after O1 and O2 | exit 0: 799 tests, 757 passed, 0 failed, 42 skipped |
| Debug tests after the staff pages | exit 0: 801 tests, 757 passed, 0 failed, 44 skipped |
| Final Debug tests (`xcodebuild test`, scheme MealLoop, no parallel testing) | exit 0: 804 tests, 760 passed, 0 failed, 44 skipped |
| Final Review tests (scheme MealLoop Review) | exit 0: 802 tests, 759 passed, 0 failed, 43 skipped |
| Release build (generic iOS Simulator) | exit 0, 1 warning, none in the seven roles' folders |

Skipped tests are the screenshot hooks, which run only with their output folder set.

## For the owner in the morning

1. Generated: the Guardian step after "No, call the hostel office" (`GA2_guardian_declined.png`).
2. Generated: the Warden Help answers (MS-G5 layout, no Warden frame).
3. Staff Help shows the roles' documented rules, not MS-G5's Kitchen answers (Needs a decision 5).
4. Needs a decision 1 to 7 above: Switch role, review window, emergency exit, the W-0, GA-0 and MS-0 sign-in frames,
   Help answers, sparse screens, translations.
5. The Guardian sign in is simulated: it runs once per launch before the decision page.
