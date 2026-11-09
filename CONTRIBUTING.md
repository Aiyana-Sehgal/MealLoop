# Contributing to MealLoop

Rules come from `docs/BRANCHING.md` and `CLAUDE.md`; each is cited. Where the owner ruled differently later, the
ruling is named.

## Get the code

The history is large, so clone only the code and documents:

```
git clone --filter=blob:none --no-checkout --depth 1 --no-tags https://github.com/VeeraaVikash/MealLoop.git
cd MealLoop
git sparse-checkout set --cone ios docs .github .claude
git checkout main
```

No image files may be committed outside `ios/` (the app's own asset catalogs); the commit-rules CI check fails a push
that adds one. Design images live in a separate design repository, `MealLoop-design`, which is being set up.

## The workflow: one branch, `main`

Owner ruling, 9 November 2026: the owner's sessions push green commits straight to `main`, with no feature branches,
and CI (`.github/workflows/ios-ci.yml`) is the safety net. **Contributors outside the owner's sessions use pull
requests.** This replaces the "all work on short-lived branches" line of `docs/BRANCHING.md` for the owner's sessions
only.

- **Branch names** (for pull requests): `<type>/<scope>-<short-description>`, lowercase, hyphens, no personal names,
  dates, `claude/` or `cowork/` prefixes. Types: `feat`, `fix`, `docs`, `design`, `chore`, `refactor`, `test`,
  `spike`. Scopes: `ios`, `backend`, `ai`, `infra`, `repo`, or a feature name (`docs/BRANCHING.md`, Naming).
- **One purpose per branch**, small enough to review (`docs/BRANCHING.md`, Branches; `CLAUDE.md`, Scope and honesty).
- **Commits:** Conventional Commits, `type(scope): summary`, imperative, under 72 characters, small and focused. No
  `Co-Authored-By` trailers and no mention of AI tools (`docs/BRANCHING.md`, Commits; `CLAUDE.md`, Git). Do not mix
  documentation, code and configuration in one commit (`CLAUDE.md`, Git).
- **Never** force-push or rewrite history on `main`; automated sessions never merge pull requests (`CLAUDE.md`, Git).

## Pull requests

- At least **one review by a teammate who did not write it** (`docs/BRANCHING.md`, Pull requests).
- Fill in `.github/pull_request_template.md` honestly: what was verified and what was not (`docs/BRANCHING.md`;
  `CLAUDE.md`, Scope and honesty).
- Code must build and pass the tests before review (`docs/BRANCHING.md`).
- **Stacked pull requests** are allowed two or three levels deep; each PR's base is the branch below it
  (`docs/BRANCHING.md`; `CLAUDE.md`). Merge a stack with **merge commits, never squash it**, so the upper branches keep
  their history (owner's Prompt 6 brief). Note: `docs/BRANCHING.md` says "Prefer squash-merge" in general; that
  still applies to a single pull request, not to a stack.

## Parallel work with `git worktree`

Keep each task in its own folder so two tasks never share a checkout:

```
git worktree add ../MealLoop-<task> -b <type>/<scope>-<description> origin/main
# work, commit, push, open the pull request
git worktree remove ../MealLoop-<task>      # once the pull request has merged
```

Never touch another person's or session's worktree, and never overwrite uncommitted changes (`CLAUDE.md`, Git).

## Run the tests

From the repository root, with an iPhone simulator id (commands as recorded in
`docs/verification/outings/REPORT.md`, Validation, and `docs/verification/outings-staff/REPORT.md`, Tests):

```
xcodebuild test -project ios/MealLoop.xcodeproj -scheme MealLoop -configuration Debug \
  -destination id=<simulator-id> -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1
xcodebuild test -project ios/MealLoop.xcodeproj -scheme "MealLoop Review" \
  -destination id=<simulator-id> -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1
xcodebuild build -project ios/MealLoop.xcodeproj -scheme MealLoop -configuration Release \
  -destination "generic/platform=iOS Simulator"
```

The latest recorded results: Debug 804 tests, 760 passed, 0 failed, 44 skipped; Review 802, 759, 0, 43
(`docs/verification/outings-staff/REPORT.md`). Never claim a build or test passes unless you ran it and can show the
result (`CLAUDE.md`, Scope and honesty).

## Report a bug

Open a GitHub issue with the **role**, the **screen name**, what you did and expected, and a **screenshot**.

## Shared files

Some files belong to one owner at a time (shared components, tokens, the tab bars, `MLScreen`, `RoleRootView`,
`docs/backend/openapi.yaml`, ADRs). Check `docs/PARTS_AND_OWNERSHIP.md` before you edit one.
