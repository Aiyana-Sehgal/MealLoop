import Foundation
import Observation

/// What the gate tries, kept so "Try again" on the offline result repeats exactly that.
enum GateAttempt: Hashable {
    case code(String)
    case outing(OutingRequestID)
    case exit(OutingRequestID)
    case back(OutingRequestID)
}

/// A full-screen gate result (GA-6).
enum GateOutcome: Hashable {
    case exitRecorded(GateRecord)
    case returnRecorded(GateRecord)
    case refused(GateCheck)
    case offline(GateAttempt)
}

/// Pushed gate pages. The gate home is the root; the scan screen and the results have no tab bar.
enum GateRoute: Hashable {
    case scan
    case passCode
    case findStudent
    case verify(GateCheck)
    case outcome(GateOutcome)
    case outNow
    case overdue
    case report
    case reportSent(GateProblemReport)
}

/// Everything the gate screens read and record, through the outing repository only. The repository refuses an exit
/// without a signed, unused pass inside its window, and a return without an exit.
@MainActor
@Observable
final class GateModel {
    private(set) var overview: GateOverview?
    private(set) var outNow: [OutingCase] = []
    private(set) var overdue: [OutingCase] = []
    private(set) var now: Date?
    private(set) var failure: LoadFailure?
    private(set) var isWorking = false
    private(set) var matches: [OutingCase]?

    private let repository: any OutingCaseRepository
    private var hasBegun = false

    init(repository: any OutingCaseRepository) {
        self.repository = repository
    }

    func load() async {
        do {
            if !hasBegun {
                try await repository.begin(as: .gate)
                hasBegun = true
            }
            now = await repository.now()
            overview = try await repository.gateOverview(by: .gate)
            outNow = try await repository.gateOutNow(by: .gate)
            overdue = try await repository.gateOverdue(by: .gate)
            failure = nil
        } catch {
            failure = LoadFailure(error)
        }
    }

    /// Runs one attempt and says where to go next: the verify page or a result.
    func run(_ attempt: GateAttempt) async -> GateRoute? {
        guard !isWorking else { return nil }
        isWorking = true
        defer { isWorking = false }
        do {
            let route: GateRoute
            switch attempt {
            case .code(let code):
                route = destination(for: try await repository.checkPassCode(code, by: .gate))
            case .outing(let id):
                route = destination(for: try await repository.checkPass(of: id, by: .gate))
            case .exit(let id):
                route = .outcome(.exitRecorded(try await repository.recordExit(id, by: .gate)))
            case .back(let id):
                route = .outcome(.returnRecorded(try await repository.recordReturn(id, by: .gate)))
            }
            now = await repository.now()
            await load()
            return route
        } catch RepositoryError.offline {
            return .outcome(.offline(attempt))
        } catch {
            failure = LoadFailure(error)
            return nil
        }
    }

    private func destination(for check: GateCheck) -> GateRoute {
        switch check {
        case .exitReady, .returnReady: return .verify(check)
        default: return .outcome(.refused(check))
        }
    }

    func find(srmID: String) async {
        do {
            matches = try await repository.findStudent(srmID: srmID, by: .gate)
        } catch {
            matches = nil
            failure = LoadFailure(error)
        }
    }

    func clearMatches() { matches = nil }

    func report(_ problem: GateProblem) async -> GateProblemReport? {
        do {
            return try await repository.reportGateProblem(problem, by: .gate)
        } catch {
            failure = LoadFailure(error)
            return nil
        }
    }
}
