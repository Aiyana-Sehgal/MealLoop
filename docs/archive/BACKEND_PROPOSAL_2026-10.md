# Backend proposal

**Status: proposal only (an unreviewed draft).** *Update (1 November 2026): the owner approved parts of this direction in [ADR-003](../adr/ADR-003-approved-platform-backend-security.md): a Spring Boot (Java) modular monolith, PostgreSQL, private object storage, no premature microservices, Kafka, Kubernetes or Redis dependency, and a different authentication design (RS256 JWT access tokens, rotating opaque refresh tokens, RBAC plus resource and scope authorization). Reliability principle 7 below (a bearer token carrying role and mess) and the `mess-ops` "staff role passwords and device lockouts" are superseded by ADR-003 and by the individual-account decision (OPEN_DECISIONS R22, R29). The module list, the meal-lifecycle ownership split between `dining-core` and `mess-ops` (T20), the outbox and the OpenAPI file stay unreviewed.* No backend code exists. The first-slice contract is in [`openapi.yaml`](openapi.yaml) (12 operations, validated with `openapi-spec-validator`). The decision record is [ADR-002](../adr/ADR-002-backend-shape.md).

## Shape: a modular monolith

One Spring Boot application (Java) with one PostgreSQL database. It is split into modules with hard boundaries, so a module can become a separate service later if there is a clear need.

| Module | Owns (tables only this module writes) | Talks to others by |
|---|---|---|
| `dining-core` | messes, meals, menus and dishes, intentions, headcounts (forecast, sent, adjustments with reason and history), vendor replies, entries, entered-without-voting, special passes | Publishes events: `MealStarted`, `MealClosed`, `EntryRecorded`, `HeadcountSent` |
| `mess-ops` | meal state transitions (start, close), shortages, waste reports (per-dish leftovers, plate waste), SOS cases (claims, checks, closing), staff role passwords and device lockouts | Reads dining-core through its Java interface, never its tables. Publishes `ShortageReported`, `WasteRecorded`, `SOSRaised` |
| `outings` | outing requests and their state machine, guardian evidence references, warden decisions, gate exit and return events | Publishes `GateExit`, `GateReturn`. Dining reads confirmed exits only |
| `notifications` | the transactional outbox, delivery attempts, push tokens | Consumes events from the outbox; retries until delivered or marked failed |
| `intelligence` *(later, optional)* | nothing in the core database | A separate Python service that reads exported, verified data and returns advisory suggestions. Core endpoints never call it synchronously |

Rules:

- A module reads another module's data only through that module's public interface (or its events), never by joining its tables. This is what makes a later split possible.
- Each module has its own package, its own Flyway migrations folder and its own tests. An ArchUnit (or Spring Modulith) test fails the build if one module imports another's internals.
- Events are written to an **outbox table in the same transaction** as the change, then delivered by the notifications module. Nothing is lost when push delivery fails.

## Why not microservices, Kafka or Kubernetes now

- **The team is four people, mostly learning.** One deployable, one database and one set of logs are far easier to build, debug and demo for External Review 4 (27 to 29 January 2027).
- **The load is small.** The pilot is one mess. Thousands of entries per meal do not need a message broker.
- **Correctness matters more than scale.** Idempotent entries, "missing is not zero" and the meal state machine are easier to guarantee inside one transaction than across services.
- **Docker alone does not give resilience.** Isolation comes from data ownership, timeouts, durable events (the outbox) and failure testing. The modular monolith keeps those properties without network hops.
- **Revisit when** a module needs independent scaling or release cadence, or a team owns it separately. The intelligence service is the expected first split, because it uses Python and is optional by design.

## Reliability principles

1. **Core dining works with AI down.** No dining endpoint calls the intelligence service. Forecasts start as a statistical baseline computed inside `dining-core`; any ML model is optional and compared against that baseline.
2. **Scans are idempotent.** `POST /meals/{mealId}/entries` requires an `Idempotency-Key`. A repeated key returns the original response. A second entry for the same student and meal returns `409 already_recorded`, and the count does not change. A unique constraint on (meal, student) backs this in the database.
3. **Offline scans are never shown as recorded.** If the server cannot verify and save an entry, the request fails and the app shows "This entry is NOT recorded". Queueing scans offline is deferred and not part of the pilot. *Superseded by NFR-REL-005 in [`../NFR.md`](../NFR.md) (the owner is asked to confirm): the pilot rule is never record.*
4. **Notifications retry from durable records.** Every notification starts as an outbox row in the same transaction as the change, with retries and a visible failed state. "Seen" is stored only when the receiver confirmed it.
5. **Missing data stays missing.** Counts are `available` or `unavailable`; leftovers are `entered`, `noneLeft`, `notMade` or `notEntered`. No column defaults a measurement to 0.
6. **Audit trails.** Headcount adjustments, meal start and close, shortage resolution and SOS closing store who, when and why.
7. **Role and mess checks on every request.** The bearer token carries the role and the mess; the server checks both on every endpoint.

## First slice (what the OpenAPI covers)

Student answers a meal → headcount → staff session → meal start → door entry → live and final counts → shortage → meal close → waste report. Feedback, Community, special passes, outings and admin results are not in this slice.

## Data notes

- Times are stored in UTC and shown in the mess's time zone (Asia/Kolkata for the pilot).
- The demo data in the iOS app is never loaded into the backend database. Seeded backend data, if any, lives in a separate schema or database, is labelled as seeded, and is excluded from analytics.
