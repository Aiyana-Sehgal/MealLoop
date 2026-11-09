# Admin polish: Today, duplicates, Remind, missing pages, Invite, Search, standards

Pushed straight to `main` under the owner workflow of 7 November. `CLAUDE.md` and `docs/BRANCHING.md` say never to push
to the default branch and to open a pull request; the brief overrides them. No branch, tag or pull request was created.
Lean mode (owner ruling): one capture per changed screen on iPhone 18 Pro at about 480 px high, beside its frame only
where the layout changed. Figma `nzzTAm9YnJRSdKEeYUWUEb` was read only. `~/Downloads/FIGMA_FRAME_MAP.md` and
`~/Downloads/SUPER_ADMIN_CONTEXT.md` were missing; node ids came from the brief, and the role context from the pack's
`data/SUPER_ADMIN_CONTEXT.md`. The `admin_votes_*` and `admin_rewards_*` images are not in the pack.

## Commits

| Commit | Title |
|---|---|
| `92b6b44` | fix(admin): match Today to the Figma frame |
| `4a8acb3` | fix(admin): size the Remind students sheet to the frame |
| `4c3a633` | feat(backend): add Admin vote decisions, proposals and redemptions |
| `eb53c01` | feat(admin): build the pages that said not part of this prototype |
| `f741afc` | feat(admin): add Admin search and role-scoped Invite |
| `2c0a25c` | refactor(admin): build every Admin page on MLScreen |
| (this file) | docs(admin): record the Admin polish pass |

## One line per changed screen (`iphone18pro/`, frames in `figma/`)

**10 screens: 4 match their frame or image, 2 differ, 4 needs design (no image).**

| Screen | Frame or image | Result |
|---|---|---|
| Today | 2257:158261 | Matches the layout: four tiles of one height, the number alone, a tile with an action shows only its button, then Needs you. The tile values are the story's (Main 860 waiting for approval at 7 AM); the frame draws a later moment. |
| Remind students sheet | 2262:237 | Matches the wording and order; the bubble is canvas-coloured because the shared sheet is white (the frame's sheet is grey). |
| Search · empty | admin_search_01_empty | Differs: Recent is empty until something is opened in this run (no saved history exists); Jump to matches. |
| Search · results | admin_search_02_results | Matches the groups and the honest "No one matches" line; All shows up to 5 per group. |
| Invite from a role page | admin_people_04_invite + brief 8 | Matches: "Add door staff", "Role · Door staff", no role chips, the mess chips. |
| Menu votes | 2277:2081 | Matches the Success frame; Rules opens a sheet, Decide opens a sheet and records, New proposals opens a page. |
| New proposals, proposal | brief images 3 and 4 (missing) | Needs design: built from the brief's wording. One proposal is held; the page says the other 2 counted are not in the record. |
| Decide, Rules sheets | brief images 1, 2, 5 (missing) | Needs design: sized to content, the brief's lines. Not captured. |
| Redemptions | brief image 6 (missing) | Needs design: "Redeemed in August" 75, Juice 63, Ice cream 12, Biryani coupon 0, from Rewards 2277:2474. |
| Today › See all | brief image 7 (missing) | Needs design: every shortage and review as hairline rows with chips; the seed holds one review at this time. |

## Removed duplicates and placeholders

- Today: the six-row lunch headcount table, the "Live forecast" (lead value) name in the tile, the Approval and Vendor
  rows, the "headcount due" line and the "Nothing needs you." filler. The six values and the status rows stay on the
  headcount page; Live meal keeps "of N expected" as drawn.
- "Not available yet": the six-value card shows a dash for a missing value. No other column of it exists.
- "This isn't part of this prototype": 0 left in More. Pass request, outing rows and the spare-food "See dishes and
  steps" hold no further data, so they are information rows (needs data). History says "The record holds the last 3
  of today's 6 entries." The Call buttons keep their honest message.

## Standards

`AdminPageScaffold` is built on `MLScreen`: the 32 pages on it get the system back button with swipe-back, the title
collapsing into the bar, and tab-bar clearance. The headcount and Edit day pages keep their own back button (bar hidden).
Checked in captures (system back circle on Menu votes); a live edge swipe and the largest Dynamic Type were not captured.

## Added backend (`4c3a633`, additive, 4 tests)

`AdminVotesRewardsRepository` (decision, decide, proposals, respond, redemptions), `DemoAdminVotesRewards`. Samples:
"Dosa on Fridays · 212" (design brief), redemptions from Rewards 2277:2474. Admin-only writes; nothing is sent.

## Decisions needed

- **P-ADMIN-POLISH-1** "Super Admin and Admin are one role (all messes)": the all-mess Admin is the Super Admin account.
  The Food Head (`.admin`) still sees only their own mess, because the data scope (`AdminDataScope`, outside this
  task's files) and its tests enforce it. Should the Food Head get all messes?
- **P-ADMIN-POLISH-2** Designs for Decide, Rules, New proposals, proposal, Redemptions and See all.
- **P-ADMIN-POLISH-3** Should Search keep recent searches between launches?

## Commands and counts (final code `2c0a25c`)

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug, `MealLoop` | 0 | 768 | 735 | 0 | 33 |
| Review, `MealLoop Review` | 0 | 766 | 734 | 0 | 32 |
| Release build | 0 | n/a | `** BUILD SUCCEEDED **` | n/a | n/a |

New tests: 6 polish rules, 4 backend. Diff: `Features/Admin` (12 files), additive `Domain`, `Data` and tests only.
`git ls-remote --heads origin`: only `main`; tags: 29, none created. Not run: a physical device, VoiceOver, the
largest Dynamic Type on every page, the full page-12 spacing audit (lean mode).
