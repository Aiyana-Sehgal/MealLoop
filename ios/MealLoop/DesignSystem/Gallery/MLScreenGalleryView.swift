#if DEBUG
import SwiftUI

/// Debug-only gallery page for the standards scaffold: a long `MLScreen` whose large title collapses as it scrolls,
/// with a trailing bar item, a pinned primary action, a rolling number, a haptic, an inserted row, `mlSheet` and the
/// compact confirmation sheet. Every value here is a local gallery sample: nothing is reachable from a real screen.
struct MLScreenGalleryView: View {
    /// Forces the iOS 17 preference-key scroll reader, to check it on a newer simulator.
    var scrollTracking: MLScreenScrollTracking = .automatic
    /// Opens a sheet on appear, for screenshots.
    var opening: Opening?
    enum Opening { case sheet, confirmation }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var count = 714
    @State private var showsNote = false
    @State private var isSheetOpen = false
    @State private var isConfirmOpen = false
    @State private var isWorking = false

    private static let rows = (1...24).map { GallerySampleRow(id: $0) }

    var body: some View {
        MLScreen(
            "Screen scaffold",
            subtitle: "Gallery sample · scroll to collapse the title",
            scrollTracking: scrollTracking
        ) {
            Button {
                isSheetOpen = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .frame(width: MLSize.hit, height: MLSize.hit)
            }
            .accessibilityLabel("Filter (sample)")
        } content: {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                counterCard
                if showsNote {
                    Text("An inserted row. It slides in, or fades under Reduce Motion.")
                        .mlFont(.body)
                        .foregroundStyle(MLColor.inkSecondary)
                        .padding(MLSpacing.s16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: MLRadius.compact).fill(MLColor.surface))
                        .mlTransition(.fromTop)
                }
                OutlineActionButton(title: "Open the compact confirmation") { isConfirmOpen = true }
                SectionHeader(title: "Sample rows")
                ForEach(Self.rows) { row in
                    QuietRow(title: row.title, value: row.value) {}
                }
            }
            .mlAnimation(.smooth, value: showsNote)
        } bottom: {
            InkActionButton(title: showsNote ? "Hide the inserted row" : "Insert a row") {
                MLMotion.animate(.smooth, reduceMotion: reduceMotion) { showsNote.toggle() }
            }
            .mlHaptic(.selection, trigger: showsNote)
        }
        .mlSheet(isPresented: $isSheetOpen) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                SheetHeader(title: "Sized to content", subtitle: "This sheet is exactly as tall as these lines.") {
                    isSheetOpen = false
                }
                InkActionButton(title: "Done") { isSheetOpen = false }
            }
        }
        .mlConfirmSheet(
            isPresented: $isConfirmOpen,
            content: ConfirmDialogContent(
                title: "Close this meal?", subject: "Lunch · Gallery sample",
                detail: "Door scanner and pass desk will stop.", cancelTitle: "Cancel", actionTitle: "Close meal"
            ),
            isWorking: isWorking
        ) {
            isWorking = true
            Task {
                try? await Task.sleep(for: .seconds(1))
                isWorking = false
                isConfirmOpen = false
            }
        }
        .onAppear {
            switch opening {
            case .sheet: isSheetOpen = true
            case .confirmation: isConfirmOpen = true
            case nil: break
            }
        }
    }

    private var counterCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text("Sample count")
                    .mlFont(.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
                Text(count, format: .number)
                    .font(MLType.heroNumber)
                    .foregroundStyle(MLColor.ink)
                    .mlNumericText(count)
            }
            Spacer(minLength: MLSpacing.s16)
            Button {
                count += 1
            } label: {
                Image(systemName: "plus")
                    .frame(width: MLSize.hit, height: MLSize.hit)
                    .background(Circle().fill(MLColor.fillQuiet))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add one (sample)")
            .mlHaptic(.success, trigger: count)
        }
        .padding(MLSpacing.s16)
        .background(RoundedRectangle(cornerRadius: MLRadius.card).fill(MLColor.surface))
    }
}

private struct GallerySampleRow: Identifiable {
    let id: Int
    var title: String { "Sample row \(id)" }
    var value: String { "\(id * 7) min" }
}

#Preview("Screen scaffold") {
    NavigationStack { MLScreenGalleryView() }
}

#Preview("Screen scaffold · iOS 17 reader") {
    NavigationStack { MLScreenGalleryView(scrollTracking: .legacy) }
}
#endif
