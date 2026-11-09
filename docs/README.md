# Documents index

Every document under `docs/`, one line each. The status comes from the document's own header; "No status in its
header" means the document does not state one.

## Product

| Document | What it is | Status |
|---|---|---|
| [`PRD.md`](PRD.md) | Product requirements | Draft for team review, not owner-approved (its header) |
| [`NFR.md`](NFR.md) | Non-functional requirements | DRAFT, owner review pending (its header) |
| [`NFR_TRACEABILITY.md`](NFR_TRACEABILITY.md) | NFR to milestone, component and test | No status in its header |
| [`REQUIREMENTS_TRACEABILITY.md`](REQUIREMENTS_TRACEABILITY.md) | Requirements traceability matrix | No status in its header |

## Architecture

| Document | What it is | Status |
|---|---|---|
| [`architecture/C4_ARCHITECTURE.md`](architecture/C4_ARCHITECTURE.md) | C4 architecture | Review draft, still under review, not implemented (its header) |
| [`architecture/FRONTEND_READINESS.md`](architecture/FRONTEND_READINESS.md) | Frontend readiness | Historical 1 November baseline (its header) |
| [`adr/ADR-001-ios-architecture.md`](adr/ADR-001-ios-architecture.md) | ADR-001 iOS architecture | Proposed, 2026-10-23 |
| [`adr/ADR-002-backend-shape.md`](adr/ADR-002-backend-shape.md) | ADR-002 Backend shape | Proposed, 2026-10-23 |
| [`adr/ADR-003-approved-platform-backend-security.md`](adr/ADR-003-approved-platform-backend-security.md) | ADR-003 Approved platform, backend and security | Partially superseded by ADR-005 |
| [`adr/ADR-004-authentication-session-and-delivery-options.md`](adr/ADR-004-authentication-session-and-delivery-options.md) | ADR-004 Authentication session and delivery options | Proposed, nothing approved |
| [`adr/ADR-005-frontend-decisions-and-authentication-revision.md`](adr/ADR-005-frontend-decisions-and-authentication-revision.md) | ADR-005 Frontend decisions and authentication revision | Accepted for the listed choices; contracts open |
| [`backend/BACKEND_PROPOSAL.md`](backend/BACKEND_PROPOSAL.md) | Backend proposal | Proposal only, no backend code |
| [`backend/openapi.yaml`](backend/openapi.yaml) | First-slice API contract | Contract; see the backend proposal |
| [`SWIFTUI_STANDARDS.md`](SWIFTUI_STANDARDS.md) | SwiftUI standards checklist for every screen | No status in its header |

## Design

| Document | What it is | Status |
|---|---|---|
| [`SCREEN_INVENTORY.md`](SCREEN_INVENTORY.md) | Every screen and state, with status, owner and priority | Per-row status (its legend) |
| [`COMPONENT_CATALOG.md`](COMPONENT_CATALOG.md) | Shared SwiftUI components | No status in its header |
| [`design/REVIEW_ADDITIONS_SPEC.md`](design/REVIEW_ADDITIONS_SPEC.md) | Review additions spec (7 November); images in `MealLoop-design` | Copied from the pack, 9 November |
| [`design/SUPER_ADMIN_CONTEXT.md`](design/SUPER_ADMIN_CONTEXT.md) | Super Admin context | Copied from the pack, 9 November |
| [`../design/README.md`](../design/README.md) | Figma page map and design notes (outside `docs/`) | See the file |
| [`../design/reference/`](../design/reference/) | Reference packs per role (outside `docs/`) | See each pack's README |

### Verification reports

