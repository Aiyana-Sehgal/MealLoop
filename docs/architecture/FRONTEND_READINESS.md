# Frontend readiness (review draft)

> **Update (6 November 2026):** This is a **historical 1 November baseline**, not current approval status. Owner-approved frontend Decisions FE-1 through FE-6 and the PostgreSQL-backed opaque bearer-token direction are now recorded in [ADR-005](../adr/ADR-005-frontend-decisions-and-authentication-revision.md). Existing code, reviewer scope, model/API signatures and Xcode verification remain uncompleted; see ADR-005 for the current pre-frontend gates.

**Date:** 1 November 2026 · **Status:** PENDING REVIEW. Nothing in this document is owner-approved except where it quotes a recorded owner decision. It does not design the frontend architecture. The next activity is a separate owner-led review of that architecture.

**Dates that matter.** External SwiftUI review: 11 November 2026. PRD milestone: 10 November 2026 (every approved, active screen in SwiftUI). From 2 to 10 November there are 7 weekdays.

**Method.** Facts below come from reading the files on the `docs/architecture-decision-sync` branch (which contains the `ios/` foundation). Nothing was built or run: this session had no Xcode and no macOS. GitHub pull-request states were not re-checked because the GitHub connector failed to connect; only branch tips were read.

## 1. What the owner has decided (and what has not been decided)

Approved and recorded in [ADR-003](../adr/ADR-003-approved-platform-backend-security.md): one native SwiftUI iOS application with role-aware navigation for all 11 roles, including Guardian; Android later in Kotlin with Jetpack Compose, sharing API contracts and not UI code; a Spring Boot (Java) modular monolith with PostgreSQL and private object storage; no premature microservices, Kafka, Kubernetes or Redis dependency; Spring Security, RS256 JWT access tokens (15 minutes), rotating opaque refresh tokens, RBAC plus resource and scope authorization.

**Not decided:** the frontend architecture, the domain models, the repository contracts, the API and DTO contracts, and everything listed in [ADR-004](../adr/ADR-004-authentication-session-and-delivery-options.md). The owner treats the generated SwiftUI models, repositories, OpenAPI definitions and the other foundation artifacts as **unreviewed drafts, not approved architectural contracts**. Existing code is not evidence that a design decision was approved.

### The owner's requirements for the November frontend

| # | Requirement | Where it stands |
|---|---|---|
| 1 | A professionally designed SwiftUI interface matching the approved Figma references | Not verified. Only Kitchen Home is implemented; no comparison with Figma is recorded |
| 2 | Coherent, interactive application workflows | Not met: eight role folders hold only a README, and a Release build shows "Not implemented" states (C-28) |
| 3 | No developer-only demo badges, debugging menus or mock-data terminology on the reviewer-facing interface | Not met in Debug: a "Demo data" badge and a "Simulated moment" menu exist (C-27, P73) |
| 4 | One frontend implementation designed for subsequent direct Spring Boot integration | Not reviewed (P75, P76) |
| 5 | Stable domain models, repository contracts and backend-compatible request and response shapes before parallel screen development | Not met: models and contracts are unreviewed drafts (P76, C-26, C-31, C-32) |
| 6 | No claim that a locally simulated operation was committed by a live server | Honoured by the foundation's rules (nothing fakes success) but the reviewer build is undecided (P73) |
| 7 | An accurate description of the review deliverable as an interactive iOS prototype if the backend is not integrated | **Recorded as the required wording.** Until the backend is integrated, the deliverable is an interactive iOS prototype, not a system that stores real data |

Backend integration is the next development milestone, not a reason to redesign the frontend after the review.

## 2. Readiness status table

Status values: **PENDING REVIEW** (an artifact exists but has not been reviewed or approved), **NOT VERIFIED** (a claim exists without evidence), **DECISION NEEDED** (the owner has not chosen). "Blocks" means blocks starting parallel screen development.

