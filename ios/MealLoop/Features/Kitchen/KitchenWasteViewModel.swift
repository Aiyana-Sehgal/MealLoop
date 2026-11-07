import Foundation
import Observation

/// One field of the report being edited: a dish, or the plate-waste total.
enum KitchenWasteField: Hashable, Identifiable {
    case dish(DishID)
    case plate

    var id: Self { self }
}

/// What is being typed on the quantity sheet. The limits are the spec's (99.9 in kg and L, 999 pieces).
struct KitchenQuantityInput: Equatable {
    let unit: WasteUnit
    private(set) var text = ""

    static let decimalLimit = 99.9
    static let piecesLimit = 999.0

    init(unit: WasteUnit, value: Double? = nil) {
        self.unit = unit
        if let value { text = KitchenFormat.number(value) }
    }

    var allowsDecimal: Bool { unit != .pieces }
    var limit: Double { unit == .pieces ? Self.piecesLimit : Self.decimalLimit }
    var limitText: String { KitchenFormat.number(limit) }

    mutating func append(_ digit: Int) {
        if let dot = text.firstIndex(of: "."), text.distance(from: dot, to: text.endIndex) > 1 { return }
        text.append(String(digit))
    }

    mutating func appendDecimal() {
        guard allowsDecimal, !text.contains(".") else { return }
        text.append(text.isEmpty ? "0." : ".")
    }

    mutating func deleteLast() {
        if !text.isEmpty { text.removeLast() }
    }

    /// The number, or nil when it is empty, not a number, negative or over the limit.
    var value: Double? {
        guard let number = Double(text), number.isFinite, number >= 0, number <= limit else { return nil }
        return number
    }
}

/// Record waste (K06, K07, K08). The rules stay in the repository: it refuses other roles, a meal that has not ended,
/// an incomplete save and an edit after six hours. This holds the report being edited.
@MainActor
@Observable
final class KitchenWasteViewModel {
    private(set) var state: LoadState<WasteReport> = .idle
    private(set) var isDirty = false
    private(set) var isSaving = false
    private(set) var lastEntered: String?
    private(set) var saveError: String?

    let meal: Meal
    let session: StaffSession
    private let wasteReports: any WasteReportRepository

    init(meal: Meal, session: StaffSession, repositories: Repositories) {
        self.meal = meal
        self.session = session
        self.wasteReports = repositories.wasteReports
    }

    var report: WasteReport? { state.value }
    var isEditingRecorded: Bool {
        if case .recorded? = report?.status { return true }
        return false
    }
    var doneDishes: Int { report?.leftovers.filter(\.measurement.isComplete).count ?? 0 }
    var totalDishes: Int { report?.leftovers.count ?? 0 }
    var missingCount: Int { report?.missingCount ?? 0 }
    var canSave: Bool { report?.canSave ?? false }

    func load() async {
        guard state.value == nil else { return }
        state = .loading
        do {
            state = .loaded(try await wasteReports.report(for: meal.id))
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(nil, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    private func change(_ work: (inout WasteReport) -> Void) {
        guard var current = report else { return }
        work(&current)
        state = .loaded(current)
        isDirty = true
        saveError = nil
    }

    func leftover(_ id: DishID) -> DishLeftover? {
        report?.leftovers.first { $0.dishID == id }
    }

    func set(_ measurement: LeftoverMeasurement, for id: DishID) {
        change { report in
            guard let index = report.leftovers.firstIndex(where: { $0.dishID == id }) else { return }
            report.leftovers[index].measurement = measurement
            lastEntered = report.leftovers[index].dishName
        }
    }

    func setPlate(_ kilograms: Double) {
        change { $0.plateWaste = .entered(kilograms: kilograms) }
    }

    /// A typed zero on a dish is a confirmed "None left", because `entered` is always above zero.
    func saveQuantity(_ value: Double, for field: KitchenWasteField) {
        switch field {
        case .dish(let id): set(value == 0 ? .noneLeft : .entered(value), for: id)
        case .plate: setPlate(value)
        }
    }

    /// "Add a dish", for one that is not on the menu. It starts as not entered, never as zero.
    func addDish(name: String, unit: WasteUnit) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        change { report in
            let id = DishID("added-\(report.leftovers.count)-\(trimmed)")
            report.leftovers.append(DishLeftover(dishID: id, dishName: trimmed, unit: unit, measurement: .notEntered))
        }
    }

    /// True when the draft was stored.
    func saveDraft() async -> Bool {
        guard let report, !isSaving else { return false }
        return await write { [wasteReports, session] in try await wasteReports.saveDraft(report, by: session.role) } != nil
    }

    /// The stored report, or nil when it was refused. A refusal is shown and never reads as saved.
    func save() async -> WasteReport? {
        guard let report, !isSaving else { return nil }
        return await write { [wasteReports, session] in try await wasteReports.save(report, by: session.role) }
    }

    private func write(_ work: () async throws -> WasteReport) async -> WasteReport? {
        isSaving = true
        saveError = nil
        defer { isSaving = false }
        do {
            let stored = try await work()
            state = .loaded(stored)
            isDirty = false
            return stored
        } catch RepositoryError.notAllowed(let reason) {
            saveError = reason
        } catch {
            saveError = KitchenCopy.saveFailed
        }
        return nil
    }
}
