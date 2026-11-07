# MealLoop screen inventory

Generated on 2026-10-23 from the repository only (no Figma access in this session). Source of each row: the file → frame tables in `design/audit/export*/README.md` (every listed PNG exists), cross-checked against every `archive_index.md`, the run reports and `STATE.md`. Screen names reuse the export / reference-pack image names. Figma node IDs are copied only where an export README records them; nothing is guessed.

**How to read it**

- One row per exported frame (a screen or a distinct state). Frames that exist in Figma but were never exported are not listed one by one; see *Needs review*.
- *Status*: **Active** = current requirement from the latest pack or run. **Needs review** = conflicting or superseded-but-not-archived, owner to decide. **Archived** = on page 99 or replaced by a newer decision; *not a requirement*.
- *Shared component dependencies* are proposed from the Figma component names recorded in `STATE.md` and the run reports, matched by screen type. Confirm when building.
- *Proposed priority*: P0 = first vertical slice (student answers a meal, headcount, door scan, kitchen waste record, admin result, plus the staff entry and meal state they need); P1 = the rest of the active core roles; P2 = outings (Guardian, Warden, Gate, student outings); P3 = polish. **The owner decides.**
- *SwiftUI implementation status* starts at “Not started” and *Assigned owner* at “Unassigned”. “Code written, build and launch owner-reported” means Swift source exists on `feature/swiftui-foundation` and the owner reports it built and launched on their Mac; the screen's behaviour is not verified and the unit-test result is not yet recorded (see `docs/FOUNDATION_REPORT.md`).

## Active screens

### Shared staff entry (7)

| Role / feature area | Screen or state name | Figma reference (page and frame name, if documented) | Status | Shared component dependencies | SwiftUI implementation status | Assigned owner | Proposed priority |
|---|---|---|---|---|---|---|---|
| Shared staff entry | `D01_role_selection` | 09 Mess Staff · “MS-1 · Choose your role” (node 1508:235) | Active | OrbitBackground, RoleRow | Scaffold for navigation (copy matches export; layout not compared) | Unassigned | P0 (proposed) |
| Shared staff entry | `D03_password` | 09 Mess Staff · “DS-0 · Password — Door Scanner” (node 2469:2102) | Active | OrbitBackground, KeyPad, PasswordBoxes | Scaffold for navigation (copy matches export; layout not compared) | Unassigned | P0 (proposed) |
| Shared staff entry | `D03_password_wrong` | 09 Mess Staff · “DS-0 · Password — Wrong” (node 2469:2229) | Active | OrbitBackground, KeyPad, PasswordBoxes | Scaffold for navigation (copy matches export; layout not compared) | Unassigned | P0 (proposed) |
| Shared staff entry | `D03_password_locked` | 09 Mess Staff · “DS-0 · Password — Locked” (node 2469:2355) | Active | OrbitBackground, KeyPad, PasswordBoxes | Scaffold for navigation (copy matches export; layout not compared) | Unassigned | P0 (proposed) |
| Shared staff entry | `D03_password_pass_desk` | 09 Mess Staff · “DS-0 · Password — Pass Desk” (node 2469:2480) | Active | OrbitBackground, KeyPad, PasswordBoxes | Not started | Unassigned | P0 (proposed) |
| Shared staff entry | `D03_password_kitchen_staff` | 09 Mess Staff · “DS-0 · Password — Kitchen Staff” (node 2469:2607) | Active | OrbitBackground, KeyPad, PasswordBoxes | Scaffold for navigation (copy matches export; layout not compared) | Unassigned | P0 (proposed) |
| Shared staff entry | `D03_password_supervisor` | 09 Mess Staff · “DS-0 · Password — Supervisor” (node 2469:2734) | Active | OrbitBackground, KeyPad, PasswordBoxes | Not started | Unassigned | P0 (proposed) |

### Student (38)

| Role / feature area | Screen or state name | Figma reference (page and frame name, if documented) | Status | Shared component dependencies | SwiftUI implementation status | Assigned owner | Proposed priority |
|---|---|---|---|---|---|---|---|
| Student | `F05_student_notification_dinner_changed` | 04 Student Light · “Notifications · Dinner changed · new” (node 2320:168935) | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Student | `P01_notifications_circles` | 04 Student Light (07 prototype) · “Notifications” | Active | OrbitBackground | Not started | Unassigned | P3 (proposed) |
| Student | `P01_notifications_circles_offline` | 04 Student Light (07 prototype) · “Notifications · Offline” | Active | OrbitBackground, OfflineBanner | Not started | Unassigned | P3 (proposed) |
| Student | `P02_home_swipe_remind` | 04 Student Light (07 prototype) · “Home · Not answered · Swipe revealed · new” | Active | OrbitBackground, HeroCard, AnswerRow, TicketStrip, CrowdRow | Not started | Unassigned | P3 (proposed) |
| Student | `P02_home_swipe_remind_set` | 04 Student Light (07 prototype) · “Home · Not answered · Reminder set · new” | Active | OrbitBackground, HeroCard, AnswerRow, TicketStrip, CrowdRow | Not started | Unassigned | P3 (proposed) |
| Student | `P02_home_swipe_remind_fired` | 04 Student Light (07 prototype) · “Home · Not answered · Reminder fired · new” | Active | OrbitBackground, HeroCard, AnswerRow, TicketStrip, CrowdRow | Not started | Unassigned | P3 (proposed) |
| Student | `P02_home_lunch_row_swipe` | 04 Student Light (07 prototype) · “Home · Lunch row · Swipe revealed · new” | Active | OrbitBackground, HeroCard, AnswerRow, TicketStrip, CrowdRow | Not started | Unassigned | P3 (proposed) |
| Student | `P02_home_lunch_row_set` | 04 Student Light (07 prototype) · “Home · Lunch row · Reminder set · new” | Active | OrbitBackground, HeroCard, AnswerRow, TicketStrip, CrowdRow | Not started | Unassigned | P3 (proposed) |
| Student | `P04_special_pass_ticket` | 04 Student Light (07 prototype) · “Pass · Live 1” | Active | OrbitBackground, BigTicket | Not started | Unassigned | P3 (proposed) |
| Student | `P04_special_pass_ticket_used` | 04 Student Light (07 prototype) · “Pass · Used” | Active | OrbitBackground, BigTicket | Not started | Unassigned | P3 (proposed) |
| Student | `P04_special_pass_ticket_not_today` | 04 Student Light (07 prototype) · “Pass · Not today · new” | Active | OrbitBackground, BigTicket | Not started | Unassigned | P3 (proposed) |
| Student | `P04_juice_ticket` | 04 Student Light (07 prototype) · “Ticket · Juice” | Active | OrbitBackground, BigTicket | Not started | Unassigned | P3 (proposed) |
| Student | `Q1_credits_coupons` | 04 Student Light (07 prototype) · “Credits” | Active | OrbitBackground, BigTicket | Not started | Unassigned | P3 (proposed) |
| Student | `Q3_highlight_chip` | 04 Student Light (07 prototype) · “Meals · Wed 14 · Lunch” | Active | OrbitBackground | Not started | Unassigned | P3 (proposed) |
| Student | `01_sign_in` | 04 Student Light (07 prototype) · “Onboarding · Sign in” | Active | OrbitBackground | Not started | Unassigned | P0 (proposed) |
| Student | `02_getting_details` | 04 Student Light (07 prototype) · “Onboarding · Getting your details” | Active | OrbitBackground | Not started | Unassigned | P0 (proposed) |
| Student | `03_home` | 04 Student Light (07 prototype) · “Home (Wed 14 Aug, 7:00 AM)” | Active | OrbitBackground, HeroCard, AnswerRow, TicketStrip, CrowdRow | Not started | Unassigned | P0 (proposed) |
| Student | `04_home_top_card_cases` | 04 Student Light (07 prototype) · “HeroCard (page 03): In, Skipped, Not answered, QR available, with the texts used on Home · After cutoff / Skipped / Not answered / Mess closed (3064 × 634)” | Active | OrbitBackground, HeroCard, AnswerRow, TicketStrip, CrowdRow | Not started | Unassigned | P0 (proposed) |
| Student | `05_meals_lunch` | 04 Student Light (07 prototype) · “Meals · Wed 14 · Lunch” | Active | OrbitBackground, MealSegments4, DishTile, HighlightChip, DietMark | Not started | Unassigned | P0 (proposed) |
| Student | `06_meals_dinner` | 04 Student Light (07 prototype) · “Meals · Wed 14 · Dinner” | Active | OrbitBackground, MealSegments4, DishTile, HighlightChip, DietMark | Not started | Unassigned | P0 (proposed) |
| Student | `07_lunch_answer` | 04 Student Light (07 prototype) · “Answer · Lunch” | Active | OrbitBackground, MealSegments4, DishTile, HighlightChip, DietMark | Not started | Unassigned | P0 (proposed) |
| Student | `08_entry_qr` | 04 Student Light (07 prototype) · “Entry QR” | Active | OrbitBackground, EntryQRCard | Not started | Unassigned | P0 (proposed) |
| Student | `09_community_list` | 04 Student Light (07 prototype) · “Community” | Active | OrbitBackground, IssueCard | Not started | Unassigned | P1 (proposed) |
| Student | `10_community_issue` | 04 Student Light (07 prototype) · “Community · Issue” | Active | OrbitBackground, IssueCard | Not started | Unassigned | P1 (proposed) |
| Student | `11_feedback_step1_good_or_not` | 04 Student Light (07 prototype) · “Feedback · How was breakfast (sheet)” | Active | OrbitBackground, FaceButton, ProblemTile, SeveritySegmented | Not started | Unassigned | P1 (proposed) |
| Student | `12_feedback_step2_which_dish` | 04 Student Light (07 prototype) · “Feedback · Which dish (sheet)” | Active | OrbitBackground, FaceButton, ProblemTile, SeveritySegmented | Not started | Unassigned | P1 (proposed) |
| Student | `13_feedback_step3_whats_wrong` | 04 Student Light (07 prototype) · “Feedback · What's wrong · Sambar (sheet)” | Active | OrbitBackground, FaceButton, ProblemTile, SeveritySegmented | Not started | Unassigned | P1 (proposed) |
| Student | `14_my_feedback` | 04 Student Light (07 prototype) · “My feedback” | Active | OrbitBackground, FaceButton, ProblemTile, SeveritySegmented | Not started | Unassigned | P1 (proposed) |
| Student | `15_sos_choose_problem` | 04 Student Light (07 prototype) · “SOS” | Active | OrbitBackground, SOSEdgeTab, SOSPanel, ProblemOption, ProofCard, ProofChecks | Not started | Unassigned | P1 (proposed) |
| Student | `16_sos_camera_proof` | 04 Student Light (07 prototype) · “SOS · Camera (Dark)” | Active | OrbitBackground, SOSEdgeTab, SOSPanel, ProofCard, ProofChecks | Not started | Unassigned | P1 (proposed) |
| Student | `17_sos_review_proof` | 04 Student Light (07 prototype) · “SOS · Review” | Active | OrbitBackground, SOSEdgeTab, SOSPanel, ProofCard, ProofChecks | Not started | Unassigned | P1 (proposed) |
| Student | `18_sos_sent_with_proof` | 04 Student Light (07 prototype) · “SOS · Sent” | Active | OrbitBackground, SOSEdgeTab, SOSPanel, ProofCard, ProofChecks | Not started | Unassigned | P1 (proposed) |
| Student | `19_you` | 04 Student Light (07 prototype) · “You” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Student | `20_notifications` | 04 Student Light (07 prototype) · “Notifications” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Student | `21_credits` | 04 Student Light (07 prototype) · “Credits” | Active | OrbitBackground, BigTicket | Not started | Unassigned | P1 (proposed) |
| Student | `22_juice_ticket` | 04 Student Light (07 prototype) · “Ticket · Juice” | Active | OrbitBackground, BigTicket | Not started | Unassigned | P1 (proposed) |
| Student | `23_attendance` | 04 Student Light (07 prototype) · “Attendance” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Student | `24_spending_private` | 04 Student Light (07 prototype) · “Spending” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |

### Student · Outings (9)

| Role / feature area | Screen or state name | Figma reference (page and frame name, if documented) | Status | Shared component dependencies | SwiftUI implementation status | Assigned owner | Proposed priority |
|---|---|---|---|---|---|---|---|
| Student · Outings | `S01_student_outing_tracker_video` | 04 Student Light (07 prototype) · “Outing · Under warden review” (node 1848:22655) | Active | OrbitBackground, ClockDial, OutingRibbon, OutingPass | Not started | Unassigned | P2 (proposed) |
| Student · Outings | `S01_student_outing_tracker_photo_and_text` | 04 Student Light (07 prototype) · “Outing · Under warden review · Photo and text” (node 2396:2557) | Active | OrbitBackground, ClockDial, OutingRibbon, OutingPass | Not started | Unassigned | P2 (proposed) |
| Student · Outings | `S01_student_outing_tracker_by_call` | 04 Student Light (07 prototype) · “Outing · Under warden review · By call” (node 2396:2657) | Active | OrbitBackground, ClockDial, OutingRibbon, OutingPass | Not started | Unassigned | P2 (proposed) |
| Student · Outings | `S01_student_outing_guardian_said_no` | 04 Student Light (07 prototype) · “Outing · Guardian said no” (node 2396:2757) | Active | OrbitBackground, ClockDial, OutingRibbon, OutingPass | Not started | Unassigned | P2 (proposed) |
| Student · Outings | `S01_student_notification_guardian_answered` | 04 Student Light (07 prototype) · “Notifications · Guardian answered” (node 2396:2858) | Active | OrbitBackground, MealSegments4, DishTile, HighlightChip, DietMark, ClockDial, OutingRibbon, OutingPass | Not started | Unassigned | P2 (proposed) |
| Student · Outings | `25_outing_new_weekday` | 04 Student Light (07 prototype) · “New outing · Wed” | Active | OrbitBackground, ClockDial, OutingRibbon, OutingPass | Not started | Unassigned | P2 (proposed) |
| Student · Outings | `26_outing_new_weekend` | 04 Student Light (07 prototype) · “New outing · Sat” | Active | OrbitBackground, ClockDial, OutingRibbon, OutingPass | Not started | Unassigned | P2 (proposed) |
| Student · Outings | `27_outing_tracker` | 04 Student Light (07 prototype) · “Outing · Under warden review” | Active | OrbitBackground, ClockDial, OutingRibbon, OutingPass | Not started | Unassigned | P2 (proposed) |
| Student · Outings | `28_outing_pass` | 04 Student Light (07 prototype) · “Outing pass · Valid” | Active | OrbitBackground, ClockDial, OutingRibbon, OutingPass | Not started | Unassigned | P2 (proposed) |

### Admin (Food head) (87)

| Role / feature area | Screen or state name | Figma reference (page and frame name, if documented) | Status | Shared component dependencies | SwiftUI implementation status | Assigned owner | Proposed priority |
|---|---|---|---|---|---|---|---|
| Admin (Food head) | `A01_today` | 12 Admin Redesign · “Today · Lunch · new” | Active | OrbitBackground, AdminTabBar, DayLine, MessTile | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A01_today_dinner` | 12 Admin Redesign · “Today · Dinner · new” | Active | OrbitBackground, AdminTabBar, DayLine, MessTile | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A01_today_safety_case_open` | 12 Admin Redesign · “Today · Safety case open · new” | Active | OrbitBackground, AdminTabBar, DayLine, MessTile, SafetyRail, SafetyRailStep | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A01_today_offline` | 12 Admin Redesign · “Today · Offline · new” | Active | OrbitBackground, AdminTabBar, DayLine, MessTile, OfflineBanner | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A02_headcount_north` | 12 Admin Redesign · “Headcount · North · new” | Active | OrbitBackground, AdminTabBar, ChainStepper, VendorChip | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A02_headcount_sent` | 12 Admin Redesign · “Headcount · Sent · new” | Active | OrbitBackground, AdminTabBar, ChainStepper, VendorChip | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A02_headcount_vendor_replied` | 12 Admin Redesign · “Headcount · Vendor replied · new” | Active | OrbitBackground, AdminTabBar, ChainStepper, VendorChip | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A02_headcount_south_no_reply` | 12 Admin Redesign · “Headcount · South · No reply · new” | Active | OrbitBackground, AdminTabBar, ChainStepper, VendorChip | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A02_headcount_adjust_headcount_sheet` | 12 Admin Redesign · “Headcount · Adjust headcount (sheet) · new” | Active | OrbitBackground, AdminTabBar, ChainStepper, VendorChip | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A03_meal_live` | 12 Admin Redesign · “Live meal · Main · Rice low · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A03_meal_live_serving` | 12 Admin Redesign · “Live meal · Main · Serving · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A04_meal_report` | 12 Admin Redesign · “Meal report · Main · Wed lunch · new” | Active | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A04_meal_report_data_missing` | 12 Admin Redesign · “Meal report · Data missing · new” | Active | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A04_meal_report_make_change` | 12 Admin Redesign · “Meal report · Make it a change (sheet) · new” | Active | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A04_meal_report_tell_vendor_sheet` | 12 Admin Redesign · “Tell the vendor (sheet) · Meal report · new” | Active | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A05_safety_case` | 12 Admin Redesign · “Safety case · Open · new” | Active | OrbitBackground, AdminTabBar, SafetyRail, SafetyRailStep | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A05_safety_case_closed` | 12 Admin Redesign · “Safety case · Closed · new” | Active | OrbitBackground, AdminTabBar, SafetyRail, SafetyRailStep | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A06_students` | 12 Admin Redesign · “Students · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A06_students_remind_sheet` | 12 Admin Redesign · “Students · Remind (sheet) · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A06_students_feedback_sambar_too_salty` | 12 Admin Redesign · “Students · Feedback · Sambar too salty · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A06_students_community_long_wait_at_north` | 12 Admin Redesign · “Students · Community · Long wait at North · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A06_students_why_students_skip` | 12 Admin Redesign · “Students · Why students skip · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A07_results_left_over` | 12 Admin Redesign · “Results · Left over · new” | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A08_results_ran_out` | 12 Admin Redesign · “Results · Ran out · new” | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A07_results_find_meal` | 12 Admin Redesign · “Results · Find a meal · new” | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A07_results_safety_cases` | 12 Admin Redesign · “Results · Safety cases · new” | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip, SafetyRail, SafetyRailStep | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `A09_reason_fewer_came` | 12 Admin Redesign · “Reason · Fewer students came · new” | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A09_reason_didnt_like_dish` | 12 Admin Redesign · “Reason · Students didn't like a dish · new” | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A09_reason_raised_late` | 12 Admin Redesign · “Reason · Raised the headcount late · new” | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A09_reason_cant_tell` | 12 Admin Redesign · “Reason · Can't tell why · Left over · new” | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A09_reason_more_came` | 12 Admin Redesign · “Reason · More students came · new” | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A09_reason_last_30_minutes` | 12 Admin Redesign · “Reason · Most came in the last 30 minutes · new” | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A09_reason_reported_late` | 12 Admin Redesign · “Reason · It was reported late · new” | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip, ReportTicket, StatBars | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A09_reason_cant_tell_ran_out` | 12 Admin Redesign · “Reason · Can't tell why · Ran out · new” | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A10_check_next_time` | 12 Admin Redesign · “Check next time · Wednesday lunch · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A11_more` | 12 Admin Redesign · “More · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A11_more_announce_write` | 12 Admin Redesign · “Announce · Write · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A11_more_announce_confirm_sheet` | 12 Admin Redesign · “Announce · Confirm (sheet) · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A11_more_restyled_passes` | 12 Admin Redesign · “AD-6a · Special passes (Success) · restyled · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A11_more_restyled_menu_votes` | 12 Admin Redesign · “AD-5c · Menu voting (Success) · restyled · new” | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A11_more_restyled_rewards` | 12 Admin Redesign · “AD-6c · Rewards (Success) · restyled · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A11_more_restyled_spare_food_accepted` | 12 Admin Redesign · “AD-6d · Surplus (Accepted) · restyled · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A11_more_restyled_history` | 12 Admin Redesign · “AD-7d · Audit log (Success) · restyled · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A12_weekly_menu` | 12 Admin Redesign · “Weekly menu · Published · new” | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A12_weekly_menu_check_thu_15` | 12 Admin Redesign · “Weekly menu · Check Thu 15 · new” | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A13_people_access` | 12 Admin Redesign · “People and access · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `A14_outings_admin` | 12 Admin Redesign · “Outings · Admin · new” | Active | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F01_results_to_check` | 12 Admin Redesign · “Results · To check · new” (node 2307:6) | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `F01_results_to_check_meal_report_tue_dinner` | 12 Admin Redesign · “Meal report · Main · Tue dinner · new” (node 2307:165877) | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip, ReportTicket, StatBars | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `F01_results_to_check_north_scanner` | 12 Admin Redesign · “Check next time · North scanner · new” (node 2307:165978) | Active | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P0 (proposed) |
| Admin (Food head) | `F02_weekly_report_export` | 12 Admin Redesign · “Weekly report · This week · new” (node 2308:112) | Active | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F02_weekly_report_last_week` | 12 Admin Redesign · “Weekly report · Last week · new” (node 2308:279) | Active | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F02_weekly_report_month` | 12 Admin Redesign · “Weekly report · Month · new” (node 2308:429) | Active | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F02_weekly_report_preparing` | 12 Admin Redesign · “Weekly report · Preparing · new” (node 2311:6) | Active | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F02_weekly_report_report_ready_sheet` | 12 Admin Redesign · “Weekly report · Report ready (sheet) · new” (node 2311:300) | Active | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F02_weekly_report_csv_saved` | 12 Admin Redesign · “Weekly report · CSV saved (toast) · new” (node 2311:104) | Active | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F02_weekly_report_pdf_saved` | 12 Admin Redesign · “Weekly report · PDF saved (toast) · new” (node 2311:202) | Active | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F02_weekly_report_vendor_summary_sheet` | 12 Admin Redesign · “Tell the vendor (sheet) · Weekly summary · new” (node 2311:549) | Active | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F03_report_pdf_page1` | 12 Admin Redesign · “Report PDF · Page 1” (node 2310:368) | Active | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F03_report_pdf_page2` | 12 Admin Redesign · “Report PDF · Page 2” (node 2310:433) | Active | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Lunch · new” (node 2313:6) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_breakfast` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Breakfast · new” (node 2313:166457) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_snacks` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Snacks · new” (node 2313:166736) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_dinner` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Dinner · new” (node 2313:166911) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_highlight_changed` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Lunch · Highlight changed · new” (node 2313:167284) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_veg_changed` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Lunch · Veg changed · new” (node 2313:167566) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_reordering` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Lunch · Reordering · new” (node 2313:167848) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_reordered` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Lunch · Reordered · new” (node 2321:6) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_swipe_to_delete` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Lunch · Swipe to delete · new” (node 2313:168130) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_deleted` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Lunch · Deleted · new” (node 2313:168417) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_copied_last_thursday` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Lunch · Copied last Thursday · new” (node 2313:168692) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_tell_students_off` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Lunch · Tell students off · new” (node 2313:168976) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_saved` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Lunch · Saved · new” (node 2313:169258) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_saved_quietly` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Lunch · Saved quietly · new” (node 2313:169544) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_dish_added` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Lunch · Dish added · new” (node 2313:169830) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_word_checked` | 12 Admin Redesign · “Weekly menu · Edit day · Thu 15 Lunch · Word checked · new” (node 2313:170629) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_check_this_word_sheet` | 12 Admin Redesign · “Weekly menu · Edit day · Check this word (sheet) · new” (node 2313:170131) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F04_menu_edit_day_add_a_dish_sheet` | 12 Admin Redesign · “Weekly menu · Edit day · Add a dish (sheet) · new” (node 2313:170380) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F05_menu_weekly_menu_published` | 12 Admin Redesign · “Weekly menu · Published · new” (node 2278:240) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F05_menu_quick_change` | 12 Admin Redesign · “Weekly menu · Change today's dinner (sheet) · new” (node 2320:6) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F05_menu_quick_change_swap_pick` | 12 Admin Redesign · “Weekly menu · Swap a dish · Pick (sheet) · new” (node 2320:264) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F05_menu_quick_change_swap_replacement` | 12 Admin Redesign · “Weekly menu · Swap a dish · Replacement (sheet) · new” (node 2320:506) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F05_menu_quick_change_add_special` | 12 Admin Redesign · “Weekly menu · Add a special (sheet) · new” (node 2320:733) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F05_menu_quick_change_remove_pick` | 12 Admin Redesign · “Weekly menu · Remove a dish · Pick (sheet) · new” (node 2320:968) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F05_menu_quick_change_remove_confirm` | 12 Admin Redesign · “Weekly menu · Remove a dish · Confirm (sheet) · new” (node 2320:1210) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F05_menu_quick_change_send_preview` | 12 Admin Redesign · “Weekly menu · Send to students (sheet) · new” (node 2320:1430) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |
| Admin (Food head) | `F05_menu_quick_change_sent` | 12 Admin Redesign · “Weekly menu · Dinner change sent (toast) · new” (node 2320:1657) | Active | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) |

