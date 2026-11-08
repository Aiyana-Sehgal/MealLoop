#if DEBUG
import SwiftUI
import UIKit
import XCTest
@testable import MealLoop

/// Captures the MLScreen gallery page for docs/verification/foundation-standards/: the large title, the collapsed
/// title (scrolled to the end), the iOS 17 reader collapsed, the sheets and the largest Dynamic Type size.
/// Real views drawn on the simulator the tests run on. Skipped unless TEST_RUNNER_FOUNDATION_SHOTS names a folder.
@MainActor
final class FoundationStandardsScreenshotTests: XCTestCase {
    private var outputFolder: URL!
    private var device = ""

    override func setUp() async throws {
        guard let path = ProcessInfo.processInfo.environment["FOUNDATION_SHOTS"], !path.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_FOUNDATION_SHOTS to capture the foundation gallery.")
        }
        outputFolder = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        let bounds = UIScreen.main.bounds
        device = "\(Int(bounds.width))x\(Int(bounds.height))"
    }

    func testCaptureGallery() async throws {
        try await shot("gallery_1_large_title") { MLScreenGalleryView() }
        try await shot("gallery_2_collapsed", scrolledToEnd: true) { MLScreenGalleryView() }
        try await shot("gallery_3_collapsed_ios17_reader", scrolledToEnd: true) {
            MLScreenGalleryView(scrollTracking: .legacy)
        }
        try await shot("gallery_4_sheet_sized_to_content", wait: 1.5) { MLScreenGalleryView(opening: .sheet) }
        try await shot("gallery_5_confirm_sheet", wait: 1.5) { MLScreenGalleryView(opening: .confirmation) }
        try await shot("gallery_6_largest_text") {
            MLScreenGalleryView().dynamicTypeSize(.accessibility5)
        }
        try await shot("gallery_7_largest_text_collapsed", scrolledToEnd: true) {
            MLScreenGalleryView().dynamicTypeSize(.accessibility5)
        }
    }

    private func shot<V: View>(_ name: String, wait: Double = 1.0, scrolledToEnd: Bool = false,
                               @ViewBuilder _ view: () -> V) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds
        window.windowLevel = .alert + 1
        window.overrideUserInterfaceStyle = .light
        // Pushed onto a root, as in the app, so the bar shows the system back button.
        let page = view()
        let root = NavigationStack(path: .constant([GalleryPage.screenScaffold])) {
            Color.clear.navigationDestination(for: GalleryPage.self) { _ in page }
        }
        window.rootViewController = UIHostingController(rootView: root)
        window.makeKeyAndVisible()
        try await Task.sleep(for: .seconds(wait))
        if scrolledToEnd {
            // Scroll the way a finger does: move the real scroll view to its last offset, then let SwiftUI react.
            let scrollView = try XCTUnwrap(scrollViews(in: window).first { $0.contentSize.height > $0.bounds.height })
            let end = scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
            scrollView.setContentOffset(CGPoint(x: 0, y: end), animated: false)
            try await Task.sleep(for: .seconds(0.8))
        }
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        try XCTUnwrap(image.pngData()).write(to: outputFolder.appendingPathComponent("\(name)_\(device).png"))
        window.rootViewController?.dismiss(animated: false)
        try await Task.sleep(for: .seconds(0.3))
        window.isHidden = true
        window.rootViewController = nil
    }

    private func scrollViews(in view: UIView) -> [UIScrollView] {
        ((view as? UIScrollView).map { [$0] } ?? []) + view.subviews.flatMap(scrollViews(in:))
    }
}
#endif
