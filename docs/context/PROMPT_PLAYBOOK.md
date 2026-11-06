# MealLoop: Prompt Playbook (Claude Code and Cowork)

How we write prompts for AI agents on this project, what every prompt must contain, templates, and the mistakes we have already learned from. Use it together with `docs/context/PROJECT_CONTEXT.md`, `CLAUDE.md` and `docs/BRANCHING.md`.

---

## 1. Principles

1. **One task per session.** Start a fresh Claude Code session for each prompt. The rules in `CLAUDE.md` and `.claude/rules/` carry the shared context; the prompt carries only what this task needs.
2. **Inspect, then act.** Every prompt starts with what to read and asks the agent to verify facts (branch names, IDs, file paths) before editing.
3. **Never trust the prompt over the repository.** IDs, file names and statuses in a prompt can be stale; the agent maps by content and reports differences.
4. **Honesty is a requirement, not a style.** Written is not verified is not complete. An agent may only say "builds", "tests pass" or "matches the design" if it ran the check and can show the result.
5. **No invention.** No made-up numbers, thresholds, policies, approvals, Figma node IDs, file paths or tokens. Unknowns go to `docs/OPEN_DECISIONS.md`.
6. **Scope and stop.** Say what is out of scope and where to stop. Agents never merge, force-push, rewrite history or push to the default branch.
7. **Evidence at the end.** Every prompt ends with a validation section (with counts) and a final report with a verdict line.

## 2. Mandatory sections in every Claude Code prompt

1. **Title and one-line goal.**
2. **Context:** repository, relevant branches and PRs, dates.
3. **Hard limits:** what must not change (code, designs, ADRs, OpenAPI, other roles).
4. **Git rules:**
   - exact branch name (`type/scope-description`) and the base branch it is created from; never `claude/...`;
   - check `git status` first, stop if not clean;
   - commit as `VeeraaVikash <veeraavikashs21@gmail.com>` via `git -c user.name=... -c user.email=... commit`;
   - Conventional Commits; no `Co-Authored-By`; no AI mention or session link in commits or PR text;
   - push, open one PR with an explicit base (stacked PRs name the lower branch), use `gh` or give the compare URL; do not merge.
5. **Inspect first:** the exact files to read; what to verify.
6. **The work:** numbered steps with the owner's decisions written out in full (never "see above" or empty placeholders).
7. **Status vocabulary** when documents are involved (for example CONFIRMED, PROPOSED, SRM APPROVAL REQUIRED, VALIDATION REQUIRED).
8. **Validation:** concrete checks with counts (unique IDs, links resolve, diff shows only allowed files, no invented numbers, rule-specific checks).
9. **Final report:** files changed, what was verified, what is pending, blockers, commit SHAs, PR link, verdict line (for example "READY FOR OWNER REVIEW" or "BLOCKED").

## 3. Templates

### 3.1 Feature implementation (SwiftUI)

```markdown
# MealLoop: Implement <feature> (<role>) for the 11 November review

Repository VeeraaVikash/MealLoop. Follow CLAUDE.md and .claude/rules/.
Branch: create `feat/ios-<feature>` from `<baseline branch>`; never `claude/...`.

Design reference: <exact screen and state names from docs/SCREEN_INVENTORY.md> and images
<design/reference/<pack>/images/<file>.png>. Do not use archived frames.

Scope: <screens and states>. Out of scope: <list>. Do not change shared models, router,
repositories or tokens without stopping and reporting (they need team review).

Behaviour rules that apply: <copy the 3 to 6 relevant product rules, for example
"missing data is never zero", "two-hour cutoff", "offline is never recorded">.

Steps: inspect existing components and models; build the view model and views; add
view-model tests against the prototype backend; build and test; run in the simulator,
screenshot, compare with the reference, fix differences.

Validation: xcodebuild build and test results (real simulator), screenshots compared,
no hardcoded data in views, all states handled.

Final report: the Definition of Done report from CLAUDE.md, then
"FEATURE READY FOR REVIEW" or "BLOCKED".
```

### 3.2 Documentation change

```markdown
# MealLoop: <document task>

Documentation only. Do not change code, designs, ADR decisions or OpenAPI.
Branch: `docs/<topic>` from `<base>`; PR base `<base>`; do not merge.
Owner decisions (CONFIRMED): <write them out in full>.
Keep OPEN: <list>. Do not invent values.
Steps: inspect; verify IDs by content; edit minimally; keep IDs stable; update
OPEN_DECISIONS and traceability.
Validation: unique IDs, references exist, links resolve, statuses consistent,
diff shows only docs. Final report and verdict.
```

