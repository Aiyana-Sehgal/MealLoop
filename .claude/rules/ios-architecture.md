---
paths:
  - "ios/MealLoop/**/*.swift"
---

# iOS architecture (ADR-005 as working rules)

Scope: all app Swift code. Source: `docs/adr/ADR-005-frontend-decisions-and-authentication-revision.md` (Accepted for the listed choices FE-1 to FE-6) and ADR-003. **Not yet decided (FE-7, FE-8):** shared-state ownership and updates, role-aware navigation and routing, app-wide session UI, delivery scope, team ownership. Do not invent those; if a task needs one, stop and ask. The generated foundation in `ios/` (structure, models, repositories, `RemoteAPI`, the OpenAPI draft) is an **unreviewed draft**: follow its patterns for new code, but never treat an existing signature as an approved contract.

## Layers and responsibilities
- **Organization (FE-1):** role-oriented presentation (`Features/<Role>/`) over one shared set of business models, repository contracts and workflows. One app target for all 11 roles; never an app target or a duplicated model set per role.
- **Views** own presentation and user input only. No networking, no business rules.
- **ViewModels** (`@MainActor`, `@Observable`) own screen state and delegate data work to repositories. They do not decide business rules such as duplicate entries, cutoffs, meal state or edit windows. Those belong to the domain types and, in the prototype, to the local prototype data source that mirrors server behaviour (the real server stays authoritative later). Create a ViewModel only for a screen with real logic; a static screen needs none.
- **Repositories** isolate data access behind protocols in `ios/MealLoop/Data/Repositories/`. Remote adapters may map API DTOs into domain models. Repositories never drive SwiftUI navigation, and no view calls HTTP.
- **Use cases** only for a justified complex workflow. Do not add a service layer for a simple operation.
- **Models (FE-5):** one canonical set in `ios/MealLoop/Domain/` plus feature-specific presentation state. Never define a second `Meal`, `Role`, `Headcount`, `EntryRecord` or similar inside a feature folder. A change to a shared model needs review by a teammate (`docs/REPOSITORY_STRUCTURE.md`).
- **Contracts (FE-6):** review and share the Swift repository contracts and keep the OpenAPI specification in step; handwritten local and remote adapters for now. A generated client is optional later. Existing protocol methods and endpoints are drafts.

Dependency direction: `Features` depend on `Domain` and on repository protocols, never on `ios/MealLoop/Data/Demo` or `ios/MealLoop/Data/Remote` concrete types. `Data` depends on `Domain`. `Domain` imports no UI and no `Data`. `DesignSystem` and `Core` import no feature.

## Dependency injection (FE-3)
- Manual constructor injection by default; one composition root (`ios/MealLoop/App/AppEnvironment.swift`).
- SwiftUI `Environment` only for genuinely app-wide observable state (for example `AppEnvironment`, `AppRouter`). A feature's ViewModel takes its repositories and an `AppClock` in its initializer; use the clock for "now", never `Date()` in a ViewModel.
- No global singleton repositories, no static shared mutable state, no third-party DI library. Shared instances are created by the composition root and passed in.

## State management
- `@Observable` (iOS 17) and `@MainActor` ViewModels; `@State` for view-owned state; `@Binding` for explicit parent-child state. Do not use `ObservableObject` or `@Published` in new code.
- Load through `LoadState` and render through `AsyncContentView` so loading, empty, failed, stale and offline look the same on every screen.
- Guard against double taps: every action that writes sets an in-progress state and ignores repeats until it finishes.
- One coherent local data source serves the whole prototype, so an action on one role's screen (for example a simulated scan) is reflected on the others. Never hardcode a count in a screen. The pattern is `ios/MealLoop/Data/Demo/DemoDataProvider.swift`; extend it through review.

## Navigation
- Reuse `ios/MealLoop/Core/Navigation/AppRouter.swift` (`AppSurface`, `StaffTab`, `StaffRoute`). The foundation has six surfaces and nine roles against the eleven approved roles: extending them is a shared-contract change.
- Hiding a button is not security. The backend enforces role, resource and mess or hostel scope; the client only presents what the signed-in role may do.
- Any developer-only role switch stays isolated from production authentication (see `contracts-and-security.md`).

## Comments
Short doc comments (`///`) on public and shared APIs, repository methods and concurrency-sensitive code, explaining **why**. No trivial comments, no commented-out code, no stale comments. Update or delete a comment when you change the code it describes.

## Stack
Swift, SwiftUI, iOS 17 minimum, Observation, async/await, XCTest. No third-party packages and no web frameworks or JavaScript-style state managers without owner approval. Do not use an API newer than iOS 17 without an availability check.
