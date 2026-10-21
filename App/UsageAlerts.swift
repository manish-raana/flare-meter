import AppKit
import UserNotifications

/// What to warn about, set in Settings → Alerts. In the app's own defaults: only the app sends notifications.
enum AlertSettings {
    static let enabledKey = "alertsEnabled"
    static let thresholdKey = "alertThreshold"
    static let spikesKey = "spikeAlerts"
    static let budgetKey = "chargeBudgetUSD"

    static let enabledDefault = true
    /// The share of a limit that earns a warning, before the one at the limit itself.
    static let thresholdDefault = 0.8
    static let spikesDefault = true
    /// Paid: estimated charges past the included amounts, in USD; 0 is off. Matches Cloudflare's default budget alert.
    static let budgetDefault = 10.0

    static let thresholds: [Double] = [0.5, 0.75, 0.8, 0.9]
    static let budgets: [Double] = [1, 5, 10, 25, 50, 100]

    static var enabled: Bool { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? enabledDefault }
    static var threshold: Double { UserDefaults.standard.object(forKey: thresholdKey) as? Double ?? thresholdDefault }
    static var spikes: Bool { UserDefaults.standard.object(forKey: spikesKey) as? Bool ?? spikesDefault }
    static var budget: Double { UserDefaults.standard.object(forKey: budgetKey) as? Double ?? budgetDefault }
}

/// Early warnings as macOS notifications, checked on every new reading while the app runs (readings the widget fetched
/// too):
/// - a metric reaching the warning level, then its limit: once each per day on Free, per month on Paid;
/// - estimated charges passing the budget (Paid), once per month;
/// - a spike: a metric running at `spikeFactor` × its rate over the last day for `spikeReadings` readings in a row,
///   and fast enough to use a whole period's allowance within the period. A runaway Durable Object alarm loop, say.
///   Cloudflare's own budget alerts arrive the day after.
///
/// Clicking a notification opens the Cloudflare dashboard.
@MainActor
final class UsageAlerts: NSObject, UNUserNotificationCenterDelegate {
    static let shared = UsageAlerts()

    private static let spikeFactor = 10.0
    /// Readings come about 15 minutes apart, so two in a row rule out short batch jobs.
    private static let spikeReadings = 2
    /// One notification per metric per spike, however long it lasts.
    private static let spikeCooldown: TimeInterval = 6 * 3600
    private static let sentKey = "alertsSent"
    private static let readingsKey = "alertReadings"

    private struct Note {
        /// The notification's identifier; for a warning sent once, also how it's remembered.
        let id: String
        let title: String
        let body: String
        /// Remembered, so it's sent once per period.
        var once = true
    }

    /// A reading's month-to-date values: rates are what they grew by between readings.
    private struct Reading: Codable {
        let at: Date
        let source: String?
        let month: [String: Double]
    }

    private let center = UNUserNotificationCenter.current()
    /// The last day's readings, oldest first. Kept across launches, so the usual rate survives a restart.
    private var readings: [Reading]
    /// Readings in a row each metric has run at spike rate.
    private var hotReadings: [String: Int] = [:]
    private var lastSpike: [String: Date] = [:]
    private var askedPermission = false

    private override init() {
        readings = UserDefaults.standard.data(forKey: Self.readingsKey).flatMap { try? JSONDecoder().decode([Reading].self, from: $0) } ?? []
        super.init()
        center.delegate = self
    }

