# Review prototype pass: progress

Resumable checkpoints for the review-prototype pass. Newest last.

## Baseline (2026-11-11)

- Base: `origin/main` at `322f3e2` (detached worktree `MealLoop-review`).
- Scheme `MealLoop`, Debug; Xcode 27.2 (27B52).
- Simulator: iPhone 18 Pro Max, iOS 27.2 (440 × 956 pt). Small phone: iPhone SE (3rd generation) simulator.
- Physical iPhone 15 Pro: unavailable. Camera, haptics and device feel stay unverified.
- Baseline Debug build: succeeded. Launch: Welcome with the black "Demo data" pill (moment menu).
- The grouped "Demo states" sheet seen on the phone is in no local or remote ref, stash, dangling commit, worktree or
  local build. It is rebuilt here from the phone screenshots.

## Checkpoints

### 1. Getting started and demo navigation (simulator, iPhone 18 Pro Max, iOS 27.2)

- Computer use could not be granted in this session (the macOS permission panel interrupted the session twice), so
  Figma frames are read with targeted Figma MCP screenshots and the app is driven with the Simulator tool.
- Owner ruling (11 Nov, mid-run): the MS-0 "loop" pages (Sign in with SRM 1508:45, Verifying 1508:111, Is this you?
  1508:147) are removed. Staff sign in opens Choose your role (1508:235) directly.
- Student: Welcome (221:62499) → Getting your details (135:15587) → Home. Failure: Couldn't sign in with Try again
  (135:15825), a retry branch. Verified on the simulator.
- Staff: Welcome → Choose your role → What you do (sheet sized to content) → Password, Wrong (2 tries left), → Kitchen
  Home. "Sign in with email" under the roles keeps the email sign-in for Food Head, Super Admin, Vendor, Guardian,
  Warden and Gate (no frame draws it). Verified on the simulator.
- The floating "Demo data" pill and its moment menu are gone. A small Demo chip on Welcome and a "Demo states" row on
  every Me, You or More page (Guardian: chip at the top) open the Demo states sheet from the app root: Getting started
  first, then Switch role (keeps data). The sheet uses a native inline title, so rows scroll under it cleanly.
- Per-role state shortcuts are left out: every one of them (meal phases, SOS active, camera denied, offline) needs a
  reset or separate data.
- Shared clock: Debug and Review start at Wed 14 Aug, 7:00 AM and then run in real time (`RunningDemoClock`). Starting
  or closing a meal, approving the headcount and switching role no longer move it. Verified: Student answers breakfast,
  switch to Kitchen and back, the answer and the time are still there.
- Breakfast cutoff: breakfast stays open until its service ends (9:30 AM), PENDING the owner's per-meal cutoff decision,
  so Home · Not answered (221:62529) is true at 7:00. Lunch and dinner keep the owner's two-hour rule.
- Student Home at 7:00: "Breakfast today?" with I'm in, Skip, Entry QR. Swipe right → Remind me in 1 hr → Reminder set
  (8:00 AM) → Undo. Verified.

### 2. Student

- SOS: What's wrong (Report) no longer lists the red Urgent rows; their legacy camera and SOS Sent pages are deleted.
  "Unsafe or unwell? Use SOS" on What's wrong (Home, Meals, Community, Search) and on the dish feedback sheets opens
  SOS · new (2162:6) → camera → review → sent. Not good still opens the dish feedback sheet with its SOS link.
- Ratings: no time, attendance or meal-state gate in the repository or the UI; Good saves, Not good takes it back, and
  the saved rating is there on reopen (tests). The "rate after it ends" and "closed after 2 days" copy is removed.
- Outings: the app's outing source shares the running clock and starts with no requests and no earlier outings; only
  already-past warden history and guardian answers remain. Opening the Guardian, Warden or Gate page no longer jumps
  the clock. Verified: You · Outings is empty, New outing → Express Avenue Mall, Wed 14 Aug 6–9 PM → Sent, waiting for
  the guardian.

### 3. Admin and Super Admin

- Scope is enforced in the data layer already: `scopedAdmin` wraps every Admin repository with `AdminDataScope`
  (Food Head: own mess only, no People and access; Super Admin: all messes, and its sends reach the base as the Food
  Head role, so it may send any mess). Unchanged and covered by the Admin scope tests.
- Today: Super Admin keeps the four-mess grid and Needs you (2257:158261). Food Head: their mess tile and Needs you;
  the Answers card and the Headcount and Live meal rows are gone from Today (Answers stays on Students).
- Counts are named by field: the story meal's hero says Live forecast (or Cutoff forecast once answers close), the
  answers row says it is the sample roster, and Approve reads "Approve live forecast · 860".
- Send: both entry points (the Main tile's headcount page and another mess's page) open the same compact sheet with
  the count, meal and mess; a failure stays in the sheet for retry; both view models drop a second tap. Verified:
  North → Cancel → Send → tile shows Waiting; Main → Approve → Send 860 → Sent to vendor 7:01 AM, vendor Pending.
- Verification aid (Debug and Review only): launch argument `-demoRole <role>` opens that role's Home, as Switch role.
