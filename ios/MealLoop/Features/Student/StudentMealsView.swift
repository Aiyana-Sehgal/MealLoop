import SwiftUI

// Coverage (student-all G4): the restyled Meals week frames are this view drawn from the menu data, one per day and
// meal: Breakfast 2150:133459, 2150:133656, 2150:134025, 2150:134240, 2150:134431, 2150:134630; Lunch 2150:134818,
// 2150:135047, 2150:135265, 2150:135483, 2150:135673, 2150:135902; Snacks 2150:136140, 2150:136302, 2150:136637,
// 2150:136815, 2150:136989, 2150:137163; Dinner 2150:137337, 2150:137573, 2150:138040, 2150:138273, 2150:138484,
// 2150:138693 ("Curries" and "Comes with it" come from `StudentMealMenu`).

/// Pushed screens on the Meals tab. The tab bar stays, as the frames draw it.
enum StudentMealsRoute: Hashable {
    case dish(DishID, day: Date, slot: MealSlot)
    case pass
    /// Report · What's wrong (221:63480), from the Meals error card, or from Not good on Rate a dish with the dish
    /// already selected.
    case report(StudentReportSubject?)
    /// Rate a dish (image student_feedback_02_rate_a_dish).
    case rateDish(DishID, day: Date, slot: MealSlot)
    /// SOS, from "Unsafe or unwell? Use SOS" on the dish feedback sheets.
    case sos
    case comingSoon(String)

    /// Pages built on `MLScreen`: the system bar, its back button and the swipe-back gesture.
    var usesSystemBar: Bool {
        switch self {
        case .comingSoon: false
        default: true
        }
    }
}

