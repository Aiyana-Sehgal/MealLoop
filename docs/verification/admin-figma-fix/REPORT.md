# Admin Figma fix: audit and results

Branch `fix/ios-admin-figma-match`, base `origin/feature/swiftui-foundation` @ 91b1ce9. Both `origin/feat/ios-admin-today` and `origin/feat/ios-admin-results-more` are ancestors (checked 2026-11-07).

**Status: done. Final code `c049fcc`. Of 84 frames: 17 match, 63 differ, 4 not built. The audit below was written before the code changed; results follow it.**

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

## Results

iPhone 16 simulator (393 pt, the frame width), iOS 27.0, Xcode as installed. Counts come from each `.xcresult`, on `c049fcc`.

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug tests | 0 | 474 | 462 | 0 | 12 |
| Review tests | 0 | 473 | 461 | 0 | 12 |
| Release build | 0 | n/a | n/a | n/a | n/a |

The 12 skipped are the opt-in `OutingScreenshotTests` (8) and `SupervisorScreenshotTests` (4), on the base already. 29 tests are new: 18 in `AdminFigmaFixTests`, 11 in `AdminMessRepositoryTests`. The Release binary has 0 `AdminMessSeed` symbols and 0 sample strings. The Admin code has no compiler warnings in the Debug log.

**Scope:** the diff lists `Features/Admin/`, two new Admin test files, this folder and the backend pieces below. No shared component, token, `GlassTabBar` or `RoleRootView` changed. `Repositories.swift` and `DemoDataProvider.swift` gained additive lines only.

**Hardcoded data:** no `Text("...")` literals in the views, and no seed names apart from the `AdminContext` line already on the base. Literals left: the accessibility label "Back", and the green and red of the Veg marks, matched by eye because no token holds them.

**Percentages:** none in any reason; a test reads every one. The ones left are data completeness, the ticket's arrow and the vote result.

## How it was checked

- **Figma:** connector working, read only. References are the exports in `design/audit/export_admin_redesign/` and `export_fix2/`, not a `get_screenshot` per frame. Three frames (`2257:158261`, `2277:2474`, `2313:6`) were rendered live and looked identical to their exports. Others were not re-checked live. This session did not call `get_design_context`; sizes come from the specs at the top of this file, `get_metadata` and measuring the exports.
- **Frame map:** `~/Downloads/FIGMA_FRAME_MAP.md` was not on the Mac. The owner pasted it into the session. It is not committed.
- **Screenshots:** 17 walks in a scratch copy opened the real `AdminRootView` in Review and tapped through it, so each state also proves its route. All 17 passed on the final code, 96 captures. `compare/` has 80 sheets, Figma left, build right, same height. Every pair was looked at by eye. Sheets hold both images, so there is no separate folder.
- **Scratch only, not in the repository:** the UI test target, the scenario switch, a seeded SOS, a seeded vendor reply on North, offline switched on after sign-in, and the sign-in field changes that stop the Save Password prompt.
- **Not run:** iPhone SE or any other width (one simulator, as the brief says), a physical device, iOS 17, VoiceOver, largest Dynamic Type, Reduce Motion.

## Common to every frame

"Matches" below means it matches apart from these, which are shared files or the simulator:

- C1. System font where Figma has Inter, and SF Mono for JetBrains Mono (shared tokens).
- C2. Tab bar: the selected tab is filled, labels are 12 pt medium, and `chart.bar` is drawn differently (shared `GlassTabBar`, decision T7). Students now uses `person.2`.
- C3. Sheets are white, not grey glass, so a white message box blends in (shared `mlSheet`).
- C4. Toasts are white and have no Undo (shared `mlToast`).
- C5. The segmented control's track is heavier (shared `SegmentedChoice`).
- C6. Status bar and clock: the story clock and simulator, not the frame's sample time. The Today header logo is smaller (shared `StaffHeader`). Vertical positions can be a few points off.

## Per frame

