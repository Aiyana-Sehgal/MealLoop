# Door Scanner, Supervisor and Pass Desk against the Figma frames

Design source: Figma file `nzzTAm9YnJRSdKEeYUWUEb`, page 09 Mess Staff, read through the connector with `get_screenshot` on each node id. Nothing in the file was edited. Base: `feature/swiftui-foundation` at `91b1ce9`.

## 1. Audit before any code change

Compared on iPhone 16 (393 x 852, the frame size). Earlier screenshots came from a 440 pt phone, which made the type look small; at 393 pt the type sizes match. The gaps are layout, fill and drawn pieces.

### Across the roles
- Result screens: frames pin the actions to the bottom, outline above ink. Build flows them under the content. `OutcomeScreen` is shared, so this needs a local view.
- Pushed pages sit 10 to 17 pt low: Back and title are too far apart.
- Status on light surfaces: frames draw pills (Waiting dashed, Seen and Approved outlined, Done and Valid lime, Fixed quiet). Build draws dot plus text.
- Report rows: frames draw a 64 pt icon, a 20 pt title and 20 pt padding. Build uses the 44 pt shared row.
- Me: frames draw a 28 pt name, 110 pt tiles, "· since 11:40 AM" and "English". Build has a 22 pt name, 87 pt tiles and neither detail.
- Hero eyebrow on Door and Pass Desk after the meal: frames draw "Meal ended" in sentence case. Shared `HeroEyebrow` uppercases.
- Shared, not changeable here: tab bar (filled icons, shadow), MealLoop mark, Back fill, offline banner, SOS tab icon.

### Door Scanner
- Waiting card 396 pt, frame 438. Scan card 232 pt, frame 300. QR glyph smaller than drawn. Home content 7 pt high.
- Offline: frame draws a black "No connection" pill above the chip; build shows the shared banner.
- Sheet: no "Matches show here as you type." card and no disabled Record entry while typing. Match card has no initials or name. "Several matches" not built.
- Results: no student name ("Aarav ••0238"). "QR not recognised" has no "It may be" card. Wrong meal has no "This QR is for" row.
- Open problems: row has no pill; Report a problem not pinned; no closing line.
- Without voting: no names; no "Just added" chip.
- Alerts: "Alerts from Ravi" where the frame says "your supervisor"; empty state too high. No Problem seen, Breakfast closed, See all or All alerts: there is no alerts feed.
- Me: still has Switch role (owner ruling: remove, overriding the frame).
- Torch, Camera denied and Low light: no camera in this build.
- SOS panel claimed: no "I can't go after all": no release operation.

### Pass Desk (Home during the meal and its typing states left alone, owner ruling)
- Before: hero 143 pt, frame 257; line is 17 pt, frame 22. Look up detail wraps to two lines.
- After: title 22 pt on one line, frame 28 on two; spacing tight.
- Check sheet: Just changed is a dot; frame draws an outlined chip inside an ink-outlined card.
- Look up: boxes quiet, frame outlined white. Keys 56 pt, frame 80. Status under the holder, frame draws a pill on the right with facts in the same card. Look up another not pinned.
- Request: boxes quiet; chips in a grid, frame wraps them by width; Send request not pinned; "Look up another" link not in the frame.
- New pass requests: no pills; request reason missing from the row; note shorter than the frame.
- Report: Food running short has no lime icon.
- Open problems: no pill; button not pinned; empty state not centred.

### Supervisor (closest of the three)
- Header content 6 pt low on Home; pushed pages 10 to 17 pt low; Alerts title 10 pt high.
- Meal history: chevrons the frame does not draw force details to wrap. Loading shows a spinner; frame draws skeleton rows and "Loading meal history…".
- Wed 14 Breakfast shows Unavailable; frame shows 402. To be traced.
- Alerts all caught up: frame draws a larger block lower on the page.
- Offline: frame draws a small "Offline" next to the avatar; build shows the shared banner.
- SOS panel claimed: frame draws an outlined "You're checking this"; build draws lime, from the shared status.
- Me: frame draws a 92 pt avatar row with more space; Meal history is semibold.

## 2. Result on the final build

Every frame below was compared with its build shot at 393 x 852. Files share a name: `figma/<node>.png` and `build/<node>.png`.

| Role | In scope | Matches | Differs | Not built | Left alone |
|---|---|---|---|---|---|
| Door Scanner | 38 | 5 | 28 | 5 | 0 |
| Pass Desk | 46 | 13 | 22 | 1 | 10 |
| Supervisor | 45 | 21 | 23 | 1 | 0 |
| **Total** | **129** | **39** | **73** | **7** | **10** |

