import SwiftUI

/// Words of the Super Admin pages. There is no approved design for this role: these pages are built from the shared
/// components only and need owner approval.
enum SuperAdminCopy {
    static let accounts = "Accounts"
    static let subtitle = "Every account that can sign in"
    static let signOut = "Sign out"
    static let active = "Active"
    static let deactivated = "Deactivated in this prototype"
    static let role = "Role"
    static let email = "Email"
    static let scope = "Scope"
    static let oneMess = "One mess"
    static let oneHostel = "One hostel"
    static let startReset = "Start password reset"
    static let deactivate = "Deactivate account"
    static let confirmDeactivate = "Deactivate this account?"
    static let cancel = "Cancel"
    static let resetRecorded = "Password reset recorded. This prototype sends nothing, and no password is ever shown here."
    static let deactivationRecorded = "Deactivation recorded. This prototype does not change sign-in."
    static let superAdminProtected = "A Super Admin account can't be deactivated here."
    static let noPasswords = "A Super Admin can't see or read any password."
    static let offline = "You're offline. These are the accounts you last saw."
    static let empty = "No accounts"
}

/// The Super Admin root: Accounts, an account's page, and Sign out. No Food Head pages.
struct SuperAdminRootView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let session: Session
    @State private var model: SuperAdminViewModel?
    @State private var path: [AccountID] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                OrbitBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: MLSpacing.s16) {
                        VStack(alignment: .leading, spacing: MLSpacing.s4) {
                            Text(SuperAdminCopy.accounts)
                                .font(MLType.largeTitle)
                                .foregroundStyle(MLColor.ink)
                                .accessibilityAddTraits(.isHeader)
                            Text(SuperAdminCopy.subtitle).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                        }
                        .padding(.top, MLSpacing.s32)
                        content
                        QuietRow(title: SuperAdminCopy.signOut) {
                            router.reset()
                            sessionStore.signOut()
                        }
                    }
                    .padding(.horizontal, MLSpacing.margin)
                    .padding(.bottom, MLSpacing.s32)
                }
                .refreshable { await model?.load() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AccountID.self) { id in
                if let model {
                    SuperAdminAccountView(model: model, id: id) { path.removeLast() }
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .task {
            if model == nil {
                model = SuperAdminViewModel(role: session.account.role, repository: environment.repositories.superAdmin)
            }
            await model?.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model?.accounts ?? .idle {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 120)
        case .failed(let failure):
            StateBlock(symbol: "exclamationmark.circle", title: failure.message)
        case .empty:
            StateBlock(symbol: "person.2", title: SuperAdminCopy.empty)
        case .loaded(let list), .stale(let list, _):
            rows(list)
        case .offline(let list, _):
            Text(SuperAdminCopy.offline).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            if let list { rows(list) }
        }
    }

    private func rows(_ list: [ManagedAccount]) -> some View {
        VStack(spacing: 0) {
            ForEach(list) { managed in
                QuietRow(title: managed.account.displayName,
                         value: MLFormat.roleName(managed.account.role) + (managed.isActive ? "" : " · \(SuperAdminCopy.deactivated)")) {
                    path.append(managed.id)
                }
                .accessibilityIdentifier("superadmin.account.\(managed.account.role.rawValue)")
            }
        }
    }
}

/// One account: role, email, scope and state, with a simulated reset and deactivation.
struct SuperAdminAccountView: View {
    @State var model: SuperAdminViewModel
    let id: AccountID
    let onBack: () -> Void
    @State private var confirming = false

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    BackButton(action: onBack)
                    if let managed = model.account(id) {
                        page(managed)
                    } else {
                        StateBlock(symbol: "exclamationmark.circle", title: SuperAdminCopy.empty)
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, MLSpacing.s32)
            }
        }
        .confirmationDialog(SuperAdminCopy.confirmDeactivate, isPresented: $confirming, titleVisibility: .visible) {
            Button(SuperAdminCopy.deactivate, role: .destructive) { Task { await model.deactivate(id) } }
            Button(SuperAdminCopy.cancel, role: .cancel) {}
        }
    }

    @ViewBuilder
    private func page(_ managed: ManagedAccount) -> some View {
        let account = managed.account
        Text(account.displayName)
            .font(MLType.largeTitle)
            .foregroundStyle(MLColor.ink)
            .accessibilityAddTraits(.isHeader)
        StatusText(text: managed.isActive ? SuperAdminCopy.active : SuperAdminCopy.deactivated,
                   dot: managed.isActive ? .filled : .empty)
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            fact(SuperAdminCopy.role, MLFormat.roleName(account.role))
            fact(SuperAdminCopy.email, account.email)
            fact(SuperAdminCopy.scope, scope(account.scope))
        }
        Text(SuperAdminCopy.noPasswords).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
        OutlineActionButton(title: SuperAdminCopy.startReset) { Task { await model.startPasswordReset(id) } }
            .disabled(model.send == .sending)
            .accessibilityIdentifier("superadmin.reset")
        if managed.resetStartedAt != nil {
            Text(SuperAdminCopy.resetRecorded).font(MLType.body).foregroundStyle(MLColor.ink)
        }
        if account.role == .superAdmin {
            Text(SuperAdminCopy.superAdminProtected).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
        } else if managed.isActive {
            OutlineActionButton(title: SuperAdminCopy.deactivate) { confirming = true }
                .disabled(model.send == .sending)
                .accessibilityIdentifier("superadmin.deactivate")
        } else {
            Text(SuperAdminCopy.deactivationRecorded).font(MLType.body).foregroundStyle(MLColor.ink)
        }
        if case .failed(let message) = model.send {
            Text(message).font(MLType.body).foregroundStyle(MLColor.danger)
        }
    }

    private func fact(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            Spacer()
            Text(value).font(MLType.body).foregroundStyle(MLColor.ink)
        }
        .accessibilityElement(children: .combine)
    }

    private func scope(_ scope: AccountScope) -> String {
        switch scope {
        case .mess: return SuperAdminCopy.oneMess
        case .hostel: return SuperAdminCopy.oneHostel
        }
    }
}