| # | Area | Existing artifact or evidence | Verified current status | Unresolved | Blocks frontend implementation? | Next review activity |
|---|---|---|---|---|---|---|
| 1 | November review feature and screen scope | [`SCREEN_INVENTORY.md`](../SCREEN_INVENTORY.md): 420 active exported screens and states, 149 distinct base screens, priorities P0 to P3 marked "owner decides"; 12 Needs design (not in Figma) rows for Vendor and Super Admin | **DECISION NEEDED.** The priorities are proposals; no owner-approved scope exists | Which screens and workflows are shown on 11 November (P74); the effort note in the inventory states that all 420 is not realistic at a normal quality bar | **Yes** | Owner scope review |
| 2 | Current design-reference mapping | `design/reference/*` packs and the inventory rows (Active, Needs review, Archived) | **PENDING REVIEW.** The inventory was generated from repository documents without Figma access; 20 rows are Needs review; no mapping from screens to features or view models exists | Needs-review rows (P15, P16); Guardian, Vendor and Super Admin surfaces in one iOS app; the guardian channel (P78) | Partly (Needs-review rows cannot be built) | Owner resolves Needs-review rows |
| 3 | Frontend layer and feature boundaries | [`ADR-001`](../adr/ADR-001-ios-architecture.md) (Proposed) and [`REPOSITORY_STRUCTURE.md`](../REPOSITORY_STRUCTURE.md): folders `App`, `Core`, `DesignSystem`, `Domain`, `Data`, `Features/<Role>` exist in `ios/` | **PENDING REVIEW.** Folders exist; boundaries are a convention, not compiler-enforced. Features implemented: Kitchen Home, StaffEntry, the staff shell. Student, Admin, DoorScanner, PassDesk, Supervisor, Guardian, Warden and Gate contain only a README | Whether the structure is accepted (P75) | **Yes** | Owner-led frontend architecture review |
| 4 | MVVM responsibility allocation | ADR-001 decision 3 (`@MainActor @Observable` view models, views are layout only); one view model, `KitchenHomeViewModel`, with a test file | **PENDING REVIEW.** One example exists; the responsibility split is not reviewed | Allocation across the 11 roles; navigation and shared-state responsibilities | **Yes** | Same review |
| 5 | Dependency-injection approach | `AppEnvironment` provides `Repositories`, `AppClock` and optional demo controls; data source chosen by build flag (`DEMO_DATA` in Debug, otherwise `api`) | **PENDING REVIEW.** The approach exists in code; it was not reviewed. Its build-flag selection is in tension with the reviewer-build requirement (C-27, C-28) | How a reviewer build and a backend build are produced (P73) | **Yes** | Same review |
| 6 | Allowed dependencies between layers | `REPOSITORY_STRUCTURE.md` rules 1 to 9 | **PENDING REVIEW.** Not enforced by the compiler; no dependency check exists | Whether rules are accepted; how enforced | **Yes** | Same review |
| 7 | Shared domain models and state transitions | 14 files in `ios/MealLoop/Domain/` | **PENDING REVIEW.** `Role` has nine roles against eleven (C-26); `Headcount` does not hold the six separate quantities and carries a stale "vendor has no login" comment (C-32); meal start and close live in `MealStateRepository`, while the backend proposal splits lifecycle ownership (C-30, T20) | Models for Vendor, Super Admin, accounts, notifications, outings; the lifecycle owner | **Yes** | Domain-model review |
| 8 | Repository protocols | `Repositories.swift`: nine protocols (meals, meal state, headcount, entries, intentions, shortages, waste reports, SOS, auth) and four empty stubs (feedback, Community, special pass, outing) | **PENDING REVIEW.** `AuthRepository` is `verifyRolePassword`, the shared-password prototype (C-25). No repository for Vendor, accounts, notifications, Admin results or Guardian and Warden flows | The contracts the November flows need (P76) | **Yes** | Same review |
| 9 | Backend-compatible API and DTO contracts | [`openapi.yaml`](../backend/openapi.yaml) version `0.1.0-draft`: 12 operations; placeholder server; shared-password session and a generic bearer scheme | **PENDING REVIEW.** An unreviewed draft. Missing for the November core flows (C-31): authentication refresh, logout and SSO; Community, feedback and rewards; special passes; outings; Admin results; Vendor headcount view and acknowledgment; account administration; notifications. DTO-to-model mapping is not reviewed | The contracts, including the approved token design (R29) | **Yes** | API and DTO contract review (P76) |
| 10 | Authentication and role-navigation integration boundary | `AppSurface` has six surfaces (student, messStaff, admin, guardian, warden, gate); `StaffEntry` shows the shared-password role entry; approved: JWT access tokens of 15 minutes, rotating opaque refresh tokens, RBAC plus resource and scope | **PENDING REVIEW.** No client design for token handling, refresh, sign-out, role-aware navigation of 11 roles or SSO exists | Keychain strategy (T17), refresh and revocation (T13, T15), SSO feasibility (P60), concurrent devices (T14), role-to-surface mapping | **Yes** | Frontend authentication boundary review |
| 11 | Shared interactive prototype state | `DemoDataProvider` (a Debug-only actor with seeded data and seven simulated moments) and a `DemoControlling` hook | **PENDING REVIEW.** Exists for Kitchen only; cross-role shared state across roles is not built. Its badge and menu conflict with requirement 3 | The reviewer-build design (P73); how simulated state is described honestly | **Yes** | Owner decision, then review |
| 12 | Xcode build and test verification | `ios/README.md` commands; 5 test files with 40 test functions; no `FOUNDATION_VERIFICATION.md` | **NOT VERIFIED.** The owner reports a successful build and launch on their Mac. The unit-test result is not recorded and no build log is in the repository. This session did not build or test | A recorded `xcodebuild build test` result | **Yes** (parallel work needs a verified base) | Owner runs the build and tests and records the output |
| 13 | Team feature ownership, branching and integration workflow | Folder ownership table in `REPOSITORY_STRUCTURE.md`; `docs/BRANCHING.md` and `CLAUDE.md` exist only on the `docs/repo-conventions` branch (not on the default branch when checked); every inventory row is "Unassigned" | **DECISION NEEDED.** The conventions are a proposal; no feature owners are assigned | Assignment of owners; whether the proposed conventions are adopted (P77) | **Yes** | Owner decision |