### Door Scanner (38)

| Role / feature area | Screen or state name | Figma reference (page and frame name, if documented) | Status | Shared component dependencies | SwiftUI implementation status | Assigned owner | Proposed priority |
|---|---|---|---|---|---|---|---|
| Door Scanner | `D02_what_you_do_sheet` | 09 Mess Staff · “DS-0 · What you do (sheet)” (node 2469:1927) | Active | OrbitBackground, WhatYouDoSheet | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D04_home_before_meal` | 09 Mess Staff · “DS-1 · Home — Before the meal” (node 2471:2234) | Active | OrbitBackground, StaffTabBar, ScannerCard, CountTile, TypeIdButton | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D05_home_during_meal` | 09 Mess Staff · “DS-1 · Home — During the meal” (node 2471:2437) | Active | OrbitBackground, StaffTabBar, ScannerCard, CountTile, TypeIdButton | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D05_home_during_meal_sos` | 09 Mess Staff · “DS-1 · Home — During · SOS active” (node 2471:2581) | Active | OrbitBackground, StaffTabBar, ScannerCard, CountTile, TypeIdButton, SOSEdgeTab, SOSPanel | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D05_home_camera_denied` | 09 Mess Staff · “DS-1 · Home — Camera denied” (node 2471:2868) | Active | OrbitBackground, StaffTabBar, ScannerCard, CountTile, TypeIdButton | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D05_home_low_light` | 09 Mess Staff · “DS-1 · Home — Low light” (node 2471:3003) | Active | OrbitBackground, StaffTabBar, ScannerCard, CountTile, TypeIdButton | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D05_home_offline` | 09 Mess Staff · “DS-1 · Home — Offline” (node 2471:3146) | Active | OrbitBackground, StaffTabBar, ScannerCard, CountTile, TypeIdButton, OfflineBanner | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D06_type_last4_typing` | 09 Mess Staff · “DS-2 · Type the last 4 digits — Typing” (node 2472:2645) | Active | OrbitBackground, KeyPad | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D06_type_last4_sheet` | 09 Mess Staff · “DS-2 · Type the last 4 digits — One match” (node 2472:2910) | Active | OrbitBackground, KeyPad | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D06_type_last4_several_matches` | 09 Mess Staff · “DS-2 · Type the last 4 digits — Several matches” (node 2472:3110) | Active | OrbitBackground, KeyPad | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D06_type_last4_no_match` | 09 Mess Staff · “DS-2 · Type the last 4 digits — No match” (node 2472:3317) | Active | OrbitBackground, KeyPad | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D06_type_last4_offline` | 09 Mess Staff · “DS-2 · Type the last 4 digits — Offline” (node 2482:186231) | Active | OrbitBackground, KeyPad, OfflineBanner | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D07_entry_recorded` | 09 Mess Staff · “DS-3 · Entry recorded” (node 2472:172058) | Active | OrbitBackground, ResultScreen | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D07_entry_recorded_no_response` | 09 Mess Staff · “DS-3 · Entry recorded — No meal response” (node 2472:172162) | Active | OrbitBackground, ResultScreen | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D08_already_scanned` | 09 Mess Staff · “DS-3 · Already scanned” (node 2472:172269) | Active | OrbitBackground, ResultScreen | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D09_qr_not_recognised` | 09 Mess Staff · “DS-3 · QR not recognised” (node 2472:172371) | Active | OrbitBackground, ResultScreen | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D09_wrong_meal` | 09 Mess Staff · “DS-3 · Wrong meal” (node 2472:172486) | Active | OrbitBackground, ResultScreen | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D10_cant_verify_offline` | 09 Mess Staff · “DS-3 · Can't check right now” (node 2472:172595) | Active | OrbitBackground, ResultScreen, OfflineBanner | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D11_report_a_problem` | 09 Mess Staff · “DS-5 · Report a problem” (node 2474:3212) | Active | OrbitBackground, ProblemOption | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D11_report_a_problem_sent_toast` | 09 Mess Staff · “DS-5 · Report a problem — Sent to Ravi (toast)” (node 2474:3359) | Active | OrbitBackground, ProblemOption | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D12_home_meal_ended` | 09 Mess Staff · “DS-1 · Home — After the meal” (node 2471:2732) | Active | OrbitBackground, StaffTabBar, ScannerCard, CountTile, TypeIdButton | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D12_meal_ended_during_scan` | 09 Mess Staff · “DS-3 · Meal ended during a scan” (node 2471:3284) | Active | OrbitBackground, ScannerCard, CountTile, TypeIdButton | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D13_sos_panel_not_claimed` | 09 Mess Staff · “DS-7 · SOS panel — Not claimed” (node 2476:3498) | Active | OrbitBackground, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D14_sos_panel_claimed` | 09 Mess Staff · “DS-7 · SOS panel — Claimed by you” (node 2476:3747) | Active | OrbitBackground, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D14_home_sos_claimed` | 09 Mess Staff · “DS-7 · Home — During · SOS claimed by you” (node 2476:3925) | Active | OrbitBackground, StaffTabBar, ScannerCard, CountTile, TypeIdButton, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D14_home_marked_as_checked` | 09 Mess Staff · “DS-7 · Home — Marked as checked (toast)” (node 2476:4075) | Active | OrbitBackground, StaffTabBar, ScannerCard, CountTile, TypeIdButton | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D15_entered_without_voting` | 09 Mess Staff · “DS-6 · Entered without voting” (node 2474:3748) | Active | OrbitBackground | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D15_entered_without_voting_during` | 09 Mess Staff · “DS-6 · Entered without voting — During the meal” (node 2474:3886) | Active | OrbitBackground, ScannerCard, CountTile, TypeIdButton | Not started | Unassigned | P0 (proposed) |
| Door Scanner | `D16_open_problems` | 09 Mess Staff · “DS-6 · Open problems” (node 2474:3490) | Active | OrbitBackground, ProblemOption | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D16_open_problems_after_report` | 09 Mess Staff · “DS-6 · Open problems — After your report” (node 2474:3613) | Active | OrbitBackground, ProblemOption | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D17_alerts` | 09 Mess Staff · “DS-8 · Alerts — SOS active (pack v2)” (node 2512:3778) | Active | OrbitBackground, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D17_alerts_sos_claimed` | 09 Mess Staff · “DS-8 · Alerts — SOS claimed by you” (node 2512:172793) | Active | OrbitBackground, SOSEdgeTab, SOSPanel, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D17_alerts_sos_checked` | 09 Mess Staff · “DS-8 · Alerts — SOS checked by you” (node 2512:172948) | Active | OrbitBackground, SOSEdgeTab, SOSPanel, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D17_alerts_during_meal` | 09 Mess Staff · “DS-8 · Alerts — During the meal” (node 2512:173100) | Active | OrbitBackground, ScannerCard, CountTile, TypeIdButton, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D17_alerts_after_meal` | 09 Mess Staff · “DS-8 · Alerts — After the meal (See all)” (node 2512:173241) | Active | OrbitBackground, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D17_alerts_all` | 09 Mess Staff · “DS-8 · All alerts” (node 2512:173386) | Active | OrbitBackground, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D17_alerts_empty` | 09 Mess Staff · “DS-8 · Alerts — Empty” (node 2512:173545) | Active | OrbitBackground, AlertRow, SOSAlertCard, EmptyStateView | Not started | Unassigned | P1 (proposed) |
| Door Scanner | `D18_me` | 09 Mess Staff · “DS-8 · Me (pack v2)” (node 2512:173663) | Active | OrbitBackground, StaffMeHeader, QuietRow | Not started | Unassigned | P1 (proposed) |

### Pass Desk (46)

| Role / feature area | Screen or state name | Figma reference (page and frame name, if documented) | Status | Shared component dependencies | SwiftUI implementation status | Assigned owner | Proposed priority |
|---|---|---|---|---|---|---|---|
| Pass Desk | `P01_what_you_do_sheet` | 09 Mess Staff · “PD-0 · What you do (sheet)” | Active | OrbitBackground, WhatYouDoSheet | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P02_home_before_meal` | 09 Mess Staff · “PD-1 · Home — Before the meal” | Active | OrbitBackground, StaffTabBar, HomeKeypad, CodeCard | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P03_home_during_meal` | 09 Mess Staff · “PD-1 · Home — During the meal” | Active | OrbitBackground, StaffTabBar, HomeKeypad, CodeCard | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P03_home_typing_1` | 09 Mess Staff · “PD-1 · Home — Typing · 1 digit” | Active | OrbitBackground, StaffTabBar, HomeKeypad, CodeCard | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P03_home_typing_2` | 09 Mess Staff · “PD-1 · Home — Typing · 2 digits” | Active | OrbitBackground, StaffTabBar, HomeKeypad, CodeCard | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P03_home_typing_3` | 09 Mess Staff · “PD-1 · Home — Typing · 3 digits” | Active | OrbitBackground, StaffTabBar, HomeKeypad, CodeCard | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P03_home_student_not_found` | 09 Mess Staff · “PD-1 · Home — Student not found” | Active | OrbitBackground, StaffTabBar, HomeKeypad, CodeCard | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P03_home_offline` | 09 Mess Staff · “PD-1 · Home — Offline” | Active | OrbitBackground, StaffTabBar, HomeKeypad, CodeCard, OfflineBanner | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P13_home_meal_ended` | 09 Mess Staff · “PD-1 · Home — After the meal” | Active | OrbitBackground, StaffTabBar, HomeKeypad, CodeCard | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P03_home_during_42_of_214` | 09 Mess Staff · “PD-1 · Home — During · 42 of 214” | Active | OrbitBackground, StaffTabBar, HomeKeypad, CodeCard | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P13_meal_ended_while_checking` | 09 Mess Staff · “PD-3 · Meal ended while checking” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P04_check_this_pass_sheet` | 09 Mess Staff · “PD-2 · Check this pass — Code fresh” | Active | OrbitBackground, CodeCard, PassResultScreen | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P04_check_this_pass_code_changed` | 09 Mess Staff · “PD-2 · Check this pass — Code changed” | Active | OrbitBackground, CodeCard, PassResultScreen | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P04_check_this_pass_code_expired` | 09 Mess Staff · “PD-2 · Check this pass — Code expired” | Active | OrbitBackground, CodeCard, PassResultScreen | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P05_pass_verified` | 09 Mess Staff · “PD-3 · Pass verified” | Active | OrbitBackground, CodeCard, PassResultScreen | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P06_no_special_pass` | 09 Mess Staff · “PD-3 · No special pass” | Active | OrbitBackground, CodeCard, PassResultScreen | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P06_wrong_meal` | 09 Mess Staff · “PD-3 · Wrong meal” | Active | OrbitBackground, CodeCard, PassResultScreen | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P07_already_recorded` | 09 Mess Staff · “PD-3 · Already recorded” | Active | OrbitBackground, CodeCard, PassResultScreen | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P08_doesnt_match` | 09 Mess Staff · “PD-3 · Doesn't match” | Active | OrbitBackground, CodeCard, PassResultScreen | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `PD_cant_check_right_now` | 09 Mess Staff · “PD-3 · Can't check right now” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P17_look_up_student` | 09 Mess Staff · “PD-2 · Look up a student” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P17_look_up_valid` | 09 Mess Staff · “PD-2 · Look up a student — Valid” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P17_look_up_used` | 09 Mess Staff · “PD-2 · Look up a student — Used” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P17_look_up_no_pass` | 09 Mess Staff · “PD-2 · Look up a student — No pass” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P17_look_up_wrong_meal` | 09 Mess Staff · “PD-2 · Look up a student — Wrong meal” | Active | OrbitBackground, CodeCard, PassResultScreen | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P09_request_new_pass` | 09 Mess Staff · “PD-4 · Request a new pass” | Active | OrbitBackground, RequestRow | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P09_request_sent_toast` | 09 Mess Staff · “PD-4 · Request a new pass — Sent (toast)” | Active | OrbitBackground, RequestRow | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P10_new_pass_requests` | 09 Mess Staff · “PD-4 · New pass requests” | Active | OrbitBackground, RequestRow | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P11_report_a_problem` | 09 Mess Staff · “PD-5 · Report a problem” | Active | OrbitBackground, ProblemOption | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P11_report_sent_toast` | 09 Mess Staff · “PD-5 · Report a problem — Sent to Ravi (toast)” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P12_food_short_sheet` | 09 Mess Staff · “PD-5 · Which food is short? (sheet)” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P12_food_short_sent_toast` | 09 Mess Staff · “PD-5 · Food short — Sent (toast)” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `PD_open_problems_after_report` | 09 Mess Staff · “PD-6 · Open problems — After your report” | Active | OrbitBackground, ProblemOption | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `PD_open_problems_food_short` | 09 Mess Staff · “PD-6 · Open problems — Food short” | Active | OrbitBackground, ProblemOption | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `PD_open_problems_none` | 09 Mess Staff · “PD-6 · Open problems — None” | Active | OrbitBackground, ProblemOption | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P15_home_with_sos_tab` | 09 Mess Staff · “PD-7 · Home — During · SOS active” | Active | OrbitBackground, StaffTabBar, HomeKeypad, CodeCard, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P16_sos_panel` | 09 Mess Staff · “PD-7 · SOS panel — Not claimed” | Active | OrbitBackground, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P16_sos_panel_claimed` | 09 Mess Staff · “PD-7 · SOS panel — Claimed by you” | Active | OrbitBackground, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P15_home_sos_claimed` | 09 Mess Staff · “PD-7 · Home — During · SOS claimed by you” | Active | OrbitBackground, StaffTabBar, HomeKeypad, CodeCard, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P15_home_marked_as_checked` | 09 Mess Staff · “PD-7 · Home — Marked as checked (toast)” | Active | OrbitBackground, StaffTabBar, HomeKeypad, CodeCard | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P14_alerts_sos_active` | 09 Mess Staff · “PD-8 · Alerts — SOS active” | Active | OrbitBackground, SOSEdgeTab, SOSPanel, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P14_alerts_sos_claimed` | 09 Mess Staff · “PD-8 · Alerts — SOS claimed by you” | Active | OrbitBackground, SOSEdgeTab, SOSPanel, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P14_alerts_sos_checked` | 09 Mess Staff · “PD-8 · Alerts — SOS checked by you” | Active | OrbitBackground, SOSEdgeTab, SOSPanel, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P14_alerts` | 09 Mess Staff · “PD-8 · Alerts” | Active | OrbitBackground, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `P14_alerts_empty` | 09 Mess Staff · “PD-8 · Alerts — Empty” | Active | OrbitBackground, AlertRow, SOSAlertCard, EmptyStateView | Not started | Unassigned | P1 (proposed) |
| Pass Desk | `PD_me` | 09 Mess Staff · “PD-8 · Me” | Active | OrbitBackground, StaffMeHeader, QuietRow | Not started | Unassigned | P1 (proposed) |

