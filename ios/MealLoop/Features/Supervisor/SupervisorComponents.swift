import SwiftUI

// Views only the Supervisor screens use. Each takes ready values; none fetches or decides anything.

/// Status as a dot plus plain text, never a pill (S01, S06, S07, S12, S19).
/// The ink dot is the pack's "Active" and "Closed"; the shared `StatusText` has no ink dot yet (see REPORT.md).
struct SupervisorStatus: View {
    enum Dot {
        /// Filled ink: Active, Closed.
        case ink
        /// Outlined: Not started, Not recorded.
        case open
        /// Lime with the ink outline: Recorded, Resolved.
        case lime
    }

    let text: String
    var dot: Dot
    /// Mono time after the text ("Closed · 2:00 PM").
    var time: String?

    var body: some View {
        HStack(spacing: MLSpacing.s8) {
            Group {
                switch dot {
                case .ink:
                    Circle().fill(MLColor.ink)
                case .open:
                    Circle().stroke(MLColor.ink, lineWidth: 1.5)
                case .lime:
                    Circle().fill(MLColor.lime).overlay(Circle().stroke(MLColor.limeOutline, lineWidth: 1))
                }
            }
            .frame(width: 12, height: 12)
            if !text.isEmpty {
                Text(text)
                    .font(MLType.staffBody)
                    .foregroundStyle(MLColor.ink)
            }
            if let time {
                Text(text.isEmpty ? time : "· \(time)")
                    .font(MLType.monoBody)
                    .foregroundStyle(MLColor.ink)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A two-line task row: title, one plain line under it, a status on the right and a chevron (S07, S18). 56 pt.
struct SupervisorTaskRow<Trailing: View>: View {
    let title: String
    let detail: String
    let action: () -> Void
    @ViewBuilder let trailing: Trailing

    var body: some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.ink)
                    Text(detail)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: MLSpacing.s8)
                trailing
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MLColor.inkSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, MLSpacing.s8)
            .frame(minHeight: MLSize.staffButton)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
    }
}

/// A label and value row with a hairline under it ("Posted", "Status", "Final entries"), 56 pt.
struct SupervisorFactRow<Value: View>: View {
    let label: String
    @ViewBuilder let value: Value

    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            Text(label)
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.inkSecondary)
            Spacer(minLength: MLSpacing.s8)
            value
        }
        .frame(minHeight: MLSize.staffButton)
        .overlay(alignment: .bottom) {
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The grey group label above rows ("Shortages", "Waste not recorded", "Follow-ups"), with a hairline under it.
struct SupervisorGroupLabel: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            Text(title)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .accessibilityAddTraits(.isHeader)
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
        .padding(.top, MLSpacing.s8)
    }
}

/// The top of a pushed page: the one round Back, then the large title and its line (S10, S12, S18, S19).
struct SupervisorPageHeader: View {
    let title: String
    var subtitle: String?
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            BackButton(action: onBack)
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text(title)
                    .font(MLType.largeTitle)
                    .foregroundStyle(MLColor.ink)
                    .accessibilityAddTraits(.isHeader)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The quieter outlined action on the black card ("Close meal", S02). White text and a grey outline, 56 pt.
struct SupervisorHeroOutlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.onHero)
                .frame(maxWidth: .infinity, minHeight: MLSize.staffButton)
                .overlay(Capsule().stroke(MLColor.onHeroSecondary, lineWidth: 1.5))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// The page body shared by the Supervisor screens: Orbit backdrop and a scrolling column with the side margin.
struct SupervisorPage<Content: View>: View {
    var bottomInset: CGFloat = 120
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    content
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, bottomInset)
            }
        }
    }
}
