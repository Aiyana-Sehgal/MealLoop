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

## Phases B and C: entry, accounts, roles and headcount (2026-11-06)

**Result: Debug, Review and Release build; all tests pass; all 11 roles land in their own area.** Same Xcode and simulator as Phase A. Tested at commit `b902b45`.

Test counts below come from the `.xcresult` bundles. Counting lines in the log is not reliable here: parallel test clones can lose a line of output.

| Check | Command | Result |
|---|---|---|
| Debug | `xcodebuild -project ios/MealLoop.xcodeproj -scheme MealLoop -destination 'platform=iOS Simulator,id=D763AB62-D9C2-4A8C-983C-902463604F57' CODE_SIGNING_ALLOWED=NO build test` | 85 passed, 0 failed, 0 skipped |
| Review | the same with `-scheme "MealLoop Review"` | 84 passed, 0 failed, 0 skipped |
| Release | the same with `-configuration Release` and `build` only | `** BUILD SUCCEEDED **` |
| Flags | `-showBuildSettings`, grep `ACTIVE_COMPILATION` | Debug `DEBUG DEMO_DATA`; Review `REVIEW_DATA REVIEW_CONFIGURATION`; Release empty |

Review has one test fewer because the role-password test is Debug only.

**Warnings:** only the two harmless `appintentsmetadataprocessor` lines from Phase A.

### What each build contains

Checked with `strings` and `nm` on the built app. Debug is the control that shows the check can find these items.

| Item | Debug | Review | Release |
|---|---|---|---|
| `DemoDataBadge` type | Present | Absent | Absent |
| "Simulated moment" text | Present | Absent | Absent |
| Moment titles such as "Before the meal" | Present | Absent | Absent |
| Role picker and role password code | Present | Absent | Absent |
| Seeded accounts and provider | Present | Present | Absent |

The empty `DemoControlling` protocol remains in all three. It has no UI and nothing conforms to it outside Debug.

### Simulator walk-through (Review)

Driven by the same temporary XCUITest approach as Phase A, from a clean install at `b902b45`. Every screen reached was also scanned for "demo", "simulated", "mock", "development launcher", "choose your role" and "docs/". None appeared.

Welcome, Staff sign in (disabled until filled, Forgot password message, wrong credentials message, show or hide password), Sign in with SRM, recent accounts, Continue as, Sign out and a relaunch with recent accounts kept were all reached.

| Role | Signed in with | Landing seen |
|---|---|---|
| Student | Sign in with SRM | Home, Meals, Community, You; placeholder |
| Super Admin | Staff sign in (prototype exception) | Home, Me; placeholder |
| Food Head / Admin | Staff sign in | Today, Students, Results, More; placeholder |
| Supervisor | Staff sign in | Home, Alerts, Me; placeholder Home |
| Kitchen Staff | Staff sign in | Home, Alerts, Me; **Kitchen Home** |
| Door Scanner | Staff sign in | Home, Alerts, Me; placeholder Home |
| Pass Desk | Staff sign in | Home, Alerts, Me; placeholder Home |
| Vendor | Staff sign in | Home, Me; placeholder |
| Guardian | Staff sign in | One page, no tabs; placeholder |
| Warden | Staff sign in | Queue, Out now, Escalated, History; placeholder |
| Gate Security | Staff sign in | Home, Me; placeholder |

Also run on the entry code before Phase C:

- **Debug:** the badge and moment menu still work after signing in.
- **Release:** Welcome shows, with no badge. Staff sign in shows `Not implemented: Remote · staff sign in.` Sign in with SRM shows `Not implemented: Remote · SRM sign in.` with Try again. Nobody can sign in, as intended.

Screenshots are in [`docs/verification/phase-b/`](verification/phase-b/).

The password field looks empty in `staff_sign_in_error.png`, but it is not: the test read back five secure characters, and showing the password displayed the typed value. Secure text is left out of the screenshot.

The Connecting and Getting your details screenshots were taken from a scratch copy with longer pauses, because the real steps pass too quickly to capture. The screens are otherwise the same.

### Against the references

