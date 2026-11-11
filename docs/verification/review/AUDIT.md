# Review prototype audit

One row per screen or state checked in this pass. Simulator: iPhone 18 Pro Max, iOS 27.2 (440 pt), unless noted.
Captures are outside the repository in `~/mealloop-captures/review/`. Status: **Verified** (walked in the running
build), **Tested** (unit tests only), **Open** (known gap), **Unverified** (needs hardware or a service).

| Role | Screen or state | Figma frame | Swift file | Issue or match | Capture | Status |
|---|---|---|---|---|---|---|
| All | Launch | — | `App/AppEnvironment.swift` | Starts Wed 14 Aug 7:00 AM on a running clock; no time jumps | — | Verified |
| All | Demo entry | — | `Features/Demo/DemoEntryButton.swift` | Floating pill replaced by a Demo chip on Welcome and a row in Me, You or More | — | Verified |
| All | Demo states sheet | phone screenshots | `Features/Demo/DemoSheet.swift` | Getting started first, then Switch role; native inline title, rows clear it | — | Verified |
| All | Switch role (keeps data) | — | `Features/Demo/DemoSheet.swift` | Student answer and time kept across Kitchen and back | — | Verified |
| All | Release build | — | `#if DEMO_DATA \|\| REVIEW_DATA` | No demo strings in the Release binary | — | Verified |
| Student | Welcome | 221:62499 | `Features/Entry/EntryViews.swift` | Matches; Staff sign in added under SRM | — | Verified |
| Student | Getting your details | 135:15587 | `Features/Entry/EntryViews.swift` | Matches | — | Verified |
| Student | Sign in failed | 135:15825 | `Features/Entry/EntryViews.swift` | Error card and Try again, retry succeeds | — | Tested |
| Staff | MS-0 SRM pages | 1508:45, 1508:111, 1508:147 | — | Removed by owner ruling (11 Nov) | — | Verified |
| Staff | Choose your role | 1508:235 | `Features/StaffEntry/StaffEntryViews.swift` | Matches; Sign in with email link added | — | Verified |
| Staff | What you do | 2469:1927, 2529:4180, 2571:157, 2620:10628 | `Features/StaffEntry/StaffEntryViews.swift` | Sheet sized to content (was a fixed medium detent with a gap) | — | Verified |
| Staff | Password, Wrong | 2469:2102, 2469:2229 | `Features/StaffEntry/StaffEntryViews.swift` | Matches; 2 tries left after one wrong | — | Verified |
| Staff | Password Locked | 2469:2355 | `Features/StaffEntry/StaffEntryViews.swift` | Locks after 3 | — | Tested |
| Student | Home · Not answered | 221:62529 | `Features/Student/StudentHomeView.swift` | Breakfast unanswered at 7:00 with I'm in, Skip, Entry QR (seed and breakfast cutoff fixed) | student_home_221-62529_inter.png | Verified |
| Student | Swipe to remind | 2222:158038, 2222:158135 | `Features/Student/StudentReminderViews.swift` | Reveal, set (8:00 AM), Undo | — | Verified |
| Student | What's wrong | 221:63480 | `Features/Student/StudentReportView.swift` | Red Urgent rows and their camera and Sent pages deleted; SOS link added | — | Tested |
| Student | SOS | 2162:6 and 2162/2163 states | `Features/Student/StudentSOSViews.swift` | Only SOS route from feedback and Report | — | Tested |
| Student | SOS camera | 2162:405, 2162:493 | `Features/Student/StudentSOSViews.swift` | Needs a camera | — | Unverified |
| Student | Ratings | owner images 7 Nov | `Data/Demo/DemoFeedbackRatings.swift` | Time, attendance and meal-state gates removed; saved rating shows on reopen | — | Tested |
| Student | You · Outings | 1848:22270 | `Features/Student/StudentOutingViews.swift` | Starts with no current or earlier requests | — | Verified |
| Student | New outing → Sent | — | `Features/Student/StudentOutingViews.swift` | Request created on the shared clock | — | Verified |
| Student | Dark appearance | — | `App/MealLoopApp.swift` | Placeholders and glass back button unreadable; app now runs in Light | dark_new_outing_before.png, dark_new_outing_after.png | Verified |
| Student | Larger text | — | `Features/Student/StudentStyle.swift` | Student tokens are fixed sizes (as before this pass) | — | Open |
| Student | iPhone SE | 221:62529 | `Features/Student/StudentHomeView.swift` | Actions stay in view; lunch row wraps | — | Verified |
| Super Admin | Today | 2257:158261 | `Features/Admin/AdminTodayView.swift` | Four-mess grid and Needs you | — | Verified |
| Food Head | Today | 2257:158261 (single mess) | `Features/Admin/AdminTodayView.swift` | Answers card and Headcount and Live meal rows removed; Needs you was empty, now scoped | — | Verified |
| Admin | Headcount page | — | `Features/Admin/AdminHeadcountView.swift` | Counts named by field; "Approve live forecast · 860" | — | Verified |
| Admin | Send sheet | — | `Features/Admin/AdminHeadcountView.swift`, `AdminMessHeadcountView.swift` | One compact sheet for both entry points; cancel, send, tile refresh | — | Verified |
| Admin | Send failure, double tap | — | `DesignSystem/Components/ConfirmDialog.swift` | Error stays in sheet; second tap ignored | — | Tested |
| Vendor | Home sent → acknowledged | vendor_02, vendor_03 (approved refs) | `Features/Vendor/VendorHomeView.swift` | Receives the Food Head's 860; Acknowledge; card no longer leaves a gap | — | Verified |
| Supervisor | Home before, during | Mess Staff 732:2 | `Features/Supervisor/SupervisorHomeView.swift` | Start and Close at 7:00 with no jump | — | Verified |
| Supervisor | Alerts | Mess Staff 732:2 | `Features/Supervisor/SupervisorAlertsView.swift` | Summary card and earlier meals removed; shortages and waste not recorded only | — | Verified |
| Kitchen | Home after the meal | Mess Staff 732:2 | `Features/Kitchen/KitchenHomeView.swift` | Follows the Supervisor's close | — | Verified |
| Kitchen | Record waste | Mess Staff 732:2 | `Features/Kitchen/KitchenWasteViews.swift` | Draft, resume, units, validation, Check and save, Report saved | — | Verified |
| Kitchen | Alerts | Mess Staff 732:2 | `Features/Kitchen/KitchenAlertsMeViews.swift` | Summary card and earlier meals removed | — | Tested |
| Door Scanner | Home during | Mess Staff 732:2 | `Features/DoorScanner/DoorHomeView.swift` | Camera off, Type ID, recorded count | — | Verified |
| Door Scanner | Type the last 4 digits | Mess Staff 732:2 | `Features/DoorScanner/DoorEntrySheet.swift` | Lookup shows the match only; Record entry counts 1 | — | Verified |
| Door Scanner | Offline, unverified | — | `Features/DoorScanner` | Never shown as recorded | — | Tested |
| Pass Desk | Alerts | Mess Staff 732:2 | `Features/PassDesk/PassDeskAlertsMeViews.swift` | Summary card removed; SOS above Earlier | — | Tested |
| Guardian | Sign in, code | 1849:1679 | `Features/Guardian/GuardianEntryViews.swift` | Simulated SMS; Demo chip now on these pages | — | Verified |
| Guardian | Request | 1849:1679 | `Features/Guardian/GuardianRootView.swift` | Shows the student's request exactly; Reject sheet | — | Verified |
| Guardian | Accept video | 1849:1679 | `Features/Guardian/GuardianRecordViews.swift` | Needs a camera | — | Unverified |
| Warden | Queue | 1853:9 | `Features/Warden/WardenRootView.swift` | Empty until the guardian accepts | — | Verified |
| Warden, Gate | Approve, exit, return | 1853:9, 1857:137869 | `Data/Demo/InMemoryOutingCaseRepository.swift` | Full journey in order | — | Tested |
| All | Fonts | 01 Foundations | `DesignSystem/Tokens/MLFonts.swift` | Inter and JetBrains Mono bundled with OFL notices | student_home_221-62529_inter.png | Verified |
| All | Physical iPhone | — | — | iPhone 15 Pro unavailable: camera, haptics, device feel | — | Unverified |
