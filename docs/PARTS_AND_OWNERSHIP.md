# Parts and ownership

How the iOS work is split so several people can build at once without conflicts.

**Part owners are not assigned yet.** Add a name to each row before that part starts.

## Parts

| Part | Scope | Folder | Reference | Owner |
|---|---|---|---|---|
| 0 | Baseline verified and PR stack merged | Not applicable | Not applicable | Repository owner |
| 1 | Entry, roles and the Review build | `Features/Entry/`, `Features/Shell/` | `redesign_2026-10` | Done |
| 2a | Core-story contracts and shared prerequisites | Shared files | Not applicable | Repository owner |
| 2b | Shared components from the reference packs | `DesignSystem/Components/` | All packs | Unassigned |
| 3a | Student Home, answer and QR | `Features/Student/` | `redesign_2026-10` | Unassigned |
| 3b | Student Meals and menu, with the dish filter behind Search | `Features/Student/` | `redesign_2026-10` | Unassigned |
| 3c | Student Community and feedback | `Features/Student/` | `redesign_2026-10` | Unassigned |
| 3d | Student You, credits and attendance | `Features/Student/` | `redesign_2026-10` | Unassigned |
| 3e | Student Crowd, notifications and SOS | `Features/Student/` | `redesign_2026-10` | Unassigned |
| 3f | Student outing request | `Features/Student/` | `guardian_2026-10`, inventory rows "Student · Outings" | Unassigned |
| 4a | Door Scanner | `Features/DoorScanner/` | `door_scanner_2026-10` | Unassigned |
| 4b | Kitchen: finish Home, then record waste, shortage, history | `Features/Kitchen/` | `kitchen_2026-10` | Unassigned |
| 4c | Supervisor | `Features/Supervisor/` | `supervisor_2026-10` | Unassigned |
| 4d | Pass Desk | `Features/PassDesk/` | `pass_desk_2026-10` | Unassigned |
| 5 | Admin: Today and headcount, Students and Results, More | `Features/Admin/` | `admin_redesign_2026-10`, `fix2_2026-10` | Unassigned |
| 6a | Guardian | `Features/Guardian/` | `guardian_2026-10` | Unassigned |
| 6b | Warden | `Features/Warden/` | `guardian_2026-10` | Unassigned |
| 6c | Gate Security | `Features/Gate/` | `design/audit/export_guardian_video/` (GA frames) | Unassigned |
| 6d | Vendor | `Features/Vendor/` | None: mock in chat, owner approves, then SwiftUI | Unassigned |
| 6e | Super Admin | `Features/SuperAdmin/` | None: mock in chat, owner approves, then SwiftUI | Unassigned |
| 7 | Wiring across roles, polish against every reference, accessibility, rehearsal | Any, through the shared-file owner | All | Unassigned |

Parts 3a to 3f share one folder. Agree file names first, and keep one screen per file.

## Shared files: one owner only

Only one person edits these at a time. Everyone else asks that person for the change. Each change here needs review by a teammate.

- `ios/MealLoop/Domain/**`
- `ios/MealLoop/Data/Repositories/Repositories.swift`
- `ios/MealLoop/Core/Navigation/**`
- `ios/MealLoop/DesignSystem/Tokens/**`
- `ios/MealLoop/App/AppEnvironment.swift` and `ios/MealLoop/App/AppClock.swift`
- `ios/MealLoop/Core/Session/**` and `ios/MealLoop/Core/LoadState/**`
- `ios/MealLoop/Features/Shell/RoleRootView.swift`
- `ios/MealLoop/Data/Demo/DemoSeed.swift` and `ios/MealLoop/Data/Demo/DemoDataProvider.swift`
- `ios/MealLoop/DesignSystem/Components/**`, listed in [`COMPONENT_CATALOG.md`](COMPONENT_CATALOG.md)
- `ios/MealLoop/DesignSystem/Gallery/**`
- `docs/COMPONENT_CATALOG.md`

**Adding or changing a shared component goes through the shared-file owner.** Check the catalog first. If nothing fits, send the owner the reference image and the roles that need it. A view only your role needs stays in `Features/<Role>/`.

**Shared-file owner:** the repository owner (VeeraaVikash), for every file above.

`DemoDataProvider.swift` is the file most parts will need. Batch requests for it rather than sending one at a time.

## Safe to work on in parallel

- `ios/MealLoop/Features/<Role>/` for your own role only.
- New test files in `ios/MealLoopTests/`.

Every role has its own root file in its own folder (for example `Features/Student/StudentRootView.swift`). A part replaces its placeholder by changing the body of that file. **Parts 3 to 6 never edit `RoleRootView.swift`.** A staff role passes its Home to `StaffRootView` in its own root file.

## Branches and worktrees

Each feature session uses its own branch and its own `git worktree`. Never share one checkout between sessions, because switching branches under another session loses its place.

```sh
git fetch --all --prune
git worktree add -b feat/student-home ../MealLoop-student-home origin/feat/ios-app-entry
cd ../MealLoop-student-home
```

Branch from `feat/ios-app-entry` until it merges, then from its merged base. Remove a worktree with `git worktree remove <path>` once its PR has merged.

- One purpose per branch and one PR per branch.
- Name branches `<type>/<scope>-<short-description>`.
- Never force-push, rewrite history or commit to the default branch.
