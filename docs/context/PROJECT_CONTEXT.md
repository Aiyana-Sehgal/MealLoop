# MealLoop: Project Context

**Last updated:** 6 November 2026, from the owner's planning chat.
**Accuracy note:** statuses below come from the planning chat and the agents' reports. Where a status says *verify*, check the repository (`git log`, the PR list, `design/audit/run_status.md`) before relying on it. When this file and an approved document disagree, the approved document wins (PRD, NFR, ADRs, `docs/OPEN_DECISIONS.md`).

---

## 1. Product in one paragraph

MealLoop is an iOS-first dining and student-engagement platform for SRM Institute of Science and Technology, Kattankulathur. Students say whether they will eat each meal; management turns that into a headcount for the vendor; staff verify entry at the door; the kitchen records leftovers and plate waste after the meal; administrators compare forecast, headcount and actual results and act on the causes. Students also report food problems, support each other's reports (Community), earn small participation credits, and (later) use a digital outing pass. The first pilot is planned at **Meenakshi Girls' Mess**. The goal of Phase 1 is to reduce **unserved food waste**; Phase 2 (proposed only) investigates plate-waste reduction with an optional RFID and camera return station.

Core loop: better student participation, better demand signal, better headcount, verified outcomes, corrective action, continuous improvement.

## 2. Team, milestones and deadlines

- **11 November 2026:** external SwiftUI review (External Review 3 is 11 to 13 November). Deliverable: an **interactive iOS prototype** that matches the approved Figma flows, with no live backend.
- **13 December 2026:** target for integrated iOS and backend feature completeness.
- **27 to 29 January 2027:** External Review 4. **February to March 2027:** pilot preparation and execution if SRM authorizes it. **8 to 9 April 2027:** External Review 5. **16 April 2027:** App Fair.
- Android (Kotlin, Jetpack Compose) comes later and must not be presented as built.
- **Delivery risk:** the screen inventory lists about 420 screen states in 149 base screens. All active screens by 11 November is not realistic for four people; the review scope must be a set of end-to-end flows (see section 12).

## 3. Links

- Repository: `VeeraaVikash/MealLoop` (default branch `feature/mealloop-ios-design`; *verify*).
- Figma: `https://www.figma.com/design/nzzTAm9YnJRSdKEeYUWUEb/MealLoop`.
- C1 diagram (Eraser, approved 24 October 2026): `https://app.eraser.io/workspace/dtLAj6uiBc7Gl2OndSW2` (set its link access to view-only or restricted).

## 4. Roles (11)

| Role | What they do | Sign-in |
|---|---|---|
| Student | Answer meals, show entry QR, see menu and crowd, give feedback, Community, credits, request outings | SRM SSO (unverified) |
| Super Admin | Accounts, roles, scopes, deactivation, password-reset initiation; institutional configuration. Cannot read passwords | SRM SSO (unverified) |
| Food Head / Admin | Approve or adjust headcount (reason required), menus, reports, results, corrective actions. No Super Admin powers | MealLoop account |
| Supervisor | Start and close meals, resolve shortages, see waste read-only, close SOS cases | MealLoop account |
| Kitchen Staff | Forecasted attendance before, live entries during, report shortages, record waste after the meal | MealLoop account |
| Door Scanner Staff | Record regular entries (QR or last 4 digits), report problems | MealLoop account |
| Pass Desk Staff | Check special-meal passes by code and colour, request reissue, report problems and food shortage | MealLoop account |
| Vendor | Restricted account: view approved headcount for its mess, acknowledge receipt. Nothing else | MealLoop account |
| Guardian | Accept or reject an outing request (live video on accept) | Authentication unresolved |
| Warden | Final outing decision for authorized hostel blocks | MealLoop account |
| Gate Security | Verify the pass, record exit and return | MealLoop account |

The shared four-digit staff role password in the Figma prototype is a **debug and prototype interaction only**, never production authentication.

## 5. Product decisions (summary; the PRD is authoritative)

