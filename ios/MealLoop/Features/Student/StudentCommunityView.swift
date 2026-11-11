import SwiftUI

// Coverage (student-all G4): Community · Issue · Backed (221:63679), Issue · Sending (1403:14739), Issue · Offline
// (1403:15023) and Me too failed (1403:14942) are states of the issue page below. Community · Fixed (1403:14841, "Fixed
// problems stay here for 30 days.") and the Comments frames (221:63691, 221:63752, 221:63775, 221:63799, 221:63823,
// 221:63846, 221:63871, 221:65532, 221:65555) are not built: they carry policy (retention, comment moderation).

/// Words of the Community and Report frames (page 07). This is wording, not data.
enum CommunityCopy {
    static let title = "Community"
    static let subtitle = "Problems students want fixed"
    static let open = "Open"
    static let fixed = "Fixed"
    static let meToo = "Me too"
    static let sending = "Sending…"
    static let backed = "Backed"
    static let undo = "Undo"
    static let waiting = "Waiting"
    static let students = "students"
    static let issue = "Issue"
    static let backingThis = "STUDENTS BACKING THIS"
    static let noOpenTitle = "No open problems"
    static let noOpenDetail = "When students report the same thing, it shows here."
    static let noFixedTitle = "Nothing fixed yet"
    /// Community · Fixed · Empty says "for 30 days"; no document sets how long, so no time is given.
    static let noFixedDetail = "Fixed problems show here."
    static let reportProblem = "Report a problem"
    static let offline = "You're offline. Me too will send when you're back."
    static let meTooFailed = "Me too didn't send. Try again."
    static let about = "About Community"
    static let waitLongest = "When the wait is longest · lunch"
    static func peak(_ time: String, minutes: Int) -> String { "Peak at \(time), about \(minutes) min" }
    static func messUpdated(_ mess: String, _ ago: String) -> String { "\(mess) · updated \(ago)" }
    static func messReported(_ mess: String, _ day: String) -> String { "\(mess) · reported \(day)" }
    static func stage(_ stage: StudentIssueStage) -> String {
        switch stage {
        case .reported: return "Reported"
        case .seen: return "Seen by the team"
        case .fixing: return "Fixing"
        case .fixed: return "Fixed"
        }
    }
    static func stageShort(_ stage: StudentIssueStage) -> String {
        switch stage {
        case .reported: return "Reported"
        case .seen: return "Seen"
        case .fixing: return "Fixing"
        case .fixed: return "Fixed"
        }
    }
    static func backersLabel(_ count: Int) -> String { "\(count) students backing this" }

    static func ago(_ date: Date, now: Date) -> String {
        let minutes = max(0, Int(now.timeIntervalSince(date) / 60))
        if minutes < 60 { return "\(max(1, minutes)) min ago" }
        if minutes < 24 * 60 { return "\(minutes / 60) h ago" }
        return "\(minutes / (24 * 60)) d ago"
    }
}

enum StudentCommunityRoute: Hashable {
    case issue(CommunityIssueID)
    case report
    /// SOS · new (2162:6), from "Unsafe or unwell? Use SOS" on What's wrong.
    case sos
    case comingSoon(String)

    /// Pages built on `MLScreen`: the system bar, its back button and the swipe-back gesture.
    var usesSystemBar: Bool {
        switch self {
        case .issue, .report, .sos: true
        case .comingSoon: false
        }
    }
}

