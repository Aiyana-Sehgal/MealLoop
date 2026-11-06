# Foundation report (Stage 1, Task 01)

Branch `feature/swiftui-foundation`, created from `claude/mealloop-ios-design-e9n1n5` at `85cedc4`. Written on 2026-10-23.

## Current status

**The foundation was built, tested and run on a Mac on 2026-11-06.** Debug and Release build, and all 40 unit tests pass, with no code change needed. Commands, results, screenshots and the visual differences are in [`FOUNDATION_VERIFICATION.md`](FOUNDATION_VERIFICATION.md).

This report was written before that, in a Linux container with no macOS, no Xcode and no simulator. Sections below describe the work as it stood then, unless they say otherwise.

## What was found before writing

- **Existing code:** none. The repository held only `design/` and the root `README.md`. No `*.xcodeproj`, `Package.swift`, `*.swift`, `docker-compose.yml`, `pom.xml` or `build.gradle` existed, and no CI. The `.js` and `.py` files under `design/audit/tools/` are Figma audit scripts. Nothing was deleted or overwritten.
- **Active requirements:** the latest pack per role.
  - Door Scanner: `door_scanner_2026-10`, pack v2 with D17 and D18.
  - Pass Desk: `pass_desk_2026-10`.
  - Kitchen: `kitchen_2026-10`, pack v2 (K19 and K20 in v3 are not drawn yet).
  - Supervisor: `supervisor_2026-10`.
  - Guardian and Warden: `guardian_2026-10` (video approval).
  - Admin: page 12 from `admin_redesign_2026-10` plus `fix2_2026-10`.
  - Student: page 04 from `redesign_2026-10` plus POLISH and FIX-2.
  - Gate: the GA-* frames.
- **Archived (not requirements):**
  - Page 99, which grew by 455 frames in STUDENT-REDESIGN alone, plus the frames listed in each `archive_index.md`. That includes the 52 admin frames archived by FIX-2, the Kitchen v1 approval loop and the old Door Scanner, Pass Desk, Supervisor, Guardian and Warden frames.
  - Guardian slide-to-approve.
  - The pre-redesign Lab student export (`design/audit/export/`).
- **Needs review (documents disagree):**
  - The student Crowd page: POLISH added one, while STUDENT-REDESIGN says there is no crowd screen.
  - Old admin page 10, which is superseded but not archived and still has flow starts.
  - Stale Dark page 05.
  - Older renders of the gate and outing screens.
  - K19 and K20, which are in the pack but not drawn.
  - Older documents that describe replaced decisions: a kitchen recommended plan, supervisor plan changes, "Hold to Confirm" for the special pass, and the old admin tabs.
  - The sample cutoff "Decide by 9 AM" on the student Home export, which predates the two-hours-before rule.

  All of these are listed in `docs/SCREEN_INVENTORY.md` and `docs/OPEN_DECISIONS.md`.

## What was implemented

### Deliverable A: `docs/SCREEN_INVENTORY.md`

Generated from the file → frame tables in the twelve `design/audit/export*/README.md` files. All 524 listed PNGs exist. Each row was cross-checked against every archive index.

| Role / feature area | Active rows |
|---|---|
| Shared staff entry | 7 |
| Student | 38 |
| Student · Outings | 9 |
| Admin (Food head) | 87 |
| Door Scanner | 38 |
| Pass Desk | 46 |
| Kitchen | 69 |
| Supervisor | 45 |
| Guardian | 41 |
| Warden | 22 |
| Gate | 18 |
| **Total active** | **420** (P0 109, P1 208, P2 90, P3 13; all proposed) |

- 20 rows need review, three of which stand for whole Figma pages. 89 rows are archived.
- Grouped by reference-image number, the 420 rows are 149 distinct base screens.

### Deliverable B: the SwiftUI foundation (`ios/`)

- **Project:** `ios/MealLoop.xcodeproj`, hand-written in the Xcode 16 format with folder-synchronised groups.
  - One app target and one unit-test target, plus a shared `MealLoop` scheme.
  - Minimum iOS 17, Swift 5 language mode, no dependencies.
  - Debug sets `DEMO_DATA`; Release does not.
- **App/:** the `@main` app, `AppEnvironment` (demo or api), `AppClock`, root routing and a development launcher for the six apps.
  - `#error` stops any build that sets `DEMO_DATA` without `DEBUG`.
- **Core/:** `AppRouter` (surfaces, staff entry path, Home / Alerts / Me tabs, `StaffRoute`), `LoadState<T>`, `LoadFailure`, `AsyncContentView` and `MLFormat`.
- **DesignSystem/:**
  - Tokens: colour, type, spacing, radius and size. Values come from the documented ML variables and the measured export colours; see "Tokens" below.
  - Components: `OrbitBackground`, built from the documented geometry.
  - Components: `StaffHeader`, `ScreenTitleBlock`, `HeroCard`, `HeroEyebrow` and `HeroCount`.
  - Components: `LimeActionButton` and `InkActionButton`, both 56 pt.
  - Components: `QuietRow`, `StatusText` (dot plus plain text), `MealProgressChip`, `ShortageRow`, `StaffTabBar` (Home, Alerts, Me) and `KeyPad`.
  - Components: the loading, empty, error-with-retry, offline, stale and Not implemented views, plus the `DemoDataBadge`.
