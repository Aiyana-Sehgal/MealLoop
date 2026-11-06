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

