import SwiftUI

/// The Meal report for one meal (A04, F01). Written from the records: a missing value is shown as missing.
struct AdminMealReportScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let meal: MealID
    let nav: AdminNav

    var body: some View {
        let results = environment.repositories.adminResults
        AdminLoadedPage(model: AdminPageModel { [meal] in try await results.meal(meal) }, timeZone: nav.timeZone) { facts, model in
            AdminMealReportBody(facts: facts, nav: nav) { Task { await model.load() } }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

/// What the screen says about a meal, kept apart from the layout so tests can read it.
enum AdminMealReportContent {
    struct Line: Equatable, Identifiable {
        let text: String
        let isKnown: Bool

        var id: String { text }
    }

    static func lines(_ meal: AdminMealFacts, timeZone: TimeZone) -> [Line] {
        var lines: [Line] = []
        if let change = meal.headcountChange {
            lines.append(Line(text: AdminScreenCopy.raisedLine(from: change.from, to: change.to, reason: change.reason), isKnown: true))
        }
        if let came = meal.finalEntries, let sent = meal.headcountSent {
            lines.append(Line(text: AdminScreenCopy.cameLine(came: came, sent: sent), isKnown: true))
        } else if !meal.isClosed {
            lines.append(Line(text: AdminScreenCopy.notClosedYet, isKnown: false))
        }
        for food in meal.ranOut {
            let time = food.at.map { MLFormat.time($0, in: timeZone) } ?? AdminFormat.missing
            lines.append(Line(text: AdminScreenCopy.ranOutLine(food.dish, time, reported: nil), isKnown: true))
        }
        lines += meal.missing.map { Line(text: AdminScreenCopy.evidenceLine($0), isKnown: false) }
        lines += meal.openQuestions.map { Line(text: AdminScreenCopy.notRecorded($0), isKnown: false) }
        return lines
    }

    /// "-9%" on the ticket's arrow. It compares two counts; it is not a reason.
    static func difference(_ meal: AdminMealFacts) -> String? {
        guard let came = meal.finalEntries, let sent = meal.headcountSent, sent > 0 else { return nil }
        let percent = Int((Double(came - sent) / Double(sent) * 100).rounded())
        return percent > 0 ? "+\(percent)%" : "\(percent)%"
    }
}

struct AdminMealReportBody: View {
    let facts: AdminMealFacts
    let nav: AdminNav
    let reload: () -> Void

    @State private var isTellingVendor = false
    @State private var isMakingChange = false

    private var timeZone: TimeZone { nav.timeZone }

    var body: some View {
        AdminPageScaffold(title: AdminScreenCopy.mealReport,
                          subtitle: AdminScreenCopy.reportSubtitle(slot: MLFormat.mealSlot(facts.slot), mess: facts.mess,
                                                                   day: AdminFormat.day(facts.day, in: timeZone)),
                          onBack: nav.pop) {
            AdminMealTicket(meal: facts, timeZone: timeZone)
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                ForEach(AdminMealReportContent.lines(facts, timeZone: timeZone)) { line in
                    HStack(alignment: .top, spacing: MLSpacing.s12) {
                        Image(systemName: line.isKnown ? "checkmark.circle" : "circle.dashed")
                            .font(.system(size: 20))
                            .foregroundStyle(MLColor.ink)
                            .accessibilityHidden(true)
                        Text(line.text)
                            .font(MLType.body)
                            .foregroundStyle(MLColor.ink)
                    }
                }
            }
            if facts.isClosed {
                HStack(spacing: MLSpacing.s12) {
                    OutlineActionButton(title: AdminScreenCopy.tellTheVendor) { isTellingVendor = true }
                    InkActionButton(title: AdminScreenCopy.checkNextTime) {
                        if !facts.needsReview, let check = facts.linkedCheck {
                            nav.push(.check(check))
                        } else {
                            isMakingChange = true
                        }
                    }
                }
            }
        }
        .mlSheet(isPresented: $isTellingVendor) {
            AdminTellVendorSheet(subtitle: AdminScreenCopy.preparedMessage,
                                 message: AdminScreenCopy.vendorMessage(facts, today: AdminFormat.day(facts.day, in: timeZone),
                                                                        name: nav.context.account.firstName),
                                 note: nil) { isTellingVendor = false }
        }
        .mlSheet(isPresented: $isMakingChange) {
            AdminMakeChangeSheet(meal: facts.id, suggested: facts.suggestedChange ?? "", context: nav.context,
                                 onClose: { isMakingChange = false }) { check in
                isMakingChange = false
                reload()
                nav.push(.check(check.id))
            }
        }
    }
}

/// The ticket: lime band, headcount sent to came in, and what was left.
struct AdminMealTicket: View {
    let meal: AdminMealFacts
    let timeZone: TimeZone

    private let shape = RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(AdminScreenCopy.mealReport.uppercased())
                    .font(MLType.eyebrow)
                    .tracking(1)
                    .foregroundStyle(MLColor.onLime)
                Spacer()
                AdminChip(text: meal.needsReview ? AdminScreenCopy.needsReview : AdminScreenCopy.reviewed,
                          style: AdminChipRules.review(needsReview: meal.needsReview))
            }
            .padding(.horizontal, MLSpacing.s16)
            .padding(.vertical, MLSpacing.s12)
            .background(MLColor.lime)
            .overlay(alignment: .bottom) { Rectangle().fill(MLColor.ink).frame(height: 1.5) }

            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                counts
                HStack {
                    Text(meal.sentAt.map { AdminScreenCopy.sentAt(MLFormat.time($0, in: timeZone)) } ?? AdminFormat.missing)
                    Spacer()
                    Text(meal.closedAt.map { AdminScreenCopy.closedAt(MLFormat.time($0, in: timeZone)) } ?? AdminFormat.missing)
                }
                .font(MLType.body)
                .foregroundStyle(MLColor.ink)
                tear
                stats
                if !meal.missing.isEmpty {
                    AdminFlow {
                        ForEach(meal.missing, id: \.self) { item in
                            AdminFactChip(text: AdminScreenCopy.evidenceOnCard(item), isMissing: true)
                        }
                    }
                }
            }
            .padding(MLSpacing.s16)
        }
        .background(MLColor.surface)
        .clipShape(shape)
        .overlay(shape.stroke(MLColor.ink, lineWidth: 1.5))
    }

    /// The tear line, with a notch cut into each side of the ticket.
    private var tear: some View {
        HStack(spacing: MLSpacing.s8) {
            notch
            Line()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(MLColor.inkSecondary)
                .frame(height: 1)
            notch
        }
        .padding(.horizontal, -MLSpacing.s16 - 8)
    }

    private var notch: some View {
        Circle()
            .fill(MLColor.canvas)
            .overlay(Circle().stroke(MLColor.ink, lineWidth: 1.5))
            .frame(width: 16, height: 16)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }

    private var counts: some View {
        HStack(alignment: .center) {
            count(AdminFormat.count(meal.headcountSent), AdminScreenCopy.headcountSent, alignment: .leading)
            Spacer(minLength: MLSpacing.s4)
            VStack(spacing: MLSpacing.s4) {
                AdminCurvedArrow()
                if let difference = AdminMealReportContent.difference(meal) {
                    Text(difference)
                        .font(MLType.monoSecondary)
                        .foregroundStyle(MLColor.inkSecondary)
                }
            }
            Spacer(minLength: MLSpacing.s4)
            count(AdminFormat.count(meal.finalEntries), AdminScreenCopy.cameInFinal, alignment: .trailing)
        }
    }

    private func count(_ value: String, _ label: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: MLSpacing.s4) {
            Text(value)
                .font(MLType.heroNumber)
                .foregroundStyle(MLColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(MLType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var stats: some View {
        HStack(alignment: .top) {
            if let food = meal.leftovers.first {
                stat(AdminScreenCopy.left(food.dish), AdminFormat.amount(food))
            } else if let food = meal.ranOut.first {
                stat(AdminScreenCopy.ranOutAt(food.dish, "").trimmingCharacters(in: .whitespaces),
                     food.at.map { MLFormat.time($0, in: timeZone) } ?? AdminFormat.missing)
            } else {
                stat(AdminScreenCopy.leftOver, AdminFormat.missing)
            }
            Spacer()
            stat(AdminScreenCopy.plateWaste, meal.plateWasteKg.map { "\(AdminFormat.number($0)) kg" } ?? AdminFormat.missing)
            Spacer()
            stat(AdminScreenCopy.data, meal.dataCompletePercent.map { "\($0)%" } ?? AdminFormat.missing)
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s4) {
            Text(label)
                .font(MLType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
            Text(value)
                .font(MLType.monoBody)
                .foregroundStyle(MLColor.ink)
        }
        .accessibilityElement(children: .combine)
    }
}