- **Domain/:** one shared, `Sendable`, `Codable` model set.
  - Meals and state: `Role`, `Mess`, `MealSlot`, `MealState`, `Meal`, `MealStatus`, `Dish` and `WasteUnit`.
  - Readings that may be missing: `CountReading`, `LeftoverMeasurement` (entered, noneLeft, notMade, notEntered) and `PlateWasteMeasurement`.
  - Planning and entry: `MealIntention` with `IntentionResponse` and the cutoff policy, `Headcount` (forecast, sent with adjustments, vendor reply), `EntryRecord`, `EntryResult` and `EnteredWithoutVoting`.
  - Mess operations: `SpecialPass` with its live code and reissue status, `Shortage` (level, delivery, status), `WasteReport` with its 6-hour edit policy, and `SOSCase` (claim, checks, close by the Supervisor only).
  - Feedback: `Feedback`, `CommunityIssue` (Fixed only with a recorded corrective action) and the follow-up statuses.
  - Outings: `OutingRequest` with an event-driven state machine, and `GuardianEvidence` (video, video needing review, photo and text, call; no text-only case exists).
  - Staff: `StaffSession`.
- **Data/:**
  - Repository protocols for meals, meal state, headcount, entries, intentions, shortages, waste reports, SOS and auth.
  - Documented empty stubs for feedback, community, special passes and outings, plus a separate optional `IntelligenceService`.
  - `RemoteAPI`: every method throws `notImplemented`.
  - `DemoDataProvider`: an actor compiled only with `DEMO_DATA`, seeded from the kitchen, supervisor and door scanner specs. It has seven simulated moments, idempotent entries that reject duplicates, never records an offline scan, and simulates the role password with 3 tries then a lock.
- **Features/:**
  - `StaffEntry` (Choose your role, What you do sheet, shared password) is a navigation scaffold whose copy comes from the exports.
  - `Staff`, the shared staff shell: Alerts and Me are "Not implemented", and Me offers Sign out.
  - **`Kitchen`, the representative screen:** Kitchen Home before, during, with a shortage reported, with stale entries, after the meal, and with waste recorded.
  - A README in each of the other eight feature folders.
- **MealLoopTests/:** 5 files, 40 test methods.

  | Test file | What it covers |
  |---|---|
  | `MeasurementTests` | Missing never becomes zero |
  | `DemoEntryRepositoryTests` | Duplicate entry rejected, idempotent replay, offline records nothing, entered without voting, scanning closed before the meal, final entries unavailable until closed, only the Supervisor closes, incomplete waste not saved, password lock |
  | `AppEnvironmentTests` | Demo in Debug, api has no demo, Remote throws Not implemented |
  | `KitchenHomeViewModelTests` | Forecast only before, entries only during, shortage row, stale, after, edit window, offline |
  | `DomainRulesTests` | Cutoff, outings, guardian evidence, Community, formatting |

### Deliverable C: backend preparation (documents only)

- `docs/backend/BACKEND_PROPOSAL.md`: a modular monolith (Spring Boot, PostgreSQL) with the modules `dining-core`, `mess-ops`, `outings`, `notifications` (outbox) and a later optional `intelligence`. It covers data ownership, why microservices, Kafka and Kubernetes are not used now, and the reliability principles.
- `docs/backend/openapi.yaml`: 12 operations covering the staff session, meals, intention, headcount, meal state with start and close, entries (idempotency key, 409 duplicate), entry count, shortage, and waste report get and save.

### Other documents

`docs/REPOSITORY_STRUCTURE.md`, `docs/adr/ADR-001-ios-architecture.md`, `docs/adr/ADR-002-backend-shape.md`, `docs/OPEN_DECISIONS.md` (18 product and 12 technical decisions) and `ios/README.md`.

## What was verified (real output, this environment)

These checks ran here. They prove syntax and structure only, not that the app compiles.

```text
$ python -I swift_syntax.py ios          # tree-sitter Swift grammar over every .swift file
51 files, 0 with syntax errors

$ python -I swift_syntax.py negtest      # negative control: a deliberately broken file
negtest/bad.swift [(2, ')', b''), (3, ']', b'')]
1 files, 1 with syntax errors

$ python -I -c "XcodeProject.load('ios/MealLoop.xcodeproj/project.pbxproj') …"   # pbxproj library
MealLoop com.apple.product-type.application ['Debug', 'Release']
MealLoopTests com.apple.product-type.bundle.unit-test ['Debug', 'Release']

$ python -I -c "minidom.parse('…/MealLoop.xcscheme')"
MealLoop.xcscheme: well-formed XML

$ openapi-spec-validator docs/backend/openapi.yaml
docs/backend/openapi.yaml: OK

$ grep -rnE "\b(860|714|774)\b|Ravi|Main Mess|0238|Steamed Rice|1234" App Core DesignSystem Domain Features Data/Repositories Data/Remote
(only five documentation comments; no sample value in code outside Data/Demo)

$ grep -rn "Color(hex\|#[0-9A-Fa-f]{6}" ios/MealLoop/Features
none
```

