import SwiftUI
import UIKit
import XCTest
@testable import MealLoop

/// The bundled typefaces resolve in the build, so no text token falls back to the system font.
final class MLFontsTests: XCTestCase {
    func testEveryBundledWeightResolves() {
        for name in Array(MLFonts.textWeights.values) + Array(MLFonts.monoWeights.values) {
            XCTAssertTrue(MLFonts.isAvailable(name), "\(name) is not registered")
        }
    }

    func testTokensUseTheBundledFaces() {
        XCTAssertEqual(MLFonts.name(weight: .bold, monospaced: false), "Inter-Bold")
        XCTAssertEqual(MLFonts.name(weight: .medium, monospaced: true), "JetBrainsMono-Medium")
        XCTAssertEqual(Font.ml(size: 34, weight: .bold), Font.custom("Inter-Bold", fixedSize: 34))
        XCTAssertEqual(Font.ml(size: 15, weight: .medium, design: .monospaced), Font.custom("JetBrainsMono-Medium", fixedSize: 15))
    }

    func testTheLicencesShipWithTheFonts() {
        XCTAssertNotNil(Bundle.main.url(forResource: "Inter-OFL", withExtension: "txt"))
        XCTAssertNotNil(Bundle.main.url(forResource: "JetBrainsMono-OFL", withExtension: "txt"))
    }
}
