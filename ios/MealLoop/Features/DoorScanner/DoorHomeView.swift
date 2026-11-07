import SwiftUI

/// Door Home: D04 (before), D05 (during), D05 offline and D12 (after). It follows the meal state and holds no data of its own.
struct DoorHomeView: View {
    @Environment(AppRouter.self) private var router
    let model: DoorHomeViewModel
    let sos: DoorSOSViewModel
    let repositories: Repositories
    let clock: any AppClock
    let onReload: () async -> Void
    let onOpenSOS: () -> Void
    let openProblems: Int
    @Binding var path: [DoorRoute]

    @State private var isEntryOpen = false

    var body: some View {
        GeometryReader { proxy in
            page(isCompact: proxy.size.height < DoorLayout.compactHeightLimit)
        }
    }

    private func page(isCompact: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    StaffHeader(initials: model.session.staffInitials) {
                        router.selectedStaffTab = .me
                    }
                    // DS-1 Offline draws its own line, so last values show without the shared banner.
                    if case .offline(let content?, _) = model.state {
                        homeBody(content, isCompact: isCompact)
                    } else {
                        AsyncContentView(state: model.state,
                                         emptyTitle: DoorScannerCopy.noMealTitle,
                                         emptyMessage: DoorScannerCopy.noMealDetail,
                                         timeZone: model.session.mess.timeZone,
                                         retry: onReload) { content in
                            homeBody(content, isCompact: isCompact)
                        }
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, 2)
                .padding(.bottom, DoorLayout.scrollBottomInset)
            }
            .refreshable { await onReload() }
            if let current = sos.current {
                SOSEdgeTab(count: sos.cases.count, isClaimedByYou: sos.isClaimedByYou,
                           claimedStatus: DoorScannerCopy.youreChecking, action: onOpenSOS)
                    .padding(.top, MLSize.avatar + MLSpacing.s16)
                    .id(current.id)
            }
        }
        .mlSheet(isPresented: $isEntryOpen) {
            if let meal = model.state.value?.meal {
                DoorEntrySheetHost(meal: meal, session: model.session, repositories: repositories,
                                   onClose: closeEntry,
                                   onReport: {
                                       closeEntry()
                                       path.append(.reportProblem)
                                   })
            }
        }
    }

    private func homeBody(_ content: DoorHomeContent, isCompact: Bool) -> some View {
        DoorHomeBody(content: content, mess: model.session.mess, isOffline: model.isOffline, isCompact: isCompact,
                     openProblems: openProblems,
                     onTypeID: { isEntryOpen = true },
                     open: { path.append($0) })
    }

    private func closeEntry() {
        isEntryOpen = false
        Task { await onReload() }
    }
}

/// The loaded screen. Pure layout: every value comes from `DoorHomeContent`.
struct DoorHomeBody: View {
    let content: DoorHomeContent
    let mess: Mess
    let isOffline: Bool
    var isCompact: Bool = false
    let openProblems: Int
    let onTypeID: () -> Void
    let open: (DoorRoute) -> Void

    private var mealName: String { MLFormat.mealSlot(content.meal.slot) }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            ScreenTitleBlock(title: mealName, subtitle: subtitle)
                .padding(.top, MLSpacing.s4)
            switch content.phase {
            case .beforeMeal(let opensAt):
                DoorWaitingCard(text: DoorScannerCopy.scanningOpens(at: MLFormat.time(opensAt, in: mess.timeZone)), isCompact: isCompact)
                reportCard
            case .duringMeal(let recorded, let minutes):
                if isOffline {
                    DoorOfflineLine()
                }
                MealProgressChip(text: DoorScannerCopy.mealInProgress(MLFormat.elapsed(minutes: minutes)))
                DoorScanCard(isOffline: isOffline, isCompact: isCompact)
                HStack(spacing: MLSpacing.s12) {
                    DoorCountTile(label: DoorScannerCopy.recordedIn, value: recorded.value)
                    typeIDButton
                }
                reportCard
            case .afterMeal(let finalEntries, _, let withoutVoting):
                afterMeal(finalEntries: finalEntries, withoutVoting: withoutVoting)
            }
        }
    }

    private var subtitle: String {
        if case .afterMeal(_, let closedAt?, _) = content.phase {
            return "\(mess.name) · \(DoorScannerCopy.ended(at: MLFormat.time(closedAt, in: mess.timeZone)))"
        }
        return "\(mess.name) · \(MLFormat.timeRange(content.meal.startsAt, content.meal.endsAt, in: mess.timeZone))"
    }

    private var reportCard: some View {
        IconCardRow(symbol: "exclamationmark.triangle", title: DoorScannerCopy.reportProblem) {
            open(.reportProblem)
        }
    }

    private var typeIDButton: some View {
        Button(action: onTypeID) {
            HStack(spacing: MLSpacing.s8) {
                Image(systemName: "keyboard")
                    .accessibilityHidden(true)
                Text(DoorScannerCopy.typeID)
            }
            .font(MLType.staffPrimary)
            .foregroundStyle(MLColor.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: MLSize.staffButton)
            .overlay(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).stroke(MLColor.ink, lineWidth: 1.5))
            .contentShape(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func afterMeal(finalEntries: CountReading, withoutVoting: Int) -> some View {
        HeroCard {
            StaffHeroLabel(text: DoorScannerCopy.mealEndedEyebrow)
            Text(DoorScannerCopy.hasEnded(mealName))
                .font(MLType.heroTitle)
                .foregroundStyle(MLColor.onHero)
                .padding(.top, MLSpacing.s8)
            Text(DoorScannerCopy.scanningClosed)
                .font(MLType.body)
                .foregroundStyle(MLColor.onHeroSecondary)
                .padding(.top, MLSpacing.s4)
            Spacer(minLength: MLSpacing.s24)
            Text(DoorScannerCopy.finalEntries)
                .font(MLType.body)
                .foregroundStyle(MLColor.onHeroSecondary)
            Text(finalEntries.value.map { String($0) } ?? DoorScannerCopy.unavailable)
                .font(finalEntries.value == nil ? MLType.heroTitle : MLType.heroNumber)
                .foregroundStyle(MLColor.onHero)
        }
        .frame(minHeight: DoorLayout.closedCardHeight)
        VStack(spacing: 0) {
            Rectangle().fill(MLColor.border).frame(height: 1)
            QuietRow(title: DoorScannerCopy.enteredWithoutVoting, value: String(withoutVoting)) {
                open(.withoutVoting(content.meal))
            }
            QuietRow(title: DoorScannerCopy.openProblems, value: String(openProblems)) {
                open(.openProblems)
            }
            QuietRow(title: DoorScannerCopy.reportProblem) {
                open(.reportProblem)
            }
        }
    }
}

/// The black card before scanning opens (D04): a dimmed QR and one line, nothing to act on.
struct DoorWaitingCard: View {
    let text: String
    var isCompact: Bool = false

    var body: some View {
        VStack(spacing: MLSpacing.s24) {
            Image(systemName: "qrcode")
                .font(.system(size: 96))
                .foregroundStyle(MLColor.onHeroSecondary.opacity(0.5))
                .accessibilityHidden(true)
            Text(text)
                .font(MLType.title2)
                .foregroundStyle(MLColor.onHero)
                .multilineTextAlignment(.center)
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, minHeight: DoorLayout.waitingCardHeight(isCompact: isCompact))
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.heroBackground))
        .accessibilityElement(children: .combine)
    }
}

