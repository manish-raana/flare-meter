import Foundation

/// Cloudflare GraphQL Analytics API (https://developers.cloudflare.com/analytics/graphql-api/).
/// Needs an API token with Account → Account Analytics → Read, nothing else.
struct CloudflareClient {
    let settings: UsageSettings
    private let endpoint = URL(string: "https://api.cloudflare.com/client/v4/graphql")!

    enum ClientError: LocalizedError {
        case notConfigured
        case badAccountID
        case http(Int)
        case graphQL(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Connect your Cloudflare account in FlareMeter."
            case .badAccountID: return "The account ID should be 32 hex characters."
            case .http(let code): return "Cloudflare answered HTTP \(code)."
            case .graphQL(let message): return message
            }
        }
    }

    /// Every metric, today (UTC) and month to date. A metric that fails gets its error instead of a value.
    func snapshot(now: Date = Date()) async throws -> UsageSnapshot {
        guard settings.isComplete else { throw ClientError.notConfigured }
        guard settings.accountID.range(of: "^[0-9a-fA-F]{32}$", options: .regularExpression) != nil else { throw ClientError.badAccountID }

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let dayStart = utc.startOfDay(for: now)
        let monthStart = utc.date(from: utc.dateComponents([.year, .month], from: now))!
        let end = now

        let values = await withTaskGroup(of: (Int, MetricValue).self) { group in
            for (i, spec) in Metrics.all.enumerated() {
                group.addTask {
                    async let today = self.result(spec, from: dayStart, to: end)
                    async let month = self.result(spec, from: monthStart, to: end)
                    let (t, m) = await (today, month)
                    let limit = spec.limit(plan: self.settings.plan, at: now)
                    var error: String? = nil
                    if case .failure(let e) = t { error = e.localizedDescription } else if case .failure(let e) = m { error = e.localizedDescription }
                    return (i, MetricValue(id: spec.id, label: spec.label, today: try? t.get(), month: try? m.get(), error: error,
                                           limit: limit, unit: Self.unitName(spec.unit)))
                }
            }
            var out: [(Int, MetricValue)] = []
            for await item in group { out.append(item) }
            return out.sorted { $0.0 < $1.0 }.map(\.1)
        }

        // Every metric failing means the token or account is wrong, not that a product is unused.
        if values.allSatisfy({ $0.today == nil && $0.month == nil }), let error = values.first?.error {
            throw ClientError.graphQL(error)
        }

        let overage = settings.plan == .paid ? Metrics.estimatedOverageUSD(values, at: now) : nil
        return UsageSnapshot(fetchedAt: now, plan: settings.plan, values: values, estimatedOverageUSD: overage, source: settings.cacheKey)
    }

    private func result(_ spec: MetricSpec, from: Date, to: Date) async -> Result<Double, Error> {
        do { return .success(try await value(spec, from: from, to: to)) } catch { return .failure(error) }
    }

    private static func unitName(_ u: MetricSpec.Unit) -> String {
        switch u {
        case .count: return "count"
        case .bytes: return "bytes"
        case .neurons: return "neurons"
        case .milliseconds: return "ms"
        }
    }

    /// One metric over [from, to): the sum (or max) across the rows Cloudflare returns.
    func value(_ spec: MetricSpec, from: Date, to: Date) async throws -> Double {
        let iso = ISO8601DateFormatter()
        let day = DateFormatter()
        day.dateFormat = "yyyy-MM-dd"
        day.timeZone = TimeZone(identifier: "UTC")
        var filters: [String] = []
        switch spec.timeFilter {
        case .datetime:
            filters.append("datetime_geq: \"\(iso.string(from: from))\"")
            filters.append("datetime_lt: \"\(iso.string(from: to))\"")
        case .date:
            filters.append("date_geq: \"\(day.string(from: from))\"")
            filters.append("date_leq: \"\(day.string(from: to))\"")
        }
        if spec.byScript, !settings.workerScript.isEmpty {
            let script = settings.workerScript.replacingOccurrences(of: "\"", with: "")
            filters.append("scriptName: \"\(script)\"")
        }
        let dims = spec.actionTypes == nil ? "" : " dimensions { actionType }"
        let query = """
        { viewer { accounts(filter: { accountTag: "\(settings.accountID)" }) { \
        rows: \(spec.dataset)(limit: 10000, filter: { \(filters.joined(separator: ", ")) }) { \(spec.aggregate) { \(spec.field) }\(dims) } } } }
        """
        let data = try await post(query)
        guard
            let viewer = (data["viewer"] as? [String: Any]),
            let accounts = viewer["accounts"] as? [[String: Any]],
            let rows = accounts.first?["rows"] as? [[String: Any]]
        else { throw ClientError.graphQL("Unexpected response for \(spec.dataset)") }

        var values: [Double] = []
        for row in rows {
            if let types = spec.actionTypes {
                let action = ((row["dimensions"] as? [String: Any])?["actionType"] as? String ?? "").lowercased()
                if !types.contains(action) { continue }
            }
            if let agg = row[spec.aggregate] as? [String: Any], let n = agg[spec.field] as? NSNumber {
                values.append(n.doubleValue)
            }
        }
        return (spec.aggregate == "max" ? (values.max() ?? 0) : values.reduce(0, +)) * spec.scale
    }

    struct Account: Identifiable, Hashable {
        let id: String
        let name: String
    }

    /// The accounts the token can see. Works with only Account Analytics: Read.
    func accounts() async throws -> [Account] {
        var request = URLRequest(url: URL(string: "https://api.cloudflare.com/client/v4/accounts?per_page=50")!)
        request.timeoutInterval = 20
        request.setValue("Bearer \(settings.apiToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        if let errors = json["errors"] as? [[String: Any]], let message = errors.first?["message"] as? String {
            throw ClientError.graphQL(message)
        }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) { throw ClientError.http(http.statusCode) }
        return (json["result"] as? [[String: Any]] ?? []).compactMap { a in
            guard let id = a["id"] as? String else { return nil }
            return Account(id: id, name: a["name"] as? String ?? id)
        }
    }

    /// Worker names with requests in the last 7 days, busiest first.
    func workerNames(now: Date = Date()) async throws -> [String] {
        let iso = ISO8601DateFormatter()
        let query = """
        { viewer { accounts(filter: { accountTag: "\(settings.accountID)" }) { \
        rows: workersInvocationsAdaptive(limit: 100, filter: { datetime_geq: "\(iso.string(from: now.addingTimeInterval(-7 * 86_400)))", \
        datetime_lt: "\(iso.string(from: now))" }, orderBy: [sum_requests_DESC]) { dimensions { scriptName } } } } }
        """
        let data = try await post(query)
        let rows = (((data["viewer"] as? [String: Any])?["accounts"] as? [[String: Any]])?.first?["rows"] as? [[String: Any]]) ?? []
        return rows.compactMap { ($0["dimensions"] as? [String: Any])?["scriptName"] as? String }.filter { $0 != "__unknown__" }
    }

    private func post(_ query: String) async throws -> [String: Any] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(settings.apiToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query])
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) { throw ClientError.http(http.statusCode) }
        let json = (try JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
            let message = errors.compactMap { $0["message"] as? String }.joined(separator: "; ")
            throw ClientError.graphQL(message.isEmpty ? "GraphQL error" : message)
        }
        return json["data"] as? [String: Any] ?? [:]
    }
}
