# Pass Desk: verification

Base `feature/swiftui-foundation` (2b2abee), which contains the tips of `feat/ios-core-story-contracts`, `fix/ios-waste-role-guard`, `feat/ios-shared-components` and `feat/ios-supervisor`. Xcode 27.2.

## Results

Clean builds on the final code, iPhone 18 Pro Max, iOS 27.2, run once at the end.

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug | 0 | 302 | 298 | 0 | 4 |
| Review | 0 | 301 | 297 | 0 | 4 |
| Release build | 0 | n/a | n/a | n/a | n/a |

The 4 skipped are the existing `SupervisorScreenshotTests`, which need an environment variable. This part adds 48 tests: 15 in `SpecialPassOperationTests.swift` and 33 in `PassDeskViewModelTests.swift`. No compiler warning names a Pass Desk file.

**Simulator walk:** every walk passed on iPhone SE (3rd generation) (`small/`) and iPhone 18 Pro Max (`large/`), 46 screenshots each, on two simulators created for this and deleted afterwards. They were driven by a temporary UI test target in a scratch copy, which is not in this repository. That copy also started Review at a chosen moment, so most screenshots have no Debug badge, and removed the system Save Password prompt. `P03_home_offline` and `PD_cant_check_right_now` come from Debug and show the badge.

`story_home_0_of_214` and `story_home_1_of_214` are the real story with nothing seeded: the Supervisor starts the meal, the desk records one pass.

**Scratch-seeded screenshots** (names end `_scratch`) show layout, not a reachable state: code expired (a refresh forced to fail), meal ended while checking (forced), SOS (a seeded case; the raise operation exists but nothing here opens one), Alerts with a seen shortage and Alerts empty. `P04_check_this_pass_code_changed` held "Just changed" longer in the scratch copy so the slow UI query could catch it; the app keeps it for 2 ticks.

`large/P12_food_short_sent_toast.png` caught the page mid-transition, so the toast is not in frame. The walk confirmed the toast text.

**Timing of the screenshots:** `small/` is from the final code. `large/` was taken before the last change, the keypad height below 700 pt, which does not apply on that phone, and was not repeated. The test counts above are from the final code. The SE was captured more than once, and the scratch walks ran in Review while iterating, because the walk found bugs; the repository's Review tests and Release build ran once, at the end.

**Checked by eye only:** the comparison with the references. **Not run:** a physical device, an iOS 17 runtime, VoiceOver by hand, largest Dynamic Type, Reduce Motion.

## Reference table

Exports are in `design/audit/export_pass_desk/`. Tabs confirmed from P03 and P14: Home, Alerts, Me. "Data-driven: yes" means through a view model and a repository.

| Reference | State | Inventory row | Tab | Components | Data-driven |
|---|---|---|---|---|---|
| P01 | What you do sheet | `P01_what_you_do_sheet` | none | none | Not built: the role flow is retired (P-ENTRY-4), as with S00 |
| P02 | Before the meal | `P02_home_before_meal` | Home | `IconCardRow` | Yes |
| P03 | During, keypad on Home | `P03_home_during_meal`, `_typing_1` to `_3`, `_during_42_of_214` | Home | `KeyPad`, `DigitBoxes`, `MealProgressChip`, `QuietRow` | Yes |
| P03 export | Student not found | `P03_home_student_not_found` | Home | `HeroCard` | Yes |
| P03 export | Offline | `P03_home_offline` | Home | `AsyncContentView` | Yes |
| P13 | After the meal | `P13_home_meal_ended` | Home | `HeroCard`, `QuietRow` | Yes |
| P13 export | Meal ended while checking | `P13_meal_ended_while_checking` | result | `OutcomeScreen` | Yes |
| P04 | Fresh, changed, expired | `P04_check_this_pass_sheet`, `_code_changed`, `_code_expired` | Home sheet | `mlSheet`, local code card | Yes |
| P05 | Pass verified | `P05_pass_verified` | result | `LimeResultScreen` | Yes |
| P06 | No pass, wrong meal | `P06_no_special_pass`, `P06_wrong_meal` | result | `OutcomeScreen` | Yes |
| P07 | Already recorded | `P07_already_recorded` | result | `OutcomeScreen` | Yes |
| P08 | Doesn't match | `P08_doesnt_match` | result | `OutcomeScreen` | Yes |
| export | Can't check right now | `PD_cant_check_right_now` | result | `OutcomeScreen` | Yes |
| P17 | Look up: entry, valid, used, no pass, wrong meal | `P17_look_up_student`, `_valid`, `_used`, `_no_pass`, `_wrong_meal` | Home push | `DigitBoxes`, `KeyPad`, `FactCard`, `StatusText` | Yes. `_used` is covered by a test, not a screenshot |
| P09 | Request, sent | `P09_request_new_pass`, `_sent_toast` | Home push | `ChoiceChip`, `mlToast` | Yes |
| P10 | Statuses | `P10_new_pass_requests` | Home push | `StatusText` | Yes, seeded row by row from P10 |
| P11 | Report, sent | `P11_report_a_problem`, `_sent_toast` | Home push | `IconCardRow` | Local log, as the Door Scanner |
| P12 | Food short, sent | `P12_food_short_sheet`, `_sent_toast` | Home sheet | `mlSheet`, `ChoiceChip` | Yes: menu and `reportShortage` |
| export | Open problems | `PD_open_problems_after_report`, `_food_short`, `_none` | Home push | `StatusText`, `StateBlock` | Local log |
| P14 | Alerts and SOS variants, empty | `P14_alerts`, `_sos_active`, `_sos_claimed`, `_sos_checked`, `_empty` | Alerts | `AlertRow`, `SOSCard`, `StateBlock` | Yes |
| P15 | SOS tab, claimed, marked | `P15_home_with_sos_tab`, `_sos_claimed`, `_marked_as_checked` | Home | `SOSEdgeTab` | Yes |
| P16 | Panel, claimed | `P16_sos_panel`, `_claimed` | Home sheet | `SOSPanel` | Yes |
| export | Me | `PD_me` | Me | `QuietRow`, `MealProgressChip` | Yes |

