# Admin

Admin (Food head) app on page 12: Today, Students, Results, More and the round Search. Reference packs: design/reference/admin_redesign_2026-10/ and fix2_2026-10/.

Built: the root and tabs, Today (A01) and the headcount pages (A02 and its Adjust sheet). Students, Results and More are Coming soon until their parts land, as are the Live meal, Safety case and See all pages that Today opens.

Before building: read docs/REPOSITORY_STRUCTURE.md, use Domain models and repository protocols (never define new models here), take values from repositories (never hardcode demo data in views), and render states with AsyncContentView. Kitchen (Features/Kitchen) is the worked example.

Today and the headcount page share `AdminTodayViewModel`. Approve and send go through `HeadcountRepository`; the backend decides what is allowed and moves the clock.
