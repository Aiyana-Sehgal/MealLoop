# Presenter script, 11 November 2026

What to show, in order, and what to say honestly. The order is the core-story walk recorded as passed in
`docs/verification/integration/REPORT.md` section 3, re-run on 9 November in `docs/verification/staff-complete/REPORT.md`
(R4: steps 1 to 6 passed; step 7's Supervisor half passed). Accounts: `docs/PRESENTER_ACCOUNTS.md`. Scheme: **MealLoop
Review**. Do not relaunch between steps: the data is in memory and a relaunch resets the story to 7:00 AM.

## The story

1. **Student, 7:00 AM.** Sign in with SRM. Open lunch, tap I'm in. The audience sees "You're in for lunch · Change by
   10 AM". Open the entry QR: a "Live" code with a refresh bar. Say: the QR is for entry; answering never blocks food.
2. **Food Head.** Staff sign in. Today, Approve, Approve 860, Send 860 to vendor, Send. The audience sees "SENT TO
   VENDOR", 860. Say: the vendor gets a headcount, not dish quantities; nothing is actually sent.
3. **Student again (optional).** Home now says "Lunch answers closed · Cutoff 10 AM passed · your QR still works".
4. **Supervisor.** Start meal, confirm. The audience sees "LIVE · 12:00 PM" and 0 students entered.
5. **Door Scanner.** Type ID, 0 2 3 8. "Recorded in" goes from 0 to 1.
6. **Kitchen.** The live count shows 1 student entered. Report Steamed Rice almost out. **Supervisor** opens it from
   Alerts; back on Kitchen the row reads "Steamed Rice, almost out, Ravi saw it".
7. **Supervisor and Kitchen.** Close meal, confirm ("Closed · 2:00 PM", final entries 1). Kitchen records waste (8
   dishes None left, plate waste 18 kg), reviews and saves: "Report saved", Home shows Recorded.
8. **Supervisor.** Me, Meal history, the lunch: the waste report is read only (18 kg, no Save, Edit or Record).

Optional, if time allows (each built and walked in `docs/verification/staff-complete/REPORT.md` R4): Guardian
(`guardian@mealloop.example`, a simulated sign in, then the decision page), Warden (Queue, Out now, Escalated,
History), Gate (Out now, Overdue returns).

## Honesty: what is simulated or not verified

- **No backend.** Everything runs on seeded in-memory data (`docs/PRESENTER_ACCOUNTS.md`: "no backend is involved").
- **Camera scanning is not available.** The build has no camera permission key; the door uses Type ID
  (`docs/verification/door-scanner/REPORT.md`, "Not built and not verified on a device").
- **The QR rotation is simulated.** The entry QR shows Live and refreshes on a timer, but no scanner verifies it
  (owner decision OD-4 in `docs/OPEN_DECISIONS.md`; P-STORY-6).
- **Nothing is delivered.** Messages, problem reports, guardian codes and calls go nowhere: the door's problem log
  stays on the phone (`docs/verification/staff-figma-fix/REPORT.md`, P-STAFF-6; P-DOOR-1), the guardian sign in sends
  no code and calls nobody (`docs/verification/outings-staff/REPORT.md`).
- **Seeded sample numbers.** 860, 714, 18 kg and the history figures are seeded samples, not measurements; the
  forecast is a seeded 860 with no approved formula (P-STORY-1, P-STORY-2; `docs/verification/integration/REPORT.md`
  section 2, item 4).
- **The sample student and the mess.** The pilot is Meenakshi Girls' Mess, but the sample student is Aarav and the
  seed mess is "Main Mess" (P-STORY-7, OUT-02).
- **Vendor is still Coming soon** (`ios/MealLoop/Features/Vendor/VendorRootView.swift`); Super Admin is minimal
  (`docs/verification/admin-final/REPORT.md`, Part C).
- **Checked on a simulator and by eye only.** No physical device, no camera, no VoiceOver pass, no live edge swipe
  (`docs/verification/outings-staff/REPORT.md` and `docs/verification/staff-complete/REPORT.md`, "not checked"); the
  integration walk's screenshots were checked mainly through the accessibility tree
  (`docs/verification/integration/REPORT.md`, "Checked by eye or not run").
- **The guardian video check is not identity proof and not the warden's approval** (CLAUDE.md product rules; Prompt 4
  role context in `docs/verification/outings-staff/REPORT.md`); on the simulator the capture is a still preview.

## Questions a reviewer is likely to ask

| Question | True answer |
|---|---|
| Is this connected to a real server? | No. Seeded in-memory data; a Spring Boot and PostgreSQL backend follows later (`CLAUDE.md`; ADR-003). |
| How is the forecast calculated? | It is not yet: the forecast is a seeded 860 and no formula is approved (P-STORY-1). |
| Can a student skip answering and still eat? | Yes. The entry QR is always available; nobody is denied food for not answering (`docs/archive/README_2026-11-09.md`, "How MealLoop works", step 3). |
| What happens when the door has no connection? | Nothing is recorded, and the screen says so (P5 default "Never record"; `docs/verification/door-scanner/REPORT.md`). |
| How are guardians verified? | Not decided: the guardian sign in is simulated (P71, OUT-03, P-ENTRY-2). |
| How long are guardian videos kept? | A draft of 30 days, not approved (P4, OUT-04). |
| How are credits earned? | The formula is not approved; no numbers ship until it is (P1). |
| Does it work in Tamil or Hindi? | Not yet: only English is shown until translations exist (owner ruling of 9 November, `docs/verification/staff-complete/REPORT.md` R1; translators: OUT-05). |
| When is Android coming? | After the iOS app and the backend (`CLAUDE.md`; ADR-005). |
| How many students will the pilot cover? | No document answers this. |
