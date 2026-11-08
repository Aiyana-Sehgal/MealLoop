import SwiftUI

/// No global answer totals are presented as if they belonged to this mess.
struct AdminSingleMessStudentsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav
    var body: some View {
        let students = environment.repositories.adminStudents
        return AdminPageScaffold(title: "Students", subtitle: nav.context.mess.name) {
            Text("Meal-answer counts for this mess are unavailable.").font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            AdminLoadedPage(model: AdminPageModel {
                guard let source = students as? any SingleMessStudentsRepository else { throw RepositoryError.notImplemented(feature: "Students for this mess") }
                return try await source.singleMessStudents()
            }, timeZone: nav.timeZone) { value, _ in
                AdminLabel(text: "Feedback")
                ForEach(value.feedback) { item in
                    QuietRow(title: "\(item.dish) · \(item.problem)", value: "\(item.students)") { nav.push(.feedback(item.id)) }
                }
                AdminLabel(text: "Community")
                ForEach(value.community) { item in
                    QuietRow(title: item.title) { nav.push(.community(item.id)) }
                }
                if value.community.isEmpty { Text("No community reports for this mess in the current records.").font(MLType.body).foregroundStyle(MLColor.inkSecondary) }
            }
        }
    }
}

struct AdminSingleMessMoreScreen: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let nav: AdminNav
    var body: some View {
        AdminPageScaffold(title: "More", subtitle: nav.context.mess.name) {
            QuietRow(title: AdminScreenCopy.weeklyMenu) { nav.push(.weeklyMenu) }
            QuietRow(title: "Weekly report") { nav.push(.weeklyReport) }
            QuietRow(title: AdminScreenCopy.wednesdayPass) { nav.push(.passes) }
            QuietRow(title: AdminScreenCopy.announceToStudents) { nav.push(.announce) }
            QuietRow(title: AdminScreenCopy.signOut) { router.reset(); sessionStore.signOut() }
        }
    }
}