/// Builds the view model from the environment.
struct StudentMealsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session

    var body: some View {
        if let model = StudentMealsViewModel(session: session, repositories: environment.repositories, clock: environment.clock) {
            StudentMealsView(model: model, session: session)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// Meals · Wed 14 · Lunch (221:62892) and its states (221:64980 to 221:65084).
struct StudentMealsView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: StudentMealsViewModel
    @State private var path: [StudentMealsRoute] = []
    @State private var showsHighlightInfo = false
    let session: Session

    init(model: StudentMealsViewModel, session: Session) {
        _model = State(initialValue: model)
        self.session = session
    }

    var body: some View {
        NavigationStack(path: $path) {
            // The tab root: a large title that collapses into the bar as the week scrolls under it.
            MLScreen(MealsCopy.title, subtitle: model.context.mess.name, bottomClearance: .tabBar) {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    if let week = model.week {
                        MealsWeekStrip(week: week, selected: model.selectedDay, timeZone: model.timeZone) { day in
                            Task { await model.select(day: day) }
                        }
                    }
                    MealsSegments(selected: model.selectedSlot) { slot in
                        Task { await model.select(slot: slot) }
                    }
                    content
                }
            }
            .refreshable { await model.load() }
            .navigationDestination(for: StudentMealsRoute.self) { route in
                destination(route)
                    .studentPushedPage(usesSystemBar: route.usesSystemBar)
            }
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
        .mlSheet(isPresented: $showsHighlightInfo) {
            HighlightInfoSheet { showsHighlightInfo = false }
        }
    }

    @ViewBuilder
    private func destination(_ route: StudentMealsRoute) -> some View {
        switch route {
        case .dish(let dish, let day, let slot):
            StudentDishDetailView(load: { try await model.dishDetail(dish, day: day, slot: slot) }, timeZone: model.timeZone,
                                  others: model.otherDishes(than: dish, day: day, slot: slot),
                                  onOther: { path.append(.dish($0.id, day: day, slot: slot)) },
                                  onRate: { path.append(.rateDish(dish, day: day, slot: slot)) }) { path.removeLast() }
        case .pass:
            StudentPassScreen(session: session) { path.removeLast() }
        case .report(let subject):
            StudentReportScreen(session: session, subject: subject) { path.removeLast() }
        case .sos:
            StudentSOSScreen(session: session) { path.removeLast() }
        case .rateDish(let dish, let day, let slot):
            if let rating = StudentRatingViewModel(session: session, repositories: environment.repositories, day: day,
                                                   slot: slot, dish: dish) {
                StudentRateDishView(model: rating, loadDish: { try await model.dishDetail(dish, day: day, slot: slot) },
                                    onSOS: { path.append(.sos) }) { path.removeLast() }
            }
        case .comingSoon(let title):
            StudentComingSoonView(title: title) { path.removeLast() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            MealsLoading()
        case .loaded(let menu), .stale(let menu, _):
            menuBody(menu)
        case .offline(let menu, let savedAt):
            StudentOfflineBanner(text: menu == nil ? MealsCopy.offlineNothingSaved
                                                   : MealsCopy.offlineMenu(savedAt.map { MLFormat.time($0, in: model.timeZone) }))
            if let menu { menuBody(menu, showsBanners: false) }
        case .empty:
            MealsStateCard(title: MealsCopy.noMealTitle(model.selectedSlot), detail: MealsCopy.noMealDetail)
        case .failed(let failure):
            if failure.isNotImplemented {
                MealsStateCard(title: failure.message, detail: "")
            } else {
                MealsErrorCard(onRetry: { Task { await model.load() } },
                               onReport: { path.append(.report(nil)) })
            }
        }
    }

    @ViewBuilder
    private func menuBody(_ menu: StudentMealMenu, showsBanners: Bool = true) -> some View {
        switch menu.status {
        case .notPublished:
            MealsStateCard(title: MealsCopy.notPublishedTitle, detail: MealsCopy.notPublishedDetail)
        case .noMeal:
            MealsStateCard(title: MealsCopy.noMealTitle(menu.slot), detail: MealsCopy.noMealDetail)
        case .published:
            if showsBanners, let ended = model.serviceEnded {
                MealsNotice(symbol: "clock", text: ([MealsCopy.serviceEnded(ended.slot)]
                    + [ended.next.map { MealsCopy.opensAt($0.slot, time: StudentFormat.shortTime($0.from, in: model.timeZone)) }]
                        .compactMap { $0 }).joined(separator: " "))
            } else if showsBanners, let changed = menu.changedAt {
                MealsNotice(symbol: "arrow.clockwise", text: MealsCopy.changedAt(StudentFormat.shortTime(changed, in: model.timeZone)))
            }
            MealsMenuLayout(menu: menu,
                            onDish: { dish in path.append(.dish(dish.id, day: menu.day, slot: menu.slot)) },
                            onHighlightInfo: { showsHighlightInfo = true },
                            onSpecial: { path.append(.pass) })
        }
    }
}

// MARK: - Week strip and meal segments

/// WeekStrip 2150:340: seven DateChips (78:1710), 48 × 64.
struct MealsWeekStrip: View {
    let week: StudentWeek
    let selected: Date?
    let timeZone: TimeZone
    let onSelect: (Date) -> Void

    private func dayNumber(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return String(calendar.component(.day, from: date))
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(week.days.enumerated()), id: \.element) { index, day in
                if index > 0 { Spacer(minLength: 2) }
                chip(day)
            }
        }
    }

    private func chip(_ day: Date) -> some View {
        let isSelected = day == selected
        let isToday = day == week.today
        let weekday = StudentFormat.shortDay(day, in: timeZone)
        return Button { onSelect(day) } label: {
            VStack(spacing: 2) {
                Text(weekday)
                    .font(StudentType.footnote)
                    .foregroundStyle(isSelected ? MLColor.onHero : MLColor.inkSecondary)
                Text(dayNumber(day))
                    .font(StudentType.mono)
                    .foregroundStyle(isSelected ? MLColor.onHero : MLColor.ink)
            }
            .frame(width: 48, height: 64)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(isSelected ? MLColor.ink : MLColor.surface))
            .overlay {
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(MLColor.ink, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MealsCopy.weekday(StudentFormat.day(day, in: timeZone), isToday: isToday))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// MealSegments4 2133:2323: four slots, the selected one a black pill.
struct MealsSegments: View {
    let selected: MealSlot
    let onSelect: (MealSlot) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(StudentMealsViewModel.slots, id: \.self) { slot in
                let isSelected = slot == selected
                Button { onSelect(slot) } label: {
                    Text(MLFormat.mealSlot(slot))
                        .font(isSelected ? StudentType.secondaryMedium : StudentType.secondary)
                        .foregroundStyle(isSelected ? MLColor.onHero : MLColor.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity)
                        .frame(height: MLSize.hit)
                        .background { if isSelected { Capsule().fill(MLColor.ink) } }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Capsule().fill(MLColor.track))
    }
}

// MARK: - Menu

/// The published menu, part by part, as the Wednesday frames lay it out.
struct MealsMenuLayout: View {
    let menu: StudentMealMenu
    let onDish: (Dish) -> Void
    let onHighlightInfo: () -> Void
    let onSpecial: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            if let highlight = menu.highlight {
                MealsHighlightTile(dish: highlight, onInfo: onHighlightInfo) { onDish(highlight) }
            }
            MealsTileRows(dishes: menu.mains, onDish: onDish)
            if let special = menu.special {
                MealsSpecialTicket(special: special, action: onSpecial)
            }
            if !menu.curries.isEmpty {
                Text(MealsCopy.curries)
                    .font(StudentType.secondaryMedium)
                    .foregroundStyle(MLColor.inkSecondary)
                    .accessibilityAddTraits(.isHeader)
                MealsTileRows(dishes: menu.curries, onDish: onDish)
            }
            ForEach(menu.slimRows) { dish in
                MealsSlimRow(dish: dish, onInfo: onHighlightInfo) { onDish(dish) }
            }
            if !menu.sides.isEmpty {
                Text(MealsCopy.comesWithIt)
                    .font(StudentType.secondaryMedium)
                    .foregroundStyle(MLColor.inkSecondary)
                    .accessibilityAddTraits(.isHeader)
                StudentFlowLayout(spacing: 4) {
                    ForEach(Array(menu.sides.enumerated()), id: \.element.id) { index, dish in
                        Button { onDish(dish) } label: {
                            Text(index < menu.sides.count - 1 ? "\(dish.name) ·" : dish.name)
                                .font(StudentType.body)
                                .foregroundStyle(MLColor.ink)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(dish.name)
                    }
                }
            }
            if !menu.isAnswerable {
                Text(MealsCopy.snacksNote)
                    .font(StudentType.footnote)
                    .foregroundStyle(MLColor.inkSecondary)
            }
        }
    }
}

/// Tiles three across, two across or full width (DishTile sizes S, M and L).
struct MealsTileRows: View {
    let dishes: [Dish]
    let onDish: (Dish) -> Void

    private var rows: [[Dish]] {
        stride(from: 0, to: dishes.count, by: 3).map { Array(dishes[$0..<min($0 + 3, dishes.count)]) }
    }

    var body: some View {
        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
            HStack(alignment: .top, spacing: MLSpacing.s12) {
                ForEach(row) { dish in
                    MealsDishTile(dish: dish, size: row.count == 3 ? .small : row.count == 2 ? .medium : .wide) { onDish(dish) }
                }
            }
        }
    }
}

struct MealsDishPicture: View {
    let name: String
    let size: CGFloat
    let color: Color

    var body: some View {
        Image(StudentPictogram.asset(for: name))
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// DishTile, Fill Default.
struct MealsDishTile: View {
    enum Size { case small, medium, wide }

    let dish: Dish
    let size: Size
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    StudentDietMark(diet: dish.diet, onDark: false)
                    Spacer(minLength: 0)
                    MealsDishPicture(name: dish.name, size: size == .small ? 32 : 40, color: MLColor.ink)
                }
                Spacer(minLength: MLSpacing.s4)
                Text(dish.name)
                    .font(size == .small ? StudentType.dishName : StudentType.bodySemibold)
                    .foregroundStyle(MLColor.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, MLSpacing.s12)
            .padding(.horizontal, size == .small ? 14 : 16)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity, minHeight: size == .small ? 113 : 116, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: StudentMetric.tileRadius, style: .continuous).fill(MLColor.surface))
            .overlay(RoundedRectangle(cornerRadius: StudentMetric.tileRadius, style: .continuous).strokeBorder(MLColor.border, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

/// The lime Highlight chip (HighlightChip 2132:2197). On a light card it carries the ink outline.
struct MealsHighlightChip: View {
    let onLight: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(MealsCopy.highlight).font(StudentType.tag)
                Image(systemName: "info.circle").font(.system(size: 18))
            }
            .foregroundStyle(MLColor.onLime)
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(Capsule().fill(MLColor.lime))
            .overlay { if onLight { Capsule().strokeBorder(MLColor.limeOutline, lineWidth: 1.5) } }
            .frame(height: MLSize.hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MealsCopy.highlight)
        .accessibilityHint(MealsCopy.highlightInfoLead)
    }
}

/// DishTile size L, Fill Highlight: the black tile with the chip.
struct MealsHighlightTile: View {
    let dish: Dish
    let onInfo: () -> Void
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                StudentDietMark(diet: dish.diet, onDark: true)
                MealsHighlightChip(onLight: false, action: onInfo)
                Spacer(minLength: 0)
                MealsDishPicture(name: dish.name, size: 48, color: MLColor.onHero)
            }
            Spacer(minLength: 0)
            Button(action: action) {
                Text(dish.name)
                    .font(StudentType.heroTitle)
                    .foregroundStyle(MLColor.onHero)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, MLSpacing.s12)
        .padding(.horizontal, MLSpacing.s20)
        .padding(.bottom, MLSpacing.s20)
        .frame(maxWidth: .infinity, minHeight: 129, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous).fill(MLColor.heroBackground))
    }
}

