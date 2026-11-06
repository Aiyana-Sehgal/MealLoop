import SwiftUI

struct SupervisorWasteReportScreen: View {
    @Environment(AppEnvironment.self) private var environment
    let mealID: MealID
    let staff: StaffSession
    let onBack: () -> Void

    var body: some View {
        SupervisorWasteReportView(model: SupervisorWasteReportViewModel(mealID: mealID, session: staff,
                                                                        repositories: environment.repositories),
                                  onBack: onBack)
    }
}

/// Waste report, read only: S10 (recorded, details open), S10b (details closed), S10c (today's report as the
/// kitchen saved it), S11 / S11b (not recorded). No save, edit, approve, return or forward action exists here.
struct SupervisorWasteReportView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: SupervisorWasteReportViewModel
    @State private var showsDetails: Bool
    let onBack: () -> Void

    /// Report details start open, as S10 draws them; S10b is the same page after a tap on "Report details".
    init(model: SupervisorWasteReportViewModel, showsDetails: Bool = true, onBack: @escaping () -> Void) {
        _model = State(initialValue: model)
        _showsDetails = State(initialValue: showsDetails)
        self.onBack = onBack
    }

    private var timeZone: TimeZone { model.session.mess.timeZone }

    var body: some View {
        SupervisorPage(bottomInset: MLSpacing.s32) {
            SupervisorPageHeader(title: SupervisorCopy.wasteReportTitle, subtitle: model.state.value.map(subtitle),
                                 onBack: onBack)
            AsyncContentView(state: model.state, timeZone: timeZone, retry: { await model.load() }) { content in
                switch content.record.waste {
                case .recorded(let at):
                    recorded(at: at, report: content.report)
                case .notRecorded:
                    notRecorded(content.record)
                }
            }
        }
        .task(id: environment.dataRevision) {
            await model.load()
        }
    }

    /// "Lunch · Tue 13 Aug · Main Mess"
    private func subtitle(_ content: SupervisorWasteContent) -> String {
        "\(MLFormat.mealSlot(content.record.slot)) · \(SupervisorFormat.dayAndMonth(content.record.day, in: timeZone)) · \(content.mess.name)"
    }

    // MARK: Recorded (S10, S10b, S10c)

    @ViewBuilder
    private func recorded(at: Date?, report: WasteReport?) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SupervisorStatus(text: SupervisorCopy.recordedByKitchen, dot: .lime, time: at.map { MLFormat.time($0, in: timeZone) })
            if let report {
                HStack(spacing: MLSpacing.s12) {
                    tile(label: SupervisorCopy.unservedFood) {
                        HStack(alignment: .firstTextBaseline, spacing: MLSpacing.s4) {
                            Text("\(report.leftovers.count)").font(.system(size: 34, weight: .bold, design: .monospaced))
                            Text(SupervisorCopy.dishes(report.leftovers.count)).font(MLType.title2)
                        }
                    }
                    tile(label: SupervisorCopy.plateWaste) {
                        Text(plateWaste(report.plateWaste)).font(.system(size: 34, weight: .bold, design: .monospaced))
                    }
                }
                details(report)
                Text(SupervisorCopy.readOnlyKitchen)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, MLSpacing.s24)
            } else {
                // Recorded, but this record holds no quantities: say so, never show zeros.
                Text(SupervisorCopy.quantitiesMissing)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                Text(SupervisorCopy.readOnlyKitchen)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, MLSpacing.s24)
            }
        }
        .padding(.top, MLSpacing.s8)
    }

    private func tile<Value: View>(label: String, @ViewBuilder value: () -> Value) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s12) {
            Text(label)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
            value()
                .foregroundStyle(MLColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(MLSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
        .accessibilityElement(children: .combine)
    }

    private func details(_ report: WasteReport) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(MLColor.border).frame(height: 1)
            Button {
                showsDetails.toggle()
            } label: {
                HStack {
                    Text(SupervisorCopy.reportDetails)
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.ink)
                    Spacer()
                    Image(systemName: showsDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MLColor.inkSecondary)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: MLSize.staffButton)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(showsDetails ? "Expanded" : "Collapsed")
            if showsDetails {
                Text(SupervisorCopy.foodLeftOver)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                    .padding(.bottom, MLSpacing.s4)
                ForEach(report.leftovers) { row in
                    HStack(spacing: MLSpacing.s12) {
                        Text(row.dishName)
                            .font(MLType.staffBody)
                            .foregroundStyle(MLColor.ink)
                        Spacer(minLength: MLSpacing.s8)
                        leftover(row)
                    }
                    .frame(minHeight: MLSize.hit)
                    .accessibilityElement(children: .combine)
                }
                Rectangle().fill(MLColor.border).frame(height: 1).padding(.top, MLSpacing.s4)
                HStack {
                    Text(SupervisorCopy.plateWasteWholeMeal)
                        .font(MLType.staffPrimary)
                        .foregroundStyle(MLColor.ink)
                    Spacer(minLength: MLSpacing.s8)
                    Text(plateWaste(report.plateWaste))
                        .font(MLType.monoBody)
                        .foregroundStyle(MLColor.ink)
                }
                .frame(minHeight: MLSize.staffButton)
                .accessibilityElement(children: .combine)
            }
            Rectangle().fill(MLColor.border).frame(height: 1)
        }
    }

    /// Each dish in its own unit; a confirmed zero says "none left"; a dish not cooked says "not made".
    @ViewBuilder
    private func leftover(_ row: DishLeftover) -> some View {
        switch row.measurement {
        case .entered(let value):
            Text("\(SupervisorFormat.quantity(value)) \(SupervisorFormat.unit(row.unit))")
                .font(MLType.monoBody)
                .foregroundStyle(MLColor.ink)
        case .noneLeft:
            HStack(spacing: MLSpacing.s4) {
                Text("0 \(SupervisorFormat.unit(row.unit))").font(MLType.monoBody)
                Text("· \(SupervisorCopy.noneLeft)").font(MLType.staffBody)
            }
            .foregroundStyle(MLColor.ink)
        case .notMade:
            Text(SupervisorCopy.notMade)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
        case .notEntered:
            Text("—")
                .font(MLType.monoBody)
                .foregroundStyle(MLColor.inkSecondary)
                .accessibilityLabel("Not available")
        }
    }

    private func plateWaste(_ measurement: PlateWasteMeasurement) -> String {
        measurement.measuredKilograms.map { "\(SupervisorFormat.quantity($0)) \(WasteUnit.kilograms.symbol)" } ?? "—"
    }

    // MARK: Not recorded (S11, S11b)

    private func notRecorded(_ record: MealRecord) -> some View {
        VStack(alignment: .leading, spacing: MLSpacing.s16) {
            SupervisorStatus(text: SupervisorCopy.notRecorded, dot: .open)
            VStack(alignment: .leading, spacing: MLSpacing.s12) {
                Text(SupervisorCopy.finalEntries)
                    .font(MLType.body)
                    .foregroundStyle(MLColor.inkSecondary)
                if let value = record.finalEntries.value {
                    Text("\(value)").font(MLType.heroNumber).foregroundStyle(MLColor.ink)
                } else {
                    Text(SupervisorCopy.unavailable).font(MLType.heroTitle).foregroundStyle(MLColor.ink)
                }
            }
            .padding(MLSpacing.s20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: MLRadius.card, style: .continuous).fill(MLColor.surface))
            .accessibilityElement(children: .combine)
            Text(SupervisorCopy.notSavedYet)
                .font(MLType.body)
                .foregroundStyle(MLColor.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, MLSpacing.s24)
        }
        .padding(.top, MLSpacing.s8)
    }
}
