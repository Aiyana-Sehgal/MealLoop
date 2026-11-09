import Observation
import SwiftUI

// Admin search (approved images admin_search_01_empty and admin_search_02_results): a field with Cancel, scope chips,
// Recent and Jump to when empty, grouped results while typing, and an honest empty line per group. It searches the
// messes, the staff, this week's dishes and the student reports the Admin already loads. Students are never listed by
// name: reports carry counts only, and the people group holds staff accounts only.

enum AdminSearchCopy {
    static let prompt = "Search messes, people, meals, reports"
    static let cancel = "Cancel"
    static let recent = "RECENT"
    static let jumpTo = "JUMP TO"
    static let todayAllMesses = "Today, all messes"
    static let peopleAndAccess = "People and access"
    static let weeklyReport = "Weekly report"
    static let today = "Today"
    static func noMatch(_ scope: AdminSearchScope, _ text: String) -> String {
        switch scope {
        case .people: "No one matches “\(text)”"
        default: "Nothing matches “\(text)”"
        }
    }
    static func students(_ count: Int) -> String { "\(count) \(count == 1 ? "student" : "students")" }
}

enum AdminSearchScope: String, CaseIterable, Identifiable, Hashable {
    case all, messes, people, meals, reports

    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: "All"
        case .messes: "Messes"
        case .people: "People"
        case .meals: "Meals"
        case .reports: "Reports"
        }
    }
    /// The heading of a result group ("MEALS").
    var heading: String { title.uppercased() }
    /// The groups in the order the results image draws them.
    static let groups: [AdminSearchScope] = [.meals, .reports, .people, .messes]
}

/// Where a result opens.
enum AdminSearchTarget: Hashable {
    case today
    case page(AdminPage)
}

struct AdminSearchResult: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let group: AdminSearchScope
    let target: AdminSearchTarget
}

/// What can be searched. Built once from the repositories; staff only, never students.
struct AdminSearchIndex: Equatable {
    var messes: [AdminSearchResult] = []
    var people: [AdminSearchResult] = []
    var meals: [AdminSearchResult] = []
    var reports: [AdminSearchResult] = []

    func items(in group: AdminSearchScope) -> [AdminSearchResult] {
        switch group {
        case .messes: messes
        case .people: people
        case .meals: meals
        case .reports: reports
        case .all: messes + people + meals + reports
        }
    }
}

enum AdminSearchEngine {
    static let allScopeLimit = 5

    /// The groups to show for a query, each with its matches (possibly none, so the group can say so). Empty for an
    /// empty query.
    static func results(for query: String, scope: AdminSearchScope, in index: AdminSearchIndex)
        -> [(group: AdminSearchScope, results: [AdminSearchResult])] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }
        let groups = scope == .all ? AdminSearchScope.groups : [scope]
        return groups.map { group in
            let matches = index.items(in: group).filter {
                $0.title.range(of: text, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
            // All shows the first few of each group; a scope chip shows every match.
            return (group, scope == .all ? Array(matches.prefix(allScopeLimit)) : matches)
        }
    }

    static func index(directory: AccessDirectory?, menu: WeekMenu?, students: AdminStudentsOverview?,
                      timeZone: TimeZone) -> AdminSearchIndex {
        var index = AdminSearchIndex()
        index.messes = (directory?.messes ?? []).map {
            AdminSearchResult(id: "mess-\($0.id.rawValue)", title: $0.name, detail: AdminSearchCopy.today, group: .messes,
                              target: .today)
        }
        index.people = (directory?.people ?? []).filter { $0.account.role != .student }.map { person in
            AdminSearchResult(id: "person-\(person.id.rawValue)", title: person.account.displayName,
                              detail: AdminAccessCopy.personRole(person.account.role), group: .people,
                              target: .page(.accessPerson(person.id)))
        }
        index.meals = (menu?.days ?? []).flatMap { day in
            MealSlot.allCases.flatMap { slot in
                (day.meals[slot] ?? []).map { dish in
                    AdminSearchResult(id: "meal-\(dish.id)-\(day.day.timeIntervalSince1970)-\(slot.rawValue)", title: dish.name,
                                      detail: "\(AdminFormat.shortDay(day.day, in: timeZone)) · \(MLFormat.mealSlot(slot))",
                                      group: .meals, target: .page(.checkDay(day.day)))
                }
            }
        }
        index.reports = (students?.feedback ?? []).map { item in
            AdminSearchResult(id: "feedback-\(item.id.rawValue)", title: "\(item.dish) · \(item.problem)",
                              detail: "\(AdminSearchCopy.students(item.students)) · \(item.mess)", group: .reports,
                              target: .page(.feedback(item.id)))
        } + (students?.community ?? []).map { issue in
            AdminSearchResult(id: "community-\(issue.id.rawValue)", title: issue.title,
                              detail: AdminSearchCopy.students(issue.students), group: .reports,
                              target: .page(.community(issue.id)))
        }
        return index
    }
}

