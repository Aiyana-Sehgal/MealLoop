import Observation
import SwiftUI

// Next week's Special pass (owner decision, 9 November; images student_pass_04_request and student_pass_05_requested):
// the student asks, the Admin accepts or declines, and the pass is usable only once accepted and only in that week.
// Shown on the pass page when this week has no pass to use.

enum PassRequestCopy {
    static let noPassNextWeek = "No pass for next week"
    static let waiting = "Waiting for approval"
    static let approved = "Approved for next week"
    static let declined = "Not approved"
    static let specialPass = "Special pass"
    static func weekLine(_ range: String) -> String { "\(range) · next week" }
    static let howItWorks = "HOW IT WORKS"
    static let youAsk = "You ask"
    static let youAskDetail = "Request next week's pass here."
    static let adminDecides = "The admin decides"
    static let adminDecidesDetail = "They accept or decline your request."
    static let youUseIt = "You use it at the counter"
    static let youUseItDetail = "Only after it is approved, during that week."
    static let yourRequest = "YOUR REQUEST"
    static let week = "Week"
    static let requested = "Requested"
    static let status = "Status"
    static let waitingForAdmin = "Waiting for the admin"
    static let acceptedStatus = "Accepted by the admin"
    static let declinedStatus = "Declined by the admin"
    static let waitingNote = "You will see it here when it is approved. You cannot use it before then."
    static let acceptedNote = "You can use it at the counter during that week, not before."
    static let declinedNote = "You can ask again."
    static let request = "Request pass for next week"
    static let requestAgain = "Request again"
    static let cancelRequest = "Cancel request"
    static let didNotSend = "Didn't send. Try again."
}

@MainActor
@Observable
final class StudentPassRequestModel {
    private(set) var request: PassRequest?
    private(set) var isLoaded = false
    private(set) var isWriting = false
    private(set) var errorText: String?

    let context: StudentContext
    private let repository: any PassRequestRepository
    private let clock: any AppClock

    convenience init?(session: Session, repositories: Repositories, clock: any AppClock) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.init(context: context, repositories: repositories, clock: clock)
    }

    init(context: StudentContext, repositories: Repositories, clock: any AppClock) {
        self.context = context
        self.repository = repositories.passRequests
        self.clock = clock
    }

    var timeZone: TimeZone { context.mess.timeZone }
    var week: PassWeek { request?.week ?? PassWeekMath.nextWeek(after: clock.now(), timeZone: timeZone) }

    func load() async {
        request = try? await repository.status(for: context.student.id)
        isLoaded = true
    }

    func ask() async {
        isWriting = true
        defer { isWriting = false }
        do {
            request = try await repository.request(for: context.student, at: context.mess)
            errorText = nil
        } catch {
            errorText = (error as? RepositoryError).flatMap { if case .notAllowed(let reason) = $0 { reason } else { nil } }
                ?? PassRequestCopy.didNotSend
        }
    }

    func cancel() async {
        isWriting = true
        defer { isWriting = false }
        do {
            try await repository.cancel(for: context.student.id)
            request = nil
            errorText = nil
        } catch {
            errorText = PassRequestCopy.didNotSend
        }
    }
}

enum PassRequestFormat {
    /// "Mon 19 – Sun 25 Aug".
    static func range(_ week: PassWeek, in timeZone: TimeZone) -> String {
        "\(format(week.start, "EEE d", timeZone)) – \(format(week.end, "EEE d MMM", timeZone))"
    }

    /// "Tue 13 Aug · 4:10 PM".
    static func moment(_ date: Date, in timeZone: TimeZone) -> String {
        "\(format(date, "EEE d MMM", timeZone)) · \(MLFormat.time(date, in: timeZone))"
    }

    private static func format(_ date: Date, _ template: String, _ timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }
}

/// The page body: the black card, then How it works or Your request.
struct StudentPassRequestSection: View {
    let model: StudentPassRequestModel

    private var chip: String {
        switch model.request?.state {
        case .pending: PassRequestCopy.waiting
        case .accepted: PassRequestCopy.approved
        case .declined: PassRequestCopy.declined
        case .cancelled, nil: PassRequestCopy.noPassNextWeek
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            card
            if let request = model.request, request.state != .cancelled {
                yourRequest(request)
            } else {
                PassRequestSteps()
            }
            if let error = model.errorText {
                FieldErrorText(text: error)
            }
        }
    }

