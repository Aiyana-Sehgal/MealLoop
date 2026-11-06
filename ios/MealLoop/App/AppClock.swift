import Foundation

/// The source of "now". Injected so the demo and tests can show fixed moments.
protocol AppClock: Sendable {
    func now() -> Date
}

/// A clock the prototype backend moves as the story happens. It is never moved by a view or a view model.
protocol StoryClock: AppClock {
    /// Jumps to any time. Used to start a scenario.
    func set(_ date: Date)
}

extension StoryClock {
    /// Moves forward to `date`. A clock already past it stays put, so time never runs backwards.
    func advance(to date: Date) {
        if date > now() { set(date) }
    }
}

struct SystemClock: AppClock {
    func now() -> Date { Date() }
}