| Screen | Reference | Result |
|---|---|---|
| Welcome | `redesign_2026-10/images/01_sign_in` | Layout matches. It adds Staff sign in and recent accounts, as the brief asks. Terms text is plain and inert, not underlined. Primary button is 56 pt where the reference measures about 80 pt |
| Getting your details | `redesign_2026-10/images/02_getting_details` | Layout matches. The title is bold where the reference is regular, the same token difference as "Lunch" in Phase A |
| Staff sign in | None exists | Follows the Orbit language and the brief. It cannot be called a match |
| Logo mark | `01_sign_in` | Redrawn as a ring with a lime dot, which closes difference 5 from Phase A on every staff Home |

**Known Debug-only overlap:** the Demo data badge sits over the two Welcome buttons. Both stay tappable. Review and Release do not have it.

### Phase C

`Headcount` now carries `liveForecast`, `cutoffForecast`, `approved`, `sentToVendor`, `actualEntries` and `finalEntries`, each with its own missing state, and an acknowledgment with actor and time. `VendorReply` is gone.

The status is derived: a published headcount without a record is pending, and a record with no publication shows as not published.

Seed notes:

- **Cutoff forecast:** seeded as not ready, because no document gives a value. It is not copied from the live forecast.
- **Approved and sent:** 860 and "Not acknowledged", from `admin_sample_data.md`.
- **Sent time:** 10:15 is borrowed from another row of the sample board, because no Main time is documented.
- **Actual entries:** available during service only, from the same source as the live count. After the meal closes, only final entries are available.

No test covers acknowledging an unpublished headcount through the provider, because the seed is always published. The model-level test covers the status.

### Manual checks for the owner

The automated walk-through covered the sign-in and landing path. Please confirm these by hand on the `MealLoop Review` scheme, using `docs/PRESENTER_ACCOUNTS.md`:

- [ ] Sign in as each of the 11 roles and confirm the landing matches the table above.
- [ ] Sign out from each role and confirm Welcome returns.
- [ ] Confirm the keyboard does not cover Sign in on the smallest supported iPhone.
- [ ] Try VoiceOver on Welcome and Staff sign in.
- [ ] Decide whether "Not implemented" is acceptable on any screen a reviewer will see.
- [ ] Watch for an iOS "save password" prompt after signing in on a physical device.

### API operations Phase C needs

`docs/backend/openapi.yaml` was not changed. It needs these before the backend can serve this model:

| Operation | Change |
|---|---|
| `getHeadcount` | Return the six named values and the acknowledgment. Replace `forecast` and `vendorReply` |
| Approve headcount | New. Food Head / Admin only, with the adjustment reason |
| Publish to vendor | New. Records the actor and time |
| Acknowledge headcount | New. Vendor account only, repeat-safe, and returns the first record on a repeat |
| Sign in with email and password | New, replacing `/staff/sessions` and the shared role password |
| SRM sign-in | New, once SRM SSO feasibility is confirmed |
| Resume a remembered account | New, or replaced by the session design |

### Stale documents left unchanged

`docs/adr/ADR-001-ios-architecture.md` item 5 still says `AppEnvironment` picks demo or api, with no mention of Review. ADRs were out of scope for this work.

## Entry fix: Welcome and tab bar (2026-11-06)

Owner review of the first entry build, on `fix/ios-entry-and-tabbar`. **This section replaces what Phases B and C say about recent accounts**, which were removed.

| Check | Result |
|---|---|
| Debug, `MealLoop` | 86 passed, 0 failed, 0 skipped (`.xcresult`) |
| Review, `MealLoop Review` | 85 passed, 0 failed, 0 skipped (`.xcresult`) |
| Release | `** BUILD SUCCEEDED **` |
| Binary scan | Review has no `DemoDataBadge` and no "Simulated moment". Release has neither, and no seed |

Xcode 27.2. Simulators: iPhone 18 Pro and iPhone 18 Pro Max on iOS 27.2 (440 x 956 pt), and a temporary iPhone SE (3rd generation) on iOS 27.2 (375 x 667 pt).

### What the references show

| Role | Reference | Pattern |
|---|---|---|
| Student | `03_home`, `05_meals_lunch`, `09_community_list`, `19_you`, `export_redesign/03_home@2x` | Glass pill: Home, Meals, Community, You. Separate 62 pt round Search, 8 pt gap |
| Food Head / Admin | `A01_today` | Same pattern: Today, Students, Results, More, plus Search |
| Mess staff | `D05`, `S02`, `K01` | One wide capsule: Home, Alerts, Me. No Search |
| Warden | `W01_warden_decide_approved` | One wide capsule of words, no icons: Queue, Out now, Escalated, History. No Search |
| Gate | `V5_gate_scan` | No tab bar on this screen |
| Guardian | Mobile web flow | No tab bar |
| Vendor, Super Admin | None | No design |

