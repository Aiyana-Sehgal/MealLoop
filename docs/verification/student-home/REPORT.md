# Student Home report (Part 3a)

Student root, Home, meal answer and Entry QR. Dated 2026-11-06. Xcode 27.2, iOS 27.2. Screenshots: [`small/`](small/) is a temporary iPhone SE (3rd generation), 375 x 667 pt; [`large/`](large/) is an iPhone 18 Pro Max, 440 x 956 pt.

## Results

Counts are from the `.xcresult` bundles, on an iPhone 18 Pro simulator.

| Check | Result |
|---|---|
| Debug | 164 run, 164 passed, 0 failed, 0 skipped |
| Review | 163 run, 163 passed, 0 failed, 0 skipped |
| Release | `** BUILD SUCCEEDED **` |
| Walk-through | Review, small and large, every state below. Temporary XCUITest in a scratch copy, which started the clock at 10:05 AM and preset answers to reach the states the story cannot reach yet |

Not run: a physical device, an iOS 17 runtime, VoiceOver and Dynamic Type.

## Reference table

Images are in `design/reference/redesign_2026-10/images/`, and renders in `design/audit/export_redesign/`. The renders were used where they differ from the sketches.

| State | Reference | Inventory row | Component | Screenshot |
|---|---|---|---|---|
| I'm in | `03_home`, `04_home_top_card_cases` | same | `HeroCard`, `HeroStatusChip`, `HeroSurfaceButton` | `01`, `09` |
| Skipped | `04_home_top_card_cases` | same | same | `10` |
| Not sure | None. Skip layout, by owner decision | None | same | `11` |
| Not answered | `04_home_top_card_cases` | same | `HeroAnswerRow` | Not reachable before a cutoff in the story |
| After the cutoff | Spec line only (`design_intent.md`, prompt stage P5) | None | `HeroAnswerRow`, locked | `07` |
| Next-meal row | `03_home` | same | Student-local `NextMealRow` | `01`, `04` |
| Answer page | `07_lunch_answer` | same | `MealAnswerButtons`, `BackButton` | `02` |
| Answer selected | None | None | `MealAnswerButtons` | `03`, `05` |
| Answer saving | None | None | `MealAnswerButtons` | Too brief to capture |
| Answer page locked | Spec line only | None | `MealAnswerButtons` | Not reachable, see P-STUDENT-5 |
| Entry QR | `08_entry_qr` | same | Student-local `EntryQRView` | `06`, `08`, `09`, `10`, `11` |
| Mess closed | `04_home_top_card_cases`, fourth card | same | **Not built**, see P-STUDENT-1 | None |
| Meal live | None | None | Default hero, by owner decision | None |
| Meal ended | None | None | Default hero, by owner decision | None |

**For the owner to look at** (no drawn image): `03` and `05` selected, `07` locked, `11` Not sure.

**Not sure** is chosen on the answer page, as `07_lunch_answer` draws it. The hero row is I'm in and Skip on purpose.

## Differences left

| Screen | Reference | App |
|---|---|---|
| Home | Points chip, SOS and bell in the header | Omitted. No credit amount is seeded, and the others belong to Part 3e |
| Home | Special pass, Crowd and feedback rows | Omitted. Later parts |
| Home | Time text says "Decide by 9 AM · 2h left" | Backend value: "Decide by 10 AM · 3 h left" |
| Answer page | "answer by 9 AM, 2 h left" | Backend value: "answer by 10 AM, 3 h left" |
| Answer page | Diet mark is green | Ink: no green token exists |
| Answer page | Dish pictograms, and an info icon on Highlight | Omitted: the drawn set is not in the app, and the info sheet is not built |
| Answer page | Tiles show Chappati, Veg Pulao, Muttar Masala | The first three non-highlight dishes in the seed: Steamed Rice, Chappathi, Muttar Masala |
| Answer page | Skip opens "Why skipping?" (prompt stage P5) | Not built: the pack lists it as not shown |
| Entry QR | "Refreshes in 12 s" and its bar | Omitted: the code is static, by owner decision |
| Entry QR | "Live" with a dot | Removed by owner ruling: a static code must not look like a live check |
| Entry QR | "Can't scan?" is underlined | Plain text: no destination exists, so it must not look like a link |
| Entry QR | QR 254 pt wide | 254 pt, smaller on short phones so "Can't scan?" clears the tab bar |
| Entry QR | "You're in" chip | Shown only when the answer is I'm in. No other chip is drawn |
| All | Titles, tab icons | Same token and SF Symbol differences as `docs/FOUNDATION_VERIFICATION.md` |

## Open questions

Proposed IDs for the owner to merge into `docs/OPEN_DECISIONS.md`.

| ID | Question | What the app does now |
|---|---|---|
| P-STUDENT-1 | What makes the mess "closed"? The fourth card is drawn at 6:30 AM, but 03 shows the normal hero at 7:00 AM, and no rule separates them | **Owner: leave unbuilt.** The story starts at 7:00 AM, so it is never reached |
| P-STUDENT-2 | Wording for Not sure | **Owner: accepted as built.** Chip "Not sure", title "Not sure about lunch", line "You can still eat." |
| P-STUDENT-3 | Eyebrow for later meals. Only "This morning" is drawn | **Owner: accepted as built.** "This afternoon" for lunch, "This evening" for snacks and dinner |
| P-STUDENT-4 | Next-meal row once answered. Only the question is drawn | **Owner: accepted as built.** The answer as the title, "Change by 10 AM · 3 h left", and an outlined Change |
| P-STUDENT-5 | Should the answer page open after the cutoff? | **Owner: accepted as built.** Only the row opens it, and the row goes away at the cutoff, so its locked state cannot be reached. The hero's locked state can |
| P-STUDENT-6 | Should a static code say "Live"? | **Owner: no.** The label is removed |
| P-STUDENT-7 | Can a student change a hero meal's answer before its cutoff? | **Owner: leave.** No control is drawn. It cannot arise in the story: lunch becomes the hero only after its cutoff |

## Shared changes needed, not made

- `ios/MealLoopTests/PlaceholderMetricTests.swift`: add `.student: ["Home"]` to `built`. Until then the count reads 32, and the true count is 31.
- A diet colour token in `MLColor`, for the green mark on 05 and 07.
- The drawn dish pictograms, added as app assets.

## Owned by later parts

Meals and the Search filter (3b), Community and feedback (3c), You, credits and attendance (3d), crowd, notifications and SOS (3e), outings (3f).
