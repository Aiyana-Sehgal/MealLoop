# Presenter accounts

For the person presenting the prototype. These accounts are not shown anywhere in the app.

**Use the `MealLoop Review` scheme.** All data is seeded in memory. Nothing here is a real account, and no backend is involved.

The one prototype password is `DemoSeed.prototypePassword` in `ios/MealLoop/Data/Demo/DemoSeed.swift`. It is deliberately not repeated here.

| Role | Sign in with | Email | Shown as | Lands on |
|---|---|---|---|---|
| Student | Sign in with SRM | none needed | Aarav | Student tabs (placeholder) |
| Super Admin | Staff sign in (see note) | `superadmin@mealloop.example` | SRM admin | Home and Me (placeholder) |
| Food Head / Admin | Staff sign in | `foodhead@mealloop.example` | Mess food head | Today, Students, Results, More (placeholder) |
| Supervisor | Staff sign in | `supervisor@mealloop.example` | Ravi | Staff tabs (placeholder Home) |
| Kitchen Staff | Staff sign in | `kitchen@mealloop.example` | AK | Staff tabs, **Kitchen Home** |
| Door Scanner | Staff sign in | `door@mealloop.example` | SK | Staff tabs (placeholder Home) |
| Pass Desk | Staff sign in | `passdesk@mealloop.example` | SK | Staff tabs (placeholder Home) |
| Vendor | Staff sign in | `vendor@mealloop.example` | Mess vendor | Home and Me (placeholder) |
| Guardian | Staff sign in | `guardian@mealloop.example` | Aarav's guardian | One page, no tabs (placeholder) |
| Warden | Staff sign in | `warden@mealloop.example` | Hostel warden | Queue, Out now, Escalated, History (placeholder) |
| Gate Security | Staff sign in | `gate@mealloop.example` | Main gate | Home and Me (placeholder) |

**Super Admin note:** Super Admin is meant to use SRM. The simulated SRM step has no real identity and always returns the student, so for the prototype this account also works on Staff sign in. See P-ENTRY-1 in `docs/OPEN_DECISIONS.md`.

**Switching roles:** sign out returns to Welcome, then sign in again. The app remembers nothing about an account, so every switch means typing the email and password.

**Kitchen Home in Review** always opens at the "during the meal" moment. The moment menu exists only in Debug.
