# MealLoop

MealLoop is an AI-assisted institutional dining and student-engagement platform. It is designed to improve
meal-demand planning, reduce avoidable food waste, manage crowding at the mess and make student feedback lead to
visible corrective action.

**Today it is an interactive iOS prototype on seeded data**, for the review on 11 November 2026 (first pilot:
Meenakshi Girls' Mess, SRM). It is not a live system: there is no backend yet. A Spring Boot and PostgreSQL backend
and an Android client follow later (`CLAUDE.md`; `docs/adr/ADR-003-approved-platform-backend-security.md`,
`docs/adr/ADR-005-frontend-decisions-and-authentication-revision.md`).

## Which branch

Use **`main`**. It is the only branch (owner ruling, 9 November): the owner's sessions push green commits straight to
`main`, with CI (`.github/workflows/ios-ci.yml`) as the safety net. Contributors outside those sessions use pull
requests (see `CONTRIBUTING.md`). Old branches are kept as `archive/*` tags (`docs/BRANCH_ARCHIVE.md`).

## Run it

The history is large, so clone only the code and documents:

```
git clone --filter=blob:none --no-checkout --depth 1 --no-tags https://github.com/VeeraaVikash/MealLoop.git
cd MealLoop
git sparse-checkout set --cone ios docs .github .claude
git checkout main
```

Open `ios/MealLoop.xcodeproj`, choose the scheme **MealLoop Review** and an iPhone simulator, and run. Xcode version
used by the verification reports: **Xcode 27.2 (27B52)** (`docs/verification/admin-final/REPORT.md`); other versions
are not verified. All data is in memory and resets on every launch.

## Sign in

The accounts and how each role signs in are in `docs/PRESENTER_ACCOUNTS.md`. Passwords are not repeated here. A
teammate's step-by-step test is `docs/TEAMMATE_TEST_SHEET.md`; the presenter's script is `docs/PRESENTER_SCRIPT.md`.

## Folders

| Folder | What it holds |
|---|---|
| `ios/` | The SwiftUI app (iOS 17), its unit tests and the asset catalogs |
| `docs/` | Product, architecture, process and verification documents (index: `docs/README.md`) |
| `design/` | Design notes and reference packs (text). Design images live in the separate repository `MealLoop-design`, being set up |

No image files may be committed outside `ios/`; the commit-rules CI check fails a push that adds one.

## Roles and what is built

| Role | State | Source |
|---|---|---|
| Student | Built; 0 destinations say Coming soon when signed in | `docs/verification/student-final/REPORT.md` (B7) |
| Food Head (Admin) | Built, single mess | `docs/verification/admin-polish/REPORT.md`, `docs/verification/followups/REPORT.md` |
| Super Admin | Minimal: Accounts, an account page, a simulated password reset | `docs/verification/admin-final/REPORT.md` (Part C) |
| Supervisor, Kitchen, Door Scanner, Pass Desk | Built; 0 reachable placeholders | `docs/verification/outings-staff/REPORT.md`, `docs/verification/staff-complete/REPORT.md` |
| Warden, Guardian, Gate security | Built; 0 reachable placeholders; Guardian sign in is simulated | `docs/verification/outings-staff/REPORT.md`, `docs/verification/staff-complete/REPORT.md` |
| Vendor | Coming soon | `ios/MealLoop/Features/Vendor/VendorRootView.swift` (no Vendor report) |

What is simulated (no camera scanning, nothing delivered, seeded sample numbers) is listed in
`docs/PRESENTER_SCRIPT.md`. Open questions are in `docs/OPEN_DECISIONS.md`.

## More

- Documents index: [`docs/README.md`](docs/README.md)
- How to contribute: [`CONTRIBUTING.md`](CONTRIBUTING.md)
- The earlier, longer README (product overview, features, roadmap, design references):
  [`docs/archive/README_2026-11-09.md`](docs/archive/README_2026-11-09.md)
