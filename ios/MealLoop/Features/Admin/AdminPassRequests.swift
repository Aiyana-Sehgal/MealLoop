import Observation
import SwiftUI

// More › Passes › Requests for next week (approved image admin_passes_01_requests; Figma AD-6a 2277:1788): the count
// waiting and approved, then each waiting request by masked ID only, with Accept and Decline. Never a student name.

enum AdminPassRequestsCopy {
    static let requestsForNextWeek = "REQUESTS FOR NEXT WEEK"
    static let waiting = "waiting"
    static func approvedSoFar(_ count: Int) -> String { "Approved so far · \(count)" }
    static let waitingForYou = "WAITING FOR YOU"
    static func requested(_ day: String, _ mess: String) -> String { "Requested \(day) · \(mess.replacingOccurrences(of: " Mess", with: ""))" }
    static let accept = "Accept"
    static let decline = "Decline"
    static let nothingWaiting = "No requests are waiting."
    static func accepted(_ id: String) -> String { "Accepted \(id). This prototype sends nothing." }
    static func declined(_ id: String) -> String { "Declined \(id). This prototype sends nothing." }
}

@MainActor
@Observable
final class AdminPassRequestsModel {
    private(set) var queue: LoadState<PassRequestQueue> = .idle
    private(set) var deciding: PassRequestID?
    private(set) var errorText: String?

    private let repository: any PassRequestRepository
    private let role: Role

    init(repository: any PassRequestRepository, role: Role) {
        self.repository = repository
        self.role = role
    }

    func load() async {
        do {
            queue = .loaded(try await repository.queue(by: role))
        } catch RepositoryError.offline(let savedAt) {
            queue = .offline(queue.value, savedAt: savedAt)
        } catch {
            queue = .failed(LoadFailure(error))
        }
    }

    func decide(_ request: PassRequest, accept: Bool) async -> Bool {
        deciding = request.id
        defer { deciding = nil }
        do {
            _ = accept ? try await repository.accept(request.id, by: role) : try await repository.decline(request.id, by: role)
            errorText = nil
            await load()
            return true
        } catch {
            errorText = AdminWriteError.text(error)
            return false
        }
    }
}

struct AdminPassRequestsSection: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: AdminPassRequestsModel?
    let nav: AdminNav

    var body: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            if let queue = model?.queue.value {
                HeroCard {
                    VStack(alignment: .leading, spacing: MLSpacing.s8) {
                        HeroEyebrow(label: AdminPassRequestsCopy.requestsForNextWeek)
                        HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s8) {
                            Text("\(queue.pending.count)")
                                .font(MLType.heroNumber)
                                .foregroundStyle(MLColor.onHero)
                                .mlNumericText(queue.pending.count)
                            Text(AdminPassRequestsCopy.waiting).mlFont(.staffBody).foregroundStyle(MLColor.onHeroSecondary)
                        }
                        Text(AdminPassRequestsCopy.approvedSoFar(queue.approvedCount))
                            .mlFont(.body)
                            .foregroundStyle(MLColor.onHeroSecondary)
                    }
                }
                AdminLabel(text: AdminPassRequestsCopy.waitingForYou)
                if queue.pending.isEmpty {
                    Text(AdminPassRequestsCopy.nothingWaiting).mlFont(.body).foregroundStyle(MLColor.inkSecondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(queue.pending) { request in row(request) }
                    }
                }
                if let error = model?.errorText { FieldErrorText(text: error) }
            } else if case .failed(let failure)? = model?.queue {
                AdminNote(text: failure.message)
            }
        }
        .task {
            if model == nil {
                model = AdminPassRequestsModel(repository: environment.repositories.passRequests, role: nav.context.account.role)
            }
            await model?.load()
        }
    }

    private func row(_ request: PassRequest) -> some View {
        HStack(spacing: MLSpacing.s8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(request.maskedID).font(MLType.monoBody).foregroundStyle(MLColor.ink)
                Text(AdminPassRequestsCopy.requested(AdminFormat.shortDay(request.requestedAt, in: nav.timeZone), request.messName))
                    .mlFont(.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
            }
            Spacer(minLength: MLSpacing.s8)
            Button {
                Task { if await model?.decide(request, accept: true) == true { nav.toast(AdminPassRequestsCopy.accepted(request.maskedID)) } }
            } label: {
                // The black Accept pill of admin_passes_01_requests; the shared compact pill has no filled ink style.
                Text(AdminPassRequestsCopy.accept)
                    .font(MLType.bodyEmphasis)
                    .foregroundStyle(MLColor.onHero)
                    .padding(.horizontal, MLSpacing.s16)
                    .frame(minWidth: MLSize.hit, minHeight: MLSize.hit)
                    .background(Capsule().fill(MLColor.ink))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            CompactPillButton(title: AdminPassRequestsCopy.decline) {
                Task { if await model?.decide(request, accept: false) == true { nav.toast(AdminPassRequestsCopy.declined(request.maskedID)) } }
            }
        }
        .disabled(model?.deciding != nil)
        .padding(.vertical, MLSpacing.s12)
        .overlay(alignment: .top) { Rectangle().fill(MLColor.border).frame(height: 1) }
        .accessibilityElement(children: .contain)
    }
}