/// The scanner card (D05, D05 offline). There is no camera yet, so it says so and points to Type ID.
/// It has no torch, because a control that does nothing would be a dead button.
struct DoorScanCard: View {
    let isOffline: Bool
    var isCompact: Bool = false

    var body: some View {
        VStack(spacing: MLSpacing.s12) {
            Image(systemName: isOffline ? "wifi.slash" : "qrcode")
                .font(.system(size: isOffline ? 44 : 80))
                .foregroundStyle(MLColor.onHeroSecondary.opacity(isOffline ? 1 : 0.5))
                .accessibilityHidden(true)
            if isOffline {
                Text(DoorScannerCopy.noConnection)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.onHero)
                Text(DoorScannerCopy.noConnectionDetail)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.onHeroSecondary)
            } else {
                Text(DoorScannerCopy.cameraOff)
                    .font(MLType.staffBody)
                    .foregroundStyle(MLColor.onHero)
            }
        }
        .multilineTextAlignment(.center)
        .padding(MLSpacing.s32)
        .frame(maxWidth: .infinity, minHeight: isOffline ? DoorLayout.offlineScanCardHeight : DoorLayout.scanCardHeight(isCompact: isCompact))
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.heroBackground))
        .overlay {
            DoorBrackets()
                .stroke(isOffline ? MLColor.onHeroSecondary : MLColor.lime, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .padding(MLSpacing.s16)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The four viewfinder corners of the scanner card.
struct DoorBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        let arm: CGFloat = 44
        let radius = MLRadius.compact
        var path = Path()
        func corner(_ start: CGPoint, _ turn: CGPoint, _ end: CGPoint) {
            path.move(to: start)
            path.addArc(tangent1End: turn, tangent2End: end, radius: radius)
            path.addLine(to: end)
        }
        corner(CGPoint(x: rect.minX, y: rect.minY + arm), CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.minX + arm, y: rect.minY))
        corner(CGPoint(x: rect.maxX - arm, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY + arm))
        corner(CGPoint(x: rect.maxX, y: rect.maxY - arm), CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.maxX - arm, y: rect.maxY))
        corner(CGPoint(x: rect.minX + arm, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY - arm))
        return path
    }
}

/// The black line above the chip when the connection is gone (DS-1 Offline).
struct DoorOfflineLine: View {
    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            Image(systemName: "wifi.slash")
                .accessibilityHidden(true)
            Text(DoorScannerCopy.notBeingRecorded)
                .font(MLType.bodyEmphasis)
        }
        .foregroundStyle(MLColor.onHero)
        .padding(.horizontal, MLSpacing.s16)
        .padding(.vertical, MLSpacing.s8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.heroBackground))
        .accessibilityElement(children: .combine)
    }
}

/// A white tile with a label and a number (D05). A missing count shows "—", never 0.
struct DoorCountTile: View {
    let label: String
    let value: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(label)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(value.map { String($0) } ?? "—")
                .font(MLType.heroTitle.monospaced())
                .foregroundStyle(MLColor.ink)
        }
        .padding(MLSpacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }
}
