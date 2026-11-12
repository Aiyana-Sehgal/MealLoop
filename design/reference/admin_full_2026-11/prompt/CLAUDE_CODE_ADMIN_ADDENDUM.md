# Addendum for the Admin and Super Admin iOS build (use with the Admin completion prompt)

Source of truth: `design/reference/admin_full_2026-11/` (images, `docs/SCREEN_MANIFEST.md`, `docs/DESIGN_SPEC.md`, `docs/FLOW.md`). After the Cowork run, the Figma exports in `figma_exports/` replace the stand-in-font PNGs.
- **Build only APPROVED or LIKED screens** (SA01, SA02, AD03 to AD09). DRAFT screens (headcount page and sheets) stay as they are today until the owner approves a mock; do not redesign them.
- **One set of views, two scopes.** Food Head is scoped to Main; Super Admin sees all messes. Parameterise by scope; do not duplicate screens. Food Head: no search button, no People and access, one Main card on Today. Super Admin: search button, all four mess tiles, By mess, Skipped.
- **Components to add in the design system (one file each, reused everywhere):** `BentoTile` (kinds: hero black, action lime, standard white, dashed), `SegmentStrip` (4-segment progress), `StackedBar` (answered split), `StatusChip` (outlined, lime, dashed), `NeedsYouRow` (hairline row with pill), `RoundGoButton` (the ↗ control). Reuse the existing glass tab bar with a `showsSearch` parameter.
- **Data rules:** missing data is never zero; Main's Yes, No and Not sure counts are not available (explicit dashed tile); sample figures live only in the seed and are labelled as sample in code comments; reasons never use percentages.
- Verify every screen against its reference in the simulator and list differences; no claim of visual parity from a compile.

- **People and access: do not change it.** Keep the existing implementation and frames exactly as they are (the owner prefers the older design). Do not restyle it with the new bento components. Shared component changes apply to all screens that use them, never to one screen alone.
