import XCTest
@testable import MealLoop

/// Keeps the three configurations apart: Debug has the demo tools, Review has seeded data only, Release has neither.
final class BuildConfigurationTests: XCTestCase {
    /// The probe is proved valid by Debug, where the same lookup must find the type.
    /// The Demo sheet (Getting started, Switch role) is compiled into Debug and Review. Release has neither flag, so the
    /// `#if DEMO_DATA || REVIEW_DATA` around it leaves it out; `testReleaseHasNoDataFlags` checks the flags, and the
    /// Release binary is checked for its strings in docs/verification/review/PROGRESS.md.
    func testTheDemoSheetIsCompiledInTheSeededBuilds() {
        XCTAssertNotNil(_typeByName("8MealLoop9DemoSheetV"))
        XCTAssertNil(_typeByName("8MealLoop13DemoDataBadgeV"), "The old floating badge is gone")
    }

    func testTheFlagsAreNeverCombined() {
        #if DEMO_DATA && REVIEW_DATA
        XCTFail("DEMO_DATA and REVIEW_DATA must never be set together")
        #endif
    }

    func testProjectSetsTheExpectedFlagsPerConfiguration() throws {
        let project = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("MealLoop.xcodeproj/project.pbxproj")
        let text = try String(contentsOf: project, encoding: .utf8)
        let pattern = #"SWIFT_ACTIVE_COMPILATION_CONDITIONS = "?([^";]*)"?;(?s:.*?)name = (\w+);"#
        let regex = try NSRegularExpression(pattern: pattern)
        var flags: [String: String] = [:]
        for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            guard let value = Range(match.range(at: 1), in: text), let name = Range(match.range(at: 2), in: text) else { continue }
            flags[String(text[name])] = String(text[value])
        }
        XCTAssertEqual(flags["Debug"], "DEBUG DEMO_DATA $(inherited)")
        XCTAssertEqual(flags["Review"], "REVIEW_DATA REVIEW_CONFIGURATION")
        XCTAssertEqual(flags["Release"], "")
    }
}
