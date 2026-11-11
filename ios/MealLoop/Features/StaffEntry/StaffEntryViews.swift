import SwiftUI

// Mess staff entry, from the 09 Mess Staff page: Staff sign in opens MS-1 Choose your role (1508:235) → What you do
// (sheet, DS-0 2469:1927, PD-0 2529:4180, KS-0 2571:157, SV-0 2620:10628) → the role's shared password (2469:2102,
// Wrong 2469:2229, Locked 2469:2355) → Home. The MS-0 SRM pages (1508:45, 1508:111, 1508:147) are left out by owner
// ruling (11 Nov). Every step is pushed on the entry stack (`EntryRoute`).

/// MS-1 · Choose your role (1508:235). A pushed page, so the system back button and swipe-back work.
/// "Sign in with email" under the roles is for accounts that are not mess staff; no frame draws it.
struct RoleSelectionView: View {
    @Environment(AppRouter.self) private var router
    @State private var sheetRole: Role?

    var body: some View {
        MLScreen(StaffEntryCopy.chooseRoleTitle, subtitle: StaffEntryCopy.chooseRoleSubtitle) {
            VStack(spacing: MLSpacing.s16) {
                ForEach(Role.staffRoles, id: \.self) { role in
                    RoleRow(role: role, isFirst: role == Role.staffRoles.first) {
                        choose(role)
                    }
                }
                Text(StaffEntryCopy.managersHeader)
                    .mlFont(.bodyEmphasis)
                    .foregroundStyle(MLColor.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, MLSpacing.s8)
                    .accessibilityAddTraits(.isHeader)
                ForEach(StaffEntryCopy.accountRoles, id: \.self) { role in
                    RoleRow(role: role) {
                        router.entryPath.append(.accountSignIn(role))
                    }
                }
                TextLinkButton(title: StaffEntryCopy.signInWithEmail) {
                    router.entryPath.append(.emailSignIn)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, MLSpacing.s8)
            }
        }
        .mlSheet(item: $sheetRole) { role in
            WhatYouDoSheet(role: role, onClose: { sheetRole = nil }) {
                sheetRole = nil
                router.entryPath.append(.rolePassword(role))
            }
        }
    }

    private func choose(_ role: Role) {
        if WhatYouDoPreference.isHidden(for: role) {
            router.entryPath.append(.rolePassword(role))
        } else {
            sheetRole = role
        }
    }
}

/// "Don't show this again" is remembered per role on this device.
enum WhatYouDoPreference {
    private static func key(_ role: Role) -> String { "whatYouDo.hidden.\(role.rawValue)" }

    static func isHidden(for role: Role) -> Bool {
        UserDefaults.standard.bool(forKey: key(role))
    }

    static func hide(for role: Role) {
        UserDefaults.standard.set(true, forKey: key(role))
    }
}

struct RoleRow: View {
    let role: Role
    var isFirst: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s16) {
                Image(systemName: StaffEntryCopy.roleSymbol(role))
                    .font(.system(size: 22))
                    .foregroundStyle(MLColor.ink)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(isFirst ? MLColor.lime : MLColor.fillQuiet))
                    .overlay {
                        if isFirst { Circle().stroke(MLColor.limeOutline, lineWidth: 1) }
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(StaffEntryCopy.roleTitle(role))
                        .mlFont(.title2)
                        .foregroundStyle(MLColor.ink)
                    Text(StaffEntryCopy.roleHint(role))
                        .mlFont(.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(MLColor.inkSecondary)
            }
            .padding(MLSpacing.s20)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// What you do (sheet), one per role (DS-0, PD-0, KS-0, SV-0). Shown in `mlSheet`, as tall as its content.
struct WhatYouDoSheet: View {
    let role: Role
    let onClose: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: StaffEntryCopy.whatYouDoTitle, onClose: onClose)
            ForEach(Array(StaffEntryCopy.whatYouDo(role).enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: MLSpacing.s16) {
                    Image(systemName: item.symbol)
                        .foregroundStyle(MLColor.ink)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(index == 0 ? MLColor.lime : MLColor.fillQuiet))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .mlFont(.staffPrimary)
                            .foregroundStyle(MLColor.ink)
                        Text(item.detail)
                            .mlFont(.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
            InkActionButton(title: StaffEntryCopy.continueTitle, action: onContinue)
                .padding(.top, MLSpacing.s8)
            Button {
                WhatYouDoPreference.hide(for: role)
                onContinue()
            } label: {
                Text(StaffEntryCopy.dontShowAgain)
                    .mlFont(.body)
                    .underline()
                    .foregroundStyle(MLColor.ink)
                    .frame(maxWidth: .infinity, minHeight: MLSize.hit)
            }
            .buttonStyle(.plain)
        }
    }
}