| Document | What it is | Status |
|---|---|---|
| [`verification/admin-figma-fix/REPORT.md`](verification/admin-figma-fix/REPORT.md) | Admin Figma fix: audit and results | Verification report |
| [`verification/admin-final/REPORT.md`](verification/admin-final/REPORT.md) | Admin (Food Head) completion and a minimal Super Admin | Verification report |
| [`verification/admin-polish/REPORT.md`](verification/admin-polish/REPORT.md) | Admin polish: Today, duplicates, Remind, missing pages, Invite, Search, standards | Verification report |
| [`verification/admin-results/REPORT.md`](verification/admin-results/REPORT.md) | Admin Students, Results and More: verification | Verification report |
| [`verification/admin-scopes/REPORT.md`](verification/admin-scopes/REPORT.md) | Admin scopes, People and access, and per-mess Supervisor | Verification report |
| [`verification/admin-today/REPORT.md`](verification/admin-today/REPORT.md) | Admin Today and headcount approval: verification | Verification report |
| [`verification/door-scanner/REPORT.md`](verification/door-scanner/REPORT.md) | Door Scanner verification | Verification report |
| [`verification/followups/REPORT.md`](verification/followups/REPORT.md) | Follow-ups from the owner's review (9 November 2026) | Verification report |
| [`verification/foundation-standards/REPORT.md`](verification/foundation-standards/REPORT.md) | Foundation standards: verification report | Verification report |
| [`verification/integration/REPORT.md`](verification/integration/REPORT.md) | Integration batch and core-story walk (Part 7a) | Verification report |
| [`verification/kitchen/REPORT.md`](verification/kitchen/REPORT.md) | Kitchen report (Part 4) | Verification report |
| [`verification/outings-staff/REPORT.md`](verification/outings-staff/REPORT.md) | Outings and mess staff roles: finish, generate what is missing, audit (Prompt 4) | Verification report |
| [`verification/outings/REPORT.md`](verification/outings/REPORT.md) | Outings: Warden, Gate Security and Guardian (Part 6, first half) | Verification report |
| [`verification/pass-desk-home/REPORT.md`](verification/pass-desk-home/REPORT.md) | Pass code (Student pass and Pass Desk) and Pass Desk Home, compared with Figma | Verification report |
| [`verification/pass-desk-simple/REPORT.md`](verification/pass-desk-simple/REPORT.md) | Pass Desk simplified to code and colour, with a 30 second student validity | Verification report |
| [`verification/pass-desk/REPORT.md`](verification/pass-desk/REPORT.md) | Pass Desk: verification | Verification report |
| [`verification/staff-complete/REPORT.md`](verification/staff-complete/REPORT.md) | Staff complete: Warden, Guardian, Gate and the mess staff roles (Prompt 5) | Verification report |
| [`verification/staff-figma-fix/REPORT.md`](verification/staff-figma-fix/REPORT.md) | Door Scanner, Supervisor and Pass Desk against the Figma frames | Verification report |
| [`verification/student-figma-1/REPORT.md`](verification/student-figma-1/REPORT.md) | Student 1 of 3: Home, Answer and Entry QR against Figma | Verification report |
| [`verification/student-figma-2/REPORT.md`](verification/student-figma-2/REPORT.md) | Student 2 of 3: Meals, Special pass and Crowd, compared with Figma | Verification report |
| [`verification/student-final-2/REPORT.md`](verification/student-final-2/REPORT.md) | Student final 2: Notifications, You, Credits, Attendance, report pages and the You destinations, compared with Figma | Verification report |
| [`verification/student-final/REPORT.md`](verification/student-final/REPORT.md) | Student final: opening screens, Community, Report and SOS, compared with Figma | Verification report |
| [`verification/student-home/REPORT.md`](verification/student-home/REPORT.md) | Student Home report (Part 3a) | Verification report |
| [`verification/supervisor/REPORT.md`](verification/supervisor/REPORT.md) | Supervisor (Part 4c) verification | Verification report |

## Process

| Document | What it is | Status |
|---|---|---|
| [`BRANCHING.md`](BRANCHING.md) | Branches, commits, pull requests | No status; the owner's 9 November one-branch ruling applies to the owner's sessions (see `CONTRIBUTING.md`) |
| [`BRANCH_ARCHIVE.md`](BRANCH_ARCHIVE.md) | Archived branches and their tags | No status in its header |
| [`PARTS_AND_OWNERSHIP.md`](PARTS_AND_OWNERSHIP.md) | Parts and file ownership | No status in its header |
| [`OPEN_DECISIONS.md`](OPEN_DECISIONS.md) | Open decisions, owner decisions and review-build questions | Each row has its own status |
| [`PRESENTER_ACCOUNTS.md`](PRESENTER_ACCOUNTS.md) | Accounts for the presenter | No status in its header |
| [`PRESENTER_SCRIPT.md`](PRESENTER_SCRIPT.md) | What to show on 11 November and what is simulated | New, 9 November |
| [`TEAMMATE_TEST_SHEET.md`](TEAMMATE_TEST_SHEET.md) | One-page test sheet for teammates | New, 9 November |
| [`REPOSITORY_STRUCTURE.md`](REPOSITORY_STRUCTURE.md) | Repository layout | No status in its header |
| [`FOUNDATION_REPORT.md`](FOUNDATION_REPORT.md) | Foundation report (Stage 1, Task 01) | Report |
| [`FOUNDATION_VERIFICATION.md`](FOUNDATION_VERIFICATION.md) | Foundation verification | Report |
| [`context/PROJECT_CONTEXT.md`](context/PROJECT_CONTEXT.md) | Project context for planning chats | Statuses come from chat; verify in the repository (its note) |
| [`context/NEW_CHAT_STARTER.md`](context/NEW_CHAT_STARTER.md) | How to start a planning chat | No status in its header |
| [`context/PROMPT_PLAYBOOK.md`](context/PROMPT_PLAYBOOK.md) | Prompt playbook for implementation sessions | No status in its header |

## Archive

| Document | What it is | Status |
|---|---|---|
| [`archive/ADR-001-ios-architecture_2026-10.md`](archive/ADR-001-ios-architecture_2026-10.md) | ADR-001: iOS architecture | Archived |
| [`archive/ADR-002-backend-shape_2026-10.md`](archive/ADR-002-backend-shape_2026-10.md) | ADR-002: Backend shape | Archived |
| [`archive/BACKEND_PROPOSAL_2026-10.md`](archive/BACKEND_PROPOSAL_2026-10.md) | Backend proposal | Archived |
| [`archive/FOUNDATION_REPORT_2026-10.md`](archive/FOUNDATION_REPORT_2026-10.md) | Foundation report (Stage 1, Task 01) | Archived |
| [`archive/OPEN_DECISIONS_2026-10.md`](archive/OPEN_DECISIONS_2026-10.md) | Open decisions | Archived |
| [`archive/README_2026-10.md`](archive/README_2026-10.md) | MealLoop | Archived |
| [`archive/README_2026-11-09.md`](archive/README_2026-11-09.md) | MealLoop | Archived |
| [`archive/REPOSITORY_STRUCTURE_2026-10.md`](archive/REPOSITORY_STRUCTURE_2026-10.md) | Repository structure | Archived |
| [`archive/SCREEN_INVENTORY_2026-10.md`](archive/SCREEN_INVENTORY_2026-10.md) | MealLoop screen inventory | Archived |
