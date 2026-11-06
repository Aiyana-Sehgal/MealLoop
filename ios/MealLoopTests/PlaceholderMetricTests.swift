import XCTest
@testable import MealLoop

/// Tracks how much of the app is still a placeholder, and that none of it says "Not implemented".
final class PlaceholderMetricTests: XCTestCase {
    /// Destinations a role reaches from its root that are real screens. Add to this as parts land.
    private let built: [RoleRoot: Set<String>] = [.kitchen: ["Home"]]

    private func destinations(of root: RoleRoot) -> [String] {
        if root.usesStaffTabs { return StaffTab.allCases.map(\.rawValue.capitalized) }
        let tabs = root.placeholderTabs.isEmpty ? ["Root"] : root.placeholderTabs
        return tabs + (root.hasSearch ? ["Search"] : [])
    }

    func testReportThePlaceholderCountPerRole() {
        var total = 0
        var reachable = 0
        for root in RoleRoot.allCases {
            let all = destinations(of: root)
            let placeholders = all.filter { !(built[root] ?? []).contains($0) }
            total += placeholders.count
            reachable += all.count
            print("PLACEHOLDERS \(root.rawValue): \(placeholders.count) of \(all.count)")
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
