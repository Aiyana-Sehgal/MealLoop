# MealLoop — Non-Functional Requirements (NFR)
**Version:** 0.3 — Consolidated Review Draft  
**Date:** 24 October 2026  
**Product:** MealLoop  
**Initial deployment:** Meenakshi Girls' Mess, SRMIST Kattankulathur  
**Status:** DRAFT — Owner review pending (not owner-approved)

## Change log

| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-10-23 | Review draft written by the owner and ChatGPT. |
| 0.2 | 2026-10-23 | Two fields (Status and Depends on) replace hybrid statuses; proposed milestone tags and Related PRD requirements on every requirement; Targets still pending table; offline-scan direction recorded as resolving the functional offline decision (owner to confirm); guardian localization added to NFR-ACC-003; NFR-PER-002 marked provisional; new requirements NFR-REL-009 to 011, NFR-PER-005 to 007, NFR-PRI-007, NFR-SEC-009, NFR-OPS-001, NFR-OBS-005 and NFR-SCL-004; undecided architecture items and an acceptance-evidence template; Appendix A of candidate values (not requirements). |
| 0.3 | 2026-10-24 | C1 reconciliation on pull request 3: NFR-SEC-001 and NFR-SEC-002 name the two authentication arrangements, the vendor account scope and the Super Admin role; NFR-PRI-001 states that the vendor view carries no student-level data; NFR-REL-009 adds notification durability criteria; new NFR-SEC-010 for the credential and account lifecycle. NFR-SEC-001 moves from Direction confirmed to SRM approval required because access to SRM SSO is unverified. |

Requirements without an explicit acceptance-criteria list in the 0.1 draft keep their Verification line (and, for NFR-PER-001, its Measurement line) as their only criterion until the owner adds criteria: NFR-PER-001, NFR-PRI-001, NFR-PRI-005, NFR-PRI-006, NFR-OBS-001, NFR-OBS-003, NFR-OBS-004, NFR-ACC-002, NFR-ACC-004, NFR-SCL-001, NFR-SCL-002, NFR-SCL-003, NFR-TST-001, NFR-TST-002, NFR-TST-003, NFR-TST-004, NFR-DEP-002, NFR-DEP-003, NFR-DEP-004, NFR-DEP-005.
## Targets still pending

Every requirement below has no measurable approved target yet. **No value is filled in here.** Owners default to "Unassigned". The milestone tags are proposed (see section 1). The right-hand column of each row is the tag of that requirement.

