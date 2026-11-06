# Admin Students, Results and More: verification

Branch `feat/ios-admin-results-more`, based on `feature/swiftui-foundation` at `2b2abee`, which contains the tips of `feat/ios-core-story-contracts`, `fix/ios-waste-role-guard`, `feat/ios-shared-components` and `feat/ios-supervisor`. Code checked at `ea63e99` on 2026-11-07.

## Results

Xcode 27.2, iPhone 17 Pro Max simulator, iOS 27.0. Counts come from each `.xcresult`.

| Run | Exit | Executed | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug tests | 0 | 305 | 301 | 0 | 4 |
| Review tests | 0 | 304 | 300 | 0 | 4 |
| Release build | 0 | n/a | n/a | n/a | n/a |

The 4 skipped tests are the opt-in `SupervisorScreenshotTests`, on the base already. 51 tests are new: 42 in `AdminResultsMoreTests` and 9 in `AdminBackendTests`. Review and Release ran from a clean build folder. Debug reused the iteration build folder. The Admin code has no compiler warnings. The Release binary has 0 `AdminSeed` or `DemoAdminStore` symbols and 0 sample strings.

**Scope:** the diff lists `Features/Admin/`, two Admin test files, this folder and the backend additions below. Today's files are unchanged. `AdminRootView` (the feature root) gained the three tabs.

**Hardcoded data:** a search of the views finds no `DemoSeed`, `AdminSeed`, sample names or sample counts, and no literal `Text("...")`. Lime as text appears once, on the black card. Nothing is below 12 pt.

**Percentages:** none in any reason, and a test reads every reason. The ones left are not reasons: data completeness, the ticket's arrow ("-10%", which compares two counts) and the vote result.

## How it was checked

- **Screenshots:** 78 states on each phone, in `large/` (iPhone 17 Pro Max, 440 pt, iOS 27.0) and `small/` (iPhone SE 3rd generation, 375 pt, iOS 26.5). `compare/` has 58 sheets with the reference on the left. All were compared by eye.
- **Method:** a scratch copy opened the real `AdminRootView` and tapped through it with the accessibility tree. The hook is not in the repository. Each state therefore also proves its route.
- **Set-up in the scratch copy:** `closed` states approve, send and close the story meal, and save a Kitchen report of Masala Sambar 4 L and plate waste 18 kg, through the real repositories. That is why the report says "Sent 1:40 PM". The waits for the upload and Preparing states were lengthened there so they could be caught.
- **Scratch-seeded:** only `A05_closed_scratch`. No closed case exists on the seed, as A07_results_safety_cases says, so this frame cannot be reached in the app.
- **Toasts:** they last 2 seconds, so some frames miss them. `F05_sent` and the large `F04_saved` frames show one. The large `F04_saved` frames come from the run before the last, whose Edit day code is the same. `A11_announced` shows the page after the toast went.
- **Machine:** other sessions were running. `pgrep -fl xcodebuild` counts lines of their shell commands (273 at one point), so it was not usable. The waits used `pgrep -x xcodebuild`. One build started before that was found, with the literal count above 4.
- **Simulators:** two were created for this work, then deleted. No others were touched.

## Reference table

Exports are in `design/audit/export_admin_redesign/` and `export_fix2/`. Tabs confirmed: Today, Students, Results, More and the round Search. Today and Search are unchanged. Data-driven means through a repository; "live" means the story meal reads the same repositories as every other role.

