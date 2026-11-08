import Observation
import SwiftUI

// Credits · Getting a ticket (221:64396), Credits · Failed (221:65873), Ticket · Juice (1529:1901), Ticket · Juice · Used
// (1529:2180) and Rewards · Balance issue (221:64463). Costs, balances, codes and colours come from
// `StudentRewardsRepository`; nothing here is a formula (P1).

/// Words of the reward frames. Wording only.
enum RewardsCopy {
    static let getting = "Getting…"
    static let tryAgain = "Try again"
    static func couldNotGet(_ name: String) -> String { "Couldn't get the \(name) ticket. Your points are safe. Try again" }
    static func ticketTitle(_ name: String) -> String { "\(name) ticket" }
    static func usedAndLeft(_ cost: Int, _ left: Int) -> String { "\(cost) pts used · \(left) left" }
    static let showAtCounter = "Show this at the counter"
    static let usedAtCounter = "Used at the counter"
    static let code = "Code"
    static let colour = "Colour"
    static func usedAt(_ time: String) -> String { "Used \(time)" }
    static let valid = "Valid"
    static let used = "Used"
    static func gotOn(_ name: String, _ day: String) -> String { "\(name) · got \(day)" }
    static func usedOn(_ name: String, _ day: String) -> String { "\(name) · used \(day)" }
    static let noScan = "No scan needed."
    static let counterChecks = "The counter checks your code and colour."
    static let ticketUsed = "This ticket is used."
    static let getAnother = "Get another from Credits when you have the points."
    static let balanceQuestion = "Something wrong with your balance?"
    static let balanceDetail = "Tell us what looks off."
    static let whatsWrong = "What's wrong?"
    static let whatsWrongPrompt = "Missing points, a wrong amount…"
    static let send = "Send"
    static let recorded = "Recorded. This prototype sends nothing."
    static let didNotSend = "Didn't send. Try again."
    static let ticketMissing = "This ticket isn't available right now."
}

// MARK: - View model

/// Getting a ticket, the ticket page and the balance question. Screen state only.
@MainActor
@Observable
final class StudentRewardsViewModel {
    enum Send: Equatable { case idle, sending, sent, failed }

    /// The reward being got right now ("juice").
    private(set) var getting: String?
    /// The reward that could not be got, for Credits · Failed.
    private(set) var failedReward: String?
    private(set) var ticket: LoadState<StudentRewardTicket> = .idle
    private(set) var balanceSend: Send = .idle

    let context: StudentContext
    private let rewards: any StudentRewardsRepository
    private let clock: any AppClock

    init?(session: Session, repositories: Repositories, clock: any AppClock) {
        guard session.account.role == .student, let context = session.student else { return nil }
        self.context = context
        self.rewards = repositories.studentRewards
        self.clock = clock
    }

    var timeZone: TimeZone { context.mess.timeZone }
    private var student: StudentID { context.student.id }

    /// The new ticket's id, or nil when it was refused or failed (nothing was taken).
    func get(_ rewardID: String) async -> StudentRewardTicketID? {
        guard getting == nil else { return nil }
        getting = rewardID
        failedReward = nil
        defer { getting = nil }
        do {
            let ticket = try await rewards.getTicket(rewardID, for: student)
            self.ticket = .loaded(ticket)
            return ticket.id
        } catch {
            failedReward = rewardID
            return nil
        }
    }

    func loadTicket(_ id: StudentRewardTicketID) async {
        if ticket.value?.id != id { ticket = .loading }
        do {
            ticket = .loaded(try await rewards.ticket(id, for: student))
        } catch RepositoryError.offline(let savedAt) {
            ticket = .offline(ticket.value, savedAt: savedAt)
        } catch {
            ticket = .failed(LoadFailure(error))
        }
    }

    func reportBalanceIssue(_ text: String) async {
        balanceSend = .sending
        do {
            _ = try await rewards.reportBalanceIssue(text, for: student)
            balanceSend = .sent
        } catch {
            balanceSend = .failed
        }
    }

    func resetBalanceIssue() {
        balanceSend = .idle
    }
}

// MARK: - Ticket page

/// Ticket · Juice (1529:1901) and Ticket · Juice · Used (1529:2180).
struct StudentRewardTicketView: View {
    @State var model: StudentRewardsViewModel
    let id: StudentRewardTicketID

