import SwiftUI

/// The Pass Desk root: Home, Alerts and Me (P03, P14). The role needs its own Alerts and Me, which `StaffRootView`
/// does not take, so it keeps the shared tab bar and router tab and supplies all three tabs here.
struct PassDeskRootView: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session

    var body: some View {
        if PassDeskAccess.canOpen(session), let staff = session.staff {
            PassDeskTabs(session: staff, repositories: environment.repositories, clock: environment.clock)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// Pushed screens inside the Home tab.
enum PassDeskRoute: Hashable {
    /// Check last 4 digits: the last option, read only.
    case checkDigits(Meal)
    case requestPass(Meal, digits: String?)
    case requests
    case reportProblem
    case openProblems
}

/// Sizes the design draws for this role, and the one colour the tokens do not have.
enum PassDeskLayout {
    static let tabBarClearance: CGFloat = 96
    static let scrollBottomInset: CGFloat = 120
    /// PD-1 Home during (2530:4460): 52 pt keys, so both rows under the keypad clear the tab bar.
    static let keyHeight: CGFloat = 52
    /// PD-1 Home during: the four boxes on the black card are 53 pt.
    static let homeBoxHeight: CGFloat = 53
    /// The white keys on Look up and Request (2535:5422).
    static let pageKeyHeight: CGFloat = 80
    /// Measured from the 2530:4250 frame at 393 x 852.
    static let waitingHeight: CGFloat = 257
    static let compactWaitingHeight: CGFloat = 150
    /// Above the tab bar, for an action pinned on a page that keeps it (PD-6).
    static let footerAboveTabBar: CGFloat = 80
    static let emptyStateTop: CGFloat = 205
    static let noProblemsTop: CGFloat = 120
    /// Short phones (iPhone SE): the whole keypad must clear the tab bar, because 0 is on the bottom row.
    static let compactKeyHeight: CGFloat = 46
    static let compactHeightLimit: CGFloat = 700
}

/// Home, Alerts and Me around one set of models, so the tabs always agree.
struct PassDeskTabs: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @State private var home: PassDeskHomeViewModel
    @State private var sos: DoorSOSViewModel
    @State private var problems: PassDeskProblemLog
    @State private var path: [PassDeskRoute] = []
    @State private var isSOSOpen = false
    @State private var toast: String?

    private let repositories: Repositories
    private let clock: any AppClock

    init(session: StaffSession, repositories: Repositories, clock: any AppClock) {
        self.repositories = repositories
        self.clock = clock
        _home = State(initialValue: PassDeskHomeViewModel(session: session, repositories: repositories, clock: clock))
        _sos = State(initialValue: DoorSOSViewModel(sos: repositories.sos, mess: session.mess.id, role: session.role))
        _problems = State(initialValue: PassDeskProblemLog(session: session, repositories: repositories, clock: clock))
    }

    /// PD-6 Open problems keeps the tab bar; the other pushed pages have none.
    private var showsTabBar: Bool { router.selectedStaffTab != .home || path.isEmpty || path.last == .openProblems }

    var body: some View {
        @Bindable var router = router
        ZStack(alignment: .bottom) {
            Group {
                switch router.selectedStaffTab {
                case .home:
                    NavigationStack(path: $path) {
                        PassDeskHomeView(model: home, sos: sos, openProblems: problems.problems.count, onReload: reload,
                                         onOpenSOS: { isSOSOpen = true }, path: $path)
                            .toolbar(.hidden, for: .navigationBar)
                            .navigationDestination(for: PassDeskRoute.self) { route in
                                destination(route)
                                    .toolbar(.hidden, for: .navigationBar)
                            }
                    }
                case .alerts:
                    PassDeskAlertsView(model: home, sos: sos, now: clock.now(), onOpenSOS: { isSOSOpen = true })
                case .me:
                    PassDeskMeView(model: home, problems: problems)
                }
            }
            if showsTabBar {
                StaffTabBar(selection: $router.selectedStaffTab)
                    .padding(.horizontal, MLSpacing.s16)
                    .padding(.bottom, MLSpacing.s8)
            }
        }
        .mlToast(message: $toast, bottomInset: PassDeskLayout.tabBarClearance)
        .mlSheet(isPresented: $isSOSOpen) {
            PassDeskSOSPanel(model: sos, session: home.session, now: clock.now(), onClose: { isSOSOpen = false }) {
                isSOSOpen = false
                toast = PassDeskCopy.markedAsChecked(home.session.supervisorName)
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
    private func destination(_ route: PassDeskRoute) -> some View {
        let back = { _ = path.popLast() }
        switch route {
        case .checkDigits(let meal):
            PassDeskCheckDigitsView(model: PassDeskCheckDigitsModel(use: repositories.passUse, live: repositories.livePassCodes,
                                                                    meal: meal.id), onBack: back)
        case .requestPass(let meal, let digits):
            PassDeskRequestView(form: PassDeskRequestForm(session: home.session, passes: repositories.specialPasses, meal: meal.id),
                                digits: digits, onBack: back) {
                path = [.requests]
            }
        case .requests:
            PassDeskRequestsView(model: PassDeskRequestsModel(passes: repositories.specialPasses, mess: home.session.mess.id),
                                 session: home.session, mealName: home.state.value.map { MLFormat.mealSlot($0.meal.slot) },
                                 onBack: back)
        case .reportProblem:
            PassDeskReportProblemView(log: problems, session: home.session, meal: home.state.value?.meal, onBack: back) {
                path = [.openProblems]
            }
        case .openProblems:
            PassDeskOpenProblemsView(log: problems, session: home.session,
                                     mealName: home.state.value.map { MLFormat.mealSlot($0.meal.slot) }, onBack: back) {
                path.append(.reportProblem)
            }
        }
    }
}
