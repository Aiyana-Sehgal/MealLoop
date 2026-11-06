import SwiftUI

enum WardenTab: Hashable {
    case queue
    case outNow
    case escalated
    case history
}

/// Pushed Warden pages. They have no tab bar (W02 student, W03 record, WV-5 Me).
enum WardenRoute: Hashable {
    case me
    case outNowAll
    case outNowStudent(OutingRequestID)
    case historyRecord(String)
    case notBuilt(String)
}

/// The Warden root: Queue, Out now, Escalated, History, words only (W01). Only a Warden session reaches the screens;
/// any other session gets the plain placeholder.
struct WardenRootView: View {
    let session: Session

    /// The one check for who may see the Warden screens.
    static func allows(_ session: Session) -> Bool { session.account.role == .warden }

    var body: some View {
        if Self.allows(session) {
            WardenTabsView(account: session.account.id)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

struct WardenTabsView: View {
    @Environment(AppEnvironment.self) private var environment
    let account: AccountID
    var initialTab: WardenTab = .queue
    var initialRoute: WardenRoute?
    /// Lets a screenshot run hold the model it prepared and open a sheet on arrival.
    var preparedModel: WardenModel?
    var queueSheet: WardenQueueScreen.Sheet?
    var askFields: Set<String> = []
    var askNote = ""
    var rejectReason: String?
    var callingID: OutingRequestID?
    var historyStartsOnAll = false

    @State private var model: WardenModel?
    @State private var tab: WardenTab = .queue
    @State private var paths: [WardenTab: [WardenRoute]] = [:]
    @State private var toast: String?

    private let tabBarClearance: CGFloat = 86

    var body: some View {
        ZStack(alignment: .bottom) {
            if let model {
                NavigationStack(path: path(for: tab)) {
                    page(model)
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationDestination(for: WardenRoute.self) { route in
                            destination(route, model: model)
                                .toolbar(.hidden, for: .navigationBar)
                        }
                }
                .id(tab)
                if (paths[tab] ?? []).isEmpty {
                    GlassTabBar(items: [
                        GlassTabItem(tab: WardenTab.queue, title: WardenCopy.queueTab),
                        GlassTabItem(tab: WardenTab.outNow, title: WardenCopy.outNowTab),
                        GlassTabItem(tab: WardenTab.escalated, title: WardenCopy.escalatedTab),
                        GlassTabItem(tab: WardenTab.history, title: WardenCopy.historyTab),
                    ], selection: $tab)
                    .padding(.horizontal, MLSpacing.s16)
                    .padding(.bottom, MLSpacing.s8)
                }
            } else {
                OrbitBackground()
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .mlToast(message: $toast, bottomInset: tabBarClearance)
        .task {
            if model == nil {
                tab = initialTab
                if let initialRoute { paths[initialTab] = [initialRoute] }
                if let preparedModel {
                    model = preparedModel
                } else {
                    let made = WardenModel(account: account, repository: OutingCaseRepositories.source(for: environment))
                    model = made
                    await made.load()
                }
            }
        }
        .onChange(of: tab) { _, _ in
            Task { await model?.load() }
        }
    }

    private func path(for tab: WardenTab) -> Binding<[WardenRoute]> {
        Binding(get: { paths[tab] ?? [] }, set: { paths[tab] = $0 })
    }

    private func push(_ route: WardenRoute) {
        paths[tab, default: []].append(route)
    }

    private func pop() {
        _ = paths[tab]?.popLast()
    }

    @ViewBuilder
    private func page(_ model: WardenModel) -> some View {
        switch tab {
        case .queue:
            WardenQueueScreen(model: model, onMe: { push(.me) }, onShowTab: { tab = $0 }, initialSheet: queueSheet,
                              initialAskFields: askFields, initialAskNote: askNote, initialRejectReason: rejectReason)
        case .outNow:
            WardenOutNowScreen(model: model, onMe: { push(.me) }, onOpen: { push($0) })
        case .escalated:
            WardenEscalatedScreen(model: model, onMe: { push(.me) }, onToast: { toast = $0 }, onOpenInQueue: { id in
                Task {
                    await model.focus(on: id)
                    tab = .queue
                }
            }, initialCalling: callingID)
        case .history:
            WardenHistoryScreen(model: model, onMe: { push(.me) }, onOpen: { push(.historyRecord($0)) },
                                startsOnAll: historyStartsOnAll)
        }
    }

    @ViewBuilder
    private func destination(_ route: WardenRoute, model: WardenModel) -> some View {
        switch route {
        case .me:
            WardenMeScreen(model: model, onBack: pop) { push(.notBuilt($0)) }
        case .outNowAll:
            WardenOutNowAllScreen(model: model, onBack: pop) { push(.outNowStudent($0)) }
        case .outNowStudent(let id):
            WardenOutNowStudentScreen(model: model, outingID: id, onBack: pop)
        case .historyRecord(let id):
            WardenHistoryRecordScreen(model: model, itemID: id, onBack: pop)
        case .notBuilt(let title):
            NotImplementedView(title: title)
        }
    }
}

/// Large title and one secondary line.
struct WardenTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(title)
                .font(MLType.largeTitle)
                .foregroundStyle(MLColor.ink)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A Warden tab page: orbit background, the header with the initials that open Me, title, content above the tab bar.
struct WardenPage<Content: View>: View {
    let initials: String
    let title: String
    let subtitle: String
    let onMe: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    StaffHeader(initials: initials, onAvatarTap: onMe)
                    WardenTitle(title: title, subtitle: subtitle)
                    content
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, 110)
            }
        }
    }
}

/// A pushed Warden page: Back, a large title and its line.
struct WardenPushedPage<Content: View>: View {
    let title: String
    let subtitle: String?
    let onBack: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    BackButton(action: onBack)
                    VStack(alignment: .leading, spacing: MLSpacing.s4) {
                        Text(title)
                            .font(MLType.largeTitle)
                            .foregroundStyle(MLColor.ink)
                            .accessibilityAddTraits(.isHeader)
                        if let subtitle {
                            Text(subtitle)
                                .font(MLType.body)
                                .foregroundStyle(MLColor.inkSecondary)
                        }
                    }
                    content
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, MLSpacing.s32)
            }
        }
    }
}
