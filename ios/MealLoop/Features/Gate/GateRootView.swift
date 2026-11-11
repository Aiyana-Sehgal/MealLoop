import SwiftUI

/// The Gate Security root: the gate home with every route on it, and no tab bar (GA-1). Only a Gate session reaches
/// the screens; any other session gets the plain placeholder.
struct GateRootView: View {
    let session: Session

    /// The one check for who may see the Gate screens.
    static func allows(_ session: Session) -> Bool { session.account.role == .gate }

    var body: some View {
        if Self.allows(session) {
            GateFlowView()
        } else {
            NotImplementedView(title: MLFormat.roleName(session.account.role))
        }
    }
}

struct GateFlowView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @Environment(SessionStore.self) private var sessionStore
    /// Lets a screenshot run start on a page with a model it prepared.
    var initialPath: [GateRoute] = []
    var preparedModel: GateModel?
    var initialCode = ""
    var initialSRMID = ""

    @State private var model: GateModel?
    @State private var path: [GateRoute] = []
    @State private var isEndingShift = false

    var body: some View {
        Group {
            if let model {
                NavigationStack(path: $path) {
                    GateHomeScreen(model: model, onOpen: { path.append($0) }, onEndShift: { isEndingShift = true })
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationDestination(for: GateRoute.self) { route in
                            destination(route, model: model)
                                .toolbar(.hidden, for: .navigationBar)
                        }
                }
            } else {
                ZStack {
                    OrbitBackground()
                    ProgressView()
                }
            }
        }
        .task {
            guard model == nil else { return }
            path = initialPath
            if let preparedModel {
                model = preparedModel
            } else {
                let made = GateModel(repository: OutingCaseRepositories.source(for: environment))
                model = made
                await made.load()
            }
        }
        .mlConfirmDialog(isPresented: $isEndingShift, content: GateCopy.endShiftDialog) {
            isEndingShift = false
            router.reset()
            sessionStore.signOut()
        }
    }

    private func go(_ attempt: GateAttempt, model: GateModel, replacing: Bool = false) {
        Task {
            guard let route = await model.run(attempt) else { return }
            if replacing, !path.isEmpty { path.removeLast() }
            path.append(route)
        }
    }

    /// Scan next: back to the scan page.
    private func scanNext() { path = [.scan] }

    @ViewBuilder
    private func destination(_ route: GateRoute, model: GateModel) -> some View {
        let back = { _ = path.popLast() }
        switch route {
        case .scan:
            GateScanScreen(model: model, onBack: back) { path.append(.passCode) }
        case .passCode:
            GatePassCodeScreen(model: model, initialCode: initialCode, onBack: back,
                               onFind: { path.append(.findStudent) }) { go(.code($0), model: model) }
        case .findStudent:
            GateFindStudentScreen(model: model, initialSRMID: initialSRMID, onBack: back) { go(.outing($0), model: model) }
        case .verify(let check):
            GateVerifyScreen(model: model, check: check, onConfirm: { attempt in go(attempt, model: model, replacing: true) },
                             onMismatch: { path.append(.report) })
        case .outcome(let outcome):
            GateOutcomeScreen(model: model, outcome: outcome, onScanNext: scanNext) { attempt in
                go(attempt, model: model, replacing: true)
            }
        case .outNow:
            GateOutListScreen(model: model, isOverdue: false, onBack: back) { go(.outing($0), model: model) }
        case .overdue:
            GateOutListScreen(model: model, isOverdue: true, onBack: back) { go(.outing($0), model: model) }
        case .report:
            GateReportScreen(model: model, onBack: back) { report in path.append(.reportSent(report)) }
        case .reportSent(let report):
            GateReportSentScreen(report: report) { path = [] }
        }
    }
}

// MARK: - Shared gate chrome

/// Back, a centred title, and the page under it (GA-4, GA-5, GA-7, GA-9).
struct GatePage<Content: View>: View {
    let title: String
    let onBack: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            OrbitBackground()
            VStack(alignment: .leading, spacing: MLSpacing.s16) {
                ZStack {
                    Text(title)
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.ink)
                        .accessibilityAddTraits(.isHeader)
                    HStack {
                        BackButton(action: onBack)
                        Spacer()
                    }
                }
                content
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.top, MLSpacing.s8)
            .padding(.bottom, MLSpacing.s16)
        }
    }
}

