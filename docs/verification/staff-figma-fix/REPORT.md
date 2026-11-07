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