| Reference | State | Inventory row | Tab | Components | Data-driven | Screenshot |
|---|---|---|---|---|---|---|
| A06_students | Main, reminder sent, offline | `A06_students` | Students | `HeroCard`, `SectionHeader`, `LimeActionButton` | Yes | A06_students, _reminder_sent, _offline |
| A06 remind sheet | Who, message, send | `A06_students_remind_sheet` | Students | `mlSheet`, `InkActionButton` | Yes | A06_remind_sheet |
| A06 feedback | Problems, meal, vendor sheet | `A06_students_feedback_sambar_too_salty` | Students | `SectionHeader`, local rows | Yes | A06_feedback, _feedback_vendor |
| A06 community | Stages, assign owner, note | `A06_students_community_long_wait_at_north` | Students | `HeroCard`, `ChoiceChip` | Yes | A06_community, _assign_sheet, _owner_assigned |
| A06 why skip | Ranked, hidden groups | `A06_students_why_students_skip` | Students | local rows | Yes | A06_why_skip |
| A07, A08 | Left over, Ran out | `A07_results_left_over`, `A08_results_ran_out` | Results | `SegmentedChoice`, `HeroCard`, `StatusText` | Yes | A07_left_over, A08_ran_out, A07_offline |
| F01 | To check | `F01_results_to_check` | Results | `StatusText`, `QuietRow` | Yes, Wed row live | F01_to_check |
| A07 find meal | Mess and meal filters | `A07_results_find_meal` | Results | `ChoiceChip`, `SegmentedChoice` | Yes | A07_find_meal |
| A07 safety cases, A05 | List, open, closed, vendor sheet | `A07_results_safety_cases`, `A05_safety_case`, `_closed` | Results | `HeroCard`, `mlSheet` | Yes; closed is scratch | A07_safety_cases, A05_* |
| A09 ×8 | Each reason page | the eight `A09_reason_*` rows | Results | `StatusText`, local cards and bars | Yes | A09_*, A09_not_closed |
| A04, F01 Tue dinner | Report, data missing, not closed | `A04_meal_report`, `_data_missing`, `F01_..._meal_report_tue_dinner` | Results | local ticket | Yes, Wed live | A04_report, _data_missing, _not_closed, F01_report_tue_dinner |
| A04 sheets | Make it a change, Tell the vendor | `A04_meal_report_make_change`, `_tell_vendor_sheet` | Results | `mlSheet`, `FieldErrorText` | Yes | A04_make_change, A04_tell_vendor |
| A10, F01 North scanner | Testing, Open | `A10_check_next_time`, `F01_..._north_scanner` | Results | `HeroCard`, local stage line | Yes | A10_check_wednesday, A10_check_north |
| F02 | Three periods, preparing, preview, CSV note, vendor summary | `F02_weekly_report_*` (8 rows) | Results | `ChoiceChip`, `mlSheet` | Yes | F02_* |
| F03 pages 1 and 2 | Preview inside the sheet | `F03_report_pdf_page1`, `_page2` | Results | local | Yes | F02_preview |
| A11 | Hub | `A11_more` | More | local row | Yes | A11_more |
| A11 announce | Write, confirm | `A11_more_announce_write`, `_confirm_sheet` | More | `ChoiceChip`, `mlSheet` | Yes | A11_announce, _announce_confirm, _announced |
| A11 restyled, A14 | Passes, votes, rewards, spare food, history, outings | `A11_more_restyled_*`, `A14_outings_admin` | More | `HeroCard`, `StatusText` | Yes, read only | A11_passes and the others, A14_outings |
| A12, F05 published | Published, uploading, reading, check day | `A12_weekly_menu`, `_check_thu_15`, `F05_menu_weekly_menu_published` | More | `HeroCard`, `SegmentedProgress`, `CompactPillButton` | Yes, simulated flow | A12_* |
| F04 ×19 | One screen: meals, star, veg, drag, swipe delete, undo, copy, word sheet, add dish, tell students, saved | the `F04_menu_edit_day*` rows | More | `SegmentedChoice`, `mlSheet`, `ChoiceChip` | Yes | F04_* |
| F05 ×8 | Sheet, swap, special, remove, preview, sent | the `F05_menu_quick_change*` rows | More | `IconCardRow`, `mlSheet` | Yes | F05_* |
| A13 | Roles, role page, invite, vendor | `A13_people_access` | More | `QuietRow`, `mlSheet` | Yes | A13_* |

Drag reorder and swipe to delete were tested in the view model, not captured. Not in this part: A01 and A02 (Today) and A03 Live meal, which only Today opens.

## Backend additions (additive)

No existing operation or signature changed.

| Commit | Piece |
|---|---|
| `6afaec3` | `Domain/AdminResults.swift`, `AdminStudents.swift`, `AdminMore.swift`; `Data/Repositories/AdminRepositories.swift` with three protocols and `AdminDataNotBuilt`; three defaulted fields on `Repositories`, so existing call sites still compile |
| `d3b2425` | `Data/Demo/AdminSeed.swift` (each value cites its source), `AdminMenuSeed.swift` (generated from `mess_menu_2024-08-12.md`), `DemoAdminStore`, `DemoAdminRepositories`; in `DemoDataProvider`, `requireConnection()`, the store and the three arguments in `makeRepositories()`; `AdminBackendTests` |
| `1107210` | The story meal's pack facts appear only once it closes |

Every write takes a role and refuses anyone but the Food Head. A source with no Admin data throws `notImplemented`, so nothing is faked in Release.

## Differences left

