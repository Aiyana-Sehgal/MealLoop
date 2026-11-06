---
paths:
  - "ios/MealLoop/**/*.swift"
  - "ios/MealLoopTests/**"
---

# Quality, testing and Definition of Done

Scope: building, testing and finishing iOS work. Facts below come from `ios/README.md`, `ios/MealLoop.xcodeproj` and `docs/adr/ADR-001-ios-architecture.md`.

## Build and test
- Project `ios/MealLoop.xcodeproj` (Xcode 16 or later; folder-synchronised groups, `objectVersion = 77`), scheme `MealLoop`, app target `MealLoop`, test target `MealLoopTests`, deployment target iOS 17.0, bundle identifier `in.mealloop.app` (a placeholder). No third-party packages.
- Configurations that exist: **Debug** (`DEBUG DEMO_DATA`: local seeded data) and **Release** (no `DEMO_DATA`: `RemoteAPI`, which throws "Not implemented"). **No reviewer-facing configuration exists yet** (ADR-005, prerequisite 6). Do not add one or change the build settings without the owner's direction.
- Find a simulator, then build and test. Never leave a placeholder name in a command:
```sh
xcodebuild -version
xcrun simctl list devices available            # pick an iPhone name from this list
xcodebuild -project ios/MealLoop.xcodeproj -scheme MealLoop \
  -destination 'platform=iOS Simulator,name=<name from the list>' build test
```
- These commands need macOS with Xcode. Without them, say so in your report: do not claim a build or a test run. Record the real `xcodebuild -version` and the summary lines of the real output when you report. The foundation's unit-test result is not yet recorded (`docs/FOUNDATION_REPORT.md`), so do not claim the baseline is green.

## Tests
- XCTest in `ios/MealLoopTests/`. Test ViewModels against fake repositories or the prototype data source; follow `KitchenHomeViewModelTests.swift` and `DemoEntryRepositoryTests.swift`.
- Critical paths need automated tests before a feature is complete (`docs/NFR.md`, NFR-TST-001): duplicate and concurrent entry handling, meal state and lifecycle, the two-hour response cutoff, the six-hour waste-edit window, missing-data handling (missing is not zero: `CountReading`, `LeftoverMeasurement`, `PlateWasteMeasurement`), headcount values staying separate, and failed or offline operations never reported as success.
- **"Verified" means all three:** a recorded build, a recorded test run, and a simulator walk-through of the screen. Anything less is "written" or "compiles".

## Accessibility (native SwiftUI)
Requirements: `docs/NFR.md` (NFR-ACC-001, NFR-ACC-002, NFR-ACC-004), PRD FR-STU-006.
- Every control has an accessibility label and the right trait; state (selected, disabled, loading) is announced. Test with VoiceOver.
- Support Dynamic Type: text scales and critical content and actions stay reachable. Do not fix font sizes where a text style is possible; the design tokens set the base sizes.
- Contrast follows the design tokens; never convey status by colour alone.
- Tap targets are at least 44 pt (`MLSize.hit`), staff primary buttons 56 pt (`MLSize.staffButton`).
- Respect safe areas; keep fields visible when the keyboard shows; honour Reduce Motion for any animation you add.
- Use native SwiftUI semantics only (no ARIA or HTML ideas).

## A screen is not complete because it compiles
It matches the named reference image; uses the shared models and contracts; navigates correctly; handles loading, empty, error, stale and offline states; shows data consistent with the other roles' screens; has no dead or misleading buttons; and runs in the simulator.

## Definition of Done report (end every implementation task with it)
1. Feature completed (and what is not).
2. Design reference followed (name the image from `design/reference/` or `design/audit/export*/`).
3. Files created or modified.
4. Shared components reused or added.
5. Contracts or models changed (repository protocols, `ios/MealLoop/Domain/`, OpenAPI).
6. The exact commands run and their results, including the Xcode version.
7. Visual checks done and the differences found (or "not captured" and why).
8. Remaining limitations and unresolved decisions.

No unverified claims. Do not hide warnings, failures or a broken build. If blocked, state the exact reason and the smallest next step.
