import SwiftUI

/// Pushed screens on the You tab.
enum StudentYouRoute: Hashable {
    case outings
    case newOuting
    case outingSent(OutingCase)
    case outing(OutingRequestID)
    case credits
    case creditsHistory
    /// Ticket · Juice (1529:1901), after Get on Credits.
    case rewardTicket(StudentRewardTicketID)
    case attendance
    case spending
    case myFeedback
    case myReports
    case report(StudentFiledReportID)
    case help
    case privacy
    case comingSoon(String)

    /// Pages built on `MLScreen`: the system bar, its back button and the swipe-back gesture.
    var usesSystemBar: Bool {
        switch self {
        case .spending, .credits, .creditsHistory, .rewardTicket, .attendance: true
        default: false
        }
    }
}

/// Builds the view model from the environment.
struct StudentYouScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session
    let onSignOut: () -> Void

    var body: some View {
        if let model = StudentYouViewModel(session: session, repositories: environment.repositories, clock: environment.clock) {
            StudentYouView(model: model, session: session, onSignOut: onSignOut)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// You (221:64576) and its states: Loading (221:66100), Offline (221:66111), Error (221:66138).
struct StudentYouView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: StudentYouViewModel
    @State private var path: [StudentYouRoute] = []
    /// Shared by Outings, New outing and a request page, so a sent request shows on the list at once.
    @State private var outingsModel: StudentOutingsViewModel?
    let session: Session
    let onSignOut: () -> Void

    init(model: StudentYouViewModel, session: Session, onSignOut: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.session = session
        self.onSignOut = onSignOut
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                OrbitBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: MLSpacing.s16) {
                        YouLargeHeader(title: YouCopy.you, subtitle: nil, onBack: nil)
                        content
                    }
                    .padding(.horizontal, MLSpacing.margin)
                    .padding(.top, MLSpacing.s8)
                    .padding(.bottom, StudentMetric.scrollBottom)
                }
                .refreshable { await model.loadProfile() }
                StudentScrollFade()
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: StudentYouRoute.self) { route in
                destination(route)
                    .studentPushedPage(usesSystemBar: route.usesSystemBar)
            }
        }
        .task(id: environment.dataRevision) {
            await model.loadProfile()
            if outingsModel == nil {
                outingsModel = StudentOutingsViewModel(session: session, repository: OutingCaseRepositories.studentSource(for: environment))
            }
            await outingsModel?.load()
        }
    }

    @ViewBuilder
    private func destination(_ route: StudentYouRoute) -> some View {
        switch route {
        case .outings:
            if let outingsModel {
                StudentOutingsView(model: outingsModel, onNew: { path.append(.newOuting) },
                                   onOpen: { path.append(.outing($0)) }) { path.removeLast() }
            } else {
                NotImplementedView(title: YouCopy.outings)
            }
        case .newOuting:
            if let outingsModel {
                StudentNewOutingView(model: outingsModel, onSent: { path.append(.outingSent($0)) },
                                     onOpen: { path.append(.outing($0)) }) { path.removeLast() }
            }
        case .outingSent(let outing):
            StudentOutingSentView(outing: outing, now: outingsModel?.now ?? .distantPast,
                                  onSee: { path = [.outings, .outing(outing.id)] }) { path = [.outings] }
        case .outing(let id):
            if let outingsModel {
                StudentOutingDetailView(model: outingsModel, id: id) { path.removeLast() }
            }
        case .credits:
            if let rewards {
                StudentCreditsView(model: model, rewards: rewards, onHistory: { path.append(.creditsHistory) },
                                   onTicket: { path.append(.rewardTicket($0)) })
            }
        case .creditsHistory:
            StudentCreditsHistoryView(model: model, rewards: rewards) { path.removeLast() }
        case .rewardTicket(let id):
            if let rewards {
                StudentRewardTicketView(model: rewards, id: id)
            }
        case .attendance:
            StudentAttendanceView(model: model) { path.removeLast() }
        case .spending:
            StudentSpendingScreen(session: session)
        case .myFeedback:
            records { StudentMyFeedbackView(model: $0, onReports: { path.append(.myReports) }) { path.removeLast() } }
        case .myReports:
            records { StudentMyReportsView(model: $0, onOpen: { path.append(.report($0)) }) { path.removeLast() } }
        case .report(let id):
            records { StudentFiledReportView(model: $0, id: id) { path.removeLast() } }
        case .help:
            records { StudentHelpView(model: $0) { path.removeLast() } }
        case .privacy:
            records { StudentPrivacyView(model: $0) { path.removeLast() } }
        case .comingSoon(let title):
            StudentComingSoonView(title: title) { path.removeLast() }
        }
    }

    private var rewards: StudentRewardsViewModel? {
        StudentRewardsViewModel(session: session, repositories: environment.repositories, clock: environment.clock)
    }

    /// A page backed by `StudentRecordsRepository`, with its own view model.
    @ViewBuilder
    private func records<Page: View>(@ViewBuilder _ page: (StudentRecordsViewModel) -> Page) -> some View {
        if let records = StudentRecordsViewModel(session: session, repositories: environment.repositories, clock: environment.clock) {
            page(records)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.profile {
        case .idle, .loading:
            YouSkeleton(heights: [88, 320, 180], label: YouCopy.you)
        case .failed(let failure):
            MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
            settingsCard
        case .empty:
            settingsCard
        case .loaded(let profile), .stale(let profile, _):
            identity(profile)
            mainCard(profile)
            settingsCard
        case .offline(let profile, _):
            StudentOfflineBanner(text: YouCopy.youOffline)
            if let profile {
                identity(profile)
                mainCard(profile)
            }
            settingsCard
        }
    }

    private func identity(_ profile: StudentProfileSummary) -> some View {
        let name = profile.firstName ?? model.displayName
        return HStack(spacing: MLSpacing.s16) {
            Text(String(name.prefix(1)))
                .font(MLType.heroTitle)
                .foregroundStyle(MLColor.onHero)
                .frame(width: 88, height: 88)
                .background(Circle().fill(MLColor.heroBackground))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text(name)
                    .font(StudentType.heroTitle)
                    .foregroundStyle(MLColor.ink)
                Text(YouCopy.idAndMess(profile.maskedID, profile.messName))
                    .font(StudentType.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func mainCard(_ profile: StudentProfileSummary) -> some View {
        YouCard {
            YouRow(symbol: "arrow.right", title: YouCopy.outings,
                   status: outingsModel?.outings.value?.current.first.map { OutingStudentCopy.chip($0.stage) }) { path.append(.outings) }
            YouDivider()
            YouRow(symbol: "gift", title: YouCopy.credits, value: profile.credits.map(YouCopy.points)) { path.append(.credits) }
            YouDivider()
            YouRow(symbol: "calendar", title: YouCopy.attendance) { path.append(.attendance) }
            YouDivider()
            YouRow(symbol: "indianrupeesign", title: YouCopy.spending) { path.append(.spending) }
            YouDivider()
            YouRow(symbol: "text.bubble", title: YouCopy.myFeedback) { path.append(.myFeedback) }
        }
    }

    private var settingsCard: some View {
        YouCard {
            YouRow(symbol: "questionmark.circle", title: YouCopy.help) { path.append(.help) }
            YouDivider()
            YouRow(symbol: "lock.shield", title: YouCopy.terms) { path.append(.privacy) }
            YouDivider()
            YouRow(symbol: "rectangle.portrait.and.arrow.right", title: YouCopy.signOut, showsChevron: false, action: onSignOut)
        }
    }
}

/// The white rounded card that holds the You rows.
struct YouCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .padding(.horizontal, MLSpacing.s16)
            .padding(.vertical, MLSpacing.s8)
            .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.surface))
    }
}

