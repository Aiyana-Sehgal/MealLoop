# ADR-004: Authentication session, credential and delivery options

- Status: **Proposed.** Nothing in this ADR is approved by the owner. "Recommended" means the assistant's recommendation, not the owner's choice. The approved baseline is in [ADR-003](ADR-003-approved-platform-backend-security.md).

## Context

ADR-003 approves signed RS256 JWT access tokens with a 15-minute lifetime, rotating opaque refresh tokens, Spring Security and RBAC plus resource or scope authorization. It does not decide how refresh sessions are stored or limited, how credentials are protected, how clients store tokens, or how live data and notifications are delivered. Those choices need security and architecture review before they are frozen.

## Status of each open choice

Statuses: **RECOMMENDED** (an option is suggested, not selected), **PROPOSED** (an existing draft states it, not reviewed), **UNVERIFIED** (depends on an external fact that has not been checked), **OPEN** (no option selected).

| # | Choice | Options or draft | Status | Register entry |
|---|---|---|---|---|
| 1 | Refresh-session storage | PostgreSQL or Redis. ADR-003 approves no Redis dependency, so PostgreSQL is consistent with it | RECOMMENDED: PostgreSQL; not selected | T13 |
| 2 | Refresh-session absolute lifetime and idle timeout | No value is set | OPEN | P61 |
| 3 | Concurrent-device policy | One device, several devices, or per role | OPEN | T14 |
| 4 | Immediate JWT revocation | Access tokens live 15 minutes (approved). Whether and how a token is revoked sooner is not decided | OPEN | T15 |
| 5 | Password hashing | Argon2id is the recommended algorithm; the parameters are not set | RECOMMENDED (algorithm); OPEN (configuration) | T16 |
| 6 | Multi-factor authentication method and enforcement | None selected | OPEN | P61 |
| 7 | Password-recovery design | Reset is initiated by Super Admin and completed by the user (FR-ID-003, FR-ID-004); the mechanism is not designed | OPEN | P61, P63 |
| 8 | Login rate limiting | NFR-SEC-006 requires protection; no policy is set | OPEN | P45 |
| 9 | iOS Keychain storage and access-control settings | Keychain is the expected store; accessibility and access-control settings are not chosen | PROPOSED; OPEN (settings) | T17 |
| 10 | Push-notification integration | FCM or APNs; delivery stays non-authoritative (R25) | OPEN | P70 |
| 11 | Transactional outbox implementation | Outbox rows in the same transaction, dispatched by a worker (ADR-002, backend proposal) | PROPOSED | T18 |
| 12 | Live data: polling or server-sent events | Not decided; NFR-REL-004 sets a provisional refresh target | OPEN | T19 |
| 13 | Hosting provider and deployment topology | Institution server or cloud | OPEN | T12, P48, P54 |
| 14 | Storage provider, region, retention, privacy and backup policy | None selected; SRM and legal review pending | OPEN | P44, P39, P54, P55 |
| 15 | SRM SSO protocol and integration availability | Not verified; nothing is assumed | UNVERIFIED | P60 |

## Decision

None. This ADR records the choices that still have to be made. It becomes one or more accepted ADRs only after the owner selects an option for each.

## Options considered

Options are listed in the table. No option is rejected here.

## Consequences

- Until these are decided, no code or API contract may present any of them as final.
- The client token-handling design (frontend authentication boundary) cannot be completed before items 1 to 4, 9 and 10 are decided or explicitly deferred ([FRONTEND_READINESS](../architecture/FRONTEND_READINESS.md)).

## Revisit triggers

- The owner selects an option for any row.
- SRM IT answers the SSO questions (P60).
- The security review (NFR-SEC-009) reports.
- The hosting decision (T12) is made.