    private var card: some View {
        VStack(spacing: MLSpacing.s12) {
            PassTicketGlyph()
                .frame(width: 46, height: 30)
                .frame(width: 112, height: 112)
                .background(Circle().fill(MLColor.fillQuiet))
                .accessibilityHidden(true)
            HStack(spacing: MLSpacing.s4) {
                Image(systemName: model.request?.state == .accepted ? "checkmark" : "circle")
                    .font(StudentType.footnote)
                    .accessibilityHidden(true)
                Text(chip).font(StudentType.footnote)
            }
            .foregroundStyle(model.request?.state == .accepted ? MLColor.onLime : MLColor.onHero)
            .padding(.horizontal, MLSpacing.s12)
            .frame(minHeight: 30)
            .background(Capsule().fill(model.request?.state == .accepted ? MLColor.lime : .clear))
            .overlay(Capsule().strokeBorder(MLColor.onHero, lineWidth: model.request?.state == .accepted ? 0 : 1))
            Text(PassRequestCopy.specialPass)
                .font(StudentType.section)
                .foregroundStyle(MLColor.onHero)
            Text(PassRequestCopy.weekLine(PassRequestFormat.range(model.week, in: model.timeZone)))
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.onHeroSecondary)
        }
        .padding(.vertical, MLSpacing.s24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: StudentMetric.highlightRadius, style: .continuous).fill(MLColor.heroBackground))
        .accessibilityElement(children: .combine)
    }

    private func yourRequest(_ request: PassRequest) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(PassRequestCopy.yourRequest)
                .font(StudentType.eyebrow)
                .tracking(1.2)
                .foregroundStyle(MLColor.inkSecondary)
                .padding(.bottom, MLSpacing.s8)
                .accessibilityAddTraits(.isHeader)
            row(PassRequestCopy.week, PassRequestFormat.range(request.week, in: model.timeZone))
            row(PassRequestCopy.requested, PassRequestFormat.moment(request.requestedAt, in: model.timeZone))
            row(PassRequestCopy.status, status(request))
            Rectangle().fill(MLColor.border).frame(height: 1)
            Text(note(request))
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, MLSpacing.s12)
        }
    }

    private func status(_ request: PassRequest) -> String {
        switch request.state {
        case .pending, .cancelled: PassRequestCopy.waitingForAdmin
        case .accepted: PassRequestCopy.acceptedStatus
        case .declined: PassRequestCopy.declinedStatus
        }
    }

    private func note(_ request: PassRequest) -> String {
        switch request.state {
        case .pending, .cancelled: PassRequestCopy.waitingNote
        case .accepted: PassRequestCopy.acceptedNote
        case .declined: PassRequestCopy.declinedNote
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Rectangle().fill(MLColor.border).frame(height: 1)
            Text(title).font(StudentType.body).foregroundStyle(MLColor.ink).padding(.top, MLSpacing.s12)
            Text(value).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary).padding(.bottom, MLSpacing.s12)
        }
        .accessibilityElement(children: .combine)
    }
}

/// How it works, in three steps (student_pass_04_request).
struct PassRequestSteps: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(PassRequestCopy.howItWorks)
                .font(StudentType.eyebrow)
                .tracking(1.2)
                .foregroundStyle(MLColor.inkSecondary)
                .padding(.bottom, MLSpacing.s8)
                .accessibilityAddTraits(.isHeader)
            step(1, PassRequestCopy.youAsk, PassRequestCopy.youAskDetail)
            step(2, PassRequestCopy.adminDecides, PassRequestCopy.adminDecidesDetail)
            step(3, PassRequestCopy.youUseIt, PassRequestCopy.youUseItDetail)
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
    }

    private func step(_ number: Int, _ title: String, _ detail: String) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(MLColor.border).frame(height: 1)
            HStack(spacing: MLSpacing.s16) {
                Text("\(number)")
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(MLColor.ink)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(MLColor.surface))
                    .overlay(Circle().strokeBorder(MLColor.border))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(StudentType.body).foregroundStyle(MLColor.ink)
                    Text(detail).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.vertical, MLSpacing.s12)
            .accessibilityElement(children: .combine)
        }
    }
}
