# Teammate test sheet

One page for a teammate who wants to try the MealLoop prototype before the review on 11 November 2026. It is an
interactive iOS prototype on seeded data: no backend, nothing is sent anywhere.

## 1. Get the code

The repository history is large, so clone only the code and documents:

```
git clone --filter=blob:none --no-checkout --depth 1 --no-tags https://github.com/VeeraaVikash/MealLoop.git
cd MealLoop
git sparse-checkout set --cone ios docs .github .claude
git checkout main
```

Use `main`: it is the only branch (owner ruling, 9 November; old branches are kept as `archive/*` tags, see
`docs/BRANCH_ARCHIVE.md`). Design images are not in this repository; they live in a separate design repository,
`MealLoop-design`, which is being set up.

## 2. Run it

1. Open `ios/MealLoop.xcodeproj` in Xcode.
2. Pick the scheme **MealLoop Review** (`docs/PRESENTER_ACCOUNTS.md`: "Use the MealLoop Review scheme") and any iPhone
   simulator.
3. Run (Cmd-R).

Xcode used by the verification reports: **Xcode 27.2 (27B52)** (`docs/verification/admin-final/REPORT.md`,
`docs/verification/admin-scopes/REPORT.md`, `docs/verification/pass-desk-simple/REPORT.md`). Other Xcode versions are
not verified.

## 3. Sign in

The accounts are in `docs/PRESENTER_ACCOUNTS.md` (Student uses **Sign in with SRM**; every other role uses **Staff
sign in** with its email). The one prototype password is `DemoSeed.prototypePassword` in
`ios/MealLoop/Data/Demo/DemoSeed.swift`; the presenter accounts document deliberately does not repeat it, and neither
does this sheet. It is a prototype value, not real authentication.

**Data resets on every launch.** Everything is in memory: a relaunch starts the story again at 7:00 AM
(`docs/PRESENTER_ACCOUNTS.md`, "Kitchen Home in Review"). To switch role, sign out and sign in again without
relaunching, or the story resets.

## 4. The story to test, in order

From the core-story walk in `docs/verification/integration/REPORT.md` section 3. Notes in *italics* are where the
re-run on 9 November (`docs/verification/staff-complete/REPORT.md`, R4) found the wording has since changed.

| # | Who | Do this | You should see |
|---|---|---|---|
| 1 | Student | Sign in with SRM, open lunch (Answer), I'm in, open the entry QR | "You're in for lunch · Change by 10 AM". At 7:00 AM the Home QR is breakfast's. *The QR now shows "Live" (owner decision OD-4).* |
| 2 | Food Head | Today, Review and approve, Approve 860, Send 860 to vendor, Send | "SENT TO VENDOR · 10:05 AM", 860. *The Today step is now called "Approve".* |
| 2b | Student | Sign in again | *Home says "Lunch answers closed · Cutoff 10 AM passed · your QR still works"; no Answer or Change.* |
| 3 | Supervisor | Start meal, confirm | "LIVE · 12:00 PM", 0 students entered, Close meal offered |
| 4 | Door Scanner | Type ID, keys 0 2 3 8 | "Recorded in" 0 → 1 |
| 5 | Kitchen, Supervisor | Kitchen sees the live count; report Steamed Rice almost out; the Supervisor opens it in Alerts | Kitchen row "Steamed Rice, almost out, Ravi saw it" |
| 6 | Supervisor, Kitchen | Close meal, confirm; Kitchen Record waste (8 dishes None left, plate waste 18 kg), Review and save, Save report | Supervisor "Closed · 2:00 PM", final entries 1; Kitchen "Report saved", Home shows Recorded |
| 7 | Supervisor, Admin | Open the waste report | Read only: 18 kg, no Save, Edit or Record. *The 9 November re-run confirmed the Supervisor half; Admin Results no longer has the "To check" filter the old walk used.* |

Other sample last-four digits for the door: 0238, 0412, 0377, 0190 (`docs/PRESENTER_ACCOUNTS.md`).

## 5. What is still "Coming soon"

The integration report's placeholder metric (6 November, `docs/verification/integration/REPORT.md` item 2) counted
9 of 32 tabs: Admin Search; Student Meals, Community, You and Search; Super Admin Home and Me; Vendor Home and Me.
Later reports changed this:

- Student: 0 destinations say Coming soon when signed in (`docs/verification/student-final/REPORT.md`, B7, run 2).
- Super Admin: a minimal Super Admin is built (Accounts, an account page, a simulated password reset;
  `docs/verification/admin-final/REPORT.md`, Part C).
- Warden, Guardian, Gate, Kitchen, Door Scanner, Pass Desk, Supervisor: 0 reachable placeholders
  (`docs/verification/outings-staff/REPORT.md`; live walk in `docs/verification/staff-complete/REPORT.md`, R4).
- Vendor: still Coming soon on `main` (`ios/MealLoop/Features/Vendor/VendorRootView.swift`); no Vendor report exists.

## 6. Report a problem

Open a GitHub issue with: the **role**, the **screen name**, what you did, what you expected, and a **screenshot**.

## 7. Branch rules

The owner's sessions push green commits straight to `main`, with CI (`.github/workflows/ios-ci.yml`) as the safety
net (owner ruling, 9 November). Teammates outside those sessions do not push to `main`: create a branch named
`type/scope-description` (for example `fix/kitchen-waste-total`; types `feat`, `fix`, `docs`, `design`, `chore`,
`refactor`, `test`, `spike`; `docs/BRANCHING.md`) and open a pull request. See `CONTRIBUTING.md`.
