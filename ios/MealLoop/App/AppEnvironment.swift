import Foundation
import Observation

// Seeded data may exist only in Debug (DEMO_DATA) and Review (REVIEW_DATA). If either flag reaches any other
// configuration (a pilot or production build), compilation stops here. Release can have neither.
#if DEMO_DATA && !DEBUG
#error("DEMO_DATA is set outside the Debug configuration. Demo data must never ship in a pilot or production build.")
#endif
#if REVIEW_DATA && !REVIEW_CONFIGURATION
#error("REVIEW_DATA is set outside the Review configuration. Seeded data must never ship in a pilot or production build.")
#endif
#if REVIEW_DATA && (DEBUG || DEMO_DATA)
#error("REVIEW_DATA cannot be combined with DEBUG or DEMO_DATA. The Review build must not contain the demo controls.")
#endif

enum DataSourceKind: String, Sendable {
    /// Seeded sample data (Debug only). Shown with a visible "Demo data" badge.
    case demo
    /// The same seeded data for the external review (Review only). It has no badge and no moment controls.
    case review
    /// The real backend. Not implemented yet: every call throws `notImplemented`.
    case api
}

/// One moment the demo can switch to (a simulated time skip).
struct DemoScenarioOption: Identifiable, Sendable, Hashable {
    let id: String
    let title: String
}

/// Hook for the Debug-only demo controls. Only the demo provider conforms, and it exists only in Debug builds.
protocol DemoControlling: Sendable {
    var scenarioOptions: [DemoScenarioOption] { get }
    func selectScenario(id: String) async
}

/// Selects exactly one data source for the running app. Demo and real data are never mixed.
@Observable
final class AppEnvironment {
    let kind: DataSourceKind
    let repositories: Repositories
    let clock: any AppClock
    /// Optional; nothing implements it yet. Core dining features never depend on it.
    let intelligence: (any IntelligenceService)?
    /// Non-nil only in the demo environment.
    let demoControls: (any DemoControlling)?
    /// Bumped when data changes outside a screen (for example a demo time skip),
    /// so screens can reload with `.task(id: environment.dataRevision)`.
    private(set) var dataRevision = 0

    init(kind: DataSourceKind, repositories: Repositories, clock: any AppClock, demoControls: (any DemoControlling)?) {
        self.kind = kind
        self.repositories = repositories
        self.clock = clock
        self.intelligence = nil
        self.demoControls = demoControls
    }

    func dataDidChange() {
        dataRevision += 1
    }

    /// The environment for this build configuration: demo in Debug, review in Review, api in every other configuration.
    static func make() -> AppEnvironment {
        #if DEMO_DATA
        return makeDemo()
        #elseif REVIEW_DATA
        return makeReview()
        #else
        return makeAPI()
        #endif
    }

    #if DEMO_DATA
    static func makeDemo(scenario: DemoScenario = .duringMeal) -> AppEnvironment {
        let provider = DemoDataProvider(scenario: scenario)
        return AppEnvironment(kind: .demo, repositories: provider.makeRepositories(), clock: provider.clock,
                              demoControls: provider)
    }
    #endif

    #if REVIEW_DATA
    static func makeReview(scenario: DemoScenario = .storyStart) -> AppEnvironment {
        let provider = DemoDataProvider(scenario: scenario)
        return AppEnvironment(kind: .review, repositories: provider.makeRepositories(), clock: provider.clock,
                              demoControls: nil)
    }
    #endif

    static func makeAPI() -> AppEnvironment {
        let api = RemoteAPI(baseURL: nil)
        return AppEnvironment(kind: .api, repositories: api.makeRepositories(), clock: SystemClock(), demoControls: nil)
    }
}