/// Builds the view model from the environment.
struct StudentCommunityScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session

    var body: some View {
        if let model = StudentCommunityViewModel(session: session, repositories: environment.repositories, clock: environment.clock) {
            StudentCommunityView(model: model, session: session)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// Community (221:63630) and its states (221:63655, 221:63667, 221:65474, 221:65493, 221:65506, 221:65518).
struct StudentCommunityView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: StudentCommunityViewModel
    @State private var path: [StudentCommunityRoute] = []
    @State private var showsFixed = false
    /// Community · Info sheet (1535:114372).
    @State private var showsInfo = false
    let session: Session

    init(model: StudentCommunityViewModel, session: Session) {
        _model = State(initialValue: model)
        self.session = session
    }

    var body: some View {
        NavigationStack(path: $path) {
            // The tab root: a large title that collapses into the bar, the info button in the bar.
            MLScreen(CommunityCopy.title, subtitle: CommunityCopy.subtitle, bottomClearance: .tabBar) {
                StudentGlassButton(symbol: "info.circle", label: CommunityCopy.about) { showsInfo = true }
            } content: {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    CommunitySegments(showsFixed: $showsFixed)
                    content
                }
            }
            .refreshable { await model.load() }
            .navigationDestination(for: StudentCommunityRoute.self) { route in
                destination(route)
                    .studentPushedPage(usesSystemBar: route.usesSystemBar)
            }
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
        .mlSheet(isPresented: $showsInfo) {
            CommunityInfoSheet { showsInfo = false }
        }
    }

    @ViewBuilder
    private func destination(_ route: StudentCommunityRoute) -> some View {
        switch route {
        case .issue(let id):
            StudentIssueView(model: model, id: id,
                             records: StudentRecordsViewModel(session: session, repositories: environment.repositories,
                                                              clock: environment.clock)) { path.removeLast() }
        case .report:
            // View report leaves the finished report for the issue, so Back from the issue returns to Community.
            StudentReportScreen(session: session, onShowIssue: { path = [.issue($0)] }, onSOS: { path.append(.sos) }) {
                path.removeLast()
            }
        case .sos:
            StudentSOSScreen(session: session) { path.removeLast() }
        case .comingSoon(let title):
            StudentComingSoonView(title: title) { path.removeLast() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            ForEach([168, 168, 120], id: \.self) { height in
                RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous)
                    .fill(MLColor.track.opacity(0.8))
                    .frame(height: CGFloat(height))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(StudentCopy.gettingMeals)
        case .failed(let failure):
            MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
        case .loaded, .stale, .empty, .offline:
            if model.isOffline {
                StudentOfflineBanner(text: CommunityCopy.offline)
            }
            if let failed = model.failed, model.issue(failed) != nil {
                Text(CommunityCopy.meTooFailed)
                    .font(StudentType.secondaryMedium)
                    .foregroundStyle(MLColor.danger)
            }
            let issues = model.issues(fixed: showsFixed)
            if issues.isEmpty {
                if showsFixed {
                    MealsStateCard(title: CommunityCopy.noFixedTitle, detail: CommunityCopy.noFixedDetail)
                } else {
                    MealsStateCard(title: CommunityCopy.noOpenTitle, detail: CommunityCopy.noOpenDetail)
                    InkActionButton(title: CommunityCopy.reportProblem) { path.append(.report) }
                }
            } else {
                ForEach(issues) { issue in
                    CommunityIssueCard(issue: issue, now: model.now, sending: model.sending == issue.id,
                                       waiting: model.waiting.contains(issue.id),
                                       onOpen: { path.append(.issue(issue.id)) },
                                       onMeToo: { Task { await model.meToo(issue.id) } },
                                       onUndo: { Task { await model.undo(issue.id) } })
                }
            }
        }
    }
}

/// Open | Fixed, a white pill on the track.
struct CommunitySegments: View {
    @Binding var showsFixed: Bool

    var body: some View {
        HStack(spacing: 2) {
            segment(CommunityCopy.open, selected: !showsFixed) { showsFixed = false }
            segment(CommunityCopy.fixed, selected: showsFixed) { showsFixed = true }
        }
        .padding(4)
        .background(Capsule().fill(MLColor.track.opacity(0.6)))
    }

    private func segment(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(selected ? StudentType.bodySemibold : StudentType.secondary)
                .foregroundStyle(MLColor.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background { if selected { Capsule().fill(MLColor.surface) } }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Four segments: Reported, Seen, Fixing, Fixed.
struct CommunityStageBar: View {
    let stage: StudentIssueStage
    var onDark = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(StudentIssueStage.allCases, id: \.self) { step in
                Capsule()
                    .fill(step <= stage ? (onDark ? MLColor.lime : MLColor.ink) : (onDark ? Color.white.opacity(0.25) : MLColor.track))
                    .frame(height: 6)
            }
        }
        .accessibilityHidden(true)
    }
}

struct CommunityIssueCard: View {
    let issue: StudentIssue
    let now: Date
    let sending: Bool
    let waiting: Bool
    let onOpen: () -> Void
    let onMeToo: () -> Void
    let onUndo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: MLSpacing.s8) {
                    Text(issue.title)
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(MLColor.ink)
                        .multilineTextAlignment(.leading)
                    Text(CommunityCopy.messUpdated(issue.messName, CommunityCopy.ago(issue.updatedAt, now: now)))
                        .font(StudentType.secondary)
                        .foregroundStyle(MLColor.inkSecondary)
                    CommunityStageBar(stage: issue.stage)
                    Text([CommunityCopy.stage(issue.stage), issue.stageNote].compactMap { $0 }.joined(separator: " · "))
                        .font(StudentType.secondary)
                        .foregroundStyle(MLColor.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(issue.backers)")
                        .font(.system(size: 28, weight: .medium, design: .monospaced))
                        .foregroundStyle(MLColor.ink)
                    Text(CommunityCopy.students)
                        .font(StudentType.secondary)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(CommunityCopy.backersLabel(issue.backers))
                Spacer()
                if issue.stage != .fixed {
                    MeTooButton(isBacked: issue.isBackedByMe, sending: sending, waiting: waiting, onDark: false,
                                onMeToo: onMeToo, onUndo: onUndo)
                }
            }
        }
        .padding(MLSpacing.s20)
        .background(RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous).fill(MLColor.surface))
    }
}