@MainActor
@Observable
final class AdminSearchModel {
    var text = ""
    var scope: AdminSearchScope = .all
    private(set) var index = AdminSearchIndex()
    private(set) var groups: [(group: AdminSearchScope, results: [AdminSearchResult])] = []
    /// Results opened in this run, newest first. Not kept after the app closes.
    private(set) var recent: [AdminSearchResult] = []

    private let repositories: Repositories
    private let session: Session
    private let timeZone: TimeZone

    init(repositories: Repositories, session: Session, timeZone: TimeZone) {
        self.repositories = repositories
        self.session = session
        self.timeZone = timeZone
    }

    func load() async {
        let directory = try? await repositories.people.directory(by: session)
        let menu = try? await repositories.adminMore.weekMenu()
        let students = try? await repositories.adminStudents.studentsOverview()
        index = AdminSearchEngine.index(directory: directory, menu: menu, students: students, timeZone: timeZone)
        search()
    }

    func search() {
        groups = AdminSearchEngine.results(for: text, scope: scope, in: index)
    }

    func opened(_ result: AdminSearchResult) {
        recent.removeAll { $0.id == result.id }
        recent.insert(result, at: 0)
        recent = Array(recent.prefix(3))
    }
}

struct AdminSearchView: View {
    @State var model: AdminSearchModel
    let nav: AdminNav
    let openToday: () -> Void
    let onCancel: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    field
                    chips
                    if model.text.trimmingCharacters(in: .whitespaces).isEmpty {
                        emptyState
                    } else {
                        results
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, AdminLayout.scrollBottomInset)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await model.load() }
        .task(id: model.text) {
            // A short pause, so each letter does not start a search of its own.
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            model.search()
        }
        .onChange(of: model.scope) { _, _ in model.search() }
    }

    private var field: some View {
        HStack(spacing: MLSpacing.s12) {
            HStack(spacing: MLSpacing.s8) {
                Image(systemName: "magnifyingglass").foregroundStyle(MLColor.inkSecondary).accessibilityHidden(true)
                TextField(AdminSearchCopy.prompt, text: $model.text, axis: .vertical)
                    .mlFont(.staffBody)
                    .lineLimit(1...2)
                    .focused($focused)
                    .submitLabel(.search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, MLSpacing.s16)
            .frame(minHeight: 56)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
            Button(AdminSearchCopy.cancel) {
                model.text = ""
                focused = false
                onCancel()
            }
            .mlFont(.staffPrimary)
            .foregroundStyle(MLColor.ink)
            .frame(minHeight: MLSize.hit)
        }
    }

    private var chips: some View {
        AdminFlow {
            ForEach(AdminSearchScope.allCases) { scope in
                ChoiceChip(title: scope.title, isSelected: model.scope == scope) { model.scope = scope }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if !model.recent.isEmpty {
            section(AdminSearchCopy.recent) {
                ForEach(model.recent) { result in row(result) }
            }
        }
        section(AdminSearchCopy.jumpTo) {
            AdminRow(title: AdminSearchCopy.todayAllMesses, action: openToday) { EmptyView() }
            AdminRow(title: AdminSearchCopy.peopleAndAccess, action: { nav.push(.people) }) { EmptyView() }
            AdminRow(title: AdminSearchCopy.weeklyReport, action: { nav.push(.weeklyReport) }) { EmptyView() }
        }
    }

    @ViewBuilder
    private var results: some View {
        ForEach(model.groups, id: \.group) { entry in
            section(entry.group.heading) {
                if entry.results.isEmpty {
                    Text(AdminSearchCopy.noMatch(entry.group, model.text.trimmingCharacters(in: .whitespaces)))
                        .mlFont(.staffBody)
                        .foregroundStyle(MLColor.ink)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                } else {
                    ForEach(entry.results) { result in row(result) }
                }
            }
        }
    }

    private func row(_ result: AdminSearchResult) -> some View {
        AdminRow(title: result.title, detail: result.detail, action: {
            model.opened(result)
            switch result.target {
            case .today: openToday()
            case .page(let page): nav.push(page)
            }
        }) { EmptyView() }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            AdminLabel(text: title)
                .padding(.bottom, MLSpacing.s8)
            Rectangle().fill(MLColor.border).frame(height: 1)
            content()
        }
    }
}