| NFR ID | What is missing | Owner | Needed by |
|---|---|---|---|
| [NFR-REL-004](#nfr-rel-004--cross-role-synchronization) | The percentile, the test-network specification and the maximum refresh delay (five seconds is provisional) | Unassigned | M2 |
| [NFR-REL-006](#nfr-rel-006--manual-continuity-and-reconciliation) | The SRM-approved manual attendance procedure and the authorized reconcilers | Unassigned | M3 |
| [NFR-PER-001](#nfr-per-001--verified-scanning-latency) | Device specifications, test-network conditions and peak concurrency | Unassigned | M2 |
| [NFR-PER-002](#nfr-per-002--initial-peak-load) | The realistic door peak, burst duration and capacity target; the number of students in the pilot mess | Unassigned | M2 |
| [NFR-PER-004](#nfr-per-004--outage-recovery-objectives) | Availability target, RTO, RPO and backup schedule (no value approved) | Unassigned | M3 |
| [NFR-SEC-005](#nfr-sec-005--encryption-and-secrets) | Detailed encryption and secrets standards | Unassigned | M3 |
| [NFR-SEC-006](#nfr-sec-006--abuse-and-rate-limiting-controls) | Rate and lockout limits | Unassigned | M3 |
| [NFR-PRI-004](#nfr-pri-004--guardian-consent-and-evidence-retention) | Guardian-evidence retention period and consent text | Unassigned | M3 |
| [NFR-PRI-005](#nfr-pri-005--feedback-and-operational-data-retention) | Retention periods per data type | Unassigned | M3 |
| [NFR-OBS-003](#nfr-obs-003--critical-failure-monitoring) | Alert thresholds | Unassigned | M3 |
| [NFR-ACC-002](#nfr-acc-002--readability-and-touch-targets) | The accessibility measurement standard | Unassigned | M1 |
| [NFR-SCL-001](#nfr-scl-001--pilot-first-scalability) | A pilot capacity figure (depends on the pilot mess student count) | Unassigned | M3 |
| [NFR-SCL-003](#nfr-scl-003--expansion-validation) | Pass criteria for the multi-mess load and isolation tests | Unassigned | M3 |
| [NFR-DEP-005](#nfr-dep-005--backup-and-restoration) | Backup schedule and retention | Unassigned | M3 |
| [NFR-REL-009](#nfr-rel-009--sos-delivery-and-fallback) | SOS delivery time | Unassigned | M2 |
| [NFR-REL-010](#nfr-rel-010--server-time-authority) | Permitted clock skew | Unassigned | M2 |
| [NFR-REL-011](#nfr-rel-011--site-connectivity) | Minimum acceptable signal at each position | Unassigned | M3 |
| [NFR-PER-005](#nfr-per-005--intention-and-reminder-burst-load) | Burst size (needs the pilot mess student count) | Unassigned | M3 |
| [NFR-PER-006](#nfr-per-006--guardian-video-on-mobile-web) | Supported mobile-browser list and video size limit | Unassigned | M3 |
| [NFR-PER-007](#nfr-per-007--door-throughput-rehearsal) | Door throughput target (set from the rehearsal) | Unassigned | M3 |
| [NFR-SEC-009](#nfr-sec-009--security-assurance-before-the-pilot) | Scope of the pre-pilot security review | Unassigned | M3 |
| [NFR-OPS-001](#nfr-ops-001--operational-readiness-and-support) | Named support contact, severity classes and owners | Unassigned | M3 |
| [NFR-OBS-005](#nfr-obs-005--scan-coverage-measurement) | Scan-coverage threshold | Unassigned | M3 |
| [NFR-SCL-004](#nfr-scl-004--cost-constraint) | Hosting-cost ceiling | Unassigned | M3 |

Candidate starting points for some of these are in [Appendix A](#appendix-a-candidate-values-for-owner-decision-not-requirements). They are for discussion only.

## 1. Purpose and scope

This document specifies the quality attributes and operational guarantees for MealLoop's student iOS application, mess staff workflows, administrator interfaces, guardian web experience, backend services, and outing-pass system.

It consolidates decisions made in NFR Rounds 1–3 and complements the functional PRD.

### Status definitions

- **Direction confirmed:** The owner has selected this behavior or engineering principle. Detailed implementation is not necessarily approved.
- **Provisional target:** A measurable objective selected for initial engineering/testing, subject to validation.
- **Technical design pending:** The quality requirement is agreed upon, but its implementation will be decided during C4/ADR/API design.
- **SRM approval required:** Activation or policy depends on formal institutional authorization.
- **Validation required:** Real measurements or user testing are necessary before final acceptance.

Each requirement carries two separate fields. **Status** is exactly one of the five values above. **Depends on** is free text for secondary dependencies (for example "SRM integration" or "hosting decision"). Where an earlier draft combined two statuses, the primary status was chosen by this rule: if SRM or legal approval gates activation, *SRM approval required*; else if a number or measured result is missing, *Provisional target* or *Validation required*; else *Direction confirmed*.

### Milestone tags (proposed)

Each requirement has a **Milestone (proposed)** tag. The tags are **PROPOSED** for the owner to confirm; none is approved.

- **M1:** needed for 10 November 2026 (SwiftUI app).
- **M2:** needed for 13 December 2026 (integrated feature completeness).
- **M3:** needed before the pilot or any live activation.
- **Later:** not needed before the pilot.

Where a requirement is tagged once but has parts that fall earlier, the part is named in its text (for example the UI states of NFR-PER-003 are needed for M1).

### Related PRD requirements

Each requirement lists the functional requirements in [`PRD.md`](PRD.md) it relates to. Every ID was checked against the PRD. "To be mapped" means no clear functional requirement exists yet.

## 2. Reliability and data integrity

### NFR-REL-001 — Authoritative meal entries
**Status:** Direction confirmed

**Depends on:** None beyond the backend design

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-ATT-002](PRD.md#fr-att-002--scanning-a-valid-qr-records-one-entry), [FR-ATT-007](PRD.md#fr-att-007--an-offline-or-unverifiable-scan-is-never-shown-as-success), [FR-PASS-006](PRD.md#fr-pass-006--an-unverified-pass-check-is-never-shown-as-success)

**Requirement:** A digital meal entry must be displayed as successfully recorded only after the backend has verified and durably committed it.

**Acceptance criteria:**
- A failed, timed-out, rejected, or offline request never produces a successful entry result.
- An uncertain outcome displays a verification-required state rather than assuming success.
- Retry behavior cannot create duplicate attendance.

**Verification:** Disconnect the network, delay responses, simulate server failures, and retry transactions while examining database records.

### NFR-REL-002 — Duplicate prevention
**Status:** Direction confirmed

**Depends on:** None beyond the backend design

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-ATT-005](PRD.md#fr-att-005--a-student-is-recorded-at-most-once-per-meal), [FR-PASS-004](PRD.md#fr-pass-004--a-special-meal-entry-is-recorded-at-most-once)

**Requirement:** At most one accepted regular entry record may exist per student per meal, even with simultaneous scanners.

**Acceptance criteria:**
- Concurrent valid attempts result in one accepted entry.
- Duplicate requests do not increase the attendance count.
- Retrying a completed request produces a consistent result.
- Special-meal consumption remains independently constrained by its own rules.

**Verification:** Concurrent request tests, duplicate-key tests, and database invariant checks.

### NFR-REL-003 — Consistent meal lifecycle
**Status:** Direction confirmed

**Depends on:** None beyond the backend design

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-SUP-001](PRD.md#fr-sup-001--the-supervisor-starts-the-meal-for-the-mess), [FR-SUP-002](PRD.md#fr-sup-002--the-supervisor-closes-the-meal), [FR-SUP-004](PRD.md#fr-sup-004--the-supervisor-follows-up-and-resolves-shortages), [FR-ATT-008](PRD.md#fr-att-008--scanning-is-open-only-while-the-meal-is-in-service), [FR-PASS-008](PRD.md#fr-pass-008--pass-desk-follows-the-meal-state)

**Requirement:** Meal start and closure use one authoritative backend state, consistent across authorized staff roles.

**Acceptance criteria:**
- Opening a meal permits the corresponding authorized entry operations.
- Closing a meal prevents subsequent ordinary entries even if a client screen is stale.
- Invalid lifecycle transitions are rejected.
- Meal closure does not automatically resolve shortages, SOS incidents, or missing waste reports.

**Verification:** State-machine tests, role-to-role integration tests, simultaneous close-and-scan tests.

### NFR-REL-004 — Cross-role synchronization
**Status:** Provisional target

**Depends on:** Validation of the percentile, the test-network specification and the maximum refresh delay

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-ATT-009](PRD.md#fr-att-009--live-entry-count-is-shown-as-recorded-entries-only), [FR-SUP-003](PRD.md#fr-sup-003--supervisor-home-follows-the-meal-state), [FR-SUP-007](PRD.md#fr-sup-007--supervisor-alerts-and-history-show-the-same-tasks-everywhere), [FR-KIT-002](PRD.md#fr-kit-002--during-the-meal-the-kitchen-sees-students-entered-only), [FR-KIT-016](PRD.md#fr-kit-016--pass-desk-food-shortages-reach-the-kitchen)

**Requirement:** Connected staff interfaces should reflect committed meal-state and operational changes within five seconds under normal pilot conditions.

**Acceptance criteria:**
- New state is eventually shown without requiring users to sign out.
- Screens indicate stale or unavailable information when synchronization fails.
- API operations enforce current server state regardless of client update delay.

**Verification:** Time synchronized tests across Supervisor, Door Scanner, Pass Desk and Kitchen clients, including reconnect scenarios.

**Open:** The final percentile, test-network specification and maximum acceptable refresh delay require validation.

### NFR-REL-005 — Offline entry policy
**Status:** Direction confirmed

**Depends on:** None. This is the owner direction that resolves the pilot offline-scan decision (see the decision note)

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-ATT-007](PRD.md#fr-att-007--an-offline-or-unverifiable-scan-is-never-shown-as-success), [FR-PASS-006](PRD.md#fr-pass-006--an-unverified-pass-check-is-never-shown-as-success)

**Requirement:** The initial pilot must not accept an offline QR scan as a digitally verified meal entry.

**Acceptance criteria:**
- The scanner explicitly displays that entry was not recorded.
- The system never claims a pending offline entry is committed.
- Restoring connectivity does not silently replay an unverified entry.

**Verification:** Offline and network-flapping tests.

**Decision note.** This records the owner's later direction that the pilot never accepts an offline scan as a verified entry. It resolves the functional decision on scanner offline behaviour (OPEN_DECISIONS R21, formerly P5): in the pilot an offline scan is never recorded and never shown as success. A future offline queue is deferred and is not part of the pilot. **The owner is asked to confirm this reading.**

### NFR-REL-006 — Manual continuity and reconciliation
**Status:** SRM approval required

**Depends on:** SRM-approved manual attendance procedure; the authorized reconcilers; reporting treatment

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-ATT-003](PRD.md#fr-att-003--staff-can-type-the-last-4-digits-when-a-qr-cannot-be-scanned), [FR-MEAL-004](PRD.md#fr-meal-004--answering-is-voluntary-and-the-entry-qr-is-never-locked); manual reconciliation itself: to be mapped

**Requirement:** Meal service must be able to continue during a digital outage under an approved manual attendance procedure.

**Acceptance criteria:**
- Students are not denied ordinary meal service solely because MealLoop is unavailable.
- Reconciled records identify their manual source, actor and time of reconciliation.
- Conflicts with already verified entries are detected and reviewed.
- Reports distinguish QR-verified records from manually reconciled records.
- Reconciliation does not fabricate historical QR verification.

**Verification:** Simulated full-backend outage, manual service exercise, recovery and reconciliation test.

**Open:** Institutional manual logging process, authorized reconcilers, evidence required and reporting treatment.

### NFR-REL-007 — Missing data integrity
**Status:** Direction confirmed

**Depends on:** None beyond the data-model design

**Milestone (proposed):** M1

**Related PRD requirements:** [FR-KIT-006](PRD.md#fr-kit-006--leftovers-are-recorded-per-dish-in-the-dishs-own-unit), [FR-KIT-008](PRD.md#fr-kit-008--waste-fields-are-entered-none-left-not-made-or-not-entered), [FR-KIT-009](PRD.md#fr-kit-009--drafts-save-freely-the-final-save-is-blocked-while-fields-are-empty), [FR-KIT-013](PRD.md#fr-kit-013--a-meal-without-a-report-shows-not-recorded), [FR-HC-002](PRD.md#fr-hc-002--headcount-quantities-are-separate-and-never-merged), [FR-CRD-002](PRD.md#fr-crd-002--honest-insufficient-data-states)

**Requirement:** Missing, unavailable, zero and not-applicable measurements must remain distinguishable.

**Acceptance criteria:**
- An unrecorded waste quantity never becomes zero.
- Not made and None left remain separate.
- Final entries remain unavailable until the appropriate meal closure state.
- Quantities in incompatible units are not incorrectly aggregated.
- Analytics identify incomplete datasets.

**Verification:** Data-model invariants, serialization tests, reporting tests with partial data.

### NFR-REL-008 — Optional AI failure isolation
**Status:** Direction confirmed

**Depends on:** None beyond the architecture

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-AI-001](PRD.md#fr-ai-001--ai-is-advisory-and-core-dining-works-without-it), [FR-AI-002](PRD.md#fr-ai-002--ai-advises-and-routes-it-never-makes-sensitive-decisions)

**Requirement:** Core dining and outing transactions must continue when optional AI services are unavailable.

**Acceptance criteria:**
- Student responses, approved headcounts, scanning, waste reports, SOS and outing decisions do not depend on synchronous AI availability.
- Unavailable predictions are labelled as unavailable or replaced only by an explicitly approved baseline.
- No AI outage causes automatic institutional approval.

**Verification:** Disable AI dependencies during end-to-end workflow tests.

### NFR-REL-009 — SOS delivery and fallback
**Status:** Technical design pending

**Depends on:** SOS delivery time (Appendix A); the notification channel and escalation design

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-FB-004](PRD.md#fr-fb-004--an-sos-reaches-staff-and-the-admin-safety-case), [FR-ATT-012](PRD.md#fr-att-012--door-staff-can-claim-and-check-an-sos-but-not-close-it), [FR-KIT-017](PRD.md#fr-kit-017--the-kitchen-can-claim-and-check-an-sos), [FR-PASS-010](PRD.md#fr-pass-010--pass-desk-can-claim-and-check-an-sos), [FR-SUP-006](PRD.md#fr-sup-006--only-the-supervisor-closes-an-sos-case-in-the-staff-app), [FR-ADM-010](PRD.md#fr-adm-010--the-safety-case-follows-an-urgent-report-to-its-close)

**Requirement:** An SOS reaches the Supervisor and the relevant staff within a defined delivery time; a failed push does not lose the SOS; an unacknowledged SOS escalates to a second authorized person; the SOS state (active, claimed, checked, closed) is authoritative on the server.

**Acceptance criteria:**
- The delivery-time target is pending (Appendix A lists a candidate for discussion only).
- A failed push notification never loses the SOS: it remains visible in the app and the Admin Safety case.
- An unacknowledged SOS escalates to a second authorized person.
- Active, claimed, checked and closed are server states; a client cannot show a state the server has not recorded.
- If external delivery fails, the committed operation stays saved, the in-app alert stays accessible and the delivery failure is recorded; the retry and escalation policy is pending.
- A delivery result is never treated as human acknowledgment.

**Verification:** Inject push failures and unacknowledged SOS cases; compare the server SOS state with each client; measure time to delivery once a target is set.

### NFR-REL-010 — Server time authority
**Status:** Technical design pending

**Depends on:** Permitted clock skew is not decided

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-MEAL-003](PRD.md#fr-meal-003--responses-can-be-changed-until-two-hours-before-the-meal), [FR-KIT-011](PRD.md#fr-kit-011--a-recorded-report-can-be-edited-for-six-hours), [FR-PASS-001](PRD.md#fr-pass-001--the-special-meal-pass-shows-a-changing-code-and-colour), [FR-OUT-006](PRD.md#fr-out-006--accept-starts-a-four-to-ten-second-live-video-with-a-phrase-and-fresh-code), [FR-OUT-015](PRD.md#fr-out-015--a-signed-time-bound-pass-is-issued-after-both-approvals)

**Requirement:** The two-hour response cutoff, the six-hour waste-edit window, the rotating special-pass code and colour, the guardian confirmation code and the outing pass validity windows use server time in IST. A device clock never decides eligibility or validity.

**Acceptance criteria:**
- A device with a wrong clock cannot extend or shorten any of these windows.
- The permitted clock skew is pending.
- Every window decision records the server time used.

**Verification:** Change the device clock in tests and confirm no window decision changes; test the boundaries of each window against server time.

### NFR-REL-011 — Site connectivity
**Status:** Validation required

**Depends on:** Site survey results; the minimum acceptable signal defined by the owner

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-ATT-007](PRD.md#fr-att-007--an-offline-or-unverifiable-scan-is-never-shown-as-success), [FR-PASS-006](PRD.md#fr-pass-006--an-unverified-pass-check-is-never-shown-as-success), [FR-OUT-016](PRD.md#fr-out-016--the-gate-checks-the-pass-and-window)

**Requirement:** Because offline scans are not accepted, a site survey of Wi-Fi and mobile coverage at the Door, Pass Desk, kitchen and supervisor positions (and the Gate for outings) must be completed and recorded before the pilot, with a minimum acceptable signal defined by the owner.

**Acceptance criteria:**
- A recorded survey exists for each listed position.
- The owner has defined the minimum acceptable signal.
- A position below the minimum has a recorded remedy before the pilot.

**Verification:** Survey each position during a meal service and record the result; review the record before the pilot.

## 3. Performance and responsiveness

### NFR-PER-001 — Verified scanning latency
**Status:** Provisional target

**Depends on:** Device specifications, test-network conditions and peak concurrency

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-ATT-002](PRD.md#fr-att-002--scanning-a-valid-qr-records-one-entry), [FR-PASS-002](PRD.md#fr-pass-002--the-desk-compares-code-and-colour-and-records-only-on-matches)

**Requirement:** At least 95% of ordinary online scan-confirmation operations should display the verified backend result within two seconds under defined normal pilot test conditions.

**Measurement:** Time from scanner confirmation/recognized-code submission until the final verified result is rendered, including API and database processing.

**Verification:** Instrumented physical-device and backend tests, reporting p50, p95, p99 and errors.

**Open:** Device specifications, test-network conditions and peak concurrency.

### NFR-PER-002 — Initial peak load
**Status:** Provisional target

**Depends on:** Number of students in the pilot mess; measured pilot data; burst duration and final capacity target

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-ATT-002](PRD.md#fr-att-002--scanning-a-valid-qr-records-one-entry), [FR-ATT-005](PRD.md#fr-att-005--a-student-is-recorded-at-most-once-per-meal)

**Requirement:** The backend should correctly process an initial burst-test workload of ten entry requests per second.

**Acceptance criteria:**
- No duplicate successful records.
- No silently lost committed records.
- Rejections and timeout outcomes are accurately reported.
- Latency and error rates are measured throughout the test.

**Verification:** Automated load test using a representative mixture of successful, duplicate, invalid and conflicting attempts.

**Open:** Burst duration, realistic peak rate and final capacity target. The ten-requests-per-second figure is a provisional starting point only. The realistic door peak must be derived from measured pilot data and this figure replaced by it. Open input: the number of students in the pilot mess.

### NFR-PER-003 — Responsive critical operations
**Status:** Technical design pending

**Depends on:** Client and API design (C4 and API work)

**Milestone (proposed):** M1

**Related PRD requirements:** [FR-ATT-007](PRD.md#fr-att-007--an-offline-or-unverifiable-scan-is-never-shown-as-success), [FR-PASS-006](PRD.md#fr-pass-006--an-unverified-pass-check-is-never-shown-as-success), [FR-KIT-010](PRD.md#fr-kit-010--a-saved-report-is-recorded-with-no-approval-loop), [FR-SUP-002](PRD.md#fr-sup-002--the-supervisor-closes-the-meal)

**Requirement:** Long-running or unavailable services must not leave staff interfaces indefinitely blocked.

**Acceptance criteria:**
- Critical actions show pending, confirmed, failed or uncertain outcomes as appropriate.
- Repeated taps cannot create duplicate actions.
- Network timeouts have a visible recovery path.
- The interface never displays a success result before authoritative confirmation.

**Verification:** Latency injection, rapid repeated-tap testing, retry and timeout testing.

**Milestone note.** The pending, failed and uncertain UI states are needed for M1; the server-side idempotency that backs them follows the other M2 work.

### NFR-PER-004 — Outage recovery objectives
**Status:** Validation required

**Depends on:** Hosting decision; the recovery and availability objectives (see Appendix A); backup schedule

**Milestone (proposed):** M3

**Related PRD requirements:** to be mapped

**Requirement:** Define and test recovery-time and recovery-point objectives appropriate to meal operations, institutional responsibilities and available infrastructure.

**Acceptance criteria:** The approved targets, backup strategy, restoration procedure and test evidence are documented before production activation.

**Verification:** Database restoration and controlled failure exercises.

**Open:** Recovery Time Objective (RTO), Recovery Point Objective (RPO), target availability and backup schedule. No numerical objective is approved yet.

### NFR-PER-005 — Intention and reminder burst load
**Status:** Validation required

**Depends on:** Number of students in the pilot mess

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-MEAL-003](PRD.md#fr-meal-003--responses-can-be-changed-until-two-hours-before-the-meal), [FR-MEAL-006](PRD.md#fr-meal-006--one-default-reminder-before-the-cutoff-plus-optional-reminders), [FR-HC-001](PRD.md#fr-hc-001--the-forecast-accounts-for-every-response-category)

**Requirement:** The system handles the burst of student responses around the reminder and the cutoff, and admin dashboards load correctly under that burst. The load is sized from the real number of students in the pilot mess (an open input), and the same duplicate and idempotency rules apply.

**Acceptance criteria:**
- Responses around the reminder and the cutoff are recorded correctly with no duplicates and no lost committed responses.
- Admin dashboards load correctly during the burst.
- The load profile is derived from the pilot mess student count once it is known.

**Verification:** Replay a burst of responses sized from the pilot mess student count and check records, dashboards and error rates.

### NFR-PER-006 — Guardian video on mobile web
**Status:** Validation required

**Depends on:** Supported mobile-browser list and the video size limit are not decided

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-OUT-006](PRD.md#fr-out-006--accept-starts-a-four-to-ten-second-live-video-with-a-phrase-and-fresh-code), [FR-OUT-008](PRD.md#fr-out-008--retries-and-the-manual-review-fallback), [FR-OUT-009](PRD.md#fr-out-009--upload-failure-falls-back-to-a-live-photo-and-typed-code)

**Requirement:** The guardian recording and upload work on supported mobile browsers (a supported-browser list is pending), tolerate slow and interrupted networks (resumable or retried upload, no duplicate submissions), handle denied camera permission with the documented fallbacks, and keep file size bounded (limit pending).

**Acceptance criteria:**
- Recording and upload work on every browser in the supported list once it exists.
- An interrupted upload resumes or retries without creating duplicate submissions.
- A denied camera permission leads to the documented fallbacks.
- An over-limit file is handled with a clear message and a fallback.

**Verification:** Test supported browsers and devices on throttled and interrupted networks; deny camera permission; exceed the size limit.

### NFR-PER-007 — Door throughput rehearsal
**Status:** Validation required

**Depends on:** A realistic door rehearsal; the device and network conditions

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-ATT-002](PRD.md#fr-att-002--scanning-a-valid-qr-records-one-entry)

**Requirement:** Measure how many students per minute one door position can process in a realistic rehearsal (device, network, queue conditions). The target is derived from the rehearsal, not assumed.

**Acceptance criteria:**
- A rehearsal is run with real devices and queue conditions and its results are recorded.
- The throughput target is set from the recorded results.

**Verification:** Run a door rehearsal and record students per minute, errors and the conditions.

## 4. Authentication, authorization and security

### NFR-SEC-001 — Production identity
**Status:** SRM approval required

**Depends on:** SRM IT confirmation that SRM SSO can be used (protocol, client registration, attributes, test environment, timeline are unverified); the production mechanism for MealLoop-managed accounts (FR-ATT-015, decided in security review)

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-STU-001](PRD.md#fr-stu-001--students-sign-in-with-their-srm-identity), [FR-ID-001](PRD.md#fr-id-001--students-and-super-admins-sign-in-through-srm-sso), [FR-ID-002](PRD.md#fr-id-002--other-internal-users-have-individual-mealloop-managed-accounts), [FR-ATT-013](PRD.md#fr-att-013--prototype-staff-entry-uses-a-shared-role-password), [FR-ATT-015](PRD.md#fr-att-015--production-staff-authentication-and-authorization)

**Requirement:** There are two authentication arrangements. Students and Super Admins are intended to authenticate through SRM SSO; SRM SSO feasibility is unverified and no endpoint, protocol or fallback is assumed or approved. All other internal users (Food Head / Admin, Supervisor, Kitchen Staff, Door Scanner Staff, Pass Desk Staff, Warden, Gate Security and Vendor) authenticate with individual MealLoop-managed accounts using email and password. Production actions must be attributable to the individual user.

**Acceptance criteria:**
- Staff sessions identify the actor and authorized role.
- Account deactivation prevents further protected operations.
- Debug/demo shared-role passwords are not sufficient as sole production authentication.
- Staff role selection does not grant permissions by itself.
- A vendor account is a MealLoop-managed account with a restricted scope, not an external API client.
- No fallback identity scheme is used for real users until the owner and SRM approve it.
- Super Admin is a separate role from Food Head / Admin.

**Verification:** Authentication tests, disabled-account tests, impersonation attempts and staff handover tests.

### NFR-SEC-002 — Server-side action authorization
**Status:** Direction confirmed

**Depends on:** None beyond the authorization design

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-ATT-015](PRD.md#fr-att-015--production-staff-authentication-and-authorization), [FR-ADM-015](PRD.md#fr-adm-015--staff-access-is-managed-by-admin), [FR-OUT-013](PRD.md#fr-out-013--the-warden-decides-on-guardian-approved-requests), [FR-VEN-005](PRD.md#fr-ven-005--the-vendor-account-is-restricted-to-the-approved-headcount), [FR-ID-003](PRD.md#fr-id-003--super-admin-manages-accounts-and-roles), [FR-ID-005](PRD.md#fr-id-005--food-head--admin-does-not-have-super-admin-privileges)

**Requirement:** Every protected backend operation must validate identity, action permission, resource ownership and applicable mess/block scope. Roles and mess assignments are scoped: the vendor account sees only the approved headcount for its explicitly assigned mess, and Food Head / Admin cannot perform Super Admin actions.

**Acceptance criteria:**
- Staff cannot operate on another mess without explicit authorization.
- Wardens cannot access unauthorized hostel blocks.
- Students cannot modify other students' records.
- Client-hidden controls do not substitute for backend enforcement.
- Default behavior is denial when authorization cannot be established.
- A vendor account cannot approve or alter headcounts, see student-level data or guardian evidence, or reach another mess without an explicit assignment.
- Provisioning, role assignment, scope changes, deactivation and password-reset initiation are refused for every role except Super Admin.

**Verification:** Permission-matrix tests, cross-scope access attempts, manipulated-resource-ID tests.

### NFR-SEC-003 — Guardian evidence confidentiality
**Status:** SRM approval required

**Depends on:** SRM policy on who may review guardian evidence; hosting and storage decision

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-OUT-012](PRD.md#fr-out-012--the-warden-sees-the-evidence-method-and-checks), [FR-OUT-022](PRD.md#fr-out-022--guardian-video-consent-retention-and-access)

**Requirement:** Guardian evidence may be accessed only by the assigned authorized warden and explicitly authorized institutional reviewers.

**Note.** FR-OUT-022 currently limits access to the warden role. Whether authorized institutional reviewers may also access evidence is not yet decided; see OPEN_DECISIONS C-20.

**Acceptance criteria:**
- Evidence access is checked for every request and download.
- Storage locations do not provide uncontrolled public access.
- View/download actions are logged with actor, request and time.
- Any temporary reviewer delegation has defined scope and duration.

**Verification:** Unauthorized video-access attempts, direct-URL access tests and audit-log inspection.

### NFR-SEC-004 — Secure shared-device sessions
**Status:** Direction confirmed

**Depends on:** Technical design of the session mechanism (C4, ADR)

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-ATT-013](PRD.md#fr-att-013--prototype-staff-entry-uses-a-shared-role-password), [FR-ATT-015](PRD.md#fr-att-015--production-staff-authentication-and-authorization)

**Requirement:** Staff account sessions must support safe handover, revocation and reauthentication on shared operational devices.

**Acceptance criteria:**
- Signing out removes access to protected screens and operations.
- A new staff member cannot reuse the previous worker's identity silently.
- A revoked session cannot continue privileged operations.
- Sensitive authentication material is not exposed in logs.

**Verification:** Shared-device handover, token/session revocation and session-expiry tests.

### NFR-SEC-005 — Encryption and secrets
**Status:** Direction confirmed

**Depends on:** Detailed encryption and secrets standards from the security review; hosting decision

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-ATT-015](PRD.md#fr-att-015--production-staff-authentication-and-authorization), [FR-OUT-022](PRD.md#fr-out-022--guardian-video-consent-retention-and-access)

**Requirement:** Protected data must be encrypted in transit and sensitive stored data, including guardian evidence and credentials, must be protected using approved security controls.

**Acceptance criteria:**
- No credentials or signing secrets are hardcoded in production application builds.
- Protected APIs reject insecure connections.
- Evidence and backups are protected against unauthorized access.
- Keys and secrets can be revoked or rotated through a documented procedure.

**Verification:** Configuration inspection, transport-security tests and secrets scanning.

### NFR-SEC-006 — Abuse and rate-limiting controls
**Status:** Validation required

**Depends on:** Rate and lockout limits are not set and need design and pilot tuning

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-ATT-013](PRD.md#fr-att-013--prototype-staff-entry-uses-a-shared-role-password), [FR-OUT-004](PRD.md#fr-out-004--the-guardian-opens-the-request-and-reviews-the-details), [FR-OUT-026](PRD.md#fr-out-026--the-guardian-contact-source-is-verified)

**Requirement:** Authentication, guardian verification and other abuse-sensitive endpoints require protection against automated guessing and excessive requests.

**Acceptance criteria:**
- Failed attempts are restricted and recorded.
- Rate-limited responses do not reveal sensitive user information.
- Controls do not permanently block legitimate users without an authorized recovery path.

**Verification:** Repeated-login tests, request flooding and recovery testing.

### NFR-SEC-007 — Auditability of privileged operations
**Status:** Direction confirmed

**Depends on:** None beyond the audit design

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-ADM-016](PRD.md#fr-adm-016--key-decisions-keep-an-audit-history), [FR-HC-004](PRD.md#fr-hc-004--admin-approves-or-adjusts-the-headcount-with-a-reason), [FR-KIT-012](PRD.md#fr-kit-012--waste-reports-keep-audit-timestamps-and-edit-history), [FR-OUT-013](PRD.md#fr-out-013--the-warden-decides-on-guardian-approved-requests), [FR-ATT-015](PRD.md#fr-att-015--production-staff-authentication-and-authorization)

**Requirement:** High-impact operations must preserve the authorized actor, action, affected resource and transaction outcome.

Includes headcount approvals, meal lifecycle changes, attendance corrections, waste edits, SOS handling, outing decisions, evidence access, permission changes and gate events.

**Acceptance criteria:**
- Audit records distinguish requested, completed and failed actions.
- Historical values are preserved where required.
- Ordinary users cannot edit protected audit history.
- Audit records are queryable by authorized reviewers.

**Verification:** Audit completeness tests and unauthorized modification tests.

### NFR-SEC-008 — Outing pass security
**Status:** Direction confirmed

**Depends on:** Technical design of the pass mechanism (C4, ADR, API work)

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-OUT-013](PRD.md#fr-out-013--the-warden-decides-on-guardian-approved-requests), [FR-OUT-015](PRD.md#fr-out-015--a-signed-time-bound-pass-is-issued-after-both-approvals), [FR-OUT-016](PRD.md#fr-out-016--the-gate-checks-the-pass-and-window), [FR-OUT-017](PRD.md#fr-out-017--exit-and-return-are-separate-gate-events)

**Requirement:** Issued outing passes must be verifiable, time-bound and resistant to unauthorized reuse.

**Acceptance criteria:**
- Only an authorized request with required approvals can produce a valid pass.
- A pass cannot be used for multiple exits.
- Return and exit are independently recorded.
- Expired, revoked, invalid or replayed passes are rejected.
- A verified guardian response does not bypass the warden decision.

**Verification:** State-transition tests, altered-pass tests, replay tests and concurrent gate-verification tests.

### NFR-SEC-009 — Security assurance before the pilot
**Status:** Technical design pending

**Depends on:** Scope of the pre-pilot security review is not decided; CI service and hosting decisions

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-ATT-015](PRD.md#fr-att-015--production-staff-authentication-and-authorization)

**Requirement:** A threat model, dependency and secrets scanning in CI, and a documented pre-pilot security review (scope pending) are completed before real users are onboarded.

**Acceptance criteria:**
- A threat model exists and is reviewed.
- Dependency and secrets scanning run in CI and findings are triaged.
- A pre-pilot security review is documented and its findings are closed or accepted by the owner.

**Verification:** Inspect the threat model, the CI scan reports and the review record.

### NFR-SEC-010 — Credential and account lifecycle
**Status:** Technical design pending

**Depends on:** The one-way hashing approach and algorithm (technical design); an email or messaging provider for invitations and resets (undecided); the password policy, multi-factor authentication, lockout and recovery rules and session length (OPEN, no value set)

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-ID-003](PRD.md#fr-id-003--super-admin-manages-accounts-and-roles), [FR-ID-004](PRD.md#fr-id-004--no-one-can-read-a-password), [FR-ID-006](PRD.md#fr-id-006--invitation-and-password-reset-messages-use-an-external-provider), [FR-ATT-015](PRD.md#fr-att-015--production-staff-authentication-and-authorization)

**Requirement:** Passwords are never stored or displayed in plaintext. Credentials are stored using an approved one-way hashing approach, with the algorithm decided in the technical design. A password reset is initiated by Super Admin and completed by the user. Deactivating an account takes effect on protected operations.

**Acceptance criteria:**
- No password appears in plaintext in storage, logs, exports, screens or API responses.
- Super Admin cannot read any user's password.
- A reset initiated by Super Admin can be completed only by the user.
- After deactivation, protected operations by that account are refused.
- No value or policy is set by this requirement; the password policy and recovery rules are decided separately.

**Verification:** Inspect stored credentials and telemetry for plaintext; attempt to read a password as Super Admin; complete and abuse a reset; deactivate an account during an active session and retry a protected operation.

## 5. Privacy and data governance

### NFR-PRI-001 — Data minimization
**Status:** Direction confirmed

**Depends on:** None

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-FB-013](PRD.md#fr-fb-013--feedback-is-aggregate-and-never-shows-names-to-staff), [FR-ADM-017](PRD.md#fr-adm-017--admin-analytics-never-include-private-trackers), [FR-OUT-030](PRD.md#fr-out-030--students-can-see-their-outing-eligibility-and-request-a-correction), [FR-VEN-002](PRD.md#fr-ven-002--the-vendor-sees-the-approved-headcount-for-its-assigned-mess-and-authorized-updates), [FR-VEN-005](PRD.md#fr-ven-005--the-vendor-account-is-restricted-to-the-approved-headcount)

**Requirement:** Each role and subsystem receives only the personal information necessary for its authorized function. The vendor view carries no student-level data.

**Verification:** Review API responses, logs, exports and operational screens for unnecessary identity and behavioral information.

### NFR-PRI-002 — Restricted behavioral modeling
**Status:** Validation required

**Depends on:** Data-access policy; validation of any behavioural feature (FR-AI-005, FR-AI-010)

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-CRD-005](PRD.md#fr-crd-005--class-schedules-and-behavioural-patterns-only-if-validated), [FR-AI-004](PRD.md#fr-ai-004--only-features-available-at-the-prediction-time-are-used), [FR-AI-005](PRD.md#fr-ai-005--forecast-signals-are-evaluated-not-assumed-useful)

**Requirement:** Forecasting may use restricted pseudonymous student-level history where authorized and validated, while normal kitchen and supervisor views present aggregate operational predictions.

**Acceptance criteria:**
- Routine operational dashboards do not expose individual prediction histories.
- Mapping pseudonymous records to student identities is restricted.
- Model-training and inference datasets follow documented access rules.
- Unvalidated behavioral features do not drive operational predictions.

**Verification:** Data-flow review, access testing and model-feature audit.

### NFR-PRI-003 — Student eligibility privacy
**Status:** Direction confirmed

**Depends on:** SRM authorization of the pilot cohort (FR-OUT-027)

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-OUT-024](PRD.md#fr-out-024--pilot-mode-digital-outings-for-the-authorized-pilot-cohort), [FR-OUT-028](PRD.md#fr-out-028--post-pilot-eligibility-needs-participation-and-reliability), [FR-OUT-030](PRD.md#fr-out-030--students-can-see-their-outing-eligibility-and-request-a-correction), [FR-RWD-003](PRD.md#fr-rwd-003--accuracy-bonus-requires-reliably-verified-behaviour)

**Requirement:** Individual participation and reliability evidence used for digital-outing eligibility must be accessible only to the student and authorized decision/review services or personnel.

**Acceptance criteria:**
- Eligibility is explainable without disclosing unnecessary behavioral data.
- Scanner failures and incomplete verification are not treated as proven absences.
- Students have a correction/dispute route.
- Initial outing-pilot eligibility bypass applies only to the authorized pilot cohort.

**Verification:** Eligibility audit tests, missing-data scenarios and authorization tests.

### NFR-PRI-004 — Guardian consent and evidence retention
**Status:** SRM approval required

**Depends on:** SRM privacy policy, consent text and retention period

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-OUT-022](PRD.md#fr-out-022--guardian-video-consent-retention-and-access), [FR-OUT-011](PRD.md#fr-out-011--text-only-confirmation-is-never-accepted)

**Requirement:** Guardian video collection, storage, review, deletion and retention require an institutionally approved privacy policy and appropriate consent.

**Acceptance criteria:**
- Approved information is presented before collection.
- Evidence access is restricted and audited.
- Retention and deletion follow the approved policy.
- No unapproved retention duration is hardcoded as institutional policy.

**Verification:** Consent-flow test, access audit and retention/deletion test.

### NFR-PRI-005 — Feedback and operational-data retention
**Status:** SRM approval required

**Depends on:** SRM retention periods per data type

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-FB-014](PRD.md#fr-fb-014--feedback-and-intent-reasons-need-a-retention-rule), [FR-ADM-016](PRD.md#fr-adm-016--key-decisions-keep-an-audit-history)

**Requirement:** Retention policies must be defined for feedback, skipping reasons, student entry history, correction records, report photos, operational analytics and audit records.

**Verification:** Data inventory, scheduled-retention test and policy review.

### NFR-PRI-006 — Privacy-safe observability
**Status:** Direction confirmed

**Depends on:** None

**Milestone (proposed):** M3

**Related PRD requirements:** to be mapped

**Requirement:** Logs, metrics, error reports and alerts must avoid unnecessary personal information, raw guardian videos, authentication tokens and sensitive complaint text.

**Verification:** Automated and manual inspection of representative telemetry and error scenarios.

### NFR-PRI-007 — Data-protection legal review
**Status:** SRM approval required

**Depends on:** SRM and legal advisers confirm which data-protection requirements apply

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-OUT-022](PRD.md#fr-out-022--guardian-video-consent-retention-and-access), [FR-FB-014](PRD.md#fr-fb-014--feedback-and-intent-reasons-need-a-retention-rule), [FR-STU-001](PRD.md#fr-stu-001--students-sign-in-with-their-srm-identity)

**Requirement:** Before any guardian video, behavioural data or student records are collected from real users, the applicable Indian data-protection requirements (for example the Digital Personal Data Protection Act, 2023; applicability to be confirmed by SRM and legal advisers) are reviewed: notice and consent, access, correction and deletion rights, data location, breach handling and processor responsibilities. This document states no legal conclusion; it records the review as required.

**Acceptance criteria:**
- A review by SRM and its legal advisers is completed and recorded before real-user collection.
- The review covers notice and consent, access, correction and deletion rights, data location, breach handling and processor responsibilities.
- Any change the review requires is reflected in the affected requirements before activation.

**Verification:** Obtain and file the review outcome; check each collection point against it before activation.

## 6. Observability and operations

### NFR-OBS-001 — Structured operational logs
**Status:** Direction confirmed

**Depends on:** None beyond the observability design

**Milestone (proposed):** M2

**Related PRD requirements:** to be mapped

**Requirement:** Backend operations must produce structured logs containing appropriate timestamps, operation identifiers, sanitized outcomes and request correlation identifiers.

**Verification:** Trace representative cross-role workflows through logs.

### NFR-OBS-002 — Health and readiness visibility
**Status:** Direction confirmed

**Depends on:** None beyond the observability design

**Milestone (proposed):** M2

**Related PRD requirements:** to be mapped

**Requirement:** Operators must distinguish a running process from a backend capable of serving its required operations.

**Acceptance criteria:**
- Health checks report relevant service/database readiness.
- Degraded dependencies are visible.
- An optional AI failure is not treated as complete core-system unavailability.

**Verification:** Simulated database, AI and network failures.

### NFR-OBS-003 — Critical failure monitoring
**Status:** Validation required

**Depends on:** Alert thresholds are not set; they need measured pilot behaviour

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-HC-007](PRD.md#fr-hc-007--admin-sees-the-vendor-reply-status), [FR-RWD-006](PRD.md#fr-rwd-006--scanner-failures-have-a-correction-process)

**Requirement:** Operators can detect abnormal scan failures, backend unavailability, unsuccessful headcount delivery, notification problems and pending reconciliation.

**Verification:** Inject each failure and confirm the monitoring and escalation behavior.

### NFR-OBS-004 — Performance measurement
**Status:** Direction confirmed

**Depends on:** None beyond the observability design

**Milestone (proposed):** M3

**Related PRD requirements:** to be mapped

**Requirement:** Operators can measure API response time, error rate, throughput and relevant business-operation failure counts without exposing sensitive student data.

**Verification:** Load-test telemetry reconciliation and dashboard inspection.

### NFR-OPS-001 — Operational readiness and support
**Status:** Technical design pending

**Depends on:** Named owners for support, severity classes, runbooks and feature switches

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-FB-004](PRD.md#fr-fb-004--an-sos-reaches-staff-and-the-admin-safety-case), [FR-OUT-027](PRD.md#fr-out-027--deploying-digital-outings-depends-on-srm)

**Requirement:** Define a support contact during meal hours, incident severity classes, runbooks for backend outage, scanner failure and SOS, and who may disable a feature (for example the guardian video or digital outings). Owners are pending.

**Acceptance criteria:**
- A named support contact exists for meal hours.
- Severity classes are defined.
- Runbooks exist for backend outage, scanner failure and SOS.
- The people who may disable a feature are named.

**Verification:** Review the documents and run a tabletop exercise for each runbook.

### NFR-OBS-005 — Scan-coverage measurement
**Status:** Validation required

**Depends on:** Coverage threshold belongs to SRM and the owner (OPEN_DECISIONS P32); measured pilot data

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-RWD-003](PRD.md#fr-rwd-003--accuracy-bonus-requires-reliably-verified-behaviour), [FR-OUT-028](PRD.md#fr-out-028--post-pilot-eligibility-needs-participation-and-reliability)

**Requirement:** Verified-entry coverage per meal (how much of the actual attendance is captured by trustworthy methods) is measured and reported, because accuracy bonuses and outing reliability depend on it. The coverage threshold is pending and belongs to SRM and the owner. Incomplete coverage is never treated as proof of absence.

**Acceptance criteria:**
- Coverage per meal is measured and reported.
- Meals with incomplete coverage are identified as such.
- No incomplete-coverage meal is used to infer a student was absent.

**Verification:** Compare reported coverage with a manual count during rehearsals; test the eligibility and bonus logic with incomplete-coverage data.

## 7. Accessibility and localization

### NFR-ACC-001 — Native accessibility
**Status:** Direction confirmed

**Depends on:** None

**Milestone (proposed):** M1

**Related PRD requirements:** [FR-STU-006](PRD.md#fr-stu-006--the-student-app-supports-larger-text)

**Requirement:** Critical iOS workflows must support Dynamic Type, VoiceOver and accessible interaction labels.

**Acceptance criteria:**
- Enlarging text preserves critical content and actions.
- VoiceOver conveys actionable control names and relevant states.
- Critical functions do not rely on colour alone.

**Verification:** Accessibility audits on student, scanner, kitchen, supervisor and approval workflows.

### NFR-ACC-002 — Readability and touch targets
**Status:** Provisional target

**Depends on:** Measurement standard to finalize; the active Figma design supplies the initial touch-target references

**Milestone (proposed):** M1

**Related PRD requirements:** to be mapped

**Requirement:** Operational screens must use readable text, adequate contrast and touch targets suitable for fast staff use.

**Verification:** Automated accessibility checks and physical-device usability tests.

**Initial design references:** 44-point general targets and larger staff targets where specified by the active Figma design.

### NFR-ACC-003 — Localization
**Status:** SRM approval required

**Depends on:** Institutional language rollout; speech-check accuracy per language (FR-OUT-023, Validation required); fluent translators for the phrases

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-OUT-007](PRD.md#fr-out-007--the-server-checks-the-spoken-phrase-and-code), [FR-OUT-008](PRD.md#fr-out-008--retries-and-the-manual-review-fallback), [FR-OUT-023](PRD.md#fr-out-023--speech-recognition-accuracy-is-measured-before-relying-on-it), [FR-OUT-026](PRD.md#fr-out-026--the-guardian-contact-source-is-verified)

**Requirement:** The student interface initially supports English, while critical staff-facing workflows must support validated Tamil/Hindi language options where required by the institution. The guardian experience must support the guardian's language, with English, Tamil and Hindi first as in the guardian video spec: the guardian page and the spoken confirmation phrase are both provided in the guardian's chosen language.

**Acceptance criteria:**
- Critical translated instructions are reviewed by proficient speakers.
- Language switching preserves current workflow state.
- Errors, warnings and safety instructions remain understandable.
- Missing translations have a documented fallback rather than misleading text.
- The guardian page and the spoken confirmation phrase are available in English, Tamil and Hindi first, and the guardian chooses the language.
- Speech-check accuracy is measured per language before it is relied on (Validation required; see FR-OUT-023).
- If a language is unsupported, or its speech check is not validated, the request routes to manual review by the warden. It is never silently accepted.

**Verification:** Native-speaker reviews, layout testing and workflow-based localization testing; per-language speech-check accuracy measurement and an unsupported-language fallback test for the guardian flow.

### NFR-ACC-004 — Clear operational feedback
**Status:** Direction confirmed

**Depends on:** None

**Milestone (proposed):** M1

**Related PRD requirements:** [FR-ATT-007](PRD.md#fr-att-007--an-offline-or-unverifiable-scan-is-never-shown-as-success), [FR-PASS-006](PRD.md#fr-pass-006--an-unverified-pass-check-is-never-shown-as-success), [FR-KIT-013](PRD.md#fr-kit-013--a-meal-without-a-report-shows-not-recorded)

**Requirement:** Critical operations explicitly distinguish confirmed, pending, failed, unavailable and stale states.

**Verification:** End-to-end success/failure tests, accessibility review and usability walkthroughs.

## 8. Scalability and maintainability

### NFR-SCL-001 — Pilot-first scalability
**Status:** Direction confirmed

**Depends on:** Number of students in the pilot mess

**Milestone (proposed):** M3

**Related PRD requirements:** to be mapped

**Requirement:** The initial system must adequately serve the authorized one-mess pilot without claiming untested campus-wide capacity.

**Verification:** Load tests representing measured pilot conditions.

### NFR-SCL-002 — Multi-mess configurability
**Status:** Direction confirmed

**Depends on:** None beyond the data-model design

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-ADM-002](PRD.md#fr-adm-002--today-shows-one-tile-per-mess-with-its-meal-progress), [FR-ADM-015](PRD.md#fr-adm-015--staff-access-is-managed-by-admin)

**Requirement:** Messes, meals, assignments, policies and permitted access must be represented as configurable, scoped entities rather than hardcoded for a single location.

**Verification:** Configure a second synthetic mess and confirm independent data, permissions and meal lifecycle.

### NFR-SCL-003 — Expansion validation
**Status:** Validation required

**Depends on:** Representative load, data-isolation and operational test results

**Milestone (proposed):** M3

**Related PRD requirements:** to be mapped

**Requirement:** Additional messes must not be activated solely because the data model supports them; representative load, data-isolation and operational tests must pass first.

**Verification:** Staged multi-mess load and role-isolation tests.

### NFR-MNT-001 — Maintainable module boundaries
**Status:** Direction confirmed

**Depends on:** Architectural implementation (C4, ADR)

**Milestone (proposed):** M2

**Related PRD requirements:** to be mapped

**Requirement:** Core dining, mess operations, outings and optional intelligence must have clear ownership and testable interfaces.

**Acceptance criteria:** Changes to one area do not require accidental edits to unrelated internal state or create unauthorized data access.

**Verification:** Module dependency tests, contract tests and code review.

### NFR-SCL-004 — Cost constraint
**Status:** Technical design pending

**Depends on:** Cost ceiling set by the owner or SRM; hosting decision

**Milestone (proposed):** M3

**Related PRD requirements:** to be mapped

**Requirement:** The architecture reports an estimated monthly operating cost for the pilot against a ceiling set by the owner or SRM. The ceiling is pending.

**Acceptance criteria:**
- An estimated monthly operating cost is reported with the architecture proposal.
- The estimate is compared with the ceiling once it is set.

**Verification:** Review the cost estimate in the architecture review.

## 9. Testing and quality gates

### NFR-TST-001 — Automated critical-path tests
**Status:** Direction confirmed

**Depends on:** None

**Milestone (proposed):** M2

**Related PRD requirements:** [FR-ATT-005](PRD.md#fr-att-005--a-student-is-recorded-at-most-once-per-meal), [FR-ATT-007](PRD.md#fr-att-007--an-offline-or-unverifiable-scan-is-never-shown-as-success), [FR-MEAL-003](PRD.md#fr-meal-003--responses-can-be-changed-until-two-hours-before-the-meal), [FR-KIT-011](PRD.md#fr-kit-011--a-recorded-report-can-be-edited-for-six-hours), [FR-HC-004](PRD.md#fr-hc-004--admin-approves-or-adjusts-the-headcount-with-a-reason), [FR-SUP-002](PRD.md#fr-sup-002--the-supervisor-closes-the-meal), [FR-OUT-002](PRD.md#fr-out-002--the-outing-sequence-is-fixed), [FR-OUT-017](PRD.md#fr-out-017--exit-and-return-are-separate-gate-events)

**Requirement:** Critical operations must have automated tests before they are treated as complete.

Minimum coverage areas:
- Duplicate and concurrent entry handling
- Server-authoritative meal lifecycle
- Intentions and two-hour cutoff
- Waste-report states and six-hour editing
- Headcount authorization and audit history
- Permission boundaries
- Guardian-to-warden outing state transitions
- Gate exit/return replay protection
- Offline and failed-operation behavior

**Verification:** CI test reports and repeatable local execution.

### NFR-TST-002 — Regression quality gates
**Status:** Direction confirmed

**Depends on:** Choice of CI service (ADR)

**Milestone (proposed):** M2

**Related PRD requirements:** to be mapped

**Requirement:** Relevant automated checks must pass before protected application or backend changes are merged.

**Verification:** Confirm a deliberately failing critical test blocks a test pull request.

### NFR-TST-003 — Integration and contract testing
**Status:** Direction confirmed

**Depends on:** API contract work

**Milestone (proposed):** M2

**Related PRD requirements:** to be mapped

**Requirement:** iOS, backend and related clients must use mutually compatible versioned API contracts.

**Verification:** Schema validation, request/response contract tests and cross-role integration tests.

### NFR-TST-004 — Failure testing
**Status:** Direction confirmed

**Depends on:** None

**Milestone (proposed):** M2

**Related PRD requirements:** to be mapped

**Requirement:** Test outages, timeouts, repeated actions, delayed responses and recovery rather than only successful paths.

**Verification:** Controlled fault-injection and recovery exercises.

## 10. Deployment and operational recovery

### NFR-DEP-001 — Environment separation
**Status:** Direction confirmed

**Depends on:** None

**Milestone (proposed):** M1

**Related PRD requirements:** [FR-ATT-013](PRD.md#fr-att-013--prototype-staff-entry-uses-a-shared-role-password), [FR-ATT-015](PRD.md#fr-att-015--production-staff-authentication-and-authorization)

**Requirement:** Demo, staging and production configurations and data must remain logically isolated.

**Acceptance criteria:**
- Production does not use demo credentials or seeded academic records.
- Debug-only simulation cannot silently become production behavior.
- Staging operations cannot modify production student, guardian or mess records.

**Verification:** Configuration, build and database-access tests.

### NFR-DEP-002 — Controlled releases
**Status:** Direction confirmed

**Depends on:** Hosting decision

**Milestone (proposed):** M2

**Related PRD requirements:** to be mapped

**Requirement:** Production releases must have a reproducible build, documented deployment procedure and a recovery strategy.

**Verification:** Staging deployment and release rehearsal.

### NFR-DEP-003 — Safe schema changes
**Status:** Direction confirmed

**Depends on:** Database design

**Milestone (proposed):** M2

**Related PRD requirements:** to be mapped

**Requirement:** Database schema changes must be version-controlled, reviewed and tested against representative existing data.

**Verification:** Migration tests from prior schema versions, including rollback or forward-recovery rehearsal.

### NFR-DEP-004 — Institutional feature activation
**Status:** SRM approval required

**Depends on:** SRM authorization of outings, guardian video and rewards (FR-OUT-027, FR-OUT-022, FR-RWD-007)

**Milestone (proposed):** M3

**Related PRD requirements:** [FR-OUT-022](PRD.md#fr-out-022--guardian-video-consent-retention-and-access), [FR-OUT-024](PRD.md#fr-out-024--pilot-mode-digital-outings-for-the-authorized-pilot-cohort), [FR-OUT-027](PRD.md#fr-out-027--deploying-digital-outings-depends-on-srm), [FR-RWD-007](PRD.md#fr-rwd-007--real-rewards-only-in-a-limited-pilot-after-srm-approval)

**Requirement:** Features requiring institutional authorization must remain disabled for real users until the necessary approvals and readiness checks exist.

Includes:
- Digital outing activation
- Guardian video collection
- Real reward redemption
- Institution-dependent operational policies

**Verification:** Feature-gate tests, authorized activation audit and disabled-state tests.

### NFR-DEP-005 — Backup and restoration
**Status:** Validation required

**Depends on:** Recovery objectives (NFR-PER-004); approved backup retention; hosting decision

**Milestone (proposed):** M3

**Related PRD requirements:** to be mapped

**Requirement:** Operational data must be backed up and recoverable according to approved recovery and retention policies.

**Verification:** Restore into an isolated environment and verify record integrity.

## 11. Architecture constraints and non-decisions

The NFR does not itself approve:
- A specific cloud hosting provider
- WebSockets versus polling
- Microservices versus modular monolith
- Redis, Kafka or Kubernetes
- A specific identity provider
- A guardian video storage provider
- A particular monitoring service
- Any unmeasured latency, capacity or availability guarantee

These choices belong to C4 architecture and ADR reviews.

Also undecided, and recorded here so the C4 and ADR work addresses them:
- The cloud region and data residency (SRM and legal advisers are involved; see NFR-PRI-007).
- A hosting-cost ceiling (see NFR-SCL-004).
- The choice of guardian-video storage.

**Update (1 November 2026).** The owner has approved Spring Boot (Java) as a modular monolith, PostgreSQL, private object storage, no premature microservices, Kafka, Kubernetes or Redis dependency, and Spring Security with RS256 JWT access tokens, rotating opaque refresh tokens and RBAC plus resource and scope authorization ([ADR-003](adr/ADR-003-approved-platform-backend-security.md)). The module boundaries, hosting, providers and the other items in [ADR-004](adr/ADR-004-authentication-session-and-delivery-options.md) are not approved. The existing backend proposal and OpenAPI file are unreviewed drafts and are not approved merely because they exist in the repository. The statements above that these choices are not approved by this NFR remain true: this document approves none of them.

## 12. NFR acceptance evidence

Each requirement shall eventually be linked to:
1. Its owning functional requirements.
2. The component or service responsible.
3. An automated test, operational exercise or documented institutional approval.
4. Test results and the environment in which those results were produced.
5. Its readiness status: not started, implemented, verified or approved for deployment.

An implemented interface is not equivalent to verified operational behavior.

The table below is the template. The filled table is [`NFR_TRACEABILITY.md`](NFR_TRACEABILITY.md).

| NFR ID | Owning functional requirements | Component | Test or exercise | Environment | Readiness |
|---|---|---|---|---|---|
| NFR identifier | Functional requirement identifiers | Component or service | Automated test, operational exercise or approval | Where the result was produced | not started / implemented / verified / approved for deployment |

## Appendix A. Candidate values for owner decision (NOT requirements)

These are suggested starting points for discussion only. They are not approved, they are not requirements, and they must be validated against the real hosting provider and pilot data. They are never to be copied into a requirement statement.

| Topic | Candidate starting point | Linked to |
|---|---|---|
| Availability | about 99% during meal-service windows, best effort outside them | [NFR-PER-004](#nfr-per-004--outage-recovery-objectives) |
| RPO (acceptable data loss) | about 15 minutes | [NFR-PER-004](#nfr-per-004--outage-recovery-objectives) |
| RTO (time to recover) | about 1 hour, because a manual fallback exists | [NFR-PER-004](#nfr-per-004--outage-recovery-objectives) |
| SOS delivery to the Supervisor | about 10 seconds, with a fallback | [NFR-REL-009](#nfr-rel-009--sos-delivery-and-fallback) |
| Door throughput | to be set from the rehearsal in NFR-PER-007 | [NFR-PER-007](#nfr-per-007--door-throughput-rehearsal) |

**Document status remains DRAFT, owner review pending, until explicit owner review and approval.**
