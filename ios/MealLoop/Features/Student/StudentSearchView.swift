import SwiftUI

/// The round Search button's one function (owner ruling): find dishes of this week's menu by name.
struct StudentSearchScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let session: Session
    let onBack: () -> Void

    var body: some View {
        if let model = StudentSearchViewModel(session: session, repositories: environment.repositories),
           let meals = StudentMealsViewModel(session: session, repositories: environment.repositories, clock: environment.clock) {
            StudentSearchView(model: model, meals: meals, onBack: onBack)
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

/// Search · No results (430:80333), and the list of matches for a typed name.
struct StudentSearchView: View {
    @State private var model: StudentSearchViewModel
    @State private var meals: StudentMealsViewModel
    @State private var path: [StudentMealsRoute] = []
    @FocusState private var focused: Bool
    let onBack: () -> Void

    init(model: StudentSearchViewModel, meals: StudentMealsViewModel, onBack: @escaping () -> Void) {
        _model = State(initialValue: model)
        _meals = State(initialValue: meals)
        self.onBack = onBack
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                OrbitBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: MLSpacing.s16) {
                        MealsCompactHeader(title: MealsCopy.search, onBack: onBack)
                        field
                        results
                    }
                    .padding(.horizontal, MLSpacing.margin)
                    .padding(.top, MLSpacing.s8)
                    .padding(.bottom, StudentMetric.scrollBottom)
                }
                .scrollDismissesKeyboard(.interactively)
                StudentScrollFade()
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: StudentMealsRoute.self) { route in
                destination(route)
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .task(id: model.text) {
            // A short pause so each letter does not start a search of its own.
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await model.search()
        }
        .onAppear { focused = true }
    }

    @ViewBuilder
    private func destination(_ route: StudentMealsRoute) -> some View {
        switch route {
        case .dish(let dish, let day, let slot):
            StudentDishDetailView(load: { try await meals.dishDetail(dish, day: day, slot: slot) }, timeZone: model.timeZone,
                                  onRate: { path.append(.comingSoon(MealsCopy.rateDish)) }) { path.removeLast() }
        case .pass, .comingSoon:
            StudentComingSoonView(title: MealsCopy.rateDish) { path.removeLast() }
        }
    }

    private var field: some View {
        HStack(spacing: MLSpacing.s8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(MLColor.inkSecondary)
                .accessibilityHidden(true)
            TextField(MealsCopy.searchPrompt, text: $model.text)
                .font(StudentType.body)
                .foregroundStyle(MLColor.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($focused)
            if !model.text.isEmpty {
                Button { model.clear() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(MLColor.ink)
                        .frame(width: MLSize.hit, height: MLSize.hit)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(MealsCopy.clear)
            }
        }
        .padding(.leading, MLSpacing.s16)
        .frame(height: 44)
        .background(Capsule().fill(MLColor.fillQuiet))
    }

    @ViewBuilder
    private var results: some View {
        switch model.state {
        case .idle:
            Text(MealsCopy.searchHint)
                .font(StudentType.secondary)
                .foregroundStyle(MLColor.inkSecondary)
            suggestions
        case .loading:
            ProgressView().frame(maxWidth: .infinity).padding(.top, MLSpacing.s24)
        case .empty:
            noResults
        case .loaded(let found), .stale(let found, _), .offline(let found?, _):
            VStack(spacing: 0) {
                ForEach(Array(found.enumerated()), id: \.element.id) { index, match in
                    if index > 0 { Rectangle().fill(MLColor.border).frame(height: 1).padding(.leading, 52) }
                    resultRow(match)
                }
            }
            .background(RoundedRectangle(cornerRadius: StudentMetric.rowRadius, style: .continuous).fill(MLColor.surface))
        case .offline(nil, _):
            StudentOfflineBanner(text: MealsCopy.searchOffline)
        case .failed(let failure):
            MealsStateCard(symbol: "exclamationmark.circle", title: failure.message, detail: "")
        }
    }

    private func resultRow(_ match: StudentDishMatch) -> some View {
        Button {
            path.append(.dish(match.dish.id, day: match.day, slot: match.slot))
        } label: {
            HStack(spacing: MLSpacing.s12) {
                StudentDietMark(diet: match.dish.diet, onDark: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text(match.dish.name)
                        .font(StudentType.body)
                        .foregroundStyle(MLColor.ink)
                    Text("\(StudentFormat.mediumDay(match.day, in: model.timeZone)) · \(MLFormat.mealSlot(match.slot))")
                        .font(StudentType.footnote)
                        .foregroundStyle(MLColor.inkSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MLColor.inkSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, MLSpacing.s20)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var noResults: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            VStack(spacing: MLSpacing.s8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(MLColor.ink)
                    .frame(width: 64, height: 64)
                    .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.fillQuiet))
                    .padding(.bottom, MLSpacing.s8)
                    .accessibilityHidden(true)
                Text(MealsCopy.noResults(model.searchedText))
                    .font(StudentType.bodySemibold)
                    .foregroundStyle(MLColor.ink)
                    .multilineTextAlignment(.center)
                Text(MealsCopy.noResultsDetail)
                    .font(StudentType.secondary)
                    .foregroundStyle(MLColor.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, MLSpacing.s24)
            .padding(.vertical, MLSpacing.s32)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: StudentMetric.heroRadius, style: .continuous).fill(MLColor.surface))
            .accessibilityElement(children: .combine)
            suggestions
        }
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Text(MealsCopy.tryLabel)
                .font(StudentType.eyebrow)
                .tracking(1.2)
                .foregroundStyle(MLColor.inkSecondary)
            HStack(spacing: MLSpacing.s12) {
                ForEach(MealsCopy.searchSuggestions, id: \.self) { word in
                    Button { model.text = word } label: {
                        Text(word)
                            .font(StudentType.tag)
                            .foregroundStyle(MLColor.ink)
                            .padding(.horizontal, MLSpacing.s12)
                            .frame(height: 30)
                            .background(Capsule().fill(MLColor.fillQuiet))
                            .overlay(Capsule().strokeBorder(MLColor.ink, lineWidth: 1))
                            .frame(minHeight: MLSize.hit)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
