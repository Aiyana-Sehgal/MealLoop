# Branch archive

On 7 November 2026 the repository was consolidated so that `main` is its only branch. Every former remote branch was kept as a tag named `archive/<branch name with / replaced by ->`, pointing at the branch tip as it was before deletion. The previous `main` (`85cedc4`, README and design only) is kept as the tag `backup/main-before-consolidation`.

Final states:

- **merged into main**: the tag's commit is an ancestor of `main`, so all of its work is in `main`.
- **salvaged**: an unmerged documentation branch. Its files that did not exist on `main` were copied in; where a file already existed on `main`, the `main` version was kept and the branch version was saved under `docs/archive/` with the suffix `_2026-10`.
- **stale**: neither merged nor salvaged (none at the time of consolidation).

To look at a former branch: `git fetch origin --tags && git switch --detach <archive tag>`.

| Archive tag | Former branch | Tip | What it was | Final state |
|---|---|---|---|---|
| `archive/chore-claude-code-rules` | `chore/claude-code-rules` | `e61e8f5` | chore(repo): add the engineering and UI standards: `CLAUDE.md` and `.claude/rules/` (PR #5) | salvaged |
| `archive/chore-ios-baseline` | `chore/ios-baseline` | `d94934a` | docs(verification): verify the iOS foundation baseline (PR #7) | merged into main |
| `archive/claude-mealloop-ios-design-e9n1n5` | `claude/mealloop-ios-design-e9n1n5` | `85cedc4` | Add official MealLoop README (last commit, no PR) | merged into main |
| `archive/docs-architecture-decision-sync` | `docs/architecture-decision-sync` | `942f7f0` | docs: mark frontend readiness as historical baseline and link current decisions (last commit, no PR) | salvaged |
| `archive/docs-c4-architecture` | `docs/c4-architecture` | `89146db` | Draft MealLoop C4 architecture — C1 context and C2 containers (PR #3) | salvaged |
| `archive/docs-nfr-consolidation` | `docs/nfr-consolidation` | `0463f7c` | Consolidate and correct the non-functional requirements (NFR 0.2 draft) (PR #2) | salvaged |
| `archive/docs-prd-consolidation` | `docs/prd-consolidation` | `8acbbe3` | Consolidate the PRD and update the documentation (PR #1) | salvaged |
| `archive/docs-project-context` | `docs/project-context` | `b9fc7dc` | docs(context): add project context and prompt playbook (PR #6) | salvaged |
| `archive/docs-repo-conventions` | `docs/repo-conventions` | `13b8cf4` | docs(repo): add branching, commit and pull request conventions (PR #4) | salvaged |
| `archive/feat-ios-admin-results-more` | `feat/ios-admin-results-more` | `e62d4db` | feat(admin): add the Students, Results and More tabs (PR #20) | merged into main |
| `archive/feat-ios-admin-today` | `feat/ios-admin-today` | `30c5642` | fix(admin): settle closed meals and the food head name (PR #18) | merged into main |
| `archive/feat-ios-app-entry` | `feat/ios-app-entry` | `d5efa5e` | feat(entry): add launch-ready entry, accounts and role routing (PR #8) | merged into main |
| `archive/feat-ios-core-story-contracts` | `feat/ios-core-story-contracts` | `47e5abb` | feat(story): add the core-story contracts and role roots (PR #10) | merged into main |
| `archive/feat-ios-door-scanner` | `feat/ios-door-scanner` | `6314d4f` | feat(door): add the Door Scanner role and entry flow (PR #15) | merged into main |
| `archive/feat-ios-kitchen` | `feat/ios-kitchen` | `0e798e3` | feat(kitchen): add the Kitchen role screens (PR #21) | merged into main |
| `archive/feat-ios-outings` | `feat/ios-outings` | `33ea904` | feat(outings): warden, gate security and guardian screens (PR #19) | merged into main |
| `archive/feat-ios-pass-desk` | `feat/ios-pass-desk` | `3035e27` | feat(pass-desk): add the role and the special-meal pass check (PR #22) | merged into main |
| `archive/feat-ios-shared-components` | `feat/ios-shared-components` | `6a0d2c3` | feat(components): add shared components from the reference packs (PR #12) | merged into main |
| `archive/feat-ios-student-home` | `feat/ios-student-home` | `ed69e29` | feat(student): add Home, the meal answer and the entry QR (PR #13) | merged into main |
| `archive/feat-ios-student-home-figma` | `feat/ios-student-home-figma` | `8b47f0e` | feat(student): rebuild Home, Answer and Entry QR from Figma (PR #24) | merged into main |
| `archive/feat-ios-supervisor` | `feat/ios-supervisor` | `41ba2e7` | feat(supervisor): Supervisor role, all screens and meal control (PR #14) | merged into main |
| `archive/feature-swiftui-foundation` | `feature/swiftui-foundation` | `00cdfde` | The integration branch every app PR merged into; last commit: Merge pull request #25 from VeeraaVikash/fix/ios-staff-figma-match | merged into main |
| `archive/fix-ios-admin-figma-match` | `fix/ios-admin-figma-match` | `1718dfa` | fix(admin): match the Admin screens to the Figma redesign (PR #23) | merged into main |
| `archive/fix-ios-breakfast-final-entries` | `fix/ios-breakfast-final-entries` | `09c72e5` | fix(demo): make breakfast final entries agree between history and finalCount (PR #16) | merged into main |
| `archive/fix-ios-entry-and-tabbar` | `fix/ios-entry-and-tabbar` | `e2fc144` | fix(entry): rebalance Welcome and add the glass tab bar (PR #9) | merged into main |
| `archive/fix-ios-integration-batch` | `fix/ios-integration-batch` | `b541193` | fix(integration): close the loose ends after the overnight merges and walk the core story (PR #26) | merged into main |
| `archive/fix-ios-staff-figma-match` | `fix/ios-staff-figma-match` | `ea904ac` | fix(staff): match Door Scanner, Pass Desk and Supervisor to the Figma frames (PR #25) | merged into main |
| `archive/fix-ios-waste-role-guard` | `fix/ios-waste-role-guard` | `583c255` | fix(waste): allow only Kitchen Staff to save waste reports (PR #11) | merged into main |

Totals: 28 branches; 21 merged into main, 7 salvaged.
