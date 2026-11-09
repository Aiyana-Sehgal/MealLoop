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
| R3 Figma compare | Not started | | |
| R4 Live sign-in walk | Not started | | |
| R5 Report | Not started | | |

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
