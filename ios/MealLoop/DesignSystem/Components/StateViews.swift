import SwiftUI

struct LoadingStateView: View {
    var body: some View {
        VStack {
            ProgressView()
                .controlSize(.large)
                .tint(MLColor.ink)
                .accessibilityLabel("Loading")
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

/// Centred empty state (title and one line).
struct EmptyStateView: View {
    let title: String
    var message: String = ""

    var body: some View {
        VStack(spacing: MLSpacing.s8) {
            Text(title)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
            if !message.isEmpty {
                Text(message)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.horizontal, MLSpacing.margin)
    }
}

/// Inline error card with "Try again". A feature with no data source says so instead of pretending to be an error.
struct ErrorRetryView: View {
    let failure: LoadFailure
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Text(failure.isNotImplemented ? "Coming soon" : "Couldn't load")
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
            Text(failure.message)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            if !failure.isNotImplemented {
                InkActionButton(title: "Try again", action: retry)
            }
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
    }
}

/// "Offline · saved 1:38 PM". Nothing on screen is claimed as recorded while this shows.
struct OfflineBanner: View {
    let savedAt: String?
    let retry: () -> Void

    var body: some View {
        HStack(spacing: MLSpacing.s12) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(MLColor.ink)
                .accessibilityHidden(true)
            Text(savedAt.map { "Offline · saved \($0)" } ?? "Offline")
                .font(MLType.bodyEmphasis)
                .foregroundStyle(MLColor.ink)
            Spacer(minLength: 0)
            Button("Try again", action: retry)
                .font(MLType.bodyEmphasis)
                .foregroundStyle(MLColor.ink)
                .frame(minWidth: MLSize.hit, minHeight: MLSize.hit)
        }
        .padding(.horizontal, MLSpacing.s16)
        .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
        .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).stroke(MLColor.border, lineWidth: 1))
    }
}

/// Small grey note for stale data ("Updated 1:12 PM · reconnecting").
struct StaleNote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(MLType.secondary)
            .foregroundStyle(MLColor.inkSecondary)
    }
}

/// Shown wherever a screen or action is not built yet. Never imitates working functionality.
struct NotImplementedView: View {
    let title: String
    var detail: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        ZStack {
            OrbitBackground()
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                Text(title)
                    .font(MLType.largeTitle)
                    .foregroundStyle(MLColor.ink)
                Text("Coming soon")
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                if let detail {
                    Text(detail)
                        .font(MLType.body)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                if let actionTitle, let action {
                    InkActionButton(title: actionTitle, action: action)
                        .padding(.top, MLSpacing.s12)
                }
                Spacer()
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.top, MLSpacing.s32)
        }
    }
}