| Node | Frame | Result | Sheet |
|---|---|---|---|
| `2257:158261` | Today · Lunch | differs: Main is the black tile with Approve and a Live forecast line, because the story meal is waiting for approval; North steps back to an outline Send (only one tile is black); the Review row is Rice ran out, from a closed meal. | [compare](compare/2257-158261_today_lunch.png) |
| `2258:460` | Today · Dinner | differs: the Needs you row is Rice ran out · Review, not Rice running low · Live, because no shortage exists at that point of the story. | [compare](compare/2258-460_today_dinner.png) |
| `2258:672` | Today · Safety case open | differs: tiles as on Lunch; elapsed reads 0 min because the case is scratch-seeded on the 7 AM clock. | [compare](compare/2258-672_today_safety.png) |
| `2258:1314` | Today · Offline | differs: the offline line is the shared white banner with Try again, not the black one; tiles as on Lunch. Scratch: offline switched on after sign-in. | [compare](compare/2258-1314_today_offline.png) |
| `2259:6` | Headcount · North | matches | [compare](compare/2259-6_headcount_north.png) |
| `2259:160986` | Headcount · Adjust (sheet) | differs: captured before any change (700, no reason picked); the frame shows 720 and Event. Same controls. | [compare](compare/2259-160986_adjust_sheet.png) |
| `2259:160041` | Headcount · Sent | differs: the sent time is the story clock (7:00, not 11:12); no Adjust headcount row, because a sent number can't change; a toast shows. | [compare](compare/2259-160041_headcount_sent.png) |
| `2259:160232` | Headcount · Vendor replied | differs: chip reads Replied 11:20 AM; no Adjust headcount row. Scratch-seeded: no vendor screen acts on the sample messes. | [compare](compare/2259-160232_vendor_replied.png) |
| `2259:160423` | Headcount · South · No reply | differs: no events stat (South's record holds none) and no Main · Lunch · Not acknowledged row, which would contradict the live Main meal. | [compare](compare/2259-160423_south_no_reply.png) |
| `2260:160216` | Live meal · Serving | differs: dishes come from the story menu and say No report, not OK; On track is dropped; 714, not 712. | [compare](compare/2260-160216_live_serving.png) |
| `2260:160412` | Live meal · Rice low | differs: Steamed Rice, Almost out, Kitchen Staff, from the story; no quantity or name, which the shortage record doesn't hold; On track is dropped. | [compare](compare/2260-160412_live_low.png) |
| `2260:161403` | Meal report · Wed lunch | differs: the story meal has no headcount sent in this scenario, so it shows a dash, with 774 and Rice ran out in place of the sample. | [compare](compare/2260-161403_report_wed.png) |
| `2260:161598` | Meal report · Data missing | differs: same story values; missing chips are Vendor cooked and Waste, from the records. | [compare](compare/2260-161598_report_data_missing.png) |
| `2307:165877` | Meal report · Tue dinner | differs: one extra line (Quantity cooked); the ran-out line has no reported time. | [compare](compare/2307-165877_report_tue_dinner.png) |
| `2280:82` | Tell the vendor (sheet) | differs: the card drops Not a login (owner ruling on the vendor account); numbers are the story's. | [compare](compare/2280-82_tell_vendor.png) |
| `2266:220` | Make it a change (sheet) | differs: Owner and Check after titles are semibold; no chevron on Owner; Check after has no Wednesday lunch text. | [compare](compare/2266-220_make_change_or_check.png) |
| `2260:162194` | Safety case · Open | differs: the elapsed time is missing on the 7 AM clock, before the case exists. Reached by the walk with a scratch-seeded SOS. | [compare](compare/2260-162194_safety_case.png) |
| `2262:6` | Students | matches | [compare](compare/2262-6_students.png) |
| `2262:237` | Students · Remind (sheet) | differs: the note is reworded (no delivery claim). | [compare](compare/2262-237_remind_sheet.png) |
| `2263:6` | Students · Feedback | differs: the meal row reads — sent → — came, because the story meal has not closed at 7 AM. | [compare](compare/2263-6_feedback.png) |
| `2263:218` | Students · Community | matches | [compare](compare/2263-218_community.png) |
| `2263:556` | Students · Why students skip | matches | [compare](compare/2263-556_why_skip.png) |
| `2264:6` | Results · Left over | matches | [compare](compare/2264-6_left_over.png) |
| `2264:254` | Results · Ran out | matches | [compare](compare/2264-254_ran_out.png) |
| `2307:6` | Results · To check | differs: adds a Safety cases row, the only way in; row details are the story's. | [compare](compare/2307-6_to_check.png) |
| `2264:162932` | Reason · Fewer students came | differs: the Wed lunch card is left out until that meal closes; the title takes two lines, not three. | [compare](compare/2264-162932_reason_fewer.png) |
| `2264:163140` | Reason · Didn't like a dish | differs: the Wed lunch card shows dashes until the meal closes. | [compare](compare/2264-163140_reason_dislike.png) |
| `2264:163320` | Reason · Raised late | differs: the Wed lunch card says Not closed yet until the meal closes. | [compare](compare/2264-163320_reason_raised.png) |
| `2264:163485` | Reason · Can't tell · Left over | differs: the Wed lunch card shows dashes until the meal closes. | [compare](compare/2264-163485_reason_cant_left.png) |
| `2264:163708` | Reason · More students came | differs: says 47 more where the frame says 8% more. A reason never carries a percentage. | [compare](compare/2264-163708_reason_more.png) |
| `2264:163865` | Reason · Last 30 minutes | differs: says Most entries where the frame says 41%. A reason never carries a percentage. | [compare](compare/2264-163865_reason_last30.png) |
| `2264:164014` | Reason · Reported late | matches | [compare](compare/2264-164014_reason_late.png) |
| `2264:164159` | Reason · Can't tell · Ran out | differs: the Wed lunch card shows dashes until the meal closes. | [compare](compare/2264-164159_reason_cant_ran.png) |
| `2266:6` | Check next time · Wednesday | differs: Wed 14 Aug reads waiting at 7 AM; a note about the change being in place sits below. | [compare](compare/2266-6_check_wednesday.png) |
| `2307:165978` | Check next time · North scanner | matches | [compare](compare/2307-165978_north_scanner.png) |
| `2266:426` | Find a meal | differs: the Date row is read only (no date filter is built); the Wed row shows dashes until the meal closes. | [compare](compare/2266-426_find_meal.png) |
| `2266:795` | Safety cases | differs: no elapsed time on the 7 AM clock, because the case is reported at 12:45. | [compare](compare/2266-795_safety_cases.png) |
| `2308:112` | Weekly report · This week | differs: the Export CSV row sits under the tab bar and needs a scroll; the third figure is mono. | [compare](compare/2308-112_weekly_this.png) |
| `2308:279` | Weekly report · Last week | differs: as This week. | [compare](compare/2308-279_weekly_last.png) |
| `2308:429` | Weekly report · Month | differs: as This week. | [compare](compare/2308-429_weekly_month.png) |
| `2311:6` | Weekly report · Preparing | differs: the shared button shows a grey spinner with no words; Export CSV sits lower. | [compare](compare/2311-6_preparing.png) |
| `2311:300` | Weekly report · Report ready | differs: a full preview that says no file was made, in place of Report ready, Save to Files and Share. PDF is not built. | [compare](compare/2311-300_report_ready.png) |
| `2311:549` | Tell the vendor · Weekly | matches | [compare](compare/2311-549_weekly_vendor.png) |
| `2278:240` | Weekly menu · Published | matches | [compare](compare/2278-240_weekly_menu.png) |
| `2278:1065` | Weekly menu · Check Thu 15 | matches | [compare](compare/2278-1065_check_thu.png) |
| `2313:6` | Edit day · Lunch | differs: keeps an Add a dish link, the only way in; a seventh row shows part way. | [compare](compare/2313-6_edit_lunch.png) |
| `2313:166457` | Edit day · Breakfast | differs: as Lunch; dish list runs longer. | [compare](compare/2313-166457_edit_breakfast.png) |
| `2313:166736` | Edit day · Snacks | differs: Add a dish is a link, not the inline field with chips; Tea and Coffee are two rows; highlights differ. | [compare](compare/2313-166736_edit_snacks.png) |
| `2313:166911` | Edit day · Dinner | differs: as Lunch; two highlights differ from the frame. | [compare](compare/2313-166911_edit_dinner.png) |
| `2313:167284` | Edit day · Highlight changed | differs: the walk changed Steamed Rice, the same control; Add a dish link. | [compare](compare/2313-167284_highlight_changed.png) |
| `2313:167566` | Edit day · Veg changed | differs: the walk changed Onion Pulao, not Kadi Pakoda; Add a dish link. | [compare](compare/2313-167566_veg_changed.png) |
| `2321:6` | Edit day · Reordered | differs: Add a dish link. Reached by a long-press drag in the walk. | [compare](compare/2321-6_reordered.png) |
| `2313:168130` | Edit day · Swipe to delete | differs: iOS draws the Delete action as a pill; the walk swiped Kadi Pakoda. | [compare](compare/2313-168130_swipe_delete.png) |
| `2313:168417` | Edit day · Deleted | differs: the shared toast is white with no Undo; Undo sits at the top of the page. | [compare](compare/2313-168417_deleted.png) |
| `2313:168692` | Edit day · Copied last Thursday | differs: Add a dish link sits under the note. | [compare](compare/2313-168692_copied.png) |
| `2313:168976` | Edit day · Tell students off | differs: Add a dish link. | [compare](compare/2313-168976_tell_off.png) |
| `2313:169258` | Edit day · Saved | differs: the toast is reworded (no delivery claim) and white. | [compare](compare/2313-169258_saved.png) |
| `2313:169544` | Edit day · Saved quietly | differs: the toast is white. | [compare](compare/2313-169544_saved_quietly.png) |
| `2313:169830` | Edit day · Dish added | differs: no Undo in the shared toast; the new dish lands below the fold. | [compare](compare/2313-169830_dish_added.png) |
| `2313:170131` | Edit day · Check this word (sheet) | matches | [compare](compare/2313-170131_check_word.png) |
| `2313:170380` | Edit day · Add a dish (sheet) | differs: chips come from the sample list for Cur; keyboard showing. | [compare](compare/2313-170380_add_dish_typed.png) |
| `2313:170629` | Edit day · Word checked | differs: no word toast; the row keeps the name in this capture, because the walk confirmed the word as read. | [compare](compare/2313-170629_word_checked.png) |
| `2320:6` | Change today's dinner (sheet) | differs: no preview box or Continue on this first step, because nothing has been chosen yet. | [compare](compare/2320-6_change_dinner.png) |
| `2320:264` | Swap a dish · Pick (sheet) | differs: the shared sheet runs full height; list order is the seed's. | [compare](compare/2320-264_swap_pick.png) |
| `2320:506` | Swap a dish · Replacement (sheet) | differs: the walk picked Chappathi and typed nothing; Swap stays disabled until a name is given. | [compare](compare/2320-506_swap_replacement.png) |
| `2320:733` | Add a special (sheet) | differs: Veg and Non-veg use the shared segmented control, not the two marks; nothing typed. | [compare](compare/2320-733_add_special.png) |
| `2320:968` | Remove a dish · Pick (sheet) | differs: as Swap a dish · Pick. | [compare](compare/2320-968_remove_pick.png) |
| `2320:1210` | Remove a dish · Confirm (sheet) | matches | [compare](compare/2320-1210_remove_confirm.png) |
| `2320:1430` | Send to students (sheet) | differs: the line under the card is reworded (no delivery claim); the walk removed a dish. | [compare](compare/2320-1430_send_preview.png) |
| `2320:1657` | Dinner change sent (toast) | differs: the toast is reworded and white. | [compare](compare/2320-1657_change_sent.png) |
| `2278:6` | More | matches | [compare](compare/2278-6_more.png) |
| `2278:166146` | People and access | differs: the vendor card drops Not a login (owner ruling). | [compare](compare/2278-166146_people.png) |
| `2278:166912` | Outings · Admin | matches | [compare](compare/2278-166912_outings.png) |
| `2278:167100` | Announce · Write | differs: title stays on one line and chips wrap differently, from the font. | [compare](compare/2278-167100_announce.png) |
| `2278:167264` | Announce · Confirm (sheet) | differs: the reach line is reworded (no delivery claim). | [compare](compare/2278-167264_announce_confirm.png) |
| `2277:1788` | Special passes | matches | [compare](compare/2277-1788_passes.png) |
| `2277:2081` | Menu voting | matches | [compare](compare/2277-2081_votes.png) |
| `2277:2474` | Rewards | differs: the ticket's edge notches are not drawn; the budget ring is simpler. | [compare](compare/2277-2474_rewards.png) |
| `2277:2967` | Spare food | differs: the frame marks Accepted as a small dot and Collected lime; the build puts lime on the step reached. | [compare](compare/2277-2967_spare_food.png) |
| `2277:3410` | History | differs: the mini strip is decorative; timeline spacing is tighter. | [compare](compare/2277-3410_history.png) |

## Not built

- `2260:162800` Safety case · Closed: no closed case exists on the seed, so it can't be reached. The page handles the state.
- `2313:167848` Edit day · Reordering: a mid-drag state, not captured. The finished drag is on `2321:6`.
- `2311:104`, `2311:202` CSV and PDF saved toasts: no file is made, so nothing may say one was saved.

Also on the frames, with no page behind them: Rules, Redemptions, Decide, New proposals, the Passes request row, See dishes and steps, See all and the Outings rows. Controls say "This isn't part of this prototype."; the chips do nothing. `F03` Report PDF pages show inside the preview sheet.

## Built beyond the frames

`A06_students_not_answered_by_mess` is archived in the inventory, but `2262:6` draws its row, so the page exists. "Answers close at 9 AM tomorrow" is left off: cutoff times come from the backend.

## Added backend pieces

Each is additive, with tests, in its own `feat(backend)` commit. All values are **samples, not measured**, cited to frames in `Data/Demo/DemoAdminMesses.swift`.

- `AdminMessRepository`, a new protocol with `AdminMessesNotBuilt` for a source without it, and `Repositories.adminMesses`, defaulted so no caller changed.
- `Domain/AdminMesses.swift`, `Data/Demo/DemoAdminMesses.swift`.
- Samples: North 700, range 660–740, 2,310 said yes, usual Wed 692, send by 11:30 (`2259:6`); South 612, sent 10:15, no reply for 55 min (`2259:160423`); Annexe no data (`2257:158261`); dinner due 4:30 PM, forecast at 3:30 (`2258:460`); usual by now ~690 (`2260:160216`); not answered 210, 180, 160, 80 (`A06_students_not_answered_by_mess`).
- SIMULATED: Send on a sample mess reaches nobody.

## Wording changed

No longer claims delivery:

| Was | Now |
|---|---|
| Saved. Students see it now. | Saved and marked to tell students. |
| Sent. Students see the new dinner. | Dinner change saved and marked to tell students. |
| All N students get this now, in Notifications and on Home. | This is addressed to all N students, in Notifications and on Home. |
| About N students at X get a notification now. | This is addressed to about N students at X. |
| Sends one notification. Students who already answered get nothing. | Queues one notification. Students who already answered are left out. |
| Reminder sent | Reminder queued |
| Announcement sent | Announcement queued |
| Invite sent | Invite queued |

Other: the tile button reads Approve (was Review and approve). It opens the page and approves nothing. The swipe action reads Delete.

## Local views added

`AdminChip`, `AdminDishPictogram`, `AdminBackButton`, `AdminSwitchStyle`, `AdminVegMark`, `AdminCurvedArrow`, `AdminProblemIcon`, `AdminChevron`, `AdminRangeBar`, `AdminLiveBar`, `AdminMessGrid`, `AdminTileCard`, `AdminOtherMessTile`, `AdminRewardTicket`, `AdminHistoryStrip`. The Edit day tab bar is hidden from `AdminRootView`, the Admin feature root.

## Open questions (proposed IDs)

- **P-ADMIN-FIG-1:** should the other messes become real? North, South and Annexe are samples, and only Main moves with the story. This is the mess-source item deferred earlier.
- **P-ADMIN-FIG-2:** what makes a dish "OK" on Live meal, and what makes a meal "On track"? No record or threshold exists, so the build says No report and drops On track.
- **P-ADMIN-FIG-3:** Headcount has 3 stops in Figma and 4 in the build, because approval is its own step (FR-HC-004). Keep 4?
- **P-ADMIN-FIG-4:** Not a login on the vendor card: the frame draws it, an earlier ruling removed it. Which wins?
- **P-ADMIN-FIG-5:** should the shared toast, sheet, offline banner and loading button be changed to match? Listed in C3, C4 and on `2258:1314`, `2311:6`.
- **T7:** tab icons, as in C2.
- **P-ADMIN-FIG-6:** should the Today tile keep the small value name (Live forecast)? The frame has none; it stays so one headcount value can't pass for another.
