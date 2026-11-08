import SwiftUI
import Observation

/// Screen copy deliberately differs from older drawings: no delivery, sign-out or forced-change claim.
enum AdminAccessCopy {
    static let title = "People and access"
    static let allMesses = "All messes"
    static let invite = "Invite someone"
    static let give = "Give password"
    static let revoke = "Revoke password"
    static let shownOnce = "Shown once."
    static let cannotShowAgain = "After you close this, the password can't be shown again."
    static let revoked = "Revoked. They can't sign in until you give a new password."
    static let pastRecords = "Past records stay with the mess they were made in."
    static let roles: [Role] = [.admin, .supervisor, .kitchenStaff, .doorScanner, .passDesk, .warden, .gate, .vendor]
    static func personRole(_ role: Role) -> String {
        switch role {
        case .admin: return "Food head"
        case .supervisor: return "Mess supervisor"
        case .doorScanner: return "Door staff"
        case .passDesk: return "Pass desk staff"
        default: return MLFormat.roleName(role)
        }
    }
    static func title(_ role: Role) -> String {
        switch role {
        case .admin: return "Food heads"
        case .supervisor: return "Mess supervisors"
        case .kitchenStaff: return "Kitchen staff"
        case .doorScanner: return "Door staff"
        case .passDesk: return "Pass desk staff"
        case .warden: return "Wardens"
        case .gate: return "Gate security"
        case .vendor: return "Vendors"
        default: return MLFormat.roleName(role)
        }
    }
}

@MainActor @Observable
final class AdminAccessModel {
    private(set) var state: LoadState<AccessDirectory> = .idle
    private(set) var isWriting = false
    private(set) var errorText: String?
    private(set) var given: GivenPassword?
    let session: Session
    private let repository: any PeopleRepository
    init(session: Session, repository: any PeopleRepository) { self.session = session; self.repository = repository }
    var canAccess: Bool { session.account.role == .superAdmin }
    func load() async {
        guard canAccess else { state = .failed(LoadFailure(RepositoryError.notAllowed(reason: "Only the Super Admin manages people and access."))); return }
        if state.value == nil { state = .loading }
        do { state = .loaded(try await repository.directory(by: session)) }
        catch RepositoryError.offline(let date) { state = .offline(state.value, savedAt: date) }
        catch { state = .failed(LoadFailure(error)) }
    }
    func people(_ role: Role) -> [AccessPerson] { state.value?.people.filter { $0.account.role == role } ?? [] }
    func person(_ id: AccountID) -> AccessPerson? { state.value?.people.first { $0.id == id } }
    func messName(_ account: Account) -> String {
        guard case .mess(let id) = account.scope else { return "Mess unavailable" }
        return state.value?.messes.first { $0.id == id }?.name ?? "Mess unavailable"
    }
    func clearPassword() { given = nil }
    @discardableResult func give(_ id: AccountID) async -> Bool {
        await write { self.given = try await self.repository.givePassword(to: id, by: self.session) }
    }
    @discardableResult func revoke(_ id: AccountID) async -> Bool {
        await write { try await self.repository.revokePassword(of: id, by: self.session) }
    }
    @discardableResult func invite(name: String, contact: String, role: Role, mess: MessID) async -> Bool {
        await write { self.given = try await self.repository.invite(name: name, contact: contact, role: role, mess: mess, by: self.session) }
    }
    @discardableResult func allot(_ id: AccountID, mess: MessID) async -> Bool {
        await write { try await self.repository.allot(id, to: mess, by: self.session) }
    }
    private func write(_ action: () async throws -> Void) async -> Bool {
        guard canAccess, !isWriting else { return false }
        isWriting = true; errorText = nil
        defer { isWriting = false }
        do { try await action(); await load(); return true }
        catch { errorText = AdminWriteError.text(error); return false }
    }
}

struct AdminAccessScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav
    var role: Role?
    var personID: AccountID?
    var body: some View {
        AdminAccessView(model: AdminAccessModel(session: Session(account: nav.context.account, staff: nil),
                                                repository: environment.repositories.people), nav: nav, role: role, personID: personID)
    }
}

