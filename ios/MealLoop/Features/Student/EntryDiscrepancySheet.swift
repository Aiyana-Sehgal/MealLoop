import SwiftUI

/// Entry · Discrepancy (221:63082), Sending and Failed. A request only: it changes no entry and no count.
/// Opened from the missed day on Attendance (the drawn host). `send` throws when nothing was recorded (offline).
struct EntryDiscrepancySheet: View {
    let record: AttendanceRecord
    let timeZone: TimeZone
    let send: (EntryCorrectionReason, String?, IdempotencyKey) async throws -> Void
    let onClose: () -> Void
    let onSent: () -> Void

    @State private var reason = EntryCorrectionReason.ateButNotScanned
    @State private var note = ""
    @State private var isSending = false
    @State private var didFail = false
    /// One key per sheet, so a retry after a failure can never create a second request.
    @State private var key = IdempotencyKey(UUID().uuidString)

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: StudentCopy.somethingWrong, onClose: onClose)
            HStack(spacing: 8) {
                fact(StudentCopy.mealEyebrow,
                     "\(MLFormat.mealSlot(record.slot)) · \(StudentFormat.mediumDay(record.day, in: timeZone))")
                fact(StudentCopy.recordEyebrow, record.wasScanned ? StudentCopy.scanned : StudentCopy.notScanned)
            }
            Text(StudentCopy.whatsWrong)
                .font(StudentType.bodySemibold)
                .foregroundStyle(MLColor.ink)
                .padding(.top, MLSpacing.s8)
            ForEach(EntryCorrectionReason.allCases, id: \.self) { option in
                reasonRow(option)
            }
            Text(StudentCopy.addNote)
                .font(StudentType.footnote)
                .foregroundStyle(MLColor.inkSecondary)
                .padding(.top, MLSpacing.s4)
            TextField("", text: $note)
                .font(StudentType.body)
                .padding(.horizontal, MLSpacing.s16)
                .frame(minHeight: 52)
                .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
                .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).strokeBorder(MLColor.border, lineWidth: 1))
                .accessibilityLabel(StudentCopy.addNote)
            if didFail {
                HStack(spacing: MLSpacing.s12) {
                    Image(systemName: "exclamationmark.triangle").accessibilityHidden(true)
                    Text(StudentCopy.didntSend).font(StudentType.secondaryMedium)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(MLColor.danger)
                .padding(MLSpacing.s16)
                .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(StudentTint.errorFill))
            }
            Button(action: sendRequest) {
                HStack(spacing: MLSpacing.s8) {
                    if isSending {
                        ProgressView().tint(MLColor.onHero)
                    }
                    Text(isSending ? StudentCopy.sending : StudentCopy.sendRequest)
                }
                .font(StudentType.bodySemibold)
                .foregroundStyle(MLColor.onHero)
                .frame(maxWidth: .infinity, minHeight: StudentMetric.answerSecondary)
                .background(Capsule().fill(MLColor.ink))
            }
            .buttonStyle(.plain)
            // `send` ignores a second tap. `.disabled` would grey the black button the frame keeps solid.
            .padding(.top, MLSpacing.s24)
        }
    }

    private func fact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(label.uppercased())
                .font(StudentType.eyebrow)
                .tracking(0.72)
                .foregroundStyle(MLColor.inkSecondary)
            Text(value)
                .font(StudentType.bodySemibold)
                .foregroundStyle(MLColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(MLSpacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.fillQuiet))
    }

    private func reasonRow(_ option: EntryCorrectionReason) -> some View {
        Button { reason = option } label: {
            HStack {
                Text(StudentCopy.correctionReason(option))
                    .font(StudentType.body)
                    .foregroundStyle(MLColor.ink)
                Spacer(minLength: 0)
                Circle()
                    .fill(reason == option ? MLColor.lime : Color.clear)
                    .overlay(Circle().strokeBorder(MLColor.ink, lineWidth: 1.5))
                    .frame(width: 22, height: 22)
            }
            .padding(.horizontal, MLSpacing.s16)
            .frame(minHeight: 52)
            // The sheet is white here, so the rows take the quiet fill to stay visible.
            .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.fillQuiet))
            .overlay {
                if reason == option {
                    RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).strokeBorder(MLColor.ink, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(reason == option ? .isSelected : [])
    }

    private func sendRequest() {
        guard !isSending else { return }
        isSending = true
        didFail = false
        Task {
            do {
                try await send(reason, note.isEmpty ? nil : note, key)
                isSending = false
                onSent()
            } catch {
                isSending = false
                didFail = true
            }
        }
    }
}