**Summary.** Rows 3 to 11 and 13 are PENDING REVIEW or DECISION NEEDED. Frontend architecture, domain contracts and API integration design are **not approved**. No row blocks only documentation; all but row 2 block starting parallel screen development.

## 3. Contradictions and obsolete statements

Authoritative rows are in [`OPEN_DECISIONS.md`](../OPEN_DECISIONS.md#conflicts). Status shows what this synchronization did.

| ID | Contradiction | Status |
|---|---|---|
| C-21, C-23, C-24 (earlier) | Vendor with no login in PRD 0.2, README and the earlier C1 draft | Resolved in the PRD and C1 draft; README corrected by the owner; the admin design pack and the OpenAPI file unchanged |
| C-25 | Shared four-digit staff password in the foundation, OpenAPI and backend proposal, against individual accounts and JWT | Documentation noted; code and OpenAPI left unchanged (open) |
| C-26 | Foundation `Role` has nine roles; the approved model has eleven | Open |
| C-27 | Demo badge and simulated-moment menu against the reviewer-facing requirement | Open (P73) |
| C-28 | Release build shows "Not implemented"; the review needs interactive workflows | Open (P73) |
| C-29 | ADR-002 and the backend proposal describe role-based bearer tokens carrying role and mess | Resolved by notes (ADR-003); OpenAPI unchanged |
| C-30 | `dining-core` and `mess-ops` both own meal start and close | Open (T20) |
| C-31 | OpenAPI and repositories do not cover the November core flows; they also differ from each other | Open (P76) |
| C-32 | `Headcount.swift` says the vendor has no login and lacks the six quantities | Open (P76) |
| C-33 | PRD and NFR said the Spring Boot and PostgreSQL choices were not approved | Resolved by notes |
| C-34 | The C2 draft and NFR-PER-006 describe guardian mobile web; the owner approved one native iOS app including Guardian | Open (P78) |

## 4. Open items that affect the frontend

P73 (reviewer build), P74 (November scope), P75 (frontend architecture review), P76 (domain, repository and API contracts), P77 (ownership and workflow), P78 (guardian channel), P68 (Vendor and Super Admin screen scope and milestone), P60 (SRM SSO), T13 to T20 and the items in ADR-004. Each has a class and a "no value is invented" default in the register.

## 5. What this document does not do

It does not design layers, MVVM, dependency injection or shared prototype state; it does not change SwiftUI code, Figma exports, the OpenAPI file or any API; and it does not mark any architecture or contract as approved. The next task is an owner-led review of the frontend architecture.
