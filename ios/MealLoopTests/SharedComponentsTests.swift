import XCTest
@testable import MealLoop

/// The logic inside the shared components. Their look is checked in the gallery, not here.
final class SharedComponentsTests: XCTestCase {
    // MARK: Gallery

    /// `_typeByName` proves the probe valid in Debug, where the same lookup must find the type.
    func testGalleryIsCompiledOnlyInDebug() {
        let gallery = _typeByName("8MealLoop20ComponentGalleryViewV")
        #if DEBUG
        XCTAssertNotNil(gallery)
        #else
        XCTAssertNil(gallery)
        #endif
    }

    // MARK: Auto return

    func testCountdownFillsAndFinishes() {
        let countdown = AutoReturnCountdown(seconds: 2)
        XCTAssertEqual(countdown.fraction(elapsed: 0), 0)
        XCTAssertEqual(countdown.fraction(elapsed: 1), 0.5)
        XCTAssertEqual(countdown.fraction(elapsed: 5), 1)
        XCTAssertFalse(countdown.isFinished(elapsed: 1.9))
        XCTAssertTrue(countdown.isFinished(elapsed: 2))
    }

    func testCountdownCaptionNeverSaysZero() {
        let countdown = AutoReturnCountdown(seconds: 1)
        XCTAssertEqual(countdown.secondsLeft(elapsed: 0), 1)
        XCTAssertEqual(countdown.secondsLeft(elapsed: 0.99), 1)
        XCTAssertEqual(countdown.secondsLeft(elapsed: 3), 1)
        XCTAssertEqual(AutoReturnCountdown(seconds: 3).secondsLeft(elapsed: 0.5), 3)
    }

    func testVoiceOverStopsTheAutomaticReturn() {
        XCTAssertTrue(AutoReturnCountdown.runsAutomatically(voiceOverEnabled: false))
        XCTAssertFalse(AutoReturnCountdown.runsAutomatically(voiceOverEnabled: true))
    }

    // MARK: Answer buttons

    func testUnansweredHasOnePrimaryAction() {
        let appearances = MealIntention.allCases.map(MealAnswerState.unanswered.appearance(of:))
        XCTAssertEqual(appearances.filter { $0 == .primary }.count, 1)
        XCTAssertEqual(MealAnswerState.unanswered.appearance(of: .attending), .primary)
    }

    func testAnsweredFillsOnlyTheChoice() {
        let state = MealAnswerState.answered(.skipping)
        XCTAssertEqual(state.appearance(of: .skipping), .selected)
        XCTAssertEqual(state.appearance(of: .attending), .outline)
        XCTAssertEqual(state.spokenValue(of: .skipping), "Selected")
        XCTAssertEqual(state.spokenValue(of: .attending), "")
    }

    func testSavingAndLockedRefuseTaps() {
        XCTAssertTrue(MealAnswerState.unanswered.acceptsTaps)
        XCTAssertTrue(MealAnswerState.answered(.notSure).acceptsTaps)
        XCTAssertFalse(MealAnswerState.saving(.attending).acceptsTaps)
        XCTAssertFalse(MealAnswerState.locked(nil).acceptsTaps)
        XCTAssertFalse(MealAnswerState.locked(.attending).acceptsTaps)
    }

    func testLockedStateIsSaidInWords() {
        let state = MealAnswerState.locked(.attending)
        XCTAssertEqual(state.appearance(of: .attending), .lockedSelected)
        XCTAssertEqual(state.appearance(of: .skipping), .locked)
        XCTAssertEqual(state.spokenValue(of: .attending), "Selected, locked")
        XCTAssertEqual(state.spokenValue(of: .skipping), "Locked")
    }

    // MARK: Digit entry

    func testDigitEntryStopsAtItsLengthAndKeepsLeadingZeros() {
        var entry = DigitEntry()
        [0, 2, 3, 8, 9].forEach { entry.append($0) }
        XCTAssertEqual(entry.text, "0238")
        XCTAssertTrue(entry.isComplete)
    }

    func testDigitEntryIgnoresAnythingThatIsNotADigit() {
        var entry = DigitEntry()
        entry.append(10)
        entry.append(-1)
        XCTAssertEqual(entry.text, "")
    }

    func testDigitEntryDeletesAndClears() {
        var entry = DigitEntry()
        entry.deleteLast()
        [1, 2].forEach { entry.append($0) }
        entry.deleteLast()
        XCTAssertEqual(entry.text, "1")
        entry.clear()
        XCTAssertFalse(entry.isComplete)
        XCTAssertEqual(entry.digits, [])
    }

    func testDigitEntryIsSpokenWithoutATrailingGap() {
        var entry = DigitEntry()
        XCTAssertEqual(entry.spokenValue, "0 of 4 entered")
        [0, 2].forEach { entry.append($0) }
        XCTAssertEqual(entry.spokenValue, "2 of 4 entered. 02")
    }

    // MARK: Missing is not zero

    func testMissingFactIsNotSpokenAsZero() {
        XCTAssertEqual(FactRow(label: "Final entries", value: nil).spokenValue, "Not available")
        XCTAssertEqual(FactRow(label: "Entries waiting", value: "0").spokenValue, "0")
    }

    func testProgressSpeaksTheStepAndNeverZeroForMissingData() {
        let labels = ["Reported", "Seen", "Fixing", "Fixed"]
        XCTAssertEqual(SegmentedProgress.spokenText(current: 2, total: 4, labels: labels, missingText: "No data"), "Step 2 of 4, Seen")
        XCTAssertEqual(SegmentedProgress.spokenText(current: 0, total: 4, labels: labels, missingText: "No data"), "Step 0 of 4")
        XCTAssertEqual(SegmentedProgress.spokenText(current: nil, total: 4, labels: labels, missingText: "No data"), "No data")
    }
}
