import AppIntents
import SwiftUI
import WidgetKit

struct UsageProvider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry(date: Date(), snapshot: .sample, problem: nil, accountID: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        if context.isPreview { completion(placeholder(in: context)); return }
        Task { completion(await load()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        Task {
            let entry = await load()
            // Analytics lag a few minutes; every 15 minutes keeps well inside the API's rate limit.
            completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60))))
        }
    }

    /// The shared reading: the menu bar app's (or the last refresh button's) when it's under 14 minutes old, so both
    /// show the same numbers; this fetches only when the menu bar app isn't running.
    private func load() async -> UsageEntry {
        let result = await UsageRefresher.load(maxAge: 14 * 60)
        return UsageEntry(date: Date(), snapshot: result.snapshot, problem: result.problem, accountID: UsageSettings.load().accountID,
                          refreshCount: UsageRefresher.widgetRefreshCount)
    }
}

/// The widget's refresh button: fetches now; WidgetKit then reloads the timeline, which shows the new reading.
struct RefreshUsageIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh FlareMeter"
    static var description = IntentDescription("Fetches the latest usage from Cloudflare.")

    func perform() async throws -> some IntentResult {
        if await UsageRefresher.load(maxAge: 0).fetched {
            UsageRefresher.widgetRefreshCount += 1
        }
        return .result()
    }
}

private struct RefreshButton: View {
    let turns: Int

    var body: some View {
        Button(intent: RefreshUsageIntent()) { RefreshGlyph(turns: turns) }
            .buttonStyle(.plain)
            .help("Refresh")
    }
}

@main
struct FlareMeterWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FlareMeter", provider: UsageProvider()) { entry in
            UsageWidgetView(entry: entry, refresh: AnyView(RefreshButton(turns: entry.refreshCount)))
        }
        .configurationDisplayName("FlareMeter")
        .description("Today's usage against your plan's limits.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
