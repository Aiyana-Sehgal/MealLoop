import Observation
import SwiftUI

// The restyled SOS flow (Figma file nzzTAm9YnJRSdKEeYUWUEb, page 07): SOS · new (2162:6), SOS · I feel unwell (2162:161),
// SOS · Camera · GPS unavailable (2162:405), SOS · Camera denied (2162:493), SOS · Review (2162:152142), Review · GPS
// unavailable (2162:152270), Review · No photo (2162:152398), Review · Offline (2162:152516), Review · Failed
// (2162:152648) and SOS Sent (221:63509).
// Rules: an urgent report raises an SOS through `SOSRepository.raise` (then the view calls `dataDidChange()`); offline
// nothing is sent or shown as sent, and it is sent once the app is back online; a failed send offers Try again with the
// same key, so a retry never opens a second case. The camera is a static preview and the location is the student's
// mess: neither is verified on a device.

/// The four SOS choices of 2162:6. Wording of the frame.
enum StudentSOSCategory: String, CaseIterable, Hashable, Sendable {
    case foundInFood
    case spoiled
    case unwell
    case otherSafety

    var title: String {
        switch self {
        case .foundInFood: return "Found something in my food"
        case .spoiled: return "Food smells or looks spoiled"
        case .unwell: return "I feel unwell after eating"
        case .otherSafety: return "Another safety problem"
        }
    }

    var symbol: String {
        switch self {
        case .foundInFood: return "magnifyingglass"
        case .spoiled: return "nose"
        case .unwell: return "hand.raised"
        case .otherSafety: return "exclamationmark.triangle"
        }
    }
}

@MainActor
@Observable
final class StudentSOSViewModel {
    /// The phone's camera, as the prototype simulates it. The simulator has no camera.
    enum Camera: Equatable { case available, denied }
    /// The phone's location, as the prototype simulates it. Nothing is measured.
    enum Location: Equatable { case atMess, unavailable }
    enum SendState: Equatable { case idle, sending, failed, offline, waitingForConnection }

    let context: StudentContext
    let camera: Camera
    let location: Location
    var category: StudentSOSCategory?
    var dish: String?
    private(set) var dishes: [String] = []
    private(set) var meal: MealSlot?
    /// When the live photo was taken; nil until then, and nil when sent without a photo.
    private(set) var photoAt: Date?
    private(set) var withoutPhoto = false
    private(set) var sendState: SendState = .idle
    private(set) var sos: SOSCase?
    private var key = IdempotencyKey.make()

    private let sosRepository: any SOSRepository
    private let mealState: any MealStateRepository
    private let meals: any StudentMealsRepository
    private let clock: any AppClock

    init(context: StudentContext, repositories: Repositories, clock: any AppClock, camera: Camera = .available,
         location: Location = .atMess) {
        self.context = context
        self.clock = clock
        self.camera = camera
        self.location = location
        sosRepository = repositories.sos
        mealState = repositories.mealState
        meals = repositories.studentMeals
    }

    var now: Date { clock.now() }
    var timeZone: TimeZone { context.mess.timeZone }
    var canGoOn: Bool { category != nil }
    var hasPhoto: Bool { photoAt != nil }
    var isSending: Bool { sendState == .sending }
    var isOffline: Bool { sendState == .offline || sendState == .waitingForConnection }

    /// "Found something in my food · Masala Sambar", or the meal for I feel unwell, as Review draws it.
    var subject: String {
        guard let category else { return "" }
        if let dish { return "\(category.title) · \(dish)" }
        if category == .unwell, let meal { return "\(category.title) · \(MLFormat.mealSlot(meal))" }
        return category.title
    }

    /// The place sent with the SOS. With no location, it says so; nothing is guessed.
    var place: String { location == .atMess ? context.mess.name : StudentSOSCopy.placeNotRecorded }

    /// The dishes of the meal the mess is in or about to start, for "Which dish? (optional)".
    func load() async {
        guard dishes.isEmpty, let status = try? await mealState.currentMeal(for: context.mess.id) else { return }
        meal = status.meal.slot
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = context.mess.timeZone
        let day = calendar.startOfDay(for: status.meal.startsAt)
        if let menu = try? await meals.mealMenu(on: day, slot: status.meal.slot, mess: context.mess.id) {
            var seen = Set<String>()
            dishes = ([menu.highlight].compactMap { $0 } + menu.mains + menu.curries + menu.slimRows)
                .map(\.name).filter { seen.insert($0).inserted }
        }
    }

