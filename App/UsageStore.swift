import AppKit
import Observation
import WidgetKit

/// The menu bar's reading: the same one the widget shows (`UsageRefresher`). Refreshed every 15 minutes, on wake,
/// when the panel opens with a stale one, and picked up at once when the widget fetches a newer one. Each new reading
/// goes past `UsageAlerts`.
@MainActor @Observable
final class UsageStore {
    private(set) var snapshot: UsageSnapshot? = SnapshotCache.load().flatMap { $0.source == UsageSettings.load().cacheKey ? $0 : nil }
    /// Why the latest refresh failed (`snapshot`, if any, is the last good one).
    private(set) var problem: String?
    private(set) var refreshing = false
    private(set) var settings = UsageSettings.load()
    /// Nil for the screenshot store.
    @ObservationIgnored private var alerts: UsageAlerts?

    /// Analytics lag a few minutes; every 15 minutes keeps well inside the API's rate limit.
    private static let interval: TimeInterval = 15 * 60
    /// Opening the panel or waking refreshes a reading older than this.
    private static let staleAfter: TimeInterval = 5 * 60

    @ObservationIgnored private var loop: Task<Void, Never>?

    init() {
        alerts = .shared
        loop = Task { [weak self] in
            while !Task.isCancelled {
                // A reading the widget fetched in the meantime counts.
                await self?.refresh(maxAge: Self.interval - 60)
                try? await Task.sleep(for: .seconds(Self.interval))
            }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { await self?.refreshIfStale() }
        }
        // The store lives as long as the app, so the unretained pointer stays valid.
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque(), { _, observer, _, _, _ in
            guard let observer else { return }
            let store = Unmanaged<UsageStore>.fromOpaque(observer).takeUnretainedValue()
            Task { @MainActor in store.adoptCache() }
        }, SnapshotCache.changedNotification as CFString, nil, .deliverImmediately)
    }

    #if DEBUG
    /// A store showing `snapshot` that never fetches (screenshots).
    init(preview snapshot: UsageSnapshot) {
        self.snapshot = snapshot
        self.settings = UsageSettings(accountID: String(repeating: "0", count: 32), apiToken: "preview", plan: snapshot.plan)
    }
    #endif

    /// After the settings were saved: show them, and fetch with them in the menu bar and widget.
    func settingsChanged() {
        settings = UsageSettings.load()
        WidgetCenter.shared.reloadAllTimelines()
        Task { await refresh() }
    }

    /// The fullest metric against its limit.
    var top: MetricValue? { snapshot?.ranked.first }
    var topFraction: Double? { snapshot.flatMap { s in top?.fraction(plan: s.plan) } }

    func refreshIfStale() async {
        await refresh(maxAge: Self.staleAfter)
    }

    /// Fetches unless the shared reading is younger than `maxAge` (0, the refresh button: always).
    func refresh(maxAge: TimeInterval = 0) async {
        guard !refreshing else { return }
        settings = UsageSettings.load()
        guard settings.isComplete else {
            problem = nil
            return
        }
        refreshing = true
        defer { refreshing = false }
        let result = await UsageRefresher.load(maxAge: maxAge)
        if let s = result.snapshot { show(s) }
        problem = result.problem
        // The widget then reloads from the reading just saved, without fetching.
        if result.fetched { WidgetCenter.shared.reloadAllTimelines() }
    }

    /// Shows the shared reading if it's newer than ours (the widget fetched it).
    private func adoptCache() {
        settings = UsageSettings.load()
        guard let cached = SnapshotCache.load(), cached.source == settings.cacheKey else { return }
        show(cached)
        problem = nil
    }

    /// Shows `s` if it's newer than the current reading, and checks it for alerts.
    private func show(_ s: UsageSnapshot) {
        guard s.fetchedAt > snapshot?.fetchedAt ?? .distantPast else { return }
        snapshot = s
        alerts?.check(s, accountID: settings.accountID)
    }
}