/// A tile on the gate home: an optional mono count, a title and a line (GA-1).
struct GateTile: View {
    var symbol: String?
    var count: Int?
    let title: String
    let detail: String
    var minHeight: CGFloat = 130
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                if let symbol {
                    Image(systemName: symbol).font(.system(size: 24)).foregroundStyle(MLColor.ink)
                        .padding(.bottom, MLSpacing.s8)
                }
                if let count {
                    Text("\(count)").font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(MLColor.ink)
                        .padding(.bottom, MLSpacing.s4)
                }
                Text(title).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                Text(detail).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                Spacer(minLength: 0)
            }
            .padding(MLSpacing.s16)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
            .contentShape(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Home (GA-1)

struct GateHomeScreen: View {
    let model: GateModel
    let onOpen: (GateRoute) -> Void
    let onEndShift: () -> Void

    var body: some View {
        ZStack {
            OrbitBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: MLSpacing.s12) {
                    ScreenTitleBlock(title: model.overview?.post.name ?? "—",
                                     subtitle: GateCopy.homeSubtitle(model.overview?.post.shiftName ?? "—"))
                        .padding(.bottom, MLSpacing.s8)
                    GateTile(symbol: "qrcode.viewfinder", title: GateCopy.scanPass, detail: GateCopy.scanPassDetail,
                             minHeight: 176) { onOpen(.scan) }
                    HStack(spacing: MLSpacing.s12) {
                        GateTile(count: model.overview?.typedCodesToday, title: GateCopy.cantScan,
                                 detail: GateCopy.typedCodesToday) { onOpen(.passCode) }
                        GateTile(count: model.overview?.outNow, title: GateCopy.outNow,
                                 detail: GateCopy.studentsOutNow) { onOpen(.outNow) }
                    }
                    GateTile(count: model.overview?.overdue, title: GateCopy.overdueReturns,
                             detail: GateCopy.overdueDetail) { onOpen(.overdue) }
                    DemoEntryRow()
                    Button(action: onEndShift) {
                        HStack(spacing: MLSpacing.s12) {
                            Image(systemName: "clock").font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(GateCopy.endShift).font(MLType.staffPrimary)
                                Text(shiftLine).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(MLColor.inkSecondary)
                        }
                        .foregroundStyle(MLColor.ink)
                        .padding(MLSpacing.s16)
                        .frame(minHeight: 72)
                        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    TextLinkButton(title: GateCopy.reportProblem) { onOpen(.report) }
                        .frame(maxWidth: .infinity)
                    if let failure = model.failure {
                        ErrorRetryView(failure: failure) { Task { await model.load() } }
                    }
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s24)
                .padding(.bottom, MLSpacing.s32)
            }
        }
        .task { await model.load() }
    }

    private var shiftLine: String {
        guard let post = model.overview?.post else { return "—" }
        return GateCopy.shiftStarted(post.shiftName, post.shiftStartedAt.map(OutingFormat.clock) ?? "—")
    }
}

// MARK: - Scan (GA-2)

/// The scan page. The simulator has no camera, so the viewfinder is a still frame; Can't scan? types the code.
struct GateScanScreen: View {
    let model: GateModel
    let onBack: () -> Void
    let onCantScan: () -> Void

    var body: some View {
        ZStack {
            MLColor.heroBackground.ignoresSafeArea()
            VStack(spacing: MLSpacing.s16) {
                ZStack {
                    Text(GateCopy.scanPass).font(MLType.staffPrimary).foregroundStyle(MLColor.onHero)
                    HStack {
                        BackButton(action: onBack).environment(\.colorScheme, .light)
                        Spacer()
                    }
                }
                VStack(spacing: MLSpacing.s16) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 44, weight: .light))
                    Text(GateCopy.pointAtPass).font(MLType.staffPrimary)
                }
                .foregroundStyle(MLColor.onHero)
                .frame(maxWidth: .infinity, minHeight: 360)
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(MLColor.onHero, lineWidth: 3))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(GateCopy.viewfinderLabel)
                HStack {
                    Label(GateCopy.torch, systemImage: "moon")
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.onHero)
                        .padding(.horizontal, MLSpacing.s20)
                        .frame(minHeight: MLSize.staffButton)
                        .overlay(Capsule().stroke(MLColor.onHero, lineWidth: 1.5))
                        .opacity(0.45)
                        .accessibilityHint("The torch needs a camera, which the prototype does not have.")
                    Spacer()
                    Text(GateCopy.outCount(model.overview?.outNow ?? 0))
                        .font(MLType.body)
                        .foregroundStyle(MLColor.onHeroSecondary)
                        .opacity(model.overview == nil ? 0 : 1)
                }
                Spacer()
                Button(action: onCantScan) {
                    Text(GateCopy.cantScan)
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.onHero)
                        .frame(maxWidth: .infinity, minHeight: MLSize.staffButton)
                        .overlay(Capsule().stroke(MLColor.onHero, lineWidth: 1.5))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, MLSpacing.margin)
            .padding(.top, MLSpacing.s8)
            .padding(.bottom, MLSpacing.s16)
        }
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Pass code (GA-4)

