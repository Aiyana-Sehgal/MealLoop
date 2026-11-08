import SwiftUI
import XCTest
@testable import MealLoop

/// The rules behind the standards scaffold (docs/SWIFTUI_STANDARDS.md): the measured sheet detent,
/// the large-title collapse threshold, the pinned bar, and motion under Reduce Motion.
final class FoundationStandardsTests: XCTestCase {
    // MARK: mlSheet

    func testASheetIsExactlyAsTallAsItsMeasuredContent() {
        XCTAssertEqual(MLSheetSizing.detents(forMeasuredHeight: 312), [.height(312)])
        // A fraction of a point is rounded up, so the last line is never cut.
        XCTAssertEqual(MLSheetSizing.detents(forMeasuredHeight: 312.2), [.height(313)])
    }

    func testASheetIsNeverAFixedHalfOnceMeasured() {
        for height in [120.0, 300.0, 480.0, 900.0] {
            XCTAssertFalse(MLSheetSizing.detents(forMeasuredHeight: height).contains(.medium))
            XCTAssertFalse(MLSheetSizing.detents(forMeasuredHeight: height).contains(.large))
        }
    }

    func testBeforeTheFirstMeasurementTheSheetFallsBackToMedium() {
        XCTAssertEqual(MLSheetSizing.detents(forMeasuredHeight: 0), [.medium])
    }

    // MARK: MLScreen title

    func testTheTitleStaysLargeUntilItsBottomScrollsUnderTheBar() {
        XCTAssertFalse(MLScreenMetrics.isTitleCollapsed(scrollOffset: 0, titleBottom: 49))
        XCTAssertFalse(MLScreenMetrics.isTitleCollapsed(scrollOffset: 48.9, titleBottom: 49))
        XCTAssertTrue(MLScreenMetrics.isTitleCollapsed(scrollOffset: 49, titleBottom: 49))
        XCTAssertTrue(MLScreenMetrics.isTitleCollapsed(scrollOffset: 400, titleBottom: 49))
    }

    func testPullingDownNeverCollapsesTheTitle() {
        XCTAssertFalse(MLScreenMetrics.isTitleCollapsed(scrollOffset: -80, titleBottom: 49))
    }

    func testNothingCollapsesBeforeTheTitleIsMeasured() {
        XCTAssertFalse(MLScreenMetrics.isTitleCollapsed(scrollOffset: 400, titleBottom: 0))
    }

    // MARK: MLScreen bottom bar and placement

    func testTheBottomBarGetsItsCanvasOnlyWhileContentRunsUnderIt() {
        XCTAssertFalse(MLScreenMetrics.isContentUnderBottomBar(contentBottom: 589, visibleBottom: 589))
        XCTAssertFalse(MLScreenMetrics.isContentUnderBottomBar(contentBottom: 589.5, visibleBottom: 589))
        XCTAssertTrue(MLScreenMetrics.isContentUnderBottomBar(contentBottom: 700, visibleBottom: 589))
    }

    func testThePrimaryActionIsPinnedExceptAtAccessibilitySizes() {
        XCTAssertTrue(MLScreenMetrics.pinsBottomBar(isAccessibilitySize: false))
        XCTAssertFalse(MLScreenMetrics.pinsBottomBar(isAccessibilitySize: true))
    }

    func testTabBarClearanceIsTheBarItsGapAndAir() {
        XCTAssertEqual(MLScreenMetrics.floatingTabBarHeight, 62)
        XCTAssertEqual(MLScreenMetrics.tabBarClearance, 86)
    }

    func testUpperMiddleSplitsTheLeftoverOnePartAboveTwoBelow() {
        XCTAssertEqual(MLScreenPlacement.upperMiddle.leftoverShares.above, 1)
        XCTAssertEqual(MLScreenPlacement.upperMiddle.leftoverShares.below, 2)
        XCTAssertEqual(MLScreenPlacement.top.leftoverShares.above, 0)
    }

    // MARK: MLMotion

    func testReduceMotionTurnsEveryCurveIntoACrossFade() {
        for curve in [MLMotion.Curve.snappy, .smooth, .crossFade] {
            XCTAssertEqual(curve.resolved(reduceMotion: true), .crossFade)
            XCTAssertEqual(curve.resolved(reduceMotion: false), curve)
        }
        XCTAssertEqual(MLMotion.Curve.crossFade.animation, .easeInOut(duration: 0.2))
    }

    func testReduceMotionTurnsEveryEntranceIntoAFade() {
        for entrance in [MLMotion.Entrance.fromTop, .fromBottom, .pop, .fade] {
            XCTAssertEqual(entrance.resolved(reduceMotion: true), .fade)
            XCTAssertEqual(entrance.resolved(reduceMotion: false), entrance)
        }
    }

    func testTheCurvesAreTheSystemSnappyAndSmooth() {
        XCTAssertEqual(MLMotion.Curve.snappy.animation, .snappy(duration: 0.3))
        XCTAssertEqual(MLMotion.Curve.smooth.animation, .smooth(duration: 0.4))
    }

    func testAnimateRunsItsBodyOnce() {
        var runs = 0
        MLMotion.animate(.snappy, reduceMotion: true) { runs += 1 }
        MLMotion.animate(.smooth, reduceMotion: false) { runs += 1 }
        XCTAssertEqual(runs, 2)
    }

    func testHapticsAreTheThreeSystemFeedbacks() {
        XCTAssertEqual(MLHaptic.selection.feedback, .selection)
        XCTAssertEqual(MLHaptic.success.feedback, .success)
        XCTAssertEqual(MLHaptic.warning.feedback, .warning)
    }

    // MARK: Dynamic Type

    func testEveryScaledStyleStartsFromItsToken() {
        for style in MLDynamicType.allCases {
            XCTAssertEqual(style.font(size: style.baseSize), style.token, "\(style)")
        }
    }
}
