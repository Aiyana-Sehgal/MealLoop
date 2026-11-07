# Admin Figma fix: audit (partial, work stopped at usage limit)

Branch `fix/ios-admin-figma-match`, base `origin/feature/swiftui-foundation` @ 91b1ce9. Both `origin/feat/ios-admin-today` and `origin/feat/ios-admin-results-more` are ancestors (checked 2026-11-07).

**Status: AUDIT ONLY. No code has been changed. Nothing has been built, tested or captured on this branch yet.**

## Sources

- Figma connector: working. File `nzzTAm9YnJRSdKEeYUWUEb`, page `2237:2` "12 Admin Redesign". It was used read only (`get_metadata`, `get_screenshot`, `get_design_context`).
- `~/Downloads/FIGMA_FRAME_MAP.md` is **not on this Mac**. Spotlight finds nothing. The node ids below come from `get_metadata` on page 12.
- `design/audit/export_admin_redesign/*@2x.png` and `export_fix2/` match live Figma. The Figma render of `2262:6` Students · new was compared with `A06_students@2x.png` and they are identical. Exports are cut at 852 pt, so for a scrolling frame use `get_metadata` to see everything (for example, the "Not answered by mess" row on 2262:6 sits below the fold).
- Build side: the earlier captures in `docs/verification/admin-results/compare/` (Figma on the left, build on the right; the build was on a 440 pt phone). These were made from the code now on the base.

## Figma specs read so far (`get_design_context`)

