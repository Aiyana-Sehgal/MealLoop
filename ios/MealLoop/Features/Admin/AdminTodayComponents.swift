import SwiftUI

/// Breakfast, Lunch, Snacks, Dinner with done, current and upcoming stops (A01). Only Admin draws this.
struct AdminDayLine: View {
    let nodes: [AdminDayNode]
    let selected: MealSlot
    let onSelect: (MealSlot) -> Void

    private let selectedDiameter: CGFloat = 32
    private let nodeDiameter: CGFloat = 24
    private let rowHeight: CGFloat = 32

    /// Ink runs from the first stop to the last one reached.
    private var reachedFraction: CGFloat {
        guard nodes.count > 1 else { return 0 }
        let last = nodes.lastIndex { $0.progress != .upcoming } ?? 0
        return CGFloat(last) / CGFloat(nodes.count - 1)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(nodes) { node in
                nodeButton(node)
            }
        }
        .background(alignment: .top) {
            GeometryReader { proxy in
                // The line runs between the centres of the first and last columns.
                let inset = proxy.size.width / CGFloat(max(nodes.count, 1) * 2)
                let width = proxy.size.width - inset * 2
                ZStack(alignment: .leading) {
                    Rectangle().fill(MLColor.track).frame(width: width, height: 3)
                    Rectangle().fill(MLColor.ink).frame(width: width * reachedFraction, height: 3)
                }
                .padding(.leading, inset)
                .frame(height: rowHeight)
            }
        }
    }

    private func nodeButton(_ node: AdminDayNode) -> some View {
        let isSelected = node.slot == selected
        let name = MLFormat.mealSlot(node.slot)
        return Button {
            onSelect(node.slot)
        } label: {
            VStack(spacing: MLSpacing.s4) {
                marker(node, isSelected: isSelected)
                    .frame(height: rowHeight)
                Text(name)
                    .font(isSelected ? MLType.bodyEmphasis : MLType.body)
                    .foregroundStyle(isSelected ? MLColor.ink : MLColor.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: MLSize.hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityValue(spokenProgress(node.progress))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func marker(_ node: AdminDayNode, isSelected: Bool) -> some View {
        if isSelected {
            Circle()
                .fill(MLColor.lime)
                .overlay(Circle().stroke(MLColor.limeOutline, lineWidth: 2))
                .overlay {
                    if node.progress == .done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(MLColor.onLime)
                    }
                }
                .frame(width: selectedDiameter, height: selectedDiameter)
        } else if node.progress == .done {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(MLColor.onHero)
                .frame(width: nodeDiameter, height: nodeDiameter)
                .background(Circle().fill(MLColor.ink))
        } else if node.progress == .current {
            Circle().fill(MLColor.ink).frame(width: nodeDiameter, height: nodeDiameter)
        } else {
            Circle()
                .fill(MLColor.canvas)
                .overlay(Circle().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])))
                .frame(width: nodeDiameter, height: nodeDiameter)
        }
    }

    private func spokenProgress(_ progress: AdminDayNode.Progress) -> String {
        switch progress {
        case .done: return "Done"
        case .current: return "Now"
        case .upcoming: return "Next"
        }
    }
}

/// One mess tile (A01): black when it needs action, white once it doesn't, dashed with no data.
/// The big number always carries its own name, so one headcount value can never pass for another.
struct AdminMessTile: View {
    let content: AdminTodayContent
    let openHeadcount: () -> Void