### 3.3 Cowork Figma run

1. **Mock first:** draw the screens in chat, iterate, and get the owner's approval.
2. **Reference pack:** `design/reference/<pack>_2026-10/` with `images/` (approved screens, 292 pt wide), `data/<pack>_spec.md` (rules, wording, sample data, open items) and `prompt/COWORK_PROMPT_<PACK>.md`. Zip it, unzip into the repo, commit on a `design/<pack>-reference` branch, and check the image count.
3. **Cowork prompt structure:** read first (master context, design intent, contract, gaps, run status, the pack); stages (`X0` preflight read-only, foundation and components, screens, wiring, spacing and checks, wiring and exports, final report); rules (snapshot per stage, verify against the reference at scale 1, never delete (archive to page 99 with links stripped), flow starts unchanged, mono only for numbers, 44 pt targets, text at least 12 pt, push after every stage, max two fix attempts then log); what is simulated; final report in 15 lines or fewer.
4. **Launcher line** (when the prompt is long): "Run the <NAME> prompt. Read design/reference/<pack>/prompt/<file>.md and execute it exactly, stages X0 to Xn. If the folder is missing, look in ~/Downloads, copy it in, commit it as VeeraaVikash with no co-author line, and continue. Branch <exact branch name>. Push after every stage. Do not merge."

### 3.4 Verification task

Ask for: the tool versions, the real simulator or device, the exact commands, the logs, test counts executed and failed, what could not be run and why, and an evidence file (`docs/<area>_VERIFICATION.md`). Forbid fixing by deleting tests or features.

### 3.5 Launching long prompts

Save the prompt file locally (for example `~/Downloads/<NAME>.md`) and send one line: "Read ~/Downloads/<NAME>.md and execute it exactly." Include any source material (for example a draft document) inside the file between clear markers. Never leave an empty placeholder.

## 4. Reviewing a prompt written elsewhere (for example ChatGPT)

Check, and fix before sending:
- Branch name, base branch, commit identity, PR base, no merge, no `claude/` branches, no AI mentions or session links.
- Missing areas (for example a PRD prompt that forgot Door Scanner, Pass Desk and Admin).
- Contradictions with the latest decisions (section 5 of `PROJECT_CONTEXT.md`), for example Community publication, vendor login, supervisor waste approval, guardian sequence.
- Invented numbers or "approved" labels on things that are open.
- Placeholders that the agent cannot fill (empty draft markers, "see above").
- Claims about status that need verification (builds, tests, approvals).
- Too much in one session (split build, rules and features into separate prompts).
- Instructions the agent cannot physically do (seeing Figma without access, tapping a simulator without UI automation); replace them with something it can do and an honest fallback.

## 5. Lessons learned (do not repeat)

| What happened | Rule now |
|---|---|
| Agents created auto-named `claude/...` branches | Every prompt names the exact branch; `CLAUDE.md` forbids `claude/` names |
| A prompt pointed at a draft that was only a placeholder; the agent correctly stopped | Embed source material in the prompt file between markers |
| A pack was missing in the repo and a run stalled | Commit the reference pack first and check the image count before the run |
| Older Cowork prompts named the old design branch | After renaming branches, update branch names inside pack prompts |
| A foundation was described as "complete" without a build | "Code must compile" means a real `xcodebuild` result in the report |
| An agent could not see Figma | Use the exported reference images in the repo; Figma via MCP is optional |
| IDs in prompts did not match the files | Agents verify IDs by content and report the mapping |
| A legend promised dashed lines that did not exist | Validation checks the artefact, not the description |
| The PR description ended with an AI session link | No AI mentions or links in PR text |
| Long prompts were pasted and truncated | Save as a file and send a one-line launcher |
| One prompt mixed build fixes, rules and docs | One task per session |

## 6. Sequence for a new feature

1. Confirm the feature is in the review scope and its frames are active (`docs/SCREEN_INVENTORY.md`).
2. If the design is missing or changing: mock in chat, approval, Cowork pack and run.
3. Write the feature prompt from template 3.1; branch from the reviewed baseline.
4. Run it in a fresh Claude Code session.
5. Owner checks the screenshots against the reference and runs it on a device or simulator.
6. Teammate review of the PR; merge only when the build and tests are green.
