import XCTest
@testable import MealLoop

/// Tracks how much of the app is still a placeholder, and that none of it says "Not implemented".
final class PlaceholderMetricTests: XCTestCase {
    /// Destinations a role reaches from its root that are real screens, as the combined base builds them.
    /// Still placeholders: Student Meals, Community, You and Search (StudentRootView); Admin Search
    /// (AdminRootView); every Super Admin and Vendor tab (PlaceholderRootView).
    private let built: [RoleRoot: Set<String>] = [
        .student: ["Home"],
        .admin: ["Today", "Students", "Results", "More"],
        .supervisor: ["Home", "Alerts", "Me"],
        .kitchen: ["Home", "Alerts", "Me"],
        .doorScanner: ["Home", "Alerts", "Me"],
        .passDesk: ["Home", "Alerts", "Me"],
        .warden: ["Queue", "Out now", "Escalated", "History"],
        .gate: ["Home"],
        .guardian: ["Root"],
    ]

    /// Roots whose real chrome differs from `placeholderTabs`. Gate has one home page and no tab bar (GateRootView, GA-1).
    private let reachableOverride: [RoleRoot: [String]] = [.gate: ["Home"]]

    private func destinations(of root: RoleRoot) -> [String] {
        if let override = reachableOverride[root] { return override }
        if root.usesStaffTabs { return StaffTab.allCases.map(\.rawValue.capitalized) }
        let tabs = root.placeholderTabs.isEmpty ? ["Root"] : root.placeholderTabs
        return tabs + (root.hasSearch ? ["Search"] : [])
    }

    /// Every built destination must be one the role can reach, so a renamed tab cannot hide in the count.
    func testBuiltDestinationsAreReachable() {
        for (root, names) in built {
            XCTAssertTrue(names.isSubset(of: Set(destinations(of: root))), "\(root.rawValue): \(names.subtracting(destinations(of: root)))")
        }
    }

    func testReportThePlaceholderCountPerRole() {
        var total = 0
        var reachable = 0
        for root in RoleRoot.allCases {
            let all = destinations(of: root)
            let placeholders = all.filter { !(built[root] ?? []).contains($0) }
            total += placeholders.count
            reachable += all.count
            print("PLACEHOLDERS \(root.rawValue): \(placeholders.count) of \(all.count) \(placeholders)")
        }
        print("PLACEHOLDERS total: \(total) of \(reachable)")
        XCTAssertEqual(Set(Role.allCases.map(RoleRoot.destination(for:))).count, 11)
    }

    func testNoSourceFileCanShowNotImplemented() throws {
        let app = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("MealLoop")
        let files = try XCTUnwrap(FileManager.default.enumerator(at: app, includingPropertiesForKeys: nil))
        var scanned = 0
        for case let file as URL in files where file.pathExtension == "swift" {
            let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: .newlines)
            scanned += 1
            // Comments never reach the screen, so only code lines count.
            let code = lines.filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            XCTAssertFalse(code.contains { $0.contains("Not implemented") }, file.lastPathComponent)
        }
        XCTAssertGreaterThan(scanned, 50)
    }
}
