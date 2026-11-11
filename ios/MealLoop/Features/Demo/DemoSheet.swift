#if DEMO_DATA || REVIEW_DATA
import SwiftUI

/// The Demo states sheet (Debug and Review). Getting started first, then Switch role (keeps data).
/// Getting started signs out and opens the real entry screens at a step. Switch role signs in the role's seeded
/// account and opens its normal Home. Neither moves the clock or replaces data, and no shortcut sets a screen state
/// directly: states that would need a reset or separate data are left out.
struct DemoSheet: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    @Environment(DemoMenu.self) private var demoMenu

    /// The order of the role list: the people of the core story first.
    static let roles: [Role] = [.student, .admin, .superAdmin, .supervisor, .kitchenStaff, .doorScanner, .passDesk,
                                .vendor, .guardian, .warden, .gate]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    row("Student · Sign in with SRM") { start([.srmSignIn]) }
                    row("Student · Sign in failed") {
                        await environment.demoControls?.failNextSRMSignIn()
                        start([.srmSignIn])
                    }
                    row("Staff · Choose your role") { start([.chooseRole]) }
                    row("Staff · Password") { start([.chooseRole, .rolePassword(.doorScanner)]) }
                    row("Staff · Sign in with email") { start([.chooseRole, .emailSignIn]) }
                } header: {
                    Text(DemoCopy.gettingStarted)
                } footer: {
                    Text(DemoCopy.gettingStartedFooter)
                }

                Section {
                    ForEach(Self.roles, id: \.self) { role in
                        let isCurrent = sessionStore.current?.account.role == role
                        row(MLFormat.roleName(role), isCurrent: isCurrent) { await switchTo(role) }
                            .disabled(isCurrent)
                    }
                } header: {
                    Text(DemoCopy.switchRole)
                } footer: {
                    Text(DemoCopy.switchRoleFooter)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(DemoCopy.sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(DemoCopy.done) { demoMenu.isPresented = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func row(_ title: String, isCurrent: Bool = false, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(Color.primary)
                Spacer(minLength: MLSpacing.s8)
                if isCurrent {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.secondary)
                        .accessibilityLabel("Current")
                }
            }
            .contentShape(Rectangle())
        }
    }

    /// Signs out and opens the entry stack at the given steps. Nothing else changes.
    private func start(_ path: [EntryRoute]) {
        demoMenu.isPresented = false
        router.reset()
        sessionStore.signOut()
        router.entryPath = path
    }

    /// Opens the role's normal landing screen with every navigation path cleared. Data and the clock are untouched.
    private func switchTo(_ role: Role) async {
        guard let session = await environment.demoControls?.demoSession(for: role) else { return }
        demoMenu.isPresented = false
        router.reset()
        sessionStore.signIn(session)
    }
}
#endif
