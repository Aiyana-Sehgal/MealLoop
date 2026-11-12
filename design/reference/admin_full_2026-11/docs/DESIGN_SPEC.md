# Design spec: Admin and Super Admin

## Language (decided in review, 11 Nov)
- **Bento tiles**, not lists. Tiles have different sizes on one grid (gap 13 pt, radius 28). Each tile has one job: a label, one big mono number, one caption, at most one action.
- **Tile kinds:** black hero (`k`), lime action tile (`l`, black text, black Remind button), white tile, dashed tile (only for data that is genuinely not available).
- **Numbers** are mono (JetBrains Mono), sized 46 to 66 pt; labels 17 pt secondary; captions 15 pt; minimum text 12 pt.
- **Chips** (existing language): outlined (Probably), lime-filled (Sure, New), dashed (Can't tell, not yet). Status elsewhere is a dot plus text.
- **Hairline rows on the canvas** (no white container) only where the original design has them: Needs you rows (title, subtitle, outlined pill), Results rows, "Weekly report ›" rows. The More hub keeps its original white grouped card.
- **One primary action per screen.** Lime pill on a black card, or a black pill on a lime tile.
- **Tab bars:** floating glass capsule. Food Head: Today, Students, Results, More, **no search button**. Super Admin: same four tabs plus the round glass search button.
- Orbit backdrop on every screen: canvas `#EDEDE8`, dot texture, lime disc top right with rings, one black dot. Tokens: Lime `#D4F25A`, Ink `#111111`, Card `#FFFFFF`, Soft `#E8E7DE`, Line `#D8D8D0`, secondary `#6B6B66`.
- Avoid repeating gimmicks (rings, ticket stubs, dashed boxes) across pages. Dashed means "not available".

## Data rules
- Missing data is never zero: use a dash and an explicit "Not available" caption.
- Real figures from the seed: Main about 860 students; 210 haven't answered; 650 answered. Yes, no and not sure counts for **Main are not available** (do not split the 650).
- Sample data (label as sample in the seed, never in the UI): Results figures for Main (3 of 14 meals left over, 1 of 14 ran out), By mess bar heights, 588/700 style per-mess numbers, times (10:15, 10:22), names (Devi, Ravi, Suresh).
- Reasons are Sure, Probably, Can't tell. Never percentages for reasons. "76% of Main has answered" is a derived answer share and is allowed.

## SA01 Today (Super Admin)
Header: logo, SA avatar, "Hey SRM", date. Context line "Lunch · 2,172 expected from 3 messes". Meal stepper (Breakfast done, Lunch active, Snacks, Dinner). Staggered tiles: Main (black, 860, 4-segment strip first lime, caption "Needs approval", lime **Approve**); North (white, 700, 2 of 4 segments, "Ready to send", outlined **Send**); South (white, 612, 3 of 4, "No reply yet"); Annexe (dashed, "—", "No data"). **Needs you · 2** rows: "Rice ran out · Main · Tue dinner" with **Review**; "South hasn't replied · Vendor · since 10:15 AM" with **Remind**. Tab bar with search.

## SA02 Students (Super Admin)
Black hero "ANSWERED 2,870 of 3,500" with a segmented bar (Yes 2,310 lime, No 420 white, Not sure 140 grey, Not yet 630 dark) and four labelled numbers. Lime tile "Not yet 630 haven't answered" with black **Remind**. White tile "Skipped 420 · Why students skip" with the round ↗ button. "By mess" tile with four bars (Annexe dashed). Feedback tile (1, "Sambar · too salty", lime **New** chip) and Community tile (1, "Long wait at North", **Needs an owner** chip).

## AD03 Students (Food Head, Main)
Hero "ANSWERED 650 of about 860", one bar, "76% of Main has answered". Lime tile "Not yet 210 haven't answered" with **Remind**. Dashed tile "I'm in · Skip · Not sure — Not available for Main yet". Feedback tile (1, Sambar, New). Community tile (0, "No reports yet", muted).

## AD04 Today (Food Head)
"Hey Devi", FH avatar, the stepper, one black **Main** card (860 expected diners, 4-segment strip, lime **Approve**, underlined **Change the number**), status line "Not sent to the vendor yet", **Needs you** row "Rice ran out" with **Review**. Tab bar without search.

## AD05 Change the number (sheet)
Stepper control (− 860 +), "Forecast was 860", **Why are you changing it?** with one required reason chip (placeholder wording: Fewer students expected, More students expected, Menu change, Special event; the owner has not approved this list), black **Save change**, note "Your name and reason are saved with the change." Save is disabled until a reason is chosen.

## AD06 to AD08 Results (Food Head, Main)
"Last 4 weeks · Main", segmented control. **Left over:** "Food was left over at 3 of 14 meals", black card (2 meals, Fewer students came than we planned for, Sure), rows with Probably and Can't tell chips. **Ran out:** "1 of 14 meals", card (1 meal, More students came than we planned for), rows Probably and Sure. **To check:** Review these meals · 2 (Wed lunch not closed; Tue dinner rice ran out), Changes being tested · 1 (Wednesday lunch plan, Testing), rows Weekly report and Find an older meal.

## AD09 More (Food Head)
Original grouped card: Weekly menu (Published), Wednesday pass (196/214), Outings (41 out), Votes (1 open), Rewards (3 live), Spare food (2 pickups); second card: Announce to students, History, Sign out. **No People and access.**

## DRAFT screens (spec only, do not build yet)
**H01 Headcount page "Lunch":** back, eyebrow "MAIN MESS · WED 14 AUG", title, stepper (Forecast, Approve, Send, Vendor). Order by priority: the next step first (Approve card), then Cutoff forecast (locked at 10:00 AM), Live forecast (closed), Send to vendor (locked until approved), then Actual entries and Final entries (after the meal). Every card is tappable. **H02 sheets:** Live forecast (answered vs not yet, answers per hour needs a real hourly series or is hidden), Cutoff (what was locked), Approved (who, when, reason if changed), Sent to vendor (Approved, Sent, Acknowledged track; the vendor sees the headcount only), Actual entries (entries timeline), Final entries (opens the meal report). Super Admin approves and sends headcount only if the owner confirms that authority (open question).

## People and access: out of scope
The owner prefers the existing People and access design in Figma. **Do not redesign, rebuild, restyle or re-link it in this pack or in the iOS build.** No mock for it exists in this pack. Any later change must be approved as a whole set, never one screen alone.

## Consistency rule
A change to a shared component (tile, chip, hero, tab bar) is applied to every screen that uses it in the same run. No screen is updated alone.

## Open decisions
Whether Super Admin may approve and send headcount for a mess; what the vendor handoff becomes once the vendor acknowledges inside MealLoop (the Figma sheet still shows message or call); the reason list in the change sheet; real hourly series for the forecast; per-mess answer counts for the By mess tile.
