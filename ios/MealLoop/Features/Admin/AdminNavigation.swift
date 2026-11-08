import SwiftUI

/// Pushed pages of the Students, Results and More tabs. Today keeps its own `AdminRoute`.
enum AdminPage: Hashable {
    case reason(ReasonKind)
    case meal(MealID)
    case check(CheckID)
    case findMeal
    case safetyCases
    case safetyCase(String)
    case weeklyReport
    case feedback(FeedbackItemID)
    case community(CommunityIssueID)
    case skipReasons
    case weeklyMenu
    case checkDay(Date)
    case editDay(Date)
    case people
    case peopleRole(String)
    case accessPerson(AccountID)
    case announce
    case passes
    case votes
    case rewards
    case spareFood
    case history
    case outings
    case messHeadcount(String, MealSlot)
    case notAnswered
}

/// What a page needs from its tab: who is signed in, how to move, and how to show a toast.
struct AdminNav {
    let context: AdminContext
    let push: (AdminPage) -> Void
    let pop: () -> Void
    let toast: (String) -> Void

    var timeZone: TimeZone { context.mess.timeZone }
}

/// One page's load, for every screen that only reads. Screens that write have their own view model.
@MainActor
@Observable
final class AdminPageModel<Value: Sendable> {
    private(set) var state: LoadState<Value> = .idle

    private let fetch: @Sendable () async throws -> Value
    private let isEmpty: @Sendable (Value) -> Bool

    init(isEmpty: @escaping @Sendable (Value) -> Bool = { _ in false }, fetch: @escaping @Sendable () async throws -> Value) {
        self.fetch = fetch
        self.isEmpty = isEmpty
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            let value = try await fetch()
            state = isEmpty(value) ? .empty : .loaded(value)
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    /// After a write that returned the new value.
    func show(_ value: Value) {
        state = .loaded(value)
    }
}

/// Keeps a page model alive and reloads it when the story moves.
struct AdminLoadedPage<Value: Sendable, Content: View>: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: AdminPageModel<Value>
    let timeZone: TimeZone
    var emptyTitle: String = AdminScreenCopy.nothingYet
    var emptyMessage: String = ""
    @ViewBuilder let content: (Value, AdminPageModel<Value>) -> Content

    init(model: AdminPageModel<Value>, timeZone: TimeZone, emptyTitle: String = AdminScreenCopy.nothingYet, emptyMessage: String = "",
         @ViewBuilder content: @escaping (Value, AdminPageModel<Value>) -> Content) {
        _model = State(initialValue: model)
        self.timeZone = timeZone
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self.content = content
    }

    var body: some View {
        AsyncContentView(state: model.state, emptyTitle: emptyTitle, emptyMessage: emptyMessage, timeZone: timeZone,
                         retry: { await model.load() }) { value in
            content(value, model)
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
    }
}

/// Writes in this tab fail in the same two ways: no connection, or refused.
enum AdminWriteError {
    static func text(_ error: Error) -> String {
        if case RepositoryError.validationFailed(let messages) = error, let first = messages.first { return first }
        if case RepositoryError.notAllowed(let reason) = error { return reason }
        if case RepositoryError.offline = error { return AdminScreenCopy.offlineNothingSaved }
        return AdminScreenCopy.couldNotSave
    }
}
