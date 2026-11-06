# Supervisor (Part 4c) verification

Branch `feat/ios-supervisor`, based on `feature/swiftui-foundation` at `a4ae9c7` (contains the tips of
`feat/ios-core-story-contracts` 47e5abb, `fix/ios-waste-role-guard` 583c255 and `feat/ios-shared-components` 6a0d2c3,
checked with `git merge-base --is-ancestor`).

Sources: `design/reference/supervisor_2026-10/` (S00–S19, `data/supervisor_spec.md`), the 45 exports in
`design/audit/export_supervisor/`, `design/audit/supervisor/decisions.md`, `docs/SCREEN_INVENTORY.md` (Supervisor, 45 rows),
`docs/COMPONENT_CATALOG.md`, Kitchen Home as the pattern.

## Tabs

Home, Alerts, Me, in that order (S01, S07, S16 tab bars; spec "Bottom bar Home, Alerts, Me"). Meal history opens from Me
only. Pushed pages hide the tab bar (S10, S12, S18, S19 draw none). The root is `SupervisorRootView`; it uses the shared
`StaffTabBar` but its own tabs and navigation, so Alerts and Me are the Supervisor's, not the shared placeholders.

## Reference table

"Data" says where every value comes from. "Shot" is the file name in `small/` and `large/`.

