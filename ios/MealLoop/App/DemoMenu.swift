import Observation

/// Whether the Demo sheet is open. It lives at the app root so the sheet survives a role switch. In Release nothing
/// opens it: the Demo entry button and the sheet are not compiled there.
@Observable
final class DemoMenu {
    var isPresented = false
}