struct YouDivider: View {
    var body: some View {
        Rectangle().fill(MLColor.border).frame(height: 1).padding(.leading, 0)
    }
}

/// A row of the You card: a 44 pt quiet square with the icon, the title, an optional status line or value, a chevron.
struct YouRow: View {
    let symbol: String
    let title: String
    var status: String?
    var value: String?
    var showsChevron = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s16) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MLColor.ink)
                    .frame(width: MLSize.hit, height: MLSize.hit)
                    .background(RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous).fill(MLColor.fillQuiet))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(MLColor.ink)
                    if let status {
                        HStack(spacing: 6) {
                            Circle().fill(MLColor.lime).overlay(Circle().strokeBorder(MLColor.limeOutline, lineWidth: 1))
                                .frame(width: 10, height: 10)
                                .accessibilityHidden(true)
                            Text(status)
                                .font(StudentType.secondary)
                                .foregroundStyle(MLColor.inkSecondary)
                        }
                    }
                }
                Spacer(minLength: MLSpacing.s8)
                if let value {
                    Text(value)
                        .font(StudentType.mono)
                        .foregroundStyle(MLColor.ink)
                }
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MLColor.ink)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, MLSpacing.s8)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Credits

/// Credits (221:64313) and its states: Getting a ticket (221:64396), Failed (221:65873), Empty (221:65843),
/// Loading (221:65904), Offline (221:65917), Error (221:65941). Get runs: Getting… → the ticket → Used after use.
struct StudentCreditsView: View {
    @State var model: StudentYouViewModel
    @State var rewards: StudentRewardsViewModel
    let onHistory: () -> Void
    let onTicket: (StudentRewardTicketID) -> Void

