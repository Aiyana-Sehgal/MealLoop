import SwiftUI

/// The answer row (AnswerRow 2135:2382). Unanswered and Not sure: black Answer. In and Skipped: outlined Change.
/// After the cutoff: dashed Closed, and "your QR still works".
struct StudentAnswerRow: View {
    let card: StudentMealCard
    let now: Date
    let timeZone: TimeZone
    let onOpen: () -> Void

    private var slot: MealSlot { card.meal.slot }
    private var cutoffTime: String { StudentFormat.shortTime(card.cutoff, in: timeZone) }
    private var timeLeft: String {
        StudentFormat.compactLeft(MLFormat.elapsed(minutes: MLFormat.minutes(from: now, to: card.cutoff)))
    }

    private var title: String {
        guard card.isAnswerOpen else { return StudentCopy.answersClosedRow(slot) }
        switch card.answer {
        case .attending?: return StudentCopy.youreIn(slot)
        case .skipping?: return StudentCopy.youSkipped(slot)
        case .notSure?, nil: return StudentCopy.youInFor(slot)
        }
    }

    private var detail: String {
        guard card.isAnswerOpen else { return StudentCopy.cutoffPassed(cutoffTime) }
        switch card.answer {
        case .attending?, .skipping?: return StudentCopy.changeBy(cutoffTime, left: timeLeft)
        case .notSure?, nil: return StudentCopy.decideBy(cutoffTime, left: timeLeft)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "fork.knife")
                .font(.system(size: 19))
                .foregroundStyle(MLColor.ink)
                .frame(width: MLSize.hit, height: MLSize.hit)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(MLColor.fillQuiet))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(MLColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(StudentType.footnote)
                    .foregroundStyle(MLColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            action
        }
        .padding(.leading, MLSpacing.s16)
        .padding(.trailing, MLSpacing.s12)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
    }

