import Foundation

/// One number the widget shows, and how to get it from Cloudflare's GraphQL Analytics API. Its limits and prices come
/// from Limits.json (`PriceList`).
///
/// Field names for some datasets aren't documented (Durable Object rows, Workers AI). Each metric is its own request,
/// so a wrong name or a product the account doesn't have hides that metric only.
struct MetricSpec: Identifiable, Hashable {
    enum TimeFilter: Hashable {
        /// `datetime_geq` / `datetime_lt` (adaptive and most datasets).
        case datetime
        /// `date_geq` / `date_leq` (daily datasets, e.g. storage).
        case date
    }

    let id: String
    let label: String
    let dataset: String
    /// "sum" or "max".
    let aggregate: String
    let field: String
    let timeFilter: TimeFilter
    /// Limit a dataset to the chosen Worker (`scriptName`).
    let byScript: Bool
    /// For datasets split by `actionType` (KV): keep only these actions.
    let actionTypes: [String]?
    let unit: Unit
    /// Multiplies what Cloudflare returns, e.g. microseconds to milliseconds.
    var scale: Double = 1

    enum Unit: Hashable { case count, bytes, neurons, milliseconds }

    private var prices: PriceList.Entry? { PriceList.bundled.entry(id) }

    /// Workers Free: the daily cap, or nil when there's none.
    var freeDailyLimit: Double? { prices?.freeDaily }

    /// Workers Paid: the amount included in the month `date` falls in. A daily allowance (Workers AI) counts every day.
    func paidIncluded(month date: Date) -> Double? {
        guard let p = prices, let included = p.paidIncluded else { return nil }
        return p.paidIncludedPer == "day" ? included * Double(UTC.daysInMonth(of: date)) : included
    }

    /// Workers Paid: the amount included from the start of the month through `date`'s day, which charges are counted
    /// past. For a daily allowance this is a lower bound: a day's unused allowance doesn't carry over.
    func paidIncludedSoFar(_ date: Date) -> Double? {
        guard let p = prices, let included = p.paidIncluded else { return nil }
        return p.paidIncludedPer == "day" ? included * Double(UTC.dayOfMonth(date)) : included
    }

    /// USD per unit past the included amount (paid plan).
    var paidPricePerUnit: Double? {
        guard let p = prices, let usd = p.paidPriceUSD, let per = p.paidPricePer, per > 0 else { return nil }
        return usd / per
    }

    /// What a reading on `plan` is measured against: today's cap (Free) or this month's included amount (Paid).
    func limit(plan: Plan, at date: Date) -> Double? {
        plan == .free ? freeDailyLimit : paidIncluded(month: date)
    }
}

/// Cloudflare's published limits and prices, from Limits.json: the same file the website's tables are built from.
/// Check them against https://developers.cloudflare.com/workers/platform/pricing/ before each release, update `asOf`,
/// and ship an update when they change.
struct PriceList: Decodable {
    struct Entry: Decodable {
        let id: String
        let freeDaily: Double?
        let paidIncluded: Double?
        /// "month", or "day" for an allowance that renews daily on Paid too (Workers AI).
        let paidIncludedPer: String?
        let paidPriceUSD: Double?
        let paidPricePer: Double?
    }

    /// Shown in Settings next to the plan, so people know how current the limits are.
    let asOf: String
    /// The Workers Paid subscription, per month.
    let paidBaseUSD: Double
    let metrics: [Entry]

    func entry(_ id: String) -> Entry? { metrics.first { $0.id == id } }

    /// Limits.json from the app's or the widget's bundle.
    static let bundled: PriceList = {
        guard let url = Bundle.main.url(forResource: "Limits", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode(PriceList.self, from: data) else {
            assertionFailure("Limits.json is missing from the bundle or doesn't decode")
            return PriceList(asOf: "unknown", paidBaseUSD: 0, metrics: [])
        }
        return list
    }()
}

enum Metrics {
    static var pricingAsOf: String { PriceList.bundled.asOf }
    static var paidBaseUSD: Double { PriceList.bundled.paidBaseUSD }