    /// macOS asks the person once and remembers the answer.
    func requestPermission() {
        askedPermission = true
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func sendTest() {
        requestPermission()
        post(Note(id: "test", title: "FlareMeter alerts are on",
                  body: "You'll get a notification like this when a metric nears its limit or suddenly spikes.", once: false),
             accountID: UsageSettings.load().accountID)
    }

    func check(_ s: UsageSnapshot, accountID: String) {
        let spikes = spikeNotes(s)
        guard AlertSettings.enabled else { return }
        // Asked on the first reading, which comes right after connecting.
        if !askedPermission { requestPermission() }
        var notes = limitNotes(s) + spikes
        if let budget = budgetNote(s) { notes.append(budget) }
        for note in notes where !note.once || markSent(note.id) {
            post(note, accountID: accountID)
        }
    }

    // MARK: Limits and charges

    private func limitNotes(_ s: UsageSnapshot) -> [Note] {
        let period = s.plan == .free ? "today's limit" : "this month's included amount"
        let untilReset = Format.duration(UTC.nextMidnight(after: s.fetchedAt).timeIntervalSince(s.fetchedAt))
        return s.ranked.compactMap { v in
            guard let f = v.fraction(plan: s.plan), f >= AlertSettings.threshold,
                  let spec = Metrics.all.first(where: { $0.id == v.id }) else { return nil }
            let reached = f >= 1
            let title = reached ? "\(v.label) \(s.plan == .free ? "reached" : "passed") \(period)" : "\(v.label) at \(Format.percent(f)) of \(period)"
            var body = v.amount(plan: s.plan, separator: " of ") + "."
            if s.plan == .free, spec.aggregate == "sum" {
                // Storage is a running total; everything else starts again at midnight.
                body += reached ? " Cloudflare refuses more until the 00:00 UTC reset, in \(untilReset)." : " The limit resets at 00:00 UTC, in \(untilReset)."
            } else if s.plan == .paid, let price = Self.price(spec) {
                body += reached ? " Cloudflare bills \(price) past it." : " Past it, Cloudflare bills \(price)."
            }
            let id = [s.source ?? "", UTC.periodID(s.fetchedAt, plan: s.plan), v.id, reached ? "limit" : "warning"].joined(separator: "|")
            return Note(id: id, title: title, body: body)
        }
    }

    private func budgetNote(_ s: UsageSnapshot) -> Note? {
        let budget = AlertSettings.budget
        guard s.plan == .paid, budget > 0, let usd = s.estimatedOverageUSD, usd >= budget else { return nil }
        let id = [s.source ?? "", UTC.periodID(s.fetchedAt, plan: .paid), "budget", String(budget)].joined(separator: "|")
        return Note(id: id, title: "Estimated charges passed \(budget.formatted(.currency(code: "USD").precision(.fractionLength(0))))",
                    body: "About \(usd.formatted(.currency(code: "USD"))) past your plan's included usage this month, by FlareMeter's estimate.")
    }

    // MARK: Spikes

    /// Updates the rates with `s` (also while spike alerts are off, so they work as soon as they're on), and returns a
    /// note for each metric that just became a spike.
    private func spikeNotes(_ s: UsageSnapshot) -> [Note] {
        let month = Dictionary(s.values.compactMap { v in v.month.map { (v.id, $0) } }, uniquingKeysWith: { a, _ in a })
        if let last = readings.last {
            // Too soon after the last reading (the refresh button) to measure a rate: keep the older one.
            if last.source == s.source, s.fetchedAt.timeIntervalSince(last.at) < 5 * 60 { return [] }
            if last.source != s.source || last.at > s.fetchedAt { readings = [] }
        }
        readings.append(Reading(at: s.fetchedAt, source: s.source, month: month))
        readings.removeAll { s.fetchedAt.timeIntervalSince($0.at) > 25 * 3600 }
        UserDefaults.standard.set(try? JSONEncoder().encode(readings), forKey: Self.readingsKey)

        // Month-to-date values start again each month, so only pairs within one month measure anything.
        let pairs = zip(readings, readings.dropFirst()).filter { UTC.calendar.isDate($0.at, equalTo: $1.at, toGranularity: .month) }
        guard let latest = pairs.last, latest.1.at == s.fetchedAt,
              // After a long sleep, a rate over hours says little about now.
              latest.1.at.timeIntervalSince(latest.0.at) <= 2 * 3600 else {
            hotReadings = [:]
            return []
        }
        let elapsed = latest.1.at.timeIntervalSince(latest.0.at)
        // The usual rate leaves out the readings being judged.
        let usualPairs = pairs.dropLast(Self.spikeReadings)
        let usualSpan = usualPairs.reduce(0) { $0 + $1.1.at.timeIntervalSince($1.0.at) }
        guard usualSpan >= 6 * 3600 else { return [] }
        let monthInterval = UTC.month(of: s.fetchedAt)
        let periodEnd = s.plan == .free ? UTC.nextMidnight(after: s.fetchedAt) : monthInterval.end
        let periodHours = s.plan == .free ? 24 : monthInterval.duration / 3600

        var notes: [Note] = []
        for spec in Metrics.all where spec.aggregate == "sum" {
            guard let v = s.values.first(where: { $0.id == spec.id }), let limit = v.limit, limit > 0,
                  let now = latest.1.month[spec.id], let before = latest.0.month[spec.id], now > before else {
                hotReadings[spec.id] = 0
                continue
            }
            let perHour = (now - before) / elapsed * 3600
            let usual = usualPairs.reduce(0.0) { $0 + max(0, ($1.1.month[spec.id] ?? 0) - ($1.0.month[spec.id] ?? 0)) } / usualSpan * 3600
            guard perHour >= Self.spikeFactor * usual, perHour >= limit / periodHours else {
                hotReadings[spec.id] = 0
                continue
            }
            let readings = (hotReadings[spec.id] ?? 0) + 1
            hotReadings[spec.id] = readings
            guard readings >= Self.spikeReadings, AlertSettings.enabled, AlertSettings.spikes,
                  s.fetchedAt.timeIntervalSince(lastSpike[spec.id] ?? .distantPast) > Self.spikeCooldown else { continue }
            lastSpike[spec.id] = s.fetchedAt

            let rate = Format.number(perHour, unit: v.unit)
            var body = usual > 0 ? "About \(rate) an hour, \(Int(perHour / usual))× its rate over the last day." : "About \(rate) an hour, up from none over the last day."
            let used = v.value(plan: s.plan) ?? 0
            let toLimit = (limit - used) / perHour * 3600
            if used < limit, s.fetchedAt.addingTimeInterval(toLimit) < periodEnd {
                let what = s.plan == .free ? "today's limit" : "the included \(Format.number(limit, unit: v.unit))"
                body += " At this pace you'll reach \(what) in \(Format.duration(toLimit))."
            } else if used >= limit, s.plan == .paid, let price = spec.paidPricePerUnit {
                body += " At this pace that's about \((perHour * price).formatted(.currency(code: "USD"))) an hour."
            }
            notes.append(Note(id: "spike|\(spec.id)|\(Int(s.fetchedAt.timeIntervalSince1970))",
                              title: "Unusual spike in \(v.label)", body: body, once: false))
        }
        return notes
    }

    // MARK: Sending

    private func post(_ note: Note, accountID: String) {
        let content = UNMutableNotificationContent()
        content.title = note.title
        content.body = note.body
        content.sound = .default
        content.userInfo = ["url": UsageSettings.dashboardURL(accountID: accountID).absoluteString]
        center.add(UNNotificationRequest(identifier: note.id, content: content, trigger: nil))
    }

    /// Remembers `id`; false when it was already sent. Forgets ids after 40 days, past any period they belong to.
    private func markSent(_ id: String) -> Bool {
        let defaults = UserDefaults.standard
        var sent = (defaults.dictionary(forKey: Self.sentKey) as? [String: Date] ?? [:]).filter { $0.value.timeIntervalSinceNow > -40 * 86_400 }
        guard sent[id] == nil else { return false }
        sent[id] = Date()
        defaults.set(sent, forKey: Self.sentKey)
        return true
    }

    /// "$0.15 per million", or per thousand for Workers AI neurons.
    private static func price(_ spec: MetricSpec) -> String? {
        guard let p = spec.paidPricePerUnit else { return nil }
        let (amount, per) = spec.unit == .neurons ? (p * 1_000, "thousand") : (p * 1_000_000, "million")
        return amount.formatted(.currency(code: "USD").precision(.fractionLength(2...3))) + " per " + per
    }

    // MARK: UNUserNotificationCenterDelegate

    /// Show them while Settings is frontmost too.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        if let url = (response.notification.request.content.userInfo["url"] as? String).flatMap(URL.init(string:)) {
            NSWorkspace.shared.open(url)
        }
        completionHandler()
    }
}
