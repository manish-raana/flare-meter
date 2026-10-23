import SwiftUI

/// The menu bar icon: a cloud, and the fullest metric's percentage.
struct MenuBarLabel: View {
    let store: UsageStore
    @AppStorage("menuBarShowsPercent") private var showsPercent = true

    var body: some View {
        // No stack: MenuBarExtra takes the image and text from the label directly.
        let f = store.topFraction
        Image(systemName: (f ?? 0) >= 0.85 ? "exclamationmark.icloud.fill" : "cloud.fill")
        if showsPercent, let f { Text(Format.percent(f)) }
    }
}

/// The window that drops down from the menu bar icon.
struct MenuBarPanel: View {
    @Environment(UsageStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @Environment(\.rendersStatically) private var rendersStatically

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if !store.settings.isComplete {
                setup
            } else if let s = store.snapshot {
                content(s)
            } else if let problem = store.problem {
                Label(problem, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout).foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ProgressView().controlSize(.small).frame(maxWidth: .infinity, minHeight: 80)
            }
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 340)
        .onAppear { Task { await store.refreshIfStale() } }
    }

    // MARK: Sections

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 1) {
                Text("FlareMeter").font(.headline)
                if let s = store.snapshot, store.settings.isComplete {
                    Text(periodText(s)).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if store.settings.isComplete {
                if rendersStatically {
                    IconButton("arrow.clockwise", help: "Refresh now") {}
                } else {
                    Button { Task { await store.refresh() } } label: { SpinningRefreshGlyph(spinning: store.refreshing) }
                        .buttonStyle(.borderless)
                        .frame(width: 20, height: 20)
                        .help(store.refreshing ? "Refreshing…" : "Refresh now")
                }
            }
        }
    }

    private var setup: some View {
        VStack(spacing: 8) {
            Text("Connect your Cloudflare account").font(.callout.weight(.semibold))
            Text("Create a read-only token and paste it: two steps.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Connect…", action: showSettings).controlSize(.regular)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func content(_ s: UsageSnapshot) -> some View {
        let top = s.ranked.first
        let bars = Array(s.prominent.dropFirst())
        let shown = Set(([top].compactMap { $0 } + bars).map(\.id))
        let rest = s.quiet.filter { !shown.contains($0.id) }
        if let top {
            hero(top, plan: s.plan)
        }
        if !bars.isEmpty {
            VStack(spacing: 9) { ForEach(bars) { MetricRow(value: $0, plan: s.plan, fontSize: 12) } }
        }
        if !rest.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                SectionTitle("Under 1% of plan")
                CompactMetrics(values: rest, plan: s.plan, fontSize: 11)
            }
        }
        if let problem = store.problem {
            Label("Couldn't refresh: \(problem)", systemImage: "exclamationmark.triangle.fill")
                .font(.caption).foregroundStyle(.orange).lineLimit(2)
        }
    }

    private func hero(_ top: MetricValue, plan: Plan) -> some View {
        HStack(spacing: 14) {
            UsageRing(fraction: top.fraction(plan: plan) ?? 0, lineWidth: 7, fontSize: 17).frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 2) {
                SectionTitle("Fullest")
                Text(top.label).font(.system(size: 14, weight: .semibold))
                Text(top.amount(plan: plan, separator: " of ")).font(.system(size: 12).monospacedDigit()).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if let fetched = store.snapshot?.fetchedAt, store.settings.isComplete {
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    Text("Updated \(fetched.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)))")
                        .id(context.date)
                }
                .font(.caption).foregroundStyle(.secondary)
                if let s = store.snapshot { PlanStatus(snapshot: s).font(.caption) }
            }
            Spacer()
            IconButton("safari", help: "Open the Cloudflare dashboard") {
                NSWorkspace.shared.open(UsageSettings.dashboardURL(accountID: store.settings.accountID))
            }
            IconButton("gearshape", help: "Settings", action: showSettings)
            IconButton("power", help: "Quit FlareMeter") { NSApp.terminate(nil) }
        }
    }

    // MARK: Helpers

    private func showSettings() {
        openSettings()
        NSApp.activate()
    }

    /// "Today · resets in 5h 12m" (Free plan, daily caps reset 00:00 UTC) or "This month · about $7.40 bill" (Paid,
    /// with the plan's base fee).
    private func periodText(_ s: UsageSnapshot) -> String {
        guard s.plan == .free else {
            guard let bill = s.estimatedBillUSD else { return "This month so far" }
            return "This month · about \(bill.formatted(.currency(code: "USD"))) bill"
        }
        let now = Date()
        return "Today · resets in \(Format.duration(UTC.nextMidnight(after: now).timeIntervalSince(now)))"
    }
}

/// A borderless glyph button (a plain glyph when rendering screenshots).
private struct IconButton: View {
    @Environment(\.rendersStatically) private var rendersStatically
    let symbol: String
    let help: String
    let action: () -> Void

    init(_ symbol: String, help: String, action: @escaping () -> Void) {
        self.symbol = symbol
        self.help = help
        self.action = action
    }

    var body: some View {
        if rendersStatically {
            Image(systemName: symbol).foregroundStyle(.secondary).frame(width: 20, height: 20)
        } else {
            Button(action: action) { Image(systemName: symbol) }
                .buttonStyle(.borderless)
                .frame(width: 20, height: 20)
                .help(help)
        }
    }
}

/// The refresh arrow, turning while a refresh runs.
private struct SpinningRefreshGlyph: View {
    let spinning: Bool
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation(paused: !spinning)) { context in
            Image(systemName: "arrow.clockwise")
                .rotationEffect(.degrees(spinning ? context.date.timeIntervalSince(start) * 420 : 0))
        }
        .onChange(of: spinning) { if spinning { start = Date() } }
    }
}
