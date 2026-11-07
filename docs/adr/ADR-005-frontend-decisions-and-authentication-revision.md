# ADR-005: Frontend architecture approvals and authentication-direction revision

- **Status:** Accepted for the explicitly listed architectural choices; implementation contracts and delivery details remain open.
- **Scope:** MealLoop's SwiftUI frontend structure, contract workflow, and authentication mechanism. This record does not claim the code, OpenAPI document, or diagrams have been updated or tested.
- **Prior record:** [ADR-003](ADR-003-approved-platform-backend-security.md) stays authoritative for platform/backend, eleven roles, Spring Security, and role/resource/scope authorization **except** its JWT access-token and refresh-token selections A9–A12, which this newer owner decision supersedes.

## Approved frontend decisions

| ID | Area | Owner-approved decision |
|---|---|---|
| FE-1 | Organization | Hybrid: role-oriented SwiftUI presentation with shared business models/contracts and workflows. |
| FE-2 | Presentation | Balanced MVVM + Repository Pattern; ViewModels manage presentation state, repositories own data access. |
| FE-3 | Dependency injection | **Manual DI**, constructor/initializer injection by default, centralized application composition, selective SwiftUI Environment for app-wide observable state. No mandatory DI library. Shared instances may be supplied by composition without global repository singletons. |
| FE-4 | Boundaries | Balanced MVVM with shared domain and repository contracts; optional Use Cases only when a workflow warrants one, not for every trivial operation. Views do not issue HTTP calls, repositories do not own SwiftUI navigation. |
| FE-5 | Models | Shared canonical domain models + feature/screen-specific presentation state; shared-model changes reviewed by teammates, avoiding duplicated and incompatible definitions. |
| FE-6 | Contracts | **Option D:** review and share Swift repository contracts and maintain an OpenAPI backend specification now; handwritten local/remote adapters initially, with **optional** OpenAPI-generated client later if justified. This is an approach decision, **not** approval of the existing draft protocol methods or draft HTTP endpoints. |

### Frontend working constraints

- One native SwiftUI iOS application with role-aware presentation for **all 11 approved roles**; Kotlin/Compose Android later, sharing backend API contracts but not UI code.
- Local, coherent prototype data may power the November review while Spring Boot integration is incomplete; avoid hardcoding conflicting counts in screens. **Do not misrepresent local writes as server-confirmed operations.**
- Repository contracts should expose the operations the ViewModels need; remote adapters may map API DTOs into domain models. No direct SwiftUI view networking.
- Keep backend business rules, identity, resource/mess authorization and persistent transactional results authoritative on Spring Boot.

## Authentication decision revised

The owner explicitly selected **PostgreSQL-backed opaque bearer access tokens** in place of the earlier signed JWT access-token / rotating refresh-token architecture direction.

**Approved at mechanism level:**

- Spring Security provides a centralized authentication boundary across the **single Spring Boot modular monolith**, not one authentication service per internal module.
- Native clients use a bearer credential. The server validates it against PostgreSQL-backed session/token records; store secure verifiers (e.g. hashes), user/device/session association, expiry and revocation status rather than storing usable raw access secrets.
- Server-controlled revocation and device/session management are intended capabilities.
- iOS credentials belong in Keychain; Android credentials must use protected platform storage.
- Existing **RBAC plus resource/mess/scope authorization remains approved**, and is server-enforced independently of the token format.

**Supersession:** ADR-003 A9 (signed JWT access), A10 (RS256 JWT), A11 (15-minute JWT access lifetime), A12 (rotating opaque refresh tokens) are **superseded as the selected architecture**, not silently assumed for the opaque scheme. No JWT access-token implementation is authorized merely because the old documents mention it.

**Still open — do not invent:** opaque token entropy and format, token hashing/lookup approach, access/renewal/absolute/idle lifetimes, whether a separate refresh credential is needed, logout/device limits, rate limiting, credential/account recovery, institutional SSO integration and guardian identity verification, token indexing/cleanup, mobile retry/offline behavior, security test cases. These must be designed and reviewed before production authentication integration.

Existing `docs/backend/openapi.yaml`, `Data/Repositories/Repositories.swift` and staff entry currently contain a legacy shared role-password flow. They are **not** the approved future production authentication contract.

## Delivery timing and scope

- The owner most recently said the frontend review is **Tuesday**; for November 2026 this means **10 November 2026**. Older repository docs say **Wednesday 11 November 2026**. Treat the schedule as a discrepancy to verify with the program coordinator. Internally aim to be review-ready by 9 November.
- **Do not attempt all 420 exported screen states.** Freeze a focused owner-approved review demonstration scope before dividing feature tasks.
- Suggested first integrated vertical slice (proposal, not yet owner-approved feature assignment): Student menu/intention -> Food Head headcount -> Kitchen preparation/status -> Door Scanner verified entry -> refreshed Kitchen/Food Head readings. Add other roles only when scope and resources permit.
- A polished *interactive prototype* is not an integrated production backend. Avoid user-facing debug badges/menus in the reviewer build, but accurately disclose prototype versus live backend.

## Critical implementation prerequisites (not yet completed by approving this ADR)

1. **Xcode baseline verification:** confirm project builds/launches and unit tests pass on the team's Macs; record exact Xcode version and output.
2. **Review scope:** choose exact Figma screens, role flow and interactions for Tuesday. Inventory priority labels are proposals, not owner approvals.
3. **Freeze minimum shared contracts:** roles (11), IDs, meal/intention/entry/headcount state meanings, repository method signatures, error/load states, core API/DTO shapes and multi-mess scope. Fix currently contradictory draft models.
4. **Shared prototype-state contract:** one coherent local source for cross-role flows, mutation/notification policy and reload behavior; do not equate a seeded number with authoritative live data.
5. **Role routing/auth seam:** role-aware navigation; do not reuse the old four-digit shared password as if it were production authentication. Reviewer-local navigation must be explicitly separated from the planned opaque-token backend mechanism.
6. **Review-ready build configuration:** current Debug-only data badge/time-skipping controls and Release `notImplemented` output are incompatible with the desired reviewer experience without a deliberate safe prototype build configuration.
7. **Team ownership/integration:** assign a feature owner per scope, common integration branch, small PRs, reviewed shared-contract edits and daily build/regression checks.

These prerequisites are gates for safe **parallel implementation**; they are not a demand to finish the full Spring Boot backend, SSO, production auth or every C3/C4 diagram before starting SwiftUI feature work.

## Items still pending

- **FE-7:** precise shared-state ownership/updates, role-aware navigation and routing, app-wide session UI.
- **FE-8:** definitive delivery scope, team ownership, branching/integration, verified builds/tests, UI review readiness.
- Exact domain, repository and HTTP API/DTO signatures remain open despite FE-5 and FE-6 *approach* approvals.
- Backend module internals, live update delivery (polling/SSE), hosting and security implementation settings remain open.

## Evidence / linked draft records

- [Frontend readiness, 1 Nov baseline](../architecture/FRONTEND_READINESS.md).
- [Proposed repository structure and rules](../REPOSITORY_STRUCTURE.md).
- [Backend OpenAPI 0.1.0 draft](../backend/openapi.yaml).
- [ADR-004: earlier open auth/session and delivery options](ADR-004-authentication-session-and-delivery-options.md).
- `ios/MealLoop/Data/Repositories/Repositories.swift`: currently includes legacy role-password `AuthRepository` and incomplete cross-role stubs.
- `ios/MealLoop/Domain/Role.swift`: currently only nine roles, against the approved eleven.
- `ios/MealLoop/App/AppEnvironment.swift`: local data gated to Debug; remote API path unfinished.
