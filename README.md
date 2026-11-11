# MealLoop

MealLoop is an AI-assisted institutional dining and student-engagement platform. It is designed to improve
meal-demand planning, reduce avoidable food waste, manage crowding at the mess and make student feedback lead to
visible corrective action.

**Today it is an interactive iOS prototype on seeded data**, for the external review (first pilot: Meenakshi Girls'
Mess, SRM). It is not a live system: there is no backend yet. A Spring Boot and PostgreSQL backend and an Android client
follow later (`CLAUDE.md`; `docs/adr/ADR-003-approved-platform-backend-security.md`,
`docs/adr/ADR-005-frontend-decisions-and-authentication-revision.md`).

## Which branch

Use **`main`**. It is the only branch (owner ruling, 9 November): the owner's sessions push green commits straight to
`main`, with CI (`.github/workflows/ios-ci.yml`) as the safety net. Contributors outside those sessions use pull
requests (see `CONTRIBUTING.md`). Old branches are kept as `archive/*` tags (`docs/BRANCH_ARCHIVE.md`).

## Run it

Setup, the schemes, the demo controls and the local checks are in **[`ios/README.md`](ios/README.md)**, the one
canonical place. In short: clone sparsely (the history is large), open `ios/MealLoop.xcodeproj`, choose
**MealLoop Review** and an iPhone simulator, and run. Every launch starts clean at Wed 14 Aug, 7:00 AM.

## What a reviewer can walk

- **Getting started.** Students: Welcome → Sign in with SRM → Getting your details → Home (a failure offers Try again).
  Mess staff: Staff sign in → Choose your role → What you do → the role's password → Home.
- **One shared story.** The Demo states sheet (the small **Demo** chip on Welcome, or **Demo states** in Me, You or
  More) switches role without losing data or time: a student's answer, an approved and sent headcount, a closed meal or
  a waste report made in one role is what the next role sees.
- **The core path.** Student answers breakfast and rates a meal → Food Head approves and sends the headcount → Vendor
  acknowledges → Supervisor starts and closes lunch → Kitchen records waste. Outings: Student asks → Guardian answers →
  Warden → Gate.

## Roles and what is built

| Role | State |
|---|---|
| Student | Built. Home, Meals, Community, You, SOS (2162 flow), ratings, Outings |
| Food Head (Admin) | Built, own mess only (Today: mess tile and Needs you) |
| Super Admin | Today with all four messes and Send for any mess; People and access |
| Supervisor, Kitchen, Door Scanner, Pass Desk | Built; Alerts show each role's own events |
| Vendor | Built: Home, History, Me; acknowledges the headcount the Food Head sends |
| Guardian, Warden, Gate security | Built; Guardian sign-in is simulated |

Verification of this build: [`docs/verification/review/PROGRESS.md`](docs/verification/review/PROGRESS.md) and the
screen-by-screen [`docs/verification/review/AUDIT.md`](docs/verification/review/AUDIT.md). Designs: the
[MealLoop Figma file](https://www.figma.com/design/nzzTAm9YnJRSdKEeYUWUEb/MealLoop) (Student prototype, Admin redesign
`2237:2`, Mess Staff `732:2`, Guardian `1849:1679`, Warden `1853:9`, Gate `1857:137869`).

## Known gaps

No backend: every Release-build call fails on purpose and nobody can sign in. SRM sign-in, guardian SMS, camera
scanning, video capture and vendor delivery are simulated or unverified; nothing is sent to anyone. Camera, haptics and
device feel are not verified on a physical iPhone. Student screens do not grow with the largest text sizes. Open
questions: `docs/OPEN_DECISIONS.md`.

## Folders

| Folder | What it holds |
|---|---|
| `ios/` | The SwiftUI app (iOS 17), its unit tests, the asset catalogs and the bundled fonts |
| `docs/` | Product, architecture, process and verification documents (index: `docs/README.md`) |
| `design/` | Design notes and reference packs (text). Design images live in the separate repository `MealLoop-design` |

No image files may be committed outside `ios/`; the commit-rules CI check fails a push that adds one.

## More

- Documents index: [`docs/README.md`](docs/README.md)
- How to contribute: [`CONTRIBUTING.md`](CONTRIBUTING.md)
- The earlier, longer README: [`docs/archive/README_2026-11-09.md`](docs/archive/README_2026-11-09.md)
