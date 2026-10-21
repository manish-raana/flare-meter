import Foundation

/// Gets the shared reading for the menu bar and the widget, so both show the same numbers.
enum UsageRefresher {
    /// How many times the widget's refresh button has fetched; each one turns its arrow once.
    static var widgetRefreshCount: Int {
        get { UsageSettings.defaults?.integer(forKey: "widgetRefreshCount") ?? 0 }
        set { UsageSettings.defaults?.set(newValue, forKey: "widgetRefreshCount") }
    }

    struct Result {
        let snapshot: UsageSnapshot?
        /// Why fetching failed (`snapshot`, if any, is the last good one).
        let problem: String?
        /// A new reading was fetched (and saved).
        let fetched: Bool
    }

    /// The cached reading when it's younger than `maxAge` and for the current settings; otherwise a fresh one,
    /// saved for the other side. Pass 0 to always fetch.
    static func load(maxAge: TimeInterval) async -> Result {
        let settings = UsageSettings.load()
        guard settings.isComplete else { return Result(snapshot: nil, problem: nil, fetched: false) }
        let cached = SnapshotCache.load().flatMap { $0.source == settings.cacheKey ? $0 : nil }
        if let cached, Date().timeIntervalSince(cached.fetchedAt) < maxAge {
            return Result(snapshot: cached, problem: nil, fetched: false)
        }
        do {
            let snapshot = try await CloudflareClient(settings: settings).snapshot()
            SnapshotCache.save(snapshot)
            return Result(snapshot: snapshot, problem: nil, fetched: true)
        } catch {
            return Result(snapshot: cached, problem: error.localizedDescription, fetched: false)
        }
    }
}
