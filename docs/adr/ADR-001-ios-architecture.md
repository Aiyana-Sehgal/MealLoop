# ADR-001: iOS architecture

- Status: Proposed (2026-10-23)
- **Update (1 November 2026):** the owner treats the generated iOS foundation (this ADR's structure, the view models, repositories, models and design system) as an unreviewed draft. The frontend architecture is **PENDING REVIEW** and is tracked in [`FRONTEND_READINESS.md`](../architecture/FRONTEND_READINESS.md). The platform choice itself (one native SwiftUI iOS app for all 11 roles) is accepted in [ADR-003](ADR-003-approved-platform-backend-security.md); the decisions in this ADR are not.
- Branch: `feature/swiftui-foundation`

## Context

Four developers, most of them learning SwiftUI, must build many screens in parallel: 420 active exported screens and states (`docs/SCREEN_INVENTORY.md`), with the first target on 10 November 2026. The backend does not exist yet, and the app must not fake success when it does not. Android will follow later from the same contracts. The repository documents no minimum iOS version.

## Decision

1. **Minimum iOS 17.** This gives the Observation framework (`@Observable`), `@Bindable` and the current `NavigationStack` APIs. The design targets iOS 26 Liquid Glass, but that is a visual layer, not an API requirement, so it is not a reason to raise the minimum. Recorded as an open decision for the owner.
2. **One app target and one unit-test target**, with strict folders instead of Swift packages: `App`, `Core`, `DesignSystem`, `Domain`, `Data` (`Repositories`, `Demo`, `Remote`) and `Features/<Role>`. See `docs/REPOSITORY_STRUCTURE.md`.
3. **SwiftUI with `@Observable` view models, marked `@MainActor`.** Views are layout only. View models depend on repository protocols, never on concrete data. All I/O uses async/await.
4. **Repositories behind small async protocols** (`MealStateRepository`, `EntryRepository`, …), grouped in one `Repositories` value that `AppEnvironment` provides.
5. **One data source per build.** `AppEnvironment` picks `demo` (Debug) or `api` (every other configuration). Demo code is compiled only when the `DEMO_DATA` flag is set, which only the Debug configuration sets. A compile-time `#error` stops any build that sets `DEMO_DATA` without `DEBUG`. The `api` source (`RemoteAPI`) throws `notImplemented` for every call until the backend exists.
6. **`LoadState<T>` and `AsyncContentView`** render idle, loading, loaded, empty, failed with retry, stale and offline the same way on every screen.
7. **No third-party dependencies.**
8. **The project file is hand-written in the Xcode 16 format** (`objectVersion = 77`) with folder-synchronised groups, instead of using a generator. A file added under `ios/MealLoop/` or `ios/MealLoopTests/` joins its target with no project-file edit, which removes most `.pbxproj` merge conflicts. Markdown files inside the app folder are listed as exceptions so they are not copied into the app bundle.
9. **AI stays optional.** `IntelligenceService` is a separate protocol with no implementation, and no dining flow depends on it.

## Options considered

| Option | Why not now |
|---|---|
| Several Swift packages (Domain, DesignSystem, Features) | Faster incremental builds and enforced imports, but more setup, more failure modes and more concepts for a learning team. Extract packages later if build time or ownership demands it; the folder boundaries are already drawn so the move is mechanical. |
| The Composable Architecture or another framework | Powerful, but a third-party dependency and a steep learning curve before the first screen ships. |
| `ObservableObject` / `@Published` (iOS 16) | Older pattern with more boilerplate. iOS 17 adoption is not a constraint here; the owner can confirm. |
| XcodeGen or Tuist | Removes `.pbxproj` conflicts too, but every teammate needs the tool. Synchronised folders give most of the benefit with plain Xcode. |
| Demo data mixed into previews or views | Breaks the "never present sample data as real" rule and makes the switch to the API risky. |

## Consequences

- Building needs **Xcode 16 or later** (synchronised folders). Xcode 15 cannot open the project.
- Every new screen follows the same pattern as Kitchen Home: a Screen wrapper builds the view model from `AppEnvironment`, the view model loads through repositories into `LoadState`, and the view renders `AsyncContentView`.
- Release builds contain no demo code. Until the backend exists, a Release build shows "Not implemented" states instead of data.
- Folder boundaries are a convention, not compiler-enforced. Code review and `docs/REPOSITORY_STRUCTURE.md` enforce them until packages are extracted.
- **Verification status:** at the time of writing no Xcode build had been run (no macOS in the authoring environment). The owner has since reported a successful build and launch on their Mac; the unit-test result is not yet recorded. See `docs/FOUNDATION_REPORT.md`.
