# Student 1 of 3: Home, Answer and Entry QR against Figma

Branch `feat/ios-student-home-figma`, base `feature/swiftui-foundation` at `91b1ce9`, code tested at `006361b`. Figma file `nzzTAm9YnJRSdKEeYUWUEb`, read only, through the connector. Xcode 27.2, iOS 27.2.

## Result

| Frames | Count |
|---|---|
| Matches | 5 |
| Differs in text only (mostly the backend cutoff the brief requires) | 27 |
| Differs in layout or content | 16 |
| Not built | 1 |
| **Total** | **49** |

"Matches" means nothing specific to that frame differs. Every frame also shares the differences below, so none is pixel-identical.

**Differences on every frame**
- The system font, because Inter stands in for it in Figma (`MLType`). Text is narrower, so lines can wrap differently.
- The device is 402 pt wide with its own status bar, against the 393 pt frame, so content sits a few points lower.
- The shared `GlassTabBar` draws larger icons than the frames. It is outside this brief.

Each file in `compare/` shows Figma, then iPhone 18 Pro, then iPhone SE (3rd generation), all at the same height. Every pair was looked at on final code.

## Frame by frame

### Home

| Frame | Node | Result | What differs |
|---|---|---|---|
| Not answered | `221:62529` | differs | Captured at 5:00 AM, the only time breakfast is still open (cutoff 5:30 AM), so Crowd reads Closed now and the row says 5h left, where the frame draws 7:00 AM, Quiet now and 2h. |
| You're in | `221:62548` | differs (text only) | cutoff text from the backend: Decide by 10 AM · 3h left. |
| Breakfast open | `221:62565` | differs (text only) | cutoff text from the backend: Decide by 10 AM · 1h 50m left, which wraps to two lines. |
| After a meal | `221:62580` | differs (text only) | Captured at 10:05 AM, because at 9:40 lunch is still open with the 10 AM cutoff. Row says Cutoff 10 AM passed. |
| After cutoff | `221:64816` | differs | The frame shows the breakfast card with lunch closed. With a 10 AM cutoff breakfast is over by then, so the card is Lunch at 12 PM and How was breakfast? shows. |
| Mess closed | `221:64833` | differs (text only) | cutoff text from the backend: Decide by 10 AM · 3h 30m left, which wraps. |
| Empty | `221:64850` | differs | Adds a Show entry QR button the frame does not draw, because the QR must always be reachable (brief section 2). |
| No Special pass | `221:64860` | differs | Shows Wednesday 14 Aug where the frame draws Thursday 15 Aug, and cutoff text from the backend. |
| Offline | `221:64876` | differs | Saved time is when Home last loaded, not the drawn 6:58 AM; cutoff text from the backend; Answer is lighter than drawn. |
| Loading | `221:64894` | matches |  |
| Skipped | `221:64907` | differs | Title fits one line in the system font where Inter wraps to two, so rows sit higher; cutoff text from the backend. |

### Answer