struct GatePassCodeScreen: View {
    let model: GateModel
    var initialCode = ""
    let onBack: () -> Void
    let onFind: () -> Void
    let onCheck: (String) -> Void

    @State private var code = ""
    @State private var showsLetters = false

    private let length = 4

    var body: some View {
        GatePage(title: GateCopy.typeCode, onBack: onBack) {
            Text(code.isEmpty ? " " : code)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(MLColor.ink)
                .padding(.horizontal, MLSpacing.s20)
                .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
                .overlay(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).stroke(MLColor.ink, lineWidth: 1.5))
                .accessibilityLabel("Pass code")
                .accessibilityValue(code.isEmpty ? "Empty" : code.map(String.init).joined(separator: " "))
            Text(GateCopy.codeHelp).font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            keys
            TextLinkButton(title: GateCopy.findBySRM, action: onFind)
            Spacer(minLength: 0)
            InkActionButton(title: GateCopy.checkCode, isLoading: model.isWorking) { onCheck(code) }
                .disabled(code.count != length)
        }
        .task { if code.isEmpty { code = initialCode } }
    }

    private var keys: some View {
        let rows: [[String]] = showsLetters
            ? [["A", "B", "C", "D", "E", "F"], ["G", "H", "J", "K", "L", "M"], ["N", "P", "Q", "R", "S", "T"],
               ["U", "V", "W", "X", "Y", "Z"]]
            : [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]]
        return VStack(spacing: MLSpacing.s8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: MLSpacing.s8) {
                    ForEach(row, id: \.self) { key in
                        keyButton(key, mono: true) { append(key) }
                    }
                }
            }
            HStack(spacing: MLSpacing.s8) {
                keyButton(showsLetters ? GateCopy.digits : GateCopy.letters, mono: false) { showsLetters.toggle() }
                if !showsLetters {
                    keyButton("0", mono: true) { append("0") }
                }
                Button {
                    if !code.isEmpty { code.removeLast() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(MLColor.ink)
                        .frame(maxWidth: .infinity, minHeight: showsLetters ? 48 : 56)
                        .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(GateCopy.delete)
            }
        }
    }

    private func keyButton(_ title: String, mono: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(mono ? .system(size: 26, weight: .semibold, design: .monospaced) : MLType.staffPrimary)
                .foregroundStyle(MLColor.ink)
                .frame(maxWidth: .infinity, minHeight: showsLetters ? 48 : 56)
                .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
        }
        .buttonStyle(.plain)
    }

    private func append(_ key: String) {
        guard code.count < length else { return }
        code.append(key)
    }
}

// MARK: - Find student (GA-5)

struct GateFindStudentScreen: View {
    let model: GateModel
    var initialSRMID = ""
    let onBack: () -> Void
    let onOpen: (OutingRequestID) -> Void

    @State private var srmID = ""