    var body: some View {
        MLScreen(YouCopy.credits, subtitle: YouCopy.creditsSubtitle, bottomClearance: .tabBar) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                content
            }
        }
        .refreshable { await model.loadCredits() }
        .task { await model.loadCredits() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.credits {
        case .idle, .loading:
            YouSkeleton(heights: [146, 80, 80, 80], label: YouCopy.credits)
        case .failed(let failure):
            MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
        case .empty:
            MealsStateCard(title: YouCopy.noBalance, detail: "")
        case .loaded(let credits), .stale(let credits, _):
            creditsBody(credits, offline: false)
        case .offline(let credits, _):
            StudentOfflineBanner(text: YouCopy.creditsOffline)
            if let credits { creditsBody(credits, offline: true) }
        }
    }

    @ViewBuilder
    private func creditsBody(_ credits: StudentCredits, offline: Bool) -> some View {
        balanceCard(credits)
        Text(YouCopy.tickets)
            .font(StudentType.section)
            .foregroundStyle(MLColor.ink)
            .accessibilityAddTraits(.isHeader)
        if let failed = rewards.failedReward, let name = credits.tickets.first(where: { $0.id == failed })?.name {
            HStack(alignment: .top, spacing: MLSpacing.s8) {
                Image(systemName: "exclamationmark.triangle").accessibilityHidden(true)
                Text(RewardsCopy.couldNotGet(name)).font(StudentType.bodySemibold)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .foregroundStyle(MLColor.danger)
            .padding(MLSpacing.s16)
            .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(StudentTint.errorFill))
            .overlay(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).strokeBorder(MLColor.danger))
            .mlTransition(.fromTop)
        }
        ForEach(credits.tickets) { ticket in
            CreditTicketCard(ticket: ticket, balance: credits.balance, enabled: !offline && rewards.getting == nil,
                             state: rewards.getting == ticket.id ? .getting
                                 : (rewards.failedReward == ticket.id ? .failed : .idle)) {
                Task {
                    if let id = await rewards.get(ticket.id) {
                        await model.loadCredits()
                        onTicket(id)
                    }
                }
            }
        }
        YouCard {
            YouRow(symbol: "clock", title: YouCopy.history, action: onHistory)
        }
    }

    private func balanceCard(_ credits: StudentCredits) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            if let balance = credits.balance {
                HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                    Text("\(balance)")
                        .font(.system(size: 56, weight: .medium, design: .monospaced))
                        .foregroundStyle(MLColor.onHero)
                        .mlNumericText(balance)
                    Text(YouCopy.pts)
                        .font(StudentType.section)
                        .foregroundStyle(MLColor.onHeroSecondary)
                }
                .accessibilityElement(children: .combine)
                if let goal = credits.nextGoal {
                    Text(YouCopy.moreFor(goal.missing, goal.ticket.name))
                        .font(StudentType.secondary)
                        .foregroundStyle(MLColor.onHeroSecondary)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.25))
                            Capsule().fill(MLColor.lime)
                                .frame(width: geometry.size.width * CGFloat(balance) / CGFloat(max(goal.ticket.cost, 1)))
                        }
                    }
                    .frame(height: 10)
                    .accessibilityHidden(true)
                }
            } else {
                Text(YouCopy.noBalance)
                    .font(StudentType.body)
                    .foregroundStyle(MLColor.onHero)
            }
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.heroBackground))
    }
}

