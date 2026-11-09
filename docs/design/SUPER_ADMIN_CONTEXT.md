> Copied from the review additions pack (`review_additions_2026-11/data/`); `~/Downloads/SUPER_ADMIN_CONTEXT.md` itself was not present. Images live in the separate design repository.

# Super Admin (combined with Admin): full context

Prepared 7 November 2026 from the repository on `main`, the Figma file `nzzTAm9YnJRSdKEeYUWUEb`, and the owner's decisions in chat. Every fact below is cited. Images are in `design/reference/review_additions_2026-11/images/` once committed (also in the zip).

## 1. The decision (owner, 7 November 2026)
- **Admin and Super Admin are one role.** It has access to **all messes**, their headcounts, and what is going on inside each mess. In Figma this is already drawn: Admin Today `2257:158261` shows "Hey Devi" with four mess tiles (Main, North, South, Annexe), the meal stepper, and a "Needs you" list; Live meal `2260:160216` shows one mess in detail.
- **The role manages people and access: give a password, revoke it, add a person, allot a person to a mess**, for a specific role (for example Door staff).
- **The Supervisor is specific to one mess** and starts and closes the meal for that mess only.

## 2. Conflicts with the written documents (owner's latest decision wins; update the documents)
| Document | Says | Now |
|---|---|---|
| `docs/archive/OPEN_DECISIONS_2026-10.md` R23, `docs/NFR.md`, `docs/PRD.md` (FR-ID-003) | Super Admin is a **separate** role; Food Head / Admin has no Super Admin privileges | One combined role |
| R23, FR-ID-004, NFR-SEC-010 | **No one can read a password**; passwords are never shown; users set and reset their own credentials | The Admin sees a **temporary** password **once**, when giving it. It is never readable afterwards. The person is told to change it; no forced-change screen exists yet |
| R22 | Super Admin signs in through SRM SSO | Unverified; the prototype signs in through Staff sign in (P-ENTRY-1) |
| Figma People and access `2278:166146` | Vendor contact card "Not a login" | The PRD (R24, FR-VEN-001 to 005) gives the vendor a restricted account: Vendors appear as a role row |
| `docs/PARTS_AND_OWNERSHIP.md` row 6e | Super Admin: "None: mock in chat" | The mocks below are approved |
Record these in `docs/OPEN_DECISIONS.md` as owner decisions with the date.

## 3. What exists in the code today (`main`)
Source: `docs/verification/admin-final/REPORT.md` Part C; files `Features/SuperAdmin/SuperAdminRootView.swift`, `SuperAdminViewModel.swift`, `Domain/SuperAdmin.swift` (`ManagedAccount`), `Data/Repositories/SuperAdminRepository.swift` (`accounts`, `account`, `deactivate`, `startPasswordReset`), `Data/Demo/DemoSuperAdmin.swift`.
- **The "Accounts" screen** lists every seeded account of every role in one flat list ("Aarav / Student", "SRM admin / Super Admin", "Devi Raman / Food Head / Admin" ...) with Sign out at the bottom. It was built **without a design**. It reads as the banned role picker. **Remove it.**
- **An account page** with "Start password reset" (recorded only) and "Deactivate account" (recorded only; sign-in does not change). **Replace** with the person page below; deactivate becomes **Revoke password** and must really block sign-in in the prototype (owner decision).
- The repository refuses every role except Super Admin, including the Food Head. **Change**: the combined Admin is the one role allowed.
- The model has **no password or token field**; a test enforces it. **Keep**: store only a hash and a state.