**Meal planning and headcount**
- Answers: I'm in, Skip, Not sure, No response. Changeable until **two hours before the meal**. Voluntary; nobody is denied food; the entry QR is always available and never gated by the answer.
- Six separate values, never merged: Live forecast, Cutoff forecast, Approved headcount, Sent or published to vendor, Actual entries, Final entries.
- Food Head approves or adjusts the headcount with a recorded reason and audit history; reminders and escalation if they do not respond; **never auto-approved**.
- Vendor gets an approved headcount only (no dish quantities, no procurement, no cooking advice) through its restricted MealLoop account and acknowledges receipt; a missing acknowledgment shows as pending and is never fabricated. Acknowledgment deadline, escalation and fallback channel are open.

**Attendance and mess staff**
- Door Scanner: QR or typed last 4 digits; no decline step; a student with no response is recorded under "Entered without voting" (not a vote); repeat, invalid and wrong-meal codes handled; **an offline or unverified scan is never recorded or shown as success**.
- Pass Desk: special-meal pass shows a live code and colour; staff type the last 4 digits, compare, then "Matches · record entry"; a lookup never records; reissue goes through the admin pass-exception flow; Approved is never shown as Done. No camera scan.
- Kitchen: before the meal "Forecasted attendance, expected diners"; during the meal only "students entered" (never "meals served", never the forecast beside it, no "recorded at the door" text); shortage report (dish required, how bad and note optional) with a slim status row (Sent, Ravi saw it, Couldn't send with Retry; no "Needs attention"); after the meal only, Record waste: per-dish leftovers in each dish's own unit (kg, L, pieces), states entered, None left, Not made, Not entered, one plate-waste total; **missing data never becomes zero**; saved report is simply **Recorded** (no supervisor approval loop); editable for **6 hours**.
- Supervisor: Start meal and Close meal (confirmation dialogs; drives every role's meal state), shortages (Mark resolved), waste read-only, SOS (claim, close case). Closing a meal does not resolve shortages or complete waste.
- SOS: a right-edge tab appears only while an SOS is active; staff can claim it ("I'll go and check") and mark it checked; only the Supervisor closes it.

**Feedback and Community**
- Structured categories plus optional text. Urgent hygiene, contamination, illness or safety reports bypass Community and escalate (SOS).
- Eligible non-urgent reports are **auto-published** after deterministic privacy, abuse and spam checks; flagged ones go to admin moderation; admin can hide and intervene; student identities are never public. AI never decides publication or safety on its own.
- Me too once per student per issue; threshold configurable and calibrated in the pilot. "Corrective action completed" is different from "improvement verified".

**Credits**
- Definite answers (I'm in, Skip) earn small participation credits; Not sure and No response earn none. Accuracy bonus only when behaviour is reliably verified; a missing scan never proves absence. Amounts, verification method and rewards budget are open (SRM approval).

**Crowd**
- Verified arrival activity and clearly labelled estimated busy or quiet periods; never claim current occupancy from entry scans; honest insufficient-data states.

**Outings**
- Sequence: Student request, Guardian decision, Warden decision, Signed pass, Gate exit, Gate return. No timeout approves anything.
- Guardian: chooses Accept or Reject first; Reject needs no video; Accept starts a live **4 to 10 second** video with a displayed phrase and a fresh random code; automatic checks with retries; fallbacks (video "please watch", live photo plus typed phrase and phone code, warden phone call) are designed, but real use needs institutional approval; text-only confirmation is not allowed. A video check is not warden approval and does not prove identity.
- Guardian authority comes from an SRM-verified contact or an authorized correction.
- Eligibility: in the authorized outing pilot every cohort student is eligible (bypass by explicit configuration); after the pilot, eligibility needs participation and reliability (thresholds open, SRM approval). Students who do not qualify keep the existing hostel procedure.

**Admin (Food Head)**
- Tabs: Today, Students, Results, More. Results compare headcount sent, final entries, shortages, dish-wise leftovers, plate waste and missing evidence; reasons are Sure, Probably or Can't tell (never percentages); corrective actions need at least two comparable meals before "worked"; menu upload with OCR and manual correction; weekly and monthly reports with PDF and CSV.

## 6. Design system (Figma; verify in `design/audit/design_intent.md`)

- **Orbit background** on every screen: flat warm canvas `#EDEDE8`, faint dot texture, a lime disc top-right with hairline rings and one black dot.
- Tokens: Canvas `#EDEDE8`, Lime `#D4F25A` (the only accent), Ink `#111111`, Card `#FBFBF4`, Soft `#E8E7DE`, Line `#E1E1DA`, secondary text greys `#6B6B66`, `#BDBDB3`, `#A9A9A3`.
- Lime: on black cards, primary actions on black, progress, success, highlights; **never lime text on a light background**; at most three lime elements per frame beyond the backdrop (SOS frames are a recorded exception request).
- Black cards and black primary buttons; one primary action per screen.
- **Status is a small dot plus plain text, never a pill that looks like a button.**
- Monospaced type only for numbers, times and units. Body 15 pt, secondary 13 pt, minimum 12 pt.
- Targets at least 44 pt; staff primary buttons about 56 pt; status never by colour alone.
- Back control: round 44 pt glass circle, top left. Logo: Orbit mark (ring with an orbiting lime dot).
- Icons: the design uses a drawn icon set; whether the code maps them to SF Symbols must follow the repository's icon mapping document (*verify*).
- Reference images in the packs are drawn 292 pt wide; multiply by about 1.346 for a 393 pt phone. Audit exports are 2x (786 by 1704).



| Pack or run | Content | Status |
|---|---|---|
| Student redesign (P0 to P16) | Student app, 34 references | Done |
| Admin redesign (X0 to X11) | Admin app, page 12 | Done |
| Polish (Q1 to Q9) | Coupons, chip, crowd, notifications, swipe, pass | Partly done; *verify* |
| FIX-2 (R1 to R7) | Student start, To check, weekly report and PDF, menu editing, cleanup | Done (commit `c358ba2`) |
| Guardian video (V0 to V7) | Guardian, Warden, Gate, student status | *Verify* |
| Door Scanner (D0 to D9) | 18 references | *Verify* |
| Pass Desk (Q0 to Q9) | 17 references; 46 frames built | Done, Q7 partly; gaps 486 to 502 |
| Kitchen (W0 to W10) | 20 references (no approval loop, 6-hour edit, SOS) | *Verify* |
| Supervisor (U0 to U10) | 20 references (start and close, shortages, SOS close) | *Verify* |

Needs design (not in Figma): Vendor sign-in, approved headcount view, acknowledgment, history; Super Admin account management (about 12 screens).

Open design questions: what the yellow highlight on the printed menu means; who the `**` gravies are for; whether students answer for Snacks.

## 8. Documentation map

| File | What it is | Status |
|---|---|---|
| `docs/PRD.md` | Functional requirements (version 0.3, 172 requirements, IDs `FR-<AREA>-NNN`) | Review draft |
| `docs/NFR.md` | Non-functional requirements (version 0.3, 59 NFRs, milestone tags, candidate values in an appendix) | Review draft |
| `docs/OPEN_DECISIONS.md` | Resolved (R), open product (P), technical (T) items, conflicts (C) | Living |
| `docs/REQUIREMENTS_TRACEABILITY.md`, `docs/NFR_TRACEABILITY.md` | Requirement to role, source, module, test, status | Living |
| `docs/SCREEN_INVENTORY.md` | All screens and states with status and priority | Living |
| `docs/architecture/C4_ARCHITECTURE.md` | C1 approved; C2 diagram unreviewed | Partly approved |
| `docs/architecture/FRONTEND_READINESS.md` | Readiness table for parallel frontend work | Living |
| `docs/adr/` | ADR-003 accepted (platform, backend, security); ADR-005 frontend decisions and authentication revision (*verify status*); ADR-001, 002, 004 proposed | Mixed |
| `docs/backend/BACKEND_PROPOSAL.md`, `openapi.yaml` | Modular monolith proposal; OpenAPI is an unreviewed draft | Draft |
| `docs/FOUNDATION_REPORT.md`, `docs/FOUNDATION_VERIFICATION.md` | iOS foundation and its verified evidence | *Verify* |
| `docs/BRANCHING.md`, `CLAUDE.md`, `.claude/rules/` | Team and AI conventions | Being added |
| `design/audit/` | Design state, intent, contracts, gaps, run status | Design history |

## 9. Architecture (approved and open)

- **Approved (ADR-003, C1):** one native SwiftUI iOS app with role-aware navigation for all 11 roles; Android later (shares API contracts, not UI code); Spring Boot (Java) modular monolith; PostgreSQL; private object storage for guardian videos and sensitive attachments; no premature microservices, Kafka, Kubernetes or Redis; Spring Security; RBAC plus resource and scope authorization.
- **Authentication revision (ADR-005, per owner):** PostgreSQL-backed opaque bearer tokens replace the earlier RS256 JWT choice; lifetimes, renewal and device policy are open.
- **Frontend (ADR-005, per owner):** hybrid role-oriented presentation with shared business contracts; balanced MVVM; `@MainActor @Observable` view models; repositories behind protocols; manual constructor injection (including `AppClock`); SwiftUI Environment only at composition points; existing router, `LoadState` and `AsyncContentView`; one shared domain model set; one in-memory prototype backend that behaves like the server (duplicates, cutoffs, meal state, edit windows); view models never decide business rules.
- **C1 external systems:** SRM SSO (unverified), SRM guardian-contact authority (unverified), notification and email providers (undecided), optional AI provider (undecided, advisory only), SRM manual outing procedure, SRM policy authorities.
- **Open:** reviewer-facing build without debug badges (P73); guardian channel in production (iOS only is an adoption risk because many guardians use Android; P78); SRM SSO feasibility (P60); vendor account holder (P67); guardian authentication (P71); notification provider; meal-lifecycle module ownership; hosting, region, retention, costs.

## 10. iOS code status (verify)

- `ios/MealLoop.xcodeproj`, scheme `MealLoop`, iOS 17 target, Swift 5 mode, no dependencies; feature folders, design system, domain models, repository protocols, Debug demo data, staff entry, Kitchen Home, unit tests. Branch `feature/swiftui-foundation` (verified at `40b8e4d` per owner).
- Known gaps: `Role` has 9 roles instead of 11; shared role password is still the code's sign-in; Debug shows a "Demo data" badge and a "Simulated moment" menu; Release shows "Not implemented"; the OpenAPI draft lacks operations for vendor, outings, special pass, Community, accounts, notifications and admin results.

## 11. How we work

- **SDLC order:** PRD, NFR, C4, ADRs, data model, API contracts, technical review, implementation. Documents are review drafts until the owner approves them.
- **Written is not verified is not complete.** Status words must match evidence: "verified" only for what was run.
- **Branches:** `type/scope-description` (feat, fix, docs, design, chore, refactor, test, spike); never `claude/...`; short-lived; one purpose. `main` (or the integration branch) is protected; PRs need one teammate review; stacked PRs up to two or three levels.
- **Commits:** author VeeraaVikash, Conventional Commits (`type(scope): summary`), no co-author trailers, no AI mentions in commits or PR text.
- How to write prompts: see `docs/context/PROMPT_PLAYBOOK.md`.

## 12. Current status and next steps (as of 6 November 2026)

1. **Baseline:** run the baseline prompt (`chore/ios-baseline`): Debug and Release builds, unit tests, `DEMO_DATA` check, evidence in `docs/FOUNDATION_VERIFICATION.md`, start-here guide in `ios/README.md`. The owner does the manual Kitchen walk-through.
2. **Standards:** run the standards prompt (`chore/claude-code-rules`): root `CLAUDE.md` and four `.claude/rules/` files. Merge both into the branch the team builds from.
3. **Review scope for 11 November (only five days away):** pick end-to-end flows, for example role entry; Student answer and entry QR; Door Scanner entry; Kitchen shortage and waste; Supervisor start and close; Food Head headcount; Vendor acknowledgment; outing request to gate. Everything else can be navigable but simulated.
5. **Owner decisions still needed soon:** reviewer build (P73), guardian channel (P78), review scope cut line, role-to-screen mapping for 11 roles, contract freeze date.

## 13. Risks

Scope versus time to the review; student participation rate; proving waste reduction without vendor production data (needs a 7 to 14 day baseline); door throughput and connectivity (offline scans are not accepted); SRM SSO availability; guardian channel; privacy and legal review for faces, voices and behavioural data; vendor and Super Admin screens not yet designed.