### Kitchen (69)

| Role / feature area | Screen or state name | Figma reference (page and frame name, if documented) | Status | Shared component dependencies | SwiftUI implementation status | Assigned owner | Proposed priority |
|---|---|---|---|---|---|---|---|
| Kitchen | `K00_what_you_do_sheet` | 09 Mess Staff · “KS-0 · What you do (sheet)” | Active | OrbitBackground, WhatYouDoSheet | Scaffold for navigation (copy matches export; layout not compared) | Unassigned | P0 (proposed) |
| Kitchen | `K01_home_before_meal` | 09 Mess Staff · “KS-1 · Home — Before the meal” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText | Code written, build and launch owner-reported (see FOUNDATION_REPORT) | Unassigned | P0 (proposed) |
| Kitchen | `K01b_home_forecast_loading` | 09 Mess Staff · “KS-1 · Home — Forecast loading” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText, AsyncContentView (loading) | Generic loading state only (AsyncContentView) | Unassigned | P0 (proposed) |
| Kitchen | `K01c_home_forecast_stale` | 09 Mess Staff · “KS-1 · Home — Forecast stale” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText, StaleNote | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K01d_home_forecast_not_ready` | 09 Mess Staff · “KS-1 · Home — Forecast not ready” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K02_home_during_meal` | 09 Mess Staff · “KS-1 · Home — During the meal” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText | Code written, build and launch owner-reported (see FOUNDATION_REPORT) | Unassigned | P0 (proposed) |
| Kitchen | `K02b_home_entries_stale` | 09 Mess Staff · “KS-1 · Home — Entries stale” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText, StaleNote | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K02c_home_offline` | 09 Mess Staff · “KS-1 · Home — Offline” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText, OfflineBanner | Generic offline state only (AsyncContentView) | Unassigned | P0 (proposed) |
| Kitchen | `K03_home_during_shortage_reported` | 09 Mess Staff · “KS-1 · Home — Shortage sent” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText, ShortageRow, ShortageChips (sheet) | Code written, build and launch owner-reported (see FOUNDATION_REPORT) | Unassigned | P0 (proposed) |
| Kitchen | `K03b_home_two_shortage_reports` | 09 Mess Staff · “KS-1 · Home — Two shortage reports” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText, ShortageRow, ShortageChips (sheet) | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K03c_shortage_reports` | 09 Mess Staff · “KS-1 · Shortage reports” | Active | OrbitBackground, ShortageRow, ShortageChips (sheet) | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K05_home_meal_ended` | 09 Mess Staff · “KS-1 · Home — After · Not started” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText | Code written, build and launch owner-reported (see FOUNDATION_REPORT) | Unassigned | P0 (proposed) |
| Kitchen | `K16_home_meal_ended_draft` | 09 Mess Staff · “KS-1 · Home — After · Draft” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K15_home_meal_ended_recorded` | 09 Mess Staff · “KS-1 · Home — After · Recorded” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K17_menu_for_lunch` | 09 Mess Staff · “KS-1 · Menu for Lunch” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K04g_meal_ended_while_reporting` | 09 Mess Staff · “KS-1 · Meal ended while reporting” | Active | OrbitBackground | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K04_report_shortage_sheet` | 09 Mess Staff · “KS-2 · Which food is short? — Steamed Rice, almost out” | Active | OrbitBackground, ShortageRow, ShortageChips (sheet) | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K04b_report_shortage_sheet_empty` | 09 Mess Staff · “KS-2 · Which food is short?” | Active | OrbitBackground, ShortageRow, ShortageChips (sheet), EmptyStateView | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K04c_report_shortage_add_note` | 09 Mess Staff · “KS-2 · Which food is short? — Add a note” | Active | OrbitBackground, ShortageRow, ShortageChips (sheet) | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K04d_shortage_sent_toast` | 09 Mess Staff · “KS-2 · Sent to Ravi (toast)” | Active | OrbitBackground, ShortageRow, ShortageChips (sheet) | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K03d_home_shortage_seen` | 09 Mess Staff · “KS-1 · Home — Shortage seen” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText, ShortageRow, ShortageChips (sheet) | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K03e_home_shortage_couldnt_send` | 09 Mess Staff · “KS-1 · Home — Shortage couldn't send” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText, ShortageRow, ShortageChips (sheet) | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K04e_report_shortage_again` | 09 Mess Staff · “KS-2 · Which food is short? — Steamed Rice again” | Active | OrbitBackground, ShortageRow, ShortageChips (sheet) | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K04f_already_reported` | 09 Mess Staff · “KS-2 · Already reported” | Active | OrbitBackground | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K06_record_waste` | 09 Mess Staff · “KS-3 · Record waste — Draft” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K06b_record_waste_not_started` | 09 Mess Staff · “KS-3 · Record waste — Not started” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K07_enter_quantity_sheet` | 09 Mess Staff · “KS-3 · Enter a quantity — Veg Pulao” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K06c_record_waste_pulao_entered` | 09 Mess Staff · “KS-3 · Record waste — Veg Pulao entered” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K06d_record_waste_pulao_none_left` | 09 Mess Staff · “KS-3 · Record waste — Veg Pulao none left” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K06e_record_waste_pulao_not_made` | 09 Mess Staff · “KS-3 · Record waste — Veg Pulao not made” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K07b_enter_quantity_pieces` | 09 Mess Staff · “KS-3 · Enter a quantity — Chappathi” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K06f_record_waste_all_entered` | 09 Mess Staff · “KS-3 · Record waste — All entered” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K07c_quantity_over_limit` | 09 Mess Staff · “KS-3 · Enter a quantity — Over limit” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K07d_quantity_not_a_number` | 09 Mess Staff · “KS-3 · Enter a quantity — Not a number” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K07e_quantity_negative` | 09 Mess Staff · “KS-3 · Enter a quantity — Negative” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K08_check_and_save` | 09 Mess Staff · “KS-3 · Check and save” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K08b_check_and_save_blocked` | 09 Mess Staff · “KS-3 · Check and save — Enter 2 more” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K08c_report_saved` | 09 Mess Staff · “KS-3 · Report saved” | Active | OrbitBackground | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K06g_save_as_draft_prompt` | 09 Mess Staff · “KS-3 · Save this as a draft?” | Active | OrbitBackground | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K06h_add_a_dish` | 09 Mess Staff · “KS-3 · Add a dish” | Active | OrbitBackground | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K06i_record_waste_dish_added` | 09 Mess Staff · “KS-3 · Record waste — Poriyal added” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K11_meal_history` | 09 Mess Staff · “KS-4 · Meal history” | Active | OrbitBackground, HistoryRow, StatusText | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K11b_meal_history_after_lunch` | 09 Mess Staff · “KS-4 · Meal history — After Lunch” | Active | OrbitBackground, HistoryRow, StatusText | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K11c_meal_history_after_lunch_not_recorded` | 09 Mess Staff · “KS-4 · Meal history — After Lunch, not recorded” | Active | OrbitBackground, HistoryRow, StatusText | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K11d_meal_history_empty` | 09 Mess Staff · “KS-4 · Meal history — Empty” | Active | OrbitBackground, HistoryRow, StatusText, EmptyStateView | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K11e_meal_history_loading` | 09 Mess Staff · “KS-4 · Meal history — Loading” | Active | OrbitBackground, HistoryRow, StatusText, AsyncContentView (loading) | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K11f_meal_history_error` | 09 Mess Staff · “KS-4 · Meal history — Error” | Active | OrbitBackground, HistoryRow, StatusText | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K09_past_meal_not_recorded` | 09 Mess Staff · “KS-4 · Past meal — Not recorded” | Active | OrbitBackground, HistoryRow, StatusText | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K09b_record_waste_tue_dinner` | 09 Mess Staff · “KS-3 · Record waste — Tue 13 Dinner” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K10_past_meal_recorded` | 09 Mess Staff · “KS-4 · Past meal — Recorded” | Active | OrbitBackground, HistoryRow, StatusText | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K10b_edit_report_breakfast` | 09 Mess Staff · “KS-3 · Edit report — Wed 14 Breakfast” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K10c_check_and_save_breakfast` | 09 Mess Staff · “KS-3 · Check and save — Wed 14 Breakfast” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K18_past_meal_edit_closed` | 09 Mess Staff · “KS-4 · Past meal — Editing closed” | Active | OrbitBackground, HistoryRow, StatusText | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K15b_today_lunch_recorded` | 09 Mess Staff · “KS-4 · Today · Lunch — Recorded” | Active | OrbitBackground | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K15c_edit_report_lunch` | 09 Mess Staff · “KS-3 · Edit report — Wed 14 Lunch” | Active | OrbitBackground | Not started | Unassigned | P0 (proposed) |
| Kitchen | `K12_alerts` | 09 Mess Staff · “KS-5 · Alerts” | Active | OrbitBackground, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K12b_alerts_during` | 09 Mess Staff · “KS-5 · Alerts — During the meal” | Active | OrbitBackground, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K12c_alerts_sos_active` | 09 Mess Staff · “KS-5 · Alerts — SOS active” | Active | OrbitBackground, SOSEdgeTab, SOSPanel, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K12d_alerts_empty` | 09 Mess Staff · “KS-5 · Alerts — Empty” | Active | OrbitBackground, AlertRow, SOSAlertCard, EmptyStateView | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K12e_alerts_error` | 09 Mess Staff · “KS-5 · Alerts — Error” | Active | OrbitBackground, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K12f_food_short_at_pass_desk` | 09 Mess Staff · “KS-5 · Food short at the pass desk” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K13_me` | 09 Mess Staff · “KS-5 · Me” | Active | OrbitBackground, StaffMeHeader, QuietRow | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K14_record_waste_with_sos_tab` | 09 Mess Staff · “KS-3 · Record waste — SOS tab” | Active | OrbitBackground, DishRow, QuantitySheet, KeyPad, StatusText, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K14b_home_sos_active` | 09 Mess Staff · “KS-1 · Home — SOS active” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K14c_sos_panel_not_claimed` | 09 Mess Staff · “KS-5 · SOS panel — Not claimed” | Active | OrbitBackground, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K14d_sos_panel_claimed` | 09 Mess Staff · “KS-5 · SOS panel — Claimed by you” | Active | OrbitBackground, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K14e_home_sos_claimed` | 09 Mess Staff · “KS-1 · Home — SOS claimed” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Kitchen | `K14f_home_marked_as_checked` | 09 Mess Staff · “KS-1 · Home — Marked as checked” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, QuietRow, StatusText | Not started | Unassigned | P1 (proposed) |
| Kitchen | `Kitchen_alerts_food_short_at_pass_desk` | 09 Mess Staff · “MS-E1 · Alerts (Kitchen Staff, shared) with the new card” | Active | OrbitBackground, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |

### Supervisor (45)

| Role / feature area | Screen or state name | Figma reference (page and frame name, if documented) | Status | Shared component dependencies | SwiftUI implementation status | Assigned owner | Proposed priority |
|---|---|---|---|---|---|---|---|
| Supervisor | `S00_what_you_do_sheet` | 09 Mess Staff · “SV-0 · What you do (sheet)” | Active | OrbitBackground, WhatYouDoSheet | Not started | Unassigned | P0 (proposed) |
| Supervisor | `S01_home_not_started` | 09 Mess Staff · “SV-1 · Home — Not started” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, FollowUpRow | Not started | Unassigned | P0 (proposed) |
| Supervisor | `S14_start_meal_dialog` | 09 Mess Staff · “SV-1 · Start this meal?” | Active | OrbitBackground, ConfirmDialog | Not started | Unassigned | P0 (proposed) |
| Supervisor | `S02_home_in_service` | 09 Mess Staff · “SV-1 · Home — In service” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, FollowUpRow | Not started | Unassigned | P0 (proposed) |
| Supervisor | `S03_home_in_service_sos_tab` | 09 Mess Staff · “SV-1 · Home — In service · SOS” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, FollowUpRow, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S15_close_meal_dialog` | 09 Mess Staff · “SV-1 · Close this meal?” | Active | OrbitBackground, ConfirmDialog | Not started | Unassigned | P0 (proposed) |
| Supervisor | `S06_home_closed` | 09 Mess Staff · “SV-1 · Home — Closed” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, FollowUpRow | Not started | Unassigned | P0 (proposed) |
| Supervisor | `S06b_home_closed_unavailable` | 09 Mess Staff · “SV-1 · Home — Closed · Unavailable” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, FollowUpRow | Not started | Unassigned | P0 (proposed) |
| Supervisor | `S02b_home_in_service_offline` | 09 Mess Staff · “SV-1 · Home — In service · Offline” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, FollowUpRow, OfflineBanner | Not started | Unassigned | P0 (proposed) |
| Supervisor | `S06c_home_closed_shortage_resolved` | 09 Mess Staff · “SV-1 · Home — Closed · Shortage resolved” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, FollowUpRow, SupervisorShortageRow | Not started | Unassigned | P0 (proposed) |
| Supervisor | `S07a_alerts_before_meal` | 09 Mess Staff · “SV-2 · Alerts — Before the meal” | Active | OrbitBackground, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S07b_alerts_during_meal` | 09 Mess Staff · “SV-2 · Alerts — During the meal” | Active | OrbitBackground, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S08_alerts_with_sos` | 09 Mess Staff · “SV-2 · Alerts — SOS active” | Active | OrbitBackground, SOSEdgeTab, SOSPanel, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S07_alerts_pending` | 09 Mess Staff · “SV-2 · Alerts — After the meal” | Active | OrbitBackground, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S07c_alerts_shortage_resolved` | 09 Mess Staff · “SV-2 · Alerts — Shortage resolved” | Active | OrbitBackground, SupervisorShortageRow, AlertRow, SOSAlertCard | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S09_alerts_empty` | 09 Mess Staff · “SV-2 · Alerts — All caught up” | Active | OrbitBackground, AlertRow, SOSAlertCard, EmptyStateView | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S12_shortage_details` | 09 Mess Staff · “SV-3 · Shortage details” | Active | OrbitBackground, SupervisorShortageRow | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S13_shortage_resolve_dialog` | 09 Mess Staff · “SV-3 · Mark shortage as resolved?” | Active | OrbitBackground, ConfirmDialog, SupervisorShortageRow | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S10_waste_report_read_only` | 09 Mess Staff · “SV-4 · Waste report — Tue 13 Lunch” | Active | OrbitBackground, WasteRow, StatusText | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S10b_waste_report_details_closed` | 09 Mess Staff · “SV-4 · Waste report — Tue 13 Lunch · Details closed” | Active | OrbitBackground, WasteRow, StatusText | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S10c_waste_report_lunch_wed_recorded` | 09 Mess Staff · “SV-4 · Waste report — Lunch Wed 14 · Recorded (first screen; the frame scrolls)” | Active | OrbitBackground, WasteRow, StatusText | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S11_waste_report_not_recorded` | 09 Mess Staff · “SV-4 · Waste report — Dinner Tue 13 · Not recorded” | Active | OrbitBackground, WasteRow, StatusText | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S11b_waste_report_lunch_wed_not_recorded` | 09 Mess Staff · “SV-4 · Waste report — Lunch Wed 14 · Not recorded” | Active | OrbitBackground, WasteRow, StatusText | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S04_sos_panel_not_taken` | 09 Mess Staff · “SV-5 · SOS panel — Not taken” | Active | OrbitBackground, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S04b_sos_panel_claimed_by_you` | 09 Mess Staff · “SV-5 · SOS panel — Claimed by you” | Active | OrbitBackground, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S03b_home_sos_claimed_by_you` | 09 Mess Staff · “SV-5 · Home — SOS claimed by you” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, FollowUpRow, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S05b_sos_panel_checked_by_supervisor` | 09 Mess Staff · “SV-5 · SOS panel — Checked by the supervisor” | Active | OrbitBackground, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S05_sos_panel_checked_close_case` | 09 Mess Staff · “SV-5 · SOS panel — Checked by the door” | Active | OrbitBackground, SOSEdgeTab, SOSPanel | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S05c_home_case_closed` | 09 Mess Staff · “SV-5 · Home — Case closed” | Active | OrbitBackground, StaffTabBar, LiveCountCard, MealProgressChip, FollowUpRow | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S16a_me_before_meal` | 09 Mess Staff · “SV-6 · Me — Before the meal” | Active | OrbitBackground, StaffMeHeader, QuietRow | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S16b_me_during_meal` | 09 Mess Staff · “SV-6 · Me — During the meal” | Active | OrbitBackground, StaffMeHeader, QuietRow | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S16_me` | 09 Mess Staff · “SV-6 · Me” | Active | OrbitBackground, StaffMeHeader, QuietRow | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S16c_me_shortage_resolved` | 09 Mess Staff · “SV-6 · Me — Shortage resolved” | Active | OrbitBackground, SupervisorShortageRow, StaffMeHeader, QuietRow | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S17_signout_dialog` | 09 Mess Staff · “SV-6 · Sign out?” | Active | OrbitBackground, ConfirmDialog | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S18_meal_history` | 09 Mess Staff · “SV-7 · Meal history” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S18b_meal_history_shortage_resolved` | 09 Mess Staff · “SV-7 · Meal history — Shortage resolved” | Active | OrbitBackground, SupervisorShortageRow | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S18c_meal_history_loading` | 09 Mess Staff · “SV-7 · Meal history — Loading” | Active | OrbitBackground, AsyncContentView (loading) | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S18d_meal_history_empty` | 09 Mess Staff · “SV-7 · Meal history — Empty” | Active | OrbitBackground, EmptyStateView | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S18e_meal_history_error` | 09 Mess Staff · “SV-7 · Meal history — Error” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S19_past_meal_summary` | 09 Mess Staff · “SV-7 · Past meal — Tue 13 · Lunch” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S19b_past_meal_wed_lunch` | 09 Mess Staff · “SV-7 · Past meal — Wed 14 · Lunch” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S19c_past_meal_wed_lunch_resolved` | 09 Mess Staff · “SV-7 · Past meal — Wed 14 · Lunch · Shortage resolved” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S19d_past_meal_wed_breakfast` | 09 Mess Staff · “SV-7 · Past meal — Wed 14 · Breakfast” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S19e_past_meal_tue_dinner` | 09 Mess Staff · “SV-7 · Past meal — Tue 13 · Dinner” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |
| Supervisor | `S19f_past_meal_mon_dinner_unavailable` | 09 Mess Staff · “SV-7 · Past meal — Mon 12 · Dinner” | Active | OrbitBackground | Not started | Unassigned | P1 (proposed) |

### Guardian (41)

| Role / feature area | Screen or state name | Figma reference (page and frame name, if documented) | Status | Shared component dependencies | SwiftUI implementation status | Assigned owner | Proposed priority |
|---|---|---|---|---|---|---|---|
| Guardian | `G00_guardian_consent` | 13 Guardian · “GV-00 · Before you record” (node 2387:1408) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G01_guardian_choose` | 13 Guardian · “GV-01 · Choose” (node 2387:1536) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G01_guardian_choose_about_sheet` | 13 Guardian · “GV-01 · About this outing (sheet)” (node 2387:1654) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G01_guardian_choose_ask_to_change_sheet` | 13 Guardian · “GV-01 · Ask to change (sheet)” (node 2387:1822) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G01_guardian_choose_language_sheet` | 13 Guardian · “GV-01 · Language (sheet)” (node 2387:2112) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G01_guardian_choose_deadline_passed` | 13 Guardian · “GV-01 · Deadline passed” (node 2387:2257) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G01_guardian_choose_already_answered` | 13 Guardian · “GV-01 · Already answered” (node 2387:2365) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G02_guardian_record` | 13 Guardian · “GV-02 · Record · Try 1 · 0:07” (node 2389:2244) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G02_guardian_record_ready` | 13 Guardian · “GV-02 · Record · Ready” (node 2389:2127) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G02_guardian_record_too_short` | 13 Guardian · “GV-02 · Record · Too short” (node 2389:2366) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G02_guardian_record_too_dark` | 13 Guardian · “GV-02 · Record · Too dark” (node 2389:2492) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G02_guardian_record_try2` | 13 Guardian · “GV-02 · Record · Try 2 · 0:07” (node 2389:2614) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G02_guardian_record_try3` | 13 Guardian · “GV-02 · Record · Try 3 · 0:07” (node 2389:2736) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G02_guardian_record_camera_blocked` | 13 Guardian · “GV-02 · Camera blocked” (node 2390:1937) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G02_guardian_record_uploading` | 13 Guardian · “GV-02 · Uploading” (node 2390:2059) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag, AsyncContentView (loading) | Not started | Unassigned | P2 (proposed) |
| Guardian | `G02_guardian_record_checking` | 13 Guardian · “GV-02 · Checking” (node 2390:2156) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G02_guardian_record_upload_failed` | 13 Guardian · “GV-02 · Upload failed” (node 2390:2572) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G03_guardian_retry` | 13 Guardian · “GV-03 · Retry · try 2 of 3” (node 2390:2264) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G03_guardian_retry_try3` | 13 Guardian · “GV-03 · Retry · try 3 of 3” (node 2390:2361) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G04_guardian_send_video` | 13 Guardian · “GV-04 · Send video to the warden” (node 2390:2458) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G05_guardian_photo_and_code` | 13 Guardian · “GV-05 · Photo and code” (node 2390:2673) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G06_guardian_sent` | 13 Guardian · “GV-06 · Sent” (node 2390:2786) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G06_guardian_sent_please_watch` | 13 Guardian · “GV-06 · Sent · Please watch” (node 2390:2894) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G06_guardian_sent_photo_and_text` | 13 Guardian · “GV-06 · Sent · Photo and text” (node 2390:3002) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G06_guardian_sent_call_requested` | 13 Guardian · “GV-06 · Sent · Call requested” (node 2390:3110) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G06_guardian_sent_rejected` | 13 Guardian · “GV-06 · Sent · Rejected” (node 2390:3216) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G06_guardian_sent_withdraw_sheet` | 13 Guardian · “GV-06 · Withdraw approval (sheet)” (node 2390:3320) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G06_guardian_sent_withdrawn` | 13 Guardian · “GV-06 · Withdrawn” (node 2390:3440) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G07_guardian_past_answers` | 13 Guardian · “GV-07 · Past answers” (node 2390:3544) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `G08_guardian_reject_sheet` | 13 Guardian · “GV-08 · Reject (sheet)” (node 2387:1967) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `V5_guardian_status_pass_ready` | 13 Guardian · “G-3 · Status · Pass ready” (node 1929:537) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `V5_guardian_status_out` | 13 Guardian · “G-3 · Status · Out” (node 1929:595) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `V5_guardian_status_back` | 13 Guardian · “G-3 · Status · Back” (node 1929:651) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `V5_guardian_status_back_late` | 13 Guardian · “G-3 · Status · Back late” (node 1929:704) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `V5_guardian_status_not_going` | 13 Guardian · “G-3 · Status · Not going” (node 1929:762) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `V5_guardian_status_change_asked` | 13 Guardian · “G-3 · Status · Change asked” (node 1929:912) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `V5_guardian_sign_in` | 13 Guardian · “G-0 · Sign in” (node 1929:131727) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `V5_guardian_verify_code` | 13 Guardian · “G-0 · Verify code” (node 1929:131799) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `V5_guardian_activate_account` | 13 Guardian · “G-A1 · Activate account” (node 1929:131872) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `V5_guardian_confirm_link` | 13 Guardian · “G-A2 · Confirm link” (node 1929:131931) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |
| Guardian | `V5_guardian_done` | 13 Guardian · “G-A3 · Done” (node 1929:132000) | Active | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) |