/// A ticket with its notch and the cost stub (Ticket 221:64313). A ticket not offered yet is dashed.
struct CreditTicketCard: View {
    enum GetState { case idle, getting, failed }

    let ticket: StudentCreditTicket
    let balance: Int?
    let enabled: Bool
    var state: GetState = .idle
    let onGet: () -> Void

    private var notYet: Bool { if case .notYet = ticket.availability { return true } else { return false } }
    private var canGet: Bool { !notYet && enabled && (balance ?? 0) >= ticket.cost && balance != nil }
    private var buttonTitle: String {
        switch state {
        case .idle: YouCopy.get
        case .getting: RewardsCopy.getting
        case .failed: RewardsCopy.tryAgain
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: MLSpacing.s4) {
                    Text(ticket.name)
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(notYet ? MLColor.inkSecondary : MLColor.ink)
                    Text(ticket.place)
                        .font(StudentType.footnote)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: MLSpacing.s8)
                if notYet || (balance ?? 0) < ticket.cost {
                    Text(balance.map { YouCopy.more(max(0, ticket.cost - $0)) } ?? "")
                        .font(StudentType.mono)
                        .foregroundStyle(MLColor.inkSecondary)
                        .padding(.horizontal, MLSpacing.s16)
                        .frame(height: 44)
                        .overlay(Capsule().strokeBorder(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                } else {
                    Button(action: onGet) {
                        Text(buttonTitle)
                            .font(StudentType.dishName)
                            .foregroundStyle(MLColor.onHero)
                            .lineLimit(1)
                            .padding(.horizontal, MLSpacing.s16)
                            .frame(minWidth: 72, minHeight: 44)
                            .background(Capsule().fill(MLColor.heroBackground))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canGet)
                    .opacity(canGet || state == .getting ? 1 : 0.4)
                    .sensoryFeedback(.success, trigger: state == .getting)
                }
            }
            .padding(.horizontal, MLSpacing.s16)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(ticketShape(left: true))
            VStack(spacing: 2) {
                Text("\(ticket.cost)")
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundStyle(notYet ? MLColor.inkSecondary : MLColor.ink)
                Text(YouCopy.pts)
                    .font(StudentType.footnote)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            .frame(width: 88)
            .frame(minHeight: 80)
            .background(ticketShape(left: false))
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func ticketShape(left: Bool) -> some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: left ? StudentMetric.rowRadius : 6,
                                           bottomLeadingRadius: left ? StudentMetric.rowRadius : 6,
                                           bottomTrailingRadius: left ? 6 : StudentMetric.rowRadius,
                                           topTrailingRadius: left ? 6 : StudentMetric.rowRadius, style: .continuous)
        if notYet {
            shape.strokeBorder(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        } else {
            shape.fill(MLColor.surface)
        }
    }
}

/// Credits history (221:64443).
struct StudentCreditsHistoryView: View {
    @State var model: StudentYouViewModel
    /// Rewards · Balance issue (221:64463). Nil hides the question.
    var rewards: StudentRewardsViewModel?
    let onBack: () -> Void
    @State private var asksBalance = false

    /// On `MLScreen`: the system back button and swipe-back pop the page; `onBack` stays for callers.
    var body: some View {
        MLScreen(YouCopy.creditsHistory, bottomClearance: .tabBar) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                content
            }
        }
        .task { await model.loadCredits() }
        .mlSheet(isPresented: $asksBalance, isWorking: rewards?.balanceSend == .sending) {
            if let rewards {
                BalanceIssueSheet(model: rewards) { asksBalance = false }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let credits = model.credits.value {
            historyBody(credits)
            if rewards != nil {
                YouCard {
                    YouRow(symbol: "questionmark.circle", title: RewardsCopy.balanceQuestion) { asksBalance = true }
                }
            }
        } else if case .failed(let failure) = model.credits {
            MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
        } else {
            YouSkeleton(heights: [146, 240], label: YouCopy.creditsHistory)
        }
    }

    @ViewBuilder
    private func historyBody(_ credits: StudentCredits) -> some View {
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text(YouCopy.balance)
                    .font(StudentType.eyebrow)
                    .tracking(1.0)
                    .foregroundStyle(MLColor.onHeroSecondary)
                if let balance = credits.balance {
                    HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                        Text("\(balance)")
                            .font(.system(size: 48, weight: .medium, design: .monospaced))
                            .foregroundStyle(MLColor.onHero)
                        Text(YouCopy.pts)
                            .font(StudentType.section)
                            .foregroundStyle(MLColor.onHeroSecondary)
                    }
                } else {
                    Text(YouCopy.noBalance).font(StudentType.body).foregroundStyle(MLColor.onHero)
                }
            }
            .padding(MLSpacing.s20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.heroBackground))
            if credits.history.isEmpty {
                MealsStateCard(title: YouCopy.noHistoryTitle, detail: YouCopy.noHistoryDetail)
            } else {
                Text(YouFormat.month(credits.history[0].day, in: model.timeZone).uppercased())
                    .font(StudentType.eyebrow)
                    .tracking(1.0)
                    .foregroundStyle(MLColor.inkSecondary)
                YouCard {
                    ForEach(Array(credits.history.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 { YouDivider() }
                        HStack {
                            Text(YouCopy.entryLine(entry.title, YouFormat.shortDay(entry.day, in: model.timeZone)))
                                .font(StudentType.secondary)
                                .foregroundStyle(MLColor.ink)
                            Spacer(minLength: MLSpacing.s8)
                            Text(YouCopy.signed(entry.points))
                                .font(StudentType.mono)
                                .foregroundStyle(MLColor.ink)
                        }
                        .frame(minHeight: 46)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
    }
}

// MARK: - Attendance

/// Attendance (221:64717) and Attendance · Offline (2173:266).
struct StudentAttendanceView: View {
    @State var model: StudentYouViewModel
    let onBack: () -> Void

    /// On `MLScreen`: the system back button and swipe-back pop the page; `onBack` stays for callers.
    var body: some View {
        MLScreen(YouCopy.attendance, subtitle: YouCopy.attendanceSubtitle, bottomClearance: .tabBar) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                content
            }
        }
        .refreshable { await model.loadAttendance() }
        .task { await model.loadAttendance() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.attendance {
        case .idle, .loading:
            YouSkeleton(heights: [150, 340], label: YouCopy.attendance)
        case .failed(let failure):
            MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
        case .empty:
            MealsStateCard(title: YouCopy.countsMissing, detail: "")
        case .loaded(let month), .stale(let month, _):
            summary(month)
            calendar(month)
        case .offline(let month, _):
            StudentOfflineBanner(text: YouCopy.attendanceOffline)
            if let month {
                summary(month)
                calendar(month)
            }
        }
    }

    private func summary(_ month: StudentAttendanceMonth) -> some View {
        HStack(spacing: MLSpacing.s20) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.2), lineWidth: 12)
                if let percent = month.percentEntered {
                    Circle()
                        .trim(from: 0, to: CGFloat(percent) / 100)
                        .stroke(MLColor.lime, style: StrokeStyle(lineWidth: 12, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                    Text("\(percent)%")
                        .font(StudentType.secondaryMedium)
                        .foregroundStyle(MLColor.onHero)
                }
            }
            .frame(width: 100, height: 100)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                if let entered = month.mealsEntered, let served = month.mealsServed {
                    Text(YouCopy.mealsOf(entered, served))
                        .font(StudentType.section)
                        .foregroundStyle(MLColor.onHero)
                    Text(YouCopy.cameThisMonth)
                        .font(StudentType.secondary)
                        .foregroundStyle(MLColor.onHeroSecondary)
                } else {
                    Text(YouCopy.countsMissing)
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(MLColor.onHero)
                }
                if month.bestStreak > 0 {
                    Text(YouCopy.bestStreak(month.bestStreak))
                        .font(StudentType.secondaryMedium)
                        .foregroundStyle(MLColor.lime)
                        .padding(.top, MLSpacing.s4)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(MLSpacing.s20)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.heroBackground))
        .accessibilityElement(children: .combine)
    }