Sizes from `prototype_contract.md` (TabBar, TabSearchButton) and the export: 62 pt tall, 16 pt side margin, selected highlight 54 pt tall. A selected tab has a filled icon, a bold label and the highlight. Selected Search has the highlight and a heavier glyph.

The contract calls these Liquid Glass, but no document gives the recipe's numbers. The fill was sampled from the export (about `#FBFBFA` over the canvas).

### Checks

UI driven by the same temporary XCUITest approach, in scratch copies:

- **Regression:** on the small and large phones, all 11 roles signed in and out. Search exists only for Student and Admin. "Continue as" never appears, including after a relaunch.
- **Selection:** Search reports selected when chosen, and the previous tab stops being selected.
- **Over light and dark content:** a scratch-only black and white block was placed under the bar. Inactive labels measured 5.79:1 on native glass and at least 5.38:1 on the fallback, above the 4.5:1 needed for small text.
- **iOS 17 fallback:** no iOS 17 runtime is installed, so the fallback was forced on in a scratch copy and run on iOS 27.2. It has not run on a real iOS 17 system.
- **System Dark Mode:** the bar stays light with readable labels. The app's tokens are light only.
- **Largest text (Accessibility XXXL) on the small phone:** nothing clips. The wordmark shrinks to one line, the screen scrolls, and the footnote is fully visible after scrolling. Button labels do not grow, because `MLType` tokens are fixed sizes.
- **Debug badge:** now at the top centre, clear of Back, the avatar, buttons and the tab bar.

Screenshots are in [`docs/verification/entry-fix/`](verification/entry-fix/).

### Differences left

| Area | Reference | App |
|---|---|---|
| Welcome wordmark | Bold, about 36 pt in the export; regular in the pack sketch | Regular 48 pt, kept larger to fill space |
| Welcome buttons | 60 pt in the export | 56 pt |
| Tab icons | Drawn set | SF Symbols, a known stand-in. `fork.knife` has no filled form, so Meals relies on the bold label and highlight |
| Staff capsule | 66 pt tall in the export | 62 pt, shared with the other roles |
| Selected highlight | `tab-selected` token, value undocumented | Ink at 8% |
| Search screens | S1 to S5 and AD-8c show recent searches and results | Title, inactive field and "Search is not built yet." No repository provides the data |
| Student Search field text | No image exists | "Search" |
| Bottom edge | `ScrollEdgeFade` above the bar | Not built, so scrolled content meets the glass directly |

Simulators that ran the earlier build keep an unused `recentAccounts.v1` value holding seeded `.example` details. The app no longer reads it, and deleting the app clears it.

## Core-story contracts (2026-11-06)

On `feat/ios-core-story-contracts`. Xcode 27.2, iPhone 18 Pro simulator, iOS 27.2. Test counts are from `.xcresult`.

| Check | Result |
|---|---|
| Debug | 128 passed, 0 failed, 0 skipped |
| Review | 127 passed, 0 failed, 0 skipped |
| Release | `** BUILD SUCCEEDED **` |
| Review walk-through | Temporary XCUITest in a scratch copy, from a clean install: all 11 roles and every tab showed none of "not implemented", "demo", "simulated", "choose your role", "continue as" or "not built" |
| Binary scan | Review and Release have no "Not implemented", badge, moment titles or role picker. Release has no seed. An older build that contains the text was used to prove the scan can find it |

Reachable placeholders: 32 of 33 destinations. Only Kitchen Home is built. `PlaceholderMetricTests` prints the count per role.

`testTheWholeStoryRunsInOrderOnOneDataSource` runs every story step in order through the repositories, not through screens, because the screens are later parts.

Not run: a physical device and an iOS 17 runtime.

## Waste role guard (2026-11-06)

`save` and `saveDraft` now take a role and accept Kitchen Staff only. Debug 131 passed, Review 130 passed, 0 failed, 0 skipped (`.xcresult`); Release builds. Every other role is refused, nothing is stored, and Supervisor and Admin can still read the report.

