# Staff complete: Warden, Guardian, Gate and the mess staff roles (Prompt 5)

Pushed straight to `main` under the owner workflow in the Prompt 5 brief (no branch, tag or pull request). Worktree
`../MealLoop-staff-complete`, detached on `origin/main` `69bd972`. Gate: `docs/verification/outings-staff/REPORT.md`
and `MLScreen.swift` are on `origin/main`. `~/Downloads/SWIFTUI_STANDARDS_SPEC.md` and `~/Downloads/blank_audit.py`
are missing: the standards come from `docs/SWIFTUI_STANDARDS.md` and the audit uses
`docs/verification/followups/blank_audit.py` (same thresholds).

## Progress

| Group | State | Commits | Notes |
|---|---|---|---|
| R1 Switch role and languages | Done | `c05fc4f`, `1ab651b` | Kitchen Switch role row removed (no other staff Me page had one). Staff Language and the Guardian pill and sheet show English only. |
| R2 Blank bands | Done | `48ffdd8`, `1fea803`, `052175e` | 20 screens: all at or below 25% (were 52 to 70%). Table below. |
| R3 Figma compare | Done (inventory, no new builds) | none | Earlier passes had compared every frame; the frames still unbuilt each lack data, a camera, or a decision. Table below. |
| R4 Live sign-in walk | Done | none (scratch only) | 7 roles, 40 pages: all reached, 0 crashes, 0 placeholders. Core story: steps 1 to 6 pass; step 7 Supervisor half passes, Admin half partly checked. |
| R5 Report | Done | this file | Final Debug, Review and Release green (below). |

## R1 (owner rulings 1 and 7, 9 November)

| Where | Before | After |
|---|---|---|
| Kitchen Me | "Switch role · Not available yet" | Row removed |
| Door Scanner, Pass Desk, Supervisor Me | No Switch role row | Unchanged |
| Staff Language (MS-G4) | English, plus Tamil "Not translated yet" | English only |
| Guardian language pill | "தமிழ்" | "English" (the language in use) |
| Guardian Language sheet | English, Tamil, Hindi | English only |

Debug tests after R1: exit 0, 804 tests, 760 passed, 0 failed, 44 skipped (screenshot hooks).

## R2 Blank bands (owner ruling 6)

Base audit: Prompt 4's capture of all 198 screens of the seven roles (67 flagged). The 20 highest blank bands among
full-screen pages were taken; Supervisor "Meal history · empty" (60%) was replaced by Guardian "Past answers" (51%)
because an empty history page loads no data to show. After: recaptured with the same hooks on iPhone 18 Pro and
re-run with `docs/verification/followups/blank_audit.py`. Captures in `~/mealloop-captures/staff-complete/`.

| Screen | Before | After | What was added (all from data the page already loads) |
|---|---|---|---|
| Kitchen Alerts · during | 70% | 7% | This meal card (state, times, food-short reports), waste report status, earlier meals from the history |
| Kitchen Alerts · before | 70% | 7% | Same |
| Supervisor Alerts · before the meal (S07a) | 67% | 8% | This meal card (active shortages), waste-not-recorded count, earlier meals |
| Door Alerts · during (2512:173100) | 66% | 7% | This meal card (recorded so far), started, closes, on shift |
| Door Entered without voting · during (2474:3886) | 65% | 14% | Count card, first and latest entry |
| Door Entered without voting · after (2474:3748) | 65% | 14% | Same |
| Door Open problems (2474:3490) | 64% | 7% | Count card, count per kind |
| Pass Desk Open problems · after report (2539:6145) | 61% | 7% | Count card, count per kind, sent and saved on this phone |
| Guardian · after "No" (generated) | 60% | 25% | Student card, the guardian's own number and who sent the link (no outing details) |
| Pass Desk Alerts (2545:6885) | 58% | 7% | This meal card (special meals recorded), times, on shift |
| Door Alerts · after (2512:173241) | 58% | 6% | This meal card (final recorded entries), times, entered without voting |
| Supervisor Alerts · shortage resolved (S07c) | 56% | 6% | As S07a |
| Door Open problems · after report (2474:3613) | 53% | 7% | As 2474:3490 |
| Guardian G-A3 Done | 53% | 12% | The outing from the request |
| Guardian Verify code | 52% | 6% | How it works (student and block from the link) |
| Guardian Sent · withdrawn | 52% | 14% | The outing |
| Guardian Sent · rejected | 52% | 14% | The outing |
| Guardian Uploading | 52% | 12% | The outing |
| Pass Desk Open problems · food short (2539:6267) | 51% | 7% | As 2539:6145 |
| Guardian Past answers (GV-07) | 51% | 19% | Accepted, rejected and by-video counts |

