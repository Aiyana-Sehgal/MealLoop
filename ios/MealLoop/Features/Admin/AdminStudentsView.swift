import SwiftUI

/// Students (A06): who has answered tomorrow's meal, and what students have raised. Counts only, never a name.
@MainActor
@Observable
final class AdminStudentsViewModel {
    private(set) var state: LoadState<AdminStudentsOverview> = .idle
    private(set) var isSending = false
    private(set) var errorText: String?

    private let students: any AdminStudentsRepository
    private let role: Role
    /// One key per screen, so a double tap reminds once.
    private let key = IdempotencyKey.make()

    init(students: any AdminStudentsRepository, role: Role) {
        self.students = students
        self.role = role
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            let overview = try await students.studentsOverview()
            state = overview.totalStudents == 0 ? .empty : .loaded(overview)
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
            state = .loaded(try await students.remind(key: key, by: role))
            return true
        } catch {
            errorText = AdminWriteError.text(error)
            return false
        }
    }
}

struct AdminStudentsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        AdminStudentsView(model: AdminStudentsViewModel(students: environment.repositories.adminStudents, role: nav.context.account.role), nav: nav)
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

    var body: some View {
        AdminPageScaffold(title: AdminScreenCopy.studentsTitle, subtitle: AdminScreenCopy.whatNeedsYou) {
            AsyncContentView(state: model.state, timeZone: timeZone, retry: { await model.load() }) { overview in
                content(overview)
            }
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
        .mlSheet(isPresented: $isReminding, isWorking: model.isSending) {
            if let overview = model.state.value {
                remindSheet(overview)
            }
        }
    }

    private func content(_ overview: AdminStudentsOverview) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            hero(overview)
            VStack(alignment: .leading, spacing: 6) {
                AdminLabel(text: AdminScreenCopy.feedbackToActOn)
                VStack(spacing: 0) {
                    ForEach(overview.feedback) { item in
                        AdminRow(title: AdminScreenCopy.feedbackRowTitle(item),
                                 detail: AdminScreenCopy.feedbackRowDetail(item, day: AdminFormat.weekday(item.day, in: timeZone).prefix(3).description),
                                 showsChevron: !item.isNew, leadingDish: item.dish, action: { nav.push(.feedback(item.id)) }) {
                            if item.isNew {
                                AdminChip(text: AdminScreenCopy.new, style: .lime)
                            }
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                AdminLabel(text: AdminScreenCopy.community)
                VStack(spacing: 0) {
                    ForEach(overview.community) { issue in
                        AdminRow(title: issue.title, detail: AdminScreenCopy.studentCount(issue.students), showsChevron: false,
                                 action: { nav.push(.community(issue.id)) }) {
                            AdminChip(text: issue.owner.map(AdminScreenCopy.ownedBy) ?? AdminScreenCopy.needsAnOwner,
                                      style: AdminChipRules.community(hasOwner: issue.owner != nil))
                        }
                    }
                    AdminRow(title: AdminScreenCopy.whyStudentsSkip, action: { nav.push(.skipReasons) }) { EmptyView() }
                    AdminRow(title: AdminScreenCopy.notAnsweredByMess,
                             detail: AdminScreenCopy.notAnsweredRow(AdminFormat.count(overview.notAnswered), overview.mealTitle),
                             action: { nav.push(.notAnswered) }) { EmptyView() }
                }
                .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
            }
        }
    }

    private func hero(_ overview: AdminStudentsOverview) -> some View {
        HeroCard {
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                HeroEyebrow(label: AdminScreenCopy.answered(overview.mealTitle))
                HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                    Text(AdminFormat.count(overview.answered))
                        .font(MLType.heroNumber)
                        .foregroundStyle(MLColor.onHero)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(AdminScreenCopy.ofWord)
                        .font(MLType.staffBody)
                        .foregroundStyle(MLColor.onHeroSecondary)
                    Text(AdminFormat.count(overview.totalStudents))
                        .font(AdminType.mono20)
                        .foregroundStyle(MLColor.onHeroSecondary)
                }
                bar(AdminScreenCopy.yes, overview.yes, of: overview.totalStudents, color: MLColor.lime)
                bar(AdminScreenCopy.no, overview.no, of: overview.totalStudents, color: MLColor.onHero)
                bar(AdminScreenCopy.notSure, overview.notSure, of: overview.totalStudents, color: MLColor.onHero)
                if let sentAt = overview.reminderSentAt {
                    Text(AdminScreenCopy.reminderSent(MLFormat.time(sentAt, in: timeZone)))
                        .font(MLType.body)
                        .foregroundStyle(MLColor.onHero)
                } else {
                    LimeActionButton(title: AdminScreenCopy.remind(AdminFormat.count(overview.notAnswered))) { isReminding = true }
                }
            }
        }
    }

    private func bar(_ title: String, _ value: Int, of total: Int, color: Color) -> some View {
        HStack(spacing: MLSpacing.s12) {
            Text(title)
                .font(MLType.body)
                .foregroundStyle(MLColor.onHero)
                .frame(width: 80, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(MLColor.inkSecondary)
                    Capsule().fill(color).frame(width: proxy.size.width * CGFloat(value) / CGFloat(max(total, 1)))
                }
            }
            .frame(height: 10)
            Text(AdminFormat.count(value))
                .font(MLType.monoBody)
                .foregroundStyle(MLColor.onHero)
                .frame(width: 56, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(AdminFormat.count(value))")
    }

    private func remindSheet(_ overview: AdminStudentsOverview) -> some View {
        let count = AdminFormat.count(overview.notAnswered)
        return VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: AdminScreenCopy.remindStudents) { isReminding = false }
            AdminLabel(text: AdminScreenCopy.who)
            // Remind sheet 2262:237: body-size text, the message in a white bubble, one helper line, the button below.
            Text(AdminScreenCopy.remindWho(count, meal: overview.mealLongTitle))
                .mlFont(.body)
                .foregroundStyle(MLColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            AdminLabel(text: AdminScreenCopy.messageLabel)
            Text(overview.reminderMessage)
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