struct AdminAccessView: View {
    @State var model: AdminAccessModel
    let nav: AdminNav
    var role: Role?
    var personID: AccountID?
    @State private var sheet: AccessSheet?
    @State private var confirming = false
    @State private var name = ""
    @State private var contact = ""
    @State private var invitedRole: Role = .doorScanner
    @State private var selectedMess: MessID?
    init(model: AdminAccessModel, nav: AdminNav, role: Role? = nil, personID: AccountID? = nil,
         initialSheet: AccessSheet? = nil, initiallyConfirming: Bool = false) {
        _model = State(initialValue: model); self.nav = nav; self.role = role; self.personID = personID
        _sheet = State(initialValue: initialSheet); _confirming = State(initialValue: initiallyConfirming)
        if let personID, let person = model.person(personID), case .mess(let mess) = person.account.scope {
            _selectedMess = State(initialValue: mess)
        } else { _selectedMess = State(initialValue: model.state.value?.messes.first?.id) }
    }
    enum AccessSheet: String, Identifiable { case invite, password, allot; var id: String { rawValue } }

    var body: some View {
        AdminPageScaffold(title: title, subtitle: subtitle, onBack: nav.pop) {
            AsyncContentView(state: model.state, timeZone: nav.timeZone, retry: { await model.load() }) { directory in
                if let id = personID, let person = model.person(id) { personPage(person) }
                else if let role { rolePage(role) }
                else { rolesPage(directory) }
                if let error = model.errorText { FieldErrorText(text: error) }
            }
        }
        .task { await model.load() }
        .mlSheet(isPresented: Binding(get: { sheet != nil }, set: { visible in
            if !visible { sheet = nil; model.clearPassword(); Task { await model.load() } }
        })) {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    switch sheet ?? .invite {
                    case .invite: inviteSheet
                    case .password: passwordSheet
                    case .allot: allotSheet
                    }
                    if let error = model.errorText { FieldErrorText(text: error) }
                }

        }
        .overlay { if confirming, let id = personID, let person = model.person(id) { revokeDialog(person) } }
    }
    private var title: String {
        if let id = personID, let person = model.person(id) { return AdminAccessCopy.title(person.account.role) }
        return role.map(AdminAccessCopy.title) ?? AdminAccessCopy.title
    }
    private var subtitle: String {
        if let id = personID, let person = model.person(id) { return "\(person.account.displayName) · \(model.messName(person.account))" }
        if let role { let count = model.people(role).count; return "\(count) \(count == 1 ? "person" : "people") · all messes" }
        return AdminAccessCopy.allMesses
    }
    private func rolesPage(_ directory: AccessDirectory) -> some View {
        VStack(spacing: 0) {
            ForEach(AdminAccessCopy.roles) { role in
                accessRow(AdminAccessCopy.title(role), value: "\(model.people(role).count)") { nav.push(.peopleRole(role.rawValue)) }
            }
            InkActionButton(title: AdminAccessCopy.invite) { beginInvite(role: .doorScanner) }.padding(.top, MLSpacing.s16)
        }
    }
    private func rolePage(_ role: Role) -> some View {
        VStack(spacing: MLSpacing.s8) {
            ForEach(model.people(role)) { person in
                Button { nav.push(.accessPerson(person.id)) } label: {
                    HStack(spacing: MLSpacing.s12) {
                        Text(person.account.displayName.split(separator: " ").count == 1 ? String(person.account.displayName.prefix(2)).uppercased() : AdminCopy.initials(person.account.displayName)).font(MLType.bodyEmphasis)
                            .frame(width: MLSize.avatar, height: MLSize.avatar).background(Circle().fill(MLColor.surface))
                        VStack(alignment: .leading, spacing: MLSpacing.s4) {
                            Text(person.account.displayName).font(MLType.staffBody).foregroundStyle(MLColor.ink)
                            Text(model.messName(person.account)).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                        }
                        Spacer()
                        Text(person.passwordRevoked ? "Password revoked" : "● Password set")
                            .font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                    }.frame(minHeight: MLSize.hit).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
            if model.people(role).isEmpty { Text("No people in this role").font(MLType.body).foregroundStyle(MLColor.inkSecondary) }
            InkActionButton(title: "Add \(AdminAccessCopy.title(role).lowercased())") { beginInvite(role: role) }.padding(.top, MLSpacing.s16)
        }
    }
    private func personPage(_ person: AccessPerson) -> some View {
        VStack(spacing: MLSpacing.s16) {
            HeroCard {
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    Text("SIGN-IN").font(MLType.bodyEmphasis).foregroundStyle(MLColor.onHeroSecondary)
                    HStack {
                        Text(person.passwordRevoked ? "○ Password revoked" : "● Password set")
                            .font(MLType.bodyEmphasis).foregroundStyle(person.passwordRevoked ? MLColor.onHero : MLColor.onLime)
                            .padding(MLSpacing.s8).background(Capsule().fill(person.passwordRevoked ? MLColor.heroBackground : MLColor.lime))
                        Spacer()
                        Text(AdminAccessCopy.personRole(person.account.role)).font(MLType.body).foregroundStyle(MLColor.onHeroSecondary)
                    }
                    if person.passwordRevoked { LimeActionButton(title: AdminAccessCopy.give) { give(person.id) } }
                }
            }
            VStack(spacing: 0) {
                accessRow("Mess", detail: model.messName(person.account)) {
                    if case .mess(let mess) = person.account.scope { selectedMess = mess }
                    sheet = .allot
                }
                accessRow("Role", detail: AdminAccessCopy.personRole(person.account.role)) { nav.push(.peopleRole(person.account.role.rawValue)) }
                if !person.passwordRevoked { accessRow(AdminAccessCopy.give, detail: "Makes a temporary one. You see it once.") { give(person.id) } }
                if person.account.role != .admin && person.account.role != .superAdmin {
                    accessRow(AdminAccessCopy.revoke, detail: person.passwordRevoked ? "Already revoked" : "Blocks new sign-ins until you give a new password.", symbol: "exclamationmark.triangle") { confirming = true }
                        .disabled(!person.canRevoke || model.isWriting)
                }
                Text(person.passwordRevoked ? "\(person.account.displayName) can't sign in until you give a new password." : "Past records stay. Passwords can't be read back.")
                    .font(MLType.body).foregroundStyle(MLColor.inkSecondary).frame(maxWidth: .infinity, alignment: .leading).padding(.top, MLSpacing.s12)
            }
        }.disabled(model.isWriting)
    }
    private func accessRow(_ title: String, detail: String? = nil, value: String? = nil, symbol: String = "chevron.right", action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MLSpacing.s12) {
                VStack(alignment: .leading, spacing: MLSpacing.s4) {
                    Text(title).font(MLType.staffBody).foregroundStyle(MLColor.ink)
                    if let detail { Text(detail).font(MLType.body).foregroundStyle(MLColor.inkSecondary) }
                }
                Spacer()
                if let value { Text(value).font(MLType.monoBody).foregroundStyle(MLColor.inkSecondary) }
                Image(systemName: symbol).font(MLType.bodyEmphasis).foregroundStyle(MLColor.inkSecondary)
            }.padding(.vertical, MLSpacing.s12).frame(minHeight: MLSize.staffButton).contentShape(Rectangle())
        }.buttonStyle(.plain).overlay(alignment: .top) { Rectangle().fill(MLColor.border).frame(height: 1) }
    }
    private func beginInvite(role: Role) {
        invitedRole = role; name = ""; contact = ""; selectedMess = model.state.value?.messes.first?.id; model.clearPassword(); sheet = .invite
    }
    private func give(_ id: AccountID) { Task { if await model.give(id) { sheet = .password } } }
    private var passwordSheet: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: "Temporary password") { model.clearPassword(); sheet = nil }
            if let given = model.given {
                HeroCard {
                    VStack(spacing: MLSpacing.s16) {
                        Text("For \(given.person.account.displayName) · \(AdminAccessCopy.personRole(given.person.account.role)) · \(model.messName(given.person.account))")
                            .font(MLType.bodyEmphasis).foregroundStyle(MLColor.onHeroSecondary)
                        Text(given.value).font(MLType.largeTitle.monospaced()).foregroundStyle(MLColor.onHero).lineLimit(1).minimumScaleFactor(0.4).textSelection(.enabled)
                        Text(AdminAccessCopy.shownOnce).font(MLType.body).foregroundStyle(MLColor.onHeroSecondary)
                    }.frame(maxWidth: .infinity)
                }
                InkActionButton(title: "Copy password") { UIPasteboard.general.string = given.value }
            }
            OutlineActionButton(title: "Done") { model.clearPassword(); sheet = nil }
            Text(AdminAccessCopy.cannotShowAgain).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
        }
    }
    private var inviteSheet: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: AdminAccessCopy.invite) { sheet = nil }
            AdminTextField(placeholder: "Name", text: $name)
            AdminTextField(placeholder: "Phone or email", text: $contact).textInputAutocapitalization(.never).autocorrectionDisabled()
            Text("Role").font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            AdminFlow { ForEach(AdminAccessCopy.roles) { role in ChoiceChip(title: AdminAccessCopy.personRole(role), isSelected: role == invitedRole) { invitedRole = role } } }
            Text("Mess").font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            AdminFlow { ForEach(model.state.value?.messes ?? []) { mess in ChoiceChip(title: mess.name, isSelected: selectedMess == mess.id) { selectedMess = mess.id } } }
            Text(AdminAccessCopy.cannotShowAgain).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            InkActionButton(title: "Add person and give password") {
                guard let mess = selectedMess else { return }
                Task { if await model.invite(name: name, contact: contact, role: invitedRole, mess: mess) { sheet = .password } }
            }.disabled(model.isWriting || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || contact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedMess == nil)
        }
    }
    private var allotSheet: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SheetHeader(title: "Allot to a mess") { sheet = nil }
            if let id = personID, let person = model.person(id) {
                Text("\(person.account.displayName) · \(AdminAccessCopy.personRole(person.account.role))").font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                ForEach(model.state.value?.messes ?? []) { mess in
                    accessRow(mess.name, symbol: selectedMess == mess.id ? "checkmark.circle.fill" : "circle") { selectedMess = mess.id }
                }
                Text(AdminAccessCopy.pastRecords).font(MLType.body).foregroundStyle(MLColor.inkSecondary)
                InkActionButton(title: "Save allotment") {
                    guard let mess = selectedMess else { return }
                    Task { if await model.allot(id, mess: mess) { sheet = nil } }
                }.disabled(model.isWriting || selectedMess == nil || person.account.role == .superAdmin)
            }
        }
    }
    private func revokeDialog(_ person: AccessPerson) -> some View {
        ZStack {
            MLColor.ink.opacity(0.4).ignoresSafeArea()
            VStack(spacing: MLSpacing.s16) {
                Text("Revoke \(person.account.displayName)'s password?").font(MLType.title2).foregroundStyle(MLColor.ink)
                Text("They can't sign in until you give a new password. Their past records stay.").font(MLType.body).foregroundStyle(MLColor.inkSecondary).multilineTextAlignment(.center)
                HStack(spacing: MLSpacing.s12) {
                    OutlineActionButton(title: "Cancel") { confirming = false }
                    InkActionButton(title: AdminAccessCopy.revoke) {
                        Task { if await model.revoke(person.id) { confirming = false; nav.toast(AdminAccessCopy.revoked) } }
                    }
                }
                if let error = model.errorText { FieldErrorText(text: error) }
            }.padding(MLSpacing.s20).background(RoundedRectangle(cornerRadius: MLRadius.card).fill(MLColor.surface)).padding(MLSpacing.s24).disabled(model.isWriting)
        }.accessibilityAddTraits(.isModal)
    }
}
