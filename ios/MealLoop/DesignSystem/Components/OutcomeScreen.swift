import SwiftUI

/// One label and value in a `FactCard`. A nil value shows "—", never 0.
struct FactRow: Equatable, Identifiable {
    let label: String
    let value: String?
    /// Numbers, times and units are mono. Words ("Valid", "Recorded") are not.
    var isMono: Bool = true

    var id: String { label }

    /// What a screen reader says for the value.
    var spokenValue: String { value ?? "Not available" }
}

/// The white card of label and value rows with hairlines between them (D08, D10, P07).
struct FactCard: View {
    let rows: [FactRow]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Rectangle().fill(MLColor.border).frame(height: 1)
                }
                HStack(spacing: MLSpacing.s12) {
                    Text(row.label)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                    Spacer(minLength: MLSpacing.s8)
                    Text(row.value ?? "—")
                        .font(row.isMono ? MLType.monoBody : MLType.bodyEmphasis)
                        .foregroundStyle(MLColor.ink)
                }
                .frame(minHeight: MLSize.staffButton)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.label)
                .accessibilityValue(row.spokenValue)
            }
        }
        .padding(.horizontal, MLSpacing.s20)
        .padding(.vertical, MLSpacing.s4)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
    }
}

/// The result screen for anything that did not record: already scanned, wrong code, no connection (D08, D09, D10, P06, P07, P08).
/// It never says something was saved. Good results use `LimeResultScreen`.
struct OutcomeScreen: View {
    enum Badge {
        /// A quiet filled circle (D08).
        case quiet
        /// A white circle with an ink outline (D10).
        case outlined
    }

    struct Action {
        let title: String
        let handler: () -> Void
    }

    var onBack: (() -> Void)?
    var badge: Badge = .quiet
    let symbol: String
    let title: String
    let message: String
    /// True when the message is the point of the screen ("This entry is NOT recorded.").
    var isMessageEmphasized: Bool = false
    var facts: [FactRow] = []
    /// Grey line under the facts ("Nothing was added to the count.").
    var note: String?
    let primary: Action
    var secondary: Action?
    var link: Action?
    /// Grey line at the bottom ("Entries are never shown as recorded until they are saved.").
    var footnote: String?

    /// Measured from the D08 and D10 packs at 1.346.
    private let badgeDiameter: CGFloat = 120

    var body: some View {
        ZStack(alignment: .topLeading) {
            OrbitBackground()
            ScrollView {
                VStack(spacing: MLSpacing.s16) {
                    badgeView
                    VStack(spacing: MLSpacing.s8) {
                        Text(title)
                            .font(MLType.largeTitle)
                            .foregroundStyle(MLColor.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .accessibilityAddTraits(.isHeader)
                        Text(message)
                            .font(MLType.staffBody)
                            .foregroundStyle(isMessageEmphasized ? MLColor.ink : MLColor.inkSecondary)
                    }
                    .multilineTextAlignment(.center)
                    if !facts.isEmpty {
                        FactCard(rows: facts)
                    }
                    if let note {
                        Text(note)
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                            .multilineTextAlignment(.center)
                    }
                    actions
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSize.hit + MLSpacing.s24)
                .padding(.bottom, MLSpacing.s24)
            }
            .scrollBounceBehavior(.basedOnSize)
            if let onBack {
                BackButton(action: onBack)
                    .padding(.leading, MLSpacing.s16)
                    .padding(.top, MLSpacing.s8)
            }
        }
    }

    private var badgeView: some View {
        Image(systemName: symbol)
            .font(.system(size: 44, weight: .regular))
            .foregroundStyle(MLColor.ink)
            .frame(width: badgeDiameter, height: badgeDiameter)
            .background(Circle().fill(badge == .quiet ? MLColor.track : MLColor.surface))
            .overlay {
                if badge == .outlined {
                    Circle().stroke(MLColor.ink, lineWidth: 1.5)
                }
            }
            .accessibilityHidden(true)
    }

    private var actions: some View {
        VStack(spacing: MLSpacing.s12) {
            InkActionButton(title: primary.title, action: primary.handler)
            if let secondary {
                OutlineActionButton(title: secondary.title, action: secondary.handler)
            }
            if let link {
                TextLinkButton(title: link.title, action: link.handler)
            }
            if let footnote {
                Text(footnote)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, MLSpacing.s8)
    }
}
