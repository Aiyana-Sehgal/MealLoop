import Foundation

/// Public directory entries never contain a password, verifier or token.
struct AccessPerson: Identifiable, Sendable, Equatable {
    let account: Account
    let passwordRevoked: Bool
    var id: AccountID { account.id }
    var canRevoke: Bool { account.role != .admin && account.role != .superAdmin && !passwordRevoked }
}

/// Not Codable: a transient result consumed only by the one-time sheet.
struct GivenPassword: Sendable {
    let person: AccessPerson
    let value: String
}

struct AccessDirectory: Sendable {
    let people: [AccessPerson]
    let messes: [Mess]
}

struct AccessAudit: Sendable, Equatable {
    enum Action: Sendable { case give, revoke, invite, allot }
    let actor: AccountID
    let person: AccountID
    let action: Action
    let at: Date
}

protocol PeopleRepository: Sendable {
    func directory(by session: Session) async throws -> AccessDirectory
    func givePassword(to person: AccountID, by session: Session) async throws -> GivenPassword
    func revokePassword(of person: AccountID, by session: Session) async throws
    func invite(name: String, contact: String, role: Role, mess: MessID, by session: Session) async throws -> GivenPassword
    func allot(_ person: AccountID, to mess: MessID, by session: Session) async throws
    func audit(by session: Session) async throws -> [AccessAudit]
}

struct UnavailablePeople: PeopleRepository {
    private var missing: RepositoryError { .notImplemented(feature: "People and access") }
    func directory(by session: Session) async throws -> AccessDirectory { throw missing }
    func givePassword(to person: AccountID, by session: Session) async throws -> GivenPassword { throw missing }
    func revokePassword(of person: AccountID, by session: Session) async throws { throw missing }
    func invite(name: String, contact: String, role: Role, mess: MessID, by session: Session) async throws -> GivenPassword { throw missing }
    func allot(_ person: AccountID, to mess: MessID, by session: Session) async throws { throw missing }
    func audit(by session: Session) async throws -> [AccessAudit] { throw missing }
}
