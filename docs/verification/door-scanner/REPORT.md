# Door Scanner verification

Branch `feat/ios-door-scanner`, with `feature/swiftui-foundation` merged in up to `e92f205`. Code checked at `0d3f3e5` on 2026-11-06.

## Results

Xcode 27.2, iPhone 17e simulator, iOS 27.0, clean build. Counts come from each `.xcresult`.

| Run | Exit | Executed | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug tests | 0 | 247 | 243 | 0 | 4 |
| Review tests | 0 | 246 | 242 | 0 | 4 |
| Release build | 0 | n/a | n/a | n/a | n/a |

The 30 Door tests are in `DoorScannerTests.swift` and all pass. The 4 skipped tests are the opt-in `SupervisorScreenshotTests`, which run only with `TEST_RUNNER_SUPERVISOR_SHOTS` set. The Door code has no compiler warnings.

**Scope:** the diff lists only `Features/DoorScanner/`, `DoorScannerTests.swift` and this folder. No shared file changed.

**Hardcoded data:** a search of the feature folder finds no sample names, seeded numbers, times or `DemoSeed` in any view, and no wording outside `DoorScannerCopy` and `DoorProblemKind`.

## SOS on the real backend

The merge brought in `SOSRepository.raise`, so `FakeSOS` now has it and SOS has run against the prototype backend, not only a stand-in. Here "real" means `DemoDataProvider`. `RemoteAPI.raise` is still not implemented.

- **Test:** `testARaisedCaseRunsThroughTheDoorOnTheRealBackend` raises a case, then loads, claims and marks it checked. The case stays open until the Supervisor closes it, and then the tab goes.
- **Screens:** `SOS_real_1` to `SOS_real_5` in `small/` and `large/` show the real `DoorScannerRootView` on the real repository: no case, tab after the raise, panel, claimed, checked. A scratch copy made the raise and the taps, because no screen in the app calls `raise` yet. They were taken at `f622909`; the later merge changed only Admin files.

**A raised case does not appear by itself.** The Door reloads on `dataRevision`, on pull to refresh and when the root opens. Whatever raises the case in the Student SOS part must call `environment.dataDidChange()`, and a real backend will need a push or a poll. The scratch run made that call itself.

## How it was checked

- **Screenshots:** 41 states on the iPhone 17e (390 pt, iOS 27.0) and iPhone 17 Pro Max (440 pt, iOS 26.5), in `small/` and `large/`. `compare/` has 21 side-by-side sheets with the reference on the left.
- **Method:** the role has no way to reach most states by hand in one run, so a scratch copy added a launch hook that opens each state. The hook is not in the repository. The D13 and D14 states used a stand-in repository, taken before `raise` reached this branch. The `SOS_real_*` states use the real one.
- **Walk-through on the real root (scratch test, driven through the accessibility tree):** before the meal shows the time and no Type ID; Home follows the Supervisor; Type ID opens the sheet; digits find a match; the lookup records nothing; Record entry shows the lime screen; it returns to Home by itself with the count at 1; a repeat shows Already scanned and the count stays; a no-response student is listed; the sheet reopens empty; no match; Home follows the meal closing.
- **In the running app:** Report opens, Back returns Home, and sending lands on Open problems (the `walk_` screenshots).
- **Kitchen sees each entry:** `testKitchenSeesEachRecordedEntry` reads the count through Kitchen's own view model.

## Defects found by running it, now fixed

- Every sheet opened empty, because the entry flow was read only inside the sheet's closure. Tests could not see this.
- Any error while recording showed "meal ended", and any lookup error showed "no such student". Unverified failures now show as not recorded.
- After a match the keypad was disabled, so a wrong digit could not be corrected.
- The Open problems row had no count after the meal.

## Reference table

| Reference | State | Inventory row | Component | Data |
|---|---|---|---|---|
| D04 | Home before | `D04_home_before_meal` | `IconCardRow` | `meal.startsAt` |
| D05 | Home during | `D05_home_during_meal` | `MealProgressChip`, `IconCardRow` | Count from `liveCount`; camera line is copy |
| D05 | SOS tab | `D05_home_during_meal_sos`, `D14_home_sos_claimed` | `SOSEdgeTab` | `activeCases` |
| D05 | Offline | `D05_home_offline` | `OfflineBanner` | `RepositoryError.offline` |
| D05 | Camera denied, low light | `D05_home_camera_denied`, `D05_home_low_light` | none | Not built (owner ruling) |
| D06 | Typing, one match, no match, offline | `D06_type_last4_*` | `mlSheet`, `DigitBoxes`, `KeyPad` | `resolveEntry` |
| D06 | Several matches | `D06_type_last4_several_matches` | none | Cannot occur (owner ruling) |
| D07 | Entry recorded | `D07_entry_recorded` | `LimeResultScreen` | `recordEntry` |
| D07 | No response | `D07_entry_recorded_no_response` | `LimeResultScreen` | `hadMealResponse` |
| D08 | Already scanned | `D08_already_scanned` | `OutcomeScreen` | `.alreadyRecorded` |
| D09 | Not recognised | `D09_qr_not_recognised` | `OutcomeScreen` | `.notRecognised`, QR path only |
| D09 | Wrong meal | `D09_wrong_meal` | `OutcomeScreen` | `.wrongMeal(servingNow:)` |
| D10 | Can't check | `D10_cant_verify_offline` | `OutcomeScreen` | `RepositoryError.offline` |
| D11 | Report, toast | `D11_report_a_problem*` | `IconCardRow`, `mlToast` | Local log |
| D12 | Home after | `D12_home_meal_ended` | `HeroCard`, `QuietRow` | `finalCount`, `enteredWithoutVoting` |
| D12 | Ended during a scan | `D12_meal_ended_during_scan` | `OutcomeScreen` | `notAllowed`, `finalCount` |
| D13, D14 | SOS panel | `D13_*`, `D14_sos_panel_claimed`, `D14_home_marked_as_checked` | `SOSPanel`, `mlSheet` | `claim`, `markChecked` |
| D15 | Entered without voting | `D15_entered_without_voting*` | `StateBlock` | `enteredWithoutVoting` |
| D16 | Open problems | `D16_open_problems*` | `StatusText`, `StateBlock` | Local log |
| D17 | Alerts | `D17_alerts*` | `SOSCard`, `AlertRow`, `SectionHeader`, `StateBlock` | `activeCases`, meal state |
| D18 | Me | `D18_me` | `MealProgressChip` | Meal state, local log |
| D02, D03 | What you do, password | `D02_what_you_do_sheet`, shared entry rows | Existing | Retired by email sign-in; outside this root |