## Backend additions

One commit, `feat(backend): add the special-meal pass operations and seed`, with 15 tests. No existing operation changed behaviour or signature.

- New file `Domain/SpecialPassCheck.swift`.
- `SpecialPassRepository` was an empty stub; it now has `lookUpPass`, `refreshPassCode`, `recordPassEntry`, `specialMealCount`, `specialMealEntries`, `reissueRequests` and `requestReissue`.
- `Repositories.specialPasses` is a defaulted `var`, so every existing `Repositories(...)` call compiles unchanged. `UnavailableSpecialPasses` is the default, so `RemoteAPI` says not implemented and fakes nothing.
- `DemoDataProvider`: new state fields, and an extension implementing the protocol.
- `DemoSeed`, each value citing its source: 214, 41 and 196 (`pass_desk_spec.md`); codes 218 Lime (P04), K2M9 Blue (export), 7A3F Lime (`design_intent.md`); the 10 s window (export); who holds a pass; the four P10 rows.

## Differences left

- **Status is a dot and text,** not the drawn chips on P10, P17 and open problems, per the brief.
- **No "since 11:40 AM"** on the On shift chip: nothing holds a shift start.
- **Switch role is left out of Me,** because the role comes from the account (P-ENTRY-4). Door Scanner keeps the row as Coming soon. Language and Help are Coming soon.
- **"New pass approved" reads "can get the pass",** not P14's "her pass": no record gives a pronoun.
- **The food-short chips are the seeded menu,** not the drawn biryani dishes. The spec says the dishes come from the day's menu.
- **The request form uses a keypad** while digits are entered, because P09 draws none and the digits need a way in. "Look up another" under the found student is added wording, for changing the student.
- **Icons are SF Symbols** (T7), including the crossed ticket on P06, which is a plain ticket here.
- **Blue** is `#2F61E6`, measured from the export and local to the colour pill, because the tokens have no blue.
- **Tab bar:** hidden on pushed pages, as P09 to P11. The open problems export draws it.
- **iPhone SE:** keys are 46 pt, not 56, so the whole keypad clears the tab bar. "Request a new pass" and "Report a problem" need a scroll. With the offline banner up, the bottom key row also needs a scroll.
- **Seeded times in the story:** P10's times (12:20 PM and so on) are fixed, so at 7:00 AM they read as the future.

## Found and fixed by the walk

- **Food-short sheet showed no dishes.** State read only inside a sheet's closure is not a dependency of the parent, so the sheet opened with the stale empty list. The unit test passed because it called the log directly. The sheet is now its own view that loads its own dishes. Other parts using `mlSheet` should watch for the same trap.
- **Bottom keypad row hidden on iPhone SE,** which holds the 0. See above.

## Gaps

- **Report a problem is local,** as the brief says. Three kinds stay on this phone: the Supervisor sees nothing, a problem stays Waiting, and "Sent to Ravi" is a prototype claim. Food running short is real: it goes through `reportShortage`, so Kitchen and Supervisor read it.
- **No operation moves a reissue on.** Only the seed has Approved and Done, and nothing here fakes an approval.
- **Nothing marks a shortage seen,** so "Food shortage seen" appears only with scratch data.
- **No screen in another role reads `specialMealEntries` yet.** The read takes no role, and a test proves the entry is there.
- **The pass service is simulated:** sample codes take turns. The code changes on a timer in the sheet, because the story clock does not tick.
- **SOS reuses `DoorSOSViewModel` and `DoorSOSStage`,** because the spec says "Same as the Door Scanner". Moving them somewhere shared is the owner's call.

## Open questions (proposed IDs)

| ID | Question | What the prototype does now |
|---|---|---|
| P-PASS-1 | Does a special-meal entry also count toward Actual entries? | No. It has its own count, and the door count does not move |
| P-PASS-2 | What level does a desk food-short report carry? P12 asks only which food | `gettingLow`, the mildest |
| P-PASS-3 | How long is a code's window? | 10 s, from one export. P04 shows 7 s; no document gives a value |
| P-PASS-4 | Should Review's special count start at 0 like live entries (P-STORY-5)? | Yes in the story, 41 in Debug's sample moments |
| P-PASS-5 | Who holds a pass in the seed? | Sample: Aarav lunch, Kiran dinner, Meera and Dev none. Only Aarav's comes from the spec |
| P-PASS-6 | Should a second Waiting request for one student be refused? | Allowed: no document says otherwise |
| P-PASS-7 | Who sees the special-meal entry list (spec open item 5)? | The read is open to any role; no screen uses it |
| P-PASS-8 | Should Language, Help and Switch role be the same across staff roles? | Door keeps all three as Coming soon; here Switch role is out |
