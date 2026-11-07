import SwiftUI

struct SupervisorMeScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session
    let staff: StaffSession
    let open: (SupervisorRoute) -> Void

    var body: some View {
        SupervisorMeView(model: SupervisorMeViewModel(session: staff, repositories: environment.repositories),
                         displayName: session.account.displayName, open: open)
    }
}

/// Me (S16a, S16b, S16, S16c) and "Sign out?" (S17). No editable profile, no mess switcher.
struct SupervisorMeView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    @State private var model: SupervisorMeViewModel
    @State private var isConfirmingSignOut = false
    let displayName: String
    let open: (SupervisorRoute) -> Void

    /// S16 draws the avatar at about 92 pt.
    private let avatarSize: CGFloat = 92

    init(model: SupervisorMeViewModel, displayName: String, open: @escaping (SupervisorRoute) -> Void) {
        _model = State(initialValue: model)
        self.displayName = displayName
        self.open = open
    }

    var body: some View {
        SupervisorPage {
            Text(SupervisorCopy.meTitle)
                .font(MLType.largeTitle)
                .foregroundStyle(MLColor.ink)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, MLSize.hit + MLSpacing.s4)
            profile
            VStack(alignment: .leading, spacing: 0) {
                Rectangle().fill(MLColor.border).frame(height: 1)
                SupervisorStrongRow(title: SupervisorCopy.historyTitle) { open(.history) }
            }
            AsyncContentView(state: model.state, timeZone: model.session.mess.timeZone,
                             retry: { await model.load() }) { followUps in
                VStack(alignment: .leading, spacing: 0) {
                    SupervisorGroupLabel(title: SupervisorCopy.followUps)
                    QuietRow(title: SupervisorCopy.activeShortages, value: "\(followUps.activeShortages.count)") {
                        router.selectedStaffTab = .alerts
                    }
                    QuietRow(title: SupervisorCopy.wasteNotRecorded, value: "\(followUps.wasteNotRecorded.count)") {
                        router.selectedStaffTab = .alerts
                    }
                }
            }
            VStack(spacing: 0) {
                Rectangle().fill(MLColor.border).frame(height: 1)
                signOutRow
            }
            .padding(.top, MLSpacing.s16)
        }
        .refreshable { await model.load() }
        .task(id: environment.dataRevision) {
            await model.load()
        }
        .mlConfirmDialog(isPresented: $isConfirmingSignOut, content: SupervisorCopy.signOutDialog) {
            isConfirmingSignOut = false
            router.reset()
            sessionStore.signOut()
        }
    }

    private var profile: some View {
        HStack(spacing: MLSpacing.s24) {
            Text(model.session.staffInitials)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(MLColor.lime)
                .frame(width: avatarSize, height: avatarSize)
                .background(Circle().fill(MLColor.ink))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text(displayName)
                    .font(MLType.heroTitle)
                    .foregroundStyle(MLColor.ink)
                Text("\(MLFormat.roleName(model.session.role)) · \(model.session.mess.name)")
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .padding(.bottom, MLSpacing.s8)
    }

    private var signOutRow: some View {
        Button {
            isConfirmingSignOut = true
        } label: {
            Text(SupervisorCopy.signOut)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
                .frame(maxWidth: .infinity, minHeight: MLSize.staffButton, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
    }
}
