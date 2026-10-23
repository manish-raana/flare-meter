import XCTest
@testable import FlareMeter

private func spec(_ id: String) -> MetricSpec { Metrics.all.first { $0.id == id }! }

private func utc(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }

private func metricValue(_ id: String, today: Double? = nil, month: Double?) -> MetricValue {
    MetricValue(id: id, label: id, today: today, month: month, error: nil, limit: nil, unit: "count")
}

final class PriceListTests: XCTestCase {
    func testLimitsAreBundledForEveryMetric() {
        let list = PriceList.bundled
        XCTAssertEqual(list.paidBaseUSD, 5)
        XCTAssertNotEqual(list.asOf, "unknown")
        let ids = Set(Metrics.all.map(\.id))
        for entry in list.metrics { XCTAssertTrue(ids.contains(entry.id), "\(entry.id) in Limits.json isn't a metric") }
        for s in Metrics.all where s.id != "workerErrors" { XCTAssertNotNil(list.entry(s.id), "\(s.id) has no limits") }
    }

    func testFreeLimits() {
        XCTAssertEqual(spec("workerRequests").freeDailyLimit, 100_000)
        XCTAssertEqual(spec("kvWrites").freeDailyLimit, 1_000)
        // Free caps CPU time per request, not per day.
        XCTAssertNil(spec("workerCPUTime").freeDailyLimit)
        XCTAssertNil(spec("workerErrors").limit(plan: .free, at: Date()))
    }

    func testPaidIncludedAmounts() {
        let oct15 = utc("2026-10-15T12:00:00Z")
        XCTAssertEqual(spec("workerRequests").paidIncluded(month: oct15), 10_000_000)
        XCTAssertEqual(spec("workerRequests").paidIncludedSoFar(oct15), 10_000_000)
        XCTAssertEqual(spec("workerCPUTime").paidIncluded(month: oct15), 30_000_000)
        XCTAssertEqual(spec("workerRequests").limit(plan: .paid, at: oct15), 10_000_000)
        XCTAssertEqual(spec("workerRequests").limit(plan: .free, at: oct15), 100_000)
    }

    /// Workers AI's 10,000 neurons are per day on Paid too.
    func testWorkersAIAllowanceIsDaily() {
        let ai = spec("aiNeurons")
        XCTAssertEqual(ai.paidIncluded(month: utc("2026-10-15T12:00:00Z")), 310_000)
        XCTAssertEqual(ai.paidIncluded(month: utc("2026-02-10T00:00:00Z")), 280_000)
        XCTAssertEqual(ai.paidIncludedSoFar(utc("2026-10-15T12:00:00Z")), 150_000)
        XCTAssertEqual(ai.paidIncludedSoFar(utc("2026-10-01T00:00:00Z")), 10_000)
    }

    func testPrices() {
        XCTAssertEqual(spec("workerRequests").paidPricePerUnit!, 0.30 / 1_000_000, accuracy: 1e-15)
        XCTAssertEqual(spec("aiNeurons").paidPricePerUnit!, 0.011 / 1_000, accuracy: 1e-15)
        XCTAssertNil(spec("doStorage").paidPricePerUnit)
    }
}

final class OverageTests: XCTestCase {
    func testOverageSumsEveryPricedMetricPastItsIncludedAmount() {
        let oct15 = utc("2026-10-15T12:00:00Z")
        let values = [
            metricValue("workerRequests", month: 12_000_000),   // 2M over × $0.30/M = $0.60
            metricValue("workerCPUTime", month: 40_000_000),    // 10M ms over × $0.02/M = $0.20
            metricValue("aiNeurons", month: 160_000),           // 10k over 15 days' allowance × $0.011/k = $0.11
            metricValue("kvReads", month: 5_000_000),           // within
            metricValue("doStorage", month: 9_000_000_000),     // no price
            metricValue("workerErrors", month: 1_000_000),      // no limit
            metricValue("d1RowsRead", month: nil),              // not returned
        ]
        XCTAssertEqual(Metrics.estimatedOverageUSD(values, at: oct15), 0.91, accuracy: 1e-9)
    }

    func testNothingOverIsZero() {
        XCTAssertEqual(Metrics.estimatedOverageUSD([metricValue("workerRequests", month: 1)], at: Date()), 0)
    }

    func testBillAddsTheBaseFee() {
        let paid = UsageSnapshot(fetchedAt: Date(), plan: .paid, values: [], estimatedOverageUSD: 0.91)
        XCTAssertEqual(paid.estimatedBillUSD!, 5.91, accuracy: 1e-9)
        let free = UsageSnapshot(fetchedAt: Date(), plan: .free, values: [], estimatedOverageUSD: nil)
        XCTAssertNil(free.estimatedBillUSD)
    }
}

