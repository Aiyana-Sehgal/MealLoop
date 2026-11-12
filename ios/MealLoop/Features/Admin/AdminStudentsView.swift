import SwiftUI

/// What Students shows for the signed-in scope. The Super Admin reads every mess; the Food Head reads their own mess,
/// where the source holds who has not answered but not the yes, no and not sure split.
enum AdminStudentsSummary: Equatable {
    case allMesses(AdminStudentsOverview)
    case oneMess(SingleMessStudents)

    var mealTitle: String {
        switch self {
        case .allMesses(let value): return value.mealTitle
        case .oneMess(let value): return value.mealTitle
        }
    }
    var mealLongTitle: String {
        switch self {
        case .allMesses(let value): return value.mealLongTitle
        case .oneMess(let value): return value.mealLongTitle
        }
    }
    /// Nil when the source does not hold it, never zero.
    var notAnswered: Int? {
        switch self {
        case .allMesses(let value): return value.notAnswered
        case .oneMess(let value): return value.notAnswered
        }
    }
    var reminderMessage: String {
        switch self {
        case .allMesses(let value): return value.reminderMessage
        case .oneMess(let value): return value.reminderMessage
        }
    }
    var reminderSentAt: Date? {
        switch self {
        case .allMesses(let value): return value.reminderSentAt
        case .oneMess(let value): return value.reminderSentAt
        }
    }
    var feedback: [FeedbackItem] {
        switch self {
        case .allMesses(let value): return value.feedback
        case .oneMess(let value): return value.feedback
        }
    }
    var community: [AdminCommunityIssue] {
        switch self {
        case .allMesses(let value): return value.community
        case .oneMess(let value): return value.community
        }
    }
}

/// Students (SA02, AD03): who has answered the next meal, and what students have raised. Counts only, never a name.
@MainActor
@Observable
final class AdminStudentsViewModel {
    private(set) var state: LoadState<AdminStudentsSummary> = .idle
    private(set) var isSending = false
    private(set) var errorText: String?

    private let students: any AdminStudentsRepository
    private let role: Role
    private let allMesses: Bool
    /// One key per screen, so a double tap reminds once.
    private let key = IdempotencyKey.make()

    init(students: any AdminStudentsRepository, role: Role, allMesses: Bool = true) {
        self.students = students
        self.role = role
        self.allMesses = allMesses
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            if allMesses {
                let overview = try await students.studentsOverview()
                state = overview.totalStudents == 0 ? .empty : .loaded(.allMesses(overview))
            } else {
                state = .loaded(.oneMess(try await singleMess().singleMessStudents()))
            }
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    func remind() async -> Bool {
        guard !isSending else { return false }
        isSending = true
        errorText = nil
        defer { isSending = false }
        do {
            if allMesses {
                state = .loaded(.allMesses(try await students.remind(key: key, by: role)))
            } else {
                state = .loaded(.oneMess(try await singleMess().remindMess(key: key, by: role)))
            }
            return true
        } catch {
            errorText = AdminWriteError.text(error)
            return false
        }
    }

    private func singleMess() throws -> any SingleMessStudentsRepository {
        guard let source = students as? any SingleMessStudentsRepository else {
            throw RepositoryError.notImplemented(feature: "Students for this mess")
        }
        return source
    }
}

struct AdminStudentsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        AdminStudentsView(model: AdminStudentsViewModel(students: environment.repositories.adminStudents, role: nav.context.account.role,
                                                        allMesses: nav.context.allMesses), nav: nav)
    }
}