/// The slim non-veg row of Breakfast and Dinner (P9 default).
struct MealsSlimRow: View {
    let dish: Dish
    let onInfo: () -> Void
    let action: () -> Void

    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            Button(action: action) {
                HStack(spacing: MLSpacing.s12) {
                    StudentDietMark(diet: dish.diet, onDark: false)
                    Text(dish.name)
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(MLColor.ink)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if dish.isHighlight {
                MealsHighlightChip(onLight: true, action: onInfo)
            }
        }
        .padding(.horizontal, MLSpacing.s16)
        .frame(minHeight: 58)
        .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface.opacity(0.4)))
        .overlay(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).strokeBorder(MLColor.border, lineWidth: 1))
    }
}

/// TicketStrip / Alternate Wednesday (2133:2374).
struct MealsSpecialTicket: View {
    let special: StudentSpecialMeal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image("student-ticket")
                    .resizable()
                    .frame(width: 22, height: 22)
                    .frame(width: MLSize.hit, height: MLSize.hit)
                    .background(Circle().fill(MLColor.heroBackground))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(special.dishes.joined(separator: " · "))
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(MLColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(special.note)
                        .font(StudentType.footnote)
                        .foregroundStyle(MLColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if special.isLimited {
                    StudentPerforation()
                        .stroke(MLColor.border, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                        .frame(width: 1.5, height: 40)
                        .accessibilityHidden(true)
                    HStack(spacing: MLSpacing.s4) {
                        Circle().fill(MLColor.lime).frame(width: 12, height: 12)
                            .overlay(Circle().strokeBorder(MLColor.limeOutline, lineWidth: 1))
                        Text(MealsCopy.limited)
                            .font(StudentType.bodySemibold)
                            .foregroundStyle(MLColor.ink)
                    }
                }
            }
            .padding(.horizontal, MLSpacing.s20)
            .padding(.vertical, 14)
            .frame(minHeight: 114)
            .background(StudentTicketShape().fill(MLColor.surface))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - States

/// The bordered notice above the menu: Menu changed (221:64980) and Service ended (221:65007).
struct MealsNotice: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            Image(systemName: symbol)
                .font(.system(size: 17))
                .foregroundStyle(MLColor.ink)
                .accessibilityHidden(true)
            Text(text)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, MLSpacing.s20)
        .padding(.vertical, 14)
        .frame(minHeight: 74)
        .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.fillQuiet.opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).strokeBorder(MLColor.border, lineWidth: 1))
    }
}