    var body: some View {
        GatePage(title: GateCopy.findStudent, onBack: onBack) {
            Text(GateCopy.findHelp(model.overview?.post.name ?? "—"))
                .font(MLType.body).foregroundStyle(MLColor.inkSecondary)
            VStack(alignment: .leading, spacing: MLSpacing.s4) {
                Text(GateCopy.srmID).font(MLType.meta).foregroundStyle(MLColor.inkSecondary)
                TextField("", text: $srmID)
                    .font(MLType.monoBody)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(.horizontal, MLSpacing.s16)
                    .frame(minHeight: 52)
                    .background(RoundedRectangle(cornerRadius: MLRadius.input, style: .continuous).fill(MLColor.surface))
                    .accessibilityLabel(GateCopy.srmID)
                    .onSubmit { Task { await model.find(srmID: srmID) } }
            }
            if let matches = model.matches {
                Text(GateCopy.matches(matches.count)).font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                ForEach(matches) { outing in
                    Button { onOpen(outing.id) } label: {
                        HStack(spacing: MLSpacing.s12) {
                            Image(systemName: "person.crop.circle").font(.system(size: 28, weight: .light))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(outing.student.displayName).font(MLType.staffPrimary)
                                Text(GateCopy.passValid(outing.student.block, window(outing)))
                                    .font(MLType.secondary).foregroundStyle(MLColor.inkSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(MLColor.ink)
                        .padding(MLSpacing.s16)
                        .background(RoundedRectangle(cornerRadius: MLRadius.compact, style: .continuous).fill(MLColor.surface))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
            Text(GateCopy.noMatch).font(MLType.body).foregroundStyle(MLColor.ink)
        }
        .task {
            if srmID.isEmpty, !initialSRMID.isEmpty {
                srmID = initialSRMID
                await model.find(srmID: initialSRMID)
            }
        }
        .onChange(of: srmID) { _, _ in model.clearMatches() }
    }

    private func window(_ outing: OutingCase) -> String {
        guard let leave = outing.leaveAt, let back = outing.returnBy else { return "—" }
        return OutingFormat.window(leave, back)
    }
}

// MARK: - Verify (GA-3)

struct GateVerifyScreen: View {
    let model: GateModel
    let check: GateCheck
    let onConfirm: (GateAttempt) -> Void
    let onMismatch: () -> Void

    var body: some View {
        if let (outing, isReturn) = parts {
            ZStack {
                OrbitBackground()
                VStack(alignment: .leading, spacing: MLSpacing.s16) {
                    Text(isReturn ? GateCopy.gateReturn(gate) : GateCopy.gateExit(gate))
                        .font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                        .frame(minHeight: MLSize.hit)
                    photo(outing)
                    Text(GateCopy.isThisTheStudent)
                        .font(MLType.staffPrimary).foregroundStyle(MLColor.ink)
                        .frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: MLSpacing.s12) {
                        ForEach(lines(outing, isReturn: isReturn), id: \.self) { line in
                            HStack(spacing: MLSpacing.s12) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(MLColor.ink)
                                    .frame(width: 26, height: 26)
                                    .background(Circle().fill(MLColor.lime))
                                    .overlay(Circle().stroke(MLColor.limeOutline, lineWidth: 1))
                                Text(line).font(MLType.staffBody).foregroundStyle(MLColor.ink)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(MLSpacing.s16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
                    Spacer(minLength: 0)
                    InkActionButton(title: isReturn ? GateCopy.yesRecordReturn : GateCopy.yesLetOut,
                                    isLoading: model.isWorking) {
                        onConfirm(isReturn ? .back(outing.id) : .exit(outing.id))
                    }
                    OutlineActionButton(title: GateCopy.doesntMatch, action: onMismatch)
                }
                .padding(.horizontal, MLSpacing.margin)
                .padding(.top, MLSpacing.s8)
                .padding(.bottom, MLSpacing.s16)
            }
        }
    }

    private var gate: String { model.overview?.post.name ?? "—" }

    private var parts: (OutingCase, Bool)? {
        switch check {
        case .exitReady(let outing): return (outing, false)
        case .returnReady(let outing): return (outing, true)
        default: return nil
        }
    }

    private func photo(_ outing: OutingCase) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.track)
            FacePlaceholder(tint: MLColor.border)
            Text(outing.student.displayName)
                .font(MLType.staffPrimary)
                .foregroundStyle(MLColor.onHero)
                .padding(.horizontal, MLSpacing.s20)
                .frame(minHeight: 44)
                .background(Capsule().fill(MLColor.ink))
                .padding(MLSpacing.s16)
        }
        .overlay(alignment: .topTrailing) {
            if let block = outing.student.block {
                Text(block)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.ink)
                    .padding(.horizontal, MLSpacing.s12)
                    .frame(minHeight: 32)
                    .background(Capsule().fill(MLColor.surface))
                    .padding(MLSpacing.s16)
            }
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Student photo not available in the prototype. \(outing.student.displayName)")
    }

    private func lines(_ outing: OutingCase, isReturn: Bool) -> [String] {
        if isReturn {
            let out = outing.exitAt.map { "\(OutingFormat.weekday($0)) \(OutingFormat.clock($0))" } ?? "—"
            let backBy = outing.returnBy.map(OutingFormat.hour) ?? "—"
            let now = model.now ?? .distantPast
            let back: String
            if let returnBy = outing.returnBy, now > returnBy {
                back = GateCopy.backByLate(backBy, OutingFormat.span(from: returnBy, to: now))
            } else {
                back = GateCopy.backByOnTime(backBy)
            }
            return [GateCopy.outSince(out), back, GateCopy.passMatches]
        }
        let window = outing.leaveAt.flatMap { leave in outing.returnBy.map { OutingFormat.window(leave, $0) } } ?? "—"
        return [GateCopy.passValidLeave(window), GateCopy.bothApproved, GateCopy.notUsedYet]
    }
}
