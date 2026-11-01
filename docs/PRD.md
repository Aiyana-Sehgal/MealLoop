# MealLoop Product Requirements Document (PRD)

## 1. Document control

| Field | Value |
|---|---|
| Version | 0.3 |
| Date | 2026-10-24 |
| Status | **Draft for team review.** Not owner-approved; it stays a review draft until the owner explicitly approves it |
| Owner | VeeraaVikash (repository owner) |
| Reviewers | The four-member development team; the owner for every item marked CHANGED |
| Branch | `docs/prd-consolidation` (based on `feature/swiftui-foundation`) |
| Next documents | Non-functional requirements, C4 architecture, ADRs, data model, API contracts, technical review |

### Change log

| Version | Date | Change |
|---|---|---|
| 0.3 | 2026-10-24 | C1 reconciliation on pull request 3: the vendor works through a restricted MealLoop account (FR-HC-006, FR-HC-007, FR-HC-008, FR-HC-004, FR-HC-005; new FR-VEN-001 to FR-VEN-005); two authentication arrangements and a separate Super Admin role (FR-ATT-013, FR-ATT-015, FR-ADM-015, FR-ADM-016, FR-STU-001; new FR-ID-001 to FR-ID-006); stakeholder list and permission matrix gain Super Admin and Vendor; dependency D10 and risks R13 and R14. No milestone changed. |
| 0.2 | 2026-10-23 | Corrections on pull request 1 for the owner's decisions: Community publication is automatic after configured checks (FR-FB-005, FR-AI-002, FR-AI-008, FR-FB-007); participation credits with a conditional accuracy bonus (FR-RWD-003, FR-RWD-002); outing eligibility split into pilot mode and post-pilot mode (FR-OUT-024, new FR-OUT-028 to FR-OUT-030); the warden phone fallback needs institutional approval (FR-OUT-010); the prototype's shared staff password is demo behaviour only, with proposed production authentication (FR-ATT-013, new FR-ATT-015); the archived calorie tracker is no longer named as active (FR-ADM-017). Foundation status now reads built and launched on the owner's Mac (owner-reported). Every open decision is classified. New risks R10 to R12. The PRD is still a draft for review and is not owner-approved. |
| 0.1 | 2026-10-23 | First consolidated draft. Brings the latest owner decisions and the active design packs into one requirements document, records contradictions with older documents, and adds the requirements traceability matrix ([`REQUIREMENTS_TRACEABILITY.md`](REQUIREMENTS_TRACEABILITY.md)). |

## 2. Purpose and scope

**Purpose.** This document states what MealLoop must do, in testable requirements, so the team can move through the sequence PRD → non-functional requirements → C4 architecture → ADRs → data model → API contracts → technical review → implementation.

**In scope.** Product behaviour for the Phase 1 pilot at Meenakshi Girls' Mess and the roles around it: Student, Door Scanner, Pass Desk, Kitchen Staff, Supervisor, Admin (Food head), and the outing roles Guardian, Warden and Gate.

**Out of scope for this document.** Numbers for availability, performance and retention (the non-functional requirements task), architecture and technology choices (the C4 and ADR tasks), the data model and API detail, and any policy that SRM or the owner has not decided. Where a policy is undecided this document says so and does not choose.

**How to read it.**

