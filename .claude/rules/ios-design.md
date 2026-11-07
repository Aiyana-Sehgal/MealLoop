---
paths:
  - "ios/MealLoop/DesignSystem/**"
  - "ios/MealLoop/Features/**"
---

# iOS design fidelity and components

Scope: SwiftUI screens, shared components and tokens. Architecture is in `ios-architecture.md`; build and Definition of Done are in `quality-and-testing.md`. The design language below was verified in `design/audit/design_intent.md`, `design/audit/prototype_contract.md` and the packs under `design/reference/`.

## Workflow for every screen
1. **Identify the exact active screen and state.** Find it in `docs/SCREEN_INVENTORY.md` (Status must be Active; Needs review and Archived are not requirements) and in the latest pack under `design/reference/` (read the pack's `README.md` and `data/*_spec.md`). Name the reference image in your report. Screens marked "Needs design (not in Figma)" have no reference: stop and ask.
2. **Inspect tokens and existing components** (below) before writing any view.
3. **Implement in SwiftUI**, with all visible wording in the feature's `<Feature>Copy` enum and all values coming from a view model.
4. **Run it in the simulator, capture a screenshot and compare it with the reference image.** Fix visible differences (layout, spacing, copy, colour, state) before calling it done.
5. If you cannot capture a screenshot in this session, say so. **Never claim a visual match you did not check.**

Screenshot commands (macOS with Xcode; `<UDID or name>` comes from `xcrun simctl list devices available`):
```sh
xcrun simctl boot "<UDID or name>"                      # an error saying it is already booted is fine
# build as in quality-and-testing.md, adding -derivedDataPath build (build only; no tests needed for a screenshot)
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/MealLoop.app
xcrun simctl launch booted in.mealloop.app
xcrun simctl io booted screenshot /path/screen.png
```
Then open both images and compare. These `simctl` subcommands and the bundle identifier (`in.mealloop.app`, a placeholder in `ios/MealLoop.xcodeproj`) were not run when this file was written (the authoring session had no macOS). Confirm with `xcrun simctl help` on first use and correct this file if one differs.

## Reference images and scale
- The pack images under `design/reference/*/images/` are 640 x 1304 px: a 320 x 652 pt sketch shown at 2x whose screen is **292 pt wide**. Multiply every size read from them by **1.346** to get the 393 pt design (pack READMEs, for example `design/reference/kitchen_2026-10/README.md`).
- Images under `design/audit/export*/` are 2x of the 393 pt design (for example `design/audit/export/a01_today_now.png` is 786 x 1704 px).
- `MLSize.designWidth` is 393; `OrbitBackground` already scales by it.
- `design/tokens.json` is from the first design system and is out of date. Never take values from it.

## Design language (verified)
- Canvas is the flat warm `MLColor.canvas` with the faint dot texture and the Orbit backdrop (`OrbitBackground`) on every screen. Exceptions are in the pack spec (for example the full-lime result screens, and the dark recording screens).
- **Lime is the only accent.** Never lime text on a light background, never lime card fills; on light surfaces lime appears only as an ink-outlined chip or arc. At most three lime elements per frame beyond the backdrop. Black (`heroBackground`) cards and black primary buttons.
- **One primary action per screen.** Staff primary buttons are `MLSize.staffButton` (56 pt); every tap target is at least `MLSize.hit` (44 pt).
- On the staff screens, status is a small dot plus plain text, not a pill (`StatusText`). Status is never shown by colour alone: add an icon, a shape or a word (`prototype_contract.md`).
- Monospaced type only for numbers, times, IDs, codes and units. Body text is never below 12 pt (`MLType.meta`).
- Drill-in screens have the one standard Back control, a 44 pt round control with the system chevron, top-left; tab roots have none. Sheets have a grab handle and a Close (×). Read the exact rule in `design/audit/design_intent.md` (BackButton).
- Handle loading (skeleton), empty, error with retry, offline and stale states deliberately with the shared state views and `AsyncContentView`.
- Staff navigation is Home, Alerts and Me. Do not add a fourth tab.

## Forbidden
Generic dashboards and default list rows where the design is custom; arbitrary gradients, glass or blur effects; random icons or illustrations; a new visual style in the middle of a feature; invented colours, type sizes or spacing; default Apple layouts where the design is custom; duplicating a large screen per role; screenshots or exported images used as UI; placeholders presented as finished. **An effect is allowed when it appears in the approved reference** (for example the round glass Back control).

## Tokens and components
- Use the real tokens in `ios/MealLoop/DesignSystem/Tokens/`: `MLColor`, `MLType`, `MLSpacing`, `MLRadius`, `MLSize` (the last three are in `MLLayout.swift`). No hex values, font sizes or spacing literals in feature code.
- If a token is missing: stop, report it, and propose the smallest addition backed by a named reference image. Record anything measured rather than documented (see `docs/OPEN_DECISIONS.md`, T4).
- Search `ios/MealLoop/DesignSystem/Components/` first (for example `LimeActionButton`, `InkActionButton`, `HeroCard`, `QuietRow`, `StatusText`, `StaffHeader`, `StaffTabBar`, the state views). Compose from them. Reusable primitives belong in the DesignSystem; feature-specific views stay in their `Features/<Role>/` folder.
- Do not add an abstraction until two screens need it. Before changing a shared component, search every call site and check each affected screen against its reference.
- User-facing wording never contains developer terms such as "demo", "mock" or "simulated". The existing Debug-only badge and simulated-moment menu are developer tools (see `contracts-and-security.md`).
