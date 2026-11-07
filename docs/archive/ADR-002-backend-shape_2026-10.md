# ADR-002: Backend shape

- Status: Proposed (2026-10-23). Documentation only; no backend code exists.
- **Update (1 November 2026):** the owner has since approved parts of this direction: Spring Boot (Java) as a modular monolith, PostgreSQL, private object storage, no premature microservices, Kafka, Kubernetes or Redis dependency, and a different authentication design (Spring Security, RS256 JWT access tokens of 15 minutes, rotating opaque refresh tokens, RBAC plus resource and scope authorization). Those choices are recorded in [ADR-003](ADR-003-approved-platform-backend-security.md). **The sentence below that says authentication uses "role-based bearer tokens carrying role and mess" is superseded by ADR-003.** The module list, the outbox, Docker Compose, the Python `intelligence` service and the `/v1` REST details stay Proposed and unreviewed.

## Context

The backend must serve the iOS app now and Android later, integrate with iOS by 13 December 2026, and be working with a database by External Review 4 (27 to 29 January 2027). The team is four developers. The pilot is a single mess. Core dining must keep working when AI is unavailable, scans must never be counted twice, and an unverified scan must never look recorded.

## Decision

A **modular monolith**: one Spring Boot (Java) application and one PostgreSQL database, split into the modules `dining-core`, `mess-ops`, `outings` and `notifications` (transactional outbox). A separate, optional Python `intelligence` service comes later. Modules own their tables, talk through interfaces and outbox events, and boundaries are checked by an architecture test. The REST API is JSON, described with OpenAPI, and versioned in the path (`/v1`). Authentication uses role-based bearer tokens carrying role and mess. Details: [`docs/backend/BACKEND_PROPOSAL.md`](../backend/BACKEND_PROPOSAL.md) and [`docs/backend/openapi.yaml`](../backend/openapi.yaml).

## Options considered

| Option | Why not now |
|---|---|
| Microservices from the start | Network failure modes, distributed transactions and many deployables for a four-person team and one pilot mess. No load or ownership reason yet. |
| Kafka (or another broker) | The outbox table plus a polling dispatcher gives durable, retried events at this scale without running a broker. |
| Kubernetes | Docker Compose is enough to run the app and database for development and the review. Orchestration adds operational work without a matching need. |
| A backend-as-a-service | Fast to start, but it makes the idempotency, audit and data-ownership rules harder to guarantee, and it is not the planned stack. |

## Consequences

- One deployable to build, test and demo. Module boundaries must be enforced by tests, or the monolith will tangle.
- Moving a module to its own service later means swapping an interface call for an HTTP or event call. The outbox and data ownership are what make that possible.
- The iOS `RemoteAPI` implementation follows `openapi.yaml`; contract changes go through that file first.
