# MealLoop Admin and Super Admin: design pack (November 2026)

What is in this pack
- `images/`: 9 approved or liked screens as PNG at 2x (393 pt wide) and `FLOW_all_screens.png`, the map of how every screen connects. The type in the PNGs is a stand-in font (Inter and JetBrains Mono were not available when they were rendered); use the design system type in Figma and SwiftUI.
- `html/`: the source of each screen, so they can be opened in a browser and re-exported with the real fonts.
- `docs/SCREEN_MANIFEST.md`: every screen with its status (APPROVED, LIKED, DRAFT).
- `docs/DESIGN_SPEC.md`: the design language, per-screen content, sample data and data rules.
- `docs/FLOW.md`: the flow as a table (from, action, to, role).
- `prompt/COWORK_PROMPT_ADMIN_FULL.md`: the Cowork run that builds these in Figma.
- `prompt/CLAUDE_CODE_ADMIN_ADDENDUM.md`: what the iOS build must follow.

Roles: **Food Head (Admin)** runs one mess (Main). **Super Admin** sees all messes and manages people and access. They share the same screens and differ by scope.
People and access is out of scope: the existing Figma frames stay unchanged.
Rule: screens marked DRAFT have no approved image. Do not build them until the owner approves a mock.
