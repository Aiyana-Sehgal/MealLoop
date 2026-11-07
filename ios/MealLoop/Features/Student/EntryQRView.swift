import CoreImage.CIFilterBuiltins
import SwiftUI

/// Draws a QR from a payload. A failure returns nil and the screen says so; it never shows a blank code as real.
enum EntryQRImage {
    static func make(_ payload: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage,
              let image = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: image)
    }
}

/// Which card Entry QR shows (EntryQRCard 2153:3742). The QR is never locked: every answer and state keeps a way in.
enum EntryQRCase: Equatable {
    case live
    case savedOffline
    case scanned(at: Date)
    case scannedAgain(firstAt: Date)
    case wrongMess(homeMess: String)
}

/// Entry QR and its states (Entry QR frames, page 07). The refresh is SIMULATED: the code changes every 12 seconds on
/// a timer, and no scanner verifies it because QR scanning is not built. The typed last four digits are unchanged.
struct EntryQRView: View {
    let model: StudentHomeViewModel
    let onBack: () -> Void

    private var meal: StudentMealCard? { model.entryMeal }

    private var entryCase: EntryQRCase {
        switch model.standing {
        case .wrongMess(let home): return .wrongMess(homeMess: home)
        case .scanned(let at): return .scanned(at: at)
        case .scannedAgain(let at): return .scannedAgain(firstAt: at)
        case .notScanned: return model.isOffline ? .savedOffline : .live
        }
    }

    var body: some View {
        GeometryReader { proxy in
            page(zoneSize: min(StudentMetric.qrZone, proxy.size.height * 0.33))
        }
        .task { await model.loadEntryCode() }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                await model.tickEntryQR()
            }
        }
    }

    /// 254 pt as drawn, smaller on a short phone so the card stays near the tab bar.
    private func page(zoneSize: CGFloat) -> some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    StudentNavHeader(title: StudentCopy.entryQR,
                                     subtitle: StudentCopy.entrySubtitle(meal?.meal.slot, mess: model.context.mess.name),
                                     onBack: onBack)
                    VStack(spacing: MLSpacing.s16) {
                        if entryCase == .savedOffline {
                            StudentOfflineBanner(text: StudentCopy.offlineQRBanner)
                        }
                        AsyncContentView(state: model.entryCode, timeZone: model.timeZone,
                                         retry: { await model.loadEntryCode() }) { code in
                            EntryQRCard(model: model, code: code, entryCase: entryCase, zoneSize: zoneSize)
                        }
                        Text(StudentCopy.cantScan)
                            .font(StudentType.secondaryMedium)
                            .underline()
                            .foregroundStyle(MLColor.ink)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, MLSpacing.s8)
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s4)
                .padding(.bottom, StudentMetric.scrollBottom)
            }
            StudentScrollFade()
        }
    }
}

private struct EntryQRCard: View {
    let model: StudentHomeViewModel
    let code: EntryCode
    let entryCase: EntryQRCase
    let zoneSize: CGFloat

    private var meal: StudentMealCard? { model.entryMeal }
    private var answer: MealIntention? { meal?.answer }
    private func time(_ date: Date) -> String { StudentFormat.shortTime(date, in: model.timeZone) }

