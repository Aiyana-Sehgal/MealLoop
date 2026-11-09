import SwiftUI

// Coverage (student-all G4): Crowd · Main Mess · Busy (2220:158655), Closed (2220:158973), Breakfast (2220:159132),
// Snacks (2220:159291) and Dinner (2220:159442) are this view with the crowd reading's level and meal. Packed
// (2220:158814) is not built: `CrowdLevel` has no Packed level and where Busy ends is not decided.

/// Builds the view model from the environment.
struct StudentCrowdScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session
    let onBack: () -> Void

    var body: some View {
        if let model = StudentCrowdViewModel(session: session, repositories: environment.repositories) {
            StudentCrowdView(model: model, onBack: onBack)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// Crowd · Main Mess (221:63246) and its Offline frame (221:65361). Own mess only. The level is an estimate and is
/// labelled so; nothing here claims how many people are inside.
struct StudentCrowdView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: StudentCrowdViewModel
    let onBack: () -> Void

    init(model: StudentCrowdViewModel, onBack: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onBack = onBack
    }

    /// On `MLScreen`: the system back button and swipe-back pop the page; `onBack` stays for callers.
    var body: some View {
        MLScreen(MealsCopy.crowd, subtitle: model.context.mess.name, bottomClearance: .tabBar) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                content
            }
        }
        .refreshable { await model.load() }
        .task(id: environment.dataRevision) {
            await model.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            ForEach([143, 249, 118], id: \.self) { height in
                RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous)
                    .fill(MLColor.track.opacity(0.8))
                    .frame(height: CGFloat(height))
            }
        case .loaded(let crowd), .stale(let crowd, _):
            CrowdBody(crowd: crowd, isOffline: false, timeZone: model.timeZone)
        case .offline(let crowd?, _):
            StudentOfflineBanner(text: MealsCopy.crowdOffline(MLFormat.time(crowd.observedAt, in: model.timeZone)))
            CrowdBody(crowd: crowd, isOffline: true, timeZone: model.timeZone)
        case .offline(nil, _):
            StudentOfflineBanner(text: MealsCopy.crowdOfflineNothing)
        case .empty:
            MealsStateCard(symbol: "chart.bar", title: MealsCopy.notEnoughTitle, detail: MealsCopy.notEnoughDetail)
        case .failed(let failure):
            MealsStateCard(symbol: "exclamationmark.circle", title: MealsCopy.crowdFailed,
                           detail: failure.isNotImplemented ? failure.message : "")
        }
    }
}

struct CrowdBody: View {
    let crowd: StudentCrowd
    let isOffline: Bool
    let timeZone: TimeZone

    private var observed: String { MealsFormat.clock(crowd.observedAt, in: timeZone) }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            hero
            CrowdChart(crowd: crowd, isOffline: isOffline, timeZone: timeZone)
            HStack(alignment: .top, spacing: MLSpacing.s12) {
                CrowdTile(label: isOffline ? MealsCopy.waitAt(observed) : MealsCopy.waitNow,
                          value: crowd.waitNowMinutes.map(MealsCopy.minutes) ?? MealsCopy.noMinutes,
                          detail: crowd.waitNowMinutes == nil ? MealsCopy.notServing : MealsCopy.about, monoDetail: false)
                CrowdTile(label: MealsCopy.atTheBusiest,
                          value: crowd.busiestWaitMinutes.map(MealsCopy.minutes) ?? MealsCopy.noMinutes,
                          detail: crowd.busiestAt.map { StudentFormat.shortTime($0, in: timeZone) } ?? "", monoDetail: true)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            Text(eyebrow.uppercased())
                .font(StudentType.eyebrow)
                .tracking(0.72)
                .foregroundStyle(MLColor.onHeroSecondary)
            Text(isOffline ? MealsCopy.levelAt(crowd.level, time: observed) : StudentCopy.crowdLevel(crowd.level))
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(MLColor.onHero)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let time = crowd.detailTime {
                HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s12) {
                    Text(MealsCopy.detailLabel(crowd.level))
                        .font(StudentType.body)
                        .foregroundStyle(MLColor.onHeroSecondary)
                    Text(StudentFormat.shortTime(time, in: timeZone))
                        .font(.system(size: 22, weight: .medium, design: .monospaced))
                        .foregroundStyle(MLColor.lime)
                }
            }
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.heroBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(StudentCopy.crowdSpoken(crowd.level)). \(MealsCopy.estimateSpoken)")
    }

    /// "Lunch · 12:10 PM · Estimate". The frame has no estimate word; the brief requires the label, so it is added here.
    private var eyebrow: String { Self.eyebrow(crowd, isOffline: isOffline, timeZone: timeZone) }

    static func eyebrow(_ crowd: StudentCrowd, isOffline: Bool, timeZone: TimeZone) -> String {
        let time = MLFormat.time(crowd.observedAt, in: timeZone)
        if isOffline { return MealsCopy.crowdUpdatedEyebrow(crowd.meal.slot, time: time) }
        return "\(MealsCopy.crowdEyebrow(crowd.meal.slot, time: time)) · \(MealsCopy.estimate)"
    }
}