- **Reason counts are seeded, not worked out.** The pack's rules are drafts, and the records to compute them don't exist.
- **Percent wording removed:** A09 draws "8% more" and "41% of entries". The pages say "47 more than the headcount sent" and "Most entries came in the last 30 minutes".
- **Status is a dot and text**, not the drawn pills, on Sure, Probably, Can't tell, Review, Testing, Open, Needs review and New.
- **No file claims:** F02's "Report ready", "Save to Files", "Share" and the saved toasts became "Report preview" and a line saying no file was made.
- **Vendor:** "Not a login" is dropped, because the PRD has a vendor account and Today follows it. "Nothing is sent for you" stays. Message, Call and Call Ravi say nothing happened.
- **Added links:** Safety cases is a third link on To check, because the pack draws no way in. Add a dish sits above the list, not at its end.
- **Display only, no target drawn in the kept pack:** Passes request, New proposals, Outings rows, role people. Decide, Rules, Catalogue and Redemptions and See all are left out. The role pages other than Kitchen staff have no permissions text.
- **Find a meal** has no date picker; it lists the period.
- **Data missing:** A04's "Event count" chip has no meal behind it. The state is shown by the real missing waste record, and "Data" is "—", not 60%.
- **Preparing** is a spinner with no words, because `InkActionButton` hides its title while loading.
- **Icons:** SF Symbols, not the drawn set (T7). Veg marks are ink, not green and red, as there is no token. The toggle has a white knob.
- **Small phone:** Edit day shows about three dishes above the fixed Save, then scrolls. The report preview pages are small print.
- **Wording not in the packs:** the explanations on Fewer and More came, the vendor messages for feedback and safety, "The change is in place...", and swap and remove lines in the student preview.

## Honesty notes for the presenter

- **Nothing leaves the phone.** "Reminder sent", "Announcement sent", "Invite sent", "Saved. Students see it now." and "Sent. Students see the new dinner." follow the pack, but students see nothing. Changes last until the app restarts.
- **The upload reads no photo.** The card says so. The seeded board appears, and it is a transcription of a blurry photo.
- **Story order:** in Review the Wed lunch rows show "—" and "Not closed yet" until the Supervisor closes the meal. The Kitchen's waste then appears in the report.
- **"Check next time" counts 0 of 2** until the story meal closes, then 1 of 2.

## Not run

A real device, VoiceOver by hand, largest Dynamic Type, Reduce Motion, an iOS 17 system, a real PDF, CSV or OCR step (not built).

## Shared changes needed, not made

| File | Change |
|---|---|
| `PlaceholderMetricTests.swift` | Add `.admin: ["Today", "Students", "Results", "More"]` to `built`, or the metric undercounts |
| `docs/PRESENTER_ACCOUNTS.md` | Food Head no longer lands on placeholders |
| `docs/SCREEN_INVENTORY.md` | Mark these rows built |
| `AdminTodayView` | Its Safety case route could open the page built here |

## Open questions (proposed IDs for `OPEN_DECISIONS.md`)

| ID | Question | What the prototype does now |
|---|---|---|
| P-ADMIN-7 | Wed lunch final entries: 786 (Admin pack) or 774 (Kitchen spec, seed)? | 774, from the live repositories |
| P-ADMIN-8 | Tue dinner, Main: the Admin pack has 640 → 691 with rice out; the Supervisor seed has 598 and no shortage. Which is right? | Each role keeps its own sample, so they disagree |
| P-ADMIN-9 | The pack gives three rice stories for its 2 ran-out meals (Wed 1:34 PM Main, Tue 8:34 PM Main, Mon 8:40 PM South, and Tue 1:50 PM North) and four reasons at 1 meal each. Which meals are meant? | Pages as drawn |
| P-ADMIN-10 | Confirm the draft thresholds: 5%, 40%, 15 minutes | None is applied |
| P-ADMIN-11 | How is "data complete" worked out? | The pack's value, and "—" with no waste record |
| P-ADMIN-12 | Does a comparable meal that ran out stop "worked", or only flag it? | It stops it |
| P-ADMIN-13 | Should simulated sends keep the pack's wording ("Students see it now")? | Kept |
| P-ADMIN-14 | Can the Food Head close a safety case? A05 says yes; `SOSRepository` says Supervisor only | The page is read only |
| P-ADMIN-15 | Should seed gain North, South and Annexe as messes? | Sample history only; Today shows Main |
| P-ADMIN-16 | Is Ravi Kitchen (Admin pack) or Supervisor (seed)? | Both, by role |
| P-ADMIN-17 | Should "Karan" show on Passes? It is from the reference, with a masked ID | Shown as drawn |
| P-ADMIN-18 | Does Announce ship (pack open item 4)? | Built, simulated |
| P-ADMIN-19 | What does "Copy last Thursday" read? No earlier week exists | Refills the seeded board and says Thu 8 Aug |
