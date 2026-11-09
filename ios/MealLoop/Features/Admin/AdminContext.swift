import Foundation

/// The two Admin presentation roles and the account's assigned mess. Other roles cannot construct this context.
struct AdminContext: Equatable, Sendable {
    let account: Account
    let mess: Mess
    var allMesses: Bool { account.role == .superAdmin }
    var canManagePeople: Bool { allMesses }

    init?(session: Session) {
        guard session.account.role == .admin || session.account.role == .superAdmin,
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

/// Temporary registry of the four approved prototype mess names. Recognizing an assignment does not
/// imply that live meal data exists for it; repositories keep missing data unavailable.
private enum AdminMessLookup {
    static func mess(_ id: MessID) -> Mess? {
        #if DEMO_DATA || REVIEW_DATA
        return DemoPeopleStore.messes.first { $0.id == id }
        #else
        return nil
        #endif
    }
}
