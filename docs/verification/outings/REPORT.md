# Outings: Warden, Gate Security and Guardian (Part 6, first half)

Branch `feat/ios-outings`, based on `origin/feature/swiftui-foundation` at `2b2abee` (it contains the tips of `feat/ios-core-story-contracts`, `fix/ios-waste-role-guard`, `feat/ios-shared-components` and `feat/ios-supervisor`, checked with `git merge-base --is-ancestor`; PR #16 and PR #18 are merged on this base too).

All three roles are built in the order asked (Warden, Gate, Guardian). Every screen reads the new outing repository and its seed; decisions go through the repository, which enforces the sequence. The Student request screens (Part 3f) are not part of this work: the requests these roles read are seeded.

## What existed before

- `Domain/Outing.swift` had an `OutingState` machine and `GuardianEvidenceMethod`; nothing used them. `Repositories.swift` had an empty `OutingRepository` stub. No backend operation existed for Guardian, Warden or Gate, and no outing seed.
- The three roots were "Coming soon" placeholders (`PlaceholderRootView`). The Warden placeholder already had the four word tabs.

## Backend additions (additive, each in a `feat(backend)` commit, with tests)

| Commit | What |
|---|---|
| `feat(backend): add outing requests for guardian, warden and gate` | `Domain/OutingCase.swift` (new records and an `OutingStage` machine with the call path), `Data/Repositories/OutingCaseRepository.swift` (protocol, `RemoteOutingCaseRepository` that throws `notImplemented`, and `OutingCaseRepositories`, which hands each `AppEnvironment` one source), `Data/Demo/OutingSeed.swift`, `Data/Demo/InMemoryOutingCaseRepository.swift` (actor), `OutingCaseRepositoryTests` |
| `feat(backend): record the exit gate and every gate lookup` | `exitGate` on a request; Find student keeps each lookup with its time (GA-5 says "every lookup is recorded") |
| `feat(backend): order escalations longest overdue first` | Past deadline first, then please watch, then the calls |

Nothing existing was changed: `Outing.swift`, `Repositories.swift`, `AppEnvironment`, `DemoSeed`, `DemoDataProvider`, `RoleRootView`, shared components, tokens and the project file are untouched. New files are picked up by the project's synchronized folders.

Every seed value names its frame in `OutingSeed.swift`. Values no frame draws are `nil` and show as "—" (for example Dev's place and leave time, Meera's and Arjun's reasons, the GA-7 students' blocks).

## Rules and where they are enforced

| Rule | Where |
|---|---|
| Sequence: request, guardian, warden, signed pass, gate exit, gate return | `InMemoryOutingCaseRepository`: every warden decision needs `awaitingWarden` with evidence; exit needs `passSigned` inside the leave window; return needs `out` |
| No timeout approves anything | Time only derives `OutingCase.escalation(at:)`; no operation changes a stage because time passed. Close after a missed deadline is a person's action and never signs a pass |
| Reject needs no video | `rejectAsGuardian` takes an optional reason only |
| Accept needs consent and the live capture; never text only | `startCapture` refuses before consent and after the reply time; a fresh random 3-digit code per try; an old code is refused; under 4 s is "too short" (no try used), over 10 s refused; 3 failed checks, then the video goes as "please watch"; after 2 failed uploads the photo path needs the typed phrase **and** the SMS code |
| Warden decides only for own block, only after the guardian | `wardenCase` filters by block; `decidable` needs the guardian's acceptance |
| Call path ("Confirmed by call") | Only for a guardian who asked for a call; the note is required |
| Role guards | Every write names its role and is refused for any other; `WardenRootView.allows`, `GateRootView.allows`, `GuardianRootView.allows` show the placeholder to every other role |
| No wording that a video proves identity or is the warden's approval | Copy says "Video, checked" / "Sent to the warden" only; the video block is labelled "Guardian video" |

## The prototype story clock (needs the owner: OUT-01)

The spec draws the guardian on Friday evening and the warden and gate on Saturday. The outing source keeps its own clock, separate from the core story's clock, starting at **Fri 16 Aug, 7:41 PM** (G01). Opening a role moves it forward to the moment that role is drawn at, never backwards: Warden **Sat 10:00 AM** (W01, W04), Gate **Sat 2:00 PM** (GA-3). So the presenter can run Guardian, then Warden, then Gate. Opening the Guardian after the Warden shows "This request has expired", which is what the rules say.

In the running app the capture check and the upload always succeed (`MatchingCaptureSimulation`): there is no camera, upload or speech-to-text. The retry, please-watch and photo paths are reached through a scripted simulation in tests and screenshot runs only.

## Reference table

Reference frames are the exports in `design/audit/export_guardian_video/` (newest renders of `design/reference/guardian_2026-10/`). Every row below is an Active inventory row (`docs/SCREEN_INVENTORY.md`, Guardian 41, Warden 22, Gate 18); Archived rows were ignored. Screenshots are in `iPhone_17_Pro_Max/` (large) and `iPhone_SE_3rd_gen/` (small) under the same names.

| Reference (export) | State (frame) | Role · tab | Components used | Data | Screenshot | How reached |
|---|---|---|---|---|---|---|
| `W01_warden_decide_with_video` | 14 Warden · “WV-1 · Queue · Live video” (node 2393:1592) | Warden · Queue | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W01_warden_decide_with_video.png` | Repository operations on the seed |
| `W01_warden_decide_please_watch` | 14 Warden · “WV-1 · Queue · Please watch” (node 2393:1748) | Warden · Queue | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W01_warden_decide_please_watch.png` | Repository operations on the seed |
| `W01_warden_decide_photo_and_text` | 14 Warden · “WV-1 · Queue · Photo and text” (node 2393:1890) | Warden · Queue | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W01_warden_decide_photo_and_text.png` | Repository operations on the seed |
| `W01_warden_decide_confirmed_by_call` | 14 Warden · “WV-1 · Queue · Confirmed by call” (node 2393:2048) | Warden · Queue | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W01_warden_decide_confirmed_by_call.png` | Repository operations on the seed |
| `W01_warden_decide_video_loading` | 14 Warden · “WV-1 · Queue · Video loading” (node 2393:2187) | Warden · Queue | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W01_warden_decide_video_loading.png` | Reload over shown data |
| `W01_warden_decide_empty` | 14 Warden · “WV-1 · Queue · Empty” (node 2393:2346) | Warden · Queue | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W01_warden_decide_empty.png` | Repository operations on the seed |
| `W01_warden_decide_offline` | 14 Warden · “WV-1 · Queue · Offline” (node 2393:2463) | Warden · Queue | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W01_warden_decide_offline.png` | Repository set offline (test hook) |
| `W01_warden_decide_ask_sheet` | 14 Warden · “WV-1 · Ask (sheet)” (node 2395:1766) | Warden · Queue | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W01_warden_decide_ask_sheet.png` | Repository operations on the seed |
| `W01_warden_decide_no_sheet` | 14 Warden · “WV-1 · No (sheet)” (node 2395:1895) | Warden · Queue | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W01_warden_decide_no_sheet.png` | Repository operations on the seed |
| `W01_warden_decide_approved` | 14 Warden · “WV-1 · Approved” (node 2395:2021) | Warden · Queue | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W01_warden_decide_approved.png` | Repository operations on the seed |
| `W01_warden_decide_change_asked` | 14 Warden · “WV-1 · Change asked” (node 2395:2150) | Warden · Queue | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W01_warden_decide_change_asked.png` | Repository operations on the seed |
| `W01_warden_decide_rejected` | 14 Warden · “WV-1 · Rejected” (node 2395:2267) | Warden · Queue | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W01_warden_decide_rejected.png` | Repository operations on the seed |
| `W01_warden_me` | 14 Warden · “WV-5 · Me” (node 2395:170898) | Warden · pushed from WB avatar, no tab bar | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W01_warden_me.png` | Repository operations on the seed |
| `W02_warden_out_now` | 14 Warden · “WV-2 · Out now” (node 2395:2384) | Warden · Out now | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W02_warden_out_now.png` | Repository operations on the seed |
| `W02_warden_out_now_student` | 14 Warden · “WV-2 · Out now · Kiran” (node 2395:2538) | Warden · Out now (pushed, no tab bar) | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W02_warden_out_now_student.png` | Repository operations on the seed |
| `W03_warden_history` | 14 Warden · “WV-3 · History” (node 2395:2982) | Warden · History | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W03_warden_history.png` | Repository operations on the seed |
| `W03_warden_history_all` | 14 Warden · “WV-3 · History · All” (node 2395:3126) | Warden · History | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W03_warden_history_all.png` | Repository operations on the seed |
| `W03_warden_history_record` | 14 Warden · “WV-3 · Record · Aarav” (node 2395:3282) | Warden · History (pushed, no tab bar) | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W03_warden_history_record.png` | Repository operations on the seed |
| `W03_warden_history_record_video_expired` | 14 Warden · “WV-3 · Record · Video expired” (node 2395:3424) | Warden · History (pushed, no tab bar) | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W03_warden_history_record_video_expired.png` | Repository operations on the seed |
| `W04_warden_escalated` | 14 Warden · “WV-4 · Escalated” (node 2395:2675) | Warden · Escalated | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W04_warden_escalated.png` | Repository operations on the seed |
| `W04_warden_escalated_call_kiran_sheet` | 14 Warden · “WV-4 · Call Kiran's guardian (sheet)” (node 2395:2802) | Warden · Escalated | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W04_warden_escalated_call_kiran_sheet.png` | Repository operations on the seed |
| `W04_warden_escalated_call_dev_sheet` | 14 Warden · “WV-4 · Call Dev's guardian (sheet)” (node 2395:2892) | Warden · Escalated | GlassTabBar (words only), StaffHeader, OutingTag, OutingVideoTile, DeadlineRing, ChoiceChip, mlSheet, StateBlock, QuietRow | Repository + OutingSeed | `W04_warden_escalated_call_dev_sheet.png` | Repository operations on the seed |
| `V5_gate_scan` | 15 Gate · “GA-2 · Scan” (node 1858:133) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_scan.png` | Repository operations on the seed |
| `V5_gate_verify_exit` | 15 Gate · “GA-3 · Verify — Exit” (node 1858:179) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_verify_exit.png` | Repository operations on the seed |
| `V5_gate_verify_return` | 15 Gate · “GA-3 · Verify — Return” (node 1858:303) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_verify_return.png` | Repository operations on the seed |
| `V5_gate_pass_code` | 15 Gate · “GA-4 · Can’t scan? — Pass code” (node 1858:415) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_pass_code.png` | Repository operations on the seed |
| `V5_gate_find_student` | 15 Gate · “GA-5 · Find student” (node 1858:481) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_find_student.png` | Repository operations on the seed |
| `V5_gate_exit_recorded` | 15 Gate · “GA-6 · Exit recorded” (node 1860:328) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_exit_recorded.png` | Repository operations on the seed |
| `V5_gate_return_recorded` | 15 Gate · “GA-6 · Return recorded” (node 1860:361) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_return_recorded.png` | Repository operations on the seed |
| `V5_gate_back_late` | 15 Gate · “GA-6 · Back late” (node 1860:392) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_back_late.png` | Repository operations on the seed |
| `V5_gate_already_exited` | 15 Gate · “GA-6 · Already exited” (node 1860:427) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_already_exited.png` | Repository operations on the seed |
| `V5_gate_not_valid` | 15 Gate · “GA-6 · Not valid” (node 1860:461) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_not_valid.png` | Repository operations on the seed |
| `V5_gate_pass_withdrawn` | 15 Gate · “GA-6 · Pass withdrawn” (node 1863:127216) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_pass_withdrawn.png` | Repository operations on the seed |
| `V5_gate_too_early` | 15 Gate · “GA-6 · Outside the window — Too early” (node 1863:127250) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_too_early.png` | Repository operations on the seed |
| `V5_gate_too_late` | 15 Gate · “GA-6 · Outside the window — Too late” (node 1863:127283) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_too_late.png` | Repository operations on the seed |
| `V5_gate_offline` | 15 Gate · “GA-6 · Offline” (node 1863:127316) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_offline.png` | Outcome built directly (repository offline path) |
| `V5_gate_emergency_exit_recorded` | 15 Gate · “GA-6 · Emergency exit recorded” (node 1863:127354) | Gate · no tab bar | — | — | — | Not built: no frame or rule draws how the duty warden authorises an emergency exit (OUT-11). |
| `V5_gate_out_now` | 15 Gate · “GA-7 · Out now” (node 1864:454) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_out_now.png` | Repository operations on the seed |
| `V5_gate_report_a_problem` | 15 Gate · “GA-9 · Report a problem” (node 1864:672) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_report_a_problem.png` | Repository operations on the seed |
| `V5_gate_sent_to_duty_warden` | 15 Gate · “GA-9 · Sent to the duty warden” (node 1864:724) | Gate · no tab bar | GatePage, GateTile, GateResultLayout, InkActionButton, OutlineActionButton, LimeActionButton, BackButton | Repository + OutingSeed | `V5_gate_sent_to_duty_warden.png` | Repository operations on the seed |
| `G00_guardian_consent` | 13 Guardian · “GV-00 · Before you record” (node 2387:1408) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G00_guardian_consent.png` | Repository operations on the seed |
| `G01_guardian_choose` | 13 Guardian · “GV-01 · Choose” (node 2387:1536) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G01_guardian_choose.png` | Repository operations on the seed |
| `G01_guardian_choose_about_sheet` | 13 Guardian · “GV-01 · About this outing (sheet)” (node 2387:1654) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G01_guardian_choose_about_sheet.png` | Repository operations on the seed |
| `G01_guardian_choose_ask_to_change_sheet` | 13 Guardian · “GV-01 · Ask to change (sheet)” (node 2387:1822) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G01_guardian_choose_ask_to_change_sheet.png` | Repository operations on the seed |
| `G01_guardian_choose_language_sheet` | 13 Guardian · “GV-01 · Language (sheet)” (node 2387:2112) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G01_guardian_choose_language_sheet.png` | Repository operations on the seed |
| `G01_guardian_choose_deadline_passed` | 13 Guardian · “GV-01 · Deadline passed” (node 2387:2257) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G01_guardian_choose_deadline_passed.png` | Repository operations on the seed |
| `G01_guardian_choose_already_answered` | 13 Guardian · “GV-01 · Already answered” (node 2387:2365) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G01_guardian_choose_already_answered.png` | Repository operations on the seed |
| `G02_guardian_record` | 13 Guardian · “GV-02 · Record · Try 1 · 0:07” (node 2389:2244) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G02_guardian_record.png` | Repository operations on the seed |
| `G02_guardian_record_ready` | 13 Guardian · “GV-02 · Record · Ready” (node 2389:2127) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G02_guardian_record_ready.png` | Repository operations on the seed |
| `G02_guardian_record_too_short` | 13 Guardian · “GV-02 · Record · Too short” (node 2389:2366) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G02_guardian_record_too_short.png` | Repository operations on the seed |
| `G02_guardian_record_too_dark` | 13 Guardian · “GV-02 · Record · Too dark” (node 2389:2492) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G02_guardian_record_too_dark.png` | Step set directly: no light sensor in the prototype |
| `G02_guardian_record_try2` | 13 Guardian · “GV-02 · Record · Try 2 · 0:07” (node 2389:2614) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G02_guardian_record_try2.png` | Scripted capture simulation (check not matched) |
| `G02_guardian_record_try3` | 13 Guardian · “GV-02 · Record · Try 3 · 0:07” (node 2389:2736) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G02_guardian_record_try3.png` | Scripted capture simulation (check not matched) |
| `G02_guardian_record_camera_blocked` | 13 Guardian · “GV-02 · Camera blocked” (node 2390:1937) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G02_guardian_record_camera_blocked.png` | Step set directly: no camera permission prompt in the simulator |
| `G02_guardian_record_uploading` | 13 Guardian · “GV-02 · Uploading” (node 2390:2059) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G02_guardian_record_uploading.png` | Step set directly: the in-memory upload is instant |
| `G02_guardian_record_checking` | 13 Guardian · “GV-02 · Checking” (node 2390:2156) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G02_guardian_record_checking.png` | Step set directly: the in-memory check is instant |
| `G02_guardian_record_upload_failed` | 13 Guardian · “GV-02 · Upload failed” (node 2390:2572) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G02_guardian_record_upload_failed.png` | Scripted capture simulation (upload fails) |
| `G03_guardian_retry` | 13 Guardian · “GV-03 · Retry · try 2 of 3” (node 2390:2264) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G03_guardian_retry.png` | Scripted capture simulation (check not matched) |
| `G03_guardian_retry_try3` | 13 Guardian · “GV-03 · Retry · try 3 of 3” (node 2390:2361) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G03_guardian_retry_try3.png` | Scripted capture simulation (check not matched) |
| `G04_guardian_send_video` | 13 Guardian · “GV-04 · Send video to the warden” (node 2390:2458) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G04_guardian_send_video.png` | Scripted capture simulation (3 checks not matched) |
| `G05_guardian_photo_and_code` | 13 Guardian · “GV-05 · Photo and code” (node 2390:2673) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G05_guardian_photo_and_code.png` | Scripted capture simulation (2 failed uploads) |
| `G06_guardian_sent` | 13 Guardian · “GV-06 · Sent” (node 2390:2786) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G06_guardian_sent.png` | Repository operations on the seed |
| `G06_guardian_sent_please_watch` | 13 Guardian · “GV-06 · Sent · Please watch” (node 2390:2894) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G06_guardian_sent_please_watch.png` | Scripted capture simulation (3 checks not matched) |
| `G06_guardian_sent_photo_and_text` | 13 Guardian · “GV-06 · Sent · Photo and text” (node 2390:3002) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G06_guardian_sent_photo_and_text.png` | Scripted capture simulation (2 failed uploads) |
| `G06_guardian_sent_call_requested` | 13 Guardian · “GV-06 · Sent · Call requested” (node 2390:3110) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G06_guardian_sent_call_requested.png` | Repository operations on the seed |
| `G06_guardian_sent_rejected` | 13 Guardian · “GV-06 · Sent · Rejected” (node 2390:3216) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G06_guardian_sent_rejected.png` | Repository operations on the seed |
| `G06_guardian_sent_withdraw_sheet` | 13 Guardian · “GV-06 · Withdraw approval (sheet)” (node 2390:3320) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G06_guardian_sent_withdraw_sheet.png` | Repository operations on the seed |
| `G06_guardian_sent_withdrawn` | 13 Guardian · “GV-06 · Withdrawn” (node 2390:3440) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G06_guardian_sent_withdrawn.png` | Repository operations on the seed |
| `G07_guardian_past_answers` | 13 Guardian · “GV-07 · Past answers” (node 2390:3544) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G07_guardian_past_answers.png` | Repository operations on the seed |
| `G08_guardian_reject_sheet` | 13 Guardian · “GV-08 · Reject (sheet)” (node 2387:1967) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `G08_guardian_reject_sheet.png` | Repository operations on the seed |
| `V5_guardian_status_pass_ready` | 13 Guardian · “G-3 · Status · Pass ready” (node 1929:537) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `V5_guardian_status_pass_ready.png` | Repository operations on the seed |
| `V5_guardian_status_out` | 13 Guardian · “G-3 · Status · Out” (node 1929:595) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `V5_guardian_status_out.png` | Repository operations on the seed |
| `V5_guardian_status_back` | 13 Guardian · “G-3 · Status · Back” (node 1929:651) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `V5_guardian_status_back.png` | Repository operations on the seed |
| `V5_guardian_status_back_late` | 13 Guardian · “G-3 · Status · Back late” (node 1929:704) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `V5_guardian_status_back_late.png` | Repository operations on the seed |
| `V5_guardian_status_not_going` | 13 Guardian · “G-3 · Status · Not going” (node 1929:762) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `V5_guardian_status_not_going.png` | Repository operations on the seed |
| `V5_guardian_status_change_asked` | 13 Guardian · “G-3 · Status · Change asked” (node 1929:912) | Guardian · one page, no tabs | GuardianLayout, GuardianSteps, GuardianPhraseCard, OutingVideoTile, OutingTag, ChoiceChip, mlSheet, DigitBoxes | Repository + OutingSeed | `V5_guardian_status_change_asked.png` | Repository operations on the seed |
| `V5_guardian_sign_in` | 13 Guardian · “G-0 · Sign in” (node 1929:131727) | Guardian · one page, no tabs | — | — | — | Not built: production guardian sign-in is undecided (OUT-03); the seeded account signs in through the shared entry. |
| `V5_guardian_verify_code` | 13 Guardian · “G-0 · Verify code” (node 1929:131799) | Guardian · one page, no tabs | — | — | — | Not built: same as sign-in (OUT-03). |
| `V5_guardian_activate_account` | 13 Guardian · “G-A1 · Activate account” (node 1929:131872) | Guardian · one page, no tabs | — | — | — | Not built: same as sign-in (OUT-03). |
| `V5_guardian_confirm_link` | 13 Guardian · “G-A2 · Confirm link” (node 1929:131931) | Guardian · one page, no tabs | — | — | — | Not built: same as sign-in (OUT-03). |
| `V5_guardian_done` | 13 Guardian · “G-A3 · Done” (node 1929:132000) | Guardian · one page, no tabs | — | — | — | Not built: same as sign-in (OUT-03). |
| — | design/audit/outings/o5/GA-1_Gate_home.png (not an inventory row) | Gate · root, no tab bar | as above | Repository + OutingSeed | `GA1_gate_home.png` | Repository operations on the seed |
| — | GA-8 (named in DEMO.md, not exported; drawn from the GA-7 layout) | Gate · pushed | as above | Repository + OutingSeed | `GA8_gate_overdue_returns.png` | Repository operations on the seed |
| — | WV-1 Confirmed by call, before the note is written (not exported) | Warden · Queue | as above | Repository + OutingSeed | `W01_warden_decide_call_note_needed.png` | Repository operations on the seed |

The Student S01 frames in the same pack belong to Part 3f and were not built.

## Differences from the references (checked by eye on the large device, layout on the small one)

Warden
- Counts come from the seed, so "1 of 3" not "1 of 14", Out now **3 / due 2 / late 1** not 12 / 9 / 1, and "See all" appears only above four rows. No names were added to reach the drawn totals (OUT-08).
- The deadline ring's arc is the share of the warden's window still left since the guardian answered; with no answer time (seeded Meera, Arjun) only the text shows.
- "Past answers: 3 by video" is plain text, not an underlined link: no frame draws where it goes.
- Reason chips on the No sheet sit in a two-column grid, not hugging their text.
- Copy says "their guardian" where the frames say "his guardian" (OUT-13).
- Call buttons (Call Kiran, Call the guardian, Call +91 …) are shown but inactive: the prototype cannot place calls and holds only masked numbers.
- Out now detail drops "Kiran's guardian was told at 5:10 PM" (no notification record exists).
- History record: the deletion day is computed from the capture time plus the draft 30 days (Sun 15 Sep here, Mon 16 Sep drawn). "A fingerprint stays" and "every view is logged" are left out because neither exists in the prototype (OUT-04).

Gate
- The home adds a "Report a problem" link (DEMO.md, gate step 9); the GA-1 render shows none. GA-8 Overdue returns is not exported, so it reuses the GA-7 layout.
- The scan viewfinder is a still frame and is not tappable (no camera); Torch is inactive. "Can't scan?" and the typed code reach every result.
- Exit recorded shows the real count of students out (7 with the GA-7 seed), not "3".
- Out now keeps "Times are the gate's own records." and drops "The warden sees the same list.": the warden sees only their own block.
- "Call the warden" on Can't verify is inactive (see calls above).
- "Pass withdrawn" says who withdrew it: the frame draws the warden, but only the guardian has a withdraw action, so the seeded flow reads "The guardian withdrew it at …" (OUT-10).

Guardian
- "Reply by Fri 11 PM" is a dot and plain text, not a capsule, per the status rule.
- The language sheet lists all three languages; only English can be chosen ("Not translated yet") until the translations exist (OUT-05).
- About this outing drops "Aarav's last 30 days · 3 outings · all back on time": no such data is seeded.
- Past answers dates use one form ("Sat 3"), where the frame mixes "Sat 10" and "Aug 3".
- "Call the warden", "Messages" and "Help" are shown but inactive.
- Status copy uses the student's name where the frames say "he".
- Capture screens use a still face placeholder; the timer, the length rules and the codes are real. **Capture is not verified on a device.**
- On the small phone the page scrolls under the footer (Choose, Photo and code); every control is reachable.
- Status colours green and amber (G-3) are not in the token set and are local values (OUT-09).

## Open questions for the owner (proposed IDs)

| ID | Question |
|---|---|
| OUT-01 | Approve the outing story clock: one forward-only clock that moves to each role's drawn moment (Fri 7:41 PM guardian, Sat 10:00 AM warden, Sat 2:00 PM gate)? |
| OUT-02 | The seed keeps the design's names, including "Aarav's guardian" (DemoSeed) and male sample students, while the pilot is a girls' mess. Rename? Nothing was renamed. |
| OUT-03 | Production guardian authentication (G-0 Sign in, Verify code, G-A1–A3 Activate) is undecided, so those five frames are not built. Who verifies the guardian number (SRM source)? |
| OUT-04 | Video retention is a draft (30 days). Approve, and decide whether "fingerprint" and audit-logged access are promised in copy. |
| OUT-05 | Languages: who writes the Tamil and Hindi phrase and page translations? |
| OUT-06 | Is the call path allowed (spec open item)? How does the warden record a guardian who says no on the phone (not drawn)? |
| OUT-07 | W01 says Aarav has "3 by video"; G07 lists one video and one one-tap reject. Which is right? The seed keeps both as drawn. |
| OUT-08 | Sample density: W01 "1 of 14", W02 "12 out", GA-6 "3 out now" need more students than the frames name. Add named students, or accept the real counts? |
| OUT-09 | Add the G-3 green and amber status colours to the tokens? |
| OUT-10 | Can the warden withdraw a signed pass (GA-6 says so; no warden action is drawn)? |
| OUT-11 | Emergency exit: how does the duty warden authorise it, and what does the gate record? |
| OUT-12 | `Domain/Outing.swift` (`OutingState`) has no call path and no close; this part added `OutingStage` beside it. Reconcile the two in the shared domain. |
| OUT-13 | Student pronouns in copy: the frames say "his"; these screens use the name or "their". |
| OUT-14 | Warden undo: the screen offers it for 10 seconds; the prototype allows it until the pass is used. What is the server rule? |
| OUT-15 | Warden "Past answers" link and guardian "Messages" / "Help" have no drawn destination. |

## Commands and results

`pgrep -x xcodebuild` was checked before every build (never above 4). Note: `pgrep -fl xcodebuild | wc -l` counts other sessions' multi-line shell commands too (it printed 274 once while 2 real `xcodebuild` processes ran), so `-x` was used.

Base, before any change (Debug, Supervisor Pro Max, `-parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1`): **254 total, 250 passed, 0 failed, 4 skipped**. The Review suite was not run on the base.

```sh
xcodebuild test -project ios/MealLoop.xcodeproj -scheme MealLoop -configuration Debug \
  -destination id=E505D03D-2EE0-4434-A506-8334257E6353 -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1
xcodebuild test -project ios/MealLoop.xcodeproj -scheme "MealLoop Review" \
  -destination id=E505D03D-2EE0-4434-A506-8334257E6353 -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1
xcodebuild build -project ios/MealLoop.xcodeproj -scheme MealLoop -configuration Release \
  -destination "generic/platform=iOS Simulator"
TEST_RUNNER_OUTINGS_SHOTS=docs/verification/outings xcodebuild test ... -only-testing:MealLoopTests/OutingScreenshotTests
```

Final results on this branch (`.xcresult` summaries; the last code change is `fix(outings): keep guardian and gate controls on screen on small phones`):

| Run | Result | Total | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| Debug tests, Supervisor Pro Max (iPhone 17 Pro Max, iOS 26.5) | exit 0, Passed | 288 | 276 | 0 | 12 |
| Review tests (`MealLoop Review`), same simulator | exit 0, Passed | 287 | 275 | 0 | 12 |
| Release build, generic iOS Simulator | exit 0, BUILD SUCCEEDED | — | — | — | — |
| Screenshots, Supervisor Pro Max | exit 0 | 8 | 8 | 0 | 0 |
| Screenshots, Supervisor SE (iPhone SE 3rd gen, iOS 26.5) | exit 0 | 8 | 8 | 0 | 0 |

Against the base Debug run (254 / 250 / 4): +34 tests. 26 new tests pass (18 `OutingCaseRepositoryTests`, 8 `OutingRoleTests`); the 8 `OutingScreenshotTests` are skipped unless `TEST_RUNNER_OUTINGS_SHOTS` is set, so the skipped count is 4 + 8. All earlier tests still pass. The only Release warning is Xcode's AppIntents metadata note.

Changed files (`git diff --name-only origin/feature/swiftui-foundation...HEAD`): only `Features/Warden/`, `Features/Gate/`, `Features/Guardian/` (including their roots), the new `Features/Outings/`, the new outing files `Domain/OutingCase.swift`, `Data/Repositories/OutingCaseRepository.swift`, `Data/Demo/OutingSeed.swift`, `Data/Demo/InMemoryOutingCaseRepository.swift`, three new test files, and this folder.

Hardcoded data: `grep` over the three role folders and `Features/Outings/` (outside the `*Copy.swift` files) finds no sample name, code, count, block or place in view code. The only literals are the dial's "12" and "6", the pass-code keypad keys, accessibility wording, and the screenshot start hooks.

## What could not be run, and what was only checked by eye

- No camera exists in the simulator: video and photo capture, the torch and QR scanning are not exercised. Capture must be verified on a device.
- The live speech-to-text check and the upload are simulated (always succeed in the running app); their failure paths are reached only through the scripted simulation in tests and screenshots.
- Calls cannot be placed; all call controls are inactive.
- The screenshots host the real role views in a window with prepared repository state (the Supervisor pattern); the sign-in flow into each role was not driven through the UI. Role routing itself is unchanged and covered by `OutingRoleTests`.
- Visual comparison with the references was by eye, on montages of the large-device captures beside the exports; the small-device captures were checked for clipping and overlap only.