    private var payload: String {
        entryCase == .live ? (model.rotatingCode?.payload ?? code.payload) : code.payload
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                chip
                Spacer(minLength: 0)
                indicator
            }
            zone
            if entryCase == .live {
                countdown
            }
            if let note {
                Text(note.text)
                    .font(StudentType.secondary)
                    .foregroundStyle(note.isError ? MLColor.danger : MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            Text("\(model.name) \(model.context.student.maskedID)")
                .font(StudentType.section)
                .foregroundStyle(MLColor.ink)
            Text(footnote)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, MLSpacing.s24)
        .padding(.bottom, 26)
        .padding(.horizontal, MLSpacing.s24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.surface))
    }

    private var note: (text: String, isError: Bool)? {
        switch entryCase {
        case .live: return (model.isRefreshingQR ? StudentCopy.newCodeSoon : StudentCopy.refreshesIn(model.entrySecondsLeft), false)
        case .savedOffline:
            let saved = model.lastLoadedAt.map(time)
            return (StudentCopy.savedUntil(saved, until: meal.map { time($0.meal.endsAt) } ?? "—"), false)
        case .scanned(let at): return (StudentCopy.entryRecorded(time(at)), false)
        case .scannedAgain(let at): return (StudentCopy.alreadyScannedAt(time(at)), true)
        case .wrongMess(let home): return (StudentCopy.qrIsFor(home), true)
        }
    }

    private var footnote: String {
        switch entryCase {
        case .live:
            switch answer {
            case nil: return StudentCopy.walkInDetail
            case .skipping?: return StudentCopy.canStillEat
            case .notSure?: return StudentCopy.notSureCanEat
            case .attending?: return StudentCopy.holdUp
            }
        case .savedOffline: return StudentCopy.showSavedQR
        case .scanned: return StudentCopy.enjoy(meal?.meal.slot)
        case .scannedAgain: return StudentCopy.askDoorStaff
        case .wrongMess: return StudentCopy.differentMess
        }
    }

    @ViewBuilder
    private var chip: some View {
        switch entryCase {
        case .live:
            switch answer {
            case .attending?: EntryChip(text: StudentCopy.youreInChip, style: .lime)
            case .skipping?: EntryChip(text: StudentCopy.skipped, style: .ink)
            case .notSure?: EntryChip(text: StudentCopy.notSure, style: .ink)
            case nil: EntryChip(text: StudentCopy.walkIn, style: .dashed)
            }
        case .savedOffline: EntryChip(text: StudentCopy.savedQR, style: .ink)
        case .scanned: EntryChip(text: StudentCopy.scanned, style: .ink, showsCheck: true)
        case .scannedAgain: EntryChip(text: StudentCopy.scannedEarlier, style: .danger)
        case .wrongMess(let home): EntryChip(text: home, style: .danger)
        }
    }

    @ViewBuilder
    private var indicator: some View {
        switch entryCase {
        case .live:
            HStack(spacing: 6) {
                Circle().fill(MLColor.lime).overlay(Circle().strokeBorder(MLColor.limeOutline, lineWidth: 1.2)).frame(width: 12, height: 12)
                Text(StudentCopy.live).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
            }
        case .savedOffline:
            HStack(spacing: 6) {
                Circle().strokeBorder(MLColor.inkSecondary, lineWidth: 1.2).frame(width: 12, height: 12)
                Text(StudentCopy.offline).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
            }
        case .scanned, .scannedAgain, .wrongMess:
            EmptyView()
        }
    }

    private var zone: some View {
        ZStack {
            switch entryCase {
            case .scanned:
                Image(systemName: "checkmark")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(MLColor.onLime)
                    .frame(width: 120, height: 60)
                    .background(Capsule().fill(MLColor.lime))
                    .overlay(Capsule().strokeBorder(MLColor.limeOutline, lineWidth: 1.5))
                    .accessibilityHidden(true)
            case .scannedAgain:
                qr(dimmed: true)
                zoneMessage(symbol: "exclamationmark.triangle", text: StudentCopy.alreadyScanned, color: MLColor.danger)
            case .wrongMess:
                qr(dimmed: true)
                zoneMessage(symbol: "exclamationmark.triangle", text: StudentCopy.wrongMess, color: MLColor.danger)
            case .live where model.isRefreshingQR:
                qr(dimmed: true)
                zoneMessage(symbol: "arrow.clockwise", text: StudentCopy.refreshing, color: MLColor.ink)
            case .live, .savedOffline:
                qr(dimmed: false)
            }
        }
        .frame(width: zoneSize, height: zoneSize)
        .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
        .overlay(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).strokeBorder(MLColor.border, lineWidth: 1.5))
    }

    private func zoneMessage(symbol: String, text: String, color: Color) -> some View {
        VStack(spacing: MLSpacing.s8) {
            Image(systemName: symbol).font(.system(size: 26)).accessibilityHidden(true)
            Text(text).font(StudentType.bodySemibold)
        }
        .foregroundStyle(color)
    }

    private func qr(dimmed: Bool) -> some View {
        EntryQRPicture(payload: payload, label: StudentCopy.qrLabel(model.name, maskedID: model.context.student.maskedID))
            .opacity(dimmed ? 0.18 : 1)
            .task(id: model.isRefreshingQR) {
                guard model.isRefreshingQR else { return }
                try? await Task.sleep(for: .milliseconds(600))
                model.finishQRRefresh()
            }
    }

    private var countdown: some View {
        let window = Double(StudentHomeViewModel.entryQRWindow)
        let elapsed = model.isRefreshingQR ? 1 : (window - Double(model.entrySecondsLeft)) / window
        return GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(MLColor.track)
                Capsule().fill(MLColor.ink).frame(width: proxy.size.width * elapsed)
            }
        }
        .frame(height: 8)
        .frame(width: zoneSize)
        .animation(.linear(duration: 1), value: model.entrySecondsLeft)
        .accessibilityHidden(true)
    }
}

/// Redraws the QR only when the payload changes, not on every second of the countdown.
private struct EntryQRPicture: View {
    let payload: String
    let label: String
    @State private var image: UIImage?
    @State private var drawn: String?

    var body: some View {
        // A real base view: `.task` on an empty Group never runs, and the QR would stay blank.
        ZStack {
            Color.clear
            if let image {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(MLSpacing.s24)
                    .accessibilityLabel(label)
            } else if drawn != nil {
                Text(StudentCopy.qrUnavailable)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(MLSpacing.s16)
            }
        }
        .task(id: payload) {
            image = EntryQRImage.make(payload)
            drawn = payload
        }
    }
}

private struct EntryChip: View {
    enum Style { case lime, ink, dashed, danger }

    let text: String
    let style: Style
    var showsCheck = false

    var body: some View {
        HStack(spacing: 6) {
            if showsCheck {
                Image(systemName: "checkmark").font(.system(size: 13, weight: .semibold))
            }
            Text(text).font(StudentType.secondaryMedium)
        }
        .foregroundStyle(style == .danger ? MLColor.danger : MLColor.ink)
        .padding(.horizontal, MLSpacing.s16)
        .frame(height: StudentMetric.chipHeight)
        .background {
            switch style {
            case .lime:
                Capsule().fill(MLColor.lime)
                Capsule().strokeBorder(MLColor.limeOutline, lineWidth: 1.5)
            case .ink:
                Capsule().strokeBorder(MLColor.ink, lineWidth: 1.5)
            case .dashed:
                Capsule().strokeBorder(MLColor.ink, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            case .danger:
                Capsule().strokeBorder(MLColor.danger, lineWidth: 1.5)
            }
        }
    }
}