/// "Today, every 15 minutes": eight bars, the slot the clock is in drawn lime, the best time marked with a dot.
struct CrowdChart: View {
    let crowd: StudentCrowd
    let isOffline: Bool
    let timeZone: TimeZone

    private let barArea: CGFloat = 138
    private let tallest: CGFloat = 118

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            Text(MealsCopy.everyFifteen)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(crowd.slots.enumerated()), id: \.offset) { index, slot in
                    bar(index, slot)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: barArea, alignment: .bottom)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(MealsCopy.everyFifteen). \(MealsCopy.estimateSpoken)")
            .accessibilityValue(spokenBars)
            axis
        }
        .padding(MLSpacing.s20)
        .background(RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous).fill(MLColor.surface))
    }

    private func bar(_ index: Int, _ slot: StudentCrowdSlot) -> some View {
        let isNow = index == crowd.currentSlot
        return VStack(spacing: 6) {
            if index == crowd.bestSlot {
                Circle().fill(MLColor.lime).frame(width: 12, height: 12)
                    .overlay(Circle().strokeBorder(MLColor.limeOutline, lineWidth: 1.5))
            }
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isNow ? MLColor.lime : (isOffline ? Color(hex: 0x878787) : MLColor.ink))
                .overlay {
                    if isNow {
                        RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(MLColor.limeOutline, lineWidth: 1.5)
                    }
                }
                .frame(width: 26, height: max(8, tallest * CGFloat(slot.activity)))
        }
    }

    private var axis: some View {
        let start = crowd.slots.first?.startsAt
        let labels = [0.0, 3600, 7200].compactMap { offset in start.map { MealsFormat.clock($0.addingTimeInterval(offset), in: timeZone) } }
        return HStack {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                if index > 0 { Spacer() }
                Text(label)
            }
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
        .foregroundStyle(MLColor.inkSecondary)
        .accessibilityHidden(true)
    }

    private var spokenBars: String {
        crowd.slots.enumerated().map { index, slot in
            var words = [MealsCopy.activityWord(slot.activity)]
            if index == crowd.currentSlot { words.append(MealsCopy.barNow) }
            if index == crowd.bestSlot { words.append(MealsCopy.barBest) }
            return MealsCopy.barLabel(StudentFormat.shortTime(slot.startsAt, in: timeZone), level: words.joined(separator: ", "))
        }
        .joined(separator: "; ")
    }
}

struct CrowdTile: View {
    let label: String
    let value: String
    let detail: String
    let monoDetail: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
            Text(value)
                .font(.system(size: 30, weight: .medium, design: .monospaced))
                .foregroundStyle(MLColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(monoDetail ? StudentType.mono : StudentType.secondary)
                .foregroundStyle(monoDetail ? MLColor.ink : MLColor.inkSecondary)
        }
        .padding(MLSpacing.s16)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }
}