    private var meal: AdminMealContent? { content.meal }
    private var timeZone: TimeZone { content.mess.timeZone }
    private var isHero: Bool { content.tileIsUrgent }
    private var hasData: Bool { meal?.filledSteps != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(content.mess.name)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(isHero ? MLColor.onHero : MLColor.ink)
                if hasData, let lead = meal?.leadValue {
                    Text(lead.name)
                        .font(MLType.secondary)
                        .foregroundStyle(isHero ? MLColor.onHeroSecondary : MLColor.inkSecondary)
                }
            }
            Text((hasData ? meal?.leadValue.count : nil).map { String($0) } ?? "—")
                .font(MLType.heroNumber)
                .foregroundStyle(isHero ? MLColor.onHero : (hasData ? MLColor.ink : MLColor.inkSecondary))
            SegmentedProgress(current: meal?.filledSteps, total: 4, surface: isHero ? .hero : .light,
                              missingText: AdminCopy.noData)
            bottomLine
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { background }
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous)
        if isHero {
            shape.fill(MLColor.heroBackground)
        } else if hasData {
            shape.fill(MLColor.surface)
        } else {
            shape.stroke(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
        }
    }

    @ViewBuilder
    private var bottomLine: some View {
        if let meal, hasData {
            Text(statusLine(meal))
                .font(MLType.body)
                .foregroundStyle(isHero ? MLColor.onHeroSecondary : MLColor.ink)
            action(meal)
        } else {
            Text(AdminCopy.noData)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
        }
    }

    @ViewBuilder
    private func action(_ meal: AdminMealContent) -> some View {
        if let next = meal.nextAction {
            let title = if case .approve = next { AdminCopy.reviewAndApprove } else { AdminCopy.reviewAndSend }
            if isHero {
                LimeActionButton(title: title, action: openHeadcount)
            } else {
                // A safety case holds the black place, so the action steps back to an outline.
                CompactPillButton(title: title, action: openHeadcount)
            }
        } else {
            TextLinkButton(title: AdminCopy.seeHeadcount, action: openHeadcount)
        }
    }

    private func statusLine(_ meal: AdminMealContent) -> String {
        switch meal.status.state {
        case .closed:
            if let closedAt = meal.status.closedAt { return AdminCopy.closedAt(MLFormat.time(closedAt, in: timeZone)) }
        case .inService:
            return AdminCopy.servingNotFinal
        case .notStarted:
            break
        }
        switch meal.headcount.vendorAcknowledgmentStatus {
        case .acknowledged(let record):
            return AdminCopy.acknowledgedAt(MLFormat.time(record.acknowledgedAt, in: timeZone))
        case .pending(let publishedAt):
            return AdminCopy.sentPending(MLFormat.time(publishedAt, in: timeZone))
        case .notPublished:
            return meal.headcount.approved.count == nil ? AdminCopy.waitingForApproval : AdminCopy.approvedNotSent
        }
    }
}

/// The six named values. A missing one says so in words, and is never drawn as zero.
struct AdminHeadcountValuesCard: View {
    let values: [AdminHeadcountValue]

    var body: some View {
        FactCard(rows: values.map { value in
            FactRow(label: value.name, value: value.count.map { String($0) } ?? AdminCopy.notAvailableYet,
                    isMono: value.count != nil)
        })
    }
}

/// Approval and vendor status: a dot and plain text. Pending never reads as replied or agreed.
struct AdminHeadcountStatusRows: View {
    let headcount: Headcount?
    let timeZone: TimeZone

    var body: some View {
        VStack(spacing: 0) {
            row(AdminCopy.approval) { approval }
            Rectangle().fill(MLColor.border).frame(height: 1)
            row(AdminCopy.vendor) { vendor }
        }
    }

    private func row<Status: View>(_ title: String, @ViewBuilder status: () -> Status) -> some View {
        HStack(spacing: MLSpacing.s12) {
            Text(title)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            Spacer(minLength: MLSpacing.s8)
            status()
        }
        .frame(minHeight: MLSize.hit)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var approval: some View {
        if case .approved(let approved)? = headcount?.approved {
            StatusText(text: AdminCopy.approved, dot: .filled, time: MLFormat.time(approved.approvedAt, in: timeZone))
        } else {
            StatusText(text: AdminCopy.notApproved, dot: .empty)
        }
    }

    @ViewBuilder
    private var vendor: some View {
        switch headcount?.vendorAcknowledgmentStatus {
        case .acknowledged(let record)?:
            StatusText(text: AdminCopy.acknowledged, dot: .filled, time: MLFormat.time(record.acknowledgedAt, in: timeZone))
        case .pending?:
            StatusText(text: AdminCopy.pending, dot: .dashed)
        case .notPublished?, nil:
            StatusText(text: AdminCopy.notSent, dot: .empty)
        }
    }
}
