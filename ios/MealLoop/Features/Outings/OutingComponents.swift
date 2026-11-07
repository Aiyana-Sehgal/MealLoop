import SwiftUI

// Views used by more than one outing role (Guardian, Warden, Gate). They take data and closures only.
// Tags here are labels, not buttons: they have no button trait and do nothing when tapped.

/// The evidence label on W01, W03 and G07: lime "Live · 0:09", outlined "Please watch" or "Video",
/// dashed "Photo and text", "Confirmed by call", "Call", "One tap"; grey outline "No video".
struct OutingTag: View {
    enum Style {
        case lime
        case outline
        case dashed
        case quiet
        /// Black, for "Late" (spec: "Late first, black chip").
        case ink
    }

    let text: String
    var style: Style = .outline

    var body: some View {
        Text(text)
            .font(MLType.secondary)
            .foregroundStyle(foreground)
            .lineLimit(1)
            .padding(.horizontal, MLSpacing.s12)
            .frame(minHeight: 32)
            .background { background }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
    }

    private var foreground: Color {
        switch style {
        case .ink: return MLColor.onHero
        case .quiet: return MLColor.inkSecondary
        default: return MLColor.ink
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .lime:
            Capsule().fill(MLColor.lime).overlay(Capsule().stroke(MLColor.limeOutline, lineWidth: 1))
        case .outline:
            Capsule().stroke(MLColor.ink, lineWidth: 1.2)
        case .dashed:
            Capsule().stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
        case .quiet:
            Capsule().stroke(MLColor.inkSecondary, lineWidth: 1)
        case .ink:
            Capsule().fill(MLColor.ink)
        }
    }
}

/// Initials in a quiet circle (W01 "AA", W02 "KS").
struct OutingAvatar: View {
    let initials: String?

    var body: some View {
        Text(initials ?? "—")
            .font(MLType.meta)
            .foregroundStyle(MLColor.ink)
            .frame(width: MLSize.iconSquare, height: MLSize.iconSquare)
            .background(Circle().fill(MLColor.fillQuiet))
            .accessibilityHidden(true)
    }
}

/// The dark video area. There is no video in the prototype (no camera in the simulator), so the play mark is a
/// picture of the control, not a working player.
struct OutingVideoTile: View {
    enum Mode: Equatable {
        case ready
        case loading(String)
        case unavailable(String)
        /// A face placeholder, for the photo path and the live preview.
        case face
    }

    var mode: Mode = .ready
    var height: CGFloat = 104
    var label: String?

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
                .fill(MLColor.heroBackground)
            Group {
                switch mode {
                case .ready:
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(MLColor.ink)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(MLColor.surface))
                case .loading(let text):
                    VStack(spacing: MLSpacing.s8) {
                        ProgressView().tint(MLColor.onHero)
                        Text(text).font(MLType.body).foregroundStyle(MLColor.onHero)
                    }
                case .unavailable(let text):
                    VStack(spacing: MLSpacing.s8) {
                        Image(systemName: "wifi.slash").foregroundStyle(MLColor.onHero)
                        Text(text).font(MLType.body).foregroundStyle(MLColor.onHero)
                    }
                case .face:
                    FacePlaceholder()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let label {
                Text(label)
                    .font(MLType.meta)
                    .foregroundStyle(MLColor.onHero)
                    .padding(.horizontal, MLSpacing.s12)
                    .padding(.vertical, MLSpacing.s4)
                    .background(Capsule().fill(Color.white.opacity(0.14)))
                    .padding(MLSpacing.s12)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        switch mode {
        case .ready: return label.map { "Recorded video, \($0)" } ?? "Recorded video"
        case .loading(let text), .unavailable(let text): return text
        case .face: return "Face picture"
        }
    }
}

/// A grey head and shoulders, as the references draw a face that is not shown.
struct FacePlaceholder: View {
    var tint: Color = Color.white.opacity(0.28)

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle().fill(tint)
                    .frame(width: size * 0.34, height: size * 0.34)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.38)
                Ellipse().fill(tint)
                    .frame(width: size * 0.78, height: size * 0.62)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 1.0)
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// Phrase, Code, Number with a ticked circle each (W01). Only the checks that passed are listed.
struct EvidenceChecksRow: View {
    let checks: [(EvidenceCheck, String)]

    var body: some View {
        HStack(spacing: MLSpacing.s16) {
            ForEach(checks, id: \.0) { check in
                HStack(spacing: MLSpacing.s4) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 17))
                    Text(check.1).font(MLType.body)
                }
                .foregroundStyle(MLColor.ink)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The ring beside "Decide by": the time left in mono, the arc the share of the warden's window still left.
struct DeadlineRing: View {
    let text: String
    /// 0...1, or nil when the window's start is unknown (the arc is then not drawn).
    let remaining: Double?

    var body: some View {
        ZStack {
            Circle().stroke(MLColor.track, lineWidth: 3)
            if let remaining {
                Circle()
                    .trim(from: 0, to: max(0, min(1, remaining)))
                    .stroke(MLColor.ink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Text(text)
                .font(MLType.monoSecondary)
                .foregroundStyle(MLColor.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .padding(MLSpacing.s4)
        }
        .frame(width: 52, height: 52)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(text) left")
    }
}

/// A white rounded card on the orbit background.
struct OutingCard<Content: View>: View {
    var padding: CGFloat = MLSpacing.s16
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
    }
}

/// A label and value row with a hairline (W02 detail, W03 record, G01 About).
struct OutingFactRow: View {
    let label: String
    let value: String?
    var isMono = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s12) {
            Text(label)
                .font(MLType.staffBody)
                .foregroundStyle(MLColor.ink)
            Spacer(minLength: MLSpacing.s8)
            Text(value ?? "—")
                .font(isMono ? MLType.monoBody : MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 52)
        .overlay(alignment: .top) { Rectangle().fill(MLColor.border).frame(height: 1) }
        .accessibilityElement(children: .combine)
        .accessibilityValue(value == nil ? "Not available" : "")
    }
}

/// A call control. The prototype cannot place calls and has no full numbers, so it is shown but not active.
struct OutingCallButton: View {
    enum Style {
        case ink
        case outline
        case link
    }

    let title: String
    var style: Style = .ink

    var body: some View {
        Group {
            switch style {
            case .ink: InkActionButton(title: title) {}
            case .outline: OutlineActionButton(title: title) {}
            case .link: TextLinkButton(title: title) {}
            }
        }
        .disabled(true)
        .opacity(style == .ink ? 1 : 0.45)
        .accessibilityHint("Calls are not available in the prototype.")
    }
}
