# Admin Figma fix: audit and results

Branch `fix/ios-admin-figma-match`, base `origin/feature/swiftui-foundation` @ 91b1ce9. Both `origin/feat/ios-admin-today` and `origin/feat/ios-admin-results-more` are ancestors (checked 2026-11-07).

**Status: audit finished before code changed. Results are added at the end of this file when the work is done.**

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
Audit part 2: the frames part 1 did not reach, each read against the same export and the existing build captures.

- `2257:158261` Today · Lunch: **four mess tiles in a 2×2 grid** (Main, North, South, Annexe; number, four segments, status word or Send); the build has one full-width Main tile. Black tile is the one needing action. Annexe is dashed with "No data". "Needs you" is directly under the tiles; the build puts the six values there first. Rows end in a Lime "Live" and an Outline "Review" control; the build has only an outline Live, and no left-over row.
- `2258:460` Today · Dinner: a line "Dinner · headcount due 4:30 PM" above the tiles; tiles read "Forecast at 3:30". Missing in the build.
- `2258:672` Today · Safety case open: the case card is right; tiles stay below as a grid; "Open case" goes to a "not implemented" page in the build although the case page exists.
- `2258:1314` Today · Offline: same grid under the offline banner.
- Today "Live" goes to a "not implemented" page. **`2260:160216` and `2260:160412` Live meal are not built at all.** Drawn: Live chip, 4-stop line, hero "came in so far", "of 860 expected", progress bar with "usual by now" mark, "Food left · reported by staff" rows with pictogram, and for a low dish a white outlined card with Lime "Running low" and "Tell the vendor".
- `2259:6` Headcount · North: hero number about 80 pt (build 52); forecast range bar 660–740 with marker; three stats (said yes, usual Wed, events); the build has four answer stats and a note. Stepper has 3 stops; the build has 4 because approval is its own step (FR-HC-004: keep, list).
- `2259:160041`, `2259:160232`: "Vendor reply" row with Quiet "Waiting" and Outline "Replied 11:20" chips; the build has dot rows. "Sent before" list missing.
- `2259:160423` South · No reply: Outline "No reply", Call vendor and Message buttons, dashed "Not acknowledged" chip on a past row. Missing.
- `2259:160986` Adjust sheet: reason chips are content width (build: 2-column full width); forecast line has range and usual; button "Save 720" (build "Approve 860", saving approves, keep and list).
- `2260:162194`, `2260:162800` Safety case: role labels are Outline chips (build: grey text); the rail has a joining line; the hero place box has a round photo thumbnail. Closed state is scratch only, as before.
- `2266:426` Find a meal: "Wed 14 Aug / Date" row with calendar icon is missing above the chips.
- `2266:795` Safety cases: subtitle "Last 4 weeks · all messes" missing; "Open" is a Lime chip with no chevron (build: dot and chevron).
- `2260:161598`, `2307:165877` Meal report: same ticket fixes as `2260:161403`; "Vendor cooked" and the missing chips are Dashed, or Outline when the fact is held.
- `2266:220`, `2280:82` sheets: "Tell the vendor" has a dashed vendor card with the number and "Not a login…" text, and Message and Call buttons.
- `2307:165978` North scanner: Outline "Not enough data yet" should be Dashed; check against `2266:6`.
- `2278:240`, `2278:1065` Weekly menu and Check Thu 15: the menu page is close. Check adds a dashed "(?)" mark in each field and "Highlight on the board" and "Non-veg" toggles per word. Missing in the build, and that page is emptier than its frame.
- `2313:6` and the Edit day family: Veg mark is a lime-filled green square (build: outline); the unset star sits in an outlined circle; the switch is lime with an ink knob; the build adds an "Add a dish" link (keep: it is the only way in, list it).
- `2313:170380` Add a dish: "From earlier weeks" chips are missing.
- `2320:6` Change today's dinner: options are quiet filled cards; Add a special has a lime circle; a preview box and Continue sit below the switch.
- `2277:1788` Special passes: "Main Mess" chip with fork icon, "Rules" chip with info icon, "Reissue asked" filled chip with chevron.
- `2277:2081` Menu voting: Rules chip, "Vote closed" chip in the hero, for/against bar, white "Decide" button, rows as separate cards.
- `2277:2474` Rewards: Rules chip, Catalogue and Redemptions chips, budget ring, ticket rows with a dashed stub holding the points, chips for Live, Launches Fri, Awaiting SRM, dashed Fruit bowl row.
- `2277:2967` Spare food: clock circle, "Awaiting pickup" chip, stage line in the hero, "See dishes and steps" row, Main Mess chip with icon.
- `2277:3410` History: "All types" chip, mini timeline in the hero, joined timeline card, "See all · 6" row, "Safety" black chip.
- `2278:166912` Outings: 41 is much larger with Due back and Late at the side; chevrons on rows; Rules is a Dashed "Draft" chip.
- `2278:167100`, `2278:167264` Announce: counter sits inside the box; "When" row has a "Now" chip; title wraps on a 393 pt phone.
- `2311:*` Weekly report states and toasts: same cross-cutting fixes as `2308:112`.