    func choose(_ category: StudentSOSCategory) {
        self.category = category
    }

    func toggle(dish name: String) { dish = dish == name ? nil : name }

    /// The shutter: a live photo at the clock's time (a static preview in the simulator).
    func takePhoto() {
        photoAt = clock.now()
        withoutPhoto = false
    }

    /// Camera denied: "Send without photo". It goes flagged so the team asks for details.
    func continueWithoutPhoto() {
        photoAt = nil
        withoutPhoto = true
    }

    /// Checks the connection on Review, so the Offline state shows before the student taps.
    func checkConnection() async {
        guard sendState == .idle || sendState == .offline else { return }
        do {
            _ = try await sosRepository.activeCases(for: context.mess.id)
            if sendState == .offline { sendState = .idle }
        } catch RepositoryError.offline {
            sendState = .offline
        } catch {}
    }

    /// Raises the SOS. True only when the case is open; offline it waits and nothing is shown as sent.
    func send() async -> Bool {
        guard category != nil, sendState != .sending else { return false }
        let waiting = sendState == .offline || sendState == .waitingForConnection
        sendState = .sending
        let title = withoutPhoto ? "\(subject) · \(StudentSOSCopy.noPhotoTag)" : subject
        do {
            sos = try await sosRepository.raise(SOSReport(messID: context.mess.id, title: title, place: place,
                                                          idempotencyKey: key))
            sendState = .idle
            return true
        } catch RepositoryError.offline {
            sendState = waiting ? .waitingForConnection : .offline
            return false
        } catch {
            sendState = .failed
            return false
        }
    }

    /// "Send when online": kept until the app is back online, then sent with the same key.
    func sendWhenOnline() async -> Bool {
        sendState = .waitingForConnection
        return await send()
    }
}

/// Words of the SOS frames. Wording only.
enum StudentSOSCopy {
    static let title = "SOS"
    static let pickOne = "What's wrong? Pick one."
    static let whichDish = "Which dish? (optional)"
    static let next = "Next: take a photo"
    static let footnote = "A live photo and your location go with it. The food head and mess supervisor are told at once."
    static let noGPS = "No GPS · place not recorded"
    static let noGPSShort = "No GPS"
    static let placeNotRecorded = "Place not recorded"
    static let cameraOff = "Camera is off for MealLoop"
    static let cameraOffDetail = "MealLoop needs the camera for a live photo. Turn it on in Settings, or send without a photo."
    static let openSettings = "Open Settings"
    static let sendWithoutPhoto = "Send without photo"
    static let flagged = "It is sent flagged: the team will ask you for details."
    static let review = "Review SOS"
    static let checkProof = "Check the proof, then send."
    static let retake = "Retake photo"
    static let noPhoto = "No photo"
    static let cameraWasOff = "Camera was off · sent without photo"
    static let takenLive = "Taken live in the app"
    static func atPlace(_ place: String) -> String { "At \(place) (GPS)" }
    static let noGPSAsk = "No GPS · the team will ask where you are"
    static let noPhotoFlagged = "No photo · flagged for the team"
    static func timeRecorded(_ time: String) -> String { "Time recorded · \(time)" }
    static let sendSOS = "Send SOS"
    static let sending = "Sending…"
    static let tryAgain = "Try again"
    static let sendWhenOnline = "Send when online"
    static let offline = "You're offline. SOS sends the moment you're back. Tell the counter staff now."
    static let failed = "Couldn't send SOS. Try again, and tell the counter staff now."
    static let toldAtOnce = "The food head and mess supervisor are told at once. The photo and location go with it."
    static let photoAttached = "photo attached"
    static let noPhotoTag = "no photo"
    static func placeAndPhoto(_ place: String, photo: Bool) -> String { "\(place) · \(photo ? photoAttached : noPhoto.lowercased())" }
    static let back = "Back"
    static let close = "Close"
}
