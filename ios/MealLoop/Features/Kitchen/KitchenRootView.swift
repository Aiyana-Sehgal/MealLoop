import SwiftUI

/// Pushed Kitchen pages. Meal history opens from Past meals and from Me; there is no fourth tab.
enum KitchenRoute: Hashable {
    case menu(Meal)
    case shortages
    case mealEndedWhileReporting(Date?)
    case recordWaste(Meal)
    case reportSaved(WasteReport, Meal)
    case history
    case pastMeal(MealID)
}

/// The Kitchen root: Home, Alerts and Me (K01, K12, K13). Only a Kitchen Staff session reaches the screens;
/// any other session gets the plain placeholder.
struct KitchenRootView: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session

    /// The one check for who may see the Kitchen screens.
    static func allows(_ session: Session) -> Bool {
        session.account.role == .kitchenStaff && session.staff?.role == .kitchenStaff
    }

    var body: some View {
        if Self.allows(session), let staff = session.staff {
            KitchenTabsView(session: staff, repositories: environment.repositories, clock: environment.clock)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// Home, Alerts and Me around one set of models, so the tabs always agree.
struct KitchenTabsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @State private var home: KitchenHomeViewModel
    @State private var sos: KitchenSOSViewModel
    @State private var alerts: KitchenAlertsViewModel
    @State private var homePath: [KitchenRoute] = []
    @State private var alertsPath: [KitchenRoute] = []
    @State private var mePath: [KitchenRoute] = []
    @State private var isSOSOpen = false
    @State private var toast: String?

    private let repositories: Repositories
    private let clock: any AppClock

    init(session: StaffSession, repositories: Repositories, clock: any AppClock) {
        self.repositories = repositories
        self.clock = clock
        _home = State(initialValue: KitchenHomeViewModel(session: session, repositories: repositories, clock: clock))
        _sos = State(initialValue: KitchenSOSViewModel(sos: repositories.sos, mess: session.mess.id, role: session.role))
        _alerts = State(initialValue: KitchenAlertsViewModel(session: session, repositories: repositories))
    }

    private var isOnRootPage: Bool {
        switch router.selectedStaffTab {
        case .home: return homePath.isEmpty
        case .alerts: return alertsPath.isEmpty
        case .me: return mePath.isEmpty
        }
    }

    var body: some View {
        @Bindable var router = router
        ZStack(alignment: .bottom) {
            Group {
                switch router.selectedStaffTab {
                case .home:
                    NavigationStack(path: $homePath) {
                        KitchenHomeView(model: home, sos: sos, open: { homePath.append($0) },
                                        onOpenSOS: { isSOSOpen = true }, onToast: { toast = $0 })
                            .toolbar(.hidden, for: .navigationBar)
                            .navigationDestination(for: KitchenRoute.self) { destination($0, path: $homePath) }
                    }
                case .alerts:
                    NavigationStack(path: $alertsPath) {
                        KitchenAlertsView(model: alerts, sos: sos, now: clock.now(), onOpenSOS: { isSOSOpen = true }) {
                            alertsPath.append($0)
                        }
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationDestination(for: KitchenRoute.self) { destination($0, path: $alertsPath) }
                    }
                case .me:
                    NavigationStack(path: $mePath) {
                        KitchenMeView(session: home.session) { mePath.append($0) }
                            .toolbar(.hidden, for: .navigationBar)
                            .navigationDestination(for: KitchenRoute.self) { destination($0, path: $mePath) }
                    }
                }
            }
            // Pushed pages have no tab bar (K06, K11, K17).
            if isOnRootPage {
                StaffTabBar(selection: $router.selectedStaffTab)
                    .padding(.horizontal, MLSpacing.s16)
                    .padding(.bottom, MLSpacing.s8)
            }
        }
        .mlToast(message: $toast, bottomInset: isOnRootPage ? KitchenLayout.tabBarClearance : MLSpacing.s16)
        .mlSheet(isPresented: $isSOSOpen) {
            KitchenSOSPanel(model: sos, session: home.session, now: clock.now(), onClose: { isSOSOpen = false }) {
                isSOSOpen = false
                toast = KitchenCopy.markedAsChecked
            }
        }
        .task(id: environment.dataRevision) {
            await reload()
        }
    }

    private func reload() async {
        await home.load()
        await sos.load()
        await alerts.load()
    }

    @ViewBuilder
    private func destination(_ route: KitchenRoute, path: Binding<[KitchenRoute]>) -> some View {
        let back = { _ = path.wrappedValue.popLast() }
        Group {
            switch route {
            case .menu(let meal):
                KitchenMenuView(model: KitchenMenuViewModel(meal: meal, meals: repositories.meals),
                                mess: home.session.mess, day: meal.startsAt, onBack: back)
            case .shortages:
                KitchenShortagesView(model: home, onBack: back)
            case .mealEndedWhileReporting(let at):
                KitchenMealEndedView(mealName: home.state.value.map { MLFormat.mealSlot($0.meal.slot) } ?? "",
                                     endedAt: at, timeZone: home.session.mess.timeZone, onBack: back) {
                    if let meal = home.state.value?.meal {
                        path.wrappedValue = [.recordWaste(meal)]
                    }
                }
            case .recordWaste(let meal):
                KitchenRecordWasteView(
                    model: KitchenWasteViewModel(meal: meal, session: home.session, repositories: repositories),
                    sos: sos, onOpenSOS: { isSOSOpen = true }, onToast: { toast = $0 },
                    onBack: {
                        back()
                        Task { await reload() }
                    },
                    onSaved: { report in
                        path.wrappedValue = [.reportSaved(report, meal)]
                        Task { await reload() }
                    })
            case .reportSaved(let report, let meal):
                KitchenReportSavedView(report: report, meal: meal, timeZone: home.session.mess.timeZone,
                                       onViewReport: { path.wrappedValue = [.pastMeal(meal.id)] },
                                       onDone: { path.wrappedValue = [] })
            case .history:
                KitchenHistoryView(model: KitchenHistoryViewModel(session: home.session, repositories: repositories),
                                   onBack: back) { path.wrappedValue.append(.pastMeal($0)) }
            case .pastMeal(let id):
                KitchenPastMealView(
                    model: KitchenPastMealViewModel(mealID: id, session: home.session, repositories: repositories, clock: clock),
                    onBack: back) { path.wrappedValue.append(.recordWaste($0)) }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}