/// Not published (221:65026) and No menu (221:65036): a white card with a check mark.
struct MealsStateCard: View {
    var symbol = "checkmark.circle"
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: MLSpacing.s8) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundStyle(MLColor.ink)
                .frame(width: 64, height: 64)
                .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.fillQuiet))
                .padding(.bottom, MLSpacing.s12)
                .accessibilityHidden(true)
            Text(title)
                .font(StudentType.bodySemibold)
                .foregroundStyle(MLColor.ink)
                .multilineTextAlignment(.center)
            if !detail.isEmpty {
                Text(detail)
                    .font(StudentType.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, MLSpacing.s24)
        .padding(.vertical, MLSpacing.s32)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }
}

/// Meals · Error (221:65084).
struct MealsErrorCard: View {
    let onRetry: () -> Void
    let onReport: () -> Void

    var body: some View {
        VStack(spacing: MLSpacing.s8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 22))
                .foregroundStyle(MLColor.ink)
                .frame(width: 64, height: 64)
                .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.fillQuiet))
                .padding(.bottom, MLSpacing.s12)
                .accessibilityHidden(true)
            Text(MealsCopy.loadFailedTitle)
                .font(StudentType.bodySemibold)
                .foregroundStyle(MLColor.ink)
            Button(action: onRetry) {
                Text(MealsCopy.tryAgain)
                    .font(StudentType.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
                    .frame(minHeight: MLSize.hit)
            }
            .buttonStyle(.plain)
            Button(action: onReport) {
                Text(MealsCopy.report)
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(MLColor.ink)
                    .padding(.horizontal, MLSpacing.s24)
                    .frame(height: 48)
                    .overlay(Capsule().strokeBorder(MLColor.ink, lineWidth: 1.5))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, MLSpacing.s24)
        .padding(.vertical, MLSpacing.s32)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.surface))
    }
}