    private func calendar(_ month: StudentAttendanceMonth) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        let cells: [Int?] = Array(repeating: nil, count: month.firstWeekdayOffset) + (1...month.daysInMonth).map { Optional($0) }
        return VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Text(YouFormat.month(month.month, in: model.timeZone))
                .font(StudentType.bodySemibold)
                .foregroundStyle(MLColor.ink)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(YouCopy.weekdays.enumerated()), id: \.offset) { _, day in
                    Text(day).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
                }
                ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        AttendanceDayCell(day: day, mark: month.marks[day] ?? .noRecord)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
            HStack(spacing: MLSpacing.s16) {
                legend(filled: true, YouCopy.everyMeal)
                legend(filled: false, YouCopy.noEntry)
            }
            Text(YouCopy.missingScanNote)
                .font(StudentType.footnote)
                .foregroundStyle(MLColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MLSpacing.s20)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.surface))
    }

    private func legend(filled: Bool, _ text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(filled ? MLColor.ink : Color.clear)
                .overlay(Circle().strokeBorder(MLColor.ink, lineWidth: 1.5))
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
            Text(text).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
        }
    }
}

struct AttendanceDayCell: View {
    let day: Int
    let mark: StudentAttendanceMark

    var body: some View {
        Text("\(day)")
            .font(StudentType.secondaryMedium)
            .foregroundStyle(mark == .everyMeal ? MLColor.onHero : (mark == .noRecord ? MLColor.inkSecondary : MLColor.ink))
            .frame(width: 40, height: 40)
            .background {
                switch mark {
                case .everyMeal: Circle().fill(MLColor.heroBackground)
                case .noEntryForAMeal: Circle().strokeBorder(MLColor.ink, lineWidth: 1.5)
                case .today: Circle().fill(MLColor.lime).overlay(Circle().strokeBorder(MLColor.limeOutline, lineWidth: 1.5))
                case .noRecord: EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel(accessibility)
    }

    private var accessibility: String {
        switch mark {
        case .everyMeal: return "\(day), \(YouCopy.everyMeal)"
        case .noEntryForAMeal: return "\(day), \(YouCopy.noEntry)"
        case .today: return "\(day), \(YouCopy.today)"
        case .noRecord: return "\(day)"
        }
    }
}