**What "matches" means here.** Layout, wording, drawn pieces and values agree, apart from five things on nearly every frame, which sit in shared components or the platform and which this brief does not allow changing:

1. Tab bar: selected icons are filled and the bar has a shadow; the frames draw outline icons.
2. The MealLoop mark is the drawn-from-reference ring, not the frame's mark.
3. Back has a material fill; the frames draw solid white.
4. Type is SF Pro and SF Mono; the frames use Inter and JetBrains Mono as stand-ins (design/README.md), so widths differ by a few points and some lines break elsewhere.
5. Icons are SF Symbols, close but not identical (QR, ticket, pan, wifi, person with a tick). The frames' status bars are not drawn in the captures.

Times in a frame are samples. Where only the story clock differs, the line says so or the frame still counts as a match.

### Door Scanner
| Node | Frame | Result |
|---|---|---|
| `2471:2234` | DS-1 Home before | matches |
| `2471:2437` | DS-1 Home during | no torch; line says "Camera is off. Use Type ID." (no camera in this build) |
| `2471:2581` | DS-1 Home during, SOS active | no torch; camera line as above |
| `2471:2732` | DS-1 Home after | counts are real (0 and 0), frame samples 6 and 1 |
| `2471:3146` | DS-1 Home offline | rows sit about 8 pt lower; offline line wraps at a different word |
| `2471:3284` | DS-3 Meal ended during a scan | matches |
| `2472:2645` | DS-2 Typing | sheet sized to its content (shared mlSheet), frame runs near full height |
| `2472:2910` | DS-2 One match | sheet height, as above |
| `2472:3317` | DS-2 No match | sheet height, as above |
| `2482:186231` | DS-2 Offline | sheet height; capture shows the shared offline strip behind the sheet because it loads fresh |
| `2472:172058` | DS-3 Entry recorded | says "Back to Home", frame "Back to the camera" (no camera) |
| `2472:172162` | DS-3 Recorded, no meal response | no-response line sits above the count, frame below; no "See the list" link (shared LimeResultScreen) |
| `2472:172269` | DS-3 Already scanned | matches |
| `2472:172371` | DS-3 QR not recognised | bullet says "another meal", frame names Dinner: the backend does not say which meal a code is for |
| `2472:172486` | DS-3 Wrong meal | no "This QR is for" row and no meal hours in the fact: same backend gap |
| `2472:172595` | DS-3 Can't check right now | title fits one line, so the page sits higher |
| `2474:3212` | DS-5 Report a problem | wording: "Pick what went wrong", "saved" (no delivery claims, brief rule) |
| `2474:3359` | DS-5 Report saved toast | wording: "Report saved", frame "Sent to Ravi" (brief rule) |
| `2474:3490` | DS-6 Open problems | "Saved" line, frame "Sent to Ravi" (brief rule); closing line reworded |
| `2474:3613` | DS-6 After your report | both rows Waiting: Seen and Fixed have no source, so no pill claims them |
| `2474:3748` | DS-6 Entered without voting | lists real entries (1), frame samples 6 |
| `2474:3886` | DS-6 Without voting, during | no "Just added" chip; subtitle says "1 student", frame "3 so far"; shorter closing line |
| `2476:3498` | DS-7 SOS not claimed | matches |
| `2476:3747` | DS-7 SOS claimed by you | no "I can't go after all": no release operation |
| `2476:3925` | DS-7 Home, claimed by you | no torch; camera line |
| `2476:4075` | DS-7 Marked as checked | SOS tab drawn as claimed (lime), frame black; no torch; camera line |
| `2512:3778` | DS-8 Alerts SOS active | no Problem seen or Breakfast closed rows: no alerts feed |
| `2512:172793` | DS-8 Alerts claimed | same rows missing; Open the SOS is lime (shared SOSCard), frame outlined |
| `2512:172948` | DS-8 Alerts checked | same rows missing |
| `2512:173100` | DS-8 Alerts during | same rows missing |
| `2512:173241` | DS-8 Alerts after | no Meal ends soon, Problem seen or See all: no alerts feed |
| `2512:173545` | DS-8 Alerts empty | matches |
| `2512:173663` | DS-8 Me | no Switch role (owner ruling); problems count is real (0) |

