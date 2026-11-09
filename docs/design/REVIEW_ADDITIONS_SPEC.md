> The approved screen images for this spec live in the separate design repository (`MealLoop-design`, being set up); only this text is kept here.

# Review additions: approved screens drawn in chat (7 November 2026)

These 16 screens were drawn in chat from real Figma frames and the repository's tokens, and **approved by the owner**. Figma has no frames for them. Images are 786 x 1704 (2x of 393 x 852). They are references for SwiftUI builds, not Figma exports: build them with the repository's tokens (`MLColor`, `MLLayout`, `MLType`) and compare screenshots against these images.

Source frames used: Admin `2259:160232` and `2259:160041` (headcount), staff Home `2471:2437`, Pass Desk Home `2530:4460`, student pass `221:63212`, Admin People and access `2278:166146`.

## Owner decisions behind these screens
1. **Admin and Super Admin are one role**: access to all messes, their headcounts, and what is going on in each mess (the four-mess Today in the Figma Admin Redesign). They also manage people and access.
2. **Admin can give a password and revoke it, for a specific role.** Give password makes a temporary password that is shown **once** (they must change it at first sign-in); the admin can never read a password back. Revoke signs the person out and blocks sign-in until a new password is given. Past records stay.
3. **Supervisor is specific to one mess.** They deal only with operations inside their mess and have no relation to other messes; they start and close the meal for their own mess only (the backend must refuse any other mess).
4. **Pass Desk Home during the meal shows the current pass code and colour** like the student's pass (no student entry first); entering the last four digits is the fallback.
5. **The Vendor** has a restricted MealLoop account: sees the approved headcount only and acknowledges receipt. A missing acknowledgment shows as Pending and is never filled in.

## Screens
| Image | Role | What it shows |
|---|---|---|
| `vendor_01_home_waiting` | Vendor | Not approved yet: dash, "Waiting for the Food Head to approve." |
| `vendor_02_home_sent` | Vendor | Sent, waiting for you: approved headcount, lime "Acknowledge receipt" inside the black card |
| `vendor_03_home_acknowledged` | Vendor | Sent and acknowledged times in the eyebrow, no button |
| `vendor_04_home_cant_send` | Vendor | Offline, "Couldn't send" chip with warning icon, black Retry |
| `vendor_05_history` | Vendor | Past meals with reply time or Pending |
| `vendor_06_me` | Vendor | Account, mess, signed-in email, Sign out |
| `passdesk_home_01_code_colour` | Pass Desk | Black card "The pass should show": code, colour chip **with its name**, "Changes in N s"; hairline rows: Enter last 4 digits, Look up a student, Request a new pass, Report a problem |
| `passdesk_home_02_last4_sheet` | Pass Desk | Fallback sheet: four boxes, keypad, "A match is recorded here." |
| `admin_people_01_door_staff` | Admin | People in one role across all messes, with mess and password status |
| `admin_people_02_person` | Admin | Sign-in card; Mess, Role, **Give password**, **Revoke password** |
| `admin_people_03_give_password` | Admin | Temporary password shown once, Copy password, Done |
| `admin_people_04_invite` | Admin | Invite someone: name, phone or email, role chips, mess chips |
| `admin_people_05_revoke_confirm` | Admin | Confirmation: "Revoke SK's password?" |
| `admin_people_00_roles` | Admin | People and access: roles with counts and "Invite someone" (replaces the Figma card "Vendor contact · Not a login") |
| `admin_people_06_allot_mess` | Admin | Allot to a mess: pick the mess for a person |
| `admin_people_07_person_revoked` | Admin | Person page after a revoke: "Password revoked", Give password |

## Rules that apply
- Tab bars: Vendor Home and Me (wide staff capsule, no Search); Pass Desk Home, Alerts, Me; Admin Today, Students, Results, More plus the round Search.
- Status wording, numbers, names and times in the images are **placeholders**. The build reads data; where no source supplies a value it shows "unavailable". "Sample name" stands for a person the data does not yet name.
- Never show a password after the one-time sheet is closed. Never claim a message or password was delivered unless it was.

## Open items
- The Figma People and access frame draws "Vendor contact · Not a login · headcount goes by message". The PRD and the Vendor screens above give the vendor a restricted account. Owner to confirm which is right.
- Who may revoke an Admin account is not decided.
- Role-scoped lists beyond Door staff (Mess supervisors, Kitchen staff, Wardens, Gate security) use the same layout.
