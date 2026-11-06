# Parts and ownership

How the remaining iOS work is split so several people can build at once without conflicts. Parts 1 and 2 are the foundation and the entry work on `chore/ios-baseline` and `feat/ios-app-entry`.

**Owners are not assigned yet.** Add a name to each row before that part starts.

## Parts

| Part | Scope | Folder | Reference | Owner |
|---|---|---|---|---|
| 3a | Student Home, meal answer and entry QR | `Features/Student/` | `redesign_2026-10` | Unassigned |
| 3b | Student Meals | `Features/Student/` | `redesign_2026-10` | Unassigned |
| 3c | Student Community and feedback | `Features/Student/` | `redesign_2026-10` | Unassigned |
| 3d | Student SOS with proof | `Features/Student/` | `redesign_2026-10` | Unassigned |
| 3e | Student You, credits and notifications | `Features/Student/` | `redesign_2026-10` | Unassigned |
| 3f | Student outings | `Features/Student/` | `guardian_2026-10`, inventory rows "Student · Outings" | Unassigned |
| 4a | Door Scanner | `Features/DoorScanner/` | `door_scanner_2026-10` | Unassigned |
| 4b | Kitchen (the rest; Home exists) | `Features/Kitchen/` | `kitchen_2026-10` | Unassigned |
| 4c | Supervisor | `Features/Supervisor/` | `supervisor_2026-10` | Unassigned |
| 4d | Pass Desk | `Features/PassDesk/` | `pass_desk_2026-10` | Unassigned |
| 5 | Admin (Food Head) | `Features/Admin/` | `admin_redesign_2026-10`, `fix2_2026-10` | Unassigned |
| 6a | Guardian | `Features/Guardian/` | `guardian_2026-10` | Unassigned |
| 6b | Warden | `Features/Warden/` | `guardian_2026-10` | Unassigned |
| 6c | Gate Security | `Features/Gate/` | `design/audit/export_guardian_video/` (GA frames) | Unassigned |
| 6d | Vendor | new `Features/Vendor/` | None. These screens are not in Figma | Unassigned |
| 6e | Super Admin | new `Features/SuperAdmin/` | None found | Unassigned |
| 7 | Wiring across roles and polish, including the visual differences in `FOUNDATION_VERIFICATION.md` | Any, through the shared-file owner | All | Unassigned |

Parts 3a to 3f share one folder. Agree file names first, and keep one screen per file.

## Shared files: one owner only

Only one person edits these at a time. Everyone else asks that person for the change. Each change here needs review by a teammate.

- `ios/MealLoop/Domain/**`
- `ios/MealLoop/Data/Repositories/Repositories.swift`
- `ios/MealLoop/Core/Navigation/**`
- `ios/MealLoop/DesignSystem/Tokens/**`
- `ios/MealLoop/App/AppEnvironment.swift`
- `ios/MealLoop/Data/Demo/DemoSeed.swift` and `ios/MealLoop/Data/Demo/DemoDataProvider.swift`
- `ios/MealLoop/DesignSystem/Components/**`, listed in [`COMPONENT_CATALOG.md`](COMPONENT_CATALOG.md)
- `ios/MealLoop/DesignSystem/Gallery/**`
- `docs/COMPONENT_CATALOG.md`

**Adding or changing a shared component goes through the shared-file owner.** Check the catalog first. If nothing fits, send the owner the reference image and the roles that need it. A view only your role needs stays in `Features/<Role>/`.

**Shared-file owner:** Unassigned. Until one is named, the repository owner holds this.

`DemoDataProvider.swift` is the file most parts will need. Batch requests for it rather than sending one at a time.

## Safe to work on in parallel

- `ios/MealLoop/Features/<Role>/` for your own role only.
- New test files in `ios/MealLoopTests/`.

A part replaces its placeholder by adding a case to `Features/Shell/RoleRootView.swift` or `StaffHomeSwitch`. These are small edits, but several parts touch them, so land them one at a time.

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