## 4. Screens
Real Figma frames (read-only reference; the Admin build already follows them): Today `2257:158261` (also Dinner `2258:460`, Offline `2258:1314`, Safety case `2258:672`), Live meal `2260:160216`, More `2278:6`, Weekly menu, Announce, Outings, People and access `2278:166146`.
Approved drawings for the people-and-access flow (images):
| Image | Screen |
|---|---|
| `admin_people_00_roles` | People and access: roles with counts (Food heads, Mess supervisors, Kitchen staff, Door staff, Pass desk staff, Wardens, Gate security, Vendors) and "Invite someone". Replaces the Figma frame's vendor "Not a login" card |
| `admin_people_01_door_staff` | The people in one role across all messes: mess and password status |
| `admin_people_02_person` | Person page: Mess, Role, **Give password**, **Revoke password** |
| `admin_people_03_give_password` | Temporary password shown once, Copy password, Done |
| `admin_people_04_invite` | Invite someone: name, phone or email, role chips, mess chips |
| `admin_people_05_revoke_confirm` | Confirm: "Revoke SK's password?" |
| `admin_people_06_allot_mess` | **Allot to a mess**: pick the mess, "Past records stay with the mess they were made in." |
| `admin_people_07_person_revoked` | Person page after a revoke: "Password revoked", lime **Give password**, revoke disabled, "SK can't sign in until you give a new password." |
Navigation: More › People and access › role › person. The tab bar is Today, Students, Results, More plus the round Search (Search stays the placeholder).

## 5. Rights and rules
- **Can:** see all messes and each mess's headcount chain, live meal, shortages and results; give a password; revoke a password; invite and allot a person to a role and a mess; change a person's mess.
- **Cannot:** read any password after the one-time sheet closes; revoke an Admin account (the screen offers no Revoke on an Admin; who may revoke an Admin is open); act as a Supervisor of a mess; change a student's data.
- **Give password:** the backend makes a temporary password, returns it once, stores only a hash and a state, never logs it. After the sheet closes it cannot be shown again.
- **Revoke password:** signs the person out and refuses their sign-in until a new password is given. Past records stay.
- **Honest wording:** nothing is delivered to the person unless the prototype really does it (it sends nothing). No sheet says they "must change it at first sign-in" unless a change-password screen is built.
- **Audit:** FR-ADM-016 requires key decisions to keep an audit history. Each give, revoke, invite and allot is recorded with who and when (no screen is drawn for the log yet).

## 6. Backend (additive; names are proposals)
`PeopleRepository`: `roles()` (counts from data), `people(role:)`, `person(id:)`, `givePassword(person:)` returns a one-time temporary password, `revokePassword(person:)`, `invite(name:contact:role:mess:)` returns a one-time temporary password, `allot(person:mess:)`. Sign-in checks the person's state: seeded accounts keep the shared prototype password until revoked; after a revoke sign-in is refused; after a give only the new temporary password works. A relaunch resets everything.

## 7. Per-mess Supervisor
The backend refuses start and close for any mess other than the acting supervisor's own, and the Supervisor screens show only that mess. Kitchen, Door Scanner and Pass Desk operations that already take the acting session get the same check.

## 8. Open questions
1. Who may revoke an Admin account?
2. Update R23, FR-ID-003, FR-ID-004, NFR-SEC-010 to the combined model (a documentation task).
3. Is a forced change-password screen wanted before the review?
4. How does the person receive the password in production (FR-ID-006 says an external provider)? Today nothing is sent.
5. How many food heads per mess (the Figma list shows 2 food heads and 4 messes)? "No food head" rows are drawn only in an earlier drawing.
6. Role rows not in the Figma list (Pass desk staff, Vendors) use placeholder counts.
7. An audit-log screen is not drawn.

## 9. Build order and tests
1. Route the Super Admin account to the Admin root; remove the flat Accounts screen. 2. People and access screens in the order of section 4. 3. Backend and sign-in checks. 4. Per-mess Supervisor guard. Tests: both Admin accounts reach the same root; give returns a password once and stores no plaintext; revoke blocks sign-in and give restores it; allot moves the person and keeps past records; invite adds the person; no Revoke on an Admin; a supervisor of mess A cannot start or close mess B; existing tests keep passing.