### Warden (22)

| Role / feature area | Screen or state name | Figma reference (page and frame name, if documented) | Status | Shared component dependencies | SwiftUI implementation status | Assigned owner | Proposed priority |
|---|---|---|---|---|---|---|---|
| Warden | `W01_warden_decide_with_video` | 14 Warden · “WV-1 · Queue · Live video” (node 2393:1592) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W01_warden_decide_please_watch` | 14 Warden · “WV-1 · Queue · Please watch” (node 2393:1748) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W01_warden_decide_photo_and_text` | 14 Warden · “WV-1 · Queue · Photo and text” (node 2393:1890) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W01_warden_decide_confirmed_by_call` | 14 Warden · “WV-1 · Queue · Confirmed by call” (node 2393:2048) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W01_warden_decide_video_loading` | 14 Warden · “WV-1 · Queue · Video loading” (node 2393:2187) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow, AsyncContentView (loading) | Not started | Unassigned | P2 (proposed) |
| Warden | `W01_warden_decide_empty` | 14 Warden · “WV-1 · Queue · Empty” (node 2393:2346) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow, EmptyStateView | Not started | Unassigned | P2 (proposed) |
| Warden | `W01_warden_decide_offline` | 14 Warden · “WV-1 · Queue · Offline” (node 2393:2463) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow, OfflineBanner | Not started | Unassigned | P2 (proposed) |
| Warden | `W01_warden_decide_ask_sheet` | 14 Warden · “WV-1 · Ask (sheet)” (node 2395:1766) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W01_warden_decide_no_sheet` | 14 Warden · “WV-1 · No (sheet)” (node 2395:1895) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W01_warden_decide_approved` | 14 Warden · “WV-1 · Approved” (node 2395:2021) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W01_warden_decide_change_asked` | 14 Warden · “WV-1 · Change asked” (node 2395:2150) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W01_warden_decide_rejected` | 14 Warden · “WV-1 · Rejected” (node 2395:2267) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W01_warden_me` | 14 Warden · “WV-5 · Me” (node 2395:170898) | Active | OrbitBackground, StaffMeHeader, QuietRow, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W02_warden_out_now` | 14 Warden · “WV-2 · Out now” (node 2395:2384) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W02_warden_out_now_student` | 14 Warden · “WV-2 · Out now · Kiran” (node 2395:2538) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W03_warden_history` | 14 Warden · “WV-3 · History” (node 2395:2982) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W03_warden_history_all` | 14 Warden · “WV-3 · History · All” (node 2395:3126) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W03_warden_history_record` | 14 Warden · “WV-3 · Record · Aarav” (node 2395:3282) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W03_warden_history_record_video_expired` | 14 Warden · “WV-3 · Record · Video expired” (node 2395:3424) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W04_warden_escalated` | 14 Warden · “WV-4 · Escalated” (node 2395:2675) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W04_warden_escalated_call_kiran_sheet` | 14 Warden · “WV-4 · Call Kiran's guardian (sheet)” (node 2395:2802) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |
| Warden | `W04_warden_escalated_call_dev_sheet` | 14 Warden · “WV-4 · Call Dev's guardian (sheet)” (node 2395:2892) | Active | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) |

### Gate (18)

| Role / feature area | Screen or state name | Figma reference (page and frame name, if documented) | Status | Shared component dependencies | SwiftUI implementation status | Assigned owner | Proposed priority |
|---|---|---|---|---|---|---|---|
| Gate | `V5_gate_scan` | 15 Gate · “GA-2 · Scan” (node 1858:133) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_verify_exit` | 15 Gate · “GA-3 · Verify — Exit” (node 1858:179) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_verify_return` | 15 Gate · “GA-3 · Verify — Return” (node 1858:303) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_pass_code` | 15 Gate · “GA-4 · Can’t scan? — Pass code” (node 1858:415) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_find_student` | 15 Gate · “GA-5 · Find student” (node 1858:481) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_exit_recorded` | 15 Gate · “GA-6 · Exit recorded” (node 1860:328) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_return_recorded` | 15 Gate · “GA-6 · Return recorded” (node 1860:361) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_back_late` | 15 Gate · “GA-6 · Back late” (node 1860:392) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_already_exited` | 15 Gate · “GA-6 · Already exited” (node 1860:427) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_not_valid` | 15 Gate · “GA-6 · Not valid” (node 1860:461) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_pass_withdrawn` | 15 Gate · “GA-6 · Pass withdrawn” (node 1863:127216) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_too_early` | 15 Gate · “GA-6 · Outside the window — Too early” (node 1863:127250) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_too_late` | 15 Gate · “GA-6 · Outside the window — Too late” (node 1863:127283) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_offline` | 15 Gate · “GA-6 · Offline” (node 1863:127316) | Active | OrbitBackground, GateVerify, OutingPass, OfflineBanner | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_emergency_exit_recorded` | 15 Gate · “GA-6 · Emergency exit recorded” (node 1863:127354) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_out_now` | 15 Gate · “GA-7 · Out now” (node 1864:454) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_report_a_problem` | 15 Gate · “GA-9 · Report a problem” (node 1864:672) | Active | OrbitBackground, ProblemOption, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |
| Gate | `V5_gate_sent_to_duty_warden` | 15 Gate · “GA-9 · Sent to the duty warden” (node 1864:724) | Active | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) |

## Needs review (20)

| Role / feature area | Screen or state name | Figma reference (page and frame name, if documented) | Status | Shared component dependencies | SwiftUI implementation status | Assigned owner | Proposed priority  Why |
|---|---|---|---|---|---|---|---|---|
| Student · Outings | `02_Tracker_Under_warden_review` | “04 · Outing · Under warden review” | Needs review | OrbitBackground, ClockDial, OutingRibbon, OutingPass | Not started | Unassigned | P2 (proposed) | Pre-redesign render; restyled in STUDENT-REDESIGN |
| Student · Outings | `03_Outing_pass_Valid` | “04 · Outing pass · Valid” | Needs review | OrbitBackground, ClockDial, OutingRibbon, OutingPass | Not started | Unassigned | P2 (proposed) | Pre-redesign render; restyled in STUDENT-REDESIGN |
| Gate | `06_Gate_Verify` | “15 · GA-3 · Verify — Exit” | Needs review | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) | Older render of GA-3 / GA-6; newer renders in export_guardian_video |
| Gate | `07_Gate_Exit_recorded` | “15 · GA-6 · Exit recorded” | Needs review | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) | Older render of GA-3 / GA-6; newer renders in export_guardian_video |
| Admin (Food head) | `08_Admin_Outings_overview_full` | “10 · AD-9a · Outings — Overview (Success)” | Needs review | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Page 10 (old admin); page 12 is the active admin |
| Admin (Food head) | `09_Manage_hub_full` | “10 · AD-5-0 · Manage hub (Success)” | Needs review | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Page 10 (old admin); page 12 is the active admin |
| Student · Outings | `01 Student New outing · Wed` | “04 New outing · Wed · new” | Needs review | OrbitBackground, ClockDial, OutingRibbon, OutingPass | Not started | Unassigned | P2 (proposed) | Restyled again in STUDENT-REDESIGN (25/26) |
| Student · Outings | `02 Student New outing · Sat` | “04 New outing · Sat · new” | Needs review | OrbitBackground, ClockDial, OutingRibbon, OutingPass | Not started | Unassigned | P2 (proposed) | Restyled again in STUDENT-REDESIGN (25/26) |
| Student | `P03_crowd_page` | 04 Student Light (07 prototype) · “Crowd · Main Mess” | Needs review | OrbitBackground | Not started | Unassigned | P3 (proposed) | STUDENT-REDESIGN says no crowd screen; POLISH (later) added one |
| Student | `P03_crowd_page_busy` | 04 Student Light (07 prototype) · “Crowd · Main Mess · Busy · new” | Needs review | OrbitBackground | Not started | Unassigned | P3 (proposed) | STUDENT-REDESIGN says no crowd screen; POLISH (later) added one |
| Student | `P03_crowd_page_closed` | 04 Student Light (07 prototype) · “Crowd · Main Mess · Closed · new” | Needs review | OrbitBackground | Not started | Unassigned | P3 (proposed) | STUDENT-REDESIGN says no crowd screen; POLISH (later) added one |
| Student | `P03_crowd_page_offline` | 04 Student Light (07 prototype) · “Crowd · Main Mess · Offline” | Needs review | OrbitBackground, OfflineBanner | Not started | Unassigned | P3 (proposed) | STUDENT-REDESIGN says no crowd screen; POLISH (later) added one |
| Gate | `32_gate_verify` | “15 · GA-3 · Verify — Exit” | Needs review | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) | Duplicate of GA-3 / GA-6 in export_guardian_video |
| Gate | `33_gate_exit_recorded` | “15 · GA-6 · Exit recorded” | Needs review | OrbitBackground, GateVerify, OutingPass | Not started | Unassigned | P2 (proposed) | Duplicate of GA-3 / GA-6 in export_guardian_video |
| Student | `34_brand_mark_and_app_icon` | 04 Student Light (07 prototype) · “OrbitMark 24 / 32 / 48 and AppIcon Black / Lime × 40 / 96 (page 03; 1264 × 320)” | Needs review | OrbitBackground | Not started | Unassigned | P1 (proposed) | Brand mark asset, not a screen; final logo file is an open decision |
| Kitchen | `K19_home_during_meal_sos_tab` | (not documented) | Needs review | SOSEdgeTab, LiveCountCard | Not started | Unassigned | P1 (proposed) | In the Kitchen pack (v3) but not drawn in Figma yet (gap 553) |
| Kitchen | `K20_sos_panel` | (not documented) | Needs review | SOSPanel | Not started | Unassigned | P1 (proposed) | In the Kitchen pack (v3) but not drawn in Figma yet (gap 553) |
| Student | Remaining page 04 student frames (states, sheets, day × slot menus) | 04 Student Light: 294 phone frames (STATE.md) | Needs review | — | Not started | Unassigned | P1 (proposed) | Only the frames above are exported and named in the repository; the full list must be exported from Figma before it can be planned |
| Admin (Food head) | Page 10 Admin (old four-tab admin: Today, Issues, Insights, Manage) | 10 Admin: 187 frames (STATE.md) | Needs review | — | Not started | Unassigned | — | Superseded in direction by page 12 (Today, Students, Results, More), but not archived and still has five flow starts |
| Student | Page 05 Student Dark | 05 Student Dark: 333 frames, all named “· stale” | Needs review | — | Not started | Unassigned | P3 (proposed) | Not rebuilt after STUDENT-REDESIGN (stale_05.md); Dark mode is out of scope until rebuilt |

## Archived (not requirements) (89)

Listed only so nobody builds them by mistake. Do not implement these.

| Role / feature area | Screen or state name | Figma reference (page and frame name, if documented) | Status | Shared component dependencies | SwiftUI implementation status | Assigned owner | Proposed priority  Why |
|---|---|---|---|---|---|---|---|---|
| Student (pre-redesign) | `s01_home.png` | “Home · Afternoon” | Archived | OrbitBackground, HeroCard, AnswerRow, TicketStrip, CrowdRow | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `s02_meals_menu_lunch.png` | “Meals · Menu” | Archived | OrbitBackground, MealSegments4, DishTile, HighlightChip, DietMark | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `s03_meal_detail_answered.png` | “Meal detail · Answer Yes · Saved” | Archived | OrbitBackground, MealSegments4, DishTile, HighlightChip, DietMark | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `s04_community_list.png` | “Community · List” | Archived | OrbitBackground, IssueCard | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `s05_credits.png` | “Rewards (titled Credits)” | Archived | OrbitBackground, BigTicket | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `s06_juice_ticket.png` | “Ticket · Juice · new” | Archived | OrbitBackground, BigTicket | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `s07_special_pass_live.png` | “Pass · Live 1” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `s08_plate_tracker_day.png` | “You · Daily breakdown” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `m01_pick_your_job.png` | “MS-1 · Pick your job” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `m02_home_supervisor_alert.png` | “MS-H · Home — Supervisor (Alert)” | Archived | OrbitBackground, HeroCard, AnswerRow, TicketStrip, CrowdRow | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `m03_scan_welcome.png` | “MS-A2 · Welcome” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Student (pre-redesign) | `m04_pass_check.png` | “MS-B1 · Pass check (Live)” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `m05_running_out.png` | “MS-C3 · Running out?” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `m06_confirm_hold.png` | “MS-F1 · Confirm hold — 1 Stop” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `a01_today_now.png` | “AD-1a · Today — Now” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `a02_to_do.png` | “AD-1c · Today — Decisions” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `a03_safety_case.png` | “AD-3b · Safety case” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `a04_issues_sos.png` | “AD-3a · Issues — SOS” | Archived | OrbitBackground, SOSEdgeTab, SOSPanel, ProofCard, ProofChecks | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `a05_insights_overview.png` | “AD-4a · Insights — Overview (Success)” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `a06_insights_waste.png` | “AD-4c · Insights — Waste (Success)” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `a07_meal_record.png` | “AD-4e · Insights — Meal (Success)” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `a08_manage_hub.png` | “AD-5-0 · Manage hub (Success)” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `a09_menu_lunch.png` | “AD-5a · Menu — Lunch” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `a10_staff_access.png` | “AD-7b · Staff access — Ravi (Request)” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `a11_pass_exception.png` | “AD-6b · Pass exception (Open)” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `a12_report_summary.png` | “Report page 2 · Summary” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Student (pre-redesign) | `a13_brand_sheet.png` | “Brand sheet · new (page 03)” | Archived | OrbitBackground | Not started | Unassigned | P1 (proposed) | Pre-redesign Lab student/staff export; replaced by STUDENT-REDESIGN and the role packs |
| Admin (Food head) | `A01_today_breakfast` | 12 Admin Redesign · “Today · Breakfast · new” | Archived | OrbitBackground, AdminTabBar, DayLine, MessTile | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A01_today_snacks` | 12 Admin Redesign · “Today · Snacks · new” | Archived | OrbitBackground, AdminTabBar, DayLine, MessTile | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A01_today_all_sent` | 12 Admin Redesign · “Today · All sent · new” | Archived | OrbitBackground, AdminTabBar, DayLine, MessTile | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A01_today_nothing_needs_you` | 12 Admin Redesign · “Today · Nothing needs you · new” | Archived | OrbitBackground, AdminTabBar, DayLine, MessTile | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A01_today_loading` | 12 Admin Redesign · “Today · Loading · new” | Archived | OrbitBackground, AdminTabBar, DayLine, MessTile, AsyncContentView (loading) | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A01_today_mess_closed` | 12 Admin Redesign · “Today · Mess closed · new” | Archived | OrbitBackground, AdminTabBar, DayLine, MessTile | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A01_today_north_sending` | 12 Admin Redesign · “Today · North sending · new” | Archived | OrbitBackground, AdminTabBar, DayLine, MessTile | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A01_today_north_sent` | 12 Admin Redesign · “Today · North sent · new” | Archived | OrbitBackground, AdminTabBar, DayLine, MessTile | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A01_today_north_replied` | 12 Admin Redesign · “Today · North replied · new” | Archived | OrbitBackground, AdminTabBar, DayLine, MessTile | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A01_today_needs_you_all` | 12 Admin Redesign · “Today · Needs you (all) · new” | Archived | OrbitBackground, AdminTabBar, DayLine, MessTile | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A02_headcount_forecast_pending` | 12 Admin Redesign · “Headcount · Forecast pending · new” | Archived | OrbitBackground, AdminTabBar, ChainStepper, VendorChip | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A02_headcount_low_data` | 12 Admin Redesign · “Headcount · Low data · new” | Archived | OrbitBackground, AdminTabBar, ChainStepper, VendorChip | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A02_headcount_sending` | 12 Admin Redesign · “Headcount · Sending · new” | Archived | OrbitBackground, AdminTabBar, ChainStepper, VendorChip | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A02_headcount_failed` | 12 Admin Redesign · “Headcount · Failed · new” | Archived | OrbitBackground, AdminTabBar, ChainStepper, VendorChip | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A02_headcount_main_changed_after_sending` | 12 Admin Redesign · “Headcount · Main · Changed after sending · new” | Archived | OrbitBackground, AdminTabBar, ChainStepper, VendorChip | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A02_headcount_tell_the_vendor_sheet` | 12 Admin Redesign · “Tell the vendor (sheet) · Headcount · new” | Archived | OrbitBackground, AdminTabBar, ChainStepper, VendorChip | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A03_meal_live_rice_ran_out` | 12 Admin Redesign · “Live meal · Main · Rice ran out · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A03_meal_live_behind_pace` | 12 Admin Redesign · “Live meal · Main · Behind pace · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A03_meal_live_not_enough_history` | 12 Admin Redesign · “Live meal · Main · Not enough history · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A03_meal_live_scanner_offline` | 12 Admin Redesign · “Live meal · Main · Scanner offline · new” | Archived | OrbitBackground, AdminTabBar, OfflineBanner | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A03_meal_live_tell_the_vendor_sheet` | 12 Admin Redesign · “Tell the vendor (sheet) · Rice low · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A04_meal_report_reviewed` | 12 Admin Redesign · “Meal report · Reviewed · new” | Archived | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A04_meal_report_check_next_time_started` | 12 Admin Redesign · “Meal report · Check next time started · new” | Archived | OrbitBackground, AdminTabBar, ReportTicket, StatBars | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A05_safety_case_hold_confirmed` | 12 Admin Redesign · “Safety case · Hold confirmed · new” | Archived | OrbitBackground, AdminTabBar, SafetyRail, SafetyRailStep | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A05_safety_case_vendor_told` | 12 Admin Redesign · “Safety case · Vendor told · new” | Archived | OrbitBackground, AdminTabBar, SafetyRail, SafetyRailStep | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A05_safety_case_close_case_sheet` | 12 Admin Redesign · “Safety case · Close case (sheet) · new” | Archived | OrbitBackground, AdminTabBar, SafetyRail, SafetyRailStep | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A05_safety_case_tell_vendor_sheet` | 12 Admin Redesign · “Tell the vendor (sheet) · Safety case · new” | Archived | OrbitBackground, AdminTabBar, SafetyRail, SafetyRailStep | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A06_students_reminder_sent` | 12 Admin Redesign · “Students · Reminder sent · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A06_students_empty` | 12 Admin Redesign · “Students · Empty · new” | Archived | OrbitBackground, AdminTabBar, EmptyStateView | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A06_students_loading` | 12 Admin Redesign · “Students · Loading · new” | Archived | OrbitBackground, AdminTabBar, AsyncContentView (loading) | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A06_students_offline` | 12 Admin Redesign · “Students · Offline · new” | Archived | OrbitBackground, AdminTabBar, OfflineBanner | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A06_students_assign_owner_sheet` | 12 Admin Redesign · “Students · Assign owner (sheet) · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A06_students_not_answered_by_mess` | 12 Admin Redesign · “Students · Not answered by mess · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A07_results_to_check` | 12 Admin Redesign · “Results · To check · new” | Archived | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A07_results_not_enough_meals` | 12 Admin Redesign · “Results · Not enough meals yet · new” | Archived | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A07_results_weekly_report` | 12 Admin Redesign · “Results · Weekly report · new” | Archived | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip, ReportTicket, StatBars | Not started | Unassigned | P0 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A11_more_announce_sent` | 12 Admin Redesign · “Announce · Sent · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A11_more_restyled_pass_exception` | 12 Admin Redesign · “AD-6b · Pass exception (Open) · restyled · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A11_more_restyled_proposals` | 12 Admin Redesign · “AD-5c2 · Proposals (Success) · restyled · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A11_more_restyled_vote_result` | 12 Admin Redesign · “AD-5d · Vote result → final decision · restyled · new” | Archived | OrbitBackground, AdminTabBar, ReasonCard, ReasonRow, FoodTile, TagChip | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A11_more_restyled_redemptions` | 12 Admin Redesign · “AD-6c3 · Rewards — Redemptions · restyled · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A11_more_restyled_spare_food_offered` | 12 Admin Redesign · “AD-6d · Surplus (Offered) · restyled · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A11_more_restyled_spare_food_collected` | 12 Admin Redesign · “AD-6d · Surplus (Collected) · restyled · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A11_more_restyled_pickup` | 12 Admin Redesign · “AD-6d2 · Pickup detail (Success) · restyled · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A11_more_restyled_outings_policy` | 12 Admin Redesign · “AD-9b · Outings — Policy (Success) · restyled · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A11_more_restyled_outing_audit` | 12 Admin Redesign · “AD-9g · Outing audit (Success) · restyled · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A12_weekly_menu_uploading` | 12 Admin Redesign · “Weekly menu · Uploading · new” | Archived | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile, AsyncContentView (loading) | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A12_weekly_menu_reading` | 12 Admin Redesign · “Weekly menu · Reading · new” | Archived | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A12_weekly_menu_publish_sheet` | 12 Admin Redesign · “Weekly menu · Publish (sheet) · new” | Archived | OrbitBackground, AdminTabBar, FoodChip, MenuDishTile | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A13_people_kitchen_staff` | 12 Admin Redesign · “People · Kitchen staff · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A13_people_invite_sheet` | 12 Admin Redesign · “People · Invite (sheet) · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Admin (Food head) | `A13_people_vendor_contact_sheet` | 12 Admin Redesign · “People · Vendor contact (sheet) · new” | Archived | OrbitBackground, AdminTabBar | Not started | Unassigned | P1 (proposed) | Moved to page 99 (archive index) |
| Student · Outings | `01_Student_New_outing` | “04 · New outing” | Archived | OrbitBackground, ClockDial, OutingRibbon, OutingPass | Not started | Unassigned | P2 (proposed) | Replaced by New outing · Wed / Sat (OUTINGS-FIX) and STUDENT-REDESIGN 25/26 |
| Guardian | `04_Guardian_Request` | “13 · G-2 · Request” | Archived | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) | Replaced by guardian video and the WV-* warden queue |
| Warden | `05_Warden_Queue_Decide_next` | “14 · W-1 · Queue — Decide next” | Archived | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) | Replaced by guardian video and the WV-* warden queue |
| Guardian | `03 Guardian Request` | “13 G-2 · Request · Ready · new” | Archived | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) | Slide-to-approve guardian flow; replaced by guardian video |
| Guardian | `04 Guardian Status · Waiting for the warden` | “13 G-3 · Status · Waiting for the warden · new” | Archived | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) | Slide-to-approve guardian flow; replaced by guardian video |
| Guardian | `05 Guardian Status · Out` | “13 G-3 · Status · Out · new” | Archived | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) | Slide-to-approve guardian flow; replaced by guardian video |
| Guardian | `06 Guardian About this outing (full height)` | “13 G-2A · About this outing · new” | Archived | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) | Slide-to-approve guardian flow; replaced by guardian video |
| Guardian | `29_guardian_request` | “13 · G-2 · Request · Ready” | Archived | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) | Slide-to-approve guardian page; replaced by guardian video (GUARDIAN-VIDEO) |
| Guardian | `30_guardian_status` | “13 · G-3 · Status · Waiting for the warden” | Archived | OrbitBackground, PhraseCard, VideoRecorder, StepList, MethodTag | Not started | Unassigned | P2 (proposed) | Slide-to-approve guardian page; replaced by guardian video (GUARDIAN-VIDEO) |
| Warden | `31_warden_decide_next` | “14 · W-1 · Queue — Decide next” | Archived | OrbitBackground, WardenTabBar4, EvidenceCard, MethodTag, OutNowRow, HistoryRow | Not started | Unassigned | P2 (proposed) | Warden deck; replaced by the WV-* queue (GUARDIAN-VIDEO) |

## Needs design (not in Figma)

These screens follow from the owner's C1 decisions (the vendor works through a restricted MealLoop account; Super Admin is a separate role; non-student users have MealLoop-managed accounts). **None exists in Figma.** The names are proposed for tracking, the platform (iOS app or another surface) is not decided, and the owner decides scope and milestone ([`OPEN_DECISIONS.md`](OPEN_DECISIONS.md), P68). These rows are not part of the Active, Needs review or Archived counts below.

| Role / feature area | Screen or state name | Figma reference | Status | Shared component dependencies | SwiftUI implementation status | Assigned owner | Proposed priority |
|---|---|---|---|---|---|---|---|
| Vendor | `V01_vendor_sign_in` (Vendor sign-in with a MealLoop-managed account) | None (not in Figma) | Needs design (not in Figma) | To be decided | Not started | Unassigned | Owner decides |
| Vendor | `V02_vendor_approved_headcount` (Approved headcount for the assigned mess (no dish quantities, no student data)) | None (not in Figma) | Needs design (not in Figma) | To be decided | Not started | Unassigned | Owner decides |
| Vendor | `V03_vendor_acknowledge` (Acknowledge receipt of a published headcount; pending and acknowledged states) | None (not in Figma) | Needs design (not in Figma) | To be decided | Not started | Unassigned | Owner decides |
| Vendor | `V04_vendor_updates_history` (Authorized updates and the publication and acknowledgment history) | None (not in Figma) | Needs design (not in Figma) | To be decided | Not started | Unassigned | Owner decides |
| Super Admin | `SA01_super_admin_sign_in` (Sign-in through SRM SSO (feasibility unverified)) | None (not in Figma) | Needs design (not in Figma) | To be decided | Not started | Unassigned | Owner decides |
| Super Admin | `SA02_accounts_and_roles` (List of accounts with roles, mess or block scope and status) | None (not in Figma) | Needs design (not in Figma) | To be decided | Not started | Unassigned | Owner decides |
| Super Admin | `SA03_provision_account` (Provision an account, assign a role and scope, change scope) | None (not in Figma) | Needs design (not in Figma) | To be decided | Not started | Unassigned | Owner decides |
| Super Admin | `SA04_deactivate_account` (Deactivate an account) | None (not in Figma) | Needs design (not in Figma) | To be decided | Not started | Unassigned | Owner decides |
| Super Admin | `SA05_initiate_password_reset` (Initiate a password reset; no password is ever shown) | None (not in Figma) | Needs design (not in Figma) | To be decided | Not started | Unassigned | Owner decides |
| All MealLoop-account users | `ID01_set_or_reset_password` (The user sets or resets their own password through a secure process) | None (not in Figma) | Needs design (not in Figma) | To be decided | Not started | Unassigned | Owner decides |
| Shared staff entry | `ID02_staff_email_password_sign_in` (Production sign-in with individual email and password (the shared four-digit password stays a prototype interaction)) | None (not in Figma) | Needs design (not in Figma) | To be decided | Not started | Unassigned | Owner decides |
| Admin (Food head) | `A02_headcount_vendor_acknowledgment_states` (Pending acknowledgment and acknowledged states fed by the vendor account (the current frames show a manually recorded reply)) | None (not in Figma) | Needs design (not in Figma) | To be decided | Not started | Unassigned | Owner decides |

**12 rows.** Admin tab changes follow the existing Admin pack; only the vendor acknowledgment states are new.

## Counts

| Role / feature area | Active rows | of which P0 | P1 | P2 | P3 |
|---|---|---|---|---|---|
| Shared staff entry | 7 | 7 | 0 | 0 | 0 |
| Student | 38 | 8 | 17 | 0 | 13 |
| Student · Outings | 9 | 0 | 0 | 9 | 0 |
| Admin (Food head) | 87 | 22 | 65 | 0 | 0 |
| Door Scanner | 38 | 21 | 17 | 0 | 0 |
| Pass Desk | 46 | 0 | 46 | 0 | 0 |
| Kitchen | 69 | 42 | 27 | 0 | 0 |
| Supervisor | 45 | 9 | 36 | 0 | 0 |
| Guardian | 41 | 0 | 0 | 41 | 0 |
| Warden | 22 | 0 | 0 | 22 | 0 |
| Gate | 18 | 0 | 0 | 18 | 0 |
| **Total active** | **420** | **109** | **208** | **90** | **13** |

- Archived rows: **89**.
- Rows marked Needs design (not in Figma): **12** (not counted in the totals above or below)
- Needs-review rows: **20** (three of them stand for whole Figma pages: 294 student frames on page 04, 187 old admin frames on page 10, 333 stale Dark frames on page 05).

## Effort note against 10 November 2026

- **420 active exported screens and states**, plus the un-exported student frames on page 04 (up to 294 frames there in total). From 23 October to 10 November is 18 calendar days, 12 weekdays.
- With four people working weekdays only, that is **8.8 exported screens or states per person per working day**, before the student page 04 remainder, before review and fixes, and while most of the team is still learning SwiftUI.
- Many rows are state variants of one screen (loading, offline, stale, sheet open). Grouping rows by their reference-image number (for example `K02`, `K02b`, `K02c` count once) gives **149 distinct base screens**, which is still **3.1 base screens per person per working day**. Shared components and `AsyncContentView` make the state variants cheaper, but each still needs data wiring, wording and a check against the export.
- Implementing every active frame by 10 November is **not realistic at a normal quality bar** unless the owner narrows the scope. Suggested reading: treat P0 as the 10 November commitment, P1 as stretch, and P2 and P3 as later. The owner decides.
- The effort figures above do **not** include the Needs design (not in Figma) rows. They are added scope and are recorded as a risk in the PRD (R13). The 10 November and 13 December milestones are not moved by this document.
