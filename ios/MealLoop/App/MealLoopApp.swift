import SwiftUI

@main
struct MealLoopApp: App {
    @State private var environment = AppEnvironment.make()
    @State private var router = AppRouter()
    @State private var sessionStore = SessionStore()
    @State private var demoMenu = DemoMenu()

    init() {
        MLFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(environment)
                .environment(router)
                .environment(sessionStore)
                .environment(demoMenu)
                // Every surface is drawn light (the app has no dark theme). In dark appearance the system chrome on
                // top of them — placeholders, the glass back button, keyboards — turned light-on-light, so the app
                // runs in Light. Gate and the Guardian video page keep their own dark sections.
                .preferredColorScheme(.light)
        }
    }
}