### Pass Desk
| Node | Frame | Result |
|---|---|---|
| `2530:4250` | PD-1 Home before | matches |
| `2531:5101` | PD-1 Home after | title breaks one word earlier |
| `2531:5403` | PD-3 Meal ended while checking | fact value is mono |
| `2533:4953` | PD-2 Code fresh | sample code 218 and 10 s, frame 7A3F and 7 s (P-PASS-3 open); sheet slightly shorter |
| `2533:5217` | PD-2 Code changed | matches |
| `2533:5411` | PD-2 Code expired | matches |
| `2533:5598` | PD-3 Pass verified | count card shorter (shared LimeResultScreen) |
| `2534:5241` | PD-3 No special pass | matches |
| `2534:5359` | PD-3 Wrong meal | matches |
| `2534:5466` | PD-3 Already recorded | matches |
| `2534:5568` | PD-3 Doesn't match | sample code 218, frame 7A3F |
| `2534:5675` | PD-3 Can't check right now | title fits one line, so the page sits higher |
| `2535:5422` | PD-2 Look up | matches |
| `2535:5570` | PD-2 Look up valid | matches |
| `2535:5697` | PD-2 Look up used | time is the real recording time |
| `2535:5824` | PD-2 Look up no pass | a different seeded student, because Aarav holds a pass |
| `2535:5948` | PD-2 Look up wrong meal | a different seeded student, as above |
| `2538:5464` | PD-4 Request a new pass | matches |
| `2538:5607` | PD-4 Request sent toast | matches |
| `2538:5739` | PD-4 New pass requests | matches |
| `2539:5555` | PD-5 Report a problem | wording: "Pick what went wrong", "saved" (brief rule) |
| `2539:5708` | PD-5 Report saved toast | wording: "Report saved" (brief rule) |
| `2539:5848` | PD-5 Which food is short? | chips come from the seeded menu, frame draws biryani dishes; nothing preselected |
| `2539:6005` | PD-5 Food short toast | subtitle "Pick what went wrong" (brief rule) |
| `2539:6145` | PD-6 After your report | "Saved" line and closing line (brief rule) |
| `2539:6267` | PD-6 Food short | seeded dish; closing line reworded; capture omits the tab bar |
| `2539:6389` | PD-6 None | icon larger (shared StateBlock); line drops "until Ravi fixes it"; capture omits the tab bar |
| `2544:6222` | PD-7 SOS not claimed | matches |
| `2544:6417` | PD-7 SOS claimed by you | no "I can't go after all": no release operation |
| `2545:6435` | PD-8 Alerts SOS active | "••0412 can get the pass", frame adds the name and "her" (not guessed); ticket mark, regular weight |
| `2545:6596` | PD-8 Alerts claimed | same row; Open the SOS is lime (shared SOSCard) |
| `2545:6742` | PD-8 Alerts checked | same row; pill hugs its text, frame runs wider |
| `2545:6885` | PD-8 Alerts | no Food shortage seen row until the desk's report is seen |
| `2545:7026` | PD-8 Alerts empty | matches |
| `2545:7144` | PD-8 Me | no Switch role (owner ruling); problems count is real (0) |