Also improved by the same changes (not in the 20): Supervisor S07 37% to 6%, S07b 48% to 6%. The other 45 flagged
screens were not changed (mostly result screens with a pinned action, Gate results, Warden decided states).
Figma compare for these 20: the frames draw the sparse version; the additions follow the owner's ruling, use the
existing hero card and hairline rows, and were checked by eye in the captures.

## R3 Figma compare

Prompt 4 said the Guardian, Warden, Gate and mess staff frames were "not yet compared". They had been, by earlier
passes, and Prompt 4 had not re-done it. Where each comparison lives:

| Pages | Compared in | Result there |
|---|---|---|
| 13 Guardian, 14 Warden, 15 Gate | `docs/verification/outings/REPORT.md` (one row per frame) | Built and compared, except the rows below |
| 09 Mess Staff: Door Scanner, Pass Desk, Supervisor | `docs/verification/staff-figma-fix/REPORT.md` section 2 | 129 frames: 39 match, 73 differ (listed per frame, mostly shared components), 7 not built, 10 left alone (Pass Desk Home, owner ruling) |
| 09 Mess Staff: Kitchen | `docs/verification/kitchen/REPORT.md` | Compared per frame |
| Guardian G-0 to G-A3, G-5, G-6; Warden W-6; MS-G4, MS-G5 | `docs/verification/outings-staff/REPORT.md` (Prompt 4) | Built and compared |

Frames still unbuilt, and why (no policy invented, none generated):

| Frame | Why it stays unbuilt |
|---|---|
| Gate GA-6 Emergency exit recorded (`1863:127354`) | SRM policy on who authorises it (owner ruling 3) |
| W-0, GA-0, MS-0 sign in, verifying, confirm profile; MS-1 Choose your role | Authentication undecided, P71 (owner ruling 4); the role picker is retired |
| DS-0, PD-0, KS-0, SV-0 "What you do" sheets | Belong to the retired role flow (P-ENTRY-4) |
| DS-1 Camera denied, Low light | The build has no camera, so the states cannot occur |
| DS-2 Several matches | The entry backend returns one student for a last four |
| DS-8 All alerts | No alerts feed behind it (P-STAFF-4) |
| KS-1 Forecast stale (K01c) | The repository cannot tell a stale forecast |
| Warden W-6 "Review window opens" row | No record holds it (owner ruling 2) |

Not re-done in this run: the 73 "differs" items in staff-figma-fix (most are in shared components this brief may not
edit: tab bar, mark, back fill, hero eyebrow case).

## R4 Live sign-in walk (scratch copy, never committed)

