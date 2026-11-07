import SwiftUI

/// History (screen 5): today's headcounts that reached the vendor, newest first. A missing reply is Pending.
struct VendorHistoryView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: VendorHistoryViewModel
    let mess: Mess?
    let onBack: () -> Void

    init(model: VendorHistoryViewModel, mess: Mess?, onBack: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.mess = mess
        self.onBack = onBack
    }

    private var timeZone: TimeZone { mess?.timeZone ?? .current }

    var body: some View {
        ZStack(alignment: .topLeading) {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    VStack(alignment: .leading, spacing: MLSpacing.s8) {
                        BackButton(action: onBack)
                            .padding(.leading, -MLSpacing.s4)
                        ScreenTitleBlock(title: VendorCopy.history, subtitle: mess?.name ?? "")
                    }
                    AsyncContentView(state: model.state,
                                     emptyTitle: VendorCopy.nothingSentYet,
                                     emptyMessage: VendorCopy.nothingSentYetDetail,
                                     timeZone: timeZone,
                                     retry: { await model.load() }) { entries in
                        VStack(spacing: MLSpacing.s12) {
                            ForEach(entries) { entry in
                                VendorStatusRow(title: VendorFormat.historyTitle(entry)) {
                                    VendorReplyText(prefix: entry.acknowledgedAt == nil ? nil : VendorCopy.repliedWord,
                                                    time: entry.acknowledgedAt.map { MLFormat.time($0, in: timeZone) })
                                }
                            }
                            VendorNote(text: VendorCopy.pendingNote)
                                .padding(.top, MLSpacing.s4)
                        }
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, VendorLayout.tabBarClearance)
            }
        }
        .task(id: environment.dataRevision) { await model.load() }
    }
}

/// Me (screen 6): who is signed in, and Sign out. Nothing here edits the account.
struct VendorMeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let account: Account
    let mess: Mess?

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    Text(VendorCopy.me)
                        .font(MLType.largeTitle)
                        .foregroundStyle(MLColor.ink)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, MLSize.hit + MLSpacing.s8)
                    HStack(spacing: MLSpacing.s16) {
                        Text(VendorFormat.initials(account.displayName))
                            .font(MLType.heroTitle)
                            .foregroundStyle(MLColor.lime)
                            .frame(width: VendorLayout.meAvatar, height: VendorLayout.meAvatar)
                            .background(Circle().fill(MLColor.ink))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: MLSpacing.s4) {
                            Text(account.displayName)
                                .font(MLType.heroTitle)
                                .foregroundStyle(MLColor.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            if let mess {
                                Text(mess.name)
                                    .font(MLType.body)
                                    .foregroundStyle(MLColor.inkSecondary)
                            }
                            Text(account.email)
                                .font(MLType.body)
                                .foregroundStyle(MLColor.inkSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                    }
                    .padding(.bottom, MLSpacing.s12)
                    VStack(spacing: 0) {
                        Rectangle().fill(MLColor.border).frame(height: 1)
                        Button {
                            router.reset()
                            sessionStore.signOut()
                        } label: {
                            Text(VendorCopy.signOut)
                                .font(MLType.staffPrimary)
                                .foregroundStyle(MLColor.ink)
                                .frame(maxWidth: .infinity, minHeight: MLSize.staffButton, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .bottom) { Rectangle().fill(MLColor.border).frame(height: 1) }
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.bottom, VendorLayout.tabBarClearance)
            }
        }
    }
}
