import SwiftUI

/// People and access (A13). SIMULATED: an invite goes nowhere.
@MainActor
@Observable
final class AdminPeopleViewModel {
    private(set) var state: LoadState<AdminPeople> = .idle
    private(set) var errorText: String?

    private let more: any AdminMoreRepository
    private let role: Role

    init(more: any AdminMoreRepository, role: Role) {
        self.more = more
        self.role = role
    }

    func load() async {
        if state.value == nil {
            state = .loading
        }
        do {
            state = .loaded(try await more.people())
        } catch RepositoryError.offline(let savedAt) {
            state = .offline(state.value, savedAt: savedAt)
        } catch {
            state = .failed(LoadFailure(error))
        }
    }

    func invite(phone: String, role invited: String) async -> Bool {
        await write { [more, role] in try await more.invite(phone: phone, role: invited, by: role) }
    }

    func saveVendor(_ contact: VendorContact) async -> Bool {
        await write { [more, role] in try await more.saveVendorContact(contact, by: role) }
    }

    private func write(_ work: () async throws -> AdminPeople) async -> Bool {
        errorText = nil
        do {
            state = .loaded(try await work())
            return true
        } catch {
            errorText = AdminWriteError.text(error)
            return false
        }
    }
}

struct AdminPeopleScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav

    var body: some View {
        AdminPeopleView(model: AdminPeopleViewModel(more: environment.repositories.adminMore, role: nav.context.account.role), nav: nav)
    }
}

struct AdminPeopleView: View {
    @State private var model: AdminPeopleViewModel
    let nav: AdminNav

    @State private var isInviting = false
    @State private var isEditingVendor = false
    @State private var phone = ""
    @State private var inviteRole = AdminPeopleChoices.roles.first ?? ""
    @State private var vendorPhone = ""
    @State private var channel: VendorChannel = .message

    init(model: AdminPeopleViewModel, nav: AdminNav) {
        _model = State(initialValue: model)
        self.nav = nav
    }

    var body: some View {
        AdminPageScaffold(title: AdminScreenCopy.peopleAndAccess, subtitle: AdminScreenCopy.whoCanDoWhat, onBack: nav.pop) {
            AsyncContentView(state: model.state, timeZone: nav.timeZone, retry: { await model.load() }) { people in
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    VStack(alignment: .leading, spacing: 0) {
                        AdminLabel(text: AdminScreenCopy.roles)
                            .padding(.bottom, MLSpacing.s8)
                        ForEach(people.roles) { role in
                            QuietRow(title: role.title, value: "\(role.count)") { nav.push(.peopleRole(role.id)) }
                        }
                    }
                    vendorCard(people.vendor)
                    InkActionButton(title: AdminScreenCopy.inviteSomeone) { isInviting = true }
                }
            }
        }
        .task { await model.load() }
        .mlSheet(isPresented: $isInviting) { inviteSheet }
        .mlSheet(isPresented: $isEditingVendor) { vendorSheet }
    }

    private func vendorCard(_ vendor: VendorContact) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s8) {
            HStack {
                Text(AdminScreenCopy.vendorContact)
                    .font(MLType.staffPrimary)
                    .foregroundStyle(MLColor.ink)
                Spacer()
                TextLinkButton(title: AdminScreenCopy.edit) {
                    vendorPhone = vendor.phone
                    channel = vendor.channel
                    isEditingVendor = true
                }
            }
            Text(vendor.channel == .message ? AdminScreenCopy.headcountByMessage : AdminScreenCopy.headcountByCall)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            Text(vendor.phone)
                .font(MLType.monoBody)
                .foregroundStyle(MLColor.ink)
        }
        .padding(MLSpacing.s16)
        .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous)
            .stroke(MLColor.ink, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
    }

    private var inviteSheet: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: AdminScreenCopy.inviteSomeone) { isInviting = false }
            AdminLabel(text: AdminScreenCopy.phoneNumber)
            AdminTextField(placeholder: AdminScreenCopy.phonePrefix, text: $phone)
                .keyboardType(.phonePad)
            AdminLabel(text: AdminScreenCopy.role)
            AdminFlow {
                ForEach(AdminPeopleChoices.roles, id: \.self) { role in
                    ChoiceChip(title: role, isSelected: inviteRole == role) { inviteRole = role }
                }
            }
            if let error = model.errorText {
                FieldErrorText(text: error)
            }
            InkActionButton(title: AdminScreenCopy.sendInvite) {
                Task {
                    if await model.invite(phone: phone, role: inviteRole) {
                        isInviting = false
                        phone = ""
                        nav.toast(AdminScreenCopy.inviteSent)
                    }
                }
            }
        }
    }

    private var vendorSheet: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            SheetHeader(title: AdminScreenCopy.vendorContact, subtitle: AdminScreenCopy.vendorSheetDetail) { isEditingVendor = false }
            AdminLabel(text: AdminScreenCopy.phoneNumber)
            AdminTextField(placeholder: AdminScreenCopy.phonePrefix, text: $vendorPhone)
            AdminLabel(text: AdminScreenCopy.sendHeadcountsBy)
            HStack(spacing: MLSpacing.s8) {
                ChoiceChip(title: AdminScreenCopy.message, isSelected: channel == .message) { channel = .message }
                ChoiceChip(title: AdminScreenCopy.call, isSelected: channel == .call) { channel = .call }
            }
            if let error = model.errorText {
                FieldErrorText(text: error)
            }
            InkActionButton(title: AdminScreenCopy.save) {
                Task {
                    if await model.saveVendor(VendorContact(phone: vendorPhone, channel: channel)) {
                        isEditingVendor = false
                        nav.toast(AdminScreenCopy.vendorSaved)
                    }
                }
            }
        }
    }
}

/// The roles a Food Head can invite (A13_people_invite_sheet). These are product roles, not sample data.
enum AdminPeopleChoices {
    static let roles = ["Door staff", "Kitchen staff", "Mess supervisor", "Food head"]
}

/// One role (A13_people_kitchen_staff). The pack writes out Kitchen staff only.
struct AdminRoleScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let id: String
    let nav: AdminNav

    var body: some View {
        let more = environment.repositories.adminMore
        AdminLoadedPage(model: AdminPageModel { try await more.people() }, timeZone: nav.timeZone) { people, _ in
            if let role = people.roles.first(where: { $0.id == id }) {
                AdminPageScaffold(title: role.title, subtitle: AdminScreenCopy.peopleCount(role.count, messes: role.messes), onBack: nav.pop) {
                    if let permissions = role.permissions {
                        Text(permissions)
                            .font(MLType.body)
                            .foregroundStyle(MLColor.inkSecondary)
                    }
                    VStack(spacing: 0) {
                        ForEach(role.named) { person in
                            AdminRow(title: person.name, detail: person.detail, action: nil) { EmptyView() }
                        }
                        AdminRow(title: AdminScreenCopy.morePeople(role.count - role.named.count), detail: AdminScreenCopy.namesOnList, action: nil) { EmptyView() }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