/// Me too → Sending… → Backed, with Undo under it (221:63655, 221:63667).
struct MeTooButton: View {
    let isBacked: Bool
    let sending: Bool
    let waiting: Bool
    let onDark: Bool
    let onMeToo: () -> Void
    let onUndo: () -> Void

    var body: some View {
        if isBacked {
            VStack(spacing: 4) {
                Button(action: {}) {
                    Label(CommunityCopy.backed, systemImage: "checkmark")
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(onDark ? MLColor.onHero : MLColor.ink)
                        .padding(.horizontal, MLSpacing.s24)
                        .frame(minHeight: 48)
                        .overlay(Capsule().strokeBorder(onDark ? MLColor.onHero : MLColor.ink, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .allowsHitTesting(false)
                Button(action: onUndo) {
                    Text(CommunityCopy.undo)
                        .font(StudentType.footnote)
                        .underline()
                        .foregroundStyle(onDark ? MLColor.onHeroSecondary : MLColor.inkSecondary)
                        .frame(minHeight: 28)
                }
                .buttonStyle(.plain)
            }
        } else {
            Button(action: onMeToo) {
                Text(sending ? CommunityCopy.sending : (waiting ? CommunityCopy.waiting : CommunityCopy.meToo))
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(onDark ? MLColor.onLime : MLColor.onHero)
                    .padding(.horizontal, MLSpacing.s24)
                    .frame(maxWidth: onDark ? .infinity : nil)
                    .frame(height: onDark ? 56 : 48)
                    .background(Capsule().fill(onDark ? MLColor.lime : (sending || waiting ? MLColor.inkSecondary : MLColor.ink)))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .allowsHitTesting(!sending && !waiting)
        }
    }
}

/// Community · Issue (221:63643) and Community · Issue · Hidden (221:65484).
struct StudentIssueView: View {
    @State var model: StudentCommunityViewModel
    let id: CommunityIssueID
    /// The updates under the backing card. Nil where no records source is wired.
    var records: StudentRecordsViewModel?
    let onBack: () -> Void

    /// On `MLScreen`: the issue's title is the large title, and the system back button and swipe-back pop the page.
    var body: some View {
        MLScreen(model.issue(id)?.title ?? CommunityCopy.issue, subtitle: model.issue(id).map(reportedLine),
                 bottomClearance: .tabBar) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                if let issue = model.issue(id) {
                    details(issue)
                } else {
                    MealsStateCard(symbol: "exclamationmark.circle", title: CommunityCopy.issue, detail: "")
                }
            }
        }
        .task {
            await model.loadCrowd()
            await records?.loadUpdates(for: id)
        }
    }

    private func reportedLine(_ issue: StudentIssue) -> String {
        CommunityCopy.messReported(issue.messName, StudentFormat.mediumDay(issue.reportedOn, in: model.timeZone))
    }

    @ViewBuilder
    private func details(_ issue: StudentIssue) -> some View {
        if let hidden = issue.hiddenReason {
            HStack(alignment: .top, spacing: MLSpacing.s12) {
                Image(systemName: "lock").accessibilityHidden(true)
                Text(hidden).font(StudentType.secondary).fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(MLColor.ink)
            .padding(MLSpacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).strokeBorder(MLColor.border, lineWidth: 1))
        }
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Text(CommunityCopy.backingThis)
                .font(StudentType.eyebrow)
                .tracking(1.0)
                .foregroundStyle(MLColor.onHeroSecondary)
            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                Text("\(issue.backers)")
                    .font(.system(size: 52, weight: .medium, design: .monospaced))
                    .foregroundStyle(MLColor.onHero)
                Text(CommunityCopy.students)
                    .font(StudentType.body)
                    .foregroundStyle(MLColor.onHeroSecondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(CommunityCopy.backersLabel(issue.backers))
            CommunityStageBar(stage: issue.stage, onDark: true)
            HStack {
                ForEach(StudentIssueStage.allCases, id: \.self) { step in
                    Text(CommunityCopy.stageShort(step))
                        .font(step == issue.stage ? StudentType.secondaryMedium : StudentType.secondary)
                        .foregroundStyle(step == issue.stage ? MLColor.onHero : MLColor.onHeroSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(CommunityCopy.stage(issue.stage))
            if issue.hiddenReason == nil && issue.stage != .fixed {
                MeTooButton(isBacked: issue.isBackedByMe, sending: model.sending == issue.id, waiting: model.waiting.contains(issue.id),
                            onDark: true, onMeToo: { Task { await model.meToo(issue.id) } },
                            onUndo: { Task { await model.undo(issue.id) } })
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(MLSpacing.s20)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.heroBackground))
        if issue.isAboutWaiting, let crowd = model.crowd, !crowd.slots.isEmpty {
            waitCard(crowd)
        }
        if let updates = records?.updates, !updates.isEmpty {
            issueUpdates(updates)
        }
        if issue.hiddenReason == nil && issue.stage != .fixed {
            Text(RecordsCopy.meTooFootnote)
                .font(StudentType.footnote)
                .foregroundStyle(MLColor.inkSecondary)
                .frame(maxWidth: .infinity)
        }
    }

    /// Timeline (221:63643): what the mess team did, then the next step, hollow. It names no person. The "4 comments"
    /// row under it is not built: student comments are not an owner decision.
    private func issueUpdates(_ updates: [StudentIssueUpdate]) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            ForEach(Array(updates.enumerated()), id: \.offset) { _, update in
                HStack(alignment: .top, spacing: MLSpacing.s12) {
                    Circle()
                        .fill(update.isNext ? Color.clear : MLColor.ink)
                        .overlay(Circle().strokeBorder(update.isNext ? MLColor.inkSecondary : MLColor.ink, lineWidth: 1.5))
                        .frame(width: 12, height: 12)
                        .padding(.top, 5)
                        .accessibilityHidden(true)
                    Text(update.isNext ? RecordsCopy.next(update.title)
                         : RecordsCopy.withWhen(update.title, update.at.map {
                             "\(StudentFormat.mediumDay($0, in: model.timeZone)), \(MLFormat.time($0, in: model.timeZone))" }))
                        .font(StudentType.secondary)
                        .foregroundStyle(update.isNext ? MLColor.inkSecondary : MLColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.surface))
    }

    /// "When the wait is longest": the Crowd estimate's pattern, with its busiest slot drawn lime.
    private func waitCard(_ crowd: StudentCrowd) -> some View {
        let busiest = crowd.slots.indices.max { crowd.slots[$0].activity < crowd.slots[$1].activity }
        return VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Text(CommunityCopy.waitLongest)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
            if let at = crowd.busiestAt, let minutes = crowd.busiestWaitMinutes {
                Text(CommunityCopy.peak(MLFormat.time(at, in: model.timeZone), minutes: minutes))
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(MLColor.ink)
            }
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(crowd.slots.enumerated()), id: \.offset) { index, slot in
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(index == busiest ? MLColor.lime : MLColor.ink)
                        .overlay {
                            if index == busiest {
                                RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(MLColor.limeOutline, lineWidth: 1.5)
                            }
                        }
                        .frame(width: 30, height: max(14, 80 * CGFloat(slot.activity)))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 84, alignment: .bottom)
            .accessibilityHidden(true)
            HStack {
                ForEach(Array([0.0, 3600, 7200].enumerated()), id: \.offset) { index, offset in
                    if index > 0 { Spacer() }
                    Text(crowd.slots.first.map { MealsFormat.clock($0.startsAt.addingTimeInterval(offset), in: model.timeZone) } ?? "")
                }
            }
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundStyle(MLColor.inkSecondary)
            .accessibilityHidden(true)
        }
        .padding(MLSpacing.s20)
        .background(RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
        .accessibilityHint(MealsCopy.estimateSpoken)
    }
}

/// Community · Info sheet (1535:114372): How Community works, in three short items. Sized to its content.
struct CommunityInfoSheet: View {
    let onClose: () -> Void

    private static let items: [(title: String, detail: String)] = [
        ("Who sees it", "Your mess food head and the mess team. Others see how many back a report, never who."),
        ("What to write", "The dish or the place, not a person."),
        ("Same problem?", "Tap Me too instead of a new report. You can undo it."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: "How Community works", onClose: onClose)
            ForEach(Self.items, id: \.title) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).font(StudentType.bodySemibold).foregroundStyle(MLColor.ink)
                    Text(item.detail).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