| Reference (inventory row) | State | Tab | Components | Data-driven | Shot |
|---|---|---|---|---|---|
| `S00_what_you_do_sheet` | What you do sheet (role selection) | Entry | StaffEntry `WhatYouDoSheet` (Part 1) | Not changed: lives in the retired Debug-only role flow in `Features/StaffEntry/`; email sign-in goes straight to Home | — |
| `S01_home_not_started` | Home · not started, Start meal | Home | OrbitBackground, StaffHeader, ScreenTitleBlock, HeroCard, HeroEyebrow, HeroCount, LimeActionButton, QuietRow; local SupervisorStatus | Yes: currentMeal, headcount.liveForecast, follow-ups (shortages + mealHistory) | [small](small/S01_home_not_started.png) · [large](large/S01_home_not_started.png) |
| `S14_start_meal_dialog` | Start this meal? | Home | mlConfirmDialog | Yes: meal slot and mess from the loaded meal | [small](small/S14_start_meal_dialog.png) · [large](large/S14_start_meal_dialog.png) |
| `S02_home_in_service` | Home · in service, Close meal | Home | MealProgressChip, HeroCard, HeroCount; local SupervisorHeroOutlineButton | Yes: liveCount (students entered only), startedAt → minutes | [small](small/S02_home_in_service.png) · [large](large/S02_home_in_service.png) |
| `S03_home_in_service_sos_tab` | Home · in service with SOS tab | Home | SOSEdgeTab | Yes: sos.activeCases | [small](small/S03_home_in_service_sos_tab.png) · [large](large/S03_home_in_service_sos_tab.png) |
| `S15_close_meal_dialog` | Close this meal? | Home | mlConfirmDialog | Yes | [small](small/S15_close_meal_dialog.png) · [large](large/S15_close_meal_dialog.png) |
| `S06_home_closed` | Home · closed, final entries | Home | HeroCard, HeroEyebrow; local SupervisorStatus (ink dot) | Yes: finalCount, closedAt | [small](small/S06_home_closed.png) · [large](large/S06_home_closed.png) |
| `S06b_home_closed_unavailable` | Home · closed, final count missing | Home | same | View handles `.unavailable` ("Unavailable" + "The final count did not arrive."). The prototype backend always has a final count after closing, so the shot is drawn from a constructed `SupervisorHomeContent` | [small](small/S06b_home_closed_unavailable_constructed.png) · [large](large/S06b_home_closed_unavailable_constructed.png) |
| `S02b_home_in_service_offline` | Home · in service, offline | Home | AsyncContentView offline → OfflineBanner | Yes: offline after load keeps the last values | [small](small/S02b_home_in_service_offline.png) · [large](large/S02b_home_in_service_offline.png) |
| `S06c_home_closed_shortage_resolved` | Home · closed, shortage resolved | Home | QuietRow | Yes: Active shortages 0, Waste not recorded 2 | [small](small/S06c_home_closed_shortage_resolved.png) · [large](large/S06c_home_closed_shortage_resolved.png) |
| `S07a_alerts_before_meal` | Alerts · before the meal | Alerts | SupervisorGroupLabel, SupervisorTaskRow (local) | Yes: Dinner Tue 13 from mealHistory | [small](small/S07a_alerts_before_meal.png) · [large](large/S07a_alerts_before_meal.png) |
| `S07b_alerts_during_meal` | Alerts · during the meal | Alerts | same | Yes: Steamed Rice + Dinner Tue 13 | [small](small/S07b_alerts_during_meal.png) · [large](large/S07b_alerts_during_meal.png) |
| `S08_alerts_with_sos` | Alerts · SOS card on top | Alerts | SOSCard (eyebrow "SOS", no action) | Yes | [small](small/S08_alerts_with_sos.png) · [large](large/S08_alerts_with_sos.png) |
| `S07_alerts_pending` | Alerts · after the meal | Alerts | same | Yes: Steamed Rice, Lunch Wed 14 (Closed 2:00 PM), Dinner Tue 13 (598 entered) | [small](small/S07_alerts_pending.png) · [large](large/S07_alerts_pending.png) |
| `S07c_alerts_shortage_resolved` | Alerts · shortage resolved, toast | Alerts | mlToast | Yes | [small](small/S07c_alerts_shortage_resolved.png) · [large](large/S07c_alerts_shortage_resolved.png) |
| `S09_alerts_empty` | Alerts · all caught up | Alerts | StateBlock | Yes, but see difference D3: the seed's Dinner Tue 13 is never recorded, so the shot uses a mess with no open tasks | [small](small/S09_alerts_empty_other_mess.png) · [large](large/S09_alerts_empty_other_mess.png) |
| `S12_shortage_details` | Shortage details, Mark resolved | Alerts (pushed) | SupervisorPageHeader (BackButton), SupervisorFactRow, InkActionButton | Yes: shortages(for:) | [small](small/S12_shortage_details.png) · [large](large/S12_shortage_details.png) |
| `S13_shortage_resolve_dialog` | Mark shortage as resolved? | Alerts (pushed) | mlConfirmDialog | Yes: dish name | [small](small/S13_shortage_resolve_dialog.png) · [large](large/S13_shortage_resolve_dialog.png) |
| `S10_waste_report_read_only` | Waste report · Tue 13 Lunch, details open | Alerts / Me (pushed) | local tiles, rows; SupervisorStatus lime | Yes: mealHistory record rows | [small](small/S10_waste_report_read_only.png) · [large](large/S10_waste_report_read_only.png) |
| `S10b_waste_report_details_closed` | Waste report · details closed | pushed | same | Yes | [small](small/S10b_waste_report_details_closed.png) · [large](large/S10b_waste_report_details_closed.png) |
| `S10c_waste_report_lunch_wed_recorded` | Waste report · today's, saved by the kitchen | pushed | same | Yes: wasteReports.report(for:) after Kitchen Staff `save` (8 dishes, Tomato Dal not made, 18 kg) | [small](small/S10c_waste_report_lunch_wed_recorded.png) · [large](large/S10c_waste_report_lunch_wed_recorded.png) |
| `S11_waste_report_not_recorded` | Waste report · Dinner Tue 13 not recorded | pushed | local final-entries card | Yes: 598 from the record | [small](small/S11_waste_report_not_recorded.png) · [large](large/S11_waste_report_not_recorded.png) |
| `S11b_waste_report_lunch_wed_not_recorded` | Waste report · Lunch Wed 14 not recorded | pushed | same | Yes: 774 final entries | [small](small/S11b_waste_report_lunch_wed_not_recorded.png) · [large](large/S11b_waste_report_lunch_wed_not_recorded.png) |
| `S04_sos_panel_not_taken` | SOS panel · not taken | Home (sheet) | mlSheet, SOSPanel | Yes | [small](small/S04_sos_panel_not_taken.png) · [large](large/S04_sos_panel_not_taken.png) |
| `S04b_sos_panel_claimed_by_you` | SOS panel · claimed by you | Home (sheet) | SOSPanel | Yes: claim by .supervisor | [small](small/S04b_sos_panel_claimed_by_you.png) · [large](large/S04b_sos_panel_claimed_by_you.png) |
| `S03b_home_sos_claimed_by_you` | Home · SOS claimed by you (lime tab) | Home | SOSEdgeTab isClaimedByYou | Yes | [small](small/S03b_home_sos_claimed_by_you.png) · [large](large/S03b_home_sos_claimed_by_you.png) |
| `S05b_sos_panel_checked_by_supervisor` | SOS panel · checked by the supervisor | Home (sheet) | SOSPanel, Close case / Not yet | Yes: markChecked by .supervisor | [small](small/S05b_sos_panel_checked_by_supervisor.png) · [large](large/S05b_sos_panel_checked_by_supervisor.png) |
| `S05_sos_panel_checked_close_case` | SOS panel · checked by the door | Home (sheet) | SOSPanel | Yes: door claim + markChecked at 12:52 PM | [small](small/S05_sos_panel_checked_close_case.png) · [large](large/S05_sos_panel_checked_close_case.png) |
| `S05c_home_case_closed` | Home · case closed, toast, no tab | Home | mlToast | Yes: close → activeCases empty | [small](small/S05c_home_case_closed.png) · [large](large/S05c_home_case_closed.png) |
| `S16a_me_before_meal` | Me · before the meal (0 / 1) | Me | QuietRow, SupervisorGroupLabel; local avatar block | Yes: same follow-ups as Home | [small](small/S16a_me_before_meal.png) · [large](large/S16a_me_before_meal.png) |
| `S16b_me_during_meal` | Me · during the meal (1 / 1) | Me | same | Yes | [small](small/S16b_me_during_meal.png) · [large](large/S16b_me_during_meal.png) |
| `S16_me` | Me · after the meal (1 / 2) | Me | same | Yes | [small](small/S16_me.png) · [large](large/S16_me.png) |
| `S16c_me_shortage_resolved` | Me · shortage resolved (0 / 2) | Me | same | Yes | [small](small/S16c_me_shortage_resolved.png) · [large](large/S16c_me_shortage_resolved.png) |
| `S17_signout_dialog` | Sign out? | Me | mlConfirmDialog | Copy only; Sign out resets the router and the session | [small](small/S17_signout_dialog.png) · [large](large/S17_signout_dialog.png) |
| `S18_meal_history` | Meal history | Me (pushed) | SupervisorTaskRow | Yes: mealHistory | [small](small/S18_meal_history.png) · [large](large/S18_meal_history.png) |
| `S18b_meal_history_shortage_resolved` | Meal history · shortage resolved | Me (pushed) | same | Yes | [small](small/S18b_meal_history_shortage_resolved.png) · [large](large/S18b_meal_history_shortage_resolved.png) |
| `S18c_meal_history_loading` | Meal history · loading | Me (pushed) | AsyncContentView loading | Yes: a history source that has not answered | [small](small/S18c_meal_history_loading.png) · [large](large/S18c_meal_history_loading.png) |
| `S18d_meal_history_empty` | Meal history · empty | Me (pushed) | AsyncContentView empty ("No meals yet") | Yes: a mess with no closed meals | [small](small/S18d_meal_history_empty.png) · [large](large/S18d_meal_history_empty.png) |
| `S18e_meal_history_error` | Meal history · error | Me (pushed) | AsyncContentView offline / failed | Yes: shot shows the offline form (no saved list); a non-offline error shows "Couldn't load" + Try again | [small](small/S18e_meal_history_error_offline.png) · [large](large/S18e_meal_history_error_offline.png) |
| `S19_past_meal_summary` | Past meal · Tue 13 Lunch | Me (pushed) | SupervisorFactRow, TextLinkButton | Yes | [small](small/S19_past_meal_summary.png) · [large](large/S19_past_meal_summary.png) |
| `S19b_past_meal_wed_lunch` | Past meal · Wed 14 Lunch, shortage active | Me (pushed) | same | Yes | [small](small/S19b_past_meal_wed_lunch.png) · [large](large/S19b_past_meal_wed_lunch.png) |
| `S19c_past_meal_wed_lunch_resolved` | Past meal · Wed 14 Lunch, resolved | Me (pushed) | same | Yes | [small](small/S19c_past_meal_wed_lunch_resolved.png) · [large](large/S19c_past_meal_wed_lunch_resolved.png) |
| `S19d_past_meal_wed_breakfast` | Past meal · Wed 14 Breakfast | Me (pushed) | same | Yes: unnamed shortage shown as "1 shortage" | [small](small/S19d_past_meal_wed_breakfast.png) · [large](large/S19d_past_meal_wed_breakfast.png) |
| `S19e_past_meal_tue_dinner` | Past meal · Tue 13 Dinner | Me (pushed) | same | Yes | [small](small/S19e_past_meal_tue_dinner.png) · [large](large/S19e_past_meal_tue_dinner.png) |
| `S19f_past_meal_mon_dinner_unavailable` | Past meal · Mon 12 Dinner, Unavailable | Me (pushed) | same | Yes: `.unavailable`, never 0 | [small](small/S19f_past_meal_mon_dinner_unavailable.png) · [large](large/S19f_past_meal_mon_dinner_unavailable.png) |

