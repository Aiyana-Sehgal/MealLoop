#if DEMO_DATA || REVIEW_DATA
import Foundation
import CryptoKit

/// In-memory prototype credentials. This is not production password authentication.
/// Only salted digests and revocation state survive an operation, never readable passwords.
actor DemoPeopleStore {
    private enum Credential { case revoked; case temporary(salt: String, digest: SHA256.Digest) }
    private var accounts = DemoSeed.accounts
    private var credentials: [AccountID: Credential] = [:]
    private var events: [AccessAudit] = []

    // Names from the approved four-mess frame. IDs for additional prototype records are local only.
    static let messes = [DemoSeed.mess] + ["North", "South", "Annexe"].map {
        Mess(id: MessID("demo-\($0.lowercased())-mess"), name: $0 == "Annexe" ? $0 : "\($0) Mess", timeZoneIdentifier: "Asia/Kolkata")
    }
    private func require(_ session: Session) throws {
        guard session.account.role == .superAdmin,
              accounts.contains(where: { $0 == session.account }) else {
            throw RepositoryError.notAllowed(reason: "Only the Super Admin manages people and access.")
        }
    }
    private func index(_ id: AccountID) throws -> Int {
        guard let index = accounts.firstIndex(where: { $0.id == id }) else { throw RepositoryError.notFound }
        return index
    }
    private func person(_ account: Account) -> AccessPerson {
        let revoked: Bool
        if case .revoked? = credentials[account.id] { revoked = true } else { revoked = false }
        return AccessPerson(account: account, passwordRevoked: revoked)
    }
    private func record(_ action: AccessAudit.Action, person: AccountID, by session: Session, at date: Date) {
        events.append(AccessAudit(actor: session.account.id, person: person, action: action, at: date))
    }
    private func makePassword(_ account: Account) -> GivenPassword {
        let password = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let salt = UUID().uuidString
        credentials[account.id] = .temporary(salt: salt, digest: SHA256.hash(data: Data((salt + password).utf8)))
        return GivenPassword(person: person(account), value: password)
    }
    func authenticate(email: String, password: String) throws -> Account {
        guard let account = accounts.first(where: { $0.email.lowercased() == email }), account.role != .student else {
            throw RepositoryError.invalidCredentials
        }
        switch credentials[account.id] {
        case .revoked?: throw RepositoryError.invalidCredentials
        case .temporary(let salt, let digest)?:
            guard SHA256.hash(data: Data((salt + password).utf8)) == digest else { throw RepositoryError.invalidCredentials }
        case nil:
            guard password == DemoSeed.prototypePassword else { throw RepositoryError.invalidCredentials }
        }
        return account
    }
    func directory(by session: Session) throws -> AccessDirectory {
        try require(session)
        return AccessDirectory(people: accounts.filter { $0.role != .student && $0.role != .guardian }.map(person), messes: Self.messes)
    }
    func give(_ id: AccountID, by session: Session, at date: Date) throws -> GivenPassword {
        try require(session)
        let account = accounts[try index(id)]
        guard account.role != .student && account.role != .guardian else { throw RepositoryError.notAllowed(reason: "This account is outside People and access.") }
        let result = makePassword(account)
        record(.give, person: id, by: session, at: date)
        return result
    }
    func revoke(_ id: AccountID, by session: Session, at date: Date) throws {
        try require(session)
        let account = accounts[try index(id)]
        guard account.role != .admin && account.role != .superAdmin && account.role != .student && account.role != .guardian else {
            throw RepositoryError.notAllowed(reason: "This account's password can't be revoked here.")
        }
        if case .revoked? = credentials[id] { return }
        credentials[id] = .revoked
        record(.revoke, person: id, by: session, at: date)
    }
    func invite(name: String, contact: String, role: Role, mess: MessID, by session: Session, at date: Date) throws -> GivenPassword {
        try require(session)
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let contact = contact.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !name.isEmpty, !contact.isEmpty, Self.messes.contains(where: { $0.id == mess }),
              role != .student && role != .guardian && role != .superAdmin else {
            throw RepositoryError.validationFailed(["Enter a name, contact, role and mess."])
        }
        guard !accounts.contains(where: { $0.email.lowercased() == contact }) else {
            throw RepositoryError.validationFailed(["That contact already has an account."])
        }
        let account = Account(id: AccountID("invited-\(UUID().uuidString)"), displayName: name, email: contact, role: role, scope: .mess(mess))
        accounts.append(account)
        let result = makePassword(account)
        record(.invite, person: account.id, by: session, at: date)
        return result
    }
    func allot(_ id: AccountID, to mess: MessID, by session: Session, at date: Date) throws {
        try require(session)
        guard Self.messes.contains(where: { $0.id == mess }) else { throw RepositoryError.notFound }
        let i = try index(id)
        let old = accounts[i]
        guard old.role != .superAdmin && old.role != .student && old.role != .guardian else {
            throw RepositoryError.notAllowed(reason: "This account can't be allotted here.")
        }
        guard old.scope != .mess(mess) else { return }
        accounts[i] = Account(id: old.id, displayName: old.displayName, email: old.email, role: old.role, scope: .mess(mess))
        record(.allot, person: id, by: session, at: date)
    }
    func audit(by session: Session) throws -> [AccessAudit] { try require(session); return events }
}

extension DemoDataProvider: AdminDataOrigin {
    nonisolated var adminSourceMess: Mess { DemoSeed.mess }
}

struct DemoPeople: PeopleRepository {
    let core: DemoDataProvider
    let store: DemoPeopleStore
    func directory(by session: Session) async throws -> AccessDirectory {
        try await core.requireConnection(); return try await store.directory(by: session)
    }
    func givePassword(to person: AccountID, by session: Session) async throws -> GivenPassword {
        try await core.requireConnection(); return try await store.give(person, by: session, at: core.clock.now())
    }
    func revokePassword(of person: AccountID, by session: Session) async throws {
        try await core.requireConnection(); try await store.revoke(person, by: session, at: core.clock.now())
    }
    func invite(name: String, contact: String, role: Role, mess: MessID, by session: Session) async throws -> GivenPassword {
        try await core.requireConnection(); return try await store.invite(name: name, contact: contact, role: role, mess: mess, by: session, at: core.clock.now())
    }
    func allot(_ person: AccountID, to mess: MessID, by session: Session) async throws {
        try await core.requireConnection(); try await store.allot(person, to: mess, by: session, at: core.clock.now())
    }
    func audit(by session: Session) async throws -> [AccessAudit] { try await core.requireConnection(); return try await store.audit(by: session) }
}
#endif
