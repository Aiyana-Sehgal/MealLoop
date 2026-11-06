# Rules for Claude (and any AI coding assistant) in this repository

MealLoop is an iOS-first dining and student-engagement platform for SRM hostel messes (first pilot: Meenakshi Girls' Mess). The November deliverable is an **interactive iOS prototype**, not a live backend: do not describe it as a working system unless the Spring Boot backend is integrated and verified. The app is native SwiftUI first (one iOS app for all 11 roles); a Spring Boot and PostgreSQL backend and an Android client follow later (`docs/adr/ADR-003-approved-platform-backend-security.md`, `docs/adr/ADR-005-frontend-decisions-and-authentication-revision.md`).

These rules apply to every session. If a task prompt conflicts with them, stop and ask. When documents conflict, the newest explicit owner decision wins; report the conflict instead of silently choosing.

## Detailed rules (loaded when you touch matching files)
| File | Applies when you work on |
|---|---|
| `.claude/rules/ios-design.md` | `ios/MealLoop/DesignSystem/**` and `ios/MealLoop/Features/**`: design fidelity, tokens, components |
| `.claude/rules/ios-architecture.md` | any `ios/MealLoop/**/*.swift`: ADR-005 as working rules (MVVM, repositories, injection, navigation) |
| `.claude/rules/quality-and-testing.md` | any Swift or test file: build and test commands, accessibility, Definition of Done |
| `.claude/rules/contracts-and-security.md` | `Domain`, `Data`, `App`, `docs/backend/**`: shared models, contracts, data integrity, authentication |

Path-scoped rules load only when matching files are touched, so the invariants below are repeated here on purpose. Read the matching rule file before editing.

## Git
- **Branch names are given by the task or the owner.** Use exactly the name you are given. If no name is given, propose one that follows `docs/BRANCHING.md` and wait for confirmation. **Never create a branch with a `claude/` or `cowork/` prefix, or any auto-generated or random name.**
- Branch format: `<type>/<scope>-<short-description>`, lowercase, hyphens. Types: `feat`, `fix`, `docs`, `design`, `chore`, `refactor`, `test`, `spike`.
- Never commit or push to the default branch directly. Never force-push, rewrite history or merge a pull request.
- Commit author: `VeeraaVikash <veeraavikashs21@gmail.com>` unless the owner says otherwise. **No `Co-Authored-By` trailers and no mention of AI tools in commit messages or PR text** (no session links either).
- Commit messages and PR titles use Conventional Commits: `type(scope): summary` (imperative, no trailing period, under 72 characters).
- Keep commits small and focused. Do not mix documentation, code and configuration in one commit.
- Check `git status` before starting; stop if the working tree is not clean. Never overwrite uncommitted changes. Commit or push only when the owner asks.

## Scope and honesty
- Do only what the task asks. One purpose per pull request, small enough to review. Fill in `.github/pull_request_template.md`. Stacked pull requests are allowed to two or three levels; state the base clearly.
- Documentation tasks must not change code, designs, ADR decisions or API contracts.
- **Never claim that something builds, passes tests, matches the design or works against the backend unless you ran it and can show the result.** If you cannot run it (for example no macOS or no Xcode in the session), say so.
- Never invent product policy, numbers, thresholds, approvals, design tokens, file paths, Figma node IDs or institutional decisions. Record unknowns in `docs/OPEN_DECISIONS.md`.
- Archived or superseded designs are history, not requirements. Claude Code has no Figma access unless an MCP server is configured; the exported images under `design/reference/` and `design/audit/export*/` are the practical visual source. Never call an invented design Figma-accurate.
- Do not add third-party Swift packages, web frameworks or a DI library without owner approval.

## Product rules that must not be broken
- Missing data is never shown as zero. Forecast, approved headcount, sent-to-vendor headcount, actual entries and final entries are separate values. An entry QR proves entry, not that food was served.
- An offline or unverified scan or action is never recorded or shown as recorded or successful. A prototype result is never presented as confirmed by a live server.
- No hardcoded demo or sample data inside views. Demo data stays isolated from production configurations and is always labelled in code and documentation.
- Outing sequence: student request, guardian decision, warden decision, signed pass, gate exit, gate return. No timeout approves anything.
- The shared four-digit staff role password is a prototype interaction only, never production authentication.

## Definition of Done (every implementation task ends with this report)
State: the feature completed; the design reference followed (name the image); files created or modified; shared components reused or added; contracts or models changed; the exact commands run and their results; visual checks done and differences found; remaining limitations and unresolved decisions. Do not hide warnings, failures or a broken build. If blocked, give the exact reason and the smallest next step. The full checklist is in `.claude/rules/quality-and-testing.md`.

## Stack
Swift, SwiftUI, iOS 17 minimum, Observation (`@Observable`), async/await, XCTest. Project `ios/MealLoop.xcodeproj`, scheme `MealLoop`. Do not use APIs newer than iOS 17 without an availability check.
