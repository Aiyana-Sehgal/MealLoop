# Admin

Admin (Food head) app on page 12: Today, Students, Results, More and the round Search. Reference packs: design/reference/admin_redesign_2026-10/ and fix2_2026-10/.

Built: the root and tabs, Today (A01), the headcount pages (A02 and its Adjust sheet), Students (A06), Results (A04, A05, A07 to A10, F01, F02, F03) and More (A11 to A14, F04, F05). The Live meal, Safety case and See all pages that Today opens are still Coming soon from Today.

SIMULATED: the menu upload (no photo, no OCR), PDF and CSV export (a preview only, no file), reminders, announcements, invites and menu saves (stored for this run, delivered to nobody). The data comes from `AdminSeed`; the story meal is read from the live repositories.

Before building: read docs/REPOSITORY_STRUCTURE.md, use Domain models and repository protocols (never define new models here; the Admin read models are in `Domain/Admin*.swift`), take values from repositories (never hardcode demo data in views), and render states with AsyncContentView. Kitchen (Features/Kitchen) is the worked example.

Today and the headcount page share `AdminTodayViewModel`. Approve and send go through `HeadcountRepository`; the backend decides what is allowed and moves the clock.