- Every requirement has a stable ID (`FR-<AREA>-NNN`), a statement, testable acceptance criteria, dependencies, sources and **exactly one status label** ([section 16](#16-requirement-status-legend)).
- **Source order.** When documents disagree, the newest owner decision wins. Archived or superseded designs (Figma page 99, the archive indexes, the "(v1, superseded)" components) are never active requirements. The latest packs for the Door Scanner, Pass Desk, Kitchen, Supervisor and Guardian video override older text.
- **Contradictions are recorded, not hidden.** The Conflicts table in [`OPEN_DECISIONS.md`](OPEN_DECISIONS.md#conflicts) lists every place where an existing document disagrees with this one.
- **Implementation state.** No requirement is marked implemented for production. The iOS foundation in `ios/` was built and launched on the owner's Mac (owner-reported); the unit-test result is not yet recorded and no build output is in the repository ([`FOUNDATION_REPORT.md`](FOUNDATION_REPORT.md)). [`REQUIREMENTS_TRACEABILITY.md`](REQUIREMENTS_TRACEABILITY.md) keeps three states apart: foundation code exists; behaviour verified on a simulator or device (only what is evidenced); production functionality (unimplemented).
- **Sample data.** The design screens use placeholder names and sample numbers (for example "Main Mess", 860, 714, 774). They illustrate behaviour and are not measured results. The pilot is planned at Meenakshi Girls' Mess; whether the screens should be renamed is an owner decision.

## 3. Background and problem

SRM Institute of Science and Technology, Kattankulathur, runs hostel messes that cook for large numbers of students without knowing in advance who will eat. The expected consequences are food left over on some days and shortages on others, queues at peak times, and feedback that gets no visible response. This section records the situation as the owner described it; none of it is measured by this project yet.

- **Pilot location.** Meenakshi Girls' Mess, which has a common entrance and exit doorway.
- **Today at the pilot mess.** There is no collection of meal intentions and no student entry scanning. MealLoop proposes per-meal intentions and QR-based entry verification.
- **Out of the initial pilot.** The boys' hostel has an existing Face ID attendance system; integrating it is outside the initial pilot scope.
- **Institution.** The institution has indicated cooperation. This is an indication, not a signed agreement.
- **What exists.** A detailed Figma design and its audit documents, an iOS SwiftUI foundation that runs on demo data and was built and launched on the owner's Mac (owner-reported; the unit-test result is not yet recorded), and a backend proposal. No production backend, no deployment and no measured result exist.

MealLoop is one operational system connecting students, door and desk staff, kitchen workers, supervisors and administrators. It is not an attendance app, a form replacement, a waste dashboard, a QR scanner or a chatbot.

**The loop.** Better student participation → more useful demand signals → better meal planning → verified operational outcomes → corrective action → continuous improvement.

## 4. Goals, non-goals and rollout phases

### Goals

1. **Reduce institutional mess food waste.** Phase 1 concentrates on **unserved food waste** (food left over after the meal, measured per dish) through student intentions, better headcount forecasting, verified entry and dish-wise waste measurement.
2. **Verified entry.** Know how many students actually entered, without denying anyone food.
3. **Honest measurement.** Keep intention, forecast, headcount, entries, leftovers and plate waste distinct, and never turn a missing measurement into a zero.
4. **Accountable feedback.** Turn student reports into owned corrective actions, and check whether things really improved.
5. **An earned, convenient digital outing option**, available first to an institutionally authorized pilot cohort and afterwards based on participation and reliability, with verified gate events as the only attendance-related evidence.

### Non-goals

- Dish-quantity planning, ingredient data or procurement. MealLoop makes the approved headcount available to the vendor's restricted MealLoop account only; the vendor decides its own buffer, quantities and batches. There is no direct vendor API.
- Claiming real-time occupancy from entry scans, or exact waiting times.
- Automatic approval of a headcount or an outing.
- A supervisor approval loop for waste reports.
- Camera scanning at the Pass Desk (it would need a QR on the pass; this is an open decision, not part of the current design).
- Integrating the boys' hostel Face ID system in the initial pilot.
- Using NGO donation records as a measure of total unserved food.
- Native Android before iOS, and any claim that Android or any AI model is built.

### Rollout phases

| Phase | Scope | Status |
|---|---|---|
| Phase 0: design and foundation | Figma design, audit documents, PRD, iOS foundation, backend proposal | In progress. The foundation was built and launched on the owner's Mac (owner-reported); the unit-test result is not yet recorded |
| Phase 1: pilot | Meenakshi Girls' Mess: intentions, forecasting, verified entry, dish-wise waste measurement, feedback and Community, and digital outings if SRM authorizes them | Not started. Depends on SRM authorization (see [section 14](#14-open-decisions)) |
| Phase 2: plate-waste reduction | Investigate an optional RFID and camera return station, only after Phase 1 shows value ([FR-KIT-018](#fr-kit-018--phase-2-optional-plate-waste-return-station)) | **PROPOSED**. Not part of the December 2026 delivery |

## 5. Stakeholders and roles

| Stakeholder | Interest |
|---|---|
| Students | Menus, meal plans, a fair way to answer, entry that never depends on answering, problem reports with visible follow-up, credits, outings |
| Door staff, pass-desk staff | Fast, honest entry recording with clear fallbacks |
| Kitchen staff | A forecast before the meal, a live count during it, a simple way to report shortages and record waste |
| Supervisors | Control of the meal state, shortage follow-up, SOS handling |
| Super Admin | System-level identity and institutional configuration: account provisioning, role assignment, scope changes, deactivation and password-reset initiation. The detailed permission matrix is OPEN |
| Admin (Food head) | Headcount approval and the vendor handoff, results, corrective actions, menus, reports. No Super Admin privileges |
| Guardians, wardens, gate security | A trustworthy outing approval and gate record |
| Vendor | A restricted MealLoop account: views the approved headcount and authorized updates for its assigned mess and acknowledges receipt |
| SRM Institute of Science and Technology | Authorizes the pilot, privacy and consent, retention, rewards and outing policy |
| Development team | Four developers, mostly learning native iOS |

### Role and permission matrix

Only documented behaviour is shown. ✓ = can do; R = can see, read-only; — = not offered; ? = not documented.

| Capability | Student | Door | Pass Desk | Kitchen | Supervisor | Admin | Guardian | Warden | Gate | Super Admin | Vendor |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Answer a meal (I'm in, Skip, Not sure) | ✓ | — | — | — | — | — | — | — | — | — | — |
| Show the entry QR | ✓ | — | — | — | — | — | — | — | — | — | — |
| Record entry (scan or last 4 digits) | — | ✓ | — | — | — | — | — | — | — | — | — |
| Check a special pass and record on Matches | — | — | ✓ | — | — | — | — | — | — | — | — |
| Look up a pass status (never records) | — | — | ✓ | — | — | — | — | — | — | — | — |
| Request a pass reissue | — | — | ✓ | — | — | — | — | — | — | — | — |
| Approve or reject a pass reissue | — | — | — | — | — | ✓ | — | — | — | — | — |
| See Forecasted attendance (before the meal) | — | — | — | ✓ | ✓ | ✓ | — | — | — | — | — |
| See live students entered | — | ✓ | — | ✓ | ✓ | ✓ | — | — | — | — | — |
| Start and close the meal | — | — | — | — | ✓ | — | — | — | — | — | — |
| Report a shortage | — | — | ✓ | ✓ | — | — | — | — | — | — | — |
| Resolve a shortage | — | — | — | — | ✓ | — | — | — | — | — | — |
| Record and edit waste (six-hour window) | — | — | — | ✓ | — | — | — | — | — | — | — |
| See a recorded waste report | — | — | — | ✓ | R | R | — | — | — | — | — |
| Approve or adjust the headcount and publish it to the vendor account | — | — | — | — | — | ✓ | — | — | — | — | — |
| Claim and check an SOS | — | ✓ | ✓ | ✓ | ✓ | — | — | — | — | — | — |
| Close an SOS case in the staff app | — | — | — | — | ✓ | — | — | — | — | — | — |
| See and close the Safety case in the admin app | — | — | — | — | — | ✓ (relation to the staff close is open) | — | — | — | — | — |
| Submit feedback or an urgent report | ✓ | — | — | — | — | — | — | — | — | — | — |
| Back an issue with Me too | ✓ | — | — | — | — | — | — | — | — | — | — |
| Hide or moderate a Community report (eligible reports publish automatically; flagged ones are held for Admin) | — | — | — | — | — | ✓ | — | — | — | — | — |
| Manage menus and send reports | — | — | — | — | — | ✓ | — | — | — | — | — |
| See who has which role and request access | — | — | — | — | — | ✓ | — | — | — | — | — |
| Request an outing | ✓ | — | — | — | — | — | — | — | — | — | — |
| Accept or reject an outing with video evidence | — | — | — | — | — | — | ✓ | — | — | — | — |
| See the guardian evidence and decide an outing (own block only) | — | — | — | — | — | ? | — | ✓ | — | — | — |
| See the guardian video | — (never) | — | — | — | — | ? | — | ✓ | — | — | — |
| Record gate exit and return | — | — | — | — | — | — | — | — | ✓ | — | — |
| See the approved headcount for the assigned mess and acknowledge it | — | — | — | — | — | R (sees acknowledgment status) | — | — | — | — | ✓ |
| Provision accounts, assign roles and scope, deactivate accounts, initiate password resets (detailed matrix OPEN) | — | — | — | — | — | — | — | — | — | ✓ | — |
Notes:

- In the prototype, staff open a role with a shared role password (approved demo behaviour, [FR-ATT-013](#fr-att-013--prototype-staff-entry-uses-a-shared-role-password)); production authentication and authorization are proposed in [FR-ATT-015](#fr-att-015--production-staff-authentication-and-authorization).
- Staff, kitchen and door roles act within their own mess; wardens see their own hostel or block only; Admin can see all messes.
- The vendor works through its own restricted MealLoop account and sees only the approved headcount and authorized updates for its assigned mess, never student-level data. The earlier message or call handoff remains the designed interim handoff. The vendor is not an external API integration.
- Super Admin is a separate role from Food Head / Admin. Admin cannot provision accounts, assign roles, change scope, deactivate accounts or initiate password resets. The detailed Super Admin permission matrix is OPEN and no broader permission is implied.
- Students and Super Admins are intended to sign in through SRM SSO (feasibility unverified); all other internal users, including the vendor, use individual MealLoop-managed accounts ([FR-ID-001](#fr-id-001--students-and-super-admins-sign-in-through-srm-sso), [FR-ID-002](#fr-id-002--other-internal-users-have-individual-mealloop-managed-accounts)).

## 6. Guiding principles

These data-integrity rules apply to every requirement. A requirement that breaks one is a defect in the requirement.

| ID | Principle |
|---|---|
| DI-1 | **Intention is not attendance.** What a student said (I'm in, Skip, Not sure, No response) is never reported as who attended. |
| DI-2 | **Six headcount quantities stay separate:** Live forecast, Cutoff forecast, Approved headcount, Sent to vendor, Actual entries (live) and Final entries. They are never merged or substituted. |
| DI-3 | **Food produced, served, left over and plate waste are different things.** MealLoop does not know what was produced (the vendor cooked amount is Missing unless typed in) and never calls an entry "served". |
| DI-4 | **Missing is not zero.** A missing measurement is shown as missing; only a confirmed measurement of none (None left) is zero. |
| DI-5 | **Predicted crowd is not verified crowd.** Entry scans are never presented as current occupancy. |
| DI-6 | **An AI suggestion is not a decision.** An authorized person decides, and the actor is recorded. |
| DI-7 | **The entry QR confirms entry**, not that food was served or eaten. |
| DI-8 | **Incompatible units are never added.** Kilograms, litres and pieces stay separate. |
| DI-9 | **Live is not final.** Live entries are never labelled final; Final entries exist only after the Supervisor closes the meal. |
| DI-10 | **No success without a verified save.** An offline or unverifiable action is never shown as done and records nothing. |
| DI-11 | **Accountability.** Headcount changes, meal state changes, shortage resolution, waste edits, SOS closing and key decisions record who, when and why. |
| DI-12 | **Sample data is labelled and never mixed with real data.** |

## 7. Functional requirements by area

This section holds **172 requirements**. Each has an ID, a statement, acceptance criteria, dependencies, a source and exactly one status ([section 16](#16-requirement-status-legend)). The traceability matrix ([`REQUIREMENTS_TRACEABILITY.md`](REQUIREMENTS_TRACEABILITY.md)) adds the planned backend module, a test scenario and the implementation state for each.

**No requirement is currently marked `CHANGED, OWNER CONFIRMATION REQUIRED`.** The two items marked that way in version 0.1, FR-FB-005 (Community publication) and FR-RWD-003 (accuracy bonus), were resolved by the owner's decisions recorded in version 0.2.

### Requirement counts

| Area | Requirements | CONFIRMED | PROPOSED | SRM APPROVAL REQUIRED | VALIDATION REQUIRED | CHANGED, OWNER CONFIRMATION REQUIRED |
|---|---|---|---|---|---|---|
| `MEAL` Meal planning and student responses | 6 | 5 | 1 | 0 | 0 | 0 |
| `HC` Headcount and forecasting | 8 | 7 | 1 | 0 | 0 | 0 |
| `ATT` Attendance verification and the Door Scanner | 15 | 14 | 1 | 0 | 0 | 0 |
| `PASS` Special meal pass and the Pass Desk | 11 | 10 | 1 | 0 | 0 | 0 |
| `KIT` Kitchen and waste measurement | 18 | 17 | 1 | 0 | 0 | 0 |
| `SUP` Supervisor | 7 | 7 | 0 | 0 | 0 | 0 |
| `FB` Feedback, Community and urgent safety | 14 | 12 | 0 | 1 | 1 | 0 |
| `STU` Student experience | 6 | 4 | 1 | 1 | 0 | 0 |
| `CRD` Crowd guidance | 5 | 3 | 1 | 0 | 1 | 0 |
| `RWD` Credits and rewards | 8 | 5 | 1 | 2 | 0 | 0 |
| `ADM` Admin (Food head) | 19 | 16 | 1 | 1 | 1 | 0 |
| `MENU` Menu management | 4 | 3 | 1 | 0 | 0 | 0 |
| `OUT` Digital outings | 30 | 22 | 1 | 6 | 1 | 0 |
| `AI` AI and intelligence | 10 | 9 | 0 | 0 | 1 | 0 |
| `VEN` Vendor account workflow | 5 | 5 | 0 | 0 | 0 | 0 |
| `ID` Accounts, roles and identity | 6 | 4 | 1 | 1 | 0 | 0 |
| **Total** | **172** | **143** | **12** | **12** | **5** | **0** |

### 7.1 Meal planning and student responses (`FR-MEAL`)

Students answer per meal, voluntarily, until two hours before it starts.

#### FR-MEAL-001 · Students can read the published menu

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** A student can read the published menu for each meal slot (Breakfast, Lunch, Snacks, Dinner) of each day.

**Acceptance criteria.**
1. Given a mess has a published menu for a day, when the student opens Meals, then all four slots are available for that day with the dishes published for each.
2. Given a slot has no published menu, when the student opens it, then a No menu state is shown and no dish is invented.

**Dependencies:** [FR-MENU-001](#fr-menu-001--menu-upload-reads-a-photo-and-flags-uncertain-words)

**Source:** [`design/reference/redesign_2026-10/README.md`](../design/reference/redesign_2026-10/README.md) (05_meals_lunch, 06_meals_dinner); [`design/audit/design_intent.md`](../design/audit/design_intent.md) (STUDENT REDESIGN 2026-10)

#### FR-MEAL-002 · A meal response is I'm in, Skip, Not sure or No response

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** For each meal a student's state is exactly one of I'm in, Skip, Not sure or No response, and No response means no answer was given and is never treated as Skip.

**Acceptance criteria.**
1. Given a student has not answered, when the meal is queried, then the state is No response and counts report No response separately from Skip.
2. Given the student taps Skip, when it is saved, then the state is Skip; given Not sure, then Not sure (never I'm in).
3. Given a count or report of responses, when it is shown, then I'm in, Skip, Not sure and No response are four separate groups.

**Dependencies:** none

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (Definitions: Intent; 'No response is its own group and is never a skip'); owner decision in task prompt

#### FR-MEAL-003 · Responses can be changed until two hours before the meal

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** A student can set or change the response until two hours before the meal starts, after which the answer controls are disabled and the server rejects changes.

**Acceptance criteria.**
1. Given a meal that starts at time T in the mess time zone, when the student answers one minute before T minus two hours, then the answer is saved.
2. Given the cutoff has passed, when the student opens the meal, then the answer buttons are disabled and a direct change request is rejected with cutoff_passed.
3. Given the cutoff has passed, when the student opens Home, then the entry QR is still available.

**Dependencies:** [FR-MEAL-004](#fr-meal-004--answering-is-voluntary-and-the-entry-qr-is-never-locked)

**Source:** owner decision in task prompt; [`docs/backend/openapi.yaml`](../docs/backend/openapi.yaml) (PUT /meals/{mealId}/intentions/me)

**Note.** Older Figma sample screens show lunch 9 AM and dinner 6 PM; those are sample times superseded by this rule (see the Conflicts table in docs/OPEN_DECISIONS.md, C-12).

#### FR-MEAL-004 · Answering is voluntary and the entry QR is never locked

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** No student loses access to food for skipping or not responding, and the entry QR is available in every response state.

**Acceptance criteria.**
1. Given a student who chose Skip, Not sure, I'm in or did not respond, when they open Home or Entry QR, then Show entry QR is available.
2. Given the cutoff has passed, when the student opens Home, then answer buttons are disabled (dashed) while the QR still works.
3. Given a student with no response is scanned, when the door records the entry, then food access is unaffected (see FR-ATT-004).

**Dependencies:** [FR-ATT-004](#fr-att-004--no-decline-step-entries-without-a-response-are-listed-separately)

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (STUDENT REDESIGN 2026-10: The QR is never locked); [`design/reference/redesign_2026-10/README.md`](../design/reference/redesign_2026-10/README.md) (04_home_top_card_cases)

#### FR-MEAL-005 · Skipping reasons are optional

**Status:** `PROPOSED` · **Roles:** Student, Admin

**Statement.** A student who skips can optionally give a reason from a fixed list, and Skip saves without one; how reasons are used and how long they are kept is undecided.

**Acceptance criteria.**
1. Given the student chooses Skip, when the reason sheet is shown, then choosing a reason is optional and Skip saves without it.
2. Given reasons exist, when Admin views them, then they appear only in aggregate and never with a student name.
3. Given the retention and use of reasons are undecided, then no reason is used for credits or shown per student.

**Dependencies:** [FR-FB-014](#fr-fb-014--feedback-and-intent-reasons-need-a-retention-rule)

**Source:** [`design/README.md`](../design/README.md) (Open decisions: how intent reasons are used and kept); [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (Students sub-pages (Why students skip) not drawn)

#### FR-MEAL-006 · One default reminder before the cutoff, plus optional reminders

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** A student gets one default reminder before the cutoff if they have not answered, and can add optional reminders under their own control.

**Acceptance criteria.**
1. Given a student has not answered, when the default reminder time arrives, then one notification is sent before the cutoff and none after it.
2. Given Notification settings, when the student switches optional reminders on or off, then only the switched-on reminders are sent.
3. Given a student who has answered, when the default reminder time arrives, then no reminder is sent.

**Dependencies:** [FR-MEAL-003](#fr-meal-003--responses-can-be-changed-until-two-hours-before-the-meal)

**Source:** owner decision in task prompt; [`design/audit/export_polish/README.md`](../design/audit/export_polish/README.md) (P02_home_swipe_remind, P01_notifications_circles)

**Note.** Reminder timing is not documented (open decision).

### 7.2 Headcount and forecasting (`FR-HC`)

The headcount sent to the vendor, how it is produced, and the six quantities that are never merged (DI-2).

#### FR-HC-001 · The forecast accounts for every response category

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** The forecast uses I'm in, Skip, Not sure and No response, not only I'm in.

**Acceptance criteria.**
1. Given responses in all four categories, when a forecast is produced, then all four are inputs and the Students view shows how many students are in each.
2. Given the forecast is shown, then it never presents I'm in as the headcount.

**Dependencies:** [FR-MEAL-002](#fr-meal-002--a-meal-response-is-im-in-skip-not-sure-or-no-response), [FR-AI-003](#fr-ai-003--forecasting-starts-from-a-statistical-baseline)

**Source:** owner decision in task prompt; [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Students (tomorrow lunch))

#### FR-HC-002 · Headcount quantities are separate and never merged

**Status:** `CONFIRMED` · **Roles:** Admin, Kitchen Staff, Supervisor

**Statement.** Live forecast, Cutoff forecast, Approved headcount, Sent to vendor, Actual entries and Final entries are separate, named quantities that are never merged or substituted for one another.

**Acceptance criteria.**
1. Given any screen, API or report shows one of the six quantities, then it carries its own name and no field is filled from another.
2. Given the meal is in service, when entries are shown, then they are labelled live (Actual entries) and never final.
3. Given the meal has not closed, when Final entries are requested, then they are unavailable, not zero.

**Dependencies:** [FR-ATT-009](#fr-att-009--live-entry-count-is-shown-as-recorded-entries-only), [FR-SUP-002](#fr-sup-002--the-supervisor-closes-the-meal)

**Source:** owner decision in task prompt; [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (Decision 5: Live entries are never final); [`design/audit/design_intent.md`](../design/audit/design_intent.md) (Definitions)

**Note.** Foundation gap: the Domain models have a forecast, a sent headcount and live and final counts, but no separate Live forecast, Cutoff forecast or Approved headcount.

**Note.** *Sent to vendor* means the approved headcount as published to the vendor account (FR-VEN-002); it is still a headcount only.

#### FR-HC-003 · The cutoff forecast is preserved

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** The forecast as it stood at the cutoff is preserved with its rule version and the cutoff time.

**Acceptance criteria.**
1. Given the cutoff has passed, when the live forecast later changes, then the cutoff forecast, its rule version and its time are unchanged and viewable.
2. Given a forecast is shown, then its rule version and the time it was set are visible.

**Dependencies:** [FR-HC-002](#fr-hc-002--headcount-quantities-are-separate-and-never-merged)

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (Definitions: Forecast (rule version and cutoff time); 'The forecast is preserved as it stood at the cutoff')

#### FR-HC-004 · Admin approves or adjusts the headcount with a reason

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Admin reviews the forecast and approves it or adjusts it with a mandatory reason, and every approval and adjustment is kept in an audit history.

**Acceptance criteria.**
1. Given a forecast is ready, when Admin approves it, then the Approved headcount is set with who and when in the history.
2. Given Admin adjusts the headcount, when the reason is empty, then saving is refused.
3. Given an adjustment is saved, then the history shows the original value, new value, reason, actor and time, and cannot be edited.
4. Given a vendor account or any other role, then it cannot approve or alter the headcount (FR-VEN-005); only the Food Head / Admin role can.

**Dependencies:** [FR-HC-002](#fr-hc-002--headcount-quantities-are-separate-and-never-merged), [FR-ADM-016](#fr-adm-016--key-decisions-keep-an-audit-history), [FR-VEN-005](#fr-ven-005--the-vendor-account-is-restricted-to-the-approved-headcount)

**Source:** owner decision in task prompt; [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (A02_headcount_north); [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Lunch headcount board)

#### FR-HC-005 · No automatic approval; reminders and escalation instead

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** If Admin does not respond, MealLoop sends reminders and escalates to authorized administrators, and it never approves or sends a headcount automatically.

**Acceptance criteria.**
1. Given a forecast awaits approval and no one responds by the reminder time, then Admin is reminded.
2. Given the reminder is unanswered, then the request is escalated to authorized administrators and the escalation is recorded.
3. Given no administrator responds at all, then the headcount stays not approved and nothing is made available to the vendor account.

**Dependencies:** [FR-HC-004](#fr-hc-004--admin-approves-or-adjusts-the-headcount-with-a-reason)

**Source:** owner decision in task prompt

**Note.** Who is an authorized administrator, the reminder times and the escalation order are open decisions (docs/OPEN_DECISIONS.md, P25).

#### FR-HC-006 · The vendor receives a headcount only

**Status:** `CONFIRMED` · **Roles:** Admin, Vendor

**Statement.** MealLoop makes the approved headcount available to the authorized vendor account for the assigned mess and nothing else: no dish quantities, no ingredient data, no procurement, no recipes and no automatic cooking recommendations. The vendor decides its own buffer, quantities and batches. The vendor is a MealLoop user, not an external API integration.

**Acceptance criteria.**
1. Given a headcount is published to the vendor account, then the vendor view shows the approved headcount for the meal and no dish quantity.
2. Given the data model and API, then no field holds a dish quantity to cook, and there is no direct vendor API.
3. Given the vendor's cooked amount is not recorded, then Vendor cooked shows Missing.
4. Given the vendor account, then it cannot enter production quantities, ingredients, procurement or recipes through this workflow (FR-VEN-005).

**Dependencies:** [FR-HC-004](#fr-hc-004--admin-approves-or-adjusts-the-headcount-with-a-reason), [FR-VEN-002](#fr-ven-002--the-vendor-sees-the-approved-headcount-for-its-assigned-mess-and-authorized-updates), [FR-VEN-005](#fr-ven-005--the-vendor-account-is-restricted-to-the-approved-headcount)

**Source:** [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (Decision 1; its "no vendor login" wording is superseded); [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (What MealLoop does and does not know); owner decision in task prompt; owner decision in the C1 review task prompt (vendor architecture)

**Note.** Superseded in part: version 0.2 said the vendor has no login and receives the headcount by message. The vendor now has a restricted MealLoop account (confirmed product direction). The earlier message or call handoff (the Tell the vendor step) remains the designed interim handoff and is not removed. The vendor screens do not exist in Figma yet (docs/SCREEN_INVENTORY.md).

#### FR-HC-007 · Admin sees the vendor reply status

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** For each meal Admin sees whether the headcount is not sent, waiting for the vendor (pending acknowledgment), replied (acknowledged by the vendor account) or missing a reply.

**Acceptance criteria.**
1. Given a headcount was published and no acknowledgment exists, then the status is Waiting (pending acknowledgment) with the time since it was published.
2. Given the vendor account acknowledged, then the status shows Replied with the actor and the time of the acknowledgment.
3. Given a reply is expected and absent, then the status is Missing and is never shown as an agreement.
4. Given a headcount was published, then publishing is never shown as an acknowledgment (FR-VEN-003).

**Dependencies:** [FR-HC-006](#fr-hc-006--the-vendor-receives-a-headcount-only), [FR-VEN-003](#fr-ven-003--the-vendor-acknowledges-receipt-and-an-acknowledgment-is-never-fabricated)

**Source:** [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Lunch headcount board); [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (A02_headcount_north); owner decision in the C1 review task prompt (vendor architecture)

**Note.** In the current Figma design the reply is a status the admin records after a message or call (the designed interim handoff); with a vendor account the reply is the vendor's acknowledgment. Whether acknowledgment is mandatory before a deadline, the deadline, the escalation recipients, the fallback when the vendor cannot reach MealLoop and the authorized fallback process are OPEN (docs/OPEN_DECISIONS.md, P6, P64, P65).

#### FR-HC-008 · A change after sending is recorded and offered to the vendor

**Status:** `PROPOSED` · **Roles:** Admin

**Statement.** A change to the headcount after it was sent is recorded with a reason and time, and Admin is offered the Tell the vendor step.

**Acceptance criteria.**
1. Given a sent headcount, when Admin changes it, then a reason is required and the history shows before and after with the time.
2. Given a change after sending, then the vendor account shows it as an update (FR-VEN-004) and Admin can still tell the vendor through the designed interim message or call handoff.
3. Given the change happened late, then Results can later show it as We raised the headcount late.

**Dependencies:** [FR-HC-004](#fr-hc-004--admin-approves-or-adjusts-the-headcount-with-a-reason), [FR-ADM-006](#fr-adm-006--results-explain-waste-and-shortages-in-plain-reasons), [FR-VEN-004](#fr-ven-004--a-later-update-is-shown-as-an-update)

**Source:** [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (Tell the vendor sheet); [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Results: We raised the headcount late)

**Note.** The Changed after sending frame and the headcount Tell the vendor sheet were archived by FIX-2 (design/audit/admin_redesign/archive_index.md) and are not requirements; this item rests on the admin sample data (We raised the headcount late) and needs product review.

### 7.3 Attendance verification and the Door Scanner (`FR-ATT`)

How entry is verified at the door. The entry QR confirms entry only (DI-7). The latest Door Scanner decisions override older documents.

#### FR-ATT-001 · The entry QR confirms entry only

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** Every student can show a live entry QR for the current meal, and the QR confirms entry, not that food was served or eaten.

**Acceptance criteria.**
1. Given a student opens Entry QR during a meal, then a QR with a refresh countdown is shown.
2. Given a scan is recorded, then it is called an entry and no screen, API or report calls it served or eaten.

**Dependencies:** none

**Source:** [`design/reference/redesign_2026-10/README.md`](../design/reference/redesign_2026-10/README.md) (08_entry_qr); [`design/audit/design_intent.md`](../design/audit/design_intent.md) (OUTING PASS: Words; DOOR SCANNER 2026-10)

#### FR-ATT-002 · Scanning a valid QR records one entry

**Status:** `CONFIRMED` · **Roles:** Door Scanner

**Statement.** When door staff scan a valid entry QR while the meal is in service, the entry is recorded once, the count goes up by one and the screen returns to the camera.

**Acceptance criteria.**
1. Given the meal is in service and a valid QR not yet recorded, when it is scanned, then Entry recorded shows the masked student ID and the count increases by one.
2. Given Entry recorded is shown, then the camera returns automatically and the entry holds time, student, meal and method.
3. Given the scan was recorded, then it is recorded with an idempotency key so a retry does not add a second entry.

**Dependencies:** [FR-ATT-008](#fr-att-008--scanning-is-open-only-while-the-meal-is-in-service)

**Source:** [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (Scan outcomes 1); [`docs/backend/openapi.yaml`](../docs/backend/openapi.yaml) (POST /meals/{mealId}/entries)

#### FR-ATT-003 · Staff can type the last 4 digits when a QR cannot be scanned

**Status:** `CONFIRMED` · **Roles:** Door Scanner

**Statement.** When a QR cannot be scanned, staff can type the last 4 digits of the student's SRM ID, choose from the matches and record the entry.

**Acceptance criteria.**
1. Given four digits are typed and one student matches, when staff tap Record entry, then Entry recorded is shown.
2. Given more than one student matches, then a short list is shown to pick from.
3. Given no student matches, then a message names the digits and mess and offers Try again, and nothing is recorded.

**Dependencies:** [FR-ATT-002](#fr-att-002--scanning-a-valid-qr-records-one-entry)

**Source:** [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (Type the last 4 digits)

#### FR-ATT-004 · No decline step; entries without a response are listed separately

**Status:** `CONFIRMED` · **Roles:** Door Scanner

**Statement.** The Door Scanner has no decline step and no supervisor approval; a student with no meal response is recorded like any other entry and added automatically to a separate Entered without voting list, which is not a vote.

**Acceptance criteria.**
1. Given a student with no response is scanned, then the same Entry recorded screen is shown and the count increases by one.
2. Given that entry, then the student appears in the Entered without voting list with masked ID and time, separate from all responses.
3. Given any Door Scanner screen, then none offers Decline or waits for a supervisor's approval.

**Dependencies:** [FR-ATT-002](#fr-att-002--scanning-a-valid-qr-records-one-entry), [FR-MEAL-004](#fr-meal-004--answering-is-voluntary-and-the-entry-qr-is-never-locked)

**Source:** [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (Scan outcomes 2); [`design/audit/design_intent.md`](../design/audit/design_intent.md) (DOOR SCANNER 2026-10: rule 5)

#### FR-ATT-005 · A student is recorded at most once per meal

**Status:** `CONFIRMED` · **Roles:** Door Scanner

**Statement.** A repeat scan of a student already recorded for the meal shows Already scanned with the first time and leaves the count unchanged.

**Acceptance criteria.**
1. Given a student is already recorded, when scanned again, then Already scanned shows the first scan time and the count is unchanged.
2. Given the same idempotency key is sent again, then the original response is returned.
3. Given the server stores entries, then a second entry for the same student and meal is impossible.

**Dependencies:** [FR-ATT-002](#fr-att-002--scanning-a-valid-qr-records-one-entry)

**Source:** [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (Scan outcomes 3); [`docs/backend/openapi.yaml`](../docs/backend/openapi.yaml) (409 already_recorded)

#### FR-ATT-006 · Invalid and wrong-meal codes are rejected

**Status:** `CONFIRMED` · **Roles:** Door Scanner

**Statement.** A code that is not a MealLoop entry code, or that is for another meal, is rejected with the reason and nothing is recorded.

**Acceptance criteria.**
1. Given a code that is not a MealLoop entry code, when scanned, then the screen says so and offers Scan again and Type the last 4 digits.
2. Given a code for another meal, when scanned, then the screen names that meal.
3. Given either case, then the count is unchanged.

**Dependencies:** [FR-ATT-002](#fr-att-002--scanning-a-valid-qr-records-one-entry)

**Source:** [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (Scan outcomes 4)

#### FR-ATT-007 · An offline or unverifiable scan is never shown as success

**Status:** `CONFIRMED` · **Roles:** Door Scanner

**Statement.** If an entry cannot be verified and saved, the app never shows success and records nothing, and staff can try again, type the digits or report a problem.

**Acceptance criteria.**
1. Given no connection, when staff scan, then the screen says the entry is NOT recorded, shows the last update time and offers Try again, Type the last 4 digits and Report a problem.
2. Given that state, then the count and every list are unchanged and no entry is queued.
3. Given the connection returns, when staff try again, then the scan is verified and recorded normally.

**Dependencies:** [FR-ATT-002](#fr-att-002--scanning-a-valid-qr-records-one-entry)

**Source:** [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (Scan outcomes 5; Open items 2); owner decision in task prompt

**Note.** For the pilot, an offline scan is never recorded and never shown as success. A future offline queue is deferred and is not part of the pilot. *Superseded by NFR-REL-005 in [`NFR.md`](NFR.md) (the owner is asked to confirm); resolves the former open decision P5 (now R21).*

#### FR-ATT-008 · Scanning is open only while the meal is in service

**Status:** `CONFIRMED` · **Roles:** Door Scanner, Supervisor

**Statement.** Door scanning is available only while the Supervisor has the meal in service: before the meal Home says when scanning opens, and after the meal is closed scanning is closed.

**Acceptance criteria.**
1. Given the meal has not started, then Home shows Scanning opens at the meal start and no scan is accepted.
2. Given the meal is in service, then the scanner is available.
3. Given the Supervisor closed the meal, then scanning is closed and the final recorded entries are shown.

**Dependencies:** [FR-SUP-001](#fr-sup-001--the-supervisor-starts-the-meal-for-the-mess), [FR-SUP-002](#fr-sup-002--the-supervisor-closes-the-meal)

**Source:** [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (Meal lifecycle)

#### FR-ATT-009 · Live entry count is shown as recorded entries only

**Status:** `CONFIRMED` · **Roles:** Door Scanner, Kitchen Staff, Supervisor, Admin

**Statement.** During the meal the number of recorded entries is shown as live entries, labelled as students entered, never as meals served and never as the final count.

**Acceptance criteria.**
1. Given entries are recorded, then the live count equals the number of recorded entries and excludes failed or offline scans.
2. Given the live count is shown, then it is labelled students entered (or recorded entries) and not served or final.
3. Given the count is unavailable, then it shows a dash or Unavailable and never 0.

**Dependencies:** [FR-HC-002](#fr-hc-002--headcount-quantities-are-separate-and-never-merged)

**Source:** [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (During the meal); [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Home by meal state: During)

#### FR-ATT-010 · Door staff camera problems have a clear next step

**Status:** `CONFIRMED` · **Roles:** Door Scanner

**Statement.** Camera permission denied, low light and camera busy each give a clear next step and make typing the last 4 digits the main action when the camera is unusable.

**Acceptance criteria.**
1. Given camera permission is denied, then the screen explains, offers Open Settings and makes Type the last 4 digits the primary action.
2. Given low light, then a torch state is offered.
3. Given the camera is busy, then Try again is offered.

**Dependencies:** [FR-ATT-003](#fr-att-003--staff-can-type-the-last-4-digits-when-a-qr-cannot-be-scanned)

**Source:** [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (Scan outcomes 6)

#### FR-ATT-011 · Door staff can report a problem in one tap

**Status:** `CONFIRMED` · **Roles:** Door Scanner

**Statement.** Door staff can report Scanner not working, Crowd at the door or Something else in one tap, which goes to the Supervisor and is listed under Open problems.

**Acceptance criteria.**
1. Given a category is tapped, then the report is sent to the Supervisor and a Sent toast is shown.
2. Given the report was sent, then it appears under Open problems.
3. Given the report could not be sent, then the app says so and does not claim delivery.

**Dependencies:** [FR-SUP-007](#fr-sup-007--supervisor-alerts-and-history-show-the-same-tasks-everywhere)

**Source:** [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (Report a problem)

#### FR-ATT-012 · Door staff can claim and check an SOS but not close it

**Status:** `CONFIRMED` · **Roles:** Door Scanner

**Statement.** Door staff can see an active SOS, claim it with I'll go and check and mark it Checked by the door, which does not close the case.

**Acceptance criteria.**
1. Given an SOS is active, then a right-edge SOS tab with a count appears, and it is absent when no SOS is active.
2. Given the case is unclaimed, then the panel says Nobody has taken this yet and offers I'll go and check and Not now.
3. Given staff claim and then mark it checked, then the case shows Checked by the door and stays open until the Supervisor closes it.

**Dependencies:** [FR-SUP-006](#fr-sup-006--only-the-supervisor-closes-an-sos-case-in-the-staff-app), [FR-FB-004](#fr-fb-004--an-sos-reaches-staff-and-the-admin-safety-case)

**Source:** [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (SOS)

#### FR-ATT-013 · Prototype staff entry uses a shared role password

**Status:** `CONFIRMED` · **Roles:** Door Scanner, Pass Desk, Kitchen Staff, Supervisor

**Statement.** In the Figma prototype a staff member opens a role after entering a shared four-digit password for that role (three tries, then locked until the Supervisor resets it); this is approved demo behaviour for the prototype and is not an approved production security architecture.

**Acceptance criteria.**
1. Given the prototype, when the role is chosen and the correct password is entered, then the role Home opens with no separate Start Shift screen.
2. Given a wrong password, then the tries left are shown.
3. Given three wrong tries, then the prototype is locked with Ask your supervisor to reset it.
4. Given a production build, then a shared role password alone is not accepted as the authentication mechanism (FR-ATT-015).

**Dependencies:** [FR-ATT-015](#fr-att-015--production-staff-authentication-and-authorization), [FR-ID-002](#fr-id-002--other-internal-users-have-individual-mealloop-managed-accounts)

**Source:** [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (Flow); [`design/audit/design_intent.md`](../design/audit/design_intent.md) (DOOR SCANNER 2026-10: rule 9)

**Note.** A prototype interaction only (a Debug or Figma behaviour), not an approved production method. Production staff use individual MealLoop-managed accounts (FR-ID-002); the mechanism details are proposed in FR-ATT-015.

#### FR-ATT-014 · Staff roles share Home, Alerts and Me

**Status:** `CONFIRMED` · **Roles:** Door Scanner, Pass Desk, Kitchen Staff, Supervisor

**Statement.** Every staff role has the same three tabs (Home, Alerts, Me); Alerts puts an active SOS on top and Me shows the role, mess and shift.

**Acceptance criteria.**
1. Given any staff role, then the bottom bar has Home, Alerts and Me and no fourth tab.
2. Given an SOS is active, then Alerts shows the SOS card first.
3. Given Me, then it shows initials, role, mess and an On shift state, and no invented name.

**Dependencies:** none

**Source:** [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (Alerts and Me; Navigation)

#### FR-ATT-015 · Production staff authentication and authorization

**Status:** `PROPOSED` · **Roles:** Door Scanner, Pass Desk, Kitchen Staff, Supervisor, Admin, Super Admin, Warden, Gate Security, Vendor

**Statement.** Production access must give every internal user an individually attributable identity: Students and Super Admins through SRM SSO (FR-ID-001; feasibility unverified) and all other internal users through individual MealLoop-managed accounts (FR-ID-002). Each user has an assigned role with mess or block scope, secure sessions with revocation, and auditable approvals, changes, scanning overrides and SOS actions. The exact mechanism is decided in the NFR, architecture and security reviews.

**Acceptance criteria.**
1. Given any production action, then it carries the actor's individual identity, role and mess or block scope.
2. Given a session, then it is secure and can be revoked, and a deactivated account cannot perform protected operations.
3. Given an approval, a change, a scanning override, an SOS action, an account administration action or a vendor acknowledgment, then it is recorded in an audit trail with the actor.
4. Given the prototype's shared role password, then it is not accepted as the sole production credential.

**Dependencies:** [FR-ATT-013](#fr-att-013--prototype-staff-entry-uses-a-shared-role-password), [FR-ADM-015](#fr-adm-015--staff-access-is-managed-by-admin), [FR-ADM-016](#fr-adm-016--key-decisions-keep-an-audit-history), [FR-ID-001](#fr-id-001--students-and-super-admins-sign-in-through-srm-sso), [FR-ID-002](#fr-id-002--other-internal-users-have-individual-mealloop-managed-accounts), [FR-ID-003](#fr-id-003--super-admin-manages-accounts-and-roles)

**Source:** owner decision in task prompt; owner decision in the C1 review task prompt (identity boundaries)

**Note.** Proposed production controls. The two authentication arrangements are confirmed direction (FR-ID-001, FR-ID-002). The password policy, multi-factor authentication, lockout and recovery rules, session length and who may provision which roles are OPEN (P61, P62); the mechanism is not chosen here (P35).

### 7.4 Special meal pass and the Pass Desk (`FR-PASS`)

The special-meal pass is separate from hostel outing passes. The desk does not scan.

#### FR-PASS-001 · The special-meal pass shows a changing code and colour

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** An eligible student's special-meal pass shows a code and a colour that keep changing and says no scan is needed.

**Acceptance criteria.**
1. Given a valid pass for the meal, when the student opens it, then the code and colour change on a visible countdown.
2. Given the pass is not for today, expired, already used or for another mess, then the matching state is shown.
3. Given the pass is shown, then it states that no scan is needed and the desk checks the code and colour.

**Dependencies:** [FR-PASS-002](#fr-pass-002--the-desk-compares-code-and-colour-and-records-only-on-matches)

**Source:** [`design/reference/pass_desk_2026-10/data/pass_desk_spec.md`](../design/reference/pass_desk_2026-10/data/pass_desk_spec.md) (How a pass is checked); [`design/audit/export_polish/README.md`](../design/audit/export_polish/README.md) (P04_special_pass_ticket)

**Note.** Older student wording (Hold to Confirm records a single use; ends in Redeemed) conflicts with the desk recording the entry (Conflicts table C-9).

#### FR-PASS-002 · The desk compares code and colour and records only on Matches

**Status:** `CONFIRMED` · **Roles:** Pass Desk

**Statement.** Pass Desk staff type the student's last 4 digits, the app shows the code and colour the student's phone should be showing, staff compare, and only the Matches · record entry action records the entry.

**Acceptance criteria.**
1. Given the fourth digit is typed, then Check this pass shows the expected code, colour and a Changes in countdown.
2. Given staff tap Matches · record entry, then the entry is recorded once and Pass verified is shown.
3. Given any other action (Doesn't match, Back, close), then nothing is recorded.
4. Given the desk, then there is no camera scanning.

**Dependencies:** [FR-PASS-001](#fr-pass-001--the-special-meal-pass-shows-a-changing-code-and-colour)

**Source:** [`design/reference/pass_desk_2026-10/data/pass_desk_spec.md`](../design/reference/pass_desk_2026-10/data/pass_desk_spec.md) (How a pass is checked (DECISION: no camera))

#### FR-PASS-003 · A lookup never records an entry

**Status:** `CONFIRMED` · **Roles:** Pass Desk

**Statement.** Looking up a student's special-pass status never records an entry.

**Acceptance criteria.**
1. Given a student is looked up, then only status is shown (Valid, Used or no pass) with This does not count as an entry.
2. Given a lookup, then the special-meal count is unchanged.

**Dependencies:** [FR-PASS-002](#fr-pass-002--the-desk-compares-code-and-colour-and-records-only-on-matches)

**Source:** [`design/reference/pass_desk_2026-10/data/pass_desk_spec.md`](../design/reference/pass_desk_2026-10/data/pass_desk_spec.md) (Outcomes 6)

#### FR-PASS-004 · A special-meal entry is recorded at most once

**Status:** `CONFIRMED` · **Roles:** Pass Desk

**Statement.** A student with a special-meal entry already recorded for the meal shows Already recorded and nothing is added.

**Acceptance criteria.**
1. Given an entry exists, when staff check the same pass again, then Already recorded shows the first time and the count stays the same.
2. Given a retry with the same idempotency key, then the original result is returned.

**Dependencies:** [FR-PASS-002](#fr-pass-002--the-desk-compares-code-and-colour-and-records-only-on-matches)

**Source:** [`design/reference/pass_desk_2026-10/data/pass_desk_spec.md`](../design/reference/pass_desk_2026-10/data/pass_desk_spec.md) (Outcomes 3)

#### FR-PASS-005 · No pass, wrong meal and mismatch record nothing

**Status:** `CONFIRMED` · **Roles:** Pass Desk

**Statement.** No special pass, Wrong meal and Doesn't match each show the reason and record nothing; a student without a pass can still have the regular meal.

**Acceptance criteria.**
1. Given no valid special pass, then the screen says so, records nothing and says the regular meal is still available.
2. Given a pass for another meal, then the screen names that meal and records nothing.
3. Given the code or colour does not match, then the expected values are shown with Nothing was recorded and Check again.

**Dependencies:** [FR-PASS-002](#fr-pass-002--the-desk-compares-code-and-colour-and-records-only-on-matches)

**Source:** [`design/reference/pass_desk_2026-10/data/pass_desk_spec.md`](../design/reference/pass_desk_2026-10/data/pass_desk_spec.md) (Outcomes 2, 4)

#### FR-PASS-006 · An unverified pass check is never shown as success

**Status:** `CONFIRMED` · **Roles:** Pass Desk

**Statement.** If a pass cannot be verified and saved, the desk never shows success and records nothing.

**Acceptance criteria.**
1. Given no connection or unavailable pass data, then the screen says This pass is NOT checked and offers retry.
2. Given that state, then no entry is recorded and none is queued.

**Dependencies:** [FR-ATT-007](#fr-att-007--an-offline-or-unverifiable-scan-is-never-shown-as-success)

**Source:** [`design/reference/pass_desk_2026-10/data/pass_desk_spec.md`](../design/reference/pass_desk_2026-10/data/pass_desk_spec.md) (Outcomes 5)

**Note.** Pilot rule: an offline or unverifiable pass check records nothing and is never shown as success. *Superseded by NFR-REL-005 in [`NFR.md`](NFR.md) (the owner is asked to confirm); resolves the former open decision P5 (now R21).*

#### FR-PASS-007 · Pass reissue goes through the admin pass-exception flow

**Status:** `CONFIRMED` · **Roles:** Pass Desk, Admin

**Statement.** A request for a new pass goes to the existing admin pass-exception flow, and its status is Waiting, Approved, Done or Rejected, where Approved is never shown as Done.

**Acceptance criteria.**
1. Given staff request a new pass, then the request is sent to the admin pass-exception flow with a reason.
2. Given Admin approves it, then the status is Approved and not Done.
3. Given the student actually has the new pass, then the status is Done.

**Dependencies:** [FR-ADM-014](#fr-adm-014--special-pass-oversight)

**Source:** [`design/reference/pass_desk_2026-10/data/pass_desk_spec.md`](../design/reference/pass_desk_2026-10/data/pass_desk_spec.md) (Request a new pass (reissue))

**Note.** The admin pass-exception screens exist on Figma page 10, the older admin (Conflicts table C-5).

#### FR-PASS-008 · Pass Desk follows the meal state

**Status:** `CONFIRMED` · **Roles:** Pass Desk, Supervisor

**Statement.** Before the meal the Pass Desk shows when checking opens, during the meal it offers the keypad and the special-meal count, and after the Supervisor closes the meal checking is closed.

**Acceptance criteria.**
1. Given the meal has not started, then no keypad or count is shown.
2. Given the meal is in service, then the keypad is on Home with the special-meal count.
3. Given the meal is closed, then Checking is closed and the final recorded count is shown.

**Dependencies:** [FR-SUP-001](#fr-sup-001--the-supervisor-starts-the-meal-for-the-mess), [FR-SUP-002](#fr-sup-002--the-supervisor-closes-the-meal)

**Source:** [`design/reference/pass_desk_2026-10/data/pass_desk_spec.md`](../design/reference/pass_desk_2026-10/data/pass_desk_spec.md) (Meal lifecycle)

#### FR-PASS-009 · Pass Desk can report a problem or food running short

**Status:** `CONFIRMED` · **Roles:** Pass Desk

**Statement.** Pass Desk staff can report a problem in one tap to the Supervisor, and Food running short sends the dish to the kitchen team of that mess.

**Acceptance criteria.**
1. Given a problem option is tapped, then it is sent to the Supervisor with a Sent toast.
2. Given Food running short, when a dish is chosen and sent, then it appears in the kitchen's alerts as Food short at the pass desk.
3. Given sending fails, then the app says so and does not claim delivery.

**Dependencies:** [FR-KIT-016](#fr-kit-016--pass-desk-food-shortages-reach-the-kitchen)

**Source:** [`design/reference/pass_desk_2026-10/data/pass_desk_spec.md`](../design/reference/pass_desk_2026-10/data/pass_desk_spec.md) (Report a problem)

#### FR-PASS-010 · Pass Desk can claim and check an SOS

**Status:** `CONFIRMED` · **Roles:** Pass Desk

**Statement.** Pass Desk staff can claim an active SOS and mark it Checked by the desk, which does not close the case.

**Acceptance criteria.**
1. Given an SOS is active, then the SOS tab appears and the panel offers I'll go and check.
2. Given the desk marks it checked, then the case shows Checked by the desk and stays open.

**Dependencies:** [FR-ATT-012](#fr-att-012--door-staff-can-claim-and-check-an-sos-but-not-close-it)

**Source:** [`design/reference/pass_desk_2026-10/data/pass_desk_spec.md`](../design/reference/pass_desk_2026-10/data/pass_desk_spec.md) (SOS, Alerts, Me)

#### FR-PASS-011 · Special-pass eligibility

**Status:** `PROPOSED` · **Roles:** Student, Pass Desk

**Statement.** Which students hold a special-meal pass and for which weeks is decided outside this document; a student without a valid pass uses the regular meal.

**Acceptance criteria.**
1. Given a student without a valid special pass, when the desk checks them, then nothing is recorded and the regular meal remains available.
2. Given eligibility rules are undecided, then no rule is hard-coded.

**Dependencies:** [FR-PASS-005](#fr-pass-005--no-pass-wrong-meal-and-mismatch-record-nothing)

**Source:** [`design/README.md`](../design/README.md) (Open decisions: Special Meal Pass eligibility and weeks); [`design/reference/pass_desk_2026-10/data/pass_desk_spec.md`](../design/reference/pass_desk_2026-10/data/pass_desk_spec.md) (Open items 3)

### 7.5 Kitchen and waste measurement (`FR-KIT`)

Before the meal the forecast, during it the live count, after it leftovers per dish and one plate-waste total.

#### FR-KIT-001 · Before the meal the kitchen sees Forecasted attendance only

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff

**Statement.** Before the meal, Kitchen Home shows Forecasted attendance (the expected diners) and nothing else in that card, with clear loading, stale and not-ready states.

**Acceptance criteria.**
1. Given the meal has not started, when the kitchen opens Home, then a card labelled Forecasted attendance shows the forecast and expected diners.
2. Given the forecast is not ready, then the card shows a dash and Forecast not ready yet (never 0).
3. Given the forecast is old, then a small note shows when it was updated and that it may be out of date.
4. Given the meal has not started, then no waste action and no live entry count are shown.

**Dependencies:** [FR-HC-002](#fr-hc-002--headcount-quantities-are-separate-and-never-merged)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Home by meal state: Before)

#### FR-KIT-002 · During the meal the kitchen sees students entered only

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff

**Statement.** During the meal, Kitchen Home shows only the live count of students who have entered, never meals served, never the forecast beside it and never a remaining count.

**Acceptance criteria.**
1. Given the meal is in service, then the card shows the live entry count labelled students entered with its update time.
2. Given the live count is shown, then the forecast is not shown on the same screen.
3. Given the count is unavailable, then it shows a dash, never 0.
4. Given the count is old, then a stale note shows when it was updated, and offline shows an offline banner.

**Dependencies:** [FR-ATT-009](#fr-att-009--live-entry-count-is-shown-as-recorded-entries-only), [FR-HC-002](#fr-hc-002--headcount-quantities-are-separate-and-never-merged)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Home by meal state: During); [`design/audit/design_intent.md`](../design/audit/design_intent.md) (KITCHEN STAFF 2026-10: Counting rule)

#### FR-KIT-003 · The kitchen reports food running short in one tap

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff

**Statement.** During service the kitchen can report that a dish is running short by choosing the dish, optionally how bad and a note, and sending it to the Supervisor.

**Acceptance criteria.**
1. Given the meal is in service, when the kitchen taps Report food running short, then a sheet shows the day's dishes and at least one must be chosen.
2. Given the report is sent, then a slim row shows the dish, level and sent time, and no row exists when nothing was reported.
3. Given the same dish is reported again within a short window, then the app asks whether to report again.
4. Given sending fails, then the row says Couldn't send with a Retry and nothing claims delivery.

**Dependencies:** [FR-SUP-004](#fr-sup-004--the-supervisor-follows-up-and-resolves-shortages)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Report food running short)

#### FR-KIT-004 · Shortage status never claims seen without evidence

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff, Supervisor

**Statement.** A shortage row shows Sent, and shows that the Supervisor saw it only when that was confirmed.

**Acceptance criteria.**
1. Given a shortage was sent, then the row says Sent with the time.
2. Given the Supervisor opened it and the system recorded that, then the row says the Supervisor saw it.
3. Given no confirmation exists, then the row never says seen.

**Dependencies:** [FR-KIT-003](#fr-kit-003--the-kitchen-reports-food-running-short-in-one-tap)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Shortage status)

#### FR-KIT-005 · Waste is recorded only after the meal has ended

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff

**Statement.** The kitchen can record waste only after the Supervisor has closed the meal; before and during the meal no waste action is available.

**Acceptance criteria.**
1. Given the meal is not closed, then no Record waste action is shown and a save request is refused.
2. Given the meal is closed, then Home shows the Waste report card with Record waste.
3. Given a local timer, then it never ends a meal; only the Supervisor does.

**Dependencies:** [FR-SUP-002](#fr-sup-002--the-supervisor-closes-the-meal)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Record waste (after the meal only))

#### FR-KIT-006 · Leftovers are recorded per dish in the dish's own unit

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff

**Statement.** Leftovers are recorded one row per dish in that dish's own unit (kg, L or pieces), and units are never combined or converted.

**Acceptance criteria.**
1. Given the day's menu, then Record waste has one row per dish with its own unit beside the value.
2. Given rows in different units, then no total, sum or conversion across units is shown anywhere.
3. Given an entered quantity, then it must be a number greater than zero (zero is recorded as None left).

**Dependencies:** [FR-KIT-005](#fr-kit-005--waste-is-recorded-only-after-the-meal-has-ended)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Record waste)

#### FR-KIT-007 · Plate waste is one total for the whole meal

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff

**Statement.** Plate waste is recorded as one total in kilograms for the whole meal and never per dish.

**Acceptance criteria.**
1. Given Record waste, then there is exactly one plate-waste field for the meal.
2. Given no plate-waste value was entered, then it is Not entered and never 0.

**Dependencies:** [FR-KIT-005](#fr-kit-005--waste-is-recorded-only-after-the-meal-has-ended)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Record waste)

#### FR-KIT-008 · Waste fields are entered, None left, Not made or Not entered

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff

**Statement.** Each dish row is entered, None left (a confirmed zero), Not made or Not entered, and missing data never becomes zero.

**Acceptance criteria.**
1. Given a dish with a quantity, then it is stored as entered with its unit.
2. Given the kitchen confirms nothing is left, then it is stored as None left, a measured zero, in a different state from Not entered.
3. Given a dish was not cooked, then it is Not made and carries no quantity.
4. Given a dish was not filled in, then it is Not entered and is never read as zero in totals or reports.

**Dependencies:** [FR-KIT-006](#fr-kit-006--leftovers-are-recorded-per-dish-in-the-dishs-own-unit)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Record waste: Row states); owner decision in task prompt

#### FR-KIT-009 · Drafts save freely; the final save is blocked while fields are empty

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff

**Statement.** The kitchen can save a draft at any time, and Review and save is blocked while any field is empty or invalid.

**Acceptance criteria.**
1. Given a partly filled report, when the kitchen leaves, then the draft is saved with its time.
2. Given any field is Not entered, then Review and save is blocked and says how many remain.
3. Given a value is invalid, then it is rejected with a reason.

**Dependencies:** [FR-KIT-008](#fr-kit-008--waste-fields-are-entered-none-left-not-made-or-not-entered)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Record waste)

**Note.** Maximum quantities per unit are not defined (open decision).

#### FR-KIT-010 · A saved report is Recorded with no approval loop

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff, Supervisor

**Statement.** A saved waste report is simply Recorded; there is no Waiting, Returned or Approved state and no supervisor approval.

**Acceptance criteria.**
1. Given a complete report is saved, then its status is Recorded with the time and the kitchen sees View report.
2. Given any screen or API, then no waste state named Waiting, Returned or Approved exists and no approve action is offered to anyone.
3. Given a report is Recorded, then the Supervisor sees it read-only.

**Dependencies:** [FR-SUP-005](#fr-sup-005--the-supervisor-sees-waste-reports-read-only)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (What Kitchen Staff does); [`design/audit/MASTER_CONTEXT.md`](../design/audit/MASTER_CONTEXT.md) (Run KITCHEN · pack v2); owner decision in task prompt

#### FR-KIT-011 · A recorded report can be edited for six hours

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff

**Statement.** A recorded report can be edited for six hours after it was saved, then it is read-only.

**Acceptance criteria.**
1. Given a report was saved, then Home and the past meal show You can edit until the time six hours after saving.
2. Given the six hours have passed, then Editing closed after 6 hours is shown and no edit action exists.
3. Given an edit is saved, then the edit is recorded in the history (see FR-KIT-012).

**Dependencies:** [FR-KIT-010](#fr-kit-010--a-saved-report-is-recorded-with-no-approval-loop), [FR-KIT-012](#fr-kit-012--waste-reports-keep-audit-timestamps-and-edit-history)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Editing (DECISION: 6 hours)); owner decision in task prompt

**Note.** Whether an edit restarts the six-hour window is an open decision (P27).

#### FR-KIT-012 · Waste reports keep audit timestamps and edit history

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff, Admin

**Statement.** Drafts, saves and late submissions carry audit timestamps, and every edit of a recorded report preserves the earlier values in an edit history.

**Acceptance criteria.**
1. Given a draft, a save, an edit or a late submission, then the system stores who and when.
2. Given a recorded report was edited, then the earlier values remain retrievable and are not overwritten.
3. Given a meal that ended without a report and one is recorded later, then it is marked as a late submission with the time.

**Dependencies:** [FR-KIT-010](#fr-kit-010--a-saved-report-is-recorded-with-no-approval-loop)

**Source:** owner decision in task prompt

#### FR-KIT-013 · A meal without a report shows Not recorded

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff, Supervisor

**Statement.** A meal that ended without a waste report shows Not recorded, and its waste can still be recorded.

**Acceptance criteria.**
1. Given a meal ended with no report, then Meal history and the Supervisor's alerts show Not recorded.
2. Given the kitchen opens that meal, then Record waste is available.

**Dependencies:** [FR-KIT-005](#fr-kit-005--waste-is-recorded-only-after-the-meal-has-ended)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Editing; Meal history)

**Note.** How long a missed meal's waste can still be recorded is an open decision (P10).

#### FR-KIT-014 · Meal history lists ended meals only

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff

**Statement.** Meal history lists only meals that have ended, each with the entered count and a plain status of Recorded or Not recorded.

**Acceptance criteria.**
1. Given today's meal has not ended, then it is not in Meal history.
2. Given an ended meal, then its row shows the entered count and a dot plus text status, never a pill.
3. Given no ended meals, then Meal history shows its empty state.

**Dependencies:** [FR-KIT-013](#fr-kit-013--a-meal-without-a-report-shows-not-recorded)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Meal history)

#### FR-KIT-015 · The kitchen menu shows dish names only

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff

**Statement.** Before the meal the kitchen can read the day's menu as a plain list of dish names, with no units, tags or counts.

**Acceptance criteria.**
1. Given the menu for the meal, when the kitchen opens Menu for Lunch, then only dish names are listed.
2. Given the list, then no quantities to cook are shown.

**Dependencies:** [FR-MENU-001](#fr-menu-001--menu-upload-reads-a-photo-and-flags-uncertain-words)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Home by meal state: Before)

#### FR-KIT-016 · Pass Desk food shortages reach the kitchen

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff, Pass Desk

**Statement.** A food shortage reported at the Pass Desk appears in the kitchen's Alerts as Food short at the pass desk.

**Acceptance criteria.**
1. Given the desk sends Food running short for a dish, then the kitchen's Alerts shows it with the dish and time.
2. Given it is shown, then it is not presented as seen by the Supervisor unless confirmed.

**Dependencies:** [FR-PASS-009](#fr-pass-009--pass-desk-can-report-a-problem-or-food-running-short)

**Source:** [`design/reference/pass_desk_2026-10/data/pass_desk_spec.md`](../design/reference/pass_desk_2026-10/data/pass_desk_spec.md) (Report a problem); [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Alerts, Me, SOS)

#### FR-KIT-017 · The kitchen can claim and check an SOS

**Status:** `CONFIRMED` · **Roles:** Kitchen Staff

**Statement.** Kitchen staff can claim an active SOS and mark it Checked by the kitchen, which does not close the case.

**Acceptance criteria.**
1. Given an SOS is active, then the SOS tab appears on Home and the panel offers I'll go and check with kitchen wording.
2. Given the kitchen marks it checked, then the case shows Checked by the kitchen and stays open.

**Dependencies:** [FR-ATT-012](#fr-att-012--door-staff-can-claim-and-check-an-sos-but-not-close-it)

**Source:** [`design/reference/kitchen_2026-10/data/kitchen_spec.md`](../design/reference/kitchen_2026-10/data/kitchen_spec.md) (Alerts, Me, SOS)

**Note.** K19 and K20 (Kitchen Home with the SOS tab, SOS panel) are in the pack but not yet drawn in Figma.

#### FR-KIT-018 · Phase 2: optional plate-waste return station

**Status:** `PROPOSED` · **Roles:** Admin, Kitchen Staff

**Statement.** After Phase 1 shows value, investigate an optional RFID and camera return station to measure plate waste; it is not part of the December 2026 delivery.

**Acceptance criteria.**
1. Given Phase 1 results are available, then the decision to investigate is made explicitly by the owner.
2. Given any camera at a return station, then a privacy, consent and institutional review precedes any build.
3. Given this requirement, then no Phase 1 or December work depends on it.

**Dependencies:** [FR-ADM-005](#fr-adm-005--the-meal-report-compares-sent-headcount-final-entries-and-waste)

**Source:** owner decision in task prompt

### 7.6 Supervisor (`FR-SUP`)

The Supervisor starts and closes the meal, follows up shortages, reads waste read-only and closes SOS cases.

#### FR-SUP-001 · The Supervisor starts the meal for the mess

**Status:** `CONFIRMED` · **Roles:** Supervisor

**Statement.** The Supervisor starts the meal for the mess, which opens the Door Scanner and Pass Desk and changes the meal state of every staff role in that mess.

**Acceptance criteria.**
1. Given the meal has not started, when the Supervisor confirms Start this meal, then the state becomes in service for the whole mess.
2. Given the meal is in service, then the Door Scanner and Pass Desk open and the kitchen shows the live count.
3. Given a role other than the Supervisor, then it cannot start the meal.

**Dependencies:** none

**Source:** [`design/reference/supervisor_2026-10/data/supervisor_spec.md`](../design/reference/supervisor_2026-10/data/supervisor_spec.md) (Home by meal state; Confirmations)

**Note.** Whether Start meal unlocks only near the scheduled time is an open decision (P13).

#### FR-SUP-002 · The Supervisor closes the meal

**Status:** `CONFIRMED` · **Roles:** Supervisor

**Statement.** The Supervisor closes the meal for the mess, which stops scanning and pass checks, and closing does not resolve a shortage or complete a waste report.

**Acceptance criteria.**
1. Given the meal is in service, when the Supervisor confirms Close this meal, then the state becomes closed for every staff role.
2. Given the meal is closed, then Final entries are shown, or Unavailable if missing and never zero.
3. Given the meal was closed, then open shortages stay active and the waste report is not marked complete.

**Dependencies:** [FR-SUP-001](#fr-sup-001--the-supervisor-starts-the-meal-for-the-mess)

**Source:** [`design/reference/supervisor_2026-10/data/supervisor_spec.md`](../design/reference/supervisor_2026-10/data/supervisor_spec.md) (Home by meal state; Confirmations); owner decision in task prompt

#### FR-SUP-003 · Supervisor Home follows the meal state

**Status:** `CONFIRMED` · **Roles:** Supervisor

**Statement.** Supervisor Home shows Forecasted attendance before the meal, the live students entered during it (never with the forecast beside it), and Final entries after it.

**Acceptance criteria.**
1. Given the meal has not started, then Home shows Forecasted attendance and a Start meal action.
2. Given the meal is in service, then Home shows the live count and a Close meal action, with no forecast.
3. Given the meal is closed, then Home shows Final entries or Unavailable.

**Dependencies:** [FR-HC-002](#fr-hc-002--headcount-quantities-are-separate-and-never-merged)

**Source:** [`design/reference/supervisor_2026-10/data/supervisor_spec.md`](../design/reference/supervisor_2026-10/data/supervisor_spec.md) (Home by meal state)

#### FR-SUP-004 · The Supervisor follows up and resolves shortages

**Status:** `CONFIRMED` · **Roles:** Supervisor

**Statement.** The Supervisor sees active shortages, opens the details and marks a shortage resolved after confirming, and the resolution is kept in history.

**Acceptance criteria.**
1. Given a shortage was reported, then it appears in the Supervisor's Alerts as Active.
2. Given the Supervisor taps Mark resolved and confirms, then it leaves the active list and history shows Shortage resolved.
3. Given the meal was closed, then the shortage is still active until the Supervisor resolves it.

**Dependencies:** [FR-KIT-003](#fr-kit-003--the-kitchen-reports-food-running-short-in-one-tap)

**Source:** [`design/reference/supervisor_2026-10/data/supervisor_spec.md`](../design/reference/supervisor_2026-10/data/supervisor_spec.md) (Shortage)

#### FR-SUP-005 · The Supervisor sees waste reports read-only

**Status:** `CONFIRMED` · **Roles:** Supervisor

**Statement.** The Supervisor can read a recorded waste report (unserved food and plate waste, each dish in its own unit) but cannot edit, approve, return or forward it.

**Acceptance criteria.**
1. Given a Recorded report, then the Supervisor sees Unserved food and Plate waste and expandable details with each dish in its unit and 0 kg · none left for a confirmed zero.
2. Given a report is Not recorded, then the screen says so and that there is nothing to do.
3. Given any waste screen, then no forward, approve, edit or return action exists for the Supervisor.

**Dependencies:** [FR-KIT-010](#fr-kit-010--a-saved-report-is-recorded-with-no-approval-loop)

**Source:** [`design/reference/supervisor_2026-10/data/supervisor_spec.md`](../design/reference/supervisor_2026-10/data/supervisor_spec.md) (Waste (read only)); owner decision in task prompt

#### FR-SUP-006 · Only the Supervisor closes an SOS case in the staff app

**Status:** `CONFIRMED` · **Roles:** Supervisor

**Statement.** The Supervisor can claim, mark checked and close an SOS case in the staff app, and no other staff role has a Close case action.

**Acceptance criteria.**
1. Given an SOS is not taken, then the panel offers I'll go and check and Not now.
2. Given the Supervisor marks it checked, then it shows Checked by the supervisor, and Close case closes it with a Case closed message and the tab disappears.
3. Given a case was checked by the door, desk or kitchen, then the Supervisor can still Close case.
4. Given any other staff role, then Close case is never offered.

**Dependencies:** [FR-ATT-012](#fr-att-012--door-staff-can-claim-and-check-an-sos-but-not-close-it), [FR-FB-004](#fr-fb-004--an-sos-reaches-staff-and-the-admin-safety-case)

**Source:** [`design/reference/supervisor_2026-10/data/supervisor_spec.md`](../design/reference/supervisor_2026-10/data/supervisor_spec.md) (SOS); owner decision in task prompt

**Note.** The admin Safety case also has Checked and closed; which role closes in which app is an open decision (P28).

#### FR-SUP-007 · Supervisor Alerts and history show the same tasks everywhere

**Status:** `CONFIRMED` · **Roles:** Supervisor

**Statement.** Active shortages and Waste not recorded are the same tasks and counts on Home, Alerts and Me, and past meals have a read-only history.

**Acceptance criteria.**
1. Given a shortage or a missing report, then its count is the same on Home, Alerts and Me.
2. Given Meal history, then each past meal shows its entries (or Unavailable) and a plain status, read-only.
3. Given the Supervisor has nothing pending, then Alerts shows the all-caught-up state.

**Dependencies:** [FR-SUP-004](#fr-sup-004--the-supervisor-follows-up-and-resolves-shortages), [FR-SUP-005](#fr-sup-005--the-supervisor-sees-waste-reports-read-only)

**Source:** [`design/reference/supervisor_2026-10/data/supervisor_spec.md`](../design/reference/supervisor_2026-10/data/supervisor_spec.md) (Alerts; Me and History)

**Note.** Problem reports from the door and desk (FR-ATT-011, FR-PASS-009) also reach the Supervisor; how they appear in Alerts is not drawn.

### 7.7 Feedback, Community and urgent safety (`FR-FB`)

Structured reports, Community, Me too and the separate urgent path. Eligible non-urgent reports publish automatically after configured checks; urgent reports bypass Community (FR-FB-005, FR-FB-003).

#### FR-FB-001 · Students submit structured complaints

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** A student can submit a structured complaint by choosing a predefined category with optional free text.

**Acceptance criteria.**
1. Given Report a problem, then plain categories with examples are offered and free text is optional.
2. Given a report is sent, then a receipt and a My reports entry with progress are shown.
3. Given a send fails, then no receipt is shown and Try again is offered.

**Dependencies:** none

**Source:** owner decision in task prompt; [`design/README.md`](../design/README.md) (Round 3: Report); [`design/audit/PROJECT_CONTEXT.md`](../design/audit/PROJECT_CONTEXT.md) (Report a problem)

**Note.** Backend ownership is not assigned in docs/backend/BACKEND_PROPOSAL.md.

#### FR-FB-002 · Dish feedback names the dish, the problem and how bad

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** Dish feedback is given in steps: Good or Not good, then which dish, then the specific problem and how bad.

**Acceptance criteria.**
1. Given Good, then it is sent at once.
2. Given Not good, then the student picks the dish (most reported today is offered with one-tap Me too), then a problem from the list for that dish type and how bad.
3. Given Service, then it goes to Community rather than a dish.

**Dependencies:** [FR-FB-008](#fr-fb-008--me-too-counts-once-per-student-per-issue)

**Source:** [`design/reference/redesign_2026-10/README.md`](../design/reference/redesign_2026-10/README.md) (11_feedback_step1_good_or_not, 12_feedback_step2_which_dish, 13_feedback_step3_whats_wrong); [`design/audit/design_intent.md`](../design/audit/design_intent.md) (STUDENT REDESIGN 2026-10: Feedback)

#### FR-FB-003 · Urgent issues bypass Community and go to SOS

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** Urgent hygiene, contamination, illness or safety reports bypass Community and trigger direct escalation through the SOS workflow, and they never wait for votes.

**Acceptance criteria.**
1. Given an urgent category, then the flow goes to Tell the counter staff now and the SOS steps, not to Community.
2. Given a food SOS, then a live photo with place and time and three checks are required before sending; I feel unwell may be sent without a photo.
3. Given the camera is denied, then Send without photo is offered and flagged on the admin Safety case.
4. Given an urgent report, then it is never published to Community, never held for Community support or an Admin publication decision, and it escalates through the SOS workflow.

**Dependencies:** [FR-FB-004](#fr-fb-004--an-sos-reaches-staff-and-the-admin-safety-case)

**Source:** owner decision in task prompt; [`design/audit/design_intent.md`](../design/audit/design_intent.md) (STUDENT REDESIGN 2026-10: SOS needs proof)

**Note.** Whether anyone is alerted in real time and whether photos are kept are open (design/audit/prototype_gaps.md).

#### FR-FB-004 · An SOS reaches staff and the admin Safety case

**Status:** `CONFIRMED` · **Roles:** Student, Door Scanner, Pass Desk, Kitchen Staff, Supervisor, Admin

**Statement.** A student's SOS appears to staff on duty, who can claim and check it, the Supervisor can close it, and Admin sees it as a Safety case with the proof and who has acted.

**Acceptance criteria.**
1. Given a student sends an SOS, then staff on duty see the SOS tab and card.
2. Given staff claim and check it, then the case records who and when, and stays open.
3. Given the Admin opens it, then the Safety case shows student, staff, vendor and admin steps with the proof.

**Dependencies:** [FR-ATT-012](#fr-att-012--door-staff-can-claim-and-check-an-sos-but-not-close-it), [FR-SUP-006](#fr-sup-006--only-the-supervisor-closes-an-sos-case-in-the-staff-app)

**Source:** [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Safety case); [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (SOS)

#### FR-FB-005 · Community publication of non-urgent reports

**Status:** `CONFIRMED` · **Roles:** Student, Admin

**Statement.** Eligible non-urgent student reports are published to Community automatically, without Admin action, after they pass the configured privacy, safety, abuse and spam checks; flagged or uncertain reports are held for Admin moderation.

**Acceptance criteria.**
1. Given an eligible non-urgent report that passes the configured checks, when it is submitted, then it is published to Community without any Admin action, and the record shows the approved deterministic policy (and its version) that published it.
2. Given an urgent hygiene, contamination, illness or safety report, then it is never published to Community and it enters the urgent escalation workflow at once (FR-FB-003).
3. Given a report that is flagged or uncertain under the checks, then it is not published and is held in a queue for Admin moderation.
4. Given a published report, when Admin hides it, then it is no longer visible to students, the action is recorded with who, when and why, and Admin can intervene at any stage.
5. Given any Community view, API response or export, then no student identity (name, ID or any other identifier) is exposed publicly.
6. Given reports about the same problem, then duplicates are grouped into one issue so that supporters and Me too counts are not split.
7. Given an issue below any Me too threshold, then Admin can investigate it without waiting for votes (FR-FB-010).

**Dependencies:** [FR-FB-003](#fr-fb-003--urgent-issues-bypass-community-and-go-to-sos), [FR-FB-007](#fr-fb-007--rules-and-categories-come-first-ai-is-optional), [FR-FB-008](#fr-fb-008--me-too-counts-once-per-student-per-issue), [FR-FB-010](#fr-fb-010--admin-can-investigate-or-intervene-before-a-threshold), [FR-AI-002](#fr-ai-002--ai-advises-and-routes-it-never-makes-sensitive-decisions)

**Source:** owner decision in task prompt; [`design/audit/PROJECT_CONTEXT.md`](../design/audit/PROJECT_CONTEXT.md) (Admin (10): community moderation (AD-3d))

**Note.** Owner decision (confirmed in the correction notes for this PR). The exact check rules and the criteria for flagged or uncertain are implementation details for the API and security design and are not set here. Automatic publication by an approved deterministic policy is allowed; a publication decision made autonomously by an AI model is not (FR-AI-002). Resolves open decision P26 and Conflicts C-1 and C-2.

#### FR-FB-006 · Community comments are checked before they show

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** Comments on a Community issue are checked before they are shown and show no names.

**Acceptance criteria.**
1. Given a comment is sent, then it is Pending until checked and shows as Visible or Hidden afterwards.
2. Given a visible comment, then no student name appears.
3. Given a failed send, then Failed and a retry are shown.

**Dependencies:** none

**Source:** [`design/README.md`](../design/README.md) (Fix round: Comments)

**Note.** Moderation and review time are open (design/README.md).

#### FR-FB-007 · Rules and categories come first; AI is optional

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Feedback handling is built in this order: (1) structured complaint categories; (2) deterministic routing and publication rules; (3) semantic duplicate detection; (4) an optional small or large language model, only after testing shows useful administrative value, and then only to advise or route to human moderation.

**Acceptance criteria.**
1. Given a report, then it is categorized with structured categories and routed and, if eligible, published by deterministic rules, without a language model.
2. Given reports describing the same problem, then semantic duplicate detection groups them.
3. Given a language model is proposed, then it is enabled only after testing shows useful administrative value, and it may only advise or route a report to human moderation.
4. Given the model is down or disabled, then submission, routing, publication and the Admin view still work.

**Dependencies:** [FR-AI-002](#fr-ai-002--ai-advises-and-routes-it-never-makes-sensitive-decisions), [FR-AI-008](#fr-ai-008--a-language-model-is-optional-and-added-only-on-evidence), [FR-FB-005](#fr-fb-005--community-publication-of-non-urgent-reports)

**Source:** owner decision in task prompt

#### FR-FB-008 · Me too counts once per student per issue

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** A student can back an issue with Me too once, can undo it, and each student counts once.

**Acceptance criteria.**
1. Given an issue, when a student taps Me too, then the count increases by one and the button shows backed with Undo.
2. Given the student taps again, then the count does not increase.
3. Given Undo, then the count decreases by one.

**Dependencies:** none

**Source:** owner decision in task prompt; [`design/reference/redesign_2026-10/README.md`](../design/reference/redesign_2026-10/README.md) (09_community_list: Me too, Backed state with Undo)

#### FR-FB-009 · The Community support threshold is configurable

**Status:** `VALIDATION REQUIRED` · **Roles:** Admin

**Statement.** The support threshold is configurable and calibrated during the pilot, and there is no fixed number.

**Acceptance criteria.**
1. Given the threshold is a setting, then it can be changed without a release.
2. Given no threshold is set, then no automatic escalation is triggered by votes.
3. Given the pilot ends, then the chosen value is recorded with the evidence used.

**Dependencies:** [FR-FB-008](#fr-fb-008--me-too-counts-once-per-student-per-issue)

**Source:** owner decision in task prompt; [`design/audit/design_intent.md`](../design/audit/design_intent.md) (Open items)

#### FR-FB-010 · Admin can investigate or intervene before a threshold

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Admin can investigate, assign an owner or act on an issue before any support threshold is reached.

**Acceptance criteria.**
1. Given an issue below any threshold, then Admin can open it, assign an owner and record an action.
2. Given Admin acts early, then the issue records who, what and when.

**Dependencies:** [FR-FB-011](#fr-fb-011--corrective-action-completed-is-not-improvement-verified)

**Source:** owner decision in task prompt; [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Students: Community needs an owner)

#### FR-FB-011 · Corrective action completed is not improvement verified

**Status:** `CONFIRMED` · **Roles:** Admin, Student

**Statement.** An issue moves Sent, Seen, Working on it, Fixed (with Need more info and Reopened), records the owner, what was investigated, what was done and when, and Fixed means the corrective action was completed, not that improvement was verified.

**Acceptance criteria.**
1. Given an issue, then its status uses these plain words only.
2. Given Admin marks it Fixed, then at least one recorded corrective action is required.
3. Given the action is complete, then the issue shows corrective action completed and improvement is a separate, later state set only from follow-up evidence.

**Dependencies:** [FR-FB-012](#fr-fb-012--student-follow-up-verifies-real-improvement)

**Source:** owner decision in task prompt; [`design/README.md`](../design/README.md) (Round 3: plain status words); [`design/audit/design_intent.md`](../design/audit/design_intent.md) (Definitions)

#### FR-FB-012 · Student follow-up verifies real improvement

**Status:** `CONFIRMED` · **Roles:** Student, Admin

**Statement.** After an issue is Fixed, students who reported or backed it can say whether it improved, and Admin evaluates real improvement from that follow-up.

**Acceptance criteria.**
1. Given an issue is Fixed, then the relevant students are asked whether things improved.
2. Given answers arrive, then Admin sees the result as follow-up evidence and not as a percentage of waste.
3. Given insufficient answers, then the issue is not marked improvement verified.

**Dependencies:** [FR-FB-011](#fr-fb-011--corrective-action-completed-is-not-improvement-verified)

**Source:** owner decision in task prompt; [`design/README.md`](../design/README.md) (Prototype flows: fix check)

**Note.** What counts as enough answers is not defined and must not be invented.

#### FR-FB-013 · Feedback is aggregate and never shows names to staff

**Status:** `CONFIRMED` · **Roles:** Admin, Student

**Statement.** Feedback is shown to Admin in aggregate and never with student names; the private spending tracker never feeds admin data.

**Acceptance criteria.**
1. Given Admin views feedback, then counts and problems are shown and no student name.
2. Given the spending tracker, then none of its data reaches any admin view.
3. Given a safety case, then the student appears only as a masked ID where documented.

**Dependencies:** none

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (Product decisions: Privacy; Permissions); [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Safety case)

**Note.** Whether staff see who sent a report is an open decision (design/README.md).

#### FR-FB-014 · Feedback and intent reasons need a retention rule

**Status:** `SRM APPROVAL REQUIRED` · **Roles:** Admin

**Statement.** How long feedback, skipping reasons and report photos are kept is decided before the pilot and then enforced.

**Acceptance criteria.**
1. Given a retention rule is approved, then data older than it is deleted or reduced as the rule says.
2. Given no rule is approved, then no personal feedback data is used beyond its original purpose.

**Dependencies:** none

**Source:** [`design/README.md`](../design/README.md) (Open decisions: retention, deletion scope)

### 7.8 Student experience (`FR-STU`)

The other approved student features.

#### FR-STU-001 · Students sign in with their SRM identity

**Status:** `SRM APPROVAL REQUIRED` · **Roles:** Student

**Statement.** A student signs in with their SRM identity through SRM's official SSO and reaches Home without extra screens. SRM SSO feasibility is unverified; the sign-in provider, access to it and any profile-correction path are decided by SRM and SRM IT.

**Acceptance criteria.**
1. Given a valid SRM identity, when the student signs in, then Getting your details leads straight to Home.
2. Given a failed sign-in, then a clear failure and offline state are shown.
3. Given the provider or SSO access is unconfirmed, then no real authentication is claimed as built and no fallback identity scheme is described as approved.

**Dependencies:** [FR-ID-001](#fr-id-001--students-and-super-admins-sign-in-through-srm-sso)

**Source:** [`design/reference/redesign_2026-10/README.md`](../design/reference/redesign_2026-10/README.md) (01_sign_in, 02_getting_details); [`design/README.md`](../design/README.md) (Open decisions: Sign-in provider)

#### FR-STU-002 · Student Home adapts to the moment

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** Student Home shows the next meal with the response buttons, the entry QR, the passes row, the crowd row and the credits chip, and changes with the time of day.

**Acceptance criteria.**
1. Given the time of day, then Home shows the matching meal and state (before, answered, near the meal, during, done).
2. Given a response, then the hero shows it with the cutoff and a way to change it until the cutoff.
3. Given the entry QR, then Show entry QR is a solid button in every case.

**Dependencies:** [FR-MEAL-003](#fr-meal-003--responses-can-be-changed-until-two-hours-before-the-meal), [FR-MEAL-004](#fr-meal-004--answering-is-voluntary-and-the-entry-qr-is-never-locked)

**Source:** [`design/reference/redesign_2026-10/README.md`](../design/reference/redesign_2026-10/README.md) (03_home, 04_home_top_card_cases); [`design/audit/PROJECT_CONTEXT.md`](../design/audit/PROJECT_CONTEXT.md) (Student: Home)

#### FR-STU-003 · Students see entry status and history

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** Students can see the live entry QR, whether it was scanned, an already-scanned state and their entry history.

**Acceptance criteria.**
1. Given a QR is scanned, then the student sees Scanned.
2. Given a repeat scan, then Already scanned is shown.
3. Given Entry history, then recorded entries are listed.

**Dependencies:** [FR-ATT-001](#fr-att-001--the-entry-qr-confirms-entry-only)

**Source:** [`design/audit/PROJECT_CONTEXT.md`](../design/audit/PROJECT_CONTEXT.md) (Student: Entry QR)

#### FR-STU-004 · Notifications and lock-screen messages

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** Students receive notifications with a type circle in an inbox and as lock-screen messages, including dinner changed and guardian answered.

**Acceptance criteria.**
1. Given a notification is sent, then it appears in the inbox with its type circle and in the lock-screen style.
2. Given the app is offline, then the saved list is shown under an offline banner.

**Dependencies:** none

**Source:** [`design/audit/export_polish/README.md`](../design/audit/export_polish/README.md) (P01_notifications_circles)

#### FR-STU-005 · The You tab and private trackers

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** The You tab shows the ID card, outings, attendance, credits, notification settings, privacy and help, and the private spending tracker never feeds admin data.

**Acceptance criteria.**
1. Given the You tab, then Outings is the first settings row and Waste, Nutrition and the plate tracker are absent.
2. Given the spending tracker, then it is private to the student.

**Dependencies:** [FR-FB-013](#fr-fb-013--feedback-is-aggregate-and-never-shows-names-to-staff)

**Source:** [`design/reference/redesign_2026-10/README.md`](../design/reference/redesign_2026-10/README.md) (19_you, 24_spending_private); [`design/audit/design_intent.md`](../design/audit/design_intent.md) (STUDENT REDESIGN 2026-10: Not in the student app)

#### FR-STU-006 · The student app supports larger text

**Status:** `PROPOSED` · **Roles:** Student

**Statement.** Student screens remain usable at the largest accessibility text sizes.

**Acceptance criteria.**
1. Given the largest text size, then Home, Attendance, the live pass and Report step 1 remain usable.
2. Given any text, then wrapping is used and text is not truncated.

**Dependencies:** none

**Source:** [`design/README.md`](../design/README.md) (Page 06 States & Accessibility; Known limits: build with Dynamic Type)

**Note.** Targets are quantified in the non-functional requirements task.

### 7.9 Crowd guidance (`FR-CRD`)

Verified arrival activity and clearly labelled estimates; never occupancy (DI-5).

#### FR-CRD-001 · Crowd shows verified arrival activity and labelled estimates

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** The crowd view shows verified arrival activity and clearly labelled estimated busy or quiet periods, each with data freshness and confidence.

**Acceptance criteria.**
1. Given entries exist, then arrival activity shows entries by time slot.
2. Given an estimated busy or quiet period, then it is labelled as an estimate with its freshness and confidence.
3. Given the data is stale or unavailable, then Stale or Unavailable is shown.

**Dependencies:** [FR-CRD-003](#fr-crd-003--entry-scans-never-become-an-occupancy-claim)

**Source:** owner decision in task prompt; [`design/audit/PROJECT_CONTEXT.md`](../design/audit/PROJECT_CONTEXT.md) (Student: Crowd)

**Note.** The Home row currently reads Quiet now; that wording needs review (Conflicts C-14).

#### FR-CRD-002 · Honest insufficient-data states

**Status:** `CONFIRMED` · **Roles:** Student, Admin

**Statement.** When there is not enough history, crowd and live comparisons say so instead of showing a number.

**Acceptance criteria.**
1. Given too little arrival history, then Not enough history yet is shown and no usual value is invented.
2. Given the scanner is offline, then the view says so.

**Dependencies:** [FR-CRD-001](#fr-crd-001--crowd-shows-verified-arrival-activity-and-labelled-estimates)

**Source:** [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Live meal: Not enough history yet); owner decision in task prompt

**Note.** How much history is enough is a pilot question; the admin sample says four weeks as a sample, not a decision.

#### FR-CRD-003 · Entry scans never become an occupancy claim

**Status:** `CONFIRMED` · **Roles:** Student, Admin

**Statement.** MealLoop never claims current occupancy from entry scans: a crowd forecast is not verified current occupancy, cumulative entries are not occupancy, exit detection is not assumed, and predicted and verified crowd are labelled separately.

**Acceptance criteria.**
1. Given entry scans, then no screen or API labels them as people currently inside.
2. Given an estimate of busy or quiet, then it is labelled predicted and kept apart from verified arrivals.
3. Given a wait time, then none is shown without validation.

**Dependencies:** none

**Source:** owner decision in task prompt; [`design/audit/design_intent.md`](../design/audit/design_intent.md) (Definitions: crowd (a level, never 'inside'))

#### FR-CRD-004 · Arrival activity is bucketed by time

**Status:** `PROPOSED` · **Roles:** Admin, Door Scanner

**Statement.** Entry timestamps are summarised in time buckets to show arrival patterns and recurring peaks.

**Acceptance criteria.**
1. Given entries, then a bar view shows entries per time slot.
2. Given the door count, then it can show the slot view.
3. Given a bucket size, then it is configurable.

**Dependencies:** [FR-ATT-002](#fr-att-002--scanning-a-valid-qr-records-one-entry)

**Source:** [`design/reference/door_scanner_2026-10/data/door_scanner_spec.md`](../design/reference/door_scanner_2026-10/data/door_scanner_spec.md) (During the meal); [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Reason detail)

**Note.** Bucket size is not decided.

#### FR-CRD-005 · Class schedules and behavioural patterns only if validated

**Status:** `VALIDATION REQUIRED` · **Roles:** Admin

**Statement.** Class schedules and individual or group behavioural patterns are used for crowd estimates only if validated on unseen data.

**Acceptance criteria.**
1. Given a proposed signal, then it is evaluated on unseen data before it is used.
2. Given no validation, then the signal is not used.

**Dependencies:** [FR-AI-003](#fr-ai-003--forecasting-starts-from-a-statistical-baseline)

**Source:** owner decision in task prompt

### 7.10 Credits and rewards (`FR-RWD`)

Participation credits and a conditional accuracy bonus are confirmed; every amount, the verification method, the budget and the scheme need SRM approval or pilot validation.

#### FR-RWD-001 · Definite responses earn small participation credits

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** I'm in and Skip earn small participation credits when given before the cutoff, while Not sure and No response earn none.

**Acceptance criteria.**
1. Given a definite response before the cutoff, then a participation credit is granted once for that meal.
2. Given Not sure or No response, then no credit is granted.
3. Given a changed response, then at most one participation credit exists per student per meal.

**Dependencies:** [FR-MEAL-003](#fr-meal-003--responses-can-be-changed-until-two-hours-before-the-meal)

**Source:** owner decision in task prompt

**Note.** Credit values are not defined (FR-RWD-002).

#### FR-RWD-002 · Credit amounts, budget and redemption need SRM approval

**Status:** `SRM APPROVAL REQUIRED` · **Roles:** Student, Admin

**Statement.** The exact participation-credit amount, the exact accuracy-bonus amount, the redemption budget, the reward values and the incentive scheme as a whole are approved by SRM before any real reward is offered.

**Acceptance criteria.**
1. Given no approval, then screens show Credits soon and sample values are labelled sample.
2. Given approval, then the amounts, budget, reward values and redemption rules are recorded with their source.

**Dependencies:** none

**Source:** owner decision in task prompt; [`design/README.md`](../design/README.md) (Open decisions: points)

#### FR-RWD-003 · Accuracy bonus requires reliably verified behaviour

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** In addition to participation credits, a student may earn an accuracy bonus when a definite answer matches reliably verified behaviour; a bonus is awarded only on trustworthy evidence, and credit corrections are auditable.

**Acceptance criteria.**
1. Given a student answered I'm in or Skip before the cutoff and reliably verified behaviour matches the answer, then an accuracy bonus can be awarded in addition to the participation credit.
2. Given a Skip and no QR scan exists, then the Skip is not treated as verified absence merely because the scan is missing.
3. Given scanning coverage is incomplete or unreliable (for example a scanner failure), then a missing entry is not proof of absence and no accuracy bonus is awarded for that meal.
4. Given a credit or bonus is corrected, then the correction is recorded with who, when and why and cannot be edited silently.
5. Given any bonus decision, then it never depends solely on an AI model.

**Dependencies:** [FR-RWD-001](#fr-rwd-001--definite-responses-earn-small-participation-credits), [FR-RWD-002](#fr-rwd-002--credit-amounts-budget-and-redemption-need-srm-approval), [FR-RWD-006](#fr-rwd-006--scanner-failures-have-a-correction-process), [FR-ATT-007](#fr-att-007--an-offline-or-unverifiable-scan-is-never-shown-as-success)

**Source:** owner decision in task prompt; [`design/README.md`](../design/README.md) (Rules: Points never depend on attendance or reports (superseded by this decision))

**Note.** Owner decision (confirmed in the correction notes for this PR): conditional accuracy bonuses are a confirmed product direction. Still open and not decided here: the exact participation-credit amount, the exact accuracy-bonus amount, the reliable absence-verification method, the minimum verification coverage, the redemption budget and reward values, and institutional approval of the incentive scheme (open decisions P1, P22 and P32). Resolves Conflict C-11.

#### FR-RWD-004 · Duplicate claims and redemptions are prevented

**Status:** `CONFIRMED` · **Roles:** Student, Admin

**Statement.** A credit claimed from a verified entry can be claimed at most once per student per meal, and a redemption can be used once.

**Acceptance criteria.**
1. Given an entry credit exists, when claimed twice for the same entry, then the second is refused.
2. Given a redeemed ticket, then it cannot be redeemed again.

**Dependencies:** [FR-ATT-005](#fr-att-005--a-student-is-recorded-at-most-once-per-meal)

**Source:** owner decision in task prompt

**Note.** Whether an entry credit exists is not documented.

#### FR-RWD-005 · Answers are never pushed and corrections are allowed

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** Yes and No are equally valid, students are not pushed toward Yes, and a genuine correction before the cutoff is supported.

**Acceptance criteria.**
1. Given the answer screen, then no option is pre-selected.
2. Given a change before the cutoff, then it replaces the earlier answer without penalty.

**Dependencies:** [FR-MEAL-003](#fr-meal-003--responses-can-be-changed-until-two-hours-before-the-meal)

**Source:** owner decision in task prompt

#### FR-RWD-006 · Scanner failures have a correction process

**Status:** `PROPOSED` · **Roles:** Student, Admin

**Statement.** If a scanner failure prevented a student's entry from being recorded, a correction path exists so that credits and reliability records are not lost or wrongly lowered, and every correction is auditable.

**Acceptance criteria.**
1. Given a scanner failure, then a student or staff can request a correction.
2. Given a correction is accepted, then the entry and any credit are updated with an audit record.

**Dependencies:** [FR-RWD-003](#fr-rwd-003--accuracy-bonus-requires-reliably-verified-behaviour), [FR-OUT-028](#fr-out-028--post-pilot-eligibility-needs-participation-and-reliability)

**Source:** [`README.md`](../README.md) (Credits and incentives); [`design/README.md`](../design/README.md) (Open decisions: attendance correction window and reviewer)

#### FR-RWD-007 · Real rewards only in a limited pilot after SRM approval

**Status:** `SRM APPROVAL REQUIRED` · **Roles:** Admin

**Statement.** Limited real pilot rewards are offered only after SRM approves the budget and the redemption method.

**Acceptance criteria.**
1. Given no SRM approval, then no real reward is offered.
2. Given approval, then the budget and redemption method are recorded.

**Dependencies:** [FR-RWD-002](#fr-rwd-002--credit-amounts-budget-and-redemption-need-srm-approval)

**Source:** owner decision in task prompt

#### FR-RWD-008 · Credits screens

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** Students can see a credits balance, ticket offers, ticket detail with a live code and credits history, and see Credits soon before launch.

**Acceptance criteria.**
1. Given credits are not launched, then Credits soon is shown.
2. Given a ticket, then a live code and colour are shown and it can be used once.

**Dependencies:** [FR-RWD-002](#fr-rwd-002--credit-amounts-budget-and-redemption-need-srm-approval)

**Source:** [`design/audit/PROJECT_CONTEXT.md`](../design/audit/PROJECT_CONTEXT.md) (Student: Credits); [`design/audit/export_polish/README.md`](../design/audit/export_polish/README.md) (Q1_credits_coupons)

**Note.** All point values in the screens are samples.

### 7.11 Admin (Food head) (`FR-ADM`)

The Admin (Food head) app on Figma page 12: Today, Students, Results, More.

#### FR-ADM-001 · Admin has four tabs: Today, Students, Results, More

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** The Admin app has four tabs, Today, Students, Results and More, and no Meals tab or date strip.

**Acceptance criteria.**
1. Given Admin signs in, then the tab bar shows Today, Students, Results and More.
2. Given a meal, then it is reached from Today (to send, live) or from Results (needs review, or Find a meal).

**Dependencies:** none

**Source:** [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (Decisions baked into these screens 2)

**Note.** Page 12 (Admin Redesign) is the active admin; page 10 is older (Conflicts C-5).

#### FR-ADM-002 · Today shows one tile per mess with its meal progress

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Today shows one tile per mess with one number, a four-step bar (forecast ready, headcount sent, vendor replied, meal served and counted) and one bottom line, with the tile that needs action first.

**Acceptance criteria.**
1. Given several messes, then each has one tile and the tile that needs action is emphasised.
2. Given a mess with no data, then its tile says No data and shows no number.
3. Given Today, then Needs you lists items that need Admin's action.

**Dependencies:** [FR-HC-004](#fr-hc-004--admin-approves-or-adjusts-the-headcount-with-a-reason)

**Source:** [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (Decisions 3); [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Lunch headcount board)

**Note.** The vendor replied step is the vendor account's acknowledgment once vendor accounts exist (FR-VEN-003); until then it is the manually recorded reply of the interim handoff (FR-HC-007).

#### FR-ADM-003 · Admin sends the headcount from the headcount page

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** For one mess Admin sees the forecast, its range, the number of students who said yes and the usual figure, and approves and sends the headcount to the vendor from one page.

**Acceptance criteria.**
1. Given a ready forecast, then Admin sees the forecast with its basis and a Send action.
2. Given Admin sends (publishes the approved headcount to the vendor account), then the state moves to Sent and then Vendor replied or Waiting (pending acknowledgment).
3. Given a mess with no forecast data, then no number or range is shown (Today shows No data).

**Dependencies:** [FR-HC-004](#fr-hc-004--admin-approves-or-adjusts-the-headcount-with-a-reason), [FR-HC-006](#fr-hc-006--the-vendor-receives-a-headcount-only)

**Source:** [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (A02_headcount_north); [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Lunch headcount board)

**Note.** The existing Send and Tell the vendor design is the interim handoff; the vendor account workflow (FR-VEN-001 to FR-VEN-005) adds screens that are not in Figma.

#### FR-ADM-004 · The live meal page shows entries, not the final count

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** During service the live meal page shows entries so far (marked not the final count), the Supervisor's start state, and food reported low by staff.

**Acceptance criteria.**
1. Given the meal is in service, then entries so far are labelled not the final count.
2. Given staff reported low stock, then the page shows the dish and the report time.
3. Given history is short, then the page says Not enough history yet and shows no usual value.

**Dependencies:** [FR-ATT-009](#fr-att-009--live-entry-count-is-shown-as-recorded-entries-only), [FR-KIT-003](#fr-kit-003--the-kitchen-reports-food-running-short-in-one-tap)

**Source:** [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (A03_meal_live); [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Live meal)

#### FR-ADM-005 · The meal report compares sent headcount, final entries and waste

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** After a meal closes, the meal report shows headcount sent, final verified entries, shortages, dish-wise leftovers in their units, plate waste, how complete the data is, and what the vendor cooked only if it was recorded.

**Acceptance criteria.**
1. Given a closed meal, then the report shows headcount sent and Final entries as separate figures.
2. Given leftovers, then each dish is shown in its own unit and no cross-unit total exists.
3. Given vendor cooked data was not shared, then it shows Not shared or Missing, never zero.
4. Given missing evidence, then the report says what is missing.

**Dependencies:** [FR-HC-002](#fr-hc-002--headcount-quantities-are-separate-and-never-merged), [FR-KIT-010](#fr-kit-010--a-saved-report-is-recorded-with-no-approval-loop)

**Source:** [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (A04_meal_report); [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Meal report)

#### FR-ADM-006 · Results explain waste and shortages in plain reasons

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Results have the segments Left over, Ran out and To check, every number is labelled as meals, and each reason carries a tag of Sure, Probably or Can't tell and is never shown as a percentage.

**Acceptance criteria.**
1. Given Results, then each reason shows a count of meals and one of the three tags.
2. Given a reason, then no percentage of the waste is shown.
3. Given a meal can have more than one reason, then totals can exceed the number of meals and the screen says so.
4. Given key data is missing, then the reason is Can't tell and the missing items are shown.

**Dependencies:** [FR-ADM-005](#fr-adm-005--the-meal-report-compares-sent-headcount-final-entries-and-waste), [FR-AI-009](#fr-ai-009--waste-analysis-shows-association-not-causation)

**Source:** [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (Decisions 4); [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Results); owner decision in task prompt

#### FR-ADM-007 · The rules behind Results tags are validated before use

**Status:** `VALIDATION REQUIRED` · **Roles:** Admin

**Statement.** The thresholds that turn data into the Sure, Probably and Can't tell reasons are drafts and must be validated with the owner and pilot data before they are relied on.

**Acceptance criteria.**
1. Given the draft rules in the admin sample data, then none is treated as approved.
2. Given a threshold is confirmed, then it is recorded with its source and is configurable.

**Dependencies:** [FR-ADM-006](#fr-adm-006--results-explain-waste-and-shortages-in-plain-reasons)

**Source:** [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Rules behind the tags (DRAFT, owner to confirm the numbers))

#### FR-ADM-008 · Check next time needs two comparable meals

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** A change under test cannot be marked as having worked until at least two comparable meals are recorded, and it moves Open, Testing, Result.

**Acceptance criteria.**
1. Given a change was started, then its status is Open then Testing.
2. Given fewer than two comparable meals are recorded, then Result cannot be set to worked.
3. Given the change reduces one problem, then running-out is also checked.

**Dependencies:** [FR-ADM-006](#fr-adm-006--results-explain-waste-and-shortages-in-plain-reasons)

**Source:** [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (Decisions 6); [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Check next time)

#### FR-ADM-009 · The Students tab shows participation and what needs action

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** The Students tab shows how many students answered each way and did not answer, lets Admin remind those who did not answer, and lists feedback to act on and Community issues that need an owner.

**Acceptance criteria.**
1. Given a meal, then answered and not answered counts are shown for each response group.
2. Given Admin taps Remind, then a confirm sheet shows who and the message before sending.
3. Given feedback or a Community issue needs action, then it is listed with a way to act.

**Dependencies:** [FR-MEAL-002](#fr-meal-002--a-meal-response-is-im-in-skip-not-sure-or-no-response), [FR-FB-010](#fr-fb-010--admin-can-investigate-or-intervene-before-a-threshold)

**Source:** [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (A06_students); [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Students)

#### FR-ADM-010 · The Safety case follows an urgent report to its close

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Admin sees a Safety case across student, staff, vendor and Admin steps, with the proof and actions to call staff or tell the vendor, and closes it only after the hold is confirmed.

**Acceptance criteria.**
1. Given an urgent report, then the case shows its steps with who acted and when.
2. Given the hold is not confirmed, then Check and close is not available.
3. Given Admin tells the vendor, then it is recorded.

**Dependencies:** [FR-FB-004](#fr-fb-004--an-sos-reaches-staff-and-the-admin-safety-case)

**Source:** [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (A05_safety_case); [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Safety case)

**Note.** Relation to the Supervisor's Close case is open decision P28.

#### FR-ADM-011 · More holds menu, people, outings and announcements

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** More gives access to the weekly menu, people and access, outings and announcements, and the restyled older Admin pages that were kept.

**Acceptance criteria.**
1. Given More, then the weekly menu, people and access, outings and announce entries are present.
2. Given an older page that was archived, then it is not reachable.

**Dependencies:** [FR-MENU-001](#fr-menu-001--menu-upload-reads-a-photo-and-flags-uncertain-words), [FR-ADM-015](#fr-adm-015--staff-access-is-managed-by-admin), [FR-ADM-018](#fr-adm-018--admin-outings-overview)

**Source:** [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (A11_more)

#### FR-ADM-012 · Weekly and monthly reports export to PDF and CSV

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Admin can prepare a weekly report for this week, last week or a month and export it as PDF or CSV and send a vendor summary.

**Acceptance criteria.**
1. Given a period, then a report is prepared with a Preparing state and a Report ready message.
2. Given Export PDF or Export CSV, then the file is produced and a confirmation shows.
3. Given a report, then missing data is shown as missing and never as zero.

**Dependencies:** [FR-ADM-005](#fr-adm-005--the-meal-report-compares-sent-headcount-final-entries-and-waste)

**Source:** [`design/reference/fix2_2026-10/README.md`](../design/reference/fix2_2026-10/README.md) (F02_weekly_report_export, F03_report_pdf_page1)

#### FR-ADM-013 · Rewards administration

**Status:** `SRM APPROVAL REQUIRED` · **Roles:** Admin

**Statement.** Admin can manage the rewards catalogue and see redemptions, within the budget and rules SRM approves.

**Acceptance criteria.**
1. Given no approved budget, then no real reward can be activated.
2. Given redemptions, then each is traceable to one student and one use.

**Dependencies:** [FR-RWD-002](#fr-rwd-002--credit-amounts-budget-and-redemption-need-srm-approval)

**Source:** [`design/audit/PROJECT_CONTEXT.md`](../design/audit/PROJECT_CONTEXT.md) (Admin (10): Rewards AD-6c / 6c3); owner decision in task prompt

**Note.** Only the older page 10 draws Rewards; its restyled copy on page 12 was archived (design/audit/admin_redesign/archive_index.md).

#### FR-ADM-014 · Special-pass oversight

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Admin can see special passes and handle pass exceptions, including reissue requests from the Pass Desk.

**Acceptance criteria.**
1. Given a reissue request from the desk, then it appears for Admin to approve or reject.
2. Given Admin approves, then it is Approved and becomes Done only when the student has the new pass.

**Dependencies:** [FR-PASS-007](#fr-pass-007--pass-reissue-goes-through-the-admin-pass-exception-flow)

**Source:** [`design/reference/pass_desk_2026-10/data/pass_desk_spec.md`](../design/reference/pass_desk_2026-10/data/pass_desk_spec.md) (Request a new pass); [`design/audit/PROJECT_CONTEXT.md`](../design/audit/PROJECT_CONTEXT.md) (Admin (10): Special passes AD-6a / 6b)

**Note.** Drawn only on page 10 (Conflicts C-5).

#### FR-ADM-015 · Staff access is managed by Admin

**Status:** `CONFIRMED` · **Roles:** Admin, Super Admin

**Statement.** Admin can see who has which role (food heads, supervisors, door staff, kitchen staff, wardens, gate security, the vendor account) and can request access, and sees the access history. Super Admin provisions accounts, assigns roles and scope, changes scope, deactivates accounts and initiates password resets (FR-ID-003); Admin does not do these.

**Acceptance criteria.**
1. Given People and access, then counts by role and a way to request access are shown.
2. Given an access change, then it is recorded in history with who and when.
3. Given the Food Head / Admin role, then it cannot provision, assign roles, change scope, deactivate or initiate a password reset (FR-ID-005).

**Dependencies:** [FR-ADM-016](#fr-adm-016--key-decisions-keep-an-audit-history), [FR-ID-003](#fr-id-003--super-admin-manages-accounts-and-roles), [FR-ID-005](#fr-id-005--food-head--admin-does-not-have-super-admin-privileges)

**Source:** [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (People and access); [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (A13_people_access); owner decision in the C1 review task prompt (identity boundaries)

**Note.** Superseded in part: version 0.2 said Admin can give access. Provisioning and role assignment now belong to the separate Super Admin role. The People and access frame is a read and request surface for Admin; the Super Admin screens are not in Figma.

#### FR-ADM-016 · Key decisions keep an audit history

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Headcount adjustments, headcount publication to the vendor account and its acknowledgment, meal start and close, shortage resolution, waste edits, SOS closing, access changes (account provisioning, role and scope changes, deactivation and password-reset initiation) and outing overrides are recorded with who, when and why.

**Acceptance criteria.**
1. Given any listed action, then the record holds actor, time and reason where one is required.
2. Given the history, then entries cannot be edited or deleted.

**Dependencies:** none

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (RULES: logs); [`README.md`](../README.md) (Principles: Accountability); owner decision in task prompt

#### FR-ADM-017 · Admin analytics never include private trackers

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Admin analytics never include the students' private spending tracker data.

**Acceptance criteria.**
1. Given any admin analytic or export, then no spending-tracker data is present.
2. Given the student app, then the spending tracker is not sent to the server for admin use.

**Dependencies:** [FR-FB-013](#fr-fb-013--feedback-is-aggregate-and-never-shows-names-to-staff)

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (RULES: analytics 18 (historical rule, names the calorie tracker)); [`design/reference/redesign_2026-10/README.md`](../design/reference/redesign_2026-10/README.md) (19_you, 24_spending_private)

**Note.** The calorie and nutrition trackers were archived in the student redesign and are not requirements; the older rule in design_intent.md that names them is a historical record (Conflicts C-17).

#### FR-ADM-018 · Admin outings overview

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Admin can see outings at a glance: students out now, due back, late, waiting for a warden and escalated.

**Acceptance criteria.**
1. Given outings exist, then counts of out now, due back, late, waiting and escalated are shown.
2. Given a late return, then it is visible to Admin.

**Dependencies:** [FR-OUT-018](#fr-out-018--overdue-returns-are-escalated)

**Source:** [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Outings (admin)); [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (A14_outings_admin)

#### FR-ADM-019 · Announce to students

**Status:** `PROPOSED` · **Roles:** Admin

**Statement.** Admin can send an announcement to students.

**Acceptance criteria.**
1. Given a message, when Admin sends it, then students receive it and it is recorded.
2. Given the feature is undecided, then it is not built.

**Dependencies:** [FR-STU-004](#fr-stu-004--notifications-and-lock-screen-messages)

**Source:** [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Open items 4: Whether Announce to students ships)

### 7.12 Menu management (`FR-MENU`)

Menu photo upload with human-checked reading, publishing and change notices.

#### FR-MENU-001 · Menu upload reads a photo and flags uncertain words

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Admin uploads a photo of the printed menu board, the app reads it with OCR or vision, uncertain readings are flagged for checking, and a person corrects them before publishing.

**Acceptance criteria.**
1. Given a photo, then the app produces a draft menu with each uncertain word marked.
2. Given a flagged word, then Admin must check or correct it before it can be published.
3. Given an unreadable photo, then the app says so and does not invent dishes.

**Dependencies:** [FR-AI-001](#fr-ai-001--ai-is-advisory-and-core-dining-works-without-it)

**Source:** [`design/reference/admin_redesign_2026-10/README.md`](../design/reference/admin_redesign_2026-10/README.md) (A12_weekly_menu); [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Weekly menu); owner decision in task prompt

#### FR-MENU-002 · Admin publishes the menu and students are told of significant changes

**Status:** `CONFIRMED` · **Roles:** Admin, Student

**Statement.** Admin publishes the weekly menu, can edit a day or quickly change a meal (swap, add a special, remove), and students are notified of significant changes.

**Acceptance criteria.**
1. Given a checked menu, when Admin publishes, then students can read it.
2. Given a significant change, then students are notified; Given Tell students is switched off, then no notification is sent.
3. Given a quick change, then a preview is shown before it is sent.

**Dependencies:** [FR-MENU-001](#fr-menu-001--menu-upload-reads-a-photo-and-flags-uncertain-words), [FR-STU-004](#fr-stu-004--notifications-and-lock-screen-messages)

**Source:** [`design/reference/fix2_2026-10/README.md`](../design/reference/fix2_2026-10/README.md) (F04_menu_edit_day, F05_menu_quick_change)

#### FR-MENU-003 · Menu dishes show tier, diet mark and highlight

**Status:** `PROPOSED` · **Roles:** Student

**Statement.** The student menu shows highlight dishes, mains, curries and the rest, with a diet mark per dish; the meaning of the yellow highlight on the printed board is undecided.

**Acceptance criteria.**
1. Given a dish is marked on the board, then it is shown as Highlight with the note Marked by the mess on the menu board.
2. Given a non-veg dish, then it carries the non-veg mark.
3. Given the meaning is undecided, then no claim is made about what Highlight means.

**Dependencies:** [FR-MEAL-001](#fr-meal-001--students-can-read-the-published-menu)

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (STUDENT REDESIGN 2026-10: Menu tiers); [`design/reference/redesign_2026-10/README.md`](../design/reference/redesign_2026-10/README.md) (05_meals_lunch)

**Note.** Open decisions: yellow highlight meaning, who the ** gravies are for.

#### FR-MENU-004 · The menu source is the printed board with items to check

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** The menu data comes from the printed mess board, and any item the transcription could not read is marked for checking.

**Acceptance criteria.**
1. Given the transcribed menu, then items marked (?) are flagged and listed.
2. Given an unchecked item, then it is not published as confirmed.

**Dependencies:** [FR-MENU-001](#fr-menu-001--menu-upload-reads-a-photo-and-flags-uncertain-words)

**Source:** [`design/reference/redesign_2026-10/data/mess_menu_2024-08-12.md`](../design/reference/redesign_2026-10/data/mess_menu_2024-08-12.md) (transcription with (?) items); [`design/reference/redesign_2026-10/README.md`](../design/reference/redesign_2026-10/README.md) (Contents)

### 7.13 Digital outings (`FR-OUT`)

Digital outings: Student request, Guardian decision, Warden decision, Signed pass, Gate exit, Gate return. Eligibility has a pilot mode and a post-pilot mode. Deployment depends on SRM (FR-OUT-027).

#### FR-OUT-001 · Students request a digital outing

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** A student can request an outing with the day, time window, place and reason, and sees the deadlines and rule that apply before sending.

**Acceptance criteria.**
1. Given a day and window, then the request shows the rule (weekday or weekend) and the guardian and warden deadlines.
2. Given a request that is too late for the rule, then it is shown as Too soon and cannot be sent.
3. Given the request is sent, then its tracker shows the current step.

**Dependencies:** [FR-OUT-024](#fr-out-024--pilot-mode-digital-outings-for-the-authorized-pilot-cohort)

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (OUTING PASS: Approved workflow); [`design/reference/redesign_2026-10/README.md`](../design/reference/redesign_2026-10/README.md) (25_outing_new_weekday, 26_outing_new_weekend)

**Note.** The deadline numbers in the documents are drafts and are not adopted here (FR-OUT-025).

#### FR-OUT-002 · The outing sequence is fixed

**Status:** `CONFIRMED` · **Roles:** Student, Guardian, Warden, Gate

**Statement.** An outing follows this sequence: Student request, Guardian decision, Warden decision, Signed outing pass, Gate exit, Gate return, and guardian approval always comes before warden approval.

**Acceptance criteria.**
1. Given a new request, then it is awaiting the guardian and the warden cannot decide it.
2. Given the guardian has approved, then it moves to the warden.
3. Given both approved, then a signed pass is issued, and only then can the gate record an exit.
4. Given any other order, then the transition is refused.

**Dependencies:** none

**Source:** owner decision in task prompt; [`design/audit/design_intent.md`](../design/audit/design_intent.md) (OUTING PASS: Approved workflow)

#### FR-OUT-003 · No timeout ever grants permission

**Status:** `CONFIRMED` · **Roles:** Guardian, Warden

**Statement.** No timeout or missed deadline grants permission; a missed deadline escalates to a person and never approves an outing.

**Acceptance criteria.**
1. Given the guardian deadline passes, then the request escalates to the senior (duty) warden and is not approved.
2. Given the warden deadline passes, then the request escalates and is not approved.
3. Given any state, then there is no automatic approval path.

**Dependencies:** [FR-OUT-002](#fr-out-002--the-outing-sequence-is-fixed)

**Source:** owner decision in task prompt; [`design/audit/design_intent.md`](../design/audit/design_intent.md) (OUTING PASS 8)

#### FR-OUT-004 · The guardian opens the request and reviews the details

**Status:** `CONFIRMED` · **Roles:** Guardian

**Statement.** The guardian opens the request (a link with a one-time code) and reviews the destination, date, timing and other details before deciding.

**Acceptance criteria.**
1. Given the link, then the guardian verifies a one-time code and sees the request details (destination, date, timing and details).
2. Given the deadline has passed, then the page says so and no answer can be given.
3. Given the request was already answered, then the earlier answer is shown.

**Spec rule, quoted from [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md).**

> 1. Guardian opens the SMS link (mobile web, OTP). First time: consent page (G00).

**Dependencies:** [FR-OUT-026](#fr-out-026--the-guardian-contact-source-is-verified)

**Source:** [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md) (The flow 1)

**Note.** The channel for the link and the verification of the guardian contact are open (P20, FR-OUT-026).

#### FR-OUT-005 · The guardian chooses Accept or Reject first; Reject needs no video

**Status:** `CONFIRMED` · **Roles:** Guardian

**Statement.** The guardian chooses Accept or Reject before any recording, and Reject is one tap with optional reason chips and never requires a video.

**Acceptance criteria.**
1. Given the guardian opens the decision, then Accept and Reject are offered and no camera opens yet.
2. Given the guardian taps Reject, then the answer is sent without any video or photo, with an optional reason.
3. Given the guardian taps Accept, then the live confirmation video flow starts.

**Spec rule, quoted from [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md).**

> 2. Choose: "I accept" (record a 10-second video) or "I reject" (one tap, optional reason chips, no video) (G01, G08).

**Dependencies:** [FR-OUT-004](#fr-out-004--the-guardian-opens-the-request-and-reviews-the-details)

**Source:** [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md) (The flow 2)

#### FR-OUT-006 · Accept starts a four to ten second live video with a phrase and fresh code

**Status:** `CONFIRMED` · **Roles:** Guardian

**Statement.** Accept starts a live front-camera confirmation video of at least four and at most ten seconds that shows the phrase and a fresh random code for every request and every try.

**Acceptance criteria.**
1. Given Accept, then the camera is live only (no upload and no gallery) and a phrase with a fresh random 3-digit code is shown.
2. Given a recording shorter than four seconds, then it is rejected with Too short, try again.
3. Given a recording reaches ten seconds, then it stops.
4. Given a retry, then a new code is shown and the server stores the time.

**Spec rule, quoted from [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md).**

> 3. Record (G02): live camera only (no upload, no gallery), front camera, 10 seconds maximum, minimum 4 seconds ("Too short, try again" under 4 s). A random 3-digit code and the phrase are shown: "I accept <student>'s outing. Code 4 7 2." A new code for every request and every try. Countdown ring. The page stores a server timestamp.

**Dependencies:** [FR-OUT-005](#fr-out-005--the-guardian-chooses-accept-or-reject-first-reject-needs-no-video)

**Source:** [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md) (The flow 3)

#### FR-OUT-007 · The server checks the spoken phrase and code

**Status:** `CONFIRMED` · **Roles:** Guardian, Warden

**Statement.** The server checks the spoken phrase (tolerant of accent) and the digits (exact) in the chosen language, and a match sends the video to the warden as Video, auto-checked.

**Acceptance criteria.**
1. Given a matching phrase and digits, then the warden sees Live video with the Phrase, Code and Number checks.
2. Given the phrase or digits do not match, then the guardian is told we couldn't hear that and may try again.
3. Given a successful automatic check, then the request goes to the warden for final review; the automatic check is not warden approval.

**Spec rule, quoted from [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md).**

> 4. Check (server): speech-to-text in the chosen language (English, Tamil, Hindi first). The phrase and the code must match (tolerant of accent, strict on the 3 digits). Match -> sent to the warden as "Video, auto-checked".

**Dependencies:** [FR-OUT-006](#fr-out-006--accept-starts-a-four-to-ten-second-live-video-with-a-phrase-and-fresh-code), [FR-OUT-008](#fr-out-008--retries-and-the-manual-review-fallback)

**Source:** [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md) (The flow 4)

**Note.** Speech-recognition accuracy is not yet validated (FR-OUT-023, P21). This is the designed check, not a verified guarantee.

#### FR-OUT-008 · Retries and the manual-review fallback

**Status:** `CONFIRMED` · **Roles:** Guardian, Warden

**Statement.** A guardian has up to three tries, and after the third the last video goes to the warden marked Please watch with no automatic checks.

**Acceptance criteria.**
1. Given a failed check, then the guardian can try again up to three times with a new code each time.
2. Given the third failure, then Send video to the warden is offered and the video is sent as Please watch with no green checks.

**Spec rule, quoted from [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md).**

> 5. No match: "We couldn't hear that" (G03), up to 3 tries. After the third: G04 "Send video to the warden": the last video goes as "Video, please watch" with no green checks.

**Dependencies:** [FR-OUT-006](#fr-out-006--accept-starts-a-four-to-ten-second-live-video-with-a-phrase-and-fresh-code)

**Source:** [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md) (The flow 5)

**Note.** A designed fallback. Real operation depends on the consent and retention approval (FR-OUT-022) and the other SRM gates (FR-OUT-027).

#### FR-OUT-009 · Upload failure falls back to a live photo and typed code

**Status:** `CONFIRMED` · **Roles:** Guardian, Warden

**Statement.** If the video cannot upload after two retries, the guardian takes a live photo of their face, types the phrase with the code, and enters a one-time code sent to their phone, and the warden sees Photo and text with no video.

**Acceptance criteria.**
1. Given the video cannot upload after two retries, then a live photo (no gallery) is requested.
2. Given the photo, the typed phrase and the phone code, then the answer is sent as Photo and text, no video.
3. Given any missing part, then the answer is not sent.

**Spec rule, quoted from [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md).**

> 6. Video cannot upload (camera works, network does not, after 2 upload retries): G05 "Take a photo of your face instead": live photo only, type "I accept <code>", enter the 6-digit code sent to the guardian's phone. Sent as "Photo and text, no video".

**Dependencies:** [FR-OUT-006](#fr-out-006--accept-starts-a-four-to-ten-second-live-video-with-a-phrase-and-fresh-code)

**Source:** [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md) (The flow 6)

**Note.** A designed fallback. Real operation depends on the consent and retention approval (FR-OUT-022) and the other SRM gates (FR-OUT-027).

#### FR-OUT-010 · Phone confirmation by the warden is a designed fallback needing institutional approval

**Status:** `SRM APPROVAL REQUIRED` · **Roles:** Guardian, Warden

**Statement.** The design includes a fallback in which, if the guardian has no working camera, the request goes to Escalated and the warden phones the guardian and records Confirmed by call with a note; using it in real operation requires institutional approval.

**Acceptance criteria.**
1. Given no working camera, then Ask the warden to call me puts the request in Escalated as No camera (designed behaviour).
2. Given the warden phones and records the answer, then the evidence is Confirmed by call with the warden's note.
3. Given institutional approval has not been given, then the call path is not enabled for real students.
4. Given the call path is used, then the warden's note is the only evidence and no identity-verification guarantee is claimed.

**Spec rule, quoted from [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md).**

> 7. No working camera: the guardian cannot approve in the app. The request goes to Escalated; the warden phones the guardian and records "Confirmed by call".

**Dependencies:** [FR-OUT-008](#fr-out-008--retries-and-the-manual-review-fallback), [FR-OUT-027](#fr-out-027--deploying-digital-outings-depends-on-srm)

**Source:** [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md) (The flow 7; Open items)

**Note.** Separates a designed fallback from a fallback authorized for real operation. The guardian spec lists whether the call path is allowed as an open item (open decision P30, Conflicts C-16).

#### FR-OUT-011 · Text-only confirmation is never accepted

**Status:** `CONFIRMED` · **Roles:** Guardian, Warden

**Statement.** Text-only confirmation is never accepted; the guardian's face is always captured by video or live photo, except on the call path which the warden records.

**Acceptance criteria.**
1. Given any approval, then it carries a video, a live photo, or a warden-recorded call.
2. Given a text-only answer, then it is refused.

**Spec rule, quoted from [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md).**

> 8. NEVER text-only. The parent's face is always captured (video or photo) except the call path, which is recorded by the warden.

**Dependencies:** [FR-OUT-007](#fr-out-007--the-server-checks-the-spoken-phrase-and-code)

**Source:** [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md) (The flow 8)

**Note.** This is the designed rule. The evidence is not proof of identity and no identity-verification guarantee is claimed.

#### FR-OUT-012 · The warden sees the evidence method and checks

**Status:** `CONFIRMED` · **Roles:** Warden

**Statement.** The warden sees the evidence for each request tagged as Live video, Please watch, Photo and text, Confirmed by call or No video, with the checks that apply.

**Acceptance criteria.**
1. Given a request, then its evidence tag and the checks shown match the method.
2. Given the student view, then the student sees only the method and time and never the video.

**Dependencies:** [FR-OUT-007](#fr-out-007--the-server-checks-the-spoken-phrase-and-code)

**Source:** [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md) (What the warden sees; Student side)

#### FR-OUT-013 · The warden decides on guardian-approved requests

**Status:** `CONFIRMED` · **Roles:** Warden

**Statement.** The warden receives guardian-accepted requests with the evidence for final review, can examine the current request, the verification method, relevant previous guardian responses and the allowed evidence history, and approves, requests changes or rejects with a reason, for authorized hostel or block data only.

**Acceptance criteria.**
1. Given a guardian-accepted request, then it appears in the queue closest deadline first with its evidence, verification method and past answers.
2. Given the automatic video check succeeded, then the warden still makes the final decision; the automatic check is not warden approval.
3. Given Approve, then the pass is signed; given Ask, then the guardian is asked to change; given No, then a reason is required.
4. Given another block's request, then the warden cannot see it.

**Dependencies:** [FR-OUT-012](#fr-out-012--the-warden-sees-the-evidence-method-and-checks)

**Source:** [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md) (What the warden sees (own block only)); owner decision in task prompt

#### FR-OUT-014 · Missed deadlines escalate to the senior warden

**Status:** `CONFIRMED` · **Roles:** Warden

**Statement.** A request whose guardian or warden deadline passes is escalated to the senior (duty) warden.

**Acceptance criteria.**
1. Given a missed deadline, then the request appears in Escalated for the senior warden.
2. Given Escalated, then no request is approved by the escalation itself.

**Dependencies:** [FR-OUT-003](#fr-out-003--no-timeout-ever-grants-permission)

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (OUTING PASS 8)

**Note.** Who the escalation authority is remains an open decision (P19).

#### FR-OUT-015 · A signed, time-bound pass is issued after both approvals

**Status:** `CONFIRMED` · **Roles:** Student, Gate

**Statement.** After the guardian and the warden approve, a signed, time-bound pass is issued that is valid only inside the approved window.

**Acceptance criteria.**
1. Given both approvals, then a pass with a code is issued.
2. Given a pass outside its window, then it is not valid at the gate.

**Dependencies:** [FR-OUT-013](#fr-out-013--the-warden-decides-on-guardian-approved-requests)

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (OUTING PASS 4)

#### FR-OUT-016 · The gate checks the pass and window

**Status:** `CONFIRMED` · **Roles:** Gate

**Statement.** At the gate security checks that the pass is valid and within its window before recording an exit, and the student's identity is verified by the method the institution approves.

**Acceptance criteria.**
1. Given a valid pass inside its window, then Verify exit is available.
2. Given a pass too early, too late, withdrawn or not valid, then the matching message is shown and nothing is recorded.

**Dependencies:** [FR-OUT-015](#fr-out-015--a-signed-time-bound-pass-is-issued-after-both-approvals)

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (OUTING PASS 5)

**Note.** The identity method and the photo source are open (P4, prototype_gaps 360).

#### FR-OUT-017 · Exit and return are separate gate events

**Status:** `CONFIRMED` · **Roles:** Gate

**Statement.** The gate records the actual exit and the return as separate events, one exit per pass, and rejects a duplicate or invalid passage.

**Acceptance criteria.**
1. Given a valid pass, then an exit is recorded once.
2. Given the same pass is used to exit again, then it is rejected as Already exited.
3. Given a return, then it is recorded as a separate event with its own time.

**Dependencies:** [FR-OUT-016](#fr-out-016--the-gate-checks-the-pass-and-window)

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (OUTING PASS 5, 6)

#### FR-OUT-018 · Overdue returns are escalated

**Status:** `CONFIRMED` · **Roles:** Gate, Warden

**Statement.** A student not returned by the back-by time is Overdue, the warden and guardian are told, and the case is escalated.

**Acceptance criteria.**
1. Given no return after the back-by time, then the outing is Overdue.
2. Given Overdue, then the warden and guardian are told and it appears in Escalated.

**Dependencies:** [FR-OUT-017](#fr-out-017--exit-and-return-are-separate-gate-events)

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (OUTING PASS 7)

#### FR-OUT-019 · An approval does not prove the student left

**Status:** `CONFIRMED` · **Roles:** Gate, Admin

**Statement.** An outing approval does not prove the student left; only verified gate events count as attendance-related evidence, and the meal forecast uses confirmed exits only.

**Acceptance criteria.**
1. Given an approved outing with no gate exit, then the student is not treated as absent.
2. Given a verified gate exit, then it may be used as evidence.
3. Given the forecast, then only confirmed exits adjust it.

**Dependencies:** [FR-OUT-017](#fr-out-017--exit-and-return-are-separate-gate-events), [FR-HC-001](#fr-hc-001--the-forecast-accounts-for-every-response-category)

**Source:** owner decision in task prompt; [`design/audit/MASTER_CONTEXT.md`](../design/audit/MASTER_CONTEXT.md) (Outing Pass module: An approved outing is not an absence)

#### FR-OUT-020 · The guardian can withdraw approval and sees past answers

**Status:** `CONFIRMED` · **Roles:** Guardian

**Statement.** After answering, the guardian can see the answer, method and time, withdraw an approval, call the warden and read past answers.

**Acceptance criteria.**
1. Given an answer was sent, then it shows the method and time.
2. Given the guardian withdraws, then the request is withdrawn and the warden is told.

**Dependencies:** [FR-OUT-005](#fr-out-005--the-guardian-chooses-accept-or-reject-first-reject-needs-no-video)

**Source:** [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md) (The flow 9)

#### FR-OUT-021 · Emergency outings are handled by phone with a recorded override

**Status:** `PROPOSED` · **Roles:** Warden

**Statement.** An emergency outing is handled by phone with the warden, and any override is recorded with a reason for review.

**Acceptance criteria.**
1. Given an emergency, then an override can be recorded only with a reason.
2. Given an override, then it appears in the audit history.

**Dependencies:** [FR-ADM-016](#fr-adm-016--key-decisions-keep-an-audit-history)

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (OUTING PASS 9)

**Note.** Emergency authorities are an open decision.

#### FR-OUT-022 · Guardian video consent, retention and access

**Status:** `SRM APPROVAL REQUIRED` · **Roles:** Guardian, Warden

**Statement.** Recording a guardian's face and voice needs SRM approval, written consent on first use, a written retention period and access limited to the warden role with an audit log; the draft retention is in the guardian spec.

**Acceptance criteria.**
1. Given first use, then the consent page is shown before recording.
2. Given retention ends, then only the transcript and a fingerprint remain.
3. Given any access to a video, then it is limited to the warden role and logged.

**Dependencies:** [FR-OUT-006](#fr-out-006--accept-starts-a-four-to-ten-second-live-video-with-a-phrase-and-fresh-code)

**Source:** [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md) (Privacy and policy (OWNER items)); [`design/audit/design_intent.md`](../design/audit/design_intent.md) (GUARDIAN VIDEO APPROVAL: Privacy and retention)

#### FR-OUT-023 · Speech recognition accuracy is measured before relying on it

**Status:** `VALIDATION REQUIRED` · **Roles:** Guardian, Warden

**Statement.** Speech-to-text accuracy for English, Tamil and Hindi is measured before Video, auto-checked is relied on, and a verification fallback policy is decided.

**Acceptance criteria.**
1. Given an evaluation on representative recordings, then the result is recorded before the auto-check is trusted.
2. Given insufficient accuracy, then the warden must watch the video (Please watch).

**Dependencies:** [FR-OUT-007](#fr-out-007--the-server-checks-the-spoken-phrase-and-code)

**Source:** [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md) (Privacy and policy: Speech-to-text accuracy for Indian languages must be measured)

#### FR-OUT-024 · Pilot mode: digital outings for the authorized pilot cohort

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** In the initial institutionally authorized outing pilot, digital outings are available to every student in the authorized pilot cohort; participation and reliability thresholds are not enforced in this phase, and guardian approval and warden approval remain mandatory.

**Acceptance criteria.**
1. Given a student in the authorized pilot cohort, then Outings is available regardless of participation or reliability.
2. Given a student outside the cohort, then Outings is not available and the existing hostel outing approval procedure is the only route.
3. Given the pilot bypass, then it is an explicit configuration limited to the authorized cohort and cannot apply to students outside it.
4. Given any pilot outing, then guardian approval and warden approval are still required and no timeout approves it (FR-OUT-002, FR-OUT-003).
5. Given the pilot, then live deployment still requires SRM authorization (FR-OUT-027).

**Dependencies:** [FR-OUT-002](#fr-out-002--the-outing-sequence-is-fixed), [FR-OUT-003](#fr-out-003--no-timeout-ever-grants-permission), [FR-OUT-027](#fr-out-027--deploying-digital-outings-depends-on-srm), [FR-OUT-028](#fr-out-028--post-pilot-eligibility-needs-participation-and-reliability)

**Source:** owner decision in task prompt; [`README.md`](../README.md) (Digital outings)

**Note.** Pilot mode only; post-pilot mode is FR-OUT-028 to FR-OUT-030. The eligibility engine and the pilot-bypass configuration belong to the 13 December 2026 integrated feature-completeness target; real deployment stays gated on SRM authorization.

#### FR-OUT-025 · Outing deadline rules need institutional approval

**Status:** `SRM APPROVAL REQUIRED` · **Roles:** Guardian, Warden, Student

**Statement.** The weekday and weekend deadlines for the guardian and the warden are drafts that SRM must approve before use.

**Acceptance criteria.**
1. Given the draft tables in the source, then none is treated as approved.
2. Given an approved rule, then it is configurable and recorded with its source.

**Dependencies:** [FR-OUT-001](#fr-out-001--students-request-a-digital-outing)

**Source:** [`design/audit/design_intent.md`](../design/audit/design_intent.md) (OUTING PASS: Weekend policy (draft); WEEKDAY RULE (draft))

#### FR-OUT-026 · The guardian contact source is verified

**Status:** `SRM APPROVAL REQUIRED` · **Roles:** Guardian

**Statement.** A guardian is contacted only through a contact verified from an SRM source, and guardian video languages are English, Tamil and Hindi first, subject to approval.

**Acceptance criteria.**
1. Given a request, then the guardian number comes from a verified source.
2. Given an unverified number, then no link is sent.

**Dependencies:** [FR-OUT-004](#fr-out-004--the-guardian-opens-the-request-and-reviews-the-details)

**Source:** [`design/audit/MASTER_CONTEXT.md`](../design/audit/MASTER_CONTEXT.md) (Outing Pass module: Owner decisions open); [`design/reference/guardian_2026-10/data/guardian_video_spec.md`](../design/reference/guardian_2026-10/data/guardian_video_spec.md) (Privacy and policy)

#### FR-OUT-027 · Deploying digital outings depends on SRM

**Status:** `SRM APPROVAL REQUIRED` · **Roles:** Student, Guardian, Warden, Gate

**Statement.** Digital outings are deployed only with SRM authorization (including the authorized pilot cohort), privacy consent, an approved evidence retention rule and a verified guardian contact source.

**Acceptance criteria.**
1. Given any of the four is missing, then digital outings are not activated for students.
2. Given all four are in place, then activation is a recorded Admin action.

**Dependencies:** [FR-OUT-022](#fr-out-022--guardian-video-consent-retention-and-access), [FR-OUT-024](#fr-out-024--pilot-mode-digital-outings-for-the-authorized-pilot-cohort), [FR-OUT-026](#fr-out-026--the-guardian-contact-source-is-verified)

**Source:** owner decision in task prompt

#### FR-OUT-028 · Post-pilot eligibility needs participation and reliability

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** After pilot validation, a student is eligible for digital outings only if both (1) participation and (2) reliability are met: participation is consistently submitting a definite I'm in or Skip before the cutoff; reliability is those definite responses matching actual meal behaviour where the verification evidence is trustworthy.

**Acceptance criteria.**
1. Given the post-pilot phase, then eligibility requires both participation and reliability; neither alone is enough.
2. Given I'm in and Skip, then they count equally toward participation, and Not sure and No response are not definite responses for participation scoring.
3. Given eligibility scoring, then no answer is favoured and students are never pushed to answer I'm in unnecessarily (FR-RWD-005).
4. Given a missing QR scan, then it is not proof of absence, and a scanner failure never lowers a student's reliability.
5. Given insufficient valid historical evidence, then no reliability threshold is enforced.
6. Given a student who does not qualify, then the existing hostel outing approval procedure remains available.

**Dependencies:** [FR-OUT-024](#fr-out-024--pilot-mode-digital-outings-for-the-authorized-pilot-cohort), [FR-MEAL-002](#fr-meal-002--a-meal-response-is-im-in-skip-not-sure-or-no-response), [FR-RWD-003](#fr-rwd-003--accuracy-bonus-requires-reliably-verified-behaviour), [FR-RWD-005](#fr-rwd-005--answers-are-never-pushed-and-corrections-are-allowed), [FR-ATT-007](#fr-att-007--an-offline-or-unverifiable-scan-is-never-shown-as-success)

**Source:** owner decision in task prompt

**Note.** Post-pilot mode. The eligibility engine belongs to the 13 December 2026 integrated feature-completeness target. Resolves the structure of open decision P3; the numeric items remain open (FR-OUT-029).

#### FR-OUT-029 · Eligibility thresholds and evaluation need SRM approval

**Status:** `SRM APPROVAL REQUIRED` · **Roles:** Student, Admin

**Statement.** Eligibility thresholds are configurable, and the evaluation period, the minimum sample size, the exceptions and the thresholds require SRM approval before enforcement; no value is set in this document.

**Acceptance criteria.**
1. Given thresholds, then they are configuration and can be changed without a release.
2. Given no SRM-approved values, then no eligibility threshold is enforced.
3. Given approved values, then they are recorded with their source.

**Dependencies:** [FR-OUT-028](#fr-out-028--post-pilot-eligibility-needs-participation-and-reliability)

**Source:** owner decision in task prompt

**Note.** Open decision P33.

#### FR-OUT-030 · Students can see their outing eligibility and request a correction

**Status:** `CONFIRMED` · **Roles:** Student

**Statement.** Students can see their eligibility status and request a correction, and students who do not qualify keep the existing hostel outing approval procedure.

**Acceptance criteria.**
1. Given a student, then their eligibility status (pilot access, eligible or not eligible) and the reason are visible to them.
2. Given a student disputes the status, then they can request a correction, and the request and its outcome are recorded in an audit trail.
3. Given a student who is not eligible, then the existing hostel outing approval procedure is still available.

**Dependencies:** [FR-OUT-028](#fr-out-028--post-pilot-eligibility-needs-participation-and-reliability), [FR-RWD-006](#fr-rwd-006--scanner-failures-have-a-correction-process)

**Source:** owner decision in task prompt

**Note.** Not drawn in Figma. Who reviews a correction request is not decided.

### 7.14 AI and intelligence (`FR-AI`)

Principles and evaluation, not implementation.

#### FR-AI-001 · AI is advisory and core dining works without it

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** AI is advisory unless a specific low-risk operation is explicitly approved, and every core dining workflow keeps working when AI is unavailable.

**Acceptance criteria.**
1. Given the intelligence service is down, then intentions, headcount, entry, kitchen, supervisor and outing flows still work.
2. Given an AI output, then it is shown as a suggestion and a person decides.

**Dependencies:** none

**Source:** owner decision in task prompt; [`docs/backend/BACKEND_PROPOSAL.md`](../docs/backend/BACKEND_PROPOSAL.md) (Reliability principles 1)

#### FR-AI-002 · AI advises and routes; it never makes sensitive decisions

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** An AI model never independently approves or sends a headcount, resolves a safety incident, closes a corrective action, rejects a complaint, declares food safe, decides an outing, or makes a publication decision on its own; it may only advise or route to human moderation. Automatic publication by an approved deterministic policy is allowed and is not an AI decision.

**Acceptance criteria.**
1. Given any listed action, then it is taken by an authorized person or, for publication of eligible non-urgent reports, by the approved deterministic policy, and the actor or the policy version is recorded.
2. Given an AI model output, then it is labelled as a suggestion and can only advise or route a report to human moderation.
3. Given an eligible report is published by the deterministic policy (FR-FB-005), then the record names the policy, not a model, as the decision-maker.
4. Given a safety-related report, then no AI model decides whether it is published, closed or declared safe.

**Dependencies:** [FR-AI-001](#fr-ai-001--ai-is-advisory-and-core-dining-works-without-it)

**Source:** owner decision in task prompt

#### FR-AI-003 · Forecasting starts from a statistical baseline

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Forecasting starts from a statistical baseline, any machine-learning model is compared against it on unseen data with time-based splits, and no model is called production-ready until validated.

**Acceptance criteria.**
1. Given a candidate model, then its result is compared with the baseline on later, unseen data.
2. Given no validation, then the model is not used in a decision.
3. Given a result, then it is recorded with its data period and method.

**Dependencies:** [FR-HC-001](#fr-hc-001--the-forecast-accounts-for-every-response-category)

**Source:** owner decision in task prompt

#### FR-AI-004 · Only features available at the prediction time are used

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** A prediction uses only information available at the time it is made.

**Acceptance criteria.**
1. Given a prediction timestamp, then no feature from after it is used.
2. Given an evaluation, then leakage checks are recorded.

**Dependencies:** [FR-AI-003](#fr-ai-003--forecasting-starts-from-a-statistical-baseline)

**Source:** owner decision in task prompt

#### FR-AI-005 · Forecast signals are evaluated, not assumed useful

**Status:** `VALIDATION REQUIRED` · **Roles:** Admin

**Statement.** Each candidate signal (historical attendance, individual and aggregate arrival patterns, same-day breakfast-to-lunch relationships, class timings, academic calendar and exams, holidays and events, menu popularity) is evaluated on unseen data before it is used.

**Acceptance criteria.**
1. Given a signal, then its contribution is evaluated on unseen data with time-based splits.
2. Given no evidence of benefit, then the signal is not used.

**Dependencies:** [FR-AI-003](#fr-ai-003--forecasting-starts-from-a-statistical-baseline)

**Source:** owner decision in task prompt

#### FR-AI-006 · Attendance prediction and arrival-time prediction are separate

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Attendance prediction and arrival-time prediction are separate tasks with separate evaluation.

**Acceptance criteria.**
1. Given the two tasks, then each has its own target, data and evaluation.
2. Given a result, then it is never reported as covering the other task.

**Dependencies:** [FR-AI-003](#fr-ai-003--forecasting-starts-from-a-statistical-baseline)

**Source:** owner decision in task prompt

#### FR-AI-007 · Uncertainty is shown and no result is fabricated

**Status:** `CONFIRMED` · **Roles:** Student, Admin

**Statement.** Predictions show uncertainty, freshness and data limits, and no prediction, accuracy or improvement is fabricated.

**Acceptance criteria.**
1. Given a prediction, then its freshness and confidence are shown.
2. Given insufficient data, then an honest state is shown instead of a number.
3. Given an AI-related screen, then it does not imply a model exists unless one has been built.

**Dependencies:** [FR-CRD-002](#fr-crd-002--honest-insufficient-data-states)

**Source:** owner decision in task prompt

#### FR-AI-008 · A language model is optional and added only on evidence

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** A small or large language model is added to feedback handling only if testing shows useful administrative value, and then it only advises or routes to human moderation.

**Acceptance criteria.**
1. Given a proposal, then testing that shows useful administrative value is recorded first.
2. Given the model is added, then it never takes the decisions in FR-AI-002 and may only advise or route to human moderation.

**Dependencies:** [FR-AI-002](#fr-ai-002--ai-advises-and-routes-it-never-makes-sensitive-decisions)

**Source:** owner decision in task prompt

**Note.** The root README was aligned with this decision (Conflicts C-2).

#### FR-AI-009 · Waste analysis shows association, not causation

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** Waste and shortage analysis compares forecast with actual and repeated patterns, and shows reasons as Sure, Probably or Can't tell without implying cause.

**Acceptance criteria.**
1. Given an analysis, then correlation is not presented as causation.
2. Given weak evidence, then the tag is Probably or Can't tell.

**Dependencies:** [FR-ADM-006](#fr-adm-006--results-explain-waste-and-shortages-in-plain-reasons)

**Source:** owner decision in task prompt; [`design/reference/admin_redesign_2026-10/data/admin_sample_data.md`](../design/reference/admin_redesign_2026-10/data/admin_sample_data.md) (Results)

#### FR-AI-010 · No accuracy claim without a recorded evaluation

**Status:** `CONFIRMED` · **Roles:** Admin

**Statement.** No accuracy, waste-reduction or improvement figure is stated unless a recorded evaluation supports it.

**Acceptance criteria.**
1. Given a figure in a document or screen, then it links to its evaluation.
2. Given no evaluation, then the figure is marked sample or removed.

**Dependencies:** [FR-AI-003](#fr-ai-003--forecasting-starts-from-a-statistical-baseline)

**Source:** owner decision in task prompt; [`README.md`](../README.md) (AI in MealLoop)

### 7.15 Vendor account workflow (`FR-VEN`)

The vendor is a MealLoop user with a restricted account. It is not an external system and there is no direct vendor API. These requirements are confirmed product direction; the screens do not exist in Figma yet, and several rules (a mandatory acknowledgment deadline, escalation, the fallback when the vendor cannot reach MealLoop, and whether an update needs a new acknowledgment) are OPEN in [`OPEN_DECISIONS.md`](OPEN_DECISIONS.md).

#### FR-VEN-001 · The vendor signs in to a restricted MealLoop account

**Status:** `CONFIRMED` · **Roles:** Vendor

**Statement.** The vendor signs in to its own individual MealLoop-managed account (FR-ID-002), assigned to specific messes. The vendor is a MealLoop user, not an external API integration.

**Acceptance criteria.**
1. Given a vendor account assigned to a mess, when the vendor signs in, then it reaches only the vendor views for that mess.
2. Given a mess the vendor account is not explicitly assigned to, then nothing about that mess is visible.
3. Given the vendor account is deactivated, then protected operations are refused (FR-ID-003).
4. Given the requirements and API, then there is no direct vendor API integration.

**Dependencies:** [FR-ID-002](#fr-id-002--other-internal-users-have-individual-mealloop-managed-accounts), [FR-ID-003](#fr-id-003--super-admin-manages-accounts-and-roles), [FR-ATT-015](#fr-att-015--production-staff-authentication-and-authorization)

**Source:** owner decision in the C1 review task prompt (vendor architecture)

**Note.** Vendor sign-in screens are not in Figma (docs/SCREEN_INVENTORY.md, Needs design). Who holds the account at the vendor and how many users it has are OPEN (vendor agreement).

#### FR-VEN-002 · The vendor sees the approved headcount for its assigned mess and authorized updates

**Status:** `CONFIRMED` · **Roles:** Vendor, Admin

**Statement.** After the Food Head approves and publishes a headcount, the vendor sees the approved headcount for its assigned mess and any later authorized update, and nothing else.

**Acceptance criteria.**
1. Given the Food Head has published the approved headcount for a meal, then the vendor sees that value for the assigned mess.
2. Given a headcount that is a forecast or is not approved or not published, then the vendor does not see it.
3. Given the vendor view, then it shows no individual student intention or identity and no dish quantity.
4. Given the Food Head changes the headcount after publishing, then the vendor sees the authorized update (FR-VEN-004).

**Dependencies:** [FR-HC-004](#fr-hc-004--admin-approves-or-adjusts-the-headcount-with-a-reason), [FR-HC-006](#fr-hc-006--the-vendor-receives-a-headcount-only), [FR-VEN-001](#fr-ven-001--the-vendor-signs-in-to-a-restricted-mealloop-account)

**Source:** owner decision in the C1 review task prompt (vendor architecture)

#### FR-VEN-003 · The vendor acknowledges receipt and an acknowledgment is never fabricated

**Status:** `CONFIRMED` · **Roles:** Vendor, Admin

**Statement.** The vendor acknowledges receipt of the published headcount. MealLoop stores the publication and acknowledgment history. Publishing a headcount is never the same as acknowledgment, and a vendor acknowledgment is never fabricated.

**Acceptance criteria.**
1. Given the vendor acknowledges, then the acknowledgment is recorded with the vendor account as actor and the time.
2. Given the vendor has not acknowledged, then the interface shows pending acknowledgment to the Food Head and never shows replied or agreed.
3. Given a headcount was published, then the history shows the publication, its actor and time separately from any acknowledgment.
4. Given the history, then entries cannot be edited or deleted (FR-ADM-016).

**Dependencies:** [FR-VEN-002](#fr-ven-002--the-vendor-sees-the-approved-headcount-for-its-assigned-mess-and-authorized-updates), [FR-HC-007](#fr-hc-007--admin-sees-the-vendor-reply-status), [FR-ADM-016](#fr-adm-016--key-decisions-keep-an-audit-history)

**Source:** owner decision in the C1 review task prompt (vendor architecture)

**Note.** Whether acknowledgment is mandatory before a deadline, the deadline, the escalation recipients and what happens when the vendor cannot reach MealLoop are OPEN (P64, P65).

#### FR-VEN-004 · A later update is shown as an update

**Status:** `CONFIRMED` · **Roles:** Vendor, Admin

**Statement.** When an approved headcount changes after it was published, the vendor sees the change as an update with its time, and the history keeps both values.

**Acceptance criteria.**
1. Given a later authorized change, then the vendor view shows it as an update, not as a replacement without trace.
2. Given the earlier value was acknowledged, then that acknowledgment stays in the history and is not shown as acknowledging the update.
3. Given the update, then the Food Head sees pending acknowledgment until the vendor account acknowledges it.

**Dependencies:** [FR-HC-008](#fr-hc-008--a-change-after-sending-is-recorded-and-offered-to-the-vendor), [FR-VEN-003](#fr-ven-003--the-vendor-acknowledges-receipt-and-an-acknowledgment-is-never-fabricated)

**Source:** owner decision in the C1 review task prompt (vendor architecture)

**Note.** Whether a later update supersedes an earlier acknowledgment and requires a new one is OPEN (P66); the criteria above only keep the history honest and decide nothing about that rule.

#### FR-VEN-005 · The vendor account is restricted to the approved headcount

**Status:** `CONFIRMED` · **Roles:** Vendor

**Statement.** The vendor account can sign in, view the approved headcount for its assigned mess, view authorized updates and acknowledge receipt, and can do nothing else.

**Acceptance criteria.**
1. Given the vendor account, then it cannot approve or alter a headcount.
2. Given the vendor account, then it cannot see individual student intentions or identities, or guardian evidence.
3. Given the vendor account, then it cannot access another mess without an explicit assignment.
4. Given the vendor account, then it cannot manage rewards, outings, attendance corrections or accounts.
5. Given the vendor account, then it cannot enter production quantities, ingredients, procurement or recipes through this workflow.

**Dependencies:** [FR-VEN-001](#fr-ven-001--the-vendor-signs-in-to-a-restricted-mealloop-account), [FR-HC-004](#fr-hc-004--admin-approves-or-adjusts-the-headcount-with-a-reason), [FR-ATT-015](#fr-att-015--production-staff-authentication-and-authorization)

**Source:** owner decision in the C1 review task prompt (vendor architecture)

### 7.16 Accounts, roles and identity (`FR-ID`)

MealLoop uses two internal authentication arrangements: SRM SSO for Students and Super Admins (feasibility unverified), and individual MealLoop-managed accounts (email and password) for all other internal users. These requirements are confirmed product direction except where marked. The password policy, multi-factor authentication, lockout and recovery rules, session length, who may provision which roles and the detailed Super Admin permission matrix are OPEN ([`OPEN_DECISIONS.md`](OPEN_DECISIONS.md), P60 to P63).

#### FR-ID-001 · Students and Super Admins sign in through SRM SSO

**Status:** `SRM APPROVAL REQUIRED` · **Roles:** Student, Super Admin

**Statement.** Students and Super Admins are intended to authenticate through SRM's official SSO. This is a required architectural direction, but access to SRM's identity service must be confirmed with SRM IT, so SRM SSO feasibility is unverified. No OAuth, OIDC or SAML endpoint, approved client registration, user attributes or administrative API is assumed to exist, and no fallback identity scheme is approved.

**Acceptance criteria.**
1. Given SRM confirms access, when a Student or Super Admin signs in, then they authenticate through SRM SSO.
2. Given SRM SSO feasibility is unverified, then no real authentication through it is claimed as built.
3. Given any alternative sign-in for the pilot, then it is not described as approved until the owner and SRM approve it.

**Dependencies:** [FR-STU-001](#fr-stu-001--students-sign-in-with-their-srm-identity), [FR-ATT-015](#fr-att-015--production-staff-authentication-and-authorization)

**Source:** owner decision in the C1 review task prompt (identity boundaries)

**Note.** Open questions for SRM IT: the protocol, client registration, available attributes, a test environment, the timeline, and how pilot access works if SSO is not ready (P60).

#### FR-ID-002 · Other internal users have individual MealLoop-managed accounts

**Status:** `CONFIRMED` · **Roles:** Admin, Supervisor, Kitchen Staff, Door Scanner Staff, Pass Desk Staff, Warden, Gate Security, Vendor

**Statement.** Food Head / Admin, Supervisor, Kitchen Staff, Door Scanner Staff, Pass Desk Staff, Warden, Gate Security and the Vendor each authenticate with an individual MealLoop-managed account using email and password.

**Acceptance criteria.**
1. Given any of these users, then they have their own account and no shared credential is used in production.
2. Given a production action, then it is attributable to that individual account (FR-ATT-015).
3. Given the shared four-digit role password of the prototype, then it is not accepted as a production method (FR-ATT-013).

**Dependencies:** [FR-ATT-015](#fr-att-015--production-staff-authentication-and-authorization), [FR-ATT-013](#fr-att-013--prototype-staff-entry-uses-a-shared-role-password)

**Source:** owner decision in the C1 review task prompt (identity boundaries)

**Note.** OPEN: password policy, multi-factor authentication, lockout and recovery rules, session length, and who may provision which roles (P61, P62).

#### FR-ID-003 · Super Admin manages accounts and roles

**Status:** `CONFIRMED` · **Roles:** Super Admin

**Statement.** Super Admin is a separate role that manages system-level identity and institutional configuration: account provisioning, role assignment, scope changes, account deactivation and password-reset initiation.

**Acceptance criteria.**
1. Given Super Admin provisions an account, assigns a role or changes scope, then the action is recorded with actor, time and reason (FR-ADM-016).
2. Given Super Admin deactivates an account, then protected operations by that account are refused from then on.
3. Given Super Admin initiates a password reset, then the user completes it and no password is shown to Super Admin (FR-ID-004).

**Dependencies:** [FR-ID-002](#fr-id-002--other-internal-users-have-individual-mealloop-managed-accounts), [FR-ADM-016](#fr-adm-016--key-decisions-keep-an-audit-history), [FR-ID-004](#fr-id-004--no-one-can-read-a-password)

**Source:** owner decision in the C1 review task prompt (identity boundaries)

**Note.** The detailed Super Admin permission matrix is OPEN and not reviewed; no broader permission is implied (P62).

#### FR-ID-004 · No one can read a password

**Status:** `CONFIRMED` · **Roles:** Super Admin, all MealLoop-account users

**Statement.** Passwords are never stored or displayed in plaintext. Super Admin cannot read any user's password. Users establish or reset their own credentials through a secure process.

**Acceptance criteria.**
1. Given any screen, API response, log or export, then no password is shown in plaintext.
2. Given Super Admin, then there is no way to read a user's password.
3. Given a new account or a reset, then the user sets their own password through the secure process (FR-ID-006).

**Dependencies:** [FR-ID-003](#fr-id-003--super-admin-manages-accounts-and-roles), [FR-ID-006](#fr-id-006--invitation-and-password-reset-messages-use-an-external-provider)

**Source:** owner decision in the C1 review task prompt (identity boundaries)

**Note.** The credential storage mechanism is decided in technical design (NFR-SEC-010); this requirement states the outcome only.

#### FR-ID-005 · Food Head / Admin does not have Super Admin privileges

**Status:** `CONFIRMED` · **Roles:** Admin, Super Admin

**Statement.** Food Head / Admin continues to manage operational mess workflows (headcount approval and vendor handoff, menus, reports) and does not have Super Admin privileges. Super Admin and Food Head / Admin are separate roles.

**Acceptance criteria.**
1. Given the Food Head / Admin role, then it cannot provision accounts, assign roles, change scope, deactivate accounts or initiate password resets.
2. Given the role and permission matrix, then Super Admin and Admin are separate columns.

**Dependencies:** [FR-ID-003](#fr-id-003--super-admin-manages-accounts-and-roles), [FR-ADM-015](#fr-adm-015--staff-access-is-managed-by-admin)

**Source:** owner decision in the C1 review task prompt (identity boundaries)

#### FR-ID-006 · Invitation and password-reset messages use an external provider

**Status:** `PROPOSED` · **Roles:** Super Admin, all MealLoop-account users

**Statement.** Account invitations and password-reset messages are delivered through an external email or messaging provider. The provider is undecided and its availability is unverified.

**Acceptance criteria.**
1. Given an invitation or reset, then the user receives a message that lets them set their own password.
2. Given delivery fails, then the failure is recorded and the account state is unchanged; a delivery result is never treated as the user completing the reset.
3. Given no provider is chosen, then no delivery is claimed as built.

**Dependencies:** [FR-ID-004](#fr-id-004--no-one-can-read-a-password)

**Source:** owner decision in the C1 review task prompt (identity boundaries)

**Note.** External integration feasibility is not verified; the provider choice is OPEN (P63).

## 8. AI and forecasting requirements

AI is advisory. It supports predictions, feedback analysis and decisions, never replaces a person's decision, and must not be needed for any core dining action. The detailed, testable requirements are the `FR-AI-*` entries above; this section states the principles and the evaluation discipline.

**Principles**

- Core dining (intentions, headcount, entry, kitchen, supervisor, outings) works when AI is down ([FR-AI-001](#fr-ai-001--ai-is-advisory-and-core-dining-works-without-it)).
- An AI model never independently approves or sends a headcount, resolves a safety incident, closes a corrective action, rejects a complaint, declares food safe, decides an outing or makes a publication decision on its own; it may only advise or route to human moderation. Automatic publication of an eligible report by an approved deterministic policy is allowed and is not an AI decision ([FR-AI-002](#fr-ai-002--ai-advises-and-routes-it-never-makes-sensitive-decisions)).
- No prediction, accuracy figure or improvement is stated without a recorded evaluation ([FR-AI-010](#fr-ai-010--no-accuracy-claim-without-a-recorded-evaluation)). An AI-related screen in the design does not mean the AI exists.

**Evaluation discipline (forecasting)**

1. Start from a statistical baseline; compare any machine-learning model against it ([FR-AI-003](#fr-ai-003--forecasting-starts-from-a-statistical-baseline)).
2. Use only features available at the prediction timestamp ([FR-AI-004](#fr-ai-004--only-features-available-at-the-prediction-time-are-used)).
3. Evaluate each candidate signal on unseen data with time-based splits: historical attendance, individual and aggregate arrival patterns, same-day breakfast-to-lunch relationships, class timings, academic calendar and exams, holidays and events, menu popularity. None is assumed useful ([FR-AI-005](#fr-ai-005--forecast-signals-are-evaluated-not-assumed-useful), VALIDATION REQUIRED).
4. Treat attendance prediction and arrival-time prediction as separate tasks ([FR-AI-006](#fr-ai-006--attendance-prediction-and-arrival-time-prediction-are-separate)).
5. Do not call an unvalidated model production-ready.

**Where AI may help** (all optional, all advisory): demand forecasting; arrival-pattern estimates for crowd guidance; feedback grouping and duplicate detection (rules and semantic similarity first; a language model only if testing shows useful administrative value, [FR-AI-008](#fr-ai-008--a-language-model-is-optional-and-added-only-on-evidence)); waste and shortage analysis ([FR-AI-009](#fr-ai-009--waste-analysis-shows-association-not-causation)); menu extraction with human verification ([FR-MENU-001](#fr-menu-001--menu-upload-reads-a-photo-and-flags-uncertain-words)).

## 9. Privacy, consent and security requirements

These are requirement **inputs** to be detailed later (privacy and security tasks). They are topics with a required principle, not yet testable requirements, so they carry a status label but no acceptance criteria here.

| Topic | Required in principle | Related requirements | Status |
|---|---|---|---|
| Student identity | Students sign in with their SRM identity (SRM SSO feasibility unverified); staff see masked student IDs only; the vendor view carries no student-level data | FR-STU-001, FR-ATT-003, FR-VEN-005 | SRM APPROVAL REQUIRED |
| Staff access, prototype | A shared four-digit password per staff role (three tries, then locked) is approved demo behaviour for the Figma prototype; it is not an approved production security architecture | FR-ATT-013 | CONFIRMED (demo behaviour) |
| Identity, two arrangements | Students and Super Admins authenticate through SRM SSO (feasibility unverified; no endpoint, protocol, attributes or fallback is assumed). All other internal users, including the vendor, use individual MealLoop-managed accounts with email and password | FR-ID-001, FR-ID-002, FR-STU-001 | SRM APPROVAL REQUIRED (SRM SSO), CONFIRMED (MealLoop accounts) |
| Credentials | Passwords are never stored or displayed in plaintext; Super Admin cannot read any password; users set and reset their own through a secure process; invitations and resets need an external email provider (undecided). Password policy, multi-factor authentication, lockout and recovery rules and session length are OPEN | FR-ID-004, FR-ID-006 | CONFIRMED (outcome), PROPOSED (provider) |
| Staff access, production | Verified staff identity; an assigned role with mess or block scope; actions attributable to the actor; secure sessions with revocation; auditable approvals, changes, scanning overrides and SOS actions. The mechanism is decided in the NFR, architecture and security reviews | FR-ATT-015, FR-ADM-015, FR-ADM-016 | PROPOSED |
| Guardian video | Recorded only with SRM approval and written consent; face and voice are sensitive; access limited to the warden role and logged | FR-OUT-022 | SRM APPROVAL REQUIRED |
| Evidence retention | A written retention period for guardian evidence (draft in the guardian spec); a retention rule for feedback, skipping reasons and report photos | FR-OUT-022, FR-FB-014 | SRM APPROVAL REQUIRED |
| Student-private data | The private spending tracker never feeds admin data (the calorie and nutrition trackers were archived in the student redesign and are not requirements) | FR-FB-013, FR-ADM-017 | CONFIRMED |
| Feedback privacy | Feedback is aggregate; no names in Community or Admin views | FR-FB-006, FR-FB-013 | CONFIRMED |
| Community publication checks | Eligible non-urgent reports are published automatically only after the configured privacy, safety, abuse and spam checks; flagged or uncertain reports are held for Admin moderation; Admin can hide published content; no student identity is exposed publicly. The exact check rules are details for the API and security design | FR-FB-005, FR-FB-006 | CONFIRMED (policy); rule details to follow |
| Location and photos | SOS proof uses a live photo with place and time; handling and retention of photos is undecided | FR-FB-003 | SRM APPROVAL REQUIRED |
| Audit | Key actions record who, when and why and cannot be edited | FR-ADM-016, FR-HC-004, FR-KIT-012 | CONFIRMED |
| Demo data | Seeded data is labelled, kept apart from pilot data, never presented as measured results, and never included in production analytics | all | CONFIRMED |
| Consent for cameras (Phase 2) | A privacy and institutional review before any return-station camera | FR-KIT-018 | PROPOSED |

## 10. Non-functional requirement inputs

Topics only. **No numbers are given here;** they are set in the non-functional requirements task. Each row is a question that task must answer. The draft non-functional requirements are in [`NFR.md`](NFR.md) (draft, owner review pending).

| Topic | What the NFR task must quantify or define | Related requirements |
|---|---|---|
| Availability | How available the entry, meal-state and kitchen paths must be during a meal service, and how outages are communicated | FR-ATT-002, FR-SUP-001 |
| Offline behaviour | The pilot rule for scanning and pass checks is never record (NFR-REL-005, owner to confirm); a later offline queue is deferred; what is cached for reading | FR-ATT-007, FR-PASS-006 |
| Performance | Responsiveness of scan-to-confirmation, live counts and screen loads; freshness of live counts before they are marked stale | FR-ATT-002, FR-KIT-002 |
| Data integrity | Idempotency and duplicate rejection guarantees; consistency of the shared meal state across roles | FR-ATT-005, FR-SUP-001 |
| Privacy | Handling of masked IDs, guardian video, report photos and location | section 9 |
| Retention | Retention and deletion periods per data type; backup retention | FR-OUT-022, FR-FB-014 |
| Failure behaviour | Behaviour when push, AI, outings or the backend fail (core dining continues; notifications retry from durable records) | FR-AI-001, FR-HC-005 |
| Security | Authentication, authorization per role and mess, secret handling, audit | section 9 |
| Accessibility and language | Dynamic type, contrast, tap-target and language support (English, Tamil and Hindi first for guardian video) | FR-STU-006, FR-OUT-026 |
| Observability | What is logged and monitored, without exposing personal data | all |
| Capacity | Concurrent users and entries at peak, for one mess and for all messes | FR-ATT-002 |
| Device and network | Supported iOS versions, devices and the network conditions at the mess | all |

## 11. Dependencies, assumptions and risks

### Dependencies

| # | Dependency | Needed for |
|---|---|---|
| D1 | SRM authorization of the pilot at Meenakshi Girls' Mess | Phase 1 |
| D2 | SRM approval of privacy, consent and retention for guardian evidence | Digital outings |
| D3 | A verified guardian contact source | Digital outings |
| D4 | SRM approval of the participation-credit and accuracy-bonus amounts, the reward budget, reward values and redemption, and of the incentive scheme | Credits and rewards |
| D5 | Vendor agreement to use a restricted MealLoop account, to acknowledge a published headcount, and to an agreed fallback when it cannot reach MealLoop | Headcount |
| D6 | Staff and institutional approval to measure unserved food for a baseline | Baseline and success metrics |
| D7 | A working backend and database | Everything beyond the design demo |
| D8 | Recorded evidence of the foundation build and its unit-test result (the owner reports a build and launch on the owner's Mac; `docs/FOUNDATION_VERIFICATION.md` does not exist yet) | Implementation |
| D9 | SRM authorization of the outing pilot cohort, and later of the eligibility thresholds, evaluation period, minimum sample size and exceptions | Digital outings |
| D10 | SRM IT confirmation of access to SRM SSO (protocol, client registration, attributes, test environment, timeline); SRM confirmation of the guardian-contact authority; an email or notification provider for invitations and resets | Identity, guardian access, account lifecycle |

### Assumptions (not facts)

| # | Assumption |
|---|---|
| A1 | The pilot mess has the connectivity and devices that door, desk and kitchen staff need; this has not been surveyed. |
| A2 | Enough students will answer for the forecast to be useful; participation is unknown. |
| A3 | The vendor will accept an approved headcount as the only input and will use a restricted MealLoop account to see it and acknowledge it. |
| A4 | The institution will allow QR entry scanning at a common entrance. |
| A5 | The design's sample data is a fair picture of the real flows; real volumes are unknown. |

### Risks

| # | Risk | Mitigation direction |
|---|---|---|
| R1 | The 10 November 2026 target (every approved, active screen in SwiftUI) is large against the time left: [`SCREEN_INVENTORY.md`](SCREEN_INVENTORY.md) counts 420 active screens and states (149 distinct base screens), 20 rows needing review and 89 archived rows, and 12 weekdays from 23 October to 10 November, which its effort note puts at 8.8 states (3.1 base screens) per person per working day with four people, before review and fixes. The milestone is not weakened. | Record the risk; the owner sets the scope; proposed priority P0 first. |
| R2 | The foundation's unit-test result is not recorded and no build output is in the repository (the owner reports a build and launch on the owner's Mac). | Record the result in `docs/FOUNDATION_VERIFICATION.md`. |
| R3 | SRM approvals (outings, guardian video, rewards) may not arrive in time. | Keep outings and rewards behind approval; do not block dining. |
| R4 | Forecast signals may add little value. | Baseline first; validate each signal; do not assume. |
| R5 | A missing or late waste record weakens the baseline and the results. | Make recording simple; show Not recorded honestly; never treat missing as zero. |
| R6 | Older documents still describe superseded behaviour and could be built by mistake. | The Conflicts table and Superseded notes in the old documents. |
| R7 | Speech recognition for Indian languages may be too weak to auto-check guardian videos. | Measure first; fall back to warden review. |
| R8 | Automatic Community publication could publish something harmful, identifying or abusive if the configured checks are wrong. | Configured checks, a held-for-moderation queue, Admin hide, the urgent bypass (FR-FB-003) and no identity exposure; evaluate in the pilot. |
| R9 | Staff adoption: door, desk and kitchen staff add steps to a busy service. | Keep steps minimal; test on the pilot floor. |
| R10 | Participation credits for Skip and I'm in could be gamed by answering carelessly. | The accuracy bonus and the verification rules are the mitigation; evaluate behaviour in the pilot. |
| R11 | The outing pilot bypass could be misconfigured and reach students outside the authorized cohort. | An explicit cohort-limited configuration with an audit trail (FR-OUT-024). |
| R13 | Added scope: the vendor account workflow, Super Admin and account-management screens, and email and password sign-in are not in Figma, and SRM SSO feasibility is unverified. This adds work to the 10 November and 13 December targets, which are not moved or weakened. | Record the screens as Needs design (not in Figma) in [`SCREEN_INVENTORY.md`](SCREEN_INVENTORY.md); the owner decides their scope and milestone (OPEN_DECISIONS P68); keep the existing message or call handoff as the interim; do not block dining on SSO. |
| R14 | A vendor acknowledgment could be assumed when it is only a published headcount, or fabricated by an interface. | Publishing is never acknowledgment; pending acknowledgment is always visible (FR-VEN-003). |
| R12 | A missing QR scan could be read as absence and unfairly lower credits or outing reliability. | A missing scan is not proof of absence (FR-RWD-003, FR-OUT-028); no threshold is enforced without enough valid evidence. |

## 12. Success metrics and pilot evaluation

**All targets are VALIDATION REQUIRED.** No baseline data exists and none is invented here. Targets are set only after a baseline is measured.

**Baseline.** Establish an initial baseline by measuring unserved food over roughly 7 to 14 days, subject to staff and institutional approval. NGO donation records do not capture total unserved food and must not be presented as if they did.

| Metric | What is compared | Notes |
|---|---|---|
| Unserved food by dish | Leftovers per dish in comparable units (kg, L, pieces separately) | Units never added; Not entered is excluded, not counted as zero |
| Waste per reliably measured diner | Unserved food against Final entries for meals with complete evidence | Appropriate baseline needed; only reliably measured meals |
| Forecast accuracy | Forecast against Final entries | Baseline method first; evaluation on unseen data |
| Shortage incidents | Count and timing of shortage reports and resolutions | Reported by the kitchen; resolved by the Supervisor |
| Intention participation | Share of students giving a definite response before the cutoff | Not Sure and No response reported separately |
| Verified entry coverage | Entries recorded against students who ate, where measurable | Entries confirm entry only |
| Feedback resolution | Issues reaching corrective action completed, and the share with verified improvement | Completed is not the same as verified |

**Evaluation rules.** Compare like with like; state the data period and method; report missing data as missing; mark anything unmeasured as unmeasured; do not report improvement without the follow-up evidence in [FR-FB-012](#fr-fb-012--student-follow-up-verifies-real-improvement). Waste reduction is not claimed until it is measured.

## 13. Delivery milestones

These are targets, not commitments.

| When | Milestone |
|---|---|
| 10 November 2026 | Every approved, active Figma screen represented in functional SwiftUI flows, with coherent navigation and demo data isolated from production |
| 11–13 November 2026 | External Review 3 |
| 13 December 2026 | Target for integrated iOS and backend feature completeness, including the outing eligibility engine and the pilot-bypass configuration (real deployment stays gated on SRM authorization) |
| January 2027 | Stabilization and review |
| 27–29 January 2027 | External Review 4 |
| February–March 2027 | Pilot, where institutionally authorized |
| 8–9 April 2027 | External Review 5 |
| April 2027 | Pilot validation and institutional demonstration |
| 16 April 2027 | App Fair |

**Platform direction (owner approved, 1 November 2026; see [ADR-003](adr/ADR-003-approved-platform-backend-security.md)):** one native iOS application (SwiftUI) with role-aware navigation for all 11 roles, including Guardian; an Android client later (Kotlin, Jetpack Compose) that shares the backend API contracts but not UI code; a Spring Boot (Java) modular monolith with PostgreSQL and private object storage; Spring Security with RS256 JWT access tokens and rotating opaque refresh tokens. The frontend architecture, API contracts, hosting and storage providers are **not** approved ([`FRONTEND_READINESS.md`](architecture/FRONTEND_READINESS.md), [ADR-004](adr/ADR-004-authentication-session-and-delivery-options.md)). The earlier ADR-001, ADR-002 and the files under [`docs/backend/`](backend/BACKEND_PROPOSAL.md) remain unreviewed drafts.

## 14. Open decisions

The full list, each with options and a suggested default, is in [`OPEN_DECISIONS.md`](OPEN_DECISIONS.md), which also has a **Resolved** section and the **Conflicts** table. The decisions that most affect this PRD:

- **Resolved since version 0.1 by owner decisions:** Community publication (automatic after configured checks), the credits and accuracy-bonus direction, and the structure of outing eligibility (pilot mode, then participation and reliability).
- Official SRM outing policy and escalation authority; the authorized outing pilot cohort; the post-pilot eligibility thresholds, evaluation period, minimum sample size and exceptions; the verified guardian contact source.
- Guardian video retention, consent and privacy approval; speech-recognition accuracy; institutional approval of the warden phone-confirmation fallback.
- Resolved since version 0.2 by owner decisions: two authentication arrangements (SRM SSO for Students and Super Admins; MealLoop-managed accounts for the rest), a separate Super Admin role, and the vendor working through a restricted MealLoop account. **SRM SSO feasibility is unverified** (questions for SRM IT in OPEN_DECISIONS P60).
- Open: password policy, multi-factor authentication, lockout and recovery rules, session length; who may provision which roles and the detailed Super Admin permission matrix; the email and notification provider; the design scope and milestone of the vendor and Super Admin screens.
- Open: whether vendor acknowledgment is mandatory before a deadline, the deadline and escalation recipients, the fallback when the vendor cannot reach MealLoop and the authorized fallback process, and whether a later update needs a new acknowledgment.
- Open: notification retry and escalation policy; SOS escalation targets; guardian authentication, and the authorized correction process for guardian contacts.
- Scanner offline behaviour: resolved for the pilot as never record (NFR-REL-005, owner to confirm); a future offline queue is deferred.
- Vendor communication channel: partly resolved. The primary channel is the vendor's MealLoop account; the fallback channel is open.
- The exact participation-credit and accuracy-bonus amounts, the redemption budget and reward values, and institutional approval of the incentive scheme; the reliable absence-verification method and the minimum verification coverage.
- The production staff authentication and authorization mechanism (technical design).
- Pilot data availability and success thresholds; the Community support threshold.
- Whether students answer for Snacks; the meaning of the yellow menu highlight; how long a missed meal's waste can still be recorded.

## 15. Glossary

| Term | Meaning |
|---|---|
| Intention / response | A student's answer for one meal: I'm in, Skip, Not sure, or No response |
| No response | No answer was given. It is its own group and never a Skip |
| Cutoff | Two hours before the meal starts; the last time a response can be set or changed |
| Live forecast | The current estimate of diners, which can still change |
| Cutoff forecast | The forecast as it stood at the cutoff, preserved with its rule version |
| Approved headcount | The headcount Admin approved (or adjusted with a reason) |
| Super Admin | A separate role for account provisioning, role assignment, scope changes, deactivation and password-reset initiation; not the Food Head / Admin role |
| Vendor account | A restricted MealLoop account for the vendor: it sees the approved headcount and authorized updates for its assigned mess and acknowledges receipt |
| Pending acknowledgment | A published headcount that the vendor account has not acknowledged; never shown as replied |
| SRM SSO | SRM's official single sign-on; its availability to MealLoop is unverified |
| Sent to vendor | The approved headcount as sent to the vendor; a headcount only |
| Actual entries | Live count of students who have entered so far; never final |
| Final entries | The count of recorded entries after the Supervisor closes the meal |
| Entry QR | The student's QR; confirms entry only |
| Entered without voting | The separate list of students who entered with no meal response; not a vote |
| Special-meal pass | A pass with a live code and colour for a special meal; separate from outing passes |
| Pass exception / reissue | A request for a new pass, handled in the admin pass-exception flow |
| Unserved food / leftovers | Food left over after the meal, recorded per dish in its own unit |
| Plate waste | One total in kilograms for the whole meal; never per dish |
| None left | A confirmed measurement of zero leftover for a dish |
| Not made | The dish was not cooked for the meal |
| Not entered | Nothing has been recorded yet; never read as zero |
| Recorded | The status of a saved waste report; there is no approval step |
| Shortage | A report that a dish is getting low, almost out or out |
| SOS | The urgent safety workflow; claimable and checkable by staff, closed by the Supervisor |
| Community / Me too | The student-visible issue list and the one-per-student support action |
| Corrective action | What was done about an issue; completing it is not proof that things improved |
| Improvement verified | Evidence from follow-up that the problem actually improved |
| Sure / Probably / Can't tell | The evidence tags on a result reason; never percentages |
| Evidence method | How a guardian's approval was captured: Live video (auto-checked), Please watch, Photo and text, Confirmed by call |
| Deterministic publication policy | A fixed, approved set of rules that publishes an eligible report automatically; it is not an AI decision |
| Participation | Consistently submitting a definite I'm in or Skip before the cutoff |
| Reliability | Definite responses that match actual meal behaviour where the verification evidence is trustworthy |
| Accuracy bonus | An additional credit when a definite answer matches reliably verified behaviour |
| Pilot cohort | The students the institution authorizes for the outing pilot |
| Outing pass | A signed, time-bound pass issued after both approvals |
| Idempotency key | A unique key sent with a write so a repeat returns the original result |
| Demo data | Seeded, labelled sample data that never mixes with real data |
| OCR / vision | Reading a menu photo into text, always with human verification |
| SLM / LLM | Small or large language model; optional and advisory |

## 16. Requirement status legend

| Label | Meaning |
|---|---|
| **CONFIRMED** | Approved product behaviour: stated as approved in the active specifications or by the owner in the task prompt, and not dependent on SRM or a policy number |
| **PROPOSED** | Needs product review before it can be built |
| **SRM APPROVAL REQUIRED** | Depends on a decision or approval from SRM |
| **VALIDATION REQUIRED** | Needs pilot evidence or an evaluation before it can be relied on |
| **CHANGED, OWNER CONFIRMATION REQUIRED** | The task prompt differs from earlier documented behaviour; both are recorded and the owner must choose |

Policy numbers, reward values, thresholds and anything depending on SRM are never CONFIRMED.

In the identity and vendor requirements, **CONFIRMED** means a confirmed product direction, **PROPOSED** means a proposed technical implementation, **SRM APPROVAL REQUIRED** covers SRM and SRM IT dependencies, and an external integration whose feasibility is not verified says so in its statement.
