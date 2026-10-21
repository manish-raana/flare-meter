import Foundation

/// One number the widget shows, and how to get it from Cloudflare's GraphQL Analytics API.
///
/// Field names for some datasets aren't documented (Durable Object rows, Workers AI). Each metric is its own request,
/// so a wrong name or a product the account doesn't have hides that metric only.
struct MetricSpec: Identifiable, Hashable {
    enum TimeFilter: Hashable {
        /// `datetime_geq` / `datetime_lt` (adaptive and most datasets).
        case datetime
        /// `date_geq` / `date_lt` (daily datasets, e.g. storage).
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
    let freeDailyLimit: Double?
    let paidMonthlyIncluded: Double?
    /// USD per unit past the included amount (paid plan).
    let paidPricePerUnit: Double?

    enum Unit: Hashable { case count, bytes, neurons }
}

/// Limits and prices are Cloudflare's published ones as of `pricingAsOf`; check
/// https://developers.cloudflare.com/workers/platform/pricing/ before each release, and ship an update when they change.
enum Metrics {
    /// Shown in Settings next to the plan, so people know how current the limits are.
    static let pricingAsOf = "October 2026"

    static let all: [MetricSpec] = [
        MetricSpec(id: "workerRequests", label: "Worker requests", dataset: "workersInvocationsAdaptive", aggregate: "sum", field: "requests",
                   timeFilter: .datetime, byScript: true, actionTypes: nil, unit: .count,
                   freeDailyLimit: 100_000, paidMonthlyIncluded: 10_000_000, paidPricePerUnit: 0.30 / 1_000_000),
        MetricSpec(id: "workerErrors", label: "Worker errors", dataset: "workersInvocationsAdaptive", aggregate: "sum", field: "errors",
                   timeFilter: .datetime, byScript: true, actionTypes: nil, unit: .count,
                   freeDailyLimit: nil, paidMonthlyIncluded: nil, paidPricePerUnit: nil),
        MetricSpec(id: "doRequests", label: "DO requests", dataset: "durableObjectsInvocationsAdaptiveGroups", aggregate: "sum", field: "requests",
                   timeFilter: .datetime, byScript: false, actionTypes: nil, unit: .count,
                   freeDailyLimit: 100_000, paidMonthlyIncluded: 1_000_000, paidPricePerUnit: 0.15 / 1_000_000),
        MetricSpec(id: "doRowsRead", label: "DO rows read", dataset: "durableObjectsPeriodicGroups", aggregate: "sum", field: "rowsRead",
                   timeFilter: .datetime, byScript: false, actionTypes: nil, unit: .count,
                   freeDailyLimit: 5_000_000, paidMonthlyIncluded: 25_000_000_000, paidPricePerUnit: 0.001 / 1_000_000),
        MetricSpec(id: "doRowsWritten", label: "DO rows written", dataset: "durableObjectsPeriodicGroups", aggregate: "sum", field: "rowsWritten",
                   timeFilter: .datetime, byScript: false, actionTypes: nil, unit: .count,
                   freeDailyLimit: 100_000, paidMonthlyIncluded: 50_000_000, paidPricePerUnit: 1.0 / 1_000_000),
        MetricSpec(id: "doStorage", label: "DO storage", dataset: "durableObjectsStorageGroups", aggregate: "max", field: "storedBytes",
                   timeFilter: .date, byScript: false, actionTypes: nil, unit: .bytes,
                   freeDailyLimit: 5_000_000_000, paidMonthlyIncluded: 5_000_000_000, paidPricePerUnit: nil),
        MetricSpec(id: "kvReads", label: "KV reads", dataset: "kvOperationsAdaptiveGroups", aggregate: "sum", field: "requests",
                   timeFilter: .datetime, byScript: false, actionTypes: ["read"], unit: .count,
                   freeDailyLimit: 100_000, paidMonthlyIncluded: 10_000_000, paidPricePerUnit: 0.50 / 1_000_000),
        MetricSpec(id: "kvWrites", label: "KV writes", dataset: "kvOperationsAdaptiveGroups", aggregate: "sum", field: "requests",
                   timeFilter: .datetime, byScript: false, actionTypes: ["write", "delete", "list"], unit: .count,
                   freeDailyLimit: 1_000, paidMonthlyIncluded: 1_000_000, paidPricePerUnit: 5.0 / 1_000_000),
        MetricSpec(id: "d1RowsRead", label: "D1 rows read", dataset: "d1AnalyticsAdaptiveGroups", aggregate: "sum", field: "rowsRead",
                   timeFilter: .datetime, byScript: false, actionTypes: nil, unit: .count,
                   freeDailyLimit: 5_000_000, paidMonthlyIncluded: 25_000_000_000, paidPricePerUnit: 0.001 / 1_000_000),
        MetricSpec(id: "d1RowsWritten", label: "D1 rows written", dataset: "d1AnalyticsAdaptiveGroups", aggregate: "sum", field: "rowsWritten",
                   timeFilter: .datetime, byScript: false, actionTypes: nil, unit: .count,
                   freeDailyLimit: 100_000, paidMonthlyIncluded: 50_000_000, paidPricePerUnit: 1.0 / 1_000_000),
        MetricSpec(id: "aiNeurons", label: "Workers AI neurons", dataset: "aiInferenceAdaptiveGroups", aggregate: "sum", field: "totalNeurons",
                   timeFilter: .datetime, byScript: false, actionTypes: nil, unit: .neurons,
                   // 10,000 a day free on both plans, then $0.011 per 1,000.
                   freeDailyLimit: 10_000, paidMonthlyIncluded: 300_000, paidPricePerUnit: 0.011 / 1_000),
    ]
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

    /// The plan's period `date` falls in: "2026-10-21" on Free (daily), "2026-10" on Paid (monthly).
    static func periodID(_ date: Date, plan: Plan) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let month = String(format: "%04d-%02d", c.year!, c.month!)
        return plan == .free ? month + String(format: "-%02d", c.day!) : month
    }
}