    @ViewBuilder
    private var action: some View {
        if !card.isAnswerOpen {
            Button(action: onOpen) {
                Text(StudentCopy.closed)
                    .font(StudentType.secondaryMedium)
                    .foregroundStyle(MLColor.inkSecondary)
                    .padding(.horizontal, MLSpacing.s20)
                    .frame(height: MLSize.hit)
                    .background(Capsule().strokeBorder(MLColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
            }
            .buttonStyle(.plain)
        } else if card.answer == .attending || card.answer == .skipping {
            Button(action: onOpen) {
                Text(StudentCopy.change)
                    .font(StudentType.secondaryMedium)
                    .foregroundStyle(MLColor.ink)
                    .padding(.horizontal, MLSpacing.s20)
                    .frame(height: MLSize.hit)
                    .background(Capsule().strokeBorder(MLColor.ink, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        } else {
            Button(action: onOpen) {
                Text(StudentCopy.answer)
                    .font(StudentType.secondaryMedium)
                    .foregroundStyle(MLColor.onHero)
                    .padding(.horizontal, MLSpacing.s20)
                    .frame(height: MLSize.hit)
                    .background(Capsule().fill(MLColor.ink))
            }
            .buttonStyle(.plain)
        }
    }
}

/// A rounded row with a half circle cut from each end, 22 pt below the row's centre (TicketStrip 2133:2374).
struct StudentTicketShape: Shape {
    func path(in rect: CGRect) -> Path {
        let row = Path(roundedRect: rect, cornerRadius: StudentMetric.rowRadius, style: .continuous)
        let radius: CGFloat = 10
        let y = rect.midY + 22
        var notches = Path()
        notches.addEllipse(in: CGRect(x: rect.minX - radius, y: y - radius, width: radius * 2, height: radius * 2))
        notches.addEllipse(in: CGRect(x: rect.maxX - radius, y: y - radius, width: radius * 2, height: radius * 2))
        return row.subtracting(notches)
    }
}

/// The dashed line between a ticket's text and its status.
struct StudentPerforation: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

/// The Special pass row: a notched ticket, a dashed perforation and the status.
struct StudentTicketRow: View {
    let pass: StudentPassRow
    let timeZone: TimeZone
    let onOpen: () -> Void

    private var when: String {
        StudentCopy.passWhen(StudentFormat.shortDay(pass.meal.startsAt, in: timeZone),
                             range: MLFormat.timeRange(pass.meal.startsAt, pass.meal.endsAt, in: timeZone))
    }

    private var status: String {
        switch pass.status {
        case .open: return StudentCopy.open
        case .used: return StudentCopy.used
        case .closed: return StudentCopy.closed
        }
    }

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 14) {
                Image("student-ticket")
                    .resizable()
                    .frame(width: 22, height: 22)
                    .frame(width: MLSize.hit, height: MLSize.hit)
                    .background(Circle().fill(MLColor.heroBackground))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(StudentCopy.specialPass)
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(MLColor.ink)
                    Text(when)
                        .font(StudentType.footnote)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: 0)
                StudentPerforation()
                    .stroke(MLColor.border, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .frame(width: 1.5, height: 40)
                    .accessibilityHidden(true)
                HStack(spacing: MLSpacing.s4) {
                    if pass.status == .open {
                        Circle().fill(MLColor.ink).frame(width: 12, height: 12)
                    }
                    Text(status)
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(pass.status == .open ? MLColor.ink : MLColor.inkSecondary)
                }
            }
            .padding(.horizontal, MLSpacing.s20)
            .padding(.vertical, 14)
            .background(StudentTicketShape().fill(MLColor.surface))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(StudentCopy.specialPass), \(when), \(status)")
    }
}

/// The one Crowd row (CrowdRow 2133:2427). Its level is an estimate and the bars are hourly activity, never a head count.
struct StudentCrowdRow: View {
    /// Nil when there is no reading to show.
    let crowd: CrowdReading?
    let mess: String
    let timeZone: TimeZone

    private var detail: String? {
        guard let crowd, let time = crowd.detailTime else { return nil }
        return StudentCopy.crowdDetail(crowd.level, time: StudentFormat.shortTime(time, in: timeZone).replacingOccurrences(of: " ", with: "\u{00A0}"))
    }

    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(StudentCopy.crowdAt(mess))
                    .font(StudentType.footnote)
                    .foregroundStyle(MLColor.inkSecondary)
                Text(crowd.map { StudentCopy.crowdLevel($0.level) } ?? StudentCopy.crowdUnavailable)
                    .font(StudentType.section)
                    .foregroundStyle(crowd == nil ? MLColor.inkSecondary : MLColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let detail {
                    Text(detail)
                        .font(StudentType.footnote)
                        .foregroundStyle(MLColor.inkSecondary)
                }
            }
            Spacer(minLength: 0)
            if let crowd {
                bars(crowd)
            }
        }
        .padding(.horizontal, MLSpacing.s20)
        .padding(.vertical, MLSpacing.s16)
        .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).strokeBorder(MLColor.border, lineWidth: 1.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([StudentCopy.crowdAt(mess), crowd.map { StudentCopy.crowdSpoken($0.level) } ?? StudentCopy.crowdUnavailable, detail]
            .compactMap { $0 }.joined(separator: ", "))
    }

    private func bars(_ crowd: CrowdReading) -> some View {
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(Array(crowd.bars.enumerated()), id: \.offset) { index, height in
                RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                    .fill(fill(index, crowd))
                    .overlay {
                        if index == crowd.currentBar {
                            RoundedRectangle(cornerRadius: 6.5, style: .continuous).strokeBorder(MLColor.limeOutline, lineWidth: 1.2)
                        }
                    }
                    .frame(width: 13, height: CGFloat(height))
            }
        }
        .frame(height: 48, alignment: .bottom)
    }

    private func fill(_ index: Int, _ crowd: CrowdReading) -> Color {
        if crowd.level == .closed { return MLColor.track }
        return index == crowd.currentBar ? MLColor.lime : MLColor.ink
    }
}

// Home · After a meal: the How was … card is `StudentHowWasCard` (StudentRatingsViews.swift).

/// The follow-up on the student's own feedback (Feedback row 2147:620).
struct StudentRecheckRow: View {
    let recheck: StudentRecheck
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: MLSpacing.s12) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 19))
                    .foregroundStyle(MLColor.inkSecondary)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(recheck.title)
                        .font(StudentType.bodySemibold)
                        .foregroundStyle(MLColor.ink)
                    Text(recheck.detail)
                        .font(StudentType.secondary)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.leading, MLSpacing.s4)
            .padding(.vertical, MLSpacing.s4)
        }
        .buttonStyle(.plain)
    }
}
