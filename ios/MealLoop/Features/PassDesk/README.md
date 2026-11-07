# PassDesk

Part 4d. Reference pack: `design/reference/pass_desk_2026-10/` (P01 to P17) and the exports in `design/audit/export_pass_desk/`. Verification and the reference table: `docs/verification/pass-desk/REPORT.md`.

Tabs Home, Alerts, Me. No camera: staff type the last 4 digits, compare the code and colour, then tap "Matches · record entry". A lookup never records.

| File | What |
|---|---|
| `PassDeskRootView.swift` | Root, tabs, routes, the outcome layer. Only a Pass Desk session reaches the screens. |
| `PassDeskHomeViewModel.swift` | Home, and `PassDeskCheckFlow`: lookup, compare, record. |
| `PassDeskHomeView.swift` | Home before, during and after the meal. |
| `PassDeskCheckSheet.swift` | Check this pass: fresh, changed, expired. |
| `PassDeskOutcomeView.swift` | Every end of a check. |
| `PassDeskTaskModels.swift`, `PassDeskTaskViews.swift` | Look up, request a new pass, requests, report a problem, open problems. |
| `PassDeskAlertsMeViews.swift` | SOS panel, Alerts, Me. |
| `PassDeskContent.swift`, `PassDeskCopy.swift` | Content types and all wording. |

Rules: the pass service decides; view models only follow its answers. Nothing records but `PassDeskCheckFlow.matches()`. Approved is never Done. SOS reuses `DoorSOSViewModel`, because the behaviour is the same by spec.
