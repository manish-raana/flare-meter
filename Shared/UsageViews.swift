import SwiftUI

// Views shared by the widget and the menu bar panel, so both read the same.

extension EnvironmentValues {
    /// Drawing into an image (screenshots): controls are drawn as plain glyphs, since images can't hold them.
    @Entry var rendersStatically = false
}

/// Green under 60% of a limit, orange under 85%, red past that.
enum UsageTone {
    static func color(_ fraction: Double?) -> Color {
        guard let f = fraction else { return .secondary }
        if f >= 0.85 { return .red }
        if f >= 0.6 { return .orange }
        return .green
    }
}

extension MetricValue {
    /// "109k / 300k" (with a limit) or "329".
    func amount(plan: Plan, separator: String = " / ") -> String {
        let v = Format.number(value(plan: plan), unit: unit)
        guard let limit else { return v }
        return v + separator + Format.number(limit, unit: unit)
    }
}

extension UsageSnapshot {
    /// Metrics at 1% of their limit or more, fullest first: these get a bar.
    var prominent: [MetricValue] { ranked.filter { ($0.fraction(plan: plan) ?? 0) >= 0.01 } }

    /// Everything else that's in use: under 1% of a limit, or no limit at all (errors). Metrics at zero (products the
    /// account doesn't use) and ones Cloudflare didn't return are left out.
    var quiet: [MetricValue] {
        (ranked.filter { ($0.fraction(plan: plan) ?? 0) < 0.01 } + values.filter { $0.limit == nil })
            .filter { ($0.value(plan: plan) ?? 0) > 0 }
    }

    /// "Today" (Free, daily caps) or "This month" (Paid).
    var periodLabel: String { plan == .free ? "Today" : "This month" }

    /// The short form for tight spots: "Today" or the month, e.g. "Oct".
    var shortPeriodLabel: String {
        plan == .free ? "Today" : fetchedAt.formatted(.dateTime.month(.abbreviated))
    }
}

/// A capsule filled to `fraction` of a limit (capped at full).
struct UsageBar: View {
    let fraction: Double
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule().fill(UsageTone.color(fraction).gradient).frame(width: max(height, geo.size.width * min(1, fraction)))
            }
        }
        .frame(height: height)
    }
}

/// A ring filled to `fraction`, with the percentage inside.
struct UsageRing: View {
    let fraction: Double
    var lineWidth: CGFloat = 6
    var fontSize: CGFloat = 16

    var body: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.005, min(1, fraction)))
                .stroke(UsageTone.color(fraction).gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(Format.percent(fraction))
                .font(.system(size: fontSize, weight: .bold, design: .rounded).monospacedDigit())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(lineWidth)
        }
    }
}

/// Width of the percentage column, kept even on rows without a limit so the amounts line up.
private let percentColumn: CGFloat = 34

/// Label, amount and percentage on one line, with a bar under it when there's a limit.
struct MetricRow: View {
    let value: MetricValue
    let plan: Plan
    var fontSize: CGFloat = 11

    var body: some View {
        let f = value.fraction(plan: plan)
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value.label).lineLimit(1)
                Spacer(minLength: 4)
                Text(value.amount(plan: plan)).foregroundStyle(.secondary).monospacedDigit().lineLimit(1)
                Text(f.map { Format.percent($0) } ?? "")
                    .fontWeight(.semibold).monospacedDigit().foregroundStyle(UsageTone.color(f))
                    .frame(width: percentColumn, alignment: .trailing)
            }
            .font(.system(size: fontSize))
            if let f { UsageBar(fraction: f) }
        }
    }
}

/// Low-usage metrics in two columns of label and value, without bars.
struct CompactMetrics: View {
    let values: [MetricValue]
    let plan: Plan
    var fontSize: CGFloat = 10

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 4) {
            ForEach(Array(stride(from: 0, to: values.count, by: 2)), id: \.self) { i in
                GridRow {
                    cell(values[i])
                    if i + 1 < values.count { cell(values[i + 1]) } else { Color.clear.gridCellUnsizedAxes([.horizontal, .vertical]) }
                }
            }
        }
        .font(.system(size: fontSize))
    }

    private func cell(_ v: MetricValue) -> some View {
        HStack(spacing: 4) {
            Text(v.label).foregroundStyle(.secondary).lineLimit(1)
            Spacer(minLength: 2)
            Text(Format.number(v.value(plan: plan), unit: v.unit)).monospacedDigit().lineLimit(1)
                .foregroundStyle(v.id == "workerErrors" && (v.value(plan: plan) ?? 0) > 0 ? AnyShapeStyle(.orange) : AnyShapeStyle(.primary))
        }
        .frame(maxWidth: .infinity)
    }
}

/// "Within plan" with a check, or what's over: estimated charges (Paid) or a reached daily cap (Free).
struct PlanStatus: View {
    let snapshot: UsageSnapshot

    var body: some View {
        Group {
            if let usd = snapshot.estimatedOverageUSD, usd >= 0.005 {
                Label(usd.formatted(.currency(code: "USD")) + " over", systemImage: "dollarsign.circle.fill").foregroundStyle(.orange)
            } else if snapshot.plan == .free, (snapshot.ranked.first?.fraction(plan: .free) ?? 0) >= 1 {
                Label("Limit reached", systemImage: "exclamationmark.octagon.fill").foregroundStyle(.red)
            } else {
                Label("Within plan", systemImage: "checkmark.circle.fill").foregroundStyle(.secondary)
            }
        }
        .help(billText)
    }

    /// Paid: "Estimated bill this month: about $7.40, including the $5.00 Workers Paid subscription."
    private var billText: String {
        guard let bill = snapshot.estimatedBillUSD else { return "" }
        return "Estimated bill this month: about \(bill.formatted(.currency(code: "USD"))), including the "
            + "\(Metrics.paidBaseUSD.formatted(.currency(code: "USD"))) Workers Paid subscription."
    }
}

/// A small section title, e.g. "UNDER 1%".
struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased()).font(.system(size: 9, weight: .semibold)).foregroundStyle(.tertiary).tracking(0.4)
    }
}
