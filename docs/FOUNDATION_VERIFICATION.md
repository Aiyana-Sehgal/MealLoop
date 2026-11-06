# Foundation verification

Real results from building and running `ios/` on a Mac. Anything not listed here as run has not been verified.

## Phase A: baseline (2026-11-06)

**Result: the foundation builds, all 40 unit tests pass, and no code change was needed.**

### Environment

| Item | Value |
|---|---|
| Commit tested | `40b8e4d` (tip of `origin/feature/swiftui-foundation`) |
| Xcode | 27.2, build 27B52 |
| Simulator | iPhone 18 Pro, iOS 27.2, `D763AB62-D9C2-4A8C-983C-902463604F57` |
| Language mode and target | Swift 5, iOS 17.0 (from `-showBuildSettings`) |

### Commands and results

| Check | Command | Result |
|---|---|---|
| Debug build and tests | `xcodebuild -project ios/MealLoop.xcodeproj -scheme MealLoop -destination 'platform=iOS Simulator,id=D763AB62-D9C2-4A8C-983C-902463604F57' CODE_SIGNING_ALLOWED=NO build test` | `** BUILD SUCCEEDED **`, `** TEST SUCCEEDED **` |
| Tests executed | counted from the log | 40 passed, 0 failed |
| Release build | the same command with `-configuration Release` and `build` only | `** BUILD SUCCEEDED **` |
| Debug flags | `-showBuildSettings`, grep `ACTIVE_COMPILATION` | `SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG DEMO_DATA` |
| Release flags | the same with `-configuration Release` | the setting is empty, so `DEMO_DATA` is not compiled in |

Tests per class: `MeasurementTests` 10, `DemoEntryRepositoryTests` 9, `DomainRulesTests` 9, `KitchenHomeViewModelTests` 7, `AppEnvironmentTests` 5.

`-derivedDataPath` was added to these commands so the built app could be found. It does not affect the result.

**Warnings:** the only ones in either log are two `appintentsmetadataprocessor` lines ("Metadata extraction skipped, no AppIntents.framework dependency found"). They are harmless because the app does not use App Intents.

**Fixes:** none. The hand-written project opened and built as committed.

### Simulator walk-through

`Simulator.app` is not installed on this machine and `simctl` cannot tap, so the UI was driven by a temporary XCUITest target added to a scratch copy of the project. That target is **not** in this repository. Screenshots were read and compared by eye.

**Debug, all reached:** Development launcher, Mess staff, Choose your role, Kitchen Staff, What you do sheet, Continue, password page, wrong password ("Wrong password. 2 tries left."), correct password, Kitchen Home, all seven moments, Me, Sign out.

| Moment | What the screen showed |
|---|---|
| Before the meal (K01) | FORECASTED ATTENDANCE, 860, expected diners; Menu for Lunch; Past meals |
| During the meal (K02) | Meal in progress · 1 h 40 min; LIVE · 1:40 PM; 714 students entered |
| Shortage reported (K03) | As K02, plus Steamed Rice, almost out, Sent 1:30 PM |
| Entries stale (K02b) | Updated 1:12 PM · reconnecting; LIVE · 1:12 PM |
| After the meal (K05) | MEAL CLOSED; Lunch has ended; Final entries 774; Waste report, Not started |
| Waste recorded (K15) | Recorded · 2:40 PM; You can edit until 8:40 PM. |
| Offline (K02c) | Offline · saved 1:38 PM over the last content shown |

**Release (what a reviewer sees today):** the same "Development launcher" with six rows and no Demo data badge. Choosing Mess staff, Kitchen Staff and entering a password shows `Not implemented: Remote · role password.` Nobody can sign in. Phase B addresses this.

Screenshots are in [`docs/verification/phase-a/`](verification/phase-a/).

### Kitchen Home against `design/reference/kitchen_2026-10/images`

Content, order and states match K01, K02, K03 and K05. **The visual match is partial.** Differences found:

| # | Area | Reference | Running app |
|---|---|---|---|
| 1 | Hero number | Very large, regular weight (about 60% of the card width) | Much smaller and bold. This is the most visible difference |
| 2 | Hero card | Taller, because of the number | Shorter |
| 3 | Mono digits | Dotted zero, lighter | Slashed zero, heavier (SF Mono) |
| 4 | Screen title "Lunch" | Regular weight | Bold |
| 5 | Logo mark | Ring with a lime dot | Black capsule with a lime dot, which looks like a toggle (`OrbitMarkView`, a known approximation) |
| 6 | Tab bar icons | Thin outline; inactive tabs grey | Filled and heavier; inactive tabs black |
| 7 | Cards and tab bar | Warm off-white in the pack images | Pure white (`#FFFFFF`, the documented token). The pack images and the token disagree; not changed |
| 8 | Shortage row icon | Pot | `frying.pan`, a known stand-in |
| 9 | Shortage row time | Regular text | Monospaced |
| 10 | Elapsed time | K02 and K03 pack images say "55 min" | "1 h 40 min", as `FOUNDATION_REPORT.md` describes. The sources disagree; not changed |
| 11 | K04 Report shortage sheet | Designed | Not built; the button opens "Not implemented" |

Debug also shows the intentional Demo data badge.

**Demo-only oddity:** choosing Offline after an after-meal moment shows "Offline · saved 1:38 PM" above "ended 2:00 PM". `KitchenHomeViewModel.load()` keeps the last content on purpose and 1:38 PM is a fixed seed value, so this comes from the order the moments were chosen. No false success is shown. Not changed.

### Read-only analysis: facts checked

All of these held: 51 Swift files and 3,855 lines; two targets; shared scheme; iOS 17; Swift 5; no packages; 40 tests; the entry and root switching; `AppSurface` 6 cases; `Role` 9 cases; the staff entry path; demo password in `DemoSeed.simulatedRolePassword`; Debug and Release flags; the `#error` guard; `RemoteAPI(baseURL: nil)`; only Kitchen Home built, with 7 moments; 9 repositories plus 4 empty stubs; `Headcount` fields; the stale vendor comment; `DemoDataProvider` is a 426-line actor.

Differences:

- **`OrbitMarkView` is not unused.** `StaffHeader` uses it, so it is on every staff Home.
- **There is a fifth empty protocol:** `IntelligenceService`, separate from the four stubs.

### Pending

- A person should try VoiceOver, Dynamic Type and a physical device. None of these were checked.
- Differences 1 to 9 above are not fixed. They are outside Phase A.
