# MealLoop iOS

SwiftUI app, minimum iOS 17, one app target (`MealLoop`) and one unit-test target (`MealLoopTests`), shared scheme `MealLoop`. Structure and rules: [`docs/REPOSITORY_STRUCTURE.md`](../docs/REPOSITORY_STRUCTURE.md).

> **Verified on 2026-11-06:** Debug and Release build, and all 40 unit tests pass (Xcode 27.2, iPhone 18 Pro simulator, iOS 27.2). Kitchen Home runs in the simulator; its content matches the reference, its visual match is partial. Evidence: [`docs/FOUNDATION_VERIFICATION.md`](../docs/FOUNDATION_VERIFICATION.md).

## Start here

- **Project and scheme:** `ios/MealLoop.xcodeproj`, scheme `MealLoop`.
- **Run:** open the project in Xcode, pick an iPhone simulator, press ⌘R.
- **Test:** ⌘U, or the command under [Command line](#command-line).
- **Where code belongs:**
  - Screens go in `MealLoop/Features/<Role>/`.
  - Reusable UI goes in `MealLoop/DesignSystem/Components/`.
  - Models go in `MealLoop/Domain/`, and only there.
  - Repository protocols go in `MealLoop/Data/Repositories/`.
  - Sample data goes in `MealLoop/Data/Demo/`, never in a View.
- **Branches and PRs:** one purpose per branch, named `<type>/<scope>-<short-description>`. Open one PR per branch. Never push to the default branch, force-push or merge your own work without review.
- **Shared files:** one person at a time edits `Domain/**`, `Data/Repositories/Repositories.swift`, `Core/Navigation/**`, `DesignSystem/Tokens/**`, `App/AppEnvironment.swift` and the demo seed and provider. Agree it with the owner before changing them. `Features/<Role>/` folders and new component files are safe to work on in parallel.

## Requirements

- **Xcode 16 or later.** The project uses folder-synchronised groups (`objectVersion = 77`); Xcode 15 cannot open it.
- An iOS 17 or later simulator runtime.
- No third-party dependencies and no generator to install.

## Build and run in Xcode

1. Open `ios/MealLoop.xcodeproj`.
2. Pick the `MealLoop` scheme and an iPhone simulator.
3. Run (⌘R). The Debug build uses the demo data provider and shows a black **Demo data** badge.
4. In the development launcher, choose **Mess staff** → **Kitchen Staff** → Continue → enter the simulated password `1234`. That is a placeholder, not from the design: see `docs/OPEN_DECISIONS.md`. Kitchen Home opens.
5. Tap **Demo data** to switch the simulated moment: before the meal (K01), during (K02), shortage reported (K03), entries stale, after the meal (K05), waste recorded, offline.
6. Run the tests with ⌘U.

## Command line

List the simulators installed on your Mac first and use one of their names:

```sh
xcrun simctl list devices available
```

Then build and test (replace `<an installed iPhone>` with a name printed above). `CODE_SIGNING_ALLOWED=NO` is what the recorded run used:

```sh
xcodebuild -project ios/MealLoop.xcodeproj -scheme MealLoop \
  -destination 'platform=iOS Simulator,name=<an installed iPhone>' \
  CODE_SIGNING_ALLOWED=NO build test
```

## Configurations

| Configuration | Data source | `DEMO_DATA` | Use |
|---|---|---|---|
| Debug | Demo provider (seeded sample data, labelled) | set | Development, demos, unit tests |
| Release | `RemoteAPI` (throws Not implemented until the backend exists) | not set | Pilot and production builds |

Setting `DEMO_DATA` in any configuration other than Debug stops the build with a compile error (`App/AppEnvironment.swift`).

## Signing

The bundle identifier `in.mealloop.app` is a placeholder and no development team is set. Simulator builds do not need either. For a device build, set your team under Signing & Capabilities locally, and do not commit personal team IDs. The final identifier is an open decision.
