import SwiftUI

@main
struct MealLoopApp: App {
    @State private var environment = AppEnvironment.make()
    @State private var router = AppRouter()
    @State private var sessionStore = SessionStore(recentStore: UserDefaultsRecentAccountsStore())

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(environment)
                .environment(router)
                .environment(sessionStore)
        }
    }
}