/// Builds the view model from the environment, then shows the password page.
struct RolePasswordScreen: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let role: Role

    var body: some View {
        RolePasswordView(model: RolePasswordViewModel(role: role, auth: environment.repositories.auth)) { session in
            router.reset()
            sessionStore.signIn(session)
        }
    }
}

/// DS-0 · Password (2469:2102), Wrong (2469:2229) and Locked (2469:2355). The same page for each role.
struct RolePasswordView: View {
    @State private var model: RolePasswordViewModel
    private let onGranted: (Session) -> Void

    init(model: RolePasswordViewModel, onGranted: @escaping (Session) -> Void) {
        _model = State(initialValue: model)
        self.onGranted = onGranted
    }

    var body: some View {
        MLScreen(StaffEntryCopy.enterPasswordTitle, subtitle: StaffEntryCopy.passwordSubtitle(model.role)) {
            Label(MLFormat.roleName(model.role), systemImage: StaffEntryCopy.roleSymbol(model.role))
                .mlFont(.bodyEmphasis)
                .foregroundStyle(MLColor.ink)
                .padding(.horizontal, MLSpacing.s16)
                .frame(minHeight: MLSize.hit)
                .overlay(Capsule().stroke(MLColor.ink, lineWidth: 1.5))
        } trailing: {
            EmptyView()
        } content: {
            VStack(spacing: MLSpacing.s16) {
                passwordBoxes
                statusLine
                KeyPad(isEnabled: model.isKeypadEnabled) { digit in
                    Task {
                        if let session = await model.append(digit) {
                            onGranted(session)
                        }
                    }
                } onDelete: {
                    model.deleteLast()
                }
                Text(StaffEntryCopy.passwordFooter)
                    .mlFont(.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .frame(maxWidth: .infinity)
            }
        } bottom: {
            EmptyView()
        }
    }

    private var isWrong: Bool {
        if case .wrong = model.phase { return true }
        return false
    }

    private var passwordBoxes: some View {
        HStack(spacing: MLSpacing.s12) {
            ForEach(0..<RolePasswordPolicy.digits, id: \.self) { index in
                RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
                    .fill(MLColor.surface)
                    .frame(height: 72)
                    .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
                        .stroke(isWrong ? MLColor.danger : MLColor.ink, lineWidth: index < model.digits.count || isWrong ? 1.5 : 0))
                    .overlay {
                        if index < model.digits.count {
                            Circle().fill(MLColor.ink).frame(width: 16, height: 16)
                        }
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(model.digits.count) of \(RolePasswordPolicy.digits) digits entered")
    }

    @ViewBuilder
    private var statusLine: some View {
        switch model.phase {
        case .wrong(let triesLeft):
            Text(StaffEntryCopy.wrongPassword(triesLeft: triesLeft))
                .mlFont(.staffPrimary)
                .foregroundStyle(MLColor.danger)
                .frame(maxWidth: .infinity)
        case .locked(let resetBy):
            VStack(alignment: .leading, spacing: MLSpacing.s8) {
                Label(StaffEntryCopy.lockedTitle, systemImage: "lock")
                    .mlFont(.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                Text(StaffEntryCopy.lockedDetail(role: model.role, resetBy: resetBy))
                    .mlFont(.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(MLSpacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
        case .failed(let failure):
            Text(failure.message)
                .mlFont(.body)
                .foregroundStyle(MLColor.danger)
        case .checking:
            ProgressView().frame(maxWidth: .infinity)
        case .entering:
            EmptyView()
        }
    }
}