final class UTCTests: XCTestCase {
    func testPeriods() {
        let d = utc("2026-10-21T23:30:00Z")
        XCTAssertEqual(UTC.periodID(d, plan: .free), "2026-10-21")
        XCTAssertEqual(UTC.periodID(d, plan: .paid), "2026-10")
        XCTAssertEqual(UTC.nextMidnight(after: d), utc("2026-10-22T00:00:00Z"))
        XCTAssertEqual(UTC.dayOfMonth(d), 21)
        XCTAssertEqual(UTC.daysInMonth(of: utc("2028-02-01T00:00:00Z")), 29)
        XCTAssertEqual(UTC.month(of: d).start, utc("2026-10-01T00:00:00Z"))
    }
}

final class FormatTests: XCTestCase {
    func testNumbers() {
        XCTAssertEqual(Format.number(nil), "—")
        XCTAssertEqual(Format.number(329), "329")
        XCTAssertEqual(Format.number(1_500), "1.5k")
        XCTAssertEqual(Format.number(68_000), "68k")
        XCTAssertEqual(Format.number(2_500_000), "2.5M")
        XCTAssertEqual(Format.number(3_000_000_000), "3.0B")
        XCTAssertEqual(Format.number(0, unit: "bytes"), "0 B")
    }

    func testPercentAndDuration() {
        XCTAssertEqual(Format.percent(0.004), "<1%")
        XCTAssertEqual(Format.percent(0), "0%")
        XCTAssertEqual(Format.percent(0.5), "50%")
        XCTAssertEqual(Format.duration(3_000), "50m")
        XCTAssertEqual(Format.duration(18_720), "5h 12m")
    }

    func testFraction() {
        let v = MetricValue(id: "x", label: "x", today: 50, month: 500, error: nil, limit: 1_000, unit: "count")
        XCTAssertEqual(v.fraction(plan: .free), 0.05)
        XCTAssertEqual(v.fraction(plan: .paid), 0.5)
    }
}

/// Account bookkeeping only: these don't save, so they leave the Mac's real settings and tokens alone.
final class SettingsTests: XCTestCase {
    private let a = String(repeating: "a", count: 32)
    private let b = String(repeating: "b", count: 32)

    func testSettingsFromBeforeSeveralAccountsStillDecode() throws {
        let json = #"{"accountID":"\#(a)","workerScript":"api","plan":"paid"}"#
        let s = try JSONDecoder().decode(UsageSettings.self, from: Data(json.utf8))
        XCTAssertEqual(s.accountID, a)
        XCTAssertEqual(s.workerScript, "api")
        XCTAssertEqual(s.plan, .paid)
        XCTAssertEqual(s.savedAccounts, [])
    }

    func testTheTokenIsNeverEncoded() throws {
        let s = UsageSettings(accountID: a, apiToken: "secret", savedAccounts: [SavedAccount(id: a, name: "Acme")])
        let json = String(decoding: try JSONEncoder().encode(s), as: UTF8.self)
        XCTAssertFalse(json.contains("secret"))
        let back = try JSONDecoder().decode(UsageSettings.self, from: Data(json.utf8))
        XCTAssertEqual(back.savedAccounts, s.savedAccounts)
    }

    func testSwitchingKeepsEachAccountsWorkerAndPlan() {
        var s = UsageSettings(accountID: a, workerScript: "", plan: .paid, savedAccounts: [
            SavedAccount(id: a, name: "Acme", workerScript: "", plan: .paid),
            SavedAccount(id: b, name: "Side project", workerScript: "blog", plan: .free),
        ])
        s.workerScript = "api"
        s.select(b)
        XCTAssertEqual(s.accountID, b)
        XCTAssertEqual(s.accountName, "Side project")
        XCTAssertEqual(s.workerScript, "blog")
        XCTAssertEqual(s.plan, .free)

        s.select(a)
        XCTAssertEqual(s.workerScript, "api")
        XCTAssertEqual(s.plan, .paid)
        XCTAssertEqual(s.savedAccounts.first { $0.id == b }?.workerScript, "blog")
    }

    func testSelectingAnUnknownAccountChangesNothing() {
        var s = UsageSettings(accountID: a, savedAccounts: [SavedAccount(id: a, name: "Acme")])
        s.select(b)
        XCTAssertEqual(s.accountID, a)
    }

    func testAccountNameFallsBackToTheID() {
        XCTAssertEqual(UsageSettings(accountID: a).accountName, a)
    }
}
