import SwiftUI

/// The Door Scanner root. The role needs its own Alerts and Me, which `StaffRootView` does not take, so it keeps the
/// shared tab bar and router tab and supplies all three tabs here.
struct DoorScannerRootView: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session

    var body: some View {
        if DoorScannerAccess.canOpen(session), let staff = session.staff {
            DoorScannerTabs(session: staff, repositories: environment.repositories, clock: environment.clock)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// Pushed screens inside the Home tab.
enum DoorRoute: Hashable {
    case reportProblem
    case openProblems
    case withoutVoting(Meal)
}

/// Home, Alerts and Me around one set of models, so the tabs always agree.
struct DoorScannerTabs: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @State private var home: DoorHomeViewModel
    @State private var sos: DoorSOSViewModel
    @State private var problems: DoorProblemLog
    @State private var path: [DoorRoute] = []
    @State private var isSOSOpen = false
    @State private var toast: String?

    private let repositories: Repositories
    private let clock: any AppClock

    init(session: StaffSession, repositories: Repositories, clock: any AppClock) {
        self.repositories = repositories
        self.clock = clock
        _home = State(initialValue: DoorHomeViewModel(session: session, repositories: repositories, clock: clock))
        _sos = State(initialValue: DoorSOSViewModel(sos: repositories.sos, mess: session.mess.id, role: session.role))
        _problems = State(initialValue: DoorProblemLog(mealState: repositories.mealState, mess: session.mess.id, clock: clock))
    }

    var body: some View {
        @Bindable var router = router
        ZStack(alignment: .bottom) {
            Group {
                switch router.selectedStaffTab {
                case .home:
                    NavigationStack(path: $path) {
                        DoorHomeView(model: home, sos: sos, repositories: repositories, clock: clock,
                                     onReload: reload, onOpenSOS: { isSOSOpen = true },
                                     openProblems: problems.problems.count, path: $path)
                            .toolbar(.hidden, for: .navigationBar)
                            .navigationDestination(for: DoorRoute.self) { route in
                                destination(route)
                                    .toolbar(.hidden, for: .navigationBar)
                            }
                    }
                case .alerts:
                    DoorAlertsView(model: home, sos: sos, now: clock.now(), onOpenSOS: { isSOSOpen = true })
                case .me:
                    DoorMeView(model: home, problems: problems)
                }
            }
            StaffTabBar(selection: $router.selectedStaffTab)
                .padding(.horizontal, MLSpacing.s16)
                .padding(.bottom, MLSpacing.s8)
        }
        .mlToast(message: $toast, bottomInset: DoorLayout.tabBarClearance)
        .mlSheet(isPresented: $isSOSOpen) {
            DoorSOSPanel(model: sos, session: home.session, now: clock.now(), onClose: { isSOSOpen = false }) {
                isSOSOpen = false
                toast = DoorScannerCopy.markedAsChecked
            }
        }
        .task(id: environment.dataRevision) {
            await reload()
        }
    }

    private func reload() async {
        await home.load()
        await sos.load()
    }

    @ViewBuilder
    private func destination(_ route: DoorRoute) -> some View {
        switch route {
        case .reportProblem:
            DoorReportProblemView(log: problems, supervisorName: home.session.supervisorName,
                                  onBack: { path.removeLast() }) {
                path = [.openProblems]
            }
        case .openProblems:
            DoorOpenProblemsView(log: problems, session: home.session, subtitle: subtitle, onBack: { path.removeLast() }) {
                path.append(.reportProblem)
            }
        case .withoutVoting(let meal):
            DoorWithoutVotingView(model: DoorWithoutVotingViewModel(entries: repositories.entries, meal: meal.id),
                                  meal: meal, mess: home.session.mess, onBack: { path.removeLast() })
        }
    }

    private var subtitle: String {
        guard let meal = home.state.value?.meal else { return home.session.mess.name }
        return "\(MLFormat.mealSlot(meal.slot)) · \(home.session.mess.name)"
    }
}

/// Sizes the design draws for this role, measured from the D04, D05 and D12 exports.
enum DoorLayout {
    static let tabBarClearance: CGFloat = 96
    static let scrollBottomInset: CGFloat = 120
    static let scanCardHeight: CGFloat = 236
    static let closedCardHeight: CGFloat = 352
    static let waitingCardHeight: CGFloat = 400
    static let meAvatar: CGFloat = 92
}