### Supervisor
| Node | Frame | Result |
|---|---|---|
| `2620:194494` | SV-1 Not started | matches |
| `2620:194630` | SV-1 Start this meal? | matches |
| `2620:194777` | SV-1 In service | matches |
| `2620:194914` | SV-1 In service, SOS | matches |
| `2620:195606` | SV-1 Close this meal? | matches |
| `2620:195754` | SV-1 Closed | matches |
| `2620:195890` | SV-1 Closed, unavailable | drawn from constructed content, so follow-ups show 0 and no tab bar; "Unavailable" is white and the card shorter |
| `2620:196028` | SV-1 In service, offline | Active shortages 0, frame 1 (capture has no report) |
| `2622:11763` | SV-1 Closed, shortage resolved | matches |
| `2623:11633` | SV-2 Alerts before | matches |
| `2621:194949` | SV-2 Alerts during | matches |
| `2621:195091` | SV-2 Alerts SOS | age reads from the capture clock |
| `2621:195244` | SV-2 Alerts after | matches |
| `2621:195397` | SV-2 Alerts resolved | matches |
| `2621:195540` | SV-2 All caught up | title 22 pt set, frame slightly larger |
| `2622:11500` | SV-3 Shortage details | Item block sits about 10 pt higher |
| `2622:11634` | SV-3 Mark resolved? | matches |
| `2624:11817` | SV-4 Waste report | tiles about 10 pt taller, so the rows sit lower |
| `2624:11959` | SV-4 Details closed | tiles about 10 pt taller |
| `2624:12082` | SV-4 Not recorded, Tue | card about 10 pt taller |
| `2624:12191` | SV-4 Not recorded, Wed | card about 10 pt taller |
| `2624:12300` | SV-4 Recorded, Wed | tiles about 10 pt taller, so the last row is lower |
| `2626:11859` | SV-5 SOS not taken | age reads from the capture clock (55 min, frame 5 min) |
| `2626:12110` | SV-5 SOS claimed | age, as above |
| `2626:12289` | SV-5 Home, claimed | matches |
| `2626:12432` | SV-5 Checked by the supervisor | age format "1 h 3 min", frame "63 min" |
| `2626:12612` | SV-5 Checked by the door | SOS tab state and elapsed time differ in the capture behind the sheet |
| `2626:12781` | SV-5 Case closed | elapsed time from the capture clock |
| `2628:12342` | SV-6 Me before | matches |
| `2628:12499` | SV-6 Me during | matches |
| `2628:12641` | SV-6 Me | matches |
| `2628:12783` | SV-6 Me resolved | matches |
| `2628:12925` | SV-6 Sign out? | dialog shorter (shared ConfirmDialog) |
| `2629:12594` | SV-7 History | Breakfast shows Unavailable, frame 402: no spec gives 402 |
| `2629:12742` | SV-7 History resolved | Breakfast Unavailable, as above |
| `2629:12875` | SV-7 History loading | matches |
| `2629:12991` | SV-7 History empty | block higher and text smaller (shared empty state) |
| `2629:13094` | SV-7 History error | line fits one row, so the block sits 10 pt higher |
| `2630:12744` | SV-7 Wed lunch | matches |
| `2630:12893` | SV-7 Wed lunch resolved | resolved time from the capture clock |
| `2630:13027` | SV-7 Wed breakfast | Unavailable, frame 402: no spec gives 402 |
| `2630:13159` | SV-7 Tue dinner | matches |
| `2630:13288` | SV-7 Tue lunch | "By the kitchen · Recorded", frame "Recorded by the kitchen" and a dot with the time |
| `2630:13422` | SV-7 Mon dinner | matches |

## 3. Not built
| Node | Frame | Result |
|---|---|---|
| `2469:1927` | DS-0 What you do (sheet) | Staff entry folder, outside this brief |
| `2529:4180` | PD-0 What you do (sheet) | Staff entry folder, outside this brief |
| `2620:10628` | SV-0 What you do (sheet) | Staff entry folder, outside this brief |
| `2471:2868` | DS-1 Camera denied | no camera in this build, so the state cannot occur |
| `2471:3003` | DS-1 Low light | no camera in this build |
| `2472:3110` | DS-2 Several matches | the entry backend returns one student for a last four |
| `2512:173386` | DS-8 All alerts | no alerts feed behind it |

## 4. Left alone (owner ruling)

Pass Desk Home during the meal and the states drawn on it. The layout of that screen did not change.

| Node | Frame |
|---|---|
| `2530:4460` | PD-1 Home during |
| `2530:4652` | PD-1 Typing, 1 digit |
| `2530:4844` | PD-1 Typing, 2 digits |
| `2530:5008` | PD-1 Typing, 3 digits |
| `2531:4666` | PD-1 Student not found |
| `2531:4933` | PD-1 Offline |
| `2531:5239` | PD-1 During, 42 of 214 |
| `2544:5980` | PD-7 Home, SOS active |
| `2544:6614` | PD-7 Home, claimed |
| `2544:6784` | PD-7 Marked as checked |

## 5. Rules kept over the frame

- Problem reports that stay on the phone do not claim delivery, although DS-5, DS-6, PD-5 and PD-6 draw "Sent to Ravi". Only Food running short says sent, because it goes through `reportShortage`.
- Open problems stay Waiting: nothing can mark one Seen or Fixed, so those pills are built but never claimed.
- Switch role removed from Door Scanner Me, and still absent from Pass Desk Me, although both frames draw it.
- Approved is an outline pill and Done is the only lime one.
- A lookup records nothing and an offline lookup is never a match (`StaffFigmaRuleTests`).
- No torch and no "Point at the student's QR": the camera does not exist.
- Wed 14 Breakfast stays Unavailable. S18 and S19d draw 402, and no spec gives it.

### Wording changed

