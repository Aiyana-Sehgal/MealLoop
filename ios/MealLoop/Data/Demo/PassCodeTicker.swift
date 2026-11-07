#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SIMULATED. The instant the live pass code is read at: the story time plus the seconds since the story clock last
/// moved. The story clock only moves when the story does, so without this the code would never change on screen.
/// One instance per prototype backend, so the student's phone and the Pass Desk read the same instant.
final class PassCodeTicker: @unchecked Sendable {
    private let lock = NSLock()
    private let uptime: @Sendable () -> TimeInterval
    private var anchorStory: Date?
    private var anchorUptime: TimeInterval = 0

    /// `uptime` is injected so tests can move it; the default is the device's monotonic uptime, not the wall clock.
    init(uptime: @escaping @Sendable () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.uptime = uptime
    }

    func instant(story: Date) -> Date {
        lock.lock()
        defer { lock.unlock() }
        let now = uptime()
        if anchorStory != story {
            anchorStory = story
            anchorUptime = now
        }
        return story.addingTimeInterval(max(0, now - anchorUptime))
    }
}
#endif
