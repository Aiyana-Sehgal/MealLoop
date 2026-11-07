# Branching, commits and pull requests

## Branches
- `main` is protected and contains only reviewed, verified work (builds and tests pass). Releases and milestone demos are tagged on `main` (for example `v0.1-review3`).
- All work happens on short-lived branches created from `main` (or from another branch when stacking). One purpose per branch. Delete the branch after it merges.

### Naming
`<type>/<scope>-<short-description>`: lowercase, hyphens, no personal names, no dates, no `claude/` or `cowork/` prefixes. An issue number may follow the type: `feat/12-kitchen-home`.

| Type | Use for | Examples |
|---|---|---|
| `feat` | new functionality | `feat/ios-kitchen-home`, `feat/backend-meal-state` |
| `fix` | bug fixes | `fix/ios-offline-scan-banner` |
| `docs` | documentation | `docs/prd-consolidation`, `docs/c4-c2-review` |
| `design` | Figma references and design packs | `design/figma-reference-packs` |
| `chore` | tooling, CI, configuration | `chore/ci-github-actions` |
| `refactor` | code restructuring without behaviour change | `refactor/ios-navigation` |
| `test` | tests only | `test/backend-duplicate-entry` |
| `spike` | throwaway experiments (never merged as-is) | `spike/crowd-forecast-baseline` |

Scopes: `ios`, `backend`, `ai`, `infra`, `repo`, or a feature name.

## Commits
Conventional Commits: `type(scope): summary`, for example `feat(ios): add Kitchen Home during-meal state` or `docs(prd): record vendor account decision`. Imperative mood, under 72 characters. Small, focused commits. No `Co-Authored-By` trailers.

## Pull requests
- Title uses the commit format. One purpose, small, linked to the requirement IDs or issues it addresses.
- At least **one review by a teammate who did not write it** before merging. Fill in the template honestly (what was verified and what was not).
- Code pull requests must build and pass tests before review. Never merge work that is unverified.
- **Stacked pull requests:** allowed up to two or three levels. Each PR's base is the branch below it. After the lower PR merges, retarget the next PR to `main` and rebase if needed.
- Prefer squash-merge to keep `main` readable. Delete the branch after merging.

## Repository settings the owner should enable (GitHub, Settings, Branches)
Protect `main`: require a pull request, require one approval, require status checks once CI exists, block force pushes and deletion.

## Existing branch names (history)
Older branches named `claude/...` and `feature/...` are being renamed to this convention. Documents that mention the old names are historical records and are not edited.
