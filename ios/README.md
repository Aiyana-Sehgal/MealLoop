# MealLoop iOS

SwiftUI app, minimum iOS 17, one app target (`MealLoop`) and one unit-test target (`MealLoopTests`). Structure and
rules: [`docs/REPOSITORY_STRUCTURE.md`](../docs/REPOSITORY_STRUCTURE.md). This file is the one place for setup.

> **Verified on 2026-11-11** (Xcode 27.2 27B52, iPhone 18 Pro Max and iPhone SE simulators, iOS 27.2): Debug tests
> 821 passed, Review tests 821 passed, Release build succeeds. Walkthrough and evidence:
> [`docs/verification/review/PROGRESS.md`](../docs/verification/review/PROGRESS.md) and
> [`AUDIT.md`](../docs/verification/review/AUDIT.md).

## Get the code

The history is large, so clone only what you need:

```sh
git clone --filter=blob:none --no-checkout --depth 1 --no-tags https://github.com/VeeraaVikash/MealLoop.git
cd MealLoop
git sparse-checkout set --cone ios docs .github .claude
git checkout main
```

`ios` and `.github` alone are enough to build and test; `docs` holds the verification records.

## Requirements

- **Xcode 16 or later** (verified on 27.2). The project uses folder-synchronised groups (`objectVersion = 77`).
- An iOS 17 or later iPhone simulator. No third-party dependencies and no generator to install.

## Run the review build

1. Open `ios/MealLoop.xcodeproj`, choose the scheme **MealLoop Review** and an iPhone simulator, press ⌘R.
2. The app opens on Welcome at **Wed 14 Aug, 7:00 AM**. The clock then runs in real time; nothing jumps it.
   All data is in memory and resets on every launch.
3. **Getting started** is the real sign-in. Students: **Sign in with SRM** → Getting your details → Home.
   Mess staff: **Staff sign in** → Choose your role → What you do → shared password **1234** → Home (3 wrong tries lock
   it). Food Head, Super Admin, Vendor, Guardian, Warden and Gate: **Sign in with email** under the roles; accounts are
   in [`docs/PRESENTER_ACCOUNTS.md`](../docs/PRESENTER_ACCOUNTS.md).
4. **Demo states.** The small **Demo** chip on Welcome (and on the Guardian page), or the **Demo states** row in Me, You
   or More, opens a sheet:
   - **Getting started** signs out and opens a sign-in step, including a one-time failed SRM sign-in.
   - **Switch role (keeps data)** opens any role's normal Home. Answers, entries, headcounts, waste reports, outings
     and the time are kept.
   The sheet exists only in Debug and Review; the Release binary does not contain it.

### Seeded data

Sample values only, never measured results: one student (Aarav), four messes with sample headcounts, the lunch menu
and forecast (860), sample earlier meals and reviews. Breakfast starts unanswered; lunch is not started; outings start
empty. Lunch answers close at 10:00 AM; breakfast stays open until its service ends (the per-meal cutoffs are an open
owner decision). Only Main Mess lunch has a vendor account.

## Local checks

```sh
xcrun simctl list devices available
```

```sh
xcodebuild test -project ios/MealLoop.xcodeproj -scheme MealLoop -destination 'platform=iOS Simulator,name=<an installed iPhone>' CODE_SIGNING_ALLOWED=NO
```

```sh
xcodebuild test -project ios/MealLoop.xcodeproj -scheme "MealLoop Review" -destination 'platform=iOS Simulator,name=<an installed iPhone>' CODE_SIGNING_ALLOWED=NO
```

```sh
xcodebuild build -project ios/MealLoop.xcodeproj -scheme MealLoop -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

For verification runs, Debug and Review also accept the launch argument `-demoRole <role>` (for example `kitchenStaff`),
which opens that role's Home as Switch role does.

CI (`.github/workflows/ios-ci.yml`) runs the same three checks on every push to `main` and every pull request, from a
sparse checkout of `ios` and `.github`, and keeps the test result bundles for 7 days. A second job checks commit
messages (Conventional Commits, no co-author or tool trailers) and tracked junk files.

## Configurations

| Configuration | Scheme | Data source | Flags |
|---|---|---|---|
| Debug | `MealLoop` | Seeded provider and the Demo states sheet | `DEBUG DEMO_DATA` |
| Review | `MealLoop Review` | The same seeded provider and sheet | `REVIEW_DATA REVIEW_CONFIGURATION` |
| Release | `MealLoop`, `-configuration Release` | `RemoteAPI`: every call fails until the backend exists, so nobody can sign in | none |

`App/AppEnvironment.swift` stops the build if `DEMO_DATA` appears without `DEBUG`, if `REVIEW_DATA` appears without
`REVIEW_CONFIGURATION`, or if the two are combined. `BuildConfigurationTests` checks the flags, including that Release
has none.

## Where code belongs

- Screens: `MealLoop/Features/<Role>/`. Reusable UI: `MealLoop/DesignSystem/Components/`.
- Models: `MealLoop/Domain/`. Repository protocols: `MealLoop/Data/Repositories/`.
- Sample data: `MealLoop/Data/Demo/`, never in a View.
- Fonts: Inter and JetBrains Mono in `MealLoop/Resources/Fonts` with their OFL notices, registered by
  `DesignSystem/Tokens/MLFonts.swift`. Only the weights the app uses are bundled.

## Known gaps

SRM sign-in, guardian SMS, camera scanning and video capture are simulated, and nothing reaches a vendor or a phone.
Camera, haptics and device feel are not verified on a physical device. Student screens use fixed text sizes and do not
grow with the largest accessibility sizes. The app runs in Light: it has no dark theme.

## Signing

The bundle identifier is a placeholder and no development team is committed. Simulator builds need neither. For a
device build, set your team under Signing & Capabilities locally and do not commit it.
