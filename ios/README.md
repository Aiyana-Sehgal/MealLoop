# MealLoop iOS

SwiftUI app, minimum iOS 17, one app target (`MealLoop`) and one unit-test target (`MealLoopTests`), shared scheme `MealLoop`. Structure and rules: [`docs/REPOSITORY_STRUCTURE.md`](../docs/REPOSITORY_STRUCTURE.md).

> **Review status (1 November 2026).** The owner treats this foundation (structure, view models, repositories, models, design system and its OpenAPI counterpart) as an **unreviewed draft**. The frontend architecture is PENDING REVIEW ([`docs/architecture/FRONTEND_READINESS.md`](../docs/architecture/FRONTEND_READINESS.md)). The Debug "Demo data" badge, the simulated-moment menu and the simulated shared role password described below are developer tools, not the reviewer-facing interface.

> **Build status (owner-reported).** The project was written in an environment without macOS or Xcode. The owner reports that it was built and launched on their Mac. The unit-test result is not yet recorded, and no build log is stored in this repository. Record the real `xcodebuild` and test output in `docs/FOUNDATION_REPORT.md`.

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

## Command line (not yet run; to be confirmed on a Mac)

List the simulators installed on your Mac first and use one of their names:

```sh
xcrun simctl list devices available
```

Then build and test (replace `<an installed iPhone>`, for example the name printed above):

```sh
xcodebuild -project ios/MealLoop.xcodeproj -scheme MealLoop \
  -destination 'platform=iOS Simulator,name=<an installed iPhone>' \
  build test
```

## Configurations

| Configuration | Data source | `DEMO_DATA` | Use |
|---|---|---|---|
| Debug | Demo provider (seeded sample data, labelled) | set | Development, demos, unit tests |
| Release | `RemoteAPI` (throws Not implemented until the backend exists) | not set | Pilot and production builds |

Setting `DEMO_DATA` in any configuration other than Debug stops the build with a compile error (`App/AppEnvironment.swift`).

## Signing

The bundle identifier `in.mealloop.app` is a placeholder and no development team is set. Simulator builds do not need either. For a device build, set your team under Signing & Capabilities locally, and do not commit personal team IDs. The final identifier is an open decision.