/// Meals · Loading (221:65046).
struct MealsLoading: View {
    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            ForEach([129, 113, 89], id: \.self) { height in
                RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous)
                    .fill(MLColor.track.opacity(0.8))
                    .frame(height: CGFloat(height))
            }
            Text(MealsCopy.gettingMenu)
                .font(StudentType.footnote)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MealsCopy.gettingMenu)
    }
}

/// Meals · Highlight info (sheet) (2150:140175). The words are P8's default; no meaning is invented.
struct HighlightInfoSheet: View {
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            HStack {
                Text(MealsCopy.highlightInfoTitle)
                    .font(StudentType.section)
                    .foregroundStyle(MLColor.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(MLColor.ink)
                        .frame(width: MLSize.hit, height: MLSize.hit)
                        .modifier(StudentGlass(shape: Circle()))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(MealsCopy.close)
            }
            Text(MealsCopy.highlightInfoLead)
                .font(StudentType.bodySemibold)
                .foregroundStyle(MLColor.ink)
            Text(MealsCopy.highlightInfoDetail)
                .font(StudentType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        // The frame draws the sheet from mid-screen down; the shared sheet fits its content.
        .frame(maxWidth: .infinity, minHeight: 330, alignment: .topLeading)
    }
}

// MARK: - Dish detail

/// Meals · Dish detail (221:62916).
struct StudentDishDetailView: View {
    let load: () async throws -> StudentDishDetail
    let timeZone: TimeZone
    /// The meal's other dishes, from the menu the host already loaded. Empty hides the section.
    var others: [Dish] = []
    var onOther: ((Dish) -> Void)?
    let onRate: () -> Void
    let onBack: () -> Void
    @State private var state: LoadState<StudentDishDetail> = .idle