- Type: ML/Body is Inter 17/24 Regular (maps to `MLType.staffBody`). ML/Secondary is 15/21 (`MLType.body`). ML/Body Semibold is 17 (`staffPrimary`). ML/Secondary Medium is 15 medium. Hero Metric is JetBrains Mono Bold 52/56. Hero Unit is Mono Medium 20 (no token exists). Mono Body is 15. Tab Label is Inter Semibold 11.
- **AdminChip** (2240:213) is display only. Its variants: **Lime** (lime fill, 1.5 pt ink outline: Live, New, Running low, Sure, Testing), **Outline** (1.5 pt ink: Review, Needs an owner, Reviewed, Probably, Open), **Dashed** (Draft, missing data, Can't tell), **Black** (lime text on black: Needs review) and **Quiet**. Padding is 14 × 6 and the label is 15 pt medium.
- **DishPictogram** (2129:2299) is 28–40 pt. Bread: dosa, idli, chapathi, paratha, poori, bhature, idiyappam, bread. Rice: rice, pulao, briyani. Paneer: paneer. Curd: curd, raita, buttermilk, ice cream. Curry: everything else. The SVGs are in `design/reference/redesign_2026-10/assets/pictograms/`. They are simple paths and can be drawn locally with a SwiftUI `Path`/`Canvas`.
- **AdminTabBar** (2237:2455) uses Regular outline symbols `calendar`, `person.2`, `chart.bar` and `ellipsis` at 22 pt. The selected tab stays an outline on the pill.
- Rows (StatBars section, 2262:53): there is a hairline **above** each row, min 56 pt, py 12. Section label is 15 pt secondary with 6 pt space. A row that has a chip has **no chevron**.

## Difference list (frames audited so far)

Cross-cutting (applies to every Admin page):
- X1. Status is drawn as `StatusText` dot + text where Figma draws an AdminChip (Lime, Outline, Dashed or Black). Fix: add a local `AdminChip` in `Features/Admin/` and leave `StatusText` alone.
- X2. Dish rows and tiles have no pictogram, or use `fork.knife`. Fix: add a local `AdminDishPictogram` (5 kinds, keyword rule above).
- X3. Type is a step too small. Section labels are 13 pt (shared `SectionHeader` uses `MLType.secondary`) where Figma uses 15. Row subtitles are 15 → should be 15 (ok). Page subtitles are 15 → should be 17. Fix: use a local section label in place of `SectionHeader`.
- X4. Rows with a chip also show a chevron. Figma has none.
- X5. The back button is the shared 44 pt thin-outlined `BackButton`. Figma draws a 46 pt white filled circle with a soft shadow. Fix: a local `AdminBackButton`.
- X6. Tab bar: `person.3` should be `person.2` (fix in `AdminRootView`). Shared `GlassTabBar` forces `.fill` on the selected tab, but Figma keeps outlines. That cannot be fixed without a shared change, so list it under T7. Labels are `MLType.meta` 12 pt medium; Figma uses 11 pt semibold (also shared).

Per frame:
- `2262:6` Students · new: feedback row has no soup-bowl pictogram; "New" should be a Lime chip; "Needs an owner" should be an Outline chip; both rows have an extra chevron; **row "Not answered by mess / 630 students for tomorrow lunch" (with chevron) is missing**; hero "of" should be 17 Inter and "3,500" mono 20 (build: mono 15); bars should be 10 pt on an `inkSecondary` track (build: 8 pt at 20% white); bar label width 80; Remind button 48 pt; section labels 15 pt.
- `2262:237` Remind sheet: the message box is white in Figma (build: `fillQuiet` grey); type is larger (17); the note is 15.
- `2263:6` Feedback: dish card is missing its pictogram and is laid out as a row; problem row is missing its icon (Figma symbol, name to read via `get_design_context`); count should be a large mono "6" plus "students"; the meal row detail differs ("Sambar 4 L left" vs "Needs review").
- `2263:218` Community: "Needs an owner" on the Assign owner row should be an Outline chip with no chevron; the stage line should be wider, with the labels left/centre/right aligned to the ends; hero type is larger.
- `2263:556` Why students skip: titles should be 17 Regular (build: semibold); counts should be mono 17 + "students" 13; rows are 59 pt.
- `2264:6` / `2264:254` Results Left over / Ran out: the reason row tag should be a chip (Probably = Outline, Sure = Lime, Can't tell = Dashed); counts 28 pt with "meals" under them; titles 17 regular wrapping; the segmented track is lighter; the hero tag is a dot (that one matches).
- `2307:6` To check: Review should be an Outline chip, Testing Lime, Open Outline, with no chevrons; Figma has no "Safety cases" row (the build adds it as the only way in, so keep it and list it).
- A09 Reason pages (8): the header tag dot matches. Food tiles lack pictograms. "Didn't like" dish card lacks a pictogram and problem icon. Meal cards: the sample has only the dish chip; the build adds "Rice ran out" (live story data, keep). Type is larger in Figma. Percent-free text stays.
- `2260:161403` Meal report: "Needs review" should be a Black chip (build: dot); the ticket's side notches are missing; the arrow should be curved and dashed with the % under it (build: straight); the checklist icons match.
- `2266:6` Check next time: chips and stage line are roughly right; the hero title should be 22 pt; the buttons are cut under the tab bar in Figma too.
- `2308:112` Weekly report: "In the report" rows are missing their leading check-circle icons; the hero numbers should be larger (52); the chips are larger.
- `2278:6` More: card row titles should be 17 regular (build: semibold-ish); the rows are taller (59 pt).
- `2278:166146` People and access: role rows are close; the vendor card line says "Not a login · headcount goes by message" in Figma, but the build drops "Not a login" (an earlier owner ruling: vendor account per PRD; keep it and list it).
- Not yet audited: Today ×4, Headcount ×5, Live meal ×2, Safety case ×2, Find a meal, Safety cases list, Meal report Data missing / Tue dinner / sheets, Check North scanner, Weekly report other states, Weekly menu + Edit day ×18 + quick-change sheets ×8, Announce ×2, restyled AD-* ×5, Outings · Admin.

## Not done

Every code fix, the tests, the captures, the per-frame "matches/differs" lines, Debug/Review tests and the Release build, the push and the PR.