    static let all: [MetricSpec] = [
        MetricSpec(id: "workerRequests", label: "Worker requests", dataset: "workersInvocationsAdaptive", aggregate: "sum", field: "requests",
                   timeFilter: .datetime, byScript: true, actionTypes: nil, unit: .count),
        // Paid bills CPU time past 30 million ms a month; Free only caps each request.
        MetricSpec(id: "workerCPUTime", label: "Worker CPU ms", dataset: "workersInvocationsAdaptive", aggregate: "sum", field: "cpuTimeUs",
                   timeFilter: .datetime, byScript: true, actionTypes: nil, unit: .milliseconds, scale: 0.001),
        MetricSpec(id: "workerErrors", label: "Worker errors", dataset: "workersInvocationsAdaptive", aggregate: "sum", field: "errors",
                   timeFilter: .datetime, byScript: true, actionTypes: nil, unit: .count),
        MetricSpec(id: "doRequests", label: "DO requests", dataset: "durableObjectsInvocationsAdaptiveGroups", aggregate: "sum", field: "requests",
                   timeFilter: .datetime, byScript: false, actionTypes: nil, unit: .count),
        MetricSpec(id: "doRowsRead", label: "DO rows read", dataset: "durableObjectsPeriodicGroups", aggregate: "sum", field: "rowsRead",
                   timeFilter: .datetime, byScript: false, actionTypes: nil, unit: .count),
        MetricSpec(id: "doRowsWritten", label: "DO rows written", dataset: "durableObjectsPeriodicGroups", aggregate: "sum", field: "rowsWritten",
                   timeFilter: .datetime, byScript: false, actionTypes: nil, unit: .count),
        MetricSpec(id: "doStorage", label: "DO storage", dataset: "durableObjectsStorageGroups", aggregate: "max", field: "storedBytes",
                   timeFilter: .date, byScript: false, actionTypes: nil, unit: .bytes),
        MetricSpec(id: "kvReads", label: "KV reads", dataset: "kvOperationsAdaptiveGroups", aggregate: "sum", field: "requests",
                   timeFilter: .datetime, byScript: false, actionTypes: ["read"], unit: .count),
        MetricSpec(id: "kvWrites", label: "KV writes", dataset: "kvOperationsAdaptiveGroups", aggregate: "sum", field: "requests",
                   timeFilter: .datetime, byScript: false, actionTypes: ["write", "delete", "list"], unit: .count),
        MetricSpec(id: "d1RowsRead", label: "D1 rows read", dataset: "d1AnalyticsAdaptiveGroups", aggregate: "sum", field: "rowsRead",
                   timeFilter: .datetime, byScript: false, actionTypes: nil, unit: .count),
        MetricSpec(id: "d1RowsWritten", label: "D1 rows written", dataset: "d1AnalyticsAdaptiveGroups", aggregate: "sum", field: "rowsWritten",
                   timeFilter: .datetime, byScript: false, actionTypes: nil, unit: .count),
        MetricSpec(id: "aiNeurons", label: "Workers AI neurons", dataset: "aiInferenceAdaptiveGroups", aggregate: "sum", field: "totalNeurons",
                   timeFilter: .datetime, byScript: false, actionTypes: nil, unit: .neurons),
    ]

    /// Workers Paid: estimated charges this month past the included amounts, Σ max(0, month − included) × price over
    /// every metric with a price. Without the plan's base fee (`paidBaseUSD`).
    static func estimatedOverageUSD(_ values: [MetricValue], at date: Date) -> Double {
        values.reduce(0.0) { total, v in
            guard let spec = all.first(where: { $0.id == v.id }), let price = spec.paidPricePerUnit,
                  let included = spec.paidIncludedSoFar(date), let month = v.month else { return total }
            return total + max(0, month - included) * price
        }
    }
}

/// A metric's reading: today (UTC) and this month so far.
struct MetricValue: Codable, Hashable, Identifiable {
    let id: String
    let label: String
    let today: Double?
    let month: Double?
    let error: String?
    /// The limit it's measured against on the chosen plan (today's for Free, this month's for Paid).
    let limit: Double?
    let unit: String

    /// 0...1+ of the limit, or nil when there's no limit or no value.
    func fraction(plan: Plan) -> Double? {
        guard let limit, limit > 0, let v = plan == .free ? today : month else { return nil }
        return v / limit
    }

    func value(plan: Plan) -> Double? { plan == .free ? today : month }
}

struct UsageSnapshot: Codable, Hashable {
    let fetchedAt: Date
    let plan: Plan
    let values: [MetricValue]
    /// Paid plan: estimated charges this month past the included amounts.
    let estimatedOverageUSD: Double?
    /// `UsageSettings.cacheKey` it was read with: a cached reading for other settings isn't shown.
    var source: String? = nil

    /// Paid plan: the estimate plus the plan's monthly base fee.
    var estimatedBillUSD: Double? { estimatedOverageUSD.map { $0 + Metrics.paidBaseUSD } }

    /// Metrics with a limit, fullest first.
    var ranked: [MetricValue] {
        values.filter { $0.fraction(plan: plan) != nil }.sorted { ($0.fraction(plan: plan) ?? 0) > ($1.fraction(plan: plan) ?? 0) }
    }
}

enum Format {
    static func number(_ v: Double?, unit: String = "count") -> String {
        guard let v else { return "—" }
        if unit == "bytes" {
            if v == 0 { return "0 B" }
            return ByteCountFormatter.string(fromByteCount: Int64(v), countStyle: .decimal)
        }
        switch abs(v) {
        case 1_000_000_000...: return String(format: "%.1fB", v / 1_000_000_000)
        case 1_000_000...: return String(format: "%.1fM", v / 1_000_000)
        case 10_000...: return String(format: "%.0fk", v / 1_000)
        case 1_000...: return String(format: "%.1fk", v / 1_000)
        default: return String(format: "%.0f", v)
        }
    }

    static func percent(_ f: Double?) -> String {
        guard let f else { return "—" }
        return f < 0.01 && f > 0 ? "<1%" : String(format: "%.0f%%", f * 100)
    }

    /// "5h 12m", or "45m" under an hour.
    static func duration(_ seconds: TimeInterval) -> String {
        let minutes = max(0, Int(seconds / 60))
        return minutes < 60 ? "\(minutes)m" : "\(minutes / 60)h \(minutes % 60)m"
    }
}

/// Cloudflare's days and months are UTC: Workers Free's limits reset at 00:00 UTC, Paid's included amounts monthly.
enum UTC {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    static func nextMidnight(after date: Date) -> Date {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
    }

    static func month(of date: Date) -> DateInterval {
        calendar.dateInterval(of: .month, for: date)!
    }

    static func daysInMonth(of date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)!.count
    }

    /// 1 on the first of the month.
    static func dayOfMonth(_ date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    /// The plan's period `date` falls in: "2026-10-21" on Free (daily), "2026-10" on Paid (monthly).
    static func periodID(_ date: Date, plan: Plan) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let month = String(format: "%04d-%02d", c.year!, c.month!)
        return plan == .free ? month + String(format: "-%02d", c.day!) : month
    }
}
