import SwiftUI

/// The right-edge tab under the avatar, shown only while an SOS is active (D05, K19, P15, S03).
/// Black with a lime outline; lime once you have claimed it. The lime here is the recorded SOS exception.
/// The caller places it flush with the right edge of the screen and decides when it exists.
struct SOSEdgeTab: View {
    let count: Int
    var isClaimedByYou: Bool = false
    /// Spoken after the count when claimed ("You're checking this").
    var claimedStatus: String = ""
    let action: () -> Void

    /// Measured from the D05 export: 58 × 105 pt, flush with the right edge.
    private let width: CGFloat = 58
    private let height: CGFloat = 105
    private let badgeDiameter: CGFloat = 28

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: MLRadius.compact, bottomLeadingRadius: MLRadius.card, style: .continuous)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: MLSpacing.s4) {
                Image(systemName: isClaimedByYou ? "exclamationmark.triangle" : "exclamationmark.triangle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isClaimedByYou ? MLColor.ink : MLColor.lime)
                Text("SOS")
                    .font(MLType.meta)
                    .foregroundStyle(isClaimedByYou ? MLColor.ink : MLColor.onHero)
            }
            .frame(width: width, height: height)
            .background(alignment: .leading) {
                // Drawn wider than the tab, so the right side runs off the screen with no outline on it.
                shape.fill(isClaimedByYou ? MLColor.lime : MLColor.ink)
                    .overlay(shape.stroke(isClaimedByYou ? MLColor.limeOutline : MLColor.lime, lineWidth: 2))
                    .frame(width: width + MLSpacing.s4)
            }
            .overlay(alignment: .topLeading) { badge }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("SOS, \(count) active")
        .accessibilityValue(isClaimedByYou ? claimedStatus : "")
    }

    private var badge: some View {
        Text("\(count)")
            .font(MLType.monoSecondary)
            .foregroundStyle(isClaimedByYou ? MLColor.onHero : MLColor.onLime)
            .frame(width: badgeDiameter, height: badgeDiameter)
            .background(Circle().fill(isClaimedByYou ? MLColor.ink : MLColor.lime))
            .overlay(Circle().stroke(MLColor.ink, lineWidth: 1))
            .offset(x: -MLSpacing.s8, y: -MLSpacing.s12)
    }
}

/// The incident as text, ready to show. Formatting and wording come from the feature.
struct SOSIncident: Equatable {
    /// Leading word, used on Alerts ("SOS"). Nil inside the panel, whose title already says it.
    var eyebrow: String?
    /// "12:45 PM"
    let time: String
    /// "5 min ago"
    let age: String
    let title: String
    let place: String
}

/// Where an SOS stands, as the wording to show. The feature decides which case applies; only it knows the role.
enum SOSCardStatus: Equatable {
    /// "Nobody has taken this yet"
    case notTaken(String)
    /// "You're checking this"
    case claimed(String)
    /// "Checked by the door", with the time
    case checked(String, time: String?)
}

/// The black incident card, inside the panel (D13, D14, S05) and on top of Alerts (D17, S08).
struct SOSCard: View {
    let incident: SOSIncident
    let status: SOSCardStatus
    /// Line under the status ("Ravi and the kitchen team can see you're on your way.").
    var note: String?
    /// The lime action, on Alerts only. The panel has its own buttons.
    var actionTitle: String?
    var onAction: (() -> Void)?

    var body: some View {
        HeroCard {
            VStack(alignment: .leading, spacing: MLSpacing.s8) {
                eyebrow
                Text(incident.title)
                    .font(MLType.title2)
                    .foregroundStyle(MLColor.onHero)
                Text(incident.place)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.onHeroSecondary)
                statusChip
                if let note {
                    Text(note)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.onHeroSecondary)
                }
                if let actionTitle, let onAction {
                    LimeActionButton(title: actionTitle, action: onAction)
                        .padding(.top, MLSpacing.s8)
                }
            }
        }
    }

    private var eyebrow: some View {
        HStack(spacing: MLSpacing.s8) {
            Circle().fill(MLColor.lime).frame(width: MLSize.statusDot, height: MLSize.statusDot)
            if let word = incident.eyebrow {
                Text(word).font(MLType.eyebrow)
                Text("·").font(MLType.monoSecondary)
            }
            Text(incident.time).font(MLType.monoSecondary)
            Text("·").font(MLType.monoSecondary)
            Text(incident.age).font(MLType.secondary)
        }
        .foregroundStyle(MLColor.onHeroSecondary)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var statusChip: some View {
        switch status {
        case .notTaken(let text):
            HeroStatusChip(text: text, style: .outline)
        case .claimed(let text):
            HeroStatusChip(text: text, style: .lime)
        case .checked(let text, let time):
            HeroStatusChip(text: text, time: time, style: .lime)
        }
    }
}

/// The compact SOS panel, for the content of `mlSheet` (D13, D14, K20, P16, S04, S05).
/// Claiming, marking checked and closing are the caller's closures. This view holds no rule about who may do what.
struct SOSPanel: View {
    struct Action {
        let title: String
        let handler: () -> Void
    }

    /// "SOS · 1 active"
    let title: String
    let incident: SOSIncident
    let status: SOSCardStatus
    var note: String?
    /// "Only if you're free. Keep scanning first if the door is busy."
    var helper: String?
    let primary: Action
    var secondary: Action?
    /// The quiet underlined way out ("I can't go after all").
    var link: Action?
    /// Spinner on the primary button while its write is running.
    var isWorking: Bool = false
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: MLSpacing.s16) {
            SheetHeader(title: title, onClose: onClose)
            SOSCard(incident: incident, status: status, note: note)
            if let helper {
                Text(helper)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            InkActionButton(title: primary.title, isLoading: isWorking, action: primary.handler)
            if let secondary {
                OutlineActionButton(title: secondary.title, action: secondary.handler)
            }
            if let link {
                TextLinkButton(title: link.title, action: link.handler)
            }
        }
    }
}
