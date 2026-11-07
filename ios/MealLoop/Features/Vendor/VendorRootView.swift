import SwiftUI

/// The Vendor root: Home and Me only, in the wide staff capsule, with no Search.
/// Only the vendor account reaches it; any other session sees the placeholder.
struct VendorRootView: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session

    var body: some View {
        if VendorAccess.canOpen(session) {
            VendorTabs(account: session.account, repositories: environment.repositories)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

enum VendorTab: Hashable {
    case home
    case me
}

enum VendorRoute: Hashable {
    case history
}

struct VendorTabs: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var home: VendorHomeViewModel
    @State private var tab: VendorTab
    @State private var path: [VendorRoute]
    private let repositories: Repositories

    /// `home` lets a caller hand in a model it has already moved (the screenshot tests); the app passes none.
    init(account: Account, repositories: Repositories, home: VendorHomeViewModel? = nil, tab: VendorTab = .home,
         path: [VendorRoute] = []) {
        self.repositories = repositories
        _home = State(initialValue: home ?? VendorHomeViewModel(account: account, repositories: repositories))
        _tab = State(initialValue: tab)
        _path = State(initialValue: path)
    }

    private let items = [
        GlassTabItem(tab: VendorTab.home, title: VendorCopy.home, symbol: "house"),
        GlassTabItem(tab: VendorTab.me, title: VendorCopy.me, symbol: "person.crop.circle"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:
                    NavigationStack(path: $path) {
                        VendorHomeView(model: home, onReload: { await home.load() }, onAvatar: { tab = .me },
                                       onHistory: { path.append(.history) })
                            .toolbar(.hidden, for: .navigationBar)
                            .navigationDestination(for: VendorRoute.self) { _ in
                                VendorHistoryView(model: VendorHistoryViewModel(account: home.account, vendor: repositories.vendor),
                                                  mess: home.mess, onBack: { _ = path.popLast() })
                                    .toolbar(.hidden, for: .navigationBar)
                            }
                    }
                case .me:
                    VendorMeView(account: home.account, mess: home.mess)
                }
            }
            GlassTabBar(items: items, selection: $tab)
                .padding(.horizontal, MLSpacing.s16)
                .padding(.bottom, MLSpacing.s8)
        }
        .task(id: environment.dataRevision) {
            // A failed reply stays on screen until the vendor retries; a reload would hide it.
            if home.send != .failed { await home.load() }
        }
    }
}