## Owner rulings

| Finding | Ruling |
|---|---|
| Camera | Skipped for the review. D05 layout, an honest line, no torch; typed last-four is the working path. The permission key is a later stretch goal |
| SOS raise | Added by the Supervisor session, not here |
| Several matches | Fine: seeded codes are unique, so it cannot occur |
| Wrong meal, student name | Accepted; the name is batched for Monday |
| Problem reports | Static, as briefed |

## Camera status

**Not built and not verified on a device.** The project has no camera permission key, so opening the camera would crash the app. `DoorEntryFlow.scan(payload:)` handles a QR payload and is tested, but nothing in the app calls it, so QR not recognised can only be reached in tests. The card says "Camera is off. Use Type ID." instead of "Point at the student's QR".

## Differences left

| Area | Reference | App |
|---|---|---|
| Scanner card | "Point at the student's QR", torch | "Camera is off. Use Type ID.", no torch |
| Student name | "Aarav ••0238" | "••0238" (`StudentRef` has no name) |
| Wrong meal | "This QR is for Dinner." | "This code isn't for the meal being served." with Scanning now |
| QR not recognised | Bulleted causes in a card | One grey line (`OutcomeScreen` has no bullet slot) |
| Lime screen caption | "Back to the camera in 1 s" | "Back to Home in 1 s" |
| No-response screen | "See the list · 3 so far" link | No link (`LimeResultScreen` has no link slot), so D15 opens only from Home after the meal |
| Offline banner | Black, "No connection. Entries are not being recorded." | Shared `OfflineBanner`; the card carries the wording |
| Open problems status | Waiting, Seen, Fixed as pills | Dot plus text as the rules ask; only Waiting exists |
| Alerts | Three rows including Problem seen, Meal ends soon | Only Meal started and Lunch closed, from the meal state |
| "I can't go after all" | On the claimed panel | Left out: no operation releases a claim |
| Me chip | "On shift · since 11:40 AM" | "On shift": no shift time exists |
| Me Language row | "English" | No value, because `QuietRow` shows values in mono |
| Switch role, Language, Help | Working rows | "Coming soon" pages |
| Sheets | Edge to edge, ink at 40% | System style, floats, lighter scrim (as Part 2b) |
| Icons | Drawn set | SF Symbols, decision T7 |

## Honesty notes for the presenter

- **"Sent to Ravi" is not delivered.** The toast follows the spec, but nothing leaves the phone and the Supervisor sees nothing. A report survives only until sign-out.
- **Debug moments:** with the seeded after-meal moment, Entered without voting shows 0 beside 774 entries, because the seed has no list. In the Review story both come from real entries.
- **The role check is on the phone only.** `recordEntry` takes no role, so the backend would accept an entry from any role.

## Not run

A real device, a real camera, VoiceOver by hand, largest Dynamic Type, Reduce Motion, an iOS 17 system. The SOS raise from a real screen, because none exists yet. Parallel sessions shared the machine, so several screenshots needed a retry.

## Shared changes needed, not made

| File | Change |
|---|---|
| `PlaceholderMetricTests.swift` | Add `.doorScanner: ["Home", "Alerts", "Me"]` to `built`, or the metric undercounts |
| `Domain/Entry.swift` | `StudentRef.firstName: String?`, the Monday batch |
| `Domain/Entry.swift` | `.wrongMeal(servingNow:, codeMeal: MealSlot?)`, for "This QR is for Dinner." |
| `Data/Repositories/Repositories.swift` | `ProblemRepository`: `report(_:)`, `problems(for:)`, `markSeen`, `markFixed` |
| `Data/Repositories/Repositories.swift` | `SOSRepository.release(_ sos: SOSCaseID, by role: Role)` |
| `Domain/Entry.swift` | A role on `EntryRequest`, so the backend can refuse other roles |
| `Domain/StaffSession.swift` | `shiftStartedAt: Date?` |
| `LimeResultScreen.swift` | An optional link slot, for "See the list" |
| `OutcomeScreen.swift` | An optional bullet list |
| `ios/MealLoop.xcodeproj` | `INFOPLIST_KEY_NSCameraUsageDescription`, if the camera goes ahead |

## Open questions (proposed IDs, for the owner to merge into `OPEN_DECISIONS.md`)

| ID | Question |
|---|---|
| P-DOOR-1 | Should the "Sent to Ravi" toast stay in the review, given that nothing is delivered? |
| P-DOOR-2 | Which screen should open Entered without voting during the meal? |
| P-DOOR-3 | What should Switch role do now that role selection is retired? |
| P-DOOR-4 | Should a second person be able to claim a case someone else has claimed? The backend allows it and replaces the claim |
