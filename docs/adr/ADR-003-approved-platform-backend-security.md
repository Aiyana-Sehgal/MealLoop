# ADR-003: Approved platform, backend and security decisions

- Status: **Accepted.** These are decisions the owner explicitly approved, as stated in the architecture-synchronization task of 1 November 2026. The repository does not record the original date of each approval, so no earlier date is claimed here. C1 (the system context) was approved on 24 October 2026 (see `docs/architecture/C4_ARCHITECTURE.md`).
- Scope: only the choices listed in the mapping table. Everything else stays `Proposed`, `Recommended`, `Unverified` or `Open` (see [ADR-004](ADR-004-authentication-session-and-delivery-options.md) and `docs/OPEN_DECISIONS.md`).
- Partly supersedes the authentication wording of [ADR-002](ADR-002-backend-shape.md) ("role-based bearer tokens carrying role and mess").

## Mapping of the approved choices

| ID | Approved choice |
|---|---|
| A1 | One native SwiftUI iOS application with role-aware navigation for all 11 roles, including Guardian |
| A2 | A future Android client in Kotlin with Jetpack Compose |
| A3 | Android and iOS share backend API contracts, not UI code |
| A4 | Spring Boot (Java) as a modular monolith |
| A5 | PostgreSQL for structured persistent data |
| A6 | Private object storage for guardian videos and sensitive attachments |
| A7 | No premature microservices, Kafka, Kubernetes or Redis dependency |
| A8 | Spring Security |
| A9 | Signed JWT access tokens |
| A10 | RS256 signatures for the JWT access tokens |
| A11 | A 15-minute access-token lifetime |
| A12 | Rotating opaque refresh tokens |
| A13 | Role-based access control (RBAC) plus resource and scope authorization |
| A14 | Identity direction: SRM SSO for Students and Super Admins, subject to institutional feasibility; individually managed MealLoop accounts for operational staff and Vendors; server-enforced authorization; guardian contact authority from institutionally verified information or an approved correction; guardian video evidence supports historical review but does not independently prove identity (C1 decisions, recorded as OPEN_DECISIONS R22 and R26) |

The 11 roles are: Student, Super Admin, Food Head / Admin, Supervisor, Kitchen Staff, Door Scanner Staff, Pass Desk Staff, Vendor, Guardian, Warden, Gate Security.

## Context

Four developers, most of them learning native iOS, must deliver an iOS client and a Spring Boot backend. The pilot is one mess. The owner needs one client codebase per platform, a single deployable backend that can be reasoned about, and server-enforced authorization that does not depend on what a device shows. The existing proposals ([ADR-001](ADR-001-ios-architecture.md), ADR-002, `docs/backend/BACKEND_PROPOSAL.md`, `docs/backend/openapi.yaml`) are unreviewed drafts and are not made accepted by this ADR.

## Decision

The choices A1 to A14 above are accepted.

## Alternatives considered

The owner's approval statement did not list alternatives. The alternatives below are recorded by the author of this ADR from the existing documents and are not the owner's wording.

| Area | Alternative | Why it was not selected (as recorded in the repository) |
|---|---|---|
| Backend shape | Microservices, Kafka, Kubernetes, Redis from the start | Network failure modes, many deployables and operational work for a four-person team and one pilot mess (ADR-002, backend proposal). Not selected now; revisit triggers below |
| Backend shape | A backend-as-a-service | Idempotency, audit and data-ownership rules are harder to guarantee (ADR-002) |
| Client | Cross-platform UI shared between iOS and Android | Not selected: the owner chose native clients that share API contracts, not UI code |
| Access tokens | Opaque access tokens with a server lookup per request; a shared-secret signature | Not recorded by the owner. The approved direction is signed JWTs with RS256 |

## Rationale

The repository records the reasons for a modular monolith and for no premature infrastructure (ADR-002 and the backend proposal). **The owner's reasons for the security choices (JWT, RS256, the 15-minute lifetime, opaque rotating refresh tokens) are not recorded in the repository**, so none are written here.

## Consequences

- iOS and Android clients depend on versioned backend API contracts, so the contracts are the integration point. The existing OpenAPI file is an unreviewed draft and does not yet reflect these decisions (conflicts C-25, C-29 and C-31 in `docs/OPEN_DECISIONS.md`).
- A single iOS application must cover 11 roles, including Guardian, Vendor and Super Admin. Guardian, Vendor and Super Admin screens do not exist in Figma yet, and the foundation's `Role` model has nine roles (conflict C-26). The earlier C2 draft showed Guardian as separate mobile web; that is now contradicted (conflict C-34).
- Access tokens expire after 15 minutes, so the client needs a refresh flow and the server needs a refresh-token store. How that store, revocation, device limits and client storage work is not decided ([ADR-004](ADR-004-authentication-session-and-delivery-options.md)).
- Server authorization uses role and resource or scope on every request. The shared four-digit role password is a prototype interaction only.
- No Redis dependency is approved, so a design that needs one must come back for review.

## What this ADR does not decide

Hosting, storage provider, region, retention, privacy and backup policy; refresh-session storage, lifetimes and device policy; immediate revocation; password hashing configuration; multi-factor authentication; password recovery; login rate limiting; client token storage; push-notification integration; outbox details; polling versus server-sent events; SRM SSO protocol and availability; module boundaries inside the monolith; the frontend architecture; API contracts. See ADR-004 and `docs/OPEN_DECISIONS.md`.

## Revisit triggers

- A module needs independent scaling, release cadence or ownership (backend shape).
- Measured load, availability or recovery needs that one deployable and one database cannot meet.
- SRM IT confirms or rules out SRM SSO.
- A security review finds a weakness in the token design.
- The owner changes the client strategy (for example, a requirement for a guardian channel other than the iOS app).