    var body: some View {
        MLScreen(title, subtitle: subtitle, bottomClearance: .tabBar) {
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                content
            }
        }
        .task { await model.loadTicket(id) }
        .refreshable { await model.loadTicket(id) }
    }

    private var title: String {
        model.ticket.value.map { RewardsCopy.ticketTitle($0.name) } ?? YouCopy.credits
    }

    private var subtitle: String? {
        model.ticket.value.map { RewardsCopy.usedAndLeft($0.cost, $0.balanceAfter) }
    }

    @ViewBuilder
    private var content: some View {
        switch model.ticket {
        case .idle, .loading:
            YouSkeleton(heights: [392, 60], label: YouCopy.credits)
        case .loaded(let ticket), .stale(let ticket, _):
            RewardTicketCard(ticket: ticket, timeZone: model.timeZone)
            footer(ticket)
        case .offline(let ticket, _):
            StudentOfflineBanner(text: YouCopy.offline)
            if let ticket {
                RewardTicketCard(ticket: ticket, timeZone: model.timeZone)
                footer(ticket)
            }
        case .empty, .failed:
            MealsStateCard(symbol: "exclamationmark.circle", title: RewardsCopy.ticketMissing, detail: "")
        }
    }

    private func footer(_ ticket: StudentRewardTicket) -> some View {
        VStack(spacing: MLSpacing.s4) {
            Text(ticket.isUsed ? RewardsCopy.ticketUsed : RewardsCopy.noScan)
                .font(StudentType.bodySemibold)
                .foregroundStyle(MLColor.ink)
            Text(ticket.isUsed ? RewardsCopy.getAnother : RewardsCopy.counterChecks)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

/// The white ticket: code and colour above the tear line, the holder below.
struct RewardTicketCard: View {
    let ticket: StudentRewardTicket
    let timeZone: TimeZone

    private var ink: Color { ticket.isUsed ? MLColor.inkSecondary : MLColor.ink }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: MLSpacing.s12) {
                Text(ticket.isUsed ? RewardsCopy.usedAtCounter : RewardsCopy.showAtCounter)
                    .font(StudentType.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
                VStack(spacing: 0) {
                    Text(RewardsCopy.code).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
                    Text(ticket.code)
                        .font(.system(size: 72, weight: .bold, design: .default))
                        .foregroundStyle(ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .accessibilityLabel(ticket.code.map(String.init).joined(separator: " "))
                }
                Text(RewardsCopy.colour).font(StudentType.secondary).foregroundStyle(MLColor.inkSecondary)
                Text(ticket.colourName)
                    .font(StudentType.section)
                    .foregroundStyle(ink)
                    .frame(maxWidth: 180, minHeight: 48)
                    .background(Capsule().fill(ticket.isUsed ? MLColor.track : colourFill))
                    .overlay(Capsule().strokeBorder(ticket.isUsed ? .clear : MLColor.ink, lineWidth: 1.5))
                    .accessibilityLabel("\(RewardsCopy.colour) \(ticket.colourName)")
                if let usedAt = ticket.usedAt {
                    Text(RewardsCopy.usedAt(MLFormat.time(usedAt, in: timeZone)))
                        .font(StudentType.secondary)
                        .foregroundStyle(MLColor.inkSecondary)
                }
            }
            .padding(.vertical, MLSpacing.s24)
            .padding(.horizontal, MLSpacing.s20)
            .frame(maxWidth: .infinity)
            Line()
                .stroke(MLColor.border, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .frame(height: 1)
                .padding(.horizontal, MLSpacing.s20)
            HStack {
                VStack(alignment: .leading, spacing: MLSpacing.s4) {
                    Text([ticket.holderName, ticket.holderMaskedID.isEmpty ? nil : ticket.holderMaskedID]
                        .compactMap { $0 }.joined(separator: " "))
                        .font(StudentType.section)
                        .foregroundStyle(MLColor.ink)
                    Text(ticket.isUsed
                         ? RewardsCopy.usedOn(ticket.name, YouFormat.shortDay(ticket.usedAt ?? ticket.gotAt, in: timeZone))
                         : RewardsCopy.gotOn(ticket.name, YouFormat.shortDay(ticket.gotAt, in: timeZone)))
                        .font(StudentType.secondary)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: MLSpacing.s8)
                Text(ticket.isUsed ? RewardsCopy.used : RewardsCopy.valid)
                    .font(StudentType.dishName)
                    .foregroundStyle(ticket.isUsed ? MLColor.inkSecondary : MLColor.onLime)
                    .padding(.horizontal, MLSpacing.s16)
                    .frame(minHeight: 36)
                    .background(Capsule().fill(ticket.isUsed ? MLColor.track : MLColor.lime))
                    .overlay(Capsule().strokeBorder(ticket.isUsed ? .clear : MLColor.ink, lineWidth: 1))
            }
            .padding(MLSpacing.s20)
            .accessibilityElement(children: .combine)
        }
        .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.surface))
    }

    private var colourFill: Color {
        ticket.colourName == "Lime" ? MLColor.lime : MLColor.surface
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }
}

// MARK: - Balance issue

/// Rewards · Balance issue (221:64463), in a sheet sized to its content.
struct BalanceIssueSheet: View {
    let model: StudentRewardsViewModel
    let onClose: () -> Void
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: RewardsCopy.balanceQuestion, subtitle: RewardsCopy.balanceDetail, onClose: onClose)
            if model.balanceSend == .sent {
                SpendingSavedBanner(text: RewardsCopy.recorded)
                    .mlTransition(.fade)
            } else {
                VStack(alignment: .leading, spacing: MLSpacing.s8) {
                    Text(RewardsCopy.whatsWrong).font(StudentType.footnote).foregroundStyle(MLColor.inkSecondary)
                    TextField(RewardsCopy.whatsWrongPrompt, text: $text, axis: .vertical)
                        .font(StudentType.body)
                        .lineLimit(1...4)
                        .focused($focused)
                        .submitLabel(.send)
                        .padding(MLSpacing.s16)
                        .background(RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous).fill(MLColor.surface))
                        .overlay(RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous)
                            .strokeBorder(MLColor.border))
                }
                if model.balanceSend == .failed {
                    FieldErrorText(text: RewardsCopy.didNotSend)
                }
                InkActionButton(title: RewardsCopy.send, isLoading: model.balanceSend == .sending) {
                    focused = false
                    Task { await model.reportBalanceIssue(text) }
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.balanceSend == .sending)
            }
        }
        .onAppear {
            model.resetBalanceIssue()
            focused = true
        }
        .sensoryFeedback(trigger: model.balanceSend) { _, state in state == .sent ? .success : nil }
    }
}
