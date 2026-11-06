import Foundation

/// Who is using the Admin app, and the mess they work in. It can only be made from a Food Head / Admin session,
/// so no other role can reach these screens even if something routed it here.
struct AdminContext: Equatable, Sendable {
    let account: Account
    let mess: Mess

    init?(session: Session) {
        guard session.account.role == .admin,
              case .mess(let messID) = session.account.scope,
              let mess = AdminMessLookup.mess(messID) else { return nil }
        self.account = session.account
        self.mess = mess
    }
}

extension Account {
    /// "Devi Raman" gives "Devi", as the packs write the Food Head.
    var firstName: String { displayName.split(separator: " ").first.map(String.init) ?? displayName }
}

/// TEMPORARY. `Session` gives an admin a `MessID` only, and no repository returns a `Mess`, so the name and the
/// time zone have no other source. This is the one place that reads them, and it goes when the shared-file owner
/// adds a source (docs/verification/admin-today/REPORT.md, "Shared changes needed"). A build without seeded data
/// finds nothing, so the role falls back to its Coming soon placeholder.
private enum AdminMessLookup {
    static func mess(_ id: MessID) -> Mess? {
        #if DEMO_DATA || REVIEW_DATA
        return id == DemoSeed.mess.id ? DemoSeed.mess : nil
        #else
        return nil
        #endif
    }
}