| Frame | Node | Result | What differs |
|---|---|---|---|
| Lunch | `221:62596` | differs (text only) | cutoff text from the backend (10 AM, 3 h left); dish spelt Chappathi as seeded, drawn Chappati. |
| Lunch · Sending | `221:62613` | differs (text only) | Same text differences as Answer · Lunch. |
| Lunch · I'm in | `221:62630` | differs (text only) | Same; line wraps at a different word. |
| Lunch · Cutoff passed · In | `221:62648` | differs (text only) | cutoff text from the backend; Chappathi. |
| Lunch · Offline | `221:62666` | differs (text only) | Same text differences as Answer · Lunch. |
| Why skipping · Reason picked | `221:62683` | differs | Sheet is the shared `mlSheet`: white, inset from the edges, where the frame is edge-to-edge glass. |
| Why skipping | `221:62700` | differs | Same sheet difference. |
| Lunch · Skipped | `221:62730` | differs (text only) | cutoff text from the backend; Chappathi. |
| Lunch · Not sure | `221:62749` | differs | "We'll remind you at 8:30 AM" removed: no reminder exists and no document sets its time (P-STUDENT-F1). Shows Decide by 10 AM. |
| Lunch · Failed | `221:64924` | differs (text only) | cutoff text from the backend; line breaks differently. Reached with a forced failure in the capture copy. |
| Lunch · Failed (skipping) | `221:64941` | differs (text only) | Same. |
| Lunch · Cutoff passed · Not answered | `221:64958` | differs (text only) | cutoff text from the backend; Chappathi. |
| Lunch · Cutoff passed · Skipped | `221:65099` | differs (text only) | cutoff text from the backend; Chappathi. |
| Dinner · Cutoff passed · In | `221:65133` | differs (text only) | cutoff text from the backend: 5:30 PM, drawn 4 PM. |
| Dinner · Not sure | `221:65154` | differs | Reminder line removed as above; 5:30 PM. |
| Breakfast · Cutoff passed · Not answered | `221:65175` | differs (text only) | cutoff text from the backend: 5:30 AM, drawn 6 AM. |
| Breakfast | `2154:143268` | differs (text only) | cutoff text from the backend: 5:30 AM, 30 min left. |
| Breakfast · I'm in | `2154:143425` | differs (text only) | Same. |
| Breakfast · Why skipping | `2154:143580` | differs | Sheet difference as above. |
| Breakfast · Not sure | `2154:143770` | differs | Reminder line removed. |
| Breakfast · Offline | `2154:143926` | differs (text only) | cutoff text from the backend. |
| Breakfast · Failed | `2154:144087` | differs (text only) | cutoff text from the backend. |
| Dinner | `2154:144248` | differs (text only) | cutoff text from the backend: 5:30 PM, 10 h 30 min left; Panneer Butter Masala wraps differently. |
| Dinner · I'm in | `2154:144445` | differs (text only) | Same. |
| Dinner · Why skipping | `2154:144640` | differs | Sheet difference as above. |
| Dinner · Offline | `2154:144870` | differs (text only) | cutoff text from the backend. |
| Dinner · Failed | `2154:145071` | differs (text only) | cutoff text from the backend. |

### Entry

| Frame | Node | Result | What differs |
|---|---|---|---|
| Entry QR | `221:62986` | differs (text only) | The countdown is live, so it reads the real seconds and the bar follows them. The frame draws 12 s with the bar 60% full. The QR is a real code. |
| Scanned | `221:62996` | matches |  |
| Already scanned | `221:63016` | matches | The dimmed QR is a real code. |
| Refreshing | `221:65200` | matches | Shows for about 0.6 s at each change; held longer in the capture copy to photograph it. |
| Wrong mess | `221:65220` | matches | Only a second mess can trigger it, and none is seeded, so it was forced in the capture copy. |
| Offline (Saved QR) | `221:65240` | differs (text only) | Saved time is real, not the drawn 6:58 AM; footnote fits one line. |
| Walk-in | `2154:147126` | differs (text only) | Live countdown, as Entry QR. |
| Discrepancy | `221:63082` | differs | Sheet works, but **cannot be reached in the app**: its host is the Attendance page (You tab), not built here. Captured over Home. Rows use a quiet fill because `mlSheet` is white; no Attendance title behind it. |
| Discrepancy — sending | `221:63101` | differs | Same. |
| Discrepancy — failed | `221:65251` | differs | Same. |
| Under review | `221:63120` | not built | The frame renders blank in Figma: its backdrop layer sits above the content. The hidden content is the full Attendance page (ring, weeks), which belongs to the You tab. |

## Reachable in the Review build, or only with capture hooks

The Review story starts at 7:00 AM with breakfast answered, so many frames need a time or a failure the story never reaches. They were captured from a scratch copy with launch hooks, never committed.

- **Reachable by tapping:** Home · You're in, After a meal, After lunch; every Answer · Lunch and Answer · Dinner frame for an open answer; Why skipping; Entry QR; Refreshing; Scanned; Already scanned; cutoff-passed frames after the headcount moves the clock.
- **Hooks only:** Home · Not answered, Mess closed, Empty, No Special pass, Offline, Loading, Skipped; every Failed and Offline frame; Answer · Breakfast with an open answer; Wrong mess; Discrepancy.

## Built as local views

The shared components could not draw these, so they live in `Features/Student` and no shared file changed: `StudentHeroCard` (radius 30, padding 24), `StudentHeroChip` (36 pt), `StudentGlass`, `StudentOfflineBanner`, `StudentScrollFade`, `StudentNavHeader`, `StudentTicketShape`, dish tiles and diet marks. `StudentAssets.xcassets` holds the Figma star, ticket and diet marks and the repository pictograms. It is a new file in the Student folder, not a project setting.

## Added to the backend