    /// On `MLScreen`: the system back button and swipe-back pop the page; `onBack` stays for callers.
    var body: some View {
        MLScreen(MealsCopy.dish) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                switch state {
                case .idle, .loading:
                    RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous)
                        .fill(MLColor.track.opacity(0.8)).frame(height: 162)
                case .loaded(let detail), .stale(let detail, _), .offline(let detail?, _):
                    details(detail)
                    alsoServed(detail)
                case .empty, .offline(nil, _):
                    StudentOfflineBanner(text: MealsCopy.offlineNothingSaved)
                case .failed(let failure):
                    MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
                }
            }
        } bottom: {
            if state.value != nil {
                InkActionButton(title: MealsCopy.rateDish, action: onRate)
                    .studentAboveTabBar()
            }
        }
        .task {
            do {
                state = .loaded(try await load())
            } catch RepositoryError.offline(let savedAt) {
                state = .offline(nil, savedAt: savedAt)
            } catch {
                state = .failed(LoadFailure(error))
            }
        }
    }

    /// The rest of the meal, so the page is not a lone card over a blank band (blank audit, S5).
    @ViewBuilder
    private func alsoServed(_ detail: StudentDishDetail) -> some View {
        if !others.isEmpty {
            Text(MealsCopy.alsoAt(MLFormat.mealSlot(detail.slot)))
                .font(StudentType.eyebrow)
                .tracking(1.2)
                .foregroundStyle(MLColor.inkSecondary)
                .padding(.top, MLSpacing.s8)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                ForEach(Array(others.enumerated()), id: \.element.id) { index, dish in
                    if index > 0 { Rectangle().fill(MLColor.border).frame(height: 1).padding(.leading, 52) }
                    Button { onOther?(dish) } label: {
                        HStack(spacing: MLSpacing.s12) {
                            StudentDietMark(diet: dish.diet, onDark: false)
                            Text(dish.name)
                                .font(StudentType.body)
                                .foregroundStyle(MLColor.ink)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                            if onOther != nil {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(MLColor.inkSecondary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(.horizontal, MLSpacing.s20)
                        .frame(minHeight: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(onOther == nil)
                }
            }
            .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
        }
    }

    @ViewBuilder
    private func details(_ detail: StudentDishDetail) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Text(detail.dish.name)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(MLColor.onHero)
                .fixedSize(horizontal: false, vertical: true)
            StudentFlowLayout(spacing: MLSpacing.s8) {
                DishOutlineChip(text: "\(MLFormat.mealSlot(detail.slot)) · \(StudentFormat.mediumDay(detail.day, in: timeZone))")
                if let from = detail.servedFrom, let until = detail.servedUntil {
                    DishOutlineChip(text: MLFormat.timeRange(from, until, in: timeZone))
                }
                DishOutlineChip(text: detail.dish.diet == .veg ? MealsCopy.veg : MealsCopy.nonVeg)
            }
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous).fill(MLColor.heroBackground))
        Text(MealsCopy.portionAndAllergens)
            .font(StudentType.eyebrow)
            .tracking(1.2)
            .foregroundStyle(MLColor.inkSecondary)
        let facts = [detail.portion].compactMap { $0 } + detail.allergens
        if facts.isEmpty {
            Text(MealsCopy.noDetails)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
        } else {
            StudentFlowLayout(spacing: MLSpacing.s8) {
                ForEach(facts, id: \.self) { fact in
                    Text(fact)
                        .font(StudentType.tag)
                        .foregroundStyle(MLColor.ink)
                        .padding(.horizontal, MLSpacing.s12)
                        .frame(height: 34)
                        .background(Capsule().fill(MLColor.fillQuiet))
                }
            }
        }
        Text(detail.verifiedOn.map { MealsCopy.verifiedBy(StudentFormat.mediumDay($0, in: timeZone)) } ?? MealsCopy.notVerified)
            .font(StudentType.secondary)
            .foregroundStyle(MLColor.inkSecondary)
    }
}

private struct DishOutlineChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(StudentType.tag)
            .foregroundStyle(MLColor.onHero)
            .padding(.horizontal, MLSpacing.s12)
            .frame(height: 34)
            .overlay(Capsule().strokeBorder(MLColor.onHeroSecondary, lineWidth: 1.5))
    }
}
