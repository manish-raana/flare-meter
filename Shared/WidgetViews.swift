import SwiftUI
import WidgetKit

// The widget's views, shared with the app so it can render them (App Store screenshots and the website).

struct UsageEntry: TimelineEntry {
    let date: Date
    let snapshot: UsageSnapshot?
    /// Why the latest refresh failed (the snapshot, if any, is the last good one).
    let problem: String?
    let accountID: String
    /// `UsageRefresher.widgetRefreshCount` when the entry was made: a change turns the refresh arrow.
    var refreshCount = 0
}

// MARK: - Views

/// The refresh arrow, as the widget's button shows it. Widgets can't animate continuously, so it turns once each time
/// `turns` goes up (WidgetKit animates the change between two entries).
struct RefreshGlyph: View {
    var turns = 0

    var body: some View {
        Image(systemName: "arrow.clockwise").font(.system(size: 10, weight: .semibold))
            .rotationEffect(.degrees(Double(turns) * 360))
            .animation(.smooth(duration: 0.9), value: turns)
            .frame(width: 18, height: 18)
            .contentShape(Rectangle())
            .foregroundStyle(.secondary)
    }
}

private struct Header: View {
    let entry: UsageEntry
    let refresh: AnyView
    /// Small: the update time on the right instead of a footer.
    var compact = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "cloud.fill").foregroundStyle(.orange).font(.system(size: 12))
            Text(compact ? (entry.snapshot?.shortPeriodLabel ?? "FlareMeter") : "FlareMeter")
                .font(.system(size: 12, weight: .semibold)).lineLimit(1)
            Spacer(minLength: 4)
            if entry.problem != nil {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange).font(.system(size: 9))
            }
            if let s = entry.snapshot {
                Text(compact ? s.fetchedAt.formatted(date: .omitted, time: .shortened) : s.periodLabel)
                    .font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
            }
            if entry.snapshot != nil { refresh.padding(.trailing, -4) }
        }
    }
}

private struct Footer: View {
    let snapshot: UsageSnapshot
    let problem: String?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: problem == nil ? "clock" : "exclamationmark.triangle.fill")
                .foregroundStyle(problem == nil ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.orange))
            Text(snapshot.fetchedAt, style: .time)
            Spacer(minLength: 4)
            PlanStatus(snapshot: snapshot)
        }
        .font(.system(size: 10))
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}

/// The fullest metric: ring, name, and amount of limit.
private struct Hero: View {
    let value: MetricValue
    let plan: Plan
    var ring: CGFloat = 58

    var body: some View {
        let f = value.fraction(plan: plan) ?? 0
        HStack(spacing: 12) {
            UsageRing(fraction: f, lineWidth: ring / 9, fontSize: ring * 0.27).frame(width: ring, height: ring)
            VStack(alignment: .leading, spacing: 2) {
                SectionTitle("Fullest")
                Text(value.label).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                Text(value.amount(plan: plan, separator: " of ")).font(.system(size: 11).monospacedDigit()).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct SetupView: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "cloud.fill").font(.title2).foregroundStyle(.orange)
            Text("FlareMeter").font(.system(size: 12, weight: .semibold))
            Text(message).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct UsageWidgetView: View {
    @Environment(\.widgetFamily) private var environmentFamily
    let entry: UsageEntry
    /// The widget's refresh button (an App Intent, so it lives in the widget target); a plain glyph elsewhere.
    var refresh: AnyView = AnyView(RefreshGlyph())
    /// Set when rendering outside WidgetKit.
    var familyOverride: WidgetFamily? = nil

    private var family: WidgetFamily { familyOverride ?? environmentFamily }

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                // While the refresh button's fetch runs, macOS shows these as pending.
                content(snapshot).invalidatableContent()
            } else {
                SetupView(message: entry.problem ?? "Click the cloud in the menu bar → Connect to add your account.")
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(UsageSettings.dashboardURL(accountID: entry.accountID))
    }

    @ViewBuilder
    private func content(_ s: UsageSnapshot) -> some View {
        let top = s.ranked.first
        switch family {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 0) {
                Header(entry: entry, refresh: refresh, compact: true)
                Spacer(minLength: 6)
                if let top {
                    UsageRing(fraction: top.fraction(plan: s.plan) ?? 0, lineWidth: 7, fontSize: 19).frame(width: 66, height: 66)
                    Spacer(minLength: 6)
                    Text(top.label).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                    Text(top.amount(plan: s.plan, separator: " of ")).font(.system(size: 10).monospacedDigit()).foregroundStyle(.secondary).lineLimit(1)
                } else {
                    Text("No limits measured").font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .systemMedium:
            VStack(alignment: .leading, spacing: 8) {
                Header(entry: entry, refresh: refresh)
                HStack(alignment: .center, spacing: 14) {
                    if let top {
                        VStack(alignment: .leading, spacing: 4) {
                            UsageRing(fraction: top.fraction(plan: s.plan) ?? 0, lineWidth: 6, fontSize: 15).frame(width: 54, height: 54)
                            Text(top.label).font(.system(size: 11, weight: .semibold)).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(width: 92, alignment: .leading)
                    }
                    VStack(spacing: 7) {
                        ForEach(s.ranked.dropFirst().prefix(3)) { MetricRow(value: $0, plan: s.plan) }
                    }
                }
                Spacer(minLength: 0)
                Footer(snapshot: s, problem: entry.problem)
            }
        default:
            // Four bars fill the large size; the rest go in the compact grid.
            let bars = Array(s.ranked.dropFirst().prefix(4))
            let shown = Set(([top].compactMap { $0 } + bars).map(\.id))
            VStack(alignment: .leading, spacing: 10) {
                Header(entry: entry, refresh: refresh)
                if let top { Hero(value: top, plan: s.plan) }
                if !bars.isEmpty {
                    VStack(spacing: 7) { ForEach(bars) { MetricRow(value: $0, plan: s.plan) } }
                }
                let rest = s.quiet.filter { !shown.contains($0.id) }
                if !rest.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        SectionTitle("Under 1% of plan")
                        CompactMetrics(values: rest, plan: s.plan)
                    }
                }
                Spacer(minLength: 0)
                Footer(snapshot: s, problem: entry.problem)
            }
        }
    }
}

extension UsageSnapshot {
    /// Gallery preview and placeholder.
    static let sample: UsageSnapshot = {
        func v(_ id: String, _ label: String, _ month: Double, _ limit: Double?, _ unit: String = "count") -> MetricValue {
            MetricValue(id: id, label: label, today: nil, month: month, error: nil, limit: limit, unit: unit)
        }
        return UsageSnapshot(
            fetchedAt: Date(),
            plan: .paid,
            values: [
                v("workerRequests", "Worker requests", 68_000, 10_000_000),
                v("workerErrors", "Worker errors", 329, nil),
                v("doRequests", "DO requests", 97_000, 1_000_000),
                v("doRowsRead", "DO rows read", 33_700_000, 25_000_000_000),
                v("doRowsWritten", "DO rows written", 158_000, 50_000_000),
                v("doStorage", "DO storage", 0, 5_000_000_000, "bytes"),
                v("kvReads", "KV reads", 42_000, 10_000_000),
                v("kvWrites", "KV writes", 467, 1_000_000),
                v("d1RowsRead", "D1 rows read", 1_200_000, 25_000_000_000),
                v("d1RowsWritten", "D1 rows written", 786, 50_000_000),
                v("aiNeurons", "Workers AI neurons", 109_000, 300_000, "neurons"),
            ],
            estimatedOverageUSD: 0
        )
    }()
}
