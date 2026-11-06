import SwiftUI

/// Pushed Supervisor pages. Meal history opens from Me only (spec "Flow"); there is no fourth tab.
enum SupervisorRoute: Hashable {
    case shortage(ShortageID)
    case wasteReport(MealID)
    case history
    case pastMeal(MealID)
}

/// The Supervisor root: Home, Alerts and Me, in that order (S01, S07, S16). Only a Supervisor session reaches it;
/// any other session gets the plain placeholder, so no other role can open these screens.
struct SupervisorRootView: View {
    let session: Session

    /// The one check for who may see the Supervisor screens.
    static func allows(_ session: Session) -> Bool {
        session.account.role == .supervisor && session.staff?.role == .supervisor
    }

    var body: some View {
        if Self.allows(session), let staff = session.staff {
            SupervisorTabsView(session: session, staff: staff)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

struct SupervisorTabsView: View {
    @Environment(AppRouter.self) private var router
    let session: Session
    let staff: StaffSession

    @State private var homePath: [SupervisorRoute] = []
    @State private var alertsPath: [SupervisorRoute] = []
    @State private var mePath: [SupervisorRoute] = []
    @State private var toast: String?

    /// The tab bar is 62 pt with an 8 pt gap below; toasts sit above it.
    private let tabBarClearance: CGFloat = 86

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
                        SupervisorHomeScreen(staff: staff, onToast: showToast)
                            .toolbar(.hidden, for: .navigationBar)
                            .navigationDestination(for: SupervisorRoute.self) { destination($0, path: $homePath) }
                    }
                case .alerts:
                    NavigationStack(path: $alertsPath) {
                        SupervisorAlertsScreen(staff: staff) { alertsPath.append($0) }
                            .toolbar(.hidden, for: .navigationBar)
                            .navigationDestination(for: SupervisorRoute.self) { destination($0, path: $alertsPath) }
                    }
                case .me:
                    NavigationStack(path: $mePath) {
                        SupervisorMeScreen(session: session, staff: staff) { mePath.append($0) }
                            .toolbar(.hidden, for: .navigationBar)
                            .navigationDestination(for: SupervisorRoute.self) { destination($0, path: $mePath) }
                    }
                }
            }
            // Pushed pages have no tab bar (S10, S12, S18, S19).
            if isOnRootPage {
                StaffTabBar(selection: $router.selectedStaffTab)
                    .padding(.horizontal, MLSpacing.s16)
                    .padding(.bottom, MLSpacing.s8)
            }
        }
        .mlToast(message: $toast, bottomInset: isOnRootPage ? tabBarClearance : MLSpacing.s16)
    }

    private func showToast(_ text: String) {
        toast = text
    }

    @ViewBuilder
    private func destination(_ route: SupervisorRoute, path: Binding<[SupervisorRoute]>) -> some View {
        let back = { _ = path.wrappedValue.popLast() }
        Group {
            switch route {
            case .shortage(let id):
                SupervisorShortageScreen(shortageID: id, staff: staff, onBack: back) {
                    back()
                    showToast(SupervisorCopy.shortageResolvedToast)
                }
            case .wasteReport(let id):
                SupervisorWasteReportScreen(mealID: id, staff: staff, onBack: back)
            case .history:
                SupervisorHistoryScreen(staff: staff, onBack: back) { path.wrappedValue.append(.pastMeal($0)) }
            case .pastMeal(let id):
                SupervisorPastMealScreen(mealID: id, staff: staff, onBack: back) {
                    path.wrappedValue.append(.wasteReport(id))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
