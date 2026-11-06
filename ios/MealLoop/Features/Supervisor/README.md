# Supervisor

Part 4c. Reference pack: `design/reference/supervisor_2026-10/` (S00–S19) and the 45 exports in
`design/audit/export_supervisor/`. Verification and the reference table: `docs/verification/supervisor/REPORT.md`.

Tabs Home, Alerts, Me (`SupervisorRootView`). Meal history opens from Me only.

| File | What |
|---|---|
| `SupervisorRootView.swift` | Root, tabs, routes. Only a Supervisor session reaches the screens. |
| `SupervisorHomeView(Model).swift` | Not started / in service / closed, Start and Close meal dialogs, SOS tab. |
| `SupervisorAlertsView.swift` | SOS card, Shortages, Waste not recorded, all caught up. |
| `SupervisorShortageView.swift` | Shortage details and Mark resolved. |
| `SupervisorWasteReportView.swift` | The kitchen's waste report, read only. |
| `SupervisorSOSModel.swift`, `SupervisorSOSViews.swift` | SOS panel: claim, mark checked, Close case. |
| `SupervisorMeView.swift` | Me, follow-ups, Sign out. |
| `SupervisorHistoryViews.swift` | Meal history and past meal. |
| `SupervisorTaskViewModels.swift` | Alerts, shortage, waste, Me, history and past meal view models. |
| `SupervisorContent.swift` | Content types and the follow-ups every tab counts the same way. |
| `SupervisorCopy.swift`, `SupervisorFormat.swift` | All wording and Supervisor-only formatting. |
| `SupervisorComponents.swift` | Views only this role uses (status with an ink dot, task row, page header). |

Rules: starting and closing go through `MealStateRepository`, which drives every role and moves the story clock;
view models never decide a rule or move the clock. Closing resolves no shortage and completes no waste report.
Waste is read only (the repository refuses a Supervisor save). Only the Supervisor closes an SOS case.
