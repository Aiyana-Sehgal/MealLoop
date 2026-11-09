import SwiftUI

// The Food Head's own-mess screens (single-mess scope). Same design language as the all-mess Admin: black hero cards,
// white grouped cards and hairline rows, filled with the data this mess has. Global totals are never shown as if they
// belonged to this mess.

enum AdminSingleMessCopy {
    static func answersFor(_ meal: String) -> String { "ANSWERS · \(meal.uppercased())" }
    static func answered(_ count: Int) -> String { "\(count) answered" }
    static let yes = "I'm in"
    static let no = "Skip"
    static let notSure = "Not sure"
    static let noReply = "No reply yet"
    static let feedback = "FEEDBACK"
    static let community = "COMMUNITY"
    static func students(_ count: Int) -> String { "\(count) \(count == 1 ? "student" : "students")" }
    static let noFeedback = "No feedback for this mess yet."
    static let noCommunity = "No community reports for this mess yet."
    static func stage(_ stage: CommunityStage) -> String {
        switch stage {
        case .raised: "Raised"
        case .owner: "Owner set"
        case .fixed: "Fixed"
        }
    }
    static let foodHead = "Food head"
    static let yourMess = "You see this mess only."
    static let planning = "PLANNING"
    static let account = "ACCOUNT"
    static let headcountPage = "Headcount"
    static let liveMeal = "Live meal"
}

/// The answers for the selected meal of this mess, from the same record the headcount page reads.
struct AdminAnswersCard: View {
    let mealName: String
    let answers: MealAnswerCounts

    private var answered: Int { answers.attending + answers.skipping + answers.notSure }
    private var total: Int { answered + answers.noResponse }

    var body: some View {
        HeroCard {
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                HeroEyebrow(label: AdminSingleMessCopy.answersFor(mealName))
                Text(AdminSingleMessCopy.answered(answered))
                    .font(AdminType.count)
                    .foregroundStyle(MLColor.onHero)
                    .mlNumericText(answered)
                VStack(spacing: MLSpacing.s8) {
                    bar(AdminSingleMessCopy.yes, answers.attending, lime: true)
                    bar(AdminSingleMessCopy.no, answers.skipping)
                    bar(AdminSingleMessCopy.notSure, answers.notSure)
                    bar(AdminSingleMessCopy.noReply, answers.noResponse)
                }
            }
        }
    }

    private func bar(_ label: String, _ value: Int, lime: Bool = false) -> some View {
        HStack(spacing: MLSpacing.s12) {
            Text(label).mlFont(.body).foregroundStyle(MLColor.onHeroSecondary).frame(width: 96, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(MLColor.onHero.opacity(0.15))
                    Capsule().fill(lime ? MLColor.lime : MLColor.onHero.opacity(0.7))
                        .frame(width: total > 0 ? proxy.size.width * CGFloat(value) / CGFloat(total) : 0)
                }
            }
            .frame(height: 8)
            .accessibilityHidden(true)
            Text("\(value)").font(MLType.monoBody).foregroundStyle(MLColor.onHero).frame(minWidth: 48, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

/// White grouped card of hairline rows, as on More.
struct AdminGroupCard<Rows: View>: View {
    @ViewBuilder let rows: Rows

    var body: some View {
        VStack(spacing: 0) { rows }
            .padding(.horizontal, MLSpacing.s16)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
    }
}

/// Students for the Food Head's mess: this meal's answers, then feedback and community for this mess.
struct AdminSingleMessStudentsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let nav: AdminNav
    @State private var today: AdminTodayViewModel?

    var body: some View {
        let students = environment.repositories.adminStudents
        AdminPageScaffold(title: AdminScreenCopy.studentsTitle, subtitle: nav.context.mess.name) {
            if let content = today?.state.value, let meal = content.meal {
                AdminAnswersCard(mealName: MLFormat.mealSlot(content.selectedSlot), answers: meal.answers)
            }
            AdminLoadedPage(model: AdminPageModel {
                guard let source = students as? any SingleMessStudentsRepository else {
                    throw RepositoryError.notImplemented(feature: "Students for this mess")
                }
                return try await source.singleMessStudents()
            }, timeZone: nav.timeZone) { value, _ in
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    VStack(alignment: .leading, spacing: MLSpacing.s8) {
                        AdminLabel(text: AdminSingleMessCopy.feedback)
                        if value.feedback.isEmpty {
                            Text(AdminSingleMessCopy.noFeedback).mlFont(.body).foregroundStyle(MLColor.inkSecondary)
                        } else {
                            AdminGroupCard {
                                ForEach(value.feedback) { item in
                                    AdminHubRow(title: "\(item.dish) · \(item.problem)",
                                                value: AdminSingleMessCopy.students(item.students),
                                                isLast: item.id == value.feedback.last?.id) { nav.push(.feedback(item.id)) }
                                }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: MLSpacing.s8) {
                        AdminLabel(text: AdminSingleMessCopy.community)
                        if value.community.isEmpty {
                            Text(AdminSingleMessCopy.noCommunity).mlFont(.body).foregroundStyle(MLColor.inkSecondary)
                        } else {
                            AdminGroupCard {
                                ForEach(value.community) { issue in
                                    AdminHubRow(title: issue.title, value: AdminSingleMessCopy.stage(issue.stage),
                                                isLast: issue.id == value.community.last?.id) { nav.push(.community(issue.id)) }
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            if today == nil {
                today = AdminTodayViewModel(context: nav.context, repositories: environment.repositories, clock: environment.clock)
            }
            await today?.load()
        }
    }
}

/// More for the Food Head: who and which mess, then planning and the account, as grouped cards.
struct AdminSingleMessMoreScreen: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    let nav: AdminNav

    var body: some View {
        AdminPageScaffold(title: AdminScreenCopy.moreTitle) {
            HeroCard {
                HStack(spacing: MLSpacing.s16) {
                    Text(AdminCopy.initials(nav.context.account.displayName))
                        .mlFont(.title2)
                        .foregroundStyle(MLColor.onLime)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(MLColor.lime))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nav.context.account.displayName).mlFont(.staffPrimary).foregroundStyle(MLColor.onHero)
                        Text("\(AdminSingleMessCopy.foodHead) · \(nav.context.mess.name)").mlFont(.body).foregroundStyle(MLColor.onHeroSecondary)
                        Text(AdminSingleMessCopy.yourMess).mlFont(.secondary).foregroundStyle(MLColor.onHeroSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
            AdminLabel(text: AdminSingleMessCopy.planning)
            AdminGroupCard {
                AdminHubRow(title: AdminScreenCopy.weeklyMenu) { nav.push(.weeklyMenu) }
                AdminHubRow(title: AdminScreenCopy.weeklyReport) { nav.push(.weeklyReport) }
                AdminHubRow(title: AdminScreenCopy.wednesdayPass) { nav.push(.passes) }
                AdminHubRow(title: AdminScreenCopy.announceToStudents, isLast: true) { nav.push(.announce) }
            }
            AdminLabel(text: AdminSingleMessCopy.account)
            AdminGroupCard {
                AdminHubRow(title: AdminScreenCopy.signOut, isLast: true) {
                    router.reset()
                    sessionStore.signOut()
                }
            }
        }
    }
}