45 inventory rows; 44 captured on each device (S00 belongs to the shared entry flow).

## Backend operations

| Item | Operation | State |
|---|---|---|
| Start meal | `MealStateRepository.startMeal` | Existed. Supervisor only; moves the clock to the meal start (12:00 PM). |
| Close meal | `MealStateRepository.closeMeal` | Existed. Supervisor only; moves the clock to the meal end (2:00 PM). Resolves nothing, completes no waste. |
| List shortages | `ShortageRepository.shortages(for:)` | Existed (current meal). |
| Resolve shortage | `ShortageRepository.markResolved` | Existed. Supervisor only. |
| Read waste | `WasteReportRepository.summary`, `report` | Existed (current meal). `save` / `saveDraft` refuse every role but Kitchen Staff (PR #11). |
| SOS claim, check, close | `SOSRepository.claim`, `markChecked`, `close` | Existed. `close` is Supervisor only. |
| SOS raise | `SOSRepository.raise(_ report: SOSReport)` | **Added** (`7acf5df`). Without it no case could ever exist, so the tab, claim and close were unreachable. Idempotent on its key; remote throws notImplemented. 6 tests (`SOSRaiseOperationTests`). |
| Meal history | `MealStateRepository.mealHistory(for:)` → `[MealRecord]` | **Added** (`da17fc8`). Needed by S18/S19, the Alerts "Waste not recorded" group and the follow-up counts (S01 shows Dinner Tue 13). The story meal joins once closed and reads the same state as every other role; earlier meals are seeded from S10, S11, S18, S19. Remote throws notImplemented. 7 tests (`MealHistoryOperationTests`). |

Both additions are additive: new protocol requirements implemented by `DemoDataProvider` and `RemoteAPI`, new types
`SOSReport` and `MealRecord`, new seed values with their source next to them. No existing operation changed.
`openapi.yaml` is not changed (not allowed in this part); both operations need an entry there (open question SV-Q3).

## Rules, and where each is enforced

| Rule | Where |
|---|---|
| Start and Close use confirmation dialogs and drive every role | `mlConfirmDialog` on Home → `SupervisorHomeViewModel.startMeal/closeMeal` → `MealStateRepository`; the view then calls `environment.dataDidChange()` so every screen reloads. The backend moves the clock; no view or view model sets it. |
| Closing resolves no shortage and completes no waste | Backend unchanged; tested (`testClosingLeavesShortagesUnresolvedAndWasteIncomplete`, Kitchen sees `.notStarted` waste after close). |
| Shortages: Mark resolved | `SupervisorShortageViewModel.markResolved` → `ShortageRepository.markResolved` (Supervisor only, tested). |
| Waste read only, no approval or forward | The page has no action but Back; the repository refuses `save`/`saveDraft` for the Supervisor (tested). Saved waste reads "Recorded by the kitchen". Missing waste reads "Not recorded" with the final entries; missing quantities say so; nothing is zero-filled. |
| SOS tab only while active; staff claim and check; only the Supervisor closes | `SupervisorSOSModel` + shared `SOSEdgeTab`/`SOSPanel`/`SOSCard`; Close case is offered only once the case is checked; the repository refuses close for other roles (tested). |
| One task, one count | `SupervisorFollowUps.load` is the single source for Home, Alerts and Me (tested equal). |
| Missing data never zero | `CountReading.unavailable` → "Unavailable"; `MealRecord` keeps nil for values the pack does not draw. |
| Status as dot + text | Local `SupervisorStatus` (ink, open, lime dots). SOS chips stay as the shared SOS card draws them (lime exception, decision 6). |
| One primary action per screen | Home: Start meal / Close meal; Shortage: Mark resolved; SOS panel: one ink button; other pages none. |
| Type: mono for numbers, times, units only; body 15, secondary 13, minimum 12 | Shared tokens only (`MLType`); no new sizes below 12. |
| Targets ≥ 44 pt, staff buttons 56 pt | Rows 56 pt (`QuietRow`, task rows, fact rows); read-only dish lines 44 pt (not tappable); buttons 56 pt. |
| Non-Supervisor sessions cannot reach the role | `RoleRoot` maps only `.supervisor` here, and `SupervisorRootView.allows` also needs a Supervisor staff session (tested for all 10 other roles). |

## Differences from the references

| # | Where | Difference | Why |
|---|---|---|---|
| D1 | Home cards | Hero numbers 56 pt (`MLType.heroNumber`) vs about 90 pt drawn | Shared token, same as Kitchen (decision 4, gap 556). |
| D2 | S04, S05, S08 | Card age is computed: "55 min ago" at 1:40 PM for a 12:45 PM case; the pack draws "5 min ago" | The pack's own clock mismatch (decision 26, gap 546). |
| D3 | S09 | Shot uses a mess with no open tasks | In the seed, Dinner Tue 13 is never recorded and the kitchen can only save the story meal, so the main mess always has one task. See SV-Q4. |
| D4 | S06b | Shot drawn from a constructed `SupervisorHomeContent` | The prototype backend always has a final count after closing; the view's `.unavailable` branch is the real one. |
| D5 | S02b | Offline uses the shared `OfflineBanner` (via `AsyncContentView`), not only a header dot | Inventory lists OfflineBanner; spec says "a small offline dot in the header". SV-Q7. |
| D6 | S16 | "Meal history" row is regular weight (shared `QuietRow`); S16 draws it bold | Shared component, not changed. |
| D7 | S19 | Waste line is always "By the kitchen · ● Recorded · time"; S19 draws "Recorded by the kitchen · ● 2:40 PM" | One form for every past meal (S19d, S19f use "By the kitchen"). |
| D8 | S05 shot | "LIVE · 1:40 PM" while the harness clock is 12:59 PM | The seeded live count is stamped 1:40 PM in the `duringMeal` scenario (existing seed). |
| D9 | All shots | No status bar | Shots are the app window drawn to PNG by the harness, not device screenshots. |
| D10 | S04b | Helper "When you have seen it, mark it as checked. You can close the case after." | No image of this helper; wording from decision 7. |
| D11 | Not drawn | Case claimed by another role, not yet checked: outline chip "The door is checking this", "I'll go and check" / "Not now" | Spec lists no such state. SV-Q6. |
| D12 | Recorded, no rows | "The kitchen's quantities for this report are not available here." | Mon 12 Dinner and the Debug "Waste recorded" moment have no rows; never zeros. Wording not drawn (SV-Q9). |

## Open questions (proposed IDs for the owner)

- **SV-Q1** Shared `StatusText` has no ink-filled dot ("Active", "Closed"). The Supervisor uses a local `SupervisorStatus`. Add `.ink` to `StatusText` (shared-file owner)?
- **SV-Q2** Breakfast Wed 14: `mealHistory` gives 402 final entries (S18) while the existing `EntryRepository.finalCount(breakfast)` returns `.unavailable` (not changed). Which source wins?
- **SV-Q3** `docs/backend/openapi.yaml` needs `SOSRepository.raise` and `MealStateRepository.mealHistory` (not edited here).
- **SV-Q4** Should the prototype let the kitchen record an earlier meal's report (Dinner Tue 13), so "All caught up" is reachable in the main mess?
- **SV-Q5** No presenter path raises an SOS in the running app until the student SOS flow (Part 3e) calls `raise`. Add a Debug moment "SOS active" in `DemoDataProvider` (shared file)?
- **SV-Q6** Confirm the undrawn "claimed by someone else" panel (D11).
- **SV-Q7** Offline: banner (current, shared pattern) or header dot only (spec)?
- **SV-Q8** Carried from the pack: Start meal always available (gap 537), reminder for missing waste (538), who else may close a case (539), Mon 12 Unavailable vs Kitchen 577 (549).
- **SV-Q9** Wording for a recorded report without quantities (D12).

## Commands and results

All on simulators created for this run ("Supervisor SE" = iPhone SE 3rd gen, iOS 26.5; "Supervisor Pro Max" = iPhone 17 Pro Max, iOS 26.5). Xcode 27.2.

| Command | Exit | Result |
|---|---|---|
| Baseline before changes: `xcodebuild test -scheme MealLoop -configuration Debug` (iPhone 18 Pro) | 0 | 145 passed, 0 failed, 0 skipped |
| `xcodebuild test -scheme MealLoop -configuration Debug -parallel-testing-enabled NO -resultBundlePath debug.xcresult` | 0 | **187 tests: 183 passed, 0 failed, 4 skipped** |
| `xcodebuild test -scheme "MealLoop Review" -configuration Review -parallel-testing-enabled NO -resultBundlePath review.xcresult` | 0 | **186 tests: 182 passed, 0 failed, 4 skipped** |
| `xcodebuild build -scheme MealLoop -configuration Release -destination 'generic/platform=iOS Simulator'` | 0 | BUILD SUCCEEDED |
| `TEST_RUNNER_SUPERVISOR_SHOTS=… xcodebuild test -only-testing:MealLoopTests/SupervisorScreenshotTests` on both simulators | 0 | 44 PNGs each (`small/`, `large/`; large downscaled to 1434 px high) |

New tests: `SOSRaiseOperationTests` 6, `MealHistoryOperationTests` 7, `SupervisorViewModelTests` 25 (+38 passing). The 4 skipped are the `SupervisorScreenshotTests` methods, which run only when an output folder is given. Existing tests all still pass.

Diff against `origin/feature/swiftui-foundation`: `Features/Supervisor/**`, `MealLoopTests/{Supervisor*,SOSRaiseOperationTests,MealHistoryOperationTests}.swift`, `docs/verification/supervisor/**`, and for the two backend operations only: `Domain/SOSCase.swift` (+`SOSReport`), `Domain/MealRecord.swift` (new), `Data/Repositories/Repositories.swift` (+2 requirements), `Data/Remote/RemoteAPI.swift` (+2 stubs), `Data/Demo/DemoDataProvider.swift`, `Data/Demo/DemoSeed.swift` (additions only). No change to `RoleRootView`, shared components, tokens, `GlassTabBar`, `openapi.yaml`, ADRs, project settings, `OPEN_DECISIONS.md` or `FOUNDATION_VERIFICATION.md`.

Hardcoded data: `grep -nE '\b(860|714|774|598|806|402|21|18)\b|Steamed Rice|Ravi|Main Mess|Block A|12:45|1:30|2:40|"RV"'` over the Supervisor views finds only three doc comments. Every value comes from a view model; every word from `SupervisorCopy`.

## What could not be run

- **Tapping through the installed app in the simulator.** Access to the booted iPhone 18 Pro panel was declined in this session, and this repository has no UI-test target (adding one changes project settings, which this part may not do). Instead every state was reached through the prototype backend's own operations and the real Supervisor views were drawn on both simulators by `SupervisorScreenshotTests`. Dialogs and the SOS sheet in the shots are opened with the real `mlConfirmDialog` / `mlSheet` modifiers, but not by a tap.
- The Review build was built and its tests run; it was not launched for a manual walk.

