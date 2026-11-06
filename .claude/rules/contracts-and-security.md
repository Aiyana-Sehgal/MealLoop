---
paths:
  - "ios/MealLoop/Domain/**"
  - "ios/MealLoop/Data/**"
  - "ios/MealLoop/App/**"
  - "docs/backend/**"
---

# Shared contracts, data integrity and authentication

Scope: domain models, repository protocols, the data layer, the app composition root and the backend documents. Sources: `docs/adr/ADR-005-frontend-decisions-and-authentication-revision.md`, `docs/adr/ADR-003-approved-platform-backend-security.md`, `docs/PRD.md`, `docs/NFR.md`.

## Before changing shared code
1. Search for the existing implementation (`rg`/Grep) before writing a new one.
2. Read the domain model in `ios/MealLoop/Domain/`, the protocols in `ios/MealLoop/Data/Repositories/Repositories.swift` and the matching operation in `docs/backend/openapi.yaml`.
3. List every affected call site (views, ViewModels, the prototype data source, `RemoteAPI`, tests) and update them in the same change.
4. Keep identifiers and field meanings consistent across models, repositories, DTOs and screens. A shared-model or contract change is reviewed by a teammate before it merges.
5. **The OpenAPI file and the existing repository protocols are unreviewed drafts, not approved contracts** (ADR-005, FE-6). If two documents conflict, the newest explicit owner decision wins; report the discrepancy instead of choosing silently. Do not invent endpoints, fields or DTO shapes the task did not ask for.

## Data integrity (never break)
- **Missing data is never zero.** Use `CountReading`, `Forecast`, `LeftoverMeasurement`, `PlateWasteMeasurement`. Never default a measurement to 0 or to an empty value that reads as zero.
- **Headcount values stay separate:** live forecast, cutoff forecast, approved headcount, sent-to-vendor headcount, actual entries and final entries (PRD FR-HC-002). No field is filled from another.
- An entry QR proves entry, not that food was served or eaten.
- **An offline scan is never recorded or shown as recorded.** A failed, timed-out or unverified write is an error state, never a success (NFR-REL-001, NFR-REL-005).
- **A screen never claims backend success the real backend did not confirm.** A result from the local prototype data source is labelled as simulated in the code and in documentation. Do not present local writes as server-confirmed (ADR-005).
- Duplicate prevention (one entry per student per meal) belongs to the data layer, not to a view or a ViewModel.
- Demo data is isolated and labelled. `ios/MealLoop/Data/Demo/` code is compiled only with `DEMO_DATA`, and `ios/MealLoop/App/AppEnvironment.swift` stops any non-Debug build that sets it. Never move demo data into `Domain`, a view or a Release path. No hardcoded demo values inside views.
- Time: cutoffs and windows use the injected `AppClock`, never a view's `Date()`. On the real backend, server time in IST is authoritative (NFR-REL-010).

## Authentication and security (ADR-005; verify its wording before relying on it)
- **Direction:** PostgreSQL-backed opaque bearer access tokens, validated by the single Spring Boot application with Spring Security. The server stores secure verifiers (such as hashes), user, device and session association, expiry and revocation status, not usable raw access secrets. **The earlier signed JWT, RS256 and rotating-refresh-token choice (ADR-003 A9 to A12) is superseded.** Do not write JWT-based code or documents.
- RBAC plus resource and mess or hostel scope authorization stays approved and is enforced by the server, whatever the token format. Client checks only shape the interface.
- iOS credentials go in the Keychain (the exact access-control settings are open). Android uses protected platform storage.
- **Still open: never state them as settled:** token format and entropy, hashing and lookup, access, renewal, absolute and idle lifetimes, whether a separate refresh credential exists, device limits, rate limiting, recovery, SSO integration, guardian identity verification, retry and offline behaviour (ADR-005; `docs/adr/ADR-004-authentication-session-and-delivery-options.md`).
- The shared four-digit role password (`AuthRepository.verifyRolePassword`, `Features/StaffEntry`, `/staff/sessions` in the OpenAPI draft) is a **debug and prototype interaction only**. Never treat it as production authentication or build on it. Keep any developer-only role switch separate from the production authentication path.
- No hardcoded passwords, tokens or secrets in source, tests, fixtures, logs or documents. Never log tokens, passwords or personal data.
- The reviewer-facing build must not show developer badges (such as the Debug `DemoDataBadge`), simulation menus or mock-data wording, and it must not hide that the deliverable is an interactive prototype. No such build configuration exists yet; do not create one without the owner's direction.