All additive, in `b22f950` and the rename `2ce5148`, with `StudentExtrasRepositoryTests`.

- `StudentExtrasRepository`, with a defaulted slot on `Repositories`: `homeExtras`, `studentMenu`, `skipReason`, `setSkipReason`, `entryStanding`, `rotatingEntryCode`, `correctableRecord`, `requestEntryCorrection`.
- `Domain/StudentHome.swift` and `Data/Demo/DemoStudentSeed.swift`.
- Three lines inside existing operations, none changing a result: `requireDayMeal` and `setIntention` accept the dinner meal, which did not exist before; `recordEntry` notes a repeat scan.

**Samples, not measured** (each cited in `DemoStudentSeed.swift`): 120 pts, the seven Crowd bars, Best time 1:30 PM, Quieter after 8:45 AM, the 7:00 AM opening, the sambar follow-up, the dinner time, the breakfast and dinner dishes, and the Tue 13 dinner record.

**The QR refresh is simulated.** The image regenerates every 12 seconds from the seeded code plus a changing token. No scanner verifies it, because QR scanning is not built. The door's typed last four is unchanged and tested.

## Results

Counts are from `.xcresult`.

| Run on `006361b` | Exit | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug tests | 0 | 496 | 484 | 0 | 12 |
| Review tests | 0 | 495 | 483 | 0 | 12 |
| Release build | 0 | n/a | n/a | n/a | n/a |
| Review tap walk, iPhone 18 Pro | 0 | 3 | 3 | 0 | 0 |
| Review tap walk, iPhone SE (3rd generation) | 0 | 3 | 3 | 0 | 0 |

The walks tap sign-in, every Home row, Skip with a reason, Change answer, Not sure, I'm in, the return to Home, and confirm the QR image itself changes on screen after 12 seconds. They are temporary and not committed.

**Not run:** a physical device, iOS 17, VoiceOver, Dynamic Type, any real QR scan. Hero Skip on Home has no walk, because it needs a time before 5:30 AM.

**Greps:** no sample data and no `DemoSeed` in Student views; no credential in Student code.

**Diff against the base:** the Student folder, its tests, this folder, plus the backend pieces listed above.

**Base:** Kitchen, Outings and Admin merged while this was being built, moving the base from `dd2b21e` to `91b1ce9`. It was merged in, and everything above ran on that combined code. The merge exposed a real clash: Admin already had a `SkipReason`, a count row, so the student's choice became `MealSkipReason`.

**Repeated runs:** the final pass ran twice, because the last visual check found the iPhone SE header cut short and a greyed Sending button. The first capture attempt also failed on a harness patch, not on the app. Debug, Review and Release ran twice as a result, not once.

## Defects found by comparing, all fixed

Unit tests passed through every one of these.

- The QR did not draw at all, in two separate ways: a zone with no width, then `.task` on an empty view.
- Ticket notches bulged outward instead of cutting in, and the perforation was missing.
- Saving and Sending buttons were greyed by `.disabled`.
- The iPhone SE header truncated MealLoop and the points.

## Open questions

| ID | Question | Built today |
|---|---|---|
| P-STUDENT-F1 | Is there a Not sure reminder, and when? The frame draws 8:30 AM against a 9 AM cutoff. No document sets it, and nothing would send it | Line removed |
| P-STUDENT-F2 | Should Crowd say it is an estimate on screen? The brief asks for an estimated label, the frame has none, and the frame wins | Frame wording; the spoken label says Estimate |
| P-STUDENT-F3 | No hourly arrivals exist, so the Crowd bars are samples, not the verified activity the brief asks for. Build real ones from entries? | Sample bars; the level follows the meal state |
| P-STUDENT-F4 | Where does Discrepancy open from before the You tab exists? | Built, not reachable |
| P-STUDENT-F5 | Fix the Under review frame in Figma so it can be read? | Not built |
| P-STUDENT-F6 | Chappati or Chappathi on the student menu? The board spells Wednesday lunch Chappati; the seed follows the Kitchen spec | Chappathi |
| P-STUDENT-F7 | The Empty frame has no QR button, but the rule says the QR is always available | Button kept |
| P-STUDENT-F8 | Good and Not good, the feedback row, the pass and the header buttons all open Coming soon until later Student parts | Coming soon |

P-STUDENT-1 (what makes the mess closed) is answered here as a sample: before 7:00 AM, unless an open question comes first. The owner should confirm it.
