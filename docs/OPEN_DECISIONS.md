# Open decisions

Decisions the owner still has to make. Each row gives the options and a **suggested default** so work can continue; a suggested default is not a decision. Where a gap number exists in `design/audit/prototype_gaps.md` it is given.

## Product

| # | Decision | Options | Suggested default | Blocks |
|---|---|---|---|---|
| P1 | Credits formula, thresholds, rewards and eligibility window | Participation only; participation + accuracy (answer matched a verified entry); weighting and window undecided | Participation + accuracy, both counted only from verified data. Ship no numbers until approved; screens show "Credits soon" | Student Credits screens, any reward logic |
| P2 | Community "Me too" support threshold | A fixed count; a share of the mess; per-category | Keep `CommunityPolicy.supportThreshold = nil`; admins publish manually until decided | Community escalation |
| P3 | Digital-outing eligibility formula | Participation rate; reliability (answers that matched entries); both, over a window | Nobody eligible by formula until approved; the existing SRM outing process stays the default | Student outings (P2 priority) |
| P4 | Guardian video policy | Privacy approval by SRM; retention (draft 30 days, then transcript and fingerprint only); languages (English, Tamil, Hindi first); guardian number verification source; whether the call path is allowed | Build behind a switch that is off until SRM approves; draft 30 days | Guardian and Warden |
| P5 | Offline policy for scanning and pass checks | Never record (draft); queue on device and sync later | Never record: show "This entry is NOT recorded" | Door Scanner, Pass Desk |
| P6 | Vendor channel | WhatsApp; phone call; SMS | Record the headcount in MealLoop and the reply manually; choose the channel before the pilot | Admin headcount "Tell the vendor" |
| P7 | Whether students answer for Snacks | Yes; no (menu only) | Menu only; no answer buttons for Snacks (gap 382) | Student Home and Meals |
| P8 | Meaning of the yellow highlight on the printed menu | Chef's special; new dish; other | Show it as "Highlight" with the existing note "Marked by the mess on the menu board" (gap 381) | Student Meals |
| P9 | Who the `**` gravies are for | Non-veg; a specific group | Keep the slim non-veg row as drawn (gap 383) | Student Meals |
| P10 | How long a missed meal's waste can still be recorded | No limit (draft); a fixed window | No limit, with "Not recorded" until saved | Kitchen Record waste |
| P11 | Pilot naming | Keep the sample "Main Mess" in screens; rename to Meenakshi Girls' Mess | Keep sample names in Debug only and label them sample; real names come from the backend | All screens |
| P12 | Who can see "Entered without voting" | Door Scanner and Supervisor (draft); admin too | Door Scanner and Supervisor | Door Scanner, Supervisor |
| P13 | Should "Start meal" unlock only near the scheduled time | Always available (draft); unlock N minutes before | Always available | Supervisor |
| P14 | Student sign-in provider and profile corrections | SRM SSO; other | Not implemented until SRM confirms | Student onboarding |
| P15 | Old admin page 10 | Archive it; keep it as a reference | Treat page 12 as the only admin requirement; page 10 rows are "Needs review" | Admin |
| P16 | Student Crowd page | Keep the POLISH Crowd page; follow STUDENT-REDESIGN (one Home row only) | One Home row only until the owner confirms | Student |
| P17 | Dark mode | Rebuild page 05 first; ship Light only | Light only for 10 November | All |
| P18 | Kitchen K19 and K20 (SOS on Kitchen Home) | Draw them in Figma first; build from the pack image | Draw first, then build | Kitchen |

## Technical

