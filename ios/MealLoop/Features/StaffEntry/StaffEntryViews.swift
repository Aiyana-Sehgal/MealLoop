#if DEMO_DATA
import SwiftUI

/// RETIRED FROM THE APP FLOW: Staff sign in replaced this role selection and shared password path.
/// Kept in Debug only, with nothing opening it, until the owner decides whether D01 to D03 return.
/// Staff entry: Choose your role → What you do (sheet, can be skipped next time) → shared password → role Home.
struct StaffEntryFlowView: View {
    @Environment(AppRouter.self) private var router
    let onGranted: (StaffSession) -> Void

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.staffEntryPath) {
            RoleSelectionView()
                .navigationDestination(for: StaffEntryRoute.self) { route in
                    switch route {
                    case .password(let role):
                        RolePasswordScreen(role: role, onGranted: onGranted)
                    }
                }
        }
    }
}

struct RoleSelectionView: View {
    @Environment(AppRouter.self) private var router
    @State private var sheetRole: Role?

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    VStack(alignment: .leading, spacing: MLSpacing.s4) {
                        Text(StaffEntryCopy.chooseRoleTitle)
                            .font(MLType.largeTitle)
                            .foregroundStyle(MLColor.ink)
                        Text(StaffEntryCopy.chooseRoleSubtitle)
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                    ForEach(Role.staffRoles, id: \.self) { role in
                        RoleRow(role: role, isFirst: role == Role.staffRoles.first) {
                            choose(role)
                        }
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    router.reset()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Back")
            }
        }
        .sheet(item: $sheetRole) { role in
            WhatYouDoSheet(role: role) {
                sheetRole = nil
                router.staffEntryPath.append(.password(role))
            }
            .presentationDetents([.medium])
        }
    }

    private func choose(_ role: Role) {
        if WhatYouDoPreference.isHidden(for: role) {
            router.staffEntryPath.append(.password(role))
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
                    Text(MLFormat.roleName(role))
                        .font(MLType.title2)
                        .foregroundStyle(MLColor.ink)
                    Text(StaffEntryCopy.roleHint(role))
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(MLColor.inkSecondary)
            }
            .padding(MLSpacing.s20)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        }
        .buttonStyle(.plain)
    }
}

struct WhatYouDoSheet: View {
    let role: Role
    let onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            HStack {
                Text(StaffEntryCopy.whatYouDoTitle)
                    .font(MLType.title2)
                    .foregroundStyle(MLColor.ink)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(MLColor.ink)
                        .frame(width: MLSize.hit, height: MLSize.hit)
                        .background(Circle().fill(MLColor.surface))
                }
                .accessibilityLabel("Close")
            }
            ForEach(Array(StaffEntryCopy.whatYouDo(role).enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: MLSpacing.s16) {
                    Image(systemName: item.symbol)
                        .foregroundStyle(MLColor.ink)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(index == 0 ? MLColor.lime : MLColor.fillQuiet))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(MLType.staffPrimary)
                            .foregroundStyle(MLColor.ink)
                        Text(item.detail)
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                }
            }
            InkActionButton(title: StaffEntryCopy.continueTitle, action: onContinue)
            Button {
                WhatYouDoPreference.hide(for: role)
                onContinue()
            } label: {
                Text(StaffEntryCopy.dontShowAgain)
                    .font(MLType.body)
                    .underline()
                    .foregroundStyle(MLColor.ink)
                    .frame(maxWidth: .infinity, minHeight: MLSize.hit)
            }
            .buttonStyle(.plain)
        }
        .padding(MLSpacing.margin)
        .presentationBackground(MLColor.fillQuiet)
    }
}

/// Builds the view model from the environment, then shows the password page.
struct RolePasswordScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let role: Role
    let onGranted: (StaffSession) -> Void

    var body: some View {
        RolePasswordView(model: RolePasswordViewModel(role: role, auth: environment.repositories.auth), onGranted: onGranted)
    }
}

struct RolePasswordView: View {
    @State private var model: RolePasswordViewModel
    private let onGranted: (StaffSession) -> Void

    init(model: RolePasswordViewModel, onGranted: @escaping (StaffSession) -> Void) {
        _model = State(initialValue: model)
        self.onGranted = onGranted
    }

    var body: some View {
        ZStack {
            OrbitBackground()
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                Label(MLFormat.roleName(model.role), systemImage: StaffEntryCopy.roleSymbol(model.role))
                    .font(MLType.bodyEmphasis)
                    .foregroundStyle(MLColor.ink)
                    .padding(.horizontal, MLSpacing.s16)
                    .frame(minHeight: MLSize.hit)
                    .overlay(Capsule().stroke(MLColor.ink, lineWidth: 1.5))
                Text(StaffEntryCopy.enterPasswordTitle)
                    .font(MLType.largeTitle)
                    .foregroundStyle(MLColor.ink)
                Text(StaffEntryCopy.passwordSubtitle(model.role))
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
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
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, MLSpacing.margin)
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
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.danger)
                .frame(maxWidth: .infinity)
        case .locked(let resetBy):
            VStack(alignment: .leading, spacing: MLSpacing.s8) {
                Label(StaffEntryCopy.lockedTitle, systemImage: "lock")
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                Text(StaffEntryCopy.lockedDetail(role: model.role, resetBy: resetBy))
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            .padding(MLSpacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
        case .failed(let failure):
            Text(failure.message)
                .font(MLType.body)
                .foregroundStyle(MLColor.danger)
        case .checking:
            ProgressView().frame(maxWidth: .infinity)
        case .entering:
            EmptyView()
        }
    }
}
#endif