struct AdminStudentsView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: AdminStudentsViewModel
    let nav: AdminNav

    @State private var isReminding: Bool

    /// - Parameter remindOpen: opens the Remind sheet at once (previews and the verification captures).
    init(model: AdminStudentsViewModel, nav: AdminNav, remindOpen: Bool = false) {
        _model = State(initialValue: model)
        _isReminding = State(initialValue: remindOpen)
        self.nav = nav
    }

    private var timeZone: TimeZone { nav.timeZone }
    private var messName: String { AdminCopy.tileName(nav.context.mess.name) }

    var body: some View {
        AdminPageScaffold(title: AdminScreenCopy.studentsTitle, subtitle: subtitle) {
            AsyncContentView(state: model.state, timeZone: timeZone, retry: { await model.load() }) { summary in
                content(summary)
            }
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
        .mlSheet(isPresented: $isReminding, isWorking: model.isSending) {
            if let summary = model.state.value {
                remindSheet(summary)
            }
        }
    }

    private var subtitle: String? {
        guard let meal = model.state.value?.mealTitle else { return nil }
        return AdminStudentsCopy.subtitle(nav.context.allMesses ? AdminStudentsCopy.allMesses : nav.context.mess.name, meal: meal)
    }

    private func content(_ summary: AdminStudentsSummary) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            switch summary {
            case .allMesses(let overview):
                allMessesHero(overview)
                pair { notYetTile(summary) } trailing: { skippedTile(overview) }
                byMessTile(overview.byMess)
            case .oneMess(let mess):
                oneMessHero(mess)
                pair { notYetTile(summary) } trailing: { splitNotAvailableTile }
            }
            pair { feedbackTile(summary.feedback) } trailing: { communityTile(summary.community) }
        }
    }

    /// Two tiles side by side, one height.
    private func pair<A: View, B: View>(@ViewBuilder leading: () -> A, @ViewBuilder trailing: () -> B) -> some View {
        HStack(alignment: .top, spacing: MLSpacing.s12) {
            leading().frame(maxHeight: .infinity)
            trailing().frame(maxHeight: .infinity)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Heroes

    /// SA02: answered of all students, the split in one bar and four labelled numbers.
    private func allMessesHero(_ overview: AdminStudentsOverview) -> some View {
        BentoTile(kind: .hero) {
            HeroEyebrow(label: AdminStudentsCopy.answered)
            heroNumber(AdminFormat.count(overview.answered), of: AdminStudentsCopy.ofTotal(AdminFormat.count(overview.totalStudents)))
            StackedBar(parts: [
                .init(id: "yes", value: overview.yes, color: MLColor.lime),
                .init(id: "no", value: overview.no, color: MLColor.onHero),
                .init(id: "notSure", value: overview.notSure, color: MLColor.onHeroSecondary),
                .init(id: "notYet", value: overview.notAnswered, color: MLColor.onHero.opacity(0.2)),
            ])
            .padding(.vertical, MLSpacing.s8)
            HStack(alignment: .top, spacing: MLSpacing.s8) {
                figure(AdminScreenCopy.yes, overview.yes)
                figure(AdminScreenCopy.no, overview.no)
                figure(AdminScreenCopy.notSure, overview.notSure)
                figure(AdminStudentsCopy.notYet, overview.notAnswered)
            }
        }
    }

    /// AD03: answered of about the mess's size, one bar, the derived share. Each missing figure is a dash.
    private func oneMessHero(_ mess: SingleMessStudents) -> some View {
        BentoTile(kind: .hero) {
            HeroEyebrow(label: AdminStudentsCopy.answered)
            heroNumber(mess.answered.map(AdminFormat.count), of: mess.students.map { AdminStudentsCopy.ofAbout(AdminFormat.count($0)) })
            if let answered = mess.answered, let students = mess.students, students > 0 {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(MLColor.onHero.opacity(0.2))
                        Capsule().fill(MLColor.lime).frame(width: proxy.size.width * CGFloat(answered) / CGFloat(students))
                    }
                }
                .frame(height: 14)
                .padding(.vertical, MLSpacing.s8)
                .accessibilityHidden(true)
                BentoCaption(text: AdminStudentsCopy.answeredShare(Int((Double(answered) / Double(students) * 100).rounded()),
                                                                   mess: messName), kind: .hero)
            } else {
                BentoCaption(text: AdminStudentsCopy.notAvailableFor(messName), kind: .hero)
            }
        }
    }

    private func heroNumber(_ value: String?, of total: String?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s12) {
            Text(value ?? "—")
                .font(AdminType.heroMetric)
                .foregroundStyle(value == nil ? MLColor.onHeroSecondary : MLColor.onHero)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if let total {
                Text(total)
                    .font(AdminType.mono20)
                    .foregroundStyle(MLColor.onHeroSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func figure(_ label: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).mlFont(.secondary).foregroundStyle(MLColor.onHeroSecondary).lineLimit(1).minimumScaleFactor(0.8)
            Text(AdminFormat.count(value)).font(AdminType.mono17).foregroundStyle(MLColor.onHero).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: Tiles

    /// Lime action tile: who hasn't answered, and Remind. Once a reminder is recorded the tile says when instead.
    @ViewBuilder
    private func notYetTile(_ summary: AdminStudentsSummary) -> some View {
        let kind: BentoKind = summary.notAnswered == nil ? .dashed : .action
        BentoTile(kind: kind, fillsHeight: true) {
            BentoLabel(text: AdminStudentsCopy.notYet, kind: kind)
            BentoNumber(text: summary.notAnswered.map(AdminFormat.count), kind: kind, font: AdminType.tileMetric,
                        spoken: "\(AdminStudentsCopy.notYet), \(summary.notAnswered.map(String.init) ?? AdminCopy.noData)")
            BentoCaption(text: summary.notAnswered == nil ? AdminStudentsCopy.notAvailableFor(messName) : AdminStudentsCopy.haventAnswered,
                         kind: kind)
            Spacer(minLength: 0)
            if summary.notAnswered != nil {
                if let sentAt = summary.reminderSentAt {
                    BentoCaption(text: AdminScreenCopy.reminderSent(MLFormat.time(sentAt, in: timeZone)), kind: kind)
                } else {
                    InkActionButton(title: AdminStudentsCopy.remind) { isReminding = true }
                }
            }
        }
    }

    /// SA02: who said no, and the way to why.
    private func skippedTile(_ overview: AdminStudentsOverview) -> some View {
        BentoTile(kind: .standard, fillsHeight: true) {
            HStack(alignment: .top) {
                BentoLabel(text: AdminStudentsCopy.skipped, kind: .standard)
                Spacer(minLength: 0)
                RoundGoButton(label: AdminStudentsCopy.whySkip) { nav.push(.skipReasons) }
            }
            BentoNumber(text: AdminFormat.count(overview.no), kind: .standard, font: AdminType.tileMetric,
                        spoken: "\(AdminStudentsCopy.skipped), \(overview.no)")
            BentoCaption(text: AdminStudentsCopy.whySkip, kind: .standard)
        }
        .onTapGesture { nav.push(.skipReasons) }
    }

    /// AD03: the split is not held for one mess, so the tile says so instead of dividing the answered count.
    private var splitNotAvailableTile: some View {
        BentoTile(kind: .dashed, fillsHeight: true) {
            BentoLabel(text: AdminStudentsCopy.splitLabel, kind: .dashed)
            BentoNumber(text: nil, kind: .dashed, font: AdminType.tileMetric, spoken: AdminStudentsCopy.notAvailableFor(messName))
            BentoCaption(text: AdminStudentsCopy.notAvailableFor(messName), kind: .dashed)
        }
    }

    /// SA02: who hasn't answered, mess by mess. The highest bar is the one outlined lime; a mess with no figure is a
    /// dashed bar. Opens the not-answered page.
    @ViewBuilder
    private func byMessTile(_ rolls: [AdminMessRoll]?) -> some View {
        if let rolls, !rolls.isEmpty {
            let highest = rolls.compactMap(\.notAnswered).max() ?? 0
            Button { nav.push(.notAnswered) } label: {
                BentoTile(kind: .standard) {
                    BentoLabel(text: AdminStudentsCopy.byMess, kind: .standard)
                    BentoCaption(text: AdminStudentsCopy.byMessCaption, kind: .standard)
                    HStack(alignment: .bottom, spacing: MLSpacing.s12) {
                        ForEach(rolls) { roll in
                            messBar(roll, highest: highest)
                        }
                    }
                    .padding(.top, MLSpacing.s8)
                }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AdminStudentsCopy.byMess)
            .accessibilityValue(rolls.map { AdminStudentsCopy.spokenNotAnswered($0.mess, $0.notAnswered.map(String.init) ?? AdminCopy.noData) }
                .joined(separator: "; "))
            .accessibilityAddTraits(.isButton)
        }
    }

    private func messBar(_ roll: AdminMessRoll, highest: Int) -> some View {
        let maxHeight: CGFloat = 72
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        return VStack(spacing: MLSpacing.s4) {
            Text(roll.notAnswered.map(AdminFormat.count) ?? "—")
                .font(MLType.monoBody)
                .foregroundStyle(roll.notAnswered == nil ? MLColor.inkSecondary : MLColor.ink)
            Group {
                if let value = roll.notAnswered {
                    shape.fill(value == highest ? MLColor.lime : MLColor.ink)
                        .overlay(shape.stroke(MLColor.ink, lineWidth: 1.5))
                        .frame(height: max(16, maxHeight * CGFloat(value) / CGFloat(max(highest, 1))))
                } else {
                    shape.stroke(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .frame(height: maxHeight * 0.6)
                }
            }
            .frame(maxWidth: 48)
            Text(roll.mess)
                .mlFont(.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func feedbackTile(_ feedback: [FeedbackItem]) -> some View {
        let first = feedback.first
        Button { if let first { nav.push(.feedback(first.id)) } } label: {
            BentoTile(kind: .standard, fillsHeight: true) {
                BentoLabel(text: AdminStudentsCopy.feedback, kind: .standard)
                Text(AdminFormat.count(feedback.count))
                    .font(AdminType.tileMetric)
                    .foregroundStyle(feedback.isEmpty ? MLColor.inkSecondary : MLColor.ink)
                BentoCaption(text: first.map(AdminScreenCopy.feedbackRowTitle) ?? AdminStudentsCopy.noFeedback, kind: .standard)
                if first?.isNew == true {
                    AdminChip(text: AdminScreenCopy.new, style: .lime, isSmall: true)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(first == nil)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func communityTile(_ community: [AdminCommunityIssue]) -> some View {
        let first = community.first
        Button { if let first { nav.push(.community(first.id)) } } label: {
            BentoTile(kind: .standard, fillsHeight: true) {
                BentoLabel(text: AdminStudentsCopy.community, kind: .standard)
                Text(AdminFormat.count(community.count))
                    .font(AdminType.tileMetric)
                    .foregroundStyle(community.isEmpty ? MLColor.inkSecondary : MLColor.ink)
                BentoCaption(text: first?.title ?? AdminStudentsCopy.noReports, kind: .standard)
                if let first {
                    AdminChip(text: first.owner.map(AdminScreenCopy.ownedBy) ?? AdminScreenCopy.needsAnOwner,
                              style: AdminChipRules.community(hasOwner: first.owner != nil), isSmall: true)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(first == nil)
        .accessibilityElement(children: .combine)
    }

    // MARK: Remind

    private func remindSheet(_ summary: AdminStudentsSummary) -> some View {
        let count = summary.notAnswered.map(AdminFormat.count) ?? AdminFormat.missing
        let who: String = switch summary {
        case .allMesses: AdminScreenCopy.remindWho(count, meal: summary.mealLongTitle)
        case .oneMess(let mess): AdminStudentsCopy.remindWhoMess(count, meal: summary.mealLongTitle, mess: AdminCopy.messName(mess.mess))
        }
        return VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: AdminScreenCopy.remindStudents) { isReminding = false }
            AdminLabel(text: AdminScreenCopy.who)
            // Remind sheet 2262:237: body-size text, the message in a white bubble, one helper line, the button below.
            Text(who)
                .mlFont(.body)
                .foregroundStyle(MLColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            AdminLabel(text: AdminScreenCopy.messageLabel)
            Text(summary.reminderMessage)
                .mlFont(.body)
                .foregroundStyle(MLColor.ink)
                .padding(MLSpacing.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
                // The shared sheet is white, so the bubble takes the canvas colour to keep the frame's contrast.
                .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.canvas))
            Text(AdminScreenCopy.remindNote)
                .mlFont(.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let error = model.errorText {
                FieldErrorText(text: error)
            }
            InkActionButton(title: AdminScreenCopy.sendTo(count), isLoading: model.isSending) {
                Task {
                    if await model.remind() {
                        isReminding = false
                        nav.toast(AdminScreenCopy.reminderToast)
                    }
                }
            }
        }
    }
}

/// One piece of feedback (A06).
struct AdminFeedbackScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let id: FeedbackItemID
    let nav: AdminNav

    var body: some View {
        let students = environment.repositories.adminStudents
        let results = environment.repositories.adminResults
        AdminLoadedPage(model: AdminPageModel { [id] () -> (FeedbackItem, AdminMealFacts) in
            let item = try await students.feedback(id)
            return (item, try await results.meal(item.meal))
        }, timeZone: nav.timeZone) { value, _ in
            AdminFeedbackBody(item: value.0, meal: value.1, nav: nav)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct AdminFeedbackBody: View {
    let item: FeedbackItem
    let meal: AdminMealFacts
    let nav: AdminNav

    @State private var isTellingVendor = false
    @State private var isLoggingFix = false

    private var timeZone: TimeZone { nav.timeZone }

    var body: some View {
        AdminPageScaffold(title: "\(item.dish) · \(item.problem)",
                          subtitle: AdminScreenCopy.feedbackSubtitle(item, day: AdminFormat.weekday(item.day, in: timeZone).prefix(3).description),
                          onBack: nav.pop) {
            AdminCard {
                HStack(spacing: MLSpacing.s12) {
                    AdminDishPictogram(dish: item.dish, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.dish)
                            .font(MLType.staffPrimary)
                            .foregroundStyle(MLColor.ink)
                        Text(AdminScreenCopy.feedbackContext(item, day: AdminFormat.day(item.day, in: timeZone)))
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                AdminLabel(text: AdminScreenCopy.problemsReported)
                ForEach(item.problems) { problem in
                    problemRow(problem)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                AdminLabel(text: AdminScreenCopy.mealsLabel)
                AdminRow(title: AdminFormat.mealLine(meal, in: timeZone), detail: AdminScreenCopy.feedbackMealDetail(meal),
                         action: { nav.push(.meal(meal.id)) }) { EmptyView() }
            }
            HStack(spacing: MLSpacing.s12) {
                InkActionButton(title: AdminScreenCopy.sendToVendor) { isTellingVendor = true }
                OutlineActionButton(title: AdminScreenCopy.logAFix) { isLoggingFix = true }
            }
            AdminNote(text: AdminScreenCopy.vendorSheetNote)
        }
        .mlSheet(isPresented: $isTellingVendor) {
            AdminTellVendorSheet(subtitle: AdminScreenCopy.preparedMessage, message: AdminScreenCopy.vendorFeedback(item, name: nav.context.account.firstName),
                                 note: nil) { isTellingVendor = false }
        }
        .mlSheet(isPresented: $isLoggingFix) {
            AdminMakeChangeSheet(meal: nil, suggested: "", context: nav.context, onClose: { isLoggingFix = false }) { check in
                isLoggingFix = false
                nav.push(.check(check.id))
            }
        }
    }

    private func problemRow(_ problem: FeedbackProblem) -> some View {
        HStack(spacing: MLSpacing.s12) {
            AdminProblemIcon()
            VStack(alignment: .leading, spacing: 2) {
                Text(problem.title)
                    .font(MLType.staffBody)
                    .foregroundStyle(MLColor.ink)
                Text(problem.severity)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            Spacer(minLength: MLSpacing.s8)
            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s4) {
                Text(String(problem.students))
                    .font(AdminType.count)
                Text(AdminScreenCopy.students(problem.students))
                    .font(MLType.secondary)
            }
            .foregroundStyle(MLColor.ink)
        }
        .padding(.vertical, MLSpacing.s12)
        .overlay(alignment: .top) { Rectangle().fill(MLColor.border).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }
}

/// A Community issue (A06). Assigning an owner is not fixing it.
@MainActor
@Observable
final class AdminCommunityViewModel {
    private(set) var state: LoadState<AdminCommunityIssue> = .idle
    private(set) var owners: [String] = []
    private(set) var errorText: String?
    var note = ""

    private let id: CommunityIssueID
    private let role: Role
    private let students: any AdminStudentsRepository

    init(id: CommunityIssueID, role: Role, students: any AdminStudentsRepository) {
        self.id = id
        self.role = role
        self.students = students
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            owners = try await students.ownerChoices()
            state = .loaded(try await students.community(id))
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    func assign(_ owner: String) async -> Bool {
        await write { [students, id, role] in try await students.assignOwner(owner, to: id, by: role) }
    }

    func postNote() async -> Bool {
        let text = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }
        let didPost = await write { [students, id, role] in try await students.postNote(text, on: id, by: role) }
        if didPost { note = "" }
        return didPost
    }

    private func write(_ work: () async throws -> AdminCommunityIssue) async -> Bool {
        errorText = nil
        do {
            state = .loaded(try await work())
            return true
        } catch {
            errorText = AdminWriteError.text(error)
            return false
        }
    }
}

struct AdminCommunityScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let id: CommunityIssueID
    let nav: AdminNav

    var body: some View {
        AdminCommunityView(model: AdminCommunityViewModel(id: id, role: nav.context.account.role, students: environment.repositories.adminStudents), nav: nav)
    }
}

struct AdminCommunityView: View {
    @State private var model: AdminCommunityViewModel
    let nav: AdminNav

    @State private var isAssigning = false

    init(model: AdminCommunityViewModel, nav: AdminNav) {
        _model = State(initialValue: model)
        self.nav = nav
    }

    var body: some View {
        AdminPageScaffold(title: model.state.value?.title ?? AdminScreenCopy.community,
                          subtitle: model.state.value.map { AdminScreenCopy.communitySubtitle($0.students) }, onBack: nav.pop) {
            AsyncContentView(state: model.state, timeZone: nav.timeZone, retry: { await model.load() }) { issue in
                content(issue)
            }
        }
        .task { await model.load() }
        .mlSheet(isPresented: $isAssigning) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                SheetHeader(title: AdminScreenCopy.assignOwner) { isAssigning = false }
                AdminFlow {
                    ForEach(model.owners, id: \.self) { owner in
                        ChoiceChip(title: owner, isSelected: model.state.value?.owner == owner) {
                            Task {
                                if await model.assign(owner) {
                                    isAssigning = false
                                    nav.toast(AdminScreenCopy.ownerAssigned)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func content(_ issue: AdminCommunityIssue) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: MLSpacing.s16) {
            HeroCard {
                VStack(alignment: .leading, spacing: MLSpacing.s8) {
                    HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                        Text("\(issue.students)")
                            .font(MLType.heroNumber)
                            .foregroundStyle(MLColor.onHero)
                        Text(AdminScreenCopy.saidMeToo)
                            .font(MLType.staffBody)
                            .foregroundStyle(MLColor.onHeroSecondary)
                    }
                    Text(AdminScreenCopy.raisedOn(AdminFormat.day(issue.raisedOn, in: nav.timeZone), issue.context))
                        .font(MLType.body)
                        .foregroundStyle(MLColor.onHeroSecondary)
                }
            }
            AdminStageLine(stages: [AdminScreenCopy.stageRaised, AdminScreenCopy.stageOwner, AdminScreenCopy.stageFixed],
                           current: CommunityStage.allCases.firstIndex(of: issue.stage) ?? 0)
            AdminRow(title: AdminScreenCopy.assignOwner, detail: issue.owner.map(AdminScreenCopy.ownedBy) ?? AdminScreenCopy.nobodyOwns,
                     showsChevron: issue.owner != nil, action: { isAssigning = true }) {
                if issue.owner == nil {
                    AdminChip(text: AdminScreenCopy.needsAnOwner, style: .outline)
                }
            }
            AdminLabel(text: AdminScreenCopy.noteToStudents)
            if let posted = issue.postedNote {
                Text(posted)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.ink)
            }
            AdminTextField(placeholder: AdminScreenCopy.notePlaceholderStudents, text: $model.note, lines: 2)
            if let error = model.errorText {
                FieldErrorText(text: error)
            }
            OutlineActionButton(title: AdminScreenCopy.postNote) {
                Task {
                    if await model.postNote() { nav.toast(AdminScreenCopy.notePosted) }
                }
            }
        }
    }
}

/// Why students skip (A06). Groups under 10 stay hidden.
struct AdminSkipReasonsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        let students = environment.repositories.adminStudents
        AdminLoadedPage(model: AdminPageModel { try await students.skipReasons() }, timeZone: nav.timeZone) { skips, _ in
            AdminPageScaffold(title: AdminScreenCopy.whyStudentsSkip, subtitle: AdminScreenCopy.skipSubtitle(skips.mealTitle, skips.saidNo), onBack: nav.pop) {
                Text(AdminScreenCopy.skipIntro)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                VStack(spacing: 0) {
                    ForEach(skips.reasons) { reason in
                        AdminRow(title: reason.title, action: nil) {
                            HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s4) {
                                Text("\(reason.students)").font(AdminType.mono17)
                                Text(AdminScreenCopy.students(reason.students)).font(MLType.secondary)
                            }
                            .foregroundStyle(MLColor.ink)
                        }
                    }
                }
                AdminNote(text: AdminScreenCopy.hiddenGroups(skips.hiddenGroups, noReason: skips.gaveNoReason))
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