| # | Decision | Options | Suggested default |
|---|---|---|---|
| T1 | Minimum iOS | 17 (Observation); 18; 26 (matches the Liquid Glass design) | **iOS 17** (used in the foundation, see ADR-001) |
| T2 | Bundle identifier and Apple developer team | Any reverse-DNS the institution or team owns | Placeholder `in.mealloop.app` until decided |
| T3 | Demo role password | The design documents no value | Placeholder `1234` in `DemoSeed.simulatedRolePassword`, Debug only |
| T4 | Colour tokens not named in the documents | `onHero` #FFFFFF, `onHeroSecondary` #B5B5AE and `danger` #B32635 were **measured** from the K02 and D03 exports | Keep the measured values and confirm them against the Figma "ML Color" variables. The hinted `#FBFBF4` (card) and `#E8E7DE` (soft) do not appear in the exports or the documents and were **not** added |
| T5 | Disabled keypad on the locked password page | The rule says disabled controls are outlined or dashed, never faded; the D03 locked export shows a faded keypad | Follow the export (faded at 40%) until the owner picks |
| T6 | "What you do" wording for Kitchen | The export says "send it to Ravi" (a sample name) before anyone has signed in | "send it to the supervisor"; the real name needs a session |
| T7 | Icons and logo | SF Symbols as stand-ins; the drawn pictograms from the reference packs; the final logo file | SF Symbols now (gap 386); swap in the drawn set as an asset catalogue when exported; logo pending (gap 384) |
| T8 | Fonts | SF Pro / SF Mono (the design's real target); Inter / JetBrains Mono (Figma stand-ins) | System SF fonts |
| T9 | When live entries count as stale | The design shows the state but no threshold | 2 minutes (`KitchenHomeViewModel.staleAfter`) |
| T10 | When a forecast counts as stale | The design shows "Updated 8:50 AM, may be out of date" but no rule | Not implemented; needs a rule from the forecast owner |
| T11 | Swift packages | One target with folders (now); split Domain, DesignSystem and Features into packages | Revisit if a clean build takes over 2 minutes or ownership needs enforcing |
| T12 | Backend hosting | Institution server; cloud | Decide before External Review 4 |

## Entry and accounts (2026-11-06)

Raised while building the launch-ready entry. Each entry records what the prototype does today, not a decision.

| ID | Question | What the prototype does now |
|---|---|---|
| P-ENTRY-1 | How does Super Admin reach the app before real SRM SSO exists? | The simulated SRM step returns the student, so the seeded Super Admin also works on Staff sign in. This is a prototype exception, not the intended design |
| P-ENTRY-2 | How do Guardian, Warden, Gate Security and Vendor sign in for real? The Guardian design is an SMS link with OTP on mobile web | All four use Staff sign in with a seeded account |
| P-ENTRY-3 | What does "Forgot password?" do? | It shows "Password reset isn't available yet. Ask your administrator." No flow exists |
| P-ENTRY-4 | Do Choose your role, What you do and the shared role password (D01 to D03) return in any form? | Replaced by Staff sign in. The code stays in Debug only with nothing opening it |
| P-ENTRY-5 | What tabs do Gate Security, Vendor and Super Admin have? | No design documents them. They use Home and Me as placeholders |
| P-ENTRY-6 | Which mess or hostel scope does Super Admin have? | The seed gives it the sample mess, because the account model allows only a mess or a hostel |

## Core story (2026-11-06)

Proposals from the core-story contracts work. Each records what the prototype does today, not a decision.

| ID | Question | What the prototype does now |
|---|---|---|
| P-STORY-1 | Should a student's answer move the forecast? | No. The forecast is the seeded 860, and only the counts of each answer are derived. No formula has been approved |
| P-STORY-2 | Sample answers | **Sample, not measured.** Meera, Kiran and Dev are names from the design documents; their lunch answers are made up so counts are not empty. The counts cover this roster of four, not the 860 forecast |
| P-STORY-3 | What is the cutoff forecast in Review? | It stays missing, because no document gives a value. Proposal: keep it missing until the owner supplies one |
| P-STORY-4 | What does "wrong meal" mean with one static code per student? | The Door spec means a QR for another meal. With a static code, the prototype reports a wrong meal when the meal asked for is not the one being served |
| P-STORY-5 | Should the live count start from a sample base? | **Decided by the owner (2026-11-06): no.** In Review it starts at 0 when the Supervisor starts the meal, and each recorded entry raises it |
| P-STORY-6 | Entry QR refresh | Known difference from `08_entry_qr`: the code is static, and "Refreshes in 12 s" is not built |
| P-STORY-7 | The sample student and the pilot mess | The pilot is Meenakshi Girls' Mess, but the sample student is Aarav and `W01` says "Aarav and his guardian". The seed mess is "Main Mess". Nothing was renamed |
| P-STORY-8 | How much of breakfast is seeded? | Times and the student's answer only. It follows the clock, the Supervisor does not run it, and its menu is empty and its headcount values are missing. Proposal: Part 3b seeds the menu from `mess_menu_2024-08-12.md` |
| P-STORY-9 | Lunch cutoff wording | `03_home` and `07_lunch_answer` say 9 AM, but the two-hour rule gives 10:00 AM, which is what the backend enforces |
| P-STORY-10 | Who can save a waste report? | **Decided by the owner (2026-11-06): Kitchen Staff only.** `save` and `saveDraft` take a role and refuse every other role, so Supervisor and Admin can only read |

## Owner decisions (2026-11-07)

Stated by the owner in chat and recorded here as CONFIRMED with the date 7 November 2026 (decision 8 carries the owner's 9 November correction).

| ID | Decision | Status |
|---|---|---|
| OD-1 | The role picker stays banned and "Continue as ..." stays removed; rehearsal uses `docs/PRESENTER_ACCOUNTS.md` and iOS autofill. | CONFIRMED 2026-11-07 |
| OD-2 | The Search button stays in the tab bar; its one real function before the review is filtering dishes on the Student Meals screen. | CONFIRMED 2026-11-07 |
| OD-3 | The Review clock is story-driven with no visible control (starts 7:00 AM; Food Head approval moves it past the lunch cutoff; Supervisor start and close move it on). | CONFIRMED 2026-11-07 |
| OD-4 | The Student entry QR matches Figma: "Live" label and a 12-second refresh bar, with a real timed rotation, simulated and not verified by a scanner. | CONFIRMED 2026-11-07 |
| OD-5 | Where Figma draws a chip, pill, icon, outline or badge, the build matches Figma; the "status is a dot plus text" rule applies only where a frame draws a dot (the Kitchen ruling that its statuses are dot plus text stands). | CONFIRMED 2026-11-07 |
| OD-6 | Pass Desk Home during the meal shows the current pass code and colour like the student's pass (no student entry first); the last-four entry is the fallback. | CONFIRMED 2026-11-07 |
| OD-7 | All screens are required for the review: every screen present with static data, and real interaction only on the core cross-role story. | CONFIRMED 2026-11-07 |
| OD-8 | Roles: the Food Head (`foodhead@mealloop.example`) is single-mess and sees only their own mess; the Super Admin (`superadmin@mealloop.example`) sees every mess and manages People and access; the Supervisor is specific to one mess and starts and closes the meal for that mess only. (Owner correction, 9 November; it replaces the earlier "one combined role" wording.) | CONFIRMED 2026-11-07 |
| OD-9 | Passwords: the Super Admin can give a password for a specific role (a temporary password shown once, never readable afterwards) and revoke it (signs the person out and blocks sign-in until a new password is given). | CONFIRMED 2026-11-07 |
| OD-10 | The Vendor has a restricted MealLoop account and acknowledges the approved headcount; a missing acknowledgment is Pending and never filled in. (The older Figma "Vendor contact · Not a login" frame is an open conflict: RA-1 below.) | CONFIRMED 2026-11-07 |
| OD-11 | Special pass: hold-to-use stays (in a compact sheet); a student requests next week's pass and the Admin accepts or declines it (masked IDs only); a request never unlocks the pass. | CONFIRMED 2026-11-07 |
| OD-12 | Ratings of a meal or dish stay open for 2 days after the meal ends and can be changed in that window. | CONFIRMED 2026-11-07 |
| OD-13 | Outings: the "What happens next" stepper shows Your guardian, The warden, You are out; the last step is lit only after the warden approves; nothing is approved by waiting. | CONFIRMED 2026-11-07 |
| OD-14 | Rewards: the Admin can add and delete reward items; Student Credits reads the same catalogue. The meaning of "in get 3 can make card too change 3 times" is open (P-FINAL-10). | CONFIRMED 2026-11-07 |
| OD-15 | Staff Me pages have no "Switch role" row. | CONFIRMED 2026-11-07 |

## Review additions spec, open items

From `docs/design/REVIEW_ADDITIONS_SPEC.md`, section "Open items".

| ID | Question | Status |
|---|---|---|
| RA-1 | The Figma People and access frame draws "Vendor contact · Not a login · headcount goes by message", while the PRD and the Vendor screens give the vendor a restricted account: which is right? | OPEN |
| RA-2 | Who may revoke an Admin account? | OPEN |
| RA-3 | Role-scoped lists beyond Door staff (Mess supervisors, Kitchen staff, Wardens, Gate security) use the same layout: confirm. | OPEN |

## Review-build questions (from the part reports)

Collected on 2026-11-09 from every `docs/verification/*/REPORT.md` on `main`. Each keeps its report's ID; the question is the report's own first sentence. IDs already listed above are not repeated.

| ID | Question | From | Status |
|---|---|---|---|
| D-INT-1 | Wed 14 lunch final entries: 774 (`kitchen_spec.md`, `supervisor_spec.md`) or 786 (`admin_sample_data.md`). | integration (`docs/verification/integration/REPORT.md`) | OPEN |
| D-INT-2 | Approve the proposed rule "a comparable meal that ran out does not count as comparable" (implemented as proposed). | integration (`docs/verification/integration/REPORT.md`) | OPEN |
| D-INT-3 | The draft reason thresholds (5%, 40%, 30 min, 15 min, 3 "not good"): SRM approval required (pack open item 2). | integration (`docs/verification/integration/REPORT.md`) | OPEN |
| D-INT-4 | Admin's missing-number glyph: "—" or "Unavailable" (observation 4). | integration (`docs/verification/integration/REPORT.md`) | OPEN |
| D-INT-5 | Whether the story lunch's seeded "Rice ran out 1:34 PM" stays once the meal is run live (observation 2), and the Tue dinner ran-out (observation 3). | integration (`docs/verification/integration/REPORT.md`) | OPEN |
| OUT-01 | Approve the outing story clock: one forward-only clock that moves to each role's drawn moment (Fri 7:41 PM guardian, Sat 10:00 AM warden, Sat 2:00 PM gate)? | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| OUT-02 | The seed keeps the design's names, including "Aarav's guardian" (DemoSeed) and male sample students, while the pilot is a girls' mess. | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| OUT-03 | Production guardian authentication (G-0 Sign in, Verify code, G-A1–A3 Activate) is undecided, so those five frames are not built. | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| OUT-04 | Video retention is a draft (30 days). | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| OUT-05 | Languages: who writes the Tamil and Hindi phrase and page translations? | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| OUT-06 | Is the call path allowed (spec open item)? | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| OUT-07 | W01 says Aarav has "3 by video"; G07 lists one video and one one-tap reject. | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| OUT-08 | Sample density: W01 "1 of 14", W02 "12 out", GA-6 "3 out now" need more students than the frames name. | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| OUT-09 | Add the G-3 green and amber status colours to the tokens? | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| OUT-10 | Can the warden withdraw a signed pass (GA-6 says so; no warden action is drawn)? | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| OUT-11 | Emergency exit: how does the duty warden authorise it, and what does the gate record? | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| OUT-12 | `Domain/Outing.swift` (`OutingState`) has no call path and no close; this part added `OutingStage` beside it. | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| OUT-13 | Student pronouns in copy: the frames say "his"; these screens use the name or "their". | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| OUT-14 | Warden undo: the screen offers it for 10 seconds; the prototype allows it until the pass is used. | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| OUT-15 | Warden "Past answers" link and guardian "Messages" / "Help" have no drawn destination. | outings (`docs/verification/outings/REPORT.md`) | OPEN |
| P-ADMIN-1 | Can a headcount be approved or sent once the meal has closed? | admin-today (`docs/verification/admin-today/REPORT.md`) | OPEN |
| P-ADMIN-2 | Must the headcount be approved before the Supervisor starts the meal? | admin-today (`docs/verification/admin-today/REPORT.md`) | OPEN |
| P-ADMIN-3 | What should the Food Head see for reminders and escalation (P25)? | admin-today (`docs/verification/admin-today/REPORT.md`) | OPEN |
| P-ADMIN-4 | How is a change made after sending (FR-VEN-004, P66)? | admin-today (`docs/verification/admin-today/REPORT.md`) | OPEN |
| P-ADMIN-5 | Where do the forecast's rule version and time show (FR-HC-003)? | admin-today (`docs/verification/admin-today/REPORT.md`) | OPEN |
| P-ADMIN-6 | Should `KitchenHomeViewModel.staleAfter` (T9) move somewhere shared? | admin-today (`docs/verification/admin-today/REPORT.md`) | OPEN |
| P-ADMIN-7 | Wed lunch final entries: 786 (Admin pack) or 774 (Kitchen spec, seed)? | admin-results (`docs/verification/admin-results/REPORT.md`) | OPEN |
| P-ADMIN-8 | Tue dinner, Main: the Admin pack has 640 → 691 with rice out; the Supervisor seed has 598 and no shortage. | admin-results (`docs/verification/admin-results/REPORT.md`) | OPEN |
| P-ADMIN-9 | The pack gives four rice stories for its 2 ran-out meals (Wed 1:34 PM Main, Tue 8:34 PM Main, Mon 8:40 PM South, and Tue 1:50 PM North) and four reasons at 1 meal each. | admin-results (`docs/verification/admin-results/REPORT.md`) | OPEN |
| P-ADMIN-10 | Confirm the draft thresholds: 5%, 40%, 15 minutes | admin-results (`docs/verification/admin-results/REPORT.md`) | OPEN |
| P-ADMIN-11 | How is "data complete" worked out? | admin-results (`docs/verification/admin-results/REPORT.md`) | OPEN |
| P-ADMIN-12 | Does a comparable meal that ran out stop "worked", or only flag it? | admin-results (`docs/verification/admin-results/REPORT.md`) | OPEN |
| P-ADMIN-13 | Should simulated sends keep the pack's wording ("Students see it now")? | admin-results (`docs/verification/admin-results/REPORT.md`) | OPEN |
| P-ADMIN-14 | Can the Food Head close a safety case? | admin-results (`docs/verification/admin-results/REPORT.md`) | OPEN |
| P-ADMIN-15 | Should seed gain North, South and Annexe as messes? | admin-results (`docs/verification/admin-results/REPORT.md`) | OPEN |
| P-ADMIN-16 | Is Ravi Kitchen (Admin pack) or Supervisor (seed)? | admin-results (`docs/verification/admin-results/REPORT.md`) | OPEN |
| P-ADMIN-17 | Should "Karan" show on Passes? | admin-results (`docs/verification/admin-results/REPORT.md`) | OPEN |
| P-ADMIN-18 | Does Announce ship (pack open item 4)? | admin-results (`docs/verification/admin-results/REPORT.md`) | OPEN |
| P-ADMIN-19 | What does "Copy last Thursday" read? | admin-results (`docs/verification/admin-results/REPORT.md`) | OPEN |
| P-DOOR-1 | Should the "Sent to Ravi" toast stay in the review, given that nothing is delivered? | door-scanner (`docs/verification/door-scanner/REPORT.md`) | OPEN |
| P-DOOR-2 | Which screen should open Entered without voting during the meal? | door-scanner (`docs/verification/door-scanner/REPORT.md`) | OPEN |
| P-DOOR-3 | What should Switch role do now that role selection is retired? | door-scanner (`docs/verification/door-scanner/REPORT.md`) | CONFIRMED 2026-11-07 (owner decision 15: staff Me pages have no Switch role row) |
| P-DOOR-4 | Should a second person be able to claim a case someone else has claimed? | door-scanner (`docs/verification/door-scanner/REPORT.md`) | OPEN |
| P-FINAL-1 | How long Fixed problems stay on Community (the frame says 30 days; no document). | student-final (`docs/verification/student-final/REPORT.md`) | OPEN |
| P-FINAL-2 | Whether staff sign in with SRM as MS-0 draws, or keep email and password. | student-final (`docs/verification/student-final/REPORT.md`) | OPEN |
| P-FINAL-3 | Which words hold a report for moderation (the prototype uses staff names and phone numbers). | student-final (`docs/verification/student-final/REPORT.md`) | OPEN |
| P-FINAL-4 | When "No one reads reports right now" applies (the prototype uses before 7:00 AM, the only known opening time). | student-final (`docs/verification/student-final/REPORT.md`) | OPEN |
| P-FINAL-5 | Do reward tickets rotate their code like the Special pass, and does the Pass Desk check them? | student-final (`docs/verification/student-final/REPORT.md`) | OPEN |
| P-FINAL-6 | How long is a reward ticket valid ("valid today" in 1529:1901)? | student-final (`docs/verification/student-final/REPORT.md`) | OPEN |
| P-FINAL-7 | Who answers a balance question, and where does the reply show? | student-final (`docs/verification/student-final/REPORT.md`) | OPEN |
| P-FINAL-8 | Ratings earning credits: the history frame shows +2 for a rating; the ratings spec says none. | student-final (`docs/verification/student-final/REPORT.md`) | OPEN |
| P-FINAL-9 | Approval of the Special pass redesign (B2e). | student-final (`docs/verification/student-final/REPORT.md`) | OPEN |
| P-FINAL-10 | "in get 3 can make card too change 3 times" (Credits Get) is unclear. | followups (`docs/verification/followups/REPORT.md`) | OPEN |
| P-FOLLOWUP-1 | Added rewards show "At your mess counter" as their place line, the wording of every seeded reward | followups (`docs/verification/followups/REPORT.md`) | OPEN |
| P-FOLLOWUP-2 | Next week's pass requests: is there a request deadline, and a limit on how many the Admin accepts? | followups (`docs/verification/followups/REPORT.md`) | OPEN |
| P-FOLLOWUP-3 | Rewards › the earlier ₹ budget lines per reward (₹30 each, 57 left) are no longer listed; the | followups (`docs/verification/followups/REPORT.md`) | OPEN |
| P-KITCHEN-1 | Should waste be recordable for an earlier meal such as Tue 13 Dinner (K09b)? | kitchen (`docs/verification/kitchen/REPORT.md`) | OPEN |
| P-KITCHEN-2 | How long can a missed meal's waste be recorded? | kitchen (`docs/verification/kitchen/REPORT.md`) | OPEN |
| P-KITCHEN-3 | Should a report written while offline be kept after a relaunch? | kitchen (`docs/verification/kitchen/REPORT.md`) | OPEN |
| P-KITCHEN-4 | "Back to cooking" or "Back to the kitchen"? | kitchen (`docs/verification/kitchen/REPORT.md`) | OPEN |
| P-KITCHEN-5 | Should the dashed "Enter kg" rows show for plate waste too? | kitchen (`docs/verification/kitchen/REPORT.md`) | OPEN |
| P-PASS-1 | Does a special-meal entry also count toward Actual entries? | pass-desk (`docs/verification/pass-desk/REPORT.md`) | OPEN |
| P-PASS-2 | What level does a desk food-short report carry? | pass-desk (`docs/verification/pass-desk/REPORT.md`) | OPEN |
| P-PASS-3 | (the window length: 10 s built, the frame shows 7 s) and P-STUDENT-M5 (when a pass may be started) stay open. | pass-desk-home (`docs/verification/pass-desk-home/REPORT.md`) | OPEN |
| P-PASS-4 | Should Review's special count start at 0 like live entries (P-STORY-5)? | pass-desk (`docs/verification/pass-desk/REPORT.md`) | OPEN |
| P-PASS-5 | Who holds a pass in the seed? | pass-desk (`docs/verification/pass-desk/REPORT.md`) | OPEN |
| P-PASS-6 | Should a second Waiting request for one student be refused? | pass-desk (`docs/verification/pass-desk/REPORT.md`) | OPEN |
| P-PASS-7 | Who sees the special-meal entry list (spec open item 5)? | pass-desk (`docs/verification/pass-desk/REPORT.md`) | OPEN |
| P-PASS-8 | Should Language, Help and Switch role be the same across staff roles? | pass-desk (`docs/verification/pass-desk/REPORT.md`) | OPEN; Switch role part CONFIRMED 2026-11-07 (owner decision 15: no Switch role row) |
| P-PASS-10 | One code per window for everyone (prototype). | pass-desk-home (`docs/verification/pass-desk-home/REPORT.md`) | OPEN |
| P-PASS-11 | The pass-code instant moves with real time between story moments. | pass-desk-home (`docs/verification/pass-desk-home/REPORT.md`) | OPEN |
| P-PASS-12 | The Figma frames for the Pass Desk (PD-1 to PD-3) and the Student pass (no In use state; Used shows the | pass-desk-simple (`docs/verification/pass-desk-simple/REPORT.md`) | OPEN |
| P-PASS-13 | The PRD, the handoff and the Pass Desk spec still say "type the last 4 digits, then Matches · record | pass-desk-simple (`docs/verification/pass-desk-simple/REPORT.md`) | OPEN |
| P-PASS-14 | The In use clock is the pass-code instant: the story time plus the real seconds since the story clock | pass-desk-simple (`docs/verification/pass-desk-simple/REPORT.md`) | OPEN |
| P-SADMIN-1 | A design for Super Admin: these pages need the owner's approval or frames. | admin-final (`docs/verification/admin-final/REPORT.md`) | OPEN |
| P-SADMIN-2 | Should a deactivation block sign-in in the prototype? | admin-final (`docs/verification/admin-final/REPORT.md`) | OPEN |
| P-SADMIN-3 | Who receives a password reset, and through what channel? | admin-final (`docs/verification/admin-final/REPORT.md`) | OPEN |
| P-STAFF-1 | does 402 for Wed 14 Breakfast become a labelled sample, or stay Unavailable? | staff-figma-fix (`docs/verification/staff-figma-fix/REPORT.md`) | OPEN |
| P-STAFF-2 | should `resolveEntry` say which meal a code is for? | staff-figma-fix (`docs/verification/staff-figma-fix/REPORT.md`) | OPEN |
| P-STAFF-3 | can a last four match several students? | staff-figma-fix (`docs/verification/staff-figma-fix/REPORT.md`) | OPEN |
| P-STAFF-4 | an alerts feed would add the missing rows on Alerts, See all and All alerts. | staff-figma-fix (`docs/verification/staff-figma-fix/REPORT.md`) | OPEN |
| P-STAFF-5 | a release operation would add "I can't go after all". | staff-figma-fix (`docs/verification/staff-figma-fix/REPORT.md`) | OPEN |
| P-STAFF-6 | a problem repository would make Sent, Seen and Fixed true. | staff-figma-fix (`docs/verification/staff-figma-fix/REPORT.md`) | OPEN |
| P-STAFF-7 | should the shared tab bar, mark and Back change to match the frames? | staff-figma-fix (`docs/verification/staff-figma-fix/REPORT.md`) | OPEN |
| P-STAFF-8 | the Pass Desk frames say "her pass" for Meera. | staff-figma-fix (`docs/verification/staff-figma-fix/REPORT.md`) | OPEN |
| P-STUDENT-1 | What makes the mess "closed"? | student-home (`docs/verification/student-home/REPORT.md`) | OPEN |
| P-STUDENT-2 | Wording for Not sure | student-home (`docs/verification/student-home/REPORT.md`) | OPEN |
| P-STUDENT-3 | Eyebrow for later meals. | student-home (`docs/verification/student-home/REPORT.md`) | OPEN |
| P-STUDENT-4 | Next-meal row once answered. | student-home (`docs/verification/student-home/REPORT.md`) | OPEN |
| P-STUDENT-5 | Should the answer page open after the cutoff? | student-home (`docs/verification/student-home/REPORT.md`) | OPEN |
| P-STUDENT-6 | Should a static code say "Live"? | student-home (`docs/verification/student-home/REPORT.md`) | CONFIRMED 2026-11-07 (owner decision 4: the entry QR shows Live and a 12-second refresh bar, simulated) |
| P-STUDENT-7 | Can a student change a hero meal's answer before its cutoff? | student-home (`docs/verification/student-home/REPORT.md`) | OPEN |
| SV-Q1 | Shared `StatusText` has no ink-filled dot ("Active", "Closed"). | supervisor (`docs/verification/supervisor/REPORT.md`) | OPEN |
| SV-Q2 | Breakfast Wed 14: `mealHistory` gives 402 final entries (S18) while the existing `EntryRepository.finalCount(breakfast)` returns `.unavailable` (not changed). | supervisor (`docs/verification/supervisor/REPORT.md`) | OPEN |
| SV-Q3 | `docs/backend/openapi.yaml` needs `SOSRepository.raise` and `MealStateRepository.mealHistory` (not edited here). | supervisor (`docs/verification/supervisor/REPORT.md`) | OPEN |
| SV-Q4 | Should the prototype let the kitchen record an earlier meal's report (Dinner Tue 13), so "All caught up" is reachable in the main mess? | supervisor (`docs/verification/supervisor/REPORT.md`) | OPEN |
| SV-Q5 | No presenter path raises an SOS in the running app until the student SOS flow (Part 3e) calls `raise`. | supervisor (`docs/verification/supervisor/REPORT.md`) | OPEN |
| SV-Q6 | Confirm the undrawn "claimed by someone else" panel (D11). | supervisor (`docs/verification/supervisor/REPORT.md`) | OPEN |
| SV-Q7 | Offline: banner (current, shared pattern) or header dot only (spec)? | supervisor (`docs/verification/supervisor/REPORT.md`) | OPEN |
| SV-Q8 | Carried from the pack: Start meal always available (gap 537), reminder for missing waste (538), who else may close a case (539), Mon 12 Unavailable vs Kitchen 577 (549). | supervisor (`docs/verification/supervisor/REPORT.md`) | OPEN |
| SV-Q9 | Wording for a recorded report without quantities (D12). | supervisor (`docs/verification/supervisor/REPORT.md`) | OPEN |

## Admin pack and Today headcount (12 Nov 2026)

From the Admin and Super Admin pack (`design/reference/admin_full_2026-11/`) and the owner's Today mocks of 12 Nov 2026. Figma frames: page 12, sections "Admin · Food Head" (3277:5637) and "Admin · Super Admin" (3277:5638).

| ID | Question | Status |
|---|---|---|
| AP-1 | Change the number reasons ("Fewer students expected", "More students expected", "Menu change", "Special event") are the pack's placeholder list. Approve or replace. | OPEN |
| AP-2 | The Food Head's More leaves out Outings, Votes, Rewards and History because the source has no per-mess figures for them; AD09 draws them. Add per-mess data, or keep them Super Admin only? | OPEN |
| AP-3 | The Food Head's Results reason rows do not open: the reason pages hold every mess's meals. Build per-mess reason pages? | OPEN |
| AP-4 | "Answers per hour" (Live forecast) and "Entries per 15 minutes" (Actual entries) are hidden until a real series is held. Which source provides them? | OPEN |
| AP-5 | The Actual entries sheet does not show "entered without voting" yet: the Admin screens do not load that list. Show it for the Food Head (see P12)? | OPEN |
| AP-6 | Today is now one meal's headcount; the Breakfast, Lunch, Snacks, Dinner day line is gone, so another meal cannot be picked from Today. Keep it that way? | OPEN |
| AP-7 | North's approval (10:12 AM by the Food Head), cutoff 700 and 588 answered are sample values from the owner mock; other messes hold no entries. Real per-mess records are needed from the backend. | OPEN |
| AP-8 | The story's lunch has 3 answered and 1 not yet, so Today's Live forecast tile reads "3 answered"; the mock shows 650 and 210, which are tomorrow's Main figures on Students. Align the seed? | OPEN |
| AP-9 | The pack's lime "Not yet" tile conflicts with `.claude/rules/ios-design.md` ("never lime card fills"). The pack is newer and owner-approved, so it was followed; update the rule? | OPEN |