- Every file in `Data/Demo/` starts with `#if DEMO_DATA`. The only other file that names the demo provider is `App/AppEnvironment.swift`, and only inside `#if DEMO_DATA`.
- The tree-sitter grammar does not type-check. Wrong argument labels, missing members, actor-isolation errors or Swift 5 vs 6 differences would not be caught. I reviewed the code by hand for these, but that is not a build.

## Verification on a Mac

| Check | Result (2026-11-06) |
|---|---|
| Build | Succeeded |
| Unit tests | 40 passed, 0 failed |
| Simulator run and visual check against `K01`, `K02`, `K03`, `K05` | Run. Content matches; the visual match is partial |
| Release build has no demo code | Succeeded; `DEMO_DATA` is not set in Release |

Details: [`FOUNDATION_VERIFICATION.md`](FOUNDATION_VERIFICATION.md).

## Representative screen: Kitchen Home compared with the reference

I compared the code with `design/reference/kitchen_2026-10/images/K01–K05` and the exports `design/audit/export_kitchen/K01, K02, K03, K05@2x.png`. This list was made by reading the code against the images, before any render existed. The comparison of the running app is in [`FOUNDATION_VERIFICATION.md`](FOUNDATION_VERIFICATION.md) and takes priority.

| Area | Reference | Implementation | Difference |
|---|---|---|---|
| Counting rules | During: "LIVE · 1:40 PM", 714, "students entered"; no forecast; no "recorded at the door" | The same; the type makes a forecast impossible in the during phase (`KitchenHomePhase`) | None intended |
| Before | "FORECASTED ATTENDANCE", 860, "expected diners"; rows Menu for Lunch, Past meals | The same; "—" and "Forecast not ready yet" when not ready | Row actions open "Not implemented" |
| Shortage row | Pot icon, "Steamed Rice, almost out", "Sent 1:30 PM"; no row when none | The same text; SF Symbol `frying.pan` | Icon is a stand-in |
| After | "● MEAL CLOSED", "Lunch has ended", "Final entries 774"; Waste report "○ Not started" + Record waste | The same; "Unavailable" instead of a number when missing | Record waste opens "Not implemented" |
| Meal chip | Lime chip with ink outline "Meal in progress · 1 h 40 min" | The same | Height estimated (36 pt) |
| Header | Plate-loop mark + "MealLoop", black avatar with lime initials | Approximate mark drawn with shapes | Final logo pending |
| Tab bar | White capsule, Home / Alerts / Me with drawn icons | The same layout with SF Symbols | Icons are stand-ins |
| Typography | Inter / JetBrains Mono in Figma (stand-ins for SF) | SF Pro / SF Mono; hero number 56 pt is estimated from the export | Sizes not measured |
| Background | Orbit | `OrbitBackground` from the documented geometry | Not visually checked |
| Debug badge | — | Black "Demo data" badge, Debug only | Intentional |

## Tokens

- **Documented and confirmed by the export colours:**
  - canvas `#EDEDE8`, surface `#FFFFFF`, fill-quiet `#F2F2EC`, ink `#111111`, ink-secondary `#5C5C58`;
  - border `#D6D6D0`, track `#E1E1DA`, lime `#D4F25A`, on-lime and lime-outline `#111111`, hero-bg `#111111`;
  - spacing 4–32 with a 20 margin; radius card 24, compact 16, icon 12, input 12, pill 999;
  - button 52 / 48, hit 44, icon square 40, staff 56.
- **Measured, not named in any document:**
  - on-hero `#FFFFFF` and on-hero-secondary `#B5B5AE`, from the K02 export;
  - danger `#B32635`, from the D03 export.
- **Hinted in the brief but not in the design:** `#FBFBF4` and `#E8E7DE`. Neither appears in the exports or the documents, so they were **not** added.

## Known limitations

- The intermediate commits on this branch are not meant to build on their own; only the branch tip is the intended state.
- Staff entry screens are a navigation scaffold: their wording matches the exports, but their layout was not compared.
- Alerts, Me, SOS, the shortage sheet, Record waste, Menu, Past meals, and every other role's screens are **Not implemented**.
- The project file was hand-written. Xcode 27.2 builds it as committed.
- The root `README.md` still says the repository holds no app code. This branch adds iOS code, so its status table will need an update; a separate task owns that file, and it was not edited here.

## What remains

1. Owner decisions in `docs/OPEN_DECISIONS.md`, especially T1 (minimum iOS), P5 (offline policy) and the scope for 10 November.
2. Build the P0 slice from the inventory, then P1.
3. Start the backend skeleton from `docs/backend/`.