| Where | Was | Now |
|---|---|---|
| Door and Pass Desk report subtitle | Pick one. Ravi gets it at once. | Pick what went wrong. |
| Door and Pass Desk report footer | It is sent as soon as you tap. | It is saved as soon as you tap. |
| Door toast | Sent to Ravi. It is under Open problems. | Report saved. It is under Open problems. |
| Pass Desk toast | Sent to Ravi | Report saved. It is under Open problems. |
| Door and Pass Desk problem rows | Sent to Ravi · | Saved · |
| Door error | Couldn't send. No connection, so nothing was sent. | Couldn't save. No connection, so nothing was saved. |
| Pass Desk error | Couldn't send. Nothing was sent. | Couldn't save. Nothing was saved. |
| Pass Desk Open problems note | Waiting until Ravi sees it. | Reports are saved on this phone. Food shortages go to the kitchen. |
| Pass Desk food toast | Sent to the kitchen | Sent to the kitchen and Ravi. |
| Pass Desk request toast | Request sent | Request sent to the pass admin. |
| Alerts empty, both | Alerts or messages from Ravi show here. | Alerts from your supervisor show here. |
| Marked as checked, both | Marked as checked | Marked as checked. Ravi will close it. |

## 6. Added backend pieces

All additive, each with tests in `StaffDirectoryTests`. No existing operation changed.

- `StaffDirectoryRepository` (`studentName`, `shiftStartedAt`), defaulted on `Repositories` to `UnavailableStaffDirectory`, so every existing caller is unchanged and a source with no directory shows less, not a guess.
- `DemoStaffDirectory.swift`, guarded to the demo builds.
- `DemoSeed.deskShiftStartedAt`, 11:40 AM. **Sample, not measured**, from `2512:173663` and `2545:7144`. It shows only once that time has passed.
- `sampleReissues`: the waiting row now carries Phone lost, from `2538:5739`. **Sample.**

## 7. Local views

`Features/DoorScanner/StaffFrameViews.swift` holds pieces the shared components cannot draw; Pass Desk and Supervisor use it too: `StaffStatusPill`, `StaffOutcomeScreen` (shared `OutcomeScreen` with actions pinned), `StaffReportRow`, `StaffHomeRow`, `StaffDigitBoxes`, `StaffChip`, `StaffWrapLayout`, `StaffMeProfile`, `StaffMeTile`, `StaffMeRow`, `StaffHeroLabel`. Supervisor adds `SupervisorHistoryRow`, `SupervisorStrongRow`, `SupervisorCaughtUp`, `SupervisorHistorySkeleton`, `SupervisorOfflineMark`.

## 8. Open questions (proposed IDs)

- **P-STAFF-1:** does 402 for Wed 14 Breakfast become a labelled sample, or stay Unavailable?
- **P-STAFF-2:** should `resolveEntry` say which meal a code is for? That unlocks "This QR is for Dinner".
- **P-STAFF-3:** can a last four match several students? Several matches needs a lookup that returns a list.
- **P-STAFF-4:** an alerts feed would add the missing rows on Alerts, See all and All alerts.
- **P-STAFF-5:** a release operation would add "I can't go after all".
- **P-STAFF-6:** a problem repository would make Sent, Seen and Fixed true.
- **P-STAFF-7:** should the shared tab bar, mark and Back change to match the frames? They affect every role.
- **P-STAFF-8:** the Pass Desk frames say "her pass" for Meera. The build shows the masked ID with no pronoun; should a name be added?

## 9. Validation

Final commit `6475926`, one simulator (iPhone 16, iOS 27.2), `-parallel-testing-enabled NO`.

| Run | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug | 0 | 469 | 447 | 0 | 22 |
| Review | 0 | 468 | 446 | 0 | 22 |
| Release build | 0 | n/a | n/a | n/a | n/a |

- Skipped are the opt-in screenshot suites: 10 staff, 8 Outings, 4 Supervisor.
- 24 tests added (14 run normally, 10 capture). No existing test changed or was removed.
- Release failed on the first full run: the new demo directory was not guarded. Fixed in `6475926`, then all three ran again, so Debug and Review ran twice at the end, not once.
- Screenshots come from `f70cf47`. The only later commit adds that compile guard, so the screens are the same.
- Diff outside the three feature folders, tests and this folder: the five backend files in section 6 only.
- Hardcoded data grep over the views: two doc comments only.

## 10. Not run

An iPhone SE or any phone other than the iPhone 16: the new heights have a short-phone branch, and it was not captured. A physical device, a camera, VoiceOver, largest Dynamic Type, Reduce Motion, iOS 17. The comparison was by eye. Every frame was compared at least once; the frames last seen before the final small tweaks were rechecked where those tweaks touched them, not all 112 again. The captures are hosted views seeded by the test, not a walk through the running app, and `2620:195890` is drawn from constructed content.