How it ran: a copy of this code in the session scratchpad with a temporary XCUITest target `MealLoopWalk` (the
target the integration session used, grafted onto today's project file), `xcodebuild test -scheme "MealLoop Review"
-configuration Review -only-testing:MealLoopWalk`, one simulator, no parallel testing. The walk signs in through Staff
sign in with the presenter accounts (`docs/PRESENTER_ACCOUNTS.md`) and searches the accessibility tree of every page
for "Coming soon", "Not implemented" and "isn't part of this prototype".

| Role | Pages opened | Reached | Crashed | Placeholder text |
|---|---|---|---|---|
| Kitchen | Home, Alerts, Me, Me > Meal history, Language, Help | 6 | 0 | 0 |
| Door Scanner | Home, Alerts, Me, Me > Language, Help, Home > Report a problem | 6 | 0 | 0 |
| Pass Desk | Home, Alerts, Me, Me > Language, Help, Home > Report a problem | 6 | 0 | 0 |
| Supervisor | Home, Alerts, Me, Me > Meal history, a past meal | 5 | 0 | 0 |
| Warden | Queue, Out now, Escalated, History, Me, Me > Alerts, Me > Help | 7 | 0 | 0 |
| Gate | Home, Out now, Overdue returns, Report a problem | 4 | 0 | 0 |
| Guardian | G-0 Sign in, Verify code, decision page, Past answers, Notifications, Help | 6 | 0 | 0 |

The walk's first two runs reported Gate "Overdue returns" and "Report a problem" as not found: a fault in the walk
(it did not go back after Out now, and Gate tiles read as one combined label). After fixing the walk, all 40 pages
were reached.

Core-story walk (`docs/verification/integration/REPORT.md` section 3), re-run once on today's code:

| Step | Result |
|---|---|
| 1 Student: sign in, lunch, I'm in, entry QR | Pass. The QR shows "Live", as owner decision 4 now requires (the old walk asserted the opposite and was updated). |
| 2 Food Head: approve and send the headcount | Pass, after updating the walk: the rebuilt Today names the step "Approve" (was "Review and approve"). |
| 2b Student: lunch answers locked | Pass: Home says "Lunch answers closed · Cutoff 10 AM passed · your QR still works", no Answer or Change. |
| 3 Supervisor: Start meal | Pass |
| 4 Door Scanner: record an entry by last four | Pass |
| 5 Kitchen: live count, shortage, Supervisor sees it | Pass |
| 6 Supervisor close; Kitchen record and save waste | Pass |
| 7 Supervisor and Admin: waste read only | Supervisor half: pass. Admin half: not completed by the walk. Admin Results no longer has the "To check" filter the walk taps; the Results page itself lists "Lunch, Wed 14 · sent 860 · came 1" and "Plate waste, 18 kg" with no edit action (from the accessibility tree). The Admin meal report page was not opened. |

Nothing in the seven roles broke, so nothing was fixed in R4. The walk changes are test-only and stay in the scratch copy.

## R5 Summary

**Placeholders left per role** (signed in, reachable): Warden 0, Guardian 0, Gate 0, Kitchen 0, Door Scanner 0,
Pass Desk 0, Supervisor 0. Kitchen's "Switch role · Not available yet" row was removed (R1). Checked by `grep` over the
eight feature folders and by the live walk (R4).

**Generated pages:** none new in this run. Prompt 4's two stay (owner to review): the Guardian step after "No, call the
hostel office" (now with the guardian's own number and who sent the link) and the Warden Help answers.

**Still needing a decision:** none new. The owner's rulings of 9 November settled Prompt 4's seven items; ruling 3
(emergency exit) and ruling 4 (sign-in frames) leave those frames unbuilt by decision.

**Diff:** only the Guardian, Kitchen, Door Scanner, Pass Desk, Supervisor and Warden feature folders and this report.
No shared component, token, tab bar, `MLScreen`, `RoleRootView`, `openapi.yaml`, ADR, Student or Admin file, and no
image outside `ios/`. Pass Desk Home was not touched.

**Not checked:** a physical device, the camera, a live edge swipe, VoiceOver, the largest Dynamic Type, iPhone SE.

## Tests

| Run | Result |
|---|---|
| Debug after R1 | exit 0: 804 tests, 760 passed, 0 failed, 44 skipped |
| Debug after R2 | exit 0: 804 tests, 760 passed, 0 failed, 44 skipped |
| Final Debug (`xcodebuild test`, scheme MealLoop, no parallel testing) | exit 0: 804 tests, 760 passed, 0 failed, 44 skipped |
| Final Review (scheme MealLoop Review) | exit 0: 802 tests, 759 passed, 0 failed, 43 skipped |
| Release build (generic iOS Simulator) | exit 0 |
| Walk (scratch copy, Review build, `MealLoopWalk`) | RoleWalk: 40 pages reached; CoreStoryWalk: steps 1 to 6 pass, step 7 stops at the Admin "To check" filter (see R4) |

Skipped tests are the screenshot hooks, which run only with their output folder set.
